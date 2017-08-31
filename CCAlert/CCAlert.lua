------------------------------------
-- Boilerplate
------------------------------------

--[[ TODO:
	* Font color
	* Dynamic font change
	* BG opacity
	* BG sprite
	* CC states display priority
	- icon options
	* use grid list to display cc states
	- play sound on cc applied
	* get rid of tSettings.ccState[map] and use enum instead
	* cc duration progress bar
	* cc bar display options (text,bar,both)
	* weapon indicator on disarm/subdue
	- weapon indicator window scaling option
	- dubug improving via table.insert(tDebug,var)
	* dropdown container to grid list & clean sprite list
	- organize xml control windows and fix labels
	- allow cc text editing

	Taunt   13
	Disarm   3
	AbilityRestriction   27
	Pull   18
	Polymorph   5
	Disorient   11
	Hold   7
	Tether   20
	Stun   0
	Vulnerability   9
	Daze   23
	Fear   6
	Interrupt   22
	Knockback   16
	Blind   15
	Snare   21
	Root   2
	Grounded   25
	DeTaunt   14
	VulnerabilityWithAct   10
	DisableCinematic   26
	PositionSwitch   19
	Knockdown   8
	Sleep   1
	Pushback   17
	Silence   4
	Subdue   24
	Disable   12

]]

local CCAlert = {}

local tCCStates = { -- lower number = higher priority
	[Unit.CodeEnumCCState.Disable] = { enabled = true, text = "Disabled", priority = 1 }, -- 12
	[Unit.CodeEnumCCState.Fear] = { enabled = true, text = "Fear", priority = 2 }, -- 6
	[Unit.CodeEnumCCState.Sleep] = { enabled = true, text = "Sleep", priority = 3 }, -- 1
	[Unit.CodeEnumCCState.Polymorph] = { enabled = true, text = "Polymorph", priority = 4 }, -- 5
	[Unit.CodeEnumCCState.Silence] = { enabled = true, text = "Silenced", priority = 5 }, -- 4
	[Unit.CodeEnumCCState.Stun] = { enabled = true, text = "Stunned", priority = 6 }, -- 0
	[Unit.CodeEnumCCState.Knockdown] = { enabled = true, text = "Knockdown", priority = 7 }, -- 8
	[Unit.CodeEnumCCState.Disarm] = { enabled = true, text = "Disarmed", priority = 8 }, -- 3
	[Unit.CodeEnumCCState.Subdue] = { enabled = true, text = "Subdue", priority = 9 }, -- 24
	[Unit.CodeEnumCCState.Root] = { enabled = true, text = "Rooted", priority = 10 }, -- 2
	[Unit.CodeEnumCCState.Disorient] = { enabled = true, text = "Disorient", priority = 11 }, -- 11
	[Unit.CodeEnumCCState.Tether] = { enabled = true, text = "Tethered", priority = 12 }, -- 20
	[Unit.CodeEnumCCState.Blind] = { enabled = true, text = "Blinded", priority = 13 }, -- 15
	[Unit.CodeEnumCCState.Daze] = { enabled = true, text = "Dazed", priority = 14 }, -- 23
	[Unit.CodeEnumCCState.AbilityRestriction] = { enabled = true, text = "Abilities Locked", priority = 15 }, -- 27
	[Unit.CodeEnumCCState.Snare] = { enabled = false, text = "Snared", priority = 16 }, -- 21
	[Unit.CodeEnumCCState.Hold] = { enabled = false, text = "Hold", priority = 17 }, -- 7
	[Unit.CodeEnumCCState.Grounded] = { enabled = false, text = "Grounded", priority = 18 }, -- 25
}

local tFontList = {
	["  HeaderGigantic"] = "CRB_HeaderGigantic_O",
	["  FloaterMedium"] = "CRB_FloaterMedium",
	["  Header24"] = "CRB_Header24_O",
	["  Dialog_Heading"] = "CRB_Dialog_Heading_Huge",
}

