-----------------------------------------------------------------------------------------------
-- Client Lua Script for HousingDecorSetManager
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "HousingLib"
 
-----------------------------------------------------------------------------------------------
-- HousingDecorSetManager Module Definition
-----------------------------------------------------------------------------------------------
local HousingDecorSetManager = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knSaveVersion = 1
local knTimerDelay = 0.1
local knTimerDelayShort = 0.05
local knDecorListItemsPerLoad = 10
local ktInteriorZones = {412, 434, 435, 436, 437, 438, 439, 440, 441}
local knMaxTextLength = 30720

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function HousingDecorSetManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    o.tSavedData = {
		nSaveVersion = knSaveVersion,
		tDecorSets = {},
	}

    return o
end

function HousingDecorSetManager:Init()
    Apollo.RegisterAddon(self)
end
 
function HousingDecorSetManager:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then
		return
	end

	return self.tSavedData
end

function HousingDecorSetManager:OnRestore(eType, tSavedData)
	if tSavedData and tSavedData.nSaveVersion == knSaveVersion then
		self.tSavedData = tSavedData
	end
end

-----------------------------------------------------------------------------------------------
-- HousingDecorSetManager OnLoad
-----------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("HousingDecorSetManager.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- HousingDecorSetManager OnDocLoaded
-----------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "HousingDecorSetManagerForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
		self.wndNewSet = Apollo.LoadForm(self.xmlDoc, "CreateDecorSetForm", nil, self)
		self.wndCopySet = Apollo.LoadForm(self.xmlDoc, "CopySetForm", nil, self)
		self.wndLoadSet = Apollo.LoadForm(self.xmlDoc, "LoadSetForm", nil, self)
		self.wndPlaceAll = Apollo.LoadForm(self.xmlDoc, "PlaceAllForm", nil, self)
		self.wndPlugWarningPopup = Apollo.LoadForm(self.xmlDoc, "PopupPlugMismatchWarning", nil, self)
		self.wndAddDecorPopup = Apollo.LoadForm(self.xmlDoc, "PopupAddGroup", nil, self)
		
	    self.wndMain:Show(false, true)
		self.wndNewSet:Show(false, true)
		self.wndCopySet:Show(false, true)
		self.wndLoadSet:Show(false, true)
		self.wndPlaceAll:Show(false, true)
		self.wndPlugWarningPopup:Show(false, true)
		self.wndAddDecorPopup:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterEventHandler("HousingPanelControlOpen", 			"OnPropertyEnter", self)
	    Apollo.RegisterEventHandler("HousingPanelControlClose", 		"OnPropertyExit", self)
	    Apollo.RegisterEventHandler("PlayerCurrencyChanged", 			"OnPlayerCurrencyChanged", self)
		Apollo.RegisterSlashCommand("DecorSetMgr",                      "OnHousingDecorSetManagerOn", self)
		Apollo.RegisterSlashCommand("dsm",                              "OnHousingDecorSetManagerOn", self)
		
		self.wndDecorSetListFrame = self.wndMain:FindChild("DecorSetListFrame")
		self.wndDecorListFrame = self.wndMain:FindChild("DecorListFrame")
		
		self.wndOptionsFrame = self.wndMain:FindChild("OptionsFrame")
		self.wndOptionsMinimizeBtn = self.wndOptionsFrame:FindChild("OptionsMinimizeBtn")
		self.wndOptionsPropertyFrame = self.wndOptionsFrame:FindChild("LandscapeOptionsFrame")
		self.wndOptionsCustomizationFrame = self.wndOptionsFrame:FindChild("CustomizationOptionsFrame")
		self.wndInteriorOptionsFrame = self.wndOptionsCustomizationFrame:FindChild("InteriorCustomizationOptionsFrame")
		self.wndExteriorOptionsFrame = self.wndOptionsCustomizationFrame:FindChild("ExteriorCustomizationOptionsFrame")
		self.wndOptionsTooltip = self.wndMain:FindChild("LandscapeRemodelTooltip")
		
		self.wndCashCredit = self.wndMain:FindChild("CashWindowCredit")
		self.wndCashCredit:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
		self.wndCashCredit:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits), true)
		    
		self.wndCashRenown = self.wndMain:FindChild("CashWindowRenown")
		self.wndCashRenown:SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
		self.wndCashRenown:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown), true)
		
		self.wndShareSetBtn = self.wndMain:FindChild("ShareSetBtn")
		self.wndShareSetBtn:Enable(false)
		self.wndDeleteSetBtn = self.wndMain:FindChild("DeleteSetBtn")
		self.wndDeleteSetBtn:Enable(false)
		
		self.wndDecorListFrame = self.wndMain:FindChild("DecorListFrame")
		self.wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
		self.wndDecorLoadingText = self.wndDecorListFrame:FindChild("LoadingText")
		self.wndDecorListBlocker = self.wndDecorListFrame:FindChild("WindowBlocker")
		
		self.wndOptionsMinimizeBtn:SetCheck(true)
		
		Apollo.RegisterTimerHandler("DecorListLoadTimer", 	"OnLoadNextDecorListItems", self)
		Apollo.RegisterTimerHandler("DecorPlacementTimer", 	"OnUpdatePlaceDecor", self)
		Apollo.RegisterTimerHandler("PlaceAllUpdateTimer", 	"OnUpdatePlaceAllDecor", self)
		Apollo.RegisterTimerHandler("PlaceAllUpdateTimerShort", "OnUpdatePlaceAllDecor", self)
		
		Apollo.CreateTimer("DecorListLoadTimer", knTimerDelayShort, false)
		Apollo.CreateTimer("DecorPlacementTimer", knTimerDelay, false)
		Apollo.CreateTimer("PlaceAllUpdateTimer", knTimerDelay, false)
		Apollo.CreateTimer("PlaceAllUpdateTimerShort", knTimerDelayShort, false)
		Apollo.StopTimer("DecorListLoadTimer")
	    Apollo.StopTimer("DecorPlacementTimer")
	    Apollo.StopTimer("PlaceAllUpdateTimer")
		Apollo.StopTimer("PlaceAllUpdateTimerShort")
	end
end

-----------------------------------------------------------------------------------------------
-- HousingDecorSetManager Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/DecorSetMgr"
function HousingDecorSetManager:OnHousingDecorSetManagerOn()
	self.wndMain:Invoke() -- show the window
	
	HousingLib.SetEditMode(true)
	
	local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
    self:ShowDecorSetListItems(wndSetList, self.tSavedData.tDecorSets)
    
    local wndList = self.wndDecorListFrame:FindChild("DecorList")
    wndList:DeleteAll()

	self.wndMain:FindChild("HousingDecorSetForm"):FindChild("BG_ArtHeader"):SetText("")
	
	local nPlotCount = HousingLib.GetResidence():GetPlotCount()
	for idx = 1, nPlotCount do
		self.wndOptionsPropertyFrame:FindChild("Plot"..idx):Enable(false)
		self.wndOptionsPropertyFrame:FindChild("OccupiedSprite."..idx):Show(false)
		self.wndOptionsPropertyFrame:FindChild("WarningSprite."..idx):Show(false)
	end
    
    self:OnPlayerCurrencyChanged()
    
    HousingLib:RefreshUI()
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnPropertyEnter(idPropertyInfo, idZone, bPlayerIsInside)
	if HousingLib.IsHousingWorld() then
	    self.bOnProperty = true
        self.bPlayerIsInside = bPlayerIsInside == true --make sure we get true/false
		self.nIdZone = idZone

        local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
        local nRow = wndList:GetCurrentRow()
        if nRow ~= nil then
            local tDecorSetData = wndList:GetCellData( nRow, 1 )

			self:ShowLandscapeOptions(tDecorSetData.plots)
			self:ShowRemodelOptions(tDecorSetData.intOptions, tDecorSetData.extOptions)
            local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
            self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
		else
			self:ShowRemodelOptions(nil, nil)
    	end
	end	
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnPropertyExit()
	self.bOnProperty = false -- you've left your property!
	self:OnCloseHousingDecorSetManagerWindow()
end

function HousingDecorSetManager:OnPlayerCurrencyChanged()
	if not self.wndMain or not self.wndMain:IsShown() then 
		return 
	end
	
    self.wndCashCredit:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits), true)
    self.wndCashRenown:SetAmount(GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown), true)
end


-----------------------------------------------------------------------------------------------
-- HousingDecorSetManagerForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function HousingDecorSetManager:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function HousingDecorSetManager:OnCancel()
	self.wndMain:Close() -- hide the window
end

function HousingDecorSetManager:OnCloseHousingDecorSetManagerWindow()
    self.wndDecorSetListFrame:FindChild("DecorSetList"):SetCurrentRow(0)
    self.wndDecorListFrame:FindChild("DecorList"):SetCurrentRow(0)
	if self.decorSelection ~= nil then
		self.decorSelection:CancelTransform()
		self.decorSelection = nil
	end
    
    self.wndNewSet:Show(false, true)
    self.wndCopySet:Show(false, true)
    self.wndLoadSet:Show(false, true)
    self.wndPlaceAll:Show(false, true)
	self.wndPlugWarningPopup:Show(false, true)
	self.wndAddDecorPopup:Show(false, true)
		
    Apollo.StopTimer("DecorPlacementTimer")
    
	self.wndMain:Close() -- hide the window
end

function HousingDecorSetManager:OnRestoreOptions( wndHandler, wndControl, eMouseButton )
	local nLeft, nTop, nRight, nBottom = self.wndOptionsFrame:GetAnchorOffsets()
	self.wndOptionsFrame:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 238)
	
	--This is a little hack to make it update the size of the DecorListFrame correctly
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function HousingDecorSetManager:OnMinimizeOptions( wndHandler, wndControl, eMouseButton )
	local nLeft, nTop, nRight, nBottom = self.wndOptionsFrame:GetAnchorOffsets()
	self.wndOptionsFrame:SetAnchorOffsets(nLeft, nTop, nRight, nTop + 37)
	
	--This is a little hack to make it update the size of the DecorListFrame correctly
	local nLeft, nTop, nRight, nBottom = self.wndMain:GetAnchorOffsets()
	self.wndMain:SetAnchorOffsets(nLeft, nTop, nRight, nBottom)
