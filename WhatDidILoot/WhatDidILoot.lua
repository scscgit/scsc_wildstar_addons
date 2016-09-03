-----------------------------------------------------------------------------------------------
-- Client Lua Script for WhatDidILoot
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Item"

 
-----------------------------------------------------------------------------------------------
-- WhatDidILoot Module Definition
-----------------------------------------------------------------------------------------------
local WhatDidILoot = {} 

local arItemQuality = 
{
	[Item.CodeEnumItemQuality.Inferior] 		= 
  {
    Color           = "ItemQuality_Inferior"
  },
	[Item.CodeEnumItemQuality.Average] 			= 
  {
    Color           = "ItemQuality_Average"
  },
	[Item.CodeEnumItemQuality.Good] 			  =
  {
    Color           = "ItemQuality_Good"
  },
	[Item.CodeEnumItemQuality.Excellent] 		=   
  {
    Color           = "ItemQuality_Excellent"
  },
	[Item.CodeEnumItemQuality.Superb] 			= 
  {
    Color           = "ItemQuality_Superb"
  },
	[Item.CodeEnumItemQuality.Legendary] 		=   
  {
    Color           = "ItemQuality_Legendary"
  },
	[Item.CodeEnumItemQuality.Artifact]		 	=   
  {
    Color           = "ItemQuality_Artifact"
  }
}

