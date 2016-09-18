-----------------------------------------------------------------------------------------------
-- Was it Worth It Bar (WiWiBar) by Sephius
-- Any questions/suggestions/bug reports ? 
--> julien.foucher@memory-leaks.org
--> curse username :
-- or contact me IG (Tyrah, server Eko, EU)
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- WiWiBar Module Definition
-----------------------------------------------------------------------------------------------
local WiWiBar = {} 

local BarHeight = 15
local BarPosY = 0


local tTableInfo =
{
	nBaseDecal = 100,
	nBaseSpacing = 1,
	nCount = 0
}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
printEnabled = false
baseFont = "CRB_Header10"
UpdateInterval = .5
MaxCustomTab = 6
DatabaseScanInterval = 0.01

local QualityColor  = 
{
	"ItemQuality_Inferior",
	"ItemQuality_Average",
	"ItemQuality_Good",
	"ItemQuality_Excellent",
	"ItemQuality_Superb",
	"ItemQuality_Legendary",
	"ItemQuality_Artifact"  
}




----------------------------------------------------
-- usefull stuff
----------------------------------------------------
function sPrint( string )
	if printEnabled then Print("[WiWi] " .. tostring(string)) end
end

function QualityColorText( cl, txt, font )
	if font == nil then font = baseFont end
	return string.format('<P Font="%s" TextColor="%s">%s</P>', font, cl, txt)
end

function GetTimeValue(TimeValueSec)
	TimeValueSec = tonumber(TimeValueSec)
	if TimeValueSec == nil then TimeValueSec = 0 end
	TimeValueSec = math.floor(TimeValueSec)
	local subTime = 0
	local hours = math.floor(TimeValueSec / 3600)
	subTime = (hours * 3600)	
	local minuts = math.floor((TimeValueSec - subTime) / 60 )
	subTime = subTime + (minuts * 60)
	local seconds = TimeValueSec - subTime 
		
	if hours < 10 then hours = "0" .. hours end -- string.format('0%s', hours)
	if minuts < 10 then minuts = "0" .. minuts end -- string.format('0%d', minuts)
	if seconds < 10 then seconds = "0" .. seconds end -- string.format('0%d', seconds)
	
	return hours ..":" .. minuts ..":" .. seconds 
end

function GetLargeNumbers(number)

	local strNumber = tostring(number)
	local Length = string.len(strNumber)
	local RevertedStr = string.reverse(strNumber)
	local strBuffer = ""
	for i = 1, Length do
		if (i - 1) % 3 == 0 and  i ~= 1 then
			strBuffer = strBuffer .. ","
		end
		strBuffer = strBuffer .. string.sub(RevertedStr ,i,i) 
	end		
	strBuffer = string.reverse(strBuffer)
	return strBuffer 
end

function GetMoneyValue(number)
--ok, don't look at that, that's disgusting. Close your eyes, please
	local strNumber = tostring(number)
	local Length = string.len(strNumber)
	local RevertedStr = string.reverse(strNumber)
	local strBuffer = ""	
	for i = 1, Length do
		if  i == 1 and string.sub(RevertedStr ,i,i) ~= "-"  then
			strBuffer = strBuffer .. " c"
		elseif i == 3 and string.sub(RevertedStr ,i,i) ~= "-" then
			strBuffer = strBuffer .. " s"
		elseif i == 5 and string.sub(RevertedStr ,i,i) ~= "-" then
			strBuffer = strBuffer .. " g"
		elseif i == 7 and string.sub(RevertedStr ,i,i) ~= "-" then
			strBuffer = strBuffer .. " p"
		end
		strBuffer = strBuffer .. string.sub(RevertedStr ,i,i) 
	end	
	
	
	local LengthAdded = 0		
	local CurLen = string.len(strBuffer )
	for i = 0, CurLen do
		local curStr = string.sub(strBuffer ,i,i)
		if curStr == " " then
			LengthAdded = LengthAdded + 1
		elseif curStr  == "c" or curStr  == "s" or curStr  == "g" or curStr  == "p" or curStr  == "-" then
			LengthAdded = LengthAdded + 1.5
		else
			LengthAdded = LengthAdded + 3
		end
	end	
	
	for i = 0, 44 - LengthAdded do
		strBuffer = strBuffer .. " "
	end
	
--	sPrint(tostring(15 - CurLen ))
	strBuffer = string.reverse(strBuffer)
	
--you can open your eyes now	
	return strBuffer 
end


function WiWiBar:GetValuePerHour(value, floor)	
	if self.tCurrentRun.tTimeInfo.nTimeElapsed > 0 then
		if floor then 
			return math.floor((value * 3600) / self.tCurrentRun.tTimeInfo.nTimeElapsed)
		else
			return (value * 3600) / self.tCurrentRun.tTimeInfo.nTimeElapsed
		end
	end
	return 0
end

function GetCaseInsensitivePattern(pattern)
	pattern = pattern:gsub('%W','')
  -- find an optional '%' (group 1) followed by any character (group 2)
  local p = pattern:gsub("(%%?)(.)", function(percent, letter)

    if percent ~= "" or not letter:match("%a") then
      -- if the '%' matched, or `letter` is not a letter, return "as is"
      return percent .. letter
    else
      -- else, return a case-insensitive character class of the matched letter
      return string.format("%s%s", letter:lower(), letter:upper())
    end

  end)

  return p
end


------------------------------------------------
----------------------------------------------
---------------------------------------------

function WiWiBar:CreateTab(tab)	
	local xmlDoc = XmlDoc.CreateFromFile("WiWiBar.xml")
	wndTab = Apollo.LoadForm(xmlDoc , "TabForm", nil, tab)
	xmlDoc = nil	
--	wndTab:Show(true, true)
	return wndTab
end




local tLine = {}

function tLine:New(name, unit, valueType)
	local self = {}
	self.strName = tostring(name)
	self.Value = 0
	self.strValueType = tostring(valueType)
	self.strUnit = tostring(unit)
	
	function self:GetName()
		return self.strName
	end

	function self:GetValue()
		return self.Value
	end

	function self:GetValueType()
		return self.strValueType
	end

	function self:GetUnit()
		return self.strUnit
	end
	
	function self:SetName(strName)
		self.strName = strName
	end

	function self:SetValue(value)
		self.Value = value
	end

	function self:SetValueType(strValueType)
		self.strValueType = strValueType
	end

	function self:SetUnit(strUnit)
		self.strUnit = strUnit
	end
	
	function self:GetValueStr()
		if self.strValueType == "str" then
			return self.Value
		elseif self.strValueType == "int" then
			return GetLargeNumbers(self.Value)
		elseif self.strValueType == "time" then
			return GetTimeValue(self.Value)
		elseif self.strValueType == "money" then
			return GetMoneyValue(self.Value)
		end
		
		return "GetValueStr error"
	end
	
	return self
end

local tTab = {}

function tTab:New(name, strType, nIDParam)
	local self = {}
	self.nItemID = nil
	self.strType = "unknown"
	
	if nIDParam ~= nil then
		self.nItemID = nIDParam
	end

	if strType ~= nil then
		self.strType = strType
	end
	
	self.bPinned = true
	self.strName = name
	self.nLineCount = 0
	self.tLines = {}	
	self.fullDisplay = false
	self.fullDisplayStay = false	
	self.tabSize = {0, 0, 185, 16}
	self.currentSizeX = 185
	self.currentSizeY = 16
	self.CenterPosY = -2
	self.currentPosY = 0	
	self.BasePosX = tTableInfo.nBaseDecal + tTableInfo.nCount * self.tabSize[3] + tTableInfo.nBaseSpacing * tTableInfo.nCount	
	self.wndTab = WiWiBar:CreateTab(self)
	self.tabGrid = self.wndTab:FindChild("WindowGrid")
	self.tabGrid:SetAnchorOffsets(self.BasePosX, 0, self.BasePosX + self.tabSize[3], self.tabSize[4])
	self.AnchorPos = {self.tabGrid:GetAnchorOffsets()}
	self.wndIcon = self.wndTab:FindChild("GridIcon")

	self.bDisplayed = true
	
	
--[[	
	if self.strType == "unknown" then
		sPrint("rien")
		self.wndIcon:Show(false, true)
	elseif self.strType == "item" and self.nItemID ~= nil then
		sPrint("lalala")
		sPrint(Item.GetDataFromId(self.nItemID):GetIcon())
		self.wndIcon:SetSprite(Item.GetDataFromId(self.nItemID):GetIcon())	
	end
--]]	
	if self.nItemID ~= nil then	
--		sPrint(self.nItemID)
		local rowIndex = self.wndIcon:AddRow("")
		local itItem = Item.GetDataFromId(self.nItemID)
		if itItem then
--			sPrint("item found")
--			sPrint(itItem:GetName())
			self.wndIcon:SetCellImage(rowIndex , 1, tostring(itItem:GetIcon()))
		else
			self.wndIcon:Show(false, true)
		end
	else
		self.wndIcon:Show(false, true)
	end
	
	self.CellMaxChar = 0
	tTableInfo.nCount = tTableInfo.nCount + 1
	
	function self:Delete()
--		if self.wndIcon then
--			self.wndIcon:Destroy()
--		end
--		self.tabGrid:Destroy()
		self.wndTab:Destroy()
		tTableInfo.nCount = tTableInfo.nCount - 1
	end
	
	function self:Show(bShow)
		self.tabGrid:Show(bShow, true)
	end
	
	function self:GetItemID()
		return self.nItemID
	end

	function self:GetName()
		return self.strName
	end
	
	function self:GetLineCount()
		return self.nLineCount 
	end
	
	function self:GetLineArray()
		return self.tLines
	end
	
	function self:AddLine(strName, strUnit, strValueType)
		local SizeUnit = string.len(strUnit)
		if SizeUnit > self.CellMaxChar then 
			self.CellMaxChar = SizeUnit 
			self:ResizeCelFromCharCount()
		end
		
		self.nLineCount = self.nLineCount + 1
		self.tLines[self.nLineCount] = tLine:New(strName, strUnit, strValueType)		
	end
	
	function self:ResizeCelFromCharCount()
		self.tabGrid:SetColumnWidth(1, 178 - (self.CellMaxChar * 6))
	end
	
	function self:GetLine(strName)
		for _, elem in pairs(self.tLines) do
			if elem:GetName() == strName then
				return elem
			end
		end
		return nil
	end	
	
	function self:OnLineSelected(wndControl, wndHandler, iRow, iCol, eMouseButton)
		local BufferLine = self.tLines[1]
		self.tLines[1] = self.tLines[iRow]
		self.tLines[iRow] = BufferLine
		self:Render()
	end
	
	function self:OnMouseEnter()
		self.fullDisplay = true
