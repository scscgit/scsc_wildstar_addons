-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

local Addon = Apollo.GetAddon("CombatMeter")
if not Addon then return end

local _defaultSettings = Addon._defaultSettings
local _resetSettings = Addon._resetSettings

local _floor = math.floor
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
			local ot = v.strTable and o[v.strTable] or o
			local w = type(v.strControlName) == "string" and wo:FindChild(v.strControlName) or v.strControlName
			if nControlType == 1 or nControlType == 4 or nControlType == 7 then
				w:SetCheck(ot[k])
				if nControlType == 7 then
					w:GetParent():FindChild("Label"):SetCheck(ot[k])
				end
			elseif nControlType == 2 then
				w:SetValue(ot[k])
			elseif nControlType == 3 then
				w:FindChild("Color"):SetBGColor(ot[k])
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
		if self.OnSingleOptionsTab then
			self:OnSingleOptionsTab(w, bSelected)
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
		local n,s = wndControl:GetValue() or 0, v.nSliderPrec
		ot[v.sName] = s and (_floor(n * s) / s) or n
	elseif v.nControlType == 3 then
		local wc = self.wndOpts:FindChild("ColorEdit")
		local checked = wndControl:IsChecked()
		self:EditColorHide(wc)
		if checked then
			wc:SetData(v)
			wndControl:SetCheck(true)
			self:EditColorInvoke(wc, ot[v.sName], v.default)
		end
	elseif v.nControlType == 4 then
		ot[v.sName] = wndControl:GetParent():GetRadioSelButton(v.strControlGroup) == wndControl
	elseif v.nControlType == 6 then
		ot[v.sName] = tonumber(wndControl:GetText()) or v.default
	end
	if v.fnCallback and v.nControlType ~= 3 then
		self[v.fnCallback](self, v)
	end
end

function Addon:OnSingleEditColor(wndHandler, wndControl, arColor)			-- edit form callback on value change
	local o,wo = self.userSettings, self.wndOpts
	local v = wndControl:GetData()

	local ca = o[v.sName]
	ca[1],ca[2],ca[3] = arColor[1],arColor[2],arColor[3]

	local w = wo:FindChild(v.strControlName)
	w:FindChild("Color"):SetBGColor(ca)

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
	local o,wo,v = self.userSettings, self.wndOpts, wndControl:GetData()
	if type(v) ~= "table" then
		return
	end

	local ot = v.strTable and o[v.strTable] or o
	if v.nControlType == 3 then
		if v.strControlName then
			wo:FindChild(v.strControlName):SetCheck(false)
		end
	elseif v.nControlType == 8 then
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

function Addon:SetEmbedButtonEnabled(wndControl, bState, bDisable)
	wndControl:SetBGColor(bState and "white" or "UI_AlphaPercent60")
	local w = wndControl:FindChild("Label")
	w:SetTextColor(bState and "white" or "UI_BtnTextHoloNormal")
	--w:SetTextColor(bState and "UI_BtnTextHoloNormal" or "white")--UI_BtnTextHoloNormal")
	w:SetOpacity(bState and 1 or .85, 20000)
	if bDisable then
		wndControl:Enable(bState)
	end
end

function Addon:SetPlateButtonEnabled(wndControl, bState, bDisable)
	wndControl:SetBGColor(bState and "white" or "UI_AlphaPercent60")
	--wndControl:GetParent():FindChild("Label"):SetOpacity(bState and 1 or .50, 20000)
	local w = wndControl:GetParent():FindChild("Label")
	w:SetNormalTextColor(bState and "UI_BtnTextHoloNormal" or (not bDisable and "UI_TextHoloBodyCyan" or "UI_BtnTextHoloDisabled"))
	w:SetPressedTextColor(bState and "UI_BtnTextHoloPressed" or (not bDisable and "UI_TextHoloBody" or "UI_BtnTextHoloDisabled"))
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


-- drop choice

