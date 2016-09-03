-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoMountHP
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoMountHP Module Definition
-----------------------------------------------------------------------------------------------
local PotatoMountHP = {}
local Defaults = _G["PUIDefaults"]["MountHP"]
local bEditorMode = false

local ktPos = {"textLeft", "textMid", "textRight"}
local ktTextType = {
	[0] = {"None", ""},
	[1] = {"Name", "This is a Name"},
	[2] = {"Detailed", "1100/5500"},
	[3] = {"Shortened", "1100"},
	[4] = {"Percent", "20%"},
	[5] = {"Super Short", "1.1k"},
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------

function PotatoMountHP:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoMountHP:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PotatoLib"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function PotatoMountHP:OnLoad() --Loaded 1st
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoMountHP.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function PotatoMountHP:OnDocLoaded() --Loaded 3rd
	if self.xmlDoc == nil and not self.xmlDoc:IsLoaded() then return end
	
	self.wndMountHP = Apollo.LoadForm(self.xmlDoc, "MountHealth", "FixedHudStratum", self)
	
	for key, val in pairs(Defaults) do
		if key ~= "__index" then
			--[[if self[key] then
				Print("MountHP"..key..":Loaded")
			else
				Print("MountHP"..key..":Defaulted")
			end]]--
			self[key] = self[key] or val --Load from restored values (self[key] from OnRestore()), or use the default (val).
		end
	end
	
	self:Position()
	self:UpdateAppearance()	
	
	--Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("SubZoneChanged", "OnSubZoneChanged", self)	
	Apollo.RegisterEventHandler("Mount", "OnMountState", self)	
	
	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"Reset", self)
	Apollo.RegisterEventHandler("PotatoSettings",				"PopulateSettingsList", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)
	
	if GameLib.GetPlayerUnit() == nil then
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
	else
		self:OnCharacterCreated()
	end
	
	Apollo.RegisterEventHandler("VarChange_FrameCount", "OnFrame", self)
end

function PotatoMountHP:PopulateResetFeatures()
	PotatoLib:AddResetItem("Mount Health", nil, self)
end

function PotatoMountHP:OnPRFReset()
	self:Reset()
end

function PotatoMountHP:EditorModeToggle(bState)
	bEditorMode = bState
	
	if bEditorMode then
		self.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", self.wndMountHP, self)
		self.wndCover:SetText(self.name)
		--self.wndCover:FindChild("Reset"):Show(false)
		if self.border.show then
			self.wndCover:SetAnchorOffsets(self.border.size, self.border.size, -self.border.size, -self.border.size)
		else
			self.wndCover:SetAnchorOffsets(0,0,0,0)
		end
		self.wndMountHP:Show(true)
	else
		self.wndCover:Destroy()
		self.wndCover = nil
		if self.wndEditor then
			self.wndEditor:Destroy()
			self.wndEditor = nil
		end
		self.wndMountHP:Show(self:ShouldShow())
	end
	self.wndMountHP:SetStyle("Moveable", bEditorMode)
	self.wndMountHP:SetStyle("Sizable", bEditorMode)
end

function PotatoMountHP:OnFrame() --Continually updated.
	self:UpdateMountHPStats()
end

function PotatoMountHP:OnTimer()
end

function PotatoMountHP:Position()
	self.wndMountHP:SetAnchorPoints(unpack(self.anchors))
	self.wndMountHP:SetAnchorOffsets(unpack(self.offsets))
	--Print(string.format("%s: %s, %s, %s, %s", self.name, unpack(self.offsets)))
end

function PotatoMountHP:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)
end

function PotatoMountHP:UpdateAppearance() --Creates or updates the visual appearance of the frame. Called when the frame is customized.
	--Show
	self.wndMountHP:Show(self:ShouldShow())
	--Positioning
	--self:Position()
	
	--Background and Border
	self.wndMountHP:FindChild("Content"):SetStyle("Picture", self.background.show)
	PotatoLib:UpdateBorder(self.wndMountHP, self.wndMountHP:FindChild("Content"), self.border)

	--Bar Appearances
	PotatoLib:SetBarAppearance2(self.wndMountHP:FindChild("HPBar"), self.texture, self.color, self.transparency)
	self.wndMountHP:FindChild("HPBar"):SetStyleEx("BRtoLT", self.barGrowth == 2)
	
	--Text
	PotatoLib:SetBarFonts(self.wndMountHP:FindChild("HPBar"), self)
end

