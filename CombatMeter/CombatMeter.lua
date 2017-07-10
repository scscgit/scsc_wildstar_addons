-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. Portions (C) Vim,Vince via CC 3.0 VortexMeter,
-- and coasini VortexTrueColors.  All rights reserved.
-- Original: Rift Meter by Vince at www.curse.com/addons/rift/rift-meter
-----------------------------------------------------------------------------------------------

require "Window"


-----------------------------------------------------------------------------------------------
-- CombatMeter Module Definition
-----------------------------------------------------------------------------------------------
local _Version,_VersionMinor = 70523,0
local _AddonName,_VersionWindow = "CombatMeter", 7
local CombatMeter = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local _eSaveLevel = GameLib.CodeEnumAddonSaveLevel

local _eClass = GameLib.CodeEnumClass
local _eDamageType = GameLib.CodeEnumDamageType

local _defaultSettings = {	--type: 0 custom, 1 single check, 2 slider, 3 color, 4 radio, 5 text, 6 number, 7 check parts, 8 signal, 9 drop, 10 check drop
	-- General
	-- global
	["bLockWindows"] = { default=false, nControlType=1, strControlName="LockWindows", fnCallback="OnCurrentToMain" },
	["bShowTooltips"] = { default=true, nControlType=1, strControlName="ShowTooltips" },
	["bShowSelf"] = { default=true, nControlType=1, strControlName="ShowSelf", fnCallback="OnConfigChangedUpdate" },	-- always show self
	["bShowOnlyBoss"] = { default=false, nControlType=1, strControlName="OnlyBoss", fnCallback="OnConfigChangedUpdate" },
	["bLogOthers"] = { default=true, nControlType=1, strControlName="LogOthers", fnCallback="OnCurrentToMain" },		-- CVar set on a timer, also notify SOLO button
	-- bar formatting
	["bShowPercent"] = { default=true, nControlType=1, strControlName="ShowPercent", fnCallback="OnConfigChangedUpdate" },
	["bShowAbsolute"] = { default=true, nControlType=1, strControlName="ShowAbsolute", fnCallback="OnConfigChangedUpdate" },
	["bShowRank"] = { default=true, nControlType=1, strControlName="ShowRank", fnCallback="OnConfigChangedUpdate" },
	["bShowShort"] = { default=false, nControlType=1, strControlName="ShowShort", fnCallback="OnConfigChangedUpdate" },
	-- Advanced
	["bShowMarker"] = { default=true, nControlType=1, strControlName="ShowMarker", fnCallback="OnConfigChangedUpdate" },
	["bCleanCombats"] = { default=false, nControlType=1, strControlName="CleanCombats", fnCallback="OnConfigChangedUpdate" },
	["bSaveCombats"] = { default=false, nControlType=1, strControlName="SaveCombats", fnCallback="OnConfigChangedUpdate" },

	-- Window
	-- opacity
	["nOpacity"] = { default=0, nControlType=2, nSliderPrec=100, strControlName="BackgroundOpacitySlider", fnCallback="OnConfigSliderChanged" },
	["nMouseOpacity"] = { default=0.5, nControlType=2, nSliderPrec=100, strControlName="HeaderOpacitySlider", fnCallback="OnConfigSliderChanged" },
	-- advanced
	["nUpdateRate"] = { default=0.3, nControlType=2, nSliderPrec=100, strControlName="UpdateRateSlider", fnCallback="OnConfigSliderChanged" },
	["nTextOpacity"] = { default=0.95, nControlType=2, nSliderPrec=100, strControlName="LineTextSlider", fnCallback="OnConfigSliderChanged" },

	-- Color
	-- class
	["crEngineer"] ={ default={0.65, 0.65, 0, 1}, nControlType=3, strControlName="EngineerColor", fnCallback="OnConfigColorChanged" },
	["crEsper"] =	{ default={0.1, 0.5, 0.7, 1}, nControlType=3, strControlName="EsperColor", fnCallback="OnConfigColorChanged" },
	["crMedic"] =	{ default={0.2, 0.6, 0.1, 1}, nControlType=3, strControlName="MedicColor", fnCallback="OnConfigColorChanged" },
	["crSslinger"] ={ default={0.9, 0.4,   0, 1}, nControlType=3, strControlName="SslingerColor", fnCallback="OnConfigColorChanged" },
	["crStalker"] =	{ default={0.5, 0.1, 0.8, 1}, nControlType=3, strControlName="StalkerColor", fnCallback="OnConfigColorChanged" },
	["crWarrior"] =	{ default={0.8, 0.1, 0.1, 1}, nControlType=3, strControlName="WarriorColor", fnCallback="OnConfigColorChanged" },
	-- ability
	["crMagic"] =	{ default={0.5, 0.1, 0.8, 1}, nControlType=3, strControlName="MagicColor", fnCallback="OnConfigColorChanged" },
	["crTech"] =    { default={0.2, 0.6, 0.1, 1}, nControlType=3, strControlName="TechColor", fnCallback="OnConfigColorChanged" },
	["crPhysical"] ={ default={0.6, 0.6, 0.6, 1}, nControlType=3, strControlName="PhysicalColor", fnCallback="OnConfigColorChanged" },
	["crShields"] =	{ default={0.1, 0.5, 0.7, 1}, nControlType=3, strControlName="ShieldsColor", fnCallback="OnConfigColorChanged" },
	["crHeal"] =	{ default={  0, 0.8,   0, 1}, nControlType=3, strControlName="HealColor", fnCallback="OnConfigColorChanged" },
	["crFall"] =	{ default={0.8, 0.3, 0.1, 1}, nControlType=3, strControlName="FallColor", fnCallback="OnConfigColorChanged" },
	["crSuffocate"]={ default={0.1, 0.7, 0.6, 1}, nControlType=3, strControlName="SuffocateColor", fnCallback="OnConfigColorChanged" },
	-- misc
	["crNone"] =	{ default={  1,   1,   1, 1}, nControlType=3, strControlName="NoneColor", fnCallback="OnConfigColorChanged" },
	["crTotal"] =	{ default={  0, 0.5,   1, 1}, nControlType=3, strControlName="TotalColor", fnCallback="OnConfigColorChanged" },
	["crDefault"] =	{ default={0.7, 0.7, 0.7, 1}, nControlType=3, strControlName="DefaultColor", fnCallback="OnConfigColorChanged" },
	-- opaticy
	["nFillOpacity"] = { default=0.7, nControlType=2, nSliderPrec=100, strControlName="LineFillSlider", fnCallback="OnConfigSliderChanged" },
	-- reset
	["bColorsTrue"] = { default=false, nControlType=8, strControlName="TruePlayerColors", fnCallback="OnConfigResetColors" },
	["bColorsOriginal"] = { default=false, nControlType=8, strControlName="DefaultPlayerColors", fnCallback="OnConfigResetColors" },
	["bColorsReset"] = { default=false, nControlType=8, strControlName="DefaultColors", fnCallback="OnConfigResetColors" },

	-- Base
	arPanels = { },					-- each panel window has its own settings, _defaultPanelSettings
	--data = {						-- save data
	--	arGUnits = nil,				-- special self.arGUnits
	--	arGAbilites = nil,			-- special self.arGAbilities and self.arGAbilitiesP
	--	arCombats = nil,			-- special self.arCombats
	--	tCombatOverall = nil,		-- special self.tCombatOverall
	--	tCombatCurrent = nil,		-- special self.tCombatCurrent
	--  nLastDamageAction = nil,	-- mirror self.nLastDamageAction
	--	bStopTracking = nil,		-- mirror self.bStopTracking
	--	bPermanent = nil,			-- mirror self.bPermanent
	--	bIsCombatOn = nil,			-- mirror self.bIsCombatOn
	--},
	--nSaveNow = 0,					-- saved 'now' for restart in combat, GameTime * 1000
	--nNow = 0,						-- single current 'now' used during run time, GameTime * 1000
	--bRequestRemovePartial = nil,	-- remember if still need to clean partial due to remove
	
	-- Report
	--sReportChannel = nil,
	--sReportTarget = nil,
	--nReportLines = nil,

	-- Non config window options
	bEnabled = true,
	--bNotice = nil,				-- display change notice

	-- Other

	sSettingsName = "Default",
	nSettingsVersion = 41,
}

