local IntegratedWatchlist = {}

function IntegratedWatchlist:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	o:Init()
	return o
end

function IntegratedWatchlist:Init()
	self.dirty = false

	IntegratedWatchlistRow = Apollo.GetPackage("IntegratedWatchlistRow").tPackage
	IntegratedWatchlistOrderRow = Apollo.GetPackage("IntegratedWatchlistOrderRow").tPackage

    Apollo.RegisterEventHandler("CommodityInfoResults", "OnCommodityInfoResults", self)
	Apollo.RegisterEventHandler("OwnedCommodityOrders", "OnOwnedCommodityOrders", self)

	Apollo.RegisterEventHandler("ItemAuctionWon", 							"OnRefresh", self)
	Apollo.RegisterEventHandler("ItemAuctionOutbid", 						"OnRefresh", self)
	Apollo.RegisterEventHandler("ItemAuctionExpired", 						"OnRefresh", self)
	Apollo.RegisterEventHandler("ItemCancelResult", 						"OnRefresh", self)

	self.wndMain = Apollo.LoadForm(self.supernova.xmlDoc, "IntegratedWatchlist", nil, self)

	Apollo.RegisterTimerHandler("OneSecTimer", "OnTimer", self)
end

function IntegratedWatchlist:Open()
	self.commodityHandler:Refresh()
	self:DrawCommodities()
	self.wndMain:Invoke()
end

function IntegratedWatchlist:OnClose()
	self.wndMain:Close() -- hide the window
end

function IntegratedWatchlist:DrawCommodities()
	if (self.wndMain) then
		local wndGrid = self:GetGrid()
		if (wndGrid) then
			wndGrid:DestroyChildren()
			for key,value in pairs(self.commodityHandler.commodities) do
				local row = IntegratedWatchlistRow:new({watchlist = self, supernova = self.supernova, commodity = value})
				local listings = self.listingHandler:GetListingsById(value:GetId())
				for _,listing in pairs(listings) do
					local orderRow = IntegratedWatchlistOrderRow:new({watchlist = self, supernova = self.supernova, commodity = value, listing = listing})
				end
			end
			wndGrid:ArrangeChildrenVert(0)
		end
	end
end

function IntegratedWatchlist:GetGrid()
	return self.wndMain:FindChild("Grid")
end

function IntegratedWatchlist:OnRefreshClicked()
	self:OnRefresh()
end

function IntegratedWatchlist:OnRefresh()
	self.commodityHandler:Refresh()
	self.listingHandler:Refresh()
	self.dirty = true
end

function IntegratedWatchlist:OnTimer()
	if self.dirty then
		self.dirty = false
		self:DrawCommodities()
	end
end

function IntegratedWatchlist:OnCommodityInfoResults(nItemId, tStats, tOrders)
	self.commodityHandler:OnCommodityInfoResults(nItemId, tStats, tOrders)
	self.dirty = true
end

function IntegratedWatchlist:OnOwnedCommodityOrders(nItemId, tStats, tOrders)
	self.listingHandler:OnCommodityInfoResults(nItemId, tStats, tOrders)
	self.dirty = true
end

--[[function Watchlist:AddCommodityById( commodityId )
	local commodity = self.commodityHandler:AddCommodity(commodityId)

	self:DrawCommodities()
	self:OpenWatchlist()
end

function Watchlist:RemoveCommodity(commodity)
	self.commodityHandler:RemoveCommodity(commodity)
	self:DrawCommodities()
end



function Watchlist:OnOK()
	self.wndMain:Close() -- hide the window
end]]

Apollo.RegisterPackage(IntegratedWatchlist, "IntegratedWatchlist", 1, {})