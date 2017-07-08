-----------------------------------------------------------------------------------------------
-- Client Lua Script for PlayerBadger
-- Copyright Celess. Portions (C) drSpod via drScoreBadger. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"


-----------------------------------------------------------------------------------------------
-- PlayerBadger Module Definition
-----------------------------------------------------------------------------------------------
local _Version,_VersionMinor = 70523,0
local _AddonName,_VersionWindow = "PlayerBadger", 5
local PlayerBadger = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local _tRoles = {
	heals =  { sFile = "heals",  nSprites = 5, sSort = "nHealed", kMax = "nHeals",  kShow = "bShowHeals",  kId = "nHealsId" },
	damage = { sFile = "kills",  nSprites = 5, sSort = "nDamage", kMax = "nDamage", kShow = "bShowDamage", kId = "nDamageId" },
	kills =  { sFile = "kills",  nSprites = 5, sSort = "nKills",  kMax = "nKills",  kShow = "bShowDamage", kId = "nDamageId" },
	deaths = { sFile = "deaths", nSprites = 5, sSort = "nDeaths", kMax = "nDeaths", kShow = "bShowHeals",  kId = "nDeathsId" },
	test =   { sFile = "heals",  nSprites = 5, sSort = "nHealed", kMax = "nHeals",  kShow = "nHeals",      kId = "nHealsId" },
}

local _eSaveLevel = GameLib.CodeEnumAddonSaveLevel

local _defaultSettings = {		--type: 0 custom, 1 single check, 2 slider, 3 color, 4 radio, 5 text, 6 number, 7 check parts, 8 signal, 9 drop
	-- Normal
	-- display
	["nHealsId"] = { default=5, nControlType=0, },
	["nDamageId"] = { default=2, nControlType=0, },
	["nDeathsId"] = { default=4, nControlType=0, },
	["bShowHeals"] = { default=true, nControlType=1, strControlName="showHeals", fnCallback="OnSettingDisplayChanged" },
	["bShowDamage"] = { default=true, nControlType=1, strControlName="showKills", fnCallback="OnSettingDisplayChanged" },
	["bShowDeaths"] = { default=true, nControlType=1, strControlName="showDeaths", fnCallback="OnSettingDisplayChanged" },
	["nHeals"] = { default=10, nControlType=0, strControlName=nil },
	["nDamage"] = { default=3, nControlType=6, strControlName="maxDamage", fnCallback="OnSettingDisplayChanged" },
	["nKills"] = { default=3, nControlType=6, strControlName="maxKills", fnCallback="OnSettingDisplayChanged" },
	["nDeaths"] = { default=3, nControlType=6, strControlName="maxDeaths", fnCallback="OnSettingDisplayChanged" },
	--["bShowText"] = { default=false, nControlType=0, },
	-- style
	["bNewRules"] = { default=true, nControlType=1, strControlName="StyleNewRules", fnCallback="OnSettingStyleChanged" },
	["bAboveName"] = { default=true, nControlType=1, strControlName="StyleAboveName", fnCallback="OnSettingStyleChanged" },
	["opacity"] = { default=65, nControlType=2, strControlName="badgeOpacity", fnCallback="OnSettingStyleChanged" },
	["size"] = { default=50, nControlType=2, strControlName="badgeSize", fnCallback="OnSettingStyleChanged" },
	["height"] = { default=65, nControlType=2, strControlName="badgeHeight", fnCallback="OnSettingStyleChanged" },

	-- Other

	sSettingsName = "Default",
	nSettingsVersion = 1,
	tSettingsCustom = {	},
}

