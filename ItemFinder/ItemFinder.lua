----------------------------------------------------------------------------------------------
-- ItemFinder
--- © 2015 Vim
--
--- ItemFinder is free software, all files licensed under the GPLv3. See LICENSE for details.
--
---- TODO
--
--- Reset filters on search button rightclick 
--- Progress bar colors are ugly
--- tune search speed
--
---- Feature requests
--
--- optional cache
--- decor filters
--- drop location

local tCategories = {
	  [1] = {label = "Light Armor"},
	  [2] = {label = "Medium Armor"},
	  [3] = {label = "Heavy Armor"},
	  [8] = {label = "Greatsword"},
	 [12] = {label = "Resonators"},
	 [16] = {label = "Pistols"},
	 [22] = {label = "Psyblade"},
	 [24] = {label = "Claws"},
	[108] = {label = "Heavy Gun"},
}

local tSlots = {
	[GameLib.CodeEnumEquippedItems.Head]             = {label = "Head"},
	[GameLib.CodeEnumEquippedItems.Shoulder]         = {label = "Shoulder"},
	[GameLib.CodeEnumEquippedItems.Chest]            = {label = "Chest"},
	[GameLib.CodeEnumEquippedItems.Hands]            = {label = "Hands"},
	[GameLib.CodeEnumEquippedItems.Legs]             = {label = "Legs"},
	[GameLib.CodeEnumEquippedItems.Feet]             = {label = "Feet"},
	[GameLib.CodeEnumEquippedItems.WeaponAttachment] = {label = "Attachment"},
	[GameLib.CodeEnumEquippedItems.System]           = {label = "Support"},
	[GameLib.CodeEnumEquippedItems.Gadget]           = {label = "Gadget"},
	[GameLib.CodeEnumEquippedItems.Implant]          = {label = "Implant"},
	[GameLib.CodeEnumEquippedItems.Shields]          = {label = "Shield"},
	[GameLib.CodeEnumEquippedItems.WeaponPrimary]    = {label = "Weapon"},
}

local tStats = {
	[Unit.CodeEnumProperties.AssaultRating]              = {label = "Assault Rating",short = "AP"},
	[Unit.CodeEnumProperties.SupportRating]              = {label = "Support Rating", short = "SP"},
	[Unit.CodeEnumProperties.Rating_CritChanceIncrease]  = {label = "Crit",          short = "CHR"},
	[Unit.CodeEnumProperties.RatingMultiHitChance]       = {label = "Multi-Hit",     short = "MH"},
	[Unit.CodeEnumProperties.RatingCritSeverityIncrease] = {label = "Crit Severity", short = "CSR"},
	[Unit.CodeEnumProperties.Rating_AvoidReduce]         = {label = "Strikethrough", short = "SR"},
	[Unit.CodeEnumProperties.Armor]                      = {label = "Armor",         short = "A"},
	[Unit.CodeEnumProperties.ShieldCapacityMax]          = {label = "Shield",        short = "S"},
	[Unit.CodeEnumProperties.RatingGlanceChance]         = {label = "Glance",        short = "G"},
	[Unit.CodeEnumProperties.RatingDamageReflectChance]  = {label = "Reflect",       short = "R"},
	[Unit.CodeEnumProperties.RatingVigor]                = {label = "Vigor",         short = "V"},
	[Unit.CodeEnumProperties.Rating_AvoidIncrease]       = {label = "Deflect",       short = "DR"},
	[Unit.CodeEnumProperties.RatingCriticalMitigation]   = {label = "Crit Mitigation", short = "CM"},
	[Unit.CodeEnumProperties.PvPOffensiveRating]         = {label = "PvP Power",     short = " PvP PR"},
	[Unit.CodeEnumProperties.PvPDefensiveRating]         = {label = "PvP Defense",   short = " PvP DR"},
	[Unit.CodeEnumProperties.RatingCCResilience]         = {label = "CC Resilience", short = "CCR"},
	[Unit.CodeEnumProperties.RatingIntensity]            = {label = "Intensity",     short = "I"},
	[Unit.CodeEnumProperties.BaseFocusPool]              = {label = "Focus Pool",    short = "FP"},
	[Unit.CodeEnumProperties.RatingFocusRecovery]        = {label = "Focus Regen",   short = "FR"},
	[Unit.CodeEnumProperties.BaseHealth]                 = {label = "Base Health",   short = "BH"},
	[Unit.CodeEnumProperties.RatingLifesteal]            = {label = "Lifesteal",     short = "LS"},
}

