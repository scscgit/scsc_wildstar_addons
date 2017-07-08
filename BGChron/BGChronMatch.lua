-----------------------------------------------------------------------------------------------
-- Client Lua Script for BGChron
-- Copyright orbv, Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

local BGChron = Apollo.GetAddon("BGChron")
if not BGChron then return end

local _VersionWindow = BGChron._VersionWindow
local _defaultSettings = BGChron._defaultSettings

local _tSupportedGameTypes = BGChron._tSupportedGameTypes
local _tGameType2GameSet = BGChron._tGameType2GameSet
local _eGameTypes = BGChron._eGameTypes
local _eResultTypes = BGChron._eResultTypes

-----------------------------------------------------------------------------------------------
-- BGChronMatch Module Definition
-----------------------------------------------------------------------------------------------
local BGChronMatch = {}
BGChron.BGChronMatch = BGChronMatch

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------


local _eMatchType = MatchMakingLib.MatchType
local _eRatingType = MatchMakingLib.RatingType

local _floor = math.floor
local _sqrt = math.sqrt
local _abs = math.abs
local _format = string.format
local _tinsert = table.insert
local _date = os.date

local _print = BGChron._print
local print = _print

local _tMatchNamesArena = {
	[2] = "Open Arena (2v2)",
	[3] = "Open Arena (3v3)",
	[5] = "Open Arena (5v5)"
}

local ktRatingTypesToString = {
	[_eRatingType.Arena2v2]          = "Rated Arena (2v2)",
	[_eRatingType.Arena3v3]          = "Rated Arena (3v3)",
	[_eRatingType.Arena5v5]          = "Rated Arena (5v5)",
	[_eRatingType.RatedBattleground] = "Rated Battleground",
	--[_eRatingType.Warplot]           = "Warplot"
}

local kstrClassToMLIcon = {
	[GameLib.CodeEnumClass.Warrior]     = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Warrior\"></T> ",
	[GameLib.CodeEnumClass.Engineer]    = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Engineer\"></T> ",
	[GameLib.CodeEnumClass.Esper]       = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Esper\"></T> ",
	[GameLib.CodeEnumClass.Medic]       = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Medic\"></T> ",
	[GameLib.CodeEnumClass.Stalker]     = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Stalker\"></T> ",
	[GameLib.CodeEnumClass.Spellslinger]  = "<T Image=\"CRB_Raid:sprRaid_Icon_Class_Spellslinger\"></T> ",
}

local ktEventTypeToWindowName = {
	[PublicEvent.PublicEventType_PVP_Arena]                     = "PvPArenaContainer",
	[PublicEvent.PublicEventType_PVP_Warplot]                   = "PvPWarPlotContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]  = "PvPHoldContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex]       = "PvPCTFContainer",
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]     = "PvPSaboContainer",
}

-- necessary until we can either get column names for a compare/swap or a way to set localized strings in XML for columns
local ktEventTypeToColumnNameList = {
	[PublicEvent.PublicEventType_PVP_Arena] = {
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves"
	},
	[PublicEvent.PublicEventType_PVP_Warplot] = {
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine] = {
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_Captures",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex] = {
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_Captures",
		"PublicEventStats_Stolen",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	},
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage] = {
		"PublicEventStats_Name",
		"PublicEventStats_Kills",
		"PublicEventStats_Deaths",
		"PublicEventStats_Assists",
		"PublicEventStats_DamageDone",
		"PublicEventStats_HealingDone",
		"PublicEventStats_DamageTaken",
		"PublicEventStats_HealingTaken",
		"PublicEventStats_Saves",
		"PublicEventStats_KillStreak"
	}
}
for _,v in pairs(ktEventTypeToColumnNameList) do
	for i,v2 in pairs(v) do
		v[i] = Apollo.GetString(v2)
	end
end

local _tParticipantKeys = {		-- Can swap to event type id's, but this just saves space
	["Arena"] = {
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves"
	},
	["WarPlot"] = {
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},
	["HoldTheLine"] = {
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		1,	--ktEventTypeToColumnNameList[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine][5],	--"nCustomNodesCaptured",		--FIXME: all columns are hard coded atm, from xml UI to code 
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},
	["CTF"] = {
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		1,	--ktEventTypeToColumnNameList[PublicEvent.PublicEventType_PVP_Battleground_Vortex][5],		--"nCustomFlagsPlaced",
		2,	--ktEventTypeToColumnNameList[PublicEvent.PublicEventType_PVP_Battleground_Vortex][6],		--"bCustomFlagsStolen",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	},
	["Sabotage"] = {
		"strName",
		"nKills",
		"nDeaths",
		"nAssists",
		"nDamage",
		"nHealed",
		"nDamageReceived",
		"nHealingReceived",
		"nSaves",
		"nKillStreak"
	}
}

