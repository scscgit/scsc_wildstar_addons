-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. All rights reserved.
-----------------------------------------------------------------------------------------------

local CombatMeter = Apollo.GetAddon("CombatMeter")
if not CombatMeter then return end

local _AddonName = CombatMeter._AddonName
local _defaultPanelSettings = CombatMeter._defaultPanelSettings

local _floor = math.floor
local _abs = math.abs
local _tremove = table.remove
local _max = math.max

local _print = CombatMeter._print

local DeepCopy = CombatMeter.DeepCopy

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local _nFillHoverOpacity = 0.9
local _nTextHoverOpacity = 1.0

-----------------------------------------------------------------------------------------------
-- Panel Layout Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:UpdatePanelLayout(panel)
	local w,ow = panel.w, panel.settings
	if self.bInLayout or not w then
		return
	end
	self.bInLayout = true

	local left,top,right,bottom = w:GetAnchorOffsets()
	local _right,_bottom = right, bottom

	local widthNow, heightNow, nDisplayRowsNow, nRowWidthNow =
		_abs(left - right), _abs(bottom - top), ow.nDisplayRows, panel.nRowWidth
	local width, height, nDisplayRows, nRowWidth = widthNow, heightNow, nDisplayRowsNow, nRowWidthNow

	-- adjust height
	local nRowHeight = ow.nRowHeight
	nDisplayRows = _floor((height - 45) / (nRowHeight + 1) + .5)		-- adjust number of rows for height
	nDisplayRows = nDisplayRows < 1 and 1 or nDisplayRows
	height = nDisplayRows * (nRowHeight + 1) + 45					-- adjust height to fit for number of rows

	-- adjust width
	width = _max(width, 10)
	nRowWidth = _max(width - 2, 1)

	-- save
	ow.nDisplayRows = nDisplayRows
	ow.nWidth = width

	-- set
	if width ~= widthNow then
		right = right + (width - widthNow)
	end
	if height ~= heightNow then
		bottom = bottom + (height - heightNow)
	end
	if right ~= _right or bottom ~= _bottom or bMustSet then
		w:SetAnchorOffsets(left, top, right, bottom)
	end
	if nRowWidth ~= nRowWidthNow then

	end
	if nDisplayRows ~= nDisplayRowsNow then
		panel:EnsureRows(nDisplayRows)
		panel:Update()						-- force immediate update, only number of rows requires immediate update now
	end

	self.bInLayout = nil
end


