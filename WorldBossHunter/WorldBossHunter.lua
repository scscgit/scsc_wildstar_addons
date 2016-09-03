-----------------------------------------------------------------------------------------------
-- Client Lua Script for WorldBossHunter
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- WorldBossHunter Module Definition
-----------------------------------------------------------------------------------------------
local WorldBossHunter = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
WorldBossHunter.WorldBossTable = {
['5756'] = {
['name'] = 'Metal Maw',
['loc'] = '-5135, -460',
['region'] = 'Deradune',
['title'] = 'The Biped Butche',
['level'] = 11,
['HP'] = 1300000
},
['5755'] = {
['name'] = 'Hoarding Stemdragon',
['loc'] = '-2585, -4512',
['region'] = 'Ellevar',
['title'] = 'The Weed Killer',
['level'] = 10,
['HP'] = 1270000
},
['3571'] = {
['name'] = 'Grendelus the Guardian',
['loc'] = '2773, -1461',
['region'] = 'Celestion',
['title'] = 'The Giant Slayer',
['level'] = 11,
['HP'] = 1400000
},
['3530'] = {
['name'] = 'Kraggar the Earth-Render',
['loc'] = '3515, -3316',
['region'] = 'Algoroc',
['title'] = 'The Rock Climber',
['level'] = 11,
['HP'] = 1400000
},
['5754'] = {
['name'] = 'King Honeygrave',
['loc'] = '-768, -2239',
['region'] = 'Auroria',
['title'] = 'King Slayer',
['level'] = 19,
['HP'] = 2500000
},
['3583'] = {
['name'] = 'Doomthorn the Ancient',
['loc'] = '6248, -2474',
['region'] = 'Galeras',
['title'] = 'Doomfeller',
['level'] = 22,
['HP'] = 2900000
},
['1438'] = {
['name'] = 'Metal Maw Prime',
['loc'] = '1976, 370',
['region'] = 'Whitevale',
['title'] = '',
['level'] = 30,
['HP'] = 4150000
},
['3942'] = {
['name'] = 'Defensive Protocol Unit',
['loc'] = '3756, -5818',
['region'] = 'Farside',
['title'] = 'The Defiant',
['level'] = 37,
['HP'] = 4750000
},
['UNKNOWN - Zoetic'] = {
['name'] = 'Zoetic',
['loc'] = '1079, -3604',
['region'] = 'Wilderrun',
['title'] = '',
['level'] = 40,
['HP'] = 5760000
},
['5729'] = {
['name'] = 'Pyre Everflame',
['loc'] = '1328, 2354',
['region'] = 'Hellrose Bowl Event - Malgrave',
['title'] = '',
['level'] = 45,
['HP'] = 6350000
},
['5727'] = {
['name'] = 'Makeshift Merfee',
['loc'] = '1328, 2354',
['region'] = 'Hellrose Bowl Event - Malgrave',
['title'] = '',
['level'] = 45,
['HP'] = 6320000
},
['5728'] = {
['name'] = 'Moltan',
['loc'] = '1328, 2354',
['region'] = 'Hellrose Bowl Event - Malgrave',
['title'] = '',
['level'] = 45,
['HP'] = 6350000
},
['4235'] = {
['name'] = 'Hellrose Bowl Event',
['loc'] = '1328, 2354',
['region'] = 'Malgrave',
['title'] = 'The Unburnable',
['level'] = 45,
['HP'] = 0
},
['4905'] = {
['name'] = 'R12',
['loc'] = '1790, 2074',
['region'] = 'Containement R-12 - Malgrave',
['title'] = '',
['level'] = 0,
['HP'] = 0
},
['5725'] = {
['name'] = 'Subject Y - Titan',
['loc'] = '1790, 2074',
['region'] = 'Containement R-12 - Malgrave',
['title'] = '',
['level'] = 0,
['HP'] = 0
},
['5726'] = {
['name'] = 'Subject H - Goliath',
['loc'] = '1790, 2074',
['region'] = 'Containement R-12 - Malgrave',
['title'] = '',
['level'] = 0,
['HP'] = 0
},
['5733'] = {
['name'] = 'Aggregor the Dust Eater',
['loc'] = '-22330, -27583',
['region'] = 'Crimson Badlands',
['title'] = '',
['level'] = 50,
['HP'] = 422000
},
['5475'] = {
['name'] = 'Scorchwing',
['loc'] = '2310, -6811',
['region'] = 'Blighthaven',
['title'] = 'Gut Gouger',
['level'] = 50,
['HP'] = 18900000
}
}
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WorldBossHunter:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function WorldBossHunter:Init()
    Apollo.RegisterAddon(self, true)
end
 

