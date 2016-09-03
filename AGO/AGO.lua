
require "Window"
require "Apollo"

local TBGO = {} 
local userSettings = {}

local format = string.format
local tonumber = tonumber 
local tostring = tostring


function TBGO:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function TBGO:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "AdvGraphicsOptions"
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


function TBGO:OnConfigure()
    self:LoadCurrentValues()
	self.wndMain:Invoke() 
end

function TBGO:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("AGO.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function TBGO:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "TBGOForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	    self.RTslider = self.wndMain:FindChild("renderSliderBar")
	    self.FOVslider = self.wndMain:FindChild("fovSliderBar")
	    self.SPELLslider = self.wndMain:FindChild("spellSliderBar")
	   	self.RTtextBOX = self.wndMain:FindChild("rtSliderValue")
	   	self.FOVtextBOX = self.wndMain:FindChild("fovsliderValue")
	   	self.SPELLtextBOX = self.wndMain:FindChild("spellsliderValue")
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("ago", "OnTBGOOn", self)


		-- Do additional Addon initialization here
		Print("Mekret released. Hide your cookies!")
		Print("LayA's Advanced Graphic Options Loaded. http://gamemodderz.com/")
	end
end
-----------------------------------------------------------------------------------------------
-- TBGO Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function TBGO:OnTBGOOn()
	self:LoadCurrentValues()
	self.wndMain:Invoke() -- show the window
end

function TBGO:LoadCurrentValues()
	RTvalue = Apollo.GetConsoleVariable("lod.renderTargetScale")
	self.RTslider:SetValue(RTvalue)
	self.RTtextBOX:SetText(format("%.f %%",RTvalue * 100))
	FOVvalue = Apollo.GetConsoleVariable("camera.FovY")
	self.FOVslider:SetValue(FOVvalue)
	self.FOVtextBOX:SetText(FOVvalue)
	SPELLvalue = Apollo.GetConsoleVariable("spell.visualSuppression")
	self.SPELLslider:SetValue(SPELLvalue)
	self.SPELLtextBOX:SetText(format("%.f %%",SPELLvalue * 100))
end

-----------------------------------------------------------------------------------------------
-- TBGOForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function TBGO:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function TBGO:OnCancel()
	Apollo.SetConsoleVariable("lod.renderTargetScale", RTvalue)
	Apollo.SetConsoleVariable("camera.FovY", FOVvalue)
	Apollo.SetConsoleVariable("spell.visualSuppression", SPELLvalue)
	self.wndMain:Close() -- hide the window
end


function TBGO:onRTsliderchange( wndHandler, wndControl, fNewValue, fOldValue )
	local RTsetting = tonumber(fNewValue)
	self.RTslider:SetValue(RTsetting) -- setting name is after Slider_
	Apollo.SetConsoleVariable("lod.renderTargetScale", RTsetting)
	self.RTtextBOX:SetText(format("%.f %%",RTsetting * 100))
end

function TBGO:onFOVsliderchange( wndHandler, wndControl, fNewValue, fOldValue )
	local FOVsetting = tonumber(fNewValue)
	Apollo.SetConsoleVariable("camera.FovY", FOVsetting)
	self.FOVtextBOX:SetText(FOVsetting)
end

function TBGO:onSPELLsliderchange( wndHandler, wndControl, fNewValue, fOldValue )
	local SPELLsetting = tonumber(fNewValue) -- setting name is after Slider_
	self.SPELLslider:SetValue(SPELLsetting)
	Apollo.SetConsoleVariable("spell.visualSuppression", SPELLsetting)
	self.SPELLtextBOX:SetText(format("%.f %%",SPELLsetting * 100))
	
end

-----------------------------------------------------------------------------------------------
-- TBGO Instance
-----------------------------------------------------------------------------------------------
local TBGOInst = TBGO:new()
TBGOInst:Init()