--		sPrint("enter")
		self:Unfold()
		self:Render()
	end
	
	function self:OnMouseExit()
		if self.fullDisplayStay == false then
			self.fullDisplay = false
--			sPrint("exit")
			self:Fold()
			self:CenterPos()
			self:Render()
		end
	end
	
	function self:SetTooltipStay()
		self.fullDisplayStay = true
	end
	
	function self:SetTooltipNotStay()
		self.fullDisplayStay = false
	end
	
	function self:SetPinned(bPinned)
		self.bPinned = bPinned
		if bPinned then self:CenterPos() end
	end
	
	function self:GetPinned()
		return self.bPinned
	end
	
	function self:SetPosX(posX)
		local AnchorBuffer = { self.tabGrid:GetAnchorOffsets() }
		AnchorBuffer[1] = 0 + posX
		AnchorBuffer[3] = posX + self.currentSizeX
		self.tabGrid:SetAnchorOffsets(AnchorBuffer[1], AnchorBuffer[2], AnchorBuffer[3], AnchorBuffer[4] )
		self.AnchorPos = AnchorBuffer
	end
	
	function self:CenterPos()
		if self.bPinned then			
			self.currentPosY = BarPosY 
			if self.currentPosY == nil then
				self.currentPosY = 0
			end
		end
		local AnchorBuffer = { self.tabGrid:GetAnchorOffsets() }
		AnchorBuffer[2] = 0 + self.CenterPosY + self.currentPosY
		AnchorBuffer[4] = self.currentSizeY + self.CenterPosY + self.currentPosY
		self.tabGrid:SetAnchorOffsets(AnchorBuffer[1], AnchorBuffer[2], AnchorBuffer[3], AnchorBuffer[4] )
		self.AnchorPos = AnchorBuffer 
		if AnchorBuffer[1] < 0 then
			self:SetPosX(0)
		end	
		if AnchorBuffer[1] > 1920 - self.currentSizeX then
			self:SetPosX(1920 - self.currentSizeX)
		end	
	end
	
	function self:OnWindowMove()
		if self.bPinned then			
			self:CenterPos()
		end			
	end
	
	function self:Unfold()

		local AnchorBuffer = { self.tabGrid:GetAnchorOffsets() }
		AnchorBuffer[4] = self.tabSize[4] * self.nLineCount	+ self.currentPosY
		self.currentSizeY = AnchorBuffer[4] - self.currentPosY
		self.tabGrid:SetAnchorOffsets(AnchorBuffer[1], AnchorBuffer[2], AnchorBuffer[3], AnchorBuffer[4])
		self.AnchorPos = AnchorBuffer 
--		sPrint("unfold "..self.currentPosY .. "   lines " .. self.nLineCount .."  cursizeY " .. self.currentSizeY)
--		self:CenterPos()
	end
	
	function self:Fold()

		local AnchorBuffer = { self.tabGrid:GetAnchorOffsets() }
		AnchorBuffer[4] = self.tabSize[4] + self.currentPosY
		self.currentSizeY = AnchorBuffer[4] - self.currentPosY
		self.tabGrid:SetAnchorOffsets(AnchorBuffer[1], AnchorBuffer[2], AnchorBuffer[3], AnchorBuffer[4])
		self.AnchorPos = AnchorBuffer 
--		sPrint("fold "..self.currentPosY .. "   lines " .. self.nLineCount .."  cursizeY " .. self.currentSizeY)
--		self:CenterPos()
	end
	
	function self:Render()
		self.tabGrid:DeleteAll()
		local rowIndex = 0
		if self.fullDisplay or self.fullDisplayStay then
			self.currentSizeY = self.tabSize[4]	* self.nLineCount
			for i = 1, self.nLineCount  do
				rowIndex = self.tabGrid:AddRow("")
				if self.tLines[i]:GetValueType() == "money" then
					if self.tLines[i]:GetValue() < 0 then
						self.tabGrid:SetCellDoc(rowIndex , 1, QualityColorText("red",self.tLines[i]:GetValueStr(), baseFont))
					else
						self.tabGrid:SetCellDoc(rowIndex , 1, QualityColorText("white",self.tLines[i]:GetValueStr(), baseFont))
					end
				else				
					self.tabGrid:SetCellText(rowIndex , 1, self.tLines[i]:GetValueStr())
				end
				self.tabGrid:SetCellText(rowIndex , 2, self.tLines[i]:GetUnit())
			end
		elseif self.tLines[1] ~= nil then
			self.currentSizeY = self.tabSize[4]
			rowIndex = self.tabGrid:AddRow("")
			if  self.tLines[1]:GetValueType() == "money" then
				if  self.tLines[1]:GetValue() < 0 then
					self.tabGrid:SetCellDoc(rowIndex , 1, QualityColorText("red", self.tLines[1]:GetValueStr(), baseFont))
				else
					self.tabGrid:SetCellDoc(rowIndex , 1, QualityColorText("white" ,self.tLines[1]:GetValueStr(), baseFont))
				end
			else				
				self.tabGrid:SetCellText(rowIndex , 1, self.tLines[1]:GetValueStr())
			end
			self.tabGrid:SetCellText(rowIndex , 2, self.tLines[1]:GetUnit())
		end
	end

	self:CenterPos()
	
	return self
end

 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WiWiBar:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
	self.tSavedData = 
	{
		REVISION = 0,
		tConfiguration =
		{
			bBarDisplayed = true,
			nBarPosY = 0,
			bBarDisplayedALL = true
		}
	}

    self.tCurrentRun = 
	{
		tTimeInfo = 
		{
			nTimeStarted 	= 0, 
			nTimeElapsed 		= 0, 
			nPauseTimeElapsed 	= 0,
			nPauseTimeStarted 	= 0
		},
		tItemInfo = 
		{
			nItemCount 	= 0, 
			tItemLooted = {}
		},
		tXpInfo = 
		{
			nPerHour 			= 0,
			nGained 			= 0,
			nFromMobs 			= 0,
			nNeeded 			= 0,
			nTimeBeforeUp 		= 0,
			nLevelGainedCount 	= 0,
			nAveragePerMob 		= 0,
			nMobNeeded 			= 0
		},
		tElderGemInfo = 
		{
			nGained			= 0,
			nPerHour 		= 0,
			nPreviousElderGemCount = 0
		},
		tRenownInfo = 
		{
			nAtStart		= 0,
			nGained			= 0,
			nPerHour 		= 0,
			nGainedOutOfRun = 0		
		},
		tMoneyInfo = 
		{
			nLooted 			= 0,
			nPerHour 			= 0,
			nFromJunk 			= 0,
			nTotal 				= 0,
			nCurrent 			= 0,
			nLost 				= 0,
			nEarnedThisFrame 	= 0
		},
		tMobInfo =
		{
			nKilledWithXpGainCount = 	0,
			nKilledWithXpGainPerHour = 	0	
		}		
	}
	
	self.tDisplay =
	{
		nCustomTabCount = 0,
		tCustomTab = {},
		tToolTip = 
		{
			tPlayerCurrentXpInfo 		= nil,
			tPlayerCurrentRenownInfo 	= nil,
			tPlayerCurrentMoneyInfo 	= nil,
			tPlayerCurrentElderGemInfo	= nil		
		},
		tWindowLoots = 
		{
			tFilters = 
			{
				chkInferior 	= nil,
				chkAverage  	= nil,
				chkGood	 		= nil,
				chkExcellent 	= nil,
				chkSuperb		= nil,
				chkLegendary	= nil,
				chkArtifact		= nil,
				chkQualAll 		= nil,
				wstrSearch		= nil,
				strFilterSearch = "",
				bFilterSearch = false
			},
			wndTrackedItemIndicator = nil,
			wndButtonTrack = nil,
			wndSearchIndicator = nil,
			wndGridLoot = nil,
			wndLoots 	= nil,
			strFilterSearch = "",
			bFilterSearch = false
		},
		tSectionSwitchCkeck =
		{
			chkSettings 	= nil,
			chkLoots 		= nil,
			chkItemSearch 	= nil,
			chkTracked		= nil
		},
		tWindowItemSearch =
		{			
			tFilters = 
			{
				chkInferior 	= nil,
				chkAverage  	= nil,
				chkGood	 		= nil,
				chkExcellent 	= nil,
				chkSuperb		= nil,
				chkLegendary	= nil,
				chkArtifact		= nil,
				chkQualAll 		= nil,
				wstrSearch		= nil,
				strFilterSearch = "",
				bFilterSearch 	= false
			},
			wndItemSearch = nil,
			wndSearchIndicator = nil,
			wndGridSearch = nil

		},
		tWindowSettings =
		{
			wndSettings = nil,
			wndBarPosYTxtBox = nil,
			tCheck =
			{
				chkDisplayBarBackground = nil				
			}
		}
	}
	
	self.SettingsRestored = false
	

	
	self.SessionStarted = false	
	self.Paused = false
	
	self.bBuildingDatabase = false
	self.nDatabasePercentBuilded = 0
	self.nDatabaseItemLooked = 0
	
	self.lootSortType = "cost"
	self.sortUp = false

	self.XpTooltipStay = false
	self.MoneyTooltipStay = false
	self.RenownTooltipStay = false
	self.bItemSelected = false
	self.screenSizeX, self.screenSizeY = Apollo.GetScreenSize()	

    return o
end

