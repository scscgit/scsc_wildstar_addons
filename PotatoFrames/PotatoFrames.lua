-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoFrames
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
 --TODO: Modulate into object based form like Castbars, Buffs, etc. for even more performance.
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoFrames Module Definition
-----------------------------------------------------------------------------------------------
local PotatoFrames = {} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local bEditorMode = false
--local showPortrait = true
--local showIcons = true
local bHovering = false
local daCColor =  CColor.new(0, 0, 1, 1)
local bPetClass = false

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PotatoFrames:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoFrames:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = { "PotatoLib", "Util" }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

local kstrRaidMarkerToSprite =
{
	"Icon_Windows_UI_CRB_Marker_Bomb",
	"Icon_Windows_UI_CRB_Marker_Ghost",
	"Icon_Windows_UI_CRB_Marker_Mask",	
	"Icon_Windows_UI_CRB_Marker_Octopus",
	"Icon_Windows_UI_CRB_Marker_Pig",
	"Icon_Windows_UI_CRB_Marker_Chicken",
	"Icon_Windows_UI_CRB_Marker_Toaster",
	"Icon_Windows_UI_CRB_Marker_UFO",
	[0] = ""
}

local ktArchetypes = {
	["Guard"] = {name="Guard", description="These NPCs have high defenses."},
	["Townie"] = {name="Townie", description="Generally non-aggressive NPCs that won't attack unless provoked."},
	["Bruiser"] = {name="Bruiser", description="These NPC primarily use attacks with CC effects."},
	["Tank"] = {name="Tank", description="These NPCs will attempt to have you focus your attacks on them."},
	["OffensiveHealer"] = {name="Offensive Healer", description="These NPCs heal themselves through attacking, with life-steal abilities."},
	["RangedDPS"] = {name="Ranged", description="These ranged attacking NPCs will usually not move unless out of range or line of sight."},
	["MeleeDPS"] = {name="Melee", description="These melee attacking NPCs will stay in range of their target."},
	["DefensiveHealer"] = {name="Defensive Healer", description="These NPCs primarily heal themselves and other NPCs."},
	["Vehicle"] = {name="Bruiser", description=""}
}	

local ktRoles = {
	["Commander"] = {name="Commander", description =""},
	["Controller"] = {name="Controller", description =""},
	["Guard"] = {name="Guard", description =""},
	["Healer"] = {name="Healer", description =""},
	["MeleeHeavy"] = {name="Melee Heavy", description =""},
	["MeleeLight"] = {name="Melee Light", description =""},
	["Mount"] = {name="Mount", description =""},
	["Ranged"] = {name="Ranged", description =""},
	["Summoner"] = {name="Summoner", description =""},
	["Towner"] = {name="Towner", description =""}
}
	
local ktTextures = {
	[1] = "Aluminum", Aluminum = 1,
	[2] = "Bantobar", Bantobar = 2,
	[3] = "Charcoal", Charcoal = 3,
	[4] = "Striped", Striped = 4,
	[5] = "Minimalist", Minimalist = 5,
	[6] = "Smooth", Smooth = 6,
	[7] = "Frost", Frost = 7,
	[8] = "TrueFrost", TrueFrost = 8,
	[9] = "Glaze", Glaze = 9,
	[10] = "HealBot", HealBot = 10,
	[11] = "LiteStep", LiteStep = 11,
	[12] = "Otravi", Otravi = 12,
	[13] = "Rocks", Rocks = 13,
	[14] = "Runes", Runes = 14,
	[15] = "Smudge", Smudge = 15,
	[16] = "Xeon", Xeon = 16,
	[17] = "Xus", Xus = 17,
	[18] = "Skullflower", Skullflower = 18,
	[19] = "WhiteFill", WhiteFill = 19
}
	
local ktDefaultFrames =
{
	{ name = "Player Frame", anchors = {0.5, 1, 0.5, 1}, offsets = {-370, -202,  -10, -128}, portraitType = 1, showIcons = true},
	{ name = "Target Frame", anchors = {0.5, 1, 0.5, 1}, offsets = {  10, -202,  370, -128}, portraitType = 1, showIcons = true},
	{ name = "ToT Frame", anchors = {0.5, 1, 0.5, 1}, offsets =    { 270, -300,  500, -240}, portraitType = 1, showIcons = true},
	{ name = "Focus Frame", anchors = {0.5, 0, 0.5, 0}, offsets =  {-100,  70,  100,  130}, portraitType = 1, showIcons = true},
	{ name = "Pet Frame 1", anchors = {0.5, 1, 0.5, 1}, offsets =  {-320, -300, -190, -250}, portraitType = 4, showIcons = false, colorType="customcolor", color="00FF00"},
	{ name = "Pet Frame 2", anchors = {0.5, 1, 0.5, 1}, offsets =  {-190, -300, -60, -250}, portraitType = 4, showIcons = false, colorType="customcolor", color="00FF00"},
}

local ktDefaultIcons = {
	{npcType="level", playerType="level"},
	{npcType="faction", playerType="faction"},
	{npcType="class", playerType="class"},
	{npcType="difficulty", playerType="path"}
}

local ktDifficultySprites = {
	[Unit.CodeEnumRank.Elite] = "Elite",
	[Unit.CodeEnumRank.Superior] = "Superior",
	[Unit.CodeEnumRank.Champion] = "Challenger",
	[Unit.CodeEnumRank.Standard] = "Grunt",
	[Unit.CodeEnumRank.Minion] = "Minion",
	[Unit.CodeEnumRank.Fodder] = "Fodder"
}

local ktPos = {"Left", "Mid", "Right"}

local ktTextType = {
	[0] = {"None", ""},
	[1] = {"Name", "This is a Name"},
	[2] = {"Detailed", "1100/5500"},
	[3] = {"Shortened", "1100"},
	[4] = {"Percent", "20%"},
	[5] = {"Super Short", "1.1k"},
	[6] = {"Class", "Class Name"},
	[7] = {"Level", "LV"}
}

local karConInfo =
{
	{-4, "ConTrivial", 	Apollo.GetString("TargetFrame_Trivial"), 	Apollo.GetString("TargetFrame_NoXP"), 				"ff7d7d7d"},
	{-3, "ConInferior", 	Apollo.GetString("TargetFrame_Inferior"), 	Apollo.GetString("TargetFrame_VeryReducedXP"), 		"ff01ff07"},
	{-2, "ConMinor", 		Apollo.GetString("TargetFrame_Minor"), 		Apollo.GetString("TargetFrame_ReducedXP"), 			"ff01fcff"},
	{-1, "ConEasy", 		Apollo.GetString("TargetFrame_Easy"), 		Apollo.GetString("TargetFrame_SlightlyReducedXP"), 	"ff597cff"},
	{ 0, "ConAverage", 	Apollo.GetString("TargetFrame_Average"), 	Apollo.GetString("TargetFrame_StandardXP"), 		"ffffffff"},
	{ 1, "ConModerate", 	Apollo.GetString("TargetFrame_Moderate"), 	Apollo.GetString("TargetFrame_SlightlyMoreXP"), 	"ffffff00"},
	{ 2, "ConTough", 		Apollo.GetString("TargetFrame_Tough"), 		Apollo.GetString("TargetFrame_IncreasedXP"), 		"ffff8000"},
	{ 3, "ConHard", 		Apollo.GetString("TargetFrame_Hard"), 		Apollo.GetString("TargetFrame_HighlyIncreasedXP"), 	"ffff0000"},
	{ 4, "ConImpossible", 	Apollo.GetString("TargetFrame_Impossible"), Apollo.GetString("TargetFrame_GreatlyIncreasedXP"),	"ffff00ff"}
}	

