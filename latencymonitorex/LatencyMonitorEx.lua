require "Window"
require "GameLib"

local LatencyMonitorEx = {} 
local pairs, unpack = pairs, unpack
local VILib, GeminiColor
local tVersion = {
  nMajor = 1,
  nMinor = 0,
  nPatch = 0
}
local tDefaultSettings = {
	tVersion = {
		nMajor = tVersion.nMajor,
		nMinor = tVersion.nMinor,
		nPatch = tVersion.nPatch,
	},
	bFirstRun = true,
	tThresholds = {
		[1] = { 60, { 0, 255, 0 } },
		[2] = { 160, { 255, 255, 0} },
		[3] = { 400, { 255, 0, 0} },
	},
	sTextColor = "ffffffff",
	strOrbColor = "ffffffff",
	bShowNetworkLatency = false,
	bShowMs = true,
	bShowOrb = true,
	bColorOrb = true,
	bOrbTextureID = 1,
	nOrbSize = 24,
	bShowText = true,
	bColorText = false,
	bTransitionColor = true,
	tWindowOffsets = {
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{0, 0, 0, 0},
		{4, -84, 134, -44},
	},
	nTextAlign = 1,
	nOrbAlign = 1,
	nMainAnchorID = 9,
	tOptionsWindowPos = {},
	nFontSize = 2,
	nFontType = 1,
	fUpdateFrequency = 1,
	nGraphicID = 2,
}
local arSize = {100, 40}
local tColors = {}
local arStateChangingGraphics = {
	[2] = true,
}
local arGraphicHasHighlight = {
	[1] = true,
}
local arGraphicIDs = {
	[1] = "Orb",
	[2] = "4Bars",
}
local arTextOffsets = {0, 12, 110, 10}

local arFontSizes = {
	[1] = {
		[1] = 9,
		[2] = 10,
		[3] = 11,
		[4] = 12,
		[5] = 13,
		[6] = 14,
		[7] = 16,
		[8] = 24,
	},
	[2] = {
		[1] = 9,
		[2] = 10,
		[3] = 11,
		[4] = 12,
		[5] = 14,
		[6] = 16,
	},
	[3] = {
		[1] = "",
	},
}

local arFontTypes = {
	[1] = "Header",
	[2] = "Interface",
	[3] = "Pixel",
}
local strLatencyDisclaimer = "<T Font=\"CRB_Interface10\" TextColor=\"ff9fefff\">%s</T>"
local tLatencyDisclaimer = {
	"This add-on allows for outputting two different latency values and I want to explain the differences here.",
	"The option for showing network latency (which will be the second value) will also show the value reported by Alt + F1. This is the pure network latency which means it's the same as running a ping command from your system to an IP. It basically asks the destination if it's there and then measures the time for it to reply back that it is. This is fine for knowing your network latency, obviously, but in a game like an MMO this isn't a proper indication of your actual latency.",
	"This is where the first value comes in, which is your real latency because it reports the network latency with the time it takes for the server to actually handle your request.\nIn a game like this there's a ton of stuff the server needs to verify before it happens. For instance when you use an ability the server needs to make sure that what you're doing is actually possible to do. For instance when you use an ability the server needs to check if you can acually use it, if it didn't someone could modify their client to remove cooldowns from abilities. There's a lot of this stuff happening and it takes time for the server to handle and report back to you about what's going on. On top of that the server of course needs to keep up with all the data of every other player and mob in your \"visible\" area of what you see around your character and send it to you - like it's doing for every other player on the server.",
	"So the first value is the correct one because you aren't doing things at network latency speed, you have to go through the server(s) for nearly everything you do and this takes an added amount of time, especially if the servers are under pressure.",
	"Now with this being said the method for getting the server latency value isn't perfect. Because of the way Carbine has setup their servers it actually means that different actions go to different servers and all of this isn't currently taken into account in the function used to get the latency value. There are many factors that can influence how long a specific action will take to actually execute and right now there's no way to get a completely accurate representation of this. Hopefully in the future this will change but right now this is the best we have.",
	"Server latency is always the first number and network latency is the optional second number. The graphic is always colored according to the server latency.",
}


