-- Sorted Pairs function, pass in the sort function
local function spairs(t, order)
	-- Collect keys
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end

	-- If order function given, sort by passing the table and keys a, b,
	-- otherwise just sort keys
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end

	-- Return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end

require "Window"

-----------------------------------------------------------------------------------------------
-- MarketplaceToVendor Module Definition
-----------------------------------------------------------------------------------------------
local MarketplaceToVendor = {}

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MarketplaceToVendor:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function MarketplaceToVendor:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"MarketplaceCommodity",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- MarketplaceToVendor OnLoad
-----------------------------------------------------------------------------------------------
function MarketplaceToVendor:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("MarketplaceToVendor.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- MarketplaceToVendor OnDocLoaded
-----------------------------------------------------------------------------------------------
function MarketplaceToVendor:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MarketplaceToVendorForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil

		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("mv", "OnMarketplaceToVendorOn", self)

		-- Do additional Addon initialization here
		Apollo.RegisterEventHandler("CommodityInfoResults", "OnCommodityInfoResults", self)
		Apollo.RegisterEventHandler("ToggleMarketplaceWindow", "OnMarketplaceWindowOpened", self)
		Apollo.RegisterEventHandler("MarketplaceWindowClose", "OnMarketplaceWindowClosed", self)

		self.wndIsScanningText = self.wndMain:FindChild("IsScanningText")
		self.wndIncludeTaxesCheckbox = self.wndMain:FindChild("IncludeTaxesCheckbox")

		self.listItems = {}
		self.vendorItems = {}
		self.wndIncludeTaxesCheckbox:SetCheck(true)
		self:OnMarketplaceWindowClosed()
	end
end

-----------------------------------------------------------------------------------------------
-- MarketplaceToVendor Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/mv"
function MarketplaceToVendor:OnMarketplaceToVendorOn()
	self.wndMain:Invoke() -- show the window
end

function MarketplaceToVendor:ScanCx(wndHandler, wndControl, eMouseButton)
	self.queue = {}

	for idx, family in ipairs(MarketplaceLib.GetCommodityFamilies()) do
		for idx2, category in ipairs(MarketplaceLib.GetCommodityCategories(family.nId)) do
			for idx3, type in ipairs(MarketplaceLib.GetCommodityTypes(category.nId)) do
				for idx4, item in ipairs(MarketplaceLib.GetCommodityItems(type.nId)) do
					table.insert(self.queue, item.nId)
				end
			end
		end
	end

	self.queueIndex = 0
	self.isScanning = true
	self.wndIsScanningText:Show(true)
	self.vendorItems = {}

	for i, id in ipairs(self.queue) do
		MarketplaceLib.RequestCommodityInfo(id)
	end
end

function MarketplaceToVendor:OnCommodityInfoResults(nItemId, tStats, tOrders)
	if tStats.arSellOrderPrices[1].monPrice:GetAmount() > 0 then
		-- Top 1
		local vendorProfit = self:GetVendorProfit(tStats.arSellOrderPrices[1].monPrice:GetAmount(), nItemId)

		if vendorProfit > 0 then
			local itemData = { item  =  Item.GetDataFromId(nItemId), tStats = tStats, vendorProfit = vendorProfit }
			table.insert(self.vendorItems, itemData)
		end
	end

	if self.isScanning then
		self.queueIndex = self.queueIndex + 1

		if self.queueIndex >= #self.queue then
			self.isScanning = false
			self.wndIsScanningText:Show(false)

			self:RefreshVendorList()
		end
	end
end

function MarketplaceToVendor:ClearVendorList()
	for i, listItem in ipairs(self.listItems) do
		listItem:Destroy()
	end

	self.listItems = {}
end

function MarketplaceToVendor:RefreshVendorList()
	self:ClearVendorList()

	local wndList = self.wndMain:FindChild("VendorList")

	if #self.vendorItems == 0 then
		table.insert(self.listItems, self:AddListItem(wndList, "No profitable commodities found."))
	else
		for i, item in spairs(self.vendorItems, function(t, a, b) return t[a].vendorProfit > t[b].vendorProfit end) do
			table.insert(self.listItems, self:AddListItem(wndList, item.item:GetName(), item.vendorProfit))
		end
	end

	wndList:ArrangeChildrenVert()
end

function MarketplaceToVendor:OrderVendorItemsByProfit(t, a, b)
	return t[a].vendorProfit < t[b].vendorProfit
end

function MarketplaceToVendor:GetVendorProfit(sellPrice, nItemId, quantity)
	quantity = quantity or 1

	local item = Item.GetDataFromId(nItemId)

	if item == nil then
		return 0
	end

	local vendorPrice = item:GetSellPrice()

	if vendorPrice == nil then
		return 0
	end

	local profit = (vendorPrice:GetAmount() - sellPrice) * quantity

	if self.wndIncludeTaxesCheckbox:IsChecked() then
		local pricePercentageTax = sellPrice * quantity * MarketplaceLib.kfCommodityBuyOrderTaxMultiplier
		
		if pricePercentageTax < MarketplaceLib.knCommodityBuyOrderTaxMinimum then
			profit = profit - MarketplaceLib.knCommodityBuyOrderTaxMinimum
		else
			profit = profit - pricePercentageTax
		end
	end

	return profit
end

function MarketplaceToVendor:AddListItem(wndTarget, name, profit)
	local wndListItem = Apollo.LoadForm(self.xmlDoc, "ListItem", wndTarget, self)
	wndListItem:FindChild("NameText"):SetText(name)

	if profit ~= nil then
		wndListItem:FindChild("ProfitCash"):SetAmount(profit)
		wndListItem:FindChild("ProfitCash"):Show(true)
	end

	return wndListItem
end

function MarketplaceToVendor:OnMarketplaceWindowOpened()
	local scanButton = self.wndMain:FindChild("ScanButton")
	scanButton:Enable(true)

	local marketplaceClosedText = self.wndMain:FindChild("MarketplaceClosedText")
	marketplaceClosedText:Show(false)
end

function MarketplaceToVendor:OnMarketplaceWindowClosed()
	local scanButton = self.wndMain:FindChild("ScanButton")
	scanButton:Enable(false)

	local marketplaceClosedText = self.wndMain:FindChild("MarketplaceClosedText")
	marketplaceClosedText:Show(true)
end

-----------------------------------------------------------------------------------------------
-- MarketplaceToVendorForm Functions
-----------------------------------------------------------------------------------------------
function MarketplaceToVendor:OnScanCx(wndHandler, wndControl, eMouseButton)
	self:ScanCx()
end

function MarketplaceToVendor:OnCancel(wndHandler, wndControl, eMouseButton)
	self.wndMain:Show(false)
end

-----------------------------------------------------------------------------------------------
-- MarketplaceToVendor Instance
-----------------------------------------------------------------------------------------------
local MarketplaceToVendorInst = MarketplaceToVendor:new()
MarketplaceToVendorInst:Init()
