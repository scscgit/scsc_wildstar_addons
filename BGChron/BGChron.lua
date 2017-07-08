-----------------------------------------------------------------------------------------------
-- Client Lua Script for BGChron
-- Copyright orbv, Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchMakingLib"
require "MatchingGameLib"

-----------------------------------------------------------------------------------------------
-- BGChron Module Definition
-----------------------------------------------------------------------------------------------
local _Version,_VersionMinor = 70523,0
local _AddonName,_VersionWindow = "BGChron", 1
local BGChron = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local PixiePlot = Apollo.GetPackage("Drafto:Lib:PixiePlot-1.4").tPackage
local BGChronMatch
local ktMatchTypeKeys

local _eMatchType = MatchMakingLib.MatchType
local _eRatingType = MatchMakingLib.RatingType

local _eSaveLevel = GameLib.CodeEnumAddonSaveLevel

local _defaultSettings = {	--type: 0 custom, 1 single check, 2 slider, 3 color, 4 radio, 5 text, 6 number, 7 check parts, 8 signal, 9 drop, 10 check drop
	-- Main
	--["bHidePanels"] = { default=false, nControlType=1, ePanel=1, strControlName="HidePanels", fnCallback="OnMainHideToggle" },		-- only uses o value as scratch-pad

	-- Base
	--aListType = nil			-- default list match type
	--aListGame = nil			-- default list game filter
	
	-- DB
	MatchHistory = {},			-- current main data for this character
	tCompKeys = {},
	tCompValues = {},
	tCompSchemas = {},
	
	--TempMatch = nil,			-- current temp match data for this character
	["profileKeys"] = { default=nil, nControlType=0, eSaveLevel=_eSaveLevel.Account  },	-- old style multi-char data that needs to get flushed back to disk each time 
	["char"] = { default=nil, nControlType=0, eSaveLevel=_eSaveLevel.Account },			--   until a particular char has loaded its settings out of it

	-- Other

	sSettingsName = "Default",
	nSettingsVersion = 1,
}

local _tGraphOptions = {
	ePlotStyle = PixiePlot.LINE,
	eCoordinateSystem = PixiePlot.CARTESIAN,

	fYLabelMargin = 40,
	fXLabelMargin = 25,
	fPlotMargin = 10,
	strXLabel = "Match",
	strYLabel = "Rating",
	bDrawXAxisLabel = false,
	bDrawYAxisLabel = false,
	nXValueLabels = 8,
	nYValueLabels = 8,
	bDrawXValueLabels = false,
	bDrawYValueLabels = true,
	bPolarGridLines = false,
	bDrawXGridLines = false,
	bDrawYGridLines = true,
	fXGridLineWidth = 1,
	fYGridLineWidth = 1,
	clrXGridLine = clrGrey,
	clrYGridLine = clrGrey,
	clrXAxisLabel = clrClear,
	clrYAxisLabel = clrClear,
	clrXValueLabel = nil,
	clrYValueLabel = nil,
	clrXValueBackground = nil,
	clrYValueBackground = {
		a = 0,
		r = 1,
		g = 1,
		b = 1
	},

	fXAxisLabelOffset = 170,
	fYAxisLabelOffset = 120,
	strLabelFont = "CRB_Interface9",
	fXValueLabelTilt = 20,
	fYValueLabelTilt = 0,
	nXLabelDecimals = 1,
	nYLabelDecimals = 0,
	xValueFormatter = nil,
	yValueFormatter = nil,

	bDrawXAxis = true,
	bDrawYAxis = true,
	clrXAxis = clrWhite,
	clrYAxis = clrWhite,
	fXAxisWidth = 2,
	fYAxisWidth = 2,

	bDrawSymbol = true,
	fSymbolSize = nil,
	strSymbolSprite = "WhiteCircle",
	clrSymbol = nil,

	strLineSprite = nil,
	fLineWidth = 3,
	bScatterLine = false,

	fBarMargin = 5,     -- Space between bars in each group
	fBarSpacing = 20,   -- Space between groups of bars
	fBarOrientation = PixiePlot.VERTICAL,
	strBarSprite = "",
	strBarFont = "CRB_Interface11",
	clrBarLabel = clrWhite,

	bWndOverlays = false,
	fWndOverlaySize = 6,
	wndOverlayMouseEventCallback = nil,
	wndOverlayLoadCallback = nil,

	aPlotColors = {
		{ a=1, r=0.858, g=0.368, b=0.53 },
		{ a=1, r=0.363, g=0.858, b=0.500 },
		{ a=1, r=0.858, g=0.678, b=0.368 },
		{ a=1, r=0.368, g=0.796, b=0.858 },
		{ a=1, r=0.58, g=0.29, b=0.89 },
		{ a=1, r=0.27, g=0.78, b=0.20 }
	}
}

local _eGameTypes = {							-- match maker to BGChron match types
	RatedBattleground = 1,
	RatedArena = 2,
	Battleground = 3,
	Arena = 4,
	Warplot = 5,
}

local _tMmToChronGameTypes = {					-- match maker to bgchron match types
	[_eMatchType.RatedBattleground] = _eGameTypes.RatedBattleground,
	[_eMatchType.Arena]				= _eGameTypes.RatedArena,
	[_eMatchType.Battleground]		= _eGameTypes.Battleground,
	[_eMatchType.OpenArena]			= _eGameTypes.Arena,
	[_eMatchType.Warplot]			= _eGameTypes.Warplot,
}

local _tGameType2GameSet = {
	[_eGameTypes.Arena]				= "4.1",
	[_eGameTypes.RatedArena]        = "5.1",
	[_eGameTypes.Battleground]      = "6.1",
	[_eGameTypes.RatedBattleground] = "7.1",
	[_eGameTypes.Warplot]           = "8.1",
}

local _tSupportedGameTypes = {
	[_eGameTypes.RatedBattleground]	= true,
	[_eGameTypes.RatedArena]		= true,
	[_eGameTypes.Battleground]		= true,
	[_eGameTypes.Arena]				= true
	--[_eGameTypes.Warplot]			= true,
}

local _tSupportedRatingTypes = {
	[_eRatingType.Arena2v2]          = true,
	[_eRatingType.Arena3v3]          = true,
	[_eRatingType.Arena5v5]          = true,
	[_eRatingType.RatedBattleground] = true
}

local _tArenaFilters = {
	--All    = nil,
	Twos   = 2,
	Threes = 3,
	Fives  = 5
}

