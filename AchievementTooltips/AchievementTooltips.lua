-----------------------------------------------------------------------------------------------
-- Client Lua Script for AchievementTooltips
-- Created 2014 by Kekz aka Kullerkugel. 
-- Addon homepage: http://www.curse.com/ws-addons/wildstar/221383-achievementtooltips
-- Contact: http://www.curse.com/users/Kullerkugel
-- Version: 1.2, Modified: 20140615
-----------------------------------------------------------------------------------------------
 
require "Apollo"
require "GameLib" 
require "Window"
require "Achievement"
require "AchievementsLib"
 
-----------------------------------------------------------------------------------------------
-- AchievementTooltips Module Definition
-----------------------------------------------------------------------------------------------
local AchievementTooltips = {} 
local tAchievementTooltips = nil
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- Addon 'Achievements' variables
local tAchievements = nil
local wndAchievements = nil
local fOrigLoadSummaryScreen = nil
local fOrigBuildSimpleAchievement = nil
local fOrigOnRecentUpdateBtn = nil
local fOrigOnZoomToAchievementIfValid = nil
local fOrigToggleWindow = nil

-- Addon 'FloatTextPanel' variables
local tFloatTextPanel = nil
local fOrigOnAchievementNotice = nil
local fOrigOnAchievementOpenBtn = nil
local bFloatTextPanelInitDone = false
local idxFtpAchievements = 8

-- Own variables
local lstAchievementsAll = {}
local nTooltipType = 0 -- Tooltip type 0: OnCursor
local bHideDateTooltip = false
local bAnnounceGuildActive = false
local bPrimulaPresent = false
local sSlashcmd = "att"
local xmlDoc = nil
local buffer = ""
local log = nil--////////////////////////////////
local temporaryData = nil -- for calling WrapOnRecentUpdateBtn without the button
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function AchievementTooltips:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    return o
end

