-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoCastbars
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoCastbars Module Definition
-----------------------------------------------------------------------------------------------
local Multitap = {}
local Charged = {}
local Castbar = {}
local PotatoCastbars = {}
local Defaults = _G["PUIDefaults"]["Castbar"]

local bEditorMode = false
local ccolorPlaceholder =  CColor.new(0, 0, 1, 1)
local ktPos = {"textLeft", "textMid", "textRight"}

local ktChargedMaxes = {
	--Esper
	["Illusionary Blades"] = 5100,
	["Soothe"] = 5100,
	
	--Spellslinger
	["Charged Shot"] = {7300,8300},
	["Tir concentré"] = {7300,8300},
	["Sustain"] = {7500,7500},
	["Soutenir"] = {7500,7500},
	["Vitality Burst"] = {7400,8400},
	["Rafale de vitalité"] = {7400,8400}

}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
local ktTextType = {
	[0] = {"None", ""},
	[1] = {"Name", "Ability Name"},
	[2] = {"Detailed", "1.1/5.5"},
	[3] = {"Shortened", "1.1"},
	[4] = {"Percent", "20%"}
}

local ktSpecialTextType = {
	[0] = {"None", ""},
	[1] = {"Name", "Ability Name"},
	[2] = {"Current", "3"},
	[3] = {"Maximum", "4"},
	[4] = {"Progress", "3/4"}
}

function PotatoCastbars:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoCastbars:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PotatoLib" --"PotatoLibV2",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function Castbar:InitMultitap()
	self.tMultitap = Multitap:new(self.tMultitap)
	self.tMultitap:Init(self)
end

function Castbar:InitCharged()
	self.tCharged = Charged:new(self.tCharged)
	self.tCharged:Init(self)
end

function PotatoCastbars:OnLoad() --Loaded 1st
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoCastbars.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	self.maxCCTime = 0
end

function PotatoCastbars:OnDocLoaded() --Loaded 3rd
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	--Initialize all castbars
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key] = Castbar:new(self[key] or val) --Load from restored values (self[key] from OnRestore()), or use the default (val).
			if self[key] == val then
				--Print(key..":Defaulted")
			else
				--Print(key..":Loaded")
			end
			self[key]:Init(self)
		end
	end
	
	self.luaSpecialCastbar:InitMultitap()
	self.luaSpecialCastbar:InitCharged()
	self.luaSpecialCastbar.wndCastbar:FindChild("CastProgress"):SetAnchorPoints(0, 0.75, 1, 1)
	self.luaSpecialCastbar.wndCastbar:FindChild("CastProgress"):SetMax(1)

	--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", "OnAlternateTargetUnitChanged", self)
	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"ResetAll", self)
	Apollo.RegisterEventHandler("PotatoSettings",				"PopulateSettingsList", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)

	Apollo.RegisterEventHandler("StartSpellThreshold", 	"OnStartSpellThreshold", self)
	Apollo.RegisterEventHandler("ClearSpellThreshold", 	"OnClearSpellThreshold", self)
	Apollo.RegisterEventHandler("UpdateSpellThreshold", "OnUpdateSpellThreshold", self)
	 	
	--Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)

	if GameLib.GetPlayerUnit() == nil then
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	else
		self:OnCharacterCreated()
	end
	
	self.timer = ApolloTimer.Create(0.033, true, "OnTimer", self)
end

function PotatoCastbars:PopulateResetFeatures()
	PotatoLib:AddResetParent("Castbars")
	
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			PotatoLib:AddResetItem(val.name, "Castbars", self[key])
		end
	end
end

function PotatoCastbars:OnWindowManagementReady()
	--Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndPlayerFrame.wndFrame,		strName = "[PUI] Player Frame"})
end

function PotatoCastbars:EditorModeToggle(bState)
	bEditorMode = bState
	
	for key, val in pairs(self) do
		if type(val) == "table" and val.wndCastbar then
			if bEditorMode then
				val.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", val.wndCastbar, val)
				val.wndCover:SetText(val.name)
				if val.border.show then
					val.wndCover:SetAnchorOffsets(val.border.size, val.border.size, -val.border.size, -val.border.size)
				else
					val.wndCover:SetAnchorOffsets(0,0,0,0)
				end
				--Populate castbar with a dummy
				val:CreateEditorDummy()
			else
				val.wndCover:Destroy()
				val.wndCover = nil
				if val.wndEditor then
					val.wndEditor:Destroy()
					val.wndEditor = nil
				end
			end
			val.wndCastbar:SetStyle("Moveable", bEditorMode)
			val.wndCastbar:SetStyle("Sizable", bEditorMode)
			val.wndCastbar:Show(bEditorMode)
		end
	end
end

function PotatoCastbars:OnFrame()
	--self:OnCharacterCreated(1)
end

function PotatoCastbars:OnTimer()
	if not bEditorMode then
		self:OnCharacterCreated()
	end
	--self:OnCharacterCreated(1)
	--self:OnCharacterCreated(2)
end

function PotatoCastbars:OnCharacterCreated(nLoc)
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer ~= nil then
		local unitTarget = unitPlayer:GetTarget()
		local altPlayerTarget = unitPlayer:GetAlternateTarget()
		if self.luaPlayerCastbar.showFrame == 1 or
		  (self.luaPlayerCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitPlayer) or PotatoLib.bInCombat)) or
		  (self.luaPlayerCastbar.showFrame == 3 and PotatoLib.bInCombat) then
		
			self.luaPlayerCastbar:SetTarget(unitPlayer)
		end
		
		if unitTarget then
			if self.luaTargetCastbar.showFrame == 1 or
			  (self.luaTargetCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitTarget) or PotatoLib.bInCombat)) or
			  (self.luaTargetCastbar.showFrame == 3 and PotatoLib.bInCombat) then
		
				self.luaTargetCastbar:SetTarget(unitTarget)
			end
							
			local unitToT = unitTarget:GetTarget()
			if unitToT and (self.luaToTCastbar.showFrame == 1 or
			  (self.luaToTCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitToT) or PotatoLib.bInCombat)) or
			  (self.luaToTCastbar.showFrame == 3 and PotatoLib.bInCombat)) then
		
				self.luaToTCastbar:SetTarget(unitToT )
			end
		end
		if altPlayerTarget and (self.luaFocusCastbar.showFrame == 1 or
		  (self.luaFocusCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, altPlayerTarget) or PotatoLib.bInCombat)) or
		  (self.luaFocusCastbar.showFrame == 3 and PotatoLib.bInCombat)) then
			self.luaFocusCastbar:SetTarget(altPlayerTarget)
		end
		
		if self.luaSpecialCastbar.wndCastbar:IsShown() then
			local eCastMethod = GameLib.GetSpell(self.nCurrentSpecialId):GetCastMethod()
			
			if eCastMethod == Spell.CodeEnumCastMethod.RapidTap then
				self.luaSpecialCastbar.tMultitap:UpdateTimeLeft()
			elseif eCastMethod == Spell.CodeEnumCastMethod.ChargeRelease then
				self.luaSpecialCastbar.tCharged:UpdateProgress()
				self.luaSpecialCastbar.tCharged:UpdateTimeLeft()
			elseif eCastMethod == Spell.CodeEnumCastMethod.PressHold then
				Print("[PotatoUI] PressHold found for \""..tSpellInfo.strName.."\" - Leave a comment on Curse!")
			end

		end
	end
