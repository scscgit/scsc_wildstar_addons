-----------------------------------------------------------------------------------------------
-- Client Lua Script for KuronaBags
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "StorefrontLib"
require "GameLib"
require "Item"
require "Window"
require "Money"
require "AccountItemLib"
-----------------------------------------------------------------------------------------------
-- KuronaBags Module Definition
-----------------------------------------------------------------------------------------------
local KuronaBags = {} 
local Major, Minor, Patch, Suffix =4, 5, 6, 3
local Version = tonumber(Major.."."..Minor..Patch..Suffix)
local KuronaBags_CURRENT_VERSION = string.format("%d.%d.%d", Major, Minor, Patch)
local APIVersion = Apollo.GetAPIVersion()

local QualityFrames = {
	[0] = "",
	[1] = "BK3:UI_RarityBorder_Grey",
	[2] = "BK3:UI_RarityBorder_White",
	[3] = "BK3:UI_RarityBorder_Green",
	[4] = "BK3:UI_RarityBorder_Blue",
	[5] = "BK3:UI_RarityBorder_Purple",
	[6] = "BK3:UI_RarityBorder_Orange",
	[7] = "BK3:UI_RarityBorder_Pink",
}

local ItemQualityFrames = {
	[1] = "CRB_Tooltips:sprTooltip_Header_Silver",
	[2] = "CRB_Tooltips:sprTooltip_Header_White",
	[3] = "CRB_Tooltips:sprTooltip_Header_Green",
	[4] = "CRB_Tooltips:sprTooltip_Header_Blue",
	[5] = "CRB_Tooltips:sprTooltip_Header_Purple",
	[6] = "CRB_Tooltips:sprTooltip_Header_Orange",
	[7] = "CRB_Tooltips:sprTooltip_Header_Pink",
}

local AltQualityFrames = {
	[1] = "CRB_Tooltips:sprTooltip_SquareFrame_Silver",
	[2] = "CRB_Tooltips:sprTooltip_SquareFrame_White",
	[3] = "CRB_Tooltips:sprTooltip_SquareFrame_Green",
	[4] = "CRB_Tooltips:sprTooltip_SquareFrame_Blue",
	[5] = "CRB_Tooltips:sprTooltip_SquareFrame_Purple",
	[6] = "CRB_Tooltips:sprTooltip_SquareFrame_Orange",
	[7] = "CRB_Tooltips:sprTooltip_SquareFrame_Pink",
}

local QualityColors = {
	[0] = "00000000",
	[1] = "ccc0c0c0",
	[2] = "ccFFFFFF",
	[3] = "cc00ff00",
	[4] = "cc0000ff",
	[5] = "cc800080",
	[6] = "ccff8000",
	[7] = "ccFFC0CB",
}

	local QualityNames = {
	[1] = "All",
	[2] = "Common",
	[3] = "Uncommon",
	[4] = "Rare",
	[5] = "Epic",
	[6] = "Legendary",
	[7] = "Artifact",
	}
	
	local fnSortItemsByName = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local fnSortItemsByCategory = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local strLeftName = itemLeft:GetItemCategoryName()
	local strRightName = itemRight:GetItemCategoryName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local fnSortItemsByQuality = function(itemLeft, itemRight)
	if itemLeft == itemRight then
		return 0
	end
	if itemLeft and itemRight == nil then
		return -1
	end
	if itemLeft == nil and itemRight then
		return 1
	end

	local eLeftQuality = itemLeft:GetItemQuality()
	local eRightQuality = itemRight:GetItemQuality()
	if eLeftQuality > eRightQuality then
		return -1
	end
	if eLeftQuality < eRightQuality then
		return 1
	end

	local strLeftName = itemLeft:GetName()
	local strRightName = itemRight:GetName()
	if strLeftName < strRightName then
		return -1
	end
	if strLeftName > strRightName then
		return 1
	end

	return 0
end

local ktSortFunctions = {"default",fnSortItemsByName, fnSortItemsByCategory, fnSortItemsByQuality}

 -----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function KuronaBags:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function KuronaBags:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- KuronaBags OnLoad
-----------------------------------------------------------------------------------------------
function KuronaBags:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("KuronaBags.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("KBsprites.xml","KBsprites")
end

-----------------------------------------------------------------------------------------------
-- KuronaBags OnDocLoaded
-----------------------------------------------------------------------------------------------
function KuronaBags:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.BagForm = Apollo.LoadForm(self.xmlDoc, "MainBagForm", nil, self)
	    self.BankBagForm = Apollo.LoadForm(self.xmlDoc, "BankBagForm", nil, self)
	    self.LootNote = Apollo.LoadForm(self.xmlDoc, "LootNotificationForm",nil, self)
		if self.BagForm == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end		
		
	    self.BagForm:Show(false, true)
		self.BagForm:FindChild("BagWindow"):SetOpacity(0.05)
		self.CurrentBag = self.BagForm
		self.VendorOpen = false
		self.wndDeleteConfirm 	= Apollo.LoadForm(self.xmlDoc, "InventoryDeleteNotice", nil, self)
		self.wndSalvageConfirm 	= Apollo.LoadForm(self.xmlDoc, "InventorySalvageNotice", nil, self)
		self.wndSplit 			= Apollo.LoadForm(self.xmlDoc, "SplitStackContainer", nil, self)
		Apollo.RegisterEventHandler("HideBank", "OnHideBank", self)
		Apollo.RegisterEventHandler("ShowBank", "OnShowBank", self)

		self.SmallLootForm = Apollo.LoadForm(self.xmlDoc, "NotificationContainer", nil, self)
		self.SmallLootNote = self.SmallLootForm:FindChild("NotificationList")
		self.SmallLootForm:Show(true,true)
		self.LootOptions = self.BagForm:FindChild("LootOptionsWindow")
		self.SearchInput = self.BagForm:FindChild("SearchInput")
		self.OptionsWindow = self.BagForm:FindChild("OptionsWindow")
		self.SalvageButton = self.BagForm:FindChild("SalvageAllButton")
		self.AutoSortButton = self.BagForm:FindChild("AutoSortButton")
		self.ClosedBagRack = self.BagForm:FindChild("ClosedBagRack")
		self.DebugWindow = self.BagForm:FindChild("DebugWindow")
		self.PreventSalvageList = {}
		self.KuronaSalvageList = {}
		if self.ExtraBags == nil then
			self.ExtraBags = {}
		end
		
		self.MainCashWindow = self.BagForm:FindChild("MainCashWindow")
		self.OmniBitsCashWindow = self.BagForm:FindChild("OmniBitsCashWindow")
		self.ServiceTokenCashWindow = self.BagForm:FindChild("ServiceTokenCashWindow")
		self.ElderGemCashWindow = self.BagForm:FindChild("ElderGemCashWindow")
		self.GloryCashWindow = self.BagForm:FindChild("GloryCashWindow")
		self.RenownCashWindow = self.BagForm:FindChild("RenownCashWindow")
		self.PrestigeCashWindow = self.BagForm:FindChild("PrestigeCashWindow")
		self.CraftingCashWindow = self.BagForm:FindChild("CraftingCashWindow")
		
		self.ElderGemCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.ElderGems)
		
		self.OmniBitsCashWindow:SetMoneySystem(AccountItemLib.CodeEnumAccountCurrency.Omnibits)
		self.OmniBitsCashWindow:SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.Omnibits, bIncreasingOrder = true})
		self.ServiceTokenCashWindow:SetMoneySystem(AccountItemLib.CodeEnumAccountCurrency.ServiceToken)
		self.ServiceTokenCashWindow:SetData({eCurrency = AccountItemLib.CodeEnumAccountCurrency.ServiceToken, bIncreasingOrder = true})

		
		self.GloryCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.Glory)
		self.RenownCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
		self.PrestigeCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.Prestige)
		self.CraftingCashWindow:SetMoneySystem(Money.CodeEnumCurrencyType.CraftingVouchers)
		
		Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self)
		Apollo.RegisterEventHandler("ShowInventory", "InventoryToggle", self)
		Apollo.RegisterEventHandler("ToggleInventory", "InventoryToggle", self)
		Apollo.RegisterEventHandler("RefreshInventoryBags","RefreshInventoryBags",self)
		Apollo.RegisterEventHandler("UpdateInventory", "OnStartUpdateInventory", self)
		Apollo.RegisterEventHandler("InterfaceMenu_ToggleInventory", "InventoryToggle", self)
		Apollo.RegisterEventHandler("PlayerCurrencyChanged", "OnPlayerCurrencyChanged", self)
		Apollo.RegisterTimerHandler("DelayedSearch", "OnDelayedSearchTimer", self)
		Apollo.RegisterTimerHandler("DelayedInventoryUpdate", "OnUpdateInventory", self)
		Apollo.RegisterTimerHandler("RedrawTimer", "Redraw", self)
		Apollo.RegisterTimerHandler("DelayedUpdate", "OnSmallLootTimer", self)
		Apollo.RegisterTimerHandler("SmallLootTimer", "OnSmallLootTimer", self)
		Apollo.RegisterTimerHandler("StartUpTimer", "OnStartUp", self)
		Apollo.RegisterTimerHandler("LootNotificationGracePeriod", "OnLootNotificationGracePeriod", self)
		Apollo.RegisterTimerHandler("ItemCooldownTimer", "CheckItemCoolDowns", self)
		Apollo.RegisterEventHandler("GenericEvent_SplitItemStack", "OnGenericEvent_SplitItemStack", self)
--		Apollo.RegisterEventHandler("LootedMoney", 			"OnLootedMoney", self)
		Apollo.RegisterEventHandler("LootItemSentToTradeskillBag", "LST", self)
		Apollo.RegisterEventHandler("UI_EffectiveLevelChanged", "OnEffectiveLevelChange", self)
		Apollo.RegisterEventHandler("DragDropSysBegin", "OnSystemBeginDragDrop", self)
		Apollo.RegisterEventHandler("DragDropSysEnd", 	"OnSystemEndDragDrop", self)
		
		--F2P Bank
		self.timerNewBagPurchasedAlert = ApolloTimer.Create(12.0, false, "OnBankViewer_NewBagPurchasedAlert", self)
		self.timerNewBagPurchasedAlert:Stop()

		
		--Quest Items
		Apollo.RegisterEventHandler("PlayerPathMissionUpdate", 					"OnQuestObjectiveUpdated", self) -- route to same event
		Apollo.RegisterEventHandler("QuestObjectiveUpdated", 					"OnQuestObjectiveUpdated", self)
		Apollo.RegisterEventHandler("PlayerPathRefresh", 						"OnQuestObjectiveUpdated", self) -- route to same event
		Apollo.RegisterEventHandler("QuestStateChanged", 						"OnQuestObjectiveUpdated", self)
		Apollo.RegisterEventHandler("StoreLinksRefresh",						"RefreshStoreLink", self)



--		self.timerCash = ApolloTimer.Create(5.0, false, "OnLootStack_CashTimer", self)

		Apollo.RegisterSlashCommand("kb", "OnConsole", self)

		
		-- Do additional Addon initialization here
		self.NVB = self.BagForm:FindChild("NVBagWindow")
		self.OBW = self.BagForm:FindChild("BagWindow")
		self.OBS = self.BagForm:FindChild("OneBagSlot")
		self.OBW:SetCannotUseSprite("ClientSprites:LootCloseBox")
		self.NVB:SetCannotUseSprite("ClientSprites:LootCloseBox")
		self.RowSlider = self.BagForm:FindChild("RowSliderBar")
		self.LootSlider = self.BagForm:FindChild("LootThresholdSliderBar")
		self.ColumnSlider = self.BagForm:FindChild("ColumnSliderBar")
		self.IconSizeSlider = self.BagForm:FindChild("IconSizeSliderBar")
		self.TotalSlots = self.BagForm:FindChild("TotalSlots")
		self.SCancelButton = self.BagForm:FindChild("SettingsCancelButton")
		self.SApplyButton = self.BagForm:FindChild("SettingsApplyButton")
		self.SearchBox = self.BagForm:FindChild("SearchBox")
		self.InvButton = self.BagForm:FindChild("InvButton")
		self.OBWHightlight = self.BagForm:FindChild("OBWHightlight")
		self.TradeskillButton = self.BagForm:FindChild("TradeskillButton")
		self.BagLocator = self.BagForm:FindChild("BagLocator")

		if self.tSettings == nil then
			self.tSettings = self:DefaultTable()
		end
		
		self.tSettings.bAutoPrune = false

		self.BagForm:FindChild("ResetButton"):Show(self.tSettings.bEnableVB)
		
		self.SmallList = {}

		self.CooldownList = {}
		self.CurrentSlot = 1
		
		self.BagForm:SetAnchorOffsets(self.tSettings.nMainL,self.tSettings.nMainT,self.tSettings.nMainR,self.tSettings.nMainB)
		self.BankBagForm:SetAnchorOffsets(self.tSettings.nBankL,self.tSettings.nBankT,self.tSettings.nBankR,self.tSettings.nBankB)
--		self.LootNote:SetAnchorOffsets(self.tSettings.TopL,self.tSettings.TopT,self.tSettings.TopR,self.tSettings.TopB)
--		self.SmallLootForm:SetAnchorOffsets(self.tSettings.nSideL,self.tSettings.nSideT,self.tSettings.nSideR,self.tSettings.nSideB)
		
		self.canSalvage = false
		
		
--		self.LootQueue = {}
--		self.LootWaiting = 0
--		self.SideLootResized = false

		self.BagForm:FindChild("OptionsButton"):AttachWindow(self.BagForm:FindChild("OptionsWindow"))
		self.MainBagFilterButton = self.BagForm:FindChild("MainBagFilterButton")
		self.BagSortWindow = self.BagForm:FindChild("BagSortWindow")
		self.MainBagFilterButton:AttachWindow(self.BagSortWindow)	
		self.BagForm:FindChild("BagsButton"):AttachWindow(self.BagForm:FindChild("BagSlotWindow"))	
		self:SetOptions()
		self.FullStackTransfer = false
		
		
		
		if self.tSettings.nSortType ~= 1 then
			self.NVB:SetSort(true)
			self.NVB:SetItemSortComparer(ktSortFunctions[self.tSettings.nSortType])
		else
			self.NVB:SetSort(false)
		end
		
		if GameLib.GetPlayerUnit() ~= nil then
			self:OnCharacterCreated()
		end
		
		
		--Carbine Bag Fix
		self.BankViewer =  Apollo.GetAddon("BankViewer")
		Apollo.RemoveEventHandler("HideBank", self.BankViewer)
		Apollo.RemoveEventHandler("ShowBank", self.BankViewer)
		Apollo.RemoveEventHandler("ToggleBank", self.BankViewer)

		
		--One Version
		Event_FireGenericEvent("OneVersion_ReportAddonInfo", "KuronaBags", Major, Minor, Patch)  
		
	end

	
	if not self.tSettings.bEnableVB then
		local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
		local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize

		self.NVB:SetAnchorOffsets(0,0,width,height)
		self.NVB:SetSquareSize(self.tSettings.IconSize,self.tSettings.IconSize)
		self.BagForm:FindChild("BagHolder"):Show(false)
		self.NVB:SetBoxesPerRow(self.tSettings.Columns)
		self.BagForm:FindChild("NewBagButton"):Show(false)
		self.BagForm:FindChild("AutoSortButton"):Show(false)
		--self.BagForm:FindChild("SearchBox"):Show(false)
		self.BagForm:FindChild("NewBagButton"):Enable(false)
		self.BagForm:FindChild("AutoSortButton"):Enable(false)
		self.RowSlider:GetParent():GetParent():Show(false)
		self.MainBagFilterButton:Show(true)
		self.OBW:Show(false)
		self.OBS:Show(false)
		self:ResizeNVBag()
	end
	self.DragDrop = false
	--self:HookIntoImprovedSalvage()
	
end

-----------------------------------------------------------------------------------------------
-- KuronaBags Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here


-----------------------------------------------------------------------------------------------
-- KuronaBagsForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function KuronaBags:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function KuronaBags:OnCancel()
	self.wndMain:Close() -- hide the window
end

function KuronaBags:OnLoaded()
	if self.BagSlots == nil then
		self:PopulateBag()
	end
	if not self.tSettings.bEnableVB then
		local iconsize = self.tSettings.IconSize
		self.NVB:SetSquareSize(iconsize,iconsize)
	end
end

function KuronaBags:InventoryToggle()
	if self.BagForm:IsShown() then
		self:CloseInventory()
	else
		self:OpenInventory()
	end
end

function KuronaBags:CloseInventory()
	--self.BagForm:Show(false,false)
	--self.BagForm:Close()
	self:AllItemsSeen()
	self:OnBagHide()
	self.BagForm:Close()
	if self.tSettings.bEnableVB then
		self:OpenExtraBags(false)
	end
	self:OnSearchLostFocus()
	if self.QuestBag and self.QuestBag:IsShown() then
		self:MinimizeBag(self.QuestBag)	
	end
end

function KuronaBags:OpenInventory()

	if self.tSettings.bEnableVB then
	if self.needArrange then
		self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)
		self.needArrange = false
	end
	self:OnPlayerCurrencyChanged()
	if self.BagSlots == nil then
		self:PopulateBag()
	end

	self.BagForm:Show(true,false)
	self.BagForm:Invoke()	
	self:GetFirstFreeSpace()
	self:GetLastFreeSpace()
	
	--self:InventorySnapShot()
	self:OnUpdateInventory()
	self:DisplayFreeSlots()
	self:UpdateBagItemSlots()
	
	self:CheckSalvageState()
	--self:HookIntoImprovedSalvage()
	self:AutoSlotRepair()
	else
		self.OBW:Show(false)
		self.OBS:Show(false)
		self.NVB:Show(true)
		self.NVB:GetParent():Show(true)
		self.TotalSlots:Show(false)

		local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
		local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
	
		self.NVB:SetAnchorOffsets(0,0,width,height)
		self.NVB:SetSquareSize(self.tSettings.IconSize,self.tSettings.IconSize)
		self.BagForm:FindChild("BagHolder"):Show(false)
		self.NVB:SetBoxesPerRow(self.tSettings.Columns)
		self.BagForm:FindChild("NewBagButton"):Show(false)
		self.BagForm:FindChild("AutoSortButton"):Show(false)
		self.BagForm:FindChild("NewBagButton"):Enable(false)
		self.BagForm:FindChild("AutoSortButton"):Enable(false)
		self.MainBagFilterButton:Show(true)