-- Life cycle method
function AchievementTooltips:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"Lib:ApolloFixes-1.0"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- AchievementTooltips Lifecycle
-----------------------------------------------------------------------------------------------
function AchievementTooltips:OnLoad()
	tAchievementTooltips = self

	-- Logging
	--local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	--log = GeminiLogging:GetLogger()
	--/////////////
	
	-- DEPENDENCIES
	-- Test for the FloatText package. It is not mentioned in the dependencies to allow for addons
	-- that replace the FloatText package without changing the FloatTextPanel
	--[[if Apollo.GetPackage("FloatText") == nil and Apollo.GetPackage("YetAnotherSCT") == nil then
		--log:info("Neither package 'FloatText' nor 'AnotherSCT' were found.")
		error("Neither package 'FloatText' nor 'YetAnotherSCT' were found. "..
			"AchievementTooltips depends on Carbine's FloatTextPanel. "..
			"Please report this error to the addon author, together with the name "..
			"of the addon you use to replace Carbine's 'FloatText'. "..
			"Maybe then, the compatibility can be fixed.")
			return
	end]]--
	if Apollo.GetPackage("FloatText") == nil then
		--log:info("Neither package 'FloatText' nor 'AnotherSCT' were found.")
		error("The package 'FloatText' was not found. "..
			"AchievementTooltips depends on Carbine's FloatTextPanel. "..
			"Please report this error to the addon author, together with the name "..
			"of the addon you use to replace Carbine's 'FloatText'. "..
			"Maybe then, the compatibility can be fixed.")
			return
	end
	
	-- Test for the Achievement addon. Primula is also compatible.
	if Apollo.GetPackage("Primula") == nil then 
		tAchievements = Apollo.GetAddon("Achievements") 
	else 
		tAchievements = Apollo.GetAddon("Primula")
		bPrimulaPresent = true
	end
	if tAchievements == nil then
		--log:info("Neither package 'Achievements' nor 'Primula' were found.")
		error("Neither package 'Achievements' nor 'Primula' were found. "..
			"AchievementTooltips depends on Carbine's Achievements. "..
			"Please report this error to the addon author, together with the name "..
			"of the addon you use to replace Carbine's 'Achievements'. "..
			"Maybe then, the compatibility can be fixed.")
			return
	end
	
	-- INIT
	--self:PopulateAchievementList() CRASH! in GetTradeskillAchievements
	-- Register handlers
	Apollo.RegisterSlashCommand(sSlashcmd, "OnSlashCmd", self)
	Apollo.RegisterSlashCommand("achtooltip", "OnSlashCmd", self) -- deprecated
	

	-- ACHIEVEMENTS
	-- Wrap LoadSummaryScreen, add tooltips
	fOrigLoadSummaryScreen = tAchievements.LoadSummaryScreen
	tAchievements.LoadSummaryScreen = WrapLoadSummaryScreen
	
	-- Wrap BuildSimpleAchievement, remove tooltips
	fOrigBuildSimpleAchievement = tAchievements.BuildSimpleAchievement
	tAchievements.BuildSimpleAchievement = WrapBuildSimpleAchievement
	
	-- Wrap OnRecentUpdateBtn, fix for tiered achievements
	fOrigOnRecentUpdateBtn = tAchievements.OnRecentUpdateBtn
	tAchievements.OnRecentUpdateBtn = WrapOnRecentUpdateBtn
	
	-- Wrap ToggleWindow, fix for ToggleWindow event from ProgressLog
	fOrigToggleWindow = tAchievements.ToggleWindow
	tAchievements.ToggleWindow = WrapToggleWindow
	
	-- Replace OnZoomToAchievmentIfValid, fix tree iteration (iteration is fixed? but add IsChecked test)
	fOrigOnZoomToAchievementIfValid = tAchievements.OnZoomToAchievementIfValid
	tAchievements.OnZoomToAchievementIfValid = FixOnZoomToAchievementIfValid
	
	
	-- FLOATTEXT
	--tFloatTextPanel = Apollo.GetAddon("FloatTextPanel") is not loaded at this point.
	-- this is done in AchievementTooltips:HandlerOnAlertAchievement. 
	-- Also c.f. LibApolloFixes caveat documentation.
	Apollo.RegisterEventHandler("AlertAchievement", "HandlerOnAlertAchievement", self)
	
	-- For guild chat announcement
	Apollo.RegisterEventHandler("AchievementGranted", "HandlerOnAchievementGranted", self)
end

-- Initialization of FloatTextPanel variables. Since it can not be guaranteed that FTP is already
-- loaded when AchievementTooltips is initialized, FTP is initialized when used the first time.
function AchievementTooltips:InitFtp()

	if not bFloatTextPanelInitDone then
		bFloatTextPanelInitDone = true
		self:PopulateAchievementList()
		
		-- Get the FloatTextPanel addon. This is only possible with LibApolloFixes
		tFloatTextPanel = Apollo.GetAddon("FloatTextPanel")
		
		-- Wrap the popup method to append the achievement description
		fOrigOnAchievementNotice = tFloatTextPanel.OnAchievementNotice
		tFloatTextPanel.OnAchievementNotice = WrapOnAchievementNotice
		
		fOrigOnAchievementOpenBtn = tFloatTextPanel.OnAchievementOpenBtn
		tFloatTextPanel.OnAchievementOpenBtn = WrapOnAchievementOpenBtn
		
		-- Make the "View" button invisible but stretch it over the whole popup
		local wndAch = tFloatTextPanel.tMainWindow[idxFtpAchievements]
		--wndAch:FindChild("AchievementOpenBtn"):Show(false)
		wndAch:FindChild("AchievementOpenBtn"):SetBGColor("")
		wndAch:FindChild("AchievementOpenBtn"):SetText("")
		wndAch:FindChild("AchievementOpenBtn"):SetAnchorOffsets(-441, -84, 20, -14)
	end
end


function AchievementTooltips:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.General then
        return nil
	end	
	
	local save = {}
	save.bHideDateTooltip = bHideDateTooltip
	save.bAnnounceGuildActive = bAnnounceGuildActive
	save.saved = true
	return save
