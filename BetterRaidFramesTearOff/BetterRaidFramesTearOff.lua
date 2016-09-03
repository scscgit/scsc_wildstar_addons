-----------------------------------------------------------------------------------------------
-- Client Lua Script for BetterRaidFramesTearOff
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "MatchMakingLib"

local BetterRaidFramesTearOff = {}

local LuaEnumLeaderType =
{
	Leader = 1,
	MainTank = 2,
	MainAssist = 3,
	RaidAssist = 4,
}

local LuaEnumSpriteColor =
{
	Red = 1,
	Orange = 2,
	Green = 3,
}	

local ktClassIdToClassName =
{
	[GameLib.CodeEnumClass.Esper] 			= "Esper",
	[GameLib.CodeEnumClass.Medic] 			= "Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "Stalker",
	[GameLib.CodeEnumClass.Warrior] 		= "Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "Engineer",
	[GameLib.CodeEnumClass.Spellslinger] 	= "Spellslinger",
}

local ktIdToRoleSprite =
{
	[-1] = "",
	[MatchMakingLib.Roles.DPS] = "sprRaid_Icon_RoleDPS",
	[MatchMakingLib.Roles.Healer] = "sprRaid_Icon_RoleHealer",
	[MatchMakingLib.Roles.Tank] = "sprRaid_Icon_RoleTank",
}

local ktIdToRoleTooltip =
{
	[-1] = "",
	[MatchMakingLib.Roles.DPS] = "CRB_DPS",
	[MatchMakingLib.Roles.Healer] = "CRB_Healer",
	[MatchMakingLib.Roles.Tank] = "CRB_Tank",
}

local ktIdToLeaderSprite =  -- 0 is valid
{
	[0] = "",
	[LuaEnumLeaderType.Leader] 		= "CRB_Raid:sprRaid_Icon_Leader",
	[LuaEnumLeaderType.MainTank] 	= "CRB_Raid:sprRaid_Icon_TankLeader",
	[LuaEnumLeaderType.MainAssist] 	= "CRB_Raid:sprRaid_Icon_AssistLeader",
	[LuaEnumLeaderType.RaidAssist] 	= "CRB_Raid:sprRaid_Icon_2ndLeader",
}

local ktIdToLeaderTooltip =
{
	[0] = "",
	[LuaEnumLeaderType.Leader] 		= "RaidFrame_RaidLeader",
	[LuaEnumLeaderType.MainTank] 	= "RaidFrame_MainTank",
	[LuaEnumLeaderType.MainAssist] 	= "RaidFrame_MainAssist",
	[LuaEnumLeaderType.RaidAssist] 	= "RaidFrame_CombatAssist",
}

local ktHealthStatusToSpriteSmall =
{
	[LuaEnumSpriteColor.Red] 	= "sprRaid_HealthProgBar_Red",
	[LuaEnumSpriteColor.Orange] = "sprRaid_HealthProgBar_Orange",
	[LuaEnumSpriteColor.Green] 	= "sprRaid_HealthProgBar_Green",
}

local ktHealthStatusToSpriteSmallEdgeGlow =
{
	[LuaEnumSpriteColor.Red] 	= "sprRaid_HealthEdgeGlow_Red",
	[LuaEnumSpriteColor.Orange] = "sprRaid_HealthEdgeGlow_Orange",
	[LuaEnumSpriteColor.Green] 	= "sprRaid_HealthEdgeGlow_Green",
}

local ktHealthStatusToSpriteBig =
{
	[LuaEnumSpriteColor.Red] 	= "sprRaidTear_BigHealthProgBar_Red",
	[LuaEnumSpriteColor.Orange] = "sprRaidTear_BigHealthProgBar_Orange",
	[LuaEnumSpriteColor.Green] 	= "sprRaidTear_BigHealthProgBar_Green",
}

local ktHealthStatusToSpriteBigEdgeGlow =
{
	[LuaEnumSpriteColor.Red] 	= "sprRaidTear_BigHealthEdgeGlow_Red",
	[LuaEnumSpriteColor.Orange] = "sprRaidTear_BigHealthEdgeGlow_Orange",
	[LuaEnumSpriteColor.Green] 	= "sprRaidTear_BigHealthEdgeGlow_Green",
}

local ktDispositionToSprite =
{
	[Unit.CodeEnumDisposition.Neutral] 	= "",
	[Unit.CodeEnumDisposition.Friendly] = "sprRaid_Icon_GreenFriendly",
	[Unit.CodeEnumDisposition.Hostile] 	= "sprRaid_Icon_RedEnemy",
}
-- Set below

local DefaultSettings = {
	bLockFrame = false,
	bShowIcon_Leader = true,
	bShowIcon_Role = false,
	bShowDebuffs = false,
	bShowBuffs = false,
	bShowFocus = false,
	bShowToL = true, -- Target of Leader
	bAutoLock_Combat = true,
	tTrackedCharacters = {},
}

--DefaultSettings.__index = DefaultSettings

function BetterRaidFramesTearOff:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function BetterRaidFramesTearOff:Init()
    Apollo.RegisterAddon(self)
end

function BetterRaidFramesTearOff:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end
	
	local tSaved = 
	{
		nSaveVersion = knSaveVersion,
	}
	
	self:recursiveCopyTable(self.settings, tSaved)
	
	return tSaved
end

