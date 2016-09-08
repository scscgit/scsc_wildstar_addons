local ListingHandler = {}

function ListingHandler:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	o:Init()
	return o
end

function ListingHandler:Init()
	self.items = {}

	Apollo.RegisterEventHandler("OwnedCommodityOrders", "OnOwnedCommodityOrders", self)
	--Apollo.RegisterEventHandler("OwnedItemAuctions", "OnOwnedItemAuctions", self)
	
	self:Refresh()
end

function ListingHandler:Refresh()
	MarketplaceLib.RequestOwnedCommodityOrders() 
end

function ListingHandler:OnOwnedCommodityOrders(tOrders)
	self.items = {}

	for nIdx, tCurrOrder in pairs(tOrders) do
		local listing = {
			order = tCurrOrder,
			id = tCurrOrder:GetItem():GetItemId(),
			name = tCurrOrder:GetItem():GetName(),
			count = tCurrOrder:GetCount(),
			pricePerUnit = tCurrOrder:GetPricePerUnit():GetAmount(),
			isBuy = tCurrOrder:IsBuy(),
			expirationTime = tCurrOrder:GetExpirationTime()
		}
		table.insert(self.items, listing)
	end

end

function ListingHandler:GetListingsById(id)
	local returnListings = {}
	for _,listing in pairs(self.items) do
		if listing.id == id then
			table.insert(returnListings, listing)
		end
	end
	return returnListings
end


Apollo.RegisterPackage(ListingHandler, "ListingHandler", 1, {})