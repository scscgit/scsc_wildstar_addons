
local KuronaBags =  Apollo.GetAddon("KuronaBags")
local self = KuronaBags
local APIVersion = Apollo.GetAPIVersion()

function KuronaBags:OnShowBank()
	self:SetBankOptions()
	self.BankBagForm:Show(true)
	self.BankOpen = true
	self.BankBagForm:ToFront()
end

function KuronaBags:OnHideBank()
	self.BankBagForm:Show(false)
	self.BankOpen = false
end

function KuronaBags:OnBankSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.tSettings.nBankIconSize = self.BankBagForm:FindChild("BankIconSizeSliderBar"):GetValue()
	self.tSettings.nBankWidth = self.BankBagForm:FindChild("BankRowSliderBar"):GetValue()
	self.BankBagForm:FindChild("BankIconSizeSliderBar"):GetParent():GetParent():SetText(self.tSettings.nBankIconSize)
	self.BankBagForm:FindChild("BankRowSliderBar"):GetParent():GetParent():SetText(self.tSettings.nBankWidth)

	self:SetBankOptions()
end

function KuronaBags:SetBankOptions()
	self.BankBagForm:FindChild("BankIconSizeSliderBar"):GetParent():GetParent():SetText(self.tSettings.nBankIconSize)
	self.BankBagForm:FindChild("BankRowSliderBar"):GetParent():GetParent():SetText(self.tSettings.nBankWidth)
	
	local totalSlots = self.BankBagForm:FindChild("BankWindow"):GetTotalBagSlots()
	local l,t,r,b = self.BankBagForm:GetAnchorOffsets()

	self.BankBagForm:FindChild("BankWindow"):SetSquareSize(self.tSettings.nBankIconSize,self.tSettings.nBankIconSize)
	self.BankBagForm:FindChild("BankWindow"):SetBoxesPerRow(self.tSettings.nBankWidth)
	r = (self.tSettings.nBankIconSize * self.tSettings.nBankWidth)+34
	b = t + (math.ceil(totalSlots / self.tSettings.nBankWidth) * self.tSettings.nBankIconSize) + 84
	self.BankBagForm:SetAnchorOffsets(l,t,l+r,b)

end

function KuronaBags:CloseBank( wndHandler, wndControl, eMouseButton )
	Event_CancelBanking()

	self.BankOpen = false
	self.BankBagForm:Show(false)
end

function KuronaBags:PopulateBankBag()
	self.BankBagForm:FindChild("BankOptionsButton"):AttachWindow(self.BankBagForm:FindChild("BankOptionsWindow"))	
	self.BankBagForm:FindChild("BankBagsButton"):AttachWindow(self.BankBagForm:FindChild("BankBagSlotWindow"))	
end

function KuronaBags:RedrawBank(override)

	if self.bStoreLinkValid == nil then
		self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.BankSlots)
	end
	
	self.BankBagForm:FindChild("MainCashWindow"):SetAmount(GameLib.GetPlayerCurrency(), true)
	self.BankBagForm:FindChild("BankWindow"):MarkAllItemsAsSeen()
	self.EmptyBankBagSlots =  self.BankBagForm:FindChild("BankWindow"):GetTotalEmptyBagSlots()
	self:UpdateBankBagItemSlots(override)
	local color ="FFFFFFFF"
	if self.EmptyBankBagSlots == 0 then
		color = "FFFF0000"
	elseif self.EmptyBankBagSlots == 1 then
		color = "FFFFFF00"
	end
		self.BankBagForm:UpdatePixie(2,{
		 strBGColor = color,
		 strText = "",
		 strFont = "Default",
		 bLine = false,
		 strSprite = "KBsprites:Frame",
		 cr = color,
		 loc = {
		 fPoints = {0,0,1,1},
		 nOffsets = {0,0,0,0}
		 },
		 flagsText = {
		 DT_RIGHT = true,
		 }
		})
end

function KuronaBags:UpdateBankBagItemSlots(override)
--F2P function
	-- Configure Screen
	local nNumBagSlots = GameLib.GetNumBankBagSlots()

	self.BankBagForm:FindChild("OptionsConfigureBagsBG"):DestroyChildren()
	
	for idx = 1, GameLib.knMaxBankBagSlots do
		if not self.bStoreLinkValid and idx > nNumBagSlots then
			break
		end
		local idBag = idx + 20
		local wndCurr = Apollo.LoadForm(self.xmlDoc, "BankSlot", self.BankBagForm:FindChild("OptionsConfigureBagsBG"), self)
		local wndBagBtn = Apollo.LoadForm(self.xmlDoc, "BagBtn"..idBag, wndCurr:FindChild("BankSlotFrame"), self)
		if wndBagBtn:GetItem() then
			wndCurr:FindChild("BagCount"):SetText(wndBagBtn:GetItem():GetBagSlots())
		elseif wndBagBtn then
			wndCurr:FindChild("BagCount"):SetText("")
		end
		wndCurr:FindChild("BagCount"):SetData(wndBagBtn)
		wndCurr:FindChild("NewBagPurchasedAlert"):Show(false, true)
		wndBagBtn:Enable(idx <= nNumBagSlots)
		
		if idx > nNumBagSlots + 1 then
			wndCurr:FindChild("BagLocked"):Show(true)
			wndCurr:SetTooltip(Apollo.GetString("Bank_LockedTooltip"))
		elseif idx > nNumBagSlots then
			wndCurr:FindChild("MTXUnlock"):Show(true)
			wndCurr:SetTooltip(Apollo.GetString("Bank_LockedTooltip"))
		else
			wndCurr:SetTooltip(Apollo.GetString("Bank_SlotTooltip"))
		end
	end
	self.BankBagForm:FindChild("OptionsConfigureBagsBG"):ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
end

--[[
function KuronaBags:OnBankBuySlotConfirmYes()
	local curcount = GameLib.GetNumBankBagSlots()
	self:OnBankBuySlotConfirmCancel()
	self:SetBankOptions()
	self:RedrawBank(curcount+1)
	GameLib.BuyBankBagSlot()
end

function KuronaBags:OnBankBuySlotConfirmCancel()
	self.BankBagForm:FindChild("BuyBankBagsButton"):SetCheck(false)
end
]]

--F2P Additions
function KuronaBags:RefreshStoreLink()
	self.bStoreLinkValid = StorefrontLib.IsLinkValid(StorefrontLib.CodeEnumStoreLink.BankSlots)
	if self.BankBagForm and self.BankBagForm:IsValid() then
		self:RedrawBank()
	end
end

function KuronaBags:UnlockMoreBankSlots()
	StorefrontLib.OpenLink(StorefrontLib.CodeEnumStoreLink.BankSlots)
end


function KuronaBags:OnBankViewer_NewBagPurchasedAlert() -- handler for timerNewBagPurchasedAlert -- hide new bag purchased alert when it triggers
	if self.BankBagForm and self.BankBagForm:IsValid() then
		for idx, wndCurr in pairs(self.wndMain:FindChild("OptionsConfigureBagsBG"):GetChildren()) do
			wndCurr:FindChild("NewBagPurchasedAlert"):Show(false)
		end
		self.BankBagForm:FindChild("BankLable"):SetText("KuronaBank")
	end
end

function KuronaBags:OnEntitlementUpdate(tEntitlement)
	if self.BankBagForm and tEntitlement.nEntitlementId == AccountItemLib.CodeEnumEntitlement.ExtraBankSlots then
		self.BankBagForm:FindChild("BankLable"):SetText(Apollo.GetString("Bank_BuySuccess"))
		self.timerNewBagPurchasedAlert:Start()
		self:RedrawBank()
	end
end