end

function HousingDecorSetManager:OnOpenCreateNewSetWindow(wndHandler, wndControl)
	self.wndNewSet:Show(true, true)
	self.wndNewSet:ToFront()
	local wndSettingsFrame = self.wndNewSet:FindChild("SettingsFrame")
	wndSettingsFrame:SetRadioSel("IncludeDecorRadioGroup", 1)
end

function HousingDecorSetManager:OnPlaceBtn(wndHandler, wndControl)
	local wndList = self.wndDecorListFrame:FindChild("DecorList")
	local nRow = wndList:GetCurrentRow()
	if nRow ~= nil then
		local tDecorData = wndList:GetCellData( nRow, 1 )
		if self:IsDecorAvailable(tDecorData) then
			self:PlaceDecor(tDecorData)
		end
	end
end

function HousingDecorSetManager:OnRemoveFromSetBtn(wndHandler, wndControl)
	local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
	local nRow = wndSetList:GetCurrentRow()
	if nRow ~= nil then
		local tDecorSetData = wndSetList:GetCellData( nRow, 1 )
		
		local wndList = self.wndDecorListFrame:FindChild("DecorList")
		local nRow = wndList:GetCurrentRow()
		if nRow ~= nil then
			local tDecorData = wndList:GetCellData( nRow, 1 )
			
			for idx = 1, #tDecorSetData.decor do
				if tDecorSetData.decor[idx].name == tDecorData.name then
					table.remove(tDecorSetData.decor, idx)
					break
				end
			end
		end
	
		local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
    	self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
	end
end

function HousingDecorSetManager:OnAddToSetBtn(wndHandler, wndControl)
	local decorSelection = HousingLib.GetResidence():GetSelectedDecor()
	if decorSelection ~= nil then
		
		if decorSelection:IsParent() then
			self.wndAddDecorPopup:Show(true)
			self.wndAddDecorPopup:ToFront()
			return
		else
			local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
			local nRow = wndSetList:GetCurrentRow()
			if nRow ~= nil then
				local tDecorSetData = wndSetList:GetCellData( nRow, 1 )
				local tNewDecorEntry = {}
				local tDecorIconInfo = decorSelection:GetDecorIconInfo()
				if tDecorIconInfo ~= nil then
                    local tNewDecorEntry = {}
                    tNewDecorEntry.name = decorSelection:GetName()
					tNewDecorEntry.index = nDecorCount
                    tNewDecorEntry.decorIdLow, tNewDecorEntry.decorIdHi = decorSelection:GetId()
                    tNewDecorEntry.positionX = tDecorIconInfo.fWorldPosX
                    tNewDecorEntry.positionY = tDecorIconInfo.fWorldPosY
                    tNewDecorEntry.positionZ = tDecorIconInfo.fWorldPosZ
                    tNewDecorEntry.pitch = tDecorIconInfo.fPitch
                    tNewDecorEntry.roll = tDecorIconInfo.fRoll
                    tNewDecorEntry.yaw = tDecorIconInfo.fYaw
                    tNewDecorEntry.scale = tDecorIconInfo.fScaleCurrent
					table.insert(tDecorSetData.decor, tNewDecorEntry)
				end
				
				local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
    			self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
			end
		end
	end
end

function HousingDecorSetManager:OnAddDecorCancel(wndHandler, wndControl)
	self.wndAddDecorPopup:Show(false)
end

function HousingDecorSetManager:OnAddGroup(wndHandler, wndControl)
	local decorSelection = HousingLib.GetResidence():GetSelectedDecor()
	if decorSelection ~= nil then
		local tdecorChildren = decorSelection:GetChildren()
		local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
		local nRow = wndSetList:GetCurrentRow()
		if nRow ~= nil then
			local tDecorSetData = wndSetList:GetCellData( nRow, 1 )
			
			-- Add the parent
			local tNewDecorEntry = {}
			local nParentIndex = 0
			local tDecorIconInfo = decorSelection:GetDecorIconInfo()
			if tDecorIconInfo ~= nil then
                local tNewDecorEntry = {}
                tNewDecorEntry.name = decorSelection:GetName()
				tNewDecorEntry.index = nDecorCount
                tNewDecorEntry.decorIdLow, tNewDecorEntry.decorIdHi = decorSelection:GetId()
                tNewDecorEntry.positionX = tDecorIconInfo.fWorldPosX
                tNewDecorEntry.positionY = tDecorIconInfo.fWorldPosY
                tNewDecorEntry.positionZ = tDecorIconInfo.fWorldPosZ
                tNewDecorEntry.pitch = tDecorIconInfo.fPitch
                tNewDecorEntry.roll = tDecorIconInfo.fRoll
                tNewDecorEntry.yaw = tDecorIconInfo.fYaw
                tNewDecorEntry.scale = tDecorIconInfo.fScaleCurrent
				table.insert(tDecorSetData.decor, tNewDecorEntry)
				nParentIndex = #tDecorSetData.decor
			end
			
			-- Add all the children
			for idx = 1, #tdecorChildren do
				local tNewDecorEntry = {}
				local tDecorIconInfo = tdecorChildren[idx]:GetDecorIconInfo()
				if tDecorIconInfo ~= nil then
	                local tNewDecorEntry = {}
	                tNewDecorEntry.name = tdecorChildren[idx]:GetName()
					tNewDecorEntry.index = nDecorCount
	                tNewDecorEntry.decorIdLow, tNewDecorEntry.decorIdHi = tdecorChildren[idx]:GetId()
	                tNewDecorEntry.positionX = tDecorIconInfo.fWorldPosX
	                tNewDecorEntry.positionY = tDecorIconInfo.fWorldPosY
	                tNewDecorEntry.positionZ = tDecorIconInfo.fWorldPosZ
	                tNewDecorEntry.pitch = tDecorIconInfo.fPitch
	                tNewDecorEntry.roll = tDecorIconInfo.fRoll
	                tNewDecorEntry.yaw = tDecorIconInfo.fYaw
	                tNewDecorEntry.scale = tDecorIconInfo.fScaleCurrent
					tNewDecorEntry.parent = nParentIndex
					table.insert(tDecorSetData.decor, tNewDecorEntry)
				end
			end
				
			local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
			self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
		end
	end
end

function HousingDecorSetManager:OnAddSingle(wndHandler, wndControl)
	local decorSelection = HousingLib.GetResidence():GetSelectedDecor()
	if decorSelection ~= nil then
		local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
		local nRow = wndSetList:GetCurrentRow()
		if nRow ~= nil then
			local tDecorSetData = wndSetList:GetCellData( nRow, 1 )
			local tNewDecorEntry = {}
			local tDecorIconInfo = decorSelection:GetDecorIconInfo()
			if tDecorIconInfo ~= nil then
                local tNewDecorEntry = {}
                tNewDecorEntry.name = decorSelection:GetName()
				tNewDecorEntry.index = nDecorCount
                tNewDecorEntry.decorIdLow, tNewDecorEntry.decorIdHi = decorSelection:GetId()
                tNewDecorEntry.positionX = tDecorIconInfo.fWorldPosX
                tNewDecorEntry.positionY = tDecorIconInfo.fWorldPosY
                tNewDecorEntry.positionZ = tDecorIconInfo.fWorldPosZ
                tNewDecorEntry.pitch = tDecorIconInfo.fPitch
                tNewDecorEntry.roll = tDecorIconInfo.fRoll
                tNewDecorEntry.yaw = tDecorIconInfo.fYaw
                tNewDecorEntry.scale = tDecorIconInfo.fScaleCurrent
				table.insert(tDecorSetData.decor, tNewDecorEntry)
			end
			
			local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
			self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
		end
	end
end

