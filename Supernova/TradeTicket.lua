local TradeTicket = {}

local BUY = 0
local SELL = 1

function TradeTicket:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	local window = Apollo.LoadForm(TradeTicket.xmlDoc, "TradeTicket", nil, o)
	o.window = window

	Apollo.RegisterEventHandler("PostCommodityOrderResult", "OnPostCommodityOrderResult", o)

	o:Init()
	return o
end

function TradeTicket:Init()
	self:DisableExecuteButton()
	self.buySell = BUY

	self.volume = 1
	self.price = 0

	self:SetTextFields()
	self:SetIcon()

	self:Validate()
end

function TradeTicket:SetTextFields()
	self.window:FindChild("CommodityName"):SetText(self.commodity:GetName())
	self:SetBuyPrices()
end

function TradeTicket:SetBuyPrices()
	self.window:FindChild("Top1Value"):SetText(self.commodity.buy1)
	self.window:FindChild("Top10Value"):SetText(self.commodity.buy10)
	self.window:FindChild("Top50Value"):SetText(self.commodity.buy50)
	self.window:FindChild("OrderCount"):SetText(self.commodity.sellOrderCount)
end

function TradeTicket:SetSellPrices()
	self.window:FindChild("Top1Value"):SetText(self.commodity.sell1)
	self.window:FindChild("Top10Value"):SetText(self.commodity.sell10)
	self.window:FindChild("Top50Value"):SetText(self.commodity.sell50)
	self.window:FindChild("OrderCount"):SetText(self.commodity.buyOrderCount)
end

function TradeTicket:SetIcon()
	self.window:FindChild("TradeWindow"):FindChild("CommodityItem"):SetSprite(self.commodity:GetIcon())
	local tItem  = self.commodity:GetItem()
	local tooltip = Tooltip.GetItemTooltipForm(self, 
	self.window:FindChild("TradeWindow"):FindChild("CommodityItem"), 
	tItem, 
	{bPrimary = true, bSelling = false, itemCompare = tItem:GetEquippedItemForItemType()}
	)
end

function TradeTicket:OnPostCommodityOrderResult(eAuctionPostResult, orderSource, nActualCost)
	MarketplaceLib.RequestOwnedCommodityOrders() 

	local isBuy = orderSource:IsBuy()
	local isLimitOrder = false

	if orderSource:GetExpirationTime() then
		isLimitOrder = true
	end

	self:HideTradeWindow()
	self:ShowConfirmationWindow()
	--Print(isBuy .. " | " .. count .. " | " .. itemName)
	local okMessage = "You succesfully " .. self:BoughtOrSoldString() .. " " .. orderSource:GetCount() .. " [" .. orderSource:GetItem():GetName() .. "] at " .. orderSource:GetPricePerUnit():GetAmount() .. "c each"
	if isLimitOrder then
		okMessage = "You succesfully created a Limit Order to " .. self:BuyOrSellString()  .. " " .. orderSource:GetCount() .. " [" .. orderSource:GetItem():GetName() .. "] at " .. orderSource:GetPricePerUnit():GetAmount() .. "c each"
	end
	local responseString = {
		[MarketplaceLib.AuctionPostResult.Ok] 						= okMessage,
		[MarketplaceLib.AuctionPostResult.DbFailure] 				= Apollo.GetString("MarketplaceAuction_TechnicalDifficulties"),
		[MarketplaceLib.AuctionPostResult.Item_BadId] 				= Apollo.GetString("MarketplaceAuction_CantPostInvalidItem"),
		[MarketplaceLib.AuctionPostResult.NotEnoughToFillQuantity]	= Apollo.GetString("GenericError_Vendor_NotEnoughToFillQuantity"),
		[MarketplaceLib.AuctionPostResult.NotEnoughCash]			= Apollo.GetString("GenericError_Vendor_NotEnoughCash"),
		[MarketplaceLib.AuctionPostResult.NotReady] 				= Apollo.GetString("MarketplaceAuction_TechnicalDifficulties"),
		[MarketplaceLib.AuctionPostResult.CannotFillOrder]		 	= Apollo.GetString("MarketplaceCommodities_NoOrdersFound"),
		[MarketplaceLib.AuctionPostResult.TooManyOrders] 			= Apollo.GetString("MarketplaceAuction_MaxOrders"),
		[MarketplaceLib.AuctionPostResult.OrderTooBig] 				= Apollo.GetString("MarketplaceAuction_OrderTooBig")
	}

	local confirmationString = responseString[eAuctionPostResult] -- .. "\n\n" .. Apollo.GetString("MarketplaceCommodity_CannotFillBuyOrder") .. "\n\n" .. Apollo.GetString("MarketplaceCommodity_CannotFillSellOrder")
	Print(confirmationString)
	self:SetConfirmationString(confirmationString)
end

function TradeTicket:OnListInputNumberChanged()
	self.volume = self.window:FindChild("TradeWindow"):FindChild("ListInputNumber"):GetText()
	self:Validate()
end