function BetterRaidFramesTearOff:OnRestore(eType, tSavedData)
	if not tSavedData or tSavedData.nSaveVersion ~= knSaveVersion then
		return
	end
	
	self.settings = self:recursiveCopyTable(DefaultSettings, self.settings)
	self.settings = self:recursiveCopyTable(tSavedData, self.settings)
end

function BetterRaidFramesTearOff:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("BetterRaidFramesTearOff.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
	
	self.settings = self.settings or self:recursiveCopyTable(DefaultSettings)
end

function BetterRaidFramesTearOff:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("UnitEnteredCombat", 					"OnEnteredCombat", self)
	Apollo.RegisterEventHandler("GenericEvent_Raid_ToggleRaidTearOff", 	"Initialize", self)
	Apollo.RegisterTimerHandler("MainUpdateTimer", 						"MainUpdateTimer", self)
	Apollo.RegisterEventHandler("Group_Updated", 						"OnGroup_Updated", self)
	Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("ChangeWorld", 							"OnChangeWorld", self)
	Apollo.RegisterTimerHandler("TrackSavedCharactersTimer",					"TrackSavedCharacters", self)

	Apollo.CreateTimer("MainUpdateTimer", 0.5, true)
	Apollo.StopTimer("MainUpdateTimer")
	
	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BetterRaidFramesTearOffForm", nil, self)
	self.BetterRaidFrames = Apollo.GetAddon("BetterRaidFrames")

	self.tTrackedMemberIdx = {}	
	
	self:OnChangeWorld()
end

function BetterRaidFramesTearOff:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("CRB_Options")})
	Apollo.StartTimer("MainUpdateTimer")
	self:LockFrameHelper(self.settings.bLockFrame)
	self:BarTexturesHelper()
	self:RefreshSettings()
end

function BetterRaidFramesTearOff:OnGroup_Updated()
	if not GroupLib:InRaid() then return end
	self:TrackSavedCharacters()
end

function BetterRaidFramesTearOff:recursiveCopyTable(from, to)
	to = to or {}
	for k,v in pairs(from) do
		if type(v) == "table" then
			to[k] = self:recursiveCopyTable(v, to[k])
		else
			to[k] = v
		end
	end
	return to
end

function BetterRaidFramesTearOff:RefreshSettings()
	local wndOptions = self.wndMain:FindChild("RaidTearOffOptions:SelfConfigRaidCustomizeOptions")
	self.wndMain:FindChild("RaidTearOffOptionsBtn"):AttachWindow(self.wndMain:FindChild("RaidTearOffOptions"))
	if self.settings.bShowIcon_Leader ~= nil then
		wndOptions:FindChild("RaidCustomizeLeaderIcons"):SetCheck(self.settings.bShowIcon_Leader) end
	if self.settings.bShowIcon_Role ~= nil then
		wndOptions:FindChild("RaidCustomizeRoleIcons"):SetCheck(self.settings.bShowIcon_Role) end
	if self.settings.bShowDebuffs ~= nil then
		wndOptions:FindChild("RaidCustomizeDebuffs"):SetCheck(self.settings.bShowDebuffs) end
	if self.settings.bShowBuffs ~= nil then
		wndOptions:FindChild("RaidCustomizeBuffs"):SetCheck(self.settings.bShowBuffs) end
	if self.settings.bShowFocus ~= nil then
		wndOptions:FindChild("RaidCustomizeManaBar"):SetCheck(self.settings.bShowFocus) end
	if self.settings.bShowToL ~= nil then
		wndOptions:FindChild("RaidCustomizeAssistTargets"):SetCheck(self.settings.bShowToL) end
	if self.settings.bAutoLock_Combat ~= nil then
		wndOptions:FindChild("RaidCustomizeLockInCombat"):SetCheck(self.settings.bAutoLock_Combat) end
end

function BetterRaidFramesTearOff:Initialize(nMemberIdx)
	if not nMemberIdx then
		return
	end
	
	self.unitPlayerDisposComparison = GameLib.GetPlayerUnit()
	self.tTrackedMemberIdx[nMemberIdx] = GroupLib.GetUnitForGroupMember(nMemberIdx) -- Add a member to the tracked list TODO: Remove
	
	-- This function is fired every time a new player is added to the focus frame, just add it to the list here.
	local unitName = self.tTrackedMemberIdx[nMemberIdx]:GetName()
	self.settings.tTrackedCharacters[unitName] = unitName
	
	self.wndMain:Show(true)	
	self:MainUpdateTimer()
end

-----------------------------------------------------------------------------------------------
-- Main Methods
-----------------------------------------------------------------------------------------------

