--****************************************************************************************************
-- Client Lua Script for CREDDBroker
-- Copyright (c) NCsoft. All rights reserved
-- Created by SpielePhilosoph - http://www.curse.com/users/SpielePhilosoph/projects
-- Last modified: 201407015
-- Version: 0.4
--****************************************************************************************************
 
--****************************************************************************************************
-- List of used libs, that need for this addon.
--****************************************************************************************************
require "Apollo"
require "CREDDExchangeLib"
require "Window"

--****************************************************************************************************
-- CREDDBroker Module Definition
--****************************************************************************************************
local CREDDBroker = {}

--****************************************************************************************************
-- CREDDBroker Variables
--****************************************************************************************************
-- Infos for debugging the addon.
local ShowDebugInfos = false
-- Functions for debug use:
-- Event_FireGenericEvent("SendVarToRover", "itemName", item) -- Send a item to rover for detail validation.
-- Print(debug.traceback()) -- Prints the current stacktrace.

local ColorBuy = "UI_TextHoloBody" -- Colour to mark buy prices.
local ColorSell = "ffc2e57f" -- Colour to mark sell prices.

local ConfigMinVersion = 2 -- Minumum version for config data to load it.
local PixieHelper = nil -- Lib instance for use.
local PixieHelperVersion = "SpielePhilosoph:Lib:PixieHelper-0.1" -- Lib name and version.
--****************************************************************************************************
-- Initialization
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- CREDDBroker new
------------------------------------------------------------------------------------------------------
function CREDDBroker:new(o)
 o = o or {}
 setmetatable(o, self)
 self.__index = self 

 o.Config = {} -- Property to save and load config data.
 o.Config.DiagramOptions = -- ConfigOptions for the diagramm.
 {
  HiddenRealmList = {}, -- List of realms that data should now shown.
  ShowAmountData = true, -- Show amount data points.
  ShowBuyData = true, -- Show buy data.
  ShowPriceData = true, -- Show price data points.
  ShowSellData = true, -- Show sell data.
  TimeSpan = 48, -- Hours to show history data.
 }
 o.Config.HistoryDataBuy = {} -- Historic information on buy orders.
 o.Config.HistoryDataSell = {} -- Historic information on sell orders.
 o.Config.IsVisible = true -- Per default the main window is shown.
 o.Config.LastDataBuy = {} -- Last information on buy order for a realm.
 o.Config.LastDataSell = {} -- Last information on Sell order for a realm.
 o.Config.PositionHistory = -- Default position for CreddBrokerHistoricForm.
 {
  Bottom = -100,
  Left = 200,
  Right = 800,
  Top = 100,
 }
 o.Config.PositionMain = -- Default position for CreddBrokerForm.
 {
  Bottom = 200,
  Left = 0,
  Right = 190,
  Top = 100,
 }
 o.Config.RealmList = {} -- List of realms that have data stored.
 o.Config.TimeSpanDeleteData = 35 -- Time span in days to delete data from history.
 o.Config.TimeSpanUpdateData = 30 -- Time span in seconds to check data for changes.
 o.Config.Version = 2 -- Version of config.
 return o
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker Init
------------------------------------------------------------------------------------------------------
function CREDDBroker:Init()
 local bHasConfigureFunction = true
 local strConfigureButtonText = "C.R.E.D.D. Broker"
 local tDependencies =
 {
  PixieHelperVersion,
 }
 if ShowDebugInfos == true then
  -- For debug make sure, that Chat and Rover ist loaded an can be used.
  table.insert(tDependencies, "ChatLog")
  table.insert(tDependencies, "Rover")
 end
 Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