local _defaultPanelSettings = {
	eSort = "damage",
	x = 0,
	y = 0,
	nWidth = 270,
	nDisplayRows = 8,
	nRowHeight = 18,
	--nRight = nil,
	--wndPosition = nil,
	--wndAnchors = nil,
}

local _eRank = Unit.CodeEnumRank
local _eCombatResult = GameLib.CodeEnumCombatResult
local _eDisposition = Unit.CodeEnumDisposition

local _tTrueColors = {
	["crWarrior"] =  {0.96, 0.31, 0.31, 1},
	["crEngineer"] = {0.94, 0.67, 0.28, 1},
	["crEsper"] =    {   0,    1,    1, 1},
	["crMedic"] =    { 0.2,  0.8,  0.2, 1},
	["crStalker"] =  {0.82, 0.24, 0.96, 1},
	["crSslinger"] = {0.29, 0.58, 0.85, 1},
}

local _tClassToColorSetting = {
	[_eClass.Warrior] = "crWarrior",		-- Class colors taken directly from website
	[_eClass.Engineer] = "crEngineer",
	[_eClass.Esper] = "crEsper",
	[_eClass.Medic] = "crMedic",
	[_eClass.Stalker] = "crStalker",
	[_eClass.Spellslinger] = "crSslinger",
}

local _tAbilityToColorSetting = {
	[_eDamageType.Magic] = "crMagic",
	[_eDamageType.Tech] = "crTech",
	[_eDamageType.Physical] = "crPhysical",
	[_eDamageType.HealShields] = "crShields",
	[_eDamageType.Heal] = "crHeal",
	[_eDamageType.Fall] = "crFall",
	[_eDamageType.Suffocate] = "crSuffocate",
}

local _arSpectrumColorSetting = {
	"crMagic",
	"crShields",
	"crSuffocate",
	"crFall",
	"crHeal",
	"crPhysical",
	"crTech",
}

local _tSettingsColors = {			-- color settings name to cached ApolloColor
}

local _crOptionsTabNormal = "11000000"
local _crOptionsTabEnter = "77000000"
local _crOptionsTabSelected = "dd000000"

local _nCombatEndWaitTime = 3000	-- milliseconds to wait from last action to see if out of combat
local _nCombatStartWaitTime = 24000	-- milliseconds to wait from first action to begin to allow reclaimation
local _nMemberUpdateTime = 3		-- frequency to update group member table
local _nInstanceCheckTime = 4		-- frequency to check for instance change
local _nProfileTime = 8				-- frequency to manage addon resource usage
local _nReclamationTime = 48		-- frequency to manage resources from longer-term structures
local _nMemoryMax = 9000000			-- memory max before attempts to reduce

local _floor = math.floor
local _abs = math.abs
local _format = string.format
local _tinsert = table.insert
local _tremove = table.remove

local _GetGameTime = GameLib.GetGameTime
local function _GameTime()
	return _floor(_GetGameTime() * 1000)
end

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


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function CombatMeter:new(o)
	o = self
	--o = o or {}
	--setmetatable(o, self)
	--self.__index = self

	o.L = o.L or _L or {}
	setmetatable(o.L, { __index = function(t,k) return k == nil and "" or tostring(k) end })

	o._AddonName = _AddonName
	o._defaultSettings = _defaultSettings
	o._resetSettings = _resetSettings
	o._defaultPanelSettings = _defaultPanelSettings
	o._print = _print
	o.print = print
	o.DeepCopy = DeepCopy
	o._tClassToColorSetting = _tClassToColorSetting
	o._tAbilityToColorSetting = _tAbilityToColorSetting
	o._arSpectrumColorSetting = _arSpectrumColorSetting
	--o._tClassColors = _tClassColors
	--o._tAbilityColors = _tAbilityColors
	o._tSettingsColors = _tSettingsColors

	--o.nTick = nil							-- fast update count
	--o.nAge = nil							-- slow update count
	--o.unitPlayer = nil
	--o.bInPvP = nil						-- currently in pvp instance
	--o.sInstanceName = nil					-- current instance name
	--o.sWorldName = nil					-- current world name

	--o.tUnitKeys = nil						-- expanded compression keys
	--o.tAbilKeys = nil

	o.arCombats = {}
	o.arGUnits = {}							-- global units, tGUnit
	o.arGAbilities = {}						-- global abilities single, tGAbility
	o.arGAbilitiesP = {}					-- global abilities periodic, tGAbility
	--o.tCombatCurrent = nil
	--o.tCombatOverall = nil

	o.nLastDamageAction = 0					-- time of last damage event, GameTime * 1000
	--o.nFirstDamageAction = nil			-- time of first damage event, GameTime * 1000
	--o.bStopTracking = nil					-- used by EndCombatAfterKill
	--o.bPermanent = nil					-- manual combat start
	--o.bIsCombatOn = nil
	--o.bRequestUpdate = nil

	o.tGroupMembers = {}					-- group member lookup

	o.arPanels = {}							-- meter panel settings
	o.arRowPool = {}

	--o.Panel = nil							-- panel class
	--o.bInLayout = nil
	--o._bWindowSizing = nil

	return o
end

function CombatMeter:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = { }
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- CombatMeter OnLoad
-----------------------------------------------------------------------------------------------

function CombatMeter:OnLoad()
	self.onXmlDocLoadedCalled = false

	self.userSettings = SettingsCopy(_defaultSettings)

	Apollo.LoadSprites("CombatMeterSprites.xml", "CombatMeter")

	-- create form
	self.xmlDoc = XmlDoc.CreateFromFile("CombatMeter.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("CombatMeter_ShowMenu", "OnShowMenu", self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)

	Apollo.RegisterSlashCommand("cm", "OnCommand", self)
	Apollo.RegisterSlashCommand("CM", "OnCommand", self)
	Apollo.RegisterSlashCommand("CombatMeter", "OnCommand", self)
	Apollo.RegisterSlashCommand("combatmeter", "OnCommand", self)
end

function CombatMeter:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName=self.L["CombatMeter Options"], nSaveVersion=_VersionWindow})
end

