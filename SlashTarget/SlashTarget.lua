-----------------------------------------------------------------------------------------------
-- Client Lua Script for SlashTarget
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- SlashTarget Module Definition
-----------------------------------------------------------------------------------------------
local SlashTarget = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function SlashTarget:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	o.unitData = {}

    return o
end

function SlashTarget:Init()
    Apollo.RegisterAddon(self)
end
 

-----------------------------------------------------------------------------------------------
-- SlashTarget OnLoad
-----------------------------------------------------------------------------------------------
function SlashTarget:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    Apollo.RegisterSlashCommand("target", "OnSlashTargetOn", self)
	Apollo.RegisterSlashCommand("tar", "OnSlashTargetOn", self)
	Apollo.RegisterSlashCommand("targetexact", "OnSlashTargetExactOn", self)
	Apollo.RegisterSlashCommand("tarexact", "OnSlashTargetExactOn", self)
	Apollo.RegisterSlashCommand("tarhint", "OnSlashTarHintOn", self)
	Apollo.RegisterSlashCommand("targethint", "OnSlashTarHintOn", self)


	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
end


-----------------------------------------------------------------------------------------------
-- SlashTarget Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function SlashTarget:OnUnitCreated(unit)
	if not unit then return end
	if not unit:IsValid() then self:OnUnitDestroyed(unit); return end
	if unit:GetActivationState() and #(unit:GetActivationState()) > 0 then return end
	
	table.insert(self.unitData, { unit = unit, name = self:PrepareName(unit:GetName()) })
end

function SlashTarget:OnUnitDestroyed(unit)
	if not unit then return end
	for i, u in ipairs(self.unitData) do
		if u.unit == unit then
			table.remove(self.unitData, i)
			break
		end
	end
end

function SlashTarget:PrepareName(s)
	return string.lower(s:find'^%s*$' and '' or s:match'^%s*(.*%S)')
end

function SlashTarget:StartsWith(str, start)
	return string.sub(str, 1, string.len(start)) == start
end

-- on SlashCommand "/targethint"
function SlashTarget:OnSlashTarHintOn(cmd, ...)
	local query = self:PrepareName(table.concat(arg, " "))
	local target = nil
	if string.len(query) > 0 then
		target = self:FindTargetFuzzy(query)
	else
		target = GameLib.GetTargetUnit()
	end
	if target ~= nil then
		target:ShowHintArrow()		
	end
end

-- on SlashCommand "/target"
function SlashTarget:OnSlashTargetOn(cmd, ...)
	local query = self:PrepareName(table.concat(arg, " "))
	self:FindTargetFuzzy(query)
end

function SlashTarget:DistanceToUnit(unit)
	local player = GameLib.GetPlayerUnit()
	if player == nil then return 0 end
	
	local playerPos = player:GetPosition()
	local unitPos = unit:GetPosition()
	local nDeltaX = unitPos.x - playerPos.x
	local nDeltaY = unitPos.y - playerPos.y
	local nDeltaZ = unitPos.z - playerPos.z
	
	return math.sqrt(math.pow(nDeltaX, 2) + math.pow(nDeltaY, 2) + math.pow(nDeltaZ, 2))
end

function SlashTarget:FindTargetFuzzy(query)
	local swUnits = {}
	local fzUnits = {}
	local unit = nil
	for i, u in ipairs(self.unitData) do
		if self:StartsWith(u.name, query) then
			table.insert(swUnits, { unit = u.unit, dist = self:DistanceToUnit(u.unit) })
		end
		if string.find(u.name, query) then
			table.insert(fzUnits, { unit = u.unit, dist = self:DistanceToUnit(u.unit) })
		end
	end
	if #swUnits > 0 then
		table.sort(swUnits, SlashTarget.SortUnitsByDistance)
		unit = swUnits[1].unit
	elseif #fzUnits > 0 then
		table.sort(fzUnits, SlashTarget.SortUnitsByDistance)
		unit = fzUnits[1].unit
	end
	if unit ~= nil then
		GameLib.SetTargetUnit(unit)
	end
	return unit
end

function SlashTarget.SortUnitsByDistance(a, b)
	return a.dist < b.dist
end

-- on SlashCommand "/targetexact"
function SlashTarget:OnSlashTargetExactOn(cmd, ...)
	local query = self:PrepareName(table.concat(arg, " "))
	self:FindTargetExact(query)
end

function SlashTarget:FindTargetExact(query)
	local units = {}
	local unit = nil
	for i, u in ipairs(self.unitData) do
		if u.name == query then
			table.insert(units, { unit = u.unit, dist = self:DistanceToUnit(u.unit) })
		end
	end
	
	if #units > 0 then
		table.sort(units, SlashTarget.SortUnitsByDistance)
		unit = units[1].unit
		GameLib.SetTargetUnit(unit)
	end
	return unit
end
-----------------------------------------------------------------------------------------------
-- SlashTarget Instance
-----------------------------------------------------------------------------------------------
local SlashTargetInst = SlashTarget:new()
SlashTargetInst:Init()
