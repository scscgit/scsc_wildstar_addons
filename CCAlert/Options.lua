local CCAlert = Apollo.GetAddon("CCAlert")

local tCCDurationValues = { "  Never show", "  Text only", "  Bar only", "  Text and Bar" }

local sDummySound = "No sound"

------------------------------------
-- Initialize settings window controls
------------------------------------

function CCAlert:InitControls()

	-- Alpha slider init
	if not self.bAlphaSliderInit then
		self.bAlphaSliderInit = true
		self:InitSliderWidget(self.settingsWindow:FindChild("Alpha"), 0, 1, .1, self.alertWindow:GetBGOpacity(), 2, function(value)
			value = math.max(math.min(value, 1), 0)
			self.tSettings.alpha = value
			self.alertWindow:SetBGOpacity(value)
		end)
	end

	-- Font color init
	local btnFontColor = self.settingsWindow:FindChild("BtnFontColor")
	local colorPicker = self.settingsWindow:FindChild("ColorPickerWindow")
	if not self.bColorPickerInit then
		self.bColorPickerInit = true
		btnFontColor:AttachWindow(colorPicker)
	end

end

------------------------------------
-- Update settings window
------------------------------------

function CCAlert:UpdateSettings()

	-- CC types grid
	self:FillGrid()

	-- Lock button
	self.settingsWindow:FindChild("BtnLocked"):SetCheck(self.tSettings.locked)

	-- Weapon Indicator button
	self.settingsWindow:FindChild("BtnWeaponIndicator"):SetCheck(self.tSettings.weaponIndicator)
	if self.tSettings.weaponIndicator then
		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	else
		Apollo.RemoveEventHandler("UnitCreated", self)
		self:WeaponIndicatorWindow_Close()
	end

	-- CC duration button
	self.settingsWindow:FindChild("BtnCCDuration"):SetText(tCCDurationValues[self.tSettings.showDuration])

	-- Sound list
	local strSound = self:getKeyByValue(Sound,self.tSettings.sound) or sDummySound
	strSound = strSound:gsub("PlayUI", "")
	strSound = strSound:gsub("Play", "")
	self.settingsWindow:FindChild("BtnSoundList"):SetText("  "..strSound)

	-- Font list
	local btnFontList = self.settingsWindow:FindChild("BtnFontList")
	btnFontList:SetText(self:getKeyByValue(self.tFontList, self.tSettings.fontName))

	-- Sprite list
	local btnSpriteList = self.settingsWindow:FindChild("BtnSpriteList")
	btnSpriteList:SetText(self:getKeyByValue(self.tSpriteList, self.tSettings.spriteName))

	-- Alpha slider
	self.alertWindow:SetBGOpacity(self.tSettings.alpha)
	self.settingsWindow:FindChild("Alpha:Slider"):SetValue(self:round(self.tSettings.alpha, 2))
	self.settingsWindow:FindChild("Alpha:Input"):SetText(tostring(self:round(self.tSettings.alpha, 2)))

	-- Font color
	local btnFontColor = self.settingsWindow:FindChild("BtnFontColor")
	btnFontColor:FindChild("Inner"):SetBGColor(self.tSettings.fontColor)

	self:AlertWindow_Update(self.sDummyText, not self.tSettings.locked)

end

------------------------------------
-- Update Main window position
------------------------------------

function CCAlert:UpdateWindowPos()
	self.alertWindow:SetAnchorOffsets(unpack(self.tSettings.offsets))
end

------------------------------------
-- Grid CC type
------------------------------------

function CCAlert:OnGridItemClick(wndControl, wndHandler, iRow, iCol, eMouseButton)

	if iCol ~= 2 then return end -- only checkbox column click

	local text = wndControl:GetCellText(iRow, 1)
	local data = wndControl:GetCellData(iRow, 1)

	data.enabled = not data.enabled
	data.image = (data.enabled and "BK3:btnHolo_Check_smallPressed") or (not data.enabled and "BK3:btnHolo_Check_smallNormal"),

	wndControl:SetCellData(iRow, 1, text, nil, data)
	wndControl:SetCellImage(iRow, 2, data.image)

	self.tSettings.ccState[data.enum].enabled = data.enabled