function Addon:OnDropCheck(wndHandler, wndControl, eMouseButton)
	local wo,v = wndControl:GetParent(), wndControl:GetData()
	local woChoices = wo:FindChild(v.strChoicesName)
	woChoices:SetData(v)
	woChoices:Show(true)					-- show the list
end

function Addon:OnDropUncheck(wndHandler, wndControl, eMouseButton)
	local wo,v = wndControl:GetParent(), wndControl:GetData()
	local woChoices = wo:FindChild(v.strChoicesName)
	woChoices:SetData(v)
	woChoices:Show(false)					-- show the list
end

function Addon:OnDropListHide(wndHandler, wndControl)
	local o,wo,v = self.userSettings, wndControl:GetParent(), wndControl:GetData()
	local woScroll = v.woChoiceScroll
	if not woScroll then return end

	wo:FindChild(v.strControlName):SetCheck(false)				-- uncheck drop buttons

	woScroll:DestroyChildren()									-- uncheck any known list selections
	v.woChoiceScroll = nil

	for i,v in ipairs(self[v.sChoices]) do						-- clear options by reference window handles
		local _d = v.sOptionName and _defaultSettings[v.sOptionName]
		if type(_d) == "table" then _d.strControlName = nil end
	end
end

function Addon:OnDropListShow(wndHandler, wndControl)
	local o,wo,_d,L = self.userSettings, wndControl:GetParent(), wndControl:GetData(), self.L
	local woScroll = _d.woChoiceScroll
	if woScroll then return end

	local woScroll = wndControl:FindChild("Scroll")
	_d.woChoiceScroll = woScroll

	local aName,nPos,bCheck = o[_d.sName], 0, _d.nControlType == 10
	for i,v in ipairs(self[_d.sChoices]) do
		local w = Apollo.LoadForm(self.xmlDoc, bCheck and "DropCheckItem" or "DropChoiceItem", woScroll, self)
		local t = v.sOptionName and _defaultSettings[v.sOptionName]
		if type(t) == "table" then t.strControlName = w end
		w:SetData(v)
		w:SetData(bCheck and _defaultSettings[v.sOptionName] or v)
		w:SetText(L[v.sSettingsName])
		w:SetTooltip(v.sTooltip or "")
		if v.sSettingsName == aName then
			w:SetCheck(true)
			nPos = (i - 1) * w:GetHeight()
			if nPos < woScroll:GetHeight() then
				nPos = 0
			end
		end
	end

	if bCheck then
		self:OnPanelForm(wndControl, _d.sName)				-- common startup, initialize controls for settings
		self:OnCurrentToPanel(wndControl, _d.sName)			-- common startup, load settings to controls
	end

	local nHeight = woScroll:ArrangeChildrenVert()
	if bCheck then
		local nLeft, nTop, nRight, nBottom = wndControl:GetAnchorOffsets()
		nHeight = nHeight - _abs(nBottom - nTop)
		nLeft, nTop, nRight, nBottom = wndControl:GetAnchorOffsets()
		wndControl:SetAnchorOffsets(nLeft, nTop, nRight, (nBottom + nHeight) + 10)
	else
		woScroll:SetVScrollPos(nPos)
	end
end

function Addon:OnDropPick(wndHandler, wndControl, eMouseButton)
	local o,woChoices,L = self.userSettings, wndControl:GetParent():GetParent(), self.L
	local v,_d = wndControl:GetData(), woChoices:GetData()

	o[_d.sName] = v.sSettingsName

	woChoices:Close()

	local wo = woChoices:GetParent()
	wo:FindChild(_d.strControlName):SetText(L[v.sSettingsName])

	if _d.fnCallback then
		self[_d.fnCallback](self, _d)
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


-----------------------------------------------------------------------------------------------
-- Compression
-----------------------------------------------------------------------------------------------