local iLastRow = -1 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WhatDidILoot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function WhatDidILoot:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- WhatDidILoot OnLoad
-----------------------------------------------------------------------------------------------
function WhatDidILoot:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("WhatDidILoot.xml")
	Apollo.LoadSprites("WhatDidILootSprites.xml", "WhatDidILootSprites")
	
  -- Loot Events
  -- Add in ItemRemoved event -- ItemData number number
							  -- ItemData.GetSellPrice(), subtract it out from the money earned to get money looted
							  -- ItemAdded vs PartyBagItemAdded
	Apollo.RegisterEventHandler("LootedItem",					"OnLootedItem",					self)
	Apollo.RegisterEventHandler("LootedMoney",					"OnLootedMoney",				self)
	Apollo.RegisterEventHandler("ChannelUpdate_Loot",			"OnLoot",						self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",	"OnInterfaceMenuListHasLoaded",	self)
	Apollo.RegisterEventHandler("ToggleWDILWindow",				"OnWhatDidILootOn",				self)
	Apollo.RegisterEventHandler("InvokeVendorWindow",			"TriggerClearLootedCash",		self)
	Apollo.RegisterEventHandler("MailBoxActivate",				"TriggerClearLootedCash",		self)

	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end


function WhatDidILoot:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
	
	local tSavedData = 
	{
		tSavedItems = self.tLootedItems,
		tSavedBlackList = self.tBlackListedItems,
		nSavedEarnedCredits = self.nEarnedCredits,
		bSavedFilterZeroValue = self.bFilterZeroValue,
		strSavedSortOrder = self.strSortOrder,
		bSavedSortItemsAscending = self.bSortItemsAscending,
		bSavedLootedCashOnly = self.bLootedCashOnly,
		bSavedResetOnReload = self.bResetOnReload,
		bSavedShowCurrentLoot = self.bShowCurrentLoot
	}
	
	return tSavedData
end

function WhatDidILoot:OnRestore(eType, tSavedData)
	self.tSavedData = tSavedData
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end

	if not tSavedData.bSavedResetOnReload or  tSavedData.bSavedResetOnReload == false then
		self.bResetOnReload = false

		if tSavedData.tSavedItems then
			self.tLootedItems = tSavedData.tSavedItems
		else	
			self.tLootedItems = {}
		end

		if tSavedData.nSavedEarnedCredits then
			self.nEarnedCredits = tSavedData.nSavedEarnedCredits
		else
			self.nEarnedCredits = 0
		end
	else
		self.bResetOnReload = true
	end

	if tSavedData.bSavedLootedCashOnly then
		self.bLootedCashOnly = tSavedData.bSavedLootedCashOnly
	else
		self.bLootedCashOnly = false
	end
	
	if tSavedData.bSavedFilterZeroValue then
		self.bFilterZeroValue = tSavedData.bSavedFilterZeroValue
	else
		self.bFilterZeroValue = false
	end
	
	if tSavedData.bSavedSortItemsAscending then
		self.bSortItemsAscending = tSavedData.bSavedSortItemsAscending 
	else
		self.bSortItemsAscending = true
	end

	if tSavedData.bSavedShowCurrentLoot then
		self.bShowCurrentLoot = tSavedData.bSavedShowCurrentLoot
	else
		self.bShowCurrentLoot = true
	end
	
	if tSavedData.strSavedSortOrder then
		self.strSortOrder = tSavedData.strSavedSortOrder 
	else
		self.strSortOrder = "Item Name"
	end
	
	if tSavedData.tSavedBlackList then
		self.tBlackListedItems = tSavedData.tSavedBlackList
	else
		self.tBlackListedItems = {}
	end

end


-----------------------------------------------------------------------------------------------
-- WhatDidILoot OnDocLoaded
-----------------------------------------------------------------------------------------------
function WhatDidILoot:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "WhatDidILootForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end	
		
		Apollo.RegisterEventHandler("WindowManagementReady", 				"OnWindowManagementReady", self)
		
	    self.wndMain:Show(false, true)
		self.wndMain:SetSizingMinimum(575, 170)
	
		self.wndWDILOptions = Apollo.LoadForm(self.xmlDoc, "WhatDidILootOptionsForm", nil, self)
		self.wndWDILOptions:Show(false)
	
		self.wndWDILConfirmRemove = Apollo.LoadForm(self.xmlDoc, "WDILConfirmRemoveForm", nil, self)
		self.wndWDILConfirmRemove:Show(false)

		self.wndFooterBar = self.wndMain:FindChild("FooterBar")
		self.gridLoot = self.wndMain:FindChild("GridLoot")
		self.gridBlacklist = self.wndWDILOptions:FindChild("gridBlacklist")

		self.nEarnedItemCredits = 0
		self.nLootCount = 1
		
		self:UpdateEarnedItemCredits(0)

		if not self.tBlackListedItems then
			self.tBlackListedItems = {}
		else
			self.timer = ApolloTimer.Create(3.0, false, "OnTimer", self)
		end
		
		if not self.tLootedItems then
			self.tLootedItems = {}
		else
			if not self.timer then
				self.timer = ApolloTimer.Create(3.0, false, "OnTimer", self)
			end
		end

		if not self.nEarnedCredits then
			self.nEarnedCredits = 0
		end
		
		if self.bFilterZeroValue and self.bFilterZeroValue == true then
			self.wndWDILOptions:FindChild("OptionsBtnFilterZero"):SetCheck(true)
		end	

		if not self.strSortOrder then
			self.strSortOrder = "Item Name"
		end
		
		if not self.bSortItemsAscending then
			self.bSortItemsAscending = true
		end

		if not self.bShowCurrentLoot then
			self.bShowCurrentLoot = true
		end
		
		if self.bSortItemsAscending == true then
			if self.strSortOrder == "Item Name" then
				self.wndMain:FindChild("btnNameSort"):SetCheck(true)
			elseif self.strSortOrder == "Count" then
				self.wndMain:FindChild("btnCountSort"):SetCheck(true)
			elseif self.strSortOrder == "Total Value" then
				self.wndMain:FindChild("btnValueSort"):SetCheck(true)
			elseif self.strSortOrder == "Date Added" then
				self.wndMain:FindChild("btnDateSort"):SetCheck(true)
			end
		end

		if self.bLootedCashOnly and self.bLootedCashOnly == true then		
			self.wndWDILOptions:FindChild("OptionsBtnOnlyLootedMoney"):SetCheck(true)	
			Apollo.RegisterEventHandler("UnitCreated",					"OnUnitCreated",				self)
		end

		if self.bResetOnReload and self.bResetOnReload == true then
			self.wndWDILOptions:FindChild("OptionsBtnResetOnReload"):SetCheck(true)	
		end

		if self.bShowCurrentLoot and self.bShowCurrentLoot == true then		
			self.wndWDILOptions:FindChild("OptionsBtnShowCurrentLoot"):SetCheck(true)
		end

		self:UpdateEarnedCredits()
		
		Apollo.RegisterSlashCommand("wdil", "OnWhatDidILootOn", self)

		-- Do additional Addon initialization here
	end
end

function WhatDidILoot:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn","What Did I Loot?", {"ToggleWDILWindow", "", "WhatDidILootSprites:WDILIcon"})
end

function WhatDidILoot:OnWindowManagementReady()	
	Event_FireGenericEvent("WindowManagementRegister", {wnd = self.wndMain, strName = "What Did I Loot"})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "What Did I Loot"})
end

-----------------------------------------------------------------------------------------------
-- WhatDidILoot EventHandlers
-----------------------------------------------------------------------------------------------