function LatencyMonitorEx:new(o)
  o = o or {} 
  setmetatable(o, self)
  self.__index = self 
  return o
end

function LatencyMonitorEx:Init()
  Apollo.RegisterAddon(self, true, "Latency Monitor", {"Viper:Lib:VILib-1.9", "GeminiColor"})
end

function LatencyMonitorEx:OnConfigure()
	self:ShowHideOptions()
end

function LatencyMonitorEx:OnLoad()
	VILib = Apollo.GetPackage("Viper:Lib:VILib-1.9").tPackage
	GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
	self.settings = VILib:CopyTable(tDefaultSettings)
	self.xmlDoc = XmlDoc.CreateFromFile("LatencyMonitorEx.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function LatencyMonitorEx:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MainForm", "", self)
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		Apollo.LoadSprites("VLM.xml")
		self.xmlDoc = nil
		self.EscapeTimer = nil
		self.wndOptions, self.wndOptionsList = nil, nil
		self.bMainAnchorShown = false
		self.bOptionsOpen = false
		self.InterfaceMenuRegistered = false
		self.strOutput = ""
		self.strOutputFontWrapper = "<T Font=\"%s\" TextColor=\"%s\">%s</T>"
		self.strOutputColorWrapper = "<T TextColor=\"%s\">%s</T>"

		tColors.colorText = CColor.new(VILib:ConvertHexToColor(self.settings.sTextColor))

		Apollo.RegisterSlashCommand("vlm", "OnSlashCommand", self)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		Apollo.RegisterEventHandler("VLM_ToggleOptions", "ShowHideOptions", self)

		if not self.timerUpdater then self.timerUpdater = ApolloTimer.Create(self.settings.fUpdateFrequency, true, "OnUpdateLatency", self) end

		self:OnInterfaceMenuListHasLoaded()
		self:SetPosition()
		self:SetSettings()
		self:OnUpdateLatency()
	end
end

function LatencyMonitorEx:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return nil end
	self.settings.tVersion = VILib:CopyTable(tVersion)
	return self.settings
end

function LatencyMonitorEx:OnRestore(eLevel, tData)
	if tData then
		self.settings = VILib:MergeTables(self.settings, tData)
		if self.wndMain then self:SetSettings() end
		tColors.colorText = CColor.new(VILib:ConvertHexToColor(self.settings.sTextColor))
		if self.timerUpdater then self.timerUpdater:Set(self.settings.fUpdateFrequency, true) end
	end
end

function LatencyMonitorEx:OnInterfaceMenuListHasLoaded()
	if self.InterfaceMenuRegistered then return end
	self.InterfaceMenuRegistered = true
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Latency Monitor", {"VLM_ToggleOptions", "", ""})
end

function LatencyMonitorEx:OnUpdateLatency()
	local nLatency = GameLib.GetLatency()
	local nNetwork = GameLib.GetPingTime()
	local colorS = self.settings.sTextColor
	local colorN = self.settings.sTextColor

	if arStateChangingGraphics[self.settings.nGraphicID] then self:SetGraphic(nLatency) end

	if self.settings.bColorText or self.settings.bColorOrb then
		colorS = self:GetLatencyColor(nLatency)
		
		if self.settings.bColorOrb then
			self.wndMain:FindChild("Orb"):SetBGColor(colorS)
		end
		
		if self.settings.bColorText then
			colorN = self:GetLatencyColor(nNetwork)
		else
			colorS = self.settings.sTextColor
		end
	end
	
	if nLatency > 1000 then nLatency = VILib:Round(nLatency / 1000, 1) .. "k" end
	if nNetwork > 1000 then nNetwork = VILib:Round(nNetwork / 1000, 1) .. "k" end
	
	self.wndMain:FindChild("Text"):SetAML(string.format(self.strOutput, colorS, nLatency, colorN, nNetwork))
end