function WiWiBar:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- WiWiBar OnLoad
-----------------------------------------------------------------------------------------------
function WiWiBar:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("WiWiBar.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-- save session data
function WiWiBar:OnSave(eType)
--	if eType ~= GameLib.CodeEnumAddonSaveLevel.General then return end
	self.tSavedData.REVISION = self.tSavedData.REVISION + 1
	return self.tSavedData
end

-- restore session data
function WiWiBar:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData or self.tSavedData
--	self.tSavedData = self.tSavedData
--	self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground:SetCheck(self.tSavedData.tConfiguration.bBarDisplayed)
--	self.wndMain:Show(self.tSavedData.tConfiguration.bBarDisplayed, true)
end

-----------------------------------------------------------------------------------------------
-- WiWiBar OnDocLoaded
-----------------------------------------------------------------------------------------------
function WiWiBar:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "WiWiBarForm", nil, self)
		self.wndMainWin = Apollo.LoadForm(self.xmlDoc, "MainForm", nil, self)
		self.wndTimer = Apollo.LoadForm(self.xmlDoc, "TimerContainer", nil, self)
	
		self.tDisplay.tWindowLoots.wndLoots = self.wndMainWin:FindChild("wndLoots")
		self.tDisplay.tWindowItemSearch.wndItemSearch = self.wndMainWin:FindChild("wndItemSearch")
		self.tDisplay.tWindowSettings.wndSettings = self.wndMainWin:FindChild("wndSettings")
		

		self.tDisplay.tWindowSettings.wndBarPosYTxtBox = self.wndMainWin:FindChild("BarPosYTxtBox")
		
		self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground = self.tDisplay.tWindowSettings.wndSettings:FindChild("ButtonDisplayBarBackground")
		self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground:SetCheck(true)
		
		self.tDisplay.tWindowLoots.wndSearchIndicator = self.tDisplay.tWindowLoots.wndLoots:FindChild("SearchIndicator")
		self.tDisplay.tWindowItemSearch.wndSearchIndicator = self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("SearchIndicator")
		
		
		self.tDisplay.tWindowLoots.wndButtonTrack = self.tDisplay.tWindowLoots.wndLoots:FindChild("TackItemButton")
		self.tDisplay.tWindowLoots.wndButtonTrack:Show(true, true)
		self.tDisplay.tWindowLoots.wndTrackedItemIndicator = self.tDisplay.tWindowLoots.wndLoots:FindChild("ItemTrackedIndicator")
		self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(false, true)		
		
		
		self.tDisplay.tWindowLoots.tFilters.chkInferior 	= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckInferior")
		self.tDisplay.tWindowLoots.tFilters.chkAverage  	= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckAverage")
		self.tDisplay.tWindowLoots.tFilters.chkGood			= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckGood")
		self.tDisplay.tWindowLoots.tFilters.chkExcellent 	= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckExcellent")
		self.tDisplay.tWindowLoots.tFilters.chkSuperb		= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckSuperb")
		self.tDisplay.tWindowLoots.tFilters.chkLegendary	= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckLegendary")
		self.tDisplay.tWindowLoots.tFilters.chkArtifact		= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckArtifact")
		self.tDisplay.tWindowLoots.tFilters.chkQualAll		= self.tDisplay.tWindowLoots.wndLoots:FindChild("LootCheckQualAll")
		self.tDisplay.tWindowLoots.tFilters.wstrSearch		= self.tDisplay.tWindowLoots.wndLoots:FindChild("SearchBoxTxt")

		self.tDisplay.tWindowLoots.tFilters.chkInferior:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkAverage:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkGood:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkExcellent:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkSuperb:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkLegendary:SetCheck(true)
		self.tDisplay.tWindowLoots.tFilters.chkArtifact:SetCheck(true)	
		self.tDisplay.tWindowLoots.tFilters.chkQualAll:SetCheck(true)	
		
		self.tDisplay.tWindowItemSearch.tFilters.chkInferior 	= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckInferior")
		self.tDisplay.tWindowItemSearch.tFilters.chkAverage  	= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckAverage")
		self.tDisplay.tWindowItemSearch.tFilters.chkGood		= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckGood")
		self.tDisplay.tWindowItemSearch.tFilters.chkExcellent 	= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckExcellent")
		self.tDisplay.tWindowItemSearch.tFilters.chkSuperb		= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckSuperb")
		self.tDisplay.tWindowItemSearch.tFilters.chkLegendary	= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckLegendary")
		self.tDisplay.tWindowItemSearch.tFilters.chkArtifact	= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckArtifact")
		self.tDisplay.tWindowItemSearch.tFilters.chkQualAll		= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("LootCheckQualAll")
		self.tDisplay.tWindowItemSearch.tFilters.wstrSearch		= self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("SearchBoxTxt")

		self.tDisplay.tWindowItemSearch.tFilters.chkInferior:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkAverage:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkGood:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkExcellent:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkSuperb:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkLegendary:SetCheck(true)
		self.tDisplay.tWindowItemSearch.tFilters.chkArtifact:SetCheck(true)	
		self.tDisplay.tWindowItemSearch.tFilters.chkQualAll:SetCheck(true)
		
		self.tDisplay.tSectionSwitchCkeck.chkSettings 		= self.wndMainWin:FindChild("SettingsButton")
		self.tDisplay.tSectionSwitchCkeck.chkLoots 			= self.wndMainWin:FindChild("LootsButton")
		self.tDisplay.tSectionSwitchCkeck.chkItemSearch 	= self.wndMainWin:FindChild("ItemSearchButton")
		self.tDisplay.tSectionSwitchCkeck.chkTracked		= self.wndMainWin:FindChild("ItemsTrackedButton")
		
		self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(false)
		self.tDisplay.tSectionSwitchCkeck.chkSettings:SetCheck(false)		
		self.tDisplay.tSectionSwitchCkeck.chkItemSearch:SetCheck(false)
		
		
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndMain:Show(false, true)
		self.wndMainWin:Show(false, true)
		self.wndMainWin:FindChild("MaxTabReached"):Show(false, true)

		
		
		self.tDisplay.tWindowLoots.wndGridLoot = self.wndMainWin:FindChild("LootGrid")
		self.tDisplay.tWindowItemSearch.wndGridSearch = self.tDisplay.tWindowItemSearch.wndItemSearch:FindChild("ItemSearchGrid")

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		
		Apollo.RegisterSlashCommand("wiwibar", "OnDisplayMainWin", self)
		Apollo.RegisterSlashCommand("wiwi", "OnDisplayMainWin", self)
		Apollo.RegisterSlashCommand("wiwitest", "SlashTest", self)
		Apollo.RegisterSlashCommand("wiwisettings", "OnDisplaySettings", self)
		Apollo.RegisterSlashCommand("wiwiset", "OnDisplaySettings", self)
		Apollo.RegisterSlashCommand("wiwiloot", "OnDisplayLoots", self)
		Apollo.RegisterSlashCommand("wiwiloots", "OnDisplayLoots", self)
		
		Apollo.RegisterEventHandler("LootedItem", "OnLootedItem", self)
		Apollo.RegisterEventHandler("LootedMoney", "OnLootedMoney",	self)
		Apollo.RegisterEventHandler("CashWindowAmountChanged", "OnCashWindowAmountChanged",	self)
		Apollo.RegisterEventHandler("ElderPointsGained", "OnElderPointsGained",	self)
		Apollo.RegisterEventHandler("ExperienceGained", "OnExperienceGained",	self)
		Apollo.RegisterEventHandler("PlayerLevelChange", "OnLevelUp",	self)
		
		Apollo.RegisterEventHandler("MatchEntered", "OnMatchEntered",	self)
		Apollo.RegisterEventHandler("MatchFinished", "OnMatchFinished",	self)
		Apollo.RegisterEventHandler("MatchExited", "OnMatchExited",	self)
		Apollo.RegisterEventHandler("MatchJoined", "OnMatchJoined",	self)
		Apollo.RegisterEventHandler("MatchLeft", "OnMatchLeft",	self)
		

		
		-- Do additional Addon initialization here
		Apollo.RegisterTimerHandler("UpdateTimer", "UpdateAll", self)
		Apollo.CreateTimer("UpdateTimer", UpdateInterval, true)
		self.tDatabaseScanTimer = ApolloTimer.Create(DatabaseScanInterval, true, "OnTimerDatabaseBuild", self)
		self.tDatabaseScanTimer:Stop()
		
		self.tDisplay.tWindowLoots.wndLoots:Show(false, true)
		self.tDisplay.tWindowItemSearch.wndItemSearch:Show(false, true)
		self.tDisplay.tWindowSettings.wndSettings:Show(false, true)
		
		self:InitialiseAllTab()
		
		self:OnDisplayBar()
--		self.wndMain:Invoke()
		
		self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(true)
		self:OnCheckLoots()
		
		self.wndTimer:FindChild("startButton"):SetCheck(true)
		self:OnStartButtonChecked()				
	end
end

--PVP/PVE
function WiWiBar:OnMatchJoined()
--	sPrint("MatchJoined")
end
function WiWiBar:OnMatchEntered()
--	sPrint("OnMatchEntered")
end
function WiWiBar:OnMatchFinished()
--	sPrint("OnMatchFinished")
end
function WiWiBar:OnMatchExited()
--	sPrint("OnMatchExited")
end
function WiWiBar:OnMatchLeft()
--	sPrint("OnMatchLeft")
end


function WiWiBar:OnCashWindowAmountChanged()
	sPrint("Changed")
end
		
		
		
		
		
		


----------------------
-----------------------
------------------------
function WiWiBar:SlashTest()
--	self:BuildDatabase()
--	self:BeginDatabaseScan()
--	self.tItemDatabase = nil
--		self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground:SetCheck(self.tSavedData.tConfiguration.bBarDisplayed)
--		self.wndMain:Show(self.tSavedData.tConfiguration.bBarDisplayed, true)
		sPrint(" bar disp ")-- .. tostring(self.tSavedData.tConfiguration.bBarDisplayed))
end

