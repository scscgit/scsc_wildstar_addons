require "Window"
require "Apollo"
require "ApolloCursor"
require "GameLib"
require "Item"

local KuronaSalvage = {}

local kidBackpack = 0

local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

function KuronaSalvage:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function KuronaSalvage:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("KuronaSalvage.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 
end

function KuronaSalvage:OnDocumentReady()
	if self.xmlDoc == nil then
		return
	end
	
	Apollo.RegisterEventHandler("RequestSalvageAll", "OnSalvageAll", self) -- using this for bag changes
	Apollo.RegisterSlashCommand("salvageall", "OnSalvageAll", self)
	Apollo.RegisterSlashCommand("ksalvage", "OnConsole", self)

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "KuronaSalvageForm", nil, self)
	self.wndItemDisplay = self.wndMain:FindChild("ItemDisplayWindow")
	
	if self.locSavedWindowLoc then
		self.wndMain:MoveToLocation(self.locSavedWindowLoc)
	end
	
	self.tContents = self.wndMain:FindChild("HiddenBagWindow")
	self.arItemList = nil
	self.nItemIndex = nil

	self.wndMain:Show(false, true)
	
	if self.IgnoreList == nil then
		self.IgnoreList = {}
	end
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	self:OnWindowManagementReady()

end

function KuronaSalvage:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementRegister", {strName = "KuronaSalvage"})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "KuronaSalvage"})
end


--------------------//-----------------------------
function KuronaSalvage:OnConsole(cmd,strArg)
	if strArg == "reset" then
		self.IgnoreList = {}
		Print("Ignore list cleared")		
	elseif strArg ~="" then
		Print("Type:")
		Print(" /ksalvage reset      :to clear ignore list")
	else
		self:OnSalvageAll()
	end
		self:RedrawKBags()
end

function KuronaSalvage:OnSalvageAll()
	local improvedSalvage = Apollo.GetAddon("ImprovedSalvage")
	if improvedSalvage then
		improvedSalvage.wndMain:Show(false)
	end
	self.arItemList = {}
	self.nItemIndex = 1
	
	
		self.KuronaBags = Apollo.GetAddon("KuronaBags")
		local preventSalvage = self.KuronaBags.PreventSalvageList
	
	local tInvItems = GameLib.GetPlayerUnit():GetInventoryItems()
	for idx, tItem in ipairs(tInvItems) do
		if tItem and tItem.itemInBag and tItem.itemInBag:CanSalvage() and not(self.IgnoreList[tItem.itemInBag:GetItemId()] or preventSalvage[tItem.itemInBag:GetItemId()]) then
			if not preventSalvage[tItem.itemInBag:GetItemId()] then
				table.insert(self.arItemList, tItem.itemInBag)
			end
		end
	end
	self:RedrawAll()
end

function KuronaSalvage:OnSalvageListItemCheck(wndHandler, wndControl)
	if not wndHandler or not wndHandler:GetData() then
		return
	end
	
	self.nItemIndex = wndHandler:GetData().nIdx
	wndHandler:GetChildren()[1]:Show(true)
	
	local itemCurr = self.arItemList[self.nItemIndex]
	self.wndMain:SetData(itemCurr)
	self.wndMain:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, itemCurr:GetInventoryId())
end

function KuronaSalvage:OnSalvageListItemUncheck( wndHandler, wndControl, eMouseButton )
	wndHandler:GetChildren()[1]:Show(false)
end




function KuronaSalvage:OnSalvageListItemGenerateTooltip(wndControl, wndHandler) -- wndHandler is VendorListItemIcon
	if wndHandler ~= wndControl then
		return
	end

	wndControl:SetTooltipDoc(nil)

	local tListItem = wndHandler:GetData().tItem
	local tPrimaryTooltipOpts = {}

	tPrimaryTooltipOpts.bPrimary = true
	tPrimaryTooltipOpts.itemModData = tListItem.itemModData
	tPrimaryTooltipOpts.strMaker = tListItem.strMaker
	tPrimaryTooltipOpts.arGlyphIds = tListItem.arGlyphIds
	tPrimaryTooltipOpts.tGlyphData = tListItem.itemGlyphData
	tPrimaryTooltipOpts.itemCompare = tListItem:GetEquippedItemForItemType()

	if Tooltip ~= nil and Tooltip.GetSpellTooltipForm ~= nil then
		Tooltip.GetItemTooltipForm(self, wndControl, tListItem, tPrimaryTooltipOpts, tListItem.nStackSize)
	end
end