function LatencyMonitorEx:GetLatencyColor(nLatency)
	local nThreshold = self:GetThreshold(nLatency)
	local color = {r = self.settings.tThresholds[nThreshold][2][1], g = self.settings.tThresholds[nThreshold][2][2], b = self.settings.tThresholds[nThreshold][2][3]}
	if self.settings.bTransitionColor then
		if nThreshold > 1 then
			local percent = (nLatency - self.settings.tThresholds[nThreshold-1][1]) / (self.settings.tThresholds[nThreshold][1] - self.settings.tThresholds[nThreshold-1][1])
			if percent > 1 then percent = 1 end
			color = VILib:GetTransitionColorFromRGB(self.settings.tThresholds[nThreshold-1][2], self.settings.tThresholds[nThreshold][2], percent)
		else
			color = {r = self.settings.tThresholds[nThreshold][2][1], g = self.settings.tThresholds[nThreshold][2][2], b = self.settings.tThresholds[nThreshold][2][3]}
		end
	end
	color.a = 255
	return VILib:ConvertARGBColorToHex(color)
end

function LatencyMonitorEx:GetThreshold(nLatency)
	local nThreshold = 3
	local nGraphicThreshold = 4
	for i, v in ipairs(self.settings.tThresholds) do
		if nLatency < v[1] then
			nThreshold = i
			nGraphicThreshold = i
			break
		end
	end
	return nThreshold, nGraphicThreshold
end

function LatencyMonitorEx:SetSettings()
	self:SetGraphic()
	local nSize = 0
	if self.settings.bShowOrb then
		nSize = self.settings.nOrbSize
		self.wndMain:FindChild("OrbContainer"):SetAnchorOffsets(0, -(nSize * 0.5), nSize, (nSize * 0.5))
		self.wndMain:FindChild("OrbContainer"):Show(true, true)
		nSize = nSize + 2
		if not self.settings.bColorOrb then
			self.wndMain:FindChild("Orb"):SetBGColor("ffffffff")
		end
	else
		self.wndMain:FindChild("OrbContainer"):Show(false, true)
	end
	local strMs = ""
	if self.settings.bShowMs then strMs = " ms" end
	self.strOutput = string.format(self.strOutputFontWrapper, "CRB_" .. arFontTypes[self.settings.nFontType] .. arFontSizes[self.settings.nFontType][self.settings.nFontSize] .. "_O", self.settings.sTextColor, "%s")
	if self.settings.bShowText then
		if self.settings.bShowNetworkLatency then
			self.strOutput = string.format(self.strOutput, "%s / %s" .. strMs)
			self.strOutput = string.format(self.strOutput, string.format(self.strOutputColorWrapper, "%s", "%s"), string.format(self.strOutputColorWrapper, "%s", "%s"))
		else
			self.strOutput = string.format(self.strOutput, string.format(self.strOutputColorWrapper, "%s", "%s") .. strMs)
		end
		local nOffset = arFontSizes[self.settings.nFontType][self.settings.nFontSize]
		if not tonumber(nOffset) then nOffset = 9 end
		if self.settings.nFontType > 1 then nOffset = nOffset + 1 end
		local nOffsetTop = arTextOffsets[2] - (nOffset - 9)
		self.wndMain:FindChild("TextContainer:Text"):SetAnchorOffsets(arTextOffsets[1], nOffsetTop, arTextOffsets[3], arTextOffsets[4])
		self.wndMain:FindChild("TextContainer"):SetAnchorOffsets(nSize, 0, 0, 0)
		self.wndMain:FindChild("TextContainer"):Show(true, true)
	else
		self.wndMain:FindChild("TextContainer"):Show(false, true)
	end

	self:OnUpdateLatency()
end

function LatencyMonitorEx:SetPosition()
	self.wndMain:SetAnchorPoints(unpack(VILib.tAnchors[self.settings.nMainAnchorID].tPoints))
	self.wndMain:SetAnchorOffsets(self:GetOffsets())
end