function WhatDidILoot:OnLoot(lootType, tLootArgs)
	if lootType == 1 then
		self:OnLootedItem(tLootArgs["itemNew"], tLootArgs["nCount"])
	elseif lootType == 2 then
		self:OnLootedMoney(tLootArgs["monNew"])
	end
end

function WhatDidILoot:OnLootedMoney(moneyNew)
	if self.bLootedCashOnly and self.bLootedCashOnly == true then
		local nLootedAmount = moneyNew:GetAmount()

		if self.nLootedCash and self.nLootedCash >= nLootedAmount then
			self.nEarnedCredits = self.nEarnedCredits + nLootedAmount
			self.nLootedCash = self.nLootedCash - nLootedAmount
			self:UpdateEarnedCredits()
		end
	else
		self.nEarnedCredits = self.nEarnedCredits + moneyNew:GetAmount()
		self:UpdateEarnedCredits()
	end
end

function WhatDidILoot:OnLootedItem(lootNew, nCount)

	if not lootNew then
		return
	end

	if not self.tLootedItems then
		self.tLootedItems = {}
	end

	local tSellInfo = lootNew:GetSellPrice()

	local nValue 	= 0
	
	-- If the item value is something other than credits, then we count it
	-- as no value for now
	if 	tSellInfo and tSellInfo:GetMoneyType() == 1 then
		nValue = tSellInfo:GetAmount()
	end
	
	if self.bFilterZeroValue and self.bFilterZeroValue == true and nValue <= 0 then
		return
	end
	
	if self.tBlackListedItems and lootNew:GetName() and self.tBlackListedItems[lootNew:GetName()] then
		return
	end

	local eItemQuality = lootNew:GetItemQuality() or 1
	local tLootInfo = { nID = lootNew:GetItemId(), strName = lootNew:GetName(), nCount = nCount, nCurCount = nCount, nValue = nValue, nRowIndex = 1, eItemQuality = eItemQuality, strLootedOn = os.date("%Y-%m-%d %H:%M") }

	if self.tLootedItems[tonumber(tLootInfo.nID)] then	
		-- If we're incrementing an item we already had stored, subtract out the current total value
		-- for it to make the math simple
		self.nEarnedItemCredits = self.nEarnedItemCredits - (self.tLootedItems[tonumber(tLootInfo.nID)].nCount * self.tLootedItems[tonumber(tLootInfo.nID)].nValue)

		tLootInfo.nCount = tLootInfo.nCount + self.tLootedItems[tLootInfo.nID].nCount
	end
		
	self.tLootedItems[tonumber(tLootInfo.nID)] = tLootInfo
	
	self:SortItemList()
end




function WhatDidILoot:OnUnitCreated(unitNew)
	if unitNew == nil or not unitNew:IsValid() or not unitNew:GetType() == "PinataLoot" or not unitNew:GetName() == "Cash" then
		return
	end

	local tLootInfo = unitNew:GetLoot()

	if tLootInfo ~= nil and tLootInfo.eLootItemType == 2 and tLootInfo.monCurrency ~= nil then
		self.nLootedCash = (self.nLootedCash or 0) + tLootInfo.monCurrency:GetAmount()
	end
end

function WhatDidILoot:TriggerClearLootedCash()
	self.nLootedCash = 0
end
-----------------------------------------------------------------------------------------------
-- WhatDidILoot Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/wdil"
function WhatDidILoot:OnWhatDidILootOn()
	self.wndMain:Show(not self.wndMain:IsVisible())
end

-- on timer
function WhatDidILoot:OnTimer()
	self:SortItemList()

	if self.tBlackListedItems  then
		for strItemName, bValue in pairs(self.tBlackListedItems) do
			self:AddNameToBlacklist(strItemName)
		end
	end
end


function WhatDidILoot:AddNameToBlacklist(strItemName)
	local nRowIndex = self.gridBlacklist:AddRow("")
	
	self.gridBlacklist:SetCellText(nRowIndex, 1, strItemName)
end