function CombatMeter:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", _AddonName,
		{ "CombatMeter_ShowMenu", "", "CombatMeter:AddonIcon" })
end


-----------------------------------------------------------------------------------------------
-- CombatMeter OnDocLoaded
-----------------------------------------------------------------------------------------------

function CombatMeter:OnDocLoaded()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
		return
	end

	Event_FireGenericEvent("OneVersion_ReportAddonInfo", _AddonName, 1, _Version, _VersionMinor)

	-- Load the window

	Apollo.RegisterEventHandler("ResolutionChanged",			"OnResolutionChanged", self)

	self.tUpdateTimer = ApolloTimer.Create(1.0, true, "OnUpdateTimer", self)
	self.tUpdateTimer:Stop()

	self.tVisibilityTimer = ApolloTimer.Create(1.0, true, "OnUpdateVisibility", self)

	self.onXmlDocLoadedCalled = true
	self:InitializeWindows()
end


-----------------------------------------------------------------------------------------------
-- CombatMeter Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:OnFrame()
	-- only if still in combat, end combat has its own. only matters if window about to update while in combat
	if self.bIsCombatOn then
		local nNow = _GameTime()

		local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall
		local n = nNow - tCombatCurrent.startTime
		tCombatOverall.duration = tCombatOverall.previousDuration + n
		tCombatCurrent.duration = n
	end

	-- update panels
	for i = 1,#self.arPanels do
		self:UpdatePanel(i)
	end
end

function CombatMeter:SetAnyCombat(bSet, bSave)
	if bSet and self.bPlayerInCombat then
		self.bIsAnyCombat = true
		if not bSave then
			return
		end
	end

	local player,units,members = self.unitPlayer, self.arGUnits, self.tGroupMembers
	if bSave then
		for k,_ in next, members do
			members[k] = nil
			local tGUnit = units[k]
			if tGUnit then
				tGUnit.bGroup = nil
			end
		end
	end

	local bCombat
	for i = 1, GroupLib.GetMemberCount() or 0 do
		local unit = GroupLib.GetUnitForGroupMember(i)
		if unit and unit:IsValid() then
			if bSet and not bCombat then
				bCombat = unit:IsInCombat()
			end
			if bSave then
				if _eDisposition.Hostile ~= unit:GetDispositionTo(player) then
					local k = unit:GetName() or ""
					members[k] = true
					local tGUnit = units[k]
					if tGUnit then
						tGUnit.bGroup = true
					end
				end
			elseif bCombat then
				break
			end
		end
	end

	if bSet then
		self.bIsAnyCombat = bCombat and true or false
	end
end

function CombatMeter:GetLastCombat()
	local combats = self.arCombats
	return combats[#combats - 1]
end

function CombatMeter:GetCurrentCombat()
	return self.tCombatCurrent
end

function CombatMeter:StartCombat(bPermanent)
	local o,panels = self.userSettings, self.arPanels
	if self.bIsCombatOn then
		return
	end

	local nNow = _GameTime()

	local tCombatOverall = self.tCombatOverall
	if not tCombatOverall then
		tCombatOverall = self:CombatNew(true, nNow)
		self.tCombatOverall = tCombatOverall
		_tinsert(self.arCombats, tCombatOverall)
	end

	local tCombatCurrent = self:CombatNew(false, nNow)
	self.tCombatCurrent = tCombatCurrent

	self.bIsCombatOn = true
	self.bPermanent = bPermanent
	_tinsert(self.arCombats, tCombatCurrent)

	for i = 1,#panels do
		self:StartPanel(i)
	end
end

function CombatMeter:EndCombat(bDurationIsCallTime, nNow)
	local o,panels = self.userSettings, self.arPanels
	if not self.bIsCombatOn then
		return
	end

	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall
	nNow = nNow or _GameTime()

	self:CombatSetStop(tCombatCurrent, bDurationIsCallTime, nNow)

	tCombatOverall.previousDuration = tCombatOverall.previousDuration + tCombatCurrent.duration
	tCombatOverall.duration = tCombatOverall.previousDuration

	self.bStopTracking = false
	self.bIsCombatOn = false
	self.bPermanent = nil

	self.bRequestUpdate = true

	self.nFirstDamageAction = nil

	for i = 1,#panels do
		self:StopPanel(i)
	end
end


-- create destroy		-----------------------------------------------------------------------

function CombatMeter:ArchiveCombats()
	local combats = self.arCombats
	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall

	for i,v in ipairs(combats) do
		if not v.bCompress and v ~= tCombatCurrent and v ~= tCombatOverall
			and not self:IsPanelsHaveCombat(v) then
			self:CombatArchive(v)
		end
	end
end

function CombatMeter:ArchivePartial()
	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall

	if tCombatCurrent and tCombatOverall
		and not self:IsPanelsHaveCombat(tCombatOverall) then
		self:CombatArchivePartial(tCombatOverall, tCombatCurrent)
	end
end

function CombatMeter:RemoveCombats()
	local o,combats = self.userSettings, self.arCombats
	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall

	local id
	for i,v in ipairs(combats) do
		if v ~= tCombatCurrent and v ~= tCombatOverall and not self:IsPanelsHaveCombat(v) then
print("remove", i, v.sWorldName)														--PROF:
			id = i; break
		end
	end
	if not id then
		return
	end

	local combat = combats[id]
	_tremove(combats, id)

	o.bRequestRemovePartial = true
	self.bRequestUpdate = true
end

function CombatMeter:RemoveCombatsPartial()
	local o = self.userSettings
	local tCombatOverall = self.tCombatOverall

	if not self:IsPanelsHaveCombat(tCombatOverall) then
		self:CombatRemovePartial(tCombatOverall)
		o.bRequestRemovePartial = nil
	end

	self.bRequestUpdate = true
end

function CombatMeter:GetGlobalUnit(unit, owner)
	local units = self.arGUnits
	local name = unit:GetName() or "Unknown"

	local list, tGOwner = units
	if owner then
		tGOwner = self:GetGlobalUnit(owner)		-- search for pet owner if pet
		list = tGOwner.tPets					-- allow pet cache per owner, by pet name
		if not list then
			list = {}
			tGOwner.tPets = list
		end
		if name == tGOwner.name then			-- unify stalker clone names
			name = self.L["Clone"]				--  client sometimes calls pet Clone and sometimes the owners name
		end
	end

	local tGUnit = list[name]
	if not tGUnit then
		tGUnit = self:NewGlobalUnit(unit, tGOwner, name)
		list[name] = tGUnit

		local count = #units + 1
		units[count] = tGUnit
		units[tGUnit] = count
	end

	return tGUnit
end

local _tDotMismatch = {		-- dots events that look like shouldn't be dots (but maybe really should be)
	[19031] = true,			-- esper bolster, dot version getting MH only
	[58792] = true,			-- esper soothe, dot version getting MH only
	[25531] = true,			-- medic mending probes, dot version getting MH only
	[25614] = true,			-- medic protection probes, dot version getting MH only
	[39093] = true,			-- medic regenerator, dot version getting MH only
	[39188] = true,			-- medic transfusion, dot version getting MH only
	[53119] = true,			-- medic rejuvination, dot version getting MH only
	--[55010] = true,		-- medic field probes damage. leave this one, not broken
	[53121] = true,			-- medic field probes heal, dot version getting
	[21490] = true,			-- ss astral infusion, dot version getting MH o MH only
	[36928] = true,			-- ss healing aura, dot version getting MH onlynly
	[47744] = true,			-- ss speed of the void, dot version getting MH only
	[58791] = true,			-- ss vitality burst, dot version getting MH only
}

function CombatMeter:GetGlobalAbility(tGCaster, ability, bPeriodic)--, sort)
	local abils = self.arGAbilities
	local name = ability:GetName() or "Unknown"

	if bPeriodic and _tDotMismatch[ability:GetBaseSpellId()] then	-- fix mismarked spells on carbine events
		bPeriodic = nil
	end
	local iga = bPeriodic and self.arGAbilitiesP or abils

	local tGAbility = iga[name]
	if not tGAbility then
		tGAbility = self:NewGlobalAbility(tGCaster, ability, name, bPeriodic)
		iga[name] = tGAbility

		local count = #abils + 1
		abils[count] = tGAbility
		abils[tGAbility] = count
	end

	return tGAbility