function PotatoFrames:HelperCalculateConValue(unitTarget)
	local nUnitCon = GameLib.GetPlayerUnit():GetLevelDifferential(unitTarget)
	local nCon = 1 --default setting

	if nUnitCon <= karConInfo[1][1] then -- lower bound
		nCon = 1
	elseif nUnitCon >= karConInfo[#karConInfo][1] then -- upper bound
		nCon = #karConInfo
	else
		for idx = 2, (#karConInfo-1) do -- everything in between
			if nUnitCon == karConInfo[idx][1] then
				nCon = idx
			end
		end
	end
	
	return nCon
end

local ktRankDescriptions =
{
	[Unit.CodeEnumRank.Fodder] 		= 	{Apollo.GetString("TargetFrame_Fodder"), 		Apollo.GetString("TargetFrame_VeryWeak")},
	[Unit.CodeEnumRank.Minion] 		= 	{Apollo.GetString("TargetFrame_Minion"), 		Apollo.GetString("TargetFrame_Weak")},
	[Unit.CodeEnumRank.Standard]	= 	{Apollo.GetString("TargetFrame_Grunt"), 		Apollo.GetString("TargetFrame_EasyAppend")},
	[Unit.CodeEnumRank.Champion] 	=	{Apollo.GetString("TargetFrame_Challenger"), 	Apollo.GetString("TargetFrame_AlmostEqual")},
	[Unit.CodeEnumRank.Superior] 	=  	{Apollo.GetString("TargetFrame_Superior"), 		Apollo.GetString("TargetFrame_Strong")},
	[Unit.CodeEnumRank.Elite] 		= 	{Apollo.GetString("TargetFrame_Prime"), 		Apollo.GetString("TargetFrame_VeryStrong")},
}

function PotatoFrames:HelperBuildTooltip(strBody, strTitle, crTitleColor)
	if strBody == nil then return end
	local strTooltip = string.format("<T Font=\"CRB_InterfaceMedium\" TextColor=\"%s\">%s</T>", "ffc0c0c0", strBody)
	if strTitle ~= nil then -- if a title has been passed, add it (optional)
		strTooltip = string.format("<P>%s</P>", strTooltip)
		local strTitle = string.format("<P Font=\"CRB_InterfaceMedium_B\" TextColor=\"%s\">%s</P>", crTitleColor or "ffdadada", strTitle)
		strTooltip = strTitle .. strTooltip
	end
	return strTooltip
end

-----------------------------------------------------------------------------------------------
-- PotatoFrames OnLoad
-----------------------------------------------------------------------------------------------

function PotatoFrames:OnLoad() --Loaded 1st
	PotatoLib = Apollo.GetAddon("PotatoLib")
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
	
	--Apollo.RegisterTimerHandler("FrameUpdate", 					"OnFrame", self)
	
	--Apollo.CreateTimer("FrameUpdate", 0.033, true)
	
	Apollo.RegisterSlashCommand("focus", "OnFocusSlashCommand", self)

	Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)
	Apollo.RegisterEventHandler("SystemKeyDown",				"OnSystemKeyDown", self)
	
	Apollo.RegisterEventHandler("TargetUnitChanged", 			"OnTargetUnitChanged", self)
	Apollo.RegisterEventHandler("AlternateTargetUnitChanged", 	"OnAlternateTargetUnitChanged", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 				"OnSubZoneChanged", self)	
	
	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"ResetAll", self)
	--Apollo.RegisterEventHandler("PotatoSettings",				"PopulateSettingsList", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)

	self.tFrames = {}
	self.tAccountData = {}
	
	--Build Frames
	for idx=1, #ktDefaultFrames do
		local tBuiltFrame = TableUtil:Copy(PotatoLib.frame)
		
		--Build default frame attributes	
		tBuiltFrame.name = ktDefaultFrames[idx].name
		tBuiltFrame.anchors = ktDefaultFrames[idx].anchors
		tBuiltFrame.offsets = ktDefaultFrames[idx].offsets
		tBuiltFrame.showFrame = 1
		tBuiltFrame.portraitType = ktDefaultFrames[idx].portraitType
		tBuiltFrame.showIcons = ktDefaultFrames[idx].showIcons
		tBuiltFrame.icons = TableUtil:Copy(ktDefaultIcons)
		tBuiltFrame.barStyles = TableUtil:Copy(PotatoLib.ktDefaultFramesMess)
		tBuiltFrame.border = TableUtil:Copy(PotatoLib.ktDefaultBorder)
		tBuiltFrame.background = TableUtil:Copy(PotatoLib.ktDefaultBackground)
		self.tFrames[idx] = {
			window = Apollo.LoadForm("PotatoFrames.xml", "Unitframe", "FixedHudStratum", self),

			frameData = tBuiltFrame,

		}
		
		self.tFrames[idx].window:SetData({id=idx,type="frame"})
		self.tFrames[idx].window:SetAnchorPoints(unpack(ktDefaultFrames[idx].anchors)) --TODO: may be able to be removed? Probably not, initial set of position.
		self.tFrames[idx].window:SetAnchorOffsets(unpack(ktDefaultFrames[idx].offsets)) --TODO: may be able to be removed?
	end
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	else
		Apollo.RegisterEventHandler("CharacterCreated", 		"OnCharacterCreated", self)
	end
end

function PotatoFrames:OnFocusSlashCommand()
	local unitTarget = GameLib.GetTargetUnit()
	
	GameLib.GetPlayerUnit():SetAlternateTarget(unitTarget)
end

function PotatoFrames:OnSave(eLevel) -- TODO: Optimize this code
    -- create a table to hold our data
	local tSave = {}
	local tWndData = {}
	
	for idx=1, #ktDefaultFrames do
		if self.tFrames[idx] then
			self.tFrames[idx].frameData.anchors = {self.tFrames[idx].window:GetAnchorPoints()}
			self.tFrames[idx].frameData.offsets = {self.tFrames[idx].window:GetAnchorOffsets()}
			
			tWndData[idx] = {
				frameData = self.tFrames[idx].frameData
			}
		end
	end
	
	tSave = {
		frameData = tWndData
	}
	
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
        return tSave
    elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData[self.strCharacterName] = tSave
		return self.tAccountData
	else
		return nil
	end
end

function PotatoFrames:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
	    --self.tSavedData = tData
		
		if tData then	
			for idx=1, #ktDefaultFrames do
				if tData.frameData[idx] and self.tFrames[idx] then
					local tFrameData = tData.frameData[idx].frameData
					if tFrameData and tFrameData ~= nil then
						if tFrameData.background == nil then tFrameData.background = TableUtil:Copy(PotatoLib.ktDefaultBackground) end --TODO: HACKY
						if tFrameData.border == nil then tFrameData.border = TableUtil:Copy(PotatoLib.ktDefaultBorder) end --TODO: HACKY
						if tFrameData.barStyles[4].showResBar == nil then tFrameData.barStyles[4].showResBar = true end
						
						for idx2=1, #tFrameData.barStyles do --Force into new text data format TODO: HACKY
							for key, val in pairs(tFrameData.barStyles[idx2]) do
								if key == "textLeft" or key == "textRight" or key == "textMid" then
									if type(val) ~= "table" then --If not a table, it's in old format
										local nTypePlaceholder = val
										tFrameData.barStyles[idx2][key] = TableUtil:Copy(PotatoLib.ktDefaultFramesMess[idx2][key])
										tFrameData.barStyles[idx2][key].type = nTypePlaceholder
									end
								end
							end
						end
						self.tFrames[idx].frameData = tFrameData
						
						self.tFrames[idx].window:SetAnchorPoints(unpack(tFrameData.anchors))
						self.tFrames[idx].window:SetAnchorOffsets(unpack(tFrameData.offsets))
						
						self:UpdateFrameAppearance(self.tFrames[idx].window)
							
						self:ShowBG(self.tFrames[idx].window:FindChild("Content"), tFrameData.background.show)
						self:ShowBG(self.tFrames[idx].window:FindChild("SimpleTarget"), tFrameData.background.show)						
						PotatoLib:UpdateBorder(self.tFrames[idx].window,self.tFrames[idx].window:FindChild("Content"), tFrameData.border)
						
						self.tFrames[idx].window:FindChild("Portrait"):SetAnimated(tFrameData.portraitType == 1)						
					end
				end
			end
			self:OnCharacterCreated()
		end
	elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData = tData
	end
end

-----------------------------------------------------------------------------------------------
-- PotatoFrames Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PotatoFrames:PopulateResetFeatures()
	PotatoLib:AddResetParent("Unitframes")
	
	for idx=1, #ktDefaultFrames do
		local tCurrFrame = self.tFrames[idx]
		if tCurrFrame then
			PotatoLib:AddResetItem(tCurrFrame.frameData.name, "Unitframes", self)
		end
	end
end

function PotatoFrames:OnPRFReset(wndHandler)
	local strName = wndHandler:GetParent():GetParent():FindChild("FeatureName"):GetText()
	
	for idx=1, #ktDefaultFrames do
		local tCurrFrame = self.tFrames[idx]
		if tCurrFrame then
			if tCurrFrame.frameData.name == strName then
				self:ResetFrame(tCurrFrame.window)
			end
		end
	end
end

function PotatoFrames:EditorModeToggle(bState)
	bEditorMode = bState
	
	for idx, frame in pairs(self.tFrames) do
		if frame.window then
			local unitPlayer = GameLib.GetPlayerUnit()
			if bEditorMode then
				frame.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", frame.window, self)
				frame.wndCover:SetText(ktDefaultFrames[idx].name)
				if frame.frameData.border.show then
					frame.wndCover:SetAnchorOffsets(frame.frameData.border.size, frame.frameData.border.size, -frame.frameData.border.size, -frame.frameData.border.size)
				else
					frame.wndCover:SetAnchorOffsets(0,0,0,0)
				end

				if not frame.window:IsShown() then
					frame.window:Show(true)
				end
				
				if idx < 5 then
					local unitFrameUnit = frame.window:GetData().unit or unitPlayer
					self:UpdateFrameProps(unitFrameUnit, frame.window)
					self:UpdateFrameStats(unitFrameUnit, frame.window)
				end
			else
				frame.wndCover:Destroy()
				frame.wndCover = nil
				
				local unitFrameUnit = nil
				if idx == 1 then
					unitFrameUnit = unitPlayer
				elseif idx == 2 then
					unitFrameUnit = GameLib.GetTargetUnit() 
				elseif idx == 3 then
					local unitTarget = GameLib.GetTargetUnit()
					unitFrameUnit = unitTarget and unitTarget:GetTarget() or nil 
				elseif idx == 4 then
					unitFrameUnit = unitPlayer and unitPlayer:GetAlternateTarget() or nil
				elseif idx == 5 or idx == 6 then
					unitFrameUnit = frame.window:GetData().unit or nil
				end
				
				local bShowFrame = unitFrameUnit and self:ShouldShow(unitFrameUnit, idx) or false
				frame.window:Show(bShowFrame)
			end
			frame.window:SetStyle("Moveable", bEditorMode)
			frame.window:SetStyle("Sizable", bEditorMode)
			frame.window:FindChild("RaidMarker"):SetStyle("NewWindowDepth", not bEditorMode)
		end
	end
	if not bEditorMode and self.wndCustomize then
		self.wndCustomize:Destroy()
		self.wndCustomize = nil
	end
end

function PotatoFrames:ShouldShow(unit, nFrameId)
	local tData = self.tFrames[nFrameId].frameData
	
	if unit ~= nil then
		if bEditorMode then return true end
		if tData.showFrame == 1 then return true end
		if tData.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unit) or PotatoLib.bInCombat) then return true end
		if tData.showFrame == 3 and PotatoLib.bInCombat then return true end
	end
	
	return false
end

function PotatoFrames:ResetAll()
	--Destroy Customization window to save memory
	if self.wndCustomize ~= nil then
		self.wndCustomize:Destroy()
		Apollo.GetAddon("PotatoLib").wndCustomize:Show(false)
	end
	
	for idx=1, #ktDefaultFrames do
		local tCurrFrame = self.tFrames[idx]
		if tCurrFrame then
			self:ResetFrame(tCurrFrame.window)
		end
	end