function HousingDecorSetManager:OnPlaceAllBtn(wndHandler, wndControl)
    local wndList = self.wndDecorListFrame:FindChild("DecorList")
    local monPlayerCash = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Credits):GetAmount()
    local monPlayerRenown = GameLib.GetPlayerCurrency(Money.CodeEnumCurrencyType.Renown):GetAmount()
    local monTotalCash = 0
    local monTotalRenown = 0

	if not self.confirmedPlaceAll then
		local residence = HousingLib.GetResidence()
		if residence == nil then
			return
		end
		
		local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
		local nRow = wndSetList:GetCurrentRow()
		if nRow ~= nil then
			local tDecorSetData = wndSetList:GetCellData( nRow, 1 )
			if tDecorSetData.plots ~= nil and tDecorSetData.plots ~= {} then
				local nPlotCount = HousingLib.GetResidence():GetPlotCount()
				for idx = 1, nPlotCount do
					local nPlugItemId = tDecorSetData.plots[idx]
					local pltPlot = HousingLib.GetPlot(idx)
					if pltPlot ~= nil and pltPlot:GetPlugItemId() ~= nPlugItemId then
						self.wndPlugWarningPopup:Show(true)
						self.wndPlugWarningPopup:ToFront()
						return
					end
				end
			end
		end
	end
    
	local nDecorCount = wndList:GetRowCount()
	if nDecorCount ~= 0 then
	    local nPlacedDecor = 0
	    self.tPlaceAllDecorList = {}
	    local nCantPlace = 0
	    local tCantPlaceList = {}
	    local tDecorCrateList = HousingLib.GetResidence():GetDecorCrateList()
	    for idx = 1, nDecorCount do 
	        --local tDecorData = wndList:GetCellData( idx, 1 )
			local tDecorData = self.tCurrentDecorList[idx]
	        local tCrateDecorData = nil
            if tDecorCrateList ~= nil and #tDecorCrateList ~= 0 then
                for idy = 1, #tDecorCrateList do
                    local tData = tDecorCrateList[idy]
                    if tData.strName == tDecorData.name then
                        local tDecorIdData = table.remove(tDecorCrateList[idy].tDecorItems)
                        if tDecorIdData ~= nil then
                            tCrateDecorData = {}
                            tCrateDecorData.strName = tData.strName
                            tCrateDecorData.tDecorItems = {}
                            tCrateDecorData.tDecorItems[1] = {}
                            tCrateDecorData.tDecorItems[1].nDecorId = tDecorIdData.nDecorId
                            tCrateDecorData.tDecorItems[1].nDecorIdHi = tDecorIdData.nDecorIdHi
                        end
                        if #tDecorCrateList[idy].tDecorItems == 0 then
                            table.remove(tDecorCrateList, idy)
                        end
						break
                    end
                end
            end
	        local tVendorDecorData = wndList:GetCellData( idx, 2 )
	        --if (tDecorData.positionY < -80 and self.bPlayerIsInside) or (tDecorData.positionY >= -80 and not self.bPlayerIsInside) then
                if tCrateDecorData ~= nil then
                    nPlacedDecor = nPlacedDecor + 1
                    self.tPlaceAllDecorList[nPlacedDecor] = {}
                    self.tPlaceAllDecorList[nPlacedDecor].tCrateDecorData = tCrateDecorData
                    self.tPlaceAllDecorList[nPlacedDecor].tVendorDecorData = nil
                    self.tPlaceAllDecorList[nPlacedDecor].tDecorData = tDecorData
                elseif tVendorDecorData ~= nil then
                    local bCanAfford = false
                    if tVendorDecorData.eCurrencyType == Money.CodeEnumCurrencyType.Credits then
                        monTotalCash = monTotalCash + tVendorDecorData.nCost
                        if monTotalCash <= monPlayerCash then
                            bCanAfford = true
                        end    
                    elseif tVendorDecorData.eCurrencyType == Money.CodeEnumCurrencyType.Renown then
                        monTotalRenown = monTotalRenown + tVendorDecorData.nCost
                        if monTotalRenown <= monPlayerRenown then
                            bCanAfford = true
                        end  
                    end

                    if bCanAfford then
                        nPlacedDecor = nPlacedDecor + 1
                        self.tPlaceAllDecorList[nPlacedDecor] = {}    
                        self.tPlaceAllDecorList[nPlacedDecor].tCrateDecorData = nil
                        self.tPlaceAllDecorList[nPlacedDecor].tVendorDecorData = tVendorDecorData
                        self.tPlaceAllDecorList[nPlacedDecor].tDecorData = tDecorData
                    else
                        nCantPlace = nCantPlace + 1
                        tCantPlaceList[nCantPlace] = tVendorDecorData
                    end
                else
                    nCantPlace = nCantPlace + 1
                    tCantPlaceList[nCantPlace] = tDecorData
                end
            --else
                --nCantPlace = nCantPlace + 1
                --tCantPlaceList[nCantPlace] = tDecorData
	        --end
	    end

	    self.wndPlaceAll:Show(true, true)
	    self.wndPlaceAll:ToFront()
	    local wndVerifyForm = self.wndPlaceAll:FindChild("VerifyPlaceAllForm")
	    wndVerifyForm:Show(true)
	    local wndProgressForm = self.wndPlaceAll:FindChild("PlaceAllProgressForm")
	    wndProgressForm:Show(false)
	    
	    local wndCashTotal = self.wndPlaceAll:FindChild("CashWindowCreditTotal")
	    wndCashTotal:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
		wndCashTotal:SetAmount(monTotalCash, true)
		
	    local wndRenownTotal = self.wndPlaceAll:FindChild("CashWindowRenownTotal")
	    wndRenownTotal:SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
		wndRenownTotal:SetAmount(monTotalRenown, true)
		
	    local wndCashYours = self.wndPlaceAll:FindChild("CashWindowCreditYours")
	    wndCashYours:SetMoneySystem(Money.CodeEnumCurrencyType.Credits)
		wndCashYours:SetAmount(monPlayerCash, true)
		
	    local wndRenownYours = self.wndPlaceAll:FindChild("CashWindowRenownYours")
	    wndRenownYours:SetMoneySystem(Money.CodeEnumCurrencyType.Renown)
		wndRenownYours:SetAmount(monPlayerRenown, true)
		
        local wndDecorList = self.wndPlaceAll:FindChild("DecorList")
        self:ShowPlaceAllListItems(wndDecorList, tCantPlaceList)
	end
end

function HousingDecorSetManager:OnCancelPlaceAllBtn(wndHandler, wndControl)
    self.wndPlaceAll:Show(false, true)
    Apollo.StopTimer("PlaceAllUpdateTimer")
end

function HousingDecorSetManager:OnConfirmPlaceAllBtn(wndHandler, wndControl)
    local wndVerifyForm = self.wndPlaceAll:FindChild("VerifyPlaceAllForm")
    wndVerifyForm:Show(false)
    
    local wndProgressForm = self.wndPlaceAll:FindChild("PlaceAllProgressForm")
    wndProgressForm:Show(true)
    local wndProgressBar = wndProgressForm:FindChild("ProgressBar")
    local nTotalDecor = #self.tPlaceAllDecorList
    wndProgressBar:SetMax(nTotalDecor)
    wndProgressBar:SetProgress(0)
    self.nPlaceAllProgress = 1
	self.nPlaceAllPass = 1
	self.tPlacedDecorList = {}
	
	self.wndPlaceAll:FindChild("CurrentPassLabel"):SetText("Placing Decor...")
    
    self.tCurrentDecorData = nil
    Apollo.StartTimer("PlaceAllUpdateTimer")
end

function HousingDecorSetManager:OnCancelPlaceAllProgressBtn(wndHandler, wndControl)
    Apollo.StopTimer("PlaceAllUpdateTimer")
	if self.decorSelection ~= nil then
		self.decorSelection:CancelTransform()
		self.decorSelection = nil
	end	
	
    self:OnPlaceAllBtn()
end

function HousingDecorSetManager:OnPlaceAllWarningContinue(wndHandler, wndControl)
	self.wndPlugWarningPopup:Show(false)
	self.confirmedPlaceAll = true
	self:OnPlaceAllBtn()
end

function HousingDecorSetManager:OnPlaceAllWarningCancel(wndHandler, wndControl)
	self.wndPlugWarningPopup:Show(false)
end

function HousingDecorSetManager:OnCloseCreateNewDecorSetWindow()
	self.wndNewSet:Show(false, true)
end

function HousingDecorSetManager:OnCancelCreateBtn()
	self.wndNewSet:Show(false, true)
end

function HousingDecorSetManager:OnCreateNewSetBtn(wndHandler, wndControl)
    local wndSettingsFrame = self.wndNewSet:FindChild("SettingsFrame")
    local wndNameEntry = wndSettingsFrame:FindChild("NewNameEntry")
    local strName = wndNameEntry:GetText()
    local nSaveOptions = wndSettingsFrame:GetRadioSel("IncludeDecorRadioGroup")
    
    local nNumSavedSets = #self.tSavedData.tDecorSets
	self.tSavedData.tDecorSets[nNumSavedSets+1] = {}
    self.tSavedData.tDecorSets[nNumSavedSets+1].name = strName
	self.tSavedData.tDecorSets[nNumSavedSets+1].decor = {}
	self.tSavedData.tDecorSets[nNumSavedSets+1].plots = {}
	self.tSavedData.tDecorSets[nNumSavedSets+1].intOptions = {}
	self.tSavedData.tDecorSets[nNumSavedSets+1].extOptions = {}
	
	if wndSettingsFrame:FindChild("IncludeLandscapeOptionsBtn"):IsChecked() then
		local residence = HousingLib.GetResidence()
		if residence == nil then
			return
		end
		
		local nPlotCount = HousingLib.GetResidence():GetPlotCount()
		for idx = 1, nPlotCount do
			local pltPlot = HousingLib.GetPlot(idx)
			if pltPlot ~= nil then
				self.tSavedData.tDecorSets[nNumSavedSets+1].plots[idx] = pltPlot:GetPlugItemId()
			else
				self.tSavedData.tDecorSets[nNumSavedSets+1].plots[idx] = 0
			end
		end
	end
	
	if wndSettingsFrame:FindChild("IncludeRemodelOptionsBtn"):IsChecked() then
		local residence = HousingLib.GetResidence()
		if residence == nil then
			return
		end
		
		local tExtRemodelValues = {}
		for eType = HousingLib.RemodelOptionTypeExterior.Roof, HousingLib.RemodelOptionTypeExterior.Ground do
		    tExtRemodelValues[eType] = nil
		end
		
		local tBakedList	= {}
		tBakedList = residence:GetBakedDecorDetails()
		for key, tData in pairs(tBakedList) do
		    if tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Roof then
				tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] = {nId = tData.nId, strName = tData.strName}
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Wallpaper then
				tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] = {nId = tData.nId, strName = tData.strName}
		    elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Entryway then
				tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entry] = {nId = tData.nId, strName = tData.strName}
            elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Door then
				tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] = {nId = tData.nId, strName = tData.strName}
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Sky then
				tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] = {nId = tData.nId, strName = tData.strName}
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Music then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] = {nId = tData.nId, strName = tData.strName}
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Ground then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] = {nId = tData.nId, strName = tData.strName}
		    end
		end
		
		self.tSavedData.tDecorSets[nNumSavedSets+1].extOptions = tExtRemodelValues
		
		for idx = 1, #ktInteriorZones do
			local tIntRemodelValues = {}
			local tSectorDecorList = residence:GetDecorDetailsBySector(ktInteriorZones[idx])
			for key, tData in pairs(tSectorDecorList) do
				tIntRemodelValues[tData.eType] = {nId = tData.nId, strName = tData.strName}
			end
			self.tSavedData.tDecorSets[nNumSavedSets+1].intOptions[idx] = tIntRemodelValues
		end
	end
    
	if nSaveOptions ~= 4 then
		local tDecorParentList = {}
	    local tDecorList = HousingLib.GetResidence():GetPlacedDecorList()
	    if tDecorList ~= nil then
	        local nDecorCount = 1
	        for idx = 1, #tDecorList do
				local decorCurrent = tDecorList[idx]
				local tDecorIconInfo = decorCurrent:GetDecorIconInfo()
	
				if tDecorIconInfo ~= nil then
					if (nSaveOptions ~= 3 and tDecorIconInfo.fWorldPosY < -80) or (nSaveOptions ~= 2 and tDecorIconInfo.fWorldPosY >= -80) then
	                    local tNewDecorEntry = {}
	                    tNewDecorEntry.name = decorCurrent:GetName()
						tNewDecorEntry.index = nDecorCount
	                    tNewDecorEntry.decorIdLow, tNewDecorEntry.decorIdHi = decorCurrent:GetId()
	                    tNewDecorEntry.positionX = tDecorIconInfo.fWorldPosX
	                    tNewDecorEntry.positionY = tDecorIconInfo.fWorldPosY
	                    tNewDecorEntry.positionZ = tDecorIconInfo.fWorldPosZ
	                    tNewDecorEntry.pitch = tDecorIconInfo.fPitch
	                    tNewDecorEntry.roll = tDecorIconInfo.fRoll
	                    tNewDecorEntry.yaw = tDecorIconInfo.fYaw
	                    tNewDecorEntry.scale = tDecorIconInfo.fScaleCurrent
						tNewDecorEntry.parent = 0
	
						tDecorParentList[nDecorCount] = decorCurrent:GetParent() and decorCurrent:GetParent():GetHandle() or 0
	                    
	                    self.tSavedData.tDecorSets[nNumSavedSets+1].decor[nDecorCount] = tNewDecorEntry
	                    nDecorCount = nDecorCount + 1
	                end
				end
			end	
			
			for idx = 1, #self.tSavedData.tDecorSets[nNumSavedSets+1].decor do
				local nHandle = tDecorParentList[idx]
				local decor = HousingLib.GetResidence():GetDecorByHandle(nHandle)
				if decor ~= nil then
					for idy = 1, #self.tSavedData.tDecorSets[nNumSavedSets+1].decor do
						local decorIdLow = self.tSavedData.tDecorSets[nNumSavedSets+1].decor[idy].decorIdLow
						local decorIdHi = self.tSavedData.tDecorSets[nNumSavedSets+1].decor[idy].decorIdHi
						local decorIdLow2, decorIdHi2 = decor:GetId()
						if decorIdLow == decorIdLow2 and decorIdHi == decorIdHi2 then
							self.tSavedData.tDecorSets[nNumSavedSets+1].decor[idx].parent = idy
							break
						end
					end
				end
			end
	    end
	end
    
    if decorSelection ~= nil then
        decorSelection:Deselect()
    end
    
    local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
    self:ShowDecorSetListItems(wndList, self.tSavedData.tDecorSets)

	self.wndNewSet:Show(false, true)
