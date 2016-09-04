-----------------------------------------------------------------------------------------------
-- Client Lua Script for Tankie
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- Tankie Module Definition
-----------------------------------------------------------------------------------------------
local Tankie = {} 

 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 local  tSettings = {}
			tSettings["nLowFocus"] = 300
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Tankie:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Tankie:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Tankie OnLoad
-----------------------------------------------------------------------------------------------
function Tankie:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Tankie.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Tankie OnDocLoaded
-----------------------------------------------------------------------------------------------
function Tankie:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "TankieForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("tankie", 							"OnTankieOn", self)
		Apollo.RegisterSlashCommand("tankiescan", 							"onScanForHealer", self)
		-- Group Events.
		Apollo.RegisterEventHandler("Group_Join",						"onTankieGroupJoined", self)
		Apollo.RegisterEventHandler("Group_Left", 						"onTankieGroupLeft", self)
		--Interface Icon Events
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",		"OnInterfaceMenuListHasLoaded", self)
		Apollo.RegisterEventHandler("ToggleTankie",						"OnTankieOn", self)
		Apollo.RegisterEventHandler("WindowManagementReady", 			"OnWindowManagementReady", self)
		-- Timer Setup.
		self.timerFocusUpdater =  ApolloTimer.Create(.5,true,			"onTankieFocusWatch", self)
		self.ShoutCooldownTimer = ApolloTimer.Create(90.0, false,       "onShoutCooldownTimer", self)
		self.ShoutCooldownTimer:Stop()
		-- Do additional Addon initialization here
		self.tCache = {}	
			self.tCache["shoutedLowFocus"] = false
	else
		Apollo.AddAddonErrorText(self, "Could not load XML document for the window.")
	end
end

-----------------------------------------------------------------------------------------------
-- Tankie Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/Tankie"
function Tankie:OnTankieOn()
	if 	self.wndMain:IsVisible() then
		self.wndMain:Close()
	else
		self.wndMain:Invoke() -- show the window
	end
end

function Tankie:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Tankie", {"ToggleTankie", "","TargetFrameSprites:sprRoleMeleeHeavy"})
	--self:UpdateInterfaceMenuAlerts()
end

function Tankie:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "Tankie"})
end


function Tankie:onTankieFocusWatch()
	local uMyHealer = Tankie:onTankieGroup_Updated()
	if uMyHealer == nil then
		self.wndMain:FindChild("wndDisplay"):Show(false, false, 2)
		self.wndMain:FindChild("wndResetHealer"):Show(true, false, 2)
	else
	SendVarToRover("uMyHealer tankie", uMyHealer, 0)
	--[[elseif uMyHealer:GetMana() == nil then
	else																															
		self.wndMain:FindChild("strHealerName"):SetText(uMyHealer:GetName())
		self.wndMain:FindChild("pFocus"):SetMax(1000)
		self.wndMain:FindChild("pFocus"):SetProgress(uMyHealer:GetMana())
		if uMyHealer:GetMana() <= tSettings["nLowFocus"] then
			self:SoundOffFocus()
		end--]]
	end
end

function Tankie:onTankieGroup_Updated()
		for i=1, GroupLib.GetMemberCount() do
		local tGroupMember = GroupLib.GetGroupMember(i)
		local tGroupMemberUnit = GroupLib.GetUnitForGroupMember(i)
		local GroupMemberRole = ""
		if tGroupMember.bHealer then
			GroupMemberRole = "Healer"
		elseif tGroupMember.bTank then
			GroupMemberRole = "Tank"
		else
			GroupMemberRole = "DPS"
		end
		
		if GroupMemberRole == "Healer" then
			-- here is where you would add this person to the *list* of healers	
			return tGroupMemberUnit
		end
	end
end


function Tankie:onTankieGroupJoined()
	self.wndMain:Invoke()
	local uMyHealer = Tankie:onTankieGroup_Updated()
	if not self.timerFocusUpdater then
		self.timerFocusUpdater:Start()
	end
	
	if not uMyHealer then
		self.timerFocusUpdater:Stop()
		self.wndMain:FindChild("wndDisplay"):Show(false, false, 2)
		self.wndMain:FindChild("wndResetHealer"):Show(true, false, 2)
	end
end

function Tankie:onTankieGroupLeft()
	self.wndMain:Close()
	self.timerFocusUpdater:Stop()
end

function Tankie:SoundOffFocus()
	if self.tCache["shoutedLowFocus"] == false then
		self.tCache["shoutedLowFocus"] = true 
		Sound.PlayFile("lowfocus.wav")
		self.ShoutCooldownTimer:Set(60.0,false)
		self.ShoutCooldownTimer:Start()
	end
end

function Tankie:onShoutCooldownTimer()
	self.ShoutCooldownTimer:Stop()
	self.tCache["shoutedLowFocus"] = false
end

---------------------------------------------------------------------------------------------------
-- TankieForm Functions
---------------------------------------------------------------------------------------------------

function Tankie:onScanForHealer( wndHandler, wndControl, eMouseButton )
	local uMyHealer = Tankie:onTankieGroup_Updated()
	if uMyHealer then
		self.timerFocusUpdater:Start()
		self.wndMain:FindChild("wndResetHealer"):Show(false, false, 2)
		self.wndMain:FindChild("wndDisplay"):Show(true, false, 2)
	elseif not uMyHealer then
		self.wndMain:FindChild("strNoneFound"):Show(false, false, 2.0)		
	end
end

-----------------------------------------------------------------------------------------------
-- Tankie Instance
-----------------------------------------------------------------------------------------------
local TankieInst = Tankie:new()
TankieInst:Init()