local _resetSettings = {
	{
		sSettingsName = "Default",
		sSettingsTooltip = "Default settings. These are the settings from when the AddOn was first installed.",
	}, {
		sSettingsName = "Updated",
		sSettingsTooltip = "A slightly more updated style than Default. Changes: Heal as Green Circle, Damage as Yellow Crown, Deaths as Brown Smiley Poo, and slighly lower Opaticy, Size and Height.",
		nHealsId = 3,
		nDamageId = 1,
		nDeathsId = 3,
		opacity = 58,
		size = 44,
		height = 64,
	}, {
		sSettingsName = "Original",
		bNewRules = false,
		height = 83,
	}, {
		sSettingsName = "Massive",
		nHealsId = 4,
		nDamageId = 3,
		nDeathsId = 1,
		nDamage = 5,
		nKills = 2,
		nDeaths = 5,
		opacity = 85,
		size = 85,
		height = 85,
	}, {
		sSettingsName = "Custom",
		sSettingsTooltip = "Custom defaults. Use the Save button at any time to save current settings to this Custom preset. Load them again by choosing this Custom preset from the list.",
	}, {
		sSettingsName = "Durina",
		nDamage = 2,
		nKills = 2,
		nDeaths = 2,
		opacity = 51.5,
		size = 42,
		height = 63.5,
	}, {
		sSettingsName = "Pancakes",
		nDeathsId = 3,
	},
}
for _,v in pairs(_resetSettings) do
	_resetSettings[v.sSettingsName:lower()] = v
end


local _eRace = GameLib.CodeEnumRace
local _eClass = GameLib.CodeEnumClass

local _eRole = {
	heals = 1,
	kills = 2,
	damage = 3,
	deaths = 4,
	test = 5,
}

local _tTextColors = {
	[_eRole.damage]	= ApolloColor.new("DispositionHostile"),
	[_eRole.kills]	= ApolloColor.new("DispositionHostile"),
	[_eRole.deaths]	= ApolloColor.new("DispositionNeutral"),
	[_eRole.heals]	= ApolloColor.new("DispositionFriendly"),
	[_eRole.test]	= ApolloColor.new("DispositionNeutral"),
}

local _teRaceToName = { }
for k,v in pairs(_eRace) do
	_teRaceToName[v] = k
end
_teRaceToName[0] = _teRaceToName[0] or "Unknown"

local _tSpritesOrdered = {		-- options order
	"heals",
	"kills",
	"deaths",
}

local _nConfigSpriteLeft = 54	-- options positions
local _nConfigSpriteTop = 50	--30
local _nConfigSpriteSpace = 72

local _nMountHeight = 3.5

local _raceHeight = {
	[0] = 3.2,
	[_eRace.Human]		= 1.95,
	[_eRace.Granok]		= 3,
	[_eRace.Aurin]		= 1.75,
	[_eRace.Draken]		= 2.30,
	[_eRace.Mechari]	= 2.96,
	[_eRace.Mordesh]	= 2.75,
	[_eRace.Chua]		= 1.25,
}

local _nRaceHeightHuman = _raceHeight[_eRace.Human]

local _raceHeight_oldRules = {
	[0] = 3,
	[_eRace.Human] = 2.1,
	[_eRace.Granok] = 3,
	[_eRace.Aurin] = 1.8,
	[_eRace.Draken] = 2.3,
	[_eRace.Mechari] = 2.85,
	[_eRace.Mordesh] = 2.75,
	[_eRace.Chua] = 1.35,
}

local _tHealClass = {
	[_eClass.Esper] = true,
	[_eClass.Medic] = true,
	[_eClass.Spellslinger] = true,
}