end

function HousingDecorSetManager:OnDeleteSetBtn(wndHandler, wndControl)
	local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
	local nRow = wndList:GetCurrentRow()
	if nRow ~= nil then
		local tCurrentDecorSetData = wndList:GetCellData( nRow, 1 )
		
		for idx = 1, #self.tSavedData.tDecorSets do
			local tDecorSetData = self.tSavedData.tDecorSets[idx]
			if tDecorSetData == tCurrentDecorSetData  then
				table.remove(self.tSavedData.tDecorSets, idx)
				break
			end
		end
	end
	
	local wndSetList = self.wndDecorSetListFrame:FindChild("DecorSetList")
    self:ShowDecorSetListItems(wndList, self.tSavedData.tDecorSets)
    wndSetList:SetCurrentRow(0)
    
    local wndList = self.wndDecorListFrame:FindChild("DecorList")
    wndList:DeleteAll()
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnDecorSetListItemChange(wndControl, wndHandler, nX, nY)
	-- Preview the selected item
	local nRow = wndControl:GetCurrentRow()
	if nRow ~= nil then
	    local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
		local tDecorSetData = wndList:GetCellData( nRow, 1 )
		
		self:ShowLandscapeOptions(tDecorSetData.plots)
		self:ShowRemodelOptions(tDecorSetData.intOptions, tDecorSetData.extOptions)
		
		local wndList = self.wndDecorListFrame:FindChild("DecorList")
    	self:ShowDecorListItems(wndList, tDecorSetData.decor)

		self.wndMain:FindChild("HousingDecorSetForm"):FindChild("BG_ArtHeader"):SetText(tDecorSetData.name)

		self.wndShareSetBtn:Enable(true)
		self.wndDeleteSetBtn:Enable(true)
		
		self.confirmedPlaceAll = false
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnDecorListItemChange(wndControl, wndHandler, nX, nY)
	-- Preview the selected item
	local nRow = wndControl:GetCurrentRow()
	if nRow ~= nil then
	    local wndList = self.wndDecorListFrame:FindChild("DecorList")
		local tItemData = wndList:GetCellData( nRow, 1 )
		local tVendorDecorData = wndList:GetCellData( nRow, 2 )
        local wndBuyBtn = self.wndMain:FindChild("BuyBtn")
        local wndPlaceBtn = self.wndMain:FindChild("PlaceBtn")
		if tVendorDecorData ~= nil and tVendorDecorData ~= {} then
		    wndBuyBtn:Show(true)
		    wndBuyBtn:Enable(true)
		    wndPlaceBtn:Show(false)
            local eCurrencyType = tVendorDecorData.eCurrencyType
            local eGroupCurrencyType = tVendorDecorData.eGroupCurrencyType
            local monCash = GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType):GetAmount()
            wndBuyBtn:Enable(tVendorDecorData.nCost < monCash)
        else
            wndBuyBtn:Show(false)
		    wndPlaceBtn:Show(true)
		end
		self.wndMain:FindChild("RemoveFromSetBtn"):Enable(true)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:OnOnlyShowToggle()

	local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
	local nRow = wndList:GetCurrentRow()
	if nRow ~= nil then
		local tDecorSetData = wndList:GetCellData( nRow, 1 )
		
		local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
    	self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:IsDecorAvailable(tDecorData)
	-- first check the crate
    if self:IsDecorAvailableInCrate(tDecorData) == true then
        return true
    end    
	
	-- if they dont have that item in their crate, check if it's purchaseable from the vendor
    if self:IsDecorAvailableOnVendor(tDecorData) == true then
        return true
    end   
	
	return false
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:IsDecorAvailableInCrate(tDecorData)
	local tDecorCrateList = HousingLib.GetResidence():GetDecorCrateList()
	if tDecorCrateList ~= nil then
		for idx = 1, #tDecorCrateList do
			local tCratedDecorData = tDecorCrateList[idx]
			if tCratedDecorData.strName == tDecorData.name then
				return true
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:IsDecorAvailableOnVendor(tDecorData)
	local tDecorVendorList = HousingLib.GetDecorCatalogList()
	if tDecorVendorList ~= nil then
		for idx = 1, #tDecorVendorList do
			local tVendorDecorData = tDecorVendorList[idx]
			if tVendorDecorData.strName == tDecorData.name then
				return true
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:GetCrateDecorData(tDecorData)
	local tDecorCrateList = HousingLib.GetResidence():GetDecorCrateList()
	if tDecorCrateList ~= nil then
		for idx = 1, #tDecorCrateList do
			local tCratedDecorData = tDecorCrateList[idx]
			if tCratedDecorData.strName == tDecorData.name then
				return tCratedDecorData
			end
		end
	end
	
	return nil
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:GetVendorDecorData(tDecorData)
	local tDecorVendorList = HousingLib.GetDecorCatalogList()
	if tDecorVendorList ~= nil then
		for idx = 1, #tDecorVendorList do
			local tVendorDecorData = tDecorVendorList[idx]
			if tVendorDecorData.strName == tDecorData.name then
				return tVendorDecorData
			end
		end
	end
	
	return nil
end


---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:PlaceDecor(tDecorData)
	-- first check the crate
	local tDecorCrateList = HousingLib.GetResidence():GetDecorCrateList()
	if tDecorCrateList ~= nil then
		for idx = 1, #tDecorCrateList do
			local tCratedDecorData = tDecorCrateList[idx]
			if tCratedDecorData.strName == tDecorData.name then
				self.decorSelection = HousingLib.PreviewCrateDecorAtLocation(tCratedDecorData.tDecorItems[1].nDecorId, tCratedDecorData.tDecorItems[1].nDecorIdHi, tDecorData.positionX, tDecorData.positionY, tDecorData.positionZ, tDecorData.pitch, tDecorData.roll, tDecorData.yaw, tDecorData.scale)
				self.tCurrentDecorData = tDecorData
				self.bFromCrate = true
				Apollo.StartTimer("DecorPlacementTimer")
				return
			end
		end
	end
	
	-- if they dont have that item in their crate, check if it's purchaseable from the vendor
	local tVendorDecorData = self:GetVendorDecorData(tDecorData)
	if tVendorDecorData ~= nil then
        local eCurrencyType = tVendorDecorData.eCurrencyType
        local eGroupCurrencyType = tVendorDecorData.eGroupCurrencyType
        local monCash = GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType):GetAmount()
        if tVendorDecorData.nCost <= monCash then
            self.decorSelection = HousingLib.PreviewVendorDecorAtLocation(tVendorDecorData.nId, tDecorData.positionX, tDecorData.positionY, tDecorData.positionZ, tDecorData.pitch, tDecorData.roll, tDecorData.yaw, tDecorData.scale)
            self.tCurrentDecorData = tDecorData
            self.bFromCrate = false
            Apollo.StartTimer("DecorPlacementTimer")
            return
        else
            Print("Error! Could not purchase decor. Insufficient funds")
        end        
    end
end

function HousingDecorSetManager:OnUpdatePlaceDecor()
	if self.decorSelection == nil then
		return
	end
	
    self.decorSelection:Place()
    self.tCurrentDecorData = nil
    self.decorSelection = nil
end