--		self.ClosedBagRack:Show(false)
--		self:OpenExtraBags(false)
	self.BagForm:Invoke()	

	end
	
	self.BagForm:ToFront()
	self.BagForm:Show(true,false)
	if self.tSettings.bEnableVB then
		self:OpenExtraBags(true)
	end
	self:DisplayFreeSlots()
	self:UpdateBagItemSlots()

	--Quest Items
	self:UpdateQuestBag()
	self:OnWindowResized()

	
end

function KuronaBags:OnButtonMouseOver( wndHandler, wndControl, x, y )
	if wndControl:GetName() ~= "Icon" and wndControl:GetName() ~= "ItemNew" then
		wndControl:GetChildren()[1]:SetBGColor("FFFFFF00")
	end
	if wndControl:GetName() == "TradeskillButton" then
		self.TradeskillButton:FindChild("ItemNew"):Show(false,false)
	end
end

function KuronaBags:OnButtonMouseExit( wndHandler, wndControl, x, y )
	if wndControl:GetName() ~= "Icon" and wndControl:GetName() ~= "ItemNew" then
		wndControl:GetChildren()[1]:SetBGColor("FFFFFFFF")
	end
end


function KuronaBags:OnConsole(cmd,strArg)
	if strArg == "reset" then
		self:Restart()
		Print("Reset. Please /reloadui")
	elseif strArg == "test" then
		self:TestLootNote()
	elseif strArg == "sort" then
		self:AutoSort()
	elseif strArg == "compact" then
		self:StartCompact()	
	elseif strArg == "smash" then
		self:SmashStacks()	
	elseif strArg == "debug" then
		self.Debug = not self.Debug
		Print("Debug Mode: "..tostring(self.Debug))
	elseif strArg == "add" then
--		self.tSettings.bAutoPrune = true
--		self:CreateNewSlot()
	elseif strArg == "bank" then
	self:ListBankItems()
	else
		self.tSettings.bAutoPrune = false
	end
end


function KuronaBags:TestLootNote()
	self.LootNote:FindChild("LegendaryOverlay"):Show(false,true)
	self.LootNote:FindChild("EpicOverlay"):Show(false,true)

	self.SmallLootNote:DestroyChildren()
	self.SmallList = {}
	self.LootQueue = {}
	Apollo.StopTimer("LootNotificationGracePeriod")
	Apollo.StopTimer("SmallLootTimer")

	self:OnLootedMoney(GameLib.GetPlayerCurrency())
	self:OnLootedMoney(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Glory))
	local equipped = GameLib.GetPlayerUnit():GetEquippedItems() 
	for k,v in pairs(equipped) do
		if k < 15 then
			self:OnLootedItem(v,1)
		end
	end
end

function KuronaBags:OnCharacterCreated()
	self:InventorySnapShot()
	Apollo.CreateTimer("StartUpTimer", 0.5, false)
end