end

function CombatMeter:UpdateLayout()
	local ipa = self.arPanels

	for _,v in ipairs(ipa) do
		self:UpdatePanelLayout(v)
	end
end


-- visibility timer		-----------------------------------------------------------------------

function CombatMeter:OnUpdateTimer()
	--self.nTick = (self.nTick or 0) + 1

	if self.bRequestUpdate or self.bPermanent then
		self.bRequestUpdate = nil
		self:OnFrame()
	end
end

function CombatMeter:OnUpdateVisibility()
	self.nAge = (self.nAge or 0) + 1

	self:UpdateVisibilityCommon()

	for _,v in ipairs(self.arPanels) do
		v:UpdateVisibility()
	end

	if self.bRequestLayout then
		self:UpdateLayout()
		self.bRequestLayout = nil
	end

	if self.bRequestUpdate then
		self:OnUpdateTimer()
	end

	self:UpdateVisibilityExternal()
end

function CombatMeter:UpdateVisibilityCommon()
	local o,player,nAge = self.userSettings, self.unitPlayer, self.nAge

	if self.bIsCombatOn then
		o.nNow = _GameTime()
	end

	if not player or not player:IsValid() then
		player = GameLib.GetPlayerUnit()
		self.unitPlayer = player or self.unitPlayer
	end

	-- in combat
	local bPlayerInCombat = self.bPlayerInCombat
	if player and player:IsValid() then
		bPlayerInCombat = player:IsInCombat() and true or false
		self.bPlayerInCombat = bPlayerInCombat
	end
	local bSet = bPlayerInCombat ~= self.bIsAnyCombat
	local bSave = (nAge % _nMemberUpdateTime) == 0
	if bSet or bSave then								-- if need to save group members, or on transitions double check other other sources
		self:SetAnyCombat(bSet, bSave)
	end

	-- end of combat
	if self.bIsCombatOn and not self.bIsAnyCombat and not self.bPermanent then
		if o.nNow - self.nLastDamageAction > _nCombatEndWaitTime then
			self:EndCombat(nil, o.nSaveNow or o.nNow)
		end
		o.nSaveNow = nil
	end

	-- archive and remove
	if (nAge % _nProfileTime) == 0 then					-- on timer to diffuse cost
		self:ArchiveCombats()							--   removes last combat thats not totals, not current, and not being viewed
	end
	if (nAge % _nReclamationTime) == 0 then
		if not self.nFirstDamageAction or (o.nNow - self.nFirstDamageAction > _nCombatStartWaitTime) then
			self:ArchivePartial()
			local t = o.bCleanCombats and Apollo.GetAddonInfo(_AddonName)
			if t then
	print(nAge, "memory", t.nMemoryUsage, _floor(t.fCallTimePerFrame * 1000000000) / 1000, self.nFirstDamageAction and (o.nNow - self.nFirstDamageAction))																	--PROF:
				if t.nMemoryUsage > _nMemoryMax then	-- we only remove one per iteration
					self:RemoveCombats()				--   removes last combat thats not totals, not current, and not being viewed
				end
			end
		end
	end
	if (nAge % _nReclamationTime) == 0 or o.bRequestRemovePartial then
		self:RemoveCombatsPartial()						-- totals may be open, so we wait if need to remove
	end

	-- instances
	if (nAge % _nInstanceCheckTime) == 0 then
		self.bInPvP = MatchingGameLib.GetPvpMatchState()
		local match = MatchingGameLib.GetQueueEntry()
		local info = match and match:GetInfo()
		self.sInstanceName = info and info.strName or GetCurrentZoneName()
		info = GameLib.GetCurrentZoneMap()
		self.sWorldName = info and info.strName or self.sInstanceName
	end
	local tCombatCurrent = self.tCombatCurrent
	if self.bIsCombatOn and self.bInPvP and not tCombatCurrent.name then
		tCombatCurrent.name = self.sWorldName or nil
	end
	if self.bIsCombatOn and not tCombatCurrent.sInstanceName then
		tCombatCurrent.sInstanceName = self.sInstanceName or nil
		tCombatCurrent.sWorldName = self.sWorldName or nil
	end

	-- cvars
	local bLogOthers = not Apollo.GetConsoleVariable("cmbtlog.disableOtherPlayers")
	if bLogOthers ~= o.bLogOthers then
		Apollo.SetConsoleVariable("cmbtlog.disableOtherPlayers", not o.bLogOthers)
	end

	if self._log and self.nAge > 3 then														--PROF:
		for i,v in ipairs(self._log) do														--PROF:
			if type(v) == "table" then print(unpack(v)) else print(v) end					--PROF:
		end																					--PROF:
		self._log = nil																		--PROF:
	end																						--PROF:
end

function CombatMeter:UpdateVisibilityExternal()
	-- external mini buttons etc

end


-- other system events	-----------------------------------------------------------------------

function CombatMeter:CombatEventsHandler(tEventArgs, sort, stat, value, stat2, value2)
	if self.bStopTracking and not self.bPermanent then		-- force a combat end on several bosses with incoming damage after kill extending the duration
		return
	end