function HousingDecorSetManager:OnUpdatePlaceAllDecor()
	if self.nPlaceAllPass == 1 then
	    if self.tCurrentDecorData ~= nil and self.decorSelection ~= nil then
			self.tPlacedDecorList[self.nPlaceAllProgress] = {}
			self.tPlacedDecorList[self.nPlaceAllProgress].nDecorIdLow, self.tPlacedDecorList[self.nPlaceAllProgress].nDecorIdHi = self.decorSelection:GetId()
	        self.decorSelection:Place()
	        
	        local wndProgressForm = self.wndPlaceAll:FindChild("PlaceAllProgressForm")
	        local wndProgressBar = wndProgressForm:FindChild("ProgressBar")
	        self.nPlaceAllProgress = self.nPlaceAllProgress + 1
	        wndProgressBar:SetProgress(self.nPlaceAllProgress)
	    end
	    
	    if self.nPlaceAllProgress <= #self.tPlaceAllDecorList then
	        local tDecorDataSet = self.tPlaceAllDecorList[self.nPlaceAllProgress]
	        self.tCurrentDecorData = tDecorDataSet.tDecorData
	        if tDecorDataSet.tCrateDecorData ~= nil then
	            self.bFromCrate = true
	            self.decorSelection = HousingLib.PreviewCrateDecorAtLocation(tDecorDataSet.tCrateDecorData.tDecorItems[1].nDecorId, tDecorDataSet.tCrateDecorData.tDecorItems[1].nDecorIdHi, self.tCurrentDecorData.positionX, self.tCurrentDecorData.positionY, self.tCurrentDecorData.positionZ, self.tCurrentDecorData.pitch, self.tCurrentDecorData.roll, self.tCurrentDecorData.yaw, self.tCurrentDecorData.scale)
	        elseif tDecorDataSet.tVendorDecorData ~= nil then
	            self.bFromCrate = false
	            self.decorSelection = HousingLib.PreviewVendorDecorAtLocation(tDecorDataSet.tVendorDecorData.nId, self.tCurrentDecorData.positionX, self.tCurrentDecorData.positionY, self.tCurrentDecorData.positionZ, self.tCurrentDecorData.pitch, self.tCurrentDecorData.roll, self.tCurrentDecorData.yaw, self.tCurrentDecorData.scale)
	        end
			self.decorSelection:SetPosition(self.tCurrentDecorData.positionX, self.tCurrentDecorData.positionY, self.tCurrentDecorData.positionZ)
	        if self.decorSelection == nil then
	            Print("Decor preview failed! Skipping this decor.")
	            self.tCurrentDecorData = nil
	        end
	        Apollo.StartTimer("PlaceAllUpdateTimer")
	        return
		else
			self.nPlaceAllPass = 2
			self.nPlaceAllProgress = 1
			self.wndPlaceAll:FindChild("CurrentPassLabel"):SetText("Setting up links...")
			Apollo.StartTimer("PlaceAllUpdateTimer")
			return
	    end
	elseif self.nPlaceAllPass == 2 then
		if self.nPlaceAllProgress <= #self.tPlaceAllDecorList then
	        local tDecorDataSet = self.tPlaceAllDecorList[self.nPlaceAllProgress]
	        self.tCurrentDecorData = tDecorDataSet.tDecorData
	
			local nParentIndex = self.tCurrentDecorData.parent
			if nParentIndex ~= 0 and self.tPlacedDecorList[nParentIndex] ~= nil then
				local decorParent = HousingLib.GetResidence():GetDecorById(self.tPlacedDecorList[nParentIndex].nDecorIdLow, self.tPlacedDecorList[nParentIndex].nDecorIdHi)
				local decorChild = HousingLib.GetResidence():GetDecorById(self.tPlacedDecorList[self.nPlaceAllProgress].nDecorIdLow, self.tPlacedDecorList[self.nPlaceAllProgress].nDecorIdHi)
				if decorChild ~= nil and decorParent ~= nil then
					decorChild:Link(decorParent)
				end
			end
	        local wndProgressForm = self.wndPlaceAll:FindChild("PlaceAllProgressForm")
	        local wndProgressBar = wndProgressForm:FindChild("ProgressBar")
	        self.nPlaceAllProgress = self.nPlaceAllProgress + 1
	        wndProgressBar:SetProgress(self.nPlaceAllProgress)
	
			Apollo.StartTimer("PlaceAllUpdateTimer")
	        return
		end
	end
    
    self.tCurrentDecorData = nil
    self.decorSelection = nil
    
    local wndProgressForm = self.wndPlaceAll:FindChild("PlaceAllProgressForm")
    wndProgressForm:Show(false, true)
    self:OnCancelPlaceAllBtn()
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:ShowDecorSetListItems(wndListControl, tSetList)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if tSetList ~= nil and wndListControl ~= nil then
		-- populate the buttons with the item data
		for idx = 1, #tSetList do
			local tSetData = tSetList[idx]
			wndListControl:AddRow("  " .. tSetData.name, "", tSetData)
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:ShowLandscapeOptions(tLandscapeOptions)
	if tLandscapeOptions == nil or tLandscapeOptions[1] == nil or tLandscapeOptions == {} then
		local nPlotCount = HousingLib.GetResidence():GetPlotCount()
		for idx = 1, nPlotCount do
			self.wndOptionsPropertyFrame:FindChild("Plot"..idx):Enable(false)
			--self.wndOptionsPropertyFrame:FindChild("Plot"..idx):SetTooltip("")
			self.wndOptionsPropertyFrame:FindChild("OccupiedSprite."..idx):Show(false)
			self.wndOptionsPropertyFrame:FindChild("WarningSprite."..idx):Show(false)
		end
		return
	end
	
	local residence = HousingLib.GetResidence()
	if residence == nil then
		return
	end
	
	local nPlotCount = HousingLib.GetResidence():GetPlotCount()
	for idx = 1, nPlotCount do
		local nPlugItemId = tLandscapeOptions[idx]
		self.wndOptionsPropertyFrame:FindChild("OccupiedSprite."..idx):Show(nPlugItemId ~= nil and nPlugItemId ~= 0)
		
		local pltPlot = HousingLib.GetPlot(idx)
		self.wndOptionsPropertyFrame:FindChild("WarningSprite."..idx):Show(pltPlot ~= nil and pltPlot:GetPlugItemId() ~= nPlugItemId)
		
		self.wndOptionsPropertyFrame:FindChild("Plot"..idx):Enable(nPlugItemId ~= 0 or (pltPlot ~= nil and pltPlot:GetPlugItemId() ~= nPlugItemId))
		
		--[[local tPlugItemData = HousingLib.GetPlugItem(nPlugItemId)
		if tPlugItemData ~= nil then
			local tCurrentPlugItemData = HousingLib.GetPlugItem(pltPlot:GetPlugItemId())
			self.wndOptionsPropertyFrame:FindChild("Plot"..idx):SetTooltip("Saved Enhancement: "..tPlugItemData.strName)
		else
			self.wndOptionsPropertyFrame:FindChild("Plot"..idx):SetTooltip("")
		end--]]
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:ShowRemodelOptions(tIntRemodelOptionsList, tExtRemodelOptions)
	local wndIntCustomizationFrame = self.wndOptionsCustomizationFrame:FindChild("InteriorCustomizationOptionsFrame")
	local wndExtCustomizationFrame = self.wndOptionsCustomizationFrame:FindChild("ExteriorCustomizationOptionsFrame")
	
	wndIntCustomizationFrame:Show(self.bPlayerIsInside)
	wndExtCustomizationFrame:Show(not self.bPlayerIsInside)
		
	if self.bPlayerIsInside and tIntRemodelOptionsList ~= nil then
		local nInteriorZoneIndex = 0
		for idx = 1, #ktInteriorZones do
			if ktInteriorZones[idx] == self.nIdZone then
				nInteriorZoneIndex = idx
			end
		end
		
		local tIntRemodelValues = {}
		local tSectorDecorList = HousingLib.GetResidence():GetDecorDetailsBySector(self.nIdZone)
		for key, tData in pairs(tSectorDecorList) do
			tIntRemodelValues[tData.eType] = tData
		end
		
		local tIntRemodelOptions = tIntRemodelOptionsList[nInteriorZoneIndex]
		if tIntRemodelOptions ~= nil then
			if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Ceiling] ~= nil then
		        wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Ceiling].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Ceiling] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Ceiling].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Ceiling].nId then
					wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Ceiling] == nil then
					wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Ceiling"))
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Ceiling] ~= nil then
					wndIntCustomizationFrame:FindChild("CeilingWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
	
		    if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Trim] ~= nil then
		        wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Trim].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Trim] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Trim].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Trim].nId then
					wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Trim] == nil then
					wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Trim"))
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Trim] ~= nil then
					wndIntCustomizationFrame:FindChild("TrimWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
	
		    if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Wallpaper] ~= nil then
	            wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.CodeEnumDecorHookType.Wallpaper].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Wallpaper] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Wallpaper].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Wallpaper].nId then
					wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Wallpaper] == nil then
					wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Wallpaper"))
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Wallpaper] ~= nil then
					wndIntCustomizationFrame:FindChild("WallpaperWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
	        
			if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Floor] ~= nil then
	            wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Floor].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Floor] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Floor].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Floor].nId then
					wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Floor] == nil then
					wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Flooring"))
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Floor] ~= nil then
					wndIntCustomizationFrame:FindChild("FloorWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
	        
			if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Lighting] ~= nil then
		        wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Lighting].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Lighting] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Lighting].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Lighting].nId then
					wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Lighting] == nil then
					wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("Description"):SetText("Default Lighting")
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Lighting] ~= nil then
					wndIntCustomizationFrame:FindChild("LightingWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
	
		    if tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Music] ~= nil then
		        wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("Description"):SetText(tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Music].strName)
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Music] ~= nil and tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Music].nId ~= tIntRemodelOptions[HousingLib.RemodelOptionTypeInterior.Music].nId then
					wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
				elseif tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Music] == nil then
					wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
				else
					wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(false)
				end
			else
				wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("Description"):SetText("Default Music")
				if tIntRemodelValues[HousingLib.RemodelOptionTypeInterior.Music] ~= nil then
					wndIntCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
				end
			end
		end
	end
	
	if not self.bPlayerIsInside and tExtRemodelOptions ~= nil then
		local tExtRemodelValues = {}
		for eType = HousingLib.RemodelOptionTypeExterior.Roof, HousingLib.RemodelOptionTypeExterior.Ground do
		    tExtRemodelValues[eType] = nil
		end
		
		local tBakedList	= {}
		tBakedList = HousingLib.GetResidence():GetBakedDecorDetails()
		for key, tData in pairs(tBakedList) do
		    if tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Roof then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Wallpaper then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] = tData
		    elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Entryway then
                tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entry] = tData 
            elseif tData.eHookType ~= nil and tData.eHookType == HousingLib.CodeEnumDecorHookType.Door then
                tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Sky then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] = tData
		    elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Music then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] = tData
            elseif tData.eType ~= nil and tData.eType == HousingLib.RemodelOptionTypeExterior.Ground then
		        tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] = tData
		    end
		end
		
		if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Roof] ~= nil then
	        wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Roof].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Roof].nId then
				wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] == nil then
				wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Roof"))
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Roof] ~= nil then
				wndExtCustomizationFrame:FindChild("RoofWindow"):FindChild("WarningSprite"):Show(true)
			end
		end

	    if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Wallpaper] ~= nil then
	        wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Wallpaper].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Wallpaper].nId then
				wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] == nil then
				wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Wallpaper"))
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Wallpaper] ~= nil then
				wndExtCustomizationFrame:FindChild("WallsWindow"):FindChild("WarningSprite"):Show(true)
			end
		end

	    if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Entryway] ~= nil then
            wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Entryway].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entryway] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entryway].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Entryway].nId then
				wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entryway] == nil then
				wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Entryway"))
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Entryway] ~= nil then
				wndExtCustomizationFrame:FindChild("EntryWindow"):FindChild("WarningSprite"):Show(true)
			end
		end
        
		if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Door] ~= nil then
            wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Door].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Door].nId then
				wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] == nil then
				wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("Description"):SetText("Default Door")
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Door] ~= nil then
				wndExtCustomizationFrame:FindChild("DoorWindow"):FindChild("WarningSprite"):Show(true)
			end
		end
        
		if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Sky] ~= nil then
	        wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Sky].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Sky].nId then
				wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] == nil then
				wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("Description"):SetText("Default Sky")
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Sky] ~= nil then
				wndExtCustomizationFrame:FindChild("SkyWindow"):FindChild("WarningSprite"):Show(true)
			end
		end

	    if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Music] ~= nil then
	        wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Music].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Music].nId then
				wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] == nil then
				wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("Description"):SetText("Default Music")
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Music] ~= nil then
				wndExtCustomizationFrame:FindChild("MusicWindow"):FindChild("WarningSprite"):Show(true)
			end
		end

        if tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Ground] ~= nil then
	        wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("Description"):SetText(tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Ground].strName)
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] ~= nil and tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground].nId ~= tExtRemodelOptions[HousingLib.RemodelOptionTypeExterior.Ground].nId then
				wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("WarningSprite"):Show(true)
			elseif tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] == nil then
				wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("WarningSprite"):Show(true)
			else
				wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("WarningSprite"):Show(false)
			end
		else
			wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("Description"):SetText(Apollo.GetString("CRB_Default_Ground"))
			if tExtRemodelValues[HousingLib.RemodelOptionTypeExterior.Ground] ~= nil then
				wndExtCustomizationFrame:FindChild("GroundWindow"):FindChild("WarningSprite"):Show(true)
			end
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:ShowDecorListItems(wndListControl, tDecorList)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if tDecorList ~= nil and wndListControl ~= nil then
		self.wndDecorLoadingText:Show(true)
		self.wndDecorListBlocker:Show(true)
		wndListControl:Enable(false)
	
		self.tCurrentDecorList = tDecorList
		self.nDecorListLoadIndex = 1
		self:OnLoadNextDecorListItems()
	end
