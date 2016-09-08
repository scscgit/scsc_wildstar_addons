-----------------------------------------------------------------------------------------------
-- Client Lua Script for PratLiteLink
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "AccountItemLib"
require "Item"
-----------------------------------------------------------------------------------------------
-- PratLiteLink Module Definition
-----------------------------------------------------------------------------------------------
local PratLiteLink = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local knXCursorOffset = 10
local knYCursorOffset = 25
local ktValidItemPreviewSlots = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [16] = true }
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PratLiteLink:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PratLiteLink:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	    "PratLite",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- PratLiteLink OnLoad
-----------------------------------------------------------------------------------------------
function PratLiteLink:OnLoad()
    -- load our form file
	--self.xmlDoc = XmlDoc.CreateFromFile("PratLiteLink.xml")
	--self.xmlDoc:RegisterCallback("OnDocLoaded", self)
    self:InitializeHooks()                                                     
    Apollo.RegisterEventHandler("SplitItemStack", 		                        "OnSplitItemStack", self)
    Apollo.RegisterEventHandler("DragDropSysBegin",                             "OnSystemBeginDragDrop", self)
	Apollo.RegisterEventHandler("DragDropSysEnd", 								"OnDragDropSystemEnd", self)
end

-----------------------------------------------------------------------------------------------
-- PratLiteLink OnDocLoaded
-----------------------------------------------------------------------------------------------
--[[function PratLiteLink:OnDocLoaded()

	-if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PratLiteLinkForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		--Apollo.RegisterSlashCommand("pll",                                          "OnPratLiteLinkOn", self)
		-- Do additional Addon initialization here
	end
end]]--

function PratLiteLink:InitializeHooks()	
    local GuildBankAddon =  Apollo.GetAddon("GuildBank")
	local ContextMenuItemAddon = Apollo.GetAddon("ContextMenuItem")
	if GuildBankAddon ~= nil then
	    GuildBankAddon.OnBankItemMouseButtonDown = self.OnBankItemMouseButtonDown
	end
	if ContextMenuItemAddon ~= nil then
	    ContextMenuItemAddon.InitializeItemObject = self.InitializeItemObject
	end
end
-----------------------------------------------------------------------------------------------
-- PratLiteLink Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/pll"
function PratLiteLink:OnPratLiteLinkOn()
	self.wndMain:Invoke() -- show the window
end

----------------------------------- Click to Item ----------------------------
function PratLiteLink:OnBankItemMouseButtonDown(wndHandler, wndControl, eMouseButton, bDoubleClick)
    local itemSelected = wndHandler:GetData() -- wndHandler is BankItemIcon
	local nStackCount =  itemSelected:GetStackCount()
	local nDecorId = itemSelected:GetHousingDecorInfoId()
	local bValidItemPreview = ktValidItemPreviewSlots[itemSelected:GetSlot()]
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and self.tWndRefs.wndMain:GetData() and wndHandler:GetData() then
		local guildOwner = self.tWndRefs.wndMain:GetData()
		guildOwner:MoveBankItemToInventory(itemSelected)
		Event_FireGenericEvent("GuildBank_ShowPersonalInventory")
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsAltKeyDown() and nStackCount > 1 then
		self:CreateSplitWindow(itemSelected, wndHandler)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsShiftKeyDown()  then
	    Event_FireGenericEvent("GenericEvent_LinkItemToChat", itemSelected)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsControlKeyDown() and nDecorId and nDecorId ~= 0 then
	    Event_FireGenericEvent("GenericEvent_LoadDecorPreview", nDecorId)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsControlKeyDown() and nStackCount < 2 and bValidItemPreview then	    
	    Event_FireGenericEvent("GenericEvent_LoadItemPreview", itemSelected)--itemEquipped)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left and Apollo.IsControlKeyDown() then
	    self:CreateSplitWindow(itemSelected, wndHandler)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self:OnBankItemBeginDragDrop(wndHandler, wndControl)
	end
	Sound.Play(185)
end

function PratLiteLink:OnSplitItemStack(itemArg)
    local nStackCount =  itemArg:GetStackCount()
    if Apollo.IsShiftKeyDown() then
		Event_FireGenericEvent("GenericEvent_LinkItemToChat", itemArg)
		Sound.Play(185)
	end
end

function PratLiteLink:OnSystemBeginDragDrop(wndSource, strType, iData)
    if not Apollo.IsShiftKeyDown() then return end
	local InventoryAddon = Apollo.GetAddon("InventoryBag")
	if InventoryAddon == nil then
	   InventoryAddon = Apollo.GetAddon("SpaceStashInventory")
	end
	if InventoryAddon == nil then
	   InventoryAddon = Apollo.GetAddon("KuronaBags")
	end
	if InventoryAddon ~= nil then
	    local item = InventoryAddon.wndBagWindow:GetItem(iData)
	    Event_FireGenericEvent("GenericEvent_LinkItemToChat", item)
		Sound.Play(185)
	end
end

function PratLiteLink:InitializeItemObject(itemArg)
    if self.wndMain and self.wndMain:IsValid() then
		self.wndMain:Destroy()
		self.wndMain = nil
	end
	local nDecorId = itemArg:GetHousingDecorInfoId()
	local nStackCount =  itemArg:GetStackCount()
	local bValidItemPreview = ktValidItemPreviewSlots[itemArg:GetSlot()]
	if Apollo.IsShiftKeyDown()  then
	    Event_FireGenericEvent("GenericEvent_LinkItemToChat", itemArg)
	elseif Apollo.IsControlKeyDown() and nDecorId and nDecorId ~= 0 then
	    Event_FireGenericEvent("GenericEvent_LoadDecorPreview", nDecorId)
	elseif Apollo.IsControlKeyDown() and nStackCount < 2  and bValidItemPreview then	    
	    Event_FireGenericEvent("GenericEvent_LoadItemPreview", itemArg)
	else
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ContextMenuItemForm", "TooltipStratum", self)
	    self.wndMain:SetData(itemArg)
	    self.wndMain:Invoke()
    
	    self.nDecorId = itemArg:GetHousingDecorInfoId()
	    local tCursor = Apollo.GetMouse()
	    self.wndMain:Move(tCursor.x - knXCursorOffset, tCursor.y - knYCursorOffset, self.wndMain:GetWidth(), self.wndMain:GetHeight())

	-- Enable / Disable the approriate buttons
	    self.wndMain:FindChild("BtnEditRunes"):Enable(self:HelperValidateEditRunes(itemArg))
	    self.wndMain:FindChild("BtnPreviewItem"):Enable(self:HelperValidatePreview(itemArg))
	    self.wndMain:FindChild("BtnSplitStack"):Enable(itemArg and itemArg:GetStackCount() > 1)
	    self.wndMain:FindChild("BtnUnlockCostume"):Enable(self:HelperValidateCostumeUnlock(itemArg))

	-- If Decor
	    if self.nDecorId and self.nDecorId ~= 0 then
		    self.wndMain:FindChild("BtnPreviewItem"):Enable(true)
	    end
	end
	Sound.Play(185)
end
	 

-----------------------------------------------------------------------------------------------
-- PratLiteLinkForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function PratLiteLink:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function PratLiteLink:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- PratLiteLink Instance
-----------------------------------------------------------------------------------------------
local PratLiteLinkInst = PratLiteLink:new()
PratLiteLinkInst:Init()