end

function PotatoCastbars:OnTargetUnitChanged(unitTarget)
	if self.luaTargetCastbar.showFrame == 1 or
	  (self.luaTargetCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitTarget) or PotatoLib.bInCombat)) or
	  (self.luaTargetCastbar.showFrame == 3 and PotatoLib.bInCombat) then
	
		self.luaTargetCastbar:SetTarget(unitTarget)
	end
						
	if self.luaToTCastbar.showFrame == 1 or
	  (self.luaToTCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitToT) or PotatoLib.bInCombat)) or
	  (self.luaToTCastbar.showFrame == 3 and PotatoLib.bInCombat) then
	
		self.luaToTCastbar:SetTarget(unitTarget and unitTarget:GetTarget() or nil)
	end
end

function PotatoCastbars:OnAlternateTargetUnitChanged(unitTarget)
	if self.luaFocusCastbar.showFrame == 1 or
	  (self.luaFocusCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, altPlayerTarget) or PotatoLib.bInCombat)) or
	  (self.luaFocusCastbar.showFrame == 3 and PotatoLib.bInCombat) then		
		self.luaFocusCastbar:SetTarget(altPlayerTarget)
	end
end

function PotatoCastbars:OnStartSpellThreshold(idSpell, nMaxThresholds, eCastMethod) -- also fires on tier change
	if self.nCurrentSpecialId ~= nil and idSpell == self.nCurrentSpecialId then	return end -- we're getting an update event, ignore this one
	
	--Print("OSST:"..idSpell)
	
	local luaSpecialCastbar = self.luaSpecialCastbar
	
	if not (luaSpecialCastbar.showFrame == 1 or
	  (luaSpecialCastbar.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitPlayer) or PotatoLib.bInCombat)) or
	  (luaSpecialCastbar.showFrame == 3 and PotatoLib.bInCombat)) then --If frame is hidden, ignore displaying.
		return
	end
	
	self.nCurrentSpecialId = idSpell
	
	local tSpellInfo = {}
	local splObject = GameLib.GetSpell(idSpell) --TODO: Expand things found in here into options.

	tSpellInfo.id = idSpell
	tSpellInfo.nCurrentTier = 1
	tSpellInfo.nMaxTier = nMaxThresholds
	tSpellInfo.eCastMethod = eCastMethod
	tSpellInfo.strName = splObject:GetName()
	tSpellInfo.icon = splObject:GetIcon()
	tSpellInfo.castOverride = splObject:GetCastTimeOverride() or splObject:GetCastTime()
	
	luaSpecialCastbar.tMultitap:Hide()
	luaSpecialCastbar.tCharged:Hide()
	
	if eCastMethod == Spell.CodeEnumCastMethod.RapidTap then
		luaSpecialCastbar.tMultitap:CreateMultitap(tSpellInfo)
	elseif eCastMethod == Spell.CodeEnumCastMethod.ChargeRelease then
		luaSpecialCastbar.tCharged:CreateCharged(tSpellInfo)
	elseif eCastMethod == Spell.CodeEnumCastMethod.PressHold then
		Print("[PotatoUI] PressHold found for \""..tSpellInfo.strName.."\" - Leave a comment on Curse!")
	end
end

function PotatoCastbars:OnUpdateSpellThreshold(idSpell, nNewThreshold) -- Updates when P/H/R changes tier or RT tap is performed
	--Print("OUST")
	if self.nCurrentSpecialId == nil or idSpell ~= self.nCurrentSpecialId then return end
	
	local luaSpecialCastbar = self.luaSpecialCastbar
	
	local eCastMethod = GameLib.GetSpell(idSpell):GetCastMethod()
	if eCastMethod == Spell.CodeEnumCastMethod.RapidTap then
		luaSpecialCastbar.tMultitap:UpdateMultitap(nNewThreshold)
	elseif eCastMethod == Spell.CodeEnumCastMethod.ChargeRelease then
		luaSpecialCastbar.tCharged:UpdateCharged(nNewThreshold)
	elseif eCastMethod == Spell.CodeEnumCastMethod.PressHold then
		Print("[PotatoUI] PressHold found for \""..tSpellInfo.strName.."\" - Leave a comment on Curse!")
	end
end

function PotatoCastbars:OnClearSpellThreshold(idSpell)
	--Print("OCST")
	if self.nCurrentSpecialId ~= nil and idSpell ~= self.nCurrentSpecialId then return end -- different spell got loaded up before the previous was cleared. this is valid.
		
	self.luaSpecialCastbar.tMultitap:DestroyMultitap()
	self.luaSpecialCastbar.tCharged:DestroyCharged()
	
	if not editorMode then
		self.luaSpecialCastbar.wndCastbar:Show(false)
	end

	self.nCurrentSpecialId = nil
end

function PotatoCastbars:ResetAll()
	for key, val in pairs(Defaults) do
		if type(val) == "table" and key ~= "__index" and string.find(key, "lua") then
			self[key].wndCastbar:Destroy()
			self[key] = nil
			
			self[key] = Castbar:new(val)
			self[key]:Init(self)
		end
	end
end

function PotatoCastbars:RemoveSystems(var)
	local t = {}
	
	if type(var) ~= "table" then
		return var
	end
	
	for key, val in pairs(var) do
		if key ~= "luaCastbarSystem" and key ~= "luaParentSystem" then
			t[key] = self:RemoveSystems(val)
		end
	end
	
	return t
end

function PotatoCastbars:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.xmlDoc = nil
	self.maxCCTime = nil
	
	local tSaveData = {}

    for key,val in pairs(self) do
		if type(val) == "table" and val.luaCastbarSystem then	--Is a castbar.
			tSaveData[key] = self:RemoveSystems(val)
			tSaveData[key].anchors = {val.wndCastbar:GetAnchorPoints()}
			tSaveData[key].offsets = {val.wndCastbar:GetAnchorOffsets()}
		else													--Is any other variable.
			tSaveData[key] = val
		end
	end

	return tSaveData
