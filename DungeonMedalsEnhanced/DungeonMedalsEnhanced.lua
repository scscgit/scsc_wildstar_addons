-----------------------------------------------------------------------------------------------
-- Client Lua Script for Protogames
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Apollo"
require "Sound"
require "GameLib"
require "PublicEvent"

local DungeonMedalsEnhanced = {}

local kstrNoMedal		= "Protogames:spr_Protogames_Icon_MedalFailed"
local kstrBronzeMedal	= "Protogames:spr_Protogames_Icon_MedalBronze"
local kstrSilverMedal	= "Protogames:spr_Protogames_Icon_MedalSilver"
local kstrGoldMedal		= "Protogames:spr_Protogames_Icon_MedalGold"

local LuaEnumDungeonTime =
{
	Stormtalon					= 40*60,
	KelVoreth					= 40*60,
	Skullcano					= 45*60,
	TorineSanctuary				= 60*60,
	ProtoAcademy				= 23*60,
}

local LuaEnumDungeonEvents =
{
	Stormtalon 					= "The Birth of a Corrupted God",
	KelVoreth 					= "Forging an Armageddon",
	Skullcano					= "No Merrier Place Than Hell",
	TorineSanctuary				= "The Sanctuary Defiled",
	ProtoAcademy				= "Protogames Academy",
}

local LuaEnumObjectives =
{
	StormtalonBoss				= 3,
	StormtalonDeathless			= 14,
	StormtalonTimer				= 21,
	StormtalonLastChallenge		= 0,

	KelVorethBoss				= 6,
	KelVorethDeathless			= 12,
	KelVorethTimer				= 18,
	KelVorethLastChallenge		= 17,

	SkullcanoBoss  				= 4,
	SkullcanoDeathless  		= 21,
	SkullcanoTimer  			= 27,
	SkullcanoLastChallenge		= 0,
	
	TorineSanctuaryBoss			= 7,
	TorineSanctuaryDeathless	= 33,
	TorineSanctuaryTimer		= 41,
	StormtalonLastChallenge		= 40,
	
	ProtoAcademyBoss			= 5,
	ProtoAcademyDeathless		= 33,
	ProtoAcademyTimer			= 32,
	StormtalonLastChallenge		= 0,
}

function DungeonMedalsEnhanced:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function DungeonMedalsEnhanced:Init()
	Apollo.RegisterAddon(self)
end

function DungeonMedalsEnhanced:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("DungeonMedalsEnhanced.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
	
	self:InitializeVars()
end

function DungeonMedalsEnhanced:InitializeVars()
	self.nTimeElapsed = 0
	self.nPointDelta = 0
	self.nPoints	= 0
	self.nBronze = 0
	self.nSilver = 0
	self.nGold = 0
	self.peMatch = nil
	self.nExpectedPoints = 0
end

function DungeonMedalsEnhanced:OnDocumentReady()
	if not self.xmlDoc then
		return
	end
	
	Apollo.RegisterEventHandler("ChangeWorld", 						"Reset", self)
	Apollo.RegisterEventHandler("PublicEventStart",					"CheckForDungeon", self)
	Apollo.RegisterEventHandler("MatchEntered", 					"CheckForDungeon", self)
	Apollo.RegisterEventHandler("PublicEventStatsUpdate", 			"OnPublicEventStatsUpdate", self)
	
	self.timerMatchOneSec = ApolloTimer.Create(1.0, true, "OnOneSecTimer", self)
	self.timerPointsCleanup = ApolloTimer.Create(1.5, true, "OnPointsCleanUpTimer", self)
	self.timerPointsCleanup:Stop()
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "DungeonMedalsMain", "FixedHudStratum", self)
	
	if not self:CheckForDungeon() then
		self:Reset()
	end
end


function DungeonMedalsEnhanced:Reset()
	self.wndMain:Show(false)
	self.timerMatchOneSec:Stop()
	self.timerPointsCleanup:Stop()
	
	self:InitializeVars()
end

