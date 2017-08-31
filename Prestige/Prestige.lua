-----------------------------------------------------------------------------------------------
-- 'Prestige' v1.1.6 [30/03/2017] 'Get prestige from bags in inventory/bank/mailbox'
-----------------------------------------------------------------------------------------------

-- v1.1.6 (30/03/2017) 
-- Add ItemId #91011 "Contract Commission (Purple bag)", this is a second version of ItemId #54143.
-- Add ItemId #92291 "Major Mercenary's Payment (Blue bag)" .
 
require "Window"
require "Item"
require "Apollo"
require "GameLib"
require "ChatSystemLib"
require "MailSystemLib"

local Prestige = {} 
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Prestige", true)
 
local MP_Ver = { major = 1, minor = 1, patch = 6, } 
local MP_VER = string.format("%d.%d.%d", MP_Ver.major, MP_Ver.minor, MP_Ver.patch)
local MP_NAME = "Prestige"

local tBagPrestige = {  
						 [1] = { itemid = 71874, prestige = 300 }, 
						 [2] = { itemid = 92291, prestige = 300 }, 
						 [3] = { itemid = 54141, prestige = 52  }, 
						 [4] = { itemid = 91009, prestige = 52  }, 
						 [5] = { itemid = 54142, prestige = 195 }, 
						 [6] = { itemid = 91010, prestige = 195 }, 
						 [7] = { itemid = 91011, prestige = 500 }, 
					     [8] = { itemid = 54143, prestige = 500 }, 
						 [9] = { itemid = 85033, prestige = 32  }, 
						[10] = { itemid = 85035, prestige = 26  }, 
						[11] = { itemid = 44862, prestige = 26  }, 
						[12] = { itemid = 85042, prestige = 35  }, 
						[13] = { itemid = 44857, prestige = 130 }, 
						[14] = { itemid = 85041, prestige = 52  }, 
						[15] = { itemid = 85038, prestige = 32  }, 
						[16] = { itemid = 85034, prestige = 130 }, 
						[17] = { itemid = 42685, prestige = 26  }, 
						[18] = { itemid = 85040, prestige = 32  }, 
					 }	

local _GetAddon			 = Apollo.GetAddon
local _FindWindowByName	 = Apollo.FindWindowByName
local _IsCharacterLoaded = GameLib.IsCharacterLoaded
local _GetPlayerUnit	 = GameLib.GetPlayerUnit
local _PostOnChannel	 = ChatSystemLib.PostOnChannel
local _GetInbox			 = MailSystemLib.GetInbox

local tInStock = {}	
local bForChat = true
local u, tWait

local tAddon = { 
					[1] = { addon = "XPBar", 			 btn = "PickerEntryBtn", 	 oprestige = nil, dosize = nil, 			   wnd = function(o) return o.wndCurrencyDisplay end },   
	                [2] = { addon = "ForgeUI_Inventory", btn = "PickerEntryBtnText", oprestige = nil, dosize = "OptionsContainer", wnd = function(o) return o.wndMain end },			  
					[3] = { addon = "LUI_Frames",		 btn = "PickerEntryBtn",     oprestige = nil, dosize = nil, 			   wnd = function(o) return o.infobar end },              
				}

function Prestige:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Prestige:Init()
	Apollo.RegisterAddon(self, false)
end

function Prestige:OnLoad()
 		
    Apollo.RegisterEventHandler("AvailableMail", "Update", self)	
	Apollo.RegisterEventHandler("ItemAdded", "OnItemAddRem", self)  
    Apollo.RegisterEventHandler("ItemRemoved", "OnItemAddRem", self)  
	Apollo.RegisterEventHandler("ChangeWorld", "OnWait", self) 
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("Generic_OnClickUI", "OnSlash", self)	
	Apollo.RegisterSlashCommand("Prestige", "OnSlash", self)	
	Apollo.RegisterSlashCommand("prestige", "OnSlash", self)
		
	self:OnWait()
end

function Prestige:OnItemAddRem(...)
   	local nItemId = arg[1]:GetItemId()
	for _=1,#tBagPrestige do
		if tBagPrestige[_].itemid == nItemId then
			self:Update()
			break
		end
	end
