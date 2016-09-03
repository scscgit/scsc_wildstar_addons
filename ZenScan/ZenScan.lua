-----------------------------------------------------------------------------------------------
-- Client Lua Script for ZenScan
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ZenScan Module Definition
-----------------------------------------------------------------------------------------------
local ZenScan = {} 

-----------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------- 
local cSlashCommand = "zs"
local cAddonName = "ZenScan"
local cHasConfigurationButton = true
local cDeleteXml = true

local cXmlFileName = "ZenScan.xml"
local cCfgWndClass = "ZenScanConfigForm"

-----------------------------------------------------------------------------------------------
-- Settings
-----------------------------------------------------------------------------------------------
local cMaxScanDistance = "MaxScanDistance"
local cSecondsBeforeRescan = "SecondsBeforeRescan"
local cAllowAutoScanSetting = "AllowAutoScan"
local cAllowTargetScanSetting = "AllowTargetScan"

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ZenScan:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function ZenScan:Init()
	local tDependencies = {	}
    Apollo.RegisterAddon(self, cHasConfigurationButton, cAddonName, tDependencies)
	
	self.Settings = {}
	self.Settings[cMaxScanDistance] = 35
	self.Settings[cSecondsBeforeRescan] = 5
	self.Settings[cAllowAutoScanSetting] = true
	self.Settings[cAllowTargetScanSetting] = true
	
	self.aAllUnits = {}
	self.aPassiveScan = {}
	self.aDeadScan = {}
	
	self.secondsSinceLastRescan = 0;
end

function ZenScan:OnLoad()
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
	Apollo.RegisterEventHandler("TargetUnitChanged", "OnTargetUnitChanged", self)
	
	-- the rest
	self.xmlDoc = XmlDoc.CreateFromFile(cXmlFileName)
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function ZenScan:OnDocumentReady()
	self.wndConfig = Apollo.LoadForm(self.xmlDoc, cCfgWndClass, nil, self)
	self.wndConfigTxtMaxScanDistance = self.wndConfig:FindChild("TxtMaxScanDistance")
	self.wndConfigTxtSecondsBeforeRescan = self.wndConfig:FindChild("TxtSecondBeforeRescan")
	
	if(cDeleteXml == true) then
		self.xmlDoc = nil
	end
	
	self.wndConfig:Show(false, true)
	
	Apollo.RegisterTimerHandler("OneSecTimer", "OnUpdate", self)

	if (cHasConfigurationButton == true) then
		Apollo.RegisterSlashCommand(cSlashCommand , "OnConfigure", self)
	end
end

-----------------------------------------------------------------------------------------------
-- Configuration
-----------------------------------------------------------------------------------------------
function ZenScan:OnConfigure()
	self.wndConfig:Show(true, true)
end 

-----------------------------------------------------------------------------------------------
-- Data
-----------------------------------------------------------------------------------------------
function ZenScan:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then 
		return 
	end
	
	return self.Settings
end

function ZenScan:OnRestore(eType, data)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then 
		return 
	end
	
	for property,tData in pairs(data) do
		self.Settings[property] = data[property]
	end
	
	
	self.LoadSettingNeeded = true
end


function ZenScan:LoadSettings()
	self:MatchConfigUiWithSettings()
	self.LoadSettingNeeded = nil
end

-----------------------------------------------------------------------------------------------
-- Functions
-----------------------------------------------------------------------------------------------
function ZenScan:TableLength(theTable)
	local length = 0;
	if(theTable ~= nil) then
		for key, value in pairs(theTable) do
			length = length + 1
		end
	end
	return length
end

function ZenScan:IsInValidState()
	local player = GameLib.GetPlayerUnit()
	return (self.player ~= nil 
		and self.player:IsValid() == true
		and self.wndConfig ~= nil)
end

function ZenScan:MatchConfigUiWithSettings()
	self.wndConfigTxtMaxScanDistance:SetText(self.Settings[cMaxScanDistance])
	self.wndConfigTxtSecondsBeforeRescan:SetText(self.Settings[cSecondsBeforeRescan])
	self.wndConfig:FindChild("ChAllowAutoScan"):SetCheck(self.Settings[cAllowAutoScanSetting])
	self.wndConfig:FindChild("ChAllowTargetScan"):SetCheck(self.Settings[cAllowTargetScanSetting])