function WiWiBar:RestoreAllSettings()

	if self.tSavedData.tConfiguration.bBarDisplayed == nil 		then self.tSavedData.tConfiguration.bBarDisplayed = true end
	if self.tSavedData.tConfiguration.nBarPosY == nil 			then self.tSavedData.tConfiguration.nBarPosY = 0 end
	if self.tSavedData.tConfiguration.bBarDisplayedALL == nil 	then self.tSavedData.tConfiguration.bBarDisplayedALL = true end
	
	self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground:SetCheck(self.tSavedData.tConfiguration.bBarDisplayed)
	self.wndMain:Show(self.tSavedData.tConfiguration.bBarDisplayed, true)
	
	if self.tSavedData.tConfiguration.bBarDisplayedALL then
		self:OnCheckDisplayBarALL()
	else
		self:OnUncheckDisplayBarALL()
	end

	self.tDisplay.tWindowSettings.wndSettings:FindChild("ButtonDisplayBarALL"):SetCheck( self.tSavedData.tConfiguration.bBarDisplayedALL )
		
	self.tDisplay.tWindowSettings.wndBarPosYTxtBox:SetText(self.tSavedData.tConfiguration.nBarPosY)
	self:CenterAllPinnedTab()
	self:SetBarPosY(self.tSavedData.tConfiguration.nBarPosY)
	
	self.SettingsRestored = true
end


local updatecount = 0

function WiWiBar:UpdateAll(bTimerStop)
	if bTimerStop == nil then
		self:UpdateTimeElapsed()
	end
	if updatecount < 2 then
		self:RestoreAllSettings()
	end

	self:UpdateValues()
	self:UpdateToolTips()
	
	self:RenderToolTips()
	
	updatecount = updatecount  + 1
end

function WiWiBar:UpdateValues()
	self:UpdateMoneyValues()
	self:UpdateExperienceValues()
	self:UpdateRenownValues()
	self:UpdateElderGemValues()
end

function WiWiBar:UpdateToolTips()
	self:UpdateExperienceToolTip()
	self:UpdateRenownToolTip()
	self:UpdateMoneyToolTip()
	self:UpdateElderGemTooltip()
	self:UpdateAllCustomTab()
end

function WiWiBar:RenderToolTips()
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:Render()
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:Render()
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:Render()
	if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:Render()
	end
	self:RenderAllCustomTab()
end

function WiWiBar:UpdateAllCustomTab()
	local itemID = 0
	local itemCount = 0
	local itemPerHour = 0
	for i = 1, self.tDisplay.nCustomTabCount do
		itemID = self.tDisplay.tCustomTab[i]:GetItemID()
		if itemID then
			itemCount = self:GetLootedItemCountPerID(itemID)
			itemPerHour = self:GetValuePerHour(itemCount , true)
			self.tDisplay.tCustomTab[i]:GetLine("total"):SetValue(itemCount )
			self.tDisplay.tCustomTab[i]:GetLine("perHour"):SetValue(itemPerHour )
		end
	end
end

function WiWiBar:RenderAllCustomTab()
	for i = 1, self.tDisplay.nCustomTabCount do
		self.tDisplay.tCustomTab[i]:Render()
	end
end







function WiWiBar:OnLevelUp(uLevel)
	self.tCurrentRun.tXpInfo.nLevelGainedCount = self.tCurrentRun.tXpInfo.nLevelGainedCount + 1
end





-----------------------------------------------------------------------------------------------
-- WiWiBar Functions
-----------------------------------------------------------------------------------------------
-- on SlashCommand "/wiwi"
function WiWiBar:OnDisplayMainWin()
	self.wndMainWin:Invoke() -- show the window
	if self.tDisplay.tSectionSwitchCkeck.chkSettings:IsChecked() then
		self:OnDisplaySettings()
	elseif self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
	
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		
	end
end

function WiWiBar:CenterAllPinnedTab()
	for i = 1, self.tDisplay.nCustomTabCount do
		if self.tDisplay.tCustomTab[i]:GetPinned() then
			self.tDisplay.tCustomTab[i]:CenterPos()
		end
	end	
	
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:CenterPos()
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:CenterPos() 
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:CenterPos()
	-- scsc: under level 50 no elder gem info
		if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:CenterPos()
	end
end

function WiWiBar:OnYPosTextChanged(wnd)
	local pos = tonumber(wnd:GetText())
	if pos ~= nil then
		self:SetBarPosY(pos)
		self:CenterAllPinnedTab()		
	end
end

function WiWiBar:OnSliderBarPosYChange(wndHandler, unknownStuff, fNewValue)
	--TODO !! at load, set the bar pos (slider)
	fNewValue = math.floor(fNewValue)
--	sPrint(tostring(fNewValue) )
	self.tDisplay.tWindowSettings.wndBarPosYTxtBox:SetText(fNewValue)
	self:SetBarPosY(fNewValue)
	self:CenterAllPinnedTab()	
end

function WiWiBar:SetBarPosY(nNexPosY)
	local AnchorBuffer = { self.wndMain:GetAnchorOffsets() }
	AnchorBuffer[2] = nNexPosY
	AnchorBuffer[4] = nNexPosY + BarHeight
	self.wndMain:SetAnchorOffsets(AnchorBuffer[1], AnchorBuffer[2], AnchorBuffer[3], AnchorBuffer[4] )		
	BarPosY = AnchorBuffer[2]
	self.tSavedData.tConfiguration.nBarPosY = BarPosY 
end

function WiWiBar:OnSortBar()
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:SetPosX(tTableInfo.nBaseDecal)
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:SetPosX(tTableInfo.nBaseDecal + 186) 
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:SetPosX(tTableInfo.nBaseDecal + 186 * 2)
	-- scsc: under level 50 no elder gem info
	if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:SetPosX(tTableInfo.nBaseDecal + 186 * 3)
	end
	
	for i = 1, self.tDisplay.nCustomTabCount do
		self.tDisplay.tCustomTab[i]:SetPosX(tTableInfo.nBaseDecal + 186 * (i + 3))
	end	
end

function WiWiBar:OnDisplaySettings()
	self.tDisplay.tWindowSettings.tCheck.chkDisplayBarBackground:SetCheck(self.tSavedData.tConfiguration.bBarDisplayed)
end

function WiWiBar:OnCheckDisplayBar()
	self.wndMain:Show(true, true)
	self.tSavedData.tConfiguration.bBarDisplayed = true
end

function WiWiBar:OnUncheckDisplayBar()
	self.wndMain:Show(false, true)
	self.tSavedData.tConfiguration.bBarDisplayed = false
end

function WiWiBar:OnCheckDisplayBarALL()
	if self then
		for _, item in pairs(self.tDisplay.tCustomTab) do
			item:Show(true)
		end

		self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:Show(true)
		self.tDisplay.tToolTip.tPlayerCurrentXpInfo:Show(true)
		self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:Show(true)
		-- scsc: under level 50 no elder gem info
		if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
			self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:Show(true)
		end
		if self.tSavedData.tConfiguration.bBarDisplayed then
			self.wndMain:Show(true, true)
		end
		self.tSavedData.tConfiguration.bBarDisplayedALL = true
	end
end

function WiWiBar:OnUncheckDisplayBarALL()
	if self then
		for _, item in pairs(self.tDisplay.tCustomTab) do
			item:Show(false)
		end
	
		self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:Show(false)
		self.tDisplay.tToolTip.tPlayerCurrentXpInfo:Show(false)
		self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:Show(false)
		-- scsc: under level 50 no elder gem info
		if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
			self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:Show(false)
		end
	

		self.wndMain:Show(false, true)
		self.tSavedData.tConfiguration.bBarDisplayedALL = false
	end
	
end


function WiWiBar:OnHideSearchWindow()
	self:AbordDatabaseScan()
end

function WiWiBar:OnCheckSettings()

	self.tDisplay.tWindowSettings.wndSettings:Show(true, true)
	self.tDisplay.tWindowLoots.wndLoots:Show(false, true)
	self.tDisplay.tWindowItemSearch.wndItemSearch:Show(false, true)

	self.tDisplay.tSectionSwitchCkeck.chkTracked:SetCheck(false)		
	self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkItemSearch:SetCheck(false)
	
end

function WiWiBar:OnUncheckSettings()
	self.tDisplay.tSectionSwitchCkeck.chkSettings:SetCheck(true)
end


function WiWiBar:OnCheckLoots()
	self.tDisplay.tWindowLoots.wndButtonTrack:Show(false, true)
	self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(false, true)
	
	self.tDisplay.tWindowSettings.wndSettings:Show(false, true)
	self.tDisplay.tWindowLoots.wndLoots:Show(true, true)
	self.tDisplay.tWindowItemSearch.wndItemSearch:Show(false, true)
	
	self.tDisplay.tSectionSwitchCkeck.chkTracked:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkSettings:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkItemSearch:SetCheck(false)
	
	self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
end

function WiWiBar:OnUncheckLoots()
	self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(true)
end

function WiWiBar:OnCheckItemSearch()
	self:BeginDatabaseScan()

	self.tDisplay.tWindowSettings.wndSettings:Show(false, true)
	self.tDisplay.tWindowLoots.wndLoots:Show(false, true)
	self.tDisplay.tWindowItemSearch.wndItemSearch:Show(true, true)

	
	self.tDisplay.tSectionSwitchCkeck.chkTracked:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkSettings:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(false)
	
--	self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)
end

function WiWiBar:OnUncheckItemSearch()
	self.tDisplay.tSectionSwitchCkeck.chkItemSearch:SetCheck(true)
end

function WiWiBar:OnCheckTracked()
	self.tDisplay.tWindowLoots.wndButtonTrack:Show(false, true)
	self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(false, true)
	
	self.tDisplay.tWindowItemSearch.wndItemSearch:Show(false, true)
	self.tDisplay.tWindowSettings.wndSettings:Show(false, true)
	self.tDisplay.tWindowLoots.wndLoots:Show(true, true)
	
	self.tDisplay.tSectionSwitchCkeck.chkItemSearch:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkSettings:SetCheck(false)
	self.tDisplay.tSectionSwitchCkeck.chkLoots:SetCheck(false)
	
	
	self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