function DungeonMedalsEnhanced:UpdatePoints()
	local additionalText = ""
	if self.peMatch then
		self.nPoints			= self.peMatch:GetStat(PublicEvent.PublicEventStatType.MedalPoints)
		if self.nPoints == nil then
			return
		end
		local bonus = 0
		local deathlessId = 0
		local timeId = 0
		local dungeonEndbossId = 0
		local allowedTime = 0
		if self.peMatch:GetName() == LuaEnumDungeonEvents.Stormtalon then
			deathlessId = LuaEnumObjectives.StormtalonDeathless
			timeId = LuaEnumObjectives.StormtalonTimer
			dungeonEndbossId = LuaEnumObjectives.StormtalonBoss
			allowedTime = LuaEnumDungeonTime.Stormtalon
		elseif self.peMatch:GetName() == LuaEnumDungeonEvents.KelVoreth then
			deathlessId = LuaEnumObjectives.KelVorethDeathless
			timeId = LuaEnumObjectives.KelVorethTimer
			dungeonEndbossId = LuaEnumObjectives.KelVorethBoss
			allowedTime = LuaEnumDungeonTime.KelVoreth
		elseif self.peMatch:GetName() == LuaEnumDungeonEvents.Skullcano then
			deathlessId = LuaEnumObjectives.SkullcanoDeathless
			timeId = LuaEnumObjectives.SkullcanoTimer
			dungeonEndbossId = LuaEnumObjectives.SkullcanoBoss
			allowedTime = LuaEnumDungeonTime.Skullcano
		elseif self.peMatch:GetName() == LuaEnumDungeonEvents.TorineSanctuary then
			deathlessId = LuaEnumObjectives.TorineSanctuaryDeathless
			timeId = LuaEnumObjectives.TorineSanctuaryTimer
			dungeonEndbossId = LuaEnumObjectives.TorineSanctuaryBoss
			allowedTime = LuaEnumDungeonTime.TorineSanctuary
		elseif self.peMatch:GetName() == LuaEnumDungeonEvents.ProtoAcademy then
			deathlessId = LuaEnumObjectives.ProtoAcademyDeathless
			timeId = LuaEnumObjectives.ProtoAcademyTimer
			dungeonEndbossId = LuaEnumObjectives.ProtoAcademyBoss
			allowedTime = LuaEnumDungeonTime.ProtoAcademy
		end
		if self.peMatch:GetObjectives()[dungeonEndbossId] ~= nil and self.peMatch:GetObjectives()[deathlessId] ~= nil and self.peMatch:GetObjectives()[timeId] ~= nil then
			-- Get Dungeon time and deathless objectives
			if self.peMatch:GetObjectives()[deathlessId]:GetStatus() == 1 then
				additionalText = additionalText .. "\n(+3500 Deathless)" 
			    bonus = bonus + 3500
			end
			if self.peMatch:GetObjectives()[timeId]:GetStatus() == 1 then
				additionalText = additionalText .. "\n(+2500 Timer Bonus)"
			    bonus = bonus + 2500
				local spaces = ""
				local timePoints = tonumber(Apollo.FormatNumber(((allowedTime - self.peMatch:GetObjectives()[timeId]:GetElapsedTime() / 1000)), 0, false))
				if timePoints < 10 then
					spaces = "      "
				elseif timePoints < 100 then
					spaces = "    "
				elseif timePoints < 1000 then
					spaces = "  "
				end
				
				additionalText = additionalText .. "\n(+" .. spaces .. timePoints .. " Extra Time)"
			    bonus = bonus + timePoints
			end
			if self.nPoints ~= nil then
				self.nExpectedPoints = self.nPoints + bonus
			end
		else
			if self.nPoints ~= nil then
				self.nExpectedPoints = self.nPoints
			end
		end
	end
	
	local strVisible	= "ffffffff"
	local strDim		= "66ffffff"
	local strExpected   = "66bbbbbb"
	local strTooltip = ""
	
	-- Update Point Count
	self.wndMain:FindChild("Points"):SetText(Apollo.FormatNumber(self.nPoints, 0, true))
	
	-- Bronze - Tier 1
	strTooltip = Apollo.FormatNumber(self.nExpectedPoints, 0, true) .. " / " .. Apollo.FormatNumber(self.nBronze, 0, true) .. additionalText
	local wndBronze = self.wndMain:FindChild("Bronze")
	wndBronze:SetTooltip(Apollo.FormatNumber(self.nBronze, 0, true))
	wndBronze:SetBGColor(self.nPoints >= self.nBronze and strVisible or strDim)
	local wndTier1 = self.wndMain:FindChild("Tier1")
	wndTier1:FindChild("Active"):Show(self.nPoints < self.nBronze)
	local wndProgressBar = wndTier1:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nBronze)
	wndProgressBar:SetProgress(math.min(self.nBronze, self.nPoints))
	wndProgressBar:SetBarColor(self.nPoints >= self.nBronze and strDim or strVisible)
	self.wndMain:FindChild("Tier1"):FindChild("ProgressBarExpected"):SetMax(self.nBronze)
	self.wndMain:FindChild("Tier1"):FindChild("ProgressBarExpected"):SetProgress(math.min(self.nBronze, self.nExpectedPoints))
	self.wndMain:FindChild("Tier1"):FindChild("ProgressBarExpected"):SetBarColor(strExpected)
	self.wndMain:FindChild("Tier1"):FindChild("ProgressBarExpected"):SetTooltip(strTooltip)
	
	-- Silver - Tier 2
	strTooltip = Apollo.FormatNumber(self.nExpectedPoints, 0, true) .. " / " .. Apollo.FormatNumber(self.nSilver, 0, true) .. additionalText
	local wndSilver = self.wndMain:FindChild("Silver")
	wndSilver:SetTooltip(Apollo.FormatNumber(self.nSilver, 0, true))
	wndSilver:SetBGColor(self.nPoints >= self.nSilver and strVisible or strDim)
	local wndTier2 = self.wndMain:FindChild("Tier2")
	wndTier2:FindChild("Active"):Show(self.nPoints >= self.nBronze and self.nPoints < self.nSilver)
	wndProgressBar = wndTier2:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nSilver - self.nBronze)
	wndProgressBar:SetProgress(self.nPoints > self.nBronze and math.min(self.nSilver, self.nPoints - self.nBronze) or 0)
	wndProgressBar:SetBarColor(self.nPoints >= self.nSilver and strDim or strVisible)
	self.wndMain:FindChild("Tier2"):FindChild("ProgressBarExpected"):SetMax(self.nSilver - self.nBronze)
	self.wndMain:FindChild("Tier2"):FindChild("ProgressBarExpected"):SetProgress(self.nExpectedPoints > self.nBronze and math.min(self.nSilver, self.nExpectedPoints - self.nBronze) or 0)
	self.wndMain:FindChild("Tier2"):FindChild("ProgressBarExpected"):SetBarColor(strExpected)
	self.wndMain:FindChild("Tier2"):FindChild("ProgressBarExpected"):SetTooltip(strTooltip)

	-- Gold - Tier 3
	strTooltip = Apollo.FormatNumber(self.nExpectedPoints, 0, true) .. " / " .. Apollo.FormatNumber(self.nGold, 0, true) .. additionalText
	local wndGold = self.wndMain:FindChild("Gold")
	wndGold:SetTooltip(Apollo.FormatNumber(self.nGold, 0, true))
	wndGold:SetBGColor(self.nPoints >= self.nGold and strVisible or strDim)
	local wndTier3 = self.wndMain:FindChild("Tier3")
	wndTier3:FindChild("Active"):Show(self.nPoints >= self.nSilver and self.nPoints < self.nGold)
	wndProgressBar = wndTier3:FindChild("ProgressBar")
	wndProgressBar:SetMax(self.nGold - self.nSilver)
	wndProgressBar:SetProgress(self.nPoints > self.nSilver and math.min(self.nGold, self.nPoints - self.nSilver) or 0)
	wndProgressBar:SetBarColor(self.nPoints >= self.nGold and strDim or strVisible)
	wndTier3:FindChild("ProgressBarExpected"):SetMax(self.nGold - self.nSilver)
	wndTier3:FindChild("ProgressBarExpected"):SetProgress(self.nExpectedPoints > self.nSilver and math.min(self.nGold, self.nExpectedPoints - self.nSilver) or 0)
	wndTier3:FindChild("ProgressBarExpected"):SetBarColor(strExpected)
	wndTier3:FindChild("ProgressBarExpected"):SetTooltip(strTooltip)