end

function ZenScan:DistanceToUnit(unit)
	local posPlayer = self.player:GetPosition()
	local posTarget = unit:GetPosition()
	local nDeltaX = posTarget.x - posPlayer.x
	local nDeltaY = posTarget.y - posPlayer.y
	local nDeltaZ = posTarget.z - posPlayer.z
	
	return math.sqrt(math.pow(nDeltaX, 2) + math.pow(nDeltaY, 2) + math.pow(nDeltaZ, 2))
end 

function ZenScan:Scan(unit)
	if(unit ~= nil) then
		local oldTarget = GameLib.GetTargetUnit()
		if(oldTarget ~= unit) then
			GameLib.SetTargetUnit(unit)
			PlayerPathLib.PathAction()
			GameLib.SetTargetUnit(oldTarget)
		else
			PlayerPathLib.PathAction()
		end
	end
	
	self.ScanTarget = unit
	self.secondsSinceLastRescan = 0
end

function ZenScan:UnitRewardful(unit)
	local tUnitRewardInfo = unit:GetRewardInfo()
	local tActivation = unit:GetActivationState()
	if(tUnitRewardInfo ~= nil
		and tActivation ~= nil
		and tActivation.ScientistScannable ~= nil) then
		local nRewardInfoListCount = self:TableLength(tUnitRewardInfo)
		for idx = 1, nRewardInfoListCount do
			if (tUnitRewardInfo[idx].pmMission ~= nil) then
				return true
			end
		end
	end
	
	return false
end
-----------------------------------------------------------------------------------------------
-- Events
-----------------------------------------------------------------------------------------------
function ZenScan:OnUpdate()
	--SEDU - stability during zone changes
	self.previousPlayer = self.player
	self.player = GameLib.GetPlayerUnit()
	if (self:IsInValidState() == false) then
		self.player = nil
	elseif (self.previousPlayer ~= self.player) then
	end
	if(self:IsInValidState() == true) then
		if(self.LoadSettingNeeded == true) then
			self:LoadSettings()
		end
		
		if(PlayerPathLib.ScientistHasScanBot() == true) then
			local currentTarget = GameLib.GetTargetUnit()
			local targetActivation = nil
			local targetDisposition = nil
			if(currentTarget ~= nil) then
				targetActivation = currentTarget:GetActivationState()
				targetDisposition = currentTarget:GetDispositionTo(self.player)
			end
			if(self.Settings[cAllowTargetScanSetting] == true
				and currentTarget ~= nil
				and currentTarget ~= self.ScanTarget
				and targetActivation ~= nil
				and (targetActivation.ScientistRawScannable ~= nil
					or targetActivation.ScientistScannable ~= nil)
				and self:DistanceToUnit(currentTarget) <= self.Settings[cMaxScanDistance]
				and (currentTarget:IsDead() == true
					or currentTarget:IsInCombat() == true
					or (targetDisposition ~= 0
						and targetDisposition ~= 1))) then
				self:Scan(currentTarget)
			elseif (self.Settings[cAllowAutoScanSetting] == true
				and (self.ScanTarget == nil 
				or self:UnitRewardful(self.ScanTarget) == false
				or  self:DistanceToUnit(self.ScanTarget) > self.Settings[cMaxScanDistance])) then
				self.ScanTarget = nil 
				if(self:TableLength(self.aDeadScan) > 0) then
					allDistances = {}
					unitsByDistance = {}
					for _, unit in pairs(self.aDeadScan) do
						if(self:UnitRewardful(unit) == true) then
							distance = self:DistanceToUnit(unit)				
							if(unit:IsDead() == true
								and distance <= self.Settings[cMaxScanDistance]) then
								table.insert(allDistances, distance)
								unitsByDistance[distance] = unit
							end
						else
							self:OnUnitDestroyed(unit)
						end
					end
					table.sort(allDistances)
					
					if(self:TableLength(unitsByDistance) > 0) then
						self:Scan(unitsByDistance[allDistances[1]])
						return
					end
				end
				
				if(self:TableLength(self.aPassiveScan) > 0) then
					allDistances = {}
					unitsByDistance = {}
					for _, unit in pairs(self.aPassiveScan) do
						if(self:UnitRewardful(unit) == true) then
							distance = self:DistanceToUnit(unit)				
							if(distance <= self.Settings[cMaxScanDistance]) then
								table.insert(allDistances, distance)
								unitsByDistance[distance] = unit
							end
						else
							self:OnUnitDestroyed(unit)
						end
					end
					table.sort(allDistances)
					
					if(self:TableLength(unitsByDistance) > 0) then
						self:Scan(unitsByDistance[allDistances[1]])
						return
					end
				end
			elseif(self.ScanTarget ~= nil) then
				if(self.secondsSinceLastRescan > self.Settings[cSecondsBeforeRescan]) then
					self:Scan(self.ScanTarget)
				else
					self.secondsSinceLastRescan = self.secondsSinceLastRescan + 1
				end
			end
		end
	end
