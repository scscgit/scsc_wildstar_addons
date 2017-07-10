-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

local CombatMeter = Apollo.GetAddon("CombatMeter")
if not CombatMeter then return end

local _tModes = CombatMeter._tModes

local _floor = math.floor

local _print = CombatMeter._print

local DeepCopy = CombatMeter.DeepCopy


-----------------------------------------------------------------------------------------------
-- Options Form Functions
-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-- ReportForm Form Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:OnCloseReportWindow(wndHandler)
	wndHandler:Close()
end

function CombatMeter:OnReportCancel(wndHandler, wndControl)
	self:OnCloseReportWindow(wndHandler:GetParent())
end

function CombatMeter:OnReportOK(wndHandler, wndControl)
	self._bReportCommitting = true
	local o,wo = self.userSettings, wndHandler:GetParent()
	o.sReportChannel = wo:FindChild('Channel'):GetText()
	o.sReportTarget = wo:FindChild('Target'):GetText()
	o.nReportLines = tonumber(wo:FindChild('Lines'):GetText())
	self:OnCloseReportWindow(wo)
end

function CombatMeter:OnReportClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local o,wo,L = self.userSettings, wndHandler, self.L
	local panel = wo:GetData()

	if wo and wo:IsValid() then
		wo:SetData(nil)
		wo:Close()
		wo:Destroy()
	end
	if self._bReportCommitting then
		self:OnReportFormGenerate(panel)
		self._bReportCommitting = false
	end
	--self:OnCurrentToMain()
end

function CombatMeter:OnReportForm(panel)
	local wo = Apollo.LoadForm(self.xmlDoc, "ReportForm", nil, self)

	wo:SetData(panel)

	self:OnCurrentToReport(wo)
	wo:Invoke()
end

function CombatMeter:OnCurrentToReport(wo)
	local o = self.userSettings

	-- Generic managed controls
	--self:OnCurrentToPanel(wo)
	wo:FindChild('Channel'):SetText(o.sReportChannel or "s")
	wo:FindChild('Target'):SetText(o.sReportTarget or "none")
	wo:FindChild('Lines'):SetText(o.nReportLines or "5")
end

function CombatMeter:OnReportFormGenerate(panel)
	local o = self.userSettings

	local oMode = panel.oMode
	if not oMode then
		oMode = _tModes.interactionAbilities
	end

	local tText = oMode:GetReportText(panel)
	local sChannel, sTarget = --, nLines =
		o.sReportChannel, o.sReportTarget --, o.nReportLines

	sTarget = (sTarget and (sChannel == 'whisper' or sChannel == 'tell' or sChannel == 'w' or sChannel == 't'))
		and (sTarget .. " ") or ""
	sChannel = (sChannel and ("/" .. sChannel) or "/none") .. " " .. sTarget
	for i,v in ipairs(tText or {}) do
		ChatSystemLib.Command(sChannel .. v)	-- /channel target text
	end
end


-----------------------------------------------------------------------------------------------
-- Tooltip Form
-----------------------------------------------------------------------------------------------

function CombatMeter:TooltipShow(text, anchor, bAML)
	local o,tooltip = self.userSettings, self.wndTooltip

	if not o.bShowTooltips or not text or text == "" then
		return
	end
	if not tooltip then
		tooltip = Apollo.LoadForm(CombatMeter.xmlDoc, "Tooltip", nil, CombatMeter)
		self.wndTooltip = tooltip
	end
	local tooltipText = tooltip:FindChild("TooltipText")

	local w,h = 0, 0
	if bAML then
		tooltipText:SetAML(text)

		tooltip:SetAnchorOffsets(0, 0, 500, 100)
		local nTextWidth,nTextHeight = tooltipText:SetHeightToContentHeight()
		w,h = nTextWidth + 14, --+ 20,
			nTextHeight + 10 --+ 16
	else
		tooltipText:SetText(text)

		local nTextWidth = Apollo.GetTextWidth("Default", text)
		w,h = nTextWidth + 13, 27 --16, 30
	end

	local m = Apollo.GetMouse()
	local x,y = m.x, m.y - 15
	local ow,oh = 0, 0
	if anchor then
		local m = anchor:GetMouse()
		x = x - m.x
		ow = anchor:GetWidth()
	end

	local e = Apollo.GetDisplaySize()
	local u,v = e.nWidth, e.nHeight

	local l, t, r, b = (x + ow + 6), y, (x + ow + 6) + w, y + h
	if r > u then
		l, t, r, b = x - w - 6, y, x - 6, y + h
	end

	tooltip:Show(true)
	tooltip:SetAnchorOffsets(l, t, r, b)
	tooltip:ToFront()
end

function CombatMeter:TooltipHide()
	local tooltip = self.wndTooltip
	if tooltip then
		tooltip:Show(false)
	end
end


-----------------------------------------------------------------------------------------------
-- ColorEdit Form
-----------------------------------------------------------------------------------------------

