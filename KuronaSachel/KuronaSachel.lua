-----------------------------------------------------------------------------------------------
-- Client Lua Script for KuronaSachel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local KuronaSachel = {}

local knItemWndWidth 			= 50	
local knItemWndHeight 			= 50
local knCategoryScrollbarWidth 	= 21
local kclrWhite = ApolloColor.new("white")
local kclrGray 	= ApolloColor.new("ff555555")
local kclrRed 	= ApolloColor.new("ItemQuantityFull")
local kclrOrange 	= ApolloColor.new("ItemQuantityNearFull")
local knUnloadWaitTime = 300 -- unload from memory if unused for 5 minutes
local knEmptyThreshold = 0
local knFullThreshold = 250
local knMediumThreshold = knFullThreshold * .90

function KuronaSachel:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function KuronaSachel:Init()
	Apollo.RegisterAddon(self, false, "", {"Util"})
end

function KuronaSachel:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("KuronaSachel.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function KuronaSachel:OnDocumentReady()
	if  self.xmlDoc == nil then
		return
	end
	Apollo.RegisterEventHandler("UpdateInventory", 					"OnUpdateInventory", self)
	Apollo.RegisterEventHandler("ToggleTradeSkillsInventory", 		"OnToggleVisibility", self)
	Apollo.RegisterEventHandler("ToggleTradeskillInventoryFromBag", "OnToggleVisibility", self)

	Apollo.RegisterTimerHandler("InitializeSatchelPart2", "OnInitializeSatchelPart2", self)
	Apollo.RegisterTimerHandler("UnloadSatchel", "OnUnloadSatchel", self)
	Apollo.RegisterEventHandler("LootStackItemSentToTradeskillBag", "OnLootstackItemSentToTradeskillBag", self)
	self.tNewlyAddedItems = {}
	self.tNewlyAddedItemsWindows = {}
end

-----------------------------------------------------------------------------------------------
-- KuronaSachelForm Functions
-----------------------------------------------------------------------------------------------
function KuronaSachel:OnLootstackItemSentToTradeskillBag(tItem)
	if tItem then
		self.tNewlyAddedItems[tItem.itemInstance:GetItemId()] = tItem
		if self.wndMain and self.wndMain:IsValid() and self.wndMain:IsShown() then
			self:PopulateSatchel(false)
		end
	end
end

function KuronaSachel:OnToggleVisibility(wndHandler, wndControl, eMouseButton)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:InitializeSatchel()
	end

	self.wndMain:Show(not self.wndMain:IsShown())
	if self.wndMain:IsShown() then
		self.wndMain:ToFront()
		self:PopulateSatchel(false)
		Apollo.StopTimer( "UnloadSatchel" )
		Event_FireGenericEvent("SupplySatchelOpen")
	else
		for idx, wnd in pairs(self.tNewlyAddedItemsWindows) do
			wnd:FindChild("NewSatchelItemRunner"):Show(false)
		end
		self.tNewlyAddedItems = {}
		self.tNewlyAddedItemsWindows = {}
		Apollo.CreateTimer("UnloadSatchel", knUnloadWaitTime, false)
		Event_FireGenericEvent("SupplySatchelClosed")
		if self.wndMain and self.wndMain:IsValid() then
		self.SavedPos = { self.wndMain:GetAnchorOffsets() }
		end
		
	end
end

function KuronaSachel:InitializeSatchel()
	if self.wndMain and self.wndMain:IsValid() then
		self.SavedPos = { self.wndMain:GetAnchorOffsets() }
		self.wndMain:Destroy()
	end

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "KuronaSachelForm", nil, self)
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = Apollo.GetString("SupplySatchel_Title")})
	

	self.wndCategoryList = self.wndMain:FindChild("CategoryList")

	-- Variables
	self.tItemCache = {}
	self.wndClickedItem = nil
	self.nLastWidth = self.wndMain:GetWidth()
	self.wndMain:SetSizingMinimum(284, 250)
	Apollo.CreateTimer("InitializeSatchelPart2", 0.1, false)
	if self.SavedPos then
		self.wndMain:SetAnchorOffsets(unpack(self.SavedPos))
	end
end