function LatencyMonitorEx:GetOffsets()
	local nOL, nOT, nOR, nOB = unpack(self.settings.tWindowOffsets[self.settings.nMainAnchorID])
	if nOL == 0 and nOR == 0 then
		local nOLM, nORM = VILib.tAnchors[self.settings.nMainAnchorID].tOffsetMults[1], VILib.tAnchors[self.settings.nMainAnchorID].tOffsetMults[3]
		nOL, nOR = VILib:Round(arSize[1] * nOLM), VILib:Round(arSize[1] * nORM)
	end
	if nOT == 0 and nOB == 0 then
		local nOTM, nOBM = VILib.tAnchors[self.settings.nMainAnchorID].tOffsetMults[2], VILib.tAnchors[self.settings.nMainAnchorID].tOffsetMults[4]
		nOT, nOB = VILib:Round(arSize[2] * nOTM), VILib:Round(arSize[2] * nOBM)
	end
	return nOL, nOT, nOR, nOB
end

function LatencyMonitorEx:SetGraphic(nLatency)
	local nLatency = nLatency or 100
	local strTmpThreshold = tostring(5 - self:GetThreshold(nLatency))
	local nID = self.settings.nGraphicID
	local strGraphic = arGraphicIDs[nID]
	if arStateChangingGraphics[nID] then strGraphic = strGraphic .. strTmpThreshold end
	self.wndMain:FindChild("Orb"):SetSprite("VLM:" .. strGraphic)
	if arGraphicHasHighlight[nID] then
		self.wndMain:FindChild("Highlight"):SetSprite("VLM:" .. strGraphic .. "Highlight")
		self.wndMain:FindChild("Highlight"):Show(true, true)
	else
		self.wndMain:FindChild("Highlight"):Show(false, true)
	end
end

function LatencyMonitorEx:OnSlashCommand(strCmd, strParam)
	if strParam ~= "" then
		local tParams = {}
		for w in string.gmatch(strParam, "%S*") do
			if w ~= "" then
				if tonumber(w) then
					table.insert(tParams, tonumber(w))
				else
					table.insert(tParams, string.lower(w))
				end
			end
		end
		if tParams[1] == "reset" or tParams[1] == "defaults" then
			self.settings = VILib:CopyTable(tDefaultSettings)
			VILib:WriteToChat("Options reset to defaults.")
		end
	else
		self:ShowHideOptions()
	end
end


---------------------------------------------------------------------------------------------------
-- OptionsList Functions
---------------------------------------------------------------------------------------------------

function LatencyMonitorEx:SetOptions()
	local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Slider"):SetMinMax(-nScreenWidth, nScreenWidth)
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Slider"):SetMinMax(-nScreenHeight, nScreenHeight)

	self:FillAnchorList()
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Slider"):SetValue(self.settings.tWindowOffsets[self.settings.nMainAnchorID][1])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Output"):SetText(self.settings.tWindowOffsets[self.settings.nMainAnchorID][1])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Slider"):SetValue(self.settings.tWindowOffsets[self.settings.nMainAnchorID][2])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Output"):SetText(self.settings.tWindowOffsets[self.settings.nMainAnchorID][2])

	self.wndOptionsList:FindChild("LookOptionsContainer:OrbShow:Button"):SetCheck(self.settings.bShowOrb)
	self.wndOptionsList:FindChild("LookOptionsContainer:OrbStyle:Slider"):SetValue(self.settings.nGraphicID)
	self.wndOptionsList:FindChild("LookOptionsContainer:OrbStyle:Output"):SetText(arGraphicIDs[self.settings.nGraphicID])
	self.wndOptionsList:FindChild("LookOptionsContainer:ColorOrb:Button"):SetCheck(self.settings.bColorOrb)
	self.wndOptionsList:FindChild("LookOptionsContainer:TextShow:Button"):SetCheck(self.settings.bShowText)
	self.wndOptionsList:FindChild("LookOptionsContainer:MsShow:Button"):SetCheck(self.settings.bShowMs)
	self.wndOptionsList:FindChild("LookOptionsContainer:ColorTextUse:Button"):SetCheck(self.settings.bColorText)
	self.wndOptionsList:FindChild("LookOptionsContainer:TransitionColorsUse:Button"):SetCheck(self.settings.bTransitionColor)
	self.wndOptionsList:FindChild("LookOptionsContainer:UpdateFrequency:Slider"):SetValue(self.settings.fUpdateFrequency)
	self.wndOptionsList:FindChild("LookOptionsContainer:UpdateFrequency:Output"):SetText(VILib:Round(self.settings.fUpdateFrequency, 1, true) .. " sec")
	self.wndOptionsList:FindChild("LookOptionsContainer:ShowNetworkLatency:Button"):SetCheck(self.settings.bShowNetworkLatency)
	self.wndOptionsList:FindChild("LookOptionsContainer:OrbSize:Slider"):SetValue(self.settings.nOrbSize)
	self.wndOptionsList:FindChild("LookOptionsContainer:OrbSize:Output"):SetText(self.settings.nOrbSize)
	self.wndOptionsList:FindChild("TextColor"):FindChild("ColorSwatch"):SetBGColor(self.settings.sTextColor)

	self.wndOptionsList:FindChild("FontOptionContainer:FontType:Slider"):SetValue(self.settings.nFontType)
	self.wndOptionsList:FindChild("FontOptionContainer:FontType:Output"):SetText(arFontTypes[self.settings.nFontType])
	self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Slider"):SetMinMax(1, #arFontSizes[self.settings.nFontType])
	self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Slider"):SetValue(self.settings.nFontSize)
	self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Output"):SetText(arFontSizes[self.settings.nFontType][self.settings.nFontSize])

	for i = 1, 3 do
		self.wndOptionsList:FindChild("ThresholdContainer:Threshold" .. i .. ":Slider"):SetValue(self.settings.tThresholds[i][1])
		self.wndOptionsList:FindChild("ThresholdContainer:Threshold" .. i .. ":Output"):SetText(self.settings.tThresholds[i][1] .. " ms")
	end

	local strText = ""
	for k, v in pairs(tLatencyDisclaimer) do
		strText = strText .. "<P>" .. v .. "</P><P TextColor=\"00ffffff\">-</P>"
	end
	strText = string.format(strLatencyDisclaimer, strText)
	self.wndOptionsList:FindChild("DisclaimerContent"):SetAML(strText)
	self.wndOptionsList:FindChild("DisclaimerContent"):SetVScrollPos(0)