function BetterRaidFramesTearOff:MainUpdateTimer()
	if not GroupLib.InRaid() or self.BetterRaidFrames.settings.bDisableFrames then
		if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
			self.wndMain:Show(false)
		end
		return
	end

	if not self.wndMain or not self.wndMain:IsValid() or not self.wndMain:IsVisible() then
		return
	end

	for nMemberIdx, unitMember in self:safePairs(self.tTrackedMemberIdx) do
		local unitCurrentUnit = GroupLib.GetUnitForGroupMember(nMemberIdx)
		
		if unitCurrentUnit ~= nil then
		
			local tMemberData = GroupLib.GetGroupMember(nMemberIdx)
			local bOutOfRange = tMemberData.nHealthMax == 0
			
			if bOutOfRange or not tMemberData.bIsOnline then
				Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidUnTear", nMemberIdx)
				self.tTrackedMemberIdx[nMemberIdx] = nil
			else
				if unitCurrentUnit == unitMember then
					self:UpdateSpecificMember(nMemberIdx, unitMember, tMemberData)
				else
					local unitDisplacedUnit = GroupLib.GetUnitForGroupMember(nMemberIdx - 1)
					if unitDisplacedUnit == unitMember then
						self.tTrackedMemberIdx[nMemberIdx] = nil
						self.tTrackedMemberIdx[nMemberIdx - 1] = unitMember
						self:UpdateSpecificMember(nMemberIdx - 1, unitMember, tMemberData)
					else
						Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidUnTear", nMemberIdx)
						self.tTrackedMemberIdx[nMemberIdx] = nil
					end
				end
			end
		else	
			Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidUnTear", nMemberIdx)
			self.tTrackedMemberIdx[nMemberIdx] = nil
		end
		
	end

	-- Remove zombie entries
	for idx, wndRaidMember in self:safePairs(self.wndMain:FindChild("RaidTearOffContainer"):GetChildren()) do
		local nFoundMemberIdx = tonumber(wndRaidMember:GetName()) or 0
		if not self.tTrackedMemberIdx[nFoundMemberIdx] then
			wndRaidMember:Destroy()
		end
	end

	if #self.wndMain:FindChild("RaidTearOffContainer"):GetChildren() == 0 then
		Apollo.StopTimer("MainUpdateTimer")
		
		self.wndMain:Show(false)
		return
	end

	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nTop + self.wndMain:FindChild("RaidTearOffContainer"):ArrangeChildrenVert(0) + 58)
	self.wndMain:SetSizingMinimum(200, self.wndMain:GetHeight())
	self.wndMain:SetSizingMaximum(1000, self.wndMain:GetHeight())
end