function KuronaSachel:OnInitializeSatchelPart2()
	local bShow = self.wndMain:FindChild("ShowAllBtn"):IsChecked()
	for strCategory, arItems in pairs(GameLib.GetPlayerUnit():GetSupplySatchelItems(0)) do
		local wndCat = Apollo.LoadForm(self.xmlDoc, "Category", self.wndCategoryList, self)
		wndCat:FindChild("CategoryText"):SetText(strCategory)

		self.tItemCache[strCategory] = {}

		local tCacheCategory = self.tItemCache[strCategory]
		tCacheCategory.wndCat = wndCat
		tCacheCategory.arItems = arItems
		tCacheCategory.nVisibleItems = 0

		for idx, tCurrItem in ipairs(tCacheCategory.arItems) do
			local wndItem = Apollo.LoadForm(self.xmlDoc, "Item", wndCat:FindChild("ItemList"), self)
			wndItem:Show(bShow)
			wndItem:SetData(tCurrItem)
			wndItem:FindChild("Icon"):SetSprite(tCurrItem.itemMaterial:GetIcon())
			wndItem:FindChild("Icon"):GetWindowSubclass():SetItem(tCurrItem.itemMaterial)
			if tCurrItem.nCount == knFullThreshold then
				wndItem:FindChild("HighCountWarnFrame"):Show(true)
				wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount).."\n/"..knFullThreshold)
				wndItem:FindChild("Count"):SetTextColor(kclrRed)
			elseif tCurrItem.nCount >= knMediumThreshold then
				wndItem:FindChild("HighCountWarnFrame"):Show(true)
				wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount).."\n/"..knFullThreshold)
				wndItem:FindChild("Count"):SetTextColor(kclrOrange)
			elseif tCurrItem.nCount > knEmptyThreshold then
				wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount))
				wndItem:FindChild("Count"):SetTextColor(kclrWhite)
			else
				wndItem:FindChild("Icon"):SetBGColor(kclrGray)
			end
			Tooltip.GetItemTooltipForm(self, wndItem, tCurrItem.itemMaterial, {bPrimary = true, bSelling = false, nStackCount = tCurrItem.nCount})

			if bShow then
				tCacheCategory.nVisibleItems = tCacheCategory.nVisibleItems + 1
			end

			tCurrItem.wndItem = wndItem
		end
	end

	self:OnResize()
	self:PopulateSatchel(false)
end

function KuronaSachel:OnUnloadSatchel()
	if self.wndMain and self.wndMain:IsValid() then
		self.SavedPos = { self.wndMain:GetAnchorOffsets() }
		self.wndMain:Destroy()
		self.wndMain = nil
	end
end

function KuronaSachel:OnUpdateInventory()
	if self.wndMain and self.wndMain:IsShown() then
		self:PopulateSatchel(false)
	end
end

function KuronaSachel:OnToggleTradeskillInventoryFromBag(tAnchors)
	if not self.wndMain or not self.wndMain:IsValid() then
		self:InitializeSatchel()
	end
end

function KuronaSachel:OnShowAll( wndHandler, wndControl, eMouseButton )
	self:PopulateSatchel(true)
end

function KuronaSachel:OnResize()
	-- Snap window width to item icons
	local nExcess = (self.wndCategoryList:GetWidth() - knCategoryScrollbarWidth) % knItemWndWidth
	if nExcess ~= 0 then
		local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
		self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight - nExcess, nBottom)
	end

	for key, tCacheCategory in pairs(self.tItemCache) do
		if tCacheCategory.nVisibleItems > 0 then
			tCacheCategory.wndCat:Show(true)
			self:ResizeCategory(tCacheCategory)
		else
			tCacheCategory.wndCat:Show(false)
		end
	end
end

function KuronaSachel:ResizeCategory(tCat)
	local wndItemList = tCat.wndCat:FindChild("ItemList")

	local nCols = math.floor(wndItemList:GetWidth() / knItemWndWidth)
	local nRows = math.ceil(tCat.nVisibleItems / nCols)
	local nLeft, nTop, nRight, nBottom = tCat.wndCat:GetAnchorOffsets()
	local nNewHeight = 51 + nRows * knItemWndHeight
	tCat.wndCat:SetAnchorOffsets(nLeft, nTop, nRight, nTop + nNewHeight)

	wndItemList:ArrangeChildrenTiles(0)
	wndItemList:RecalculateContentExtents()
	self.wndCategoryList:ArrangeChildrenVert()
	self.wndCategoryList:RecalculateContentExtents()