function KuronaBags:OnStartUp()
	self.Started = true
	self:OnPlayerCurrencyChanged()
	self:GetFirstFreeSpace()
	self:GetLastFreeSpace()
	if self.BagSlots == nil then
		self:PopulateBag()
	end
	self:InventorySnapShot()
	
	if self.tSettings.bEnableVB then
		self:ResizeVBag()
		--self:WipeTooltips()
		--self:OnBagItemMouseEnter( self.BagSlots[self.CurrentSlot]:GetChildren()[1], self.BagSlots[self.CurrentSlot], 0, 0 )
	else
		self:ResizeNVBag()
	end
	
	self:Redraw()
	
	Apollo.RegisterEventHandler("ItemAdded", "OnItemAdded", self)
	Apollo.RegisterEventHandler("ItemRemoved", "OnItemRemoved", self)
	Apollo.RegisterEventHandler("ItemModified", "OnItemModified", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", "OnEquipmentChanged", self)
	--Apollo.RegisterEventHandler("LootedItem", "OnLootedItem", self)
	Apollo.RegisterEventHandler("InvokeVendorWindow", "OnShowVendor", self)
	Apollo.RegisterEventHandler("CloseVendorWindow", "OnCloseVendor", self)
	self.CX = Apollo.GetAddon("MarketplaceCommodity")
	self.AH = Apollo.GetAddon("MarketplaceAuction")
	self.TradeSkill = Apollo.GetAddon("TradeskillContainer")
	self.KuronaSalvage = Apollo.GetAddon("KuronaSalvage")
	
	Apollo.StopTimer("ItemCooldownTimer", self)
	Apollo.CreateTimer("ItemCooldownTimer", 1, true)
	
	self.OptionsWindow:FindChild("OptionsTitle"):SetText("  KuronaBags V"..Version.." by Kurona Silversky")

	
end

function KuronaBags:UpdateBagItemSlots()
	local strEmptyBag = Apollo.GetString("Inventory_EmptySlot")
	for idx = 1, 4 do
		local wndCtrl = self.BagForm:FindChild("BagBtn"..idx)
		local itemBag = wndCtrl:GetItem()
		if itemBag then
			wndCtrl:GetChildren()[1]:SetText("+" .. itemBag:GetBagSlots())
			Tooltip.GetItemTooltipForm(self, self.BagForm:FindChild("BagBtn"..idx), itemBag, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
		else
			wndCtrl:GetChildren()[1]:SetText("")
			wndCtrl:SetTooltip(string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"white\">%s</T>", strEmptyBag))
		end
	end

end

function KuronaBags:OnBagHide( wndHandler, wndControl )

	self.BagForm:FindChild("OptionsButton"):SetCheck(false)
	self.BagForm:FindChild("BagsButton"):SetCheck(false)
end



---------------------------------------------------------------------------------------------------
-- BagForm Functions
---------------------------------------------------------------------------------------------------

function KuronaBags:OnSearchChange( wndHandler, wndControl, strNewText, strOldText, bAllowed )
	strNewText = strNewText:lower()
	--if self.tSettings.bEnableVB then
		self:StartSearch(strNewText)
	--end
end

function KuronaBags:OnSearchFocus( wndHandler, wndControl )
	wndHandler:SetText("")
end

function KuronaBags:OnSearchLostFocus( wndHandler, wndControl )
	--self.OBS:Show(true,true)
	if self.tSettings.bEnableVB then
	self.SearchBox:FindChild("SearchInput"):SetText("Search")
	self.SearchInProgress = false
		for i = 1, self.MaxBagSlots do
			if not self.BagSlots[self.RealRemap[i]]:IsShown() then
				self.BagSlots[self.RealRemap[i]]:Show(true,false)
			end
		end
	elseif not self.BagForm:IsShown() then
	self.SearchBox:FindChild("SearchInput"):SetText("Search")
	self.SearchInProgress = false
		if self.tSettings.nSortType ~= 1 then
			self.NVB:SetSort(true)
			self.NVB:SetItemSortComparer(ktSortFunctions[self.tSettings.nSortType])
		else
			self.NVB:SetSort(false)
		end
	end
end

	
---------------------------------------------------------------------------------------------------
-- MainBagForm Functions
---------------------------------------------------------------------------------------------------

function KuronaBags:OnSalvageAllButton( wndHandler, wndControl, eMouseButton )
	if self.tSettings.bEnableVB then
		self:OnPreventSalvage()
	else
		--self:HookIntoImprovedSalvage()
	end
	local KSalvage = Apollo.GetAddon("KuronaSalvage")
	if self.KuronaSalvage then
		self.KuronaSalvage:OnSalvageAll()
	else
		Event_FireGenericEvent("RequestSalvageAll", tAnchors)
	end
end

function KuronaBags:OnToggleSupplySatchel( wndHandler, wndControl, eMouseButton )
	local tAnchors = {}
	tAnchors.nLeft, tAnchors.nTop, tAnchors.nRight, tAnchors.nBottom = self.BagForm:GetAnchorOffsets()
	Event_FireGenericEvent("ToggleTradeskillInventoryFromBag", tAnchors)
end

function KuronaBags:OnDragDropSalvage(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" and self.BagForm:FindChild("SalvageIcon"):GetData() then
		self:InvokeSalvageConfirmWindow(iData)
	end
	return false
end

function KuronaBags:OnQueryDragDropSalvage(wndHandler, wndControl, nX, nY, wndSource, strType, iData)
	if strType == "DDBagItem" and self.BagForm:FindChild("SalvageIcon"):GetData() then
		return Apollo.DragDropQueryResult.Accept
	end
	return Apollo.DragDropQueryResult.Ignore
end

--[[
function KuronaBags:OnDragDropNotifySalvage(wndHandler, wndControl, bMe) -- TODO: We can probably replace this with a button mouse over state
	if bMe and self.BagForm:FindChild("SalvageIcon"):GetData() then
		--self.wndMain:FindChild("SalvageIcon"):SetSprite("CRB_Inventory:InvBtn_SalvageToggleFlyby")
		--self.wndMain:FindChild("TextActionPrompt_Salvage"):Show(true)
	elseif self.BagForm:FindChild("SalvageIcon"):GetData() then
		--self.wndMain:FindChild("SalvageIcon"):SetSprite("CRB_Inventory:InvBtn_SalvageTogglePressed")
		--self.wndMain:FindChild("TextActionPrompt_Salvage"):Show(false)
	end
end
]]



function KuronaBags:CancelApplySizeSettings( wndHandler, wndControl, eMouseButton )
	self:SetOptions()
end
		            
function KuronaBags:OnNVDragDropCancel( wndHandler, wndControl, strType, iData, eReason, bDragDropHasBeenReset )
	self:OnBagItemDragDropCancel(wndHandler, wndControl, strType, iData, eReason)
end

function KuronaBags:OnOneSlotDragDropCancel( wndHandler, wndControl, strType, iData, eReason, bDragDropHasBeenReset )
	self.ScrollAmount = nil
	self.StackSplitSource = nil
	self.FullStackTransfer = false
	self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
end

function KuronaBags:OneSlotDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
end

function KuronaBags:OnShowLootSettings( wndHandler, wndControl, eMouseButton )
	local loot = Apollo.GetAddon("KuronaLoot")
	if loot then
		loot:OnShowLootSettings()
		self:CloseInventory()
	end
end

function KuronaBags:OnButtonClose( wndHandler, wndControl, eMouseButton )
--	self:OnExitShowLootSettings()
	self.EditLoot = false
end


---------------------------------------------------------------------------------------------------
-- NotificationContainer Functions
---------------------------------------------------------------------------------------------------

function KuronaBags:OnSideLootSized( wndHandler, wndControl )
	if self.EditLoot then
		self.SideLootResized = true
	end
end

---------------------------------------------------------------------------------------------------
-- SmallLootItem Functions
---------------------------------------------------------------------------------------------------
function KuronaBags:OnDelayedSearchTimer()
	self.SearchInput:SetFocus()
	self.SearchInput:SetText(self.SearchName)
	self:StartSearch(self.SearchName:lower())
	self.SearchInput:SetSel(0,0)
	self.SearchName = nil
end

function KuronaBags:SearchForLootItem( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndControl:GetName() == "LootNotificationForm" or wndControl:GetName() == "SmallLootItem" then	
		if self.bEnableVB and not self.EditLoot and  Apollo.IsShiftKeyDown() then
			self.BagForm:Invoke()
			local strName = wndControl:GetData():GetName()
			self.SearchName = strName
			Apollo.CreateTimer("DelayedSearch", 0.25, false)
		end
	end
end


---------------------------------------------------------------------------------------------------
-- ExtraBagForm Functions
---------------------------------------------------------------------------------------------------

function KuronaBags:OnPreventSalvageButton( wndHandler, wndControl, eMouseButton )
	self:OnPreventSalvage( wndHandler, wndControl, eMouseButton )
	self:Redraw()
end

function KuronaBags:OnPinButton( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= nil then
		local bag = wndHandler:GetParent():GetParent()
		local num = self:FindExtraBag(bag)
		self.ExtraBags[num].pinned = wndHandler:IsChecked()
	end
end


function KuronaBags:OnPreventSalvage( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= nil then
		local bag = wndHandler:GetParent():GetParent()
		local num = self:FindExtraBag(bag)
		self.ExtraBags[num].psalvage = wndHandler:IsChecked()
	end
	self.PreventSalvageList = {}
	
	if self.ExtraBags == nil or not self.tSettings.bEnableVB then return end
	
	for i = 1, #self.ExtraBags do
		if self.ExtraBags[i].psalvage then
			local clist = self.ExtraBags[i].Bag:FindChild("BagHolder"):GetChildren()
			for x=1,#clist do
				local item = clist[x]:GetChildren()[1]:GetData()
				if item and (item:CanSalvage() or  item:CanAutoSalvage()) then
					self.PreventSalvageList[item:GetItemId()] = true
				end
			end
		end
	end
	--[[
	if self.KuronaSalvage == nil then
		self.KuronaSalvage = Apollo.GetAddon("KuronaSalvage")
	end
	if self.KuronaSalvage and self.KuronaSalvage.arItemList then	
	local preventSalvage = self.PreventSalvageList
	for i = #self.KuronaSalvage.arItemList, 1, -1 do
		local item = self.KuronaSalvage.arItemList[i]
		if item and preventSalvage[item:GetItemId()] then
			table.remove(self.KuronaSalvage.arItemList, i)
		end
	end
	self.KuronaSalvage:RedrawAll()
	end
	
	--HideSalvage
	--self:HookIntoImprovedSalvage()
	]]
end


function KuronaBags:ImprintAll( wndHandler, wndControl, eMouseButton )
	if wndHandler == nil then return end
	
	local sbox = wndHandler:GetParent():FindChild("ItemSortEditBox")
	local phrase = sbox:GetText()
	local startphrase =	string.gsub(sbox:GetText(),"-", " ")	
	
	local bag= wndHandler:GetParent():GetParent()
	local clist = bag:FindChild("BagHolder"):GetChildren()
	
	for x=1,#clist do
		if clist[x]:GetChildren()[1]:GetData() ~= nil then
			local itemname = string.gsub(clist[x]:GetChildren()[1]:GetData():GetName(),"-", " ")

			if startphrase == "" then startphrase = itemname  phrase = itemname end
			local x = string.match(startphrase,itemname)
			if x == nil then
				phrase = phrase .."; " .. itemname
			end
		end
	end
		self.ExtraBags[self:FindExtraBag(bag)].sortphase = phrase
		sbox:SetText(phrase)
		sbox:SetSel(999999,999999)
		self:AutoSort()
end

function KuronaBags:ClearFilter( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= nil then
		local box = wndHandler:GetParent():FindChild("ItemSortEditBox")
		box:SetText("")
		self:OnSortPhaseChanged( box, "", "", true )
	end

end

-----------------------------------------------------------------------------------------------
-- KuronaBags Instance
-----------------------------------------------------------------------------------------------
local KuronaBagsInst = KuronaBags:new()
KuronaBagsInst:Init()

function KuronaBags:OnMouseOverRealBag( wndHandler, wndControl, x, y )
	if self.HoverSlot then
		self.HoverSlot:Show(true, true)		
	end
	self.OverRealBag = true
end


function KuronaBags:OnBagItemMouseEnter( wndHandler, wndControl, x, y )
	if self.CurrentBag == nil then return end
	if wndHandler == nil then return end
	
    local bh = self.CurrentBag:FindChild("BagHolder")
	if bh == nil then return end
	wndHandler:SetTooltipDoc(nil)
	wndHandler:SetStyle("IgnoreMouse",false)
	bh:SetStyle("IgnoreMouse",false)
	local slotName = tonumber(wndHandler:GetParent():GetName())
	
	self.CurrentSlot = tonumber(wndHandler:GetParent():GetName())
	wndHandler:GetParent():FindChild("ItemNew"):Show(false,false)
	self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
	wndHandler:SetStyle("IgnoreMouse",false)
	
	--hide old hoverslot
	if self.HoverSlot ~= nil then	
		self.HoverSlot:Show(false,false)
	end
	
	self.HoverSlot = nil
	self.HoverSlot = wndHandler:GetParent():FindChild("ItemHighlight")
	self.HoverSlot:Show(true, true)
		
	local l,t,r,b = wndHandler:GetParent():GetAnchorOffsets()
	if self.CurrentBag ~= self.BagForm then t = t - 15   b = b - 15 end
	self.OBS:SetAnchorOffsets(l+15,t+45,r+15,b+45)
	--if self.DragDrop then Print("dd") return end
	local cap =  self.OBW:GetBagCapacity()
	local iconsize = self.tSettings.IconSize
	self.OBW:SetSquareSize(iconsize,iconsize)
	self.OBW:SetBoxesPerRow(cap)
	local slot = tonumber(wndHandler:GetName())

	self.MaxBagSlots =  cap
	if slot > self.MaxBagSlots or self.ScrollAmount then
		slot = self:GetLastFreeSpace()
	end
	local offset = (slot * -iconsize) + iconsize
	
	self.OBW:SetAnchorOffsets((offset),0,offset + (cap*iconsize),iconsize)
end


--For some reason this gets called on a loop when right clicking
function KuronaBags:OnBagItemMouseExit( wndHandler, wndControl, x, y )
	if self.ScrollAmount == nil and not self.OverRealBag then
		wndHandler:GetParent():FindChild("ItemNew"):Show(false,false)
		--wndHandler:GetParent():FindChild("ItemHighlight"):Show(false,true)
	end
end

function KuronaBags:OnMouseOutOfBag( wndHandler, wndControl, x, y )
	if self.HoverSlot then
		self.HoverSlot:Show(false, true)		
	end

end

function KuronaBags:OnMouseInBag( wndHandler, wndControl, x, y )
	if self.tSettings.bEnableVB then
	
	if 	self.CurrentBag ~= wndHandler:GetParent() then	
		self.OBS:Show(false,true)
		self.OBW:Show(false,true)
	end
	
	self.CurrentBag = wndHandler:GetParent()
	self.OBW:SetOpacity(0.05)
	self.OBS = self.CurrentBag:FindChild("OneBagSlot")
	self.OBW = self.CurrentBag:FindChild("BagWindow")
	self.OBS:Show(true,true)
	self.OBW:Show(true,true)
	end	
end




function KuronaBags:OnMouseWheel( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY, fScrollAmount, bConsumeMouseWheel )
	--self.OBS:Show(false,true)
if self.Debug then Print(wndHandler:GetParent():GetName() .. " / ".. wndHandler:GetName()) end
	---if not enable then return end
	
	if 	self.EmptyBagSlots == 0 then self:OnOneSlotDragDropCancel() return end
	if not Apollo.IsShiftKeyDown() then  self:OnOneSlotDragDropCancel() return end
	if 	wndHandler:GetData() == nil then self:OnOneSlotDragDropCancel() return end
	
	local stackCount = wndControl:GetData():GetStackCount()
	
	if self.ScrollAmount == nil then
		self.ScrollAmount = 0
	end

--	local count = stackCount + self.ScrollAmount + self.ScrollAmount
	self.ScrollAmount = self.ScrollAmount + fScrollAmount
	
	local newCount = stackCount + self.ScrollAmount	

	self.FullStackTransfer = false
	if newCount > stackCount then
		newCount = stackCount
		self.ScrollAmount=0
	elseif newCount < 0 then 
		newCount = 0
	elseif newCount == 0 then 
		self.FullStackTransfer = true
	end
	
	if newCount < stackCount then
		self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",true)
		wndHandler:SetStyle("IgnoreMouse",true)
	else
		self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
		wndHandler:SetStyle("IgnoreMouse",false)
	end	
	
	
	self.StackSplitSource = wndHandler
	self.JustSplitStack = true
	self:SetStackCount(wndControl, newCount,wndHandler:GetName(),true)
	
	if newCount == stackCount then
		self:OnOneSlotDragDropCancel()
	end
end

function KuronaBags:OnBagItemMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
--self:OnBagItemMouseEnter( wndHandler, wndHandler, 0, 0 )
end



--mousedown
function KuronaBags:OnBagItemMouseButtonDown(wndHandler, wndControl, eMouseButton, bDoubleClick)
	--self:OnBagItemMouseEnter( wndHandler, wndHandler, 0, 0 )
	wndHandler:GetParent():FindChild("ItemNew"):Show(false,false)
	
	--self:OnBagItemMouseEnter( wndHandler, wndControl)	
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and wndHandler:GetData() == nil and self.ScrollAmount ~= nil then
		self.ScrollAmount = nil
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right and wndHandler:GetData() then
		-- Selling item to vendor
		if self.VendorOpen and not self.DragDrop then
			wndHandler:SetTooltipDoc(nil)
			SellItemToVendor(tonumber(wndHandler:GetName()) - 1, wndHandler:GetData():GetStackCount())
			Print("Selling "..wndHandler:GetData():GetName().." x"..wndHandler:GetData():GetStackCount())
		elseif self.VendorOpen and not self.DragDrop then
			self.OBS:Show(true,true)
			self.CurrentBag:FindChild("BagHolder"):SetStyle("IgnoreMouse",true)
			wndHandler:SetStyle("IgnoreMouse",true)
			wndHandler:SetTooltipDoc(nil)			
		else
			--Make the item icon become unclickable so it clicks the real bag item hidden below it
			wndHandler:SetStyle("IgnoreMouse",true)
			self.OBW:Show(true,true)  -- Just in case
			self.OBS:Show(true,true)
			self.CurrentBag:FindChild("BagHolder"):SetStyle("IgnoreMouse",true)
			--wndHandler:SetTooltipDoc(nil)
			self.LastClick = wndHandler
		end
	elseif (eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsShiftKeyDown()  and wndHandler:GetData() ~= nil) or (eMouseButton == GameLib.CodeEnumInputMouse.Middle and wndHandler:GetData()) then
		self:ExternalSearch(wndHandler)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self:OnBagItemBeginDragDrop(wndHandler, wndControl)
	end
end

function KuronaBags:OnBagItemMouseButtonUp( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if self.LastClick then
		self.LastClick:SetStyle("IgnoreMouse",true)
	end
	wndControl:Show(true,true)
	self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
	self.BagForm:FindChild("BagWindow"):Show(false,true)
	wndHandler:SetStyle("IgnoreMouse",false)	
	if not self.DragDrop then
		self:OnBagItemDragDropCancel()
	end
	if self.HoverSlot then
		self.HoverSlot:Show(true, true)
	end
	--self:OnBagItemMouseEnter( wndHandler, wndHandler, 0, 0 )
end

function KuronaBags:OnBagItemBeginDragDrop(wndHandler, wndControl, nTransferStackCount) -- BagItemIcon
	if wndHandler ~= wndControl then
		return false
	end
	local itemSelected = wndHandler:GetData()
	local slot = tonumber(wndHandler:GetName())

	if itemSelected then
		self.DragDrop = true
	
		if itemSelected:CanSalvage() then
			self.BagForm:FindChild("SalvageIcon"):SetData(true)
		
			self.BagForm:FindChild("SalvageAllButton"):Enable(true)
		else
			self.BagForm:FindChild("SalvageAllButton"):Enable(false)
		end
	
		self.strTransferType = "DDBagItem"
		if self.strTransferType ~= nil then
			Apollo.BeginDragDrop(wndControl, self.strTransferType, itemSelected:GetIcon(), itemSelected:GetInventoryId(),"abc123")
		end
	end
	
	self.tCurrentDragData = itemSelected

end

function KuronaBags:OnBagItemQueryDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType)
	self.DragTarget = wndHandler
	local nName = tonumber(wndSource:GetName())
	if nName == nil then
		self.CurrentBag:FindChild("BagHolder"):SetStyle("IgnoreMouse",true)
		wndHandler:SetStyle("IgnoreMouse",true)
	end
	--is the item coming from tradeskill bag?
	if wndSource:GetParent():GetName() == "ItemList" then
		self.SatchelDrag = true
		self.DropLocation = self.CurrentSlot
	end
if wndSource == wndHandler then return Apollo.DragDropQueryResult.Ignore end
	if wndHandler ~= wndControl then
		return Apollo.DragDropQueryResult.PassOn
	elseif strType == "DDItemSplitStack" then -- Should change to an enum?
		return Apollo.DragDropQueryResult.Accept
	elseif strType == "DDBagItem"  or strType == "KBagItem" then -- Should change to an enum?
		return Apollo.DragDropQueryResult.Accept
	else
		return Apollo.DragDropQueryResult.Ignore
	end
end

function KuronaBags:OnBagItemDragDropClear() -- Any UI
	self:OnBagItemDragDropCancel()
end

function KuronaBags:OnBagItemDragDropEnd() -- Any UI
	self:OnBagItemMouseEnter( self.DragTarget, self.DragTarget, 0, 0 )
	self:OnBagItemDragDropCancel()
end

function KuronaBags:OnBagItemDragDropCancel(wndHandler, wndControl, strType, iData, eReason)
 -- Also called from UI
	if eReason == Apollo.DragDropCancelReason.ClickedOnWorld or eReason == Apollo.DragDropCancelReason.DroppedOnNothing then
		self:InvokeDeleteConfirmWindow(iData)
	end

	self.tCurrentDragData = nil
	self.BagForm:FindChild("BagWindow"):Show(true,true)
	self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
	
	if self.StackSplitSource and self.StackSplitSource:GetData() then
		self:SetStackCount(self.StackSplitSource, self.StackSplitSource:GetData():GetStackCount(),self.StackSplitSource:GetName())
	end
	self.StackSplitSource = nil
--	self.SatchelDrag = false
	
	
	self.ScrollAmount = nil
	self.DragDrop = false
	self:Redraw()
	
end
function KuronaBags:OnNVEndDragDrop( wndHandler, wndControl, strType, iData, bDragDropHasBeenReset )
end

function KuronaBags:OnNVDragDrop( wndHandler, wndControl, strType, iData, bDragDropHasBeenReset )
end

function KuronaBags:NVStartDragDrop( wndHandler, wndControl, x, y, wndSource, strType, iData, bDragDropHasBeenReset )
end

function KuronaBags:OnSystemBeginDragDrop(wndSource, strType, iData)
	if strType ~= "DDBagItem" then return end
	local item = self.NVB:GetItem(iData)
	if item and item:CanSalvage() then
		self.BagForm:FindChild("SalvageIcon"):SetData(true)
	end
	Sound.Play(Sound.PlayUI45LiftVirtual)
end

function KuronaBags:OnSystemEndDragDrop(strType, iData)
--	if not self.wndMain or not self.wndMain:IsValid() or not self.btnSalvage or strType == "DDGuildBankItem" or strType == "DDWarPartyBankItem" or strType == "DDGuildBankItemSplitStack" then
--		return -- TODO Investigate if there are other types///
--	end
	self.BagForm:FindChild("SalvageIcon"):SetData(false)

	self.SalvageButton:Enable(self.canSalvage)

	Sound.Play(Sound.PlayUI46PlaceVirtual)
end



function KuronaBags:OnOneSlotEndDragDrop( wndHandler, wndControl, strType, iData, bDragDropHasBeenReset )
--if self.tSettings.bEnableVB then
	self.ScrollAmount = nil
	-- we have just done a stack split.

	if 	self.EmptyBagSlots == 0 then return end
	if self.BagSlots == nil then Print("An error has occured in KuronaBags.") return end
	if self.BagSlots[self.CurrentSlot] == nil then Print("An error has occured in KuronaBags.") return end
	self:OnBagItemMouseEnter( self.BagSlots[self.CurrentSlot]:GetChildren()[1], self.BagSlots[self.CurrentSlot], 0, 0 )
--	self.DoStackSwap = true
	self.JustSplitStack = true
	self.DropLocation = self.CurrentSlot
	self.BagForm:FindChild("BagWindow"):Show(true,true)
	self.BagForm:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)

	--[[
	if self.FullStackTransfer then
		self.JustSplitStack = false
		self:OnUpdateInventory()
		self.FullStackTransfer = false
		self:OnUpdateInventory()
	end
	]]

end

function KuronaBags:OnBagItemEndDragDrop(wndHandler, wndControl, nX, nY, wndSource, strType, nBagSlot) -- Bank Icon
	local nName = tonumber(wndSource:GetName())
	
	if strType == "DDBagItem" and nBagSlot and nName and wndSource ~= wndHandler then
		self:SwapItems(wndSource,wndHandler,false,true)
		
		wndHandler:GetParent():FindChild("ItemHighlight"):Show(true,not self.tSettings.ItemTrail)		
	end
	self:OnBagItemDragDropCancel()
	return false
end


function KuronaBags:PopulateBag()
	if not self.tSettings.bEnableVB then
		self:PopulateBankBag()
		return
	end
	self.BagSlots = {}
	self.BagSlotCounts = {}
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()

	
	if self.tSettings.MaxVirtualSlots < self.MaxBagSlots then
		self:CorrectMaxSlots()
		self:OnSliderChanged()
--		self:ResizeVBag()
	end
	
	if self.RealRemap == nil or self.RealRemap[1] == nil then
		self.RealRemap = {}
		for i = 1, self.tSettings.MaxVirtualSlots do
			if i <= self.MaxBagSlots then
				self.RealRemap[i] = i
			end			
	
			self.BagSlots[i] = Apollo.LoadForm(self.xmlDoc, "BagItem", self.BagForm:FindChild("BagHolder"), self)
			self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
			self.BagSlots[i]:SetName(i)
			self.BagSlotCounts[i] = 0 
			self.BagSlots[i]:GetChildren()[1]:SetName(9999)
			if self.Debug then self.BagSlots[i]:GetChildren()[1]:SetText(9999) end
		end
	else
		for i = 1, self.tSettings.MaxVirtualSlots do
			self.BagSlots[i] = Apollo.LoadForm(self.xmlDoc, "BagItem", self.BagForm:FindChild("BagHolder"), self)
			self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
			self.BagSlots[i]:SetName(i)
			self.BagSlotCounts[i] = 0 
			self.BagSlots[i]:GetChildren()[1]:SetName(9999)
			if self.Debug then self.BagSlots[i]:GetChildren()[1]:SetText(9999) end
		end
	end
	if self.ExtraBags ~= nil then
		for k,v in pairs(self.ExtraBags) do
			if v.Bag then
				v.Bag:Destroy()
			end
		end
		for k,v in pairs(self.ExtraBags) do
			self:SetupNewBag(k,false)
		end
	end	
		
	self.canSalvage = false	
	for i = 1, self.MaxBagSlots do
		local item = GameLib.GetBagItem(i)
		if self.RealRemap[i] == nil then
			Print("An inventory error has occured within KuronaBags while populating. Remap Slot:".. i.. "/"..self.MaxBagSlots.." invalid")
			self:Restart()
--			self:AutoSort()
			return
		end			
		local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
		
		if slot and item then
			self:MakeItem(item,slot,i)
			slot:SetName(i)
			self.BagSlotCounts[i] = item:GetStackCount()
		end
		if slot then
			self.BagSlots[self.RealRemap[i]]:GetChildren()[1]:SetName(i)
		end
		if self.Debug then		self.BagSlots[self.RealRemap[i]]:GetChildren()[1]:SetText(i) end
	end
	self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)
	self:PopulateBankBag()
	self:ShowHideCurrency()	
end

function KuronaBags:CheckSalvageState()
	self.canSalvage = false
	if self.KuronaSalvage == nil then
		self.KuronaSalvage = Apollo.GetAddon("KuronaSalvage")
	end
	if self.KuronaSalvage then
		self.KuronaSalvageList = self.KuronaSalvage.IgnoreList
	end
	for i = 1, self.MaxBagSlots do
		local item = GameLib.GetBagItem(i)
		if item ~= nil then self:CanSalvageItems(item) end
	end
end

function KuronaBags:MakeItem(item, slot,nBagSlot)
	if item == nil then return end
	if slot == nil then Print("nil slot") end
	
	self:SetIcon(slot,item:GetIcon())
	slot:SetData(item)
	self:SetStackCount(slot, item:GetStackCount(),nBagSlot)
	self:SetQualityFrame(slot,item:GetItemQuality())

	local canUse = self:CantUseItem(item)
	local quest = item:GetGivenQuest()
	if self.Debug then	slot:SetText(nBagSlot) end
	self:SetCantUseIcon(slot,canUse,quest)
	self:ClearCooldownPixie(slot,nBagSlot)
	--slot:SetOpacity(0.10)
end

function KuronaBags:RemoveItem(item, slot,nBagSlot)
	self:SetIcon(slot,"")
	slot:SetData(nil)
	self:SetStackCount(slot, 0,nBagSlot)
	self:SetQualityFrame(slot,0)
	slot:GetParent():GetChildren()[3]:Show(false,true)
	if self.Debug then slot:SetText(nBagSlot) end
	self:SetCantUseIcon(slot,false)
	slot:SetTooltip("")
	slot:SetTooltipDoc(nil)
	self:ClearCooldownPixie(slot,nBagSlot)
end

function KuronaBags:ClearCooldownPixie(slot,nBagSlot)
		slot:UpdatePixie(5,{
		strText = "",
		strFont = "",
		bLine = false,
		strSprite = "",
		cr = "00000000",
		loc = {
		fPoints = {0,0,1,1},
		nOffsets = {1,1,-1,-1}
		},
		flagsText = {
		}
		})
		self.CooldownList[nBagSlot] = nil
end



function KuronaBags:CantUseItem(item)

	if item:IsEquippable() and not item:CanEquip() then	return true	end
	
    local tItemDI = item:GetDetailedInfo().tPrimary
	
	if (tItemDI.arClassRequirement and  not tItemDI.arClassRequirement.bRequirementMet) 
	or (tItemDI.tLevelRequirement and not tItemDI.tLevelRequirement.bRequirementMet)
	or (tItemDI.arTradeskillReqs and not tItemDI.arTradeskillReqs[1].bCanLearn)
	or (tItemDI.arTradeskillReqs and tItemDI.arTradeskillReqs[1].bIsKnown)
	or (tItemDI.arSpells and tItemDI.arSpells[1].strFailure)
	then
		return true
	end
	
	return false
end


function KuronaBags:SwapItems(slotA,slotB,bInstant,drag)
	local itemA = slotB:GetData()
	local itemB = slotA:GetData()
	if itemB == nil then return end
	local nameA = tonumber(slotB:GetName())
	local nameB = tonumber(slotA:GetName())

	local parentA = tonumber(slotA:GetParent():GetName())
	local parentB = tonumber(slotB:GetParent():GetName())

	if not bInstant then
		slotB:GetParent():Show(false,true)
		slotB:GetParent():Show(true,false)
	else
		slotB:GetParent():Show(true,true)
	end

	if itemA and itemB then
		if itemA:GetName() == itemB:GetName() then
			GameLib.SwapBagItems(nameB, nameA)
			return
		end
	end

	slotB:SetName(nameB)
	self.RealRemap[nameB]=parentB
	self:MakeItem(itemB,slotB,nameB)
	
	if itemA ~= nil then
		slotA:GetParent():Show(false,true)
		self:MakeItem(itemA,slotA,nameA)
		slotA:GetParent():Show(true,false)
		slotA:SetName(nameA)
		self.RealRemap[nameA]=parentA
	else
	
			self:RemoveItem(nil,slotA,9999)

	
		if drag then
			if (parentB <= self.tSettings.MaxVirtualSlots) and (parentA <= self.tSettings.MaxVirtualSlots) then
			
			elseif self.tSettings.bAutoPrune and (parentB > self.tSettings.MaxVirtualSlots) and (parentA <= self.tSettings.MaxVirtualSlots) then
			if nameA  == 9999 then
				self:DestroySlot()
			end
			--end
			elseif self.tSettings.bAutoPrune and (parentA > self.tSettings.MaxVirtualSlots) and (parentB <= self.tSettings.MaxVirtualSlots) then
				if nameA  ~= 9999 then
					local slotNum = self:FindFirstVirtualSlot()
					slotA = self.BagSlots[slotNum]:GetChildren()[1]
					parentA = tonumber(slotA:GetParent():GetName())
				end
				self:CreateNewSlot()
			end
		end

		self:RemoveItem(nil,slotA,nameA)
		
		if nameA > self.MaxBagSlots then
		--	self.RealRemap[nameA]=parentA
			slotA:SetName(9999)
		else
			slotA:SetName(nameA)
			self.RealRemap[nameA]=parentA
		end	
	end

	slotA:SetTooltip("")	
	slotB:SetTooltip("")	
	slotA:SetTooltipDoc(nil)	
	slotB:SetTooltipDoc(nil)	
	
	if self.Debug then
		self:DebugDraw()
	end
end


function KuronaBags:HelperBuildItemTooltip(wndArg, itemCurrent)
	wndArg:SetTooltipDoc(nil)
	local itemEquipped = itemCurrent:GetEquippedItemForItemType()
	Tooltip.GetItemTooltipForm(self, wndArg, itemCurrent, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
end


function KuronaBags:OnItemAdded(item, nCount, nReason,instanceItem)
	if itemInstance and itemInstance:CanTakeFromSupplySatchel() then
		Event_FireGenericEvent("LootItemSentToTradeskillBag", instanceItem)
	end
end


function KuronaBags:OnEquipmentChanged(nslot,itemNew,itemOld)
	if itemNew then
		itemNew:PlayEquipSound()
	elseif itemOld then
		itemOld:PlayEquipSound()
	end
	self:UpdateBagItemSlots()

	if itemNew then
		local slots = itemNew:GetBagSlots()
		if slots > 0 then
			if self.tSettings.bEnableVB then
				if self.ExtraBags ~= nil then
					for i = 1, #self.ExtraBags do
						if self.ExtraBags[i].Bag then
							self.ExtraBags[i].l,self.ExtraBags[i].t = self.ExtraBags[i].Bag:GetAnchorOffsets()
						end
					end	
				end
				self:ResizeVBag()
				self:WipeTooltips()
				self:OnBagItemMouseEnter( self.BagSlots[self.CurrentSlot]:GetChildren()[1], self.BagSlots[self.CurrentSlot], 0, 0 )
			else
				self:ResizeNVBag()

			end
		end
	end	
end



function KuronaBags:CorrectMaxSlots()
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	local rows = math.ceil(self.MaxBagSlots / self.tSettings.Columns)
	if self.tSettings.Rows < rows  then
		self.tSettings.Rows = rows
	end
	self.RowSlider:GetParent():GetParent():SetText(self.tSettings.Rows)
	self.RowSlider:SetValue(self.tSettings.Rows)
	self.tSettings.MaxVirtualSlots = self.tSettings.Columns * self.tSettings.Rows
end

function KuronaBags:ResizeVBag()
	self:CorrectMaxSlots()
	self:OnSliderChanged()
	self:ApplySizeSettings()
	
end


function KuronaBags:ResizeNVBag()
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	self.tSettings.Rows = math.ceil(self.MaxBagSlots / self.tSettings.Columns)
	self.RowSlider:GetParent():GetParent():SetText(self.tSettings.Rows)
	self.RowSlider:SetValue(self.tSettings.Rows)
	self:OnSliderChanged()
	self:ApplySizeSettings()
end
function KuronaBags:AddNewBagSlot(nBagSlot)
	for i = 1, #self.BagSlots do
		local slot = self.BagSlots[i]:GetChildren()[1]
		local name = tonumber(slot:GetName())
		if  name == 9999 then
			slot:SetName(nBagSlot)
			self.RealRemap[nBagSlot] = i
			return
		end
	end
end


function KuronaBags:RemoveOldBagSlot(nBagSlot)
	for i = 1, #self.BagSlots do
		local slot = self.BagSlots[i]:GetChildren()[1]
		local name = tonumber(slot:GetName())
		if  name == nBagSlot then
			slot:SetName(9999)
			self.RealRemap[nBagSlot] = nil
			return
		end
	end
end


function KuronaBags:CorrectBagSlots()
	self.RealRemap = {}
	local count = 0
	for i = 1, #self.BagSlots do
		local slot = self.BagSlots[i]:GetChildren()[1]
		local name = tonumber(slot:GetName())
		if  name ~= 9999 then
			self.RealRemap[name] = i
			count = count + 1
		end
	end
end


function KuronaBags:OnItemModified(sourceItem, nCount,arg2)
	if self.tSettings.bEnableVB then
		self:WipeTooltips()
	end
end

function KuronaBags:WipeTooltips()
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	for i = 1, self.MaxBagSlots do
		if self.RealRemap[i] == nil then
			Print("An inventory error has occured within KuronaBags while wiping tooltips. Remap Slot:".. i..  "/"..self.MaxBagSlots.."invalid")
			self:Restart()
			return
		end			
		local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
		if slot:GetData() then
			self.BagSlots[self.RealRemap[i]]:GetChildren()[1]:SetTooltip("")
		end
	end
end


function KuronaBags:OnItemRemoved(item, nCount,test,itemB)
end


function KuronaBags:GetLastFreeSpace()
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	local capacity = self.MaxBagSlots

	for i = capacity, 1, -1 do
		local item = GameLib.GetBagItem(i)
		if item == nil then
			self.LastFreeSlot = i
			return i
		end
	end
	return -1
end


function KuronaBags:GetFirstFreeSpace()
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	local capacity = self.MaxBagSlots

	for i = 1, capacity do
		local item = GameLib.GetBagItem(i)
		if item == nil then
			self.FirstFreeSlot = i
			return i
		end
	end
	return -1
end


function KuronaBags:FindRoomForItem()
	for i = 1, self.tSettings.MaxVirtualSlots do
		local slot = self.BagSlots[i]:GetChildren()[1]
		if slot:GetData() == nil then
			return slot
		end
	end
	return
end

function KuronaBags:TestClick()
	self.CurrentBag:FindChild("BagHolder"):SetStyle("IgnoreMouse",false)
	if self.LastClick then
		self.LastClick:SetStyle("IgnoreMouse",false)
	end

end

function KuronaBags:InventorySnapShot()
	self.BackupInv = {}	
	for i = 1, self.MaxBagSlots do
		self.BackupInv[i] = GameLib.GetBagItem(i)
	end
end


function KuronaBags:CompareInventory()
end


function KuronaBags:OnStartUpdateInventory()
	self:OnUpdateInventory()
--[[
	if not self.NeedToSmash and not self.JustSplitStack then
		Apollo.StopTimer("DelayedInventoryUpdate")
		Apollo.CreateTimer("DelayedInventoryUpdate", 0.05, false)
	else
		self:OnUpdateInventory()
	end
	]]
end

function KuronaBags:CanSalvageItems(item)
	if item ~=nil then
		if item:CanSalvage() and not self.PreventSalvageList[item:GetItemId()] and not self.KuronaSalvageList[item:GetItemId()] then
			self.canSalvage = true
		end
	end	
end

function KuronaBags:CheckItemCoolDowns()
	if not self.tSettings.bEnableVB then return end
	if not self.BagForm:IsShown() then return end
	for i = 1, self.MaxBagSlots do
		local item = GameLib.GetBagItem(i)
		
		if item then
			local deetz = item:GetDetailedInfo(Item.CodeEnumItemDetailedTooltip.Spell).tPrimary
			if deetz and deetz.arSpells and deetz.arSpells[1].splData:GetCooldownRemaining() > 0 then
			local time = math.floor(deetz.arSpells[1].splData:GetCooldownRemaining())
		
			if time < 100 then time = time.."s" 
			elseif time > 60 then time = math.floor(time/60 + 0.5).."m"
			end
		
			local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
			local strTime = time
		
			slot:UpdatePixie(5,{ strText = tostring(strTime), strFont = "CRB_Interface12_BO", bLine = false, strSprite = "ClientSprites:WhiteFill",
			cr = "80000000", loc = { fPoints = {0,0,1,1}, nOffsets = {1,1,-1,-1} },
			flagsText = { DT_CENTER = true, DT_VCENTER = true, } })
			self.CooldownList[i] = true
		elseif self.CooldownList[i] then
			self:ClearCooldownPixie(self.BagSlots[self.RealRemap[i]]:GetChildren()[1],i)
			self.CooldownList[i] = nil
		end
	end
	end
end

function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function KuronaBags:FindBagForItem(item)
--do a quick search to see if there are any matching filters
	local itemname = string.gsub(item:GetName(), "-", " "):lower()	
	local itemphrase = (itemname .." ".. item:GetItemTypeName() .." "..item:GetItemCategoryName()):lower()
	local deetz = item:GetDetailedInfo().tPrimary
	local pvp
	if deetz and deetz.bPvpGear then
		itemphrase = itemphrase.." pvp"
	end
	
	
	for i = 1, #self.ExtraBags do
		local basephrase = tostring(self.ExtraBags[i].sortphase:lower())
		local phrase = string.gsub(basephrase, "- ", "")
		if phrase ~= "" and phrase ~= nil then
			local splitPhrase = phrase:split("; ")
			for z=1, #splitPhrase do
				local x, j = string.find(itemphrase, splitPhrase[z])
				if x ~= nil then
					return self:FindFirstUsableSlot(self.ExtraBags[i].Bag)
				end
			end
		end
	end
	return self:FindFirstUsableSlot()
end

function KuronaBags:CreateNewSlot(nBag)
	local oldCount = self.tSettings.MaxVirtualSlots
	self.tSettings.MaxVirtualSlots = self.tSettings.MaxVirtualSlots + 1
	
	self:AdjustVirtualBagSlotCount(oldCount)

	-- Lets resize the main bag if needed.
	local children = self.BagForm:FindChild("BagHolder"):GetChildren()
	local rowsNeeded = math.ceil(self.tSettings.MaxVirtualSlots / self.tSettings.Columns)
	local height =  rowsNeeded * self.tSettings.IconSize
	local width = self.tSettings.Columns * self.tSettings.IconSize
	
	if not self.tSettings.AllowResizeBag then
		local l,t,r,b = self.BagForm:GetAnchorOffsets()
		self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
	end
	--self.tSettings.MaxVirtualSlots = self.tSettings.Columns * self.tSettings.Rows
	--self.tSettings.IconSize = self.IconSizeSlider:GetValue()
	self.needArrange = true

	
end

function KuronaBags:DestroySlot()
	local oldCount = self.tSettings.MaxVirtualSlots
	self.tSettings.MaxVirtualSlots = self.tSettings.MaxVirtualSlots - 1
	self:AdjustVirtualBagSlotCount(oldCount)
	
		-- Lets resize the main bag if needed.
	local children = self.BagForm:FindChild("BagHolder"):GetChildren()
	local rowsNeeded = math.ceil(self.tSettings.MaxVirtualSlots / self.tSettings.Columns)
	local height =  rowsNeeded * self.tSettings.IconSize
	local width = self.tSettings.Columns * self.tSettings.IconSize
	
	local l,t,r,b = self.BagForm:GetAnchorOffsets()
	self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
	self.needArrange = true
end


--Called when an item is removed/added
function KuronaBags:OnUpdateInventory()
if self.BagSlots == nil then return end
	Apollo.StopTimer("RedrawTimer")
	Apollo.CreateTimer("RedrawTimer", 0.5, false)

	if not self.tSettings.bEnableVB then return end
--[[
	if 	self.JustSplitStack and not self.FullStackTransfer then
		self.JustSplitStack = false
		self.DoStackSwap = true
		return
	end
]]
	local capacity = self.OBW:GetBagCapacity()
	if capacity ~= self.MaxBagSlots then
		self:OnEquipmentChanged()
		self:BagSlotCountChanged(capacity,self.MaxBagSlots)
	end
	self.MaxBagSlots = capacity
	
	self.canSalvage = false
	for i = 1, self.MaxBagSlots do
		local item = GameLib.GetBagItem(i)
		--if item ~= nil then self:CanSalvageItems(item) end
		
		
		if self.RealRemap[i] == nil then
--			Print("Self.Remap "..i.." is nil")
			self:Restart()
--			self:AutoSort()
			return
		end			
		if self.BagSlots[self.RealRemap[i]] == nil then
--			Print("Invalid Bag slot "..self.RealRemap[i])
			self:Restart()
--			self:AutoSort()
			return
		end

		
		
		
		
		--Remove Item
		if item == nil and self.BackupInv[i] then
			local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]

			if self.tSettings.bAutoPrune and self.RealRemap[i] > self.tSettings.MaxVirtualSlots then
				self:CreateNewSlot()
			end

			self:RemoveItem(nil,slot,i)
			--self.RealRemap[i]=i
			
			if not self.DoStackSwap then			
				slot:GetParent():FindChild("ItemNew"):Show(false,false)
			end
			if self.Debug then	slot:SetText(i) end

			--reclaim any virtual bag slot slots
			local slotNum = self:FindFirstVirtualSlot()
			
			
			if not slotNum then
				if self.tSettings.bAutoPrune then
					self:CreateNewSlot()
				end
				slotNum = self:FindFirstVirtualSlot()
			end
			
			slot:SetName(9999)
			if self.Debug then	slot:SetText(9999) end
			if self.BagSlots[slotNum] == nil then
				slotNum = self.RealRemap[i]
			end
			local newslot = self.BagSlots[slotNum]:GetChildren()[1]
			self.RealRemap[i]=tonumber(slotNum)
			newslot:SetName(i)	
			newslot:SetTooltipDoc(nil)
			if self.Debug then newslot:SetText(i) end
			if self.Debug then	slot:SetText(9999) end
			
			slot:SetTooltip("")
			slot:SetTooltipDoc(nil)
			if self.tSettings.bAutoPrune then
				--self:CreateNewSlot()
			end
		--Add Item
		elseif self.BackupInv[i] == nil and item then
			local slot
			local slotNum
			local newSlotOldName = ""
			local currentRemap = self.RealRemap[i]
			local originalslot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
			local data = originalslot:GetData()
			
			if self.JustSplitStack or self.SatchelDrag then
				
				dropslot = self.BagSlots[self.DropLocation]:GetChildren()[1]
				slotNum = tonumber(dropslot:GetName())
				self.RealRemap[i]=tonumber(dropslot:GetParent():GetName())	
			
				--swap drop slot with this slot

				originalslot:SetName(slotNum)
				if self.Debug then originalslot:SetText(slotNum) end
				
				if slotNum ~= 9999 then
					self.RealRemap[slotNum]=currentRemap
				end
				
				self:MakeItem(item, dropslot,i)
				dropslot:SetName(i)
				dropslot:SetData(item)
				slot = dropslot
				
			else
				--New slot to use
				slotNum = self:FindBagForItem(item)
				slot = self.BagSlots[slotNum]:GetChildren()[1]
				newSlotOldName = tonumber(slot:GetName())
				
				-- old slot needs name of new's
				originalslot:SetName(newSlotOldName)
				--remap old slot 
				if newSlotOldName ~= 9999 then
					self.RealRemap[newSlotOldName] = currentRemap
				end
				if self.Debug then self.BagSlots[currentRemap]:GetChildren()[1]:SetText(newSlotOldName) end
				
				
				self:MakeItem(item, slot,i)
				slot:SetName(i)
				slot:SetData(item)

				self.RealRemap[i]=tonumber(slot:GetParent():GetName())	

			end
			
			
			if self.Debug then	Print(i..":BagSlot "..slotNum..":ReplacementBagSlot".."/"..self.RealRemap[i])		end
			
			if self.Debug then		slot:SetText(i) end
	
			if not self.JustSplitStack and not self.NeedToSmash and not self.SatchelDrag then		
				slot:GetParent():GetChildren()[3]:Show(true,false)
			end
			
			self.JustSplitStack = false
			self.SatchelDrag = false
			slot:SetTooltip("")
			slot:SetTooltipDoc(nil)			
			
			if self.tSettings.bAutoPrune and (self.RealRemap[i] > self.tSettings.MaxVirtualSlots) and (currentRemap <= self.tSettings.MaxVirtualSlots) then
				self:DestroySlot()
			end

		--Item Mismatch / or item was salvaged and this new item took it's slot
		elseif item  and self.BackupInv[i] ~= item then
			local currentRemap = self.RealRemap[i]
			local originalslot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
			local slotNum = self.RealRemap[i]

			-- new slot
			if not item:CanEquip() then
				slotNum = self:FindBagForItem(item)
			end
			local slot = self.BagSlots[slotNum]:GetChildren()[1]

			local newSlotOldName = tonumber(slot:GetName())
						
			-- old slot needs name of new's
			originalslot:SetName(newSlotOldName)
			
			--remap old slot 
			if newSlotOldName ~= 9999 then
				self.RealRemap[newSlotOldName] = currentRemap
			end
			if self.Debug then self.BagSlots[currentRemap]:GetChildren()[1]:SetText(newSlotOldName) end
		
			slot = self.BagSlots[slotNum]:GetChildren()[1]

			self:MakeItem(item, slot,i)
			slot:SetName(i)
			
			self.RealRemap[i]=tonumber(slot:GetParent():GetName())
			self.lastmisEnd =  self.RealRemap[i]

			
			if not item:CanEquip() then
				self:RemoveItem(nil,originalslot,newSlotOldName)
			end
			
			slot:SetTooltipDoc(nil)
			self:HelperBuildItemTooltip(slot,item)
		elseif self.BackupInv[i] and item  then
			local slotCount = 	self.BagSlotCounts[i]
			if item:GetStackCount() ~= tonumber(slotCount) then
				local slot = self.BagSlots[tonumber(self.RealRemap[i])]:GetChildren()[1]
				if item:GetStackCount() > self.BagSlotCounts[i]  and not self.SmashStacks then
					self.BagSlots[self.RealRemap[i]]:GetChildren()[3]:Show(true,false)
				end

				self:SetStackCount(slot, item:GetStackCount(),i)
				slot:SetTooltip("")
				slot:SetTooltipDoc(nil)
			end
		elseif item then
		end		
	end
	
	self.equipmentChange = false
	self:InventorySnapShot()
	
	if self.NeedToSmash then
		self.NeedToSmash = false
		self:SmashStacks()
		if self.Debug then self:DebugDraw()	end
		return
	end
end

function KuronaBags:DebugDraw()
	local text =""
	for i=1,self.MaxBagSlots do
		text = text .. i .." "..self.RealRemap[i] .."\n"
	end
	self.DebugWindow:Show(true)
	self.DebugWindow:SetText(text)
end

function KuronaBags:Redraw()
	self:DisplayFreeSlots()
	self.MainCashWindow:SetAmount(GameLib.GetPlayerCurrency(), true)
	if self.tSettings.bEnableVB then
		--self:OnBagItemMouseEnter( self.BagSlots[self.CurrentSlot or 1]:GetChildren()[1], self.BagSlots[self.CurrentSlot or 1], 0, 0 )
		self:OnPreventSalvage()
		
		if self.BagForm:IsShown() and self.needArrange then
		
			local scroll = self.NVB:GetParent():GetVScrollPos()
		
			local Pwidth = self.BagForm:GetWidth() - 30
			local usableCol = math.floor(Pwidth / self.tSettings.IconSize)
			local rows = math.ceil(self.tSettings.MaxVirtualSlots / usableCol)

			local scroll = self.BagForm:FindChild("BagHolder"):GetVScrollPos()
			self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)
			self.needArrange = false
			self.BagForm:FindChild("BagHolder"):SetVScrollPos(scroll)
			
			--[[
			self.tSettings.Rows = rows
			self.tSettings.Columns = usableCol

			self.RowSlider:SetValue(self.tSettings.Rows)
			self.ColumnSlider:SetValue(self.tSettings.Columns)
			self.RowSlider:GetParent():GetParent():SetText(self.RowSlider:GetValue())
			self.ColumnSlider:GetParent():GetParent():SetText(self.ColumnSlider:GetValue())

			--self:ApplySizeSettings(true)
			]]
		end
	end	
	--self.BagForm:FindChild("BagWindow"):MarkAllItemsAsSeen()
	
	self.JustSplitStack = false
	self.SatchelDrag = false

	self:CheckSalvageState()
	self.SalvageButton:Enable(self.canSalvage)
	--self.AutoSortButton:Enable(#self.ExtraBags > 0)
	local color ="FFFFFFFF"
	if self.EmptyBagSlots == 0 then
		color = "FFFF0000"
	elseif self.EmptyBagSlots == 1 then
		color = "FFFFFF00"
	end
	self.BagLocator:SetBGColor(color)
	
	self:RedrawBank()
	
	if 	not self.tSettings.bEnableVB then
		local scroll = self.NVB:GetParent():GetVScrollPos()
		local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
		local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
		
		local Pwidth = self.BagForm:GetWidth() - 30
		local usableCol = math.floor(Pwidth / self.tSettings.IconSize)
		local rows = math.ceil(self.MaxBagSlots / usableCol)

		self.NVB:SetSquareSize(self.tSettings.IconSize,self.tSettings.IconSize)
		self.NVB:SetAnchorOffsets(0,0,usableCol*self.tSettings.IconSize ,(rows* self.tSettings.IconSize))
		local pos = {self.BagForm:GetAnchorOffsets()}
		
		self.BagForm:FindChild("BagHolder"):Show(false)
		self.NVB:SetBoxesPerRow(usableCol)
		self.tSettings.Rows = rows
		self.tSettings.Columns = usableCol
		--adjust the sliders
		self.RowSlider:SetValue(self.tSettings.Rows)
		self.ColumnSlider:SetValue(self.tSettings.Columns)
		self.RowSlider:GetParent():GetParent():SetText(self.RowSlider:GetValue())
		self.ColumnSlider:GetParent():GetParent():SetText(self.ColumnSlider:GetValue())
		self.NVB:GetParent():SetVScrollPos(scroll)
		self.BagForm:SetAnchorOffsets(unpack(pos))
		self.NVB:GetParent():SetVScrollPos(scroll)
		
	end
end


function KuronaBags:DisplayFreeSlots()
	self.EmptyBagSlots =  self.BagForm:FindChild("BagWindow"):GetTotalEmptyBagSlots()
	self.BagForm:FindChild("FreeSlots"):SetText(self.EmptyBagSlots)
	self.InvButton:SetTooltip(self.MaxBagSlots - self.EmptyBagSlots .."/"..	self.MaxBagSlots)

	if self.EmptyBagSlots < 1 then
		self.BagForm:FindChild("FreeSlots"):SetTextColor("red")
		self.InvButton:ChangeArt("HUD_BottomBar:btn_HUD_InventoryFull")
	else
		self.BagForm:FindChild("FreeSlots"):SetTextColor("xkcdAmber")
		self.InvButton:ChangeArt("HUD_BottomBar:btn_HUD_Inventory")
	end
end


function KuronaBags:OnLootedItem(item,ncount)
	if item == nil then return end
	
	if item and item:CanTakeFromSupplySatchel() then
		if not item:CanMoveToSupplySatchel() then
			self.TradeskillButton:FindChild("ItemNew"):Show(true,false)
		end
	end
end


function KuronaBags:MapInventorySlots()
	for i = 1, self.MaxBagSlots do
		local slot = i
		local nBagSlot = self.BagSlots[i]:GetChildren()[1]:GetName()
	end
end

function KuronaBags:DefaultTable()
	local defaultsettings = {}
	defaultsettings.MaxVirtualSlots = 200
	defaultsettings.Columns = 10 
	defaultsettings.Rows = 10
	defaultsettings.IconSize = 45
			
	defaultsettings.nMainL = -495
	defaultsettings.nMainT = -663
	defaultsettings.nMainR = -11
	defaultsettings.nMainB = -118
	
	defaultsettings.nBankL = -495
	defaultsettings.nBankT = -663
	defaultsettings.nBankR = -11
	defaultsettings.nBankB = -118
	
	defaultsettings.nSideL = 3
	defaultsettings.nSideT = -761
	defaultsettings.nSideR = 333
	defaultsettings.nSideB = -346

	defaultsettings.TopL = -200
	defaultsettings.TopT = 20
	defaultsettings.TopR = 200
	defaultsettings.TopB = 232

	defaultsettings.AutoRepair = false
	defaultsettings.AutoOpenBags = false
	defaultsettings.GuildRepair = false
	defaultsettings.AutoSellJunk = true
	defaultsettings.AutoSellAmps = false
	defaultsettings.ItemTrail = true
	defaultsettings.AllowResizeBag = false
	
	defaultsettings.LootThresholdAlert = 3
	defaultsettings.SideLootNumberDisplayed = 5
	defaultsettings.LargeLootScale = 100
	defaultsettings.SideLootScale = 100
	defaultsettings.SmallLootShowTime = 2 
	defaultsettings.LargeLootShowTime = 3
	defaultsettings.LootTimer = 2
	defaultsettings.Debug = false
	defaultsettings.bAutoPrune = false
	defaultsettings.bAutoCompact = false
	defaultsettings.bDisableVirtual = false
	
	--Bank
	defaultsettings.nBankIconSize = 45
	defaultsettings.nBankWidth = 8
	
	--Virtual Bag
	defaultsettings.bEnableVB = true
	defaultsettings.bShowQuestItems = true
	defaultsettings.nSortType = 1
--	defaultsettings.tHideSalvage = {}
	
	return defaultsettings
	
end

function KuronaBags:OnSave(eLevel,backup)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tsave = {}

	tsave.RealRemap = self.RealRemap
	
	tsave.tSettings = {}
	tsave.tSettings.MaxVirtualSlots = self.tSettings.MaxVirtualSlots
	tsave.tSettings.IconSize = self.tSettings.IconSize
	tsave.tSettings.Rows = self.tSettings.Rows
	tsave.tSettings.Columns = self.tSettings.Columns
	tsave.tSettings.nMainL,tsave.tSettings.nMainT,tsave.tSettings.nMainR,tsave.tSettings.nMainB = self.BagForm:GetAnchorOffsets()
	tsave.tSettings.nBankL,tsave.tSettings.nBankT,tsave.tSettings.nBankR,tsave.tSettings.nBankB = self.BankBagForm:GetAnchorOffsets()
--	tsave.tSettings.nSideL,tsave.tSettings.nSideT,tsave.tSettings.nSideR,tsave.tSettings.nSideB = self.SmallLootForm:GetAnchorOffsets()
--	tsave.tSettings.TopL,tsave.tSettings.TopT,tsave.tSettings.TopR,tsave.tSettings.TopB = self.LootNote:GetAnchorOffsets()

	tsave.tSettings.LootThresholdAlert = self.tSettings.LootThresholdAlert
	tsave.tSettings.LargeLootScale = self.tSettings.LargeLootScale
	tsave.tSettings.SideLootScale = self.tSettings.SideLootScale
	tsave.tSettings.SideLootNumberDisplayed = self.tSettings.SideLootNumberDisplayed
	tsave.tSettings.LootTimer = self.tSettings.LootTimer
	
	tsave.tSettings.AutoSellJunk =  self.tSettings.AutoSellJunk 
	tsave.tSettings.AutoSellAmps =  self.tSettings.AutoSellAmps
	tsave.tSettings.AutoRepair =  self.tSettings.AutoRepair
	tsave.tSettings.GuildRepair =  self.tSettings.GuildRepair
	tsave.tSettings.AutoOpenBags =  self.tSettings.AutoOpenBags
	tsave.tSettings.ItemTrail =  self.tSettings.ItemTrail
	tsave.tSettings.bAutoPrune =  self.tSettings.bAutoPrune
	tsave.tSettings.bAutoCompact =  self.tSettings.bAutoCompact
	tsave.tSettings.bDisableVirtual =  self.tSettings.bDisableVirtual
	tsave.tSettings.bEnableVB = self.tSettings.bEnableVB
	tsave.tSettings.AllowResizeBag = self.tSettings.AllowResizeBag
	tsave.tSettings.nSortType = self.tSettings.nSortType
	--Bank
	tsave.tSettings.nBankIconSize = self.tSettings.nBankIconSize
	tsave.tSettings.nBankWidth = self.tSettings.nBankWidth
	tsave.Version = Version
	tsave.Debug = self.Debug
	
	if self.QuestBag then
		tsave.tSettings.QuestBagLeft,tsave.tSettings.QuestBagTop = self.QuestBag:GetAnchorOffsets()
	else
		tsave.tSettings.QuestBagLeft = self.tSettings.QuestBagLeft
		tsave.tSettings.QuestBagTop = self.tSettings.QuestBagTop
	end
	tsave.tSettings.bShowQuestItems = self.tSettings.bShowQuestItems
	
	if self.tSettings.bEnableVB then
		for i = 1, #self.ExtraBags do
			self.ExtraBags[i].l,self.ExtraBags[i].t = self.ExtraBags[i].Bag:GetAnchorOffsets()
		end	
	end
--	tsave.tSettings.tHideSalvage = self.tSettings.tHideSalvage
	tsave.ExtraBags = self.ExtraBags
	return tsave
end


function KuronaBags:OnRestore(eLevel, saveData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.RealRemap = saveData.RealRemap
	self.Debug = saveData.Debug
	if saveData.Version == nil or saveData.Version < 2.4 then
		--self.displayApology = true
	end
	if saveData.ExtraBags then
		self.ExtraBags = saveData.ExtraBags
	end
	
	self.tSettings = {}			
	local defaultsettings = self:DefaultTable()
		
	for k,v in pairs(saveData.tSettings) do
	   	self.tSettings[k]=v
	end

	for k,v in pairs(defaultsettings) do
	   	if self.tSettings[k] == nil then
			 self.tSettings[k] = v
		end
	end
end


function KuronaBags:Restart()
if self.restarting then return end
self.restarting = true
	if self.ExtraBags ~= nil then
		for i = 1, #self.ExtraBags do
			if self.ExtraBags[i].Bag then
				self.ExtraBags[i].l,self.ExtraBags[i].t = self.ExtraBags[i].Bag:GetAnchorOffsets()
			end
		end	
	end
	if self.QuestBag then
		self.QuestBag:Destroy()
		self.QuestBag = nil
	end
	
	if self.tSettings.bEnableVB then
		self:CorrectMaxSlots()
		self:OnSliderChanged()

--		self:ResizeVBag()
	end
	
	self.tSettings.MaxVirtualSlots = self.tSettings.Columns * self.tSettings.Rows
	self:InventorySnapShot()
	self.BagForm:FindChild("BagHolder"):DestroyChildren()
	self.ClosedBagRack:DestroyChildren()
	local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
	local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
	
	local l,t,r,b = self.BagForm:GetAnchorOffsets()
	if not self.tSettings.AllowResizeBag then
		self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
	end


	self.RealRemap = nil
	self:PopulateBag()
	self:AdjustVirtualBagSlotCount(self.tSettings.MaxVirtualSlots)
	self:OpenInventory()
	self:AutoSort()
	self:OnSettingsChanged()
	self.restarting = false
end


function KuronaBags:StartSearch(strName)
	--self.OBS:Show(false,true)
	if self.tSettings.bEnableVB then
	self.OBS:SetAnchorOffsets(0,0,0,0)
	self.SearchInProgress = true

	for i = 1, self.MaxBagSlots do
		if self.RealRemap then		
			local data = self.BagSlots[tonumber(self.RealRemap[i])]:GetChildren()[1]:GetData()

			if data then
				local basename = (data:GetName() .." ".. data:GetItemTypeName() .." "..data:GetItemCategoryName()):lower()
				local deetz = data:GetDetailedInfo().tPrimary
				local pvp
				if deetz and deetz.bPvpGear then
					basename = basename.." pvp"
				end

				local name = string.gsub(basename, "- ", "")
				local x, j = string.find(name, strName)
				if x ~= nil then
					if not self.BagSlots[self.RealRemap[i]]:IsShown() then
						self.BagSlots[self.RealRemap[i]]:Show(true,false)
					end
				else
					if self.BagSlots[self.RealRemap[i]]:IsShown() then
						self.BagSlots[self.RealRemap[i]]:Show(false,false)
					end
				end			
			end 
		end
	end
	end
	
	
	--Print(self.BankBagForm:FindChild("BankWindow"):GetItem(1):GetName())
	
	if not self.bEnableVB then
	
		self.strSearch = strName
	--KuronaBags.strTest={}
		local fnSortSearch = function(itemLeft, itemRight)
		
		if self.KuronaBagAd == nil then
			self.KuronaBagAd = Apollo.GetAddon("KuronaBags")
		end
	if itemLeft then
		self.KuronaBagAd.strSearch = itemLeft:GetName()
	end
	
		if itemLeft == itemRight then
			return 0
		end
		if itemLeft and itemRight == nil then
			return -1
		end
		if itemLeft == nil and itemRight then
			return 1
		end
		--Print(self.strSearch)
		local leftMatch = false
		local rightMatch = false
	
		local basename = (itemLeft:GetName() .." ".. itemLeft:GetItemTypeName() .." "..itemLeft:GetItemCategoryName()):lower()
		local name = string.gsub(basename, "- ", "")
		local x, j = string.find(basename, self.strSearch)
		if x ~= nil then
			leftMatch = true
			return -1			
		end
	
		local basename = (itemRight:GetName() .." ".. itemRight:GetItemTypeName() .." "..itemRight:GetItemCategoryName()):lower()
		local name = string.gsub(basename, "- ", "")
		local x, j = string.find(basename, self.strSearch)
		if x ~= nil then
			rightMatch = true
			return 1			
		end
		
		if leftMatch then
			return -1
		end	
	
		if rightMatch and not leftMatch then		
			return 1
		end
	
		if not leftMatch and not rightMatch then
			return -1
		end
		return 0
		end
		
		self.NVB:SetSort(true)
		self.NVB:SetItemSortComparer(fnSortSearch)
	
	end
end

function KuronaBags:TestInter(itemLeft)
end


function KuronaBags:NVBagSearch(itemLeft, itemRight)
		if itemLeft == itemRight then
			return 0
		end
		if itemLeft and itemRight == nil then
			return -1
		end
		if itemLeft == nil and itemRight then
			return 1
		end
	
	
		local strLeftItemType = itemLeft:GetItemType()
		local strRightItemType= itemRight:GetItemType()
		if strLeftItemType==213 then
			return -1
		end
		if strRightItemType == 213 and strLeftItemType ~= 213 then
			return 1
		end
		if strLeftItemType ~= 213 and strRightItemType ~= 213 then
			return -1
		end
		return 0
end		

function KuronaBags:OnCloseVendor()
self.VendorOpen = false
end

function KuronaBags:OnShowVendor()
	self.VendorOpen = true
	if self.tSettings.AutoOpenBags then
		self:OpenInventory()
	end
	
	local itemSold = false
	--Sell Junk
	self:OnUpdateInventory()
	if self.tSettings.AutoSellJunk then
		for _, item in ipairs(GameLib.GetPlayerUnit():GetInventoryItems()) do
			if item.itemInBag:GetItemQuality() == 1  and item.itemInBag:GetSellPrice() then
				SellItemToVendorById(item.itemInBag:GetInventoryId(), item.itemInBag:GetStackCount())
				itemSold = true
			end
		end
	end
	if self.tSettings.AutoSellAmps then
		for _, item in ipairs(GameLib.GetPlayerUnit():GetInventoryItems()) do
			if item.itemInBag:GetItemFamily() == 32  and item.itemInBag:GetSellPrice() then
				if self:CantUseItem(item.itemInBag) then
					local name = item.itemInBag:GetName()
					local upgrade = string.match(name,"Upgrade")
					local unlock = string.match(name,"Unlock")
					if not upgrade and not unlock then
						SellItemToVendorById(item.itemInBag:GetInventoryId(), item.itemInBag:GetStackCount())
						itemSold = true
					end
				end
			end
		end
	end
	if self.tSettings.AutoRepair then
		if self.tSettings.GuildRepair then
			local tMyGuild = nil
			for idx, tGuild in pairs(GuildLib.GetGuilds()) do
				if tGuild:GetType() == GuildLib.GuildType_Guild then
					tMyGuild = tGuild
					break
				end
			end
			if tMyGuild then
				tMyGuild:RepairAllItemsVendor()
			end	
		end
		RepairAllItemsVendor()
	end
end



function KuronaBags:AdjustVirtualBagSlotCount(oldCount)
	--add more to self.BagSlots
	local bagHolder = self.BagForm:FindChild("BagHolder")
	if oldCount < self.tSettings.MaxVirtualSlots then
		local diff = self.tSettings.MaxVirtualSlots - oldCount

		for i = oldCount+1, self.tSettings.MaxVirtualSlots do
			self.BagSlots[i] = Apollo.LoadForm(self.xmlDoc, "BagItem", self.BagForm:FindChild("BagHolder"), self)
			self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
			self.BagSlots[i]:SetName(i)
			self.BagSlots[i]:GetChildren()[1]:SetName(9999)
			if self.Debug then self.BagSlots[i]:GetChildren()[1]:SetText(9999) end
		end
--		if self.BagForm:IsShown() then
--			self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)
--		else
			self.needArrange = true
--		end
	elseif oldCount > self.tSettings.MaxVirtualSlots then
		local diff = oldCount - self.tSettings.MaxVirtualSlots
		local killcount = 0
		
		local LostEmptySlots = {}
	local firstDeadSlot = 1
		
		for i = oldCount,1, -1 do
			if self.BagSlots[i] == nil then
			--Print(i .."nil")
			end
			local slot = self.BagSlots[i]:GetChildren()[1]
			self.BagSlots[i] = nil
			if slot:GetData() == nil then
				local num= tonumber(slot:GetName())
				if num ~= 9999 then
				if not firstDeadSlot ~=1 then
					firstDeadSlot = num
				end
					table.insert(LostEmptySlots,num)
				end
				bagHolder:GetChildren()[i]:Destroy()
				killcount = killcount + 1
			end
			if killcount == diff then break end
		end
		
	
		--self.Remap = {}
		--self.BagSlots = {}
		for i = 1, self.tSettings.MaxVirtualSlots do
			self.BagSlots[i] = bagHolder:GetChildren()[i]
			bagHolder:GetChildren()[i]:SetName(i)			
			--Print("setting "..i)
			local nBagSlot = tonumber(bagHolder:GetChildren()[i]:GetChildren()[1]:GetName())
			
			if bagHolder:GetChildren()[i]:GetChildren()[1]:GetData() then
				self.RealRemap[nBagSlot] = i
				--Reasign orphaned empty spots to any 9999 slots
			elseif nBagSlot == 9999 and LostEmptySlots[1] ~= nil then
				bagHolder:GetChildren()[i]:GetChildren()[1]:SetName(LostEmptySlots[1])
				if self.Debug then bagHolder:GetChildren()[i]:GetChildren()[1]:SetText(LostEmptySlots[1]) end
				self.RealRemap[LostEmptySlots[1]] = i
--				Print("Recovering orphaned slot :" .. LostEmptySlots[1].. " to new slot :" .. i)
				table.remove(LostEmptySlots,1)				
			end
		end
	end
end


function KuronaBags:MoveToLastFreeSpot(oldCount,slot)
	for x = self.tSettings.MaxVirtualSlots, 1, -1 do
		if self.BagSlots[x]:GetChildren()[1]:GetData() == nil then
			self:SwapItems(nil, self.BagSlots[x]:GetChildren()[1])
			return
		end
	end
end


-- can probably speed this up thru a table of "new" items
function KuronaBags:AllItemsSeen()
if self.tSettings.bEnableVB then
	for i = 1, self.MaxBagSlots do
		local slot = self.BagSlots[tonumber(self.RealRemap[i])]:GetChildren()[3]
		if slot:IsShown() then 
			slot:Show(false,true)
		end
	end
	else
		self.NVB:MarkAllItemsAsSeen()
	end
	
	self.TradeskillButton:FindChild("ItemNew"):Show(false,false)
end	


function KuronaBags:SetQualityFrame(slot,quality)
		slot:UpdatePixie(2,{
		 strText = "",
		 strFont = "Default",
		 bLine = false,
		 
		 strSprite = QualityFrames[quality],
--		 strSprite = "KBsprites:Frame",
		 cr = "2x:".. QualityColors[quality],
		 loc = {
		 fPoints = {0,0,1,1},
		 nOffsets = {1,1,0,0}
		 },
		 flagsText = {
		 DT_RIGHT = true,
		 }
		})
end

function KuronaBags:SetStackCount(slot,count,nBagSlot,ignore)
	if nBagSlot ~= 9999 then
		self.BagSlotCounts[nBagSlot] = count
	end

	if count < 2 then count = "" end
		slot:UpdatePixie(4,{
		strText = tostring(count),
		strFont = "CRB_Header9_O",
		bLine = false,
		strSprite = "",
		cr = "FFFFFFFF",
		loc = {
		fPoints = {0,0,1,1},
		nOffsets = {4,4,-5,5}
		},
		flagsText = {
		DT_RIGHT = true,
		}
		})
end


function KuronaBags:UpdateStackPixie(slot,newCount)

		if newCount < 2 then
			newCount =""
		end
		slot:UpdatePixie(4,{
		strText = newCount,
		strFont = "Default",
		bLine = false,
		strSprite = "",
		cr = {a=1,r=1.00,g=1.00,b=1.00},
		loc = {
		fPoints = {0,0,1,1},
		nOffsets = {0,2,-2,0}
		},
		flagsText = {
		DT_RIGHT = true,
		}
		})
end


function KuronaBags:SetIcon(slot,strIcon)
	local color = "FFFFFFFF"
	if self.Debug then color = "80ffffff" end
		slot:UpdatePixie(1,{
		strText = "",
		strFont = "Default",
		bLine = false,
		strSprite = strIcon,
		cr = color,
		loc = {
		fPoints = {0,0,1,1},
		nOffsets = {3,3,-2,-2}
		},
		flagsText = {
		DT_RIGHT = true,
		}
		})
end


function KuronaBags:SetCantUseIcon(slot,cantuse,quest)
	local strSprite = ""
	if quest then
		strSprite = "ClientSprites:sprItem_NewQuest"
	elseif cantuse then 
		strSprite = "ClientSprites:LootCloseBox"
	end
		slot:UpdatePixie(3,{
		strText = "",
		strFont = "Default",
		bLine = false,
		strSprite = strSprite,
		cr = {a=1,r=1.00,g=1.00,b=1.00},
		loc = {
		fPoints = {0,0,1,1},
		nOffsets = {0,2,-2,0}
		},
		flagsText = {
		DT_RIGHT = true,
		}
		})
end


-- Salvage /  Delete
function KuronaBags:InvokeDeleteConfirmWindow(iData)
	local item = Item.GetItemFromInventoryLoc(iData)
	if item == nil then return end
	
	if item and not item:CanDelete() then
		return
	end
	
	local quality = item:GetItemQuality()
	
	self.wndDeleteConfirm:FindChild("RarityBracket"):SetSprite(ItemQualityFrames[quality])
	self.wndDeleteConfirm:FindChild("LootIcon"):SetSprite(item:GetIcon())
	self.wndDeleteConfirm:FindChild("ColorBG"):SetBGColor(QualityColors[quality])
	self.wndDeleteConfirm:FindChild("IconFrame"):SetBGColor(QualityColors[quality])
	self.wndDeleteConfirm:FindChild("ItemName"):SetText(item:GetName())
	self.wndDeleteConfirm:FindChild("ItemType"):SetText(item:GetItemTypeName())
	self.wndDeleteConfirm:FindChild("DeleteLootItem"):SetOpacity(0.85)

	
	
	self.wndDeleteConfirm:SetData(iData)
	self.wndDeleteConfirm:Show(true)
	self.wndDeleteConfirm:ToFront()
	self.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(true)
	if self.tSettings.bEnableVB then
		for i = 1, #self.ExtraBags do
			self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(true)
		end
	end
	self.BagForm:FindChild("SalvageAllButton"):Enable(false)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end


function KuronaBags:InvokeSalvageConfirmWindow(iData)
	local item = Item.GetItemFromInventoryLoc(iData)
	local quality = item:GetItemQuality()
	self.wndSalvageConfirm:FindChild("RarityBracket"):SetSprite(ItemQualityFrames[quality])
	self.wndSalvageConfirm:FindChild("LootIcon"):SetSprite(item:GetIcon())
	self.wndSalvageConfirm:FindChild("ColorBG"):SetBGColor(QualityColors[quality])
	self.wndSalvageConfirm:FindChild("IconFrame"):SetBGColor(QualityColors[quality])
	self.wndSalvageConfirm:FindChild("ItemName"):SetText(item:GetName())
	self.wndSalvageConfirm:FindChild("ItemType"):SetText(item:GetItemTypeName())
	self.wndSalvageConfirm:FindChild("SalvageLootItem"):SetOpacity(0.85)

	self.wndSalvageConfirm:SetData(iData)
	self.wndSalvageConfirm:Show(true)
	self.wndSalvageConfirm:ToFront()
	self.wndSalvageConfirm:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, iData)
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(true)
	if self.tSettings.bEnableVB then
		for i = 1, #self.ExtraBags do
			self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(true)
		end
	end

	self.BagForm:FindChild("SalvageAllButton"):Enable(false)
	self.BagForm:FindChild("SalvageAllButton"):Enable(false)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

-- TODO SECURITY: These confirmations are entirely a UI concept. Code should have a allow/disallow.
function KuronaBags:OnDeleteCancel()
	self.wndDeleteConfirm:SetData(nil)
	self.wndDeleteConfirm:Close()
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(false)
	if self.tSettings.bEnableVB then
		for i = 1, #self.ExtraBags do
			self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(false)
		end
	end

	self.BagForm:FindChild("SalvageAllButton"):Enable(true)
end

function KuronaBags:OnSalvageCancel()
	self.wndSalvageConfirm:SetData(nil)
	self.wndSalvageConfirm:Close()
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(false)
	if self.tSettings.bEnableVB then
		for i = 1, #self.ExtraBags do
			self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(false)
		end
	end
	self.BagForm:FindChild("SalvageAllButton"):Enable(true)
	self:Redraw()
end

function KuronaBags:OnDeleteConfirm()
	self:OnDeleteCancel()
end

function KuronaBags:OnSalvageConfirm()
	self:OnSalvageCancel()
end

function KuronaBags:GenerateTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler or self.EditLoot then return end
	item = wndHandler:GetData()
	wndControl:SetTooltipDoc(nil)

	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

function KuronaBags:GenerateBagTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler or self.EditLoot then return end
	wndControl:SetTooltipDoc(nil)
	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end

function KuronaBags:OnPlayerCurrencyChanged()
	self.MainCashWindow:SetAmount(GameLib.GetPlayerCurrency(), true)
	self.ElderGemCashWindow:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.ElderGems):GetAmount(), true)	
	self.OmniBitsCashWindow:SetAmount(AccountItemLib.GetAccountCurrency(6))
	self.ServiceTokenCashWindow:SetAmount(AccountItemLib.GetAccountCurrency(AccountItemLib.CodeEnumAccountCurrency.ServiceToken))
	local tOmniBitInfo = GameLib.GetOmnibitsBonusInfo()
	local nTotalWeeklyOmniBitBonus = tOmniBitInfo.nWeeklyBonusMax - tOmniBitInfo.nWeeklyBonusEarned;
	if nTotalWeeklyOmniBitBonus < 0 then
		nTotalWeeklyOmniBitBonus = 0
	end
	strDescription = "OmniBits".."\n".."Remaining Weekly Bonus: " ..nTotalWeeklyOmniBitBonus
	self.OmniBitsCashWindow:SetTooltip(strDescription)

	self.GloryCashWindow:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Glory):GetAmount(), true)	
	self.RenownCashWindow:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount(), true)	
	self.PrestigeCashWindow:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Prestige):GetAmount(), true)	
	self.CraftingCashWindow:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.CraftingVouchers):GetAmount(), true)	