end

function CCAlert:FillGrid()

	local grid = self.settingsWindow:FindChild("Grid")
	grid:DeleteAll()

	-- build and sort priority table
	local a = {}
	for k,v in pairs(self.tSettings.ccState) do
		-- only unique
		if not self:getKeyByValue(a,v.priority) then
			table.insert(a, v.priority)
		end
	end
	table.sort(a)

	-- fill grid by priority order
	for k,v in ipairs(a) do

		for i,n in pairs(self.tSettings.ccState) do

			if n.priority == v then
				local row = grid:AddRow("")
				local text = self.tCCStates[i].text
				local data = {
					enabled = n.enabled,
					priority = n.priority,
					image = (n.enabled and "BK3:btnHolo_Check_smallPressed") or (not n.enabled and "BK3:btnHolo_Check_smallNormal"),
					enum = i
				}
				grid:SetCellData(row, 1, text, nil, data)
				grid:SetCellImage(row, 2, data.image) --BK3:btnHolo_Radio_SmallDisabled
				break
			end

		end

	end

end

------------------------------------
-- Up / Down Buttons
------------------------------------

function CCAlert:OnBtnMoveUp(wndHandler)

	local grid = self.settingsWindow:FindChild("Grid")
	local curRow = grid:GetCurrentRow()
	if curRow == nil or curRow == 1 then return end

	local curRow_text = grid:GetCellText(curRow, 1)
	local curRow_data = grid:GetCellData(curRow, 1)

	local prevRow_text = grid:GetCellText(curRow - 1, 1)
	local prevRow_data = grid:GetCellData(curRow - 1, 1)

	-- new priorities
	curRow_data.priority = curRow - 1
	self.tSettings.ccState[curRow_data.enum].priority = curRow_data.priority
	prevRow_data.priority = curRow
	self.tSettings.ccState[prevRow_data.enum].priority = prevRow_data.priority

	-- moving row above to current position
	grid:SetCellData(curRow, 1, prevRow_text, nil, prevRow_data)
	grid:SetCellImage(curRow, 2, prevRow_data.image)

	-- moving current row one position up
	grid:SetCellData(curRow - 1, 1, curRow_text, nil, curRow_data)
	grid:SetCellImage(curRow - 1, 2, curRow_data.image)

	-- move focus one row up
	grid:SetCurrentRow(curRow - 1)
	grid:EnsureCellVisible(curRow - 1, 1)

end

function CCAlert:OnBtnMoveDown(wndHandler)

	local grid = self.settingsWindow:FindChild("Grid")
	local rowCount = grid:GetRowCount()
	local curRow = grid:GetCurrentRow()
	if curRow == nil or curRow == rowCount then return end

	local curRow_text = grid:GetCellText(curRow, 1)
	local curRow_data = grid:GetCellData(curRow, 1)

	local nextRow_text = grid:GetCellText(curRow + 1, 1)
	local nextRow_data = grid:GetCellData(curRow + 1, 1)

	-- new priorities
	curRow_data.priority = curRow + 1
	self.tSettings.ccState[curRow_data.enum].priority = curRow_data.priority
	nextRow_data.priority = curRow
	self.tSettings.ccState[nextRow_data.enum].priority = nextRow_data.priority

	-- moving row below to current position
	grid:SetCellData(curRow, 1, nextRow_text, nil, nextRow_data)
	grid:SetCellImage(curRow, 2, nextRow_data.image)

	-- moving current row one position down
	grid:SetCellData(curRow + 1, 1, curRow_text, nil, curRow_data)
	grid:SetCellImage(curRow + 1, 2, curRow_data.image)

	-- move focus one row down
	grid:SetCurrentRow(curRow + 1)
	grid:EnsureCellVisible(curRow + 1, 1)