end

function WiWiBar:OnUncheckTracked()
	self.tDisplay.tSectionSwitchCkeck.chkTracked:SetCheck(true)
end




function WiWiBar:OnSearchButtonPressed()
	local strFilterSearch = ""
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() or self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		strFilterSearch = self.tDisplay.tWindowLoots.tFilters.wstrSearch:GetText()
		if GetCaseInsensitivePattern(strFilterSearch) ~= "" then			
			self.tDisplay.tWindowLoots.tFilters.strFilterSearch = strFilterSearch 
			self.tDisplay.tWindowLoots.tFilters.bFilterSearch = true
			self.tDisplay.tWindowLoots.wndSearchIndicator:SetText("Search ON")
			self.tDisplay.tWindowLoots.wndSearchIndicator:SetTextColor("DispositionFriendly")
			if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
				self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
			else
				self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
			end
		else
			self:ClearSearchFieldLoots()
		end
		
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		strFilterSearch = self.tDisplay.tWindowItemSearch.tFilters.wstrSearch:GetText()
		if GetCaseInsensitivePattern(strFilterSearch) ~= "" then
		self.tDisplay.tWindowItemSearch.tFilters.strFilterSearch = strFilterSearch 
		self.tDisplay.tWindowItemSearch.tFilters.bFilterSearch = true
		self.tDisplay.tWindowItemSearch.wndSearchIndicator:SetText("Search ON")
		self.tDisplay.tWindowItemSearch.wndSearchIndicator:SetTextColor("DispositionFriendly")
		--ADD SORT
		else
			self:ClearSearchFieldItemSearch()
		end		
	end
end

function WiWiBar:ClearSearchFieldItemSearch()
	self.tDisplay.tWindowItemSearch.tFilters.wstrSearch:SetText("")
	self.tDisplay.tWindowItemSearch.tFilters.strFilterSearch = ""
	self.tDisplay.tWindowItemSearch.tFilters.bFilterSearch = false
	self.tDisplay.tWindowItemSearch.wndSearchIndicator:SetText("Search OFF")
	self.tDisplay.tWindowItemSearch.wndSearchIndicator:SetTextColor("ItemQuality_Inferior")
	--ADD SORT
end

function WiWiBar:ClearSearchFieldLoots()
	self.tDisplay.tWindowLoots.tFilters.wstrSearch:SetText("")
	self.tDisplay.tWindowLoots.tFilters.strFilterSearch = ""
	self.tDisplay.tWindowLoots.tFilters.bFilterSearch = false
	self.tDisplay.tWindowLoots.wndSearchIndicator:SetText("Search OFF")
	self.tDisplay.tWindowLoots.wndSearchIndicator:SetTextColor("ItemQuality_Inferior")
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	else
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
end

function WiWiBar:OnItemSelected(wndControl, wndHandler, iRow, iCol, eMouseButton)
	if iRow and self.tDisplay.tWindowLoots.wndGridLoot:GetRowCount() >= iRow then	
		if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() or self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
			self.nCurrentItemSelectedID = tonumber(self.tDisplay.tWindowLoots.wndGridLoot:GetCellText(iRow, 5))
			self.nCurrentRowSelected = iRow
			if self:IsItemAlreadyTracked(self.nCurrentItemSelectedID) then
				self.bItemSelected = false
				self.tDisplay.tWindowLoots.wndButtonTrack:SetText("Untrack")
				self.tDisplay.tWindowLoots.wndButtonTrack:Show(true, true)
				self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(true, true)
			else
				self.bItemSelected = true
				self.tDisplay.tWindowLoots.wndButtonTrack:SetText("Track")
				self.tDisplay.tWindowLoots.wndButtonTrack:Show(true, true)
				self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(false, true)
			end	
		end	
	else
		self.tDisplay.tWindowLoots.wndButtonTrack:Show(false, true)
	end	
end


function WiWiBar:OnCloseSettings()
	self.wndMainWin:Close()
	self:AbordDatabaseScan()
end

function WiWiBar:OnEscapeWindow()
	self:AbordDatabaseScan()
end


function WiWiBar:OnDisplayBar()
	if self.tSavedData.tConfiguration.bBarDisplayed == false then
		self.wndMain:Close()
	else
		self.wndMain:Invoke()
	end	
--	self.tSavedData.tConfiguration.bBarDisplayed = not self.tSavedData.tConfiguration.bBarDisplayed
end


function WiWiBar:OnStartButtonChecked()
	self.Paused = false	
	if self.SessionStarted then
		self.tCurrentRun.tTimeInfo.nPauseTimeElapsed = self.tCurrentRun.tTimeInfo.nPauseTimeElapsed + os.clock() - self.tCurrentRun.tTimeInfo.nPauseTimeStarted
	else
		self:ResetValues()
		self:StartNewRun()
	end
	self.SessionStarted = true
end

function WiWiBar:OnStartButtonUnchecked()
	self.Paused = true
	self.tCurrentRun.tTimeInfo.nPauseTimeStarted = os.clock()
end

function WiWiBar:InitialiseAllTab()
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo = tTab:New("MoneyTab")
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:AddLine("MoneyPerHour", "/Hour", "money" )
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:AddLine("MoneyFromLoot", " Looted", "money" )
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:AddLine("MoneyFromJunk", " Junk", "money" )
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:AddLine("MoneyLost", " Lost", "money" )
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:AddLine("MoneyTotal", " Total", "money" )	

	self.tDisplay.tToolTip.tPlayerCurrentXpInfo = tTab:New("XpTab")	
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("XpPerHour", "xp/hour", "int" )
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("XpTotal", "xp total", "int" )
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("XpNeeded", "xp needed", "int" )
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("TimeBeforeNextLevel", "Before up", "time" )
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("MobNeeded", "kill needed", "int" )
	if GameLib.GetPlayerLevel() and GameLib.GetPlayerLevel() < 50 then
		self.tDisplay.tToolTip.tPlayerCurrentXpInfo:AddLine("LevelGained", "lvl gained", "int" )
	else
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo = tTab:New("ElderGemTab")
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:AddLine("ElderGemPerHour", "EG/Hour", "int" )
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:AddLine("ElderGemTotal", "EG total", "int" )	
	end
	
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo = tTab:New("RenownTab")
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:AddLine("RenownPerHour", "R/Hour", "int" )
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:AddLine("RenownTotal", "R total", "int" )
	

	

end


function WiWiBar:ButtonResetPushed()
	self:ResetValues()
	self.wndTimer:FindChild("startButton"):SetCheck(false)
	self.wndTimer:SetText(GetTimeValue(0))
	self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	
	self:UpdateToolTips()
	self:RenderToolTips()
end

function WiWiBar:ResetValues()
    self.tCurrentRun.tTimeInfo.nTimeStarted = 0
	self.tCurrentRun.tTimeInfo.nTimeElapsed = 0
	self.tCurrentRun.tTimeInfo.nPauseTimeElapsed = 0
	self.tCurrentRun.tTimeInfo.nPauseTimeStarted = 0
	
	self.tCurrentRun.tItemInfo.nItemCount = 0
--	self.tCurrentRun.tItemInfo.tItemLooted = 0

	self.tCurrentRun.tXpInfo.nPerHour = 0
	self.tCurrentRun.tXpInfo.nGained = 0
	self.tCurrentRun.tXpInfo.nFromMobs = 0
	self.tCurrentRun.tXpInfo.nNeeded = 0
	self.tCurrentRun.tXpInfo.nTimeBeforeUp = 0
	self.tCurrentRun.tXpInfo.nLevelGainedCount = 0
	self.tCurrentRun.tXpInfo.nAveragePerMob = 0
	self.tCurrentRun.tXpInfo.nMobNeeded = 0	
	
	
	self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount = 0
	self.tCurrentRun.tElderGemInfo.nGained = 0
	self.tCurrentRun.tElderGemInfo.nPerHour = 0
	
	self.tCurrentRun.tRenownInfo.nAtStart = 0
	self.tCurrentRun.tRenownInfo.nGained = 0
	self.tCurrentRun.tRenownInfo.nPerHour = 0
	self.tCurrentRun.tRenownInfo.nGainedOutOfRun = 0
	
	self.tCurrentRun.tMoneyInfo.nLooted = 0
	self.tCurrentRun.tMoneyInfo.nPerHour = 0
	self.tCurrentRun.tMoneyInfo.nFromJunk = 0
	self.tCurrentRun.tMoneyInfo.nTotal = 0
	self.tCurrentRun.tMoneyInfo.nCurrent = 0
	self.tCurrentRun.tMoneyInfo.nLost = 0
	self.tCurrentRun.tMoneyInfo.nEarnedThisFrame = 0
	
	

	self.tCurrentRun.tMobInfo.nKilledWithXpGainCount = 0
	self.tCurrentRun.tMobInfo.nKilledWithXpGainPerHour = 0
	

	
	self.SessionStarted = false	
	self.Paused = false
--[[	
	for _,v in pairs(self.tCurrentRun.tItemLooted) do
--		sPrint("Item cleared -- " .. self.tCurrentRun.tItemLooted[v.nID].strName)
		self.tCurrentRun.tItemLooted[v.nID] = nil
	end
--]]
end

function WiWiBar:StartNewRun()
	self:ResetValues()
	self.SessionStarted = true

	self.tCurrentRun.tRenownInfo.nAtStart = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount()
	self.tCurrentRun.tMoneyInfo.nCurrent = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits):GetAmount()
	self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.ElderGems):GetAmount()
	
	self.tCurrentRun.tTimeInfo.nTimeStarted = os.clock()
end

----------------------------------------------------
--GOLD
----------------------------------------------------

function WiWiBar:OnLootedMoney(value)
	if self.Paused or self.SessionStarted == false then return end
	self.tCurrentRun.tMoneyInfo.nLooted = self.tCurrentRun.tMoneyInfo.nLooted + value:GetAmount()
	self.tCurrentRun.tMoneyInfo.nEarnedThisFrame = self.tCurrentRun.tMoneyInfo.nEarnedThisFrame + value:GetAmount()
