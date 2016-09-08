-----------------------------------------------------------------------------------------------
-- Client Lua Script for Supernova
-- Copyright (c) Shikaga. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Supernova Module Definition
-----------------------------------------------------------------------------------------------
local Supernova = {}
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local marketplaceWindow = nil
local x = 1
local y = 0
local restoreCalled = false
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Supernova:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Supernova:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = "Supernova"
	local tDependencies = {"MarketplaceCommodity", "CommodityHandler", "Commodity", "TradeTicket", "TradeTicketHandler", "ListingPriceHandler"} 
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- HelloWorld OnLoad
-----------------------------------------------------------------------------------------------
function Supernova:OnLoad()
	TradeTicketHandler = Apollo.GetPackage("TradeTicketHandler").tPackage
    Watchlist = Apollo.GetPackage("Watchlist").tPackage
    IntegratedWatchlist = Apollo.GetPackage("IntegratedWatchlist").tPackage
    ListingPriceHandler = Apollo.GetPackage("ListingPriceHandler").tPackage
    CommodityHandler = Apollo.GetPackage("CommodityHandler").tPackage
    ListingHandler = Apollo.GetPackage("ListingHandler").tPackage

	self.xmlDoc = XmlDoc.CreateFromFile("Supernova.xml")
				
	self.MarketplaceCommodity = Apollo.GetAddon("MarketplaceCommodity")
    self:InitializeHooks()

    TradeTicketHandler.xmlDoc = self.xmlDoc
    ListingPriceHandler.xmlDoc = self.xmlDoc

    self.commodityHandler = CommodityHandler:new({supernova = self})
    self.listingHandler = ListingHandler:new({supernova = self})

    self.watchlist = Watchlist:new({supernova = self, commodityHandler = self.commodityHandler})
    self.integratedWatchlist = IntegratedWatchlist:new({supernova = self, commodityHandler = self.commodityHandler, listingHandler = self.listingHandler})
    self.ListingPriceHandler = ListingPriceHandler:new({supernova = self})
    self.tradeTicketHandler = TradeTicketHandler:new()
    Print("ZZ")
end

function Supernova:OnSave(eLevel)
	local save = {}
	save.commodities = self.commodityHandler:Serialize()
	return save
end

function Supernova:OnRestore(eLevel, tData)
	if tData.watchlist then
		self.commodityHandler:Deserialize(tData.watchlist)
	end
	if tData.commodities then
		self.commodityHandler:Deserialize2(tData.commodities)
	end
end

function Supernova:InitializeHooks()
	self:AddAddCommodityButtons()
	self:AddTicketButtonsToMarketplaceListing()
end

function Supernova:AddAddCommodityButtons()
	Print("AAA")
	local fnOldHeaderBtnToggle = self.MarketplaceCommodity.OnHeaderBtnToggle
    self.MarketplaceCommodity.OnHeaderBtnToggle = function(tMarketPlaceCommodity)
		marketplaceWindow  = tMarketPlaceCommodity.wndMain
        fnOldHeaderBtnToggle(tMarketPlaceCommodity)
        local children = marketplaceWindow:FindChild("MainScrollContainer"):GetChildren()
        for i, child in ipairs(children) do
            if child:GetText() == "" then
                local x = Apollo.LoadForm(self.xmlDoc, "AddButton", child, self)
            end
        end
        Apollo.LoadForm(self.xmlDoc , "CommodityButtons", marketplaceWindow, self)
    end
end

function Supernova:AddTicketButtonsToMarketplaceListing()
	
end

-----------------------------------------------------------------------------------------------
-- HelloWorldForm Functions
-----------------------------------------------------------------------------------------------

function Supernova:OnToggleWatchlist()
	self.watchlist:OpenWatchlist()
end

function Supernova:OnToggleIntegratedWatchlist()
	self.integratedWatchlist:Open()
end

-- when the Add Commodity button is clicked
function Supernova:OnAddCommodity( wndHandler, wndControl, eMouseButton )
	local commodityId = tonumber(wndControl:GetParent():GetName());
	self.watchlist:AddCommodityById(commodityId)
end

function Supernova:LaunchTicket(commodity)
	self.tradeTicketHandler:OpenTicket(commodity)
end

-----------------------------------------------------------------------------------------------
-- Utils
-----------------------------------------------------------------------------------------------


function Supernova:PrintMembers(o)
	Print('Printing Members')
	Print('----')
	for key,value in pairs(getmetatable(o)) do
	    Print("found member " .. key);
	end
	Print('----')
end

-----------------------------------------------------------------------------------------------
-- Supernova Instance
-----------------------------------------------------------------------------------------------
local SupernovaInst = Supernova:new()
SupernovaInst:Init()
