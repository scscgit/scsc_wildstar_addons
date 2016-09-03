-----------------------------------------------------------------------------------------------
-- Client Lua Script for Multicraft
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Multicraft Module Definition
-----------------------------------------------------------------------------------------------
local Multicraft = {} 
Multicraft.Remains = 0
Multicraft.ShouldStop = false 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local MCAdditiveIndex = 0
local MCAdditives = {}
local MCIsRecording = true

function table_slice (values,i1,i2)
    local res = {}
    local n = #values
    -- default values for range
    i1 = i1 or 1
    i2 = i2 or n
    if i2 < 0 then
        i2 = n + i2 + 1
    elseif i2 > n then
        i2 = n
    end
    if i1 < 1 or i1 > n then
        return {}
    end
    local k = 1
    for i = i1,i2 do
        res[k] = values[i]
        k = k + 1
    end
    return res
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Multicraft:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Multicraft:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Multicraft OnLoad
-----------------------------------------------------------------------------------------------
function Multicraft:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Multicraft.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Multicraft OnDocLoaded
-----------------------------------------------------------------------------------------------
function Multicraft:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MulticraftForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("mc", "OnMulticraftStart", self)
        Apollo.RegisterEventHandler("GenericEvent_StartCraftingGrid", "OnGridOpen", self)

		-- Do additional Addon initialization here
		self.InputWindow = self.wndMain:FindChild("EditBox")
	end
end

-----------------------------------------------------------------------------------------------
-- Multicraft Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/mc"
function Multicraft:OnMulticraftStart(arg)
	self.wndMain:Show(true)
    if self.oldaddfunc == nil then
        self.oldaddfunc = Apollo.GetAddon("CraftingGrid").OnAdditiveClick;
        Apollo.GetAddon("CraftingGrid").OnAdditiveClick = self.PatchedOnAdditiveClick;
        Print("MonkeyPatched: GridAddon:OnAdditiveClick");
    end
end

function Multicraft:PatchedOnAdditiveClick(wndHandler, wndControl)    
    local altself = Apollo.GetAddon("CraftingGrid")
    local itemData = wndHandler:GetData()
    local idSchematic = altself.wndMain:GetData()
    if itemData then
        CraftingLib.AddAdditive(itemData)
        local tCurrentCraft = CraftingLib.GetCurrentCraft()
        if tCurrentCraft then
            altself.tAdditivesAdded[tCurrentCraft.nAdditiveCount + 1] = itemData
        end
        local tSchematicInfo = CraftingLib.GetSchematicInfo(idSchematic)
        if tCurrentCraft and tCurrentCraft.nAdditiveCount < tSchematicInfo.nMaxAdditives then
            altself.strPendingLastMarkerTooltip = altself.strPendingLastMarkerTooltip .. "\n" .. itemData:GetName()
        end
        altself:HelperBuildMarker()
        
        -- Added my code to steal the additives
        if MCIsRecording == true then
            Print("Adding Additive Index: " .. MCAdditiveIndex)
            MCAdditives[MCAdditiveIndex + 1] = {h = wndHandler, c = wndControl}
            MCAdditiveIndex = MCAdditiveIndex + 1
			Apollo.GetAddon("Multicraft"):SetAddDisplay(MCAdditiveIndex)
        end
    end
end

function Multicraft:OnGridOpen()
    self:OnMulticraftStart()
end

function Multicraft:OnMulticraftStop()
	self:SetStatusText("Crafting will stop after this attempt");
	if self.timer == nil then
		return
	end
    self.timer:Stop()
	self.ShouldStop = true
end

function Multicraft:BeginCraft()
    MCIsRecording = false
	self.ShouldStop = false
	self:SetRecordText(tostring(MCIsRecording))
	
	local cGrid = Apollo.GetAddon("CraftingGrid")
	local cGridStartCraftButton = cGrid.wndMain:FindChild("PreviewStartCraftBtn")	
	if cGridStartCraftButton == nil then
		Print("Unable to find the start craft button. Have you opened the crafting grid?")
		self:SetStatusText("Error: Check chatlog.")
		return
	end
	
	cGrid:OnPreviewStartCraftBtn(cGridStartCraftButton, cGridStartCraftButton)
    self:AddAdditives()
	self:CompleteCraft()
end

function Multicraft:AddAdditives() 
    for k, v in pairs(MCAdditives) do
        self:PatchedOnAdditiveClick(v.h, v.c)
    end
end

function Multicraft:CompleteCraft()
	local cGrid = Apollo.GetAddon("CraftingGrid")
	local cGridCompleteCraftButton = cGrid.wndMain:FindChild("CraftBtn")
	if cGridCompleteCraftButton == nil then
		Print("Unable to find the complete craft button. Did the crafting grid close")
		self:SetStatusText("Error: Check chatlog.")
		return
	end
	self:SetStatusText("Working.");
    self.timer = ApolloTimer.Create(3.5, false, "OnCraftCompleteTimer", self)
	self.timer:Start()
    cGrid:OnCraftBtn(cGridCompleteCraftButton, cGridCompleteCraftButton)
end

function Multicraft:OnCraftCompleteTimer()
	if self.ShouldStop then
		self:SetStatusText("Stopped.")
		return
	end
	if self.Remains > 0 then
		self.Remains = self.Remains - 1
		self.InputWindow:SetText(self.Remains)
		self:SetStatusText("Starting.")
		self:BeginCraft()
		return
	end
	
end

function Multicraft:SetStatusText(text)
	self.wndMain:FindChild("StatusText"):SetText("Status: " .. text)
end

function Multicraft:SetAddDisplay(count)
	self.wndMain:FindChild("AddCount"):SetText(tostring(count))
end

function Multicraft:SetRecordText(text)
	self.wndMain:FindChild("RecordText"):SetText(text)
end

-----------------------------------------------------------------------------------------------
-- MulticraftForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function Multicraft:OnOK()
	self.Remains = tonumber(self.InputWindow:GetText())
	self:BeginCraft()
end

-- when the Cancel button is clicked
function Multicraft:OnCancel()
	self:OnMulticraftStop()
end


function Multicraft:OnClose( wndHandler, wndControl, eMouseButton )
	self:OnMulticraftStop()
	self.wndMain:Close()
end

function Multicraft:OnClearAdditives( wndHandler, wndControl, eMouseButton )
	MCAdditiveIndex = 0
	MCAdditives = {}
	MCIsRecording = true
	self:SetRecordText(tostring(MCIsRecording))
	self:SetAddDisplay(MCAdditiveIndex)
end

-----------------------------------------------------------------------------------------------
-- Multicraft Instance
-----------------------------------------------------------------------------------------------
local MulticraftInst = Multicraft:new()
MulticraftInst:Init()