end


function KuronaBags:OnSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	self.RowSlider:GetParent():GetParent():SetText(self.RowSlider:GetValue())
	self.ColumnSlider:GetParent():GetParent():SetText(self.ColumnSlider:GetValue())
	self.IconSizeSlider:GetParent():GetParent():SetText(self.IconSizeSlider:GetValue())
	local totalSlots = self.ColumnSlider:GetValue() * self.RowSlider:GetValue()
	self.TotalSlots:SetText("Total Slots : " .. totalSlots)
	if not self.tSettings.bEnableVB then
		self.SApplyButton:Enable(true)
	elseif totalSlots < self.MaxBagSlots then
		self.SApplyButton:Enable(false)
		self.TotalSlots:SetTextColor("red")
	else
		self.SApplyButton:Enable(true)
		self.TotalSlots:SetTextColor("white")
	end
end


function KuronaBags:SetOptions()
	self.RowSlider:SetValue(self.tSettings.Rows)
	self.ColumnSlider:SetValue(self.tSettings.Columns)
	self.IconSizeSlider:SetValue(self.tSettings.IconSize)

	self:OnSliderChanged()
	
	self.OptionsWindow:FindChild("AutoSellButton"):SetCheck(self.tSettings.AutoSellJunk)
	self.OptionsWindow:FindChild("AutoSellAmpsButton"):SetCheck(self.tSettings.AutoSellAmps)
	self.OptionsWindow:FindChild("AutoRepairButton"):SetCheck(self.tSettings.AutoRepair)
	self.OptionsWindow:FindChild("GuildRepairButton"):SetCheck(self.tSettings.GuildRepair)
	self.OptionsWindow:FindChild("GuildRepairButton"):Enable(self.tSettings.AutoRepair)
	self.OptionsWindow:FindChild("AutoOpenBags"):SetCheck(self.tSettings.AutoOpenBags)
	self.OptionsWindow:FindChild("ItemTrailButton"):SetCheck(self.tSettings.ItemTrail)
	self.OptionsWindow:FindChild("AutoCompactButton"):SetCheck(self.tSettings.bAutoCompact)
	self.OptionsWindow:FindChild("EnableVirtualInventory"):SetCheck(self.tSettings.bEnableVB)
	self.OptionsWindow:FindChild("QuestItemsButton"):SetCheck(self.tSettings.bShowQuestItems)
	self.OptionsWindow:FindChild("AllowResizeBag"):SetCheck(self.tSettings.AllowResizeBag)
	--self.OptionsWindow:FindChild("AutoSizeButton"):SetCheck(self.tSettings.bAutoPrune)
	self.RowSlider:Enable(not self.tSettings.bAutoPrune) 