--TODO: break these out onto options
local _crGuild_Dark			= ApolloColor.new("DispositionGuildmateUnflagged")
local _crGuild_Light		= ApolloColor.new("FFB970DB")	--FFAF5CD6 10% -- lightened about 20%. the regular purple color is very hard to read as its very dark against the black outline
local _crGuild				= _crGuild_Dark					--NOTE: non-static var.  the light color is also much closer to a matching color vs the other game text colors
local _crEnemy_Dark 		= _tTextColors[_eRole.damage]
local _crEnemy_Light 		= ApolloColor.new("FFFFF322A") --FA3A26") --f7211d")	--FA2521")		--FFFF211C") --FFFF3633" 20% --FFFF1D1A 10% ffff0500-- lightened about 20%. the regular red color is very hard to read as its very dark against the black outline
local _crEnemy				= _crEnemy_Dark
local _crDead 				= ApolloColor.new("DeathGrey")
local _crDefaultTagged		= ApolloColor.new("DeathGrey")
local _sFont_Default		= "Nameplates"			-- CRB_Header10_O is "Nameplates"
local _sFont_Large			= "CRB_Interface10_BO"
local _sFont_Larger			= "CRB_Interface11_BO"
local _sFont_Large85		= "CRB_Interface10_BO"
local _sFont_Larger85		= "CRB_Interface11_BO"
local _sFont_Large75		= "CRB_Interface11_BO"
local _sFont_Larger75		= "CRB_Interface12_BO"
local _sFont_Large70		= "CRB_Header11_O"
local _sFont_Larger70		= "CRB_Header12_O"
local _sFont				= _sFont_Default

local _tPixie = {
	strSprite = "", cr = "",
	strText = nil, flagsText = {},
	loc = { fPoints = { 0, 0, 0, 0 }, nOffsets = { 0, 0, 0, 0 } }
}

local _floor = math.floor
local _sqrt = math.sqrt
local _abs = math.abs
local _format = string.format
local _len = string.len
local _tsort = table.sort
local _byte = string.byte
local _char = string.char

local function _dummy() end
local print = _dummy

local function _print(...)
	local s = ""
	for i = 1, select("#",...) do
		s = s .. tostring(select(i,...)) .. " "
	end
	Print(s)
end

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

local _tShortFormatWhole = {
	[1] = Apollo.GetString("TargetFrame_ShortNumberWhole"),		-- thousands
	[2] = Apollo.GetString("TargetFrame_MillionsNumberWhole"),
	[3] = Apollo.GetString("TargetFrame_BillionsNumberWhole")
}

local _tShortFormatFloat = {
	[1] = Apollo.GetString("TargetFrame_ShortNumberFloat"),		-- thousands
	[2] = Apollo.GetString("TargetFrame_MillionsNumberFloat"),
	[3] = Apollo.GetString("TargetFrame_BillionsNumberFloat")
}

local function ShortNumber( n )							-- replaces FormatNumber/BigNumber, short number packed with thousands
	local i = 0											--   place indicator, for fast comparisons between frames.
	while n >= 1000 and i < 3 do						--   format: 54321 as int, where 1 is thousands root, and 543.2 is short form
		n = n / 1000									-- use with matching FormatNumber
		i = i + 1
	end
	return _floor((n - n % .1) * 100 + i)				-- floor to clip float errors
end

local function ShortRound( n )							-- replaces FormatNumber/BigNumber, short number packed with thousands rounded
	local i = 0											--   place indicator, for fast comparisons between frames.
	while n >= 1000 and i < 3 do						--   format: 54321 as int, where 1 is thousands root, and 543.2 is short form
		n = n / 1000									-- use with matching FormatNumber
		i = i + 1
	end
	n = n + 0.05; return _floor((n - n % .1) * 100 + i)	-- floor to clip float errors
end

local function FormatNumber( n )
	local i = n % 10									-- thousands root
	n = (n - i) / 100									-- short number form
	return i == 0 and tostring(n)
		or String_GetWeaselString((n % 1 == 0 and _tShortFormatWhole or _tShortFormatFloat)[i], n)
end


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function PlayerBadger:new(o)
	o = self
	--o = o or {}
	--setmetatable(o, self)
	--self.__index = self

	o.L = o.L or _L or {}
	setmetatable(o.L, { __index = function(t,k) return tostring(k) end })

	o._AddonName = _AddonName
	o._defaultSettings = _defaultSettings
	o._resetSettings = _resetSettings
	o._print = _print

	--o.tRoles = {}			-- compiled role data for render

	o.arShowPlates = {}
	o.arUnit2Plate = {}
	o.arPixies = {}			-- pixie ids

	--self.nTestId = nil

	return o
