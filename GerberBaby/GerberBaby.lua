-----------------------------------------------------------------------------------------------
-- Client Lua Script for GerberBaby
-- Copyright (c) NCsoft. All rights reserved
-- Developed in 2015 by Serona Winddrop & Baelix Wadu (Entity - Exile - NA)
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- GerberBaby Module Definition
-----------------------------------------------------------------------------------------------
local GerberBaby = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function GerberBaby:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function GerberBaby:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- GerberBaby OnLoad
-----------------------------------------------------------------------------------------------
function GerberBaby:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("GerberBaby.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- GerberBaby OnDocLoaded
-----------------------------------------------------------------------------------------------
function GerberBaby:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "GerberBabyForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterEventHandler("Group_ReadyCheck", "OnGroup_ReadyCheck", self)
		Apollo.RegisterSlashCommand("gerber", "OnGroup_ReadyCheck", self)


		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- GerberBaby Functions
-----------------------------------------------------------------------------------------------
function GerberBaby:OnGroup_ReadyCheck()
	local tMemberName
	local tFoodFlag = false
	local tBuffs = GameLib.GetPlayerUnit():GetBuffs().arBeneficial
	
	if GroupLib.AmILeader() then
		for i=1, GroupLib.GetMemberCount() do
			if not GroupLib.IsMemberInGroupInstance(i) then return end
			local tMemberBuffs = GroupLib.GetUnitForGroupMember(i)
			
			if tMemberBuffs then
				tMemberBuffs = tMemberBuffs:GetBuffs().arBeneficial

				
				for b, s in pairs(tMemberBuffs) do
					if s.splEffect:GetName() == "Stuffed!" then
						tFoodFlag = true
					end
				end
			end
				
			if tFoodFlag == false then
					tMemberName = GroupLib.GetGroupMember(i)['strCharacterName']
					ChatSystemLib.Command("/w " .. tMemberName .. " You need a food buff, you Gerber Baby!")
			end

		tFoodFlag = false
		end
	end
	
	if not tBuffs then return end
	for k, v in pairs(tBuffs) do
		if v.splEffect:GetName()== "Stuffed!" then
			self.wndMain:Close()
			return
		end
	end
	self.wndMain:Invoke()
end

-----------------------------------------------------------------------------------------------
-- GerberBabyForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function GerberBaby:OnOK()
	self.wndMain:Close() -- hide the window
end

-- when the Cancel button is clicked
function GerberBaby:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- GerberBaby Instance
-----------------------------------------------------------------------------------------------
local GerberBabyInst = GerberBaby:new()
GerberBabyInst:Init()