--****************************************************************************************************
-- Eventfunctions for CREDDBroker
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- CREDDBroker OnCreddBrokerCall
-- On SlashCommand "/cbroker" or menu item was clicked.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnCreddBrokerCall()
 if self.MainForm:IsShown() == true then
  self:MainHide()
 else
  self:MainShow()
 end
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnCreddBrokerUpdateData
-- This function trigger the CREDDExchangeInfoResults event.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnCreddBrokerUpdateData()
 CREDDExchangeLib.RequestExchangeInfo()
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnCreddExchangeInfoResults
-- This function is triggered for CREDDExchangeInfoResults event.
-- Update the shown data and saves historic informations.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnCreddExchangeInfoResults(marketData, orderData)
 if marketData ~= nil then
  local updateHistory = false
  local time = self:GetTimeString()
  local realm = GameLib.GetRealmName()
  local buyData =
  {
   OrderCount = marketData.nBuyOrderCount,
   Price1 = marketData.arBuyOrderPrices[1].monPrice:GetAmount(),
   Price10 = marketData.arBuyOrderPrices[2].monPrice:GetAmount(),
   Price50 = marketData.arBuyOrderPrices[3].monPrice:GetAmount(),
   Realm = realm,
   Time = time
  }
  local currentBuy = self.BuyItem:GetData()
  local lastBuy = self.Config.LastDataBuy[realm]
  if currentBuy == nil or
     (currentBuy ~= nil and
      (buyData.OrderCount ~= currentBuy.OrderCount or
       buyData.Price1 ~= currentBuy.Price1 or
       buyData.Price10 ~= currentBuy.Price10 or
       buyData.Price50 ~= currentBuy.Price50)) then
   self.BuyItem:SetData(buyData)
   self:UpdateItem(true)
  end
  if lastBuy == nil or
      (lastBuy ~= nil and
       (buyData.OrderCount ~= lastBuy.OrderCount or
        buyData.Price1 ~= lastBuy.Price1 or
        buyData.Price10 ~= lastBuy.Price10 or
        buyData.Price50 ~= lastBuy.Price50)) then
   self.Config.LastDataBuy[realm] = buyData
   table.insert(self.Config.HistoryDataBuy, buyData)
   updateHistory = true
  end
  local sellData =
  {
   OrderCount = marketData.nSellOrderCount,
   Price1 = marketData.arSellOrderPrices[1].monPrice:GetAmount(),
   Price10 = marketData.arSellOrderPrices[2].monPrice:GetAmount(),
   Price50 = marketData.arSellOrderPrices[3].monPrice:GetAmount(),
   Realm = realm,
   Time = time,
  }
  local currentSell = self.SellItem:GetData()
  local lastSell = self.Config.LastDataSell[realm]
  if currentSell == nil or
     (currentSell ~= nil and
      (sellData.OrderCount ~= currentSell.OrderCount or
       sellData.Price1 ~= currentSell.Price1 or
       sellData.Price10 ~= currentSell.Price10 or
       sellData.Price50 ~= currentSell.Price50)) then
   self.SellItem:SetData(sellData)
   self:UpdateItem(false)
  end
  if lastSell == nil or
     (lastSell ~= nil and
      (sellData.OrderCount ~= lastSell.OrderCount or
       sellData.Price1 ~= lastSell.Price1 or
       sellData.Price10 ~= lastSell.Price10 or
       sellData.Price50 ~= lastSell.Price50)) then
   self.Config.LastDataSell[realm] = sellData
   table.insert(self.Config.HistoryDataSell, sellData)
   updateHistory = true
  end
  if self.HistoryForm:IsVisible() == true and
     updateHistory == true then
   self:OnButtonSignalHistory()
  end
 end -- marketData ~= nil
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnConfigure
-- Open the config tab if configuration is called.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnConfigure()
 if self.HistoryForm ~= nil then
  self:OnButtonSignalHistory()
  self.BuyTab:Show(false, true)
  self.DiagramTab:Show(false, true)
  self.OptionsTab:Show(true, false)
  self.SellTab:Show(false, true)
 end
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnDocLoaded
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnDocLoaded()
 if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
  self.MainForm = Apollo.LoadForm(self.xmlDoc, "CreddBrokerForm", nil, self)
  self.HistoryForm = Apollo.LoadForm(self.xmlDoc, "CreddBrokerHistoryForm", nil, self)
  if self.MainForm == nil or
     self.HistoryForm == nil then
   Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
  else
    -- For preparing data the forms are generally and immediately hidden.
    self.MainForm:Show(false, true)
    self.HistoryForm:Show(false, true)
    self:FadeChild(false)
    if self.Config ~= nil then
     -- Restore saved window positions.
     if self.Config.PositionMain ~= nil then
      self.MainForm:SetAnchorOffsets(
       self.Config.PositionMain.Left,
       self.Config.PositionMain.Top,
       self.Config.PositionMain.Right,
       self.Config.PositionMain.Bottom)
     end
     if self.Config.PositionHistory ~= nil then
      self.HistoryForm:SetAnchorOffsets(
       self.Config.PositionHistory.Left,
       self.Config.PositionHistory.Top,
       self.Config.PositionHistory.Right,
       self.Config.PositionHistory.Bottom)
     end
    end
   -- Prepare two items to show infos for current top buy and sell order.
   local parent = self.MainForm:FindChild("ItemContainer")
   self.BuyItem = Apollo.LoadForm(self.xmlDoc, "CreddItem", parent, self)
   self.BuyItem:FindChild("Price"):SetTextColor(ColorBuy)
   self.SellItem = Apollo.LoadForm(self.xmlDoc, "CreddItem", parent, self)
   self.SellItem:FindChild("Price"):SetTextColor(ColorSell)
   parent:ArrangeChildrenVert()
   -- Combine sell tab and buy tab together.
   self.BuyTab = self.HistoryForm:FindChild("BuyTab")
   self.SellTab = self.HistoryForm:FindChild("SellTab")
   self.DiagramTab = self.HistoryForm:FindChild("DiagramTab")
   self.OptionsTab = self.HistoryForm:FindChild("OptionsTab")
   self.BuyTab:AttachTab(self.SellTab, false)
   self.BuyTab:AttachTab(self.DiagramTab, false)
   self.BuyTab:AttachTab(self.OptionsTab, false)

   -- Register slash command and menu item to open the main window.
   Apollo.RegisterSlashCommand("cbroker", "OnCreddBrokerCall", self)
   Apollo.RegisterSlashCommand("credd", "OnCreddBrokerCall", self)
   Apollo.RegisterEventHandler("CreddBrokerMenuClicked", "OnCreddBrokerCall", self)
   Apollo.RegisterEventHandler("CREDDExchangeInfoResults", "OnCreddExchangeInfoResults", self)
   -- Register to add entries to window management.
   Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)

   -- This timer will request the current market data and stores changes in datafile.
   -- The timer will run generally to collect historic data.
   Apollo.RegisterTimerHandler("CreddBrokerUpdateData", "OnCreddBrokerUpdateData", self)
   Apollo.CreateTimer("CreddBrokerUpdateData", self.Config.TimeSpanUpdateData, true)
   Apollo.StartTimer("CreddBrokerUpdateData")

   -- Open the main form if it was visible before.
   if self.Config ~= nil and
      self.Config.IsVisible == true then
    self:MainShow()
   end
  end
 end
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnInterfaceMenuListHasLoaded
-- Adds a menu entry for this addon.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnInterfaceMenuListHasLoaded()
 Event_FireGenericEvent(
  "InterfaceMenuList_NewAddOn",
  "C.R.E.D.D. Broker",
  {
   "CreddBrokerMenuClicked",
   "",
   "Icon_Windows32_UI_CRB_InterfaceMenu_Credd"
  })
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnLoad
-- Load the form xml file.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnLoad()
 self.xmlDoc = XmlDoc.CreateFromFile("CREDDBroker.xml")
 self.xmlDoc:RegisterCallback("OnDocLoaded", self)
 -- Access to libar< instances.
 PixieHelper = Apollo.GetPackage(PixieHelperVersion).tPackage
 -- Register for the InterfaceMenuListHasLoaded event to add a own menu item.
 Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnRestore
-- Load the saved data for the addon.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnRestore(type, savedData)
 if type == GameLib.CodeEnumAddonSaveLevel.General then
  if savedData ~= nil and
     savedData.Version ~= nil then
   if savedData.Version == 1 then
    -- Migration path from version 1 to version 2. Use the defaults and create realm list.
    savedData.DiagramOptions = self.Config.DiagramOptions
    savedData.RealmList = self.Config.RealmList
    savedData.TimeSpanDeleteData = self.Config.TimeSpanDeleteData
    savedData.TimeSpanUpdateData = self.Config.TimeSpanUpdateData
    self:UpdateRealmList(savedData)
    savedData.Version = 2
   end
   if savedData.Version >= ConfigMinVersion then
    -- Saved configs only used if they compatible with the minimum version.
    self.Config = savedData
   end
  end
 end
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnSave
-- Save the data for the addon.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnSave(eType)
 local result = nil
 if eType == GameLib.CodeEnumAddonSaveLevel.General then
  result = self.Config
 end
 return result
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker OnWindowManagementReady
-- Add forms to addon window management.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowManagementReady()
 Event_FireGenericEvent("WindowManagementAdd", {wnd = self.MainForm, strName = "C.R.E.D.D. Broker"})
 Event_FireGenericEvent("WindowManagementAdd", {wnd = self.HistoryForm, strName = "C.R.E.D.D. Broker History"})
end

--****************************************************************************************************
-- Eventfunctions for CreddBrokerForm
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- CreddBrokerForm OnButtonSignalClose
-- Closes the main window.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalClose( wndHandler, wndControl, eMouseButton )
 self:MainHide()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerForm OnButtonSignalHistory
