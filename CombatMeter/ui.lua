-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. Portions (C) Vim,Vince via CC 3.0 VortexMeter.  All rights reserved.
-- Original: Rift Meter by Vince at www.curse.com/addons/rift/rift-meter
-----------------------------------------------------------------------------------------------

local CombatMeter = Apollo.GetAddon("CombatMeter")
if not CombatMeter then return end

local _tClassToColorSetting = CombatMeter._tClassToColorSetting
local _tAbilityToColorSetting = CombatMeter._tAbilityToColorSetting
local _arSpectrumColorSetting = CombatMeter._arSpectrumColorSetting
local _tSettingsColors = CombatMeter._tSettingsColors
local _arUnitStats = CombatMeter._arUnitStats

local _floor = math.floor
local _format = string.format
local _tinsert = table.insert
local _max = math.max
local _min = math.min
local _huge = math.huge

local _print = CombatMeter._print


-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local _tModes = {}

local _tLSortModes = CombatMeter._tLSortModes

local _nMaxRowPool = 8

local _cFilterButtonTextOn = "xkcdAcidGreen"
local _cFilterButtonTextOff = "xkcdBloodOrange"

local function FormatPercent( n )
	n = n and (n <= 0 or n >= 0) and n ~= _huge and n or 0				-- nil, ind, and inf
	return _format("%.1f%%)", n)
end

local function FormatSeconds( n )
	n = n and (n <= 0 or n >= 0) and n ~= _huge and n or 0				-- nil, ind, and inf
	n = n / 1000														-- assume milliseconds
	local s = _floor(n % 60)
	return _floor(n / 60) .. ":" .. (s < 10 and (0 .. s) or s)
end

function FormatNumber( n )
	local o = CombatMeter.userSettings
	n = n and (n <= 0 or n >= 0) and n ~= _huge and n or 0				-- nil, ind, and inf
	n =  _floor(n + .5)

	if o.bShowShort then
		if n > 1000000 then
			return _format("%.1fm", n / 1000000)
		elseif n > 1000 then
			return _format("%.1fk", n / 1000)
		end
		return tostring(n)
	end

	local s,i = ""
	while n >= 1000 do
		i = n % 1000
		s =  "," .. (i < 10 and "00" or i < 100 and 0 or "") .. i .. s
		n = _floor(n / 1000)
	end
	return n .. s
end

function FormatDivision( n, d )
	d = d and d ~= 0 and (d <= 0 or d >= 0) and d ~= _huge and d or 1	-- nil, ind, and inf
	return FormatNumber((n or 0) / d)
end

function Division( n, d )
	n = n and (n <= 0 or n >= 0) and n ~= _huge and n or 0				-- nil, ind, and inf
	d = d and d ~= 0 and (d <= 0 or d >= 0) and d ~= _huge and d or 1	-- nil, ind, and inf
	return n / d
end

local function BuildFormat(nAbsolute, nPerSecond, nPercent)
	local o = CombatMeter.userSettings
	local bPer, bAbs = o.bShowPercent, o.bShowAbsolute

	if bAbs and bPer then
		return FormatNumber(nAbsolute) .. " (" .. FormatNumber(nPerSecond) .. ", " .. FormatPercent(nPercent)
	end

	return (bAbs and (FormatNumber(nAbsolute) .. (bPer and " (" or ", ")) or "") .. FormatNumber(nPerSecond) ..
		(bPer and ((bAbs and ", " or " (") .. FormatPercent(nPercent)) or "")
end

local function BuildPerFormat(nPerSecond, nPercent)
	local o = CombatMeter.userSettings
	local bPer = o.bShowPercent and nPercent

	if bPer then
		return " (" .. FormatPercent(nPercent) .. "  " .. FormatNumber(nPerSecond)
	end

	return FormatNumber(nPerSecond)
end


---------------------------------------------------------------------------

local Window = {}
CombatMeter._tModes = _tModes
CombatMeter.FormatNumber = FormatNumber
CombatMeter.FormatDivision = FormatDivision
CombatMeter.Division = Division
CombatMeter.BuildFormat = BuildFormat
CombatMeter.Panel = Window
function Window:new(settings)
	local o = {}
	Window.__index = Window
	setmetatable(o, Window)

	o.settings = settings				-- per window settings saved in config file
	o.bSavePos = true

	o.arRows = {}
	o.nScrollOffset = 0
	--o.bScrolled = nil					-- scollbar is scrolled by user outside its natural position

	o.arData = {}						-- data for rendering the rows, offered to modes to use as a consistant table. may not be the same table returned to render
	o.nData = 0							-- the full number of data items that could be shown if there were enough rows in the window

	--o.tCombat = nil					-- current combat from arCombats
	--o.tPlayer = nil					-- current from tCombat.players
	--o.tPlayerDetail = nil				-- current detail from tPlayer.detail
	--o.tAbility = nil					-- current from Player GetAbility
	--o.tAbilityDetail = nil			-- current detail from tAbility.detail
	--o.tParent = nil					-- parent tPlayer of current from tCombat.players
	--o.tParentDetail = nil				-- parent tPlayer of current detail from tPlayer.detail

	o.oMode = _tModes.combat			-- current Mode Lua object for the current mode, start with combat which is player by damage list
	--o.oModeLast = nil					-- saved mode before picking a new eSort, which uses Mode convention for its ui
	o.bStarted = CombatMeter.bIsCombatOn-- panel started or stopped
	--o.bShowEnemies = nil				-- panel filtering either non-player or player units
	--o.bFilterOn = nil					-- when filter is enabled

	-- window state flags. must start as nil
	--o.bSizable = nil
	--o.nFillOpacity = nil
	--o.nTextOpacity = nil
	--o.bInLayout = nil					-- temp flag when update may cause resize event
	--o.tMoveMouse = nil				-- saved mouse position on pressed for window move
	--o.nOpacity = nil					-- for tracking when to generate a new background trans color
	--o.nMouseOpacity = nil				-- for tracking when to generate a new header/footer trans color
	--o.nStatLabel = nil				-- original number value used for stat label
	--o._bMouseEnter = nil				-- mouse entered panel window, cleared when exit latch cleared
	--o._bMouseExit = nil				-- latch for exit triggered code in UpdateVisibility

	o:init()

	return o