function KuronaSalvage:RedrawAll()
--[[
		self.KuronaBags = Apollo.GetAddon("KuronaBags")
		local preventSalvage = self.KuronaBags.PreventSalvageList
		for i = #self.arItemList, 1, -1 do
			local item = self.arItemList[i]
			if item and preventSalvage[item:GetItemId()] then
				table.remove(self.arItemList, i)
			end
		end
]]

	local itemCurr = self.arItemList[self.nItemIndex]
	
	
	if itemCurr ~= nil then
		local wndParent = self.wndMain:FindChild("MainScroll")
		local nScrollPos = wndParent:GetVScrollPos()
		wndParent:DestroyChildren()
	
		for idx, tItem in ipairs(self.arItemList) do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "SalvageListItem", wndParent, self)
			wndCurr:FindChild("SalvageListItemBtn"):SetData({nIdx = idx, tItem=tItem})
			wndCurr:FindChild("SalvageListItemBtn"):SetCheck(idx == self.nItemIndex)
			
			wndCurr:FindChild("SalvageListItemTitle"):SetTextColor(karEvalColors[tItem:GetItemQuality()])
			wndCurr:FindChild("SalvageListItemTitle"):SetText(tItem:GetName())
			
			local bTextColorRed = self:HelperPrereqFailed(tItem)
			wndCurr:FindChild("SalvageListItemType"):SetTextColor(bTextColorRed and "xkcdReddish" or "UI_TextHoloBodyCyan")
			wndCurr:FindChild("SalvageListItemType"):SetText(tItem:GetItemTypeName())
			
			wndCurr:FindChild("SalvageListItemCantUse"):Show(bTextColorRed)
			wndCurr:FindChild("SalvageListItemIcon"):GetWindowSubclass():SetItem(tItem)
		end
		
		wndParent:ArrangeChildrenVert(0)
		wndParent:SetVScrollPos(nScrollPos)
		wndParent:GetChildren()[self.nItemIndex]:GetChildren()[1]:GetChildren()[1]:Show(true)
	
		self.wndMain:SetData(itemCurr)
		self.wndMain:FindChild("SalvageBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.SalvageItem, itemCurr:GetInventoryId())
		self.wndMain:Show(true)
		self.wndMain:ToFront()
	else
		self.wndMain:Show(false)
		self:RedrawKBags()
	end
	
end

function KuronaSalvage:HelperPrereqFailed(tCurrItem)
	return tCurrItem and tCurrItem:IsEquippable() and not tCurrItem:CanEquip()
end

function KuronaSalvage:OnSalvageCurr()
	if self.nItemIndex == #self.arItemList then 
		table.remove(self.arItemList, self.nItemIndex )
		self.nItemIndex = self.nItemIndex - 1
	else
		table.remove(self.arItemList, self.nItemIndex )
	end
	self:RedrawAll()
end

function KuronaSalvage:OnCloseBtn()
	self.arItemList = {}
	self.wndMain:SetData(nil)
	self.wndMain:Show(false)
	self:RedrawKBags()
end

function KuronaSalvage:RedrawKBags()
	local kbags = Apollo.GetAddon("KuronaBags")
	if kbags then
		kbags:Redraw()
	end	
end

----------------globals----------------------------

---------------------------------------------------------------------------------------------------
-- SalvageListItem Functions
---------------------------------------------------------------------------------------------------

function KuronaSalvage:AddToIgnore( wndHandler, wndControl, eMouseButton )
	local item = wndHandler:GetParent():GetData().tItem
	self.IgnoreList[item:GetItemId()] = true
	
	local preventSalvage = self.IgnoreList
	for i = #self.arItemList, 1, -1 do
		local item = self.arItemList[i]
			if item and self.IgnoreList[item:GetItemId()] then
				table.remove(self.arItemList, i)
			end
		end
	wndHandler:GetParent():GetParent():Destroy()
	self:RedrawAll()
end

---------------------------------------------------------------------------------------------------
-- KuronaSalvageForm Functions
---------------------------------------------------------------------------------------------------

function KuronaSalvage:ClearIgnoreList( wndHandler, wndControl, eMouseButton )
	self.IgnoreList = {}
	self:RedrawAll()
	self:OnSalvageAll()
end

local ImprovedSalvage_Singleton = KuronaSalvage:new()
Apollo.RegisterAddon(ImprovedSalvage_Singleton)

function KuronaSalvage:OnSave(eLevel,backup)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tsave = {}
	tsave.IgnoreList = self.IgnoreList
	return tsave
end


function KuronaSalvage:OnRestore(eLevel, saveData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.IgnoreList = saveData.IgnoreList
end