local ktMatchTypeKeys = {
	[_eGameTypes.Battleground]      = {
		"strDate",
		"strMatchType",
		"strResult",
		"strMatchTime",
		"strGroupType"
	},
	[_eGameTypes.RatedArena]             = {
		"strDate",
		"strMatchType",
		"strResult",
		"strRating",
		"strMatchTime",
		"strTeamName"
	},
	[_eGameTypes.RatedBattleground] = {
		"strDate",
		"strMatchType",
		"strResult",
		"strRating",
		"strMatchTime",
		"strGroupType"
	},
	[_eGameTypes.Arena]         = {
		"strDate",
		"strMatchType",
		"strResult",
		"strMatchTime",
		"strGroupType"
	}
}
BGChronMatch.ktMatchTypeKeys = ktMatchTypeKeys


local _tRatingTypeToGuildType = {
	[_eRatingType.Arena2v2] = GuildLib.GuildType_ArenaTeam_2v2,
	[_eRatingType.Arena3v3] = GuildLib.GuildType_ArenaTeam_3v3,
	[_eRatingType.Arena5v5] = GuildLib.GuildType_ArenaTeam_5v5
}

-- dopes a BGChron tGame with BGChronMatch
function BGChronMatch:new(o)
	o = o or {}   -- create object if user does not provide one
	local this = BGChronMatch		-- ensure this accidentally keeps building layers
	setmetatable(o, this)
	this.__index = this
	--o = o or {}   -- create object if user does not provide one
	--setmetatable(o, self)
	--self.__index = self

	--o.nMatchEnteredTick = nil			-- these were setting nil on self not o, i think this is a null op and an accident
	--o.nMatchEndedTick	= nil			--  and problaby saved from callers data gettign clobbered

	--nElapsedTime = nil				-- stats. these are from OnPublicEventEnd(tStats)
	--arTeamStats or {},				-- stats
	--arParticipantStats or {}			-- stats, arPersonalStats is skipped but o.strName should be key to similar record in arParticipantStats

	--o.tArenaTeamInfo = nil
	--o.nMatchType = nil
	--o.nEventType = nil
	--o.nMatchResult = nil

	--o.nRatingType = nil
	--o.nBeginRating = nil
	--o.nEndRating = nil
	--o.strTeamName = nil

	--o.nTeamSize = nil
	--o.bQueuedAsGroup = nil
	--o.nGroupSize = nil

	return o
end

-- Returns data formatted for a grid
function BGChronMatch:GetFormattedData()
	return {
		["strDate"]      = self.nMatchEndedTick and _format("%s", _date("%c", self.nMatchEndedTick)) or "N/A",
		["strMatchType"] = self:GetMatchTypeString(),
		["strResult"]    = self:GetResultString(),
		["strRating"]    = self:GetRatingString(),
		["strMatchTime"] = self:GetMatchTimeString(),
		["strTeamName"]  = self:GetTeamNameString(),
		["strGroupType"] = self:GetGroupTypeString()
	}
end

-- Returns sort text for a grid
function BGChronMatch:GetFormattedSortData()
	return {
		["strDate"]      = self:GetDateSortString(),
		["strMatchType"] = self:GetMatchTypeString(),
		["strResult"]    = self:GetResultString(),
		["strRating"]    = self:GetRatingSortString(),
		["strMatchTime"] = self:GetMatchTimeSortString(),
		["strTeamName"]  = self:GetTeamNameString(),
		["strGroupType"] = self:GetGroupTypeString()
	}
end