end

function PlayerBadger:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = _AddonName
	local tDependencies = { }
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger OnLoad
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnLoad()
	self.onXmlDocLoadedCalled = false

	self.userSettings = SettingsCopy(_defaultSettings)

	Apollo.LoadSprites("PlayerBadgerSprites.xml", "PlayerBadgerSprites")

	-- create form
	self.xmlDoc = XmlDoc.CreateFromFile("PlayerBadger.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("PlayerBadger_ShowMenu", "OnShowMenu", self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

	Apollo.RegisterSlashCommand("PB", "OnCommand", self)
	Apollo.RegisterSlashCommand("pb", "OnCommand", self)
	Apollo.RegisterSlashCommand("PlayerBadger", "OnCommand", self)
	Apollo.RegisterSlashCommand("playerbadger", "OnCommand", self)
end

function PlayerBadger:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName=self.L["PlayerBadger Options"], nSaveVersion=_VersionWindow})
end

function PlayerBadger:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", _AddonName,
		{ "PlayerBadger_ShowMenu", "", "IconSprites:Icon_Windows_UI_CRB_Fieldstudy_Guarding" })
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger OnDocLoaded
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end

	Event_FireGenericEvent("OneVersion_ReportAddonInfo", _AddonName, 1, _Version, _VersionMinor)

	-- Load the window

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "PlayerBadger", "InWorldHudStratum", self)
	if not self.wndMain then
		Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
		return
	end

	Apollo.RegisterEventHandler("NextFrame",					"OnFrame", self)

	Apollo.RegisterEventHandler("PublicEventStart",				"OnEventStatsUpdate", self)
	Apollo.RegisterEventHandler("PublicEventLiveStatsUpdate",	"OnEventStatsUpdate", self)
	--Apollo.RegisterEventHandler("MatchEntered",					"OnMatchEntered", self)
	Apollo.RegisterEventHandler("MatchExited",					"OnMatchEntered", self)

	self.onXmlDocLoadedCalled = true
	self:InitializeWindows()

	self.wndMain:Show(true, true)
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger Functions
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnFrame()
	local o,w,i2p = self.userSettings, self.wndMain, self.arPixies

	local id = 0						-- pixie cache id, any unused pixies wil get destroyed each frame

	for _,v in next, self.arShowPlates do
		local unit = v.unit											--section is 0.025ms @ 1 with unit on mount
		local bShow = unit and not unit:IsDead()
		if bShow then
			local bIsMounted = unit:IsMounted()
			unit = bIsMounted and unit:GetUnitMount() or unit

			bShow = (not unit:IsOccluded())
				and (GameLib.GetUnitScreenPosition(unit) or {}).bOnScreen		-- rarely returns nil, so new table will almost never happen

			if bIsMounted ~= v.bIsMounted then
				v.bIsMounted = bIsMounted
				self:SetPlate(v)
			end
		end

		local p = bShow and unit:GetPosition()						--section is 0.097ms - 0.025ms  @ 1
		if p then
			local y,x = p.y + v.nHeight

			p = GameLib.WorldLocToScreenPoint(Vector3.New(p.x, y, p.z))
			x,y = p.x, p.y

			if o._above then
				y = y - 60		-- creates a 60 ui-unit hole around lower chunk of name plate
			end

			local tPixie = v.tPixie
			local a,n = tPixie.loc.nOffsets, o._offset
			a[1],a[2],a[3],a[4] = x - n, y - n, x + n, y + n

			--tPixie.strText = o.bShowText and FormatNumber(ShortNumber(e[role.sSort] or 0)) or ""

			id = id + 1
			local i = i2p[id]
			if i then
				w:UpdatePixie(i, tPixie)
			else
				i2p[id] = w:AddPixie(tPixie)
			end
		end
	end

	-- remove unused pixies
	for i = id+1, #i2p do
		if i2p[i] then
			w:DestroyPixie(i2p[i])
			i2p[i] = nil
		end
	end