end

function AchievementTooltips:OnRestore(eLevel, tData)
	if tData.saved == nil then
		return
	end
	if tData.bHideDateTooltip ~= nil then
		bHideDateTooltip = tData.bHideDateTooltip
	end
	if tData.bAnnounceGuildActive ~= nil then
		bAnnounceGuildActive = tData.bAnnounceGuildActive
	end
end

function AchievementTooltips:PopulateAchievementList()
	--TODO: "Mobile Home" not found, from pre order house
	-- Get achievements list and merge normal with guild- and tradeskill-achievements
	lstAchievementsAll = AchievementsLib.GetAchievements(false)
	local lstGAchievs = AchievementsLib.GetAchievements(true)
	for k, a in pairs(lstGAchievs) do
		table.insert(lstAchievementsAll, a)
	end
	-- Tradeskills: 1-Weaponsmith, 2-Cooking, 12-Armorer, 14-Outfitter, 16-Technologist, 17-Architect, 21-Tailor
	local iTadeskills = {1, 2, 12, 14, 16, 17, 21}
	local lstTAchievs = {}
	for i, n in ipairs(iTadeskills) do
		lstTAchievs = AchievementsLib.GetTradeskillAchievements(n)
		for k, a in pairs(lstTAchievs) do
			table.insert(lstAchievementsAll, a)
		end
	end
end

-- for calling WrapOnRecentUpdateBtn without the button
function AchievementTooltips:GetData()
	return temporaryData
end

-----------------------------------------------------------------------------------------------
-- AchievementTooltips SlashCmd
-----------------------------------------------------------------------------------------------
function AchievementTooltips:OnSlashCmd(strCmd, strArgs)
	if strArgs ~= nil then
		local strOption = string.match(strArgs, "%a+")
		if strOption == "toggledate" then
			bHideDateTooltip = not bHideDateTooltip
			
			-- Refresh achievements window
			if wndAchievements ~= nil then
				wndAchievements:BuildRightPanel()
			end
		elseif strOption == "toggleannounce" then
			bAnnounceGuildActive = not bAnnounceGuildActive
		else
			AchievementTooltips:PrintUsage()
		end
	end
	AchievementTooltips:PrintState()
end

-----------------------------------------------------------------------------------------------
-- Hooks for Carbine's Achievements Addon
-- They enhance the Achievements window.
-----------------------------------------------------------------------------------------------

-- Wrapper around Carbine's Achievements:LoadSummaryScreen function.
-- It calls the original method and then adds tooltips to the achievement items.
function WrapLoadSummaryScreen(achSelf)
	-- Check function reference
	if fOrigLoadSummaryScreen == nil then
		Print("Error: Reference to original LoadSummaryScreen is nil.")
		return
	end
	
	-- Call original function, populate recent achievement container
	fOrigLoadSummaryScreen(achSelf)
	
	-- Don't add the tooltip if the Addon "Primula" is installed, which adds the info directly to the buttons
	if bPrimulaPresent then
		return
	end
	
	-- Get recent achievement list
	local wndRecentUpdateContainer = achSelf.wndMain:FindChild("RightSummaryScreen:RecentUpdateFrame:RecentUpdateContainer")
	local tRecentItems = wndRecentUpdateContainer:GetChildren()
	
	-- Add tooltip to each item
	for idx,wndItem in ipairs(tRecentItems) do
		local achData = wndItem:FindChild("RecentUpdateBtn"):GetData()
		wndItem:FindChild("RecentUpdateBtn"):SetTooltip(
			"<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_BtnTextGreenNormal\">"..achData:GetName().."</P>"..
			"<P Font=\"CRB_InterfaceMedium\" TextColor=\"UI_TextHoloBodyCyan\">"..achData:GetCategory().."</P>"..
			"<P Font=\"CRB_InterfaceMedium\" >"..achData:GetDescription().."</P>"
			)
		-- Set tooltip type to OnCursor
		wndItem:FindChild("RecentUpdateBtn"):SetTooltipType(nTooltipType)
		-- Ignore mouse events on the RecentUpdateName window, so it triggers the underlying button
		local wndItemName = wndItem:FindChild("RecentUpdateBtn"):FindChild("RecentUpdateName")
		wndItemName:SetStyle("IgnoreMouse", true)
	end
