require "Apollo"
require "Window"

local cGreen = CColor.new(0, 1, 0, 1) 
local cRed = CColor.new(250/255,0/255,0/255,1)

local NoSwiping = {}

function NoSwiping:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function NoSwiping:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = {  "MarketplaceCommodity", }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function NoSwiping:OnLoad()
	Apollo.GetPackage("Gemini:Hook-1.0").tPackage:Embed(self)
	NoSwiping.MPC = Apollo.GetAddon("MarketplaceCommodity")
	if NoSwiping.MPC then
		self:RawHook(NoSwiping.MPC,"OnCommodityInfoResults")

	end
end

local CXRAKE = (100-MarketplaceLib.kCommodityAuctionRake)/100

local function getItemDetails(i)
	local di = Item.GetDataFromId(i):GetDetailedInfo().tPrimary
	local dx = {
		s=di.tCost.arMonSell[1]:GetAmount(),
		n=di.strName
		}
	return dx
end

function NoSwiping:OnCommodityInfoResults(luaCaller, nItemId, tStats, tOrders)
	self.hooks[NoSwiping.MPC].OnCommodityInfoResults(luaCaller, nItemId, tStats, tOrders)
	local wndMC = NoSwiping.MPC.wndMain
	if (wndMC and wndMC:FindChild("HeaderSellOrderBtn") and wndMC:FindChild("HeaderSellOrderBtn"):IsChecked()) then
		local pS, pE = pcall(getItemDetails, nItemId)
		if pS then
			local wndMatch = wndMC:FindChild("MainScrollContainer"):FindChild(nItemId)
			if wndMatch then
				local buyamt = wndMatch:FindChild("ListSubtitlePriceRight"):GetAmount()
				local vndamt = pE.s
				local wListName = wndMatch:FindChild("ListName")				
				if (buyamt * CXRAKE) > vndamt then
					wListName:SetTextColor(cGreen)
				else
					wListName:SetTextColor(cRed)
				end
			end
		end
	elseif (wndMC and wndMC:FindChild("HeaderSellNowBtn") and wndMC:FindChild("HeaderSellNowBtn"):IsChecked()) then
		local pS, pE = pcall(getItemDetails, nItemId)
		if pS then
			local wndMatch = wndMC:FindChild("MainScrollContainer"):FindChild(nItemId)
			if wndMatch then
				local buyamt = wndMatch:FindChild("ListSubtitlePriceLeft"):GetAmount()
				local vndamt = pE.s
				local wListName = wndMatch:FindChild("ListName")				
				if (buyamt * CXRAKE) > vndamt then
					wListName:SetTextColor(cGreen)
				else
					wListName:SetTextColor(cRed)
				end
			end
		end

	elseif (wndMC and wndMC:FindChild("HeaderBuyNowBtn") and wndMC:FindChild("HeaderBuyNowBtn"):IsChecked()) then
		local pS, pE = pcall(getItemDetails, nItemId)
		if pS then
			local wndMatch = wndMC:FindChild("MainScrollContainer"):FindChild(nItemId)
			if wndMatch then
				local buyamt = wndMatch:FindChild("ListSubtitlePriceLeft"):GetAmount()
				local vndamt = pE.s
				local wListName = wndMatch:FindChild("ListName")				
				if (buyamt * CXRAKE) < vndamt then
					wListName:SetTextColor(cGreen)
				else
					wListName:SetTextColor(cRed)
				end
			end
		end

	elseif (wndMC and wndMC:FindChild("HeaderBuyOrderBtn") and wndMC:FindChild("HeaderBuyOrderBtn"):IsChecked()) then
		local pS, pE = pcall(getItemDetails, nItemId)
		if pS then
			local wndMatch = wndMC:FindChild("MainScrollContainer"):FindChild(nItemId)
			if wndMatch then
				local buyamt = wndMatch:FindChild("ListSubtitlePriceLeft"):GetAmount()
				local vndamt = pE.s
				local wListName = wndMatch:FindChild("ListName")				
				if (buyamt * CXRAKE) < vndamt then
					wListName:SetTextColor(cGreen)
				else
					wListName:SetTextColor(cRed)
				end
			end
		end

	end
end


local NoSwipingInst = NoSwiping:new()
NoSwipingInst:Init()