end


function PlayerBadger:OnEventStatsUpdate(peEvent)
	local s2p,u2p = self.arShowPlates, self.arUnit2Plate
	--local nTime = GameLib.GetTickCount()												--PROF:
	--for i = 1,100 do																	--PROF:

	-- teams
	local stats = peEvent:GetLiveStats()
	local teams = stats and stats.arTeamStats
	if not teams or #teams < 2 then
		return
	end
	local strTeamName = teams[1].bIsMyTeam and teams[2].strTeamName or teams[1].strTeamName

	-- enemy list
	local arStats, nStats = { }, 0						-- wasted table
	for i,v in ipairs(stats.arParticipantStats) do
		if v.strTeamName == strTeamName then
			nStats = nStats + 1
			arStats[nStats] = v
		end
	end

	-- build show list
	local sSort = nil
	local function sortFunc(a, b) return b[sSort] < a[sSort] end	-- Lua already compiled null op

	local id = self.nTestId or 0									-- plate ids, skip any allocated test ids

	for k,role in next, self.tRoles do
		local nMax = role.bShow and role.nMax or 0
		nMax = nMax < nStats and nMax or nStats

		if nMax > 0 and k ~= "test" then
			sSort = role.sSort
			_tsort(arStats, sortFunc)

			for i,v in ipairs(arStats) do
				local nStat = v[sSort]
				if i > nMax or nStat <= 0 then
					break
				end
				if sSort == "nHealed" and (nStat < v.nDamage or not _tHealClass[v.eClass]) then
					break
				end

				local unit = v.unitParticipant or GameLib.GetPlayerUnitByName(v.strName)
				if unit and unit:IsValid() then
					id = id + 1
					local plate = s2p[id]
					if not plate then
						plate = {}; s2p[id] = plate
					end

					self:SetPlate(plate, unit, role)
				end
			end
		end
	end

	-- remove unused plates
	for i = id+1, #s2p do
		s2p[i] = nil
	end

	--end																							--PROF:
	--Print("COLLECT: " .. (self._frameCount or 0) .. ": " .. (GameLib.GetTickCount() - nTime))		--PROF:
end


-- create destroy		-----------------------------------------------------------------------

function PlayerBadger:SetPlate(plate, unit, role)
	local o = self.userSettings

	if unit then
		plate.unit = unit
		plate.tRole = role
		plate.tPixie = role.tPixie
	else
		unit = plate.unit
		role = plate.tRole
	end

	local nHeight
	if o.bNewRules then
		nHeight = _raceHeight[unit:GetRaceId() or 0]

		if o._above and nHeight < _nRaceHeightHuman then
			nHeight = _nRaceHeightHuman
		end
		if plate.bIsMounted then
			nHeight = (nHeight / 2) + _nMountHeight
		end
		nHeight = (nHeight * o._height) + o._adjust * 7
	else
		nHeight = _raceHeight_oldRules[unit:GetRaceId() or 0]
		nHeight = o._height_old * nHeight * (plate.bIsMounted and 1 or 1.5)
	end

	plate.nHeight = nHeight
end


-- visibility timer		-----------------------------------------------------------------------




-- other system events	-----------------------------------------------------------------------

function PlayerBadger:OnMatchEntered()
	local s2p,u2p = self.arShowPlates, self.arUnit2Plate

	local id = self.nTestId or 0									-- plate ids, skip any allocated test ids
	for i = id+1, #s2p do											-- remove all plates because stat update event wont fire again
		s2p[i] = nil												--  or will be rendering ghost plates
	end
end


-----------------------------------------------------------------------------------------------
-- OptionsForm Form Functions
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnConfigure()
	self:OnOptionsForm()
end

function PlayerBadger:OnCloseWindow()
	self.wndOpts:Close()