local tSpriteList = {
	["  Sprite_01"] = "UI_BK3_Holo_InsetFramed_Alert",
	["  Sprite_02"] = "sprActionBar_OrangeBorder",
	["  Sprite_03"] = "kitBase_HoloBlue_InsetBorder_Thick",
	["  Sprite_04"] = "sprActionBar_GreenBorder",
	["  Sprite_05"] = "sprActionBar_YellowBorder",
	["  Sprite_06"] = "spr_StatVertProgBase",
	["  Sprite_07"] = "sprInventory_NewItemScale",
	["  Sprite_08"] = "sprMetal_ExpandMenu_Large_Framing",
	["  Sprite_09"] = "UI_BK3_Holo_InsetFramed_Darker",
	["  Sprite_10"] = "UI_BK3_Holo_Snippet",
	["  Sprite_11"] = "UI_BK3_Metal_Inset_Block1",
	["  Sprite_12"] = "UI_BK3_Metal_Footer_Large",
	["  Sprite_13"] = "UI_BK3_Holo_Framing_2_Blocker",
	["  Sprite_14"] = "sprChat_BlueBG",
	["  Sprite_15"] = "AB_Activate",
	["  Sprite_16"] = "kitBase_SmallPlain",
	["  Sprite_17"] = "kitBase_HoloBlue_TinyNoGlow",
	["  Sprite_18"] = "sprTT_BasicBack",
	["  Sprite_19"] = "sprTut_BackerSmallPulse",
	["  Sprite_20"] = "UI_BK3_MTX_NCoinReminderPulse",
	["  Sprite_21"] = "spr_glowframe",
	["  Sprite_22"] = "spr_baseframeTHIN_Hologram",
	["  Sprite_23"] = "HoloFrame3",
}

local sVer = "1.3.1"
local sDummyText = "CC Alert"

function CCAlert:tableCopy(t)
	if type(t) == "table" then
		local copy = {}
		for k, v in next, t do
			copy[self:tableCopy(k)] = self:tableCopy(v)
		end
		return copy
	else
		return t
	end
end

function CCAlert:getKeyByValue(table, value)
	for k,v in pairs (table) do
		if v == value then
			return k
		end
	end
	return false
end

function CCAlert:round(num, digits)
	local mult = 10^(digits or 0)
	return math.floor(num * mult + .5) / mult
end

function CCAlert:new(o)

    o = o or {}
    setmetatable(o, self)
    self.__index = self

	self.tCCStates = tCCStates
	self.tFontList = tFontList
	self.tSpriteList = tSpriteList
	self.sVer = sVer
	self.sDummyText = sDummyText

	local nScreenWidth = Apollo.GetDisplaySize().nWidth
	local nScreenHeight = Apollo.GetDisplaySize().nHeight
	nScreenWidth = math.floor(nScreenWidth / 2 - 90)
	nScreenHeight = math.floor(nScreenHeight / 2)
	self.tSettingsDefault = {
		offsets = { nScreenWidth, nScreenHeight, nScreenWidth+288, nScreenHeight+56 }, -- l,t,r,b
		fontName = "CRB_HeaderGigantic_O",
		fontColor = { [1]=1, [2]=1, [3]=1, [4]=1 },
		spriteName = "UI_BK3_Holo_InsetFramed_Alert",
		alpha = 1,
		locked = true,
		weaponIndicator = true,
		sound = 0,
		showDuration = 4,
		ccState = {},
	}
	for k,v in pairs(self.tCCStates) do
		self.tSettingsDefault.ccState[k] = { enabled = v.enabled, priority = v.priority }
	end
	self.tSettings = self:tableCopy(self.tSettingsDefault)

	self.debug = "" -- /eval Print(Apollo.GetAddon("CCAlert").debug)

    return o

end

function CCAlert:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {
        -- "UnitOrPackageName",
    }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function CCAlert:OnLoad()
    self.xmlDoc = XmlDoc.CreateFromFile("CCAlert.xml")
    self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function CCAlert:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.alertWindow = Apollo.LoadForm(self.xmlDoc, "AlertWindow", "FixedHudStratum", self)
		self.settingsWindow = Apollo.LoadForm(self.xmlDoc, "SettingsWindow", "FixedHudStratum", self)
		self.settingsWindow:FindChild("LblTitle"):SetText(("%s %s"):format(self.sDummyText, self.sVer))
		self.weaponIndicatorWindow = Apollo.LoadForm(self.xmlDoc, "WeaponIndicatorWindow", nil, self)
	end

	if self.alertWindow == nil then
		Apollo.AddAddonErrorText(self, "ERROR: Could not load the main window.")
		return
	end

	Apollo.RegisterEventHandler("ApplyCCState", "OnCCApplied", self)
	Apollo.RegisterEventHandler("RemoveCCState", "OnCCRemove", self)

	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)

	Apollo.RegisterSlashCommand("cca", "OnSlashHandler", self)

	self.bIsDocLoaded = true

	self.ActiveCC = {}

	self.AlertWindowTimer = ApolloTimer.Create(0.1, true, "AlertWindow_OnTimer", self)

	self:InitControls()

	self:UpdateWindowPos() -- race condition: load default settings if OnRestore was not called
	self:UpdateSettings() -- race condition: load default settings if OnRestore was not called