--	self.RowSlider:GetParent():GetParent():Show(not self.tSettings.bAutoPrune)
	self.BagSortWindow:SetRadioSel("SortChecks", self.tSettings.nSortType or 1)
--[[
	self.LootOptions:FindChild("SideLootNumSliderBar"):SetValue(self.tSettings.SideLootNumberDisplayed)	
	self.LootOptions:FindChild("LargeLootSizeSliderBar"):SetValue(self.tSettings.LargeLootScale)
	self.LootOptions:FindChild("SideLootSizeSliderBar"):SetValue(self.tSettings.SideLootScale)
	self.LootOptions:FindChild("LootThresholdSliderBar"):SetValue(self.tSettings.LootThresholdAlert)
	self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)

	self.LootOptions:FindChild("LootTimerSliderBar"):SetValue(self.tSettings.LootTimer*10)
	self.LootOptions:FindChild("LootTimer"):SetText(self.tSettings.LootTimer.." sec")
]]
	
	self:SetBankOptions()
--	self:OnLootSliderChanged(self.LootSlider,self.LootSlider,0,true)
end

function KuronaBags:StartAutoPrune()
self.MaxBagSlots =  self.BagForm:FindChild("BagWindow"):GetBagCapacity()
	local count = 0
	for i =1, self.MaxBagSlots do
		if self.RealRemap[i] < 400 then
			count = count + 1
		end
	end