function WhatDidILoot:AddItemToGrid(tLootInfo)

	local nRowIndex = tLootInfo.nRowIndex
	local nAmount = tLootInfo.nCount * tLootInfo.nValue
	
	local nPlat 	= 0
	local nGold 	= 0
	local nSilver 	= 0
	local nCopper 	= 0

	if math.floor(nAmount / 1000000) > 0 then
		nPlat = math.floor(nAmount / 1000000)
		nAmount = nAmount - (nPlat * 1000000)
	end
	if math.floor(nAmount / 10000) > 0 then
		nGold = math.floor(nAmount / 10000)
		nAmount = nAmount - (nGold * 10000)
	end
	if math.floor(nAmount / 100) > 0 then
		nSilver = math.floor(nAmount / 100)
		nAmount = nAmount - (nSilver * 100)
	end		
	strValue = string.format("%02dp %02dg %02ds %02dc", nPlat, nGold, nSilver, nAmount)
	
	self.gridLoot:SetCellDoc(nRowIndex, 1, self:ColoredText(tLootInfo.strName,arItemQuality[tLootInfo.eItemQuality].Color))
	if self.bShowCurrentLoot and self.bShowCurrentLoot == true then	
		if tLootInfo.nCurCount then
			self.gridLoot:SetCellText(nRowIndex, 2, tLootInfo.nCurCount .. " (" .. tLootInfo.nCount .. ")")
		else
			self.gridLoot:SetCellText(nRowIndex, 2, 0 .. " (" .. tLootInfo.nCount .. ")")
		end
	else
		self.gridLoot:SetCellText(nRowIndex, 2, tLootInfo.nCount)
	end

	self.gridLoot:SetCellText(nRowIndex, 3, strValue)
	self.gridLoot:SetCellText(nRowIndex, 4, tLootInfo.nID)
	self.gridLoot:SetCellText(nRowIndex, 5, tLootInfo.strLootedOn)


	self:UpdateEarnedItemCredits(tLootInfo.nCount * tLootInfo.nValue)

end

function WhatDidILoot:ColoredText(strText, strColor)
	return string.format('<P Font="CRB_Pixel_O" TextColor="%s">%s</P>', strColor, strText)
end

function WhatDidILoot:UpdateEarnedItemCredits(nItemValue)

	self.nEarnedItemCredits = self.nEarnedItemCredits + nItemValue

	local nAmount = self.nEarnedItemCredits
	nPlat = 0
	nGold = 0
	nSilver = 0

	if math.floor(nAmount / 1000000) > 0 then
		nPlat = math.floor(nAmount / 1000000)
		nAmount = nAmount - (nPlat * 1000000)
	end

	if math.floor(nAmount / 10000) > 0 then
		nGold = math.floor(nAmount / 10000)
		nAmount = nAmount - (nGold * 10000)
	end

	if math.floor(nAmount / 100) > 0 then
		nSilver = math.floor(nAmount / 100)
		nAmount = nAmount - (nSilver * 100)
	end
	
	self.wndFooterBar:FindChild("EarnedItemPlat"):SetText(string.format("%02d", nPlat))
	self.wndFooterBar:FindChild("EarnedItemGold"):SetText(string.format("%02d", nGold))
	self.wndFooterBar:FindChild("EarnedItemSilver"):SetText(string.format("%02d", nSilver))
	self.wndFooterBar:FindChild("EarnedItemCopper"):SetText(string.format("%02d", nAmount))
end

function WhatDidILoot:UpdateEarnedCredits()

	local nAmount = self.nEarnedCredits
	local nPlat = 0
	local nGold = 0
	local nSilver = 0

	if math.floor(nAmount / 1000000) > 0 then
		nPlat = math.floor(nAmount / 1000000)
		nAmount = nAmount - (nPlat * 1000000)
	end

	if math.floor(nAmount / 10000) > 0 then
		nGold = math.floor(nAmount / 10000)
		nAmount = nAmount - (nGold * 10000)
	end

	if math.floor(nAmount / 100) > 0 then
		nSilver = math.floor(nAmount / 100)
		nAmount = nAmount - (nSilver * 100)
	end
	
	self.wndFooterBar:FindChild("EarnedPlat"):SetText(string.format("%02d", nPlat))
	self.wndFooterBar:FindChild("EarnedGold"):SetText(string.format("%02d", nGold))
	self.wndFooterBar:FindChild("EarnedSilver"):SetText(string.format("%02d", nSilver))
	self.wndFooterBar:FindChild("EarnedCopper"):SetText(string.format("%02d", nAmount))
end