function BGChronMatch:GenerateRatingInfo()
	local eGameType = self.nMatchType
	if not _tSupportedGameTypes[eGameType] then
		return
	end

	Print("Generating Rating Info")

	local eRatingType

	if eGameType == _eGameTypes.RatedBattleground then
		eRatingType = _eRatingType.RatedBattleground
	elseif eGameType == _eGameTypes.RatedArena then
		if self.nTeamSize == 2 then
			eRatingType = _eRatingType.Arena2v2
		elseif self.nTeamSize == 3 then
			eRatingType = _eRatingType.Arena3v3
		elseif self.nTeamSize == 5 then
			eRatingType = _eRatingType.Arena5v5
		end
	end

	local tRatingInfo = eRatingType and MatchMakingLib.GetPvpRatingByType(eRatingType)

	local strTeamName
	local eGuildType = _tRatingTypeToGuildType[eRatingType]
	if eGuildType then
		for _,v in pairs(GuildLib.GetGuilds()) do
			if v:GetType() == eGuildType then
				strTeamName = v:GetName();  break
			end
		end
	end

	self.nRatingType = eRatingType
	self.nBeginRating = tRatingInfo and tRatingInfo.nRating or nil
	self.nEndRating = nil
	self.strTeamName = strTeamName
end


-----------------------------------------------------------------------------------------------
-- Drawing Method
-----------------------------------------------------------------------------------------------

function BGChronMatch:Redraw(wndMatchForm)
	local game = wndMatchForm:GetData()
	if not game.arTeamStats or not game.arParticipantStats then
		return
	end

	-- build list

	local tGameStats = {}
	tGameStats.tStatsTeam = BGChron:UncompressStats(self.arTeamStats)
	tGameStats.tStatsParticipants = BGChron:UncompressStats(self.arParticipantStats)

--	for key, tCurr in pairs(game.arTeamStats) do
--		if not tGameStats.tStatsTeam then
--			tGameStats.tStatsTeam = {}
--		end
--		_tinsert(tGameStats.tStatsTeam, tCurr)
--	end

--	for key, tCurr in pairs(game.arParticipantStats) do
--		if not tGameStats.tStatsParticipants then
--			tGameStats.tStatsParticipants = {}
--		end
--		_tinsert(tGameStats.tStatsParticipants, tCurr)
--	end

	-- build

	for key, wndCurr in pairs(wndMatchForm:FindChild("MainGridContainer"):GetChildren()) do
		wndCurr:Show(false)
	end

	local eEventType = self.nEventType
	local wndGrid = wndMatchForm:FindChild(ktEventTypeToWindowName[eEventType])

	if eEventType == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
		self:HelperBuildPvPSharedGrids(wndGrid, tGameStats, "HoldTheLine")

	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
		self:HelperBuildPvPSharedGrids(wndGrid, tGameStats, "CTF")

	elseif eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		self:HelperBuildPvPSharedGrids(wndGrid, tGameStats, "WarPlot")

	elseif eEventType == PublicEvent.PublicEventType_PVP_Arena then
		self:HelperBuildPvPSharedGrids(wndGrid, tGameStats, "Arena")

	elseif eEventType == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
		self:HelperBuildPvPSharedGrids(wndGrid, tGameStats, "Sabotage")
	end

	-- Title Text (including timer)
	-- TODO: Update this to something useful
	local strTitleText = "Match Detail"

	wndMatchForm:FindChild("EventTitleText"):SetText(strTitleText)

	if wndGrid then
		wndGrid:Show(true)
	end

	if not wndMatchForm:IsShown() then
		wndMatchForm:Show(true)
		wndMatchForm:ToFront()
	end
end


-----------------------------------------------------------------------------------------------
-- Data Formatting Functions
-----------------------------------------------------------------------------------------------

local _tEventTypeToMapName = {
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex]		= "Walatiki Temple",
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]	= "Halls of the Bloodsworn",
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]		= "Daggerstone"
}

function BGChronMatch:GetMatchTypeString()
	result = "N/A"

	if _tEventTypeToMapName[self.nEventType] ~= nil then
		result = _tEventTypeToMapName[self.nEventType]

	elseif self.nRatingType then
		-- Rated
		result = ktRatingTypesToString[self.nRatingType]

	elseif self.nMatchType then
		-- Non Rated
		if self.nMatchType == _eGameTypes.Arena then
			result = _tMatchNamesArena[self.nTeamSize]
		else
			local sGameSet = _tGameType2GameSet[self.nMatchType]
			result = BGChron._tGameSet2Name[sGameSet]
			--result = ktMatchTypes[self.nMatchType]
		end
	end

	return result
end

function BGChronMatch:GetResultString()
	local result = "N/A"

	local ktResultTypes = {
		[_eResultTypes.Win]     = "Win",
		[_eResultTypes.Loss]    = "Loss",
		[_eResultTypes.Forfeit] = "Forfeit"
	}

	if self.nResult then
		result = ktResultTypes[self.nResult]
	end

	return result