end

function KuronaBags:OnDefaultLootSettings( wndHandler, wndControl, eMouseButton )
	local defaults = self:DefaultTable()
	self.tSettings.LootThresholdAlert = defaults.LootThresholdAlert
	self.tSettings.SideLootNumberDisplayed = defaults.SideLootNumberDisplayed
	self.tSettings.LargeLootScale = defaults.LargeLootScale
	self.tSettings.SideLootScale = defaults.SideLootScale
	self.tSettings.LootTimer = defaults.LootTimer
	
	self.LootNote:SetAnchorOffsets(defaults.TopL,defaults.TopT,defaults.TopR,defaults.TopB)
	self.SmallLootForm:SetAnchorOffsets(defaults.nSideL,defaults.nSideT,defaults.nSideR,defaults.nSideB)

	self.LootOptions:FindChild("LargeLootSizeSliderBar"):SetValue(self.tSettings.LargeLootScale)
	self.LootOptions:FindChild("SideLootSizeSliderBar"):SetValue(self.tSettings.SideLootScale)
	self.LootOptions:FindChild("LootThresholdSliderBar"):SetValue(self.tSettings.LootThresholdAlert)
	self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)
	self.LootOptions:FindChild("LootTimerSliderBar"):SetValue(self.tSettings.LootTimer*10)
	self.LootOptions:FindChild("LootTimer"):SetText(self.tSettings.LootTimer .." sec")
	
	self:SetOptions()
end


function KuronaBags:ApplySizeSettings( wndHandler, wndControl, eMouseButton )
	self.tSettings.Rows = self.RowSlider:GetValue()
	self.tSettings.Columns = self.ColumnSlider:GetValue()
	local oldCount = self.tSettings.MaxVirtualSlots
	self.tSettings.MaxVirtualSlots = self.tSettings.Columns * self.tSettings.Rows
	self.tSettings.IconSize = self.IconSizeSlider:GetValue()
	local iconsize = self.tSettings.IconSize
	local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
	local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
	
	local l,t,r,b = self.BagForm:GetAnchorOffsets()	
	if wndHandler ~=nil then
		self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
	elseif not self.tSettings.AllowResizeBag then
		self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
	end
	
		--NVBag
--	local l,t,r,b = self.NVB:GetAnchorOffsets()
	if 	not self.tSettings.bEnableVB then
		self.NVB:SetAnchorOffsets(0,0,width,height)
		self.NVB:SetSquareSize(iconsize,iconsize)
		self.BagForm:FindChild("BagHolder"):Show(false)
		self.NVB:SetBoxesPerRow(self.tSettings.Columns)
		self.BagForm:FindChild("NewBagButton"):Show(false)
		self.BagForm:FindChild("AutoSortButton"):Show(false)
		self.BagForm:FindChild("NewBagButton"):Enable(false)
		self.BagForm:FindChild("AutoSortButton"):Enable(false)
	end
--	self.ClosedBagRack:Show(false)
--	self:OpenExtraBags(false)

	
	if self.tSettings.bEnableVB then
		self:AdjustVirtualBagSlotCount(oldCount)
	
	
	for i = 1, self.tSettings.MaxVirtualSlots do
		if self.BagSlots[i] then
			local l,t,r,b = self.BagSlots[i]:GetAnchorOffsets()
			self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)		
		end
	end
	self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)

	local Quality = {
	[1] = "All",
	[2] = "Common",
	[3] = "Uncommon",
	[4] = "Rare",
	[5] = "Epic",
	[6] = "Legendary",
	[7] = "Artifact",
	}