end


-- Wrapper around Carbine's Achievements:BuildSimpleAchievement function.
-- Depending on the user configuration, date tooltips are removed from earned achievements.
function WrapBuildSimpleAchievement(achSelf, wndContainer, achData)
	-- Check function reference
	if fOrigBuildSimpleAchievement == nil then
		Print("Error: Reference to original BuildSimpleAchievement is nil.")
		return
	end
	
	-- Call original function, populate recent achievement container
	wndAchievements = achSelf
	fOrigBuildSimpleAchievement(achSelf, wndContainer, achData)
	
	-- Depending on configuration, remove date tooltip
	if bHideDateTooltip then
		wndContainer:SetTooltip("")
	end
end


-- Wrapper around Carbine's Achievements:OnRecentUpdateBtn function.
-- Tiered achievements are not scrolled into view correctly, this is fixed.
function WrapOnRecentUpdateBtn(achSelf, wndHandler, wndControl)
	-- Check function reference
	if fOrigOnRecentUpdateBtn == nil then
		Print("Error: Reference to original OnRecentUpdateBtn is nil.")
		return
	end
	
	-- Call original function
	fOrigOnRecentUpdateBtn(achSelf, wndHandler, wndControl)
	
	if ach == nil then
		return
	end
	
	-- Call EnsureChildVisible again for tiered achievements. I don't excatly know when to look for
	-- the parent tier and when for the child tier.
	local ach = wndHandler:GetData()
	local wndRightScroll = achSelf.wndMain:FindChild("RightScroll")
	local wndTarget = wndRightScroll:FindChildByUserData(ach)
	
	--tried to fix the scrolling for the first not completely visible item, but does not work
	--wndRightScroll:SetVScrollPos( wndRightScroll:GetVScrollRange() )
	
	if ach ~= nil and ( ach:GetParentTier() or ach:GetChildTier() ) then
		-- Hierarchy for tiered items is AchievementSimple/AchievementExtraContainer/TierBox/TierItem
		wndRightScroll:EnsureChildVisible(wndTarget:GetParent():GetParent():GetParent())
	end
end


-- Wrapper around Carbine's Achievements:ToggleWindow function.
-- It adds a call to OnRecentUpdateBtn to jump directly to an earned achievement
-- if called with achievement data
function WrapToggleWindow(achSelf, achData)
	fOrigToggleWindow(achSelf, achData)

	if achData ~= nil then
		-- use this addon as quick replacement for the calling button. Therefor a GetData() method is implemented.
		temporaryData = achData
		local wndHandler = tAchievementTooltips
		local wndControl = tAchievementTooltips
	
		achSelf:OnRecentUpdateBtn(wndHandler, wndControl)
	end
end