end

function PotatoCastbars:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
    for key,val in pairs(tData) do
		self[key] = TableUtil:Copy(val)
	end
	
	self.bLoaded = true
end

-----------------------------------------------------------------------------------------------
-- Castbar Functions
-----------------------------------------------------------------------------------------------
function Castbar:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Castbar:Init(luaCastbarSystem)
	Apollo.LinkAddon(luaCastbarSystem, self)
	self.luaCastbarSystem = luaCastbarSystem	
	
	self.wndCastbar = Apollo.LoadForm(luaCastbarSystem.xmlDoc, "Castbar", "FixedHudStratum", self)

	self.unitLastTarget = nil
	self.maxCCTime = 0
	
	self:Position(self.anchors, self.offsets)
	self:FitCastIconToBar(self.wndCastbar)
	self:UpdateCastbarAppearance()
end

function Castbar:OnPRFReset()
	self:Reset()
end

function Castbar:CreateEditorDummy()
	self.wndCastbar:FindChild("CastProgress"):SetMax(1)
	self.wndCastbar:FindChild("CastProgress"):SetProgress(0.75)
	
	if self.name == "Special Castbar" then
		self.tCharged:CreateEditorDummy()
	else
		for _, strTextLoc in pairs(ktPos) do
			local nType = self[strTextLoc].type
			self.wndCastbar:FindChild(strTextLoc):SetText(ktSpecialTextType[nType][2])
		end
	end
end

function Castbar:UpdateCastbarAppearance() --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	--Positioning
	--self:Position(self.anchors, self.offsets)
	
	--Background and Border
	self.wndCastbar:FindChild("Content"):SetStyle("Picture", self.background.show)
	PotatoLib:UpdateBorder(self.wndCastbar, self.wndCastbar:FindChild("Content"), self.border)

	--Icon Visibility + Castbar Positioning
	local nLeft, nRight = self.showIcon == 1 and self.wndCastbar:GetHeight() or 0, self.showIcon == 2 and -self.wndCastbar:GetHeight() or 0
	local nBorder = self.border.size
	self.wndCastbar:FindChild("Icon"):SetAnchorOffsets(0, 0, nLeft-nBorder*2, 0)
	self.wndCastbar:FindChild("Icon"):Show(self.showIcon ~= 3)
	self.wndCastbar:FindChild("CastContent"):SetAnchorOffsets(nLeft-nBorder*2+nBorder, 0, nRight, 0)
	
	--Bar Appearances
	PotatoLib:SetBarAppearance2(self.wndCastbar:FindChild("CastProgress"), self.texture, self.color, self.transparency)
	self.wndCastbar:FindChild("CastProgress"):SetStyleEx("BRtoLT", self.barGrowth == 2)
	
	--Text
	PotatoLib:SetBarFonts(self.wndCastbar:FindChild("Text"), self)
	
	PotatoLib:SetBarSprite(self.wndCastbar:FindChild("Vulnerability"), self.texture)
end

function Castbar:Position(tAnchors, tOffsets)
	self.wndCastbar:SetAnchorPoints(unpack(tAnchors))
	self.wndCastbar:SetAnchorOffsets(unpack(tOffsets))
	--Print(string.format("%s: %s, %s, %s, %s", self.name, unpack(self.offsets)))
end

function Castbar:SetTarget(unitTarget)
	self.unitTarget = unitTarget
	self:UpdateCastbarStats()
end

function Castbar:UpdateCastbarStats() -- [CONTINUALLY UPDATED]
	local unitTarget = self.unitTarget
	
	if unitTarget ~= nil and ((unitTarget:IsCasting() and unitTarget:ShouldShowCastBar()) or unitTarget:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)> 0) then
		local nElapsed = unitTarget:GetCastElapsed()/1000
		local nDuration = unitTarget:GetCastDuration()/1000
		local nCCTime = unitTarget:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability)
		local strSpellName = unitTarget:GetCastName()

		self.wndCastbar:Show(true)
		
		if self.showIcon < 3 then
			local strSprite = self:GetIconFromSpellName(strSpellName)
			self.wndCastbar:FindChild("Icon"):SetSprite(strSprite ~= "" and strSprite or "PotatoSprites:BlackRowsdower")
		end
		self.wndCastbar:FindChild("CastProgress"):SetMax(nDuration)
		self.wndCastbar:FindChild("CastProgress"):SetProgress(nElapsed)
		
		if nCCTime > 0  then
			self.maxCCTime = nCCTime > self.maxCCTime and nCCTime or self.maxCCTime
			self.wndCastbar:FindChild("Vulnerability"):SetProgress(nCCTime)
			self.wndCastbar:FindChild("Vulnerability"):SetMax(self.maxCCTime)
			for _, strTextLoc in pairs(ktPos) do
				local strText = ""
				if self[strTextLoc].type == 1 then --Ability Name - TODO: Move to static update.
					strText = self.prevCast .. " (MoO)"
				elseif self[strTextLoc].type == 2 then --Detailed (1.1/5.5)
					strText = string.format("%.1f/%.1f", nCCTime, self.maxCCTime)
				elseif self[strTextLoc].type == 3 then --Shortened (1.1)
					strText = string.format("%.1f", nCCTime)
				elseif self[strTextLoc].type == 4 then --Percent
					strText = string.format("%s%%", math.floor((nCCTime/self.maxCCTime)*100))
				end
				
				self.wndCastbar:FindChild(strTextLoc):SetText(strText)
			end
		else
			if self.maxCCTime ~= 0 then
				self.wndCastbar:FindChild("Vulnerability"):SetProgress(0)
				self.wndCastbar:FindChild("Vulnerability"):SetMax(0)
				self.maxCCTime = 0
			end
			for _, strTextLoc in pairs(ktPos) do
				local strText = ""
				if self[strTextLoc].type == 1 then --Ability Name - TODO: Move to static update.
					strText = strSpellName
					self.prevCast = strText
				elseif self[strTextLoc].type == 2 then --Detailed (1.1/5.5)
					strText = string.format("%.1f/%.1f", nElapsed, nDuration)
				elseif self[strTextLoc].type == 3 then --Shortened (1.1)
					strText = string.format("%.1f", nElapsed)
				elseif self[strTextLoc].type == 4 then --Percent
					strText = string.format("%s%%", math.floor((nElapsed/nDuration)*100))
				end
				
				self.wndCastbar:FindChild(strTextLoc):SetText(strText)
			end
		end
	else
		self.wndCastbar:Show(bEditorMode)
	end
