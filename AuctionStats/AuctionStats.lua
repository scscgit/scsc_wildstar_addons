-----------------------------------------------------------------------------------------------
--[[ Copyright (c) chckxy (watdametz@gmail.com). All rights reserved

This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Lesser General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Lesser General Public License for more details.

You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.  --]]
-----------------------------------------------------------------------------------------------
 
local AuctionStats = {} 
local PixiePlot = nil

local timeHour  = 1
local timeDay   = (timeHour * 24)
local timeWeek  = (timeDay  * 7)
local timeMonth = (timeDay * 31)

function AuctionStats:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function AuctionStats:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"MarketplaceAuction",
		"ToolTips",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function AuctionStats:OnLoad()
	self.stats = {}
	self.ma = Apollo.GetAddon("MarketplaceAuction")
	self.xmlDoc = XmlDoc.CreateFromFile("AuctionStats.xml")
	self.timeLastCompression = 0

	-- scan button
	local fnOldInitialize = self.ma.Initialize 
	self.ma.Initialize = function(tMA)
		fnOldInitialize(tMA)
		if not tMA.wndMain then return end
		local btn = Apollo.LoadForm(self.xmlDoc, "ScanBtn", tMA.wndMain, self)
	end
	
	-- stats button
	local fnOldOnItemAuctionSearchResults = self.ma.OnItemAuctionSearchResults
	self.ma.OnItemAuctionSearchResults = function(tMA, nPage, nTotalResults, tAuctions)
		fnOldOnItemAuctionSearchResults(tMA, nPage, nTotalResults, tAuctions)
		local wndParent = nil
		if not tMA.wndMain then return nil end
		local bBuyTab = tMA.wndMain:FindChild("HeaderBuyBtn"):IsChecked()
		if bBuyTab then
			wndParent = tMA.wndMain:FindChild("BuyContainer"):FindChild("SearchResultList")
		else
			wndParent = tMA.wndMain:FindChild("SellContainer"):FindChild("SellRightSide"):FindChild("SellSimilarItemsList")
		end
		for nKey, wndChild in ipairs(wndParent:GetChildren()) do
			local wnd = Apollo.LoadForm(self.xmlDoc, "OpenPlotBtn", wndChild, self)
		end
    end

	-- sell stats button
	local fnOldOnSellListItemCheck = self.ma.OnSellListItemCheck
	self.ma.OnSellListItemCheck = function(tMA, wndHandler, wndControl)
		fnOldOnSellListItemCheck(tMA, wndHandler, wndControl)
		local wndParent = tMA.wndMain:FindChild("SellRightSide")
		local wndBtn = tMA.wndMain:FindChild("CreateSellOrderBtn")

		local item = wndBtn:GetData()
		local wndBigIcon = tMA.wndMain:FindChild("SellContainer"):FindChild("BigIcon")
		if item and item:GetStackCount() > 1 then
			wndBigIcon:SetText(item:GetStackCount())
			wndBigIcon:SetFont("CRB_Interface10")
			wndBigIcon:SetTextFlags("DT_BOTTOM", true)
			wndBigIcon:SetTextFlags("DT_RIGHT", true)
		else
			wndBigIcon:SetText("")
		end

		local wnd = Apollo.LoadForm(self.xmlDoc, "OpenPlotBtn", wndParent, self)
		wnd:SetData(wndHandler:GetData())
	end
	
	-- item tooltips
	local tt = Apollo.GetAddon("ToolTips")
	local fnOld = tt.CreateCallNames
	tt.CreateCallNames = function(tToolTips)
		fnOld(tToolTips)
	    local fnOldGetItemTooltipForm = Tooltip.GetItemTooltipForm
		Tooltip.GetItemTooltipForm = function(tToolTip, wndControl, item, bStuff, nCount)
	    	local wndTooltip, wndTooltipComp = 
				fnOldGetItemTooltipForm(tToolTip, wndControl, item, bStuff, nCount)
	        if wndTooltip ~= nil and item:IsAuctionable() then
				self:NewItemTooltip(item, wndTooltip, wndTooltipComp)
			end
			return wndTooltip, wndTooltipComp
		end
	end

    PixiePlot = Apollo.GetPackage("Drafto:Lib:PixiePlot-1.4").tPackage
end