end

function PotatoFrames:ResetFrame(wndFrame)
	local nFrameId = wndFrame:GetData().id
	local tFrameData = self.tFrames[nFrameId].frameData
	
	--Set show frame
	tFrameData.showFrame = 1
	tFrameData.showIcons = ktDefaultFrames[nFrameId].showIcons

	--Set border and BG
	tFrameData.border = TableUtil:Copy(PotatoLib.ktDefaultBorder)
	PotatoLib:UpdateBorder(wndFrame, wndFrame:FindChild("Content"), tFrameData.border)
	
	tFrameData.background = TableUtil:Copy(PotatoLib.ktDefaultBackground)
	self:ShowBG(wndFrame:FindChild("Content"), tFrameData.background.show)
	self:ShowBG(wndFrame:FindChild("SimpleTarget"), tFrameData.background.show)
	
	--Set position
	wndFrame:SetAnchorPoints(unpack(ktDefaultFrames[nFrameId].anchors))
	wndFrame:SetAnchorOffsets(unpack(ktDefaultFrames[nFrameId].offsets))
	
	--Set portrait
	tFrameData.portraitType = ktDefaultFrames[nFrameId].portraitType
	wndFrame:FindChild("Portrait"):SetAnimated(portraitType ~= 2 and true or false)
	
	--Set bar styles
	tFrameData.barStyles = TableUtil:Copy(PotatoLib.ktDefaultFramesMess)
	
	self:UpdateFrameAppearance(wndFrame)
end

--[[function PotatoFrames:CreateBar(wndBar, unit, tCurrBar)
	local PLib = Apollo.GetAddon("PotatoLib")

	if PLib.bLowHPandCC then
		if unit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) > 0 then
			strColor = "FF00FF"
		else
			if tCurrBar.name == "HP" then
				if nCurrVal/nMaxVal <= 0.30 then
					if unit:GetClassId() ~= GameLib.CodeEnumClass.Warrior and not bCharacter then
						strColor = "FF0000"
					else
						strColor = "AA0000"
					end
				end
			end
		end	
	end
	
	PotatoLib:SetBarAppearance2(wndBar, tCurrBar.texture, strColor, tCurrBar.transparency)	
end]]--

function PotatoFrames:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	local unitTarget = unitPlayer:GetTarget()
	local unitToT = unitTarget and unitTarget:GetTarget() or nil
	local unitFocus = unitPlayer:GetAlternateTarget()
	
	self:UpdateFrameStats(unitPlayer, self.tFrames[1].window)
	self:UpdateFrameStats(unitTarget, self.tFrames[2].window)
	self:UpdateFrameStats(unitToT, self.tFrames[3].window)
	self:UpdateFrameStats(unitFocus, self.tFrames[4].window)
	
	if bPetClass then
		self:UpdateFrameStats(self.tFrames[5].window:GetData().unit, self.tFrames[5].window)
		self:UpdateFrameStats(self.tFrames[6].window:GetData().unit, self.tFrames[6].window)
	end
end

function PotatoFrames:UpdateFrameAppearance(wnd) --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	local nFrameId = wnd:GetData().id
	local tFrameData = self.tFrames[nFrameId].frameData
	
	--Background and Border
	wnd:FindChild("Content"):SetStyle("Picture", tFrameData.background.show)
	PotatoLib:UpdateBorder(wnd, wnd:FindChild("Content"), tFrameData.border)
	
	--Portrait and Icons
	local showPortrait = tFrameData.portraitType < 4 and true or false
	local showIcons = tFrameData.showIcons
	
	local nPortraitContrib = showPortrait and 0.215 or 0
	local nIconsContrib = showIcons and 0.06 or 0
	local bIsLeft = true
	if nFrameId ~= 1 and nFrameId ~= 4 then bIsLeft = false end
	local nPortIconOffset = bIsLeft and (nPortraitContrib+nIconsContrib) or (1-nPortraitContrib-nIconsContrib)
	
	wnd:FindChild("Icons"):Show(showIcons)
	wnd:FindChild("Icons"):SetAnchorPoints(bIsLeft and 0 or 1-nIconsContrib, 0, bIsLeft and nIconsContrib or 1, 1)
	wnd:FindChild("Icons"):SetAnchorOffsets(bIsLeft and 0 or 3, 0, bIsLeft and 1 or 3, 0)
	
	wnd:FindChild("Portrait"):Show(showPortrait and tFrameData.portraitType ~= 3)
	wnd:FindChild("Portrait"):SetCamera(bIsLeft and "Portrait" or "Target")
	
	wnd:FindChild("ClassPort"):Show(tFrameData.portraitType == 3)
	if tFrameData.portraitType == 3 then
		wnd:FindChild("ClassPort"):SetAnchorPoints(bIsLeft and nIconsContrib or nPortIconOffset, 0, bIsLeft and nPortIconOffset or 1-nIconsContrib, 1)
	end
	
	--Position icons, portrait, and bars based on side
	wnd:FindChild("Portrait"):SetAnchorPoints(bIsLeft and nIconsContrib or nPortIconOffset, 0, bIsLeft and nPortIconOffset or 1-nIconsContrib, 1)
	wnd:FindChild("Portrait"):SetAnchorOffsets(0, 0, 0, 0)
	wnd:FindChild("Bars"):SetAnchorPoints(bIsLeft and nPortIconOffset or 0, 0, bIsLeft and 1 or nPortIconOffset, 1)
	
	for idx=1, #tFrameData.barStyles do
		local wndCurrBar = wnd:FindChild(tFrameData.barStyles[idx].name.."Bar")
		local tCurrBar = tFrameData.barStyles[idx]
		--Bar Texture
		PotatoLib:SetBarSprite(wndCurrBar, tCurrBar.texture)
		--Bar Growth
		local bBarGrowth = tCurrBar.barGrowth == 2
		wndCurrBar:SetStyleEx("BRtoLT", bBarGrowth)
		--Bar Text
		for idx2=1, #ktPos do
			local strTextLoc = "text"..ktPos[idx2] 
			local strFont = PotatoLib:FontTableToString(tCurrBar[strTextLoc].font)
			wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):SetFont(strFont)
		end			
		--Show Resource Bar
		if tCurrBar.name == "RP" and not bShowRPBar then
			local bShowRPBar = tCurrBar.showResBar
			local tHpAnchors = {wnd:FindChild("HPBar"):GetAnchorPoints()}

			wndCurrBar:Show(bShowRPBar)
			wnd:FindChild("HPBar"):SetAnchorPoints(tHpAnchors[1], tHpAnchors[2], tHpAnchors[3], bShowRPBar and 0.8 or 1)
		end
	end
end