end

function HousingDecorSetManager:OnLoadNextDecorListItems()
	local wndListControl = self.wndDecorList
	if self.tCurrentDecorList ~= nil and wndListControl  ~= nil then
		for idx = self.nDecorListLoadIndex, self.nDecorListLoadIndex + knDecorListItemsPerLoad do
			local tDecorData = self.tCurrentDecorList[idx]
			if tDecorData ~= nil then
				self.nDecorListLoadIndex = self.nDecorListLoadIndex + 1
				local bPrune = false
				local bIsInCrate = self:IsDecorAvailableInCrate(tDecorData)
				local tVendorDecorData = self:GetVendorDecorData(tDecorData)  
				
				local bFilterNotOwned = self.wndDecorListFrame:FindChild("ShowOwnedOnlyBtn"):IsChecked()
				
				if bFilterNotOwned and not bIsInCrate then
				    bPrune = true
				end
				
				if self.nDecorListFilter == 2 and tDecorData.positionY >= -80 then
					-- Interior Only
					bPrune = true
				elseif self.nDecorListFilter == 3 and tDecorData.positionY < -80 then
					-- Exterior only
					bPrune = true
				end
	            
	            if not bPrune then
	               	wndListControl:AddRow("  " .. tDecorData.name, "", tDecorData )
	               	
	               	--if (tDecorData.positionY < -80 and not self.bPlayerIsInside) or (tDecorData.positionY >= -80 and self.bPlayerIsInside) then
						--wndListControl:EnableRow(idx, false)
					--end
					wndListControl:SetCellData(idx, 2, "", "", tVendorDecorData)
	                
	                if not bIsInCrate and tVendorDecorData ~= nil then
	                    local eCurrencyType = tVendorDecorData.eCurrencyType
	                    local eGroupCurrencyType = tVendorDecorData.eGroupCurrencyType
	                    local monCash = GameLib.GetPlayerCurrency(eCurrencyType, eGroupCurrencyType):GetAmount()
	
	                    self.wndCashCredit:SetMoneySystem(eCurrencyType, eGroupCurrencyType)
	
	                    if tVendorDecorData.nCost > monCash then
	                        strDoc = self.wndCashCredit:GetAMLDocForAmount(tVendorDecorData.nCost, true, crRed)
	                    else
	                        strDoc = self.wndCashCredit:GetAMLDocForAmount(tVendorDecorData.nCost, true, crWhite)
	                    end
						
						wndListControl:SetCellDoc(idx, 2, strDoc)
	                    
	                    self.wndCashCredit:SetMoneySystem(Money.CodeEnumCurrencyType.Credits, 0)
	                elseif not bIsInCrate and tVendorDecorData == nil then
	                    wndListControl:EnableRow(idx, false)
	                end
				end
			end
			
			if self.nDecorListLoadIndex > #self.tCurrentDecorList then
				break
			end
		end
		
		if self.nDecorListLoadIndex <= #self.tCurrentDecorList then
			Apollo.StartTimer("DecorListLoadTimer")
		else
			self.wndDecorLoadingText:Show(false)
			self.wndDecorListBlocker:Show(false)
			wndListControl:Enable(true)
			Apollo.StopTimer("DecorListLoadTimer")
		end
	end
end

---------------------------------------------------------------------------------------------------
function HousingDecorSetManager:ShowPlaceAllListItems(wndListControl, tDecorList)
	if wndListControl ~= nil then
		wndListControl:DeleteAll()
	end

	if tDecorList~= nil and wndListControl ~= nil then
		-- populate the buttons with the item data
		for idx = 1, #tDecorList do
			local tDecorData = tDecorList[idx]
			
			if tDecorData.name ~= nil then
			    wndListControl:AddRow("  " .. tDecorData.name, "", tDecorData )
			    if (tDecorData.positionY < -80 and not self.bPlayerIsInside) or (tDecorData.positionY >= -80 and self.bPlayerIsInside) then
                    wndListControl:EnableRow(idx, false)
                end
			elseif tDecorData.eCurrencyType == nil then
                wndListControl:AddRow("  " .. tDecorData.strName, "", tDecorData )
            elseif tDecorData.strName ~= nil then
                wndListControl:AddRow("  " .. tDecorData.strName, "", tDecorData )
                
                local eCurrencyType = tDecorData.eCurrencyType
                local eGroupCurrencyType = tDecorData.eGroupCurrencyType
                local wndCash = self.wndPlaceAll:FindChild("CashWindowCreditTotal")
                wndCash:SetMoneySystem(eCurrencyType, eGroupCurrencyType)
                strDoc = wndCash:GetAMLDocForAmount(tDecorData.nCost, true, crRed)
                
                wndListControl:SetCellDoc(idx, 2, strDoc)
                
                wndCash:SetMoneySystem(Money.CodeEnumCurrencyType.Credits, 0)
            end
            

		end
	end
end

---------------------------------------------------------------------------------------------------
-- CopySetForm Functions
---------------------------------------------------------------------------------------------------