end

------------------------------------
-- Main window
------------------------------------

function CCAlert:AlertWindow_Update(sText, bShow, tBarData)

	local width = Apollo.GetTextWidth(self.tSettings.fontName, sText) + 75
	local wndL,wndT,wndR,wndB = self.alertWindow:GetAnchorOffsets()
	self.alertWindow:SetAnchorOffsets(wndL,wndT,wndL + width,wndB)

	local durationBar = self.alertWindow:FindChild("CCDurationBar")
	local bBarShow = tBarData ~= nil
	if tBarData then
		durationBar:SetMax(tBarData.nTimeTotal)
		durationBar:SetProgress(tBarData.nTimeRemaining)
		durationBar:SetAnchorOffsets(20,43,width-20,48)
	end
	if bBarShow ~= durationBar:IsVisible() then
		durationBar:Show(bBarShow, true)
	end

	self.alertWindow:FindChild("AlertWindowText"):SetFont(self.tSettings.fontName)
	self.alertWindow:FindChild("AlertWindowText"):SetTextColor(self.tSettings.fontColor) -- GetTextColor method exist

	if self.alertWindow:FindChild("AlertWindowText"):GetText() ~= sText then
		self.alertWindow:FindChild("AlertWindowText"):SetText(sText)
	end

	if self.alertWindow:GetSprite() ~= self.tSettings.spriteName then
		self.alertWindow:SetSprite(self.tSettings.spriteName)
	end

	if self.alertWindow:GetBGOpacity() ~= self.tSettings.alpha then
		self.alertWindow:SetBGOpacity(self.tSettings.alpha)
	end

	if bShow ~= self.alertWindow:IsVisible() then
		self.alertWindow:Show(bShow,true)
	end

end

function CCAlert:AlertWindow_Close()
	self.alertWindow:FindChild("CCDurationBar"):Show(false,true)
	self.alertWindow:Show(false,true)
end

function CCAlert:AlertWindow_OnTimer()

	if not self:HasActiveCC() then
		self.AlertWindowTimer:Stop()
		return
	end

	local unitPlayer = GameLib.GetPlayerUnit()
	local effect = self:GetPriorityCC()
	local timeTotal = unitPlayer:GetCCStateTotalTime(effect.enum) or 0
	local timeRemaining = unitPlayer:GetCCStateTimeRemaining(effect.enum) or 0

	local bHasActiveCC = self:HasActiveCC()
	local bHasDuration = timeTotal > 0 and timeRemaining > 0
	local nShowDuration = self.tSettings.showDuration

	-- safe check for bHasActiveCC in case cc removed mid timer pulse
	if bHasActiveCC then

		-- never show or no duration
		if nShowDuration == 1 or not bHasDuration then

			self.AlertWindowTimer:Stop()
			self:AlertWindow_Update(effect.text, true)
			return

		-- need to show duration and has duration
		elseif nShowDuration > 1 and bHasDuration then

			local sTextNoDuration = effect.text
			local sTextShowDuration = ("%s %4.1f"):format(effect.text, timeRemaining)
			local tBarData = { nTimeTotal = timeTotal, nTimeRemaining = timeRemaining }

			if nShowDuration == 2 then -- text only
				self:AlertWindow_Update(sTextShowDuration, true, nil)
			elseif nShowDuration == 3 then -- bar only
				self:AlertWindow_Update(sTextNoDuration, true, tBarData)
			elseif nShowDuration == 4 then -- text and bar
				self:AlertWindow_Update(sTextShowDuration, true, tBarData)
			end

		end

	end

end

------------------------------------
-- Weapon Indicator Window
------------------------------------

function CCAlert:WeaponIndicatorWindow_Show(unit)

	if unit == nil or not unit:IsValid() then return end

	self.weaponIndicatorWindow:SetUnit(unit, 1)
	self.weaponIndicatorWindow:Show(true,true)

end

function CCAlert:WeaponIndicatorWindow_Close()
	self.weaponIndicatorWindow:Show(false,true)
end