end

function Window:SetState(panel)
	self.tCombat = panel.tCombat
	self.tPlayer = panel.tPlayer
	self.tPlayerDetail = panel.tPlayerDetail
	self.tAbility = panel.tAbility
	self.tAbilityDetail = panel.tAbilityDetail
	self.tParent = panel.tParent
	self.tParentDetail = panel.tParentDetail

	self.oMode = panel.oMode
	self.oModeLast = panel.oModeLast
	self.bShowEnemies = panel.bShowEnemies
	self.bFilterOn = panel.bFilterOn

	self:Update()
end

function Window:init()
	local o,ow = CombatMeter.userSettings, self.settings

	local w = Apollo.LoadForm(CombatMeter.xmlDoc, "CombatMeter", nil, CombatMeter)
	self.w = w												-- form window
	self.header = w:FindChild(":Header")
	self.headerText = w:FindChild("HeaderText")
	self.background = w:FindChild(":Background")
	self.footer = w:FindChild(":Footer")
	self.timerLabel = w:FindChild("TimerLabel")
	self.statLabel = w:FindChild("StatLabel")

	w:SetData(self)

	self.nFillOpacity = o.nFillOpacity						-- set these before creating rows
	self.nTextOpacity = o.nTextOpacity

	if self.oMode then
		self.oMode:init(self)
	end

	self.bInLayout = true
	if ow.wndAnchors then
		w:SetAnchorPoints(unpack(ow.wndAnchors))
	end
	if not ow.wndPosition then
		ow.wndPosition = { ow.x, ow.y, ow.x + ow.nWidth, ow.y + (ow.nDisplayRows * (ow.nRowHeight + 1)) + 45 }
	end
	ow.nDisplayRows = nil									-- gets reset in layout
	w:SetAnchorOffsets(unpack(ow.wndPosition))
	self.bInLayout = false

	CombatMeter:UpdatePanelLayout(self)						-- may alter height
	CombatMeter:OnPositionRelativeChanged(self)				--   so determine final position last

	self:SettingsToCurrent()
end

function Window:SetMouseOpacity(nOpacity)
	if nOpacity ~= self.nMouseOpacity then		-- SetOpacity animation causes background to blink black on new window

		local cr = ApolloColor.new(0.094, 0.094, 0.094, nOpacity)					--00181818

		self.header:SetBGColor(cr)
		self.footer:SetBGColor(cr)

		for _,v in next, self.header:GetChildren() do
			v:SetOpacity(nOpacity, 50)
		end
		for _,v in next, self.footer:GetChildren() do
			v:SetOpacity(nOpacity, 50)
		end

		self.nMouseOpacity = nOpacity
	end
end

function Window:SetRowOpacity(row, nFillOpacity, nTextOpacity)
	if nFillOpacity then
		row.background:SetOpacity(nFillOpacity, 20000)
	end
	if nTextOpacity then
		row.marker:SetOpacity(nTextOpacity * 0.9, 20000)
		row.icon:SetOpacity(nTextOpacity, 20000)
		row.rightLabel:SetOpacity(nTextOpacity, 20000)
		row.leftLabel:SetOpacity(nTextOpacity, 20000)
	end
end