end

function LatencyMonitorEx:ShowHideOptions()
	self.bOptionsOpen = not self.bOptionsOpen
	if not self.wndOptions then
		if not self.xmlDocOptions then self.xmlDocOptions = XmlDoc.CreateFromFile("Options.xml") end
		self.wndOptions = Apollo.LoadForm(self.xmlDocOptions, "OptionsForm", nil, self)
		self.wndOptionsList = Apollo.LoadForm(self.xmlDocOptions, "OptionsList", self.wndOptions:FindChild("ContentFrame"), self)
	end
	if self.bOptionsOpen then
		self:SetOptions()
		self.wndOptions:ToFront()
		local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()
		local nLeft, nTop, nRight, nBottom = self.wndOptions:GetRect()
		local nWidth, nHeight = nRight - nLeft, nBottom - nTop
		if self.settings.tOptionsWindowPos[1] then
			self.wndOptions:Move(VILib:Round(nScreenWidth * self.settings.tOptionsWindowPos[1]), VILib:Round(nScreenHeight * self.settings.tOptionsWindowPos[2]), nWidth, nHeight)
		else
			self.wndOptions:Move(VILib:Round((nScreenWidth / 2) - (nWidth / 2)), VILib:Round((nScreenHeight / 2) - (nHeight / 2)), nWidth, nHeight)
		end
	end
	self.wndOptions:Show(self.bOptionsOpen, false)

	self.wndMain:SetStyle("Moveable", self.bOptionsOpen)
	self.wndMain:SetStyle("IgnoreMouse", not self.bOptionsOpen)
end

