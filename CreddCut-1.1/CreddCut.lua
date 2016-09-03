require "CREDDExchangeLib"

local CreddCut = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("CREDDCut", false, { "MarketplaceCREDD" }, "Gemini:Hook-1.0" )

function CreddCut:OnEnable()
   local credd = Apollo.GetAddon("MarketplaceCREDD")
   self:PostHook(credd, "OnCREDDExchangeInfoResults")
   self:PostHook(credd, "OnHeaderTabCheck", "UpdatePrice")
end

function CreddCut:OnCREDDExchangeInfoResults(mp, stats, orders)
   if stats then
      if stats.arBuyOrderPrices  then
	 self.buyCost = stats.arBuyOrderPrices[1].monPrice:GetAmount() + 1
      end
      if stats.arSellOrderPrices  then
	 self.sellCost = stats.arSellOrderPrices[1].monPrice:GetAmount() - 1
      end
      self:UpdatePrice(mp)
   end
end

function CreddCut:UpdatePrice(mp)
   if not mp or not mp.tWindowMap or not mp.tWindowMap["HeaderBuyBtn"] or not mp.tWindowMap["ActLaterPrice"] then
      return
   end
   local bBuyTabChecked = mp.tWindowMap["HeaderBuyBtn"]:IsChecked()
   mp.tWindowMap["ActLaterPrice"]:SetAmount( (bBuyTabChecked and self.buyCost or self.sellCost) or 0)
   mp.tWindowMap["ActLaterPrice"]:SetTextColor(bBuyTabChecked and ApolloColor.new("ffc2e57f") or ApolloColor.new("UI_TextHoloBody"))
   mp:RefreshBoundCredd()
end