local _tRatingTypeToGameType = {
	[_eRatingType.Arena2v2]          = _eGameTypes.RatedArena,
	[_eRatingType.Arena3v3]          = _eGameTypes.RatedArena,
	[_eRatingType.Arena5v5]          = _eGameTypes.RatedArena,
	[_eRatingType.RatedBattleground] = _eGameTypes.RatedBattleground,
	[_eRatingType.Warplot]           = _eGameTypes.Warplot
}

local _tSupportedPublicEvents = {
	[PublicEvent.PublicEventType_PVP_Arena]                     = true,
	[PublicEvent.PublicEventType_PVP_Warplot]                   = true,
	[PublicEvent.PublicEventType_PVP_Battleground_Vortex]       = true,
	[PublicEvent.PublicEventType_PVP_Battleground_Cannon]       = true,
	[PublicEvent.PublicEventType_PVP_Battleground_Sabotage]     = true,
	[PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine]  = true,
}

local _eResultTypes = {
	Win     = 0,
	Loss    = 1,
	Forfeit = 2
}

local _tGameTypeToGridName = {
	[_eGameTypes.Battleground]      = "BGGrid",
	[_eGameTypes.RatedArena]        = "RArenaGrid",
	[_eGameTypes.RatedBattleground] = "RBGGrid",
	[_eGameTypes.Arena]				= "ArenaGrid"
}

local _tFilterListButtons = {
	[_eGameTypes.Battleground] = "BattlegroundBtn",
	[_eGameTypes.RatedArena] = "ArenaBtn",
	[_eGameTypes.RatedBattleground] = "RatedBattlegroundBtn",
	[_eGameTypes.Arena] = "OpenArenaBtn",
}


local _floor = math.floor
local _sqrt = math.sqrt
local _abs = math.abs
local _format = string.format
local _len = string.len
local _tsort = table.sort
local _tinsert = table.insert

local function _dummy() end
local print = _dummy

local function _print(...)
	local s = ""
	for i = 1, select("#",...) do
		s = s .. tostring(select(i,...)) .. " "
	end
	Print(s)
end
--print = _print

local function DeepCopy(o)
	if type(o) ~= 'table' then return o end

	local copy = {}
	for k,v in next, o do copy[k] = DeepCopy(v) end
	return copy
end

local function SettingsCopy(o)
	local copy = {}
	for k,v in next, o do
		if type(v) == "table" and v.nControlType then v = v.default end
		copy[k] = DeepCopy(v)
	end
	return copy
end

local function PostChat(s)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_System, s)
end


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function BGChron:new(o)
	o = self
	--o = o or {}
	--setmetatable(o, self)
	--self.__index = self

	o.L = o.L or _L or {}
	setmetatable(o.L, { __index = function(t,k) return tostring(k) end })

	o._AddonName,o._VersionWindow = _AddonName, _VersionWindow
	o._defaultSettings = _defaultSettings
	o._print = _print
	o._tSupportedGameTypes = _tSupportedGameTypes
	o._tGameType2GameSet = _tGameType2GameSet
	o._eGameTypes = _eGameTypes
	o._eResultTypes = _eResultTypes

	--o.bIntroShown = false		-- for intro message
	--o.bGraphShown = false

	--currentMatch = nil

	--o.wndOpts = nil													-- options window
	--o.wndMain = nil													-- display window

	o.nAge = 0
	o.nWAge = 0															-- world age

	return o
end

function BGChron:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function BGChron:NewLocale(lc, default)
	local L,s = self.L, Apollo.GetString(1)
	if (s == "Annuler" and "frFR" or (s == "Abbrechen" and "deDE" or "enUS")) == lc then return L,self end

	if default then
		self.Ldefault = setmetatable({}, getmetatable(L))
		setmetatable(L, { __index = self.Ldefault })
		return self.Ldefault,self
	end
end


-----------------------------------------------------------------------------------------------
-- BGChron OnLoad
-----------------------------------------------------------------------------------------------

function BGChron:OnLoad()
	self.onXmlDocLoadedCalled = false

	BGChronMatch = self.BGChronMatch
	ktMatchTypeKeys = BGChronMatch.ktMatchTypeKeys

	self.userSettings = SettingsCopy(_defaultSettings)

	-- create form
	self.xmlDoc = XmlDoc.CreateFromFile("BGChron.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterSlashCommand("bgchronclear", "OnBGChronClear", self)
	Apollo.RegisterSlashCommand("bgchron", "OnBGChronOn", self)
end

function BGChron:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName=self.L[_AddonName], nSaveVersion=_VersionWindow})
end

function BGChron:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", _AddonName,
		{ "BGChronOn", "", "" })
end


-----------------------------------------------------------------------------------------------
-- BGChron OnDocLoaded
-----------------------------------------------------------------------------------------------

function BGChron:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end

	Event_FireGenericEvent("OneVersion_ReportAddonInfo", _AddonName, 1, _Version, _VersionMinor)

	-- Load the window

--	self.wndMain = Apollo.LoadForm(self.xmlDoc, _AddonName, nil, self)
--	self.wndMatchForm = Apollo.LoadForm(self.xmlDoc, "BGChronMatch", nil, self)
--	if not self.wndMain or not self.wndMatchForm then
--		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
--		return
--	end
--	local w = self.wndMain

--	-- PixiePlot Initialization
--	self.wndGraph = w:FindChild("GraphContainer")
--	self.plot = PixiePlot:New(self.wndGraph, _tGraphOptions)

--	w:Show(false, true)
--	self.wndMatchForm:Show(false)

	-- Register handlers for events, slash commands and timer, etc.
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("BGChronOn",			"OnBGChronOn", self)
	Apollo.RegisterEventHandler("MatchingJoinQueue",	"OnPVPMatchQueued", self)
	Apollo.RegisterEventHandler("MatchEntered",			"OnPVPMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited",			"OnPVPMatchExited", self)
	Apollo.RegisterEventHandler("PvpRatingUpdated",		"PvpRatingUpdated", self)
	Apollo.RegisterEventHandler("PVPMatchFinished",		"OnPVPMatchFinished", self)
	Apollo.RegisterEventHandler("PublicEventStart",		"OnPublicEventStart", self)
	Apollo.RegisterEventHandler("PublicEventEnd",		"OnPublicEventEnd", self)

	self.tUpdateTimer = ApolloTimer.Create(1.0, true, "OnUpdateTimer", self)

	self.onXmlDocLoadedCalled = true
	self:InitializeWindows()
end