function PotatoFrames:UpdateFrameStats(unit, wnd) --Updates the frame with unit statistics (e.g. hp, shield, resource, etc.) [CONTINUALLY FIRED]
	if unit == nil then
		if wnd:IsVisible() and not bEditorMode then
			wnd:Show(false)
		end
		return
	end
	
	if unit:IsInVehicle() then
		unit = unit:GetVehicle()
	end
	
	local nFrameId = wnd:GetData().id
	local tFrameData = self.tFrames[nFrameId].frameData
	
	local unitFrameUnit = self.tFrames[nFrameId].window:GetData().unit
	
	if unitFrameUnit ~= unit then
		self:UpdateFrameProps(unit, wnd)
	end
	
	wnd:Show(self:ShouldShow(unit, nFrameId))
	
	local bSimple = unit:GetHealth() == nil
	if not bSimple then
		--Set Level
		local strLevel = unit:GetLevel() ~= nil and (unit:GetLevel() .. "") or "??"
		local nCon = self:HelperCalculateConValue(unit) --TODO: High function call
		local strReward = String_GetWeaselString(Apollo.GetString("TargetFrame_TargetXPReward"), karConInfo[nCon][4])
		PotatoLib:TextSquish(strLevel, wnd:FindChild("Level"), "_BO", 5) --TODO: High function call
		--wnd:FindChild("Level"):SetText(strLevel)
		wnd:FindChild("Level"):SetTextColor(karConInfo[nCon][2])
		wnd:FindChild("Level"):SetTooltip(self:HelperBuildTooltip(strReward, karConInfo[nCon][3], karConInfo[nCon][5])) --TODO: High function call
		
		--Set Portrait
		if tFrameData.portraitType < 3 then

			wnd:FindChild("Portrait"):SetCostume(unit)
			wnd:FindChild("PvpFlag"):Show(unit:IsPvpFlagged())
		end	
		
		--Target Marker
		local nMarker = unit:GetTargetMarker() or 0
		local wndRaidMarker = self.tFrames[nFrameId].window:FindChild("RaidMarker")
		
		if nMarker ~= wndRaidMarker:GetData() then
			wndRaidMarker:SetData(nMarkerId)
			wndRaidMarker:SetSprite(kstrRaidMarkerToSprite[nMarker])
		end

		--Bar Things		
		local ktBars = {
			HP = {unit:GetHealth(), unit:GetMaxHealth()},
			SP = {unit:GetShieldCapacity(), unit:GetShieldCapacityMax()},
			RP = {PotatoLib:GetClassResource(unit)},
			AP = {unit:GetAbsorptionValue(), unit:GetAbsorptionMax()}
		}
		
		for idx=1, 4 do
			local tCurrBar = tFrameData.barStyles[idx]
			local wndCurrBar = wnd:FindChild(tCurrBar.name.."Bar")
			local nCurrVal, nMaxVal = unpack(ktBars[tCurrBar.name])
			
			--Bar Values
			PotatoLib:SetBarVars2(wndCurrBar, nCurrVal, nMaxVal)
			
			--Bar Color TODO: Find optimization to reduce performance loss in this section. Possibility is to check combat.
			if tCurrBar.colorType == "customcolor" or PotatoLib.bLowHPandCC then
				local strColor = tCurrBar.color
				
				if PotatoLib.bLowHPandCC and tCurrBar.name == "HP" then
					if unit:GetCCStateTimeRemaining(Unit.CodeEnumCCState.Vulnerability) > 0 then
						strColor = "FF00FF"
					else
						if nCurrVal/nMaxVal <= 0.30 then
							if unit:GetClassId() ~= GameLib.CodeEnumClass.Warrior and not unit:IsACharacter() then
								strColor = "FF0000"
							else
								strColor = "FFFF00"
							end
						end
					end	
				end
				PotatoLib:SetBarAppearance2(wndCurrBar, tCurrBar.texture, strColor, tCurrBar.transparency) --Set appearance
			end
			
			--Bar Text TODO: Find optimization to reduce performance loss in this section.
			for idx2=1, 3 do
				local strTextLoc = "text"..ktPos[idx2]
				local strText = ""
				--ktPos == 0 is None
				if tCurrBar[strTextLoc].type == 1 then --Name
					strText = unit:GetName()
				elseif tCurrBar[strTextLoc].type == 2 then --Detailed Verbose
					strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (math.floor(nCurrVal) .. "/" .. math.floor(nMaxVal)) or ""
				elseif tCurrBar[strTextLoc].type == 3 then --Detailed Short
					strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (self:FormatNumber(nCurrVal) .. "/" .. self:FormatNumber(nMaxVal)) or ""
				elseif tCurrBar[strTextLoc].type == 4 then --Percent
					strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (string.format("%.1f%%",nCurrVal/nMaxVal*100)) or ""--(math.floor(nCurrVal/nMaxVal*100).."%") or ""
				elseif tCurrBar[strTextLoc].type == 5 then --Super Short
					strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (self:FormatNumber(nCurrVal)) or ""
				elseif tCurrBar[strTextLoc].type == 6 then --Class
					local strClassName = GameLib.GetClassName(unit:GetClassId()) or "Unknown Class"
					strText = strClassName ~= "Unknown Class" and strClassName or ""
				elseif tCurrBar[strTextLoc].type == 7 then
					strText = unit:GetLevel() ~= nil and (unit:GetLevel() .. "") or "??"
				end	
				
				wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):SetText(strText)
				
				--Begin text truncation
				if PotatoLib.bTruncateText and strText ~= "" then
					local strFont = PotatoLib:FontTableToString(tCurrBar[strTextLoc].font)
					local nFieldWidth = wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):FindChild("HoverSpot"):GetWidth()
					local nTextWidth = Apollo.GetTextWidth(strFont,strText)
					local tFieldsFilled = {true, true, true}
					
					if nTextWidth > nFieldWidth then
						for idx3=1, #ktPos do
							if wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx3]):GetText() == "" then
								tFieldsFilled[idx3] = false
							end
						end
						
						if idx2 == 1 then
							if not tFieldsFilled[2] then
								if tFieldsFilled[3] then
									nFieldWidth = nFieldWidth*2
								else
									nFieldWidth = nFieldWidth*3
								end
							end
						elseif idx == 2 then
							if not tFieldsFilled[1] and not tFieldsFilled[3] then
								nFieldWidth = nFieldWidth*3
							end
						elseif idx == 3 then
							if not tFieldsFilled[2] then
								if tFieldsFilled[1] then
									nFieldWidth = nFieldWidth*2
								else
									nFieldWidth = nFieldWidth*3
								end
							end
						end
					
					--[[if nTextWidth > nFieldWidth then
						local bShorten = false
			
						if idx2 == 1 then
							if wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2+1]):GetText() ~= "" then
								bShorten = true
							end
						elseif idx2 == 2 then
							if wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2-1]):GetText() ~= "" then
								bShorten = true
							elseif wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2+1]):GetText() ~= "" then
								bShorten = true
							end
						elseif idx2 == 3 then
							if wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2-1]):GetText() ~= "" then
								bShorten = true
							end
						end]]--
						
						
						if nTextWidth > nFieldWidth then --if bShorten then
							wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):SetText(PotatoLib:TextTruncate(strFont, strText, nFieldWidth))--wndBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):FindChild("HoverSpot")))
							wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):FindChild("HoverSpot"):SetTooltip(strText)
						else
							wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):FindChild("HoverSpot"):SetTooltip("")
						end
					else
						wndCurrBar:FindChild(tCurrBar.name.."text"..ktPos[idx2]):FindChild("HoverSpot"):SetTooltip("")
					end
				end
			end
		end
	end
end

function PotatoFrames:OnSubZoneChanged(nSubZoneId, strSubZone, nSomething)
	self:OnCharacterCreated()
end

function PotatoFrames:UpdateFrameProps(unit, wnd) --Updates portions of frame dependent on unit, but not continually updated (e.g. path, class, etc.). Called when a target is changed.
	local tWndData = wnd:GetData()
	tWndData.unit = unit
	wnd:SetData(tWndData)
	
	local PLib = Apollo.GetAddon("PotatoLib")
		
	local nFrameId = wnd:GetData().id
	local tFrameData = self.tFrames[nFrameId].frameData
	
	if unit == nil then
		return
	end
	--If it's a simple target, the simple target format is used.
	local bSimple = unit:GetHealth() == nil
	wnd:FindChild("SimpleTarget"):Show(bSimple)
	wnd:FindChild("Content"):Show(not bSimple)
	
	if bSimple then
		wnd:FindChild("SimpleTarget"):SetText(unit:GetName())
	else
		local bCharacter = unit:IsACharacter()
		
		--Portrait
		if tFrameData.portraitType == 3 then
			local strPortSprite = ""
			if bCharacter then
				strPortSprite = "ClientSprites:Icon_Windows_UI_CRB_" .. GameLib.GetClassName(unit:GetClassId())
			elseif unit:GetArchetype() ~= nil then
				strPortSprite = unit:GetArchetype().strIcon --TODO: Revamp the positioning.
			end
			
			--TODO: Figure out what is going on with Stalkers during Clone.
			if strPortSprite == nil then
				strPortSprite = ""
			end
			
			--strPortSprite = bCharacter and ("ClientSprites:Icon_Windows_UI_CRB_" .. GameLib.GetClassName(unit:GetClassId())) or unit:GetArchetype().strIcon
			wnd:FindChild("ClassPort"):SetSprite(strPortSprite)
			wnd:FindChild("ClassPort"):FindChild("Icon"):SetSprite(strPortSprite)
		end

		for idx=1, #tFrameData.barStyles do
			local wndCurrBar = wnd:FindChild(tFrameData.barStyles[idx].name.."Bar")
			local tCurrBar = tFrameData.barStyles[idx]

			--Bar Appearance
			if tCurrBar.colorType ~= "customcolor" then
				if tCurrBar.colorType == "classcolor" then
					local vClass = ""

					if bCharacter then
						vClass = unit:GetClassId()
					else
						local nDisposition = GameLib.GetPlayerUnit():GetDispositionTo(unit)
						if nDisposition == Unit.CodeEnumDisposition.Hostile then
							vClass = "Hostile"
						elseif nDisposition == Unit.CodeEnumDisposition.Neutral then
							vClass = "Neutral"
						elseif nDisposition == Unit.CodeEnumDisposition.Friendly then
							vClass = "Friendly"
						end
					end
					strColor = PLib.classColors[PLib.strColorStyle][vClass]
				elseif tCurrBar.colorType == "resourcecolor" then
					strColor = bCharacter and PotatoLib.resourceColors[unit:GetClassId()] or "AAAAAA"
				end
				tCurrBar.color = strColor
				PotatoLib:SetBarAppearance2(wndCurrBar, tCurrBar.texture, tCurrBar.color, tCurrBar.transparency) --Set appearance
			end
		end
		
		--Set Icons
		--faction/group size
		local strFactionSprite = PotatoLib.factionNames[unit:GetFaction()] ~= nil and ("CRB_CharacterCreateSprites:sprCC_" .. PotatoLib.factionNames[unit:GetFaction()] .. "Icon") or ""	
		local nGroupSize = unit:GetGroupValue()
		local strFactionText = nGroupSize > 1 and nGroupSize or ""
		local strFactionTooltip = nGroupSize > 1 and self:HelperBuildTooltip(String_GetWeaselString(Apollo.GetString("TargetFrame_GroupSize"), unit:GetGroupValue()), String_GetWeaselString(Apollo.GetString("TargetFrame_Man"), unit:GetGroupValue())) or ""
		
		--Set group size sprite and value.	
		local nGroupSize = unit:GetGroupValue()
		if nGroupSize > 1 then
			strText = nGroupSize
			if PotatoLib.factionNames[unit:GetFaction()] == nil then --If it's not a factioned NPC, give it a group size background.
				strFactionSprite = "CRB_TargetFrameSprites:sprTF_GroupRank_Base"
			end
		end
		wnd:FindChild("FactionGroup"):SetSprite(strFactionSprite)
		wnd:FindChild("FactionGroup"):SetText(strFactionText)	
		wnd:FindChild("FactionGroup"):SetTooltip(strFactionTooltip)
		
		--archetype/class
		local strClassSprite = ""
		local strClassTooltip = ""

		if bCharacter then
			strClassSprite = "ClientSprites:Icon_Windows_UI_CRB_" .. PotatoLib.ktClassNames[unit:GetClassId()]
		elseif unit:GetArchetype() ~= nil then
			local tArchetype = unit:GetArchetype()
			strClassSprite = tArchetype.strIcon
			
			local strType, bReplaced = string.gsub(strClassSprite, "ClientSprites:Icon_ArchetypeUI_CRB_", "")
			if bReplaced == 1 then
				strClassTooltip = ktArchetypes[strType] ~= nil and self:HelperBuildTooltip(ktArchetypes[strType].description, ktArchetypes[strType].name) or ""
			else
				strType, bReplaced = string.gsub(strClassSprite, "TargetFrameSprites:sprRole", "")
				if bReplaced == 1 then
					strClassTooltip = self:HelperBuildTooltip(ktRoles[strType].description, ktRoles[strType].name) or ""
				end
			end

			--TODO: Figure out what is going on with Stalkers during Clone.
			if strClassSprite == nil then
				strClassSprite = ""
			end
		end
		wnd:FindChild("Class"):SetSprite(strClassSprite or "")
		wnd:FindChild("Class"):SetTooltip(strClassTooltip)
		
		--path/diff
		local nRank = unit:GetRank()
		local strPathSprite = ""
		local strPathTooltip = ""
		
		if bCharacter then
			strPathSprite = "ClientSprites:Icon_Windows_UI_CRB_" .. PotatoLib.pathNames[unit:GetPlayerPathType()]
		else
			if ktRankDescriptions[nRank] then
				strPathSprite = ktDifficultySprites[nRank] and "PotatoSprites:"..ktDifficultySprites[nRank] or ""
				local strRank = String_GetWeaselString(Apollo.GetString("TargetFrame_CreatureRank"), ktRankDescriptions[nRank][2])
				strPathTooltip = self:HelperBuildTooltip(strRank, ktRankDescriptions[nRank][1])
			end
		end
		wnd:FindChild("PathDiff"):SetSprite(strPathSprite)
		wnd:FindChild("PathDiff"):SetTooltip(strPathTooltip)
	end