local tItemQualities = {
	[Item.CodeEnumItemQuality.Inferior]  = {label = "Inferior",  color = "ItemQuality_Inferior"},
	[Item.CodeEnumItemQuality.Average]   = {label = "Average",   color = "ItemQuality_Average"},
	[Item.CodeEnumItemQuality.Good]      = {label = "Good",      color = "ItemQuality_Good"},
	[Item.CodeEnumItemQuality.Excellent] = {label = "Excellent", color = "ItemQuality_Excellent"},
	[Item.CodeEnumItemQuality.Superb]    = {label = "Superb",    color = "ItemQuality_Superb"},
	[Item.CodeEnumItemQuality.Legendary] = {label = "Legendary", color = "ItemQuality_Legendary"},
	[Item.CodeEnumItemQuality.Artifact]  = {label = "Artifact",  color = "ItemQuality_Artifact"},
}

local tCurrencies = {
	[Money.CodeEnumCurrencyType.Credits]          = {label = "Money",     icon = "CRB_CurrencySprites:sprCashGold"},
	[Money.CodeEnumCurrencyType.Renown]           = {label = "Renown",    icon = "IconSprites:Icon_Windows_UI_CRB_Coin_Reknown"},
	[Money.CodeEnumCurrencyType.ElderGems]        = {label = "Elder Gem", icon = "IconSprites:Icon_Windows_UI_CRB_Coin_ElderGems"},
	[Money.CodeEnumCurrencyType.CraftingVouchers] = {label = "Vouchers",  icon = "IconSprites:Icon_Windows_UI_CRB_Coin_TradeskillVoucher"},
	[Money.CodeEnumCurrencyType.Prestige]         = {label = "Prestige",  icon = "IconSprites:Icon_Windows_UI_CRB_Coin_Prestige"},
	[Money.CodeEnumCurrencyType.Glory]            = {label = "Glory",     icon = "IconSprites:Icon_Windows_UI_CRB_Coin_Raid"},
}

-----------------------------------------------------------------------------------------------
-- Init

ItemFinder = {
	name = "ItemFinder",
	version = {0,10,0},

	nMaxItems = 90000,         -- FIXME: tune these
	nMaxDisplayedItems = 1000, -- 
	nScanPerTick = 300,       --- make sure we have :
	nShowPerTick = 2000,      --- nShowPerTick/fShowInterval > nScanPerTick/fScanInterval
	fScanInterval = 1/20,     --- to ensure we display items faster than we scan them
	fShowInterval = 1/4,      --- so we don't hit 100% with more than nMaxDisplayedItems waiting to be drawn
 	
	tCategoryFilters = {},
	tSlotFilters = {},
	tStatFilters = {},
	tQualityFilters = {},
	tPriceFilters = {},
	nILvlMin = nil,
	nILvlMax = nil,
	
	tItems = {},
	nScanIndex = 1,
	nShowIndex = 1,
	nLastValidId = 1,
} 

function ItemFinder:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ItemFinder.xml")
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ItemFinder", nil, self)
	self.wndMain:FindChild("Title"):SetText(self.name .. " v" .. table.concat(self.version,"."))
	self.wndProgress = self.wndMain:FindChild("ProgressBar")
	self.wndItemList = self.wndMain:FindChild("ItemList")
	
	self:DropDownList("Category", tCategories, self.tCategoryFilters)
	self:DropDownList("Slot", tSlots, self.tSlotFilters)
	self:ButtonFilters(self.wndMain:FindChild("StatFilters"), tStats, self.tStatFilters, true) 
	self:ButtonFilters(self.wndMain:FindChild("QualityFilters"), tItemQualities, self.tQualityFilters)
	self:ButtonFilters(self.wndMain:FindChild("PriceFilters"), tCurrencies, self.tPriceFilters)

	self.tmrItemScanner = ApolloTimer.Create(self.fScanInterval, true, "ItemScanner", self)
	self.tmrItemScanner:Stop()
	
	self.tmrUpdateDisplay = ApolloTimer.Create(self.fShowInterval, true, "UpdateDisplay", self)
	self.tmrUpdateDisplay:Stop()
		
	Apollo.RegisterSlashCommand("itemfinder", "OnSlashCommand", self)
	Apollo.RegisterSlashCommand("if", "OnSlashCommand", self)

	Event_FireGenericEvent("OneVersion_ReportAddonInfo", self.name, unpack(self.version))