function HousingDecorSetManager:OnShareSetBtn(wndHandler, wndControl)
	local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
	local nRow = wndList:GetCurrentRow()
	if nRow ~= nil then
		self.wndCopySet:Show(true, true)
		self.wndCopySet:ToFront()
		
		local wndTextBox = self.wndCopySet:FindChild("TextEditBox")
		
		local tDecorSetData = wndList:GetCellData( nRow, 1 )
		tDecorSetData = self:ConvertSaveToSimpleData(tDecorSetData)
		local strEncodedSet = self:SaveTable(tDecorSetData)
		
		self.nCurrentPage = 1
		self.nNumPages = 1
		self.strEncodedSetPageList = {}
		if string.len(strEncodedSet) > knMaxTextLength then
			local nNumPages = 1
			local nStrIndex = 1
			local strEncodedSetPageList = {}
			while string.len(strEncodedSet) > knMaxTextLength do
				local pageText = string.sub(strEncodedSet, 1, knMaxTextLength)
				strEncodedSetPageList[nNumPages] = pageText
				
				nNumPages = nNumPages + 1
				strEncodedSet = string.sub(strEncodedSet, knMaxTextLength + 1)
			end
			strEncodedSetPageList[nNumPages] = strEncodedSet
			self.nNumPages = nNumPages
			self.strEncodedSetPageList = strEncodedSetPageList
			
			wndTextBox:SetText(strEncodedSetPageList[1])
			self.wndCopySet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
			self.wndCopySet:FindChild("PrevBtn"):Enable(false)
			self.wndCopySet:FindChild("NextBtn"):Enable(true)
		else
			wndTextBox:SetText(strEncodedSet)
			self.wndCopySet:FindChild("CurrentPageText"):SetText("1/1")
			self.wndCopySet:FindChild("PrevBtn"):Enable(false)
			self.wndCopySet:FindChild("NextBtn"):Enable(false)
		end
	end
end

function HousingDecorSetManager:OnCloseCopySetWindow(wndHandler, wndControl)
	self.wndCopySet:Show(false, true)
end

function HousingDecorSetManager:OnPrevBtn(wndHandler, wndControl)
	self.nCurrentPage = self.nCurrentPage - 1
	if self.nCurrentPage == 1 then
		self.wndCopySet:FindChild("PrevBtn"):Enable(false)
	end
	self.wndCopySet:FindChild("NextBtn"):Enable(true)
	self.wndCopySet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
	self.wndCopySet:FindChild("TextEditBox"):SetText(self.strEncodedSetPageList[self.nCurrentPage])
end

function HousingDecorSetManager:OnNextBtn(wndHandler, wndControl)
	self.nCurrentPage = self.nCurrentPage + 1
	if self.nCurrentPage >= self.nNumPages then
		self.wndCopySet:FindChild("NextBtn"):Enable(false)
	end
	self.wndCopySet:FindChild("PrevBtn"):Enable(true)
	self.wndCopySet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
	self.wndCopySet:FindChild("TextEditBox"):SetText(self.strEncodedSetPageList[self.nCurrentPage])
end

---------------------------------------------------------------------------------------------------
-- LoadSetForm Functions
---------------------------------------------------------------------------------------------------

function HousingDecorSetManager:OnOpenSetBtn(wndHandler, wndControl)
	self.wndLoadSet:Show(true, true)
	self.wndLoadSet:ToFront()
	local wndTextBox = self.wndLoadSet:FindChild("TextEditBox")
	wndTextBox:SetText("")
	local wndCreateBtn = self.wndLoadSet:FindChild("CreateSetBtn")
	wndCreateBtn:Enable(false)
	local wndNameEntry = self.wndLoadSet:FindChild("NewNameEntry")
	wndNameEntry:SetText("")
	wndNameEntry:Enable(false)
	
	self.wndLoadSet:FindChild("PrevBtn"):Enable(false)
	self.wndLoadSet:FindChild("NextBtn"):Enable(false)
	self.wndLoadSet:FindChild("CurrentPageText"):SetText("1/1")
	self.nCurrentPage = 1
	self.nNumPages = 1
	self.strEncodedSetPageList = {}
end

function HousingDecorSetManager:OnCancelLoadSetBtn(wndHandler, wndControl)
	self.wndLoadSet:Show(false, true)
end

function HousingDecorSetManager:OnLoadSetEditBoxChanged( wndHandler, wndControl, strText )
	local wndTextBox = self.wndCopySet:FindChild("TextEditBox")
	if strText  ~= nil and strText ~= "" then
		local wndCreateBtn = self.wndLoadSet:FindChild("CreateSetBtn")
		wndCreateBtn:Enable(true)
		
		self.strEncodedSetPageList[self.nCurrentPage] = strText
		local wndNameEntry = self.wndLoadSet:FindChild("NewNameEntry")
		wndNameEntry:Enable(true)
		
		--[[local tDecodedTable = self:LoadTable(strText)
		if tDecodedTable ~= nil then
		    tDecodedTable = self:ConvertSimpleToSaveData(tDecodedTable)
			if tDecodedTable.name ~= nil then
				local wndNameEntry = self.wndLoadSet:FindChild("NewNameEntry")
				wndNameEntry:SetText(tDecodedTable.name)
				wndNameEntry:Enable(true)
			end
		end--]]
	end
end

function HousingDecorSetManager:OnCreateSetBtn(wndHandler, wndControl)
	local nNumSavedSets = #self.tSavedData.tDecorSets
	self.tSavedData.tDecorSets[nNumSavedSets+1] = {}
	
	local strText = ""
	for idx = 1, self.nNumPages do
		strText = strText .. self.strEncodedSetPageList[idx]
	end
	
	--local wndTextBox = self.wndLoadSet:FindChild("TextEditBox")
	--local strText = wndTextBox:GetText()
	local tDecodedTable = self:LoadTable(strText)
	if tDecodedTable ~= nil then
	    tDecodedTable = self:ConvertSimpleToSaveData(tDecodedTable)
		self.tSavedData.tDecorSets[nNumSavedSets+1] = tDecodedTable
		local wndNameEntry = self.wndLoadSet:FindChild("NewNameEntry")
		local strName = wndNameEntry:GetText()
    	self.tSavedData.tDecorSets[nNumSavedSets+1].name = strName
	end

	local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
    self:ShowDecorSetListItems(wndList, self.tSavedData.tDecorSets)

	self.wndLoadSet:Show(false, true)
end

function HousingDecorSetManager:OnLoadSetPrevBtn(wndHandler, wndControl)
	self.nCurrentPage = self.nCurrentPage - 1
	if self.nCurrentPage == 1 then
		self.wndLoadSet:FindChild("PrevBtn"):Enable(false)
	end
	self.wndLoadSet:FindChild("NextBtn"):Enable(true)
	self.wndLoadSet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
	self.wndLoadSet:FindChild("TextEditBox"):SetText(self.strEncodedSetPageList[self.nCurrentPage])
end

function HousingDecorSetManager:OnLoadSetNextBtn(wndHandler, wndControl)
	self.nCurrentPage = self.nCurrentPage + 1
	if self.nCurrentPage >= self.nNumPages then
		self.wndLoadSet:FindChild("NextBtn"):Enable(false)
	end
	self.wndLoadSet:FindChild("PrevBtn"):Enable(true)
	self.wndLoadSet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
	self.wndLoadSet:FindChild("TextEditBox"):SetText(self.strEncodedSetPageList[self.nCurrentPage])
end

function HousingDecorSetManager:OnAddPageBtn(wndHandler, wndControl)
	self.nNumPages = self.nNumPages + 1
	self.nCurrentPage = self.nCurrentPage + 1
	self.wndLoadSet:FindChild("PrevBtn"):Enable(true)
	self.wndLoadSet:FindChild("CurrentPageText"):SetText(self.nCurrentPage.."/"..self.nNumPages)
	self.wndLoadSet:FindChild("TextEditBox"):SetText("")
end


function HousingDecorSetManager:OnMouseEnterPlot(wndHandler, wndControl, x, y)
	local nPlotCount = HousingLib.GetResidence():GetPlotCount()
	for idx = 1, nPlotCount do
		if wndControl == self.wndOptionsPropertyFrame:FindChild("Plot"..idx) then
			local pltPlot = HousingLib.GetPlot(idx)
			local tPlugData = pltPlot ~= nil and HousingLib.GetPlugItem(pltPlot:GetPlugItemId()) or nil
			
			local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
        	local nRow = wndList:GetCurrentRow()
        	if nRow ~= nil then
            	local tDecorSetData = wndList:GetCellData( nRow, 1 )
				local tPlugItemData = HousingLib.GetPlugItem(tDecorSetData.plots[idx])
				self.wndOptionsTooltip:FindChild("SavedLandscapeOptionText"):SetText(tPlugItemData ~= nil and tPlugItemData.strName or "[Empty]")
				
				--[[local strCurrentPlugText = ""
				if tDecorSetData.plots[idx] ~= pltPlot:GetPlugItemId() then
					strCurrentPlugText = string.format("<T TextColor=\"UI_WindowTextRed\">%s</T>", tPlugData ~= nil and tPlugData.strName or "[Empty]")
				else
					strCurrentPlugText = string.format("<T TextColor=\"UI_WindowTextDefault\">%s</T>", tPlugData ~= nil and tPlugData.strName or "[Empty]")
				end--]]
				self.wndOptionsTooltip:FindChild("CurrentLandscapeOptionText"):SetText(tPlugData ~= nil and tPlugData.strName or "[Empty]")
				self.wndOptionsTooltip:Show(true)
				local tMousePos = Apollo.GetMouse()
				self.wndOptionsTooltip:Move(tMousePos.x/2, tMousePos.y/2, self.wndOptionsTooltip:GetWidth(), self.wndOptionsTooltip:GetHeight())
			end
			return
		end
	end
end

function HousingDecorSetManager:OnMouseExitPlot(wndHandler, wndControl, x, y)
	local nPlotCount = HousingLib.GetResidence():GetPlotCount()
	for idx = 1, nPlotCount do
		if wndControl == self.wndOptionsPropertyFrame:FindChild("Plot"..idx) then
			if not self.wndOptionsPropertyFrame:FindChild("Plot"..idx):ContainsMouse() then
				self.wndOptionsTooltip:Show(false)
				return
			end
		end
	end
end

function HousingDecorSetManager:OnViewDropdownBtnCheck( wndHandler, wndControl, eMouseButton )
    self.wndDecorListFrame:FindChild("ViewDropdownWindow"):Show(true)
end

function HousingDecorSetManager:OnViewDropdownBtnUncheck( wndHandler, wndControl, eMouseButton )
    self.wndDecorListFrame:FindChild("ViewDropdownWindow"):Show(false)
end