end

function WiWiBar:UpdateMoneyValues()
	local CurrentMoney = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits):GetAmount()
	local MoneyGained = CurrentMoney - self.tCurrentRun.tMoneyInfo.nCurrent - self.tCurrentRun.tMoneyInfo.nEarnedThisFrame
	if MoneyGained < 0 then
		self.tCurrentRun.tMoneyInfo.nLost = self.tCurrentRun.tMoneyInfo.nLost - MoneyGained 
	end
	self.tCurrentRun.tMoneyInfo.nCurrent = CurrentMoney
	
	self.tCurrentRun.tMoneyInfo.nEarnedThisFrame = 0
	self.tCurrentRun.tMoneyInfo.nPerHour = self:GetValuePerHour(self.tCurrentRun.tMoneyInfo.nLooted - self.tCurrentRun.tMoneyInfo.nLost, true)
	self.tCurrentRun.tMoneyInfo.nFromJunk = self:GetJunkValue()
	self.tCurrentRun.tMoneyInfo.nTotal = self.tCurrentRun.tMoneyInfo.nFromJunk + self.tCurrentRun.tMoneyInfo.nLooted - self.tCurrentRun.tMoneyInfo.nLost
end

function WiWiBar:UpdateMoneyToolTip()
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:GetLine("MoneyPerHour"):SetValue(self.tCurrentRun.tMoneyInfo.nPerHour)
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:GetLine("MoneyFromLoot"):SetValue(self.tCurrentRun.tMoneyInfo.nLooted)
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:GetLine("MoneyFromJunk"):SetValue(self.tCurrentRun.tMoneyInfo.nFromJunk)
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:GetLine("MoneyTotal"):SetValue(self.tCurrentRun.tMoneyInfo.nTotal)
	self.tDisplay.tToolTip.tPlayerCurrentMoneyInfo:GetLine("MoneyLost"):SetValue(self.tCurrentRun.tMoneyInfo.nLost)
end	

	
--[[ A AJOUTER POUR L'UPDATE VISUEL
	if 	ResPerHour.nMoney >= 0 then
		self.wndMain:FindChild("MoneyHour"):SetTextColor("ffffffff")
	else
		ResPerHour.nMoney = -ResPerHour.nMoney
		self.wndMain:FindChild("MoneyHour"):SetTextColor("AddonError")
	end
	
	self.wndMain:FindChild("MoneyHour"):SetAmount(ResPerHour.nMoney , true)
--]]
----------------------------------------------------
------------------------------------------------------



----------------------------------------------------------
--EXP
----------------------------------------------------------


function WiWiBar:OnExperienceGained(eReason, targetUnitId, text)
	if self.Paused or self.SessionStarted == false then return end

	local XpEarned = text:gsub('%a','')	--remove all letters
	if eReason == 2 then
		self.tCurrentRun.tXpInfo.nFromMobs = self.tCurrentRun.tXpInfo.nFromMobs + XpEarned
		self.tCurrentRun.tMobInfo.nKilledWithXpGainCount = self.tCurrentRun.tMobInfo.nKilledWithXpGainCount + 1
	end
	self.tCurrentRun.tXpInfo.nGained = self.tCurrentRun.tXpInfo.nGained + tonumber(XpEarned)
end

function WiWiBar:OnElderPointsGained(XpEarned)
	if self.Paused or self.SessionStarted == false then return end	
	
	--not xp reward amount from quests : it must be a mob
	if XpEarned < 75000 then
		self.tCurrentRun.tXpInfo.nFromMobs = self.tCurrentRun.tXpInfo.nFromMobs + XpEarned
		self.tCurrentRun.tMobInfo.nKilledWithXpGainCount = self.tCurrentRun.tMobInfo.nKilledWithXpGainCount + 1
	end
	self.tCurrentRun.tXpInfo.nGained = self.tCurrentRun.tXpInfo.nGained + tonumber(XpEarned)
end

function WiWiBar:UpdateExperienceValues()
	if self.Paused or self.SessionStarted == false then return end
	
	local PlayerLevel = GameLib.GetPlayerLevel()
	
	local nCurrentXP = 0
	local nNeededXP = 0
	
	if PlayerLevel == 50 then
		--elder points
		nCurrentXP = GetElderPoints()
		nNeededXP = GameLib.ElderPointsPerGem - nCurrentXP 
	else
		nCurrentXP = GetXp() - GetXpToCurrentLevel()
		nNeededXP = GetXpToNextLevel() - nCurrentXP 	
	end

	local XpPerHour = self:GetValuePerHour(self.tCurrentRun.tXpInfo.nGained, true)

	if nNeededXP > 75000 then nNeededXP = 0 end
	local TimeBeforeNextLevel = "--"
	if XpPerHour > 0 then
		TimeBeforeNextLevel = math.floor((nNeededXP / XpPerHour) * 3600)	
	end

	local AverageXpPerMob = 0
	local MobNeeded = 0
	if self.tCurrentRun.tMobInfo.nKilledWithXpGainCount > 0 then
		AverageXpPerMob = self.tCurrentRun.tXpInfo.nFromMobs / self.tCurrentRun.tMobInfo.nKilledWithXpGainCount
	end
	
	if AverageXpPerMob > 0 then
		MobNeeded = math.floor(nNeededXP / AverageXpPerMob)
	end
	
	local MobKilledWithXpGainPerHour = self:GetValuePerHour(self.tCurrentRun.tMobInfo.nKilledWithXpGainCount, true)
	

	
	self.tCurrentRun.tXpInfo.nPerHour = XpPerHour	
	self.tCurrentRun.tXpInfo.nNeeded = nNeededXP
	self.tCurrentRun.tXpInfo.nTimeBeforeUp = TimeBeforeNextLevel
	self.tCurrentRun.tXpInfo.nAveragePerMob = AverageXpPerMob
	self.tCurrentRun.tXpInfo.nMobNeeded = MobNeeded
	self.tCurrentRun.tMobInfo.nKilledWithXpGainPerHour = MobKilledWithXpGainPerHour 
end

function WiWiBar:UpdateExperienceToolTip()
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("XpPerHour"):SetValue(self.tCurrentRun.tXpInfo.nPerHour)
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("XpTotal"):SetValue(self.tCurrentRun.tXpInfo.nGained)
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("XpNeeded"):SetValue(self.tCurrentRun.tXpInfo.nNeeded)
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("TimeBeforeNextLevel"):SetValue(self.tCurrentRun.tXpInfo.nTimeBeforeUp)
	self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("MobNeeded"):SetValue(self.tCurrentRun.tXpInfo.nMobNeeded)
	if GameLib.GetPlayerLevel() and GameLib.GetPlayerLevel() < 50 then
		self.tDisplay.tToolTip.tPlayerCurrentXpInfo:GetLine("LevelGained"):SetValue(self.tCurrentRun.tXpInfo.nLevelGainedCount)
	end
end



---------------------------------------------------------------
--------------ELDER GEM
---------------------------------------------------------------

function WiWiBar:UpdateElderGemValues()
	local CurrentEG = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.ElderGems):GetAmount()
	
	if CurrentEG > self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount and self.Paused == false then
		self.tCurrentRun.tElderGemInfo.nGained = self.tCurrentRun.tElderGemInfo.nGained + CurrentEG - self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount
		self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount = CurrentEG
	else
		self.tCurrentRun.tElderGemInfo.nPreviousElderGemCount = CurrentEG
	end
	
	self.tCurrentRun.tElderGemInfo.nPerHour = self:GetValuePerHour(self.tCurrentRun.tElderGemInfo.nGained, true)
end

function WiWiBar:UpdateElderGemTooltip()
	if self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo then
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:GetLine("ElderGemPerHour"):SetValue(self.tCurrentRun.tElderGemInfo.nPerHour)
		self.tDisplay.tToolTip.tPlayerCurrentElderGemInfo:GetLine("ElderGemTotal"):SetValue(self.tCurrentRun.tElderGemInfo.nGained)
	end
end

---------------------------------------------------------------
--------------RENOWN
---------------------------------------------------------------
function WiWiBar:UpdateRenownValues()
	if self.SessionStarted == false then return end
	
	local CurrentRealRenown = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount()
	
	if self.Paused then
		local CurrentRenown = self.tCurrentRun.tRenownInfo.nGainedOutOfRun + self.tCurrentRun.tRenownInfo.nGained + self.tCurrentRun.tRenownInfo.nAtStart 
		local EarnedRenown = CurrentRealRenown - CurrentRenown  
		if  CurrentRealRenown > CurrentRenown then
			self.tCurrentRun.tRenownInfo.nGainedOutOfRun = self.tCurrentRun.tRenownInfo.nGainedOutOfRun + EarnedRenown 
		end		
	else
		self.tCurrentRun.tRenownInfo.nGained = CurrentRealRenown - self.tCurrentRun.tRenownInfo.nAtStart - self.tCurrentRun.tRenownInfo.nGainedOutOfRun
	end
	
	self.tCurrentRun.tRenownInfo.nPerHour = self:GetValuePerHour(self.tCurrentRun.tRenownInfo.nGained, true)	
end

function WiWiBar:UpdateRenownToolTip()
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:GetLine("RenownPerHour"):SetValue(self.tCurrentRun.tRenownInfo.nPerHour)
	self.tDisplay.tToolTip.tPlayerCurrentRenownInfo:GetLine("RenownTotal"):SetValue(self.tCurrentRun.tRenownInfo.nGained)
end



-------------------------------------------------------------
-------------ITEMS
------------------------------------------------------------


function WiWiBar:OnLootFilterQualityCheck()
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
end

function WiWiBar:OnLootFilterQualityCheckAll()
	local Checked = self.tDisplay.tWindowLoots.tFilters.chkQualAll:IsChecked()
	
	self.tDisplay.tWindowLoots.tFilters.chkInferior:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkAverage:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkGood:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkExcellent:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkSuperb:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkLegendary:SetCheck(Checked)
	self.tDisplay.tWindowLoots.tFilters.chkArtifact:SetCheck(Checked)	
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
end