-- Replacement for Carbine's Achievement:OnZoomToAchievementIfValid function.
-- 1, deprecated: It fixes the identification of the correct categories. The categoryId is not
-- saved in the wndItems, but in their subsidiary button. On each level it is
-- the second item in the data table. ==> fixed now by Carbine
-- 2: categories are only opened if their are not already open. This prevents the categories
-- from being closed again if called twice in a row. This is needed for WrapToggleWindow.
function FixOnZoomToAchievementIfValid(achSelf, achArg)
	if not achArg or not achArg:GetCategoryId() then
		-- Abort zoom without achievement data
		return
	end

	if achArg:IsGuildAchievement() ~= achSelf.bShowGuild then
		achSelf.bShowGuild = achArg:IsGuildAchievement()
		achSelf:BuildCategoryTree()
		achSelf:LoadSummaryScreen()
	end

	local idArgCategory = achArg:GetCategoryId()
	-- Iterate top level
	for key, wndTopGroup in pairs(achSelf.wndMain:FindChild("BGLeft:LeftScroll"):GetChildren()) do
		local wndTopGroupBtn = wndTopGroup:FindChild("TopGroupBtn")
		if wndTopGroup:GetData() == idArgCategory and not wndTopGroupBtn:IsChecked() then
			achSelf:OnTopGroupSelect(wndTopGroupBtn) 
			return
		end
		
		-- Iterate middle level
		for key2, wndMiddleGroup in pairs(wndTopGroup:FindChild("GroupContents"):GetChildren()) do
			local wndMiddleGroupBtn = wndMiddleGroup:FindChild("MiddleGroupBtn")
			if wndMiddleGroup:GetData() == idArgCategory and not wndMiddleGroupBtn:IsChecked() then
				achSelf:OnBottomItemSelect(wndMiddleGroupBtn)
				return
			end

			-- Iterate bottom level
			for key3, wndBottomGroup in pairs(wndMiddleGroup:FindChild("GroupContents"):GetChildren()) do
				local wndBottomGroupBtn = wndBottomGroup:FindChild("BottomItemBtn")
				if wndBottomGroup:GetData() == idArgCategory and not wndBottomGroupBtn:IsChecked() then
					wndMiddleGroup:FindChild("MiddleExpandBtn"):SetCheck(true)
					achSelf:ResizeTree()
					achSelf:OnBottomItemSelect(wndBottomGroupBtn)
					return
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------------------
-- Hooks for Carbine's FloatTextPanel Addon
-- They enhance the achievement popup text.
-- Call order: OnAlertAchievement, OnAchievementNotice, OnAchievementGranted, OnAchievementUpdated
-----------------------------------------------------------------------------------------------

-- Handler AlertAchievement
-- Whether it is called before FloatTextPanel's OnAlertAchievement handler is not tested,
-- but it is definitely called before FloatTextPanel's OnAchievementNotice method.
-- Thus the function wrappers for FloatTextPanel are set here, before the first
-- time they are needed.
-- This works at the moment, but it depends on the timing (function call order)!
function AchievementTooltips:HandlerOnAlertAchievement(strAch)
	-- Use of FTP, now it is time to initialize the corresponding variables
	self:InitFtp()
end


-- Wrapper around Carbine's FloatTextPanel:OnAchievementNotice function.
-- This function triggers FloatTextPanel's popup. Append the achievement's description to the text.
function WrapOnAchievementNotice(ftpSelf, strAch)
	-- Since we only have the notice string and not the achievement data, 
	-- find the correct achievement by it's name.
	local found = false
	local i1, i2 = string.find(strAch, "\".*\"")
	local strName = string.sub(strAch, i1+1, i2-1)
	-- iterate all achievements
	for k, a in pairs(lstAchievementsAll) do
		if found ~= true and a:GetName() == strName and a:IsComplete() then
			-- this is the one
			found = true
			--log:info("Found ID"..a:GetId()..":"..a:GetName()..":"..a:GetDescription().." at "..k)
			-- special handling for tiered achievements. Only report newest tier.
			while a:GetChildTier() ~= nil and a:GetChildTier():IsComplete() do
				a = a:GetChildTier()
				--log:info("Switch to tier:"..a:GetId()..":"..a:GetName()..":"..a:GetDescription())
			end
			-- Append!
			strAch = strAch.."\n"..a:GetDescription()
		end
	end
	--Print("strAch:"..strAch)
	
	-- Warning if no matching achievement was found
	if not found then
		Print("AchievementTooltips Warning: No achievement matches the name '"..strName.."' from notice '"..strAch.."'")
		Print("(or you somehow got a popup without earning the achievement, which would be a bug?)")
		Print("You are free to report this on AchievementTooltips' Curse page.")
	end
	
	-- Check function reference
	if fOrigOnAchievementNotice == nil then
		Print("Error: Reference to original OnAchievementNotice is nil.")
		return
	end
	fOrigOnAchievementNotice(ftpSelf, strAch)
