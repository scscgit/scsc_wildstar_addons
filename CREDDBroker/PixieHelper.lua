--****************************************************************************************************
-- Lua Script for PixieHelper
-- Created by SpielePhilosoph - http://www.curse.com/users/SpielePhilosoph/projects
-- Description: This file contains some helper function to create pixies.
-- Last modified: 20140715
-- Version: 0.2
--****************************************************************************************************

--****************************************************************************************************
-- List of used libs, that need for this script.
--****************************************************************************************************
require "Apollo"
 
--****************************************************************************************************
-- PixieHelper Module Definition
--****************************************************************************************************
local PixieHelper = {}

--****************************************************************************************************
-- PixieHelper Variables
--****************************************************************************************************
local ColorBuy = "UI_TextHoloBody" -- Colour to mark buy points.
local ColorSell = "ffc2e57f" -- Colour to mark sell points.
local ColorLine = -- Some list of colors that used to show up the data from one realm together with lines.
{
 "ff990000", -- red dark
 "ff009900", -- green dark
 "ff000099", -- blue dark
 "ff999900", -- yellow dark
 "ff990099", -- lila
 "ff009999", -- cyan
 "ffff0000", -- red
 "ff00ff00", -- green
 "ff0000ff", -- blue
 "ffffff00", -- yellow
 "ffff00ff", -- pink neon
 "ff00ffff", -- cyan
 "ffff9900", -- orange
 "ffff0099", -- pink
 "ffff9999", -- rose
 "ff99ff00", -- neon green
 "ff00ff99", -- green pastel
 "ff99ff99", -- green pistatize
}

--****************************************************************************************************
-- Initialization
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- PixieHelper new
------------------------------------------------------------------------------------------------------
function PixieHelper:new(o)
 o = o or {}
 setmetatable(o, self)
 self.__index = self
 return o
end

--****************************************************************************************************
-- Functions for PixieHelper
--****************************************************************************************************
------------------------------------------------------------------------------------------------------
-- PixieHelper AddHelperLines
-- Add vertical and horizontal helper lines to a grid with the corresponding values.
-- Points and offset values: Left, Top, Right, Bottom
------------------------------------------------------------------------------------------------------
function PixieHelper:AddHelperLines(control, minX, maxX, showYA, minYA, maxYA, showYB, minYB, maxYB)
 minX = minX or -24
 maxX = maxX or -0
 minYA = minYA or 0
 maxYA = maxYA or 50
 minYB = minYB or 3,5
 maxYB = maxYB or 15
 -- Create the vertical lines in background.
 for i = 0.1, 0.9, 0.1 do
  self:AddLine(control, {i, 0, i, 1}, {25, 30, 25, -26})
  -- Values created from left to right, so the value of i can direct used to calculate the values.
  self:AddText(
   control,
   {i, 1, i, 1},
   {10, -15, 40, 0},
   string.format("%.1f", (minX + ((maxX - minX) * i))))
 end
 -- Create the horizontal lines in background.
 for i = 0.1, 0.9, 0.1 do
  self:AddLine(control, {0, i, 1, i}, {31, -20, -10, -20})
  -- Values created from top to bottom, the values need to be lower, so the value 1-i is used for caluculation.
  local labelText = ""
  if showYA == true then
   labelText = labelText .. string.format("%.1f", (minYA + ((maxYA - minYA) * (1-i))))
  end
  if showYA == true and
     showYB == true then
   labelText = labelText .. "\n"
  end
  if showYB == true then
   labelText = labelText .. string.format("%.2f", (minYB + ((maxYB - minYB) * (1-i))))
  end
  self:AddText(
   control,
   {0, i, 0, i},
   {0, -32, 25, -12},
   labelText) -- horizontal
 end
end

