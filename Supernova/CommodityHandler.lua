local CommodityHandler = {}

function CommodityHandler:new(o)
 	o = o or {}   -- create object if user does not provide one
	setmetatable(o, self)
	self.__index = self

	self.commodities = {}
	self.commodityMap = {}
    Apollo.RegisterEventHandler("CommodityInfoResults", "OnCommodityInfoResults", self)
	self.x = 6
	return o
end

function CommodityHandler:OnLoad()
    Commodity = Apollo.GetPackage("Commodity").tPackage
end


function CommodityHandler:OnCommodityInfoResults(nItemId, tStats, tOrders)
	if self.commodityMap[nItemId] then
		local commodity = self.commodityMap[nItemId]
		commodity:UpdateTStats(tStats)
	end
end

function CommodityHandler:AddCommodity(commodityId)
	if self.commodityMap[commodityId] then
		return self.commodityMap[commodityId]
	else
		local commodity = Commodity:new {supernova = self.supernova, id = commodityId}
		self.commodityMap[commodityId] = commodity
		table.insert(self.commodities, commodity)

		MarketplaceLib.RequestCommodityInfo(commodity:GetId())
		return commodity
	end
end

function CommodityHandler:RemoveCommodity(commodity)
	if self.commodityMap[commodity:GetId()] then
		self.commodityMap[commodity:GetId()] = nil
		for key,value in pairs(self.commodities) do
			if value == commodity then
				self.commodities[key] = nil
			end
		end
	end
end

function CommodityHandler:ClearCommodities()
	self.commodityMap = {}
	self.commodities = {}
end

function CommodityHandler:RequestCommodityInfo()
	for key, commodity in pairs(self.commodities) do
		MarketplaceLib.RequestCommodityInfo(commodity:GetId())
	end
end

function CommodityHandler:Refresh()
	self:RequestCommodityInfo()
end

function CommodityHandler:Serialize()
	local save = {}
	for key, value in pairs(self.commodities) do
		table.insert(save, {id = value.id, buyWatchPrice = value.buyWatchPrice, sellWatchPrice = value.sellWatchPrice}) 
	end
	return save
end

function CommodityHandler:Deserialize(commodityIds)
	self:ClearCommodities()
	for key, value in pairs(commodityIds) do
		self:AddCommodity(value)
 	end
end

function CommodityHandler:Deserialize2(commodities)
	self:ClearCommodities()
	for key, value in pairs(commodities) do
		local commodity = self:AddCommodity(value.id)
		if value.buyWatchPrice then
			commodity.buyWatchPrice = value.buyWatchPrice
		end
		if value.sellWatchPrice then
			commodity.sellWatchPrice = value.sellWatchPrice
		end
 	end
end

Apollo.RegisterPackage(CommodityHandler, "CommodityHandler", 1, {})