-----------------------------------------------------------------------------------------------
-- QueueView Functions
-----------------------------------------------------------------------------------------------

-- visibility timer		-----------------------------------------------------------------------

function BGChron:OnUpdateTimer()
	self.nAge, self.nWAge = self.nAge + 1, self.nWAge + 1
	self:OnUpdateVisibility()
end

function BGChron:OnUpdateVisibility()
	self:UpdateVisibilityCommon()

end

function BGChron:UpdateVisibilityCommon()
	local o,w,player = self.userSettings, self.wndMain, self.unitPlayer

	if not player or not player:IsValid() then
		player = GameLib.GetPlayerUnit()
		self.unitPlayer = player
	end

	if self._log and self.nAge > 3 then														--PROF:
		for i,v in ipairs(self._log) do														--PROF:
			if type(v) == "table" then print(unpack(v)) else print(v) end					--PROF:
		end																					--PROF:
		self._log = nil																		--PROF:
	end																						--PROF:
end


-----------------------------------------------------------------------------------------------
-- BGChron Events
-----------------------------------------------------------------------------------------------

--PRECONDITION:  The user is near a public event.
--POSTCONDITION: If the public event is a valid PVP event, the event type is stored in a temporary table.
function BGChron:OnPublicEventStart(peEvent)
	local game = self.currentMatch
	if not game then
		return
	end

	local nEventType = peEvent:GetEventType()
	if _tSupportedPublicEvents[nEventType] then
		game.nEventType = nEventType
	end
end

--PRECONDITION:  The player is able to queue.
--POSTCONDITION: Preliminary match information is stored in a temporary table.
function BGChron:OnPVPMatchQueued()		--FIXME: shouldnt use last queued item, so for now here we need to know if *any* were as group for it to work
	local o = self.userSettings			--  should just use whatever match was entered, either polling or catch an event 

	-- gather info
	local bIsQueuedAsGroup = false
	local t
	for _,match in ipairs(MatchMakingLib.GetQueuedEntries()) do
		local info = match:GetInfo()
		local eGameType = _tMmToChronGameTypes[info.eMatchType]

		if _tSupportedGameTypes[eGameType] then
			t = t or {}
			t.nMatchType = eGameType
			t.nTeamSize  = info.nTeamSize

			if match:IsQueuedAsGroup() then
				bIsQueuedAsGroup = true
			end
		end
	end
	if not t then
		return
	end
	t.bQueuedAsGroup = bIsQueuedAsGroup		-- check if solo or group queue, for any of the types

	-- ensure current game
	self.currentMatch = nil					-- force a fresh current game
	self:EnsureCurrentGame(t, true)
end

--PRECONDITION:  The user was queued for a valid PVP match and accepted the queue.
--POSTCONDITION: The current match is restored from a backup if the user had to reload, otherwise the time is saved.
function BGChron:OnPVPMatchEntered()
	local o = self.userSettings

	local tMatchState = MatchingGameLib.GetPvpMatchState()
	if not tMatchState then
		return
	end
	
	local match = MatchingGameLib.GetQueueEntry()
	local info = match and match:GetInfo()
	local eGameType = info and _tMmToChronGameTypes[info.eMatchType] or nil
	if not _tSupportedGameTypes[eGameType] then
		return
	end

	local t = {}
	t.nMatchType = eGameType
	t.nTeamSize  = info.nTeamSize
	t.bIsQueuedAsGroup = match:IsQueuedAsGroup() and true or false
	
	local game = self:EnsureCurrentGame(t)
	game.nMatchEnteredTick = game.nMatchEnteredTick or os.time()
end