end

function PlayerBadger:OnCancel()
	self:OnCloseWindow()
end

function PlayerBadger:OnOK()
	self.configCommitting = true
	self:OnCloseWindow()
end

function PlayerBadger:OnOptionsClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end

	self:SetTestingState(false)

	local wo,L = self.wndOpts, self.L
	if wo and wo:IsValid() then
		wo:Close()
		wo:Destroy()
		self.wndOpts = nil
		self.woChoiceScroll = nil

		Event_FireGenericEvent("WindowManagementRemove", {strName=L["PlayerBadger Options"]})
	end
end

function PlayerBadger:OnOptionsForm()
	local L = self.L

	local wo = Apollo.LoadForm(self.xmlDoc, "OptionsForm", nil, self)
	self.wndOpts = wo

	Apollo.LoadForm(self.xmlDoc, "NormalView", wo:FindChild("NormalContent"), self)

	self:OnPanelForm(wo)

	-- fixups
	wo:FindChild("Title"):SetText(L["PlayerBadger Options"])

	self:OnCurrentToConfig()
	wo:Invoke()

	Event_FireGenericEvent("WindowManagementAdd", {wnd = wo, strName=L["PlayerBadger Options"], nSaveVersion=_VersionWindow})
end

function PlayerBadger:OnCurrentToConfig()
	local o,wo = self.userSettings, self.wndOpts

	-- Generic managed controls
	self:OnCurrentToPanel(wo)

	wo:FindChild("ResetDropToggle"):SetText(o.sSettingsName)

	-- update actual badges
	local w,roles = wo:FindChild("Badges"), self.tRoles
	w:DestroyAllPixies()

	local p =  _tPixie.loc.nOffsets
	p[1],p[2],p[3],p[4] = _nConfigSpriteLeft, _nConfigSpriteTop, _nConfigSpriteLeft + 50, _nConfigSpriteTop + 50
	_tPixie.cr = "FFFFFFFF"

	for i,v in ipairs(_tSpritesOrdered) do
		_tPixie.strSprite = roles[v].tPixie.strSprite
		w:AddPixie(_tPixie)
		p[2] = p[2] + _nConfigSpriteSpace; p[4] = p[4] + _nConfigSpriteSpace
	end

	self:OnEnablerButtonChecked()												-- enable disable buttons
end

function PlayerBadger:OnEnablerButtonChecked()
	local o,wo = self.userSettings, self.wndOpts

	self:SetLittleButtonEnabled(wo:FindChild("StyleAboveName"), o.bNewRules)	-- Friendly Unit
end

function PlayerBadger:OnSettingDisplayChanged( )
	local o,wo,roles = self.userSettings, self.wndOpts, self.tRoles

	for k,v in pairs(roles) do		-- update all with same key to same sprite id
		v.tPixie.strSprite = "PlayerBadgerSprites:" .. v.sFile .. o[v.kId]
		v.bShow = o[v.kShow]
		v.nMax = o[v.kMax]
	end

	if wo then
		self:OnCurrentToConfig()
	end
end

