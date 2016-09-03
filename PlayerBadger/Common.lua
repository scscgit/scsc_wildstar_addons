-----------------------------------------------------------------------------------------------
-- Client Lua Script for PlayerBadger
-- Copyright Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

local Addon = Apollo.GetAddon("PlayerBadger")
if not Addon then return end

local _defaultSettings = Addon._defaultSettings
local _resetSettings = Addon._resetSettings

local _floor = math.floor
local _sqrt = math.sqrt
local _abs = math.abs
local _format = string.format
local _len = string.len
local _tsort = table.sort

local _print = Addon._print


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function Addon:NewLocale(lc, default)
	local L,s = self.L, Apollo.GetString(1)
	if (s == "Annuler" and "frFR" or (s == "Abbrechen" and "deDE" or "enUS")) == lc then return L,self end

	if default then
		self.Ldefault = setmetatable({}, getmetatable(L))
		setmetatable(L, { __index = self.Ldefault })
		return self.Ldefault,self
	end
end


-----------------------------------------------------------------------------------------------
-- OptionsForm Form Functions
-----------------------------------------------------------------------------------------------

function Addon:OnPanelForm(wo, ePanel)

	for k,v in pairs(_defaultSettings) do
		if type(v) == "table" and v.ePanel == ePanel and v.strControlName then
			v.sName = k
			local s = v.strControlName
			;(type(s) == "string" and wo:FindChild(s) or s):SetData(v)
		end
	end
end

function Addon:OnCurrentToPanel(wo, ePanel)
	local o = self.userSettings

	-- Generic managed controls
	for k,v in pairs(_defaultSettings) do
		if type(v) == "table" and v.nControlType and v.ePanel == ePanel then
			local nControlType = type(v) == "table" and v.nControlType or nil
			local w = type(v.strControlName) == "string" and wo:FindChild(v.strControlName) or v.strControlName
			local ot = v.strTable and o[v.strTable] or o
			if nControlType == 1 or nControlType == 4 or nControlType == 7 then
				w:SetCheck(ot[k])
				if nControlType == 7 then
					w:GetParent():FindChild("Label"):SetCheck(ot[k])
				end
			elseif nControlType == 2 then
				w:SetValue(ot[k])
			elseif nControlType == 6 then
				w:SetText(ot[k])
			elseif nControlType == 9 then
				w:SetText(self.L[ot[k]])
			end
		end
	end
end