function AuctionStats:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Realm then return end
	return { 
		stats = self.stats, 
		timeLastCompression = self.timeLastCompression,
	}
end

function AuctionStats:OnRestore(eLevel, tSave)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Realm then return end
	tSave = tSave or {}
	if tSave.stats and tSave.timeLastCompression then 
		self.stats = tSave.stats
	end
	-- self:CompressStats()
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

-- thanks to CommodityStats for the hour trickery
function AuctionStats:GetCurrentHour()
    local time = GameLib.GetLocalTime()
    local timeData = {
		year  = time.nYear,
		month = time.nMonth,
		day   = time.nDay,
		hour  = time.nHour,
		min   = 0,
		sec   = 0,
	}
	return os.time(timeData) / (60 ^ 2)
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

-- assume that 
function AuctionStats:CompressStats()
	--[[if os.difftime(GetTime(), self.timeLastCompression) < timeDay then return end
	
	local timeThreshold
	for nId, ttStats in pairs(self.stats) do
		local timeCurr = GetTime()
		local time = timeCurr - (timeDay * 7)

		-- daily stats before weekly cutoff
		timeThreshold = timeCurr - (timeDay * 31)
		while time > timeThreshold do
			local timeNext = time + timeDay
			local tStats = { unpack(self.stats, time, time + timeDay) }
			local nSum = 0
			local nCount = 0
			local nMin = nil
			for nKey, tData in ipairs(tStats) do
				if tData then
					if (not nMin) or (tData.nMin < nMin) then nMin = tData.nMin end
					nSum = nSum + tData.nAvg
					nCount = nCount + 1
				end
			end
			if nCount ~= 0 then end
			time = timeNext
		end
		
		-- weekly stats the rest of the time
	end--]]
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

function AuctionStats:NewItemTooltip(item, wndTooltip, wndTooltipComp)
	local wndBox = wndTooltip:FindChild("ItemTooltip_SalvageAndMoney")
	if not wndBox then return end
	local nHeight = wndBox:GetHeight()

	local nId = item:GetItemId()
	local ttStats = self.stats[nId]
 	if not ttStats then return end
	local time = table.maxn(ttStats)
	if time < 1 then return end
	local tStats = ttStats[time]

	local nMin = tStats.nMin
	local nAvg = tStats.nAvg
	if (not nMin) or (not nAvg) then return end

	-- add the two rows to tooltips
	self:AddCurrencyTooltipRow("AH Min", nMin, wndBox)
	self:AddCurrencyTooltipRow("AH Avg", nAvg, wndBox)

	-- resize
	nHeight = wndBox:ArrangeChildrenVert(0) - nHeight
	local nLeft, nTop, nRight, nBottom = wndBox:GetAnchorOffsets()
	wndBox:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)
	nLeft, nTop, nRight, nBottom = wndTooltip:GetAnchorOffsets()
	wndTooltip:SetAnchorOffsets(nLeft, nTop, nRight, nBottom + nHeight)
end

function AuctionStats:AddCurrencyTooltipRow(strDesc, nAmount, wndParent)
	local monPrice = Money.new()
	local strSellCaption = strDesc .. ":<T TextColor=\"0\">.</T>"
	local wnd = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndParent)
	xml = XmlDoc.new()
	xml:AddLine(strSellCaption, "UI_TextMetalBodyHighlight", "CRB_InterfaceSmall", "Right")
	monPrice:SetAmount(tonumber(nAmount) or 1)
	monPrice:AppendToTooltip(xml)
	wnd:SetDoc(xml)
	wnd:SetHeightToContentHeight()
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

function AuctionStats:OnScanAuctionHouseButtonSignal( scanBtn, wndControl, eMouseButton )
	self.scanBtn = scanBtn
	scanBtn:SetText("Busy Scanning")
	scanBtn:Enable(false)
	
	self.tScan = {}

	-- tell the wildstar AH to gtfo
	Apollo.RemoveEventHandler("ItemAuctionSearchResults", self.ma)
	Apollo.RegisterEventHandler("ItemAuctionSearchResults", "OnItemAuctionSearchResults", self)
	
	-- start scanning families
	self.tFamilies = MarketplaceLib.GetAuctionableFamilies()
	self.nCurrFamilyId = 0
	self:ScanNextFamily()
end