end

function Castbar:OnCastbarResize( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	local nBorder = self.border.size
	
	if wndHandler:FindChild("Icon"):GetWidth() ~= wndHandler:GetHeight()-nBorder*2 then
		self:FitCastIconToBar(wndHandler)
	end
end

function Castbar:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)
end

function Castbar:FitCastIconToBar( wndCastbar )
	local wndIcon = wndCastbar:FindChild("Icon")
	local nHeight = wndCastbar:GetHeight()
	local nBorder = self.border.size
	wndIcon:SetAnchorOffsets(0, 0, nHeight-nBorder*2, 0)
	wndCastbar:FindChild("CastContent"):SetAnchorOffsets(wndIcon:IsShown() and wndIcon:GetHeight()+nBorder or 0, 0, 0, 0)
end

function Castbar:GetIconFromSpellName(strName)
	return Defaults.tSpellNameToSprite[strName] or ""
end

---------------------------------------------------------------------------------------------------
-- Editor Functions  --TODO: Try to merge in PLib somehow.
---------------------------------------------------------------------------------------------------

function Castbar:OpenEditor()
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	if self.wndEditor then
		self.wndEditor:Destroy()
		self.wndEditor = nil
	end
	
	--Populate castbar with a dummy
	self:CreateEditorDummy()
	
	--Populate PotatoLib editor frame; Set title
	self.wndEditor = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "CastbarCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndEditor:Show(true)
	PLib.wndCustomize:FindChild("Title"):SetText(self.name .. " Settings")
	PLib.wndCustomize:Show(true)
	
	--Set frame visibility selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", self.showFrame)
	
	--Set show icon
	self.wndEditor:FindChild("ShowIcon"):FindChild("Options"):SetRadioSel("ShowCastIcon", self.showIcon)
	self.wndEditor:FindChild("ShowIcon"):FindChild("IconRight"):Enable(false)
	
	--Set background visibility and color selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("Background"):FindChild("EnableBtn"):SetCheck(self.background.show)
	self.wndEditor:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..self.background.color)
	self.wndEditor:FindChild("Background"):FindChild("HexText"):SetText(self.background.color)
	
	--Set border visibility and color selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("Border"):FindChild("EnableBtn"):SetCheck(self.border.show)
	self.wndEditor:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("HexText"):SetText(self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(self.border.size)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueUp"):Enable(self.border.size ~= 20)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueDown"):Enable(self.border.size ~= 1)
	
	local wndCastbarOpts = self.wndEditor:FindChild("Castbar")
	
	--Set bar fill direction
	wndCastbarOpts:FindChild("BarGrowth"):FindChild("Options"):SetRadioSel("BarGrowth", self.barGrowth)
	
	--Set texture
	PotatoLib:SetSprite(wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"),self.texture)
	wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(self.texture == "WhiteFill" and "Flat" or self.texture)
	wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..self.color)
	
	--Set color and transparency
	wndCastbarOpts:FindChild("Color"):SetBGColor("FF"..self.color)
	wndCastbarOpts:FindChild("HexText"):SetText(self.color)
	wndCastbarOpts:FindChild("Transparency"):SetValue(self.transparency)
	wndCastbarOpts:FindChild("TransAmt"):SetText(self.transparency.."%")
	
	--Set text options
	wndCastbarOpts:FindChild("TextOptions"):SetData("regular")
	PotatoLib:PopulateTextOptions(wndCastbarOpts, self, ktSpecialTextType)
	
	--Set position options
	local nX1, nY1, nX2, nY2 = self.wndCastbar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCastbar:GetAnchorPoints()
	
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
function Castbar:OnShowChange( wndHandler, wndControl )
	local nShow = wndHandler:GetParent():GetRadioSel("ShowFrame")
	self.showFrame = nShow
	
	self:UpdateCastbarAppearance()
end

function Castbar:OnChangeCastIcon( wndHandler, wndControl, eMouseButton )
	local nShow = wndHandler:GetParent():GetRadioSel("ShowCastIcon")
	self.showIcon = nShow
	
	self:UpdateCastbarAppearance()
end

function Castbar:OnChangeBG( wndHandler, wndControl, eMouseButton )
	local bCheck = wndHandler:IsChecked()	
	self.background.show = bCheck
	
	self:UpdateCastbarAppearance()
end


function Castbar:IncrementBorderSize( wndHandler, wndControl, eMouseButton )
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
	
	self:UpdateCastbarAppearance()
end

function Castbar:OnShowBorder( wndHandler, wndControl, eMouseButton )
	local bCheck = wndHandler:IsChecked()
	self.border.show = bCheck
	
	self:UpdateCastbarAppearance()
end

--Castbar sub-editor functions
function Castbar:OnChangeGrowth( wndHandler, wndControl, eMouseButton ) --TODO: Migrate to PLib
	local nGrowth = wndHandler:GetParent():GetRadioSel("BarGrowth")
	self.barGrowth = nGrowth
	
	self:UpdateCastbarAppearance()
end

function Castbar:BarTextureScroll( wndHandler, wndControl ) --TODO: Migrate to PLib
	local ktTextures = PotatoLib.ktTextures
	
	local nCurrBar = ktTextures[self.texture]

	if wndHandler:GetName() == "RightScroll" then
		nCurrBar = nCurrBar == #ktTextures and 1 or (nCurrBar + 1)
	elseif wndHandler:GetName() == "LeftScroll" then
		nCurrBar = nCurrBar == 1 and #ktTextures or (nCurrBar - 1)
	end
	
	local strTexture = ktTextures[nCurrBar]

	--Set data value
	self.texture = strTexture
	
	--Set editor window
	wndHandler:GetParent():FindChild("CurrentVal"):SetSprite(strTexture)
	wndHandler:GetParent():FindChild("CurrentVal"):SetText(nCurrBar == ktTextures["WhiteFill"] and "Flat" or strTexture)
	
	self:UpdateCastbarAppearance()
end

function Castbar:OnSetBarColor(wndHandler)
	PotatoLib:ColorPicker("color", self, self.UpdateCastbarAppearance, wndHandler)
end

function Castbar:TransSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	self.transparency = math.floor(fNewValue)

	--Set editor window
	wndHandler:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
	
	self:UpdateCastbarAppearance()
end