function TradeTicket:OnListInputPriceAmountChanged()
	self.price = math.max(0, tonumber(self.window:FindChild("TradeWindow"):FindChild("ListInputPrice"):GetAmount() or 0))
	self:Validate()
end

function TradeTicket:OnListInputNumberDownBtn()
	self.volume = math.max(0, self.volume - 1)
	self:UpdateVolumeField()
end

function TradeTicket:OnListInputNumberUpBtn()
	self.volume = self.volume + 1
	self:UpdateVolumeField()
end

function TradeTicket:OnCloseTicket()
	self.window:Close()
end

function TradeTicket:OnExecuteTrade()

end

function TradeTicket:UpdateVolumeField()
	self.window:FindChild("TradeWindow"):FindChild("ListInputNumber"):SetText(self.volume)
	self:Validate()
end

function TradeTicket:HideTradeWindow()
	self.window:FindChild("TradeWindow"):Show(false)
end

function TradeTicket:ShowConfirmationWindow()
	self.window:FindChild("ConfirmationWindow"):Show(true)
end

function TradeTicket:SetConfirmationString(string)
	self.window:FindChild("ConfirmationMessage"):SetText(string)
end

function TradeTicket:EnableExecuteButton()

	function round(num, idp)
		local mult = 10^(idp or 0)
		return math.floor(num * mult + 0.5) / mult
	end

	local executeButton = self.window:FindChild("ExecuteButton")
	local order
	if self.buySell == BUY then
		order = CommodityOrder.newBuyOrder(self.commodity:GetId())
		order:SetForceImmediate(false) -- If false then a Order will be created, rather than booking at market
	else
		order = CommodityOrder.newSellOrder(self.commodity:GetId())
		order:SetForceImmediate(false) -- If false then a Order will be created, rather than booking at market
	end

	local volume = tonumber(self.window:FindChild("TradeWindow"):FindChild("ListInputNumber"):GetText())
	order:SetCount(volume)
	order:SetPrices(self.window:FindChild("TradeWindow"):FindChild("ListInputPrice"):GetCurrency())

	if order:CanPost() then
		local execBtn = self.window:FindChild("Button")

		execBtn:SetActionData(GameLib.CodeEnumConfirmButtonType.MarketplaceCommoditiesSubmit, order)
		executeButton:Enable(true)
		local totalPrice = order:GetCount() * order:GetPricePerUnit():GetAmount() + order:GetTax():GetAmount()
		local each = round(totalPrice / order:GetCount(),2)
		local text = "You are going to " .. self:BuyOrSellString() .. " " .. order:GetCount() .. " [" .. self.commodity:GetName() .. "] for " .. order:GetPricePerUnit():GetAmount() .. "c each plus a fee of " .. order:GetTax():GetAmount() .. "c for total price of " .. totalPrice .. "c costing roughly " .. each .. " per unit"
		self.window:FindChild("TradeWindow"):FindChild("SummaryText"):SetText(text)
	else

	end
end

function TradeTicket:DisableExecuteButton()
	self.window:FindChild("ExecuteButton"):Enable(false)

	local text = "Set a valid price and volume"
	self.window:FindChild("TradeWindow"):FindChild("SummaryText"):SetText(text)
end

function TradeTicket:OnBuySellToggle()
	if self.buySell == BUY then
		self.buySell = SELL
		self.window:FindChild("BuySellButton"):SetText("Sell")
		self:SetSellPrices()
	else
		self.buySell = BUY
		self.window:FindChild("BuySellButton"):SetText("Buy")
		self:SetBuyPrices()
	end
	self:Validate()
end

function TradeTicket:Validate()
	local orderPrice = self.price * self.volume
	local orderFee = math.max(orderPrice * MarketplaceLib.kfCommodityBuyOrderTaxMultiplier, MarketplaceLib.knCommodityBuyOrderTaxMinimum)
	local totalPrice = orderPrice + orderFee

	if totalPrice > 0 then
		self:EnableExecuteButton()
	else
		self:DisableExecuteButton()
	end

end

function TradeTicket:BuyOrSellString()
	if self.buySell == BUY then
		return "Buy"
	else
		return "Sell"
	end
end

function TradeTicket:BoughtOrSoldString()
	if self.buySell == BUY then
		return "Bought"
	else
		return "Sold"
	end
end

function TradeTicket:HelperFormatTimeString(oExpirationTime)
	local strResult = ""
	local nInSeconds = math.floor(math.abs(Time.SecondsElapsed(oExpirationTime))) -- CLuaTime object
	local nHours = math.floor(nInSeconds / 3600)
	local nMins = math.floor(nInSeconds / 60 - (nHours * 60))

	if nHours > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Hours"), nHours)
	elseif nMins > 0 then
		strResult = String_GetWeaselString(Apollo.GetString("MarketplaceListings_Minutes"), nMins)
	else
		strResult = Apollo.GetString("MarketplaceListings_LessThan1m")
	end
	return strResult
end

Apollo.RegisterPackage(TradeTicket, "TradeTicket", 1, {})