--_print("*-----------", stat, value, value2)

	local caster,target,owner = tEventArgs.unitCaster, tEventArgs.unitTarget, tEventArgs.unitCasterOwner
	if not caster or not target then
		return
	end

	if not self.bIsCombatOn then
		if caster == target or (stat ~= "damage" and stat ~= "interrupts") then
			return
		end
		self:StartCombat()
	end

	if stat ~= "heal" then
		self.nLastDamageAction = _GameTime()
		if not self.nFirstDamageAction then
			self.nFirstDamageAction = self.nLastDamageAction
		end
	end
	self.bRequestUpdate = true

	if value == 0 then
		value = nil
	end
	if value2 == 0 then
		value2 = nil
	end

	local tGTarget = self:GetGlobalUnit(target, nil)
	local tGCaster = self:GetGlobalUnit(caster, owner)
	local tGAbility = self:GetGlobalAbility(tGCaster, tEventArgs.splCallingSpell, tEventArgs.bPeriodic)--, sort)

	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall
	if not tCombatCurrent.bBoss and (caster:GetRank() == _eRank.Elite or target:GetRank() == _eRank.Elite) then
		tCombatCurrent.bBoss = true
	end

	local tGOwner,tOwnerOverall,tOwnerCurrent = tGCaster.tGOwner
	if tGOwner then
		tOwnerOverall = self:CombatGetPlayer(tCombatOverall, tGOwner)
		tOwnerCurrent = self:CombatGetPlayer(tCombatCurrent, tGOwner)
	end

	-- Caster
	local tCasterOverall = self:CombatGetPlayer(tCombatOverall, tGCaster)
	local tCasterCurrent = self:CombatGetPlayer(tCombatCurrent, tGCaster)

	self:PlayerAddStat(tCasterOverall, tGTarget, tGCaster, tGAbility, tEventArgs, sort, stat, value)
	self:PlayerAddStat(tCasterCurrent, tGTarget, tGCaster, tGAbility, tEventArgs, sort, stat, value)

	if value2 and stat2 then						-- extra effects, like overheal overkill
		self:PlayerAddStat(tCasterOverall, tGTarget, tGCaster, tGAbility, tEventArgs, stat2, stat2, value2)
		self:PlayerAddStat(tCasterCurrent, tGTarget, tGCaster, tGAbility, tEventArgs, stat2, stat2, value2)
	end

	-- Target
	local tTargetOverall = self:CombatGetPlayer(tCombatOverall, tGTarget)
	local tTargetCurrent = self:CombatGetPlayer(tCombatCurrent, tGTarget)

	sort = stat == "heal" and "healTaken" or "damageTaken"

	self:PlayerAddStat(tTargetOverall, tGCaster, tGCaster, tGAbility, tEventArgs, sort, sort, value)
	self:PlayerAddStat(tTargetCurrent, tGCaster, tGCaster, tGAbility, tEventArgs, sort, sort, value)
end

function CombatMeter:OnCombatLogDamage(tEventArgs)
	local value = tEventArgs.nDamageAmount + tEventArgs.nAbsorption + tEventArgs.nShield
	local value2 = tEventArgs.nOverkill
	local b = tEventArgs.unitCaster ~= tEventArgs.unitTarget
	local sort = b and "damage" or "damageTaken"
	local stat = b and "damage" or "damageTaken"
	local stat2 = b and "overkill" or nil
	self:CombatEventsHandler(tEventArgs, sort, stat, value, stat2, value2)
end

function CombatMeter:OnCombatLogMultiHit(tEventArgs)
	local value = tEventArgs.nDamageAmount + tEventArgs.nAbsorption + tEventArgs.nShield
	--local value2
	tEventArgs.bMultiHit = true					-- probably shoudnt be doing this. carbine UI code only looks on deflect
	local b = tEventArgs.unitCaster ~= tEventArgs.unitTarget
	local sort = b and "damage" or "damageTaken"
	local stat = b and "damage" or "damageTaken"
	--local stat2 = b and "overkill" or nil
	self:CombatEventsHandler(tEventArgs, sort, stat, value)--, stat2, value2)
end

function CombatMeter:OnCombatLogHeal(tEventArgs)
	local value = tEventArgs.nHealAmount
	local value2 = tEventArgs.nOverheal
	self:CombatEventsHandler(tEventArgs, "heal", "heal", value, "overheal", value2)
end

function CombatMeter:OnCombatLogMultiHeal(tEventArgs)
	local value = tEventArgs.nHealAmount
	local value2 = tEventArgs.nOverheal
	tEventArgs.bMultiHit = true				--NOTE: setting on carbine table. wont conflict carbine UI code only looks at multihit on deflect
	self:CombatEventsHandler(tEventArgs, "heal", "heal", value, "overheal", value2)
end

function CombatMeter:OnCombatLogTransference(tEventArgs)
	self:OnCombatLogDamage(tEventArgs)
	local t = tEventArgs.tHealData[1]
	local value = t.nHealAmount
	local value2 = t.nOverheal
	self:CombatEventsHandler(tEventArgs, "heal", "heal", value, "overheal", value2)
end

function CombatMeter:OnCombatLogCCState(tEventArgs)
	local nInterruptArmorHit = tEventArgs.nInterruptArmorHit
	if not nInterruptArmorHit or nInterruptArmorHit == 0 then
		return
	end
	local value = nInterruptArmorHit
	local value2 = nInterruptArmorHit
	self:CombatEventsHandler(tEventArgs, "damage", "interrupts", value, "interrupts", value2)
end

function CombatMeter:OnCombatLogDeflect(tEventArgs)
	local value
	local value2 = 1
	self:CombatEventsHandler(tEventArgs, "damage", "deflects", value, "deflects", value2)
end


-----------------------------------------------------------------------------------------------
-- CombatMeter Form Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:OnCurrentToMain()
	local o,panels = self.userSettings, self.arPanels

	for _,panel in pairs(panels) do
		panel:SettingsToCurrent()
	end

	self.tUpdateTimer:Set(tonumber(o.nUpdateRate) or 0.2, true)				-- accidental nil will lock-up the client
end

function CombatMeter:OnButtonConfig(wndHandler, wndControl, eMouseButton)
	self:OnCommand(nil, "config")
end

function CombatMeter:OnButtonClear(wndHandler, wndControl, eMouseButton)
	self:OnCommand(nil, "clear")
end

function CombatMeter:OnButtonStart(wndHandler, wndControl, eMouseButton)
	self:OnCommand(nil, self.bIsCombatOn and "end" or "start")
end

function CombatMeter:OnButtonSolo(wndHandler, wndControl)
	local o = self.userSettings

	o.bLogOthers = not o.bLogOthers
	self:OnCurrentToMain()
	self:OnCurrentToConfig()			-- let the options dialog update to help make clear they are the same option
end


-----------------------------------------------------------------------------------------------
-- OptionsForm Form Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:OnConfigure()
	self:OnOptionsForm()
end

function CombatMeter:OnCloseWindow()
	self.wndOpts:Close()
end

function CombatMeter:OnCancel()
	self:OnCloseWindow()
end

function CombatMeter:OnOK()
	self.configCommitting = true
	self:OnCloseWindow()
end

function CombatMeter:OnOptionsClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local wo,L = self.wndOpts, self.L
	if wo and wo:IsValid() then
		wo:Close()
		wo:Destroy()
		self.wndOpts = nil
		self._tOptionsTabs = nil

		Event_FireGenericEvent("WindowManagementRemove", {strName=L["CombatMeter Options"]})
	end
end