function BetterRaidFramesTearOff:UpdateSpecificMember(nMemberIdx, unitMember, tMemberData)
	if not nMemberIdx or not tMemberData then
		return
	end
	local wndRaidMember = self:LoadByName("RaidTearMember", self.wndMain:FindChild("RaidTearOffContainer"), nMemberIdx)
	local unitTarget = GameLib.GetTargetUnit()
	
	wndRaidMember:FindChild("RaidMemberToTFrame"):Show(false)
	wndRaidMember:FindChild("RaidMemberUntearBtn"):Show(false)
	wndRaidMember:FindChild("RaidMemberUntearBtn"):SetData({Idx = nMemberIdx, Name = tMemberData.strCharacterName})
	wndRaidMember:FindChild("RaidMemberBaseVitals"):SetData(nMemberIdx)
	
	local bShowRoleIcon = self.settings.bShowIcon_Role
	if bShowRoleIcon then
		local eRoleIdx = -1
		if tMemberData.bDPS then
			eRoleIdx = MatchMakingLib.Roles.DPS
		elseif tMemberData.bHealer then
			eRoleIdx = MatchMakingLib.Roles.Healer
		elseif tMemberData.bTank then
			eRoleIdx = MatchMakingLib.Roles.Tank
		end
		wndRaidMember:FindChild("RaidMemberRoleIconSprite"):SetSprite(ktIdToRoleSprite[eRoleIdx])
		wndRaidMember:FindChild("RaidMemberRoleIconSprite"):SetTooltip(Apollo.GetString(ktIdToRoleTooltip[eRoleIdx]))
	end
	wndRaidMember:FindChild("RaidMemberRoleIconSprite"):Show(bShowRoleIcon)

	local bShowLeaderIcon = self.settings.bShowIcon_Leader
	if bShowLeaderIcon then
		local eLeaderIdx = 0
		if tMemberData.bIsLeader then
			eLeaderIdx = LuaEnumLeaderType.Leader
		elseif tMemberData.bMainTank then
			eLeaderIdx = LuaEnumLeaderType.MainTank
		elseif tMemberData.bMainAssist then
			eLeaderIdx = LuaEnumLeaderType.MainAssist
		elseif tMemberData.bRaidAssistant then
			eLeaderIdx = LuaEnumLeaderType.RaidAssist
		end
		wndRaidMember:FindChild("RaidMemberLeaderIcon"):SetSprite(ktIdToLeaderSprite[eLeaderIdx])
		wndRaidMember:FindChild("RaidMemberLeaderIcon"):SetTooltip(Apollo.GetString(ktIdToLeaderTooltip[eLeaderIdx]))
	end
	wndRaidMember:FindChild("RaidMemberLeaderIcon"):Show(bShowLeaderIcon)

	local bShowManaBar = self.settings.bShowFocus and tMemberData.bHealer
	local wndManaBar = self:LoadByName("RaidTearManaBar", wndRaidMember, "RaidTearManaBar")
	if bShowManaBar and tMemberData.nMana and tMemberData.nMana > 0 then
		local nManaMax
		if tMemberData.nManaMax	<= 0 then
			nManaMax = 1000
		else
			nManaMax = tMemberData.nManaMax
		end
		wndManaBar:SetMax(nManaMax)
		wndManaBar:SetProgress(tMemberData.nMana)	
	end
	wndManaBar:Show(bShowManaBar and tMemberData.bIsOnline and unitMember and unitMember:GetHealth() > 0 and unitMember:GetMaxHealth() > 0)

	-- Unit
	if unitMember then
		if unitTarget and unitTarget == unitMember then
			wndRaidMember:FindChild("RaidMemberUntearBtn"):Show(not self.settings.bLockFrame)
		end
		
		-- Change the HP Bar Color if required for debuff tracking
		local DebuffColorRequired = self:TrackDebuffsHelper(unitMember, wndRaidMember)
		
		-- Update Bar Colors
		self:UpdateBarColors(wndRaidMember, tMemberData, DebuffColorRequired, false) -- false relates to not ToL
		
		-- Update text overlays		
		self:UpdateHPText(tMemberData.nHealth, tMemberData.nHealthMax, wndRaidMember, tMemberData.strCharacterName)
		self:UpdateShieldText(tMemberData.nShield, tMemberData.nShieldMax, wndRaidMember)
		self:UpdateAbsorbText(tMemberData.nAbsorption, wndRaidMember)
		-- Update opacity if out of range
		self:CheckRangeHelper(wndRaidMember, unitMember, tMemberData)

		-- Target of Target
		if tMemberData.bIsLeader or tMemberData.bMainTank or tMemberData.bMainAssist then
			local unitToT = unitMember:GetTarget()
			if unitToT and self.settings.bShowToL then
				wndRaidMember:FindChild("RaidMemberToTName"):SetData(unitToT)
				wndRaidMember:FindChild("RaidMemberToTFrame"):SetSprite("CRB_Raid:btnRaidTear_ThinHoloListBtnNormal")
				wndRaidMember:FindChild("RaidMemberAlignIcon"):SetSprite(ktDispositionToSprite[unitToT:GetDispositionTo(self.unitPlayerDisposComparison)])
				self:DoHPAndShieldResizing(wndRaidMember:FindChild("RaidMemberToTVitals"), unitToT, false)
				
				-- Change the HP Bar Color if required for debuff tracking
				local DebuffColorRequired = self:TrackDebuffsHelper(unitToT, wndRaidMember:FindChild("RaidMemberToTVitals"))
				
				-- Update Bar Colors
				self:UpdateBarColors(wndRaidMember:FindChild("RaidMemberToTVitals"), tMemberData, DebuffColorRequired, true) -- true related to this being ToL
				
				-- Update text overlays
				self:UpdateHPText(unitToT:GetHealth(), unitToT:GetMaxHealth(), wndRaidMember:FindChild("RaidMemberToTVitals"), unitToT:GetName())
				self:UpdateShieldText(unitToT:GetShieldCapacity(), unitToT:GetShieldCapacityMax(), wndRaidMember:FindChild("RaidMemberToTVitals"))
				self:UpdateAbsorbText(unitToT:GetAbsorptionValue(), wndRaidMember:FindChild("RaidMemberToTVitals"))

				if unitTarget and unitTarget == unitToT then
					wndRaidMember:FindChild("RaidMemberToTFrame"):SetSprite("CRB_Raid:btnRaidTear_ThinHoloListBtnPressed")
				end
			end
			wndRaidMember:FindChild("RaidMemberToTFrame"):Show(unitToT and self.settings.bShowToL)
		end

		-- Buffs
		if self.settings.bShowBuffs then
			wndRaidMember:FindChild("RaidMemberBeneBuffBar"):SetUnit(unitMember)
		else
			wndRaidMember:FindChild("RaidMemberBeneBuffBar"):SetUnit(nil)
		end
		wndRaidMember:FindChild("RaidMemberBeneBuffBar"):Show(self.settings.bShowBuffs)

		-- Debuffs
		if self.settings.bShowDebuffs then
			wndRaidMember:FindChild("RaidMemberHarmBuffBar"):SetUnit(unitMember)
		else
			wndRaidMember:FindChild("RaidMemberHarmBuffBar"):SetUnit(nil)
		end
		wndRaidMember:FindChild("RaidMemberHarmBuffBar"):Show(self.settings.bShowDebuffs)

		self:DoHPAndShieldResizing(wndRaidMember:FindChild("RaidMemberBaseVitals"), unitMember, true)
	end

	-- Resize
	local nLeft, nTop, nRight, nBottom = wndRaidMember:GetAnchorOffsets()
	if (tMemberData.bIsLeader or tMemberData.bMainTank or tMemberData.bMainAssist) and self.settings.bShowToL then
		wndRaidMember:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 58)
	else
		wndRaidMember:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 42)
	end
end