end

------------------------------------
-- Slider Widget
------------------------------------

function CCAlert:InitSliderWidget(frame, min, max, tick, value, roundDigits, callback)
	frame:SetData({
		callback = callback,
		digits = roundDigits
	})
	frame:FindChild("Slider"):SetMinMax(min, max, tick)
	frame:FindChild("Slider"):SetValue(self:round(value, roundDigits))
	frame:FindChild("Input"):SetText(tostring(self:round(value, roundDigits)))
	frame:FindChild("Min"):SetText(tostring(min))
	frame:FindChild("Max"):SetText(tostring(max))
	return frame
end

function CCAlert:OnSliderWidget(wndHandler, wndControl, value)
	value = self:UpdateSliderWidget(wndHandler, value)
	wndHandler:GetParent():GetData().callback(value)
end

function CCAlert:UpdateSliderWidget(wndHandler, value)
	local parent = wndHandler:GetParent()
	if wndHandler:GetName() == "Input" then
		value = tonumber(value)
		if not value then
			return nil
		end
	else
		value = self:round(value, wndHandler:GetParent():GetData().digits)
		parent:FindChild("Input"):SetText(tostring(value))
	end
	parent:FindChild("Slider"):SetValue(value)
	return value
end

------------------------------------
-- Grid Dropdown
------------------------------------

function CCAlert:BuildDropdownList(wndSender, tList, sType)
	local wnd = self.settingsWindow:FindChild("DropDownContainer")
	local grid = wnd:FindChild("Grid")
	grid:DeleteAll()

	local a = {}
	for k in pairs(tList) do table.insert(a, k) end
	table.sort(a)
	for i,n in ipairs(a) do
		local row = grid:AddRow("")
		grid:SetCellData(row, 1, n, nil, tList[n])
	end

	grid:SetData(sType)

	local sMatch = (sType == "font" and self.tSettings.fontName) or (sType == "sprite" and self.tSettings.spriteName)
	grid:SelectCellByData(sMatch, true)
	grid:EnsureCellVisible(grid:GetCurrentRow(), 1)

	wnd:Invoke()
end

function CCAlert:OnGridDropDownItemClick(wndControl, wndHandler, iRow, iCol, eMouseButton)

	-- only left mouse button click
	-- this also stops this method call when SelectCellByData called from other functions
	if eMouseButton ~= 0 then return end

	local text = wndControl:GetCellText(iRow, 1)
	local data = wndControl:GetCellData(iRow, 1)
	local type = wndControl:GetData()

	local bNeedUpdate = false

	if type == "font" then

		local btnFontList = self.settingsWindow:FindChild("BtnFontList")
		btnFontList:SetText(text)
		btnFontList:SetCheck(false)
		self.tSettings.fontName = data
		bNeedUpdate = true

	elseif type == "sprite" then

		local btnSpriteList = self.settingsWindow:FindChild("BtnSpriteList")
		btnSpriteList:SetText(text)
		btnSpriteList:SetCheck(false)
		self.tSettings.spriteName = data
		bNeedUpdate = true

	elseif type == "duration" then

		local btnCCDuration = self.settingsWindow:FindChild("BtnCCDuration")
		btnCCDuration:SetText(text)
		btnCCDuration:SetCheck(false)
		self.tSettings.showDuration = data
		bNeedUpdate = false

		local bHasActiveCC = self:HasActiveCC()
		-- this is only executed if option changed while active cc running
		if bHasActiveCC and self.tSettings.locked then
			self.AlertWindowTimer:Start()
		end

	elseif type == "sound" then

		local btnSoundList = self.settingsWindow:FindChild("BtnSoundList")
		btnSoundList:SetText("  "..text)
		btnSoundList:SetCheck(false)
		self.tSettings.sound = data
		bNeedUpdate = false
		Sound.Play(data)

	end

	if bNeedUpdate then
		self:AlertWindow_Update(self.sDummyText, self.alertWindow:IsVisible())
	end

	wndControl:GetParent():Close()