end

function DungeonMedalsEnhanced:OnPointsCleanUpTimer()
	local nLeft, nTop, nRight, nBottom = self.wndPoints:GetAnchorOffsets()
	local tLoc = WindowLocation.new({ fPoints = { 0.5, 0, 0.5, 0 }, nOffsets = { nLeft-50, nTop-50, nRight-50, nTop-50 }})
	
	self.wndPoints:TransitionMove(tLoc, 1.0)
	self.wndPoints:Show(false, false, 1.0)
	self.nPointDelta = 0
	self.timerPointsCleanup:Stop()
end

function DungeonMedalsEnhanced:OnOneSecTimer()
	if self.peMatch then
		self.nTimeElapsed = self.peMatch:GetElapsedTime() > 0 and math.ceil(self.peMatch:GetElapsedTime() / 1000) or self.nTimeElapsed
	else
		self:CheckForDungeon()
		return
	end
	
	local nTime		= self.nTimeElapsed --+3600 (testing hour formatting)
	local nHours		= math.floor(nTime / 3600)
	local nMinutes	= math.floor((nTime - (nHours * 3600)) / 60)
	local nSeconds 	= nTime - (nHours * 3600) - (nMinutes * 60)
	
	local strTime 		= nHours > 0 
		and string.format("%02d:%02d:%02d", nHours, nMinutes, nSeconds) 
		or string.format("%02d:%02d", nMinutes, nSeconds)
	
	self.wndMain:FindChild("Time"):SetText(strTime)
	
	self.wndMain:Show(self.nTimeElapsed > 0)
	if self.peMatch then
		self:UpdatePoints()
	end
