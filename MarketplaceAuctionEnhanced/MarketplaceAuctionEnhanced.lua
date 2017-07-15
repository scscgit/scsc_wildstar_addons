-----------------------------------------------------------------------------------------------
-- Client Lua Script for MarketplaceAuctionEnhanced
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Money"
require "Item" 
require "Unit"
require "MarketplaceLib"
require "ItemAuction"

local lastBuyVScrollPos = 0
local customPageCounter = 0
local categoryPressed = false

-----------------------------------------------------------------------------------------------
-- MarketplaceAuctionEnhanced Module Definition
-----------------------------------------------------------------------------------------------
local MarketplaceAuctionEnhanced = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MarketplaceAuctionEnhanced:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function MarketplaceAuctionEnhanced:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {"MarketplaceAuction"}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)	
end


-----------------------------------------------------------------------------------------------
-- MarketplaceAuctionEnhanced OnLoad
-----------------------------------------------------------------------------------------------
function MarketplaceAuctionEnhanced:OnLoad()
	
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("MarketplaceAuctionEnhanced.xml")
	
	-- Get MarketplaceAuction addon
	self.MarketplaceAuction = Apollo.GetAddon("MarketplaceAuction")
	
	self:InitializeTimer()
	self:InitializeHooks()
	
	Print("onload ")
end


-- Timers
function MarketplaceAuctionEnhanced:InitializeTimer()

	Apollo.RegisterTimerHandler("VScrollTimer", "OnVScrollTimer", self)
end


