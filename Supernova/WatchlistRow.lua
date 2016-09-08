local WatchlistRow = {}

function WatchlistRow:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o:Init()
	return o
end

function WatchlistRow:Init()
	local rowWindow = Apollo.LoadForm(self.supernova.xmlDoc , "Row", self.watchlist:GetGrid(), self)
	rowWindow:FindChild("CommodityName"):SetText(self.commodity:GetName())
	rowWindow:FindChild("BuyPrice"):SetText(self.commodity.buy1)
	rowWindow:FindChild("SellPrice"):SetText(self.commodity.sell1)
end

function WatchlistRow:OnRowClicked( wndHandler, wndControl, eMouseButton )
	self.supernova:LaunchTicket(self.commodity)
end

function WatchlistRow:OnCloseButtonClicked(wndHandler, wndControl, eMouseButton )
	self.watchlist:RemoveCommodity(self.commodity)
end

Apollo.RegisterPackage(WatchlistRow, "WatchlistRow", 1, {})