function Window:SettingsToCurrent()
	local o = CombatMeter.userSettings
	local w,header,footer = self.w, self.header, self.footer

	-- global settings
	if o.nOpacity ~= self.nOpacity then			-- SetOpacity animation causes background to blink black on new window
		self.background:SetBGColor(ApolloColor.new(0.07, 0.07, 0.07, o.nOpacity))	--00121212
		self.nOpacity = o.nOpacity
	end
	if not self._bMouseEnter then
		self:SetMouseOpacity(o.nMouseOpacity)
	end

	local bSizable = not o.bLockWindows
	if bSizable ~= self.bSizable then
		w:FindChild("ResizeLeft"):Show(bSizable)
		w:FindChild("ResizeRight"):Show(bSizable)
		if bSizable then
			w:AddEventHandler("WindowMove", "OnWindowSizeChanged", CombatMeter)
		else
			w:RemoveEventHandler("WindowMove")
		end
		w:SetStyle("Sizable", bSizable)
		self.bSizable = bSizable
	end

	local nFillOpacity,nTextOpacity = o.nFillOpacity, o.nTextOpacity
	if nFillOpacity ~= self.nFillOpacity or nTextOpacity ~= self.nTextOpacity then
		for _,row in next, self.arRows do
			self:SetRowOpacity(row, nFillOpacity, nTextOpacity)
		end
		self.nFillOpacity, self.nTextOpacity = nFillOpacity, nTextOpacity
	end

	header:FindChild("StartButton"):ChangeArt(self.bStarted and "CombatMeter:StopButton" or "CombatMeter:StartButton")
	header:FindChild("PlayersButton"):ChangeArt(self.bShowEnemies and "CombatMeter:PlayersButton" or "CombatMeter:EnemiesButton")

	footer:FindChild("SoloButton"):SetTextColor(not o.bLogOthers and _cFilterButtonTextOn or _cFilterButtonTextOff)
	footer:FindChild("FilterButton"):SetTextColor(self.bFilterOn and _cFilterButtonTextOn or _cFilterButtonTextOff)
end

function Window:UpdateVisibility()
	local o = CombatMeter.userSettings

	if self.bStarted then
		local tCombatCurrent = CombatMeter:GetCurrentCombat()
		if self.tCombat == tCombatCurrent then
			self:SetDurationLabel(o.nNow - tCombatCurrent.startTime)
		end
	end

	if self._bMouseExit then							-- cut down on flicker when resizing, mouse leaves frame on expand
		self:SetMouseOpacity(o.nMouseOpacity)
		self._bMouseEnter = nil
		self._bMouseExit = nil
	end
end

function Window:Update()
	local ow = self.settings

	local arData, count, max, total, limit = self.oMode:update(self)
	limit = limit or arData and #arData or 0			-- allow the table to not necessarily have to shrink, and make the return value optional
	self.nData = count									-- make total count available for scroll code

	for i,row in ipairs(self.arRows) do
		local data = i <= limit and arData[i] or nil
		row.data = data

		local bShow = data and true or false

		if bShow then
			local s = data.marker or ""
			local b = s ~= ""
			if b and s ~= row.crMarker then
				row.marker:SetBGColor(s)
				row.crMarker = s
			end
			if b ~= row.bShowMarker then
				row.marker:Show(b)
				row.bShowMarker = b
			end

			s = data.icon or ""
			b = s ~= ""
			if b and s ~= row.sIcon then
				row.icon:SetSprite(s)
				row.sIcon = s
			end
			if b ~= row.bShowIcon then
				row.icon:Show(b)
				row.bShowIcon = b
			end

			s = data.leftLabel or ""
			if s ~= row.sLeftLabel then
				row.leftLabel:SetText(s)
				row.sLeftLabel = s
			end
			s = data.rightLabel or ""
			if s ~= row.sRightLabel then
				row.rightLabel:SetText(data.rightLabel or "")
				row.sRightLabel = s
			end

			local n = _tSettingsColors[data.color or "crTotal"] or _tSettingsColors["crNone"]
			if n ~= row.crBackground then
				row.background:SetBGColor(n)
				row.crBackground = n
			end
			n = _floor((data.value or 0) / (max ~= 0 and max or 1) * 1000) / 1000
			if n ~= row.nBackground then
				row.background:SetAnchorPoints(0, 0, n <= 0 and 0 or n >= 1 and 1 or n, 1)
				row.nBackground = n
			end
		end

		if bShow ~= row.bShow then
			row.w:Show(bShow)
			row.bShow = bShow
		end
	end

	if total and total ~= self.nStatLabel then
		total = _floor(total + 0.5)					-- clip so we aren't updating on value changes we won't show
	end
	if total ~= self.nStatLabel then
		self.statLabel:SetText(total and FormatNumber(total) or "")
		self.nStatLabel = total
	end
end