end

function BGChronMatch:GetRatingString()
	local result = "N/A"

	if not self.nBeginRating or not self.nEndRating then
		return result
	end

	local nBeginRating = self.nBeginRating
	local nEndRating  = self.nEndRating

	if nBeginRating and nEndRating then
		if nBeginRating < nEndRating then
			result = _format("%d (+%d)", nEndRating, (nEndRating - nBeginRating))
		elseif nBeginRating > nEndRating then
			result = _format("%d (-%d)", nEndRating, (nBeginRating - nEndRating))
		end
	end

	return result
end

function BGChronMatch:GetMatchTimeString()
	local nStart,nEnd = self.nMatchEnteredTick, self.nMatchEndedTick
	return (nStart and nEnd) and os.date("%M:%S", nEnd - nStart) or "N/A"
end

function BGChronMatch:GetGroupTypeString()
	local bQueuedAsGroup = self.bQueuedAsGroup

	local result = "N/A"

	if bQueuedAsGroup == nil then
		return result
	end

	if bQueuedAsGroup then
		result = "Group"
	else
		result = "Solo"
	end

	return result
end

function BGChronMatch:GetTeamNameString()
	return self.strTeamName or "N/A"
end

function BGChronMatch:GetDateSortString()
	local result = ""

	if self.nMatchEndedTick then
		result = self.nMatchEndedTick
	end

	return result
end

function BGChronMatch:GetRatingSortString()
	return self.nEndRating or ""
end

function BGChronMatch:GetMatchTimeSortString()
	return self.nElapsedTime or ""
end

function BGChronMatch:CreateGameStatsGrid(wndMatchForm)
	local eEventType = self.nEventType
	local wndParent = wndMatchForm:FindChild(ktEventTypeToWindowName[eEventType])

	local wndGrid = wndParent

	local tNames = ktEventTypeToColumnNameList[eEventType]

	if wndGrid:GetName() ~= "PublicEventGrid" then
		wndGrid = wndParent:FindChild("PvPTeamGridBot")

		for idx = 1, wndGrid:GetColumnCount() do
			wndGrid:SetColumnText(idx, tNames[idx])
		end

		wndGrid = wndParent:FindChild("PvPTeamGridTop")
	end

	local nMaxWndMainWidth = wndMatchForm:GetWidth() - wndGrid:GetWidth() + 15		-- magic number for the width of the scroll bar
	for idx = 1, wndGrid:GetColumnCount() do
		nMaxWndMainWidth = nMaxWndMainWidth + wndGrid:GetColumnWidth(idx)
		wndGrid:SetColumnText(idx, tNames[idx])
	end

	wndMatchForm:SetSizingMinimum(500, 500)
	wndMatchForm:SetSizingMaximum(nMaxWndMainWidth, 800)

	wndMatchForm:SetData(self)
	wndMatchForm:Show(false)

	self:Redraw(wndMatchForm)
end


-----------------------------------------------------------------------------------------------
-- Grid Building
-----------------------------------------------------------------------------------------------