end

function Prestige:OnWait()
	tWait = ApolloTimer.Create(2, true, "wait", {wait = function()
		for _=1,#tAddon do
			if _GetAddon(tAddon[_].addon) and _IsCharacterLoaded() and _GetPlayerUnit() ~= nil and tWait then
				u = _GetPlayerUnit()
               	self:Update()
				tWait = nil
				break
			end
		end
	end})
end

function Prestige:OnSlash(strCommand, sOption)
	
	local bDetail = false	
	if sOption == "detail" or sOption == "d" then
		bDetail = true
	end
		
	bForChat = true
	self:GetInStock(bDetail)
end

function Prestige:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Prestige", {"Generic_OnClickUI", "", "IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_Achievements"})
	self:UpdateInterfaceMenuAlerts()
end

function Prestige:UpdateInterfaceMenuAlerts()
  	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Prestige", {nil, "v"..MP_VER, nil})
end

function Prestige:Update()
	bForChat = false
	self:GetInStock(false)
end

function Prestige:CheckCurrWindow(nPrestige)
	for _=1,#tAddon do
	    local oA = _GetAddon(tAddon[_].addon)
		if oA then
			local sBtnTarget = tAddon[_].btn			
			local oPrestige = tAddon[_].oprestige		
			local oCurrency = nil
			if oPrestige == nil then 					
			    oCurrency = tAddon[_].wnd(oA)	
                if oCurrency and oCurrency:GetName() ~= "OptionsConfigureCurrency" then
					oCurrency = oCurrency:FindChild("OptionsConfigureCurrency")
				end
				
				if tAddon[_].dosize then				
					local oWnd = tAddon[_].wnd(oA):FindChild(tAddon[_].dosize)
					local l, t, r, b = oWnd:GetAnchorOffsets()
					oWnd:SetAnchorOffsets(l, t, 260, b)
				end
			end
			self:UpdateCurrency(nPrestige, oCurrency, sBtnTarget, _, oPrestige)
		end
	end
end

function Prestige:UpdateCurrency(nPrestige, oCurrency, sBtnTarget, nId, oPrestige)
	
	local sPrestige = Apollo.GetString("CRB_Prestige")
	if oPrestige == nil then
		if oCurrency then
			local tChildren = oCurrency:FindChild("OptionsConfigureCurrencyList"):GetChildren()
			local sDescription = Apollo.GetString("CRB_Prestige_Desc") .. "\n" .. L["P_DESC"]  
				
			for _=1, #tChildren do
			   	if tChildren[_]:FindChild(sBtnTarget):GetText() == sPrestige then
					oPrestige = tChildren[_]:FindChild(sBtnTarget)
					oPrestige:SetTooltip(sDescription)
					break
				end
			end
			tAddon[nId].oprestige = oPrestige
		end
	end	
	if oPrestige then oPrestige:SetText(sPrestige ..  "  [" .. nPrestige .. "]") end
end

local function _ChatStatus(sStatus)
	_PostOnChannel(ChatSystemLib.ChatChannel_Datachron, sStatus, MP_NAME)
end