------------------------------------
-- The Logic
------------------------------------

function CCAlert:OnCCApplied(code, unit)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	if not self.tSettings.locked then return end

	local effect = self.tCCStates[code]

	if unit == unitPlayer and effect and self.tSettings.ccState[code].enabled then

		self.ActiveCC[code] = true
		self.AlertWindowTimer:Start()

		-- Play sound
		local nSound = self.tSettings.sound or 0
		if nSound > 0 then
			Sound.Play(nSound)
		end

	end
end

function CCAlert:HasActiveCC()
	for k,v in pairs(self.ActiveCC) do
		return true
	end

	return false
end

function CCAlert:GetPriorityCC()
	local effect = { enum = -1, priority = 999, text = self.sDummyText }

	for k,v in pairs(self.ActiveCC) do

		local f = self.tSettings.ccState[k]
		if f.priority < effect.priority then
			effect.enum = k
			effect.priority = f.priority
			effect.text = self.tCCStates[k].text
		end

	end

	return effect
end

function CCAlert:OnCCRemove(code, unit)
	local unitPlayer = GameLib.GetPlayerUnit()
	if unitPlayer == nil or not unitPlayer:IsValid() then return end
	if not self.tSettings.locked then return end

	if unit == unitPlayer then

		self.ActiveCC[code] = nil
		local bHasActiveCC = self:HasActiveCC()

		if code == Unit.CodeEnumCCState.Subdue or code == Unit.CodeEnumCCState.Disarm then
			self:WeaponIndicatorWindow_Close()
		end

		if bHasActiveCC then

			self.AlertWindowTimer:Start()

		elseif not bHasActiveCC and self.alertWindow:IsVisible() then

			-- nothing to show, hiding window if visible
			self.AlertWindowTimer:Stop()
			self:AlertWindow_Close()

		end

	end
end

function CCAlert:OnChangeWorld()

	for k,v in pairs(self.ActiveCC) do
		self.ActiveCC[k] = nil
	end

	self.AlertWindowTimer:Stop()
	self:AlertWindow_Close()
	self:WeaponIndicatorWindow_Close()

end

function CCAlert:OnUnitCreated(unit)

	-- weapon indicator stuff
	-- RegisterEventHandler("UnitCreated") called in UpdateSettings()
	if unit:GetType() == "Pickup" then

		local playerName = GameLib.GetPlayerUnit():GetName()

		if string.sub(unit:GetName(), 1, string.len(playerName)) == playerName then
			self:WeaponIndicatorWindow_Show(unit)
		end

	end

end

------------------------------------
-- Save / Restore
------------------------------------

function CCAlert:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.tSettings.offsets = { self.alertWindow:GetAnchorOffsets() }

	return self.tSettings
end

function CCAlert:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	for settingsName,settingsValue in pairs(tSavedData) do
		self.tSettings[settingsName] = settingsValue
	end

	if self.bIsDocLoaded then -- race condition: updating settings, defaults were loaded in OnDocLoaded
		self:UpdateWindowPos()
		self:UpdateSettings()
	end
	self.bIsRestored = true
end

------------------------------------
-- Slash commands
------------------------------------

function CCAlert:AlertWindow_Toggle()
	local bLocked = not self.settingsWindow:FindChild("BtnLocked"):IsChecked()
	self.settingsWindow:FindChild("BtnLocked"):SetCheck(bLocked)
	self.tSettings.locked = bLocked
	self:AlertWindow_Update(self.sDummyText, not bLocked)
end

function CCAlert:ResetSettings()
	self.tSettings = self:tableCopy(self.tSettingsDefault)
	self:UpdateWindowPos()
	self:UpdateSettings()
	Print(("[%s] : default settings restored"):format(self.sDummyText))
end

function CCAlert:OpenConfig()
	self.tSettingsTemp = self:tableCopy(self.tSettings)
	self:UpdateSettings() -- is it needed ?
	self.settingsWindow:Invoke()
end

function CCAlert:OnSlashHandler(slash, arg)
	arg = arg:lower()
	if arg == "reset" then
		self:ResetSettings()
	elseif arg == "toggle" then
		self:AlertWindow_Toggle()
	elseif arg == "debug" then
		Print(("[%s] : %s"):format(self.sDummyText, self.debug))
	else
		self:OpenConfig()
	end
end

------------------------------------
-- Boilerplate
------------------------------------

local CCAlertInst = CCAlert:new()
CCAlertInst:Init()