function Window:EnsureRows(nDisplayRows)
	local w,ow,rows,arData,rowPool = self.w, self.settings, self.arRows, self.arData, CombatMeter.arRowPool

	-- cache, destroy rows
	local nRows,nPool = #rows,#rowPool
	if nDisplayRows < nRows then					-- have to remove rows
		self:ClearRows(nDisplayRows + 1)

		for i = nRows,nDisplayRows + 1,-1 do		-- push these empty rows to row pool
			local row = rows[i]
			local wr = row.w

			local bValid = wr and wr:IsValid()
			if bValid then
				wr:SetData(nil)
			end
			row.data = nil

			if bValid and nPool < _nMaxRowPool then
				nPool = nPool + 1
				rowPool[nPool] = row
			else
				wr:Destroy()
				row.w = nil
			end

			arData[i] = nil
			rows[i] = nil
		end
		return
	end

	-- adjust scroll
	if nDisplayRows > nRows then				-- more visible rows, push scroll up to keep displayed list full
		self.nScrollOffset = _max(_min(self.nScrollOffset, (self.nData or 0) - ow.nDisplayRows), 0)
	end

	-- reclaim, create rows
	local nRowHeight = ow.nRowHeight
	local nRowPos = nRows * (nRowHeight + 1) + 1
	local nFillOpacity,nTextOpacity = self.nFillOpacity, self.nTextOpacity

	for i = nRows + 1, nDisplayRows do
		local row
		if nPool > 0 then
			row = rowPool[nPool]
			rowPool[nPool] = nil
			nPool = nPool - 1
		end

		local wr = row and row.w
		if not wr or not wr:IsValid() then
			row = row or { }

			wr = Apollo.LoadForm(CombatMeter.xmlDoc, "Row", self.background, CombatMeter)
			row.w = wr
			row.background = wr:FindChild("Background")
			row.marker = wr:FindChild("Marker")
			row.icon = wr:FindChild("Icon")
			row.rightLabel = wr:FindChild("RightLabel")
			row.leftLabel = wr:FindChild("LeftLabel")

			self:SetRowOpacity(row, nFillOpacity, nTextOpacity)

			row.bShow = nil					-- clear these incase window went invalid and was reloaded
			row.bShowMarker = nil
			row.crMarker = nil
			row.bShowIcon = nil
			row.sIcon = nil
			row.sLeftLabel = nil
			row.sRightLabel = nil
			row.crBackground = nil
			row.nBackground = nil
		end

		arData[i] = {}
		rows[i] = row
		wr:SetData(row)

		wr:Show(false)						-- dont assume the row will be shown
		wr:SetAnchorOffsets(1, nRowPos, -1, nRowPos + nRowHeight)
		nRowPos = nRowPos + nRowHeight + 1
	end
end

function Window:ResetScroll()
	self.nScrollOffset = 0
	self.bScrolled = nil
end

function Window:ClearRows(nStart)
	local rows = self.arRows

	for i = nStart or 1, #rows do
		local row = rows[i]

		if row.bShow then
			row.w:Show(false)
			row.bShow = false
		end
	end
end

function Window:SetTitle(title)
	self.headerText:SetText(tostring(title))
end

function Window:SetDurationLabel(duration)
	self.timerLabel:SetText(FormatSeconds(duration))
end

function Window:SetMode(aMode, ...)
	CombatMeter:TooltipHide()

	local tMode = aMode
	if type(aMode) == "string" then
		tMode = _tModes[aMode]
	end

	if tMode ~= self.oMode then					-- prevent endless loop
		self.oModeLast = self.oMode
		self.oMode = tMode
		self:ResetScroll()
	end

	self.oMode:init(self, ...)
	self:Update()								-- force immediate update
end


---------------------------------------------------------------------------

local Mode = {}
function Mode:new(name)
	local o = {}
	Mode.__index = Mode
	setmetatable(o, Mode)

	o.name = name

	return o
end

function Mode:init() end
function Mode:update() end
--function Mode:GetTooltipText(panel, row) end
--function Mode:OnLeftClick(panel, row) end
--function Mode.OnMiddleClick(panel, row) end
--function Mode:OnRightClick(panel) end
--function Mode:OnMouse4Click(panel) end
--function Mode:OnMouse5Click(panel) end
function Mode:OnSortmodeChange(window, newSortmode) return false end
function Mode:GetReportText() end


---------------------------------------------------------------------------

_tModes.modes = Mode:new("modes")

function _tModes.modes:init(panel)
	local L = CombatMeter.L

	panel:ResetScroll()
	panel:SetTitle(L["Sort Modes"])
end