function LatencyMonitorEx:OnOptionsWindowMove(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
	local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()
	local nPosLeft, nPosTop = self.wndOptions:GetPos()
	self.settings.tOptionsWindowPos[1], self.settings.tOptionsWindowPos[2] = nPosLeft / nScreenWidth, nPosTop / nScreenHeight
end

function LatencyMonitorEx:OnOptionsWindowClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self:ShowHideOptions()
end

function LatencyMonitorEx:OnOptionsWindowHide(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	if self.wndOptions then
		self.wndOptionsList:Destroy()
		self.wndOptionsList = nil
		self.wndOptions:Destroy()
		self.wndOptions = nil
	end
end


function LatencyMonitorEx:OnPosOffsetLeftSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.tWindowOffsets[self.settings.nMainAnchorID][1] = fNewValue
	self.settings.tWindowOffsets[self.settings.nMainAnchorID][3] = fNewValue + arSize[1]
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue)
	self:SetPosition()
end

function LatencyMonitorEx:OnPosOffsetTopSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.tWindowOffsets[self.settings.nMainAnchorID][2] = fNewValue
	self.settings.tWindowOffsets[self.settings.nMainAnchorID][4] = fNewValue + arSize[2]
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue)
	self:SetPosition()
end

function LatencyMonitorEx:OnMainAnchorButtonCheck(wndHandler, wndControl, eMouseButton)
	self.wndOptionsList:FindChild("AnchorParent"):Show(not self.bMainAnchorShown, true)
end

function LatencyMonitorEx:FillAnchorList()
	local nSel = 0
	self.wndOptionsList:FindChild("AnchorParent:AnchorGrid"):DeleteAll()
	for i, v in ipairs(VILib.tAnchors) do
		if self.settings.nMainAnchorID == i then
			self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtn"):SetText(v["sLabel"])
			nSel = i
		end
		self.wndOptionsList:FindChild("AnchorParent:AnchorGrid"):AddRow(v["sLabel"], "", v)
	end
	self.wndOptionsList:FindChild("AnchorParent:AnchorGrid"):SetCurrentRow(nSel)
end

function LatencyMonitorEx:OnMainAnchorGridSelChange(wndHandler, wndControl, nRow)
	local tData = wndControl:GetCellData(nRow, 1)
	if not tData then return end
	self.settings.nMainAnchorID = nRow
	local nOL, nOT, nOR, nOB = self:GetOffsets()
	self.wndOptionsList:FindChild("AnchorParent"):Show(false)
	self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtn"):SetText(tData["sLabel"])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Slider"):SetValue(nOL)
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Output"):SetText(nOL)
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Slider"):SetValue(nOT)
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Output"):SetText(nOT)
	self:SetPosition()
end

function LatencyMonitorEx:OnMouseDownCatcher(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation)
end

function LatencyMonitorEx:OnMainAnchorShow(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self:FillAnchorList()
	self.bMainAnchorShown = true
	self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtnBG"):SetCheck(true)
	self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtn:Arrow"):SetSprite("CRB_Basekit:kitIcon_Holo_UpArrow")
	self.wndOptionsList:SetStyle("Escapable", false)
end

function LatencyMonitorEx:OnMainAnchorClosed(wndHandler, wndControl)
	if wndHandler ~= wndControl then return end
	self.bMainAnchorShown = false
	self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtnBG"):SetCheck(false)
	self.wndOptionsList:FindChild("PositionContainer:Anchor:DropdownBtn:Arrow"):SetSprite("CRB_Basekit:kitIcon_Holo_DownArrow")
	self.EscapeTimer = ApolloTimer.Create(0.1, false, "OnMainEscapableTimer", self)
end

function LatencyMonitorEx:OnMainAnchorButtonEnter(wndHandler, wndControl, x, y)
	self.wndOptionsList:FindChild("AnchorParent"):SetStyle("CloseOnExternalClick", false)
end

function LatencyMonitorEx:OnMainAnchorButtonExit(wndHandler, wndControl, x, y)
	self.wndOptionsList:FindChild("AnchorParent"):SetStyle("CloseOnExternalClick", true)
end

function LatencyMonitorEx:OnMainEscapableTimer()
	self.wndOptionsList:SetStyle("Escapable", true)
	self:SetSettings()
end

function LatencyMonitorEx:OnShowOrbButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bShowOrb = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnShowTextButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bShowText = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnShowMsButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bShowMs = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnShowNetworkLatencyButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bShowNetworkLatency = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnColorOrbButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bColorOrb = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnColorFromNetworkLatencyButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bColorFromNetworkLatency = wndControl:IsChecked()
	self:OnUpdateLatency()
end

function LatencyMonitorEx:OnColorTextUseButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bColorText = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnColorTransitionsUseButtonUp(wndHandler, wndControl, eMouseButton)
	self.settings.bTransitionColor = wndControl:IsChecked()
	self:SetSettings()
end

function LatencyMonitorEx:OnTextColorMouseUp(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY)
	if wndHandler ~= wndControl then return end
	GeminiColor:ShowColorPicker(self, "UpdateTextColor", true, self.settings.sTextColor)
end

function LatencyMonitorEx:UpdateTextColor(strColor)
	self.settings.sTextColor = strColor
	if self.wndOptionsList then self.wndOptionsList:FindChild("TextColor"):FindChild("ColorSwatch"):SetBGColor(self.settings.sTextColor) end
	self:SetSettings()
end

function LatencyMonitorEx:OnUpdateFrequencySliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.fUpdateFrequency = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(VILib:Round(fNewValue, 1, true) .. " sec")
	self.timerUpdater:Set(self.settings.fUpdateFrequency, true, "OnUpdateLatency")
end

function LatencyMonitorEx:OnFontTypeSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.nFontType = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(arFontTypes[fNewValue])
	self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Slider"):SetMinMax(1, #arFontSizes[fNewValue])
	if self.settings.nFontSize > #arFontSizes[fNewValue] then
		self.settings.nFontSize = #arFontSizes[fNewValue]
		self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Slider"):SetValue(self.settings.nFontSize)
	end
	self.wndOptionsList:FindChild("FontOptionContainer:FontSize:Output"):SetText(arFontSizes[fNewValue][self.settings.nFontSize])
	self:SetSettings()
end

function LatencyMonitorEx:OnFontSizeSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.nFontSize = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(arFontSizes[self.settings.nFontType][fNewValue])
	self:SetSettings()
end

function LatencyMonitorEx:OnOrbSizeSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.nOrbSize = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue)
	self:SetSettings()