-- TODO: This only seems to work for RBG because the rating updates after you leave the match
--PRECONDITION:  The user is eligible to receive a rating update, typically after a rated match is completed.
--POSTCONDITION: The rating change is saved to the match database.
function BGChron:PvpRatingUpdated(eRatingType)
	local o = self.userSettings
	local ohi = o.MatchHistory
	if not _tSupportedRatingTypes[eRatingType] then
		return
	end

	-- get game to populate
	local eGameType = _tRatingTypeToGameType[eRatingType]
	local game = self.currentMatch or ohi[#ohi]
	if not game or game.nMatchType ~= eGameType then
		return
	end

	-- set game ratings
	if not game.nRatingType then		-- if current, clobber to possibly more correct type or rating
		game.nRatingType = eRatingType
	end

	if not game.nEndRating then
		local t = MatchMakingLib.GetPvpRatingByType(eRatingType)
		game.nEndRating = t and t.nRating or nil
	end
end


-----------------------------------------------------------------------------------------------
-- BGChron Match Leaving Events
-----------------------------------------------------------------------------------------------

function BGChron:OnPublicEventEnd(peEnding, eReason, tStats)
	local game = self.currentMatch
	if not game then
		return
	end

	local eEventType = peEnding:GetEventType()
	if _tSupportedPublicEvents[eEventType] then
		self:SetCurrentGameStats(DeepCopy(tStats))				-- need a copy, else will toast Carbine consumers of the tStats table
	end
end

function BGChron:OnPVPMatchExited()
	local game = self.currentMatch
	if not game then
		return
	end

	game.nResult = game.nResult or _eResultTypes.Forfeit		-- Check if user left before match finished.
	game.nMatchEndedTick = os.time()

	self:CommitCurrentGameToHistory()
end

function BGChron:OnPVPMatchFinished(eWinner, eReason, nDeltaTeam1, nDeltaTeam2)
	local game = self.currentMatch
	if not game then
		return
	end
	
	local match = MatchingGameLib.GetQueueEntry()
	local info = match and match:GetInfo()
	if info then
		game.nMatchType = _tMmToChronGameTypes[info.eMatchType]
	end

	local eEventType = game.nEventType
	if eEventType == nil or not _tSupportedPublicEvents[eEventType] or eEventType == PublicEvent.PublicEventType_PVP_Warplot then
		return
	end

	local tMatchState = MatchingGameLib.GetPvpMatchState()
	local eMyTeam = tMatchState and tMatchState.eMyTeam or nil

	game.nResult = eMyTeam == eWinner and _eResultTypes.Win or _eResultTypes.Loss
	game.nMatchEndedTick = os.time()

	if nDeltaTeam1 and nDeltaTeam2 then
		self.arRatingDelta = { nDeltaTeam1, nDeltaTeam2 }
	end

	if tMatchState and eEventType == PublicEvent.PublicEventType_PVP_Arena and tMatchState.raTeams then
		local tArenaTeamInfo = {}
		for idx, tCurr in pairs(tMatchState.arTeams) do

			if eMyTeam == tCurr.nTeam then
				tArenaTeamInfo.tPlayerTeam = tCurr
			else
				tArenaTeamInfo.tEnemyTeam = tCurr
			end

			game.tArenaTeamInfo = tArenaTeamInfo
		end
	end
end


-----------------------------------------------------------------------------------------------
-- BGChron Functions
-----------------------------------------------------------------------------------------------

function BGChron:EnsureCurrentGame(t)
	local o,game = self.userSettings, self.currentMatch

	o.TempMatch = game					-- reset saved match, nil or otherwise

	if game then
		for k,v in pairs(t) do			-- just overwrite
			game[k] = v
		end
		return game
	end

	game = BGChronMatch:new(t)		-- minimum field { nMatchType, nTeamSize, bQueuedAsGroup }

	self.currentMatch = game
	o.TempMatch = game

	game:GenerateRatingInfo()

	return game
end

function BGChron:CommitCurrentGameToHistory()
	local o = self.userSettings
	local ohi = o.MatchHistory

	if self.currentMatch then
		ohi[#ohi + 1] = self.currentMatch
	end
	
	self.currentMatch = nil
	o.TempMatch = nil
end

function BGChron:SetCurrentGameStats(tStats)
	local o,game = self.userSettings, self.currentMatch
	if not game then
		return
	end
	
	-- convert and compress
	game.nElapsedTime = tStats.nElapsedTime

	local t = tStats.arPersonalStats
	game.strName = t and t.strName or nil

	game.arTeamStats = tStats.arTeamStats
	game.arParticipantStats = tStats.arParticipantStats

	-- integrate custom stats to be inline
	t = game.arTeamStats
	if t then
		for i,v in pairs(t) do
			for i2,v2 in ipairs(v.arCustomStats) do
				v[v2.strName] = v2.nValue		-- store n and v directly
				v[i2] = v2.strName				-- keep the order just in case
			end
			v.arCustomStats = nil
		end
	end
	t = game.arParticipantStats
	if t then
		for i,v in pairs(t) do
			for i2,v2 in ipairs(v.arCustomStats) do
				v[v2.strName] = v2.nValue
				v[i2] = v2.strName 
			end
			v.arCustomStats = nil
		end
	end

	-- compress
	self:EnsureCompress()
	game.arTeamStats = self:CompressStats(game.arTeamStats)
	game.arParticipantStats = self:CompressStats(game.arParticipantStats)
end

function BGChron:DisplayGameStats(game)
	--local arTeamStats = self:UncompressStats(game.arTeamStats)
	--local arParticipantStats = self:UnompressStats(game.arParticipantStats)
	--game:CreateGameStatsGrid(self.wndMatchForm, arTeamStats, arParticipantStats)
	game:CreateGameStatsGrid(self.wndMatchForm)		-- let the redraw farther down, uncompress 
end


-----------------------------------------------------------------------------------------------
-- BGChron Filters
-----------------------------------------------------------------------------------------------

function BGChron:FilterGameHistoryData(eGameType, nEventType, nTeamSize)
	local o = self.userSettings
	local ohi = o.MatchHistory

	local t = {}
	if not eGameType then						-- for now dont let it return everything
		return t
	end

	local count = 0
	for k,v in pairs(ohi) do
		if v.nMatchType == eGameType
			and (not nEventType or v.nEventType == nEventType)
			and (not nTeamSize or v.nTeamSize == nTeamSize)
		then
			count = count + 1
			t[count] = v
		end
	end

	return t
end


-----------------------------------------------------------------------------------------------
-- BGChron Helpers
-----------------------------------------------------------------------------------------------

function BGChron:BuildGamesGrid(wndParent, games)
	if not games then
		return
	end

	local wndGrid = wndParent:FindChild(_tGameTypeToGridName[self.eSelectedFilter])
	wndGrid:Show(true)

	local nVScrollPos 	= wndGrid:GetVScrollPos()
	local nSortedColumn	= wndGrid:GetSortColumn() or 1
	local bAscending	= wndGrid:IsSortAscending()

	wndGrid:DeleteAll()

	for _,game in pairs(games) do
		local row = wndGrid:AddRow("")

		wndGrid:SetCellLuaData(row, 1, game)

		BGChronMatch:new(game)				-- ensure object

		local tValues     = game:GetFormattedData()
		local tSortValues = game:GetFormattedSortData()

		for col, sFormatKey in pairs(ktMatchTypeKeys[game.nMatchType]) do
			wndGrid:SetCellText(row, col, tValues[sFormatKey])
			wndGrid:SetCellSortText(row, col, tSortValues[sFormatKey])
		end
	end

	-- Calculate Quick Stats
	self.wndMain:FindChild("WinRateLabel"):SetText(self:GetWinRate(games))
	self.wndMain:FindChild("MatchLengthLabel"):SetText(self:GetAverageMatchLength(games))

	wndGrid:SetVScrollPos(nVScrollPos)
	wndGrid:SetSortColumn(nSortedColumn, bAscending)
end

function BGChron:UpdateArenaFilterUI()
	if not self.eSelectedArenaFilter then
		self.wndArenaFilterListToggle:SetText("All")
		self.wndArenaFilterList:FindChild("ArenaAllBtn"):SetCheck(true)

	elseif self.eSelectedArenaFilter == _tArenaFilters.Twos then
		self.wndArenaFilterListToggle:SetText("2v2")
		self.wndArenaFilterList:FindChild("2v2Btn"):SetCheck(true)

	elseif self.eSelectedArenaFilter == _tArenaFilters.Threes then
		self.wndArenaFilterListToggle:SetText("3v3")
		self.wndArenaFilterList:FindChild("3v3Btn"):SetCheck(true)

	elseif self.eSelectedArenaFilter == _tArenaFilters.Fives then
		self.wndArenaFilterListToggle:SetText("5v5")
		self.wndArenaFilterList:FindChild("5v5Btn"):SetCheck(true)
	end
end

function BGChron:UpdateBattlegroundFilterUI()
	if self.eSelectedBattlegroundFilter == nil then
		self.wndBgFilterListToggle:SetText("All")
		self.wndBgFilterList:FindChild("BattlegroundAllBtn"):SetCheck(true)

	elseif self.eSelectedBattlegroundFilter == PublicEvent.PublicEventType_PVP_Battleground_Vortex then
		self.wndBgFilterListToggle:SetText("Walatiki Temple")
		self.wndBgFilterList:FindChild("WalatikiBtn"):SetCheck(true)

	elseif self.eSelectedBattlegroundFilter == PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine then
		self.wndBgFilterListToggle:SetText("Halls of the Bloodsworn")
		self.wndBgFilterList:FindChild("HotBBtn"):SetCheck(true)

	elseif self.eSelectedBattlegroundFilter == PublicEvent.PublicEventType_PVP_Battleground_Sabotage then
		self.wndBgFilterListToggle:SetText("Daggerstone")
		self.wndBgFilterList:FindChild("DaggerstoneBtn"):SetCheck(true)
	end
end


function BGChron:BuildGraphDataSet(games)
	local low = 9999
	local tRatings = {}

	for _,v in pairs(games) do
		local nEndRating = v.nEndRating

		if nEndRating then
			_tinsert(tRatings, nEndRating)

			if nEndRating < low then
				low = nEndRating
			end
		end
	end
	return { xStart = low, values = tRatings }
end


-----------------------------------------------------------------------------------------------
-- Statistics Functions
-----------------------------------------------------------------------------------------------

--PRECONDITION:  A valid data set is given. tData is a table of matches.
--POSTCONDITION: Win rate data is calculated and returned as a formatted string for display.
function BGChron:GetWinRate(tData)
	result = "Wins: N/A Losses N/A (N/A)"

	if not tData then
		return result
	end

	totalCount = 0
	winCount = 0

	for key, tSubData in pairs(tData) do
		if tSubData.nResult == _eResultTypes.Win then
			winCount = winCount + 1
		end
		totalCount = totalCount + 1
	end

	if totalCount > 0 then
		result = _format("Wins: %d Losses: %d (%2d%%)", winCount, totalCount - winCount, (winCount / totalCount) * 100)
	end

	return result
end

--PRECONDITION:  A valid data set is given. tData is a table of matches.
--POSTCONDITION: An average of the match length is produced.
function BGChron:GetAverageMatchLength(tData)
	result = "Average Match Length: N/A"

	if not tData then
		return result
	end

	totalCount = 0
	totalTime = 0

	for key, tSubData in pairs(tData) do
		if tSubData.nMatchEnteredTick and tSubData.nMatchEndedTick then
			totalTime = totalTime + (tSubData.nMatchEndedTick - tSubData.nMatchEnteredTick)
			totalCount = totalCount + 1
		end
	end

	if totalCount > 0 then
		result = _format("Average Match Length: %s", os.date("%M:%S", (totalTime / totalCount)))
	end

	return result
end


-----------------------------------------------------------------------------------------------
-- BGChron Form Functions
-----------------------------------------------------------------------------------------------

function BGChron:OnClose( wndHandler, wndControl )
	self.wndMain:Close()
end

function BGChron:OnFilterBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndFilterList:Show(true)
end

function BGChron:OnFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndFilterList:Show(false)
end

function BGChron:OnSelectRatedBattlegrounds( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = _eGameTypes.RatedBattleground
	self:OnBGChronOn()
end

function BGChron:OnSelectArenas( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = _eGameTypes.RatedArena
	self:OnBGChronOn()
end

function BGChron:OnSelectBattlegrounds( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = _eGameTypes.Battleground
	self:OnBGChronOn()
end

function BGChron:OnSelectOpenArenas( wndHandler, wndControl, eMouseButton )
	self.eSelectedFilter = _eGameTypes.Arena
	self:OnBGChronOn()
end

function BGChron:OnRowClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if not bDoubleClick then
		return
	end

	local wndGrid = self.wndMain:FindChild(_tGameTypeToGridName[self.eSelectedFilter])
	local nSelectedRow = wndGrid:GetCurrentRow()
	if not nSelectedRow then
		return
	end

	local game = wndHandler:GetCellLuaData(nSelectedRow, 1)

	self:DisplayGameStats(game)
	wndGrid:SetCurrentRow(-1)
end

-- Arena Filters

function BGChron:OnArenaFilterBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndArenaFilterList:Show(true)
end

function BGChron:OnArenaFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndArenaFilterList:Show(false)
end

function BGChron:OnSelectArenaFilterAll( wndHandler, wndControl, eMouseButton )
	self.eSelectedArenaFilter = nil
	self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter2v2( wndHandler, wndControl, eMouseButton )
	self.eSelectedArenaFilter = _tArenaFilters.Twos
	self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter3v3( wndHandler, wndControl, eMouseButton )
	self.eSelectedArenaFilter = _tArenaFilters.Threes
	self:OnBGChronOn()
end

function BGChron:OnSelectArenaFilter5v5( wndHandler, wndControl, eMouseButton )
	self.eSelectedArenaFilter = _tArenaFilters.Fives
	self:OnBGChronOn()
end

-- Battleground Filters

function BGChron:OnBattlegroundFilterBtnCheck( wndHandler, wndControl, eMouseButton )
	self.wndBgFilterList:Show(true)
end

function BGChron:OnBattlegroundFilterBtnUncheck( wndHandler, wndControl, eMouseButton )
	self.wndBgFilterList:Show(false)
end

function BGChron:OnSelectBattlegroundFilterAll( wndHandler, wndControl, eMouseButton )
	self.eSelectedBattlegroundFilter = nil
	self:OnBGChronOn()
end

function BGChron:OnSelectBattlegroundFilterWT( wndHandler, wndControl, eMouseButton )
	self.eSelectedBattlegroundFilter = PublicEvent.PublicEventType_PVP_Battleground_Vortex
	self:OnBGChronOn()
end

function BGChron:OnSelectBattlegroundFilterHotB( wndHandler, wndControl, eMouseButton )
	self.eSelectedBattlegroundFilter = PublicEvent.PublicEventType_PVP_Battleground_HoldTheLine

	self:OnBGChronOn()
end

function BGChron:OnSelectBattlegroundFilterDaggerstone( wndHandler, wndControl, eMouseButton )
	self.eSelectedBattlegroundFilter = PublicEvent.PublicEventType_PVP_Battleground_Sabotage
	self:OnBGChronOn()
end

function BGChron:ShowPlot( wndHandler, wndControl, eMouseButton )
	local games = self.tData
	if not games or #games == 0 then
		return
	end

	self.plot:RemoveAllDataSets()
	self.bGraphShown = true
	self.wndGraph:Show(true)
	self.wndMain:FindChild("GridContainer"):Show(false)
	self.wndMain:FindChild("GraphButton"):Show(false)
	self.wndMain:FindChild("BackButton"):Show(true)

	self.plot:AddDataSet(self:BuildGraphDataSet(games))

	self.plot:Redraw()
end

function BGChron:HidePlot( wndHandler, wndControl, eMouseButton )
	self.plot:RemoveAllDataSets()
	self.wndMain:FindChild("GraphButton"):Show(true)
	self.wndMain:FindChild("BackButton"):Show(false)
	self.wndGraph:Show(false)
	self.wndMain:FindChild("GridContainer"):Show(true)
	self.bGraphShown = false
end

---------------------------------------------------------------------------------------------------
-- BGChronMatch Functions
---------------------------------------------------------------------------------------------------

function BGChron:OnMatchClose( wndHandler, wndControl, eMouseButton )
	self.wndMatchForm:Show(false)
end

---------------------------------------------------------------------------------------------------
-- BGChron Debugging
---------------------------------------------------------------------------------------------------

function BGChron:ShowIntro()
	if self.bIntroShown then
		return
	end

	self.wndMain:FindChild("IntroDialog"):Show(true)
end

function BGChron:CloseIntro()
	self.bIntroShown = true
	self.wndMain:FindChild("IntroDialog"):Show(false)
	self:OnBGChronOn()
end


-----------------------------------------------------------------------------------------------
-- QueueView Startup
-----------------------------------------------------------------------------------------------

function BGChron:OnSave(eType)
	local tSave

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local o = self.userSettings
		tSave = { }
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
		tSave = { }
		--[[
		tSave = {
			nAge = self.nAge,
			nWAge = self.nWAge,
			nRequestLast = self.nRequestLast,
			nServerTime = _crbtime(),
			arUnitsAggregate = { },
			tGames = { },
			tGamesTags = { },
			tLog = { },
			nProtocol = 1,
			_profM = self._profM,															--PROF:
			_profMm = self._profMm,															--PROF:
			_profMP = self._profMP,															--PROF:
			_profMbs = self._profMbs,														--PROF:
			_profMbr = self._profMbr,														--PROF:
		}
		local t, tGames, tGamesTags = tSave.arUnitsAggregate, tSave.tGames, tSave.tGamesTags
		local tGamesKeys, _n = { }, #_arDataDefaults
		for k,v in pairs(self.arUnitsAggregate) do
			if not v.bMark and k ~= self.sId and #v > _n then
				for i = 1, _n do
					if _arDataTypes[i] == _toboolean then v[i] = v[i] and "+" or "-" end
				end
				for i = #v, _n+1, -1 do
					local nGameId = v[i]
					local n = tGamesKeys[nGameId]
					if not n then
						n = #tGames + 1
						tGames[n] = nGameId
						tGamesTags[n] = v[nGameId]
						tGamesKeys[nGameId] = n
					end
					v[i+3] = n
				end
				v[_n+1], v[_n+2], v[_n+3] = v.eFaction, v.nAge, v.nWAge
				t[k] = table.concat(v, ';')
			end
		end
		]]--
	end
	
	if eType == GameLib.CodeEnumAddonSaveLevel.Account then
		tSave = { }
	end

	if tSave then
		local o = self.userSettings
		for k,v in pairs(o) do
			local t = _defaultSettings[k]
			if (type(t) == "table" and t.eSaveLevel or _eSaveLevel.Character) == eType then
				tSave[k] = DeepCopy(v)
			end
		end
	end

	return tSave
end

function BGChron:OnRestore(eType, tSave)
--self._log = self._log or {}																--PROF:
--self._log[#self._log + 1] = { "OnRestore", eType, eType == GameLib.CodeEnumAddonSaveLevel.Account }											--PROF:
	if tSave then
		local o,_ds = self.userSettings, _defaultSettings

		local nVersion = tSave["nSettingsVersion"] or 0
		for k,v in pairs(tSave) do
			local t,b = _defaultSettings[k], nil
			if (type(t) == "table" and t.eSaveLevel or _eSaveLevel.Character) == eType then
				-- migrations
				--if nVersion <= 1 and k == "sJoinFilter" then v = "Default" end
				--if nVersion <= 2 and k == "bRelative" then v = false end
				if k == "MatchHistory" then b = true; if self.bDbMigrate then v = o.MatchHistory end end
				if k == "TempMatch" then b = true; if self.bDbMigrate then v = o.TempMatch end end
				if k == "tCompKeys" then b = true; if self.bDbMigrate then v = o.tCompKeys end end
				if k == "tCompValues" then b = true; if self.bDbMigrate then v = o.tCompValues end end
				if k == "tCompSchemas" then b = true; if self.bDbMigrate then v = o.tCompSchemas end end
				-- filters
				if k == "char" then b = true end										-- skip copy, these can be huge
				if k == "profileKeys" then b = true end									--   will use special handling instead
				if k == "nSettingsVersion" then v = o.nSettingsVersion end
				if k == "sSettingsTooltip" then v = nil end
				o[k] = b and v or DeepCopy(v)
			end
			-- migrations
		end
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Account and tSave and (tSave.char or tSave.profileKeys) then
		--if true then
		--	return
		--end
		local o = self.userSettings

		o.tCompKeys, o.tCompValues, o.tCompSchemas = {}, {}, {}
		self:EnsureCompress()
		self.tCompKeysR, self.tCompValuesR, self.tCompSchemasR = {}, {}, {} 

		local profileKey = (GameLib.GetPlayerCharacterName() or "") .. " - " .. (GameLib.GetRealmName() or "")
		local charKey = (o.profileKeys or {})[profileKey]
		if charKey then
			o.profileKeys[profileKey] = nil
		end
		
		local char = (o.char or {})[charKey]
		if char then
			self.bDbMigrate = true
			local t = char.BGChron or {}
			local ohi = {}; o.MatchHistory = ohi

			local count = 0
			for k,v in pairs(t.MatchHistory or {}) do
				for k2,v2 in ipairs(v) do
					count = count + 1
					ohi[count] = self:OnRestoreMigrateGame(v2)
				end
			end
			o.TempMatch = self:OnRestoreMigrateGame(t.TempMatch)
			o.char[charKey] = nil
		end
		
		if o.char and next(o.char) == nil then
			o.char = nil
		end
		if o.profileKeys and next(o.profileKeys) == nil then
			o.profileKeys = nil
		end
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
		local o = self.userSettings
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local o = self.userSettings
		self:InitializeWindows()
	end
end

function BGChron:OnRestoreMigrateGame(game)
	if not game then
		return
	end

	game = DeepCopy(game)

	game.nMatchType = _tMmToChronGameTypes[game.nMatchType]

	-- migrate rating to main table
	local t,t2 = game.tRating
	if type(t) == "table" then
		for k,v in pairs(t) do
			if v then game[k] = v end
		end
	end
	game.tRating = nil

	-- migrate game stats to main table
	t = game.tMatchStats
	if type(t) == "table" then
		game.nElapsedTime = t.nElapsedTime
		t2 = type(t.arPersonalStats) == "table" and t.arPersonalStats or nil	-- not used, save name as key to self in arParticipantStats
		game.strName = t2 and t2.strName or nil
		game.arTeamStats = type(t.arTeamStats) == "table" and t.arTeamStats or nil
		game.arParticipantStats = type(t.arParticipantStats) == "table" and t.arParticipantStats or nil
	end
	game.tMatchStats = nil

	-- integrate custom stats to be inline
	t = game.arTeamStats
	if t then
		for i,v in pairs(t) do
			for i2,v2 in ipairs(type(v.arCustomStats) == "table" and v.arCustomStats or {}) do
				v[v2.strName] = tonumber(v2.nValue) or v2.nValue		-- store n and v directly
				v[i2] = v2.strName										-- keep the order just in case
			end
			v.arCustomStats = nil
		end
	end
	t = game.arParticipantStats
	if t then
		for i,v in pairs(t) do
			for i2,v2 in ipairs(type(v.arCustomStats) == "table" and v.arCustomStats or {}) do
				v[v2.strName] = tonumber(v2.nValue) or v2.nValue
				v[i2] = v2.strName 
			end
			v.arCustomStats = nil
		end
	end

	-- compress
	game.arTeamStats = self:CompressStats(game.arTeamStats)
	game.arParticipantStats = self:CompressStats(game.arParticipantStats)

	return game
end

function BGChron:EnsureCompress()
	local o = self.userSettings
	local ck,cv,cs = o.tCompKeys, o.tCompValues, o.tCompSchemas

	local t = self.tCompKeysR or {}; self.tCompKeysR = t
	for i,k in ipairs(ck) do
		t[k] = i
	end

	local t = self.tCompValuesR or {}; self.tCompValuesR = t
	for i,k in ipairs(cv) do
		t[k] = i
	end

	local t = self.tCompSchemasR or {}; self.tCompSchemasR = t
	for i,k in ipairs(cs) do
		t[k] = i
	end
end

function BGChron:CompressStats(stats)
	local o = self.userSettings
	local ck,cv,cs = o.tCompKeys, o.tCompValues, o.tCompSchemas
	local ckr,cvr,csr = self.tCompKeysR, self.tCompValuesR, self.tCompSchemasR
	if not stats then
		return
	end

	local function _sort(a,b)
		local an,bn = type(a) == "number", type(b) == "number"
		if an and bn then
			return a < b
		end
		if an or bn then
			return an
		end
		
		return a < b
	end

	local keys, id
	local sRows = ""
	for istat,stat in ipairs(stats) do
		if not keys then					-- need a consistant order if really want to apply across all rows
			keys = {}
			local count = 0
			for k,v in pairs(stat) do		-- assuming first row is same as all rows for this set
				count = count + 1
				keys[count] = k
			end
			_tsort(keys, _sort)
			count = #ck

			local sKeys = ""
			for i,v in ipairs(keys) do
				id = ckr[v]
				if not id then
					count = count + 1
					ck[count] = v
					ckr[v] = count
					id = count
				end
				sKeys = sKeys .. (i==1 and "" or ";") .. tostring(id)
			end
			id = csr[sKeys]
			if not id then
				id = #cs + 1
				cs[id] = sKeys
				csr[sKeys] = id
			end
			stats.nSchema = id
		end

		count = #cv
		for i,k in ipairs(keys) do
			local v = stat[k]
			id = v
			if v == 0 then
				id = ""
			elseif type(id) == "boolean" then
				id = id and "+" or "-"
			elseif type(id) == "string" then
				id = cvr[v]
				if not id then
					count = count + 1
					cv[count] = v
					cvr[v] = count
					id = count
				end
				id = -id
			end
			sRows = sRows .. (i==1 and "" or ";") .. tostring(id)
		end
		stats[istat] = sRows; sRows = ""
	end

	return stats
end

function BGChron:UncompressStats(stats)
	local o = self.userSettings
	local ck,cv,cs = o.tCompKeys, o.tCompValues, o.tCompSchemas
	if not stats then
		return
	end

	local tUncompStats = {}

	-- expand keys
	local keys = {}
	local count = 0
	for v in (cs[stats.nSchema] or ""):gmatch("([^;]+)") do		-- add values
		count = count + 1
		keys[count] = ck[tonumber(v) or 0] or ("_"..count)
	end

	-- expand values
	for istat,stat in ipairs(stats) do
		local t = {}
		count = 0
		for v in ((stat or "")..";"):gmatch("([^;]*);") do		-- add values
			if v == "+" or v == "-" then
				v = v == "+" and true or false
			else
				v = tonumber(v) or 0							-- empty is 0 which will fail the tonumber
				v = v < 0 and cv[_abs(v)] or v
			end
			count = count + 1
			t[keys[count]] = v									-- negative is string lookup, better hope they never add negative numbers
		end
		tUncompStats[istat] = t
	end

	return tUncompStats
end

function BGChron:InitializeWindows()
	local o,w = self.userSettings, self.wndMain

	self.currentMatch = self.currentMatch or o.TempMatch

	-- rest needs docload
	if not self.onXmlDocLoadedCalled then
		return
	end

	-- form items

--	if not self.wndFilterList then											-- match type filter
--		self.wndFilterList = w:FindChild("FilterToggleList")
--		self.wndFilterListToggle = w:FindChild("FilterToggle")
--		self.wndFilterListToggle:AttachWindow(self.wndFilterList)
--	end

--	if not self.wndArenaFilterList then										-- arena filter
--		self.wndArenaFilterList = w:FindChild("ArenaFilterToggleList")
--		self.wndArenaFilterListToggle = w:FindChild("ArenaFilterToggle")
--		self.wndArenaFilterListToggle:AttachWindow(self.wndArenaFilterList)
--	end

--	if not self.wndBgFilterList then										-- battleground filter
--		self.wndBgFilterList = w:FindChild("BattlegroundFilterToggleList")
--		self.wndBgFilterListToggle = w:FindChild("BattlegroundFilterToggle")
--		self.wndBgFilterListToggle:AttachWindow(self.wndBgFilterList)
--	end

	self.eSelectedFilter = nil
	self.eSelectedArenaFilter = nil
	self.eSelectedBattlegroundFilter = nil

	-- TODO: I feel that this could be done in a more elegant way, clean it up later
	-- Maybe the UI reloaded so be sure to check if we are in a match already
	-- its fine
	if MatchingGameLib.GetQueueEntry() then
		local tMatchState = MatchingGameLib.GetPvpMatchState()
		if tMatchState then
			self:OnPVPMatchEntered()
		end
	end
end


-----------------------------------------------------------------------------------------------
-- BGChron Slash Commands
-----------------------------------------------------------------------------------------------


function BGChron:LoadWindows()
	local w = self.wndMain
	if w or not self.onXmlDocLoadedCalled then
		return
	end

	-- doc loaded

	self.wndMain = Apollo.LoadForm(self.xmlDoc, _AddonName, nil, self)
	self.wndMatchForm = Apollo.LoadForm(self.xmlDoc, "BGChronMatch", nil, self)
	if not self.wndMain or not self.wndMatchForm then
		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		return
	end
	w = self.wndMain

	self.wndGraph = w:FindChild("GraphContainer")							-- PixiePlot Initialization
	self.plot = PixiePlot:New(self.wndGraph, _tGraphOptions)

	w:Show(false, true)
	self.wndMatchForm:Show(false)

	-- init window
	
	if not self.wndFilterList then											-- match type filter
		self.wndFilterList = w:FindChild("FilterToggleList")
		self.wndFilterListToggle = w:FindChild("FilterToggle")
		self.wndFilterListToggle:AttachWindow(self.wndFilterList)
	end

	if not self.wndArenaFilterList then										-- arena filter
		self.wndArenaFilterList = w:FindChild("ArenaFilterToggleList")
		self.wndArenaFilterListToggle = w:FindChild("ArenaFilterToggle")
		self.wndArenaFilterListToggle:AttachWindow(self.wndArenaFilterList)
	end

	if not self.wndBgFilterList then										-- battleground filter
		self.wndBgFilterList = w:FindChild("BattlegroundFilterToggleList")
		self.wndBgFilterListToggle = w:FindChild("BattlegroundFilterToggle")
		self.wndBgFilterListToggle:AttachWindow(self.wndBgFilterList)
	end
end

-- on SlashCommand "/bgchron"
function BGChron:OnBGChronOn()
	self:LoadWindows()
	local o,w = self.userSettings, self.wndMain
	if not w then
		return
	end

	w:Show(true)
	self.wndGraph:Show(false)

	-- TODO: Clean these calls up by abstracting
	w:FindChild("BackButton"):Show(false)
	w:FindChild("GraphButton"):Show(false)
	w:FindChild("EmptyDialog"):Show(false)

	self.wndFilterList:Show(false)
	self.wndArenaFilterList:Show(false)
	self.wndArenaFilterListToggle:Show(false)
	self.wndBgFilterList:Show(false)
	self.wndBgFilterListToggle:Show(false)
	w:FindChild("GridContainer"):Show(false)
	w:FindChild("IntroDialog"):Show(false)

	-- Hide all grids
	for key, wndCurr in pairs(w:FindChild("GridContainer"):GetChildren()) do
		wndCurr:Show(false)
	end

	-- Show dialog
	-- DEBUG: Only for intro version
	self:ShowIntro()

	if not self.bIntroShown then
		self.wndFilterListToggle:Show(false)
		return
	else
		self.wndFilterListToggle:Show(true)
	end
	
	local tData = nil

	local eGameType = self.eSelectedFilter
	local sGameSet = _tGameType2GameSet[eGameType]

	local sFilterListButton = _tFilterListButtons[eGameType]
	if sFilterListButton then
		self.wndFilterListToggle:SetText(self._tGameSet2Name[sGameSet])
		self.wndFilterList:FindChild(sFilterListButton):SetCheck(true)
	end

	-- Move to selected filter, if eligible
	if eGameType == _eGameTypes.RatedBattleground then
		self.wndBgFilterListToggle:Show(true)

		self:UpdateBattlegroundFilterUI()
		self.tData = self:FilterGameHistoryData(eGameType, self.eSelectedBattlegroundFilter, nil)

		if next(self.tData) == nil then
			w:FindChild("EmptyDialog"):Show(true)
		elseif self.bGraphShown then
			self:ShowPlot()
		else
			w:FindChild("GridContainer"):Show(true)
			w:FindChild("GraphButton"):Show(true)
		end

	elseif eGameType == _eGameTypes.Battleground then
		self.wndBgFilterListToggle:Show(true)

		self:UpdateBattlegroundFilterUI()
		self.tData = self:FilterGameHistoryData(eGameType, self.eSelectedBattlegroundFilter, nil)

		if next(self.tData) == nil then
			w:FindChild("EmptyDialog"):Show(true)
		else
			w:FindChild("GridContainer"):Show(true)
		end

	elseif eGameType == _eGameTypes.RatedArena then
		self.wndArenaFilterListToggle:Show(true)

		self:UpdateArenaFilterUI()
		self.tData = self:FilterGameHistoryData(eGameType, nil, self.eSelectedArenaFilter)

		if next(self.tData) == nil then
			w:FindChild("EmptyDialog"):Show(true)
		elseif self.bGraphShown then
			self:ShowPlot()
		else
			w:FindChild("GridContainer"):Show(true)
			w:FindChild("GraphButton"):Show(true)
		end

	elseif eGameType == _eGameTypes.Arena then
		self.wndArenaFilterListToggle:Show(true)

		self:UpdateArenaFilterUI()
		self.tData = self:FilterGameHistoryData(eGameType, nil, self.eSelectedArenaFilter)

		if next(self.tData) == nil then
			w:FindChild("EmptyDialog"):Show(true)
		else
			w:FindChild("GridContainer"):Show(true)
		end
	end

	-- Build a list
	if eGameType then
		self:BuildGamesGrid(w:FindChild("GridContainer"), self.tData)
	end
end

-- on SlashCommand "/bgchronclear"
function BGChron:OnBGChronClear()
	local o = self.userSettings
	Print("BGChron: Match History cleared")
	o.MatchHistory = {}
end


-----------------------------------------------------------------------------------------------
-- BGChron Instance
-----------------------------------------------------------------------------------------------

local BGChronInst = BGChron:new()
BGChronInst:Init()