local tSource = 
{
	[1] = function(u) return u:GetInventoryItems() end,
	[2] = function(u) return u:GetBankItems() end,
	[3] = function()
			 local tMailItems, tMailBox = {}, _GetInbox()
			 for _=1, #tMailBox do
				 local tAttach = tMailBox[_]:GetMessageInfo().arAttachments
			 	 for _=1, #tAttach do
			 	  	 tMailItems[#tMailItems+1] = tAttach[_] 
			 	 end	
			 end
			 return tMailItems
		  end,
}

local tLoc = 
{
	[1] = function() return tInStock.bag end,
	[2] = function() return tInStock.bank end,
	[3] = function() return tInStock.mail end,
} 

local tItemObj = 
{
	[1] = function(i) return i.itemInBag end,
	[2] = function(i) return i.itemInSlot end,
	[3] = function(i) return i.itemAttached end,
} 

local tStack = 
{
	[1] = function(o) return o:GetStackCount() end,
	[2] = function(o) return o:GetStackCount() end,
	[3] = function(o,i) return i.nStackCount end,
} 

local function _SearchIn(nItemId, tItems, nLoc)
	
	if u == nil then return nil end
	local nStack, tBag = 0, nil
					
	for _=1, #tItems do
		local oItem = tItemObj[nLoc](tItems[_])
						
		if oItem:GetItemId() == nItemId then 
		   	local nStackItem = tStack[nLoc](oItem, tItems[_])
			nStack = nStack + nStackItem 
			tBag = { bagid = nItemId, baglink = oItem:GetChatLinkString(), bagquality = oItem:GetItemQuality(), bagcount = nStack }
		end
	end
	return tBag
end

local function _Find()
	
	if u == nil then u = _GetPlayerUnit() end
   	for nLoc = 1, #tSource do
	    local tItems = tSource[nLoc](u)
		local tStock = tLoc[nLoc]()	
	
		for _=1, #tBagPrestige do
			local tFindIn = _SearchIn(tBagPrestige[_].itemid, tItems, nLoc)
			if tFindIn then 
				tStock[#tStock + 1] = tFindIn
				tStock[#tStock].prestige = tFindIn.bagcount * tBagPrestige[_].prestige 
			end
		end
	end
end

function Prestige:GetInStock(bDetail)
		
	tInStock = {
				bag =  {},
				bank = {},
				mail = {},
				}
		
	_Find()
	
	local tStatus, tTempLocStack, tLoc, tSort = {}, {}, {}, {}
	local nAllBag, nPrestige = 0, 0
	
	tStatus[0] = string.rep("-",40)	
	tStatus[2] = "[" .. L["P_DETAIL"] .. "]" .. " /Prestige detail"  
	tStatus[3] = tStatus[0]	
		
	for sName, pLocation in pairs(tInStock) do
		for _=1, #pLocation do
			
			nAllBag = nAllBag + pLocation[_].bagcount
			nPrestige = nPrestige + pLocation[_].prestige
							
			if tLoc[sName] == nil then 
				tLoc[sName] = pLocation[_].bagcount
									
			elseif tLoc[sName] then 
				tLoc[sName] = tLoc[sName] + pLocation[_].bagcount
			end
						
			local tData = { bagcount = pLocation[_].bagcount, bagquality = pLocation[_].bagquality, baglink = pLocation[_].baglink }
						
			if bDetail then
				tTempLocStack[#tTempLocStack+1] = tData
				tTempLocStack[#tTempLocStack].location = L["P_" .. string.upper(sName)]
				tTempLocStack[#tTempLocStack].prestige = pLocation[_].prestige
			else
				if tTempLocStack[pLocation[_].bagid] == nil then 
					tTempLocStack[pLocation[_].bagid] = tData
				elseif tTempLocStack[pLocation[_].bagid] then 
					tTempLocStack[pLocation[_].bagid].bagcount = tTempLocStack[pLocation[_].bagid].bagcount + pLocation[_].bagcount
				end
			end
		end
	end
		
   	tStatus[1] = L["P_HAVE"] .. " " .. nAllBag .. " " .. L["P_BAGS"] .. " (~" .. nPrestige .. " Prestige)"
	for sName, oCount in pairs(tLoc) do
		tStatus[#tStatus + 1] = L["P_" .. string.upper(sName)] .. " = " .. tostring(oCount)
	end
	tStatus[#tStatus + 1] = tStatus[0]
	   
	for nBagid, oBag in pairs(tTempLocStack) do
		tSort[#tSort + 1] = oBag
	end
	
	table.sort(tSort, function(a, b) return (a.bagquality > b.bagquality ) end)
	for _=1, #tSort do
		tStatus[#tStatus + 1] = tSort[_].baglink .. " x " .. tSort[_].bagcount
		if bDetail then tStatus[#tStatus] = tStatus[#tStatus] .. " (~" .. tSort[_].prestige .. " Prestige) " .. L["P_IN"] .. " " .. tSort[_].location end
	end
		
	self:CheckCurrWindow(nPrestige)
	if not bForChat then return end
		
	for _=0, #tStatus do
		_ChatStatus(tStatus[_])
	end
end

local PrestigeInst = Prestige:new()
PrestigeInst:Init()