end

function ZenScan:OnUnitCreated(unit)
	local unitId = unit:GetId()
	self.aAllUnits[unitId] = unit
	if(self:IsInValidState() == true) then
		local eDisposition = unit:GetDispositionTo(self.player)
		if(eDisposition ~= 0 -- 0 is neutral, 1 is hostile, 2 is friendlt
			and eDisposition ~= 1) then
			self.aPassiveScan[unitId] = unit
		else
			self.aDeadScan[unitId] = unit
		end
	end
end

function ZenScan:OnUnitDestroyed(unit)
	local unitId = unit:GetId();
	self.aAllUnits[unitId] = nil
	self.aPassiveScan[unitId] = nil
	self.aDeadScan[unitId] = nil
	
	if(self.ScanTarget == unit ) then
		self.ScanTarget = nil
	end
end

function ZenScan:OnCombatLogDamage(tEventArgs)
	local unit = tEventArgs.unitTarget
	if(self.ScanTarget == nil
		and unit ~= nil
		and self:UnitRewardful(unit) == true) then
		self:Scan(unit)
	end
end

function ZenScan:OnTargetUnitChanged(unit)
	if(PlayerPathLib.ScientistHasScanBot() == true) then
		local targetActivation = nil
		local targetDisposition = nil
		if(unit ~= nil) then
			targetActivation = unit:GetActivationState()
			targetDisposition = unit:GetDispositionTo(self.player)
			if(self.Settings[cAllowTargetScanSetting] == true
				and unit ~= nil
				and unit ~= self.ScanTarget
				and targetActivation ~= nil
				and (targetActivation.ScientistRawScannable ~= nil
					or targetActivation.ScientistScannable ~= nil)
				and self:DistanceToUnit(unit) <= self.Settings[cMaxScanDistance]
				and (unit:IsDead() == true
					or unit:IsInCombat() == true
					or (targetDisposition ~= 0
						and targetDisposition ~= 1))) then
				self:Scan(unit)
			end
		end
	end
end
---------------------------------------------------------------------------------------------------
-- UI Events
---------------------------------------------------------------------------------------------------
function ZenScan:OnConfigClose( wndHandler, wndControl, eMouseButton )
	self.wndConfig:Show(false, true)
end

function ZenScan:OnSaveSecondsBeforeRescan( wndHandler, wndControl, eMouseButton )
	local text = self.wndConfigTxtSecondsBeforeRescan:GetText()
	self.Settings[cSecondsBeforeRescan] = tonumber(text)
end

function ZenScan:OnSaveMaxScanDistance( wndHandler, wndControl, eMouseButton )
	local text = self.wndConfigTxtMaxScanDistance:GetText()
	self.Settings[cMaxScanDistance] = tonumber(text)
end

function ZenScan:OnAllowAutoScanCheck( wndHandler, wndControl, eMouseButton )
	self.Settings[cAllowAutoScanSetting] = true
end

function ZenScan:OnAllowAutoScanUnCheck( wndHandler, wndControl, eMouseButton )
	self.Settings[cAllowAutoScanSetting] = false
end

function ZenScan:OnAllowTargetScanCheck( wndHandler, wndControl, eMouseButton )
	self.Settings[cAllowTargetScanSetting] = true
end

function ZenScan:OnAllowTargetScanUnCheck( wndHandler, wndControl, eMouseButton )
	self.Settings[cAllowTargetScanSetting] = false
end

-----------------------------------------------------------------------------------------------
-- ZenScan Instance
-----------------------------------------------------------------------------------------------
local ZenScanInst = ZenScan:new()
ZenScanInst:Init()