function WhatDidILoot:SortItemList()
	local tTempTable = {}
	for idx, tLootInfo in pairs(self.tLootedItems) do
		if not tLootInfo.strLootedOn then
			tLootInfo.strLootedOn = os.date("%Y-%m-%d %H:%M")
		end
		table.insert(tTempTable, tLootInfo)
	end

	if self.bSortItemsAscending == true then
		if self.strSortOrder == "Item Name" then
			table.sort(tTempTable, function(a,b) return (a.strName < b.strName) end)
		elseif self.strSortOrder == "Count" then
			table.sort(tTempTable, function(a,b) return (a.nCount < b.nCount) end)
		elseif self.strSortOrder == "Total Value" then
			table.sort(tTempTable, function(a,b) return ((a.nCount * a.nValue) < (b.nCount * b.nValue)) end)
		elseif self.strSortOrder == "Date Added" then
			table.sort(tTempTable, function(a,b) return (a.strLootedOn > b.strLootedOn) end)
		end
	else
		if self.strSortOrder == "Item Name" then
			table.sort(tTempTable, function(a,b) return (a.strName > b.strName) end)
		elseif self.strSortOrder == "Count" then
			table.sort(tTempTable, function(a,b) return (a.nCount > b.nCount) end)
		elseif self.strSortOrder == "Total Value" then
			table.sort(tTempTable, function(a,b) return ((a.nCount * a.nValue) > (b.nCount * b.nValue)) end)
		elseif self.strSortOrder == "Date Added" then
			table.sort(tTempTable, function(a,b) return (a.strLootedOn < b.strLootedOn) end)
		end
	end
	
	self:BuildItemList(tTempTable)
end

function WhatDidILoot:BuildItemList(tItemList)
	self.gridLoot:DeleteAll()
	self.nEarnedItemCredits = 0
	
	for idx, tLootInfo in pairs(tItemList) do
		nRowIndex = self.gridLoot:AddRow("")
		tLootInfo.nRowIndex = nRowIndex
		self:AddItemToGrid(tLootInfo)
	end

end

-----------------------------------------------------------------------------------------------
-- WhatDidILootForm Functions
-----------------------------------------------------------------------------------------------

-- when the Cancel button is clicked
function WhatDidILoot:OnCancel()
	self.wndMain:Close() -- hide the window
end


function WhatDidILoot:OnClearItems( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("ConfirmRemoveAll"):Show(true)
end

function WhatDidILoot:OnConfirmClearItems( wndHandler, wndControl, eMouseButton )
	self.gridLoot:DeleteAll()
	self.tLootedItems = {}
	self.nEarnedItemCredits = 0
	self:UpdateEarnedItemCredits(0)
	self.wndMain:FindChild("ConfirmRemoveAll"):Show(false)
end

function WhatDidILoot:OnCancelClearItems( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("ConfirmRemoveAll"):Show(false)
end

function WhatDidILoot:OnClearMoney( wndHandler, wndControl, eMouseButton )
	
	self.nEarnedCredits = 0
	self:UpdateEarnedCredits()
	
end

function WhatDidILoot:OnItemSelected(wndControl, wndHandler, iRow, iCol, eMouseButton)

	-- ctrl + click to remove an item
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self.nSelectedRow = iRow
		
		local tMouse = Apollo:GetMouse()
		
		if not self.wndWDILConfirmRemove:IsVisible() then
			self.wndWDILConfirmRemove:SetAnchorOffsets(tMouse.x, tMouse.y - 25, tMouse.x + 185, tMouse.y + 130)
			self.wndWDILConfirmRemove:Show(true)
			self.wndMain:ToFront()
			self.wndWDILConfirmRemove:ToFront()
		end	
	end
end

function WhatDidILoot:OnSettings( wndHandler, wndControl, eMouseButton )
	if self.wndWDILOptions:IsVisible() then
		self.wndWDILOptions:Show(false)
	else
		self.wndWDILOptions:Show(true)
		self.wndMain:ToFront()
		self.wndWDILOptions:ToFront()
	end
end

function WhatDidILoot:OnWDILItemSort( wndHandler, wndControl, eMouseButton )	
	if wndControl:IsChecked() then
		self.strSortOrder = wndHandler:FindChild("GridSortText"):GetText()
		self.bSortItemsAscending = true
		self:SortItemList()
	else
		self.bSortItemsAscending = false
		self:SortItemList()
	end
end

function WhatDidILoot:OnGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )	
	if self.gridLoot:GetCellText((x+1), 4) then
		local nID = tonumber(self.gridLoot:GetCellText((x+1), 4))
		local item = Item.GetDataFromId(nID)
	
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = nil })	
	end
end

function WhatDidILoot:OnWindowSizeChanged( wndHandler, wndControl )
	local nWidth = self.wndMain:FindChild("btnNameSort"):GetWidth()

	self.gridLoot:SetColumnWidth(1, nWidth)

