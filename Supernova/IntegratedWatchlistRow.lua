local IntegratedWatchlistRow = {}

function IntegratedWatchlistRow:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o:Init()
	return o
end

function IntegratedWatchlistRow:Init()
	local rowWindow = Apollo.LoadForm(self.supernova.xmlDoc , "IntegratedWatchlistRow", self.watchlist:GetGrid(), self)
	self.window = rowWindow
	rowWindow:FindChild("CommodityName"):SetText(self.commodity:GetName())
	self:UpdateText()
	self:SetIcon(rowWindow)
end

function IntegratedWatchlistRow:UpdateText()
	self.window:FindChild("BuyPrice"):SetText(self.commodity.buy1)
	self.window:FindChild("SellPrice"):SetText(self.commodity.sell1)
	self.window:FindChild("BuyWatchPrice"):SetText(self.commodity.buyWatchPrice)
	self.window:FindChild("SellWatchPrice"):SetText(self.commodity.sellWatchPrice)
	self:UpdateWatchPriceColor()
end

function IntegratedWatchlistRow:SetIcon(window)
	window:FindChild("CommodityItem"):SetSprite(self.commodity:GetIcon())
	local tItem  = self.commodity:GetItem()
	local tooltip = Tooltip.GetItemTooltipForm(self, 
	window:FindChild("CommodityItem"), 
	tItem, 
	{bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()}
	)
end

function IntegratedWatchlistRow:OnLaunchTicket( wndHandler, wndControl, eMouseButton )
	self.supernova:LaunchTicket(self.commodity)
end

function IntegratedWatchlistRow:OnCloseButtonClicked(wndHandler, wndControl, eMouseButton )
	self.watchlist:RemoveCommodity(self.commodity)
end

function IntegratedWatchlistRow:OnBuyTargetChanged()
	local buyTarget = self.window:FindChild("BuyWatchPrice"):GetText()
	self.commodity:SetBuyWatchPrice(buyTarget)
	self:UpdateWatchPriceColor()
end

function IntegratedWatchlistRow:OnSellTargetChanged()
	local sellTarget = self.window:FindChild("SellWatchPrice"):GetText()
	self.commodity:SetSellWatchPrice(sellTarget)
	self:UpdateWatchPriceColor()
end

function IntegratedWatchlistRow:UpdateWatchPriceColor()

	if tonumber(self.commodity.buyWatchPrice) and tonumber(self.commodity.sell1) then
		if tonumber(self.commodity.buyWatchPrice) >= tonumber(self.commodity.sell1) then
			self.window:FindChild("BuyWatchPrice"):SetTextColor("green")
		else
			self.window:FindChild("BuyWatchPrice"):SetTextColor("red")
		end
	end
	if tonumber(self.commodity.sellWatchPrice) and tonumber(self.commodity.buy1) then
		if tonumber(self.commodity.sellWatchPrice) <= tonumber(self.commodity.buy1) then
			self.window:FindChild("SellWatchPrice"):SetTextColor("green")
		else
			self.window:FindChild("SellWatchPrice"):SetTextColor("red")
		end
	end
end

Apollo.RegisterPackage(IntegratedWatchlistRow, "IntegratedWatchlistRow", 1, {})