function PlayerBadger:OnSettingStyleChanged( )
	local o,wo,s2p,roles = self.userSettings, self.wndOpts, self.arShowPlates, self.tRoles

	_crGuild = true and _crGuild_Light or _crGuild_Dark
	_crEnemy = true and _crEnemy_Light or _crEnemy_Dark
	_tTextColors[_eRole.damage] = _crEnemy
	_tTextColors[_eRole.kills] = _crEnemy
	_tTextColors[_eRole.kills] = _crGuild
	_tTextColors[_eRole.test] = _crGuild

	_sFont = _sFont_Default

	local cr = _format("%02x", o.opacity / 100 * 255) .. "FFFFFF"	-- compile color blend

	for k,v in pairs(roles) do
		local t = v.tPixie
		t.cr = cr
		t.crText = _tTextColors[_eRole[k]]
		t.strFont = _sFont
		t.flagsText["DT_CENTER"] = true
	end

	o._offset = o.size / 2						-- compile texture offset

	local h = o.height - 17						-- compile height factors
	if h < 0 then								-- below feet, -1 to 0, 0
		o._adjust = h / 17
		o._height = 0
	elseif h > 40 then							-- above head, 0 to 1, 0
		o._adjust = ((h - 40) / 43)
		o._height = 1
	else
		o._adjust = 0							-- along body,  0, 0 to 1
		o._height = h / 40
	end

	o._above = o.bNewRules and o.bAboveName and o._height >= 1	--FIXME: this needs to be on timer bacause of real o.bX values, not left here

	o._height_old = (o.height / 100) * 2.2 - 0.2	-- compile height factor.  0 to 100 -> -0.2*h to 2*h

	for _,v in next,s2p do						-- force update current plates
		self:SetPlate(v, v.unit, v.tRole)
	end

	if wo then
		self:OnEnablerButtonChecked()
	end
end

function PlayerBadger:OnSpriteChange(wndHandler, wndControl, eMouseButton)
	local o,roles = self.userSettings, self.tRoles

	local k,dir = wndControl:GetName():match("([^_]+)_(.+)")

	local oKey = roles[k].kId
	o[oKey] = ((o[oKey] + (dir == "Next" and 0 or -2)) % roles[k].nSprites) + 1

	if self.bTesting then
		roles.test.sFile = roles[k].sFile		-- set testing sprite name and id to the last changed role
		roles.test.kId = oKey
	end

	self:OnSettingDisplayChanged()
end


-- testing

function PlayerBadger:OnTestSettings()
	self:SetTestingState(not self.bTesting)
end

function PlayerBadger:SetTestingState( bTesting )
	if self.bTesting == bTesting then
		return
	end

	local o,w,L,s2p = self.userSettings, self.wndOpts, self.L, self.arShowPlates

	self.bTesting = bTesting
	w:FindChild("TestButton"):SetText(bTesting and L["Stop"] or L["Test"]) --L["Stop Testing"] or L["Test Target"])

	if bTesting then
		Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
		self:OnTargetUnitChanged(GameLib.GetTargetUnit())
	else
		Apollo.RemoveEventHandler("TargetUnitChanged", self)
		table.remove(s2p, self.nTestId)
		self.nTestId = nil
	end
end

function PlayerBadger:OnTargetUnitChanged( unit )
	local s2p,roles = self.arShowPlates, self.tRoles

	if self.bTesting then
		unit = unit or GameLib.GetPlayerUnit()
		if not self.nTestId then
			self.nTestId = 1
			table.insert(s2p, self.nTestId,	{ })
			--table.insert(s2p, self.nTestId,	{ sRole = "test", tRole = roles.test, tStat = { nHealed = 7345678 }})
		end
		self:SetPlate(s2p[self.nTestId], unit, roles.test)
	end
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger Startup
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnSave(eType)
	local tSave

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local o = self.userSettings

		tSave = { }
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
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

function PlayerBadger:OnRestore(eType, tSave)
	if tSave then
		local o,_ds = self.userSettings, _defaultSettings

		local nVersion = tSave["nSettingsVersion"] or 0

		for k,v in pairs(tSave) do
			local t = _defaultSettings[k]
			if (type(t) == "table" and t.eSaveLevel or _eSaveLevel.Character) == eType then
				-- migrations
				if k == "roles" and nVersion <= 0 then
					for k2,v2 in pairs(v) do
						local r = _tRoles[k2]
						if v2.id ~= nil and r.sFile == k2 then o[r.kId] = v2.id end
						if v2.show ~= nil and r.sFile == k2 then o[r.kShow] = v2.show end
						if v2.max ~= nil and k2 ~= "test" and k2 ~= "health" then o[r.kMax] = v2.max end
					end
					v = nil
				end
				-- filters
				if k == "nSettingsVersion" then v = o.nSettingsVersion end
				if k == "sSettingsTooltip" then v = nil end
				o[k] = DeepCopy(v)
			end
			-- migrations
			if tSave["bAboveName"] == nil and nVersion <= 0 then o.bAboveName = false end		-- previous users start with above name off, else massive jump in height
		end
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		self:InitializeWindows()
	end