function BetterRaidFramesTearOff:UpdateHPText(nHealthCurr, nHealthMax, wndFrame, strCharacterName)
	local wnd = wndFrame:FindChild("CurrHealthBar")
	
	-- Values may be nil if unit went out of range
	if not nHealthCurr or not nHealthMax then
		-- Update text to be empty, otherwise it will be stuck at the old value
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName)
		else
			wnd:SetText(nil)
		end
		return
	end
	
	-- Unit might be dead
	if nHealthCurr == 0 then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." (Dead)")
		else
			wnd:SetText("  ".."(Dead)")
		end
		return
	end
	
	-- No text needs to be drawn if all HP Text options are disabled
	if not self.BetterRaidFrames.settings.bShowHP_Full and not self.BetterRaidFrames.settings.bShowHP_K and not self.BetterRaidFrames.settings.bShowHP_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName)
		else
			wnd:SetText(nil)
		end
		return
	end

	local strHealthPercentage = self:RoundPercentage(nHealthCurr, nHealthMax)
	local strHealthCurrRounded
	local strHealthMaxRounded

	if nHealthCurr < 1000 then
		strHealthCurrRounded = nHealthCurr
	else
		strHealthCurrRounded = self:RoundNumber(nHealthCurr)
	end

	if nHealthMax < 1000 then
		strHealthMaxRounded = nHealthMax
	else
		strHealthMaxRounded = self:RoundNumber(nHealthMax)
	end

	-- Only ShowHP_Full selected
	if self.BetterRaidFrames.settings.bShowHP_Full and not self.BetterRaidFrames.settings.bShowHP_K and not self.BetterRaidFrames.settings.bShowHP_Pct then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..nHealthCurr.."/"..nHealthMax)
		else
			wnd:SetText(" "..nHealthCurr.."/"..nHealthMax)
		end
		return
	end

	-- ShowHP_Full + Pct
	if self.BetterRaidFrames.settings.bShowHP_Full and not self.BetterRaidFrames.settings.bShowHP_K and self.BetterRaidFrames.settings.bShowHP_Pct then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		else
			wnd:SetText(" "..nHealthCurr.."/"..nHealthMax.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only ShowHP_K selected
	if not self.BetterRaidFrames.settings.bShowHP_Full and self.BetterRaidFrames.settings.bShowHP_K and not self.BetterRaidFrames.settings.bShowHP_Pct then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded)
		else
			wnd:SetText(" "..strHealthCurrRounded.."/"..strHealthMaxRounded)
		end
		return
	end

	-- ShowHP_K + Pct
	if not self.BetterRaidFrames.settings.bShowHP_Full and self.BetterRaidFrames.settings.bShowHP_K and self.BetterRaidFrames.settings.bShowHP_Pct then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		else
			wnd:SetText(" "..strHealthCurrRounded.."/"..strHealthMaxRounded.." ("..strHealthPercentage..")")
		end
		return
	end

	-- Only Pct selected
	if not self.BetterRaidFrames.settings.bShowHP_Full and not self.BetterRaidFrames.settings.bShowHP_K and self.BetterRaidFrames.settings.bShowHP_Pct then
		if self.BetterRaidFrames.settings.bShowNames then
			wnd:SetText(" "..strCharacterName.." - "..strHealthPercentage)
		else
			wnd:SetText(" "..strHealthPercentage)
		end
		return
	end
end

function BetterRaidFramesTearOff:UpdateShieldText(nShieldCurr, nShieldMax, wndFrame)
	local wnd = wndFrame:FindChild("CurrShieldBar")

	-- Values may be nil if unit went out of range
	if not nShieldCurr or not nShieldMax then
		wnd:SetText(nil)
		return
	end
	
	-- Only update text if we are showing the shield bar
	if not self.BetterRaidFrames.settings.bShowShieldBar then
		return
	end

	if bOutOfRange then
		wnd:SetText(nil)
		return
	end

	local strShieldPercentage = self:RoundPercentage(nShieldCurr, nShieldMax)
	local strShieldCurrRounded

	if nShieldCurr > 0 then
		if nShieldCurr < 1000 then
			strShieldCurrRounded = nShieldCurr
		else
			strShieldCurrRounded = self:RoundNumber(nShieldCurr)
		end
	else
		strShieldCurrRounded = "" -- empty string to remove text when there is no shield
	end

	-- No text needs to be drawn if all Shield Text options are disabled
	if not self.BetterRaidFrames.settings.bShowShield_K and not self.BetterRaidFrames.settings.bShowShield_Pct then
		-- Update text to be empty, otherwise it will be stuck at the old value
		wnd:SetText(nil)
		return
	end

	-- Only Pct selected
	if not self.BetterRaidFrames.settings.bShowShield_K and self.BetterRaidFrames.settings.bShowShield_Pct then
		wnd:SetText(strShieldPercentage)
		return
	end

	-- Only ShowShield_K selected
	if self.BetterRaidFrames.settings.bShowShield_K and not self.BetterRaidFrames.settings.bShowShield_Pct then
		wnd:SetText(strShieldCurrRounded)
		return
	end
end

function BetterRaidFramesTearOff:UpdateAbsorbText(nAbsorbCurr, wndFrame)
	local wnd = wndFrame:FindChild("CurrAbsorbBar")

	-- Values may be nil if unit went out of range
	if not nAbsorbCurr then
		wnd:SetText(nil)
		return
	end
	-- Only update text if we are showing the shield bar
	if not self.BetterRaidFrames.settings.bShowAbsorbBar then
		return
	end

	if bOutOfRange then
		wnd:SetText(nil)
		return
	end

	local strAbsorbCurrRounded

	if nAbsorbCurr > 0 then
		if nAbsorbCurr < 1000 then
			strAbsorbCurrRounded = nAbsorbCurr
		else
			strAbsorbCurrRounded = self:RoundNumber(nAbsorbCurr)
		end
	else
		strAbsorbCurrRounded = "" -- empty string to remove text when there is no absorb
	end

	-- No text needs to be drawn if all absorb text options are disabled
	if not self.BetterRaidFrames.settings.bShowAbsorb_K then
		wnd:SetText(nil)
		return
	end

	if self.BetterRaidFrames.settings.bShowAbsorb_K then
		wnd:SetText(strAbsorbCurrRounded)
		return
	end
end

function BetterRaidFramesTearOff:TrackDebuffsHelper(unitMember, wndFrame)
	local wnd = wndFrame:FindChild("CurrHealthBar")

	-- Only continue if we are required to TrackDebuffs according to the settings
	if not self.BetterRaidFrames.settings.bTrackDebuffs then
		return false
	end

	local playerBuffs = unitMember:GetBuffs()
	local debuffs = playerBuffs['arHarmful']	
    	
	-- If player has no debuffs, change the color to normal in case it was changed before.
	if next(debuffs) == nil then
		return false
	end
	
	-- Loop through all debuffs. Change HP bar color if class of splEffect equals 38, which means it is dispellable
	for key, value in self:safePairs(debuffs) do
		if value['splEffect']:GetClass() == 38 then
			return true
		end
	end

	-- Reset to normal sprite if there were debuffs but none of them were dispellable.
	-- This might happen in cases where a player had a dispellable debuff -and- a non-dispellable debuff on him
	return false