end

function KuronaSachel:OnMainWindowMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if self.wndMain:GetWidth() ~= self.nLastWidth then
		self:OnResize()
		self.nLastWidth = self.wndMain:GetWidth()
	end
end

function KuronaSachel:OnQueryDragDrop( wndHandler, wndControl, nX, nY, wndSource, strType, nData, eResult )
	if strType == "DDBagItem" then
		local itemCurrent = wndSource:GetData()
		if itemCurrent and itemCurrent:CanMoveToSupplySatchel() then
			return Apollo.DragDropQueryResult.Accept
		end
	end
	return Apollo.DragDropQueryResult.Invalid
end

function KuronaSachel:OnDragDrop( wndHandler, wndControl, nX, nY, wndSource, strType, nData, bDragDropHasBeenReset )
	if strType == "DDBagItem" then
		local itemCurrent = wndSource:GetData()
		if itemCurrent and itemCurrent:CanMoveToSupplySatchel() then
			itemCurrent:MoveToSupplySatchel()
		end
	end
	return
end

function KuronaSachel:OnMainWindowClosed( wndHandler, wndControl )
	Apollo.CreateTimer("UnloadSatchel", knUnloadWaitTime, false)
end

-----------------------------------------------------------------------------------------------
-- ItemList Functions
-----------------------------------------------------------------------------------------------

function KuronaSachel:OnSearchBoxChanged(wndHandler, wndControl)
	self:PopulateSatchel(true)
end

function KuronaSachel:OnSearchClearBtn(wndHandler, wndControl)
	self.wndMain:FindChild("SearchBox"):SetText("")
	self:PopulateSatchel(true)
	wndHandler:SetFocus() -- Focus on close button to steal focus from input
end

function KuronaSachel:PopulateSatchel(bRescroll)
	local nVScrollPos = self.wndCategoryList:GetVScrollPos()
	if bRescroll then
		nVScrollPos = 0
	end

	local nMinCount = 1
	if self.wndMain:FindChild("ShowAllBtn"):IsChecked() then
		nMinCount = 0
	end

	local strSearchString = self.wndMain:FindChild("SearchBox"):GetText()
	local bSearchString = string.len(strSearchString) > 0
	self.wndMain:FindChild("SearchClearBtn"):Show(bSearchString)

	for strCategory, arItems in pairs(GameLib.GetPlayerUnit():GetSupplySatchelItems(0)) do
		local tCacheCategory = self.tItemCache[strCategory]
		if tCacheCategory then
			tCacheCategory.nVisibleItems = 0
			for idx, tCurrItem in ipairs(arItems) do
				local tCacheItem = tCacheCategory.arItems[idx]

				local strFindName = tCacheItem.itemMaterial:GetName()
				if self.tNewlyAddedItems[tCacheItem.itemMaterial:GetItemId()] ~= nil then
					tCacheItem.wndItem:FindChild("NewSatchelItemRunner"):Show(true)
					table.insert(self.tNewlyAddedItemsWindows , tCacheItem.wndItem)
				end

				if tCacheItem.nCount ~= tCurrItem.nCount then
					tCacheItem.nCount = tCurrItem.nCount
					tCacheItem.wndItem:SetData(tCurrItem)
					tCacheItem.wndItem:FindChild("HighCountWarnFrame"):Show(tCurrItem.nCount > knFullThreshold)
					if tCurrItem.nCount == knFullThreshold then
						tCacheItem.wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount).."\n/"..knFullThreshold)
						tCacheItem.wndItem:FindChild("Count"):SetTextColor(kclrRed)
						tCacheItem.wndItem:FindChild("Icon"):SetBGColor(kclrWhite)
						tCacheItem.wndItem:FindChild("HighCountWarnFrame"):Show(true)
					elseif tCurrItem.nCount >= knMediumThreshold then
						tCacheItem.wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount).."\n/"..knFullThreshold)
						tCacheItem.wndItem:FindChild("Count"):SetTextColor(kclrOrange)
						tCacheItem.wndItem:FindChild("Icon"):SetBGColor(kclrWhite)
						tCacheItem.wndItem:FindChild("HighCountWarnFrame"):Show(false)
					elseif tCurrItem.nCount > knEmptyThreshold then
						tCacheItem.wndItem:FindChild("Count"):SetText(tostring(tCurrItem.nCount))
						tCacheItem.wndItem:FindChild("Count"):SetTextColor(kclrWhite)
						tCacheItem.wndItem:FindChild("Icon"):SetBGColor(kclrWhite)
						tCacheItem.wndItem:FindChild("HighCountWarnFrame"):Show(false)
					else
						tCacheItem.wndItem:FindChild("Count"):SetText("")
						tCacheItem.wndItem:FindChild("Count"):SetTextColor(kclrWhite)
						tCacheItem.wndItem:FindChild("Icon"):SetBGColor(kclrGray)
						tCacheItem.wndItem:FindChild("HighCountWarnFrame"):Show(false)
					end
					Tooltip.GetItemTooltipForm(self, tCacheItem.wndItem, tCurrItem.itemMaterial, {bPrimary = true, bSelling = false, nStackCount = tCurrItem.nCount})
				end
				if tCurrItem.nCount >= nMinCount and (not bSearchString or self:HelperSearchNameMatch(tCurrItem.itemMaterial:GetName(), strSearchString)) then
					tCacheItem.wndItem:Show(true)
					tCacheCategory.nVisibleItems = tCacheCategory.nVisibleItems + 1
				else
					tCacheItem.wndItem:Show(false)
				end
			end
		end
	end

	self:OnResize()
	self.wndCategoryList:SetVScrollPos(nVScrollPos)
	if bRescroll then
		self.wndCategoryList:ArrangeChildrenVert()
		self.wndCategoryList:RecalculateContentExtents()
	end