end

-----------------------------------------------------------------------------------------------
-- Functions

function ItemFinder.StatsString(item)
	local tStrStats = {}
	for stat,value in pairs(item.tStats) do
		table.insert(tStrStats, string.format("%.0f", value)..(tStats[stat] and tStats[stat].short or "?"))
	end
 	return table.concat(tStrStats," | ")
end

function ItemFinder:MatchFilters(item)
	for stat,included in pairs(self.tStatFilters) do
		if included == (item.tStats[stat] == nil) then return false end 
	end
	
	return (self.strItemName            == nil or item.strName:lower():find(self.strItemName:lower()) ~= nil)
	   and (next(self.tCategoryFilters) == nil or self.tCategoryFilters[item.eCategory])
	   and (next(self.tSlotFilters)     == nil or self.tSlotFilters[item.eSlot])
	   and (next(self.tQualityFilters)  == nil or self.tQualityFilters[item.eQuality])
	   and (next(self.tPriceFilters)    == nil or (item.tCost.arMonSell and self.tPriceFilters[item.tCost.arMonSell[1]:GetMoneyType()]))
	   and (self.nILvlMin               == nil or self.nILvlMin <= (item.nEffectiveLevel or 0))
	   and (self.nILvlMax               == nil or self.nILvlMax >= (item.nEffectiveLevel or 0))
end

function ItemFinder:GetItemData(id)
	local item = Item.GetDataFromId(id)
	if item then
		local tItemInfo = item:GetDetailedInfo().tPrimary
		
		tItemInfo.item = item
		tItemInfo.eSlot = item:GetSlot()
		tItemInfo.tStats = {}
		for i=1,#(tItemInfo.arInnateProperties or {}) do
			local stat = tItemInfo.arInnateProperties[i]
			tItemInfo.tStats[stat.eProperty] = stat.nValue
		end
		for i=1,#(tItemInfo.arBudgetBasedProperties or {}) do
			local stat = tItemInfo.arBudgetBasedProperties[i]
			tItemInfo.tStats[stat.eProperty] = stat.nValue
		end
		
		return tItemInfo 
	end
end