end

function LatencyMonitorEx:OnThreshold1SliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	if fNewValue >= self.settings.tThresholds[2][1] then
		wndControl:SetValue(fOldValue)
		return
	end
	self.settings.tThresholds[1][1] = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue .. " ms")
	self:OnUpdateLatency()
end

function LatencyMonitorEx:OnThreshold2SliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	if fNewValue >= self.settings.tThresholds[3][1] or fNewValue <= self.settings.tThresholds[1][1] then
		wndControl:SetValue(fOldValue)
		return
	end
	self.settings.tThresholds[2][1] = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue .. " ms")
	self:OnUpdateLatency()
end

function LatencyMonitorEx:OnThreshold3SliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	if fNewValue <= self.settings.tThresholds[2][1] then
		wndControl:SetValue(fOldValue)
		return
	end
	self.settings.tThresholds[3][1] = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(fNewValue .. " ms")
	self:OnUpdateLatency()
end

function LatencyMonitorEx:OnOrbStyleSliderChanged(wndHandler, wndControl, fNewValue, fOldValue)
	self.settings.nGraphicID = fNewValue
	wndControl:GetParent():FindChild("Output"):SetText(arGraphicIDs[fNewValue])
	self:SetGraphic()
	self:OnUpdateLatency()
end


---------------------------------------------------------------------------------------------------
-- MainForm Functions
---------------------------------------------------------------------------------------------------

function LatencyMonitorEx:OnMainWindowMove(wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom)
	self.settings.tWindowOffsets[self.settings.nMainAnchorID] = VILib:Pack(self.wndMain:GetAnchorOffsets())
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Slider"):SetValue(self.settings.tWindowOffsets[self.settings.nMainAnchorID][1])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetLeft:Output"):SetText(self.settings.tWindowOffsets[self.settings.nMainAnchorID][1])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Slider"):SetValue(self.settings.tWindowOffsets[self.settings.nMainAnchorID][2])
	self.wndOptionsList:FindChild("PositionContainer:PosOffsetTop:Output"):SetText(self.settings.tWindowOffsets[self.settings.nMainAnchorID][2])
end



local LatencyMonitorExInst = LatencyMonitorEx:new()
LatencyMonitorExInst:Init()