end


-- Wrapper around Carbine's FloatTextPanel:OnAchievementOpenBtn callback.
-- Since the handler in ProgressLog contains a typo, we repeat the event PL_ToggleAchievementWindow
-- with the correct achievement data.
function WrapOnAchievementOpenBtn(ftpSelf, wndHandler, wndControl)
	-- Original call
	fOrigOnAchievementOpenBtn(ftpSelf, wndHandler, wndControl)
	-- Repeat subsequent call with correct argument
	Event_FireGenericEvent("PL_ToggleAchievementWindow", wndHandler:GetData())
end


-- Handler AchievementGranted
-- Trigger guild chat announcement (circle? flist?)
function AchievementTooltips:HandlerOnAchievementGranted(ach)
	--log:info("Handler AGranted")
	--log:info(ach:GetId()..": "..ach:GetName())
	-- TODO
	if ach ~= nil and bAnnounceGuildActive then
		AchievementTooltips:AchievementAnnounce(ach)
	end
end


-----------------------------------------------------------------------------------------------
-- AchievementTooltips Chat Output
-----------------------------------------------------------------------------------------------
--GuildLib.GetGuilds()
function AchievementTooltips:OutCommand(strMessage)
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, strMessage)
end

function AchievementTooltips:OutGuild(strMessage)
	ChatSystemLib.Command("/guild "..strMessage)
end

--[[function test()
	AchievementTooltips:PopulateAchievementList()
	local lstAchievements = lstAchievementsAll
	local done = false
	for k, a in pairs(lstAchievements) do
		--log:info(k..": "..a:GetId()..": "..a:GetName())
		--if a:GetName() == "Immortal: Datascape" then
		--if a:GetName() == "Mobile Home" then
		--if a:GetName() == "Double Dealer" and not done then
		if a:GetName() == "Episode Completion: A Deadly Gloom" then
		--if a:GetName() == "Journeyman Salvage Tech I" then
			Print(a:GetId()..": "..a:GetName())
			--AchievementTooltips:HandlerOnAchievementGranted(a)
			tFloatTextPanel = Apollo.GetAddon("FloatTextPanel")
			AchievementTooltips:HandlerOnAlertAchievement(a:GetName())
			tFloatTextPanel:OnAchievementUpdated(a) -- set achievement data
			tFloatTextPanel:OnAchievementNotice("\""..a:GetName().."\"")
			--tAchievements:ToggleWindow(a)

			done = true
		end
	end
	
	for i=1,100 do
		local lstTAchievs = AchievementsLib.GetTradeskillAchievements(i)
		if lstTAchievs then
			--log:info(i)
		end
	end
end]]--

function AchievementTooltips:AchievementAnnounce(ach)
	if ach ~= nil then
		AchievementTooltips:OutGuild("[Achievement Earned] "..ach:GetName())
	end
end

function AchievementTooltips:PrintUsage()
	AchievementTooltips:OutCommand("AchievementTooltips Usage:\n"..
			"type '/"..sSlashcmd.." toggledate' to toggle whether achievement date tooltips are shown.\n"..
			"type '/"..sSlashcmd.." toggleannounce' to toggle whether achievements are announced in guild chat.")
			
end

function AchievementTooltips:PrintState()
	local strTooltips = "Showing achievement date tooltips."
	if bHideDateTooltip then
		strTooltips = "Hiding achievement date tooltips."
	end
	
	local strAnnounce = "Broadcast achievements to guild chat: disabled"
	if bAnnounceGuildActive then
		strAnnounce = "Broadcast achievements to guild chat: active"
	end
	
	AchievementTooltips:OutCommand("AchievementTooltips:")
	AchievementTooltips:OutCommand(strTooltips)
	AchievementTooltips:OutCommand(strAnnounce)
end

-----------------------------------------------------------------------------------------------
-- AchievementTooltips Instance
-----------------------------------------------------------------------------------------------
local AchievementTooltipsInst = AchievementTooltips:new()
AchievementTooltipsInst:Init()
