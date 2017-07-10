-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. Portions (C) Vim,Vince via CC 3.0 VortexMeter.  All rights reserved.
-- Original: Rift Meter by Vince at www.curse.com/addons/rift/rift-meter
-----------------------------------------------------------------------------------------------

local CombatMeter = Apollo.GetAddon("CombatMeter")
if not CombatMeter then return end

local _eDamageType = GameLib.CodeEnumDamageType
local _eCombatResult = GameLib.CodeEnumCombatResult

local _floor = math.floor
local _format = string.format
local _tsort = table.sort
local _tremove = table.remove
local _tconcat = table.concat
local _max = math.max
local _min = math.min

local _print = CombatMeter._print
local print = function(...) CombatMeter.print(...) end


-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local _arUnitStats = {	-- sort mode / unit level stats. maintain order
	"damage",			-- 1
	"heal",				-- 2
	"damageTaken",		-- 3
	"healTaken",		-- 4
	"overheal",			-- 5
	"overkill",			-- 6
	"interrupts",		-- 7
	"deflects",			-- 8
}
local _eUnitStat = { }
for i,k in ipairs(_arUnitStats) do _eUnitStat[k] = i end

local _arUnitFields = {	-- all ability fields. required for a complete clone
	"detail",
	"bLinkedToOwner",	-- flag, maybe split into tUnit and tRUnit schemas, this is only tUnit flag
	--"arPets",			-- ignored, array removed before or ignored by compress
	--"_total",			-- ignored, temp field removed before compress
}
for _,k in ipairs(_arUnitStats) do _arUnitFields[#_arUnitFields + 1] = k end

local _arAbilStats = {	-- ability level stats, simple merge. maintain order
	"swings",			-- 1  running total of cast
	"hits",				-- 2  running total of cast landed
	"total",			-- 3  running value total
	"totalHit",			-- 4  running hit value total
	"crits",			-- 5  running total of crits landed
	"totalCrit",		-- 6  running crit value total
	"multihits",		-- 7  running total of multihits landed
	"totalMultiHit",	-- 8  running multihit value total
	"deflects",			-- 9  running total of casts deflected
	"interrupts",		-- 10 running total of interrupts landed
	"min",				-- 11
	"max",				-- 12
	--"totalReflect",
	--"reflects",
	--"totalGlance",
	--"glances",
}
local _eAbilStat = { }
for i,k in ipairs(_arAbilStats) do _eAbilStat[k] = i end

local _arAbilFields = {	-- all ability fields. required for a complete clone
	"detail",
	"caster",
	"type",
}
for k,_ in ipairs(_arAbilStats) do _arAbilFields[#_arAbilFields + 1] = k end

local _eswings = _eAbilStat.swings
local _ehits = _eAbilStat.hits
local _etotal = _eAbilStat.total
local _etotalHit = _eAbilStat.totalHit
local _ecrits = _eAbilStat.crits
local _etotalCrit = _eAbilStat.totalCrit
local _emultihits = _eAbilStat.multihits
local _etotalMultiHit = _eAbilStat.totalMultiHit
local _edeflects = _eAbilStat.deflects
local _einterrupts = _eAbilStat.interrupts
local _emin = _eAbilStat.min
local _emax = _eAbilStat.max


-----------------------------------------------------------------------------------------------
-- Global Data Functions
-----------------------------------------------------------------------------------------------

CombatMeter._arUnitStats = _arUnitStats

function CombatMeter:NewGlobalUnit(unit, tGOwner, name)
	local o = {}

	o.name = name
	o.bPlayer = unit:IsACharacter()
	o.eClass = unit:GetClassId()

	o.bSelf = unit:IsThePlayer() and true or nil
	--o.bGroup = nil
	o.tGOwner = tGOwner

	--o.tPets = nil
	--o.iPartial

	return o
end

function CombatMeter:NewGlobalAbility(tGCaster, ability, name, bPeriodic)
	local o = {}

	o.name = name
	o.icon = ability:GetIcon()
	o.bPeriodic = bPeriodic and true or nil

	if bPeriodic then
		name = name .. " (Dot)"
	end
	o.dname = name

	return o
end


-----------------------------------------------------------------------------------------------
-- Ability Data Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:AbilityNew(tGCaster, tGAbility, tEventArgs, eStatType)
	local o = {}

	o.detail = tGAbility
	o.caster = tGCaster
	o.type = eStatType == "heal" and _eDamageType.Heal or tonumber(tEventArgs.eDamageType)
	--o[_eAbilStat.max] = nil
	--o[_eAbilStat.min] = nil

	--o[_eAbilStat.swings] = nil
	--o[_eAbilStat.hits] = nil
	--o[_eAbilStat.total] = nil
	--o[_eAbilStat.totalHit] = nil
	--o[_eAbilStat.crits] = nil
	--o[_eAbilStat.totalCrit] = nil
	--o[_eAbilStat.multihits] = nil
	--o[_eAbilStat.totalMultiHit] = nil
	--o[_eAbilStat.deflects] = nil
	--o[_eAbilStat.interrupts] = nil

	return o
end

function CombatMeter:AbilityNewFromAbility(tAbility)
	local o = {}

	o.detail = tAbility.detail
	o.type = tAbility.type
	o.caster = tAbility.tGCaster

	return o
end

local _AbilityTotals_tGCaster = {
}

local _AbilityTotals_tGAbility = {
	name = CombatMeter.L["Total"],
	type = -123,
}

local _AbilityTotals_tEventArgs = {
}

function CombatMeter:AbilityNew_PlayerTotals(tPlayer)
	local o = self:AbilityNew(_AbilityTotals_tGCaster, _AbilityTotals_tGAbility, _AbilityTotals_tEventArgs, nil)

	o._tPlayer = tPlayer
	o._bIsGetPlayerAbilityData = true
	return o
end

function CombatMeter:AbilityClear(tAbility)
	for k,_ in pairs(_arAbilStats) do
		tAbility[k] = nil
	end
end

function CombatMeter:AbilityClone(tAbility)
	local o = {}

	for _,k in pairs(_arAbilFields) do
		o[k] = tAbility[k]
	end

	return o
end

function CombatMeter:AbilityMerge(t, o)
	for k,_ in pairs(_arAbilStats) do
		local n = o[k]
		if n then
			local m = t[k]
			if k == _emin then
				if not m or n < m then
					t[k] = n
				end
			elseif k == _emax then
				if not m or n > m then
					t[k] = n
				end
			else
				t[k] = (m or 0) + n
			end
		end
	end
end

function CombatMeter:AbilityAddStat(o, tEventArgs, eStatType, value)
	local bMultiHit = tEventArgs.bMultiHit

	if not bMultiHit and eStatType ~= "interrupts" then	-- multihits are not the inital swing
		o[_eswings] = (o[_eswings] or 0) + 1					--   and ints are a secondary effect, there will be dmg event coming also
	end

	local bIsCrit = tEventArgs.eCombatResult == _eCombatResult.Critical

	if eStatType == "deflects" then
		if not bMultiHit then							-- dont count deflects or ints off of a multihit for now
			o[_edeflects] = (o[_edeflects] or 0) + (value or 1)
		end
	elseif eStatType == "interrupts" then
		if not bMultiHit then							-- dont count deflects or ints off of a multihit for now
			o[_einterrupts] = (o[_einterrupts] or 0) + (value or 1)
		end
	elseif bMultiHit then
		o[_emultihits] = (o[_emultihits] or 0) + 1
	elseif bIsCrit then
		o[_ecrits] = (o[_ecrits] or 0) + 1
	else
		o[_ehits] = (o[_ehits] or 0) + 1
	end

--_print("------------", eStatType, value)
	if not value then
		return
	end

	o[_etotal] = (o[_etotal] or 0) + value

	if bMultiHit then
		o[_etotalMultiHit] = (o[_etotalMultiHit] or 0) + value
		return
	elseif eStatType == "deflects" or eStatType == "interrupts" then
		return
	elseif bIsCrit then
		o[_etotalCrit] = (o[_etotalCrit] or 0) + value
	else
		o[_etotalHit] = (o[_etotalHit] or 0) + value
	end

	local n,m = o[_emin], o[_emax]
	if not n or value < n then
		o[_emin] = value
	end
	if not m or value > m then
		o[_emax] = value
	end
end

function CombatMeter:AbilityGetAbilityData(tAbility, tPlayer, combat, sort, arData, offset, limit)
	local o,L = self.userSettings, self.L

	local count,max,total = 11, 1, 0						-- 11 lines of stat at the moment

	if tAbility._bIsGetPlayerAbilityData then
		self:AbilityClear(tAbility)							-- can assume its a copy
		self:PlayerMergeAbilityTotal(tAbility._tPlayer, tAbility, sort)
		total = tPlayer[sort] or 0
	else
		tAbility = self:AbilityNewFromAbility(tAbility)		-- might be an ability form the DB
		self:PlayerMergeAbility(tPlayer, tAbility.detail, sort, tAbility)
		total = tAbility.total or 0
	end

	limit = _min(count, limit)

	arData = arData or {}
	offset = offset or 0
	limit = limit or count

	local _arLAbilityStatLabels = CombatMeter._arLAbilityStatLabels
	local f,fdiv,div = self.FormatNumber, self.FormatDivision, self.Division
	local v = tAbility
	local total = v[_etotal] or 0
	local swings = v[_eswings] or 0

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	for i = 1, limit do
		local data = arData[i]
		if not data then
			data = {}
			arData[i] = data
		end

		local j = i + offset
		local value

		if j == 1 then		value = self.BuildFormat(total, total / duration, total / percent)	-- the ifthen is many orders of magnatude faster than the calls
		elseif j == 2 then	value = f(v[_emin]) .. " / " .. fdiv(total, swings) .. " / " .. f(v[_emax])
		elseif j == 3 then	value = fdiv(v[_etotalHit], v[_ehits]) .. " / " .. fdiv(v[_etotalCrit], v[_ecrits])
			.. " / " .. fdiv(v[_etotalMultiHit], v[_emultihits])
		elseif j == 4 then	value = _format("%s (%.2f%%)", f(v[_etotalCrit]), div(v[_etotalCrit], total) * 100)
		elseif j == 5 then	value = _format("%.2f%%", div(v[_ecrits], swings) * 100)
		elseif j == 6 then	value = _format("%s (%.2f%%)", f(v[_etotalMultiHit]), div(v[_etotalMultiHit], total) * 100)
		elseif j == 7 then	value = _format("%.2f%%", div(v[_emultihits], swings) * 100)
		elseif j == 8 then	value = _format("%s (%.2f)", f(swings), div(swings, combat.duration / 1000))
		elseif j == 9 then	value = f(v[_ehits]) .. " / " .. f(v[_ecrits]) .. " / " .. f(v[_emultihits])
		elseif j == 10 then	value = _format("%s (%.2f%%)", f(v[_edeflects]), div(v[_edeflects], swings) * 100)
		elseif j == 11 then	value = f(v[_einterrupts])
		end

		data.name = _arLAbilityStatLabels[j]
		data.value = value
	end

	return arData, count, max, total, limit
end


-----------------------------------------------------------------------------------------------
-- Player Data Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:PlayerNew(tGUnit, bReduced)
	local o = {}

	o.detail = tGUnit
	--o.bLinkedToOwner = nil	-- checks to set for each player added to combat, if the owner is in the combat's list yet
	--o._total = nil			-- temporary sum (with pets) of a particular stat for speeding compares

	if bReduced then
	--	o[esort] = nil			-- tables for abilites organized by sort, _eUnitStat to stat table
	--	{
	--		[1] = nil			-- abilites list for a sort, list of tGAbilites
	--		[name] = nil		-- tGAbility to tAbility of abilities in ability list
	--	}
	--	[sort] = nil,			-- value for reduced player/unit for sort. sort name to stat value
	else
		o.arPets = false		-- list of units this unit owns. must be set, used as a flag to denote non-reduced units
	--	{
	--		[1] = nil,			-- list of tUnit of owned units from same combat
	--	}
	--	[1] = nil				-- unit list of interacting units to the interacted's tGUnit.name
	--	[name] = nil			-- tGUnit.name to tReducedPlayer of units in unit list
	--	[sort] = nil			-- value for player/unit for sort. sort name to stat value
	end

	return o
end

function CombatMeter:PlayerAddStat(tPlayer, tGUnit, tGCaster, tGAbility, tEventArgs, sort, eStatType, value)
	if tPlayer.arPets == nil then				-- reduced player/unit
		local esort = _eUnitStat[sort]
		local stats = tPlayer[esort]
		if not stats then
			stats = {}
			tPlayer[esort] = stats
		end

		local tAbility = stats[tGAbility]

		if not tAbility then
			tAbility = self:AbilityNew(tGCaster, tGAbility, tEventArgs, eStatType)
			stats[tGAbility] = tAbility
			stats[#stats + 1] = tGAbility
		end

		self:AbilityAddStat(tAbility, tEventArgs, eStatType, value)
		return
	end

	local name = tGUnit.name								-- key name combines pets from different owners
	local tRPlayer = tPlayer[name]							-- reduced unit/player affected by the combat action
	if not tRPlayer then
		tRPlayer = self:PlayerNew(tGUnit, true)
		tPlayer[name] = tRPlayer
		tPlayer[#tPlayer + 1] = name
	end

	tPlayer[sort] = (tPlayer[sort] or 0) + (value or 0)		-- ensure get set with 0 to use as a sort flag,
	tRPlayer[sort] = (tRPlayer[sort] or 0) + (value or 0)	--   as an alternate test for which tUnit belongs in sort

	self:PlayerAddStat(tRPlayer, tGUnit, tGCaster, tGAbility, tEventArgs, sort, eStatType, value)
end

function CombatMeter:PlayerGetStat(tPlayer, sort)
	local total = tPlayer[sort] or 0

	local pets = tPlayer.arPets
	if pets then
		for i,tPet in next, pets do
			total = (tPet[sort] or 0) + total
		end
	end

	return total
end

function CombatMeter:PlayerFindAbility(tPlayer, tGAbility, sort)	--FIXME: this needs to also look for matching reduced player to get the same one
	local pets = tPlayer.arPets
	if pets == nil then					-- reduced player/unit
		local esort = _eUnitStat[sort]
		local stats = tPlayer[esort]
		return stats and stats[tGAbility] or nil
	end

	for _,name in ipairs(tPlayer) do
		local v = tPlayer[name]
		local t = self:PlayerFindAbility(v, tGAbility, sort)
		if t then return t end
	end

	if pets then
		for _,v in next, pets do
			local t = self:PlayerFindAbility(v, tGAbility, sort)
			if t then return t end
		end
	end
end

function CombatMeter:PlayerMergeAbilityTotal(tPlayer, tAbility, sort, level)
	local pets = tPlayer.arPets
	if pets == nil then							-- reduced player/unit
		local esort = _eUnitStat[sort]
		local stats = tPlayer[esort]
		if stats then
			for _,tGAbility in ipairs(stats) do
				local v = stats[tGAbility]
				self:AbilityMerge(tAbility, v)
			end
		end
		return
	end

	level = (level or 0) + 1
	if level > 8 then
		return
	end
	for _,name in ipairs(tPlayer) do
		local v = tPlayer[name]
		self:PlayerMergeAbilityTotal(v, tAbility, sort, level)
	end

	if pets then
		for _,v in next, pets do
			self:PlayerMergeAbilityTotal(v, tAbility, sort, level)
		end
	end
end

function CombatMeter:PlayerMergeAbility(tPlayer, tGAbility, sort, t, level)
	local pets = tPlayer.arPets
	if pets == nil then							-- reduced player/unit
		local esort = _eUnitStat[sort]
		local stats = tPlayer[esort]
		if stats then
			local v = stats[tGAbility]
			if v then self:AbilityMerge(t, v) end
		end
		return
	end

	level = (level or 0) + 1
	if level > 8 then
		return
	end
	for _,name in ipairs(tPlayer) do
		local v = tPlayer[name]
		self:PlayerMergeAbility(v, tGAbility, sort, t, level)
	end

	if pets then
		for _,v in next, pets do
			self:PlayerMergeAbility(v, tGAbility, sort, t, level)
		end
	end
end

function CombatMeter:PlayerMergeAbilities(tPlayer, sort, arAbilites, level)
	local pets = tPlayer.arPets
	if pets == nil then							-- reduced player/unit
		local esort = _eUnitStat[sort]
		local stats = tPlayer[esort]

		if stats then
			local count = #arAbilites
			for _,v in ipairs(stats) do
				local tGAbility = v
				v = stats[tGAbility]

				local t = arAbilites[tGAbility]
				if t then
					self:AbilityMerge(t, v)
				else
					t = self:AbilityClone(v)
					arAbilites[tGAbility] = t
					count = count + 1
					arAbilites[count] = t
				end
			end
		end
		return
	end

	level = (level or 0) + 1
	if level > 8 then
		return
	end
	for _,name in ipairs(tPlayer) do
		local v = tPlayer[name]
		self:PlayerMergeAbilities(v, sort, arAbilites, level)
	end

	if pets then
		for _,v in next, pets do
			self:PlayerMergeAbilities(v, sort, arAbilites, level)
		end
	end
end

function CombatMeter:PlayerGetAbilitiesData(tPlayer, sort, arData, offset, limit)
	local abilities = {}
	local count,max,total = 0, 1, 0

	self:PlayerMergeAbilities(tPlayer, sort, abilities)
	count = #abilities
	if count > 0 then
		for i,v in ipairs(abilities) do
			local value = v[_etotal] or 0
			if value > max then
				max = value
			end
			total = total + value
			v._total = value
		end
		_tsort(abilities, function (a, b) return a._total > b._total end)
	end

	count = count + 1								-- +1 for total
	limit = _min(count, limit)

	arData = arData or {}
	offset = offset or 0
	limit = limit or count

	offset = offset - 1								-- -1 for total
	local bTotals = offset < 0 or nil

	for i = 1, limit do
		local data = arData[i]
		if not data then
			data = {}
			arData[i] = data
		end

		local b = i == 1 and bTotals or nil			-- fake ability for totals
		local v,name,value

		if b then
			value = max
		else
			v = abilities[i + offset]
			name = v.detail.dname
			if v.caster.tGOwner then
				name = name .. " (Pet: " .. v.caster.name .. ")"
			end
			value = v._total
		end

		data.bTotals = b
		data.name = name
		data.value = value
		data.ref = v
	end

	return arData, count, max, total, limit
end

function CombatMeter:PlayerGetInteractionsData(tPlayer, sort, arData, offset, limit)
	local interactions = {}
	local count,max,total = 0, 1, 0

	for _,name in ipairs(tPlayer) do
		local v = tPlayer[name]
		local value = v[sort]
		if value then
			count = count + 1
			interactions[count] = v
			v._total = value
			total = total + value
		end
	end
	if count > 1 then
		_tsort(interactions, function (a, b) return (a._total or 0) > (b._total or 0) end)
	end
	if count > 0 then
		max = _max(interactions[1]._total, 1)
	end

	limit = _min(count, limit)

	arData = arData or {}
	offset = offset or 0
	limit = limit or count

	for i = 1, limit do
		local data = arData[i]
		if not data then
			data = {}
			arData[i] = data
		end

		local v = interactions[i + offset]

		local value = v._total or 0

		data.name = v.detail.name
		data.value = value
		data.ref = v
	end

	return arData, count, max, total, limit
end

function CombatMeter:PlayerGetTooltipText(tPlayer, sort)
	local o,L,div = self.userSettings, self.L, self.Division

	local stat = self:PlayerGetStat(tPlayer, sort)

	local abilities = {}

	self:PlayerMergeAbilities(tPlayer, sort, abilities)
	_tsort(abilities, function (a, b) return (a[_etotal] or 0) > (b[_etotal] or 0) end)

	local players = {}
	local count = 0

	if tPlayer.arPets ~= nil then
		for _,name in ipairs(tPlayer) do
			local v = tPlayer[name]
			local value = v[sort]
			if value then
				count = count + 1
				players[count] = v
				v._total = value
			end
		end
		_tsort(players, function(a, b) return (a._total or 0) > (b._total or 0) end)
	end

	local s = "<P TextColor=\"FFFFD100\">" .. L["Top 3 Abilities:"] .. "</P>\n"
	for i = 1, 3 do
		local v = abilities[i]
		if v then
			s = s .. _format("   (%d%%) %s\n", div(v[_etotal], stat) * 100, (v.name or v.detail.name):sub(0, 16))
		end
	end

	s = s .. "<P TextColor=\"FFFFD100\">" .. L["Top 3 Interactions:"] .. "</P>\n"
	for i = 1, 3 do
		local v = players[i]
		if v then
			s = s .. _format("   (%d%%) %s\n", div(v._total, stat) * 100, v.detail.name:sub(0, 16))
		end
	end

	return s  .. "<P TextColor=\"FF33FF33\">&lt;" .. L["Middle-Click for interactions"] .. "&gt;</P>"
end


-----------------------------------------------------------------------------------------------
-- Combat Data Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:CombatNew(bTotals, nNow)
	local o = {}

	o.bTotals = bTotals and true or nil		-- permanent fake combat for totals

	o.name = bTotals and self.L["Total"] or self.bInPvP and self.sWorldName or nil
	o.sWorldName = not bTotals and self.sWorldName or nil
	o.sInstanceName = not bTotals and self.sInstanceName or nil
	--o.bBoss = nil

	o.startTime = nNow
	o.duration = 0
	o.previousDuration = 0

	--o[1] = nil							-- unit list of combat participant to tGUnits
	--o[tGUnit] = nil						-- tGUnit to tPlayer of units in unit list

	--o._i = nil							-- temporary index hint for some ui row types
	--o._total = nil						-- temporary sum of a particular stat for speeding compares

	--o.bArchive = nil						-- archived state with summary values for display
	--o.bCompress = nil						-- all compressed state, reguarless of other states
	--o.bSaveCompress = nil					-- compressed only for save. uncompress on restore
	--o.bPartial = nil						-- only some units are compressed. tGUnit.iPartial is index to compresed tUnit

	return o
end

function CombatMeter:CombatSetStop(tCombat, bDurationIsCallTime, nNow)
	local nDuration = nNow - tCombat.startTime

	if not bDurationIsCallTime then
		nDuration = nDuration - (nNow - self.nLastDamageAction)
	end

	tCombat.duration = nDuration
end

function CombatMeter:CombatGetPlayer(combat, tGUnit)
	if combat.bPartial and tGUnit.iPartial then
		self:CombatUncompressPartial(combat, tGUnit.tGOwner or tGUnit)
	end

	tUnit = combat[tGUnit]
	if not tUnit then
		tUnit = self:PlayerNew(tGUnit)
		combat[tGUnit] = tUnit
		combat[#combat + 1] = tGUnit
	end

	local tGOwner = tGUnit.tGOwner
	local tOwner = tGOwner and combat[tGOwner]
	if tOwner and not tUnit.bLinkedToOwner then
		tUnit.bLinkedToOwner = true

		local pets = tOwner.arPets
		if not pets then
			pets = {}
			tOwner.arPets = pets
		end
		pets[#pets + 1] = tUnit
	end

	return tUnit
end

function CombatMeter:CombatGetCombatsData(combat, sort, bShowEnemies, bLast, arData, offset, limit)
	local o,combats = self.userSettings, self.arCombats

	local count,max,total = 0, 0, 0				-- 11 lines of stat at the moment

	local tCombatCurrent,tCombatOverall = self.tCombatCurrent, self.tCombatOverall
	if o.bShowOnlyBoss then
		local t = combats
		combats = {}
		for _,v in next, t do
			if v.bBoss or v == tCombatCurrent or v == tCombatOverall then
				count = count + 1
				combats[count] = v
			end
		end
	else
		count = #combats
	end
	if count > 0 then
		local nChanges,sInstanceName = -1, ""
		for _,v in next, combats do
			local n = self:CombatGetPlayersTotal(v, sort, bShowEnemies)
			local value = n / _max(v.duration / 1000, 1)
			v._total = value

			if v ~= tCombatOverall and sInstanceName ~= v.sInstanceName then
				nChanges = nChanges + 1
				sInstanceName = v.sInstanceName
			end
			v._i = nChanges

			if value > max then
				max = value
			end
			total = total + value
		end
	end

	limit = _min(count, limit)

	arData = arData or {}
	offset = bLast and _max(count - limit, 0) or offset or 0			-- adjust scroll to last, needs real count from above first
	offset = (offset + limit) <= count and offset or (count - limit)	-- clip scroll if puts limit past end, number of items were reduced
	limit = limit or count

	for i = 1, limit do
		local data = arData[i]

		local b = i == 1
		local j = b and 1 or (i + offset)
		local v = combats[j]

		data.bTotals = b
		data.i = v._i
		data.name = CombatMeter:CombatGetName(v) or ""
		data.value = v._total

		data.ref = v
	end

	return arData, count, max, total, limit, offset
end

function CombatMeter:CombatGetTooltipText(combat)
	local o,L,div = self.userSettings, self.L, self.Division

	local sInstanceName = combat.sInstanceName
	local sWorldName = combat.sWorldName

	local s = ""

	if sInstanceName and combat.name ~= sInstanceName then
		s = s .. sInstanceName
	end
	if sWorldName and sWorldName ~= sInstanceName and sWorldName ~= combat.name then
		s = s .. (s ~= "" and "\n" or "") .. sWorldName
	end

	return s
end

function CombatMeter:CombatGetPlayersTotal(combat, sort, bShowNpcs)
	local total = 0

	if combat.bArchive or combat.bPartial then
		local t = not bShowNpcs and combat or combat.mobs
		total = t and t[sort] or 0
	end

	if not combat.bArchive then
		bShowNpcs = bShowNpcs and true or false
		for _,detail in ipairs(combat) do
			if not detail.iPartial and not detail.tGOwner and (bShowNpcs == not detail.bPlayer) then
				local v = combat[detail]
				if v then										--FIXME: not supposed to be missing v with iPartial
					local value = self:PlayerGetStat(v, sort)
					total = total + value
				end
			end
		end
	end

	return total
end

function CombatMeter:CombatGetPlayersTotals(combat, sort)
	local total,mtotal = 0, 0

	for _,detail in ipairs(combat) do
		if not detail.tGOwner then
			local v = combat[detail]
			local value = self:PlayerGetStat(v, sort)

			if detail.bPlayer then
				total = total + value
			else
				mtotal = mtotal + value
			end
		end
	end

	return total, mtotal
end

function CombatMeter:CombatGetPlayerTotal(combat, detail, sort)
	local total = 0

	if not detail.tGOwner then
		local v = combat[detail]
		total = self:PlayerGetStat(v, sort)
	end

	return total
end

function CombatMeter:CombatGetPlayersData(combat, sort, bShowNpcs, bShowSelf, arData, offset, limit)
	bShowNpcs = bShowNpcs and true or false

	local players = {}
	local count,total,max = 0, 0, 0

	for _,detail in ipairs(combat) do
		if not detail.tGOwner and (bShowNpcs == not detail.bPlayer) then
			local v = combat[detail]
			local value = self:PlayerGetStat(v, sort)

			if value > 0 then
				count = count + 1
				players[count] = v
				v._total = value

				total = total + value
			end
		end
	end
	if count > 1 then								-- players and pets > other units + sort by stat desc
		_tsort(players, function (a, b) return a._total > b._total end)
	end
	if count > 0 then
		max = players[1]._total						-- max is the original top value
	end

	arData = arData or {}
	offset = offset or 0
	limit = limit or count

	local bSelf = bShowSelf
	limit = _min(count, limit)

	for i = 1, limit do
		local data = arData[i]
		if not data then
			data = {}
			arData[i] = data
		end

		local j = i + offset
		local v = players[j]

		if bSelf and v.detail.bSelf then
			bSelf = nil
		end
		if bSelf and i == limit then
			for n = j + 1, #players do
				local v2 = players[n]
				if v2.detail.bSelf then
					j,v = n,v2
					break
				end
			end
		end

		data.i = j
		data.value = v._total 						-- value plus pets
		data.ref = v
	end

	--total = _max(total, 1)
	return arData, count, max, total, limit
end

function CombatMeter:CombatGetName(combat)
	if combat.name or combat.bPartial then
		return combat.name
	end

	local b
	for _,detail in ipairs(combat) do		-- get top damage-taken other units, or players if none, or pets
		local a = combat[detail]
		b = b or a

		local d1, d2 = a.detail, b.detail

		local n = d1.tGOwner and 1 or d1.bPlayer and 2 or 3
		local m = d2.tGOwner and 1 or d2.bPlayer and 2 or 3

		local da,db = a.damageTaken, b.damageTaken

		if n > m or (n == m and (da or 0) > (db or 0)) then
			b = a
		end
	end

	return b and b.detail.name or nil
end

function CombatMeter:CombatRemovePartial(combat)			-- only units not represented in other combats
	combat.mobs = combat.mobs or {}
	local units,combats = self.arGUnits, self.arCombats
	local tUnitKeys = self:CombatEnsureCompress()

	local tUnits,arGUnits,arIndex,tUnit = {}, {}, {}, {}	-- build removal candidate list
	for i,tGUnit in ipairs(combat) do						--   get non-arPets tGUnits held by combat, without uncompressing anything
		arIndex[i] = i
		if combat[tGUnit] then
			arGUnits[tGUnit] = i
			local tGOwner = tGUnit.tGOwner					-- uncompressed units will have uncompressed pets
			if not tGOwner or not combat[tGOwner] then		-- not pet or orphan (owner never had a siginificant cast or action)
				tUnits[tGUnit] = i							-- uncompressed tGUnit to tUnit combat indexes
			end
		end 
	end
	for i,tGUnit in ipairs(units) do
		local iPartial = tGUnit.iPartial
		if iPartial then
			arGUnits[tGUnit] = iPartial
			local tGOwner = tGUnit.tGOwner					-- compressed pets will have compressed owners
			if not tGOwner or not combat[tGOwner.iPartial] then	-- not pet or orphan
				tUnits[tGUnit] = iPartial					-- compressed tGUnit to tUnit combat indexes
			end
		end 
	end

	for i,v in ipairs(combats) do							-- cull candiates that exist in other combats
		if v ~= combat then
			for i2,tGUnit in ipairs(v) do
				if not v[tGUnit] then						-- is compressed, must uncompress to know which tGUnit this refers to 
					local v2 = tGUnit
					self:UncompressRow(tUnit, v2[0], tUnitKeys, true)
					tGUnit = units[tUnit.detail]
				end
				if tUnits[tGUnit] then
					tUnits[tGUnit] = nil
				end
			end
		end
	end

	local count,tUnitsR = 0, {}
	for tGUnit,i in next, tUnits do							-- combat indexes of tGUnits to be removed from combat
		count = count + 1
		tUnitsR[i] = tGUnit
	end
	for tGUnit,i in next, arGUnits do						-- add pets
		if tUnits[tGUnit.tGOwner] then
			count = count + 1
			tUnitsR[i] = tGUnit
		end
	end
	if count == 0 then
		return
	end

	for i = #combat,1,-1 do
		local tGUnit = tUnitsR[i]
		if tGUnit then
			if tGUnit.iPartial then
				local v = combat[i]
				self:UncompressRow(tUnit, v[0], tUnitKeys, true)
	
				local list = tGUnit.bPlayer and combat or combat.mobs
				for _,sort in next, _arUnitStats do
					local n = tUnit[sort]
					if n and n ~= 0 then list[sort] = (list[sort] or 0) - n end
				end
				tGUnit.iPartial = nil
			end

			if combat[tGUnit] then
				combat[tGUnit] = nil
			end

			_tremove(combat, i)
			_tremove(arIndex, i)
print("remove","partial", tGUnit.name)														--PROF:
		end
	end

	local tIndex = {}										-- fix indexes
	for i,v in ipairs(arIndex) do
		tIndex[v] = i
	end
	for k,v in ipairs(units) do
		local i = v.iPartial
		if i and tIndex[i] then
			v.iPartial = tIndex[i]
		end		
	end
end

-----------------------------------------------------------------------------------------------
-- Data Format Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:CombatEnsureCompress()
	local tUnitKeys, tAbilKeys = self.tUnitKeys, self.tAbilKeys

	if not tUnitKeys or not tAbilKeys then
		self:EnsureCompress()

		local nUnitSchema, nAbilSchema
		nAbilSchema, tAbilKeys = self:EnsureSchema(_arAbilFields)
		nUnitSchema, tUnitKeys = self:EnsureSchema(_arUnitFields)
		self.nUnitSchema, self.nAbilSchema = nUnitSchema, nAbilSchema
		self.tUnitKeys, self.tAbilKeys = tUnitKeys, tAbilKeys
	end

	return tUnitKeys, tAbilKeys
end

function CombatMeter:CombatArchive(combat)
	combat.name = self:CombatGetName(combat)						-- make name permanent

	if not combat.bArchive then
		local mobs = {}; combat.mobs = mobs							-- clear unconditionally, may be dirty from partial

		for _,sort in next, _arUnitStats do
			local n,m = self:CombatGetPlayersTotals(combat, sort)
			if n ~= 0 then combat[sort] = n end
			if m ~= 0 then mobs[sort] = m end
		end
		combat.bArchive = true
print("archive", combat.name)														--PROF:
	end

	self:CombatCompress(combat, self:CombatEnsureCompress())
end

----------------------------------------------------------------

function CombatMeter:CombatArchivePartial(combat, scombat)
	combat.bPartial = true
	combat.mobs = combat.mobs or {}

	local tUnitKeys, tAbilKeys = self:CombatEnsureCompress()
	local tPets = {}

	for i,tGUnit in ipairs(combat) do
		local v = combat[tGUnit]
		if v and not tGUnit.tGOwner and not scombat[tGUnit] then		-- never compress pets in a partial

			local pets = v.arPets
			if pets then
				for _,v2 in next, pets do
					local tGUnit2 = v2.detail
					tPets[tGUnit2] = true
				end
			end

			self:CombatCompressPartial(combat, i, tGUnit, tUnitKeys, tAbilKeys)
		end
	end

	for i,tGUnit in ipairs(combat) do
		if tPets[tGUnit] then
print("archive","partial", "pet", tGUnit.name)														--PROF:
			self:CombatCompressUnit(combat, i, tUnitKeys, tAbilKeys)
			tGUnit.iPartial = i
		end
	end

	combat.bCompress = true
end

function CombatMeter:CombatCompressPartial(combat, i, tGUnit, tUnitKeys, tAbilKeys)
	if not tGUnit.iPartial then
		local list = tGUnit.bPlayer and combat or combat.mobs
		for _,sort in next, _arUnitStats do
			local n = self:CombatGetPlayerTotal(combat, tGUnit, sort)
			if n ~= 0 then list[sort] = (list[sort] or 0) + n end
		end
	end

	self:CombatCompressUnit(combat, i, tUnitKeys, tAbilKeys)			--   pets can only have one owner
	tGUnit.iPartial = i													-- compress unit and all of its pets
print("archive","partial", tGUnit.name)														--PROF:
end

function CombatMeter:CombatUnarchivePartial(combat, tUnitKeys, tAbilKeys)
	if not tUnitKeys then
		tUnitKeys, tAbilKeys = self:CombatEnsureCompress()
	end

	local tComp = {}
	for _,tGUnit in ipairs(self.arGUnits) do
		if tGUnit.iPartial then
			tComp[tGUnit.iPartial] = true
		end
	end

	for i = 1,#combat do
		local v = combat[i]
		if not tComp[i] and not combat[v] and not v.arPets then
			self:CombatUncompressUnit(combat, i, tUnitKeys, tAbilKeys)
		end
	end
	for i = 1,#combat do
		local v = combat[i]
		if not tComp[i] and not combat[v] then
			self:CombatUncompressUnit(combat, i, tUnitKeys, tAbilKeys)
		end
	end
end

function CombatMeter:CombatUncompressPartial(combat, tGUnit, tUnitKeys, tAbilKeys)
	if not tUnitKeys then
		tUnitKeys, tAbilKeys = self:CombatEnsureCompress()
	end

	local i = tGUnit.iPartial
print("unarchive","partial", tGUnit.name)																--PROF:

	local v = combat[i]
	local pets = v.arPets
	if pets then
		local units = self.arGUnits
		for _,i2 in ipairs(pets) do
			local tGUnit2 = units[i2]
print("unarchive","partial", "pet", tGUnit2.name)														--PROF:
			i2 = tGUnit2.iPartial
			self:CombatUncompressUnit(combat, i2, tUnitKeys, tAbilKeys)
			tGUnit2.iPartial = nil
		end
	end

	self:CombatUncompressUnit(combat, i, tUnitKeys, tAbilKeys)

	local list = tGUnit.bPlayer and combat or combat.mobs
	for _,sort in next, _arUnitStats do
		local n = self:CombatGetPlayerTotal(combat, tGUnit, sort)
		if n ~= 0 then list[sort] = (list[sort] or 0) - n end
	end
	tGUnit.iPartial = nil
end

----------------------------------------------------------------

function CombatMeter:_CombatCompressUnit(tUnit, t, tUnitKeys, tAbilKeys)
	local units,abils = self.arGUnits, self.arGAbilities

	local pets = tUnit.arPets
	if pets then
		for i2,v2 in ipairs(pets) do
			pets[i2] = units[v2.detail]								-- set pet tUnit to tGUnit id
		end
	end

	local v = tUnit
	v.detail = units[v.detail]										-- set tGUnit to tGUnit id
	t[0] = self:CompressRow(v, tUnitKeys)							-- compress values
	if pets then t.arPets = pets end								-- keep pets table

	for i2,name in ipairs(v) do
		local v2,t2 = v[name], {}									-- tRUnit
		v2.detail = units[v2.detail]								-- set tGUnit to tGUnit id
		t2[0] = self:CompressRow(v2, tUnitKeys)
		t[i2] = t2													-- tRUnit value to tUnit index

		for esort,_ in next, _arUnitStats do
			local stats = v2[esort]									-- ability bucket for sort
			v2[esort] = nil											-- for GC
			if stats then
				for i3,tGAbility in ipairs(stats) do
					local v3 = stats[tGAbility]						-- tAbility
					v3.detail = abils[v3.detail]					-- set tGAbility to tGAbility id
					v3.caster = units[v3.caster]					-- set tGUnit to tGUnit id
					v3 = self:CompressRowInline(v3, tAbilKeys)
					stats[i3] = v3									-- value to index
				end
				stats = _tconcat(stats, " ")
				t2[esort] = stats
			end
		end
	end
end

function CombatMeter:CombatCompressUnit(combat, i, tUnitKeys, tAbilKeys)
	local tGUnit = combat[i]
	local v,t = combat[tGUnit], {}									-- tUnit

	self:_CombatCompressUnit(v, t, tUnitKeys, tAbilKeys)
	combat[tGUnit] = nil											-- remove unit lookup
	combat[i] = t													-- tUnit value to combat index
end

function CombatMeter:CombatCompressUnits(combat, tUnitKeys, tAbilKeys, bPets)
	for i,tGUnit in ipairs(combat) do
		local v = combat[tGUnit]									-- only finds uncompressed units
		if v and (not tGUnit.tGOwner or bPets) then					-- skip pets by default
			local t = {}											-- tUnit

			self:_CombatCompressUnit(v, t, tUnitKeys, tAbilKeys)
			combat[tGUnit] = nil									-- remove unit lookup
			combat[i] = t											-- tUnit value to combat index
		end
	end
end

function CombatMeter:CombatCompress(combat, tUnitKeys, tAbilKeys)
	print("compress", combat.name)														--PROF:

	if combat._i then combat._i = nil end							-- remove temp field
	if combat._total then combat._total = nil end					-- remove temp field

	self:CombatCompressUnits(combat, tUnitKeys, tAbilKeys)			-- allow with arPets to roll first
	self:CombatCompressUnits(combat, tUnitKeys, tAbilKeys, true)

	combat.bCompress = true
end

------------------------------------------------------------------------------------------

function CombatMeter:_CombatUncompressUnit(combat, tUnit, tUnitKeys, tAbilKeys)
	local units,abils = self.arGUnits, self.arGAbilities

	local v = tUnit
	self:UncompressRow(v, v[0], tUnitKeys)
	v[0] = nil
	if not v.arPets then v.arPets = false end
	local tGUnit = units[v.detail]
	v.detail = tGUnit												-- set tGUnit id to tGUnit

	for i2 = 1, #v do
		local v2 = v[i2]
		self:UncompressRow(v2, v2[0], tUnitKeys)
		v2[0] = nil
		local tRGUnit = units[v2.detail]
		v2.detail = tRGUnit											-- set tGUnit id to tGUnit
		local name = tRGUnit.name
		v[i2] = name												-- name to index
		v[name] = v2												-- value lookup to name

		for esort = 1, #_arUnitStats do
			local stats = v2[esort]
			if stats then
				local stats2,i3 = {}, 0
				for v3 in (stats.." "):gmatch("([^ ]*) ") do
					i3 = i3 + 1
					v3 = self:UncompressRowInline({}, v3, tAbilKeys)
					v3.detail = abils[v3.detail]
					v3.caster = units[v3.caster]
					stats2[v3.detail] = v3
					stats2[i3] = v3.detail
				end
				v2[esort] = stats2
			end
		end
	end

	v = tUnit
	v = v.arPets
	if v then
		for i2,v2 in next, v do
			v[i2] = combat[units[v2]]								-- tGUnit id to tGUnit to combat tUnit
		end
	end
end

function CombatMeter:CombatUncompressUnit(combat, i, tUnitKeys, tAbilKeys)
	local v = combat[i]

	if not combat[v] then
		self:_CombatUncompressUnit(combat, v, tUnitKeys, tAbilKeys)

		local tGUnit = v.detail
		combat[i] = tGUnit											-- tGUnit to index
		combat[tGUnit] = v											-- value lookup to tGUnit
	end
end

function CombatMeter:CombatUncompressUnits(combat, tUnitKeys, tAbilKeys, bPets)
	for i = 1, #combat do
		local v = combat[i]											-- tUnit

		if not combat[v] and (not v.arPets or bPets) then			-- skip pet owners by default
			self:_CombatUncompressUnit(combat, v, tUnitKeys, tAbilKeys)

			local tGUnit = v.detail
			combat[i] = tGUnit										-- tGUnit to index
			combat[tGUnit] = v										-- value lookup to tGUnit
		end
	end
end

function CombatMeter:CombatUncompress(combat, tUnitKeys, tAbilKeys)
	print("uncompress", combat.name)														--PROF:
	if not tUnitKeys or not tAbilKeys then
		tUnitKeys, tAbilKeys = self:CombatEnsureCompress()
	end

	self:CombatUncompressUnits(combat, tUnitKeys, tAbilKeys)		-- allow without arPets to roll first
	self:CombatUncompressUnits(combat, tUnitKeys, tAbilKeys, true)

	combat.bCompress = nil
end