end

function PotatoFrames:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	
	if unitPlayer ~= nil then
		local unitTarget = unitPlayer:GetTarget()
		local unitToT = unitTarget and unitTarget:GetTarget() or nil
		local unitFocus = unitPlayer:GetAlternateTarget()
		
		self:UpdateFrameProps(unitPlayer, self.tFrames[1].window)
		self:UpdateFrameProps(unitTarget, self.tFrames[2].window)
		self:UpdateFrameProps(unitToT, self.tFrames[3].window)
		self:UpdateFrameProps(unitFocus, self.tFrames[4].window)
		
		local nClassId = unitPlayer:GetClassId()		
		if nClassId ~= GameLib.CodeEnumClass.Engineer and nClassId ~= GameLib.CodeEnumClass.Esper then
			if self.tFrames[5] or self.tFrames[6] then
				self.tFrames[5].window:Destroy()
				self.tFrames[5] = nil
				self.tFrames[6].window:Destroy()
				self.tFrames[6] = nil
			end
		else
			Apollo.RegisterEventHandler("UnitCreated",				"OnUnitCreated", self)
			Apollo.RegisterEventHandler("UnitDestroyed",				"OnUnitDestroyed", self)
			Apollo.RegisterEventHandler("CombatLogPet",					"OnCombatLogPet", self)
			
			if not self.tFrames[5].window:FindChild("DismissPetBtn") then
				local wndPet1Btn = Apollo.LoadForm("PotatoFrames.xml", "DismissPetBtn", self.tFrames[5].window, self)
			end
			
			if not self.tFrames[6].window:FindChild("DismissPetBtn") then
				local wndPet2Btn = Apollo.LoadForm("PotatoFrames.xml", "DismissPetBtn", self.tFrames[6].window, self)
			end
			
			bPetClass = true
			self:LoadPetsIntoFrames()
		end
	end
end


--START Pet Functions--
function PotatoFrames:LoadPetsIntoFrames(unitExtraPet)

	local tPets = GameLib.GetPlayerPets()
	if unitExtraPet then
		table.insert(tPets, unitExtraPet)
	end

	--Print("We has pets? "..#tPets)

	for idx, unitPet in pairs(tPets) do
		-- scsc: skip non-combat pets; I found Health to be the most reliable factor to decide it by
		if idx < 3 and unitPet:GetHealth() then
			--Print("Loading ".. unitPet:GetName())
			
			local tData = self.tFrames[5+(idx-1)].window:GetData()
			tData.unit = unitPet
			
			self.tFrames[5+(idx-1)].window:SetData(tData)
			self.tFrames[5+(idx-1)].window:FindChild("DismissPetBtn"):SetContentId(GameLib.GetPetDismissCommand(unitPet))
			self.tFrames[5+(idx-1)].window:Show(true)
			self:UpdateFrameAppearance(self.tFrames[5+(idx-1)].window)
		end
	end		
end

function PotatoFrames:OnUnitDestroyed(unit)
	for idx=5, 6 do
		local unitFrameUnit = self.tFrames[idx].window:GetData().unit or nil
		if unitFrameUnit == unit then
			--Print("Killing pet: "..unit:GetName().. " on frame ".. idx)
			local tData = self.tFrames[idx].window:GetData()
			tData.unit = nil
			self.tFrames[idx].window:SetData(tData)
			self.tFrames[idx].window:Show(false)
		end
	end
end

function PotatoFrames:OnCombatLogPet(tInfo)
	if tInfo.eCombatResult == 8 and tInfo.unitTargetOwner == GameLib.GetPlayerUnit() then
		--Print("Spawning pet: "..tInfo.unitTarget:GetName())
		self:LoadPetsIntoFrames(tInfo.unitTarget)
	end
end
--END Pet Functions--

function PotatoFrames:OnTargetUnitChanged(unitTarget)
	local unitToT = unitTarget and unitTarget:GetTarget() or nil
	
	self:UpdateFrameProps(unitTarget, self.tFrames[2].window)
	self:UpdateFrameProps(unitToT, self.tFrames[3].window)
end

function PotatoFrames:OnAlternateTargetUnitChanged(unitTarget)
	self:UpdateFrameProps(unitTarget, self.tFrames[4].window)
end

--TODO: function on gear change DO THIS; then it can be removed from PotatoFrames:OnFrame()
	--self.wndBars:FindChild("CostumeWindow"):SetCostume(GameLib.GetPlayerUnit())
	
function PotatoFrames:FormatNumber(nNumber)
	local strNum = "ERR"
	
	if nNumber / 1000000 >= 1 then
		strNum = string.format("%.1fm", nNumber/1000000)
	elseif nNumber / 1000 >= 1 then
		strNum = string.format("%.1fk",nNumber/1000)
	else
		strNum = math.floor(nNumber)
	end

	return string.gsub(strNum .. "", "%.0", "")
end

function PotatoFrames:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		self:OpenEditor(wndHandler:GetData().id)
	end
end

function PotatoFrames:OpenEditor(nFrameId)
	local tFrameData = self.tFrames[nFrameId].frameData
	local PLib = Apollo.GetAddon("PotatoLib")
	
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	--Populate PotatoLib editor frame; Set frame identifier; Set title
	PLib.wndCustomize:Show(true)
	self.wndCustomize = Apollo.LoadForm("PotatoFrames.xml", "UnitframeCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndCustomize:SetData(nFrameId) -- only id for now
	PLib.wndCustomize:FindChild("Title"):SetText(ktDefaultFrames[nFrameId].name .. " Settings")
	
	--Set portrait type selected from tFrames[idx].frameData
	self.wndCustomize:FindChild("ShowPortrait"):FindChild("Options"):SetRadioSel("PortraitType", tFrameData.portraitType)
	--Set icon visibility selected from tFrames[idx].frameData
	self.wndCustomize:FindChild("ShowIcons"):FindChild("Options"):SetRadioSel("ShowIcons", tFrameData.showIcons and 1 or 2)
	--Set frame visibility selected from tFrames[idx].frameData
	self.wndCustomize:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", tFrameData.showFrame)
	--Set background visibility and color selected from tFrames[idx].frameData
	self.wndCustomize:FindChild("Background"):FindChild("EnableBtn"):SetCheck(tFrameData.background.show)
	self.wndCustomize:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..tFrameData.background.color)
	self.wndCustomize:FindChild("Background"):FindChild("HexText"):SetText(tFrameData.background.color)
	--Set border visibility and color selected from tFrames[idx].frameData
	self.wndCustomize:FindChild("Border"):FindChild("EnableBtn"):SetCheck(tFrameData.border.show)
	self.wndCustomize:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..tFrameData.border.color)
	self.wndCustomize:FindChild("Border"):FindChild("HexText"):SetText(tFrameData.border.color)
	self.wndCustomize:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(tFrameData.border.size)
	self.wndCustomize:FindChild("Border"):FindChild("BorderSize:SizeValueUp"):Enable(tFrameData.border.size ~= 20)
	self.wndCustomize:FindChild("Border"):FindChild("BorderSize:SizeValueDown"):Enable(tFrameData.border.size ~= 1)
	
	for idx=1, #tFrameData.barStyles do
		local wndCurrBar = self.wndCustomize:FindChild(tFrameData.barStyles[idx].name.."Bar")
		local tCurrBarData = tFrameData.barStyles[idx]
		local bCustomColor = tCurrBarData.colorType == "customcolor"
		local nBarGrowth = tCurrBarData.barGrowth ~= nil and tCurrBarData.barGrowth or 1
		
		if wndCurrBar ~= nil then
			wndCurrBar:SetData({bar=idx})
			
			wndCurrBar:FindChild("Header1"):FindChild("Button"):ChangeArt("CRB_Basekit:kitBtn_ScrollHolo_UpLarge")
			wndCurrBar:SetAnchorOffsets(0, 0, 0, 30)
			
			PotatoLib:SetSprite(wndCurrBar:FindChild("BarTexture"):FindChild("CurrentVal"),tCurrBarData.texture)
			wndCurrBar:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(tCurrBarData.texture == "WhiteFill" and "Flat" or tCurrBarData.texture)
			wndCurrBar:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..tCurrBarData.color)

			wndCurrBar:FindChild("BarGrowth"):FindChild("Options"):SetRadioSel("BarGrowth", nBarGrowth)
			
			wndCurrBar:FindChild("Color"):SetBGColor("FF"..tCurrBarData.color)
			wndCurrBar:FindChild("Color"):Show(bCustomColor)
			wndCurrBar:FindChild("HexText"):SetText(tCurrBarData.color)
			wndCurrBar:FindChild("ColorType"):SetRadioSel("ColorType", bCustomColor and 2 or 1)
			wndCurrBar:FindChild("ClassColorCover"):Show(not bCustomColor)
			wndCurrBar:FindChild("Transparency"):SetValue(tCurrBarData.transparency)
			wndCurrBar:FindChild("TransAmt"):SetText(tCurrBarData.transparency.."%")
			if wndCurrBar:GetName() == "RPBar" then
				wndCurrBar:FindChild("ShowBar"):FindChild("Options"):SetRadioSel("ShowResBar", tCurrBarData.showResBar and 1 or 2)
			end

			PotatoLib:PopulateTextOptions(wndCurrBar, tCurrBarData, ktTextType) --Populate frame text options
		else
			Print("[PotatoUI] "..tFrameData.barStyles[idx].name.." Bar not found. Custom color:" .. tostring(bCustomColor) .. " Comment on Curse about this; you shouldn't be seeing it.")
		end
	end

	PLib.wndCustomize:FindChild("EditorContent"):ArrangeChildrenVert()

	local nBottom = self.wndCustomize:ArrangeChildrenVert()
	self.wndCustomize:SetAnchorOffsets(0,0,0,nBottom)
	PLib.wndCustomize:FindChild("EditorContent"):ArrangeChildrenVert()
	
	self.wndCustomize:Show(true)
	PLib.wndCustomize:Show(true)
	
	local nX1, nY1, nX2, nY2 = self.tFrames[nFrameId].window:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.tFrames[nFrameId].window:GetAnchorPoints()
	
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	if self.wndCustomize then
		if self.wndCustomize:FindChild("XPos") ~= nil then
			local PLib = Apollo.GetAddon("PotatoLib")
			if PLib.bPositionCenter then
				nAX1 = nAX1-0.5
				nAY1 = nAY1-0.5
			end
			self.wndCustomize:FindChild("XPos"):SetText((nAX1*nScreenX)+nX1)
			self.wndCustomize:FindChild("YPos"):SetText((nAY1*nScreenY)+nY1)
			self.wndCustomize:FindChild("Width"):SetText(nX2-nX1)
			self.wndCustomize:FindChild("Height"):SetText(nY2-nY1)
		end
	end