------------------------------------------------------------------------------------------------------
-- PixieHelper AddImage
-- Add a pixie with a image to the control.
------------------------------------------------------------------------------------------------------
function PixieHelper:AddImage(control, points, offsets, sprite, rotation, color)
 if control ~= nil then
  color = color or "UI_BtnTextHoloNormal"
  rotation = rotation or 0
  control:AddPixie(
  {
   strSprite = sprite,
   cr = color,
   fRotation = rotation,
   loc =
   {
    fPoints = points,
    nOffsets = offsets,
   },
  })
 end
end

------------------------------------------------------------------------------------------------------
-- PixieHelper AddLine
-- Adds a line to the control.
------------------------------------------------------------------------------------------------------
function PixieHelper:AddLine(control, points, offsets, color, width)
 if control ~= nil then
  color = color or "white"
  width = width or 1.0
  control:AddPixie(
  {
   bLine = true,
   cr = color,
   fWidth = width,
   loc =
   {
    fPoints = points,
    nOffsets = offsets,
   },
   strSprite = "BasicSprites:LineFill",
  })
 end
end

------------------------------------------------------------------------------------------------------
-- PixieHelper AddLine
-- Adds a line to the control.
------------------------------------------------------------------------------------------------------
function PixieHelper:AddPoint(control, points, color) --, offsets)
 if control ~= nil then
  color = color or "UI_BtnTextGreenNormal"
  --offsets = offsets or {-2, -2, 2, 2}
  offsets = {-2 + 25, -2 - 20, 2 + 25, 2 - 20} -- Sizes for the point {-2, -2, 2, 2} plus margins from the grid {20, -20, 20, -20}
  control:AddPixie(
  {
   cr = color,
   loc =
   {
    fPoints = points,
    nOffsets = offsets,
   },
   strSprite = "BasicSprites:WhiteCircle",
  })
 end
end

------------------------------------------------------------------------------------------------------
-- PixieHelper AddLine
-- Adds a line to the control.
------------------------------------------------------------------------------------------------------
function PixieHelper:AddText(control, points, offsets, text, colorText, color)
 if control ~= nil then
  colorText = colorText or "UI_TextHoloBody"
  control:AddPixie(
  {
   strText = text,
   strFont = "CRB_Pixel",
   crText = colorText,
   loc =
   {
    fPoints = points,
    nOffsets = offsets,
   },
   flagsText =
   {
    -- Default text is top and left.
    DT_CENTER = true,
    --DT_RIGHT = true,
    DT_VCENTER = true,
    --DT_BOTTOM = true,
    --DT_WORDBREAK = true,
    --DT_SINGLELINE = true,
   },
  })
 end
end