end

function DungeonMedalsEnhanced:CheckForDungeon()
	if self.peMatch then
		return true
	end
	
	for key, peCurrent in pairs(PublicEvent.GetActiveEvents()) do
		if peCurrent:ShouldShowMedalsUI() then
			self.nPoints = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_None)
			self.nBronze = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Bronze)
			self.nSilver = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Silver)
			self.nGold = peCurrent:GetRewardThreshold(PublicEvent.PublicEventRewardTier_Gold)
				
			self.peMatch = peCurrent
				
			self.timerMatchOneSec:Start()
			self:UpdatePoints()
			return true
		end
	end

	return false
end

function DungeonMedalsEnhanced:OnPublicEventStatsUpdate(peUpdated)
	if peUpdated:GetEventType() ~= PublicEvent.PublicEventType_Dungeon then
		return
	end
	local nCurrentPoints = peUpdated:GetStat(PublicEvent.PublicEventStatType.MedalPoints)
	if self.nPoints == nCurrentPoints then
		return
	end
	
	self.timerPointsCleanup:Stop()
	self.timerPointsCleanup:Start()
	
	ChatSystemLib.PostOnChannel(27, "You received " .. (nCurrentPoints - self.nPoints or 0) .. " points.")
	self.nPointDelta = self.nPointDelta + nCurrentPoints - self.nPoints
	if not self.wndPoints then
		self.wndPoints = Apollo.LoadForm(self.xmlDoc, "DungeonMedalsPlusPoints", "FixedHudStratumLow", self)
	else
		local tWndPointsOffsets = self.wndPoints:GetOriginalLocation():ToTable().nOffsets
		self.wndPoints:SetAnchorOffsets(tWndPointsOffsets[1], tWndPointsOffsets[2], tWndPointsOffsets[3], tWndPointsOffsets[4])
	end
	self.wndPoints:SetData(self.nPointDelta)
	self.wndPoints:SetText("+"..tostring(Apollo.FormatNumber(self.nPointDelta, 0, true)))
	self.wndPoints:Show(true, false, 1.0)
	
	self:UpdatePoints()
end

local DungeonMedalsEnhancedInstance = DungeonMedalsEnhanced:new()
DungeonMedalsEnhancedInstance:Init()