function AuctionStats:ScanNextFamily()
	local nId = self.nCurrFamilyId + 1
	local tData = self.tFamilies[nId]
	if tData then
		self:ScanFamily(tData)
		self.nCurrFamilyId = nId
	else 
		self:IntegrateScanData()
		self:RestoreMarketplaceAuction()
		self.scanBtn:SetText("Scan Complete")
	end
end

-- requests the information for an entire Family
function AuctionStats:ScanFamily(tTopData)
	local nId = tTopData.nId

	local eAuctionSort = MarketplaceLib.AuctionSort.Buyout
	self.fnLastSearch = function(nPage)
		MarketplaceLib.RequestItemAuctionsByFamily(
			nId, nPage, eAuctionSort, false, {}, nil, nil, nil)
	end
	self.fnLastSearch(0)
end

-- processes the scan information for a single page of an entire Family
function AuctionStats:OnItemAuctionSearchResults(nPage, nTotalResults, tAuctions)
	for nKey, aucCurr in ipairs(tAuctions) do
		self:RecordAuction(aucCurr)
	end

	local bHasPages = nTotalResults > MarketplaceLib.kAuctionSearchPageSize
	local bIsLast = (nPage + 1) * MarketplaceLib.kAuctionSearchPageSize >= nTotalResults
	
	if bHasPages and not bIsLast then
		self.fnLastSearch(nPage + 1)
	else
		self:ScanNextFamily()
	end
end

-- processes the scan information for a single item
function AuctionStats:RecordAuction(aucCurr)
	local nAmount = aucCurr:GetCount()
	local itemCurr = aucCurr:GetItem()
	local nBuyoutPrice = aucCurr:GetBuyoutPrice():GetAmount() / nAmount
	if nBuyoutPrice == 0 then return end
	local nId = itemCurr:GetItemId()
	local tStats = self.tScan[nId]
	if not tStats then
		tStats = {}
		table.insert(self.tScan, nId, tStats)
	end
	table.insert(tStats, nBuyoutPrice)
end

function AuctionStats:RestoreMarketplaceAuction()
	Apollo.RegisterEventHandler("ItemAuctionSearchResults", "OnItemAuctionSearchResults", self.ma)
	Apollo.RemoveEventHandler("ItemAuctionSearchResults", self)
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

function AuctionStats:IntegrateScanData()
	for nId, tStats in pairs(self.tScan) do
		-- find the min and the average; tStats is never {}
		local nMin = math.min(unpack(tStats))
		local nSum = 0
		for nKey, nBuyout in ipairs(tStats) do nSum = nSum + nBuyout end
		local nAvg = nSum / #tStats
		self:AddDataPoint(nId, { nMin = nMin, nAvg = nAvg, })
		self.nOffset = 0
	end
	self.tScan = nil
end

function AuctionStats:AddDataPoint( nId, tData )
	local time = self:GetCurrentHour()
	tData.time = time
	local ttStats = self.stats[nId]
	if not ttStats then
		ttStats = {}
		table.insert(self.stats, nId, ttStats)
	end
	table.insert(ttStats, time, tData)
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

function AuctionStats:OnOpenPlotBtn( wndHandler, wndControl, eMouseButton )
	local itemData = nil
	if wndHandler:GetData() then
		itemData = wndHandler:GetData()
	else
		local aucCurr = wndHandler:GetParent():GetData()
		itemData = aucCurr:GetItem()
	end
	local nId = itemData:GetItemId()
	self:DrawPlot(nId)
end