end

function PlayerBadger:InitializeWindows()
	local o = self.userSettings

	self:OnCurrentToCommand()

	if not self.tRoles then											-- ensure compiled options tables for render
		self.tRoles = DeepCopy(_tRoles)
		for k,v in pairs(self.tRoles) do
			v.tPixie = DeepCopy(_tPixie)
		end
	end

	-- re-bind any newly loaded custom reset settings to base custom settings
	self._resetSettingsCustom = self._resetSettingsCustom or _resetSettings.custom
	_resetSettings.custom = setmetatable(o.tSettingsCustom, { __index = self._resetSettingsCustom })

	-- rest needs docload
	if not self.onXmlDocLoadedCalled then
		return
	end

	-- loaded units
	self:OnSettingDisplayChanged()
	self:OnSettingStyleChanged()						-- cache render values
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger Commands
-----------------------------------------------------------------------------------------------

function PlayerBadger:OnShowMenu()				-- used by InterfaceMenuList
	self:OnCommand()
end

function PlayerBadger:OnCurrentToCommand()
	local o = self.userSettings
	print = o.bIsDebug and _print or _dummy
end

function PlayerBadger:OnCommand(sCommand, sArgs)
	local o,wo,L = self.userSettings, self.wndOpts, self.L

	sArgs = sArgs and sArgs:lower() or ""
	local sArg1, sArg2 = sArgs:match("([^ ]+) *(.-) *$")	-- '  aaa   bb cc  ' to 'aaa', 'bb cc'

	if not sArg1 or sArg1 == ""
		or sArg1 == "options"								-- toggle config window
		or sArg1 == "config" or sArg1 == "settings" then
		if wo then
			self:OnOptionsClosed()
		else
			self:OnOptionsForm()
		end
	elseif sArg1 == "optionsopen" then
		if not wo then
			self:OnOptionsForm()
		end
	elseif sArg1 == "optionsclose" then
		if wo then
			self:OnOptionsClosed()
		end

	elseif sArg1 == "reset" then
		local t = (not sArg2 or sArg2 == "") and _resetSettings.default or _resetSettings[sArg2]
		if not t then
			PostChat(_format(L["No reset settings named '%s' for %s."], sArg2, _AddonName))
			return
		end
		o = SettingsCopy(_defaultSettings); self.userSettings = o
		o.tSettingsCustom = _resetSettings.custom
		t.nSettingsVersion = t.nSettingsVersion or o.nSettingsVersion
		self:OnRestore(GameLib.CodeEnumAddonSaveLevel.Realm, t)			-- realm first because char fires init
		self:OnRestore(GameLib.CodeEnumAddonSaveLevel.Character, t)
		if wo and wo:IsValid() then
			self:OnCurrentToConfig()
		end

	elseif sArg1 == "debug" then
		o.bIsDebug = not o.bIsDebug
		self:OnCurrentToCommand()

	elseif sArg1 == "help" then
		local _addonname = _AddonName:lower()
		PostChat(_format(L["%s commands:"],_AddonName))
		PostChat(_format(L[" /%s - show options"],_addonname))
		PostChat(_format(L[" /%s reset - reset to defaults"],_addonname))
		PostChat(_format(L[" /%s reset [name] - reset to named preset"],_addonname))
		PostChat(_format(L[" /%s help - help message"],_addonname))
	end
end


-----------------------------------------------------------------------------------------------
-- PlayerBadger Instance
-----------------------------------------------------------------------------------------------

local PlayerBadgerInst = PlayerBadger:new()
PlayerBadgerInst:Init()