------------------------------------------------------------------------------------------------------
-- PixieHelper CreateCoordinateSystem
-- Create pixies to represent a corrdination system.
------------------------------------------------------------------------------------------------------
function PixieHelper:CreateCoordinateSystem(control, xmlDoc, data, showAmount, showPrice)
 if control ~= nil then
  -- Destroy pixies and tooltip areas.
  control:DestroyChildren()
  control:DestroyAllPixies()
  -- First create the helper lines so that they lay in background.
  self:AddHelperLines(
   control,
   data.Diagram.TimeMin,
   data.Diagram.TimeMax,
   showAmount,
   data.Diagram.OrderCountMin,
   data.Diagram.OrderCountMax,
   showPrice,
   data.Diagram.PriceMin,
   data.Diagram.PriceMax)
  -- Add the two images for axes endings.
  self:AddImage(control, {1, 1, 1, 1}, {-10, -30, 0, -20}, "CRB_Basekit:kitIcon_Holo_UpArrow", 90, nil) -- right, bottom
  self:AddImage(control, {0, 0, 0, 0}, {25, 20, 35, 30}, "CRB_Basekit:kitIcon_Holo_UpArrow", 0, nil) -- left, top
  -- Add the two main axes.
  self:AddLine(control, {0, 1, 1, 1}, {29, -25, -5, -25}, "UI_BtnTextHoloNormal", 2.0) -- vertical
  self:AddLine(control, {0, 0, 0, 1}, {30, 25, 30, -25}, "UI_BtnTextHoloNormal", 2.0) -- horizontal
  if xmlDoc ~= nil and
     data ~= nil then
   -- Add lables.
   local labelText = ""
   local labelTextName = ""
   if showAmount == true then
    labelText = labelText .. string.format("%.1f", data.Diagram.OrderCountMin)
    labelTextName = labelTextName .. "Amount"
   end
   if showAmount == true and
      showPrice == true then
    labelText = labelText .. "\n"
    labelTextName = labelTextName .. "\n"
   end
   if showPrice == true then
    labelText = labelText .. string.format("%.2f", data.Diagram.PriceMin)
    labelTextName = labelTextName .. "Price Platinum"
   end
   self:AddText(control, {1, 1, 1, 1}, {-30, -15, 0, 0}, "Hours") -- vertical
   self:AddText(control, {0, 1, 0, 1}, {10, -15, 40, 0}, string.format("%.1f", data.Diagram.TimeMin)) -- vertical
   self:AddText(control, {0, 0, 0, 0}, {0, 0, 80, 20}, labelTextName) -- horizontal
   self:AddText(control, {0, 1, 0, 1}, {0, -33, 20, -13}, labelText) -- horizontal
   -- Iterate buy realms.
   local colorCounterLines = 0
   local realmColor = {}
   for realmPosition, realm in pairs(data.RealmsBuy) do
    colorCounterLines = colorCounterLines + 1
    realmColor[realm] = ColorLine[colorCounterLines]
    self:CreateDataPoints(
     control,
     xmlDoc,
     data.Diagram,
     data.Buy[realm],
     realmColor[realm],
     ColorBuy,
     showAmount,
     showPrice)
   end -- for data.RealmsBuy
   for realmPosition, realm in pairs(data.RealmsSell) do
    if realmColor[realm] == nil then
     colorCounterLines = colorCounterLines + 1
     realmColor[realm] = ColorLine[colorCounterLines]
    end
    self:CreateDataPoints(
     control,
     xmlDoc,
     data.Diagram,
     data.Sell[realm],
     realmColor[realm],
     ColorSell,
     showAmount,
     showPrice)
   end -- for data.RealmsSell
  end -- if xmlDoc ~= nil and data ~= nil
 end -- if control ~= nil
end