--	self.LootOptions:FindChild("Loot Notifications"):SetText(Quality[quality])
	self:ShowHideCurrency()
	
	for i = 1, #self.ExtraBags do
		local height =  self.ExtraBags[i].rows * self.tSettings.IconSize
		local width = self.ExtraBags[i].cols * self.tSettings.IconSize
		self.ExtraBags[i].Bag:SetAnchorOffsets(self.ExtraBags[i].l,self.ExtraBags[i].t,self.ExtraBags[i].l+width+34,self.ExtraBags[i].t+height+55)
		
		local clist = self.ExtraBags[i].Bag:FindChild("BagHolder"):GetChildren()
		for x=1,#clist do
			clist[x]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)		
		end
		self.ExtraBags[i].Bag:FindChild("BagHolder"):ArrangeChildrenTiles(0)
	end	
	end
	self:UpdateQuestBag()
	Apollo.CreateTimer("RedrawTimer", 0.2, false)

end

function KuronaBags:OnGenericEvent_SplitItemStack(item)
	if not item then 
		return 
	end
	
	local nStackCount = item:GetStackCount()
	if nStackCount < 2 then
		self.wndSplit:Show(false)
		return
	end
	self.wndSplit:Invoke()
	local tMouse = Apollo.GetMouse()
	self.wndSplit:Move(tMouse.x - math.floor(self.wndSplit:GetWidth() / 2) , tMouse.y - 20 - self.wndSplit:GetHeight(), self.wndSplit:GetWidth(), self.wndSplit:GetHeight())

	self.wndSplit:SetData(item)
	self.wndSplit:FindChild("SplitValue"):SetValue(1)
	self.wndSplit:FindChild("SplitValue"):SetMinMax(1, nStackCount - 1)
	self.wndSplit:Show(true)
end

function KuronaBags:OnSplitStackCloseClick()
	self.wndSplit:Show(false)
end

function KuronaBags:OnSpinnerChanged()
	local wndValue = self.wndSplit:FindChild("SplitValue")
	local nValue = wndValue:GetValue()
	local itemStack = self.wndSplit:GetData()
	local nMaxStackSplit = itemStack:GetStackCount() - 1

	if nValue < 1 then
		wndValue:SetValue(1)
	elseif nValue > nMaxStackSplit then
		wndValue:SetValue(nMaxStackSplit)
	end
end


function KuronaBags:OnSplitStackConfirm(wndHandler, wndCtrl)
	self.wndSplit:Close()
	self.JustSplitStack = true
	self.OBW:StartSplitStack(self.wndSplit:GetData(), self.wndSplit:FindChild("SplitValue"):GetValue())
	self.SalvageButton:Enable(false)
end


function KuronaBags:FindFirstUsableSlot(bag)
	if bag ~= nil then
		local clist = bag:FindChild("BagHolder"):GetChildren()
		for x=1,#clist do
			if clist[x]:GetChildren()[1]:GetData() == nil then
				return tonumber(clist[x]:GetName())
			end
		end
	end
	
	for i =1, self.tSettings.MaxVirtualSlots  do
		if self.BagSlots[i]:GetChildren()[1]:GetData() == nil then
			return i
		end
	end
	return false
end


function KuronaBags:FindLastFreeSlot()
	for i =self.tSettings.MaxVirtualSlots, 1, -1   do
		if self.BagSlots[i]:GetChildren()[1]:GetName() == "9999" then
			return i
		end
	end
	return false
end

function KuronaBags:FindFirstVirtualSlot()
if self.BagSlots == nil then return end
	for i =1, self.tSettings.MaxVirtualSlots  do
		if self.BagSlots[i]:GetChildren()[1]:GetName() == "9999" then
			return i
		end
	end
	return false
end

function KuronaBags:FindFirstVirtualSlotInRange(startR,endR)
	for i =startR, endR do
		if self.BagSlots[i]:GetChildren()[1]:GetData() == nil then
			return i
		end
	end
	return false
end



function KuronaBags:OnSettingsChanged( wndHandler, wndControl, eMouseButton )
	self.tSettings.AutoSellJunk =  self.OptionsWindow:FindChild("AutoSellButton"):IsChecked()
	self.tSettings.AutoSellAmps =  self.OptionsWindow:FindChild("AutoSellAmpsButton"):IsChecked()
	self.tSettings.AutoRepair =  self.OptionsWindow:FindChild("AutoRepairButton"):IsChecked()
	self.tSettings.GuildRepair =  self.OptionsWindow:FindChild("GuildRepairButton"):IsChecked()
	self.tSettings.AutoOpenBags =  self.OptionsWindow:FindChild("AutoOpenBags"):IsChecked()
	self.tSettings.AllowResizeBag =  self.OptionsWindow:FindChild("AllowResizeBag"):IsChecked()
	self.OptionsWindow:FindChild("GuildRepairButton"):Enable(self.tSettings.AutoRepair)
	
	self.tSettings.ItemTrail =  self.OptionsWindow:FindChild("ItemTrailButton"):IsChecked()
	self.tSettings.bAutoCompact =  self.OptionsWindow:FindChild("AutoCompactButton"):IsChecked()
	if self.tSettings.bShowQuestItems and not self.OptionsWindow:FindChild("QuestItemsButton"):IsChecked() then
		for i=1, #self.ClosedBagRack:GetChildren() do
			local button = self.ClosedBagRack:GetChildren()[i]
			if button and button:GetData() == self.QuestBag then			
				button:Destroy()
			end
			self.ClosedBagRack:ArrangeChildrenHorz()
		end	
		if self.QuestBag then
			self.tSettings.QuestBagLeft,self.tSettings.QuestBagTop = self.QuestBag:GetAnchorOffsets()
			self.QuestBag:Destroy()
		end
		self.QuestBag = nil
		self.QuestBagLeft = nil
		self.QuestBagTop = nil
	end
	self.tSettings.bShowQuestItems =  self.OptionsWindow:FindChild("QuestItemsButton"):IsChecked()

	
	local NVSet = self.OptionsWindow:FindChild("EnableVirtualInventory"):IsChecked()
	
	-- Enable VB
	if NVSet and not self.tSettings.bEnableVB then
		self.CurrentSlot = 1
		self:ResizeVBag()
		self.tSettings.bEnableVB =  self.OptionsWindow:FindChild("EnableVirtualInventory"):IsChecked()
		self.NVB:Show(false)
		self.NVB:GetParent():Show(false)
		self.TotalSlots:Show(true)
		self.BagForm:FindChild("BagHolder"):Show(true)
		self.NVB:SetBoxesPerRow(self.tSettings.Columns)
		self.BagForm:FindChild("NewBagButton"):Show(true)
		self.BagForm:FindChild("AutoSortButton"):Show(true)
		self.BagForm:FindChild("NewBagButton"):Enable(true)
		self.BagForm:FindChild("AutoSortButton"):Enable(true)
		self.BagForm:FindChild("ResetButton"):Show(true)
		self.MainBagFilterButton:Show(false)
		--self.BagForm:FindChild("SearchBox"):Show(true)
		self:Restart()
		self.RowSlider:GetParent():GetParent():Show(true)
	-- Disable VB
	elseif not NVSet and self.tSettings.bEnableVB then
		self.CurrentSlot = 1
		self.tSettings.bEnableVB =  self.OptionsWindow:FindChild("EnableVirtualInventory"):IsChecked()
		local height =  self.RowSlider:GetValue() * self.tSettings.IconSize
		local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
		self.RealRemap = nil
		self.BagSlots = nil
		self.BagSlotCounts = nil 
		self.NVB:GetParent():Show(true)
		self.NVB:Show(true)
		self.TotalSlots:Show(false)
		self.NVB:SetAnchorOffsets(0,0,width,height)
		self.NVB:SetSquareSize(self.tSettings.IconSize,self.tSettings.IconSize)
		self.BagForm:FindChild("BagHolder"):Show(false)
		self.NVB:SetBoxesPerRow(self.tSettings.Columns)
		self.BagForm:FindChild("NewBagButton"):Show(false)
		self.BagForm:FindChild("AutoSortButton"):Show(false)
		self.BagForm:FindChild("NewBagButton"):Enable(false)
		self.BagForm:FindChild("AutoSortButton"):Enable(false)
		self.BagForm:FindChild("ResetButton"):Show(false)
		--self.BagForm:FindChild("SearchBox"):Show(false)
		self.RowSlider:GetParent():GetParent():Show(false)
--		self.ClosedBagRack:Show(false)
		self.MainBagFilterButton:Show(true)
		self:OpenExtraBags(false)
		if self.ExtraBags then
			for i = 1, #self.ExtraBags do
				self.ExtraBags[i].Bag:Destroy()
			end
		end
		--self.ExtraBags = {}
		self.ClosedBagRack:DestroyChildren()
		self:ResizeNVBag()
	end
	
	--Radios
	self.tSettings.nSortType = self.BagSortWindow:GetRadioSel("SortChecks")
	self.tSettings.bEnableVB =  self.OptionsWindow:FindChild("EnableVirtualInventory"):IsChecked()
	
	if not self.tSettings.bEnableVB then
		if self.tSettings.nSortType ~= 1 then
			self.NVB:SetSort(true)
			self.NVB:SetItemSortComparer(ktSortFunctions[self.tSettings.nSortType])
		else
			self.NVB:SetSort(false)
		end
	end

	self:UpdateQuestBag()
	self:OnPreventSalvage()
	self:Redraw()
end


function KuronaBags:SmashStacks()
	local itemList = {}
	local stackstosmash = 0
	for i = self.MaxBagSlots,1, -1 do

		local item = GameLib.GetBagItem(i)
		if item then
			if item:GetMaxStackCount() > 1 then
				if itemList[item:GetItemId()] == nil then
					itemList[item:GetItemId()] = {}
				end
				if item:GetStackCount() < item:GetMaxStackCount() then
					table.insert(itemList[item:GetItemId()],i)
				end
			end
		end		
	end
	for k,v in pairs(itemList) do
		if #itemList[k] > 1 then
			GameLib.SwapBagItems(itemList[k][1],itemList[k][2])
			self.NeedToSmash = true
			break
		end
	end
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(self.NeedToSmash)
	for i = 1, #self.ExtraBags do
		self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(self.NeedToSmash)
	end
		
	if not self.NeedToSmash then
		self:CompactAll()
	end
end


function KuronaBags:ShowHideCurrency()
	local width =  self.BagForm:GetWidth()
	self.CraftingCashWindow:Show(width > 335)
	self.PrestigeCashWindow:Show(width > 345)
--	self.ElderGemCashWindow:Show(width > 240)
--	self.RenownCashWindow:Show(width > 420)
end

function KuronaBags:OnEffectiveLevelChange()
	if self.BagSlots == nil then return end
	if self.tSettings.bEnableVB then
		for i = 1, self.MaxBagSlots do
			local item = GameLib.GetBagItem(i)
			local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
			if item then
				local canUse = self:CantUseItem(item)
				local quest = item:GetGivenQuest()
				self:SetCantUseIcon(slot,canUse,quest)
			end
		end
	end
end