function Castbar:TextOptScroll( wndHandler, wndControl )
	local strTextLoc = wndControl:GetParent():GetParent():GetName()	
	
	PotatoLib:TextOptScroll(wndHandler, ktTextType, self)

	self.wndCastbar:FindChild(strTextLoc):SetText(ktTextType[self[strTextLoc].type][2])
end

function Castbar:FontScroll( wndHandler, wndControl )
	PotatoLib:FontScroll(wndHandler, self)
	self:UpdateCastbarAppearance()
end

function Castbar:IncrementFontSize( wndHandler, wndControl, eMouseButton )
	PotatoLib:IncrementFontSize(wndHandler, self)
	self:UpdateCastbarAppearance()
end

function Castbar:OnTxtWeight( wndHandler, wndControl, eMouseButton )
	PotatoLib:ChangeTxtWeight(wndHandler, self)
	self:UpdateCastbarAppearance()
end

function Castbar:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndCastbar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCastbar:GetAnchorPoints()

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
			self.wndCastbar:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
		elseif strChange == "YPos" then
			self.wndCastbar:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
		end
		PLib:MoveLockedWnds(self.wndCastbar)
	end

	wndHandler:SetText(strPos)
	wndHandler:SetSel(#strPos,#strPos)
end

function Castbar:TxtHWChanged( wndHandler, wndControl, strHW )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndCastbar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCastbar:GetAnchorPoints()
	
	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 1 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		self.wndCastbar:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		self.wndCastbar:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
	
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end

---------------------------------------------------------------------------------------------------
-- SpecialCastbar Functions
---------------------------------------------------------------------------------------------------

function Castbar:OpenSpecialEditor()
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	if self.wndEditor then
		self.wndEditor:Destroy()
		self.wndEditor = nil
	end
	
	--Populate PotatoLib editor frame; Set title
	self.wndEditor = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "SpecialCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndEditor:Show(true)
	PLib.wndCustomize:FindChild("Title"):SetText(self.name .. " Settings")
	PLib.wndCustomize:Show(true)
	
	local tMultitap = self.tMultitap
	local tCharged = self.tCharged
	
	local wndMultitapOpts = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "MultitapOptions", self.wndEditor:FindChild("OptionsChoice"), tMultitap)
	local wndChargedOpts = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "ChargedOptions", self.wndEditor:FindChild("OptionsChoice"), tCharged)
	
	--Set CastProgress
		local wndCastbarOpts = self.wndEditor:FindChild("CastProgress")
		--Set texture
		PotatoLib:SetSprite(wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"),self.texture)
		wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(self.texture == "WhiteFill" and "Flat" or self.texture)
		wndCastbarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..self.color)
		
		--Set color and transparency
		wndCastbarOpts:FindChild("Color"):SetBGColor("FF"..self.color)
		wndCastbarOpts:FindChild("HexText"):SetText(self.color)
		wndCastbarOpts:FindChild("Transparency"):SetValue(self.transparency)
		wndCastbarOpts:FindChild("TransAmt"):SetText(self.transparency.."%")
	
	--Set up Multibar/Charged selection and default to charged.
	local wndBarSelection = self.wndEditor:FindChild("BarSelection")
	wndBarSelection:FindChild("Charged"):AttachWindow(wndChargedOpts)
	wndBarSelection:FindChild("Multitap"):AttachWindow(wndMultitapOpts)
	self.wndEditor:FindChild("BarSelection"):SetData("charged")
	self.tMultitap:Hide()
	self.tCharged.wndCharged:Show(true)
	self.tCharged:CreateEditorDummy()
	--self.wndCastbar:FindChild("CastProgress"):SetProgress(0.75)
	
	--Set frame visibility selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", self.showFrame)
	
	--Set show icon
	self.wndEditor:FindChild("ShowIcon"):FindChild("Options"):SetRadioSel("ShowCastIcon", self.showIcon)
	self.wndEditor:FindChild("ShowIcon"):FindChild("IconRight"):Enable(false)
	
	--Set background visibility and color selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("Background"):FindChild("EnableBtn"):SetCheck(self.background.show)
	self.wndEditor:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..self.background.color)
	self.wndEditor:FindChild("Background"):FindChild("HexText"):SetText(self.background.color)
	
	--Set border visibility and color selected from tFrames[idx].castbarData
	self.wndEditor:FindChild("Border"):FindChild("EnableBtn"):SetCheck(self.border.show)
	self.wndEditor:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("HexText"):SetText(self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(self.border.size)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueUp"):Enable(self.border.size ~= 20)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueDown"):Enable(self.border.size ~= 1)
	
	-----------Multi-Tap--------------------------------------------------------
	--wndMultitapOpts:FindChild("Header1"):FindChild("Button"):ChangeArt("CRB_Basekit:kitBtn_ScrollHolo_UpLarge")
	--wndMultitapOpts:SetAnchorOffsets(0, 0, 0, 30)
	
	--Set texture
	PotatoLib:SetSprite(wndMultitapOpts:FindChild("BarTexture"):FindChild("CurrentVal"), tMultitap.texture)
	wndMultitapOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(tMultitap.texture == "WhiteFill" and "Flat" or tMultitap.texture)
	wndMultitapOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..tMultitap.color)
	
	--Set color and transparency
	wndMultitapOpts:FindChild("Color"):SetBGColor("FF"..tMultitap.color)
	wndMultitapOpts:FindChild("HexText"):SetText(tMultitap.color)
	wndMultitapOpts:FindChild("Transparency"):SetValue(tMultitap.transparency)
	wndMultitapOpts:FindChild("TransAmt"):SetText(tMultitap.transparency.."%")
	PotatoLib:PopulateTextOptions(wndMultitapOpts, tMultitap, ktSpecialTextType)
	--self.wndEditor:ArrangeChildrenVert(0)

	---------Charged Cast--------------------------------------------------------
	local wndChargedOpts = self.wndEditor:FindChild("ChargedOptions")
	
	--Set show first
	wndChargedOpts:FindChild("ShowFirst"):FindChild("Options"):SetRadioSel("ShowFirst", tCharged.showFirst and 1 or 2)
	
	--Set texture
	PotatoLib:SetSprite(wndChargedOpts:FindChild("BarTexture"):FindChild("CurrentVal"),tCharged.texture)
	wndChargedOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(tCharged.texture == "WhiteFill" and "Flat" or tCharged.texture)
	
	--Set color and transparency
	local tChargedColors = {
		"Charging",
		"Charged",
		"Background"
	}
	for idx=1, #tChargedColors do
		local wndCurrOpts = wndChargedOpts:FindChild(tChargedColors[idx])
		wndCurrOpts:FindChild("Color"):SetBGColor("FF"..tCharged["color"..tChargedColors[idx]])
		wndCurrOpts:FindChild("HexText"):SetText(tCharged["color"..tChargedColors[idx]])
		wndCurrOpts:FindChild("Transparency"):SetValue(tCharged["trans"..tChargedColors[idx]])
		wndCurrOpts:FindChild("TransAmt"):SetText(tCharged["trans"..tChargedColors[idx]].."%")
	end
	
	--Set text options
	wndChargedOpts:FindChild("TextOptions"):SetData("charged")
	PotatoLib:PopulateTextOptions(wndChargedOpts, tCharged, ktSpecialTextType)
	
	--Arrange settings
	--self.wndEditor:ArrangeChildrenVert(0)
	
	--Set position options
	local nX1, nY1, nX2, nY2 = self.wndCastbar:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndCastbar:GetAnchorPoints()
	
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