function Addon:OnOptionsTabCheck(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
	if wndHandler == wndControl then
		return
	end
	local wo = self.wndOpts

	for k,v in pairs(self._tOptionsTabs) do
		local w = wo:FindChild(k)

		local bSelected = w == wndControl
		if bSelected then
			self.sOptionsTab = w:GetName()
		end
		wo:FindChild(v):Show(bSelected)
	end
end

function Addon:OnSingleEdit(wndHandler, wndControl, strText)
	local o,wo = self.userSettings, self.wndOpts

	if strText and (_len(strText) > 2 or strText:match("[^0-9]")) then		-- validate as number atm
		return
	end
	self:OnSingleCheck(wndHandler, wndControl, strText)
end

function Addon:OnSingleCheck(wndHandler, wndControl, eMouseButton)
	local o,v = self.userSettings, wndControl:GetData()
	if type(v) ~= "table" then
		return
	end

	local ot = v.strTable and o[v.strTable] or o
	if v.nControlType == 1 or v.nControlType == 7 then
		ot[v.sName] = wndControl:IsChecked()
		if v.nControlType == 7 then
			wndControl:GetParent():FindChild("Label"):SetCheck(ot[v.sName])
		end
	elseif v.nControlType == 2 then
		ot[v.sName] = wndControl:GetValue() or 0
	elseif v.nControlType == 4 then
		ot[v.sName] = wndControl:GetParent():GetRadioSelButton(v.strControlGroup) == wndControl
	elseif v.nControlType == 6 then
		ot[v.sName] = tonumber(wndControl:GetText()) or v.default
	end
	if v.fnCallback then
		self[v.fnCallback](self, v)
	end
end

function Addon:OnSingleSignal(wndHandler, wndControl, eMouseButton, bWat)
	local o,v = self.userSettings, wndControl:GetData()
	if type(v) ~= "table" then
		return
	end
	if v.fnCallback then
		self[v.fnCallback](self, v)
	end
end

function Addon:OnSingleSignalCancel(wndHandler, wndControl, eMouseButton, bWat)
	local o,v = self.userSettings, wndControl:GetData()
	if type(v) ~= "table" then
		return
	end

	local ot = v.strTable and o[v.strTable] or o
	if v.nControlType == 8 then
		wndControl:SetCheck(ot[v.sName])	-- mitigate carbine bug. dont allow a canceled signal to change the state
	end
end

function Addon:SetPushButtonEnabled(wndControl, bState, bDisable)					-- allow boxes to keep and show state, even if option isn't currently meaningful
	wndControl:SetBGColor(bState and "UI_WindowBGDefault" or "UI_AlphaPercent60")	--   carbine disable clears state. endless user confusion
	wndControl:SetNormalTextColor(bState and "UI_BtnTextHoloNormal" or "UI_TextHoloBody")	--or "UI_BtnTextHoloDisabled"
	if bDisable then																-- really disable
		wndControl:Enable(bState)
	end
end

function Addon:SetButtonEnabled(wndControl, bState, bDisable)						-- allow boxes to keep and show state, even if option isn't currently meaningful
	wndControl:SetBGColor(bState and "white" or "UI_AlphaPercent50")				--   carbine disable clears state. endless user confusion
	wndControl:SetTextColor(bState and "UI_BtnTextBlueNormal" or "UI_TextHoloBodyCyan")		--or "UI_BtnTextHoloDisabled"
	if bDisable then																-- really disable
		wndControl:Enable(bState)
	end
end

function Addon:SetLittleButtonEnabled(wndControl, bState, bDisable)
	wndControl:SetBGColor(bState and "white" or "UI_AlphaPercent50")
	wndControl:FindChild("Label"):SetTextColor(
		bState and "UI_BtnTextBlueNormal" or (not bDisable and "UI_TextHoloBodyCyan" or "UI_BtnTextHoloDisabled"))
	if bDisable then
		wndControl:Enable(bState)
	end
end

function Addon:SetControlOffset(wndControl, b, left, top, right, bottom)
	local _l, _t, _r, _b = wndControl:GetOriginalLocation():GetOffsets()
	if b then
		wndControl:SetAnchorOffsets(_l + left, _t + top, _r + right, _b + bottom)
	else
		wndControl:SetAnchorOffsets(_l, _t, _r, _b)
	end
end


-- reset choice

function Addon:OnResetDropCheck(wndHandler, wndControl, eMouseButton)
	local wo = self.wndOpts
	wo:FindChild("ChoiceContainer"):Show(true)					-- show the list
end

function Addon:OnResetDropUncheck(wndHandler, wndControl, eMouseButton)
	local wo = self.wndOpts
	wo:FindChild("ChoiceContainer"):Show(false)					-- show the list
end

function Addon:OnResetListHide()
	local o,wo,woScroll = self.userSettings, self.wndOpts, self.woChoiceScroll
	if not woScroll then return end

	wo:FindChild("ResetDropToggle"):SetCheck(false)				-- uncheck drop buttons

	woScroll:DestroyChildren()									-- uncheck any known list selections
	self.woChoiceScroll = nil
end

function Addon:OnResetListShow()
	local o,wo,woScroll = self.userSettings, self.wndOpts, self.woChoiceScroll
	if woScroll then return end

	local woScroll = wo:FindChild("ResetScroll")
	self.woChoiceScroll = woScroll

	local sName, nPos = o.sSettingsName, 0
	for i,v in ipairs(_resetSettings) do
		local w = Apollo.LoadForm(self.xmlDoc, "ChoiceResetItem", woScroll, self)
		w:SetData(v)
		w:SetText(v.sSettingsName)
		w:SetTooltip(v.sSettingsTooltip or "")
		if v.sSettingsName == sName then
			w:SetCheck(true)
			nPos = (i - 1) * w:GetHeight()
			if nPos < woScroll:GetHeight() then
				nPos = 0
			end
		end
	end

	woScroll:ArrangeChildrenVert()
	woScroll:SetVScrollPos(nPos)
end

function Addon:OnResetPick(wndHandler, wndControl, eMouseButton)
	local o,wo = self.userSettings, self.wndOpts

	local v = wndControl:GetData()
	o.sSettingsName = v.sSettingsName

	wo:FindChild("ChoiceContainer"):Close()

	self:OnReset()
end

function Addon:OnResetSave()
	local o = self.userSettings

	local t = o.tSettingsCustom												-- diff current settings with defaults
	o.sSettingsName = t.sSettingsName										-- should be same as base

	for k,v in pairs(t) do t[k] = nil end
	for k,v in next, _defaultSettings do
		if type(v) == "table" and v.nControlType then v = v.default end
		if (o[k] ~= v or k == "nSettingsVersion") and k ~= "tSettingsCustom" then -- not the same value and not reentrant
			t[k] = o[k]
		end
	end
	self:OnReset()															-- just loop it through a reload to make sure all state is in sync
end

function Addon:OnReset()
	local o = self.userSettings
	self:OnCommand(nil, "reset " .. o.sSettingsName)
end