end

function BetterRaidFramesTearOff:UpdateBarColors(wndFrame, tMemberData, DebuffColorRequired, ToL)
	local wndHP = wndFrame:FindChild("CurrHealthBar")
	local wndShield = wndFrame:FindChild("CurrShieldBar")
	local wndAbsorb = wndFrame:FindChild("CurrAbsorbBar")
	
	local HPHealthyColor
	local HPDebuffColor
	local ShieldBarColor
	local AbsorbBarColor
	
	if self.BetterRaidFrames.settings.bClassSpecificBarColors and not ToL then
		local strClassKey = "strColor"..ktClassIdToClassName[tMemberData.eClassId]
		HPHealthyColor = self.BetterRaidFrames.settings[strClassKey.."_HPHealthy"]
		HPDebuffColor = self.BetterRaidFrames.settings[strClassKey.."_HPDebuff"]
		ShieldBarColor = self.BetterRaidFrames.settings[strClassKey.."_Shield"]
		AbsorbBarColor = self.BetterRaidFrames.settings[strClassKey.."_Absorb"]
	else
		HPHealthyColor = self.BetterRaidFrames.settings.strColorGeneral_HPHealthy
		HPDebuffColor = self.BetterRaidFrames.settings.strColorGeneral_HPDebuff
		ShieldBarColor = self.BetterRaidFrames.settings.strColorGeneral_Shield
		AbsorbBarColor = self.BetterRaidFrames.settings.strColorGeneral_Absorb
	end

	if DebuffColorRequired then
		wndHP:SetBarColor(HPDebuffColor)
	else
		wndHP:SetBarColor(HPHealthyColor)
	end
	
	wndShield:SetBarColor(ShieldBarColor)
	wndAbsorb:SetBarColor(AbsorbBarColor)
end

-----------------------------------------------------------------------------------------------
-- Simple UI interaction
-----------------------------------------------------------------------------------------------

function BetterRaidFramesTearOff:OnCloseBtn(wndHandler, wndControl)
	if self.wndMain and self.wndMain:IsValid() then
		Apollo.StopTimer("MainUpdateTimer")
		self.wndMain:Show(false)
		
		for nMemberIdx, nValue in self:safePairs(self.tTrackedMemberIdx) do
			Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidUnTear", nMemberIdx)
		end
		
		self.tTrackedMemberIdx = {}
		self.settings.tTrackedCharacters = {}
	end
end

function BetterRaidFramesTearOff:OnRaidMemberUntearBtn(wndHandler, wndControl) -- RaidMemberUntearBtn
	local nMemberIdx = wndHandler:GetData()["Idx"]
	local strCharacterName = wndHandler:GetData()["Name"]
	if nMemberIdx and self.tTrackedMemberIdx[nMemberIdx] then
		Event_FireGenericEvent("GenericEvent_Raid_ToggleRaidUnTear", nMemberIdx)
		self.tTrackedMemberIdx[nMemberIdx] = nil
		self.settings.tTrackedCharacters[strCharacterName] = nil
		self:MainUpdateTimer()
	end
end

function BetterRaidFramesTearOff:OnRaidLockFrameBtnToggle(wndHandler, wndControl) -- RaidLockFrameBtn
	self.settings.bLockFrame = wndHandler:IsChecked()
	self:LockFrameHelper(self.settings.bLockFrame)
end

function BetterRaidFramesTearOff:OnRaidTearMemberMouseUp(wndHandler, wndControl) -- RaidTearMember
	if wndHandler ~= wndControl or not wndHandler then
		return
	end

	local unitMember = GroupLib.GetUnitForGroupMember(wndHandler:GetName())
	if unitMember then
		GameLib.SetTargetUnit(unitMember)
		
		if self.BetterRaidFrames.settings.bRememberPrevTarget then
			self.PrevTarget = unitMember
		end
		
		self:MainUpdateTimer()
	end
end

function BetterRaidFramesTearOff:OnRaidMemberToTNameClick(wndHandler, wndControl) -- RaidMemberToTName
	-- GOTCHA: Use MouseUp instead of ButtonCheck/SetSprite to avoid weird edgecase bugs
	if wndHandler ~= wndControl or not wndHandler or not wndHandler:GetData() then
		return
	end

	GameLib.SetTargetUnit(wndHandler:GetData())
	self:MainUpdateTimer()
end

-----------------------------------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------------------------------

function BetterRaidFramesTearOff:OnChangeWorld()
	-- Calls TrackSavedCharacters after a few seconds.
	-- This is to prevent API calls to GetPlayerUnitByName() before fully loaded (and receiving nil)
	Apollo.CreateTimer("TrackSavedCharactersTimer", 3, false)
end