function PotatoMountHP:UpdateMountHPStats() -- [CONTINUALLY UPDATED]
	local unitMount = GameLib.GetPlayerMountUnit()
	if unitMount then
		self.wndMountHP:Show(self:ShouldShow()) --TODO: Resource hungry. Quick fix.
		
		local nCurrVal = unitMount:GetHealth()
		local nMaxVal = unitMount:GetMaxHealth()
		
		self.wndMountHP:FindChild("HPBar"):SetMax(nCurrVal)
		self.wndMountHP:FindChild("HPBar"):SetProgress(nMaxVal)
		
		for _, strTextLoc in pairs(ktPos) do
			local strText = ""
			--ktPos == 0 is None
			if self[strTextLoc].type == 1 then --Name
				strText = unitMount:GetName()
			elseif self[strTextLoc].type == 2 then --Detailed Verbose
				strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (math.floor(nCurrVal) .. "/" .. math.floor(nMaxVal)) or ""
			elseif self[strTextLoc].type == 3 then --Detailed Short
				strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (self:FormatNumber(nCurrVal) .. "/" .. self:FormatNumber(nMaxVal)) or ""
			elseif self[strTextLoc].type == 4 then --Percent
				strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (math.floor(nCurrVal/nMaxVal*100).."%") or ""
			elseif self[strTextLoc].type == 5 then --Super Short
				strText = (nMaxVal ~= 0 and nMaxVal ~= nil) and (self:FormatNumber(nCurrVal)) or ""
			end
			
			self.wndMountHP:FindChild(strTextLoc):SetText(strText)
		end
	else
		self.wndMountHP:Show(bEditorMode)
	end
end

function PotatoMountHP:ShouldShow()
	local unitMount = GameLib.GetPlayerMountUnit()
	
	if unitMount ~= nil then
		if self.showFrame == 1 then return true end
		if self.showFrame == 2 and (not PotatoLib:IsBarFull({"HP","SP"}, unitMount) or PotatoLib.bInCombat) then return true end
		if self.showFrame == 3 and PotatoLib.bInCombat then return true end
	end
	
	return bEditorMode
end

function PotatoMountHP:FormatNumber(nNumber)
	local strNum = "ERR"
	
	if nNumber / 1000000 >= 1 then
		strNum = string.format("%.1fm", nNumber/1000000)
	elseif nNumber / 1000 >= 1 then
		strNum = string.format("%.1fk",nNumber/1000)
	else
		strNum = math.floor(nNumber)
	end

	return string.gsub(strNum .. "", "%.0", "")
end

function PotatoMountHP:OnCharacterCreated()
	local unitPlayer = GameLib.GetPlayerUnit()
	local bMounted = GameLib.GetPlayerMountUnit() ~= nil
	
	if unitPlayer ~= nil then
		if self.wndMountHP:IsShown() then
			self.wndMountHP:Show(bMounted)
		elseif self:ShouldShow() and bMounted then
			self.wndMountHP:Show(true)
		end
	end
end

function PotatoMountHP:OnMountState(bMounted)
	if self:ShouldShow() then
		self.wndMountHP:Show(bMounted)
	end
end

function PotatoMountHP:OnSubZoneChanged(nSubZoneId, strSubZone, nSomething)
	self:OnCharacterCreated()
end

function PotatoMountHP:Reset()
	for key, val in pairs(Defaults) do
		if key ~= "__index" then
			self[key] = TableUtil:Copy(val)
		end
	end
	
	self:Position()
	self:UpdateAppearance()
end

function PotatoMountHP:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.xmlDoc = nil
	
	local tSaveData = {}

    for key,val in pairs(self) do
		if key ~= "__index" then
			tSaveData[key] = val
		end
	end
	
	tSaveData.offsets = {self.wndMountHP:GetAnchorOffsets()}
	tSaveData.anchors = {self.wndMountHP:GetAnchorPoints()}

	return tSaveData
end

function PotatoMountHP:OnRestore(eLevel, tData) --Loaded 2nd
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
    for key,val in pairs(tData) do
		self[key] = TableUtil:Copy(val)
	end
	
	self.bLoaded = true
end

---------------------------------------------------------------------------------------------------
-- Editor Functions  --TODO: Try to merge in PLib somehow.
---------------------------------------------------------------------------------------------------

function PotatoMountHP:SelectFrame(wndHandler) --TODO: Generalize and move to PLib
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		if self.name == "Special Castbar" then
			self:OpenSpecialEditor()
		else
			self:OpenEditor()
		end
	end
end