function CombatMeter:OnOptionsForm()
	local o,L = self.userSettings, self.L
	if self.wndOpts then
		return
	end

	local wo = Apollo.LoadForm(self.xmlDoc, "OptionsForm", nil, self)
	self.wndOpts = wo

	self:OnPanelForm(wo)

	-- fixups
	wo:FindChild("Title"):SetText(L["CombatMeter Options"])

	self._tOptionsTabs = {
		GeneralViewButton = "GeneralView",
		WindowViewButton = "WindowView",
		ColorViewButton = "ColorView"
	}
	self:OnOptionsTabCheck(nil, wo:FindChild(self.sOptionsTab or "GeneralViewButton"))

	self:OnCurrentToConfig()
	wo:Invoke()

	Event_FireGenericEvent("WindowManagementAdd", {wnd = wo, strName=L["CombatMeter Options"], nSaveVersion=_VersionWindow})
end

function CombatMeter:OnSingleOptionsTab(wndControl, bSelected)
	wndControl:SetBGColor(bSelected and _crOptionsTabSelected or _crOptionsTabNormal)
end

function CombatMeter:OnConfigTabEnter(wndHandler, wndControl, x, y)
	local name = wndControl:GetName()
	if wndHandler ~= wndControl and self._tOptionsTabs[name] and self.sOptionsTab ~= name then
		wndControl:SetBGColor(_crOptionsTabEnter)
	end
end

function CombatMeter:OnConfigTabExit(wndHandler, wndControl, x, y)
	local name = wndControl:GetName()
	if wndHandler ~= wndControl and self._tOptionsTabs[name] and self.sOptionsTab ~= name then
		wndControl:SetBGColor(_crOptionsTabNormal)
	end
end

function CombatMeter:OnCurrentToConfig()
	local o,wo = self.userSettings, self.wndOpts
	if not wo then
		return
	end

	-- Generic managed controls
	self:OnCurrentToPanel(wo)

	self:OnConfigSliderChanged()

	self:OnEnablerButtonChecked()
end

function CombatMeter:OnEnablerButtonChecked()
end

function CombatMeter:OnConfigSliderChanged(v)
	local o,wo = self.userSettings, self.wndOpts

	wo:FindChild("BackgroundOpacityValue"):SetText(_format("%.2f", o.nOpacity))
	wo:FindChild("HeaderOpacityValue"):SetText(_format("%.2f",o.nMouseOpacity))
	wo:FindChild("UpdateRateValue"):SetText(_format("%.1f",o.nUpdateRate))
	wo:FindChild("LineFillValue"):SetText(_format("%.2f",o.nFillOpacity))
	wo:FindChild("LineTextValue"):SetText(_format("%.2f",o.nTextOpacity))

	if v then
		self:OnCurrentToMain()
	end
end

function CombatMeter:OnConfigChangedUpdate()
	local panels = self.arPanels

	self:OnCurrentToMain()

	for i = 1,#panels do
		self:UpdatePanel(i)
	end
end

function CombatMeter:OnConfigColorChanged(v)
	local o,panels,_d = self.userSettings, self.arPanels, _defaultSettings

	if v then
		_tSettingsColors[v.sName] = ApolloColor.new(o[v.sName])
	else
		for k,v in next, _d do
			if type(v) == "table" and v.nControlType == 3 then
				_tSettingsColors[k] = ApolloColor.new(o[k])
			end
		end
	end

	self:OnConfigChangedUpdate()
end

function CombatMeter:OnConfigResetColors(v)
	local o,wo,panels,_d = self.userSettings, self.wndOpts, self.arPanels, _defaultSettings

	if v.sName == "bColorsTrue" then
		for k,v2 in next, _tTrueColors do
			o[k] = v2
		end
	elseif v.sName == "bColorsOriginal" then
		for k,v2 in next, _tTrueColors do
			o[k] = _d[k].default
		end
	elseif v.sName == "bColorsReset" then
		for k,v2 in next, _d do
			if type(v2) == "table" and v2.nControlType == 3 then
				o[k] = v2.default
			end
		end
	end

	self:OnConfigColorChanged()
	self:OnCurrentToConfig()
end


-----------------------------------------------------------------------------------------------

function CombatMeter:OnWindowMove(wndHandler, wndControl)
	local o,ipa = self.userSettings, self.arPanels
	if wndHandler ~= wndControl or self.bInLayout then
		return
	end
	for i,v in next, ipa do
		if v.w == wndControl and not v.bInLayout then
			self:OnPositionRelativeChanged(v, true)
			self:UpdatePanelLayout(v)
		end
	end
end

function CombatMeter:OnEnablerButtonChecked()
end

function CombatMeter:OnPositionRelativeChanged(panel, bFreeMove)
	local o,w = self.userSettings, panel.w

	local p0,p1,p2,p3 = w:GetAnchorOffsets()
	local a0,a1,a2,a3 = w:GetAnchorPoints()
	local e = Apollo.GetDisplaySize()
	local u,v = e.nWidth, e.nHeight

	p0,p1,p2,p3 = p0 + u * a0, p1 + v * a1, p2 + u * a2, p3 + v * a3			-- normalize position to anchors 0,0,0,0

	if o.bRelative then
		a0 = o.bRelative and (o.bAnchorRight and 1 or 0) or a0
		a1 = o.bRelative and (o.bAnchorBottom and 1 or 0) or a1
	else
		local r0,r1,r2,r3 = p0 / u, p1 / v, p2 / u, p3 / v						-- get extent ratios to edges
		a0 = r0 < .25 and 0 or r2 > .7 and 1 or .5				-- left right
		a1 = r1 < .35 and 0 or r3 > .7 and 1 or .5				-- top bottom
	end
	a2,a3 = a0, a1

	if not bFreeMove then
		if p0 < 0 then p0,p2 = 0,				p2 - p0 end		-- left			-- clip position extents for each edge, do this on load
		if p1 < 0 then p1,p3 = 0,				p3 - p1 end		-- top
		if p2 > u then p0,p2 = u - (p2 - p0),	u		end		-- right
		if p3 > v then p1,p3 = v - (p3 - p1),	v		end		-- bottom
	end

	w:SetAnchorPoints(a0, a1, a2, a3)
	w:SetAnchorOffsets(p0 - u * a0, p1 - v * a1, p2 - u * a2, p3 - v * a3)		-- translate position to new anchors
end

function CombatMeter:OnPositionOptionsChanged()
	local wo,ipa = self.wndOpts, self.arPanels

	for _,v in ipairs(ipa) do
		self:OnPositionRelativeChanged(v)
	end

	if wo and wo:IsValid() then
		self:OnEnablerButtonChecked()
	end
end


-----------------------------------------------------------------------------------------------
-- CombatMeter Startup
-----------------------------------------------------------------------------------------------

