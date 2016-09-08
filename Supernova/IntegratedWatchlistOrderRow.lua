local IntegratedWatchlistOrderRow = {}

function IntegratedWatchlistOrderRow:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o:Init()
	return o
end

function IntegratedWatchlistOrderRow:Init()
	local rowWindow = Apollo.LoadForm(self.supernova.xmlDoc , "IntegratedWatchlistOrderRow", self.watchlist:GetGrid(), self)
	rowWindow:FindChild("ItemName"):SetText(self.listing.name)
	rowWindow:FindChild("ItemCount"):SetText(self.listing.count)
	--rowWindow:FindChild("ItemExpiration"):SetText(self.listing.expirationTime)
	if (self.listing.isBuy) then
		--rowWindow:FindChild("ItemBuySell"):SetText("BUY")
		rowWindow:FindChild("SellPrice"):SetText(self.listing.pricePerUnit)
			rowWindow:FindChild("BuySell"):SetText("Buy Order")
		if self.commodity.sell1 == "--" then

		else
			if self.listing.pricePerUnit >= self.commodity.sell1 then
				rowWindow:FindChild("SellPrice"):SetTextColor("green")
			else
				rowWindow:FindChild("SellPrice"):SetTextColor("red")
			end
		end
	else
		if self.commodity.buy1 == "--" then

		else
			rowWindow:FindChild("BuyPrice"):SetText(self.listing.pricePerUnit)
			rowWindow:FindChild("BuySell"):SetText("Sell Order")
			if self.listing.pricePerUnit <= self.commodity.buy1 then
				rowWindow:FindChild("BuyPrice"):SetTextColor("green")
			else
				rowWindow:FindChild("BuyPrice"):SetTextColor("red")
			end
		end
	end
end

function IntegratedWatchlistOrderRow:OnLaunchTicket( wndHandler, wndControl, eMouseButton )
	self.supernova:LaunchTicket(self.commodity)
end

function IntegratedWatchlistOrderRow:OnCloseButtonClicked(wndHandler, wndControl, eMouseButton )
	self.watchlist:RemoveCommodity(self.commodity)
end

function IntegratedWatchlistOrderRow:OnCancel(wndHandler, wndControl, eMouseButton )
	self.listing.order:Cancel()
	MarketplaceLib.RequestOwnedCommodityOrders() 
end

Apollo.RegisterPackage(IntegratedWatchlistOrderRow, "IntegratedWatchlistOrderRow", 1, {})