function ItemFinder:ItemScanner()
	if self.nScanIndex < self.nMaxItems then
		local nNextIndex = math.min(self.nScanIndex+self.nScanPerTick, self.nMaxItems)
		for i=self.nScanIndex,nNextIndex do
			local item = self:GetItemData(self.nMaxItems - i)
			if item then 
				self.nLastValidId = i
				if self:MatchFilters(item) then
					self.tItems[#self.tItems+1] = item
				end
			end
		end
		self.nScanIndex = nNextIndex + 1
		self.wndProgress:SetProgress(self.nScanIndex/self.nMaxItems)
	else
		self:Stop(false, "Items found: " .. #self.tItems)
		self:UpdateDisplay(true)
	end
end

function ItemFinder.ItemSort(item1, item2)
	local power1 = item1:GetData().nEffectiveLevel or 0
	local power2 = item2:GetData().nEffectiveLevel or 0
	return power1 > power2
end

function ItemFinder:UpdateDisplay(bEverything)
	local nNextIndex = bEverything and #self.tItems or math.min(self.nShowIndex+self.nShowPerTick, #self.tItems)
	if nNextIndex > self.nMaxDisplayedItems then
		self:Stop(true, "Trying to display too many items at once.")
	else
		for i=self.nShowIndex,nNextIndex do
			local item = self.tItems[i]
			local wndItem = Apollo.LoadForm(self.xmlDoc, "Item", self.wndItemList, self)
			wndItem:SetData(item)
			wndItem:FindChild("ItemIcon"):GetWindowSubclass():SetItem(item.item)
			local wndItemText = wndItem:FindChild("ItemText")
			wndItemText:SetText(item.strName .. "\n" .. item.item:GetItemTypeName()
	    		                .. " - iLvl : " .. (item.nEffectiveLevel or "")
	        		            .. "\n" .. self.StatsString(item)) 
			wndItemText:SetTextColor(tItemQualities[item.eQuality].color)
		end
		self.nShowIndex = nNextIndex + 1
		self.wndItemList:ArrangeChildrenVert(0, self.ItemSort)
	end
end

function ItemFinder:Stop(bError, strStatus)
	self.tmrItemScanner:Stop()
	self.tmrUpdateDisplay:Stop()
	self.wndProgress:SetBarColor(bError and "red" or "blue")
	if strStatus then self.wndProgress:SetText(strStatus) end
end

function ItemFinder:Start(nStart)
	self.nScanIndex = nStart or 1
	self.tmrItemScanner:Start()
	self.tmrUpdateDisplay:Start()
end

function ItemFinder:Reset()
	self:Stop()
	self.tItems = {}
	self.nScanIndex = 1 
	self.nShowIndex = 1
	self.wndProgress:SetProgress(0)
	self.wndProgress:SetBarColor("green")
	self.wndItemList:DestroyChildren()
	self.wndItemList:SetVScrollInfo(0,0,0)
end

-----------------------------------------------------------------------------------------------
-- UI Building

function ItemFinder:TiledButtons(strButtonName, wndFilters, tFilterData, tFilters, bExclude)
	for id, button in pairs(tFilterData) do
		local wndItem = Apollo.LoadForm(self.xmlDoc, strButtonName, wndFilters, self)
		local wndLabel = wndItem:FindChild("Label")
		wndItem:SetData(id)		
		wndLabel:SetText(button.label)
		if button.color then wndLabel:SetTextColor(button.color) end
		if button.icon  then 
			wndItem:FindChild("Icon"):SetSprite(button.icon) 
			wndLabel:SetAnchorOffsets(22,0,0,0)	        -- meh
			wndLabel:SetTextFlags("DT_CENTER", false)   -- kinda ugly
		end
		local strCallback = bExclude and "OnIncludeExcludeButton" or "OnIncludeButton"
		wndItem:AddEventHandler("ButtonCheck", strCallback)
		wndItem:AddEventHandler("ButtonUncheck", strCallback) 
	end
	wndFilters:SetData(tFilters)
	wndFilters:ArrangeChildrenTiles(0, function(a,b) 
		return a:GetData() < b:GetData()
	end)
end

function ItemFinder:DropDownList(strListName, ...)
	local wndList = self.wndMain:FindChild(strListName.."List")
	self:TiledButtons("DropDownItem", wndList, unpack(arg))
	self.wndMain:FindChild(strListName.."Btn"):AttachWindow(self.wndMain:FindChild(strListName.."DropDown"))
end

function ItemFinder:ButtonFilters(...) self:TiledButtons("FilterButton", unpack(arg)) end

-----------------------------------------------------------------------------------------------
-- UI Callbacks

-- Filters

function ItemFinder:OnItemNameChange(wndHandler, wndControl, strText)
	self.strItemName = strText
end

function ItemFinder:OnNumberEditBoxChange(wndHandler, wndControl, strText)
	local value = tonumber(strText)
	self[wndControl:GetName()] = value
	if not value then wndControl:SetText("") end
end

function ItemFinder:OnIncludeButton(wndHandler, wndControl, eMouseButton)
	wndControl:GetParent():GetData()[wndControl:GetData()] = wndControl:IsChecked() or nil
end

function ItemFinder:OnIncludeExcludeButton(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		wndControl:SetCheck(true)
		wndControl:SetBGColor(ApolloColor.new(2,0,0))
		wndControl:GetParent():GetData()[wndControl:GetData()] = false
	else
		wndControl:SetBGColor("UI_BtnBGDefault")
		wndControl:GetParent():GetData()[wndControl:GetData()] = wndControl:IsChecked() or nil
	end
end

-- Item

function ItemFinder:OnItemMouseEnter(wndHandler, wndControl, x, y)
	if wndHandler == wndControl then
		Tooltip.GetItemTooltipForm(self, wndControl, wndControl:GetData().item, {})
	end
end

function ItemFinder:OnItemClick(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Right then
		Event_FireGenericEvent("ItemLink", wndControl:GetData().item)
	end
end

-- Misc

function ItemFinder:OnRefresh()
	self:Reset()
	self.tmrItemScanner:Start()
	self.tmrUpdateDisplay:Start()
end

function ItemFinder:OnClose()
	self.wndMain:Close()
	self:Reset()
end

function ItemFinder:OnSlashCommand() self.wndMain:Invoke() end

Apollo.RegisterAddon(ItemFinder)