function BGChronMatch:HelperBuildPvPSharedGrids(wndParent, tGameStats, eEventType)
	if not wndParent or not tGameStats then
		return
	end

	local gridTop = wndParent:FindChild("PvPTeamGridTop")
	local gridBot = wndParent:FindChild("PvPTeamGridBot")
	local headerTop = wndParent:FindChild("PvPTeamHeaderTop")
	local headerBot = wndParent:FindChild("PvPTeamHeaderBot")

	local nVScrollPosTop = gridTop:GetVScrollPos()
	local nVScrollPosBot = gridBot:GetVScrollPos()
	local nSortedColumnTop = gridTop:GetSortColumn() or 1
	local nSortedColumnBot = gridBot:GetSortColumn() or 1
	local bAscendingTop = gridTop:IsSortAscending()
	local bAscendingBot = gridBot:IsSortAscending()

	gridTop:DeleteAll()
	gridBot:DeleteAll()

	local strMyTeamName = ""

	for _,v in pairs(tGameStats.tStatsTeam) do
		local wndHeader = nil
		local tdTop = headerTop:GetData()
		local tdBot = headerBot:GetData()
		if not tdTop or tdTop == v.strTeamName then
			wndHeader = headerTop
			gridTop:SetData(v.strTeamName)
			headerTop:SetData(v.strTeamName)
		elseif not tdBot or tdBot == v.strTeamName then
			wndHeader = headerBot
			gridBot:SetData(v.strTeamName)
			headerBot:SetData(v.strTeamName)
		end

		local strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
		local crTitleColor = ApolloColor.new("ff7fffb9")
		local strDamage = String_GetWeaselString(Apollo.GetString("PublicEventStats_Damage"), self:HelperFormatNumber(v.nDamage))
		local strHealed = String_GetWeaselString(Apollo.GetString("PublicEventStats_Healing"), self:HelperFormatNumber(v.nHealed))

		-- Setting up the team names / headers
		if eEventType == "CTF" or eEventType == "HoldTheLine" or eEventType == "Sabotage" then
			if v.strTeamName == "Exiles" then
				crTitleColor = ApolloColor.new("ff31fcf6")
			elseif v.strTeamName == "Dominion" then
				crTitleColor = ApolloColor.new("ffb80000")
			end
			local strKDA = String_GetWeaselString(Apollo.GetString("PublicEventStats_KDA"), v.nKills, v.nDeaths, v.nAssists)

			strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_PvPHeader"), strKDA, strDamage, strHealed)
		elseif eEventType == "Arena" then
			strHeaderText = String_GetWeaselString(Apollo.GetString("PublicEventStats_ArenaHeader"), strDamage, strHealed) -- TODO, Rating Change when support is added
			if v.bIsMyTeam then
				strMyTeamName = v.strTeamName
			end
		elseif eEventType == "Warplot" then
			strHeaderText = wndHeader:FindChild("PvPHeaderText"):GetData() or ""
		end

		wndHeader:FindChild("PvPHeaderText"):SetText(strHeaderText)
		wndHeader:FindChild("PvPHeaderTitle"):SetTextColor(crTitleColor)
		wndHeader:FindChild("PvPHeaderTitle"):SetText(v.strTeamName)
	end

	local sGridTopTeamName = gridTop:GetData()
	local _LPublicEventStats_SecondaryPointCaptured = Apollo.GetString("PublicEventStats_SecondaryPointCaptured")

	for _,v in pairs(tGameStats.tStatsParticipants) do
		local wndGrid = gridBot
		if gridTop:GetData() == v.strTeamName then
			wndGrid = gridTop
		end

		local wRow = self:HelperGridFactoryProduce(wndGrid, v.strName)
		wndGrid:SetCellLuaData(wRow, 1, v.strName)

		for i2,sKey in pairs(_tParticipantKeys[eEventType]) do
			local v2 = v[type(sKey) == "number" and (v[sKey] or 0) or sKey]		-- numbers are custom fields that have an indirect lookup in an attempt to be language neutral across possible client language changes

			wndGrid:SetCellSortText(wRow, i2, type(v2) == "number" and _format("%8d", v2) or v2 or 0)

			local strClassIcon = i2 == 1 and kstrClassToMLIcon[v.eClass] or ""

			v2 = "<T Font=\"CRB_InterfaceSmall\">" .. strClassIcon .. self:HelperFormatNumber(v2) .. "</T>"
			--v2 = _format("<T Font=\"CRB_InterfaceSmall\">%s%s</T>", strClassIcon, self:HelperFormatNumber(v2))
			wndGrid:SetCellDoc(wRow, i2, v2)
		end
	end

	gridTop:SetVScrollPos(nVScrollPosTop)
	gridTop:SetSortColumn(nSortedColumnTop, bAscendingTop)

	gridBot:SetVScrollPos(nVScrollPosBot)
	gridBot:SetSortColumn(nSortedColumnBot, bAscendingBot)
end


-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function BGChronMatch:HelperFormatNumber(nArg)
	local n = tonumber(nArg)
	if n and n > 10000 then
		nArg = String_GetWeaselString(Apollo.GetString("PublicEventStats_Thousands"), _floor(n / 1000))
	else
		nArg = tostring(nArg)
	end
	return nArg
end

function BGChronMatch:HelperConvertTimeToString(fTime)
	fTime = math.floor(fTime / 1000) -- TODO convert to full seconds

	return _format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60))
end

function BGChronMatch:HelperGridFactoryProduce(wndGrid, tTargetComparison)
	for nRow = 1, wndGrid:GetRowCount() do
		if wndGrid:GetCellLuaData(nRow, 1) == tTargetComparison then -- GetCellLuaData args are row, col
			return nRow
		end
	end
	return wndGrid:AddRow("") -- GOTCHA: This is a row number
end