end

---------------------------------------------------------------------------------------------------
-- UnitframeCustomize Functions
---------------------------------------------------------------------------------------------------

----------------------SECTION OPTIONS----------------------

function PotatoFrames:ToggleSectionVisibility( wndHandler, wndControl, eMouseButton )
	local wndCurrBar = wndHandler:GetParent():GetParent()
	local nPossHeight = wndCurrBar:ArrangeChildrenVert(0)
	local PLib = Apollo.GetAddon("PotatoLib")

	local bShown = wndCurrBar:GetHeight() < nPossHeight
	
	local tOffsets = {wndCurrBar:GetAnchorOffsets()}

	if bShown then
		wndCurrBar:SetAnchorOffsets(tOffsets[1], tOffsets[2], tOffsets[3], tOffsets[2] + nPossHeight)
		wndHandler:ChangeArt("CRB_Basekit:kitBtn_ScrollHolo_DownLarge")
	else
		wndCurrBar:SetAnchorOffsets(tOffsets[1], tOffsets[2], tOffsets[3], tOffsets[2] + 30)
		wndHandler:ChangeArt("CRB_Basekit:kitBtn_ScrollHolo_UpLarge")
	end
	local nBottom = self.wndCustomize:ArrangeChildrenVert()
	self.wndCustomize:SetAnchorOffsets(0,0,0,nBottom)
	PLib.wndCustomize:FindChild("EditorContent"):ArrangeChildrenVert()
	local _, nScrollPos = wndCurrBar:GetAnchorOffsets()
	PLib.wndCustomize:FindChild("EditorContent"):SetVScrollPos(nScrollPos)
end