function HousingDecorSetManager:OnViewBtnChecked( wndHandler, wndControl, eMouseButton )
	local wndDropdown = self.wndDecorListFrame:FindChild("ViewDropdownWindow")
	self.nDecorListFilter = wndDropdown:GetRadioSel("ViewSettingsBtn")
    self.wndDecorListFrame:FindChild("ViewDropdownLabel"):SetText("View: "..wndDropdown:FindChild("ViewBtn"..self.nDecorListFilter):GetText())

	self.wndDecorListFrame:FindChild("ViewDropdownBtn"):SetCheck(false)
	wndDropdown:Show(false)
	
	local wndList = self.wndDecorSetListFrame:FindChild("DecorSetList")
	local nRow = wndList:GetCurrentRow()
	if nRow ~= nil then
		local tDecorSetData = wndList:GetCellData( nRow, 1 )
		
		local wndDecorList = self.wndDecorListFrame:FindChild("DecorList")
    	self:ShowDecorListItems(wndDecorList, tDecorSetData.decor)
	end

	return true
end

-----------------------------------------------------------------------------------------------
-- Initialization of CassPkg to encode and decode tables with base64
-- Credit to "Casstiel" on official wildstar forums
-----------------------------------------------------------------------------------------------
-- from http://help.interfaceware.com/kb/112
function HousingDecorSetManager:SaveTable(Table)
   local savedTables = {} -- used to record tables that have been saved, so that we do not go into an infinite recursion
   local outFuncs = {
      ['string']  = function(value) return string.format("%q",value) end;
      ['boolean'] = function(value) if (value) then return 'true' else return 'false' end end;
      ['number']  = function(value) if (math.floor(value) == value) then return string.format('%u',math.floor(value)) else return string.format('%.3f',value) end end;
      ['userdata']  = function(value) return 'nil' end;
   }
   local outFuncsMeta = {
      __index = function(t,k) error('Invalid Type For SaveTable: '..k ) end      
   }
   setmetatable(outFuncs,outFuncsMeta)
   local tableOut = function(value)
      if (savedTables[value]) then
         error('There is a cyclical reference (table value referencing another table value) in this set.');
      end
      local outValue = function(value) return outFuncs[type(value)](value) end
      local out = '{'
      for i,v in pairs(value) do out = out..'['..outValue(i)..']='..outValue(v)..',' end
      savedTables[value] = true; --record that it has already been saved
      return out..'}'
   end
   outFuncs['table'] = tableOut;
   --return self:ascii_encode(tableOut(Table))
   return tableOut(Table)
end

function HousingDecorSetManager:LoadTable(Input)
   -- note that this does not enforce anything, for simplicity
   --local decoded = self:ascii_decode(Input)
   return assert(loadstring('return '.. Input ))()
end

-- converting
function HousingDecorSetManager:ConvertSaveToSimpleData(tSaveData)
    tSimpleData = {}

	local tStringMap = {}
	local tNameHeaderData = {}
	local index = 1
	for idx = 1, #tSaveData.decor do
		if tStringMap[tSaveData.decor[idx].name] == nil then
			tStringMap[tSaveData.decor[idx].name] = index
			tNameHeaderData[index] = tSaveData.decor[idx].name
			index = index + 1
		end
	end
    
    tSimpleData.name = tSaveData.name
	tSimpleData.text = tNameHeaderData
	tSimpleData.plugs = tSaveData.plots
	
	tSimpleData.extOptions = tSaveData.extOptions
	tSimpleData.intOptions = tSaveData.intOptions
	
	tSimpleData.decor = {}
    for idx = 1, #tSaveData.decor do
        tSimpleData.decor[idx] = {}
        tSimpleData.decor[idx].n = tStringMap[tSaveData.decor[idx].name]
        tSimpleData.decor[idx].x = tSaveData.decor[idx].positionX
        tSimpleData.decor[idx].y = tSaveData.decor[idx].positionY
        tSimpleData.decor[idx].z = tSaveData.decor[idx].positionZ
		if math.abs(tSaveData.decor[idx].pitch) >= 0.001 then
        	tSimpleData.decor[idx].p = tSaveData.decor[idx].pitch
		end
		if math.abs(tSaveData.decor[idx].roll) >= 0.001 then
        	tSimpleData.decor[idx].r = tSaveData.decor[idx].roll
		end
		if math.abs(tSaveData.decor[idx].yaw) >= 0.001 then
        	tSimpleData.decor[idx].ya = tSaveData.decor[idx].yaw
		end
		if math.abs(tSaveData.decor[idx].scale - 1.0) >= 0.001 then
        	tSimpleData.decor[idx].s = tSaveData.decor[idx].scale
		end
    end
    
    return tSimpleData
end

function HousingDecorSetManager:ConvertSimpleToSaveData(tSimpleData)
    tSaveData = {}

	local tNameHeaderData = tSimpleData.text
    
    tSaveData.name = tSimpleData.name
	tSaveData.plots = tSimpleData.plugs
	
	tSaveData.extOptions = tSimpleData.extOptions
	tSaveData.intOptions = tSimpleData.intOptions


    tSaveData.decor = {}
    for idx = 1, #tSimpleData.decor do
        tSaveData.decor[idx] = {}
        tSaveData.decor[idx].name = tNameHeaderData[tSimpleData.decor[idx].n]
        tSaveData.decor[idx].positionX = tSimpleData.decor[idx].x
        tSaveData.decor[idx].positionY = tSimpleData.decor[idx].y
        tSaveData.decor[idx].positionZ = tSimpleData.decor[idx].z
		if tSimpleData.decor[idx].p ~= nil then
        	tSaveData.decor[idx].pitch = tSimpleData.decor[idx].p
		else
			tSaveData.decor[idx].pitch = 0.0
		end
		if tSimpleData.decor[idx].r ~= nil then
        	tSaveData.decor[idx].roll = tSimpleData.decor[idx].r
		else
			tSaveData.decor[idx].roll = 0.0
		end
		if tSimpleData.decor[idx].ya ~= nil then
        	tSaveData.decor[idx].yaw = tSimpleData.decor[idx].ya
		else
			tSaveData.decor[idx].yaw = 0.0
		end
		if tSimpleData.decor[idx].s ~= nil then
        	tSaveData.decor[idx].scale = tSimpleData.decor[idx].s
		else
			tSaveData.decor[idx].scale = 1.0
		end
    end
    
    return tSaveData
end

--====================================================================--
-- Module: Ascii 85 Encoding in Pure Lua
-- Author : Satheesh
-- 
-- License: MIT

--====================================================================--

function HousingDecorSetManager:decimalToBase85(num)
    local base = 85

    local final = {}
    while num > 0 do
        table.insert(final,1,num % base)
        num = math.floor(num / base)
    end

    while #final < 5 do
        table.insert(final,1,0)
    end

    return final
end

function HousingDecorSetManager:base85ToDecimal(b85)
    local base = 85

    local l = #b85
    local final = 0

    for i=l,1,-1 do
        local digit = b85[i]
        local val = digit * base^(l-i)
        final = final + val
    end

    return final
end

function HousingDecorSetManager:decimalToBinary(num)
    local base = 2
    local bits = 8

    local final = ""
    while num > 0 do
        final = "" .. (num % base ) .. final
        num = math.floor(num / base)
    end

    local l = final:len()
        if l == 0 then
        final = "0"..final
    end

    while final:len()%8 ~=0 do
        final = "0"..final
    end

    return final
end

function HousingDecorSetManager:binaryToDecimal(bin)
    local base = 2

    local l = bin:len()
    local final = 0

    for i=l,1,-1 do
        local digit = bin:sub(i,i)
        local val = digit * base^(l-i)
        final = final + val
    end
    return final
end

function HousingDecorSetManager:encode(substr)
    local l = substr:len()
    local combine = ""
    for i=1,l do
        local char = substr:sub(i,i)
        local byte = char:byte()
        local bin = self:decimalToBinary(byte)
        combine = combine..bin
    end

    local num = self:binaryToDecimal(combine)
    local b85 = self:decimalToBase85(num)

    local final = ""
    for i=1,#b85 do
        local char = tostring(b85[i]+33)
        final = final .. char:char()
    end

    if final == "!!!!!" then
        final = "z"
    end

    return final
end

function HousingDecorSetManager:decode(substr)
    local final = ""

    local l = substr:len()
    local combine = {}
    for i=1,l do
        local char = substr:sub(i,i)
        local byte = char:byte()	
        byte = byte - 33
        combine[i] = byte
    end

    local num = self:base85ToDecimal(combine)	
    local bin = self:decimalToBinary(num)

    while bin:len() < 32 do
        bin = "0"..bin
    end

    local l = bin:len()
    local split = 8
    for i=1,l,split do
        local sub = bin:sub(i,i+split-1)
        local byte = self:binaryToDecimal(sub)
        local char = tostring(byte):char()
        final = final..char
    end

    return final
end

function HousingDecorSetManager:ascii_encode(str)
    local final = ""

    local noOfZeros = 0
    while str:len()%4~=0 do
        noOfZeros = noOfZeros + 1
        str = str.."\0"
    end

    local l = str:len()

    for i=1,l,4 do
        local sub = str:sub(i,i+3)
        final = final .. self:encode(sub)
    end

    final = final:sub(1,-noOfZeros-1)
    final = "<~"..final.."~>"
    return final
end

function HousingDecorSetManager:ascii_decode(str)
    local final = ""

    str = str:sub(3,-3)
    str = str:gsub("z","!!!!!")

    local c = 5
    local noOfZeros = 0
    while str:len()%c~=0 do
        noOfZeros = noOfZeros + 1
        str = str.."u"
    end


    local l = str:len()
    for i=1,l,c do
        local sub = str:sub(i,i+c-1)
        final = final .. self:decode(sub)
    end

    final = final:sub(1,-noOfZeros-1)
    return final
end

-----------------------------------------------------------------------------------------------
-- HousingDecorSetManager Instance
-----------------------------------------------------------------------------------------------
local HousingDecorSetManagerInst = HousingDecorSetManager:new()
HousingDecorSetManagerInst:Init()