function CombatMeter:OnSaveData(o)
	local units,abils = self.arGUnits, self.arGAbilities	-- unit reverse lookup, key to storage id

	if not units or not self.arCombats
		or not self.arGAbilities or not self.arGAbilitiesP
	then return end

	local tUnitKeys, tAbilKeys = self:CombatEnsureCompress()
	o.nUnitSchema = self.nUnitSchema
	o.nAbilSchema = self.nAbilSchema

	-- special combats
	for i,v in next, self.arCombats do
		if v == self.tCombatOverall then o.tCombatOverall = i end
		if v == self.tCombatCurrent then o.tCombatCurrent = i end
	end

	-- combats
	o.arCombats = self.arCombats
	for _,v in ipairs(o.arCombats) do
		if not v.bCompress or v.bPartial then
			self:CombatCompress(v, tUnitKeys, tAbilKeys)
			v.bSaveCompress = true
		end
	end

	-- global units
	for _,v in ipairs(units) do
		units[v.name] = nil										-- remove name lookup
		v.bPlayer = v.bPlayer or nil							-- ensure no value if not on
		v.tGOwner = units[v.tGOwner]							-- set owner to owner's id
		v.tPets = nil											-- pets will be recreated via owner
	end
	o.arGUnits = units

	-- global abilites
	for _,v in ipairs(abils) do
		abils[v.name] = nil										-- remove name lookup
	end
	o.arGAbilities = abils

	o.nLastDamageAction = self.nLastDamageAction or nil
	o.nFirstDamageAction = self.nFirstDamageAction or nil
	o.bStopTracking = self.bStopTracking or nil
	o.bPermanent = self.bPermanent or nil
	o.bIsCombatOn = self.bIsCombatOn or nil

	o.nSaveNow = self.bIsCombatOn and o.nNow or nil				-- recover if still in combat when ui stopped

	return true
end