function Castbar:ChangeSpecialSelection( wndHandler, wndControl, eMouseButton )
	local strSpecial = wndHandler:GetName()
	
	self.tCharged:Hide()
	self.tMultitap:Hide()
	self["t"..strSpecial]["wnd"..strSpecial]:Show(true)
	self["t"..strSpecial]:CreateEditorDummy()
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------
function Castbar:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
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

function Castbar:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if self.name == "Special Castbar" then
		self:OpenSpecialEditor()
	else
		self:OpenEditor()
	end
	
	self:SelectFrame(self.wndCastbar)
end

function Castbar:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	PotatoLib:HandleLockedWnd(self.wndCastbar, self.name)
end

function Castbar:Reset()
	local strCastbar = ""
	
	for key, val in pairs(self.luaCastbarSystem) do
		if val == self then
			strCastbar = key
			break
		end
	end
	
	for key, val in pairs(Defaults[strCastbar]) do
		if key ~= "__index" then
			self[key] = TableUtil:Copy(val)
		end
	end
	if self.name == "Special Castbar" then
		self:InitCharged()
		self:InitMultitap()
	end
	
	self:Position(self.anchors, self.offsets)
	self:UpdateCastbarAppearance()
end

function Castbar:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:Reset()
end

function Castbar:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			if self.name == "Special Castbar" then
				self:OpenSpecialEditor()
			else
				self:OpenEditor()
			end
		end
		self:SelectFrame(self.wndCastbar)
	end
end

---------------------------------------------------------------------------------------------------
-- Multitap Functions
---------------------------------------------------------------------------------------------------
function Multitap:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Multitap:Init(luaParentSystem)
	Apollo.LinkAddon(luaParentSystem, self)
	self.luaParentSystem = luaParentSystem
	self.luaCastbarSystem = luaParentSystem.luaCastbarSystem
	self.wndCastbar =  self.luaParentSystem.wndCastbar
			
	self.wndMultitap = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "Multitap", self.wndCastbar:FindChild("CastContent"), self)
	self.tiers = {}
	
	self:UpdateMultitapAppearance()
end

function Multitap:Hide()
	self.wndMultitap:Show(false)
end

function Multitap:CreateMultitap(tSpellInfo)
	self.tCurrentMultitap = tSpellInfo
	
	local wndMultitap = self.wndMultitap
	local wndCastbar = self.wndCastbar
	
	wndMultitap:Show(true)
	wndCastbar:FindChild("Icon"):SetSprite(tSpellInfo.icon)
	
	local nMax = tSpellInfo.nMaxTier

	if #self.tiers ~= nMax then
		wndMultitap:FindChild("Pieces"):DestroyChildren()
		self.tiers = {}
		
		--Create tiers
		for idx=1, nMax do
			--Tier box
			self.tiers[idx] = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "MultitapPiece", wndMultitap:FindChild("Pieces"), self)
			--Set position
			self.tiers[idx]:SetAnchorPoints((idx-1)/nMax, 0, idx/nMax, 1)
			--Set spacing
			local nLeft, nTop, nRight, nBottom = 1,0,-1,0
			if idx == 1 then
				nLeft = 0
			elseif idx == nMax then
				nRight = 0
			end
			self.tiers[idx]:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
			--Set color
			self.tiers[idx]:SetBGColor(string.format("%x", (self.transparency/100)*255)..self.color)
			--Set texture
			PotatoLib:SetSprite(self.tiers[idx], self.texture)
		end
		
		--Place static text
		local wndText = wndMultitap:FindChild("Text")
		
		for _, strTextPos in pairs(ktPos) do
			if self[strTextPos].type == 1 then --Spell name
				wndText:FindChild(strTextPos):SetText(tSpellInfo.strName)
			elseif self[strTextPos].type == 3 then --Maximum
				wndText:FindChild(strTextPos):SetText(tSpellInfo.nMaxTier)
			end
		end
		
		--Set cast progress (time left)
		wndCastbar:FindChild("CastProgress"):SetMax(1)
		--PotatoLib:SetBarSprite(wndCastbar:FindChild("CastProgress"), self.texture) --TODO: I think this can be omitted.
	end
	
	self:UpdateMultitap(tSpellInfo.nCurrentTier)
end

function Multitap:UpdateMultitap(nCurr)
	if not self.wndCastbar:IsShown() then
		self.wndCastbar:Show(true, true)
	end
	
	--Update tiers.
	if self.tCurrentMultitap and self.tiers then
		self.tCurrentMultitap.nCurrentTier = nCurr
		
		if self.tiers[nCurr] then
			self.tiers[nCurr]:Show(true)
		end
		
		--Update dynamic text.
		local wndText = self.wndMultitap:FindChild("Text")
		
		for _, strTextPos in pairs(ktPos) do
			if self[strTextPos].type == 2 then --Current (3)
				wndText:FindChild(strTextPos):SetText(nCurr)
			elseif self[strTextPos].type == 4 then --Progress (3/4)
				wndText:FindChild(strTextPos):SetText(nCurr.."/"..self.tCurrentMultitap.nMaxTier)
			end
		end
	end
end

function Multitap:UpdateTimeLeft()
	if self.tCurrentMultitap then
		local fTimeLeft = 1-GameLib.GetSpellThresholdTimePrcntDone(self.tCurrentMultitap.id)
		self.wndCastbar:FindChild("CastProgress"):SetProgress(fTimeLeft)
	end
end

function Multitap:DestroyMultitap(nCurr)
	for _, wnd in pairs(self.tiers) do
		wnd:Show(false)
	end
end