function CombatMeter:OnEditColorCancel(wndControl)
	self:EditColorHide(wndControl:GetParent():GetParent())
end

function CombatMeter:EditColorHide(wndControl)
	self.bIsColorEditPush = true

	wndControl:Show(false)
	self._arColorEditRgbControls = nil
	self.bIsColorEditPush = nil
end

function CombatMeter:EditColorInvoke(wndControl, tValue, tDefault)
	tValue, tDefault = DeepCopy(tValue), DeepCopy(tDefault)

	self._arColorEditRgbControls = self._arColorEditRgbControls
		or { "R_EditBox", "G_EditBox", "B_EditBox" }

	wndControl:FindChild("ResetButton"):SetData(tValue)
	wndControl:FindChild("DefaultButton"):SetData(tDefault)

	self:EditColorSet(wndControl, tValue, "Invoke")

	wndControl:Show(true)
end

function CombatMeter:EditColorSet(wndControl, arColor, sSource)
	if self.bIsColorEditPush or not arColor then return end
	self.bIsColorEditPush = true

	local ca,ch = arColor, ""								-- color hex
	for i,v in ipairs(self._arColorEditRgbControls) do
		local n = _floor(arColor[i] * 100000 + .5) / 100000	-- compress and clear float error
		arColor[i] = n
		n = _floor(n * 255 + .5)
		local w = wndControl:FindChild(v)					-- rewrite em all, clear degredation
		local t = w:GetSel(); w:SetText(tostring(n)); w:SetSel(t.cpCaret, t.cpCaret)
		ch = ch .. string.format("%02X", n);
	end

	if sSource ~= "ColorPicker" then						-- dont micro-fight slider
		wndControl:FindChild("ColorPicker"):SetColor(arColor)
	end
	if sSource ~= "RGB_EditBox" then						-- dont overwite edits in longer box
		wndControl:FindChild("RGB_EditBox"):SetText(ch)
	end
	if sSource ~= "Invoke" then								-- dont degrade source value if no changes
		self:OnSingleEditColor(wndHandler, wndControl, arColor)		-- callback, let the host respond to color change
	end
	self.bIsColorEditPush = nil
end

function CombatMeter:OnEditColorChanged(wndHandler, wndControl, tColor)
	if self.bIsColorEditPush then return end
	local wc = wndControl:GetParent()

	local ca = { tColor.R, tColor.G, tColor.B, 1 }			-- color array
	self:EditColorSet(wc, ca, "ColorPicker")
end

function CombatMeter:OnEditColorPonentChanged(wndHandler, wndControl, strText)
	if self.bIsColorEditPush then return end
	local wc = wndControl:GetParent():GetParent()

	local ca = { 1, 1, 1, 1 }
	for i,v in ipairs(self._arColorEditRgbControls) do
		local n = tonumber((wc:FindChild(v):GetText():gsub("%D", ""))) or 0
		ca[i] = n >= 255 and 1 or n <= 0 and 0 or n / 255
	end
	self:EditColorSet(wc, ca)
end

function CombatMeter:OnEditColorPositeChanged(wndHandler, wndControl, strText)
	if self.bIsColorEditPush then return end
	local wc = wndControl:GetParent():GetParent()

	local ca,ch = { 1, 1, 1, 1 }, strText
	for i,v in ipairs(ca) do								-- clean em all, clear degredation
		local n = tonumber((ch:sub(i*2-1, i*2)), 16) or 0
		ca[i] = n >= 255 and 1 or n <= 0 and 0 or n / 255
	end
	self:EditColorSet(wc, ca, "RGB_EditBox")
end

function CombatMeter:OnEditColorReset(wndHandler, wndControl, eMouseButton)
	local wc,ca = wndControl:GetParent(), wndControl:GetData()

	self:EditColorSet(wc, ca)
end

function CombatMeter:OnEditColorHide(wndHandler, wndControl)
	self.bIsColorEditPush = true
	self:OnSingleSignalCancel(wndHandler, wndControl)		-- callback, let the host repond to form close
	self.bIsColorEditPush = nil
end


-----------------------------------------------------------------------------------------------
-- Notice Form
-----------------------------------------------------------------------------------------------

function CombatMeter:OnCloseNotice()
	self.wndNotice:Close()
end

function CombatMeter:OnNoticeCancel()
	self:OnCloseNotice()
end

function CombatMeter:OnNoticeClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local wo = self.wndNotice
	if wo and wo:IsValid() then
		wo:Close()
		wo:Destroy()
	end
	self.wndNotice = nil
end

function CombatMeter:OnNoticeForm()
	local o,ipa = self.userSettings, self.arPanels
	if self.wndNotice then
		return
	end

	local panel = ipa[1]
	if panel and panel.w then 
		local wo = Apollo.LoadForm(self.xmlDoc, "NoticeForm", panel.w, self)
		self.wndNotice = wo

		wo:Invoke()
	end
end