function CombatMeter:OnRestoreData(o)
--self._log = self._log or {}																		--PROF:
--self._log[#self._log + 1] = { o.arCombats and #o.arCombats, o.tCombatOverall, o.tCombatCurrent }	--PROF:
	local units,abils = o.arGUnits, o.arGAbilities
	if not units or not abils then
		return
	end

	self.tCompKeysR, self.tCompValuesR, self.tCompSchemasR = nil, nil, nil
	self:EnsureCompress()
	local tUnitKeys = self:ExpandSchemaKeys(o.nUnitSchema)		-- use keys from saved schema
	local tAbilKeys = self:ExpandSchemaKeys(o.nAbilSchema)

	-- global units
	local _t = {}
	for i,v in ipairs(units) do									-- iterator for table expansion
		_t[i] = v
	end
	for i,v in ipairs(_t) do
		units[v] = i											-- add tGUnit key
		local list = units
		if v.tGOwner then
			local v2 = units[v.tGOwner]
			v.tGOwner = v2
			local list = v2.tPets
			if not list then
				list = {}
				v2.tPets = list									-- add pets table
			end
		end
		list[v.name] = v										-- add name key
	end
	self.arGUnits = units

	-- global abilities
	_t = {}
	for i,v in ipairs(abils) do									-- iterator for table expansion
		_t[i] = v
	end
	local abilsP = {}
	for i,v in ipairs(_t) do
		abils[v] = i;											-- add tGAbility key
		(v.bPeriodic and abilsP or abils)[v.name] = v			-- add name key
	end
	self.arGAbilities,self.arGAbilitiesP = abils, abilsP

	-- combats
	for _,v in ipairs(o.arCombats) do
		if v.bSaveCompress then
			if v.bPartial then									-- special handling for uncompress partial
				self:CombatUnarchivePartial(v, tUnitKeys, tAbilKeys)
			else
				self:CombatUncompress(v, tUnitKeys, tAbilKeys)
			end
			v.bSaveCompress = nil
		end
	end
	self.arCombats = o.arCombats

	-- special combats
	self.tCombatOverall = o.tCombatOverall and o.arCombats[o.tCombatOverall] or nil
	self.tCombatCurrent = o.tCombatCurrent and o.arCombats[o.tCombatCurrent] or nil

	self.nLastDamageAction = o.nLastDamageAction or self.nLastDamageAction or 0
	self.nFirstDamageAction = o.nFirstDamageAction or self.nFirstDamageAction or nil
	self.bStopTracking = o.bStopTracking or self.bStopTracking or nil
	self.bPermanent = o.bPermanent or self.bPermanent or nil
	self.bIsCombatOn = o.bIsCombatOn or self.bIsCombatOn or nil
end

function CombatMeter:OnSave(eType)
	local tSave

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local o = self.userSettings

		local ipa = self.arPanels
		for i,v in next, o.arPanels do
			local panel = ipa[i]
			if panel.bSavePos then
				v.wndPosition = { panel.w:GetAnchorOffsets() }
				v.wndAnchors = { panel.w:GetAnchorPoints() }
				v.x, v.y, v.nRight, _ = unpack(v.wndPosition)
				v.nWidth = _abs(v.nRight - v.x)
			end
		end

		tSave = { }

		if o.bSaveCombats then
			local data = {}
			--if xpcall(function() self:OnSaveData(data) end, function() print(debug.traceback()) end) then
			if pcall(self.OnSaveData, self, data) then
				tSave.data = data
			end
		end
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

function CombatMeter:OnRestore(eType, tSave)
	if tSave then
		local o,_ds = self.userSettings, _defaultSettings

		local nVersion = tSave["nSettingsVersion"] or 0

		for k,v in pairs(tSave) do
			local t = _defaultSettings[k]
			if (type(t) == "table" and t.eSaveLevel or _eSaveLevel.Character) == eType then
				-- migrations
				if nVersion < 3 then k = nil end	-- old beta values, just reset
				if nVersion < 4 and k == "crSsliger" then k = "crSslinger" end
				if nVersion < 6 and k == "nUpdateRate" and v < 0.4 then v = 0.3 end
				if nVersion < 7 and k == "nTextOpacity" and v == 1 then v = 0.95 end
				if nVersion < 16 and k == "crFall" then v = nil end
				if nVersion < 16 and k == "crSuffocate" then v = nil end
				if nVersion < 38 and k == "bCleanCombats" then v = true end
				if nVersion < 38 and k == "bSaveCombats" then v = true end
				-- filters
				if k == "data" then v = nil end
				if k == "nSettingsVersion" then v = o.nSettingsVersion end
				if k == "sSettingsTooltip" then v = nil end
				if k ~= nil then o[k] = DeepCopy(v) end
			end
			-- migrations
		end
		if nVersion < 38 then o.bNotice = true end
		if nVersion < 41 then tSave.data = nil end
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Realm then
	end

	if eType == GameLib.CodeEnumAddonSaveLevel.Character then
		local o = self.userSettings

		if o.bSaveCombats and tSave and tSave.data then
			--self._log = self._log or {}																		--PROF:
			--if not xpcall(function() self:OnRestoreData(tSave.data) end, function() local t = self._log; t[#t + 1] = { debug.traceback() } end) then	--PROF:
			if not pcall(self.OnRestoreData, self, tSave.data) then
				self:OnCommand(nil, "clear")
			end
			tSave.data = nil
		end

		self:InitializeWindows()
	end
end

function CombatMeter:InitializeWindows()
	local o,panels = self.userSettings, self.arPanels

	o.nNow = _GameTime()

	self:OnCurrentToCommand()

	Apollo.SetConsoleVariable("cmbtlog.disableOtherPlayers", not o.bLogOthers)		-- reconcile log other players

	for k,v in next, _defaultSettings do
		if type(v) == "table" and v.nControlType == 3 then
			_tSettingsColors[k] = ApolloColor.new(o[k])
		end
	end

	-- rest needs docload
	if not self.onXmlDocLoadedCalled then
		return
	end

	local bEnabled = o.bEnabled
	self:Off()

	-- clear existing panels
	for i = #panels,1,-1 do
		self:RemovePanel(i, false)
	end

	-- create panels
	local opanels = o.arPanels
	if #opanels == 0 then
		opanels[1] = self:GetDefaultPanelSettings()
	end
	for i,v in ipairs(opanels) do
		self:EnsurePanel(i, v)
	end

	self:OnCurrentToMain()							-- general options to main window controls

	if bEnabled then
		self:On()
	end
end


-----------------------------------------------------------------------------------------------
-- CombatMeter Commands
-----------------------------------------------------------------------------------------------

function CombatMeter:OnShowMenu()				-- used by InterfaceMenuList
	self:OnCommand()
end

function CombatMeter:OnCurrentToCommand()
	local o = self.userSettings
	print = o.bIsDebug and _print or _dummy
	self.print = print
end

function CombatMeter:On()
	local o = self.userSettings

	self:OnCommand(nil, "show")

	if not o.bEnabled then
		local f = Apollo.RegisterEventHandler
		f("CombatLogDamage",          "OnCombatLogDamage",       self)
		f("CombatLogDamageShields",   "OnCombatLogDamage",       self)
		f("CombatLogReflect",         "OnCombatLogDamage",       self)
		f("CombatLogMultiHit",        "OnCombatLogMultiHit",     self)
		f("CombatLogMultiHitShields", "OnCombatLogMultiHit",     self)
		f("CombatLogHeal",            "OnCombatLogHeal",         self)
		f("CombatLogMultiHeal",       "OnCombatLogMultiHeal",    self)
		f("CombatLogDeflect",         "OnCombatLogDeflect",      self)
		f("CombatLogTransference",    "OnCombatLogTransference", self)
		f("CombatLogCCState",         "OnCombatLogCCState",      self)

		o.bEnabled = true

		self.tUpdateTimer:Start()
	end
end

function CombatMeter:Off()
	local o = self.userSettings

	if o.bEnabled then
		o.bEnabled = false

		self.tUpdateTimer:Stop()

		local f = Apollo.RemoveEventHandler
		f("CombatLogDamage",          self)
		f("CombatLogDamageShields",   self)
		f("CombatLogReflect",         self)
		f("CombatLogMultiHit",        self)
		f("CombatLogMultiHitShields", self)
		f("CombatLogHeal",            self)
		f("CombatLogMultiHeal",       self)
		f("CombatLogDeflect",         self)
		f("CombatLogTransference",    self)
		f("CombatLogCCState",         self)
	end

	self:OnCommand(nil, "hide")
end

function CombatMeter:OnCommand(sCommand, sArgs)
	local o,wo,panels,L = self.userSettings, self.wndOpts, self.arPanels, self.L

	sArgs = sArgs and sArgs:lower() or ""
	local sArg1, sArg2 = sArgs:match("([^ ]+) *(.-) *$")	-- '  aaa   bb cc  ' to 'aaa', 'bb cc'

	if not sArg1 or sArg1 == ""				-- toggle display window
		or sArg1 == "toggle" then
		if o.bEnabled then
			self:Off()
		else
			self:On()
		end
	elseif sArg1 == "off" then
		self:Off()
		PostChat("CombatMeter is now off")
	elseif sArg1 == "on" then
		self:On()
		PostChat("CombatMeter is now on")

	elseif sArg1 == "hide" then
		for id = 1,#panels do
			self:ShowPanel(id, false)
		end
	elseif sArg1 == "show" then
		for id = 1,#panels do
			self:ShowPanel(id, true)
		end
		if o.bNotice then
			self:OnNoticeForm()
			o.bNotice = nil	
		end
	elseif sArg1 == "notice" then
		self:OnNoticeForm()

	elseif sArg1 == "options"				-- toggle config window
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

	elseif sArg1 == "start" then
		self:StartCombat(true)
	elseif sArg1 == "end" then
		self:EndCombat(true)

	elseif sArg1 == "lock" then
		o.bLockWindows = true
		self:OnCurrentToMain()
	elseif sArg1 == "unlock" then
		o.bLockWindows = false
		self:OnCurrentToMain()

	elseif sArg1 == "clear" then
		self:EndCombat()
		self.bIsCombatOn = false
		self.arCombats = {}
		self.arGUnits = {}
		self.arGAbilities = {}
		self.arGAbilitiesP = {}
		self.tCombatCurrent = nil
		self.tCombatOverall = nil
		for id = 1,#panels do
			self:ClearPanel(id)
		end
		self.tUnitKeys = nil						-- expanded compression keys
		self.tAbilKeys = nil

	elseif sArg1 == "default" then
		self:Off()
		for i = #panels,1,-1 do
			self:RemovePanel(i, true)		-- true also removes o.arPanels
		end
		self:InitializeWindows()
		self:On()

	elseif sArg1 == "reset" then
		self.userSettings = SettingsCopy(_defaultSettings)
		self:InitializeWindows()
		if wo and wo:IsValid() then
			self:OnCurrentToConfig()
		end

	elseif sArg1 == "debug" then
		o.bIsDebug = not o.bIsDebug
		self:OnCurrentToCommand()
		PostChat(L["debug"] .. " " .. (o.bIsDebug and L["on"] or L["off"]))

	elseif sArg1 == "help" then
		local _addonname = _AddonName:lower()
		PostChat(_format(L["%s commands:"],_AddonName))
		PostChat(_format(L[" /%s - toggle enable meter"],_addonname))
		PostChat(_format(L[" /%s toggle - toggle enable meter"],_addonname))
		PostChat(_format(L[" /%s on - disable meter"],_addonname))
		PostChat(_format(L[" /%s off - enable meter"],_addonname))
		PostChat(_format(L[" /%s show - show display"],_addonname))
		PostChat(_format(L[" /%s hide - hide display"],_addonname))
		PostChat(_format(L[" /%s config - open or close the options window"],_addonname))
		PostChat(_format(L[" /%s options - open or close the options window"],_addonname))
		PostChat(_format(L[" /%s optionsopen - open the options window"],_addonname))
		PostChat(_format(L[" /%s optionsclose - close the options window"],_addonname))
		PostChat(_format(L[" /%s start - start meter combat"],_addonname))
		PostChat(_format(L[" /%s end - end meter combat"],_addonname))
		PostChat(_format(L[" /%s lock - lock window"],_addonname))
		PostChat(_format(L[" /%s unlock - unlock window"],_addonname))
		PostChat(_format(L[" /%s notice - display the addon update notice"],_addonname))
		PostChat(_format(L[" /%s clear - clear all meter logs (was reset)"],_addonname))
		PostChat(_format(L[" /%s default - reset windows to default positions"],_addonname))
		PostChat(_format(L[" /%s reset - reset to defaults"],_addonname))
		--PostChat(_format(L[" /%s reset [name] - reset to named preset"],_addonname))
		PostChat(_format(L[" /%s help - help message"],_addonname))
	end
end


-----------------------------------------------------------------------------------------------
-- CombatMeter Instance
-----------------------------------------------------------------------------------------------

local CombatMeterInst = CombatMeter:new()
CombatMeterInst:Init()