function AuctionStats:DrawPlot( nId )
	local item = Item.GetDataFromId(nId)
	
	self.lastDiffHours = nil
	self.lastDiffDays = nil
	self.lastDiffWeeks = nil
	
	if not self.wndPlot then 
		local fnFormatXValue = function( time ) -- time is not an int
			-- hours
			local nDiffHours = math.floor(self:GetCurrentHour() - time)
			if nDiffHours == self.lastDiffHours then return "" end
			self.lastDiffHours = nDiffHours
			if nDiffHours < 1 then return "now" end
			if nDiffHours < 2 then return nDiffHours .. "hr" end
			if nDiffHours < 24 then return nDiffHours .. "hrs" end
			
			-- days
			local nDiffDays = math.floor(nDiffHours / 24)
			if nDiffDays == self.lastDiffDays then return "" end
			self.lastDiffDays = nDiffDays
			if nDiffDays < 1 then return "" end
			if nDiffDays < 2 then return nDiffDays .. "day" end
			if nDiffDays < 7 then return nDiffDays .. "days" end
			
			-- weeks
			local nDiffWeeks = math.floor(nDiffDays / 7)
			if nDiffWeeks == self.lastDiffWeeks then return "" end
			self.lastDiffWeeks = nDiffWeeks
			if nDiffWeeks < 1 then return "" end
			if nDiffWeeks < 2 then return nDiffWeeks .. "week" end
			if nDiffWeeks < 6 then return nDiffWeeks .. "weeks" end
			
			-- months
			local nDiffMonths = math.floor(nDiffDays / 30)
			if nDiffMonths == self.lastDiffMonths then return "" end
			self.lastDiffMonths = math.max(nDiffMonths, 1)
			if nDiffMonths < 2 then return nDiffMonths .. "month" end
			if nDiffMonths < 13 then return nDiffMonths .. "months" end
			
			return "long " .. nDiffMonths
		end

		local fnFormatYValue = function( nAmount )
			local tPlat =   { math.floor((nAmount / (100 ^ 3)))       , "p" }
			local tGold =   { math.floor((nAmount / (100 ^ 2)) % 100) , "g" }
			local tSilver = { math.floor((nAmount / (100 ^ 1)) % 100) , "s" }
			local tCopper = { math.floor((nAmount / (100 ^ 0)) % 100) , "c" }
			local bPrefix = true
			local str = ""
			for nKey, tData in ipairs({ tPlat, tGold, tSilver, tCopper }) do
				if (tData[1] > 0) or (not bPrefix) then
					bPrefix = false
					str = str .. tData[1] .. tData[2]
				end
			end
			return str
		end
		
		self.wndPlot = Apollo.LoadForm(self.xmlDoc, "PlotWindow", nil, self)
		self.plot = PixiePlot:New(self.wndPlot:FindChild("Plot"))
	    self.plot:SetOption("ePlotStyle", PixiePlot.SCATTER)
		self.plot:SetOption("fXLabelMargin", 60)
		self.plot:SetOption("fYLabelMargin", 75)
		self.plot:SetOption("fXValueLabelTilt", 45)
		self.plot:SetOption("fYValueLabelTilt", 60)
		self.plot:SetOption("bDrawXValueLabels", true)
		self.plot:SetOption("xValueFormatter", fnFormatXValue)
		self.plot:SetOption("bDrawYValueLabels", true)
		self.plot:SetOption("yValueFormatter", fnFormatYValue)
		self.plot:SetOption("bDrawYGridLines", true)
	    self.plot:SetOption("bScatterLine", true)
		self.plot:SetOption("strLabelFont", "CRB_Interface10")
	end
	
	self.wndPlot:Show(true)
	self.wndPlot:FindChild("ItemName"):SetText(item:GetName())
	self.plot:RemoveAllDataSets()

	local ttStats = self.stats[nId]
	if not ttStats then return nil end 

	local tMin = {}
	local tAvg = {}
	local nYmin = nil
	local nYmax = nil

	for time, tStats in pairs(ttStats) do
		table.insert(tMin, { x = time, y = tStats.nMin })
		table.insert(tAvg, { x = time, y = tStats.nAvg })
		if (not nYmin) or (tStats.nMin < nYmin) then nYmin = tStats.nMin end
		if (not nYmax) or (tStats.nAvg > nYmax) then nYmax = tStats.nAvg end
	end
	
	local fnRel = function(tData1, tData2) return tData1.x < tData2.x end
	table.sort(tMin, fnRel)
	table.sort(tAvg, fnRel)

	self.plot:AddDataSet({ xStart = 0, values = tMin })
	self.plot:AddDataSet({ xStart = 0, values = tAvg })
	self.plot:SetYMin(nYmin * 0.8)
	self.plot:SetYMax(nYmax * 1.2)
	self.plot:Redraw()

	self.wndPlot:ToFront()
end

function AuctionStats:OnPlotWindowClose( wndHandler, wndControl, eMouseButton )
	self.wndPlot:Show(false)
	self.plot:RemoveAllDataSets()
end

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

local AuctionStatsInst = AuctionStats:new()
AuctionStatsInst:Init()
