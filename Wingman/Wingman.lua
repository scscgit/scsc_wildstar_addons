-----------------------------------------------------------------------------------------------
-- Client Lua Script for Wingman
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GroupLib"
require "ChatSystemLib"

-----------------------------------------------------------------------------------------------
-- Wingman Module Definition
-----------------------------------------------------------------------------------------------
local Wingman = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Wingman:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Wingman:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Wingman OnLoad
-----------------------------------------------------------------------------------------------
function Wingman:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Wingman.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- Wingman OnDocLoaded
-----------------------------------------------------------------------------------------------
function Wingman:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "WingmanForm", nil, self)
		self.wndMain:Show(false)
		self.wndMain = nil
		self.xmlDoc = nil 
		

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("wingman", "OnWingman", self)


		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- Wingman Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/wingman"
function Wingman:OnWingman()
	self.fuckupsList = {}
	self:GroupDeserter()
	local chGroup = ""
	-- 0 is solo, 1-4 is party
	if GroupLib.GetMemberCount() == 0 then Print("You Do Not Have Deserter... You should open your eyes.") return end 
	
	local idType = ChatSystemLib.ChatChannel_Party
	if GroupLib.GetMemberCount() > 0 then idType = ChatSystemLib.ChatChannel_Warparty end
	for _,chId in pairs( ChatSystemLib.GetChannels() ) do 
		if chId:GetType() == ChatSystemLib.ChatChannel_Party then 
			chGroup = chId
		end
	end
	
	chGroup:Send("[Wingman Alert] -- People Cockblocking :: [ "..#self.fuckupsList.." ]")
	if #self.fuckupsList == 0 then return end 
	
	local strFuckUpsDeserter = ""
	local pos = 1 
	for _,v in pairs( self.fuckupsList ) do
		if pos == 1 then 
			strFuckUpsDeserter = v
			pos = 2 
		else 
			strFuckUpsDeserter = strFuckUpsDeserter .. ", " .. v 
		end 
	end
	
	chGroup:Send("Can't Triforce [ " .. strFuckUpsDeserter .. " ]")
	chGroup:Send("---[ End of List ]---")
	-- Check Deserter
	-- Instance
	-- ExistingQueue
end

function Wingman:GroupDeserter()
	local nMemberCount = GroupLib.GetMemberCount()
	if nMemberCount == 0 then 
		local player = GameLib.GetPlayerUnit()
		local memberInfo = player:GetBuffs() 	
		local tHarm = memberInfo.arHarmful	 	
		if #tHarm == 0 then return end -- zero harms
		for _,v in pairs (tHarm) do
			if v.splEffect:GetId() == 45444 then 
				local sUserName = player:GetName()
				table.insert(self.fuckupsList, sUserName)
			end
		end
		return
	end
	for i=1,nMemberCount do
		local player = GroupLib.GetUnitForGroupMember(i)
		local memberInfo = player:GetBuffs() 	
		local tHarm = memberInfo.arHarmful	 	
		if #tHarm == 0 then return end -- zero harms
		for _,v in pairs (tHarm) do
			if v.splEffect:GetId() == 45444 then 
				local sUserName = player:GetName()
				table.insert(self.fuckupsList, sUserName)
			end
		end
	end 
end
function Wingman:GroupInstance()
	local playerZoneMap = memberInfo.GetCurrentZoneMap().id
	local badKitteh = { 69 } -- Walatiki Temple ID = 69
	local nMemberCount = GroupLib.GetMemberCount()
	if nMemberCount == 0 then return end 
	
	--[[
		id 69
		strFolder PvPSmashandGrab
		strName Walatiki Temple
		ContinentId 40
	]]
	
	table.insert(sUserName, self.fuckupsList)
end
function Wingman:GroupQueues()
	table.insert(sUserName, self.fuckupsList)
end
-----------------------------------------------------------------------------------------------
-- Wingman Instance
-----------------------------------------------------------------------------------------------
local WingmanInst = Wingman:new()
WingmanInst:Init()