function Multitap:UpdateMultitapAppearance()
	local wndCastbar = self.wndCastbar
	local wndMultitap = self.wndMultitap
	
	--Text
	local wndText = self.wndMultitap:FindChild("Text")
	for _,strTextPos in pairs(ktPos) do
		wndText:FindChild(strTextPos):SetText(ktSpecialTextType[self[strTextPos].type][2])
	end
	PotatoLib:SetBarFonts(wndMultitap:FindChild("Text"), self)
	
	--Update dummy
	self:CreateEditorDummy()
	
	--Force update of tiers by setting tiers to nil.
	self.tiers = {}
end

--------------------------------------
-- Editor Functions
--------------------------------------

function Multitap:CreateEditorDummy()
	self.wndMultitap:Show(true)
	
	--Remove previous tiers.
	self.wndMultitap:FindChild("Pieces"):DestroyChildren()
	self.tiers = {}
	
	--Place dummies.
	for idx=1, 2 do
		self.tiers[idx] = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "MultitapPiece", self.wndMultitap:FindChild("Pieces"), self) --Tier box
		self.tiers[idx]:SetAnchorPoints((idx-1)/4, 0, idx/4, 1) --Set position
		self.tiers[idx]:SetAnchorOffsets(idx == 1 and 0 or 1, 0, -1, 0) --Set spacing
		self.tiers[idx]:SetBGColor(string.format("%x", (self.transparency/100)*255)..self.color) --Set color
		PotatoLib:SetSprite(self.tiers[idx], self.texture) --Set texture
		
		self.tiers[idx]:Show(true)
	end
	
	--Update text.
	--self.tCurrentMultitap = nil --To force update of tiers after editing.
end

function Multitap:FontScroll( wndHandler, wndControl )
	PotatoLib:FontScroll(wndHandler, self)
	self:UpdateMultitapAppearance()
end

function Multitap:IncrementFontSize( wndHandler, wndControl, eMouseButton )
	PotatoLib:IncrementFontSize(wndHandler, self)
	self:UpdateMultitapAppearance()
end

function Multitap:TextOptScroll( wndHandler, wndControl )
	local strTextLoc = wndControl:GetParent():GetParent():GetName()	
	
	PotatoLib:TextOptScroll(wndHandler, ktSpecialTextType, self)

	self.wndMultitap:FindChild(strTextLoc):SetText(ktSpecialTextType[self[strTextLoc].type][2])
end

function Multitap:OnTxtWeight( wndHandler, wndControl, eMouseButton )
	PotatoLib:ChangeTxtWeight(wndHandler, self)
	self:UpdateMultitapAppearance()
end

function Multitap:OnSetBarColor( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	PotatoLib:ColorPicker("color", self, self.UpdateMultitapAppearance, wndHandler)
end

function Multitap:TransSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	self.transparency = math.floor(fNewValue)

	--Set editor window
	wndHandler:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
	
	self:UpdateMultitapAppearance()
end
---------------------------------------------------------------------------------------------------
-- Charged Functions
---------------------------------------------------------------------------------------------------
function Charged:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function Charged:Init(luaParentSystem)
	Apollo.LinkAddon(luaParentSystem, self)
	self.luaParentSystem = luaParentSystem
	self.luaCastbarSystem = luaParentSystem.luaCastbarSystem
	self.wndCastbar =  self.luaParentSystem.wndCastbar
			
	self.wndCharged = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "Charged", self.wndCastbar:FindChild("CastContent"), self)
	self.tiers = {}
	
	self:UpdateChargedAppearance()
end

function Charged:Hide()
	self.wndCharged:Show(false)
end

function Charged:CreateCharged(tSpellInfo)
	self.tCurrentCharged = tSpellInfo
	
	local wndCharged = self.wndCharged
	local wndCastbar = self.wndCastbar
	
	wndCharged:Show(true)
	wndCastbar:FindChild("Icon"):SetSprite(tSpellInfo.icon)
	
	local nMax = tSpellInfo.nMaxTier
		
	local nOffset = self.showFirst and 0 or 1
			
	if #self.tiers ~= nMax-nOffset then
		wndCharged:FindChild("Pieces"):DestroyChildren()
		self.tiers = {}
		
		--Create tiers
		for idx=1, nMax-nOffset do
			--Tier box
			self.tiers[idx] = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "ChargedPiece", wndCharged:FindChild("Pieces"), self)
			self.tiers[idx]:SetMax(1)
			--Set position
			self.tiers[idx]:SetAnchorPoints((idx-1)/(nMax-nOffset), 0, idx/(nMax-nOffset), 1)
			--Set spacing
			local nLeft, nTop, nRight, nBottom = 1,0,-1,0
			if idx == 1 then
				nLeft = 0
			elseif idx == nMax then
				nRight = 0
			end
			self.tiers[idx]:SetAnchorOffsets(nLeft,nTop,nRight,nBottom)
			--Set color
			self.tiers[idx]:SetBGColor(string.format("%x", (self.transBackground/100)*255)..self.colorBackground)
			self.tiers[idx]:SetBarColor(string.format("%x", (self.transCharging/100)*255)..self.colorCharging)
			--Set texture
			PotatoLib:SetBarSprite(self.tiers[idx], self.texture)
		end
		if self.showFirst then
			self.tiers[1]:SetProgress(1)
		end
				
		--Place static text
		local wndText = wndCharged:FindChild("Text")
		
		for _, strTextPos in pairs(ktPos) do
			if self[strTextPos].type == 1 then --Spell name
				wndText:FindChild(strTextPos):SetText(tSpellInfo.strName)
			elseif self[strTextPos].type == 3 then --Maximum
				wndText:FindChild(strTextPos):SetText(tSpellInfo.nMaxTier)
			end
		end
		
		--Set cast progress (time left)
		wndCastbar:FindChild("CastProgress"):SetMax(self:GetChargedMaxByName(tSpellInfo.strName))
		--PotatoLib:SetBarSprite(wndCastbar:FindChild("CastProgress"), self.texture) --TODO: I think this can be omitted.
	end
	
	self:UpdateCharged(tSpellInfo.nCurrentTier)
end

function Charged:GetChargedMaxByName(strName)
	if type(ktChargedMaxes[strName]) ~= "table" then
		return ktChargedMaxes[strName]
	else
		if GameLib.IsSpellSurgeActive() then
			return ktChargedMaxes[strName][1]
		else
			return ktChargedMaxes[strName][2]
		end
	end	
end

