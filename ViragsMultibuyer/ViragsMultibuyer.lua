-----------------------------------------------------------------------------------------------
-- Client Lua Script for ViragsMultibuyer
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ViragsMultibuyer Module Definition
-----------------------------------------------------------------------------------------------
local ViragsMultibuyer= {} 
local kstrTabBuy     	= "VendorTab0"
local kstrTabSell    	= "VendorTab1"
local kstrTabBuyback 	= "VendorTab2"
local kstrTabRepair  	= "VendorTab3"
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local MAX_COUNT = 750
local parent = "Vendor"
local warningForm = "WarningForm" 
local vendorAddon
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ViragsMultibuyer:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function ViragsMultibuyer:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"Vendor", 
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ViragsMultibuyer OnLoad
-----------------------------------------------------------------------------------------------
function ViragsMultibuyer:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("ViragsMultibuyer.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ViragsMultibuyer OnDocLoaded
-----------------------------------------------------------------------------------------------
function ViragsMultibuyer:OnDocLoaded()
	vendorAddon = Apollo.GetAddon(parent)
	vendorAddon.tempOnInvokeVendorWindow = vendorAddon.OnInvokeVendorWindow
	vendorAddon.OnInvokeVendorWindow = self.OnInvokeVendorWindowHook		
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterEventHandler("ViragsMultibuyer", "OnPatchedVendorBuyOn", self)
		Apollo.RegisterEventHandler("CloseVendorWindow",	"OnCancel", self)
		vendorAddon.FinalizeBuy = self.FinalizeBuy
		vendorAddon.OnVendorListItemMouseDown = self.OnVendorListItemMouseDown
		if self.tConfig == nil then
			self.tConfig = {bAlwaysShow = false, 	bNeverShow = false, bShiftOne = true, 
				bShift = false, bResetItems = true}
		end
		-- Do additional Addon initialization here
	end
end

function ViragsMultibuyer:OnInvokeVendorWindowHook(unitArg)
	self:tempOnInvokeVendorWindow(unitArg)
	Event_FireGenericEvent("ViragsMultibuyer")
end

function ViragsMultibuyer:OnDependencyError(strDep, strError)
	if strDep == "Vendor" then
		parent = "LilVendor"
		return true
	end

	return false
end


-----------------------------------------------------------------------------------------------
-- ViragsMultibuyer Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
local nItems = 1

function ViragsMultibuyer:OnPatchedVendorBuyOn()
	if self.wndMain == nil or not self.wndMain:IsValid() then
		if vendorAddon.tWndRefs ~= nil then
			self.wndMain = Apollo.LoadForm(self.xmlDoc, "PatchedVendorOverlay", vendorAddon.tWndRefs.wndVendor, self)
			self.wndWarn = Apollo.LoadForm(self.xmlDoc, warningForm, vendorAddon.tWndRefs.wndVendor, self)
			local closeBtn = vendorAddon.tWndRefs.wndVendor:FindChild("CloseBtn")
			self.wndOptionsOverlay = Apollo.LoadForm(self.xmlDoc, "OptionsOverlay", closeBtn, self)
			self.wndOptionsBtn = self.wndOptionsOverlay:FindChild("MultibuyerOptionsBtn")
			self.wndOptions = self.wndOptionsOverlay:FindChild("OptionsWnd")
			local multibuyerOptionsBtn = self.wndOptionsOverlay:FindChild("MultibuyerOptionsBtn")
			multibuyerOptionsBtn:Move(48, -16, multibuyerOptionsBtn:GetWidth(), multibuyerOptionsBtn:GetHeight())
		else 
			warningForm = "LilWarningForm"
			self.wndMain = Apollo.LoadForm(self.xmlDoc, "LilVendorOverlay", vendorAddon.wndLilVendor, self)
			self.wndWarn = Apollo.LoadForm(self.xmlDoc, warningForm, vendorAddon.wndLilVendor, self)
			self.wndOptionsOverlay = Apollo.LoadForm(self.xmlDoc, "OptionsOverlay", vendorAddon.wndLilVendor:FindChild("CloseBtn"), self)
			self.wndOptions = self.wndOptionsOverlay:FindChild("OptionsWnd")
			self.wndOptionsBtn = self.wndOptionsOverlay:FindChild("MultibuyerOptionsBtn")
		end
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
	end
	if self.wndOptions ~= nil and self.wndOptions:IsValid() then 
		 self.wndOptions:FindChild("AlwaysShowButton"):SetCheck(self.tConfig.bAlwaysShow)
		 self.wndOptions:FindChild("NeverShowButton"):SetCheck(self.tConfig.bNeverShow)
		 self.wndOptions:FindChild("ShiftOneButton"):SetCheck(self.tConfig.bShiftOne)
		 self.wndOptions:FindChild("ShiftButton"):SetCheck(self.tConfig.bShift)
		 self.wndOptions:FindChild("ResetItemsButton"):SetCheck(self.tConfig.bResetItems)			
	end
	if self.wndMain ~= nil and self.wndMain:IsValid() and self.tConfig.bResetItems == false then
		self.wndMain:FindChild("Count"):SetText("" .. nItems)
		self:OnCountChanged()
	end
	self.wndMain:Show(true)
	self.wndWarn:Show(false)
end

function ViragsMultibuyer:OnCancel() 
	if self.tConfig.bResetItems == false then nItems = self.wndMain:FindChild("Count"):GetText() end
	--self.wndMain:FindChild("WarningArrow"):Show(false)
	--self.wndOptionsBtn:SetCheck(false)
	--self.wndOptions:Show(false)
	--self.wndWarn:Show(false)
	if self.wndMain ~= nil and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndWarn:Destroy()
		self.wndOptionsOverlay:Destroy()

	end
end

function ViragsMultibuyer:Rover(tag, var)
	Apollo.GetAddon("Rover"):AddWatch(tag, var)
end

function ViragsMultibuyer:GetCount()
	return tonumber(self.wndMain:FindChild("Count"):GetText())
end

function ViragsMultibuyer:OnVendorListItemMouseDown(wndHandler, wndControl, eMouseButton, nPosX, nPosY, bDoubleClick)
	local viragsVendor = Apollo.GetAddon("ViragsMultibuyer")
	if Apollo.IsControlKeyDown() or Apollo.IsAltKeyDown() or (Apollo.IsShiftKeyDown() and not viragsVendor.tConfig.bShiftOne and not viragsVendor.tConfig.bShift) then
		local tItemPreview = wndHandler:GetData()
		Event_FireGenericEvent("GenericEvent_ContextMenuItem", tItemPreview and tItemPreview.itemData)
		return true
	elseif (eMouseButton == GameLib.CodeEnumInputMouse.Left and bDoubleClick) or eMouseButton == GameLib.CodeEnumInputMouse.Right then -- left double click or right click
		self:OnVendorListItemCheck(wndHandler, wndControl)
		if self.tWndRefs.wndVendor:FindChild("Buy"):IsEnabled() then
			self:OnBuy(self.tWndRefs.wndVendor:FindChild("Buy"), self.tWndRefs.wndVendor:FindChild("Buy")) -- hackish, simulate a buy button click
			self.tDefaultSelectedItem = nil
			--Currently, when buying with a double click, the item is deselected as desired by the designers. So make sure to disable amount value.
			if eMouseButton == GameLib.CodeEnumInputMouse.Left and bDoubleClick then
				self:DisableAmountValue()
			end
		end
		return true
	end
end


function ViragsMultibuyer:FinalizeBuy(tItemData, bool)
	local idItem = tItemData and tItemData.idUnique or nil
	local altself = Apollo.GetAddon(parent)
	if altself.tWndRefs.wndVendor == nil then
		altself.tWndRefs.wndVendor = altself.wndLilVendor
	end
		
	if tItemData and altself.tWndRefs.wndVendor:FindChild(kstrTabBuy):IsChecked() then
		local viragsVendor = Apollo.GetAddon("ViragsMultibuyer")
		local viragsCount = viragsVendor.wndMain:FindChild("Count")
		viragsCount:ClearFocus()
		local count = viragsVendor:GetCount()
			if count > MAX_COUNT then 
				count = MAX_COUNT 
				viragsCount:SetText(count)
			end
		if not bool 
		and not (Apollo.IsShiftKeyDown() and count == 1 and viragsVendor.tConfig.bShiftOne)
		and not (Apollo.IsShiftKeyDown() and viragsVendor.tConfig.bShift) 
		and not viragsVendor.tConfig.bNeverShow then 
			altself.tWndRefs.wndVendor:ClearFocus()
			viragsVendor.wndWarn:FindChild("IconPic"):SetSprite(tItemData.strIcon)
			viragsVendor.wndWarn:FindChild("WarningMessage"):SetText("Are you sure you want to buy " ..  count * tItemData.nStackSize .. " items?")
			viragsVendor.wndWarn:FindChild(warningForm):Show(true)
			if tItemData.nStackSize == 1 then
				viragsVendor.wndWarn:FindChild("ItemName"):SetText(tItemData.strName)
			else 
				viragsVendor.wndWarn:FindChild("ItemName"):SetText(tItemData.strName .. " x" .. tItemData.nStackSize )
			end
			viragsVendor.wndWarn:FindChild("TotalPrice"):SetAmount(tItemData.itemData:GetBuyPrice():Multiply(count * tItemData.nStackSize))								
			viragsVendor.wndWarn:FindChild("WarningYes"):SetData({tItemData, count})
			return
		end
			
		

		BuyItemFromVendor(idItem, count)
		altself.tDefaultSelectedItem = tItemData
		altself:ShowAlertMessageContainer(String_GetWeaselString(Apollo.GetString("Vendor_Bought"), tItemData.strName), false) -- TODO: This shouldn't be needed
		local monBuyPrice = tItemData.itemData:GetBuyPrice()
		altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetAmount(monBuyPrice)
	elseif tItemData and altself.tWndRefs.wndVendor:FindChild(kstrTabSell):IsChecked() then
		SellItemToVendorById(idItem, tItemData.nStackSize)
		altself:SelectNextItemInLine(tItemData)
		altself:Redraw()
		local monSellPrice = tItemData.itemData:GetSellPrice():Multiply(tItemData.nStackSize)
		altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetAmount(monSellPrice)
	elseif tItemData and altself.tWndRefs.wndVendor:FindChild(kstrTabBuyback):IsChecked() then
		BuybackItemFromVendor(idItem)
		altself:SelectNextItemInLine(tItemData)
		local monBuyBackPrice = tItemData.itemData:GetSellPrice():Multiply(tItemData.nStackSize)
		altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetAmount(monBuyBackPrice)
	elseif altself.tWndRefs.wndVendor:FindChild(kstrTabRepair):IsChecked() then
		local idLocation = tItemData and tItemData.idLocation or nil
		if idLocation then
			RepairItemVendor(idLocation)
			local eRepairCurrency = tItemData.tPriceInfo.eCurrencyType1
			local nRepairAmount = tItemData.tPriceInfo.nAmount1
			altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetMoneySystem(eRepairCurrency)
			altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetAmount(nRepairAmount)
		else
			RepairAllItemsVendor()
			local monRepairAllCost = GameLib.GetRepairAllCost()
			altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
			altself.tWndRefs.wndVendor:FindChild("AlertCost"):SetAmount(monRepairAllCost)
		end
		Sound.Play(Sound.PlayUIVendorRepair)
	else
		return
	end

	altself.tWndRefs.wndVendor:FindChild("VendorFlash"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTemp")
end


-----------------------------------------------------------------------------------------------
-- ViragsMultibuyerForm Functions
-----------------------------------------------------------------------------------------------


function ViragsMultibuyer:OnWarningYes()
	local wYes = self.wndWarn:FindChild("WarningYes")
	local itemId = wYes:GetData()[1]
	local count = wYes:GetData()[2]
	self.wndMain:FindChild("Count"):SetText(tostring(count))
	self:FinalizeBuy(itemId, true)	
	self.wndWarn:Show(false)
end

function ViragsMultibuyer:OnWarningNo()
	self.wndWarn:Show(false)
end


function ViragsMultibuyer:OnCountChanged()
	local count = self:GetCount()
	
	if count == nil or count <= 0 then 
		count = 1 
		self.wndMain:FindChild("Count"):SetText(count)
	end

	if count > 1 then
		self.wndMain:FindChild("WarningArrow"):Show(true)
		if count > MAX_COUNT then 
			self.wndMain:FindChild("Count"):SetText(MAX_COUNT)
		end
	else 
		self.wndMain:FindChild("WarningArrow"):Show(false)
	end
end


---------------------------------------------------------------------------------------------------
-- OptionsOverlay Functions
---------------------------------------------------------------------------------------------------

function ViragsMultibuyer:OnOptionsRadio( wndHandler, wndControl, eMouseButton )
	self:RefreshConfig() 
end

function ViragsMultibuyer:RefreshConfig()
	self.tConfig.bAlwaysShow = self.wndOptions:FindChild("AlwaysShowButton"):IsChecked()
	self.tConfig.bNeverShow = self.wndOptions:FindChild("NeverShowButton"):IsChecked()
	self.tConfig.bShiftOne = self.wndOptions:FindChild("ShiftOneButton"):IsChecked()
	self.tConfig.bShift = self.wndOptions:FindChild("ShiftButton"):IsChecked()
	self.tConfig.bResetItems = self.wndOptions:FindChild("ResetItemsButton"):IsChecked()
end

function ViragsMultibuyer:OnOptionsToggle( wndHandler, wndControl, eMouseButton )
	if self.wndOptions ~= nil then
		if self.wndOptions:IsVisible() then
			self.wndOptions:Show(false)
		else 
			self.wndOptions:Show(true)
		end
	end
end

function ViragsMultibuyer:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.Realm then
        return nil
    end 
	local save = { SavedConfig = self.tConfig }
    return save
end

function ViragsMultibuyer:OnRestore(eType, tData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Realm then
        return nil
    end 
	if tData.SavedConfig ~= nil then
		self.tConfig = tData.SavedConfig
    end
end

-----------------------------------------------------------------------------------------------
-- ViragsMultibuyer Instance
-----------------------------------------------------------------------------------------------
local ViragsMultibuyerInst = ViragsMultibuyer:new()
ViragsMultibuyerInst:Init()