function BetterRaidFramesTearOff:TrackSavedCharacters()
	for key, value in self:safePairs(self.settings.tTrackedCharacters) do
		if GameLib.GetPlayerUnitByName(value) ~= nil then
			-- Determine nMemberIdx
			local nGroupSize = GroupLib.GetGroupMaxSize()
			if nGroupSize == nil then
				return
			end
			for i=1, nGroupSize do
				local unitPlayer = GroupLib.GetGroupMember(i)
				if unitPlayer ~= nil then
					if value  == unitPlayer.strCharacterName then
						local nMemberIdx = unitPlayer.nMemberIdx
						self:Initialize(nMemberIdx)
						break
					end
				end
			end
		end
	end
end

function BetterRaidFramesTearOff:LockFrameHelper(bLock)
	self.wndMain:SetStyle("Sizable", not bLock)
	self.wndMain:SetStyle("Moveable", not bLock)
	self.wndMain:FindChild("RaidLockFrameBtn"):SetCheck(bLock)
end

function BetterRaidFramesTearOff:OnEnteredCombat(unit, bInCombat)
	if self.settings.bLockFrame then
		return
	end
	if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsVisible() and unit == GameLib.GetPlayerUnit() and self.settings.bAutoLock_Combat then
		self.wndMain:FindChild("RaidLockFrameBtn"):SetCheck(bInCombat)
		self:LockFrameHelper(bInCombat)
	end
end

function BetterRaidFramesTearOff:DoHPAndShieldResizing(wndBtnParent, unitPlayer, bBigSprites)
	if unitPlayer and unitPlayer:GetHealth() then
		local nHealthCurr 	= unitPlayer:GetHealth()
		local nHealthMax 	= unitPlayer:GetMaxHealth()
		local nShieldCurr 	= unitPlayer:GetShieldCapacity()
		local nShieldMax 	= unitPlayer:GetShieldCapacityMax()
		local nAbsorbCurr 	= 0
		local nAbsorbMax 	= unitPlayer:GetAbsorptionMax()
		
		-- Status variables
		local bDead = nHealthCurr == 0 and nHealthMax ~= 0

		if nAbsorbMax > 0 then
			nAbsorbCurr = unitPlayer:GetAbsorptionValue() -- Since it doesn't clear when the buff drops off
		end
		local nTotalMax = nHealthMax + nShieldMax + nAbsorbMax

		-- Bars
		local wndHealthBar = wndBtnParent:FindChild("HealthBar")
		local wndMaxAbsorb = wndBtnParent:FindChild("MaxAbsorbBar")
		local wndMaxShield = wndBtnParent:FindChild("MaxShieldBar")
		local wndCurrShieldBar = wndBtnParent:FindChild("CurrShieldBar")
		local wndCurrAbsorbBar = wndBtnParent:FindChild("CurrAbsorbBar")
		local wndCurrHealthBar = wndBtnParent:FindChild("CurrHealthBar")

		wndHealthBar:Show(true)
		wndMaxAbsorb:Show(not bDead and self.BetterRaidFrames.settings.bShowAbsorbBar)
		wndMaxShield:Show(not bDead and nShieldMax > 0 and self.BetterRaidFrames.settings.bShowShieldBar)
		wndCurrShieldBar:Show(not bDead and nShieldMax > 0 and self.BetterRaidFrames.settings.bShowShieldBar)
		
		if self.BetterRaidFrames.settings.bShowShieldBar then
			self:SetBarValue(wndCurrShieldBar, 0, nShieldCurr, nShieldMax)
		end
		if self.BetterRaidFrames.settings.bShowAbsorbBar then
			self:SetBarValue(wndCurrAbsorbBar, 0, nAbsorbCurr, nAbsorbMax)
		end
		self:SetBarValue(wndCurrHealthBar, 0, nHealthCurr, nHealthMax)

		-- Scaling
		local nWidth = wndBtnParent:GetWidth()
		local nLeft, nTop, nRight, nBottom = wndHealthBar:GetAnchorOffsets()
		
		-- Example usage for HP/Shield -> To have the start of the shield bar align with the end of the HP bar, Shield-Left must be HP-Right.
		-- Define offsets based on settings of which bars to show
		if self.BetterRaidFrames.settings.bShowShieldBar and self.BetterRaidFrames.settings.bShowAbsorbBar then
			wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.67, nBottom)
			wndMaxShield:SetAnchorOffsets(nWidth * 0.67, nTop, nWidth * 0.85, nBottom)
			wndMaxAbsorb:SetAnchorOffsets(nWidth * 0.85, nTop, nWidth, nBottom)
		end
	
		if self.BetterRaidFrames.settings.bShowShieldBar and not self.BetterRaidFrames.settings.bShowAbsorbBar then
			wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.75, nBottom)
			wndMaxShield:SetAnchorOffsets(nWidth * 0.75, nTop, nWidth, nBottom)
		end
	
		if not self.BetterRaidFrames.settings.bShowShieldBar and self.BetterRaidFrames.settings.bShowAbsorbBar then
			wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth * 0.8, nBottom)
			wndMaxAbsorb:SetAnchorOffsets(nWidth * 0.8, nTop, nWidth, nBottom)
		end
	
		if not self.BetterRaidFrames.settings.bShowShieldBar and not self.BetterRaidFrames.settings.bShowAbsorbBar then
			wndHealthBar:SetAnchorOffsets(nLeft, nTop, nWidth, nBottom)
		end
	end
end