end

function CCAlert:OnDropDownContainerClose(wndHandler)
	self.settingsWindow:FindChild("BtnFontList"):SetCheck(false)
	self.settingsWindow:FindChild("BtnSpriteList"):SetCheck(false)
	self.settingsWindow:FindChild("BtnCCDuration"):SetCheck(false)
	self.settingsWindow:FindChild("BtnSoundList"):SetCheck(false)
end

------------------------------------
-- Font button
------------------------------------

function CCAlert:OnBtnFontListClick(wndHandler)
	self:BuildDropdownList(wndHandler, self.tFontList, "font")
	wndHandler:SetCheck(true)
end

------------------------------------
-- Sprite button
------------------------------------

function CCAlert:OnBtnSpriteListClick(wndHandler)
	self:BuildDropdownList(wndHandler, self.tSpriteList, "sprite")
	wndHandler:SetCheck(true)
end

------------------------------------
-- Show Duration button
------------------------------------

function CCAlert:OnBtnCCDuration(wndHandler)

	local wnd = self.settingsWindow:FindChild("DropDownContainer")
	local grid = wnd:FindChild("Grid")
	grid:DeleteAll()

	for k,v in ipairs(tCCDurationValues) do
		local row = grid:AddRow("")
		grid:SetCellData(row, 1, v, nil, k)
	end

	grid:SetData("duration")

	local sMatch = self.tSettings.showDuration or 0
	grid:SelectCellByData(sMatch, true)
	grid:EnsureCellVisible(grid:GetCurrentRow(), 1)

	wndHandler:SetCheck(true)

	wnd:Invoke()

end

------------------------------------
-- SoundList button
------------------------------------

function CCAlert:OnBtnSoundList(wndHandler)

	local wnd = self.settingsWindow:FindChild("DropDownContainer")
	local grid = wnd:FindChild("Grid")
	grid:DeleteAll()

	grid:AddRow(sDummySound,nil,0)

	local tSoundList = {}
	for k,v in pairs(Sound) do
		if type(v) == "number" then
			table.insert(tSoundList, k)
		end
	end
	table.sort(tSoundList)

	for k,v in ipairs(tSoundList) do
		if Sound[v] ~= nil then
			local s = v:gsub("PlayUI", "")
			s = s:gsub("Play", "")
			grid:AddRow(s,nil,Sound[v])
		end
	end

	grid:SetData("sound")

	local sMatch = self.tSettings.sound or 0
	grid:SelectCellByData(sMatch, true)
	grid:EnsureCellVisible(grid:GetCurrentRow(), 1)

	wndHandler:SetCheck(true)

	wnd:Invoke()

end

------------------------------------
-- Lock / Unlock button
------------------------------------

function CCAlert:OnBtnLocked(wndHandler)
	local bLocked = wndHandler:IsChecked()
	self.tSettings.locked = bLocked
	self:AlertWindow_Update(self.sDummyText, not bLocked)
end

------------------------------------
-- Weapon Indicator button
------------------------------------

function CCAlert:OnBtnWeaponIndicator(wndHandler)
	local bWeaponIndicator = wndHandler:IsChecked()
	self.tSettings.weaponIndicator = bWeaponIndicator
	if bWeaponIndicator then
		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	else
		Apollo.RemoveEventHandler("UnitCreated", self)
		self:WeaponIndicatorWindow_Close()
	end
end

------------------------------------
-- OK / Cancel buttons
------------------------------------

function CCAlert:OnBtnOK()
	self.tSettingsTemp = nil
	self.settingsWindow:Close()
end