function PotatoMountHP:OpenEditor()
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	
	if self.wndEditor then
		self.wndEditor:Destroy()
		self.wndEditor = nil
	end
	
	--Populate PotatoLib editor frame; Set title
	self.wndEditor = Apollo.LoadForm(self.xmlDoc, "MountHPCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	self.wndEditor:Show(true)
	PLib.wndCustomize:FindChild("Title"):SetText(self.name .. " Settings")
	PLib.wndCustomize:Show(true)
	
	--Set frame visibility
	self.wndEditor:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", self.showFrame)
	
	--Set background visibility and color
	self.wndEditor:FindChild("Background"):FindChild("EnableBtn"):SetCheck(self.background.show)
	self.wndEditor:FindChild("Background"):FindChild("Color"):SetBGColor("FF"..self.background.color)
	self.wndEditor:FindChild("Background"):FindChild("HexText"):SetText(self.background.color)
	
	--Set border visibility and color
	self.wndEditor:FindChild("Border"):FindChild("EnableBtn"):SetCheck(self.border.show)
	self.wndEditor:FindChild("Border"):FindChild("Color"):SetBGColor("FF"..self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("HexText"):SetText(self.border.color)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValue"):SetText(self.border.size)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueUp"):Enable(self.border.size ~= 20)
	self.wndEditor:FindChild("Border"):FindChild("BorderSize:SizeValueDown"):Enable(self.border.size ~= 1)



	--Bar Settings
	local wndBarOpts = self.wndEditor:FindChild("MountHealth")
	
	--Set bar fill direction
	wndBarOpts:FindChild("BarGrowth"):FindChild("Options"):SetRadioSel("BarGrowth", self.barGrowth)
	
	--Set texture
	PotatoLib:SetSprite(wndBarOpts:FindChild("BarTexture"):FindChild("CurrentVal"),self.texture)
	wndBarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(self.texture == "WhiteFill" and "Flat" or self.texture)
	wndBarOpts:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..self.color)
	
	--Set color and transparency
	wndBarOpts:FindChild("Color"):SetBGColor("FF"..self.color)
	wndBarOpts:FindChild("HexText"):SetText(self.color)
	wndBarOpts:FindChild("Transparency"):SetValue(self.transparency)
	wndBarOpts:FindChild("TransAmt"):SetText(self.transparency.."%")
	
	--Set text options
	PotatoLib:PopulateTextOptions(wndBarOpts, self, ktTextType)
	
	--Set position options
	local nX1, nY1, nX2, nY2 = self.wndMountHP:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndMountHP:GetAnchorPoints()
	
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	if self.wndEditor then
		if self.wndEditor:FindChild("XPos") ~= nil then
			local PLib = Apollo.GetAddon("PotatoLib")
			if PLib.bPositionCenter then
				nAX1 = nAX1-0.5
				nAY1 = nAY1-0.5
			end
			self.wndEditor:FindChild("XPos"):SetText((nAX1*nScreenX)+nX1)
			self.wndEditor:FindChild("YPos"):SetText((nAY1*nScreenY)+nY1)
			self.wndEditor:FindChild("Width"):SetText(nX2-nX1)
			self.wndEditor:FindChild("Height"):SetText(nY2-nY1)
		end
	end
end

--Frame sub-editor functions
function PotatoMountHP:OnShowChange( wndHandler, wndControl )
	local nShow = wndHandler:GetParent():GetRadioSel("ShowFrame")
	self.showFrame = nShow
	
	self:UpdateAppearance()
end


function PotatoMountHP:OnChangeBG( wndHandler, wndControl, eMouseButton ) --TODO: New BG options
	local bCheck = wndHandler:IsChecked()	
	self.background.show = bCheck
	
	self:UpdateAppearance()
end

function PotatoMountHP:IncrementBorderSize( wndHandler, wndControl, eMouseButton )
	local nChange = wndHandler:GetName() == "SizeValueUp" and 1 or -1
	
	--Set data value
	self.border.size = self.border.size + nChange
	
	if self.border.size == 1 or self.border.size == 20 then
		wndHandler:Enable(false)
	else
		for key, val in pairs(wndHandler:GetParent():GetChildren()) do
			if val.Enable then
				val:Enable(true)
			end
		end
	end	
	
	--Set editor window
	wndHandler:GetParent():FindChild("SizeValue"):SetText(self.border.size)
	
	self:UpdateAppearance()
end

function PotatoMountHP:OnShowBorder( wndHandler, wndControl, eMouseButton ) --TODO: Migrate to PLib
	local bCheck = wndHandler:IsChecked()
	self.border.show = bCheck
	
	self:UpdateAppearance()
end