function BetterRaidFramesTearOff:CheckRangeHelper(wndRaidMember, unitMember, tMemberData)
	local opacity
	
	-- Use these variables to determine if opacity has to be set.
	-- We use custom sprites, and no opacity change when OoR, dead, or offline
	local bOutOfRange = tMemberData.nHealthMax == 0 or not unitMember
	local bDead = tMemberData.nHealth == 0 and tMemberData.nHealthMax ~= 0
	local bOffline = not tMemberData.bIsOnline

	if self.BetterRaidFrames.settings.bCheckRange and not bOutOfRange and not bDead and not bOffline then
		local player = GameLib.GetPlayerUnit()
		if player == nil then return end

		if unitMember ~= player and (unitMember == nil or not self:RangeCheck(unitMember, player, self.BetterRaidFrames.settings.fMaxRange)) then
			opacity = 0.4
		else
			opacity = 1
		end
	end
	wndRaidMember:FindChild("CurrHealthBar"):SetOpacity(opacity)
	wndRaidMember:FindChild("CurrShieldBar"):SetOpacity(opacity)
	wndRaidMember:FindChild("CurrAbsorbBar"):SetOpacity(opacity)
end

function BetterRaidFramesTearOff:RangeCheck(unit1, unit2, range)
	local v1 = unit1:GetPosition()
	local v2 = unit2:GetPosition()

	local dx, dy, dz = v1.x - v2.x, v1.y - v2.y, v1.z - v2.z

	return dx*dx + dy*dy + dz*dz <= range*range
end

function BetterRaidFramesTearOff:SetBarValue(wndBar, fMin, fValue, fMax)
	wndBar:SetMax(fMax)
	wndBar:SetFloor(fMin)
	wndBar:SetProgress(fValue)
end

function BetterRaidFramesTearOff:BarTexturesHelper()
	if self.BetterRaidFrames.settings.bTransparency then
		self.wndMain:FindChild("HoloFrame"):SetSprite("")
	elseif not self.BetterRaidFrames.settings.bTransparency then
		self.wndMain:FindChild("HoloFrame"):SetSprite("BK3:UI_BK3_Holo_Framing_3")
	end
end

function BetterRaidFramesTearOff:RoundNumber(n)
	local hundreds = math.floor(n / 100) % 10
	if hundreds == 0 then
		return ('%.0fK'):format(math.floor(n/1000))
	else
		return ('%.0f.%.0fK'):format(math.floor(n/1000), hundreds)
	end
end

function BetterRaidFramesTearOff:RoundPercentage(n, total)
	local hundreds = math.floor(n / total) % 10
	if hundreds == 0 then
		return ('%.1f%%'):format(n/total * 100)
	else
		return ('%.0f%%'):format(math.floor(n/total) * 100)
	end
end

-- Use a copy of the table instead of the table directly when calling pairs()
-- Prevents lua error when table changes while looping.
function BetterRaidFramesTearOff:safePairs( _t )
	local tKeys = {}
	for key in pairs(_t) do
		table.insert(tKeys, key)
	end
	local currentIndex = 0
	return function()
		currentIndex = currentIndex + 1
		local key = tKeys[currentIndex]
		return key, _t[key]
	end
end

function BetterRaidFramesTearOff:LoadByName(strForm, wndParent, strCustomName)
	local wndNew = wndParent:FindChild(strCustomName)
	if not wndNew then
		wndNew = Apollo.LoadForm(self.xmlDoc, strForm, wndParent, self)
		wndNew:SetName(strCustomName)
	end
	return wndNew
end

---------------------------------------------------------------------------------------------------
-- BetterRaidFramesTearOffForm Functions
---------------------------------------------------------------------------------------------------
function BetterRaidFramesTearOff:OnRaidTearOffCustomizeLeaderIconsCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowIcon_Leader = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeRoleIconsCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowIcon_Role = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeDebuffsCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowDebuffs = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeBuffsCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowBuffs = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeFocusBarCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowFocus = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeShowToLCheck( wndHandler, wndControl, eMouseButton )
	self.settings.bShowToL = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

function BetterRaidFramesTearOff:OnRaidTearOffCustomizeCombatLock( wndHandler, wndControl, eMouseButton )
	self.settings.bAutoLock_Combat = wndHandler:IsChecked()
	self:MainUpdateTimer()
end

---------------------------------------------------------------------------------------------------
-- RaidTearMember Functions
---------------------------------------------------------------------------------------------------

function BetterRaidFramesTearOff:RaidMemberBaseVitals_OnMouseEnter( wndHandler, wndControl, x, y )
	if not wndControl or not self.BetterRaidFrames.settings.bMouseOverSelection then
		return
	end

	if wndControl:GetName() == "RaidMemberBaseVitals" then
		if self.BetterRaidFrames.settings.bRememberPrevTarget and not self.bOldTargetSet then
			self.PrevTarget = GameLib.GetTargetUnit()
			self.bOldTargetSet = true
		end

		local idx = wndControl:GetData()
		local unit = GroupLib.GetUnitForGroupMember(idx)
		if unit ~= nil then
			GameLib.SetTargetUnit(unit)
		end
	end
end

function BetterRaidFramesTearOff:RaidMemberBaseVitals_OnMouseExit( wndHandler, wndControl, x, y )
	if not wndHandler or not wndControl or not self.BetterRaidFrames.settings.bMouseOverSelection or not self.BetterRaidFrames.settings.bRememberPrevTarget or not self.bOldTargetSet then
		return
	end
	if wndHandler == wndControl then
		GameLib.SetTargetUnit(self.PrevTarget)
		self.bOldTargetSet = false
	end
end

local BetterRaidFramesTearOffInst = BetterRaidFramesTearOff:new()
BetterRaidFramesTearOffInst:Init()