end

---------------------------------------------------------------------------------------------------
-- WhatDidILootOptionsForm Functions
---------------------------------------------------------------------------------------------------

function WhatDidILoot:OnCloseOptions( wndHandler, wndControl, eMouseButton )
	self.wndWDILOptions:Show(false)
end

function WhatDidILoot:OnFilterZeroCheck( wndHandler, wndControl, eMouseButton )
	self.bFilterZeroValue = true
end

function WhatDidILoot:OnFilterZeroUncheck( wndHandler, wndControl, eMouseButton )
	self.bFilterZeroValue = false
end

function WhatDidILoot:OnBlacklistSelected(wndControl, wndHandler, iRow, iCol)
	if Apollo.IsControlKeyDown() then
		local strItemName = wndControl:GetCellText(iRow, 1)
		
		if self.tBlackListedItems and self.tBlackListedItems[strItemName] then
			self.tBlackListedItems[strItemName] = nil
		end		
		
		wndControl:DeleteRow(iRow)
	end
end

function WhatDidILoot:OnFilterLootedCashCheck( wndHandler, wndControl, eMouseButton )
	Apollo.RegisterEventHandler("UnitCreated",					"OnUnitCreated",				self)
	self.bLootedCashOnly = true
end

function WhatDidILoot:OnFilterLootedCashUncheck( wndHandler, wndControl, eMouseButton )
	Apollo.RemoveEventHandler("UnitCreated",				self)
	self.bLootedCashOnly = false
end

function WhatDidILoot:OnFilterResetReloadCheck( wndHandler, wndControl, eMouseButton )
	self.bResetOnReload = true
end

function WhatDidILoot:OnFilterResetReloadUncheck( wndHandler, wndControl, eMouseButton )
	self.bResetOnReload = false
end

function WhatDidILoot:OnShowCurrentLootCheck( wndHandler, wndControl, eMouseButton )
	self.bShowCurrentLoot = true
	self:SortItemList()
end

function WhatDidILoot:OnShowCurrentLootUncheck( wndHandler, wndControl, eMouseButton )
	self.bShowCurrentLoot = false
	self:SortItemList()
end

---------------------------------------------------------------------------------------------------
-- WDILConfirmForm Functions
---------------------------------------------------------------------------------------------------

function WhatDidILoot:OnRemoveItem( wndHandler, wndControl, eMouseButton )
	local nID = tonumber(self.gridLoot:GetCellText(self.nSelectedRow, 4))
	
	if self.tLootedItems and self.tLootedItems[nID] then
		local tLootInfo = self.tLootedItems[nID]

		self.nEarnedItemCredits = self.nEarnedItemCredits - (tLootInfo.nCount * tLootInfo.nValue)
		self:UpdateEarnedItemCredits(0)
		self.tLootedItems[nID] = nil
		self.gridLoot:DeleteRow(self.nSelectedRow)
	end
	
	self.wndWDILConfirmRemove:Show(false)
end

function WhatDidILoot:OnBlackListItem( wndHandler, wndControl, eMouseButton )
	if not self.tBlackListedItems then
		self.tBlackListedItems = {}
	end

	local nID = tonumber(self.gridLoot:GetCellText(self.nSelectedRow, 4))
	
	if self.tLootedItems and self.tLootedItems[nID] then
		local tLootInfo = self.tLootedItems[nID]
		
		self.tBlackListedItems[tLootInfo.strName] = true
		self:AddNameToBlacklist(tLootInfo.strName)
		
		self.nEarnedItemCredits = self.nEarnedItemCredits - (tLootInfo.nCount * tLootInfo.nValue)
		self:UpdateEarnedItemCredits(0)
		self.tLootedItems[nID] = nil
		self.gridLoot:DeleteRow(self.nSelectedRow)
	end
	
	self.wndWDILConfirmRemove:Show(false)
end

function WhatDidILoot:OnCancelRemoveItem( wndHandler, wndControl, eMouseButton )
	self.wndWDILConfirmRemove:Show(false)
end

---------------------------------------------------------------------------------------------------
-- WDILConfirmRemoveForm Functions
---------------------------------------------------------------------------------------------------

function WhatDidILoot:OnConfirmClose( wndHandler, wndControl )
end

-----------------------------------------------------------------------------------------------
-- WhatDidILoot Instance
-----------------------------------------------------------------------------------------------
local WhatDidILootInst = WhatDidILoot:new()
WhatDidILootInst:Init()