-----------------------------------------------------------------------------------------------
-- MarketplaceAuctionEnhanced Override Functions
-----------------------------------------------------------------------------------------------
function MarketplaceAuctionEnhanced:InitializeHooks()

	local MarketplaceAuction = Apollo.GetAddon("MarketplaceAuction")
		
	-- Called when user clicks on an item (row) inside the AH
	local fnOldOnRowSelectBtnCheck = MarketplaceAuction.OnRowSelectBtnCheck 
	MarketplaceAuction.OnRowSelectBtnCheck = function(wndHandler, wndControl)
	
		fnOldOnRowSelectBtnCheck(wndHandler, wndControl)
		lastBuyVScrollPos = MarketplaceAuction.wndMain:FindChild("BuyContainer"):FindChild("SearchResultList"):GetVScrollPos()
	end
	
	-- Function called when sort options combo (ending soon, newly listed...) is changed
	local fnOldOnSortOptionsUseableToggle = MarketplaceAuction.OnSortOptionsUseableToggle
	MarketplaceAuction.OnSortOptionsUseableToggle = function(wndHandler, wndControl)

		fnOldOnSortOptionsUseableToggle(wndHandler, wndControl) -- SortFlyoutStat and SortOptionsTimeLH and etc
				
		-- Reset scrollpos and page when changing search filter
		lastBuyVScrollPos = 0
		customPageCounter = 0
	
		MarketplaceAuction:OnRefreshBtn()
	end
	
	-- Function to init buy window with proper scroll positions
	local fnOldInitializeBuy = MarketplaceAuction.InitializeBuy
	MarketplaceAuction.InitializeBuy = function()
		
		fnOldInitializeBuy(MarketplaceAuction)
			
		local strSearchQuery = tostring(MarketplaceAuction.wndMain:FindChild("SearchEditBox"):GetText())
		
		-- if curpage isnt valid (happens at startup) then always go to page 0
		if MarketplaceAuction.nCurPage == nil or MarketplaceAuction.nCurPage < 0 then
			MarketplaceAuction.fnLastSearch(0)
			
		-- if user has written a search string then always go to page 0 or it will fail to list the results
		elseif strSearchQuery and string.len(strSearchQuery) > 0 then
			MarketplaceAuction.fnLastSearch(0)
			MarketplaceAuction:RequestUpdates()
			
		-- got here after user clicked on any category, reset paging	
		elseif categoryPressed == true then
			categoryPressed = false
			customPageCounter = 0
			lastBuyVScrollPos = 0
			MarketplaceAuction.fnLastSearch(0)
			
		-- else, go back to the page we were on earlier (before searching, buying, bidding, selling)
		else
			MarketplaceAuction.fnLastSearch(customPageCounter)
			-- Create new timer to restore the previous vertical scroll position after changing page
			Apollo.StopTimer("VScrollTimer")
			Apollo.CreateTimer("VScrollTimer", 1, false)
		end
		
	end
	
	-- Function called when "go to first buy page" button is pressed
	local fnOldOnBuySearchFirstBtn = MarketplaceAuction.OnBuySearchFirstBtn
	MarketplaceAuction.OnBuySearchFirstBtn = function(wndHandler, wndControl)

		fnOldOnBuySearchFirstBtn(wndHandler, wndControl)	
		customPageCounter = 0
	end
	
	-- Function called when "go to previous buy page" button is pressed
	local fnOldOnOnBuySearchPrevBtn = MarketplaceAuction.OnBuySearchPrevBtn
	MarketplaceAuction.OnBuySearchPrevBtn = function(wndHandler, wndControl)
	
		fnOldOnOnBuySearchPrevBtn(wndHandler, wndControl)
		customPageCounter = MarketplaceAuction.nCurPage - 1
	end
	
	-- Function called when "go to next buy page" button is pressed
	local fnOldOnBuySearchNextBtn = MarketplaceAuction.OnBuySearchNextBtn
	MarketplaceAuction.OnBuySearchNextBtn = function(wndHandler, wndControl)
	
		fnOldOnBuySearchNextBtn(wndHandler, wndControl)
		customPageCounter = MarketplaceAuction.nCurPage + 1
	end
	
	-- Function called when "go to last buy page" button is pressed
	local fnOldOnBuySearchLastBtn = MarketplaceAuction.OnBuySearchLastBtn
	MarketplaceAuction.OnBuySearchLastBtn = function(wndHandler, wndControl)
	
		fnOldOnBuySearchLastBtn(wndHandler, wndControl)
		customPageCounter = math.floor(MarketplaceAuction.nTotalResults / MarketplaceLib.kAuctionSearchPageSize)		
	end
	
	local fnOldInitialize = MarketplaceAuction.Initialize
	MarketplaceAuction.Initialize= function()
	
		fnOldInitialize(MarketplaceAuction)
		-- Force window to open buy decor category as the default
		self:SetDecorAsDefaultCategory()
	end
	
	---------------------------------------------------------------------------------------------------
	-- We would like to know when a user buy/bid items to stay on that AH page, problem is that code is hidden for us :(
	-- The workaround is to check for when user clicks any category/subcategory and in that case reset current page to 0
	-- Ugly hack: InitializeBuy is being called beefore OnCategoryTopBtnCheck & OnCategoryMidBtnCheck, meaning it won't 
	-- see the changed bool value, ttherefore we call InitializeBuy a second time.
	---------------------------------------------------------------------------------------------------
	
	local fnOldOnCategoryTopBtnCheck = MarketplaceAuction.OnCategoryTopBtnCheck
	MarketplaceAuction.OnCategoryTopBtnCheck = function(wndHandler, wndControl)
	
		fnOldOnCategoryTopBtnCheck(wndHandler, wndControl)
		categoryPressed = true
		self.MarketplaceAuction:InitializeBuy()
	end
	
	local fnOldOnCategoryMidBtnCheck = MarketplaceAuction.OnCategoryMidBtnCheck
	MarketplaceAuction.OnCategoryMidBtnCheck= function(wndHandler, wndControl)
	
		fnOldOnCategoryMidBtnCheck(wndHandler, wndControl)
		categoryPressed = true
		self.MarketplaceAuction:InitializeBuy()
	end
end

---------------------------------------------------------------------------------------------------
-- MarketplaceAuctionEnhanced Internal Functions
---------------------------------------------------------------------------------------------------

function MarketplaceAuctionEnhanced:SetDecorAsDefaultCategory()

	for idx, wndTopItem in pairs(self.MarketplaceAuction.wndMain:FindChild("MainCategoryContainer"):GetChildren()) do

	    if idx == 1 then
			-- Uncheck the "Heavy armor -> All" category
			wndTopItem:FindChild("CategoryTopBtn"):SetCheck(false)
		end
		
		if idx == 8 then
			-- Check the "Housing -> decor" category
			wndTopItem:FindChild("CategoryTopBtn"):SetCheck(true)

			local categoryTopItem = wndTopItem:FindChild("CategoryTopBtn"):GetData()
			local categoryTopList = categoryTopItem:FindChild("CategoryTopList")

			for idG, wndMidItem in pairs(categoryTopList:GetChildren()) do	
				if idG == 2 then --"All" button is first in list of miditems, we want second button for "Decor"
					local midButton = wndMidItem:FindChild("CategoryMidBtn")
				 	midButton:SetCheck(true)
					
					-- Set internal values so RefreshBtn() can do its magic
					self.MarketplaceAuction.nSearchId = midButton:GetData()[1]
					self.MarketplaceAuction.strSearchEnum = midButton:GetData()[2]
				end
			end
		end
	end
	
	self.MarketplaceAuction:OnRefreshBtn(self.MarketplaceAuction)
	self.MarketplaceAuction:OnResizeCategories(self.MarketplaceAuction)
end


function MarketplaceAuctionEnhanced:OnVScrollTimer()

	if self.MarketplaceAuction.wndMain and self.MarketplaceAuction.wndMain:IsValid() then
		Apollo.StopTimer("VScrollTimer")
		self.MarketplaceAuction.wndMain:FindChild("SearchResultList"):SetVScrollPos(lastBuyVScrollPos)
	end
end

-----------------------------------------------------------------------------------------------
-- MarketplaceAuctionEnhanced Instance
-----------------------------------------------------------------------------------------------
local MarketplaceAuctionEnhancedInst = MarketplaceAuctionEnhanced:new()
MarketplaceAuctionEnhancedInst:Init()