-- Shows the full historic data.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalHistory( wndHandler, wndControl, eMouseButton )
 self.HistoryForm:Show(true, false)
 -- Prepare the listed data.
 self:UpdateTabItems(self.BuyTab, self.Config.HistoryDataBuy, ColorBuy)
 self:UpdateTabItems(self.SellTab, self.Config.HistoryDataSell, ColorSell)
 -- Update diragram tab.
 self:UpdateDiagram()
 -- Set data for the option tab.
 self.OptionsTab:FindChild("BrokerUpdateTimeValue"):SetText(self.Config.TimeSpanUpdateData)
 self.OptionsTab:FindChild("BrokerDeleteHistoryValue"):SetText(self.Config.TimeSpanDeleteData)
 self.OptionsTab:FindChild("DiagramTimeSpanValue"):SetText(self.Config.DiagramOptions.TimeSpan)
 self.OptionsTab:FindChild("ShowAmountData"):SetCheck(self.Config.DiagramOptions.ShowAmountData)
 self.OptionsTab:FindChild("ShowBuyData"):SetCheck(self.Config.DiagramOptions.ShowBuyData)
 self.OptionsTab:FindChild("ShowPriceData"):SetCheck(self.Config.DiagramOptions.ShowPriceData)
 self.OptionsTab:FindChild("ShowSellData"):SetCheck(self.Config.DiagramOptions.ShowSellData)
 self:UpdateRealmItems()
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker IsInList
-- Retruns true if the items exist in the table otherwise false.
------------------------------------------------------------------------------------------------------
function CREDDBroker:IsInList(table, itemToFind)
 local result = false
 if table ~= nil and
    itemToFind~= nil then
  for position, item in pairs(table) do
   if item == itemToFind then
    result = true
    break
   end
  end
 end
 return result
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerForm OnWindowFrameMouseEnter
-- Shows titel, history button and close button.
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowFrameMouseEnter( wndHandler, wndControl, x, y )
 self:FadeChild(true)
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerForm OnWindowFrameMouseExit
-- Hides titel, history button and close button.
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowFrameMouseExit( wndHandler, wndControl, x, y )
 self:FadeChild(false)
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerForm OnWindowMoveMain
-- Saves the position after moving window in config data.
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowMoveMain( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
 self.Config.PositionMain = self:GetPosition(self.MainForm)
end

--****************************************************************************************************
-- Eventfunctions for CreddBrokerHistoryForm
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonCheckShowAmountData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonCheckShowAmountData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowAmountData = true
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonCheckShowBuyData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonCheckShowBuyData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowBuyData = true
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonCheckShowPriceData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonCheckShowPriceData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowPriceData = true
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonCheckShowSellData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonCheckShowSellData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowSellData = true
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonSignalDeleteBrokerHistory
-- Update config option and delete history data.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalDeleteBrokerHistory( wndHandler, wndControl, eMouseButton )
 local value = nil
 value = tonumber(self.OptionsTab:FindChild("BrokerDeleteHistoryValue"):GetText())
 if value ~= nil then
  self.Config.TimeSpanDeleteData = value
  if self.Config.TimeSpanDeleteData == 0 then
   -- Delete all saved data.
   self.Config.DiagramOptions.HiddenRealmList = {}
   self.Config.HistoryDataBuy = {}
   self.Config.HistoryDataSell = {}
   self.Config.LastDataBuy = {}
   self.Config.LastDataSell = {}
   self.Config.RealmList = {}
  else -- if self.Config.TimeSpanDeleteData == 0
   -- Prepare timestring to delete data that older than this.
   local timeNow = self:GetTime(self:GetTimeString()) -- Retun the server time in seconds to calculate time tifferences.
   local timeSpan = self.Config.TimeSpanDeleteData * 24 * 60 * 60 -- Collect data for the timespan set in config. Timespan is given in days.
   local timeFilter = os.date("%Y-%m-%dT%H:%M:%S", (timeNow - timeSpan)) -- Format the new time as string YYYY-MM-DDThh:mm:ss to filter data.
   table.sort(self.Config.HistoryDataBuy, function(a,b) return a.Time > b.Time end)
   for position, item in pairs(self.Config.HistoryDataBuy) do
    if item.Time < timeFilter then
     -- This item is older then the timespan. Delete all items from end to the current position.
     for i = table.getn(self.Config.HistoryDataBuy), position, -1 do
      table.remove(self.Config.HistoryDataBuy, i)
     end
     break
    end
   end
   table.sort(self.Config.HistoryDataSell, function(a,b) return a.Time > b.Time end)
   for position, item in pairs(self.Config.HistoryDataSell) do
    if item.Time < timeFilter then
     -- This item is older then the timespan. Delete all items from end to the current position.
     for i = table.getn(self.Config.HistoryDataSell), position, -1 do
      table.remove(self.Config.HistoryDataSell, i)
     end
     break
    end
   end
  end -- if self.Config.TimeSpanDeleteData == 0
  self:UpdateRealmList(self.Config)
  self:UpdateTabItems(self.BuyTab, self.Config.HistoryDataBuy, ColorBuy)
  self:UpdateTabItems(self.SellTab, self.Config.HistoryDataSell, ColorSell)
  self:UpdateDiagram()
  self:UpdateRealmItems()
 end -- if value ~= nil
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonSignalHistoryClose
-- Close the history form.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalHistoryClose( wndHandler, wndControl, eMouseButton )
 self.HistoryForm:Show(false, false)
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonSignalUpdateBrokerTimer
-- Update config option and recreate timer.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalUpdateBrokerTimer( wndHandler, wndControl, eMouseButton )
 local value = nil
 value = tonumber(self.OptionsTab:FindChild("BrokerUpdateTimeValue"):GetText())
 if value ~= nil then
  self.Config.TimeSpanUpdateData = value
  Apollo.StopTimer("CreddBrokerUpdateData")
  Apollo.CreateTimer("CreddBrokerUpdateData", self.Config.TimeSpanUpdateData, true)
  Apollo.StartTimer("CreddBrokerUpdateData")
 end
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonSignalUpdateHistoryTimeSpan
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalUpdateHistoryTimeSpan( wndHandler, wndControl, eMouseButton )
 local value = nil
 value = tonumber(self.OptionsTab:FindChild("DiagramTimeSpanValue"):GetText())
 if value ~= nil then
  self.Config.DiagramOptions.TimeSpan = value
  self:UpdateDiagram()
 end
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonUncheckShowAmountData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonUncheckShowAmountData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowAmountData = false
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonUncheckShowShowBuyData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonUncheckShowShowBuyData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowBuyData = false
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonUncheckShowPriceData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonUncheckShowPriceData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowPriceData = false
 self:UpdateDiagram()
end

------------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonUncheckShowSellData
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonUncheckShowSellData( wndHandler, wndControl, eMouseButton )
 self.Config.DiagramOptions.ShowSellData = false
 self:UpdateDiagram()
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnButtonSignalHistoryClose
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonSignalRemoveItem( wndHandler, wndControl, eMouseButton )
 if wndHandler ~= nil then
  -- Get the data item that is set for the CreddHistoryItem.
  local data = wndHandler:GetParent():GetData()
  local tableData = nil
  if self.BuyTab:IsVisible() == true then
   tableData = self.Config.HistoryDataBuy
  elseif self.SellTab:IsVisible() == true then
   tableData = self.Config.HistoryDataSell
  end
  if tableData ~= nil then
   -- Find the data entry for the given data. Normaly the timestamp should be uniqe because you can only collect data from one realm.
   for position, item in pairs(tableData) do
    if item.Time == data.Time then
     table.remove(tableData, position)
     break;
    end
   end
   if self.BuyTab:IsVisible() == true then
    self:UpdateTabItems(self.BuyTab, self.Config.HistoryDataBuy, ColorBuy)
   elseif self.SellTab:IsVisible() == true then
    self:UpdateTabItems(self.SellTab, self.Config.HistoryDataSell, ColorSell)
   end
   self:UpdateRealmList(self.Config)
   self:UpdateDiagram()
  end -- if tableData ~= nil
 end -- if wndHandler ~= nil
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnWindowMoveHistory
-- Saves the position after moving window in config data.
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowMoveHistory( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
 self.Config.PositionHistory = self:GetPosition(self.HistoryForm)
end

---------------------------------------------------------------------------------------------------
-- CreddBrokerHistoryForm OnWindowSizeChangedHistory
-- Saves the position after rezise window in config data.
---------------------------------------------------------------------------------------------------
function CREDDBroker:OnWindowSizeChangedHistory( wndHandler, wndControl )
 self.Config.PositionHistory = self:GetPosition(self.HistoryForm)
end

--****************************************************************************************************
-- CREDDBroker Helper Functions
--****************************************************************************************************
---------------------------------------------------------------------------------------------------
-- CreddBroker FadeChild
-- This function change the visibility of some child controls. Use true to shown and false is hide them.
---------------------------------------------------------------------------------------------------
function CREDDBroker:FadeChild( show)
 self.MainForm:FindChild("Close"):Show(show, false)
 self.MainForm:FindChild("HistoricData"):Show(show, false)
 self.MainForm:FindChild("Titel"):Show(show, false)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker GetPosition
-- Returns the position of the form as table.
------------------------------------------------------------------------------------------------------
function CREDDBroker:GetPosition(form)
 local result = nil
 if form ~= nil then
  local leftAnchor, topAnchor, rightAnchor, bottomAnchor = form:GetAnchorOffsets()
  result =
  {
   Bottom = bottomAnchor,
   Left = leftAnchor,
   Right = rightAnchor,
   Top = topAnchor,
  }
 end
 return result
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker GetTimeString
-- Return the server time as string in this format: YYYY-MM-DDThh:mm:ss
------------------------------------------------------------------------------------------------------
function CREDDBroker:GetTimeString(time)
 local result = ""
 local time = time or GameLib.GetServerTime()
 local day = time.nDay
 if day < 10 then
  day = "0" .. day
 end
 local month = time.nMonth
 if month < 10 then
  month = "0" .. month
 end
 result = time.nYear .. "-" .. month .. "-" .. day .. "T" .. time.strFormattedTime
 return result
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker GetTimeString
-- Convert the time string from this format: YYYY-MM-DDThh:mm:ss back into a regular time instance.
------------------------------------------------------------------------------------------------------
function CREDDBroker:GetTime(timeString)
 return os.time(
 {
  year = string.sub(timeString, 1, 4),
  month = string.sub(timeString, 6, 7),
  day = string.sub(timeString, 9, 10),
  hour = string.sub(timeString, 12, 13),
  min = string.sub(timeString, 15, 16),
  sec = string.sub(timeString, 18, 19),
 })
end
------------------------------------------------------------------------------------------------------
-- CREDDBroker MainHide
-- Closes main form.
------------------------------------------------------------------------------------------------------
function CREDDBroker:MainHide()
 -- Set config that main form is not visible.
 self.Config.IsVisible = false
 -- Hide windows.
 self.MainForm:Show(false, false)
 self.HistoryForm:Show(false, false)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker MainShow
-- Opens main form and do preparations.
------------------------------------------------------------------------------------------------------
function CREDDBroker:MainShow()
 -- Set the config that the main is visible.
 self.Config.IsVisible = true
 -- Request credd data update.
 self:OnCreddBrokerUpdateData()
 self.MainForm:Show(true, false)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker UpdateDiagram
-- Updates diagram tab.
------------------------------------------------------------------------------------------------------
function CREDDBroker:UpdateDiagram()
 -- Prepare data to show it in the diagramm. First get the filter string for date.
 local timeNow = self:GetTime(self:GetTimeString()) -- Retun the server time in seconds to calculate time tifferences.
 timeNow = timeNow + (self.Config.DiagramOptions.TimeSpan * 0.05 * 60 * 60) -- Add 5% from time span to show last points in the grid.
 local timeSpan = (self.Config.DiagramOptions.TimeSpan * 60 * 60) - (self.Config.DiagramOptions.TimeSpan * 0.01 * 60 * 60) -- Collect data for the timespan set in config. Timespan is given in hours.
 local timeFilter = os.date("%Y-%m-%dT%H:%M:%S", (timeNow - timeSpan)) -- Format the new time as string YYYY-MM-DDThh:mm:ss to filter data.
 -- Collect all data from all servers that are after the given time. Also collect Max and Min Values.
 local data = {}
 data.RealmsBuy = {}
 data.RealmsSell = {}
 data.Diagram =
 {
  OrderCountMin = 1000, -- Set it high, so this value can be lowered.
  OrderCountMax = 0, -- Set it low, so this value can be raised.
  PriceMin = 100.0, -- Set it high, so this value can be lowered.
  PriceMax = 0.0, -- Set it low, so this value can be raised.
  TimeMin = self.Config.DiagramOptions.TimeSpan * (-1.0), -- Use the time span from config.
  TimeMax = 0.0, -- Max time have no different from now.
 }
 data.Buy = {} -- Named array with realm names.
 data.Sell = {} -- Named array with realm names.
 local money1 = Money.new()
 local money10 = Money.new()
 local money50 = Money.new()
 if self.Config.DiagramOptions.ShowBuyData == true then
  table.sort(self.Config.HistoryDataBuy, function(a,b) return a.Time > b.Time end)
  for position, item in pairs(self.Config.HistoryDataBuy) do
   if item.Time < timeFilter then
    -- If the time is lower then the filter time, then the loop can be aborted.
    break
   elseif self.Config.DiagramOptions.HiddenRealmList[item.Realm] ~= true then 
    -- Only add data if realm is not in hide list.
    -- Check the min and max values. The price will only used as part of platin.
    if data.Diagram.OrderCountMin > item.OrderCount then
     data.Diagram.OrderCountMin = item.OrderCount
    end
    if data.Diagram.OrderCountMax < item.OrderCount then
     data.Diagram.OrderCountMax = item.OrderCount
    end
    if data.Diagram.PriceMin > (item.Price1 / 1000000) then
     data.Diagram.PriceMin = item.Price1 / 1000000
    end
    if data.Diagram.PriceMax < (item.Price1 / 1000000) then
     data.Diagram.PriceMax = item.Price1 / 1000000
    end
    -- Add realm to list, if not already listed and add Table to buy for this realm.
    if self:IsInList(data.RealmsBuy, item.Realm) == false then
     table.insert(data.RealmsBuy, item.Realm)
     data.Buy[item.Realm] = {} -- Create a empty table to add data items.
    end
    -- Prepare the data item to easy create graphs for the diagramm.
    money1:SetAmount(item.Price1)
    money10:SetAmount(item.Price10)
    money50:SetAmount(item.Price50)
    local dataItem =
    {
     OrderCount = item.OrderCount,
     Price = item.Price1 / 1000000,
     Time = os.difftime(self:GetTime(item.Time), timeNow) / (60 * 60), -- Calculation time difference in negative hours.
     Tooltip = (
      "Realm: " .. item.Realm ..
      "\nTime: " .. item.Time ..
      "\nBuy Orders: " .. tostring(item.OrderCount) ..
      "\nBuy Price 1: " .. money1:GetMoneyString() ..
      "\nBuy Price 10: " .. money10:GetMoneyString() ..
      "\nBuy Price 50: " .. money50:GetMoneyString()),
    }
    table.insert(data.Buy[item.Realm], dataItem)
   end -- if item.Time < timeFilter
  end -- for self.Config.HistoryDataBuy
 end -- if self.Config.DiagramOptions.ShowBuyData == true
 if self.Config.DiagramOptions.ShowSellData == true then
  table.sort(self.Config.HistoryDataSell, function(a,b) return a.Time > b.Time end)
  for position, item in pairs(self.Config.HistoryDataSell) do
   if item.Time < timeFilter then
    -- If the time is lower then the filter time, then the loop can be aborted.
    break
   elseif self.Config.DiagramOptions.HiddenRealmList[item.Realm] ~= true then 
    -- Only add data if realm is not in hide list.
    -- Check the min and max values. The price will only used as part of platin.
    if data.Diagram.OrderCountMin > item.OrderCount then
     data.Diagram.OrderCountMin = item.OrderCount
    end
    if data.Diagram.OrderCountMax < item.OrderCount then
     data.Diagram.OrderCountMax = item.OrderCount
    end
    if data.Diagram.PriceMin > (item.Price1 / 1000000) then
     data.Diagram.PriceMin = item.Price1 / 1000000
    end
    if data.Diagram.PriceMax < (item.Price1 / 1000000) then
     data.Diagram.PriceMax = item.Price1 / 1000000
    end
    -- Add realm to list, if not already listed and add Table to sell for this realm.
    if self:IsInList(data.RealmsSell, item.Realm) == false then
     table.insert(data.RealmsSell, item.Realm)
     data.Sell[item.Realm] = {} -- Create a empty table to add data items.
    end
    -- Prepare the data item to easy create graphs for the diagramm.
    money1:SetAmount(item.Price1)
    money10:SetAmount(item.Price10)
    money50:SetAmount(item.Price50)
    local dataItem =
    {
     OrderCount = item.OrderCount,
     Price = item.Price1 / 1000000,
     Time = os.difftime(self:GetTime(item.Time), timeNow) / (60 * 60), -- Calculation time difference in negative hours.
     Tooltip = (
      "Realm: " .. item.Realm ..
      "\nTime: " .. item.Time ..
      "\nSell Orders: " .. tostring(item.OrderCount) ..
      "\nSell Price 1: " .. money1:GetMoneyString() ..
      "\nSell Price 10: " .. money10:GetMoneyString() ..
      "\nSell Price 50: " .. money50:GetMoneyString()),
    }
    table.insert(data.Sell[item.Realm], dataItem)
   end -- if item.Time < timeFilter
  end -- for self.Config.HistoryDataSell
 end -- if self.Config.DiagramOptions.ShowSellData == true
 -- Add some puffer to max and min values.
 data.Diagram.OrderCountMax = math.ceil(data.Diagram.OrderCountMax * 1.05) -- Round up to the next number.
 data.Diagram.OrderCountMin = math.floor(data.Diagram.OrderCountMin * 0.95)  -- Round down to the next number.
 data.Diagram.PriceMax = data.Diagram.PriceMax * 1.05
 data.Diagram.PriceMin = data.Diagram.PriceMin * 0.95
 -- Paint diagram and data.
 PixieHelper:CreateCoordinateSystem(
  self.DiagramTab:FindChild("ItemContainer"),
  self.xmlDoc,
  data,
  self.Config.DiagramOptions.ShowAmountData,
  self.Config.DiagramOptions.ShowPriceData)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker UpdateItem
-- Updates the data for one item.
------------------------------------------------------------------------------------------------------
function CREDDBroker:UpdateItem(isBuyOrder)
 local data = nil
 local item = nil
 if isBuyOrder == true then
  data = self.BuyItem:GetData()
  item = self.BuyItem
  self.MainForm:FindChild("BuyAmount"):SetText(data.OrderCount)
 else
  data = self.SellItem:GetData()
  item = self.SellItem
  self.MainForm:FindChild("SellAmount"):SetText(data.OrderCount)
 end
 local money10 = Money.new()
 money10:SetAmount(data.Price10)
 local money50 = Money.new()
 money50:SetAmount(data.Price50)
 item:SetSprite("CRB_WindowAnimationSprites:sprWinAnim_BirthSmallTempDouble")
 item:SetTooltip("Time: " .. tostring(data.Time) ..
  "\nPrice 10: " .. money10:GetMoneyString() ..
  "\nPrice 50: " .. money50:GetMoneyString())
 item:FindChild("Price"):SetAmount(data.Price1)
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker UpdateRealmItems
-- Updates items for the options realm list.
------------------------------------------------------------------------------------------------------
function CREDDBroker:UpdateRealmItems()
 local parent = self.OptionsTab:FindChild("ItemContainer")
 parent:DestroyChildren()
 parent:ArrangeChildrenVert()
 -- Sort realms alphabetically.
 table.sort(self.Config.RealmList, function(a,b) return a < b end)
 for position, item in pairs(self.Config.RealmList) do
  local realmItem = Apollo.LoadForm(self.xmlDoc, "RealmItem", parent, self)
  realmItem:SetData(item)
  realmItem:FindChild("Realm"):SetText(item)
  realmItem:FindChild("Realm"):SetCheck(self.Config.DiagramOptions.HiddenRealmList[item] == true)
 end
 parent:ArrangeChildrenVert()
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker UpdateRealms
-- Updates the realms list for the current data.
------------------------------------------------------------------------------------------------------
function CREDDBroker:UpdateRealmList(config)
 if config ~= nil then
  local realmList = {}
  local lastRealm = nil
  table.sort(config.HistoryDataBuy, function(a,b) return a.Realm < b.Realm end)
  for position, item in pairs(config.HistoryDataBuy) do
   if lastRealm ~= nil and
      lastRealm == item.Realm then
    -- In this case we continue with the next item.
   else
    -- Add this realm to the list and go to next.
    table.insert(realmList, item.Realm)
    lastRealm = item.Realm
   end
  end
  -- Normally for a realm should exist buy and sell data, but possibly data on one side was deleted so check booth lists.
  lastRealm = nil
  table.sort(config.HistoryDataSell, function(a,b) return a.Realm < b.Realm end)
  for position, item in pairs(config.HistoryDataSell) do
   if lastRealm ~= nil and
      lastRealm == item.Realm then
    -- In this case we continue with the next item.
   else
    if self:IsInList(realmList, item.Realm) == false then
     -- Add this realm to the list and go to next.
     table.insert(realmList, item.Realm)
     lastRealm = item.Realm
    end
   end
  end
  -- Check for realms that no longer in this list.
  for position, item in pairs(config.RealmList) do
   if self:IsInList(realmList, item) == false then
    -- Remove this realm from last history list and hidden list.
    config.LastDataBuy[item] = nil
    config.LastDataSell[item] = nil
    config.DiagramOptions.HiddenRealmList[item] = nil
   end
  end
  -- Use the new list as realm list and sort alphabetic.
  table.sort(realmList, function(a,b) return a < b end)
  config.RealmList = realmList
 end -- if config ~= nil
end

------------------------------------------------------------------------------------------------------
-- CREDDBroker UpdateTabItems
-- Updates all items for the given tab.
------------------------------------------------------------------------------------------------------
function CREDDBroker:UpdateTabItems(tab, tableData, color)
 if tab ~= nil and
    tableData ~= nil and
    color ~= nil then
  local parent = tab:FindChild("ItemContainer")
  parent:DestroyChildren()
  parent:ArrangeChildrenVert()
  table.sort(tableData, function(a,b) return a.Time > b.Time end)
  for position, item in pairs(tableData) do
   Apollo.LoadForm(self.xmlDoc, "CreddHistoryLine", parent, self)
   local historyItem = Apollo.LoadForm(self.xmlDoc, "CreddHistoryItem", parent, self)
   historyItem:SetData(item)
   historyItem:FindChild("Price1"):SetTextColor(color)
   historyItem:FindChild("Price1"):SetAmount(item.Price1)
   historyItem:FindChild("Price10"):SetTextColor(color)
   historyItem:FindChild("Price10"):SetAmount(item.Price10)
   historyItem:FindChild("Price50"):SetTextColor(color)
   historyItem:FindChild("Price50"):SetAmount(item.Price50)
   historyItem:FindChild("Amount"):SetText(item.OrderCount)
   historyItem:FindChild("Realm"):SetText(item.Realm)
   historyItem:FindChild("Time"):SetText(item.Time)
  end
  parent:ArrangeChildrenVert()
 end
end

--****************************************************************************************************
-- Eventfunctions for RealmItem
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- RealmItem OnButtonCheckRealm
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonCheckRealm( wndHandler, wndControl, eMouseButton )
 if wndHandler ~= nil then
  local realm = wndHandler:GetParent():GetData()
  self.Config.DiagramOptions.HiddenRealmList[realm] = true
  self:UpdateDiagram()
 end
end

------------------------------------------------------------------------------------------------------
-- RealmItem OnButtonUncheckRealm
-- Update config option.
------------------------------------------------------------------------------------------------------
function CREDDBroker:OnButtonUncheckRealm( wndHandler, wndControl, eMouseButton )
 if wndHandler ~= nil then
  local realm = wndHandler:GetParent():GetData()
  self.Config.DiagramOptions.HiddenRealmList[realm] = nil
  self:UpdateDiagram()
 end
end

-----------------------------------------------------------------------------------------------
-- CREDDBroker Instance
-----------------------------------------------------------------------------------------------
local CREDDBrokerInst = CREDDBroker:new()
CREDDBrokerInst:Init()