function _tModes.modes:update(panel)
	local settings,L = panel.settings, CombatMeter.L

	local max = 1

	local arData = panel.arData
	local limit = _min(#_arUnitStats, settings.nDisplayRows)
	local offset = panel.nScrollOffset

	for i = 1, limit do
		local data = arData[i]

		local eSort = _arUnitStats[i + offset]

		data.marker = nil
		data.icon = nil
		data.leftLabel = _tLSortModes[eSort]
		data.rightLabel = nil
		data.color = nil
		data.value = max

		data.tMode = panel.oModeLast
		data.eSort = eSort
	end

	return arData, #_arUnitStats, max, nil, limit
end

function _tModes.modes:OnLeftClick(panel, row)
	local settings,data = panel.settings, row.data
	if not data then
		return
	end

	local eSortOld = settings.eSort
	settings.eSort = data.eSort

	local tMode = data.tMode
	if not tMode:OnSortmodeChange(panel, eSortOld) then
		panel:SetMode(tMode)
	end
end


---------------------------------------------------------------------------

_tModes.combats = Mode:new("combats")

function _tModes.combats:init(panel)
	local combats,L = CombatMeter.arCombats, CombatMeter.L

	panel:SetTitle(L["Combats"] .. ": " .. _tLSortModes[panel.settings.eSort])
end

function _tModes.combats:update(panel)
	local o,settings,combat,combats = CombatMeter.userSettings, panel.settings, panel.tCombat, CombatMeter.arCombats
	if not combat then
		return
	end

	local arData, count, max, total, limit, offset = CombatMeter:CombatGetCombatsData(combat, settings.eSort, panel.bShowEnemies,
		not panel.bScrolled, panel.arData, panel.nScrollOffset, settings.nDisplayRows)

	panel.nScrollOffset = offset			-- allow the callee to always adjust this value if necessary

	local bShowRank = o.bShowRank
	local percent = _max(max, 1) / 100

	local nColors = #_arSpectrumColorSetting

	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		local b = data.bTotals
		local v = data.ref
		local j = b and 1 or i + offset

		data.marker = nil
		data.icon = nil
		data.leftLabel = (bShowRank and (j - 1) .. ". " or "") .. FormatSeconds(v.duration) .. " " .. data.name
		data.rightLabel = BuildPerFormat(value, value ~= max and (value / percent))
		data.color = b and "crTotal" or _arSpectrumColorSetting[(data.i % nColors) + 1] or nil
		--data.value = value
	end

	return arData, count, max, total, limit
end

function _tModes.combats:GetTooltipText(panel, row)
	local settings,data = panel.settings, row.data
	if data then
		return CombatMeter:CombatGetTooltipText(data.ref)
	end
end

function _tModes.combats:OnLeftClick(panel, row)
	local data = row.data
	if data then
		panel:SetMode("combat", data.ref)
	end
end

function _tModes.combats:GetReportText(panel)
	local o,settings,combat,combats = CombatMeter.userSettings, panel.settings, panel.tCombat, CombatMeter.arCombats
	if not combat then
		return
	end

	local arData, count, max, total, limit, offset = CombatMeter:CombatGetCombatsData(combat, settings.eSort, panel.bShowEnemies,
		nil, panel.arData, panel.nScrollOffset, settings.nDisplayRows)

	local t = {}

	local tCombatOverall = CombatMeter.tCombatOverall
	local percent = _max(max, 1) / 100

	_tinsert(t, _format("Combats: (%s)", FormatSeconds(tCombatOverall.duration)))
	_tinsert(t, "--------------------")
	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		local v = data.ref

		_tinsert(t, _format("%d) %s ~ (%s, %d%%) ", i + offset, data.name:sub(0, 32),
			FormatNumber(value), _floor(value / percent + 0.5)))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.combat = Mode:new("combat")

function _tModes.combat:init(panel, combat)
	local combats,L = CombatMeter.arCombats, CombatMeter.L

	panel:ClearRows()
	panel:ResetScroll()

	if combat then
		panel.tCombat = combat
	end

	if not panel.tCombat then
		local count = #combats
		if count > 0 then
			panel.tCombat = combats[count]
		end
	end

	if panel.tCombat then
		local combat = panel.tCombat
		if combat.bCompress then
			CombatMeter:CombatUncompress(combat)
		end
		panel:SetDurationLabel(combat.duration)
	end
	panel:SetTitle(_tLSortModes[panel.settings.eSort])
end

function _tModes.combat:update(panel)
	local o,settings,combat = CombatMeter.userSettings, panel.settings, panel.tCombat
	if not combat then
		return
	end

	local arData, count, max, total, limit = CombatMeter:CombatGetPlayersData(combat, settings.eSort,
		panel.bShowEnemies, o.bShowSelf, panel.arData, panel.nScrollOffset, settings.nDisplayRows)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100
	local bShowRank = o.bShowRank
	local bShowHostile = o.bShowMarker and CombatMeter.bIsCombatOn
		and combat == CombatMeter.tCombatCurrent

	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		local v = data.ref
		local detail = v.detail
		local tGOwner = detail.tGOwner
		local tGUnit = tGOwner or detail

		local bHostile = bShowHostile and (not tGUnit.bPlayer or not (tGUnit.bSelf or tGUnit.bGroup))
		local name = detail.name
		if tGOwner then
			name = name .. " (" .. tGOwner.name .. ")"
		end

		data.marker = bHostile and "DispositionHostile" or nil
		data.icon = nil
		data.leftLabel = (bShowRank and (data.i) .. ". " or "") .. name
		data.rightLabel = BuildFormat(value, value / duration, value / percent)
		data.color = _tClassToColorSetting[tGUnit.eClass]
		--data.value = value
	end

	return arData, count, max, total / duration, limit
end

function _tModes.combat:GetTooltipText(panel, row)
	local settings,data = panel.settings, row.data
	if data then
		return CombatMeter:PlayerGetTooltipText(data.ref, settings.eSort)
	end
end

function _tModes.combat:OnLeftClick(panel, row)
	local data = row.data
	if data then
		panel:SetMode("abilities", data.ref)
	end
end

function _tModes.combat:OnMiddleClick(panel, row)
	local data = row.data
	if data and data.ref.arPets ~= nil then
		panel:SetMode("interactions", data.ref)
	end
end

function _tModes.combat:OnRightClick(panel)
	local combats = CombatMeter.arCombats
	if #combats > 0 then
		panel:SetMode("combats")
	end
end

function _tModes.combat:OnMouse4Click(panel)
	local combats,combat = CombatMeter.arCombats, panel.tCombat
	for i,v in ipairs(combats) do
		if v == combat and i > 1 then
			panel:SetMode("combat", combats[i - 1])
			return
		end
	end
end

function _tModes.combat:OnMouse5Click(panel)
	local combats,combat = CombatMeter.arCombats, panel.tCombat
	for i,v in ipairs(combats) do
		if v == combat and i < #combats then
			panel:SetMode("combat", combats[i + 1])
			return
		end
	end
end

function _tModes.combat:GetReportText(panel)
	local o,settings = CombatMeter.userSettings, panel.settings
	local combat = panel.tCombat
	if not combat then
		return
	end

	local arData, count, max, total, limit = CombatMeter:CombatGetPlayersData(combat, settings.eSort,
		panel.bShowEnemies, nil, nil, nil, o.nReportLines)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	local t = {}

	_tinsert(t, _format("Target: %s ~ (%s)", (CombatMeter:CombatGetName(combat) or ""):sub(0, 48), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")
	_tinsert(t, _format("Total %s: %s (%s, %d%%)", panel.settings.eSort, FormatNumber(total), FormatNumber(total / duration), _floor(total / percent + 0.5)))
	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		local v = data.ref
		local detail = v.detail
		local tGOwner = detail.tGOwner

		local name = detail.name
		if tGOwner then
			name = name .. " (" .. tGOwner.name .. ")"
		end

		_tinsert(t, _format("%d) %s - %s (%s, %d%%) ", i, name:sub(0, 32),
			FormatNumber(value), FormatNumber(value / duration), _floor(value / percent + 0.5)))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.abilities = Mode:new("abilities")

function _tModes.abilities:init(panel, tPlayer)
	local L = CombatMeter.L

	panel:ClearRows()
	panel:ResetScroll()

	if tPlayer then
		panel.tPlayer = tPlayer
	end
	if panel.tPlayer then
		panel:SetTitle(panel.tPlayer.detail.name .. ": " .. _tLSortModes[panel.settings.eSort])
	end
end

function _tModes.abilities:update(panel)
	local o,settings,L = CombatMeter.userSettings, panel.settings, CombatMeter.L

	if not panel.tPlayer then
		if panel.tPlayerDetail then
			self:findOwner(panel)
		end
		if not panel.tPlayer then
			return
		end
	end

	local offset = panel.nScrollOffset
	local combat = panel.tCombat

	local arData, count, max, total, limit = CombatMeter:PlayerGetAbilitiesData(panel.tPlayer, settings.eSort,
		panel.arData, offset, settings.nDisplayRows)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	for i = 1, limit do
		local data = arData[i]
		local bTotals = data.bTotals
		local value = bTotals and total or data.value

		local v = data.ref

		data.marker = nil
		data.icon = v and v.detail.icon or nil
		data.leftLabel = "      " .. (bTotals and L["Total"] or data.name)
		data.rightLabel = BuildFormat(value, value / duration, value / percent)
		data.color = v and _tAbilityToColorSetting[v.type] or nil
		--data.value = value
	end

	total = total / duration

	return arData, count, max, total, limit
end

function _tModes.abilities:OnLeftClick(panel, row)
	local data = row.data
	if data then
		panel:SetMode("ability", not data.bTotals and data.ref
			or CombatMeter:AbilityNew_PlayerTotals(panel.tPlayer))
	end
end

function _tModes.abilities:OnRightClick(panel)
	panel:SetMode("combat")
end

function _tModes.abilities:findOwner(panel)
	local settings,combat,L = panel.settings, panel.tCombat, CombatMeter.L

	local tPlayer = combat[panel.tPlayerDetail]

	self:init(panel, tPlayer)
end

function _tModes.abilities:GetReportText(panel)
	local o,settings,combat = CombatMeter.userSettings, panel.settings, panel.tCombat

	local arData, count, max, total, limit = CombatMeter:PlayerGetAbilitiesData(panel.tPlayer, settings.eSort,
		nil, nil, o.nReportLines + 1)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	local t = {}

	_tinsert(t, _format("Player: %s ~ Target: %s ~ (%s)", panel.tPlayer.detail.name,
		(CombatMeter:CombatGetName(combat) or ""):sub(1, 64), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")

	for i = 1, limit do
		local data = arData[i]
		local bTotals = data.bTotals
		local value = bTotals and total or data.value

		local v = data.ref

		local name = bTotals and ("Total " .. settings.eSort .. ":") or ((i - 1) .. ") " .. data.name:sub(1, 32) .. " -")
		_tinsert(t, _format("%s %s (%s, %d%%) ", name, FormatNumber(value), FormatNumber(value / duration), _floor(value / percent + 0.5)))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.ability = Mode:new("ability")

function _tModes.ability:init(panel, tAbility)
	panel:ClearRows()

	if tAbility then
		panel.tAbility = tAbility
	end
	if panel.tAbility then
		local tAbility = panel.tAbility
		panel:SetTitle(panel.tPlayer.detail.name .. ": " .. (tAbility.name or tAbility.detail.name))
	end
end

function _tModes.ability:update(panel)
	local o,settings,L = CombatMeter.userSettings, panel.settings, CombatMeter.L

	if not panel.tAbility or not panel.tPlayer then
		if panel.tAbilityDetail then
			self:findOwner(panel)
		end
		if not panel.tAbility then
			return
		end
	end

	local offset = panel.nScrollOffset
	local combat = panel.tCombat

	local arData, count, max, total, limit = CombatMeter:AbilityGetAbilityData(panel.tAbility, panel.tPlayer, combat, settings.eSort,
		panel.arData, offset, settings.nDisplayRows)

	for i = 1, limit do
		local data = arData[i]

		data.marker = nil
		data.icon = nil
		data.leftLabel = data.name
		data.rightLabel = data.value
		data.color = "crDefault"
		data.value = nil
	end

	total = total / _max(combat.duration / 1000, 1)

	return arData, count, max, total, limit
end

function _tModes.ability:OnRightClick(panel)
	panel:SetMode("abilities", panel.tPlayer)
end

function _tModes.ability:findOwner(panel)
	local settings = panel.settings
	if not panel.tPlayer then
		_tModes.abilities:findOwner(panel)
	end

	local tPlayer,tGAbility = panel.tPlayer, panel.tAbilityDetail
	if not tPlayer or not tGAbility then
		return
	end

	local tAbility = tGAbility.type == -123 and CombatMeter:AbilityNew_PlayerTotals(tPlayer)
		or CombatMeter:PlayerFindAbility(tPlayer, tGAbility, settings.eSort)

	self:init(panel, tAbility)
end

function _tModes.ability:GetReportText(panel)
	local o,settings,combat = CombatMeter.userSettings, panel.settings, panel.tCombat
	local tAbility = panel.tAbility

	local arData, count, max, total, limit = CombatMeter:AbilityGetAbilityData(tAbility, panel.tPlayer, combat, settings.eSort,
		nil, nil, o.nReportLines)

	local t = {}

	_tinsert(t, _format("Player: %s ~ Target: %s ~ Ability: %s ~ (%s)",
		panel.tPlayer.detail.name:sub(1, 16), (CombatMeter:CombatGetName(combat) or ""):sub(1, 12),
		(tAbility.name or tAbility.detail.name):sub(1, 24), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")

	for i = 1, limit do
		local data = arData[i]
		_tinsert(t, _format("%s ~ %s", data.name, data.value))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.interactions = Mode:new("interactions")

function _tModes.interactions:init(panel, tPlayer)
	local L = CombatMeter.L

	panel:ClearRows()
	panel:ResetScroll()

	if tPlayer then
		panel.tPlayer = tPlayer
	end
	if panel.tPlayer then
		panel:SetTitle(_format(L["%s: Interactions: %s"], panel.tPlayer.detail.name,
			_tLSortModes[panel.settings.eSort]))
	end
end

function _tModes.interactions:update(panel)
	local o,settings = CombatMeter.userSettings, panel.settings

	if not panel.tPlayer then
		if panel.tPlayerDetail then
			self:findOwner(panel)
		end
		if not panel.tPlayer then
			return
		end
	end

	local combat = panel.tCombat
	local offset = panel.nScrollOffset

	local arData, count, max, total, limit = CombatMeter:PlayerGetInteractionsData(panel.tPlayer, settings.eSort,
		panel.arData, offset, settings.nDisplayRows)

	local duration = _max(combat.duration / 1000, 1)
	local bShowRank = o.bShowRank

	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		local v = data.ref				-- reduced player
		local detail = v.detail

		data.marker = nil
		data.icon = nil
		data.leftLabel = (bShowRank and (i + offset) .. ". " or "") .. data.name
		data.rightLabel = BuildFormat(value, value / duration, value / total * 100)
		data.color = _tClassToColorSetting[(detail.tGOwner or detail).eClass]
		--data.value = value
	end

	total = total / duration

	return arData, count, max, total, limit
end

function _tModes.interactions:OnLeftClick(panel, row)
	local data = row.data
	if data then
		panel:SetMode("interactionAbilities", data.ref, panel.tPlayer)
	end
end

function _tModes.interactions:OnRightClick(panel)
	panel:SetMode("combat")
end

function _tModes.interactions:findOwner(panel)
	local combat = panel.tCombat
	local tPlayer = combat[panel.tPlayerDetail]

	self:init(panel, tPlayer)
end

function _tModes.interactions:GetReportText(panel)
	local o,settings = CombatMeter.userSettings, panel.settings
	local combat = panel.tCombat
	if not combat then
		return
	end

	local arData, count, max, total, limit = CombatMeter:PlayerGetInteractionsData(panel.tPlayer, settings.eSort,
		nil, nil, o.nReportLines)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	local t = {}

	_tinsert(t, _format("Interactions: %s ~ Target: %s ~ (%s)", panel.tPlayer.detail.name:sub(1, 16),
		(CombatMeter:CombatGetName(combat) or ""):sub(0, 16), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")
	_tinsert(t, _format("Total %s: %s (%s, %d%%)", panel.settings.eSort, FormatNumber(total), FormatNumber(total / duration), _floor(total / percent + 0.5)))
	for i = 1, limit do
		local data = arData[i]
		local value = data.value

		_tinsert(t, _format("%d) %s - %s (%s, %d%%) ", i, data.name:sub(0, 16), FormatNumber(value), FormatNumber(value / duration), _floor(value / percent + 0.5)))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.interactionAbilities = Mode:new("interactionAbilities")

function _tModes.interactionAbilities:init(panel, tPlayer, tParent)
	local L = CombatMeter.L

	panel:ClearRows()
	panel:ResetScroll()

	if tPlayer then
		panel.tPlayer = tPlayer
	end
	if tParent then
		panel.tParent = tParent
	end
	if panel.tPlayer and panel.tParent then
		panel:SetTitle(panel.tParent.detail.name:sub(0, 6) .. ": " ..
			panel.tPlayer.detail.name:sub(0, 6) .. ": " .. _tLSortModes[panel.settings.eSort])
	end
end

_tModes.interactionAbilities.update = _tModes.abilities.update

function _tModes.interactionAbilities:OnLeftClick(panel, row)
	local data = row.data
	if data then
		panel:SetMode("interactionAbility", not data.bTotals and data.ref
			or CombatMeter:AbilityNew_PlayerTotals(panel.tPlayer))
	end
end

function _tModes.interactionAbilities:OnRightClick(panel)
	panel:SetMode("interactions", panel.tParent)
end

function _tModes.interactionAbilities:findOwner(panel)
	local settings,combat = panel.settings, panel.tCombat

	local tParent,tPlayer = combat[panel.tParentDetail]
	if tParent then
		local players = tParent.arPets ~= nil and tPlayer[settings.eSort]
		if players then
			tPlayer = players[panel.tPlayerDetail.name]
		end
	end
	self:init(panel, tPlayer, tParent)
end

function _tModes.interactionAbilities:OnSortmodeChange(panel, eSortOld)
	if panel.settings.eSort ~= eSortOld then
		panel:SetMode("interactions", panel.tParent)
		return true
	end
	return false
end

function _tModes.interactionAbilities:GetReportText(panel)
	local o,settings,combat = CombatMeter.userSettings, panel.settings, panel.tCombat

	local arData, count, max, total, limit = CombatMeter:PlayerGetAbilitiesData(panel.tPlayer, settings.eSort,
		nil, nil, o.nReportLines + 1)

	local duration = _max(combat.duration / 1000, 1)
	local percent = _max(total, 1) / 100

	local t = {}

	_tinsert(t, _format("Interaction: %s ~ Player: %s ~ Target: %s ~ (%s)",
		panel.tPlayer.detail.name:sub(1, 12), panel.tParent.detail.name:sub(1, 16),
		(CombatMeter:CombatGetName(combat) or ""):sub(1, 24), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")

	for i = 1, limit do
		local data = arData[i]
		local bTotals = data.bTotals
		local value = bTotals and total or data.value

		local v = data.ref

		local name = bTotals and ("Total " .. settings.eSort .. ":") or ((i - 1) .. ") " .. data.name:sub(1, 32) .. " -")
		_tinsert(t, _format("%s %s (%s, %d%%) ", name, FormatNumber(value), FormatNumber(value / duration), _floor(value / percent + 0.5)))
	end

	return t
end


---------------------------------------------------------------------------

_tModes.interactionAbility = Mode:new("interactionAbility")

function _tModes.interactionAbility:init(panel, tAbility)
	panel:ClearRows()

	if tAbility then
		panel.tAbility = tAbility
	end
	if panel.tAbility then
		local tAbility = panel.tAbility
		panel:SetTitle(panel.tParent.detail.name .. ": " .. (tAbility.name or tAbility.detail.name))
	end
end

_tModes.interactionAbility.update = _tModes.ability.update

function _tModes.interactionAbility:OnRightClick(panel)
	panel:SetMode("interactionAbilities")
end

function _tModes.interactionAbility:findOwner(panel)
	local settings = panel.settings
	if not panel.tPlayer then
		_tModes.interactionAbilities:findOwner(panel)
	end

	local tPlayer,tGAbility = panel.tPlayer, panel.tAbilityDetail
	if not tPlayer or not tGAbility then
		return
	end

	local tAbility = tGAbility.type == -123 and CombatMeter:AbilityNew_PlayerTotals(tPlayer)
		or CombatMeter:PlayerFindAbility(tPlayer, tGAbility, settings.eSort)

	self:init(panel, tAbility)
end

function _tModes.interactionAbility:OnSortmodeChange(panel, eSortOld)
	if panel.settings.eSort ~= eSortOld then
		panel:SetMode("interactions", panel.tParent)
		return true
	end
	return false
end

function _tModes.interactionAbility:GetReportText(panel)
	local o,settings,combat = CombatMeter.userSettings, panel.settings, panel.tCombat
	local tAbility = panel.tAbility

	local arData, count, max, total, limit = CombatMeter:AbilityGetAbilityData(tAbility, panel.tPlayer, combat, settings.eSort,
		nil, nil, o.nReportLines)

	local t = {}

	_tinsert(t, _format("Interaction: %s ~ Player: %s ~ Target: %s ~ Ability: %s ~ (%s)",
		panel.tPlayer.detail.name:sub(1, 12), panel.tParent.detail.name:sub(1, 16), (CombatMeter:CombatGetName(combat) or ""):sub(1, 12),
		(tAbility.name or tAbility.detail.name):sub(1, 24), FormatSeconds(combat.duration)))
	_tinsert(t, "--------------------")

	for i = 1, limit do
		local data = arData[i]
		_tinsert(t, _format("%s ~ %s", data.name, data.value))
	end

	return t
end
