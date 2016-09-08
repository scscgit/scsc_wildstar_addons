local Watchlist = {}

function Watchlist:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self
	self.dirty = false

	o:Init()
	return o
end

function Watchlist:Init()
	WatchlistRow = Apollo.GetPackage("WatchlistRow").tPackage

    Apollo.RegisterEventHandler("CommodityInfoResults", "OnCommodityInfoResults", self)
	self.wndMain = Apollo.LoadForm(self.supernova.xmlDoc, "Watchlist", nil, self)

	Apollo.RegisterTimerHandler("OneSecTimer", "OnTimer", self)
end

function Watchlist:AddCommodityById( commodityId )
	local commodity = self.commodityHandler:AddCommodity(commodityId)

	self:DrawCommodities()
	self:OpenWatchlist()
end

function Watchlist:OnCommodityInfoResults(nItemId, tStats, tOrders)
	self.commodityHandler:OnCommodityInfoResults(nItemId, tStats, tOrders)
	self.dirty = true
end

function Watchlist:DrawCommodities()
	if (self.wndMain) then
		local wndGrid = self:GetGrid()
		if (wndGrid) then
			wndGrid:DestroyChildren()
			for key,value in pairs(self.commodityHandler.commodities) do
				local row = WatchlistRow:new({watchlist = self, supernova = self.supernova, commodity = value})
			end
			wndGrid:ArrangeChildrenVert(0)
		end
	end
end

function Watchlist:GetGrid()
	return self.wndMain:FindChild("Grid")
end

function Watchlist:RemoveCommodity(commodity)
	self.commodityHandler:RemoveCommodity(commodity)
	self:DrawCommodities()
end

function Watchlist:OpenWatchlist()
	self.commodityHandler:RequestCommodityInfo()
	self:DrawCommodities()
	self.wndMain:Invoke()
end

function Watchlist:OnRefreshClicked()
	self.commodityHandler:RequestCommodityInfo()
end

function Watchlist:OnTimer()
	if self.dirty then
		self.dirty = false
		self:DrawCommodities()
	end
end

function Watchlist:OnOK()
	self.wndMain:Close() -- hide the window
end

function Watchlist:OnCancel()
	self.wndMain:Close() -- hide the window
end

Apollo.RegisterPackage(Watchlist, "Watchlist", 1, {})