------------------------------------------------------------------------------------------------------
-- PixieHelper CreateDataPoints
-- Creates datapoints for the given data.
------------------------------------------------------------------------------------------------------
function PixieHelper:CreateDataPoints(control, xmlDoc, diagram, data, colorLine, colorPoint, showAmount, showPrice)
 if control ~= nil and
    xmlDoc ~= nil and
    diagram ~= nil and
    data ~= nil and
    colorLine ~= nil and
    colorPoint ~= nil then
  local currentItem = nil
  local lastItem = nil
  for position, item in pairs(data) do
   lastItem = currentItem
   currentItem = item
   if currentItem ~= nil and
      lastItem ~= nil then
    -- We have two points, first paint lines between the points for amount and price, then paint points for amount and price for the last item.
    if showAmount == true then
     self:AddLine(
      control,
      {
       (1 - (lastItem.Time / diagram.TimeMin)),
       (1 - ((lastItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
       (1 - (currentItem.Time / diagram.TimeMin)),
       (1 - ((currentItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
      },
      {25, -20, 25, -20},
      colorLine)
     self:AddPoint(
      control,
      {
       (1 - (lastItem.Time / diagram.TimeMin)),
       (1 - ((lastItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
       (1 - (lastItem.Time / diagram.TimeMin)),
       (1 - ((lastItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
      },
      colorPoint)
     local tooltip = Apollo.LoadForm(xmlDoc, "TooltipArea", control, self)
     tooltip:SetTooltip("Amount Point\n" .. lastItem.Tooltip)
     tooltip:SetData(lastItem)
     tooltip:SetAnchorPoints(
      (1 - (lastItem.Time / diagram.TimeMin)),
      (1 - ((lastItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
      (1 - (lastItem.Time / diagram.TimeMin)),
      (1 - ((lastItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))))
     tooltip:SetAnchorOffsets(-5 + 25, -5 - 20, 5 + 25, 5 - 20)
    end -- if showAmount == true
    if showPrice == true then
      self:AddLine(
       control,
       {
        (1 - (lastItem.Time / diagram.TimeMin)),
        (1 - ((lastItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
        (1 - (currentItem.Time / diagram.TimeMin)),
        (1 - ((currentItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
       },
       {25, -20, 25, -20},
       colorLine)
     self:AddPoint(
      control,
      {
       (1 - (lastItem.Time / diagram.TimeMin)),
       (1 - ((lastItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
       (1 - (lastItem.Time / diagram.TimeMin)),
       (1 - ((lastItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
      },
      colorPoint)
     local tooltip = Apollo.LoadForm(xmlDoc, "TooltipArea", control, self)
     tooltip:SetTooltip("Price Point\n" .. lastItem.Tooltip)
     tooltip:SetData(lastItem)
     tooltip:SetAnchorPoints(
      (1 - (lastItem.Time / diagram.TimeMin)),
      (1 - ((lastItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
      (1 - (lastItem.Time / diagram.TimeMin)),
      (1 - ((lastItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))))
     tooltip:SetAnchorOffsets(-5 + 25, -5 - 20, 5 + 25, 5 - 20)
    end -- if showPrice == true
   end -- if currentItem ~= nil and lastItem ~= nil
  end -- for data
  -- After finish the loop, the points for the current item need to be painted.
  if showAmount == true then
   self:AddPoint(
    control,
    {
     (1 - (currentItem.Time / diagram.TimeMin)),
     (1 - ((currentItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
     (1 - (currentItem.Time / diagram.TimeMin)),
     (1 - ((currentItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
    },
    colorPoint)
   local tooltip = Apollo.LoadForm(xmlDoc, "TooltipArea", control, self)
   tooltip:SetTooltip("Amount Point\n" .. currentItem.Tooltip)
   tooltip:SetData(lastItem)
   tooltip:SetAnchorPoints(
    (1 - (currentItem.Time / diagram.TimeMin)),
    (1 - ((currentItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))),
    (1 - (currentItem.Time / diagram.TimeMin)),
    (1 - ((currentItem.OrderCount - diagram.OrderCountMin) / (diagram.OrderCountMax - diagram.OrderCountMin))))
   tooltip:SetAnchorOffsets(-5 + 25, -5 - 20, 5 + 25, 5 - 20)
  end -- if showAmount == true
  if showPrice == true then
   self:AddPoint(
    control,
    {
     (1 - (currentItem.Time / diagram.TimeMin)),
     (1 - ((currentItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
     (1 - (currentItem.Time / diagram.TimeMin)),
     (1 - ((currentItem.Price - diagram.PriceMin) / (diagram.PriceMax - diagram.PriceMin))),
    },
    colorPoint)
   local tooltip = Apollo.LoadForm(xmlDoc, "TooltipArea", control, self)
   tooltip:SetTooltip("Price Point\n" ..  currentItem.Tooltip)
   tooltip:SetData(lastItem)
   tooltip:SetAnchorPoints(
    (1 - (currentItem.Time / diagram.TimeMin)),
    (1 - ((currentItem.Price - diagram.PriceMin) / diagram.PriceMax)),
    (1 - (currentItem.Time / diagram.TimeMin)),
    (1 - ((currentItem.Price - diagram.PriceMin) / diagram.PriceMax)))
   tooltip:SetAnchorOffsets(-5 + 25, -5 - 20, 5 + 25, 5 - 20)
  end -- if showPrice == true
 end -- if parameter ~= nil
end

-----------------------------------------------------------------------------------------------
-- PixieHelper Instance and registration
-----------------------------------------------------------------------------------------------
local PixieHelperInst = PixieHelper:new()
Apollo.RegisterPackage(PixieHelper, "SpielePhilosoph:Lib:PixieHelper-0.1", 1, {})