function KuronaBags:CreateNewBag()
	if self.ExtraBags == nil then
		self.ExtraBags = {}
	end

	local rows = 2
	local cols = 5
	
	local newBagTable = self:DefaultBagTable()
	
	local newBagRange = self:FindFreeRange()
	if newBagRange == nil then Print("Bag limit reached") return end

	
	nStart = (newBagRange) + 1
	nEnd = nStart + (rows * cols) - 1
	
	newBagTable.nStart = nStart
	newBagTable.nEnd = nEnd
	
	table.insert(self.ExtraBags,newBagTable)
	self:SetupNewBag(#self.ExtraBags,true)
	
	Apollo.StopTimer("RedrawTimer")
	Apollo.CreateTimer("RedrawTimer", 0.5, false)
end


function KuronaBags:FindFreeRange()
	local newBagRange = 500
	local noBag = true
	for i = 5, 20 do
		local free = true
	
		for x=1, #self.ExtraBags do
			if not free then break end
			
			if self.ExtraBags[x].nStart == (i*100+1) then
				free = false
				break
			end
		end
		if free then newBagRange = i * 100 noBag = false break end
	end
	if not noBag then
		return newBagRange
	end
end


function KuronaBags:DefaultBagTable()
	local defaultbagtable ={
		rows = 2,
		cols = 5,
		name = "New Bag",
		mini = false,
		psalvage = false,
		sortphase = ""
	}
	return defaultbagtable
end


function KuronaBags:SetupNewBag(nBag,bisnew)
	local newBag = Apollo.LoadForm(self.xmlDoc, "ExtraBagForm", nil, self)
	self.ExtraBags[nBag].Bag = newBag

	--Assign default values to new/old bags
	local defaultTable = self:DefaultBagTable()
	
		for k,v in pairs(defaultTable) do
			if self.ExtraBags[nBag][k] ==  nil then
				self.ExtraBags[nBag][k] = v
			end	
		end

	newBag:FindChild("ColumnSliderBar"):SetValue(self.ExtraBags[nBag].cols)
	newBag:FindChild("RowSliderBar"):SetValue(self.ExtraBags[nBag].rows)
	newBag:FindChild("Columns"):SetText(self.ExtraBags[nBag].cols)
	newBag:FindChild("Rows"):SetText(self.ExtraBags[nBag].rows)	
	newBag:FindChild("PreventSalvageButton"):SetCheck(self.ExtraBags[nBag].psalvage)
	newBag:FindChild("PinButton"):SetCheck(self.ExtraBags[nBag].pinned)
	newBag:FindChild("BagNameEditBox"):SetText(self.ExtraBags[nBag].name)	
	newBag:FindChild("ItemSortEditBox"):SetText(self.ExtraBags[nBag].sortphase)	
	
	local bagwindow = newBag:FindChild("BagWindow")
	
	--resize the new bag
	local height =  self.ExtraBags[nBag].rows * self.tSettings.IconSize
	local width = self.ExtraBags[nBag].cols * self.tSettings.IconSize
		
	if self.ExtraBags[nBag].l == nil then
	local rand = math.random(-40,40)
		self.ExtraBags[nBag].l,self.ExtraBags[nBag].t,self.ExtraBags[nBag].r,self.ExtraBags[nBag].b = self.ExtraBags[nBag].Bag:GetAnchorOffsets()
		self.ExtraBags[nBag].l=self.ExtraBags[nBag].l+rand
		self.ExtraBags[nBag].t=self.ExtraBags[nBag].t+rand
	end
	
	newBag:SetAnchorOffsets(self.ExtraBags[nBag].l,self.ExtraBags[nBag].t,self.ExtraBags[nBag].l+width+34,self.ExtraBags[nBag].t+height+50)
	self:PopulateExtraBags(self.ExtraBags[nBag].nStart,self.ExtraBags[nBag].nEnd,newBag)
	
	--adjust onebagslot positions
	bagwindow:SetSquareSize(iconsize,iconsize)
	bagwindow:SetBoxesPerRow(self.MaxBagSlots)
	local iconsize = self.tSettings.IconSize	
	bagwindow:SetAnchorOffsets(0,0,(self.MaxBagSlots*iconsize),iconsize)
	self.ExtraBags[nBag].Bag:FindChild("BagName"):SetText(self.ExtraBags[nBag].name)
	
	if self.ExtraBags[nBag].mini then
		self:MinimizeBag(newBag)
	end
	newBag:Show(bisnew,false)
end


function KuronaBags:PopulateExtraBags(nStart,nEnd,tBag)
	tBag:FindChild("OptionsButton"):AttachWindow(	tBag:FindChild("ExtraBagOptions"))
	tBag:FindChild("SortButton"):AttachWindow(	tBag:FindChild("BagFilterOptions"))
	tBag:FindChild("BagHolder"):DestroyChildren()
	--tBag:Show(true)
	tBag:FindChild("BagWindow"):SetCannotUseSprite("ClientSprites:LootCloseBox")
	
	for i = nStart, nEnd do
		self.BagSlots[i] = Apollo.LoadForm(self.xmlDoc, "BagItem", tBag:FindChild("BagHolder"), self)
		self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
		self.BagSlots[i]:SetName(i)
		self.BagSlotCounts[i] = 0 
		self.BagSlots[i]:GetChildren()[1]:SetName(9999)
		if self.Debug then			self.BagSlots[i]:GetChildren()[1]:SetText(9999) end
	end
	tBag:FindChild("BagHolder"):ArrangeChildrenTiles(0)
end

function KuronaBags:OnRenameBag( wndHandler, wndControl, strNewText, strOldText, bAllowed )
	local bag = wndHandler:GetParent():GetParent():GetParent()
	bag:FindChild("BagName"):SetText(strNewText)
	self.ExtraBags[self:FindExtraBag(bag)].name = strNewText
end

function KuronaBags:OnSortPhaseChanged( wndHandler, wndControl, strNewText, strOldText, bAllowed )
	local bag = wndHandler:GetParent():GetParent():GetParent()
	local len = strNewText:len()
	self.ExtraBags[self:FindExtraBag(bag)].sortphase = string.gsub(strNewText,"-", " ")
	self.ExtraBags[self:FindExtraBag(bag)].sortphase = string.gsub(strNewText,"-", " ")
end


function KuronaBags:FindExtraBag(bag)
	for i = 1, #self.ExtraBags do
		if bag == self.ExtraBags[i].Bag then
			return i
		end
	end

end

function KuronaBags:OnSortTypeChange( wndHandler, wndControl, eMouseButton )
	local bag = wndHandler:GetParent():GetParent()
	local bagNum = self:FindExtraBag(bag)

end

function KuronaBags:OnSortComboBoxChange( wndHandler, wndControl )
	local bag = wndHandler:GetParent():GetParent():GetParent()
	local bagNum = self:FindExtraBag(bag)
end

function KuronaBags:ExtraWindowOpened( wndHandler, wndControl )
	local bag = wndHandler:GetParent()
	if wndHandler:GetName() == "ExtraBagOptions" then
		bag:FindChild("SortButton"):SetCheck(false)	
	elseif wndHandler:GetName() == "BagFilterOptions" then
		bag:FindChild("OptionsButton"):SetCheck(false)
	
	end
end


function KuronaBags:OnExtraSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	wndHandler:GetParent():GetParent():SetText(fNewValue)
	local bag = wndHandler:GetParent():GetParent():GetParent():GetParent()
	local bagNum = self:FindExtraBag(bag)
	
	local oldCount = self.ExtraBags[bagNum].rows * self.ExtraBags[bagNum].cols
	self.ExtraBags[bagNum].l,self.ExtraBags[bagNum].t = bag:GetAnchorOffsets()

	if wndHandler:GetName() == "ColumnSliderBar" then
		self.ExtraBags[bagNum].cols = fNewValue
	elseif wndHandler:GetName() == "RowSliderBar" then
		self.ExtraBags[bagNum].rows = fNewValue
	end
	local newCount = self.ExtraBags[bagNum].rows * self.ExtraBags[bagNum].cols

	self.ExtraBags[bagNum].nEnd = 	self.ExtraBags[bagNum].nStart + (self.ExtraBags[bagNum].rows * self.ExtraBags[bagNum].cols) - 1
	
	local height =  self.ExtraBags[bagNum].rows * self.tSettings.IconSize
	local width = self.ExtraBags[bagNum].cols * self.tSettings.IconSize
	self.ExtraBags[bagNum].Bag:SetAnchorOffsets(self.ExtraBags[bagNum].l,self.ExtraBags[bagNum].t,self.ExtraBags[bagNum].l+width+34,self.ExtraBags[bagNum].t+height+55)
	
	self:AdjustExtraBagSlotCount(oldCount,newCount,self.ExtraBags[bagNum].Bag,self.ExtraBags[bagNum].nStart)
	
end


function KuronaBags:AdjustExtraBagSlotCount(oldCount,newCount,bag,nstart)
	--add more to self.BagSlots
	local bagHolder = bag:FindChild("BagHolder")
	if newCount > oldCount then
		local diff = newCount - oldCount

		for i = nstart+oldCount, nstart+newCount-1 do
			self.BagSlots[i] = Apollo.LoadForm(self.xmlDoc, "BagItem", bagHolder, self)
			self.BagSlots[i]:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
			self.BagSlots[i]:SetName(i)
			self.BagSlots[i]:GetChildren()[1]:SetName(9999)
			if self.Debug then self.BagSlots[i]:GetChildren()[1]:SetText("BS"..i) end
		end
	elseif oldCount > newCount then
		local diff = oldCount - newCount
		local killcount = 0
		local LostEmptySlots = {}
		
		for i = oldCount,newCount+1, -1 do
			local slot = bagHolder:GetChildren()[i]:GetChildren()[1]
			if slot:GetName() ~= "9999" then
				table.insert(LostEmptySlots,tonumber(slot:GetName()))
			end
			bagHolder:GetChildren()[i]:Destroy()
		end
		
		--find a home for deleted items
		for i = 1, #LostEmptySlots do
--			self:CreateNewSlot()

			local slotNum = self:FindFirstUsableSlot()

			if not slotNum then
				slotNum = self:FindFirstVirtualSlot()
			end

			local slot = self.BagSlots[slotNum]:GetChildren()[1]
			local item = GameLib.GetBagItem(LostEmptySlots[i])
			self:MakeItem(item, slot,LostEmptySlots[i])
			self.RealRemap[LostEmptySlots[i]]=tonumber(slotNum)
			slot:SetName(LostEmptySlots[i])
		end
		
	end
	bagHolder:ArrangeChildrenTiles(0)
end


function KuronaBags:OpenExtraBags(state)
	if self.ExtraBags then
		for i = 1, #self.ExtraBags do
			if not self.ExtraBags[i].mini then
				if not self.ExtraBags[i].pinned then
					self.ExtraBags[i].Bag:Show(state,false)
					self.ExtraBags[i].Bag:FindChild("ToolBar"):FindChild("OptionsButton"):SetCheck(false)
					self.ExtraBags[i].Bag:FindChild("ToolBar"):FindChild("SortButton"):SetCheck(false)
					self.ExtraBags[i].Bag:ToFront()
				elseif self.ExtraBags[i].pinned and state then
					self.ExtraBags[i].Bag:Show(state,false)
					self.ExtraBags[i].Bag:FindChild("ToolBar"):FindChild("OptionsButton"):SetCheck(false)
					self.ExtraBags[i].Bag:FindChild("ToolBar"):FindChild("SortButton"):SetCheck(false)
					self.ExtraBags[i].Bag:ToFront()
				end
			end
		end
	end
end


function KuronaBags:DestroyVirtualBag( wndHandler, wndControl)
	local bag = wndHandler:GetParent():GetParent()
	local bagNum = self:FindExtraBag(bag)
	local bagHolder = bag:FindChild("BagHolder")

	self:ClearBag(wndHandler,wndControl)

	table.remove(self.ExtraBags,bagNum)
	bag:Destroy()
	
	Apollo.StopTimer("RedrawTimer")
	Apollo.CreateTimer("RedrawTimer", 0.5, false)

end


function KuronaBags:ClearBag( wndHandler, wndControl )
	local bag = wndHandler:GetParent():GetParent()
	local bagNum = self:FindExtraBag(bag)
	local bagHolder = bag:FindChild("BagHolder")

	self:AdjustExtraBagSlotCount(#bagHolder:GetChildren(),0,self.ExtraBags[bagNum].Bag,self.ExtraBags[bagNum].nStart)
	self:PopulateExtraBags(self.ExtraBags[bagNum].nStart,self.ExtraBags[bagNum].nEnd,bag)
--	Apollo.StopTimer("RedrawTimer")
--	Apollo.CreateTimer("RedrawTimer", 0.1, false)
	self:Redraw()
	if self.Debug then
		self:DebugDraw()
	end
end


function KuronaBags:OpenExtraBag( wndHandler, wndControl, eMouseButton )
	local bag = wndHandler:GetData()
	bag:Show(true,false)
	bag:ToFront()
	wndHandler:Destroy()
	self.ClosedBagRack:ArrangeChildrenHorz()
	if self.tSettings.bEnableVB and bag ~= self.QuestBag then
		local num = self:FindExtraBag(bag)
		self.ExtraBags[num].mini = false
	end
end

function KuronaBags:CloseBag( wndHandler, wndControl, eMouseButton)
	local bag = wndHandler:GetParent():GetParent()
	self:MinimizeBag(bag)
end

function KuronaBags:MinimizeBag(bag)
	local newButton = Apollo.LoadForm(self.xmlDoc, "OpenBagButton", self.ClosedBagRack, self)
	newButton:SetData(bag)
	local name = bag:FindChild("BagName"):GetText()
	newButton:SetText(name)
	newButton:SetAnchorOffsets(0,0,string.len(name)*8+50,25)
	--self.ClosedBagRack:BringChildToTop(newButton)
	bag:Show(false,false)
	self.ClosedBagRack:ArrangeChildrenHorz()
	if self.tSettings.bEnableVB and bag ~= self.QuestBag then
		local num = self:FindExtraBag(bag)
		self.ExtraBags[num].mini = true
	end
	if bag == self.QuestBag then
		newButton:SetBGColor("xkcdAmber")
	end
	return
end

--This function is mostly lifted from VinceBuilds. Thanks Vince!
function KuronaBags:HookIntoImprovedSalvage()
	--local improvedSalvage = self.KSalvage-- Apollo.GetAddon("KuronaSalvage")
	if self.KuronaSalvage then	
		local orig = self.KuronaSalvage.OnSalvageAll
		self.KuronaSalvage.OnSalvageAll = function(...)
			orig(...)
			local preventSalvage = self.PreventSalvageList
			for i = #self.KuronaSalvage.arItemList, 1, -1 do
				local item = self.KuronaSalvage.arItemList[i]
				if item and preventSalvage[item:GetItemId()] then
					table.remove(self.KuronaSalvage.arItemList, i)
				end
--				if item and self.tSettings.tHideSalvage[item:GetItemId()] then
--					table.remove(improvedSalvage.arItemList, i)
--				end
			end
			self.KuronaSalvage:RedrawAll()
		end
	end
--self.KSalvage = nil
end

function KuronaBags:AutoSlotRepair()
	for i = 1, self.MaxBagSlots do
		local item = GameLib.GetBagItem(i)
		local slotData = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]:GetData()
		
		if self.RealRemap[i] == nil then
--			Print("AS : Self.Remap "..i.." is nil")
			self:Restart()
--			self:AutoSort()
			return
		end			
		if self.BagSlots[self.RealRemap[i]] == nil then
--			Print("AS : Invalid Bag slot "..self.RealRemap[i])
			self:Restart()
	--		self:AutoSort()
			return
		end
		
		if item ~= nil and slotData == nil then
--			Print(i.." "..item:GetName() .. "1. A database corruption has occured in KuronaBags. I've reset your item positions. Sorry!")
			self:Restart()
		--	self:AutoSort()
			return
		end
		
		if item == nil and slotData ~= nil then
--			Print(i.." "..slotData:GetName().." 2. A database corruption has occured in KuronaBags. I've reset your item positions. Sorry!")
			self:Restart()
--			self:AutoSort()
			return
		end
	end
end


function KuronaBags:AutoSort()
local removedSlots = 0 
	for i = 1, self.tSettings.MaxVirtualSlots do
		local slot = self.BagSlots[i]:GetChildren()[1]
		local item = slot:GetData()
		if item then
			local slotNum = self:FindBagForItem(item)
			if slotNum > 400 then
				slot:GetParent():GetChildren()[3]:Show(false,true)
				self:SwapItems(slot,self.BagSlots[slotNum]:GetChildren()[1])
				removedSlots = removedSlots + 1
			end
		end
	end
	
	if self.tSettings.bAutoPrune then
		local oldCount = self.tSettings.MaxVirtualSlots
		self.tSettings.MaxVirtualSlots = self.tSettings.MaxVirtualSlots - removedSlots
		self:AdjustVirtualBagSlotCount(oldCount)
		--self.BagForm:FindChild("BagHolder"):ArrangeChildrenTiles(0)

		self:SizeBag()
	end
	if self.tSettings.bAutoCompact then
		self:StartCompact()
	end	
end

function KuronaBags:SizeBag()
	local rowsNeeded = math.ceil(self.tSettings.MaxVirtualSlots / self.tSettings.Columns)
	local height =  rowsNeeded * self.tSettings.IconSize
	local width = self.ColumnSlider:GetValue() * self.tSettings.IconSize
	
	local l,t,r,b = self.BagForm:GetAnchorOffsets()
	self.BagForm:SetAnchorOffsets(l,t,l+width+34,t+height+95)
end



function KuronaBags:BagSlotCountChanged(capacity,currentMax)
	if capacity > currentMax then
		--add some slots
		for i = currentMax+1, capacity do	
			local slotNum = self:FindFirstVirtualSlot()
			local slot = self.BagSlots[slotNum]:GetChildren()[1]
			slot:SetName(i)
			if self.Debug then slot:SetText(i) end
			self.RealRemap[i] = tonumber(slot:GetParent():GetName())
			if self.Debug then Print("making slot ".. i.. " at " .. self.RealRemap[i]) end
		end
	
	elseif currentMax > capacity then
		--remove some slots	
		for i = capacity+1, currentMax do
			local slot = self.BagSlots[self.RealRemap[i]]:GetChildren()[1]
			self:RemoveItem(nil,slot,9999)
			slot:SetName(9999)
			self.RealRemap[i] = nil
			if self.Debug then Print("Removing item slot ".. i) end
		end
	end
end

function KuronaBags:ExternalSearch(wndHandler)
	if self.CX and self.CX.wndMain and  self.CX.wndMain:FindChild("SearchEditBox") then
		local searchbox = self.CX.wndMain:FindChild("SearchEditBox")
		if searchbox then
			searchbox:SetText(wndHandler:GetData():GetName())
			self.CX:OnSearchCommitBtn()
		end
	elseif self.AH  and self.AH.wndMain and self.AH.wndMain:FindChild("SearchEditBox") then
		local searchbox = self.AH.wndMain:FindChild("SearchEditBox")
		if searchbox then
			searchbox:SetText(wndHandler:GetData():GetName())
			self.AH:OnSearchCommitBtn()
		end
	elseif self.TradeSkill and self.TradeSkill.wndMain then
		local searchbox = self.TradeSkill.wndMain:FindChild("SearchTopLeftInputBox")
		local ts = Apollo.GetAddon("TradeskillSchematics")
		if ts and searchbox then
			self.TradeSkill.wndMain:SetRadioSel("TradeskillContainer_TopTabBtn_LocalRadioGroup", 1)
			searchbox:SetText(wndHandler:GetData():GetName())
			ts:OnSearchTopLeftInputBoxChanged()
		end
	end
end


function KuronaBags:Compact(startR,endR)
	for i = startR, endR do
		if self.BagSlots[i]:GetChildren()[1]:GetData() then 
			local slot = self:FindFirstVirtualSlotInRange(startR,endR)
			if slot and slot < i then
				self:SwapItems(self.BagSlots[i]:GetChildren()[1],self.BagSlots[slot]:GetChildren()[1])
				self.NeedToCompact = true
			end
		end
	end
	
	self.BagForm:FindChild("DragDropMouseBlocker"):Show(self.NeedToCompact or false)
	for i = 1, #self.ExtraBags do
		self.ExtraBags[i].Bag:FindChild("DragDropMouseBlocker"):Show(self.NeedToCompact or false)
	end

	if self.NeedToCompact then
		self.NeedToCompact = false
		self:Compact(startR,endR)
		return
	end
end

function KuronaBags:StartCompact()
	self.CompactStarted = true
	self:CompactAll()
	self:SmashStacks()
end


function KuronaBags:CompactAll()
	--Main bag
	self:Compact(1,self.tSettings.MaxVirtualSlots)
	
	for i = 1, #self.ExtraBags do
		self:Compact(self.ExtraBags[i].nStart,self.ExtraBags[i].nEnd)
	end
end


--Quest Bag

function KuronaBags:CreateQuestBag()
	local questBag = Apollo.LoadForm(self.xmlDoc, "ExtraBagForm", nil, self)
	self.QuestBag = questBag
	self.QuestBag:FindChild("ExtraBagOptions"):Destroy()
	self.QuestBag:FindChild("OptionsButton"):Destroy()
	self.QuestBag:FindChild("SortButton"):Destroy()
	self.QuestBag:FindChild("PinButton"):Show(false)
	self.QuestBag:FindChild("BagName"):SetText("Quest")
	--self.QuestBag:SetName("Quest")
	if tonumber(self.tSettings.QuestBagLeft) then	
		self.QuestBag:SetAnchorOffsets(self.tSettings.QuestBagLeft,self.tSettings.QuestBagTop,self.tSettings.QuestBagLeft+100,self.tSettings.QuestBagTop+100)
	end

	
	self.tSettings.QuestBagLeft,self.tSettings.QuestBagTop = self.QuestBag:GetAnchorOffsets()
	
	self:MinimizeBag(questBag)
	self:UpdateQuestBag()
end

function KuronaBags:OnQuestObjectiveUpdated()
	if self.tSettings.bShowQuestItems then
		self:UpdateQuestBag()
	end
end

function KuronaBags:UpdateQuestBag()
	local tVirtualItems = Item.GetVirtualItems()
	local bThereAreItems = #tVirtualItems > 0

	if not self.tSettings.bShowQuestItems then
		bThereAreItems = false
	end
	
	if bThereAreItems then
		if not self.QuestBag then
			self:CreateQuestBag()
			
		end
		local nOnGoingCount = 0
		local questBag = self.QuestBag:FindChild("BagHolder")
		questBag:DestroyChildren()
		
		for key, tCurrItem in pairs(tVirtualItems) do
			local wndCurr =  Apollo.LoadForm(self.xmlDoc, "QuestItem", questBag, self)
			if tCurrItem.nCount > 1 then
				wndCurr:GetChildren()[1]:UpdatePixie(4,{
				strText = tostring(tCurrItem.nCount),
				strFont = "CRB_Header9_O",
				bLine = false,
				strSprite = "",
				cr = "FFFFFFFF",
				loc = {
				fPoints = {0,0,1,1},
				nOffsets = {4,4,-5,5}
				},
				flagsText = {
				DT_RIGHT = true,
				}
				})			
			end
			nOnGoingCount = nOnGoingCount + tCurrItem.nCount
			wndCurr:GetChildren()[1]:SetSprite(tCurrItem.strIcon)
			wndCurr:GetChildren()[1]:SetTooltip(string.format("<P Font=\"CRB_InterfaceSmall\">%s</P><P Font=\"CRB_InterfaceSmall\" TextColor=\"aaaaaaaa\">%s</P>", tCurrItem.strName, tCurrItem.strFlavor))
			self:SetQualityFrame(wndCurr:GetChildren()[1],2)
			wndCurr:SetAnchorOffsets(0,0,self.tSettings.IconSize,self.tSettings.IconSize)
		end			
		questBag:ArrangeChildrenTiles()
		
		local width = 40 + (self.tSettings.IconSize * #tVirtualItems)
		local height = self.tSettings.IconSize + 50
		self.QuestBag:SetAnchorOffsets(self.tSettings.QuestBagLeft,self.tSettings.QuestBagTop,self.tSettings.QuestBagLeft+width,self.tSettings.QuestBagTop+height)
	end
	if not bThereAreItems and self.QuestBag then
		self.tSettings.QuestBagLeft,self.tSettings.QuestBagTop = self.QuestBag:GetAnchorOffsets()
		for i=1, #self.ClosedBagRack:GetChildren() do
			local button = self.ClosedBagRack:GetChildren()[i]
			if button and button:GetData() == self.QuestBag then
				button:Destroy()
			end
			self.ClosedBagRack:ArrangeChildrenHorz()
		end
		self.QuestBag:Destroy()
		self.QuestBag = nil
	end
end



function KuronaBags:OnWindowResized( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.needArrange = true
	Apollo.StopTimer("RedrawTimer")
	Apollo.CreateTimer("RedrawTimer", 0.15, false)
end

function KuronaBags:ListBankItems()
	for i = 512, 1000 do
		if self.BankBagForm:FindChild("BankWindow"):GetItem(i) then	
			Print(self.BankBagForm:FindChild("BankWindow"):GetItem(i):GetName())
		end
	end
end