-----------------------------------------------------------------------------------------------
-- Panel Form Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:OnButtonClose(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local w = wndControl:GetParent():GetParent()

	self:ClosePanel(w)
end

function CombatMeter:OnButtonOpen(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local w = wndControl:GetParent():GetParent()

	self:OpenPanel(w)
end

function CombatMeter:OnFrameMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetData()

	panel._bMouseEnter = true
	panel._bMouseExit = nil
	panel:SetMouseOpacity(1)
end

function CombatMeter:OnFrameMouseExit(wndHandler, wndControl)
	local o = self.userSettings
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetData()

	panel._bMouseExit = true
end

function CombatMeter:OnHeaderMouseEnter(wndHandler, wndControl)		-- header and footer
	if wndHandler ~= wndControl then
		self:TooltipShow(self._tLButtonTooltips[wndControl:GetName()], wndControl)
		return
	end
end

function CombatMeter:OnHeaderMouseExit(wndHandler, wndControl)		-- header and footer
	if wndHandler ~= wndControl then
		self:TooltipHide()
		return
	end
end

function CombatMeter:OnHeaderButtonDown(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
	local o = self.userSettings
	if wndHandler ~= wndControl or eMouseButton ~= 0 or (o.bLockWindows and not Apollo.IsControlKeyDown()) then
		return
	end
	local panel = wndHandler:GetParent():GetData()

	panel.tMoveMouse = panel.header:GetMouse()
end

function CombatMeter:OnHeaderButtonUp(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetParent():GetData()

	if eMouseButton == 0 then			-- left up
		panel.tMoveMouse = nil
	elseif eMouseButton == 1 then		-- right up
		panel:SetMode("modes")
	end
end

function CombatMeter:OnHeaderMouseMove(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
	if wndHandler ~= wndControl or self._bWindowSizing then
		return
	end
	local panel = wndHandler:GetParent():GetData()
	if not panel.tMoveMouse then
		return
	end
	self._bWindowSizing = true

	local mstart = panel.tMoveMouse
	local m = panel.header:GetMouse()
	local x,y = m.x - mstart.x, m.y - mstart.y

	local w = panel.w
	local r,t,l,b = w:GetAnchorOffsets()
	w:SetAnchorOffsets(r + x, t + y, l + x, b + y)

	self:OnWindowMove(w, w)											-- run as though a regular WindowMove event occured

	self._bWindowSizing = nil
end

function CombatMeter:OnWindowSizeChanged(wndHandler, wndControl)	-- called on WindowMove event
	if wndHandler ~= wndControl or self._bWindowSizing then
		return
	end
	local panel = wndHandler:GetData()
	if not panel or panel.bInLayout or panel.tMoveMouse then
		return
	end
	self._bWindowSizing = true

	local w = panel.w
	local l,t,r,_ = w:GetAnchorOffsets()
	w:SetAnchorOffsets(l, t, r, t + w:GetMouse().y)

	self:OnWindowMove(w, w)											-- run as though a regular WindowMove event occured

	panel._bFooterButtonDown = nil

	self._bWindowSizing = nil
end

function CombatMeter:OnButtonReport(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetParent():GetParent():GetData()

	self:OnReportForm(panel)
end

function CombatMeter:OnButtonPin(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel,combat = wndHandler:GetParent():GetParent():GetData(), self:GetCurrentCombat()

	panel:SetMode("combat", combat)
end

function CombatMeter:OnButtonPlayers(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetParent():GetParent():GetData()

	panel.bShowEnemies = not panel.bShowEnemies

	panel:SettingsToCurrent()
	panel:Update()							-- force immediate update
end

function CombatMeter:OnButtonFilter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetParent():GetParent():GetData()

	panel.bFilterOn = not panel.bFilterOn
	if panel.bFilterOn then											-- open up window with mobs we have fought,
		--panel:SetMode(panel.tCombat and "targets" or "combats")	--   pick a mob, and go back to normal dmg window, but only with dmg to that mob
	end
	self:OnCurrentToMain()
end

function CombatMeter:OnBackgroundButtonUp(wndHandler, wndControl, eMouseButton)
	local panel = wndHandler:GetParent():GetData()
	local mode = panel.oMode

	local func
	if eMouseButton == 1 then
		func = mode.OnRightClick
	elseif eMouseButton == 4 then
		func = mode.OnMouse4Click
	elseif eMouseButton == 5 then
		func = mode.OnMouse5Click
	end

	if func then
		func(mode, panel)
	end
end

function CombatMeter:OnBackgroundScroll(wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY, fScrollAmount, bConsumeMouseWheel)
	local panel = wndHandler:GetParent():GetData()

	local nScrollOffset = panel.nScrollOffset

	if fScrollAmount > 0 then
		nScrollOffset = nScrollOffset > 0 and nScrollOffset - 1 or 0
	else
		local nMax = (panel.nData or 0) - panel.settings.nDisplayRows
		nScrollOffset = nMax < 1 and 0 or nScrollOffset < nMax and nScrollOffset + 1 or nMax
	end

	if nScrollOffset ~= panel.nScrollOffset then
		panel.nScrollOffset = nScrollOffset
		panel.bScrolled = true
		panel:Update()						-- force immediate update
	end

	return true
end

function CombatMeter:OnRowButtonUp(wndHandler, wndControl, eMouseButton)
	if wndHandler ~= wndControl then
		return
	end
	local panel,row = wndHandler:GetParent():GetParent():GetData(), wndControl:GetData()
	local mode = panel.oMode

	local func
	if eMouseButton == 0 then
		func = mode.OnLeftClick
	elseif eMouseButton == 2 then
		func = mode.OnMiddleClick
	--elseif eMouseButton == 1 then
	--	func = mode.OnRightClick
	end
	if func then
		func(mode, panel, row)
	end
end

function CombatMeter:OnRowMouseEnter(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel,row = wndHandler:GetParent():GetParent():GetData(), wndControl:GetData()
	local mode = panel.oMode

	panel:SetRowOpacity(row, _nFillHoverOpacity, _nTextHoverOpacity)

	if mode.GetTooltipText then
		self:TooltipShow(mode:GetTooltipText(panel, row), panel.w, true)
	end
end

function CombatMeter:OnRowMouseExit(wndHandler, wndControl)
	if wndHandler ~= wndControl then
		return
	end
	local panel = wndHandler:GetParent():GetParent():GetData()
	local row = wndControl:GetData()

	panel:SetRowOpacity(row, panel.nFillOpacity, panel.nTextOpacity)

	self:TooltipHide()
end


-----------------------------------------------------------------------------------------------
-- Multi Panel Generic Functions
-----------------------------------------------------------------------------------------------

function CombatMeter:IsPanelsHaveCombat(combat)
	for _,v in next, self.arPanels do
		if v.tCombat == combat then
			return true
		end
	end
end

function CombatMeter:UpdatePanel(id)
	local panel = self.arPanels[id]
	panel:Update()
end

function CombatMeter:StartPanel(id)
	local panel = self.arPanels[id]

	if not panel.tCombat or panel.tCombat == self:GetLastCombat() then
		panel.tCombat = self:GetCurrentCombat()				-- change to current combat if last combat was selected

		if panel.tPlayer then
			panel.tPlayerDetail = panel.tPlayer.detail
			panel.tPlayer = nil
		end
		if panel.tAbility then
			panel.tAbilityDetail = panel.tAbility.detail
			panel.tAbility = nil
		end
		if panel.tParent then
			panel.tParentDetail = panel.tParent.detail
			panel.tParent = nil
		end

		panel.oMode:init(panel)
	end

	panel.bStarted = true

	panel:SettingsToCurrent()
end

function CombatMeter:StopPanel(id)
	local panel = self.arPanels[id]

	panel.bStarted = nil

	panel:SettingsToCurrent()

	local tCombat = self:GetCurrentCombat()
	if panel.tCombat == tCombat then
		panel:SetDurationLabel(tCombat.duration)
	end
end

function CombatMeter:ClearPanel(id)		-- only used by clear slash command atm
	local panel = self.arPanels[id]

	panel.tCombat = nil
	panel:SetMode("combat")

	panel.timerLabel:SetText("00:00")

	panel.statLabel:SetText("")
	panel.nStatLabel = nil

	panel:ClearRows()
	panel:ResetScroll()
end

function CombatMeter:ShowPanel(id, bShow)
	local panel = self.arPanels[id]

	self:TooltipHide()

	panel.w:Show(bShow)
end

function CombatMeter:ClosePanel(wnd)
	local panels,L = self.arPanels, self.L

	if #panels == 1 then							-- if we are the last window, just leave it and turn it off
		Print((L["Type /cm to reactivate %s."]):format(L[_AddonName]))
		CombatMeter:Off()
		return
	end

	for i,v in ipairs(panels) do
		if v.w == wnd then
			self:RemovePanel(i, true)						--FIXME: need to remove this actual window not #1
			break
		end
	end
end

function CombatMeter:RemovePanel(id, bSettings)		-- need to removed these last to start
	local o,panels = self.userSettings, self.arPanels
	local panel = panels[id]

	self:TooltipHide()

	if panel then
		local w = panel.w
		if w and w:IsValid() then
			panel:EnsureRows(0)						-- explicity remove row ui windows
			w:SetData(nil)
			w:Destroy()
		end
		panel.w = nil
	end

	_tremove(panels, id)
	if bSettings then
		_tremove(o.arPanels, id)
	end
end

function CombatMeter:OpenPanel(wnd)
	local panels,L = self.arPanels, self.L

	local panel										-- source panel
	for i,v in ipairs(panels) do
		if v.w == wnd then
			panel = v
			break
		end
	end
	if not panel then
		return
	end

	local o = self:EnsurePanel(nil, DeepCopy(panel.settings))

	local l,t,r,b = panel.w:GetAnchorOffsets()
	o.w:SetAnchorPoints(panel.w:GetAnchorPoints())	-- positional settings will be stale until reload
	o.w:SetAnchorOffsets(l + 30, t + 50, r + 30, b + 50)
	self:OnPositionRelativeChanged(o)				-- force the panel fully in-bounds

	o:SetState(panel)
end

function CombatMeter:EnsurePanel(id, settings)
	local o,panels = self.userSettings, self.arPanels
	local panel = panels[id]

	id = id or #o.arPanels + 1
	settings = settings or self:GetDefaultPanelSettings()

	o.arPanels[id] = settings

	panel = self.Panel:new(settings)
	panels[id] = panel

	return panel
end

function CombatMeter:GetDefaultPanelSettings()
	local settings = DeepCopy(_defaultPanelSettings)
	return settings			-- don't augment the defaults for now. just let it start at 0,0
end