function Addon:EnsureCompress(bClear)
	local o = self.userSettings

	if bClear or not o.tCompKeys then
		o.tCompKeys, o.tCompValues, o.tCompSchemas = {}, {}, {}
	end

	if not self.tCompKeysR then
		local t = {}; self.tCompKeysR = t
		for i,k in ipairs(o.tCompKeys) do
			t[k] = i
		end

		t = {}; self.tCompValuesR = t
		for i,k in ipairs(o.tCompValues) do
			t[k] = i
		end

		t = {}; self.tCompSchemasR = t
		for i,k in ipairs(o.tCompSchemas) do
			t[k] = i
		end
	end
end

function Addon:EnsureSchema(schema)
	local o = self.userSettings
	local ck,cs = o.tCompKeys, o.tCompSchemas
	local ckr,csr = self.tCompKeysR, self.tCompSchemasR

	local function _sort(a,b)		-- need a consistant order if really want to apply across all rows
		local n,m = type(a) == "number", type(b) == "number"
		if n and m then
			return a < b
		end
		if n or m then
			return n
		end
		return a < b
	end

	local count,keys,id = 0, {}
	for i,v in next, schema do		-- sort keys
		count = count + 1
		keys[count] = v
	end
	_tsort(keys, _sort)
	count = #ck

	local sKeys = ""				-- build compressed schema
	for i,v in ipairs(keys) do
		id = ckr[v]
		if not id then
			count = count + 1
			ck[count] = v			-- store keys
			ckr[v] = count
			id = count
		end
		sKeys = sKeys .. (i==1 and "" or ";") .. tostring(id)
	end
	id = csr[sKeys]					-- add to schemas list
	if not id then
		id = #cs + 1
		cs[id] = sKeys
		csr[sKeys] = id
	end

	return id, keys
end

function Addon:ExpandSchemaKeys(nSchema)
	local o = self.userSettings
	local ck,cs = o.tCompKeys, o.tCompSchemas

	local count,keys = 0, {}							-- expand keys
	for v in (cs[nSchema] or ""):gmatch("([^;]+)") do		-- add values
		count = count + 1
		keys[count] = ck[tonumber(v) or 0] or ("_" .. count)
	end

	return keys
end

function Addon:CompressRow(t, keys)			-- t is source table, returns compressed row
	local o = self.userSettings
	local cv,cvr = o.tCompValues, self.tCompValuesR

	local row
	local count = #cv

	for _,k in ipairs(keys) do
		local v = t[k]

		if not v then
			v = ""
		elseif type(v) == "boolean" then
			v = v and "+" or "-"
		elseif type(v) == "string" then
			local s = v
			v = cvr[v]
			if not v then
				count = count + 1
				cv[count] = s
				cvr[s] = count
				v = count
			end
			v = "+" .. v
		else
			v = tostring(v) or ""
		end

		row = row and (row .. ";" .. v) or v
	end

	return row
end

function Addon:UncompressRow(t, row, keys, b)			-- t is dest table, row is compressed row 
	local o = self.userSettings
	local cv = o.tCompValues

	local count = 0

	for v in (row..";"):gmatch("([^;]*);") do		-- add values
		count = count + 1
		local k = keys[count]

		if v == "+" or v == "-" then
			v = v == "+" and true or false
		elseif v:byte(1) == 43 then					-- 43 is '+'
			v = cv[tonumber(v)]
		else
			v = tonumber(v) or nil
		end

		if b or v ~= nil then
			t[k] = v
		end
	end

	return t
end

function Addon:CompressRowInline(t, keys)			-- t is source table, returns compressed row
	for i,k in ipairs(keys) do
		t[i] = t[k] or ""
	end
	return table.concat(t, ";")
end

function Addon:UncompressRowInline(t, row, keys)	-- t is dest table, row is compressed row
	local count = 0

	for v in (row..";"):gmatch("([^;]*);") do	--FIXME: replace so dont have to create another string, classic Lua split issue
		count = count + 1
		v = tonumber(v)

		if v then
			t[keys[count]] = v
		end
	end

	return t
end
