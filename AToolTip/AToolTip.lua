-----------------------------------------------------------------------------------------------
-- Client Lua Script for AToolTip
-- Andrej@Jabbit
-----------------------------------------------------------------------------------------------
require "Window"
require "Item"

-----------------------------------------------------------------------------------------------
-- AToolTip Module Definition
-----------------------------------------------------------------------------------------------
local AToolTip = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knSaveVersion = 1

local kUIBody = "ff39b5d4"
local kUITeal = "ff53aa7f"
local kUIRed = "xkcdReddish"
local kUIGreen = "ff42da00"

local origItemToolTipForm  = nil 

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AToolTip:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

	-- Populates when we first see stat
	-- eProperty = { eProperty, bPrimary, nSortOrder, bShow }
	o.tSettings = {}
	
    return o
end

function AToolTip:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "AToolTip"
	local tDependencies = {
		"ToolTips",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- AToolTip OnLoad
-----------------------------------------------------------------------------------------------
function AToolTip:OnLoad()
    -- Load the form file
	self.xmlDoc = XmlDoc.CreateFromFile("AToolTip.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	local crb = Apollo.GetAddon("ToolTips")
    if crb then
        self:HookToolTip(crb)
    end
end

function AToolTip:HookToolTip(aAddon)
    local origCreateCallNames = aAddon.CreateCallNames
	aAddon.CreateCallNames = function(luaCaller)
        origCreateCallNames(luaCaller) 
        origItemToolTipForm = Tooltip.GetItemTooltipForm
        Tooltip.GetItemTooltipForm = self.ItemToolTip
    end
    return true
end

-----------------------------------------------------------------------------------------------
-- AToolTip OnDocLoaded
-----------------------------------------------------------------------------------------------
function AToolTip:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndOptions = Apollo.LoadForm(self.xmlDoc, "FormOptions", nil, self)
		if self.wndOptions == nil then
			Apollo.AddAddonErrorText(self, "AToolTip: Could not load the options window for some reason.")
			return
		end
	    self.wndOptions:Show(false, true)
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("AToolTip", "OnConfigure", self)
		Apollo.RegisterSlashCommand("atooltip", "OnConfigure", self)
		Apollo.RegisterSlashCommand("att", "OnConfigure", self)
	end
end

-----------------------------------------------------------------------------------------------
-- AToolTip OnSave/Restore
-----------------------------------------------------------------------------------------------
function AToolTip:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	tData = {
		nSaveVersion = knSaveVersion,
		tSettings = self.tSettings,
	}
	return tData
end

function AToolTip:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tSavedData.nSaveVersion ~= knSaveVersion then return end
	for key, value in pairs(tSavedData.tSettings) do
		self.tSettings[key] = value
	end
end

-----------------------------------------------------------------------------------------------
-- AToolTip Functions
-----------------------------------------------------------------------------------------------
-- Flags: bBuyBack, idVendorUnique, itemModData, tGlyphData, arGlyphIds, strMaker, itemCompare, bPermanent, bNotEquipped, tCompare, bInvisibleFrame, bShowSimple, strAppend
function AToolTip:ItemToolTip(wndParent, itemSource, tFlags, nCount)
    local this = Apollo.GetAddon("AToolTip")

	-- Add compare to inspect window
	if itemSource and wndParent and wndParent:GetParent() and (wndParent:GetParent():GetName() == "VisibleSlots" or wndParent:GetParent():GetName() == "SlotInset") then
		local itemEquipped = itemSource:GetEquippedItemForItemType()
		if itemSource ~= itemEquipped then
			tFlags.itemCompare = itemEquipped
		end
	end

    local wndTooltip, wndTooltipComp = origItemToolTipForm(self, wndParent, itemSource, tFlags, nCount)
	
	if wndTooltip then
		-- Filter out costumes
		if itemSource:GetItemFamily() == Item.CodeEnumItem2Family.Costume then
			return wndTooltip, wndTooltipComp
		end
		
		-- We compare the permanent tooltips with equiped items (like links from chat)
		if tFlags.bPermanent and not tFlags.itemCompare then
			tFlags.itemCompare = itemSource:GetEquippedItemForItemType()
		end
		
		local tSourceInfo = itemSource:GetDetailedInfo().tPrimary
		local tCompareInfo = tFlags.itemCompare and tFlags.itemCompare:GetDetailedInfo().tPrimary or nil
		
		-- Item, or the item we're comparing it to, has visible runes
		if (tSourceInfo.tRunes and tSourceInfo.tRunes.arRuneSlots) or (tCompareInfo and tCompareInfo.tRunes and tCompareInfo.tRunes.arRuneSlots) then
			this:AddExtra(wndParent, wndTooltip, wndTooltipComp, tSourceInfo, tCompareInfo)
		end
	end
	
	return wndTooltip, wndTooltipComp
end

function AToolTip:AddExtra(wndParent, wndTooltip, wndTooltipComp, tItem, tItemComp)
	local tItemStats = self:GetRawStats(tItem)
	local tItemCompStats
	if tItemComp then
		tItemCompStats = self:GetRawStats(tItemComp)
		self:CompareStats(tItemStats, tItemCompStats)
	end
	
	-- Set up window
    local wndExtra = Apollo.LoadForm(self.xmlDoc, "FormToolTipExtra", wndTooltip:FindChild("Items"), self)
	local wndSep = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SeparatorDiagonal", wndExtra)
	
	self:TooltipStatHelper(wndExtra, self:SortStats(tItemStats))
	
    -- Adjust tooltip height to fit content
    local nSumHeight = wndExtra:ArrangeChildrenVert() + 5
	wndExtra:SetAnchorOffsets(0, 0, 0, nSumHeight)
    wndTooltip:FindChild("Items"):ArrangeChildrenVert()
    wndTooltip:Move(0, 0, wndTooltip:GetWidth(), wndTooltip:GetHeight() + nSumHeight)
	
	if wndTooltipComp then
		-- Same for second tooltip
	    wndExtra = Apollo.LoadForm(self.xmlDoc, "FormToolTipExtra", wndTooltipComp:FindChild("Items"), self)
		wndSep = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SeparatorDiagonal", wndExtra)
		
		self:TooltipStatHelper(wndExtra, self:SortStats(tItemCompStats))
		
	    nSumHeight = wndExtra:ArrangeChildrenVert() + 5
		wndExtra:SetAnchorOffsets(0, 0, 0, nSumHeight)
	    wndTooltipComp:FindChild("Items"):ArrangeChildrenVert()
	    wndTooltipComp:Move(0, 0, wndTooltipComp:GetWidth(), wndTooltipComp:GetHeight() + nSumHeight)
	end
end

function AToolTip:GetRawStats(tItem)
	local tStats = {}
	local eStatProperty
	
	-- Get primary stats
	if tItem.arInnateProperties then
		for _, tStat in pairs(tItem.arInnateProperties) do
			if self:CheckSettingsForStat(tStat, true) then
				tStats[tStat.eProperty] = { eProperty = tStat.eProperty, nValue = tStat.nValue, nSortOrder = tStat.nSortOrder, bPrimary = true }
			end
		end
	end
	-- Get secondary stats
	if tItem.arBudgetBasedProperties then
		for _, tStat in pairs(tItem.arBudgetBasedProperties) do
			if self:CheckSettingsForStat(tStat, false) then
				tStats[tStat.eProperty] = { eProperty = tStat.eProperty, nValue = tStat.nValue, nSortOrder = tStat.nSortOrder, bPrimary = false }
			end
		end
	end
	-- Remove stats from runes
	if tItem.tRunes and tItem.tRunes.arRuneSlots then
		for _, tRune in pairs(tItem.tRunes.arRuneSlots) do
			if tRune.arProperties and tRune.arProperties[1].nValue then
				eStatProperty = tRune.arProperties[1].eProperty
				if tStats[eStatProperty] then
					tStats[eStatProperty].nValue = tStats[eStatProperty].nValue - tRune.arProperties[1].nValue
					-- Delete redundant
					if tStats[eStatProperty].nValue == 0 then
						tStats[eStatProperty] = nil
					end
				end
			end
		end
	end
	
	return tStats
end

function AToolTip:CheckSettingsForStat(tStat, bPrimary)
	-- No record yet, set default
	if self.tSettings[tStat.eProperty] == nil then
		self.tSettings[tStat.eProperty] = {
			eProperty = tStat.eProperty,
			bPrimary = bPrimary,
			nSortOrder = tStat.nSortOrder,
			bShow = true,
		}
	end
	
	return self.tSettings[tStat.eProperty].bShow
end

function AToolTip:CompareStats(tStats, tStatsComp)
	-- Set all as new
	for _, tData in pairs(tStats) do
		tData.nDiff = tData.nValue
	end
	-- Substract the comparing stats
	for eProperty, tData in pairs(tStatsComp) do
		if tStats[eProperty] then
			tStats[eProperty].nDiff = tStats[eProperty].nValue - tData.nValue
		else
			tStats[eProperty] = {
				eProperty = tData.eProperty,
				nValue = 0,
				nDiff = 0 - tData.nValue,
				nSortOrder = tData.nSortOrder,
				bPrimary = tData.bPrimary,
			}
		end
	end
end

function AToolTip:SortStats(tStats)
	local arSortedStats = {}
    
	for k, v in pairs(tStats) do table.insert(arSortedStats, v) end
	local function fnSort(a, b)
		if a.bPrimary and not b.bPrimary then
			return true
		elseif not a.bPrimary and b.bPrimary then
			return false
		end
		return a.nSortOrder < b.nSortOrder
	end
	table.sort(arSortedStats, fnSort)
	
	return arSortedStats
end

function AToolTip:TooltipStatHelper(wndParent, arSortedStats)
	for _, tStat in pairs(arSortedStats) do
		local wndStat = Apollo.LoadForm("ui\\Tooltips\\TooltipsForms.xml", "SimpleRowSmallML", wndParent)

		local strLine = ""
		local strName = Item.GetPropertyName(tStat.eProperty)
		local nValue = tStat.nValue
		local nDiff = tStat.nDiff

		if not nDiff then
			strLine = String_GetWeaselString(Apollo.GetString("Tooltips_StatEven"), nValue, strName)
		else
			local nDiffRound = math.floor(nDiff * 10) / 10
			if nValue == 0 and nDiff < 0 then -- stat is present on other item and we are 0 - all red
				strLine = string.format("<T TextColor=\"%s\">%s</T>", kUIRed, String_GetWeaselString(Apollo.GetString("Tooltips_StatDiffNew"), nValue, strName, nDiffRound))
			else
				if nDiff == nValue then -- stat not present on other item, we are all green  Tooltips_StatDiffNew
					strLine = string.format("<T TextColor=\"%s\">%s</T>", kUIGreen, String_GetWeaselString(Apollo.GetString("Tooltips_StatLost"), nValue, strName, nDiffRound))
				elseif nDiff > 1 then -- stat present on other item, but we are higher. Diff is green
					local strDiff = string.format("<T TextColor=\"%s\">%s</T>", kUIGreen, String_GetWeaselString(Apollo.GetString("Tooltips_StatUpFloat"), nDiffRound))
					strLine = String_GetWeaselString(Apollo.GetString("Tooltips_StatDiff"), nValue, strName, strDiff)
				elseif nDiff < -1 then -- we are lower than other item : diff is red
					local strDiff = string.format("<T TextColor=\"%s\">%s</T>", kUIRed, String_GetWeaselString(Apollo.GetString("Tooltips_StatDownFloat"), nDiffRound))
					strLine = String_GetWeaselString(Apollo.GetString("Tooltips_StatDiff"), nValue, strName, strDiff)
				else -- we match other item, so no color change
					strLine = String_GetWeaselString(Apollo.GetString("Tooltips_StatEven"), nValue, strName)
				end
			end
		end
		
		if tStat.bPrimary then
			wndStat:SetAML(string.format("<T Font=\"CRB_HeaderSmall\" TextColor=\"%s\">%s</T>", kUITeal, strLine))
		else
			wndStat:SetAML(string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", kUIBody, strLine))
		end
		wndStat:SetHeightToContentHeight()
	end
end

-----------------------------------------------------------------------------------------------
-- AToolTipForm Functions
-----------------------------------------------------------------------------------------------
function AToolTip:OnConfigure()
    self:SetupOptions()
    self.wndOptions:Show(true)
end

function AToolTip:SetupOptions()
	local wndOptionsList = self.wndOptions:FindChild("OptionsList")
	local btnStat
	-- Clear old checkboxes	
	wndOptionsList:DestroyChildren()
	-- Create new ones
	for _, tStat in pairs(self:SortStats(self.tSettings)) do
		btnStat = Apollo.LoadForm(self.xmlDoc, "OptionCheckbox", wndOptionsList)
		btnStat:SetText(Item.GetPropertyName(tStat.eProperty))
		btnStat:SetData(tStat.eProperty)
		btnStat:SetCheck(tStat.bShow)
	end
	wndOptionsList:ArrangeChildrenVert()
end

function AToolTip:OnOptionChange(wndHandler, wndControl, eMouseButton)
	local eProperty = wndControl:GetData()
	local bShow = wndControl:IsChecked()
	
	self.tSettings[eProperty].bShow = bShow
end

function AToolTip:OnClose(wndHandle, wndControl)
	self.wndOptions:Close()
end

-----------------------------------------------------------------------------------------------
-- AToolTip Instance
-----------------------------------------------------------------------------------------------
local AToolTipInst = AToolTip:new()
AToolTipInst:Init()