end

-- the player clicked an item
function KuronaSachel:OnItemMouseButtonDown( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	if (eMouseButton == GameLib.CodeEnumInputMouse.Left and bDoubleClick) or eMouseButton == GameLib.CodeEnumInputMouse.Right then
		wndControl:GetData().itemMaterial:TakeFromSupplySatchel(wndControl:GetData().nCount)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left then
		-- Store the clicked window, waiting for a drag or mouse button up
		self.wndClickedItem = wndControl
--		self:OnItemMouseMove(wndHandler, wndControl)
	end
end

function KuronaSachel:OnItemMouseMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler ~= wndControl then return end
	if self.wndClickedItem and self.wndClickedItem == wndControl then
		-- Clicked and dragged
		Apollo.BeginDragDrop(wndControl, "DDSupplySatchelItem", wndControl:FindChild("Icon"):GetSprite(), wndControl:GetData().idLocation)
		self.wndClickedItem = nil
	end
end

function KuronaSachel:OnItemMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndControl == self.wndClickedItem then return end
	if wndHandler ~= wndControl then return end
	if self.wndClickedItem and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		if self.wndClickedItem == wndControl then
			-- Clicked and released
			-- Apollo.BeginClickStick(wndControl, "DDSupplySatchelItem", wndControl:FindChild("Icon"):GetSprite(), wndControl:GetData().id)
			self.wndClickedItem = nil
		end
	end
end

function KuronaSachel:HelperSearchNameMatch(strBase, strInput)
	-- Find the first character of a word or an exact match from the start
	strBase = strBase:lower() -- Not case sensitive
	strInput = strInput:lower()
	return strBase:find(strInput, 1, true)
end

-----------------------------------------------------------------------------------------------
-- KuronaSachel Instance
-----------------------------------------------------------------------------------------------
local KuronaSachelInst = KuronaSachel:new()
KuronaSachelInst:Init()

function KuronaSachel:OnSave(eLevel,backup)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tsave = {}
	if self.wndMain and self.wndMain:IsValid() then
		self.SavedPos = { self.wndMain:GetAnchorOffsets() }
	end
	tsave.SavedPos = self.SavedPos
	return tsave
end

function KuronaSachel:OnRestore(eLevel, saveData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	self.SavedPos = saveData.SavedPos
end