function PotatoFrames:OnSectionHover( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end
	wndHandler:SetTextColor("AttributeDexterity")
end

function PotatoFrames:OnSectionExit( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end
	wndHandler:SetTextColor("white")
end
----------------------MAIN FRAME OPTIONS----------------------

function PotatoFrames:OnShowChange( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	
	local nShowFrame = wndHandler:GetParent():GetRadioSel("ShowFrame")

	self.tFrames[nFrameId].frameData.showFrame = nShowFrame
end

function PotatoFrames:OnChangePortrait( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	local nPortraitType = wndHandler:GetParent():GetRadioSel("PortraitType") --1 = 3D, 2 = 2D, 3 = Class, 4 = Disabled
	
	self.tFrames[nFrameId].frameData.portraitType = nPortraitType
	self.tFrames[nFrameId].window:FindChild("Portrait"):SetAnimated(nPortraitType == 1)
	self:UpdateFrameAppearance(self.tFrames[nFrameId].window)
end

function PotatoFrames:OnChangeIcons( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	self.tFrames[nFrameId].frameData.showIcons = wndHandler:GetParent():GetRadioSel("ShowIcons") == 1 and true or false --1 = Shown, 2 = Not Shown
	self:UpdateFrameAppearance(self.tFrames[nFrameId].window)
end

function PotatoFrames:ShowBG(wnd, bShow)
	wnd:SetStyle("Picture", bShow)
end

function PotatoFrames:OnChangeBG( wndHandler, wndControl, eMouseButton ) --TODO: REVAMP
	local nFrameId = self.wndCustomize:GetData()
	local bCheck = wndHandler:IsChecked()
	
	self.tFrames[nFrameId].frameData.background.show = bCheck
	
	self:ShowBG(self.tFrames[nFrameId].window:FindChild("Content"), bCheck)
	self:ShowBG(self.tFrames[nFrameId].window:FindChild("SimpleTarget"), bCheck)
end

--[[function PotatoFrames:OnChangeBorder( wndHandler, wndControl, eMouseButton ) --TODO: REVAMP
	local nFrameId = self.wndCustomize:GetData()
	
	local bCheck = wndHandler:IsChecked()
	
	local wndMain = self.tFrames[nFrameId].window
	local wndContent = self.tFrames[nFrameId].window:FindChild("Content")
	local tBorderData = self.tFrames[nFrameId].frameData.border

	self.tFrames[nFrameId].frameData.border.show = bCheck

	PotatoLib:UpdateBorder(wndMain, wndContent, tBorderData)
end

function Castbar:OnChangeBG( wndHandler, wndControl, eMouseButton )
	local bCheck = wndHandler:IsChecked()	
	self.background.show = bCheck
	
	self:UpdateCastbarAppearance()
end]]--


function PotatoFrames:IncrementBorderSize( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	local tBorderData = self.tFrames[nFrameId].frameData.border
	
	local nChange = wndHandler:GetName() == "SizeValueUp" and 1 or -1
	
	--Set data value
	tBorderData.size = tBorderData.size + nChange
	
	if tBorderData.size == 1 or tBorderData.size == 20 then
		wndHandler:Enable(false)
	else
		for key, val in pairs(wndHandler:GetParent():GetChildren()) do
			if val.Enable then
				val:Enable(true)
			end
		end
	end	
	
	--Set editor window
	wndHandler:GetParent():FindChild("SizeValue"):SetText(tBorderData.size)
	
	self:UpdateFrameAppearance(self.tFrames[nFrameId].window)
end

function PotatoFrames:OnShowBorder( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	local tBorderData = self.tFrames[nFrameId].frameData.border
	
	local bCheck = wndHandler:IsChecked()
	tBorderData.show = bCheck
	
	self:UpdateFrameAppearance(self.tFrames[nFrameId].window)
end


function PotatoFrames:TxtPositionChanged( wndHandler, wndControl, strPos )
	local nFrameId = self.wndCustomize:GetData()
	
	local strChange = wndHandler:GetName()
	
	local wndTarget = self.tFrames[nFrameId].window
	
	if wndTarget ~= nil then	
		local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndTarget:GetAnchorPoints()
	
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
				wndTarget:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
			elseif strChange == "YPos" then
				wndTarget:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
			end
			PLib:MoveLockedWnds(wndTarget)
		end

		wndHandler:SetText(strPos)
		wndHandler:SetSel(#strPos,#strPos)
	end
end

function PotatoFrames:TxtHWChanged( wndHandler, wndControl, strHW )
	local nFrameId = self.wndCustomize:GetData()
	local strChange = wndHandler:GetName()
	
	local wndTarget = self.tFrames[nFrameId].window
	
	if wndTarget ~= nil then
		local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndTarget:GetAnchorPoints()
		
		strHW = string.gsub(strHW, "[^0-9]", "")
		if #strHW > 1 and string.sub(strHW, 1, 1) == "0" then
			strHW = string.gsub(strHW, "0", "", 1)
		end
		
		if strHW == "" then
			strHW = "0"
		end	
			
		if strChange == "Width" then
			wndTarget:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
		elseif strChange == "Height" then
			wndTarget:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
		end	
		
		wndHandler:SetText(strHW)
		wndHandler:SetSel(#strHW,#strHW)
	end
end

-------------------------------BAR OPTIONS---------------------------------

function PotatoFrames:OnChangeGrowth( wndHandler, wndControl, eMouseButton ) --TODO:
	local nFrameId = self.wndCustomize:GetData()
	
	local nGrowth = wndHandler:GetParent():GetRadioSel("BarGrowth")
	local bBarGrowth = nGrowth == 2
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name.."Bar")		

	tData.barGrowth = nGrowth
	wndTarget:SetStyleEx("BRtoLT", bBarGrowth)
end

function PotatoFrames:OnChangeColorType( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()

	local nColorType = wndHandler:GetParent():GetRadioSel("ColorType") --1 = Class Color, 2 = Custom Color
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar
	
	local strNonCustomType = nBarId == 4 and "resourcecolor" or "classcolor"
	
	local tCurrBar = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	
	wndHandler:GetParent():GetParent():FindChild("ClassColorCover"):Show(nColorType == 1)
	tCurrBar.colorType = nColorType == 1 and strNonCustomType or "customcolor"
	self.wndCustomize:FindChild(tCurrBar.name.."Bar"):FindChild("Color"):Show(nColorType ~= 1)
	self.wndCustomize:FindChild(tCurrBar.name.."Bar"):FindChild("Color"):SetBGColor("FF"..tCurrBar.color)
end

function PotatoFrames:BarTextureScroll( wndHandler, wndControl ) --TODO: REVAMP
	local nFrameId = self.wndCustomize:GetData()
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name.."Bar")

	if wndTarget ~= nil then
		local nCurrBar = ktTextures[tData.texture]

		if wndHandler:GetName() == "RightScroll" then
			nCurrBar = nCurrBar == #ktTextures and 1 or (nCurrBar + 1)
		elseif wndHandler:GetName() == "LeftScroll" then
			nCurrBar = nCurrBar == 1 and #ktTextures or (nCurrBar - 1)
		end
		
		local strTexture = ktTextures[nCurrBar]
		
		--Set bar texture
		if wndTarget.SetFillSprite ~= nil then
			PotatoLib:SetBarSprite(wndTarget, strTexture)
		else
			PotatoLib:SetSprite(wndTarget, strTexture)
		end

		--Set data value
		tData.texture = strTexture
		
		--Set editor window
		wndHandler:GetParent():FindChild("CurrentVal"):SetSprite(strTexture)
		wndHandler:GetParent():FindChild("CurrentVal"):SetText(nCurrBar == ktTextures["WhiteFill"] and "Flat" or strTexture)
	end
end

function PotatoFrames:TransSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	local nFrameId = self.wndCustomize:GetData()
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name.."Bar")

	if wndTarget ~= nil then
		if wndHandler:GetParent():GetParent():GetName() == "BorderOptions" then
			self.tFrames[nFrameId].window:SetBGColor(string.format("%x", (fNewValue/100)*255).."000000")

			wndControl:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
		else
			tData.transparency = math.floor(fNewValue)

			local strColor = string.format("%x", (fNewValue/100)*255)..tData.color
			if wndTarget.SetBarColor ~= nil then
				wndTarget:SetBarColor(strColor)
			else
				wndTarget:SetBGColor(strColor)
			end
			
			--Set editor window
			wndControl:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
		end
	end
end

function PotatoFrames:TextOptScroll( wndHandler, wndControl ) --TODO: REVAMP
	local nFrameId = self.wndCustomize:GetData()

	local strTextLoc = wndControl:GetParent():GetParent():GetName()
	
	local tData, wndTarget, bSpecial = nil, nil, nil
	
	--local nTextVal = nil
	local nChange = 0
	--local nBarId = nil
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetParent():GetData().bar
	
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId][strTextLoc]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(self.tFrames[nFrameId].frameData.barStyles[nBarId].name..strTextLoc)

	local nTextVal = tData.type
	
	if wndTarget ~= nil then
		nChange = wndHandler:GetName() == "RightScroll" and 1 or -1
		local nNewTextVal = nTextVal + nChange

		if nNewTextVal == #ktTextType or nNewTextVal == 0 then
			wndHandler:Enable(false)
		else
			for key, val in pairs(wndHandler:GetParent():GetChildren()) do
				val:Enable(true)
			end
		end
		
		--Set the Data
		tData.type = nNewTextVal
		--Set the Example
		local strText = ktTextType[nNewTextVal][2]
		wndControl:GetParent():FindChild("CurrentVal"):SetText(ktTextType[nNewTextVal][1])
		wndTarget:SetText(strText)
	end
end

function PotatoFrames:FontScroll( wndHandler, wndControl )
	local nFrameId = self.wndCustomize:GetData()
	
	local strTextLoc = wndControl:GetParent():GetParent():GetParent():GetName()
	
	local nBaseKey = nil
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetParent():GetParent():GetData().bar
	
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name..strTextLoc)

	if wndTarget ~= nil then
		local tFontData = tData[strTextLoc].font
		
		for key,val in pairs(PotatoLib.ktFonts) do
			if tFontData.base == val.base then
				nBaseKey = key
			end
		end
			
		if nBaseKey ~= nil then			
			local nChange = wndHandler:GetName() == "RightScroll" and 1 or -1
			nBaseKey = nBaseKey + nChange
			
			if nBaseKey == #PotatoLib.ktFonts or nBaseKey == 1 then
				wndHandler:Enable(false)
			else
				for key, val in pairs(wndHandler:GetParent():GetChildren()) do
					val:Enable(true)
				end
			end
			
			wndControl:GetParent():FindChild("CurrentVal"):SetText(PotatoLib.ktFonts[nBaseKey].name)
			wndControl:GetParent():FindChild("CurrentVal"):SetFont(PotatoLib.ktFonts[nBaseKey].defaultStr)
			
			local wndSizeOpts = wndControl:GetParent():GetParent():FindChild("TxtSize")
			local strSize = PotatoLib.ktFonts[nBaseKey].defaultSettings.size
			local nSizeId = PotatoLib:GetSizeKeyByBaseSize(nBaseKey,strSize)		
			wndSizeOpts:FindChild("TextValue"):SetText(strSize)
			wndSizeOpts:FindChild("TextValueDown"):Enable(nSizeId > 1)
			wndSizeOpts:FindChild("TextValueUp"):Enable(nSizeId < #PotatoLib.ktFonts[nBaseKey].sizes)
			
			--Reset Text Properties
			local wndPropOpts = wndControl:GetParent():GetParent():GetParent():FindChild("TxtProps")
			for key, wnd in pairs(wndPropOpts:GetChildren()) do
				wnd:Enable(false)
			end
			wndPropOpts:SetRadioSel("TxtWeight", 0)
			wndPropOpts:FindChild("Outline"):SetCheck(false)
			
			for key,val in pairs(PotatoLib.ktFonts[nBaseKey].sizeProp[strSize]) do
				if val == "B" then
					wndPropOpts:FindChild("Bold"):Enable(true)
				elseif val == "BB" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
				elseif val == "BO" then
					wndPropOpts:FindChild("Bold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "BBO" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "I" then
					wndPropOpts:FindChild("Italic"):Enable(true)
				elseif val == "O" then
					wndPropOpts:FindChild("Outline"):Enable(true)
				end
			end		
			
			wndTarget:SetFont(PotatoLib.ktFonts[nBaseKey].defaultStr)
			tData[strTextLoc].font = TableUtil:Copy(PotatoLib.ktFonts[nBaseKey].defaultSettings)
		else
			Print("[PotatoUI] ERROR NBASEKEY")
		end
	end
end

function PotatoFrames:IncrementFontSize( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	
	local strTextLoc = wndControl:GetParent():GetParent():GetParent():GetName()
	
	local tData, wndTarget = nil, nil --tData is the data container where textXXXX.font can be found. (Eg. frameData.barStyles(.textLeft) or castbarData(.textLeft))
	local nBaseKey, nSizeKey = nil, nil
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetParent():GetParent():GetData().bar	
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name..strTextLoc)
		
	if wndTarget ~= nil then
		local tFontData = tData[strTextLoc].font
	
		for key,val in pairs(PotatoLib.ktFonts) do
			if tFontData.base == val.base then
				nBaseKey = key
			end
		end
		
		if nBaseKey ~= nil and PotatoLib.ktFonts[nBaseKey] ~= nil then
			local tSizes = PotatoLib.ktFonts[nBaseKey].sizes
			for key,val in pairs(tSizes) do
				if tFontData.size.."" == val.."" then
					nSizeKey = key
				end
			end
			if nSizeKey ~= nil then
				local nChange = wndHandler:GetName() == "TextValueUp" and 1 or -1
				nSizeKey = nSizeKey + nChange
				
				if nSizeKey == #tSizes or nSizeKey == 1 then
					wndHandler:Enable(false)
				else
					for key, val in pairs(wndHandler:GetParent():GetChildren()) do
						val:Enable(true)
					end
				end
				
				--Set Editor Value
				wndControl:GetParent():FindChild("TextValue"):SetText(PotatoLib.ktFonts[nBaseKey].sizes[nSizeKey])
				--Set Data Value
				tData[strTextLoc].font.size = PotatoLib.ktFonts[nBaseKey].sizes[nSizeKey]	
				
				--Populate Text Options for Size	
				local wndPropOpts = wndControl:GetParent():GetParent():GetParent():FindChild("TxtProps")
				wndPropOpts:FindChild("Bold"):Enable(false)
				wndPropOpts:FindChild("BigBold"):Enable(false)
				wndPropOpts:FindChild("Italic"):Enable(false)
				wndPropOpts:FindChild("Outline"):Enable(false)
				wndPropOpts:SetRadioSel("TxtWeight", 0)
				
				for key,val in pairs(PotatoLib.ktFonts[nBaseKey].sizeProp[tFontData.size..""]) do
					if val == "B" then
						wndPropOpts:FindChild("Bold"):Enable(true)
					elseif val == "BB" then
						wndPropOpts:FindChild("BigBold"):Enable(true)
					elseif val == "BO" then
						wndPropOpts:FindChild("Bold"):Enable(true)
						wndPropOpts:FindChild("Outline"):Enable(true)
					elseif val == "BBO" then
						wndPropOpts:FindChild("BigBold"):Enable(true)
						wndPropOpts:FindChild("Outline"):Enable(true)
					elseif val == "I" then
						wndPropOpts:FindChild("Italic"):Enable(true)
					elseif val == "O" then
						wndPropOpts:FindChild("Outline"):Enable(true)
					end
				end
				
				wndTarget:SetFont(PotatoLib:FontTableToString(tData[strTextLoc].font))
			else
				Print("[PotatoUI] ERROR NSIZEKEY")
			end
		else
			Print("[PotatoUI] ERROR NBASEKEY")
		end
	end
end

function PotatoFrames:OnTxtWeight( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	
	local strTextLoc = wndControl:GetParent():GetParent():GetName()
	
	local tData, wndTarget = nil, nil
	local strProp = ""
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetParent():GetData().bar
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name..strTextLoc)

	if wndTarget ~= nil then
		local tFontData = tData[strTextLoc].font
		
		local tProps = {
			[0] = "",
			[1] = "B",
			[2] = "BB",
			[3] = "I"
		}
		
		local nWeight = wndHandler:GetParent():GetRadioSel("TxtWeight")
		strProp = tProps[nWeight]
		
		if nWeight == 3 then
			wndHandler:GetParent():FindChild("Outline"):Enable(false)
		else
			wndHandler:GetParent():FindChild("Outline"):Enable(true)
		end
	
		if wndHandler:GetParent():FindChild("Outline"):IsChecked() then
			strProp = strProp .. "O"
		end
	
		tData[strTextLoc].font.props = strProp
		wndTarget:SetFont(PotatoLib:FontTableToString(tData[strTextLoc].font))
	end
end

function PotatoFrames:OnChangeResBar( wndHandler, wndControl, eMouseButton )
	local nFrameId = self.wndCustomize:GetData()
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar
	
	local nShow = wndHandler:GetParent():GetRadioSel("ShowResBar")
	self.tFrames[nFrameId].frameData.barStyles[nBarId].showResBar = nShow == 1 and true or false
	self:UpdateFrameAppearance(self.tFrames[nFrameId].window)
end

function PotatoFrames:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)
end

function PotatoFrames:OnSetBarColor(wndHandler)
	local nFrameId = self.wndCustomize:GetData() or 0	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar	
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	self.tempcolor = tData.color
	PotatoLib:ColorPicker("tempcolor", self, self["Update"..tData.name.."BarColor"], wndHandler)
end

function PotatoFrames:UpdateHPBarColor()
	self:UpdateFrameBarColor(1)
end

function PotatoFrames:UpdateSPBarColor()
	self:UpdateFrameBarColor(2)
end

function PotatoFrames:UpdateAPBarColor()
	self:UpdateFrameBarColor(3)
end

function PotatoFrames:UpdateRPBarColor()
	self:UpdateFrameBarColor(4)
end

function PotatoFrames:UpdateFrameBarColor(nBarId)
	local nFrameId = self.wndCustomize:GetData() or 0
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name.."Bar")
	
	tData.color = self.tempcolor
	
	local strFinalColor = string.format("%x", (tData.transparency/100)*255)..tData.color
	if wndTarget.SetBarColor ~= nil then
		wndTarget:SetBarColor(strFinalColor)
	else
		wndTarget:SetBGColor(strFinalColor)
	end
	
	self.wndCustomize:FindChild(tData.name.."Bar:ColorChoice:CustomColor:Color"):SetBGColor("FF"..tData.color)
	
	self.wndCustomize:FindChild(tData.name.."Bar:ColorChoice:CustomColor:HexText"):SetText(tData.color)
	self.wndCustomize:FindChild(tData.name.."Bar:BarTexture:BarType:CurrentVal"):SetBGColor("FF"..tData.color)
end

function PotatoFrames:OnColorHexChanged( wndHandler, wndControl, strColor )
	local nFrameId = self.wndCustomize:GetData() or 0

	strColor = string.gsub(strColor, "[^0-9A-Fa-f]", "")
	
	local nBarId = wndHandler:GetParent():GetParent():GetParent():GetData().bar	
	local tData = self.tFrames[nFrameId].frameData.barStyles[nBarId]
	local wndTarget = self.tFrames[nFrameId].window:FindChild(tData.name.."Bar")
	
	if wndTarget ~= nil then
		tData.color = strColor
		
		local strFinalColor = string.format("%x", (tData.transparency/100)*255)..strColor
		if wndTarget.SetBarColor ~= nil then
			wndTarget:SetBarColor(strFinalColor)
		else
			wndTarget:SetBGColor(strFinalColor)
		end
		wndHandler:GetParent():FindChild("Color"):SetBGColor("FF"..strColor)
	end
	wndHandler:SetText(strColor)
	wndHandler:SetSel(#strColor, #strColor)
end

function PotatoFrames:OnUnitframeClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	local elementTarget = wndHandler:GetData() ~= nil and wndHandler:GetData().unit or nil
	
	if not bEditorMode then --Double check, although this shouldn't happen.
		if eMouseButton == 0 then --Left clicked on a frame
			if elementTarget or elementTarget ~= nil then
				--Target unit
				GameLib.SetTargetUnit(elementTarget)
			end
		elseif eMouseButton == 1 then
			local nFrameId = wndHandler:GetData().id
			if nFrameId < 5 then
				Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", wndHandler, elementTarget:GetName(), elementTarget)
			else --Pet Frames (stance menu)
				if self.tFrames[nFrameId].window:FindChild("StanceMenuBG") then
					self.tFrames[nFrameId].window:FindChild("StanceMenuBG"):Destroy()
				end
				local wndPetStance = Apollo.LoadForm("PotatoFrames.xml", "StanceMenuBG", self.tFrames[nFrameId].window, self)
				wndPetStance:SetData({id=nFrameId})
				for idx=1, 5 do
					local nCurrPetStance= Pet_GetStance(self.tFrames[nFrameId].window:GetData().unit:GetId())

					wndPetStance:FindChild("Stance"..idx):FindChild("StanceText"):SetTextColor(idx == nCurrPetStance and "FFFFFF00" or "FFFFFFFF")
					wndPetStance:FindChild("Stance"..idx):ChangeArt(idx == nCurrPetStance and "CRB_Basekit:kitBtn_List_HoloSort" or "CRB_Basekit:kitBtn_List_Holo")
				end
				wndPetStance:Show(true) 
			end
		end
	end
end

function PotatoFrames:OnGenerateUnitTooltip( wndHandler, wndControl, eToolTipType, x, y )
	--TODO: Create unit tooltip
	--[[Print(wndHandler:GetName())
	Print(wndControl:GetName())
	Print(wndHandler:GetData().unit:GetName())]]--
	--[[local ToolTips = Apollo.GetAddon("ToolTips")
	
	if ToolTips then
		ToolTips:UnitTooltipGen(GameLib.GetWorldTooltipContainer(), wndHandler:GetData().unit, "")
	end]]--
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------

function PotatoFrames:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	local nFrameId = wndHandler:GetParent():GetParent():GetData().id
	
	self:OpenEditor(nFrameId)
	self:SelectFrame(wndHandler:GetParent():GetParent())
end

function PotatoFrames:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	local nFrameId = wndHandler:GetParent():GetParent():GetData().id

	PotatoLib:HandleLockedWnd(self.tFrames[nFrameId].window, "Frame"..nFrameId)
end

function PotatoFrames:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end

	local nFrameId = wndHandler:GetParent():GetParent():GetData().id
	
	self:ResetFrame(self.tFrames[nFrameId].window)
end

function PotatoFrames:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	local nFrameId = wndHandler:GetParent():GetData().id
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			self:OpenEditor(nFrameId)
		end
		self:SelectFrame(self.tFrames[nFrameId].window, wndControl)
	end
end

---------------------------------------------------------------------------------------------------
-- StanceMenuBG Functions
---------------------------------------------------------------------------------------------------

function PotatoFrames:OnDismissBtn( wndHandler, wndControl, eMouseButton )
	wndHandler:FindChild("YesNo"):Show(not wndHandler:FindChild("YesNo"):IsVisible())
	local frameId = wndHandler:GetParent():GetParent():GetParent():GetData().id --TODO: There has got be a better way
	
	if frameId == 5 then
		wndHandler:FindChild("DismissYes"):SetContentId(24)
	end
	if frameId == 6 then
		wndHandler:FindChild("DismissYes"):SetContentId(36)
	end
end

function PotatoFrames:OnStanceBtn( wndHandler, wndControl, eMouseButton )
	local frameId = wndHandler:GetParent():GetParent():GetData().id
	local nStance = string.gsub(wndHandler:GetName(), "Stance", "") + 0	
	
	Pet_SetStance(self.tFrames[frameId].window:GetData().unit:GetId(), nStance) --Pet_SetStance(nPetId, nStance) where nPetId == 0 is all pets
	self.tFrames[frameId].window:FindChild("StanceMenuBG"):Show(false)
end

function PotatoFrames:OnDismissNo( wndHandler, wndControl, eMouseButton )
	wndHandler:GetParent():Show(false)
end

function PotatoFrames:OnDismissYesCover( wndHandler, wndControl, eMouseButton )
	Sound.Play(2)
end

function PotatoFrames:OnDismissHover( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end

	local strName = wndHandler:GetName()

	if strName == "DismissYesCover" then
		wndHandler:SetBGColor("FF00AA00")
	else
		wndHandler:SetBGColor("FFAA0000")
	end
end

function PotatoFrames:OnDismissExit( wndHandler, wndControl, x, y )
	if wndHandler ~= wndControl then return end
	
	local strName = wndHandler:GetName()

	if strName == "DismissYesCover" then
		wndHandler:SetBGColor("FF007700")
	else
		wndHandler:SetBGColor("FF770000")
	end
end

-----------------------------------------------------------------------------------------------
-- PotatoFrames Instance
-----------------------------------------------------------------------------------------------
local PotatoFramesInst = PotatoFrames:new()
PotatoFramesInst:Init()