function CCAlert:OnBtnCancel()
	self.tSettings = self:tableCopy(self.tSettingsTemp)
	self.tSettingsTemp = nil
	self:UpdateSettings()

	self.settingsWindow:Close()
end

------------------------------------
-- Font Color
------------------------------------

function CCAlert:OnFontColorButtonClick(wndHandler)
	local picker  = self.settingsWindow:FindChild("ColorPickerWindow:ColorPicker")
	local color = self.settingsWindow:FindChild("BtnFontColor:Inner"):GetBGColor()
	local nColor  = ApolloColor.new(color.r, color.g, color.b)

	-- set the color picker
	picker:SetColor(nColor)

	-- update RGB edits and preview
	self:OnColorPickerChange(picker, picker, color)

	self.settingsWindow:FindChild("ColorPickerWindow"):Invoke()
end

function CCAlert:OnColorPickerChange(wndHandler, wndControl, crNewColor)
	local colorpickerContainer = wndControl:GetParent()

	local nRed = math.floor(crNewColor.r * 255.0)
	local nGreen = math.floor(crNewColor.g * 255.0)
	local nBlue = math.floor(crNewColor.b * 255.0)

	local acolor = ApolloColor.new(nRed, nGreen, nBlue)

	-- set the edit boxes
	colorpickerContainer:FindChild("R_EditBox"):SetText(nRed)
	colorpickerContainer:FindChild("G_EditBox"):SetText(nGreen)
	colorpickerContainer:FindChild("B_EditBox"):SetText(nBlue)
--	colorpickerContainer:FindChild("Hex_EditBox"):SetText(self:RGBtoHEX({r = nRed, g = nGreen, b = nBlue}))

	-- update the preview
	colorpickerContainer:FindChild("ColorPreview:Inner"):SetBGColor({crNewColor.r, crNewColor.g, crNewColor.b, 1.0})
end

function CCAlert:OnRGBColorChange(wndHandler, wndControl, strText)
	local container = wndHandler:GetParent()

	local strValue = strText:gsub("%D","")
	if strValue == "" then
		strValue = "0"
	end
	local nValue = math.min(255, math.max(tonumber(strValue), 0))

	local tSelection = wndControl:GetSel()
	wndControl:SetText(tostring(nValue))
	wndControl:SetSel(tSelection.cpCaret, tSelection.cpCaret)

	local rgbColor = {}
	rgbColor.r = tonumber(container:FindChild("R_EditBox"):GetText())
	rgbColor.g = tonumber(container:FindChild("G_EditBox"):GetText())
	rgbColor.b = tonumber(container:FindChild("B_EditBox"):GetText())

	-- update the preview
	container:FindChild("ColorPreview:Inner"):SetBGColor({rgbColor.r/255.0, rgbColor.g/255.0, rgbColor.b/255.0, 1.0})

	-- set the color picker
	local nColor  = ApolloColor.new(rgbColor.r, rgbColor.g, rgbColor.b)
	container:FindChild("ColorPicker"):SetColor(nColor)
end

function CCAlert:OnColorPickerCancel(wndHandler)
	wndHandler:GetParent():Close()
end

function CCAlert:OnColorPickerApply(wndHandler, wndControl)
	-- get selected color, format is dec {1, 1, 1, 1}
	local color = wndHandler:GetParent():FindChild("ColorPreview:Inner"):GetBGColor()

	-- set selected color to settings window button
	local btnFontColor = self.settingsWindow:FindChild("BtnFontColor:Inner")
	btnFontColor:SetBGColor(color)

	-- prepare and save color table
	local tColor = {[1]=color.r, [2]=color.g, [3]=color.b, [4]=color.a}
	self.tSettings.fontColor = tColor

	-- update main window
	self:AlertWindow_Update(self.sDummyText, self.alertWindow:IsVisible())

	-- close the popup
	wndHandler:GetParent():Close()
end