-----------------------------------------------------------------------------------------------
-- WorldBossHunter OnLoad
-----------------------------------------------------------------------------------------------
function WorldBossHunter:OnLoad()

	self.config = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self)

    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("WorldBossHunter.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- WorldBossHunter OnDocLoaded
-----------------------------------------------------------------------------------------------
function WorldBossHunter:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "WorldBossHunterForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self:initLocation()
		
	    self.wndMain:Show(false, true)

		Apollo.RegisterSlashCommand("wbh", "OnWorldBossHunterOn", self)

	end
end

function WorldBossHunter:initLocation()
	if self.config.char.Position ~= nil then
		self.wndMain:SetAnchorOffsets(self.config.char.Position.left, self.config.char.Position.top, self.config.char.Position.right, self.config.char.Position.bottom)
	else 
		self.config.char.Position = {}
		self.config.char.Position.left, self.config.char.Position.top, self.config.char.Position.right, self.config.char.Position.bottom = self.wndMain:GetAnchorOffsets()
	end
end

function WorldBossHunter:OnWindowChange( wndHandler, wndControl )
	self.config.char.Position = {}
	self.config.char.Position.left, self.config.char.Position.top, self.config.char.Position.right, self.config.char.Position.bottom =  self.wndMain:GetAnchorOffsets()
end
-----------------------------------------------------------------------------------------------
-- WorldBossHunter Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/wbk"
function WorldBossHunter:OnWorldBossHunterOn()
	self:InvokeWindow()
	end

function WorldBossHunter:OnConfigure()
	self:InvokeWindow()
end

function WorldBossHunter:InvokeWindow()
	--SendVarToRover("achievementLib",AchievementsLib)
	--SendVarToRover("List", AchievementsLib.GetAchievements())
	--SendVarToRover("Kill", AchievementsLib.GetAchievementsForCategory(Category))
	
	local AchievementsTable = AchievementsLib.GetAchievements() --AchievementsLib.GetAchievementsForCategory(Category )
	local container = self.wndMain:FindChild("WorldBossContainer")
	
	self:ClearContainer(container)
	
	for key, WB in pairs(self.WorldBossTable) do 
		WB.used = false
	end
	
	for key, achievement in pairs(AchievementsTable) do
		local isGuild = achievement:IsGuildAchievement()
		--Print("is " .. isGuild)
		if not isGuild then
			local achId = tostring(achievement:GetId())
			if self.WorldBossTable[achId] ~= nil then 
				local WB = self.WorldBossTable[achId]
				local line = Apollo.LoadForm(self.xmlDoc, "WorldBossLine", container, self)
				line:FindChild("AchievementName"):SetText(achievement:GetName())
				line:FindChild("WorldBossName"):SetText(WB.name)
				line:SetData(WB)
				local own = achievement:IsComplete()
				line:FindChild("ChkBox"):SetCheck(own)
				WB.used = true
			end
		end
	end
	
	for key, WB in pairs(self.WorldBossTable) do 
		if not WB.used then	
			local line = Apollo.LoadForm(self.xmlDoc, "WorldBossLine", container, self)
			line:FindChild("AchievementName"):SetText(WB.Achievement)
			line:FindChild("WorldBossName"):SetText(WB.name)
			line:SetData(WB)
			local own = false
			line:FindChild("ChkBox"):SetCheck(own)
			WB.used = true
		end
	end
	
	container:ArrangeChildrenVert()
	
	self.wndMain:Invoke() -- show the window
end

function WorldBossHunter:ClearContainer(container)
	local kids = container:GetChildren()
	container:SetData(nil)
	for k,v in pairs(kids) do
		v:Destroy()
	end
end

-----------------------------------------------------------------------------------------------
-- WorldBossHunterForm Functions
-----------------------------------------------------------------------------------------------

-- when the Cancel button is clicked
function WorldBossHunter:OnCancel()
	self.wndMain:Close() -- hide the window
end

---------------------------------------------------------------------------------------------------
-- WorldBossLine Functions
---------------------------------------------------------------------------------------------------

function WorldBossHunter:CustomGenerateTooltip( wndHandler, wndControl, eToolTipType, x, y )
	wndControl:SetTooltipDoc(nil)
	local name = wndHandler:GetData().name
	local HP = wndHandler:GetData().HP
	local level = wndHandler:GetData().level
	local title = wndHandler:GetData().title
	local region = wndHandler:GetData().region
	local coordinate = wndHandler:GetData().loc
	
	local TEXTCOLOR = 'UI_TextHoloBodyCyan'
	local TITLEFONT = 'CRB_Interface16_BB'
	local HEADFONT = 'CRB_Interface10_B'
	
	local xml = XmlDoc.new()
	xml:StartTooltip(Tooltip.TooltipWidth)
	
	xml:AddLine('<T Font="'.. TITLEFONT ..'">' .. name .. '</T>')
	xml:AddLine('<T Font="'.. HEADFONT ..'" TextColor="'..TEXTCOLOR ..'">Level:</T> ' .. level)
	xml:AddLine('<T Font="'.. HEADFONT ..'" TextColor="'..TEXTCOLOR ..'">HP: </T>' .. HP)
	xml:AddLine('<T Font="'.. HEADFONT ..'" TextColor="'..TEXTCOLOR ..'">Title: </T>' .. title)
	xml:AddLine('<T Font="'.. HEADFONT ..'" TextColor="'..TEXTCOLOR ..'">Position: </T>' .. region .. ' (' .. coordinate .. ')')
	
	wndControl:SetTooltipDoc(xml)
end

-----------------------------------------------------------------------------------------------
-- WorldBossHunter Instance
-----------------------------------------------------------------------------------------------
local WorldBossHunterInst = WorldBossHunter:new()
WorldBossHunterInst:Init()
