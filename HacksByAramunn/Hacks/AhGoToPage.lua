local Hack = {
  nId = 20170108,
  strName = "AH Go to Page",
  strDescription = "Adds a way to go to a specific page in the AH search results",
  strXmlDocName = "AhGoToPage.xml",
  tSave = nil,
}

function Hack:Initialize()
  self.addonMarketplaceAuction = Apollo.GetAddon("MarketplaceAuction")
  if not self.addonMarketplaceAuction then return false end
  local funcOriginal = self.addonMarketplaceAuction.OnItemAuctionSearchResults
  self.addonMarketplaceAuction.OnItemAuctionSearchResults = function(...)
    funcOriginal(...)
    if self.bIsLoaded then
      self:InsertGoToPage()
    end
  end
  return true
end

function Hack:Load()
end

function Hack:InsertGoToPage()
  if not self.addonMarketplaceAuction.wndMain then return end
  local wndToModify = self.addonMarketplaceAuction.wndMain
  local arrWindows = {
    "BuyContainer",
    "SearchResultList",
    "BuyPageBtnContainer",
  }
  for idx, strWindow in ipairs(arrWindows) do
    wndToModify = wndToModify:FindChild(strWindow)
    if not wndToModify then return end
  end
  local wndGoToPage = Apollo.LoadForm(self.xmlDoc, "GoToPage", wndToModify, self)
  wndGoToPage:FindChild("PageNumber"):SetText(tostring(self.addonMarketplaceAuction.nCurPage + 1))
end

function Hack:OnGoTo(wndHandler, wndControl)
  local nMaxPage = math.floor(self.addonMarketplaceAuction.nTotalResults / MarketplaceLib.kAuctionSearchPageSize)
  local wndPage = wndControl:GetParent():FindChild("PageNumber")
  local nPage = tonumber(wndPage:GetText()) - 1
  if nPage < 0 then nPage = 0 end
  if nPage > nMaxPage then nPage = nMaxPage end
  self.addonMarketplaceAuction.fnLastSearch(nPage)
end

function Hack:Unload()
end

function Hack:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Hack:Register()
  local addonMain = Apollo.GetAddon("HacksByAramunn")
  addonMain:RegisterHack(self)
end

local HackInst = Hack:new()
HackInst:Register()