function WiWiBar:SetGridOrderQlt()
	if self.lootSortType == "quality" then
		self.sortUp = not self.sortUp
	else
		self.sortUp = true
	end
	
	self.lootSortType = "quality"

	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)
	end	
end

function WiWiBar:SetGridOrderCst()
	if self.lootSortType == "cost" then
		self.sortUp = not self.sortUp
	else
		self.sortUp = true
	end
	
	self.lootSortType = "cost"

	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)
	end	
end

function WiWiBar:SetGridOrderCnt()
	if self.lootSortType == "count" then
		self.sortUp = not self.sortUp
	else
		self.sortUp = true
	end
	
	self.lootSortType = "count"

	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)
	end	
end

function WiWiBar:SetGridOrderName()
	if self.lootSortType == "name" then
		self.sortUp = not self.sortUp
	else
		self.sortUp = true
	end
	
	self.lootSortType = "name"

	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)
	end	
end

function WiWiBar:GetJunkValue()
	local nJunkValueCurrent = 0
	for _,v in pairs(self.tCurrentRun.tItemInfo.tItemLooted) do
		if v.eItemQuality == Item.CodeEnumItemQuality.Inferior then
			nJunkValueCurrent = nJunkValueCurrent + (v.nValue * v.nCount)
		end
	end
	return nJunkValueCurrent
end

function WiWiBar:OnLootedItem(itemLooted, nItemCount)	
	if self.Paused or self.SessionStarted == false then return end
	local tSellPrice = itemLooted:GetSellPrice()	
	if tSellPrice and tSellPrice:GetMoneyType() == 1 then
		nValueMoney = tSellPrice:GetAmount()
	else
		nValueMoney = 0
	end
	local tItemInfo = 
		{ 		
			nID = itemLooted:GetItemId(), 
			strName = itemLooted:GetName(), 
			nCount = nItemCount, 
			nValue = nValueMoney,
			eItemQuality = itemLooted:GetItemQuality() or 1,
			tIcon = itemLooted:GetIcon(),
			bActuallyLooted = true
		}

	if self.tCurrentRun.tItemInfo.tItemLooted[tonumber(tItemInfo.nID)] then	
		self.tCurrentRun.tItemInfo.tItemLooted[tonumber(tItemInfo.nID)].nCount = self.tCurrentRun.tItemInfo.tItemLooted[tonumber(tItemInfo.nID)].nCount + tItemInfo.nCount 
	else
		self.tCurrentRun.tItemInfo.tItemLooted[tonumber(tItemInfo.nID)] = tItemInfo
		self.tCurrentRun.tItemInfo.nItemCount = self.tCurrentRun.tItemInfo.nItemCount + 1
	end	

	
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
	
end

function WiWiBar:SortGrid(lList, wndGrid)
	if not wndGrid then 
		sPrint("Error in function SortGrid (1385). Grid expected, got nil")
		return
	end
	if not lList then 
		sPrint("Error in function SortGrid (1385). Table expected, got nil")
		return
	end
	
	local buffArray = {}
	local index = 1	
	
	for _,v in pairs(lList ) do
		buffArray[index] = v
		index = index + 1
	end
	
	local strSortType = self.lootSortType
	
	if self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		if strSortType == "count" then strSortType = "cost" end
	end
	
	local startTime = os.clock()
	
	if self.sortUp == false then
		if strSortType  == "name" then			
			table.sort(buffArray, function(a,b) return (a.strName > b.strName) end)
		elseif strSortType == "quality" then			
			table.sort(buffArray, function(a,b) return (tonumber(a.eItemQuality) < tonumber(b.eItemQuality)) end)
		elseif strSortType == "count" then
			table.sort(buffArray, function(a,b) return (a.nCount < b.nCount) end)
		elseif strSortType == "cost" then
			table.sort(buffArray, function(a,b) return ((a.nCount * a.nValue) < (b.nCount * b.nValue)) end)
		end
	else
		if self.lootSortType == "name" then			
			table.sort(buffArray, function(a,b) return (a.strName < b.strName) end)
		elseif strSortType == "quality" then
			table.sort(buffArray, function(a,b) return (tonumber(a.eItemQuality) > tonumber(b.eItemQuality)) end)
		elseif strSortType == "count" then
			table.sort(buffArray, function(a,b) return (a.nCount > b.nCount) end)
		elseif strSortType == "cost" then
			table.sort(buffArray, function(a,b) return ((a.nCount * a.nValue) > (b.nCount * b.nValue)) end)
		end
	end
--	sPrint(index - 1 .. " items sorted in " .. os.clock() - startTime .. "s")
	self:UpdateGrid(buffArray, wndGrid)	
end


function WiWiBar:UpdateGrid(BufferArray, wndGrid)
	if not wndGrid then 
		sPrint("Error in function UpdateGrid (1428). Grid expected, got nil")
		return
	end
	if not BufferArray then 
		sPrint("Error in function UpdateGrid (1428). Table expected, got nil")
		return
	end
	
	self.bItemSelected = false
	wndGrid:DeleteAll()
	local rowIndex = 0
	local ItemValue = 0
	local QualityArrayCheck = self:GetQualityCheck()
	local bSearchFilter = false
	local strSearchFilter = ""
	local bDisplay = true
	local strPattern = ""
	local bDisplayZeroCount = true
	local bDisplayOnlyName = false

	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		bDisplayZeroCount = false
		bSearchFilter = self.tDisplay.tWindowLoots.tFilters.bFilterSearch
		strSearchFilter = self.tDisplay.tWindowLoots.tFilters.strFilterSearch
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		bSearchFilter = self.tDisplay.tWindowItemSearch.tFilters.bFilterSearch
		strSearchFilter = self.tDisplay.tWindowItemSearch.tFilters.strFilterSearch
		bDisplayOnlyName = true
	end
	
	if bSearchFilter then
		strPattern = GetCaseInsensitivePattern(strSearchFilter)
	end
	
	
	local startTime = os.clock()
	local DisplayerCount = 0
	for index, tItemInfo in pairs(BufferArray) do
		if QualityArrayCheck[tItemInfo.eItemQuality] then			
			bDisplay = true
			if bSearchFilter then
				local strNamePattern = GetCaseInsensitivePattern(tItemInfo.strName)
				if string.find(strNamePattern , strPattern ) == nil then
					bDisplay = false
				end
			end
			if bDisplayZeroCount == false and tItemInfo.bActuallyLooted == false then			
				bDisplay = false
			end
			
			if bDisplay then
				DisplayerCount = DisplayerCount + 1
				if bDisplayOnlyName then
					rowIndex = wndGrid:AddRow("")
					tItemInfo.nRowIndex = rowIndex 
					wndGrid:SetCellImage(rowIndex , 1,tItemInfo.tIcon )
					wndGrid:SetCellDoc(rowIndex , 2, QualityColorText(QualityColor[tItemInfo.eItemQuality],tItemInfo.strName, baseFont))
					wndGrid:SetCellText(rowIndex , 3, tItemInfo.nValue )
					wndGrid:SetCellText(rowIndex , 5, tItemInfo.nID )					
				else
					ItemValue = (tItemInfo.nValue * tItemInfo.nCount)
					rowIndex = wndGrid:AddRow("")
					tItemInfo.nRowIndex = rowIndex 
			--		sPrint("quality " .. QualityColor[tItemInfo.eItemQuality] .. "   : " .. tItemInfo.strName)
					wndGrid:SetCellImage(rowIndex , 1,tItemInfo.tIcon )
					wndGrid:SetCellDoc(rowIndex , 2, QualityColorText(QualityColor[tItemInfo.eItemQuality],tItemInfo.strName, baseFont))
					wndGrid:SetCellText(rowIndex , 3, tItemInfo.nCount)
					
					wndGrid:SetCellText(rowIndex , 4, GetMoneyValue(ItemValue) )
					wndGrid:SetCellText(rowIndex , 5, tItemInfo.nID )
			--		sPrint("__Item rendered  -- " .. tItemInfo.strName)
				end
			end
		end 
	end
--	sPrint(DisplayerCount .. " Items displayed in " .. os.clock() - startTime .. "s")
end


function WiWiBar:GetQualityCheck()
	local QualityArrayCheck = 
	{
		self.tDisplay.tWindowLoots.tFilters.chkInferior:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkAverage:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkGood:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkExcellent:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkSuperb:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkLegendary:IsChecked(),
		self.tDisplay.tWindowLoots.tFilters.chkArtifact:IsChecked()			
	}
	return QualityArrayCheck 
end


function WiWiBar:GetLootedItemCountPerID(nID)
	local tItemInfo = self.tCurrentRun.tItemInfo.tItemLooted[tonumber(nID)]
	local nCount = 0
	if tItemInfo then
		nCount = tItemInfo.nCount
	end
	if nCount then
		return nCount
	end
	return 0
end

function WiWiBar:OnGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	local wndTested = nil
	if self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() or self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		wndTested = self.tDisplay.tWindowLoots.wndGridLoot
	elseif self.tDisplay.tSectionSwitchCkeck.chkItemSearch:IsChecked() then
		wndTested = self.tDisplay.tWindowItemSearch.nwdGridSearch
	end
	
	if wndTested and wndTested:GetCellText((x+1), 5) then
		local nID = tonumber(wndTested:GetCellText((x+1), 5))
		local item = Item.GetDataFromId(nID)
	
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = nil })	
	end
end


function WiWiBar:OnTrackItem()
--	sPrint(self.nCurrentItemSelectedID)
	local ItemAlreadyTracked = self:IsItemAlreadyTracked(self.nCurrentItemSelectedID)
	if self.bItemSelected and ItemAlreadyTracked == false and self.tDisplay.nCustomTabCount < MaxCustomTab then
		self:AddItemTab(self.nCurrentItemSelectedID)