function Charged:UpdateCharged(nCurr)
	if not self.wndCastbar:IsShown() then
		self.wndCastbar:Show(true, true)
	end
	
	if self.tCurrentCharged and self.tiers then
		self.tCurrentCharged.nCurrentTier = nCurr
		
		--Update tiers.
		local nOffset = self.showFirst and 0 or 1
		
		if self.tiers[nCurr-nOffset] then
			for idx=1, nCurr-nOffset do
				self.tiers[idx]:SetProgress(1)
				PotatoLib:SetBarAppearance2(self.tiers[idx], self.texture, self.colorCharged, self.transCharged)
			end
		end
		
		--Update dynamic text.
		local wndText = self.wndCharged:FindChild("Text")
		
		for _, strTextPos in pairs(ktPos) do
			if self[strTextPos].type == 2 then --Current (3)
				wndText:FindChild(strTextPos):SetText(nCurr)
			elseif self[strTextPos].type == 4 then --Progress (3/4)
				wndText:FindChild(strTextPos):SetText(nCurr.."/"..self.tCurrentCharged.nMaxTier)
			end
		end
	end
end

function Charged:UpdateProgress()
	local nOffset = self.showFirst and 1 or 0
	if self.tCurrentCharged then
		local nCurr = self.tCurrentCharged.nCurrentTier
		local fTimeLeft = GameLib.GetSpellThresholdTimePrcntDone(self.tCurrentCharged.id)
		
		if self.tiers[nCurr+nOffset] then
			self.tiers[nCurr+nOffset]:SetProgress(fTimeLeft)
		end
	end
end

function Charged:UpdateTimeLeft()
	self.wndCastbar:FindChild("CastProgress"):SetProgress(GameLib.GetPlayerUnit():GetCastElapsed())
end

function Charged:DestroyCharged(nCurr)
	for idx=1, #self.tiers do	
		self.tiers[idx]:SetProgress(0)
		self.tiers[idx]:SetBarColor(string.format("%x", (self.transCharging/100)*255)..self.colorCharging)
	end
end

function Charged:UpdateChargedAppearance()
	local wndCastbar = self.wndCastbar
	local wndCharged = self.wndCharged
	
	--Text
	local wndText = self.wndCharged:FindChild("Text")
	for _,strTextPos in pairs(ktPos) do
		wndText:FindChild(strTextPos):SetText(ktSpecialTextType[self[strTextPos].type][2])
	end
	PotatoLib:SetBarFonts(wndCharged:FindChild("Text"), self)
	
	--Update dummy
	self:CreateEditorDummy()
	
	--Force update of tiers by setting tiers to nil.
	self.tiers = {}
end

--------------------------------------
-- Editor Functions
--------------------------------------

function Charged:CreateEditorDummy()
	self.wndCharged:Show(true)

	--Remove previous tiers.
	self.wndCharged:FindChild("Pieces"):DestroyChildren()
	self.tiers = {}
	
	local nMax = 4
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer ~= nil and unitPlayer:GetClassId() == GameLib.CodeEnumClass.Esper then
		nMax = 3
	end
	
	--Place dummies.
	local nOffset = self.showFirst and 0 or 1
	local ktTarget = {
		[1] = "Charged",
		[2] = "Charging",
		[3] = "Background",
		[4] = "Background"
	}
	
	for idx=1, nMax-nOffset do
		--Tier box
		self.tiers[idx] = Apollo.LoadForm(self.luaCastbarSystem.xmlDoc, "ChargedPiece", self.wndCharged:FindChild("Pieces"), self)
		self.tiers[idx]:SetMax(1)
		if idx == 1 then
			self.tiers[idx]:SetProgress(1)
		elseif idx == 2 then
			self.tiers[idx]:SetProgress(0.5)
		end
		--Set position
		self.tiers[idx]:SetAnchorPoints((idx-1)/(nMax-nOffset), 0, idx/(nMax-nOffset), 1)
		--Set spacing
		local nLeft, nTop, nRight, nBottom = 1,0,-1,0
		if idx == 1 then
			nLeft = 0
		elseif idx == nMax then
			nRight = 0
		end
		self.tiers[idx]:SetAnchorOffsets(nLeft,nTop,nRight,nBottom)
		--Set color

		--self.tiers[idx]:SetBGColor(string.format("%x", (self["trans"..ktTarget[idx]]/100)*255)..self["color"..ktTarget[idx]]) --Background
		--self.tiers[idx]:SetBarColor(string.format("%x", (self["trans"..ktTarget[idx]]/100)*255)..self["color"..ktTarget[idx]]) --Bar
		PotatoLib:SetBarAppearance2(self.tiers[idx], self.texture, self["color"..ktTarget[idx]], self["trans"..ktTarget[idx]]) --TODO: Work
	end
	
	self.tCurrentCharged = nil --To force update of tiers after editing.
end

function Charged:OnChangeShowFirst( wndHandler, wndControl, eMouseButton )
	self.showFirst = wndHandler:GetParent():GetRadioSel("ShowFirst") == 1
	
	self:UpdateChargedAppearance()
end

function Charged:FontScroll( wndHandler, wndControl )
	PotatoLib:FontScroll(wndHandler, self)
	self:UpdateChargedAppearance()
end

function Charged:IncrementFontSize( wndHandler, wndControl, eMouseButton )
	PotatoLib:IncrementFontSize(wndHandler, self)
	self:UpdateChargedAppearance()
end

function Charged:TextOptScroll( wndHandler, wndControl )
	local strTextLoc = wndControl:GetParent():GetParent():GetName()	

	PotatoLib:TextOptScroll(wndHandler, ktSpecialTextType, self)

	self.wndCharged:FindChild(strTextLoc):SetText(ktSpecialTextType[self[strTextLoc].type][2])
end

function Charged:OnTxtWeight( wndHandler, wndControl, eMouseButton )
	PotatoLib:ChangeTxtWeight(wndHandler, self)
	self:UpdateChargedAppearance()
end

function Charged:OnSetChargingColor( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	PotatoLib:ColorPicker("colorCharging", self, self.UpdateChargedAppearance, wndHandler)
end

function Charged:OnSetChargedColor( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	PotatoLib:ColorPicker("colorCharged", self, self.UpdateChargedAppearance, wndHandler)
end

function Charged:TransSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	local strColorType = wndHandler:GetParent():GetParent():GetName()
	
	self["trans"..strColorType] = math.floor(fNewValue)

	--Set editor window
	wndHandler:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
	
	self:UpdateChargedAppearance()
end

-----------------------------------------------------------------------------------------------
-- PotatoCastbars Instance
-----------------------------------------------------------------------------------------------
local PotatoCastbarsInst = PotatoCastbars:new()
PotatoCastbarsInst:Init()