--Mount HP Bar sub-editor functions
function PotatoMountHP:OnChangeGrowth( wndHandler, wndControl, eMouseButton ) --TODO: Migrate to PLib
	local nGrowth = wndHandler:GetParent():GetRadioSel("BarGrowth")
	self.barGrowth = nGrowth
	
	self:UpdateAppearance()
end

function PotatoMountHP:BarTextureScroll( wndHandler, wndControl ) --TODO: Migrate to PLib
	local ktTextures = PotatoLib.ktTextures
	
	local nCurrBar = ktTextures[self.texture]

	if wndHandler:GetName() == "RightScroll" then
		nCurrBar = nCurrBar == #ktTextures and 1 or (nCurrBar + 1)
	elseif wndHandler:GetName() == "LeftScroll" then
		nCurrBar = nCurrBar == 1 and #ktTextures or (nCurrBar - 1)
	end
	
	local strTexture = ktTextures[nCurrBar]

	--Set data value
	self.texture = strTexture
	
	--Set editor window
	wndHandler:GetParent():FindChild("CurrentVal"):SetSprite(strTexture)
	wndHandler:GetParent():FindChild("CurrentVal"):SetText(nCurrBar == ktTextures["WhiteFill"] and "Flat" or strTexture)
	
	self:UpdateAppearance()
end

function PotatoMountHP:OnSetBarColor(wndHandler)
	PotatoLib:ColorPicker("color", self, self.UpdateAppearance, wndHandler)
end

function PotatoMountHP:TransSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
	self.transparency = math.floor(fNewValue)

	--Set editor window
	wndHandler:GetParent():FindChild("TransAmt"):SetText(math.floor(fNewValue).."%")
	
	self:UpdateAppearance()
end

function PotatoMountHP:TextOptScroll( wndHandler, wndControl )
	local strTextLoc = wndControl:GetParent():GetParent():GetName()	
	
	PotatoLib:TextOptScroll(wndHandler, ktTextType, self)

	self.wndMountHP:FindChild(strTextLoc):SetText(ktTextType[self[strTextLoc].type][2])
end

function PotatoMountHP:FontScroll( wndHandler, wndControl )
	PotatoLib:FontScroll(wndHandler, self)
	self:UpdateAppearance()
end

function PotatoMountHP:IncrementFontSize( wndHandler, wndControl, eMouseButton )
	PotatoLib:IncrementFontSize(wndHandler, self)
	self:UpdateAppearance()
end

function PotatoMountHP:OnTxtWeight( wndHandler, wndControl, eMouseButton )
	PotatoLib:ChangeTxtWeight(wndHandler, self)
	self:UpdateAppearance()
end

function PotatoMountHP:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndMountHP:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndMountHP:GetAnchorPoints()

	local nWidth = nX2-nX1
	local nHeight = nY2-nY1
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	
	local PLib = Apollo.GetAddon("PotatoLib")
	if PLib.bPositionCenter then
		nAX1 = nAX1-0.5
		nAX2 = nAX2-0.5
		nAY1 = nAY1-0.5
		nAY2 = nAY2-0.5
	end
	
	strPos = string.gsub(strPos, "[^\-0-9]", "")
	if #strPos > 1 and string.sub(strPos, 1, 1) == "0" then
		strPos = string.gsub(strPos, "0", "", 1)
	end
	
	if strPos == "" then
		strPos = "0"
	end
	
	if strPos ~= "-" then
		if strChange == "XPos" then
			self.wndMountHP:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
		elseif strChange == "YPos" then
			self.wndMountHP:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
		end
		PLib:MoveLockedWnds(self.wndMountHP)
	end

	wndHandler:SetText(strPos)
	wndHandler:SetSel(#strPos,#strPos)
end

function PotatoMountHP:TxtHWChanged( wndHandler, wndControl, strHW )
	local strChange = wndHandler:GetName()
	
	local nX1, nY1, nX2, nY2 = self.wndMountHP:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = self.wndMountHP:GetAnchorPoints()
	
	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 1 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		self.wndMountHP:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		self.wndMountHP:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
	
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------

function PotatoMountHP:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:OpenEditor()
	
	self:SelectFrame(self.wndMountHP)
end

function PotatoMountHP:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	PotatoLib:HandleLockedWnd(self.wndMountHP, "MountHP")
end

function PotatoMountHP:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:Reset()
end

function PotatoMountHP:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			self:OpenEditor()
		end
		self:SelectFrame(self.wndMountHP)
	end
end

-----------------------------------------------------------------------------------------------
-- PotatoMountHP Instance
-----------------------------------------------------------------------------------------------
local PotatoMountHPInst = PotatoMountHP:new()
PotatoMountHPInst:Init()