--		self.tDisplay.tWindowLoots.wndButtonTrack:Show(false, true)
		self.tDisplay.tWindowLoots.wndButtonTrack:SetText("Untrack")
		self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(true, true)
	elseif ItemAlreadyTracked then
		self:DeletItemTab(self.nCurrentItemSelectedID)
		self.tDisplay.tWindowLoots.wndButtonTrack:SetText("Track")
		self.tDisplay.tWindowLoots.wndTrackedItemIndicator:Show(false, true)
	elseif self.tDisplay.nCustomTabCount >= MaxCustomTab then
		--max tab reached
	end
	if self.tDisplay.tWindowLoots.wndGridLoot:GetRowCount() >= self.nCurrentRowSelected then
		self.tDisplay.tWindowLoots.wndGridLoot:SelectCell(self.nCurrentRowSelected, 2)
		self:OnItemSelected(nil, nil, self.nCurrentRowSelected)
	elseif self.nCurrentRowSelected > 1 then
		self.nCurrentRowSelected = self.nCurrentRowSelected - 1
		self.tDisplay.tWindowLoots.wndGridLoot:SelectCell(self.nCurrentRowSelected, 2)
		self:OnItemSelected(nil, nil, self.nCurrentRowSelected)
	else
		self.tDisplay.tWindowLoots.wndButtonTrack:Show(false, true)
	end
end

function WiWiBar:IsItemAlreadyTracked(nID)
	for _, item in pairs(self.tDisplay.tCustomTab) do
		if item:GetItemID() == nID then
			return true
		end
	end
	--to do : return true if the item is already tracked
	return false
end

function WiWiBar:AddItemTab(itemID)
	self.tDisplay.nCustomTabCount = self.tDisplay.nCustomTabCount + 1
--	local strTabName = "customTab_" .. tostring(self.tDisplay.nCustomTabCount)
	local strTabName = Item.GetDataFromId(itemID):GetName()
	self.tDisplay.tCustomTab[self.tDisplay.nCustomTabCount] = tTab:New(strTabName, "item", itemID)	
	self.tDisplay.tCustomTab[self.tDisplay.nCustomTabCount]:AddLine("perHour", "/Hour", "int")
	self.tDisplay.tCustomTab[self.tDisplay.nCustomTabCount]:AddLine("total", "Total", "int")
	
	self:UpdateAll(true)
	self:GetItemTrackedTable()	--update the table
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
	
	if self.tDisplay.nCustomTabCount == MaxCustomTab then
		self.wndMainWin:FindChild("MaxTabReached"):Show(true, true)
	end
end

function WiWiBar:DeletItemTab(itemID)
	local iIndex = 1
	for _, item in pairs(self.tDisplay.tCustomTab) do
		if item:GetItemID() == itemID then
			sPrint(self.tDisplay.tCustomTab[iIndex]:GetName())
			self.tDisplay.tCustomTab[iIndex]:Delete()
			self.tDisplay.tCustomTab[iIndex] = self.tDisplay.tCustomTab[self.tDisplay.nCustomTabCount]
			self.tDisplay.tCustomTab[self.tDisplay.nCustomTabCount] = nil
		end
		iIndex = iIndex + 1
	end
	if self.tDisplay.nCustomTabCount == MaxCustomTab then
		self.wndMainWin:FindChild("MaxTabReached"):Show(false, true)
	end
	self.tDisplay.nCustomTabCount = self.tDisplay.nCustomTabCount - 1
	self:UpdateAll(true)
	self:GetItemTrackedTable()	--update the table
	if self.tDisplay.tSectionSwitchCkeck.chkLoots:IsChecked() then
		self:SortGrid(self.tCurrentRun.tItemInfo.tItemLooted, self.tDisplay.tWindowLoots.wndGridLoot)
	elseif self.tDisplay.tSectionSwitchCkeck.chkTracked:IsChecked() then
		self:SortGrid(self:GetItemTrackedTable(), self.tDisplay.tWindowLoots.wndGridLoot)
	end
end

function WiWiBar:GetItemTrackedTable()
	local nIdTracked = 0
	local tItemInfo = nil
	local tBuffer = {}
	for i = 1, self.tDisplay.nCustomTabCount do
		nIdTracked  = self.tDisplay.tCustomTab[i]:GetItemID()
		tItemInfo = self.tCurrentRun.tItemInfo.tItemLooted[tonumber(nIdTracked)]
		if tItemInfo == nil then
			local itItem = Item.GetDataFromId(nIdTracked )
			local tSellPrice = itItem:GetSellPrice()	
			if tSellPrice and tSellPrice:GetMoneyType() == 1 then
				tSellPrice = tSellPrice:GetAmount()
			else
				tSellPrice = 0
			end
			local tItemInfo = 
			{ 		
				nID = nIdTracked, 
				strName = itItem:GetName(), 
				nCount = 0, 
				nValue = tSellPrice,
				eItemQuality = itItem:GetItemQuality() or 1,
				tIcon = itItem:GetIcon(),
				bActuallyLooted = false
			}
		
			self.tCurrentRun.tItemInfo.tItemLooted[tonumber(nIdTracked)] = tItemInfo			
		end
		tBuffer[i] = tItemInfo
	end
	return tBuffer
end

itemToScanCount = 50000
iterationPerCall = 300
TimerDatabaseStart = 0

function WiWiBar:AbordDatabaseScan()
	if self.tDatabaseScanTimer then
		self.tDatabaseScanTimer:Stop()
	end
	self.bBuildingDatabase = false
	self.nDatabaseItemLooked = 0
	if self.tDisplay.tWindowItemSearch.wndGridSearch then
--		self.tDisplay.tWindowItemSearch.wndGridSearch:DeleteAll()
	end
	self.tItemDatabase = nil
--	sPrint("aborded")
end

function WiWiBar:BeginDatabaseScan()
	TimerDatabaseStart = os.clock()
	self.bBuildingDatabase = true
	self.nDatabaseItemLooked = 0
	self.tDatabaseScanTimer:Start()
end

function WiWiBar:OnTimerDatabaseBuild()
	if self.bBuildingDatabase then
		self:BuildDatabase()
	else
		self.tDatabaseScanTimer:Stop()
		self.bBuildingDatabase = false
		self.nDatabaseItemLooked = 0		
		sPrint("Scan finished in : " .. os.clock() - TimerDatabaseStart .. " s")
		self:SortGrid(self.tItemDatabase, self.tDisplay.tWindowItemSearch.wndGridSearch)		
	end	
end

function WiWiBar:BuildDatabase()
	if not self.tItemDatabase then
		self.tItemDatabase = {}
	end
		local startTime = os.clock()
		local invalidItemCount = 0
		
		for i = self.nDatabaseItemLooked + 1, self.nDatabaseItemLooked + iterationPerCall do
			local item = Item.GetDataFromId(i)
			if item and self:IsItemNameProhibited(item:GetName()) == false then
				local tSellPrice = item:GetSellPrice()	
				local nValueMoney = 0
				if tSellPrice and tSellPrice:GetMoneyType() == 1 then
					nValueMoney = tSellPrice:GetAmount()
				end
			
				local tItemInfo = 
				{ 		
					nID = i,
					strName = item:GetName(), 
					nCount = 1, 
					nValue = nValueMoney,
					eItemQuality = item:GetItemQuality() or 1,
					tIcon = item:GetIcon(),
					bActuallyLooted = false
				}
				self.tItemDatabase[i - invalidItemCount] = tItemInfo
			else
				invalidItemCount = invalidItemCount + 1
			end	
			self.nDatabaseItemLooked = self.nDatabaseItemLooked + 1
			if self.nDatabaseItemLooked > itemToScanCount then
				self.bBuildingDatabase = false
				return
			end
		end
--		sPrint(itemToScanCount - invalidItemCount .. " items found in " .. os.clock() - startTime .. "s")
end

function WiWiBar:IsItemNameProhibited(strName)
	if 	strName == "" or
		strName == "Armor" or 
		strName == "Focus Recovery Rate" or 
		strName == "Critical Hit Chance" or 
		strName == "Strikethrough" or 
		strName == "Critical Hit Severity" or
		strName == "Focused" or
		strName == "Finesse" or
		strName == "Insight" or
		strName == "Brutality" or
		strName == "Tech" or
		strName == "Deflect" or
		strName == "Random" or
		strName == "Grit" or
		strName == "Reflexive Shield" or
		strName == "Deflect Critical Hit" or
		strName == "Toughness" or
		strName == "Strengthen" or
		strName == "Reduced Burden" or
		strName == "Shoulder The Load" or
		strName == "Capacity" or
		strName == "Inner Strength" or
		strName == "Max Shield" or
		strName == "Max Health" or
		strName == "Deprecate"

		then return true
	else return false end
end


------------------------------------------------------------
-------TIMER---------------------------------------------
----------------------------------------------
local nDesync = 0
local ClockTime = 0

function WiWiBar:UpdateTimeElapsed()	
	if self.SessionStarted == false then return end
	
	nDesync = self.tCurrentRun.tTimeInfo.nTimeElapsed - ClockTime
--	sPrint(nDesync)
	
	if self.Paused == false then
--		self.tCurrentRun.tTimeInfo.nTimeElapsed = os.clock() - self.tCurrentRun.tTimeInfo.nTimeStarted - self.tCurrentRun.tTimeInfo.nPauseTimeElapsed 
		self.tCurrentRun.tTimeInfo.nTimeElapsed = self.tCurrentRun.tTimeInfo.nTimeElapsed + UpdateInterval -- self.tCurrentRun.tTimeInfo.nPauseTimeElapsed
--		ClockTime  = os.clock() - self.tCurrentRun.tTimeInfo.nTimeStarted - self.tCurrentRun.tTimeInfo.nPauseTimeElapsed 
	end

	self.wndTimer:SetText(GetTimeValue(self.tCurrentRun.tTimeInfo.nTimeElapsed))
end	








-----------------------------------------------------------------------------------------------
-- WiWiBarForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function WiWiBar:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function WiWiBar:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- WiWiBar Instance
-----------------------------------------------------------------------------------------------
local WiWiBarInst = WiWiBar:new()
WiWiBarInst:Init()
