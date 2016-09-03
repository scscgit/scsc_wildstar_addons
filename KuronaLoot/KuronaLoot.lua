-----------------------------------------------------------------------------------------------
-- Client Lua Script for KuronaLoot
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- KuronaLoot Module Definition
-----------------------------------------------------------------------------------------------
local KuronaLoot = {} 


local Version = 1.7

local QualityFrames = {
	[0] = "",
	[1] = "BK3:UI_RarityBorder_Grey",
	[2] = "BK3:UI_RarityBorder_White",
	[3] = "BK3:UI_RarityBorder_Green",
	[4] = "BK3:UI_RarityBorder_Blue",
	[5] = "BK3:UI_RarityBorder_Purple",
	[6] = "BK3:UI_RarityBorder_Orange",
	[7] = "BK3:UI_RarityBorder_Magenta",
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
	[7] = "ccff00ff",
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

 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function KuronaLoot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function KuronaLoot:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- KuronaLoot OnLoad
-----------------------------------------------------------------------------------------------
function KuronaLoot:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("KuronaLoot.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	Apollo.LoadSprites("KLsprites.xml","KLsprites")

end

-----------------------------------------------------------------------------------------------
-- KuronaLoot OnDocLoaded
-----------------------------------------------------------------------------------------------
function KuronaLoot:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.LootNote = Apollo.LoadForm(self.xmlDoc, "LootNotificationForm",nil, self)
		if self.LootNote == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.SmallLootForm = Apollo.LoadForm(self.xmlDoc, "NotificationContainer", nil, self)
		self.SmallLootNote = self.SmallLootForm:FindChild("NotificationList")
		self.SmallLootForm:Show(true,true)
	    self.LootOptions = Apollo.LoadForm(self.xmlDoc, "Options",nil, self)
		self.LootSlider = self.LootOptions:FindChild("LootThresholdSliderBar")

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("kloot", "OnKuronaLootOn", self)


		-- Do additional Addon initialization here
		
		Apollo.RegisterTimerHandler("LootNotificationGracePeriod", "OnLootNotificationGracePeriod", self)
		Apollo.RegisterTimerHandler("SmallLootTimer", "OnSmallLootTimer", self)
		
		
		--Needed for most items
		Apollo.RegisterEventHandler("ChannelUpdate_Loot",	"OnChannelUpdate_Loot", self)

		-- Needed for items purchased / tradeskill
		Apollo.RegisterEventHandler("ItemAdded", "OnItemAdded", self)
		--Apollo.RegisterEventHandler("LootedMoney", "OnLootedMoney", self)
		
		--Settings		
		if self.tSettings == nil then
			self.tSettings = self:DefaultTable()
		end
	
		self.timerCash = ApolloTimer.Create(5.0, false, "OnLootStack_CashTimer", self)
		self.SmallList = {}
		
		self.canSalvage = false
		
		
		self.LootQueue = {}
		self.LootWaiting = 0
		self.SideLootResized = false




		self.LootNote:SetAnchorOffsets(self.tSettings.TopL,self.tSettings.TopT,self.tSettings.TopR,self.tSettings.TopB)
		self.SmallLootForm:SetAnchorOffsets(self.tSettings.nSideL,self.tSettings.nSideT,self.tSettings.nSideR,self.tSettings.nSideB)
		self.LootOptions:SetAnchorOffsets(self.tSettings.OptionsL,self.tSettings.OptionsT,self.tSettings.OptionsR,self.tSettings.OptionsB)
		
		self:SetOptions()
		
	end
end

-----------------------------------------------------------------------------------------------
-- KuronaLoot Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/kloot"
function KuronaLoot:OnKuronaLootOn(strArg)
	self:OnShowLootSettings()
	if strArg == "reset" or strArg == "default" then
		self:OnDefaultLootSettings()
	end
--	self.Options:Invoke() -- show the window
end


-----------------------------------------------------------------------------------------------
-- KuronaLootForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function KuronaLoot:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function KuronaLoot:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- KuronaLoot Instance
-----------------------------------------------------------------------------------------------
local KuronaLootInst = KuronaLoot:new()
KuronaLootInst:Init()


function KuronaLoot:DefaultTable()
	local defaultsettings = {}
	
	defaultsettings.nSideL = 3
	defaultsettings.nSideT = -761
	defaultsettings.nSideR = 333
	defaultsettings.nSideB = -346

	defaultsettings.TopL = -200
	defaultsettings.TopT = 20
	defaultsettings.TopR = 200
	defaultsettings.TopB = 232
	
	defaultsettings.OptionsL = -900
	defaultsettings.OptionsT = -660
	defaultsettings.OptionsR = -550
	defaultsettings.OptionsB = -150
	
	defaultsettings.LootThresholdAlert = 3
	defaultsettings.SideLootNumberDisplayed = 6
	defaultsettings.LargeLootScale = 100
	defaultsettings.SideLootScale = 100
	defaultsettings.SmallLootShowTime = 2 
	defaultsettings.LargeLootShowTime = 3
	defaultsettings.LootTimer = 2
	defaultsettings.Debug = false
	return defaultsettings
	
end

function KuronaLoot:OnSave(eLevel,backup)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	local tsave = {}
		
	tsave.tSettings = self.tSettings
	tsave.tSettings.nSideL,tsave.tSettings.nSideT,tsave.tSettings.nSideR,tsave.tSettings.nSideB = self.SmallLootForm:GetAnchorOffsets()
	tsave.tSettings.TopL,tsave.tSettings.TopT,tsave.tSettings.TopR,tsave.tSettings.TopB = self.LootNote:GetAnchorOffsets()
	tsave.tSettings.OptionsL,tsave.tSettings.OptionsT,tsave.tSettings.OptionsR,tsave.tSettings.OptionsB = self.LootOptions:GetAnchorOffsets()
	return tsave
end



function KuronaLoot:OnRestore(eLevel, saveData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	self.tSettings = {}			
	local defaultsettings = self:DefaultTable()
	if not saveData.tSettings then return end
	for k,v in pairs(saveData.tSettings) do
	   	self.tSettings[k]=v
	end

	for k,v in pairs(defaultsettings) do
	   	if self.tSettings[k] == nil then
			 self.tSettings[k] = v
		end
	end
end



function KuronaLoot:TestLootNote()
	self.LootNote:FindChild("LegendaryOverlay"):Show(false,true)
	self.LootNote:FindChild("EpicOverlay"):Show(false,true)

	self.SmallLootNote:DestroyChildren()
	self.SmallList = {}
	self.LootQueue = {}
	Apollo.StopTimer("LootNotificationGracePeriod")
	Apollo.StopTimer("SmallLootTimer")

	self.SmallLootForm:FindChild("LootedCashWindow"):SetAmount(0)
	self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(0)

	self:OnLootedMoney(GameLib.GetPlayerCurrency())
	self:OnLootedMoney(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Glory))
	local equipped = GameLib.GetPlayerUnit():GetEquippedItems() 
	for k,v in pairs(equipped) do
		if k < 15 then
			self:OnLootedItem(v,1)
		end
	end
	Apollo.StopTimer("LootNotificationGracePeriod")
	Apollo.StopTimer("SmallLootTimer")
end


function KuronaLoot:OnLootedMoney(monLooted)
	if self.KB == nil then
		self.KB = Apollo.GetAddon("KuronaBags")
	end
	
	local eCurrencyType = monLooted:GetMoneyType()
	
	local AccountMon = monLooted:GetAccountCurrencyType()
	--if AccountMon == AccountItemLib.CodeEnumAccountCurrency.Omnibits and tOmniBitInfo then

	
	if eCurrencyType == Money.CodeEnumCurrencyType.Credits then
		self.SmallLootForm:FindChild("LootedCashWindow"):SetAmount(self.SmallLootForm:FindChild("LootedCashWindow"):GetAmount() + monLooted:GetAmount())
		self.SmallLootForm:FindChild("LootedCashWindow"):Show(true,true)
		self.SmallLootForm:FindChild("CashWindow"):Invoke()
		self.SmallLootForm:FindChild("CashWindow"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempLoop")
		self.timerCash:Stop()
		self.timerCash:Start()
			
	elseif eCurrencyType == Money.CodeEnumCurrencyType.Renown
		or eCurrencyType == Money.CodeEnumCurrencyType.ElderGems
		or eCurrencyType == Money.CodeEnumCurrencyType.Glory
		or eCurrencyType == Money.CodeEnumCurrencyType.ShadeSilver
		or eCurrencyType == Money.CodeEnumCurrencyType.CraftingVouchers
		or AccountMon ==	AccountItemLib.CodeEnumAccountCurrency.ServiceToken
		or AccountMon == AccountItemLib.CodeEnumAccountCurrency.Omnibits
		or AccountMon ==	AccountItemLib.CodeEnumAccountCurrency.MysticShiny then
		
		if AccountMon ~= 0 then
			eCurrencyType = AccountMon
			self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(0,true)
			self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(AccountItemLib.GetAccountCurrency(AccountMon))
			self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(monLooted:GetAmount())
		else		
			if eCurrencyType ~= self.LastSecondCurrency then
				self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetMoneySystem(eCurrencyType)
				self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(0,true)
				self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(self.SmallLootForm:FindChild("SecondLootedCashWindow"):GetAmount() + monLooted:GetAmount())			
			else			
				self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetMoneySystem(eCurrencyType)
				self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(self.SmallLootForm:FindChild("SecondLootedCashWindow"):GetAmount() + monLooted:GetAmount())
			end
		end
		
		self.SmallLootForm:FindChild("CashWindow"):Invoke()
		self.SmallLootForm:FindChild("CashWindow"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempLoop")
		self.SmallLootForm:FindChild("SecondLootedCashWindow"):Show(true,true)
		self.timerCash:Stop()
		self.timerCash:Start()
		self.LastSecondCurrency = eCurrencyType
	end
end

function KuronaLoot:OnLootStack_CashTimer()
	self.SmallLootForm:FindChild("CashWindow"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempLoop")
	self.SmallLootForm:FindChild("LootedCashWindow"):SetAmount(0)
	self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(0,false)
	self.SmallLootForm:FindChild("CashWindow"):Show(false,false)
	self.SmallLootForm:FindChild("LootedCashWindow"):Show(false,false)
	self.SmallLootForm:FindChild("SecondLootedCashWindow"):Show(false,false)
end

function KuronaLoot:OnTradeskillItemAdded(item,ncount)
end

function KuronaLoot:OnItemUpdated(item,ncount,reason)
end


function KuronaLoot:OnItemAdded(item,ncount,reason)
--	for x, y in pairs(Item.CodeEnumItemUpdateReason) do
		--Print(x.." "..y)
--	end
	if reason == 7 or reason == 16 then
		self:OnLootedItem(item,ncount)
	end
end

function KuronaLoot:OnLootedItem(item,ncount)
	if item == nil then return end
	self.SmallLootForm:ToFront()
	local tId = item:GetItemId()
	local list = self.SmallLootNote:GetChildren()
	local itemT = {}
	itemT["item"] = item
	itemT["id"] = item:GetItemId()
	itemT["count"] = ncount
	local newInsert = true
	for i=1,#self.SmallList do
		if self.SmallList[i].id ==  itemT.id then
			self.SmallList[i].count = self.SmallList[i].count + itemT.count
			newInsert = false
		end
	end
		
	if newInsert then
		table.insert(self.SmallList,itemT)
	end
		
	if #self.SmallLootNote:GetChildren() < self.tSettings.SideLootNumberDisplayed then
		self:StartSmallLootNotification()
	end
	
	local quality = item:GetItemQuality()
	if quality >= self.tSettings.LootThresholdAlert or item:GetGivenQuest() then
		if self.LootQueue == nil then self.LootQueue = {} end
		
		
		local newInsert = true
		for i=2,#self.LootQueue do
			if self.LootQueue[i].id ==  itemT.id then
				self.LootQueue[i].count = self.LootQueue[1].count + itemT.count
				newInsert = false
			end
		end
		
		if newInsert then
			table.insert(self.LootQueue,itemT)
		end

		if #self.LootQueue == 1 then
			self:StartLootNotification()
		end
	end
end

function KuronaLoot:StartSmallLootNotification()

	if #self.SmallList > 0 then
	local item = 	self.SmallList[1]["item"]
	local count = 	self.SmallList[1]["count"] or "1"
	local quality = item:GetItemQuality()
	local itemForm = Apollo.LoadForm(self.xmlDoc, "SmallLootItem", self.SmallLootNote, self)
	itemForm:FindChild("RarityBracket"):SetSprite(ItemQualityFrames[quality])
	itemForm:FindChild("LootIcon"):SetSprite(item:GetIcon())
	itemForm:FindChild("ColorBG"):SetBGColor(QualityColors[quality])
	itemForm:FindChild("IconFrame"):SetBGColor(QualityColors[quality])
	itemForm:FindChild("ItemName"):SetText(item:GetName())
	itemForm:FindChild("ItemType"):SetText(item:GetItemTypeName())
	itemForm:FindChild("ItemCount"):SetText("x" .. count)
	itemForm:SetOpacity(0.85)
	itemForm:SetData(item)
	itemForm:SetName(item:GetItemId())
	itemForm:Show(true,false)
	self.SmallLootNote:ArrangeChildrenVert(-1)
	table.remove(self.SmallList,1)
	end

	if self.SmallLootTimer == nil and not self.EditLoot then
		self.SmallLootTimer = ApolloTimer.Create(self.tSettings.LootTimer, false, "OnSmallLootTimer", self)
	end
end

function KuronaLoot:OnSmallLootTimer()
	self.SmallLootTimer:Stop()
	self.SmallLootTimer = nil
	
	if #self.SmallLootNote:GetChildren() == 0 then return end
	self.SmallLootNote:GetChildren()[1]:Show(false,false)
	self.SmallLootNote:GetChildren()[1]:Destroy()
	self.SmallLootNote:ArrangeChildrenVert(-1)
	
	if #self.SmallLootNote:GetChildren() > 0 then
		self:StartSmallLootNotification()
	end
end


function KuronaLoot:StartLootNotification()
	local item = 	self.LootQueue[1]["item"]
	local count = 	self.LootQueue[1]["count"]
	local displaytime = self.tSettings.LootTimer + 1
	Apollo.StopTimer("LootNotificationGracePeriod")
	local quality = item:GetItemQuality()
	local questitem = item:GetGivenQuest()
	self.LootNote:FindChild("RarityBracket"):SetSprite(ItemQualityFrames[quality])
	self.LootNote:FindChild("LootIcon"):SetSprite(item:GetIcon())
	self.LootNote:FindChild("ColorBG"):SetBGColor(QualityColors[quality])
	self.LootNote:FindChild("IconFrame"):SetBGColor(QualityColors[quality])
	self.LootNote:FindChild("FlashBG"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempLoop")
	self.LootNote:SetOpacity(0.90)
	self.LootNote:SetData(item)
	--self.LootNote:FindChild("IconFrame"):SetSprite(AltQualityFrames[quality])
	
	self.LootNote:FindChild("ItemName"):SetText(item:GetName())
	if quality == 4 then
		Sound.Play(Sound.PlayUIWindowNeedVsGreedOpen)
	
	elseif quality == 5 then
--		Sound.Play(Sound.PlayUIAlertPopUpRepIncrease)
		if not questitem then
			Sound.Play(Sound.PlayUIMemoryWin)
		end
		self.LootNote:FindChild("EpicOverlay"):Show(true,true)
	elseif quality > 5 then
		--Sound.Play(Sound.PlayRingtoneScientist)
				   
		Sound.Play(Sound.PlayUIAlertPopUpTitleReceived)
		Sound.Play(Sound.PlayUIQueuePopsDungeon)
		--Sound.Play(Sound.PlayUIAlertPopUpRepIncrease)
		self.LootNote:FindChild("LegendaryOverlay"):Show(true,true)
	end
	
	if count > 1 then
		self.LootNote:FindChild("ItemCount"):SetText("x" .. count)
		self.LootNote:FindChild("ItemCount"):Show(true,true)
	else
		self.LootNote:FindChild("ItemCount"):Show(false,true)
	end
	
	self.LootNote:FindChild("StartsQuestWindow"):Show(item:GetGivenQuest(),true)
	if item:GetGivenQuest() then
		displaytime = displaytime + 2
		Sound.Play(149)		
	end
	self.LootNote:FindChild("ItemType"):SetText(item:GetItemTypeName())
	self.LootNote:Show(false,true)
	self.LootNote:SetTooltip("")
	self.LootNote:Show(true,false)
	self.LootNote:ToFront()	

	Apollo.StopTimer("LootNotificationGracePeriod")
	if #self.LootQueue > 0 then
		Apollo.CreateTimer("LootNotificationGracePeriod", 	displaytime, false)
	else
		Apollo.CreateTimer("LootNotificationGracePeriod", displaytime+1, false)
	end
end

function KuronaLoot:OnLootNotificationGracePeriod()
	self.LootNote:Show(false,false)
	self.LootNote:SetTooltip("")
	self.LootNote:FindChild("LegendaryOverlay"):Show(false,true)
	self.LootNote:FindChild("EpicOverlay"):Show(false,true)
	table.remove(self.LootQueue,1)	

	if #self.LootQueue > 0 then
		self:StartLootNotification()
	end
end



function KuronaLoot:OnExitLargeLoot( wndHandler, wndControl, x, y )
	if not self.EditLoot then
		Apollo.CreateTimer("LootNotificationGracePeriod", 1, false)
	end
end

function KuronaLoot:OnOverLargeLoot( wndHandler, wndControl, x, y )
	Apollo.StopTimer("LootNotificationGracePeriod")
end

function KuronaLoot:OnOverSmallLoot( wndHandler, wndControl, x, y )
	if self.SmallLootTimer then
		self.SmallLootTimer:Stop()
		self.SmallLootTimer = nil
	end
end

function KuronaLoot:OnExitSmallLoot( wndHandler, wndControl, x, y )
	if not self.EditLoot and self.SmallLootTimer == nil then
		self.SmallLootTimer = ApolloTimer.Create(1.0, false, "OnSmallLootTimer", self)
	end
	
	if 	self.SideLootResized then
		local l,t,r,b = self.SmallLootForm:GetAnchorOffsets()
		local nt  = b - ((self.tSettings.SideLootNumberDisplayed * 65) + 25) 
		self.SmallLootForm:SetAnchorOffsets(l,nt,r,b)
		self.SideLootResized = false
		self.SmallLootNote:ArrangeChildrenVert(-1)
	end
end

function KuronaLoot:GenerateTooltip(wndControl, wndHandler, tType, item)
	if wndControl ~= wndHandler or self.EditLoot then return end

	item = wndHandler:GetData()
	
	wndControl:SetTooltipDoc(nil)

	if item ~= nil then
		local itemEquipped = item:GetEquippedItemForItemType()
		Tooltip.GetItemTooltipForm(self, wndControl, item, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	end
end



function KuronaLoot:OnLootSliderChanged( wndHandler, wndControl, fNewValue, fOldValue, bOverride)

	self.tSettings.LootThresholdAlert = self.LootSlider:GetValue()
	self.LootSlider:GetParent():GetParent():SetTextColor(QualityColors[self.tSettings.LootThresholdAlert])
	self.LootSlider:GetParent():GetParent():SetText(QualityNames[self.tSettings.LootThresholdAlert])
	
	self.tSettings.LargeLootScale = self.LootOptions:FindChild("LargeLootSizeSliderBar"):GetValue()
	self.LootOptions:FindChild("LargeLootSize"):SetText(self.tSettings.LargeLootScale .."%")
	self.LootNote:SetScale(self.tSettings.LargeLootScale / 100)
	
	self.tSettings.SideLootScale = self.LootOptions:FindChild("SideLootSizeSliderBar"):GetValue()
	self.LootOptions:FindChild("SideLootSize"):SetText(self.tSettings.SideLootScale .."%")
	self.SmallLootForm:SetScale(self.tSettings.SideLootScale / 100)

	self.tSettings.LootTimer = self.LootOptions:FindChild("LootTimerSliderBar"):GetValue() / 10
	self.LootOptions:FindChild("LootTimer"):SetText(self.tSettings.LootTimer .." sec")
--	self.SmallLootForm:SetScale(self.tSettings.SideLootScale / 100)
	

	if wndControl:GetName() == "SideLootNumSliderBar" or bOverride then
		self.tSettings.SideLootNumberDisplayed = wndControl:GetValue()
		self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)
		self.SideLootResized = true
		self:OnExitSmallLoot()
	end
	
	self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)
end


function KuronaLoot:OnExitShowLootSettings()
	self.LootNote:Show(false,true)
	self.LootNote:SetStyle("Picture",false)
	self.LootNote:SetStyle("IgnoreMouse",true)
	self.LootNote:SetStyle("Moveable",false)
	
	self.SmallLootForm:SetStyle("Picture",false)
	self.SmallLootForm:SetStyle("Sizable",false)
	self.SmallLootForm:SetStyle("IgnoreMouse",true)
	self.SmallLootForm:SetStyle("Moveable",false)
	
	self.LootNote:FindChild("LegendaryOverlay"):Show(false,true)
	self.LootNote:FindChild("EpicOverlay"):Show(false,true)
	
	self.LootOptions:Show(false,true)

	self.SmallLootForm:SetTooltip("")
	self.LootNote:SetTooltip("")

	self.SmallLootForm:FindChild("LootedCashWindow"):SetAmount(0)
	self.SmallLootForm:FindChild("SecondLootedCashWindow"):SetAmount(0)
	self.SmallLootForm:FindChild("CashWindow"):Show(false,true)
	self.SmallLootNote:DestroyChildren()
	self.SmallList = {}
	self.LootQueue = {}
end

function KuronaLoot:OnDefaultLootSettings( wndHandler, wndControl, eMouseButton )
	local defaults = self:DefaultTable()
	self.tSettings.LootThresholdAlert = defaults.LootThresholdAlert
	self.tSettings.SideLootNumberDisplayed = defaults.SideLootNumberDisplayed
	self.tSettings.LargeLootScale = defaults.LargeLootScale
	self.tSettings.SideLootScale = defaults.SideLootScale
	self.tSettings.LootTimer = defaults.LootTimer
	
	self.LootNote:SetAnchorOffsets(defaults.TopL,defaults.TopT,defaults.TopR,defaults.TopB)
	self.SmallLootForm:SetAnchorOffsets(defaults.nSideL,defaults.nSideT,defaults.nSideR,defaults.nSideB)
	self.LootOptions:SetAnchorOffsets(self.tSettings.OptionsL,self.tSettings.OptionsT,self.tSettings.OptionsR,self.tSettings.OptionsB)

	self.LootOptions:FindChild("LargeLootSizeSliderBar"):SetValue(self.tSettings.LargeLootScale)
	self.LootOptions:FindChild("SideLootSizeSliderBar"):SetValue(self.tSettings.SideLootScale)
	self.LootOptions:FindChild("LootThresholdSliderBar"):SetValue(self.tSettings.LootThresholdAlert)
	self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)
	self.LootOptions:FindChild("LootTimerSliderBar"):SetValue(self.tSettings.LootTimer*10)
	self.LootOptions:FindChild("LootTimer"):SetText(self.tSettings.LootTimer .." sec")
	
	self:SetOptions()
end

function KuronaLoot:OnShowLootSettings( wndHandler, wndControl, eMouseButton )
	self.LootOptions:Invoke()
	
	self.LootNote:Show(true,true)
	self.LootNote:SetStyle("Picture",true)
	self.LootNote:SetStyle("IgnoreMouse",false)
	self.LootNote:SetStyle("Moveable",true)
	
	self.SmallLootForm:SetStyle("Picture",true)
	self.SmallLootForm:SetStyle("Sizable",true)
	self.SmallLootForm:SetStyle("IgnoreMouse",false)
	self.SmallLootForm:SetStyle("Moveable",true)
	
	self.LootNote:FindChild("LegendaryOverlay"):Show(false,true)
	self.LootNote:FindChild("EpicOverlay"):Show(false,true)
	
	self.SmallLootNote:DestroyChildren()
	self.SmallList = {}
	self.LootQueue = {}

	self.EditLoot = true
	self:TestLootNote()
	for i = 1, #self.SmallLootNote:GetChildren() do
		self.SmallLootNote:GetChildren()[i]:SetTooltip("Moveable - Sizable")
	end
	
	self.SmallLootForm:SetTooltip("Moveable - Sizable")
	self.LootNote:SetTooltip("Moveable - Scalable via the slider")
	self.SmallLootForm:FindChild("LootedCashWindow"):SetAmount(GameLib.GetPlayerCurrency())
	self.SmallLootForm:FindChild("CashWindow"):SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempLoop")
	
	self.timerCash:Stop()
	self.SmallLootForm:FindChild("CashWindow"):Invoke()
	self.SmallLootForm:FindChild("CashWindow"):Show(true,true)
	Apollo.StopTimer("LootNotificationGracePeriod")
	Apollo.StopTimer("SmallLootTimer")
end

function KuronaLoot:OnButtonClose( wndHandler, wndControl, eMouseButton )
	self:OnExitShowLootSettings()
	self.EditLoot = false
end

function KuronaLoot:OnSideLootSized( wndHandler, wndControl )
	if self.EditLoot then
		self.SideLootResized = true
	end
end



function KuronaLoot:SetOptions()
	self.LootOptions:FindChild("SideLootNumSliderBar"):SetValue(self.tSettings.SideLootNumberDisplayed)	
	self.LootOptions:FindChild("LargeLootSizeSliderBar"):SetValue(self.tSettings.LargeLootScale)
	self.LootOptions:FindChild("SideLootSizeSliderBar"):SetValue(self.tSettings.SideLootScale)
	self.LootOptions:FindChild("LootThresholdSliderBar"):SetValue(self.tSettings.LootThresholdAlert)
	self.LootOptions:FindChild("LootNumDisplayed"):SetText(self.tSettings.SideLootNumberDisplayed)

	self.LootOptions:FindChild("LootTimerSliderBar"):SetValue(self.tSettings.LootTimer*10)
	self.LootOptions:FindChild("LootTimer"):SetText(self.tSettings.LootTimer.." sec")
	self:OnLootSliderChanged(self.LootSlider,self.LootSlider,0,true)
end


function KuronaLoot:OnChannelUpdate_Loot(eType, tEventArgs)
	if eType == GameLib.ChannelUpdateLootType.Currency and tEventArgs.monNew then

		local eCurrencyType = tEventArgs.monNew:GetMoneyType()
		self:OnLootedMoney(tEventArgs.monNew)
		
	elseif eType == GameLib.ChannelUpdateLootType.Item and tEventArgs.itemNew then
		self:OnLootedItem(tEventArgs.itemNew,tEventArgs.nCount)
	end
end
