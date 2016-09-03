-----------------------------------------------------------------------------------------------
-- Client Lua Script for WildStarInstantMessenger
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Tooltip"
require "ChatSystemLib"
require "FriendshipLib"
require "GroupLib"
require "GameLib"
--$$$$$$$$$$$$$
--NOTES
--[[
blah blah blah blah blah blah blah
]]
--%%%%%%%%%%%%%%

-----------------------------------------------------------------------------------------------
-- WildStarInstantMessenger Module Definition
-----------------------------------------------------------------------------------------------
local WildStarInstantMessenger = {}

local VERSION = 1.23
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local ktEmoticons = {
	[":D"] = "WildStarInstantMessenger:VeryHappy",
	["-_-"] = "WildStarInstantMessenger:Bored",
	[":'("] = "WildStarInstantMessenger:Crying",
	[":/"] = "WildStarInstantMessenger:Disappointed",
	[">.<"] = "WildStarInstantMessenger:Doh",
	[":3"] = "WildStarInstantMessenger:Nyan",
	[":("] = "WildStarInstantMessenger:Sad",
	["O.O"] = "WildStarInstantMessenger:Shocked",
	["o.o"] = "WildStarInstantMessenger:Shocked",
	[":x"] = "WildStarInstantMessenger:Sick",
	[":X"] = "WildStarInstantMessenger:Sick",
	[":)"] = "WildStarInstantMessenger:Smile",
	["-.-"] = "WildStarInstantMessenger:Bored",
	["XD"] = "WildStarInstantMessenger:Tired",
	["X_X"] = "WildStarInstantMessenger:Tired",
	[";)"] = "WildStarInstantMessenger:Wink",
}

local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 		= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 			= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good] 			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent] 		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb] 			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		= "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		 	= "ItemQuality_Artifact",
}

local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0
	local iterator = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iterator
end
--[[
--local ChatWindowTemplate = {}
local ChatWindow = {}
ChatWindow.template = {}



function ChatWindow:new()
	o = Apollo.LoadForm(self.xmlDoc, "ChatDialogueTabbed", nil, self)

	return o
end
]]


-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function WildStarInstantMessenger:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    -- initialize variables here

    return o
end

function WildStarInstantMessenger:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = "WildStar IM"
	local tDependencies = {
		-- "UnitOrPackageName",
		--"Gemini:Hook-1.0"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end


-----------------------------------------------------------------------------------------------
-- WildStarInstantMessenger OnLoad
-----------------------------------------------------------------------------------------------
function WildStarInstantMessenger:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("WildStarInstantMessenger.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, ktADefaults )

	--Apollo.RemoveEventHandler("ItemLink", Apollo.GetAddon("ChatLog"))
end


-----------------------------------------------------------------------------------------------
-- WildStarInstantMessenger OnDocLoaded
-----------------------------------------------------------------------------------------------
function WildStarInstantMessenger:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.tChatData = {}
		self.wndWhispers = {}
		self.tNotifications = {}
		self.tLinks = {}
		self.nNextLinkIndex = 1
		self.twndItemLinkTooltips = {}
		self.bHasStockChat = false
		self.arChatColor = {
			[ChatSystemLib.ChatChannel_Command] 		= ApolloColor.new("ChatCommand"),
			[ChatSystemLib.ChatChannel_System] 			= ApolloColor.new("ChatSystem"),
			[ChatSystemLib.ChatChannel_Debug] 			= ApolloColor.new("ChatDebug"),
			[ChatSystemLib.ChatChannel_Say] 			= ApolloColor.new("ChatSay"),
			[ChatSystemLib.ChatChannel_Yell] 			= ApolloColor.new("ChatShout"),
			[ChatSystemLib.ChatChannel_Whisper] 		= ApolloColor.new("ChatWhisper"),
			[ChatSystemLib.ChatChannel_Party] 			= ApolloColor.new("ChatParty"),
			[ChatSystemLib.ChatChannel_AnimatedEmote] 	= ApolloColor.new("ChatEmote"),
			[ChatSystemLib.ChatChannel_Zone] 			= ApolloColor.new("ChatZone"),
			[ChatSystemLib.ChatChannel_ZonePvP] 		= ApolloColor.new("ChatPvP"),
			[ChatSystemLib.ChatChannel_Trade] 			= ApolloColor.new("ChatTrade"),
			[ChatSystemLib.ChatChannel_Guild] 			= ApolloColor.new("ChatGuild"),
			[ChatSystemLib.ChatChannel_GuildOfficer] 	= ApolloColor.new("ChatGuildOfficer"),
			[ChatSystemLib.ChatChannel_Society] 		= ApolloColor.new("ChatCircle2"),
			[ChatSystemLib.ChatChannel_Custom] 			= ApolloColor.new("ChatCustom"),
			[ChatSystemLib.ChatChannel_NPCSay] 			= ApolloColor.new("ChatNPC"),
			[ChatSystemLib.ChatChannel_NPCYell] 		= ApolloColor.new("ChatNPC"),
			[ChatSystemLib.ChatChannel_NPCWhisper] 		= ApolloColor.new("ChatNPC"),
			[ChatSystemLib.ChatChannel_Datachron] 		= ApolloColor.new("ChatNPC"),
			[ChatSystemLib.ChatChannel_Combat] 			= ApolloColor.new("ChatGeneral"),
			[ChatSystemLib.ChatChannel_Realm] 			= ApolloColor.new("ChatSupport"),
			[ChatSystemLib.ChatChannel_Loot] 			= ApolloColor.new("ChatLoot"),
			[ChatSystemLib.ChatChannel_Emote] 			= ApolloColor.new("ChatEmote"),
			[ChatSystemLib.ChatChannel_PlayerPath] 		= ApolloColor.new("ChatGeneral"),
			[ChatSystemLib.ChatChannel_Instance] 		= ApolloColor.new("ChatParty"),
			[ChatSystemLib.ChatChannel_WarParty] 		= ApolloColor.new("ChatWarParty"),
			[ChatSystemLib.ChatChannel_WarPartyOfficer] = ApolloColor.new("ChatWarPartyOfficer"),
			--removed scsc [ChatSystemLib.ChatChannel_Advice] 			= ApolloColor.new("ChatAdvice"),
			[ChatSystemLib.ChatChannel_AccountWhisper]	= ApolloColor.new("ChatAccountWisper"),
		}

		self.arSupportedChannels = {
			[ChatSystemLib.ChatChannel_Whisper] 		= "Whisper",
			[ChatSystemLib.ChatChannel_Party] 			= "Party",
			[ChatSystemLib.ChatChannel_Zone] 			= "Zone",
			[ChatSystemLib.ChatChannel_ZonePvP] 		= "Zone PvP",
			[ChatSystemLib.ChatChannel_Trade] 			= "Trade",
			[ChatSystemLib.ChatChannel_Guild] 			= "Guild",
			[ChatSystemLib.ChatChannel_GuildOfficer] 	= "GuildOfficer",
			--[ChatSystemLib.ChatChannel_Society] 		= "Society",
			--[ChatSystemLib.ChatChannel_Custom] 			= "Custom",
			--[ChatSystemLib.ChatChannel_Realm] 			= "Realm",
			[ChatSystemLib.ChatChannel_Instance] 		= "Instance",
			[ChatSystemLib.ChatChannel_WarParty] 		= "WarParty",
			--[ChatSystemLib.ChatChannel_WarPartyOfficer] = "WarPartyOfficer",
			--removed scsc [ChatSystemLib.ChatChannel_Advice] 			= "Advice",
			[ChatSystemLib.ChatChannel_AccountWhisper]	= "Account Whisper",
			--Custom
			[40] 			= "Chat History",
		}

		self.wndMove = Apollo.LoadForm(self.xmlDoc, "Move", nil, self)
		--self.wndMove:Show(false, true)

		self.wndChatNotifications = Apollo.LoadForm(self.xmlDoc, "ChatNotifications", self.wndMove:FindChild("MoveContainer"), self)
		--self.wndChatNotifications:Show(false, true)
		self.wndMessagePreview = self.wndChatNotifications:FindChild("MsgPreview")
		self.wndMessagePreview:Show(false, true)
		--Set Up MsgPrev Hide Delay
		--self.db.profile.messagePreview.nMsgPrevLength
		self.timerMsgPrevHide = ApolloTimer.Create(self.db.profile.messagePreview.nMsgPrevLength, false, "OnTimerMsgPrevHide", self)
		self.timerMsgPrevHide:Stop()

		self.wndConfirmAlert = Apollo.LoadForm(self.xmlDoc, "ConfirmAlert", nil, self)
		self.wndConfirmAlert:Show(false, true)
		--self.GeminiDB = Apollo.GetPackage("Gemini:DB-1.0").tPackage
		--self.GeminiHook = Apollo.GetPackage("Gemini:Hook-1.0").tPackage
		--self.GeminiHook:Embed(self)
		--ChatLog:OnChatMessage(channelCurrent, tMessage)
		--Apollo.GetAddon("ChatLog").OrigChatMessage = Apollo.GetAddon("ChatLog").OnChatMessage
		--self:RawHook(Apollo.GetAddon("ChatLog"),"OnChatMessage", "OnChatMessageSuppress")
		--VerifyChannelVisibility

		if Apollo.GetAddonInfo("ChatLog")["bRunning"] == 1 then
			self.bHasStockChat = true
		else
			self.bHasStockChat = false
		end

		--ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, "You do not have the stock Carbine ChatLog addon enabled and some parts of WildStar Instant Messenger will not work unless you enable it.", "WildStar Instant Messenger" )

		if self.bHasStockChat then
			Apollo.GetAddon("ChatLog").OrigVerify = Apollo.GetAddon("ChatLog").VerifyChannelVisibility
			Apollo.GetAddon("ChatLog").VerifyChannelVisibility = nil
			Apollo.GetAddon("ChatLog").VerifyChannelVisibility = WildStarInstantMessenger.VerifyReplacement
		end
		--self:RawHook(Apollo.GetAddon("ChatLog"),"VerifyChannelVisibility", "VerifyReplacement")
		--Color Picker
		GeminiColor = Apollo.GetPackage("GeminiColor").tPackage
  		self.colorPicker = GeminiColor:CreateColorPicker(self, "ColorPickerCallback", false, "ffffffff")
		self.colorPicker:Show(false, true)
		--Register Options
		self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsDialogue", nil, self)
		self.wndOptions:Show(false, true)
		self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControls", self.wndOptions:FindChild("OptionsDialogueControls"), self)
		--self.wndControls:Show(false, true)
		self.wndChannelColors = Apollo.LoadForm(self.xmlDoc, "ChannelColorsDialogue", nil, self)
		self.wndChannelColors:Show(false, true)

		for nChannelType, strChannelName in pairs(self.arSupportedChannels) do
			local wndCurr = Apollo.LoadForm(self.xmlDoc, "ChannelColorsItem", self.wndChannelColors:FindChild("OptionsDialogueControls"), self)
			wndCurr:FindChild("Label"):SetText(strChannelName)
			wndCurr:SetData({["nChannelType"] = nChannelType, ["strChannelName"] = strChannelName})
			-- Hide Outgoing for special custom channels
			if nChannelType > 39 then
				wndCurr:FindChild("OutSwatch"):Show(false)
			end
		end

		self.wndChannelColors:FindChild("OptionsDialogueControls"):ArrangeChildrenVert()

		--self.wndControls = Apollo.LoadForm(self.xmlDoc, "OptionsControls", self.wndOptions:FindChild("OptionsDialogueControls"), self)
		Apollo.LoadSprites("Sprites.xml")

		--Reset Chat Log
		--WildStarInstantMessenger:ResetChatLog()

		if not self.db.char.currentProfile then
			self.db.char.currentProfile = self.db:GetCurrentProfile()
		else
			self.db:SetProfile(self.db.char.currentProfile)
		end

		self:SetOptionControls()

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil

		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("wsim", "OnWildStarInstantMessengerOn", self)

		--Apollo.RegisterEventHandler("ShowActionBarShortcut", "ShowShortcutBar", self)
		--Apollo.RegisterEventHandler("ChatTellFailed", "OnEvent", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)

		Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
		Apollo.RegisterEventHandler("ItemLink", "OnItemLink", self)
		Apollo.RegisterEventHandler("GenericEvent_QuestLink", "OnQuestLink", self)
		Apollo.RegisterEventHandler("GenericEvent_ArchiveArticleLink", "OnArchiveArticleLink", self)

		--CharacterCreated
		--Apollo.RegisterEventHandler("InterfaceOptionsLoaded", "OnCharacterCreated", self)

		--self.wndTestEdit:SetText("ttttt")
		--WildStarInstantMessenger:PrintToTest(self, "test")

		--SetOptions (delayed)
		self.timerNoChat = ApolloTimer.Create(3.0, false, "OnTimerNoChat", self)
		self.timerNoChat:Start()




		-- Do additional Addon initialization here
		if self.bHasStockChat then
			Apollo.RemoveEventHandler("ItemLink", Apollo.GetAddon("ChatLog"))
		end
	end
end

function WildStarInstantMessenger:OnChatMessageSuppress(LuaCaller, channelCurrent, tMessage)
	--Print(channel)
	if channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper and self.db.profile.general.bSuppressWhispers then
		--Print(self:ProccessChatMessage(nil, tMessage.arMessageSegments))
		return
	elseif self.bHasStockChat then
		--Print(tostring(self.bHasStockChat))
		Apollo.GetAddon("ChatLog"):OrigChatMessage(channelCurrent, tMessage)
	end
end

function WildStarInstantMessenger:VerifyReplacement(channelChecking, tInput, wndChat)
	if channelChecking:GetType() == ChatSystemLib.ChatChannel_Whisper or channelChecking:GetType() == ChatSystemLib.ChatChannel_AccountWhisper then
		local strMessage = tInput.strMessage
		channelChecking:Send(strMessage)
	else
		Apollo.GetAddon("ChatLog"):OrigVerify(channelChecking, tInput, wndChat)
	end
end

function WildStarInstantMessenger:OnItemLink(itemLinked)
	if not self.bHasStockChat then
		return
	end
	-- scsc: there is no longer such event in ChatLog addon
	--Apollo.RemoveEventHandler("ItemLink", Apollo.GetAddon("ChatLog"))
	local currInput = self:GetCurrentInput(self)
	if currInput then
		tLink = {}
		tLink.uItem = itemLinked
		tLink.strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), itemLinked:GetName())
		WildStarInstantMessenger:AppendLink(currInput , tLink)
	else
		-- scsc: there is no longer such event in ChatLog addon
		--Apollo.GetAddon("ChatLog"):OnItemLink(itemLinked)
	end
end

function WildStarInstantMessenger:OnQuestLink(queLinked)
	if queLinked == nil or not self.bHasStockChat then
		return
	end
	Apollo.RemoveEventHandler("GenericEvent_QuestLink", Apollo.GetAddon("ChatLog"))
	local currInput = self:GetCurrentInput(self)
	if currInput then

		tLink = {}
		tLink.uQuest = queLinked
		tLink.strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), queLinked:GetTitle())
		WildStarInstantMessenger:AppendLink(currInput , tLink)
	else
		Apollo.GetAddon("ChatLog"):OnGenericEvent_QuestLink(queLinked)
	end
end

function WildStarInstantMessenger:OnArchiveArticleLink(artLinked)
	if artLinked == nil or not self.bHasStockChat then
		return
	end
	Apollo.RemoveEventHandler("GenericEvent_ArchiveArticleLink", Apollo.GetAddon("ChatLog"))
	local currInput = self:GetCurrentInput(self)
	if currInput then

		tLink = {}
		tLink.uArchiveArticle = artLinked
		tLink.strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), artLinked:GetTitle())
		WildStarInstantMessenger:AppendLink(currInput , tLink)
	else
		Apollo.GetAddon("ChatLog"):OnGenericEvent_ArchiveArticleLink(artLinked)
	end
end

function WildStarInstantMessenger:AppendLink(wndEdit, tLink)
	local text = wndEdit:GetText()
	local tSelectedText = wndEdit:GetSel()
	if tSelectedText.cpCaret == 0 then
		tSelectedText.cpCaret = text:len()
	end
	--Print(tSelectedText.cpCaret)
	wndEdit:AddLink( tSelectedText.cpCaret, tLink.strText, tLink )
	--self:OnInputChanged(nil, wndEdit, wndEdit:GetText())
	wndEdit:SetFocus()
end

function WildStarInstantMessenger:GetCurrentInput(self)
	local input
	for strName, wndCurrent in pairs(self.wndWhispers or {}) do
		if wndCurrent:FindChild("EditBox1"):GetData() and wndCurrent:IsVisible() then
			input = wndCurrent:FindChild("EditBox1")
			break
		end
	end

	return input
end


-----------------------------------------------------------------------------------------------
-- WildStarInstantMessenger Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- from ESC menu
function WildStarInstantMessenger:OnConfigure()
	self.wndOptions:Invoke()
end

-- on SlashCommand "/wsim"
function WildStarInstantMessenger:OnWildStarInstantMessengerOn()
	self.wndOptions:Invoke()
end

-- on timer
function WildStarInstantMessenger:OnTimerNoChat()
	if Apollo.GetAddonInfo("ChatLog")["bRunning"] == 1 then
		self.bHasStockChat = true
	else
		self.bHasStockChat = false
		ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, "You do not have the stock Carbine ChatLog addon enabled and some parts of WildStar Instant Messenger will not work unless you enable it.", "WildStar Instant Messenger" )
	end
end

function WildStarInstantMessenger:OnUnitEnteredCombat(...)
	local arg1, bInCombat = ...
	local sUnitName = arg1:GetName()
	self.bInCombat = bInCombat
	if sUnitName == GameLib.GetPlayerUnit():GetName() and bInCombat and self.db.profile.general.bHideCombat then
		WildStarInstantMessenger:HideAllWindows(self)
	elseif sUnitName == GameLib.GetPlayerUnit():GetName() and not bInCombat and self.db.profile.general.bHideCombat then
		WildStarInstantMessenger:ShowCombatWindows(self)
	end
end

function WildStarInstantMessenger:HideAllWindows(self)
	self.arHiddenInCombat = {}
	for k, v in pairs(self.wndWhispers) do
		if v:IsShown() then
			table.insert(self.arHiddenInCombat, k)
		end
		v:Show(false)
	end
end

function WildStarInstantMessenger:ShowCombatWindows(self)
	if self.arHiddenInCombat == nil then
		return
	end
	for _, v in ipairs(self.arHiddenInCombat) do
		self.wndWhispers[v]:Show(true)
	end
	self.arHiddenInCombat = nil
end

function WildStarInstantMessenger:ShowAllAlerts(self)
	for k, v in pairs(self.tNotifications) do
		if self.wndWhispers[k] and v.bNewMsg then
			self:UpdateScrollPos(self.wndWhispers[k])
			self.tNotifications[k]["bNewMsg"] = false
			self.wndWhispers[k]:Show(true)
		end
	end
	self:UpdateNotificationList(self)
	self:UpdateNotificationAlert(self)
end

function WildStarInstantMessenger:OnChatMessage(...)
	-- tMessage has bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction, nReportId

	local arg1, arg2, arg3, arg4, arg5 = ...
	if arg1:GetType() == ChatSystemLib.ChatChannel_Whisper or arg1:GetType() == ChatSystemLib.ChatChannel_AccountWhisper then
		local strSender = arg2.strSender
		if arg2.strRealmName:len() > 0 then
			strSender = arg2.strSender .. "@" .. arg2.strRealmName
		end
		if self.wndWhispers[strSender] == nil then
			self.tNotifications[strSender] = {
				["strName"] = strSender,
				["bNewMsg"] = false
			}
			self:PopWhisper(arg1, arg2)
			self:AddToChatWindow(arg1, arg2, true)
		elseif self.wndWhispers[strSender]:IsVisible() then
			self:AddToChatWindow(arg1, arg2)
		elseif self.db.profile.general.bShowEvery then
			if not self.bInCombat and self.db.profile.general.bHideCombat then
				self.wndWhispers[strSender]:Show(true)
			end
			self:AddToChatWindow(arg1, arg2)
		else
			self.tNotifications[strSender]["bNewMsg"] = true
			self:AddToChatWindow(arg1, arg2)
			self:UpdateNotificationAlert(self)
			--Show Prev
			self:ShowMsgPreview(arg2)
		end
	else
		if arg1:GetType() == ChatSystemLib.ChatChannel_Zone and self.db.profile.chatChannels.bShowZoneChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_Guild and self.db.profile.chatChannels.bShowGuildChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_Advice and self.db.profile.chatChannels.bShowAdviceChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_Party and self.db.profile.chatChannels.bShowPartyChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_WarParty and self.db.profile.chatChannels.bShowWarPartyChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_Instance and self.db.profile.chatChannels.bShowInstanceChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_Trade and self.db.profile.chatChannels.bShowTradeChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_GuildOfficer and self.db.profile.chatChannels.bShowGuildOfficerChat then
		elseif arg1:GetType() == ChatSystemLib.ChatChannel_ZonePvP and self.db.profile.chatChannels.bShowZonePvPChat then
		else
			return
		end
		if self.wndWhispers[arg1:GetName()] == nil then
			self.tNotifications[arg1:GetName()] = {
				["strName"] = arg1:GetName(),
				["bNewMsg"] = false
			}
			self:PopOther(arg1)
			self:AddToChatWindow(arg1, arg2, true)
		elseif self.wndWhispers[arg1:GetName()]:IsVisible() then
			self:AddToChatWindow(arg1, arg2)
		elseif self.db.profile.general.bShowEvery and not self.db.profile.general.bShowEveryWhisper then
			if not self.bInCombat and self.db.profile.general.bHideCombat then
				self.wndWhispers[arg1:GetName()]:Show(true)
			end
			self:AddToChatWindow(arg1, arg2)
		else
			--self.tNotifications[arg1:GetName()]["bNewMsg"] = true
			self:AddToChatWindow(arg1, arg2)
			--self:UpdateNotificationAlert(self)
		end
	end
end

local function GetTime(source)
	if source == "Local" then
		local tm = GameLib.GetLocalTime()
		return "["..string.format("%d:%02d", tm.nHour, tm.nMinute).."]"
	elseif source == "Server" then
		local tm = GameLib.GetServerTime()
		return "["..string.format("%d:%02d", tm.nHour, tm.nMinute).."]"
	else
		return ""
	end
end

local function EscapeString(strText)
	local strOut = ""
	strOut = string.gsub(strText, "(%W)", "%%%1")

	return strOut
end

local function RemoveEscapes(strText)
	local strOut = ""
	strOut = string.gsub(strText, "%%(%W)", "%1")

	return strOut
end

function WildStarInstantMessenger:ShowMsgPreview(tMessage)
	if not self.db.profile.messagePreview.bEnableMsgPrev then
		return
	end

	self.wndMessagePreview:Show(false)

	if self.db.profile.messagePreview.strMsgPrevPos == "Left" then
		self.wndMessagePreview:SetAnchorOffsets(-279, -50, -23, 50)
	else
		self.wndMessagePreview:SetAnchorOffsets(23, -50, 279, 50)
	end

	local bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction, nReportId = tMessage.bAutoResponse, tMessage.bGM, tMessage.bSelf, tMessage.strSender, tMessage.strRealmName, tMessage.nPresenceState, tMessage.arMessageSegments, tMessage.unitSource, tMessage.bShowChatBubble, tMessage.bCrossFaction, tMessage.nReportId
	if bSelf then -- bSelf
		return
	end
	if strRealmName:len() > 0 then
		strSender = strSender .. "@" .. strRealmName
	end
	--From
	self.wndMessagePreview:FindChild("From"):SetText(strSender)

	local strMsgText = ""
	for i, tSegment in ipairs(arMessageSegments) do
		strMsgText = strMsgText..tSegment.strText
	end
	--Text
	self.wndMessagePreview:FindChild("Text"):SetText(strMsgText)
	--Text Color
	--self.wndMessagePreview:FindChild("Text"):SetTextColor()

	self.wndMessagePreview:Show(true)
	--start timer
	self.timerMsgPrevHide:Stop()
	self.timerMsgPrevHide:Start()

end

function WildStarInstantMessenger:OnTimerMsgPrevHide()
	self.wndMessagePreview:Show(false)
end


-- tMessage has bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction, nReportId
function WildStarInstantMessenger:AddToChatWindow(channelCurrent, tMessage, bIsFirst)
	local xml = XmlDoc.new()
	local sLine, crText
	local bAutoResponse, bGM, bSelf, strSender, strRealmName, nPresenceState, arMessageSegments, unitSource, bShowChatBubble, bCrossFaction, nReportId = tMessage.bAutoResponse, tMessage.bGM, tMessage.bSelf, tMessage.strSender, tMessage.strRealmName, tMessage.nPresenceState, tMessage.arMessageSegments, tMessage.unitSource, tMessage.bShowChatBubble, tMessage.bCrossFaction, tMessage.nReportId
	local chatLine
	local saveText = ""
	local strChannelName = channelCurrent:GetName()
	local nChannelType = channelCurrent:GetType()
	if strRealmName:len() > 0 then
		-- Name/Realm formatting needs to be very specific for cross realm chat to work
		strSender = strSender .. "@" .. strRealmName
	end
	local nChannelType = channelCurrent:GetType()
	if nChannelType == ChatSystemLib.ChatChannel_Whisper or nChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
		chatLine = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.wndWhispers[strSender]:FindChild("EditBox"), self)
	else
		chatLine = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.wndWhispers[strChannelName]:FindChild("EditBox"), self)
	end
	--colors
	if bSelf then
		crText = self.db.profile.windowAppearance.tChannelColors.tOutgoing[nChannelType]
	else
		crText = self.db.profile.windowAppearance.tChannelColors.tIncoming[nChannelType]
	end
	--Time and start line
	local strTime = GetTime(self.db.profile.windowAppearance.sTimestamps)
	xml:AddLine(strTime, crText, "CRB_Interface10", "Left")
	saveText = saveText..strTime
	--Name
	xml:AppendText(" [", crText, "CRB_Interface10", "Left")
	saveText = saveText.." ["
	local strName
	local crName = ApolloColor.new("white")
	if bSelf then
		strName = GameLib.GetPlayerUnit():GetName()
	else
		strName = strSender
	end


	xml:AppendText(strName, crName, "CRB_Interface10", {CharacterName=strName, nReportId=nReportId}, "Source")
	xml:AppendText("]: ", crText, "CRB_Interface10", "Left")
	saveText = saveText..strName.."]: "
	-- Text Block
	for i, tSegment in ipairs(arMessageSegments) do
		local strText = tSegment.strText
		local bAlien = tSegment.bAlien or bCrossFaction
		local crChatText = crText;
		local strChatFont = "CRB_Interface10"
		local tLink = {}
		saveText = saveText..strText
		--Print(strText)
			if tSegment.uItem ~= nil then
				-- Is Item Link
				--Print(item)
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uItem:GetName())
				crChatText = karEvalColors[tSegment.uItem:GetItemQuality()]

				tLink.strText = strText
				tLink.uItem = tSegment.uItem

			elseif tSegment.uQuest ~= nil then -- quest link
				-- Is Quest Link
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uQuest:GetTitle())
				crChatText = ApolloColor.new("green")

				tLink.strText = strText
				tLink.uQuest = tSegment.uQuest

			elseif tSegment.uArchiveArticle ~= nil then -- archive article
				-- Is Article
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uArchiveArticle:GetTitle())
				crChatText = ApolloColor.new("ffb7a767")

				tLink.strText = strText
				tLink.uArchiveArticle = tSegment.uArchiveArticle

			else
				if bAlien or tSegment.bProfanity then
					strChatFont = "CRB_AlienMedium"
				end
			end
			--Emote Finder
			for word in string.gmatch(strText, "[%pDpPsSxXoO3Cc%-%.]+") do
				if ktEmoticons[word] and self.db.profile.windowAppearance.bShowEmoticons then

					word = EscapeString(word)
					local strSubSegment = string.match(strText, "^(.-)"..word)
					xml:AppendText(strSubSegment, crChatText, strChatFont)

					xml:AppendImage(ktEmoticons[RemoveEscapes(word)], 20, 20)

					strText = string.gsub(strText, strSubSegment..word, "", 1)
				end
			end
			--Link Finder
			for link in string.gmatch(strText, "https?%:%/%/%S+") do

				link = EscapeString(link)
				local strSubSegment = string.match(strText, "^(.-)"..link)
				xml:AppendText(strSubSegment, crChatText, strChatFont)

				xml:AppendText("["..RemoveEscapes(link).."]", "fffff799", strChatFont, {strUrl=RemoveEscapes(link)} , "URL")

				strText = string.gsub(strText, strSubSegment..link, "", 1)
			end
			if next(tLink) == nil then
				xml:AppendText(strText, crChatText, strChatFont)
			else
				local strLinkIndex = tostring(self:SaveLink(tLink))
				-- Attributes have to be text
				xml:AppendText(strText, crChatText, strChatFont, {strIndex=strLinkIndex} , "Link")
			end
	end

	chatLine:SetDoc(xml)
	chatLine:SetHeightToContentHeight()

	if nChannelType == ChatSystemLib.ChatChannel_Whisper or nChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
	if bIsFirst then
		--nada
		WildStarInstantMessenger:UpdateScrollPos(self.wndWhispers[strSender])

		if self.db.profile.general.bShowOnFirst then
			self.wndWhispers[strSender]:Show(true)
		else
			self.tNotifications[strSender]["bNewMsg"] = true
			self:UpdateNotificationAlert(self)
		end
		if self.db.profile.general.bFocusShow then
			self.wndWhispers[strSender]:FindChild("EditBox1"):SetFocus()
		end
	elseif self.wndWhispers[strSender]:IsVisible() then
		WildStarInstantMessenger:UpdateScrollPos(self.wndWhispers[strSender])
		if self.db.profile.general.bFocusShow then
			self.wndWhispers[strSender]:FindChild("EditBox1"):SetFocus()
		end
	end
	self:AddToChatLog(self, strSender, saveText)
	if self.db.profile.general.bPlaySound then
		if self.db.profile.general.bPlaySoundHidden and not self.wndWhispers[strSender]:IsVisible() then
			Sound.Play(Sound.PlayUISocialWhisper)
		elseif not self.db.profile.general.bPlaySoundHidden then
			Sound.Play(Sound.PlayUISocialWhisper)
		end
	end
	else
		--nada
		WildStarInstantMessenger:UpdateScrollPos(self.wndWhispers[strChannelName])

		if self.db.profile.general.bShowOnFirst and bIsFirst and not self.db.profile.general.bShowOnFirstWhisper then
			self.wndWhispers[strChannelName]:Show(true)
		end
		self:AddToChatLog(self, strChannelName, saveText)
	end

end

function WildStarInstantMessenger:AddLogToWindow(self, strSender)
	local chatLine, xml
	local ChatHistory = 40
	local crText = self.db.profile.windowAppearance.tChannelColors.tIncoming[ChatHistory]

	if self.db.char.tChatLog[strSender] == nil then
		self.db.char.tChatLog[strSender] = {}
		return
	end

	for date, _ in pairsByKeys(self.db.char.tChatLog[strSender]) do
		--Format Change
		if type(self.db.char.tChatLog[strSender][date]) == "string" then
			WildStarInstantMessenger:ResetChatLog(self)
			ChatSystemLib.PostOnChannel( ChatSystemLib.ChatChannel_System, "The current chat history is not compatible with this version.\nResetting history to new format.", "WildStar Instant Messenger" )
			return
		end
		--Print Date
		xml = XmlDoc.new()
		chatLine = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.wndWhispers[strSender]:FindChild("EditBox"), self)
		local strDate = "["..date.."]"
		xml:AddLine(strDate, crText, "CRB_Interface10_B", "Center")
		chatLine:SetDoc(xml)
		chatLine:SetHeightToContentHeight()

		for i, v in ipairs(self.db.char.tChatLog[strSender][date]) do
			--Print Msg
			xml = XmlDoc.new()
			chatLine = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.wndWhispers[strSender]:FindChild("EditBox"), self)
			if v == nil or v == "" then
				v = " "
			end
			xml:AddLine("", crText, "CRB_Interface10", "Left")
			xml:AppendText(tostring(v), crText, "CRB_Interface10", "Left")
			chatLine:SetDoc(xml)
			chatLine:SetHeightToContentHeight()
		end
	end
	--Footer
	xml = XmlDoc.new()
	chatLine = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.wndWhispers[strSender]:FindChild("EditBox"), self)
	xml:AddLine("-", crText, "CRB_Interface10", "Center")
	chatLine:SetDoc(xml)
	chatLine:SetHeightToContentHeight()

	self:UpdateScrollPos(self.wndWhispers[strSender])
end

function WildStarInstantMessenger:AddToChatLog(self, strSender, saveText, strDate)
	local nMaxLines = self.db.profile.nMaxLines
	local nMaxDates = self.db.profile.nMaxDates
	local nTotalDates = 0
	local nTotalLines = 0
	local strDate = strDate or os.date("%m/%d/%Y")

	--WildStarInstantMessenger:ResetChatLog(self)

	if self.db.char.tChatLog[strSender] == nil then
		self.db.char.tChatLog[strSender] = {}
		self.db.char.tChatLog[strSender][strDate] = {}
	else
		if self.db.char.tChatLog[strSender][strDate] == nil then
			self.db.char.tChatLog[strSender][strDate] = {}
		else
			for k, _ in pairs(self.db.char.tChatLog[strSender][strDate]) do
				nTotalLines = nTotalLines + 1
			end

			if nTotalLines >= nMaxLines then
				table.remove(self.db.char.tChatLog[strSender][strDate], 1)
			end
		end

		for date, _ in pairs(self.db.char.tChatLog[strSender]) do
			nTotalDates = nTotalDates + 1
		end

		if nTotalDates > nMaxDates then
			--table.remove(self.db.char.tChatLog[strSender], 1)
			for date, tTable in pairsByKeys(self.db.char.tChatLog[strSender]) do
				self.db.char.tChatLog[strSender][date] = nil
				break
			end
		end
	end

	-- scsc: for some reason it can be nil and thus does errors, so we exclude it
	local a = self.db.char.tChatLog[strSender][strDate];
	local b = saveText;
	if a and b then
		table.insert(a, b)
	end

	--This comes to a max of 25 per a date with a max of 5 dates per a person (125 total lines) :/
	--	I wanted to try 25 total but how would you figure out where to remove a line?
	--	Maybe you could try and figure out the oldest date and get rid of it?
	--
	--	***Set a max for the dates too... like 3 to 5***
end

function WildStarInstantMessenger:ResetSenderChatLog(strSender)
	self.db.char.tChatLog[strSender] = nil
	self.db.char.tChatLog[strSender] = {}
end

function WildStarInstantMessenger:ResetChatLog(self)
	self.db.char.tChatLog = nil
	self.db.char.tChatLog = {}
end

function WildStarInstantMessenger:ResetChatLogButton(...)
	self.db.char.tChatLog = nil
	self.db.char.tChatLog = {}
end



function WildStarInstantMessenger:PopWhisper(channelCurrent, tMessage)
	local strSender = tMessage.strSender
	local strRealmName = tMessage.strRealmName
	if tMessage.strRealmName:len() > 0 then
	--[[
		--Figure out whether to use this or not
		if channelCurrent:GetType() == ChatSystemLib.ChatChannel_AccountWhisper then
			strRealmName = GameLib.GetRealmName()
		end
	]]
		strSender = strSender .. "@" .. strRealmName
	end

	local tChatData = {}
	tChatData = {
		["strDisplayName"]		= tMessage.strSender,
		["strSender"]		= strSender,
		["channelCurrent"] = channelCurrent,
		["strRealmName"] = strRealmName,
		["presenceState"] = tMessage.nPresenceState,
		["crossFaction"] = tMessage.bCrossFaction,
		["reportID"] = tMessage.nReportId,
		["unitSource"] = tMessage.unitSource
	}

	if self.db.profile.windowAppearance.bUseMinimalStyle then
		self.wndWhispers[strSender] = Apollo.LoadForm(self.xmlDoc, "ChatDialogueMinimal", nil, self)
	else
		self.wndWhispers[strSender] = Apollo.LoadForm(self.xmlDoc, "ChatDialogueTabbed", nil, self)
	end

	self.wndWhispers[strSender]:SetStyle("Escapable", self.db.profile.general.bCloseOnEscape)

	self.wndWhispers[strSender]:SetData(tChatData)

	self.wndWhispers[strSender]:Show(false)

	self.wndWhispers[strSender]:SetText(strSender)

	self.wndWhispers[strSender]:SetOpacity(self.db.profile.windowAppearance.nOpacity)

	local l, t, r, b = self.wndWhispers[strSender]:GetAnchorOffsets()
	self.wndWhispers[strSender]:SetAnchorOffsets(l, t, l+self.db.profile.windowAppearance.nWidth, t+self.db.profile.windowAppearance.nHeight)

	if not self.db.profile.windowAppearance.bUseMinimalStyle then
		self.wndWhispers[strSender]:FindChild("Title"):SetText(strSender)
	end

	for name, wndChat in pairs(self.wndWhispers) do
		wndChat:FindChild("EditBox1"):SetData(false)
	end
	self.wndWhispers[strSender]:FindChild("EditBox1"):SetData(true)
	--Level: 88 - Medic
	--local classID = tMessage.unitSource:GetClassId()
	--self.wndWhispers[tMessage.strSender]:FindChild("Level"):SetText(tMessage.unitSource:GetLevelString().." - "..GameLib.GetClassName(classID))

	--self.wndWhispers[tMessage.strSender]:FindChild("EditBox"):ArrangeChildrenVert()


	--[[
	--CASCADE
	local nLeft, mTop, nRight, nBottom = self.wndWhispers[tMessage.strSender]:GetAnchorOffsets()
		WildStarInstantMessenger:GetTotalWindows(self, true)
	end
	]]

	--Add History (Chat Log)
	WildStarInstantMessenger:AddLogToWindow(self, strSender)

end

function WildStarInstantMessenger:PopOther(channelCurrent)
	local strChannelName
	if type(channelCurrent) == "string" then
		strChannelName = channelCurrent
	else
		strChannelName = channelCurrent:GetName()
	end

	local tChatData = {}
	tChatData = {
		["strDisplayName"]		= strChannelName,
		["strSender"]		= false,
		["channelCurrent"] = channelCurrent,
		--["strRealmName"] = tMessage.strRealmName,
		--["presenceState"] = tMessage.nPresenceState,
		--["crossFaction"] = tMessage.bCrossFaction,
		--["reportID"] = tMessage.nReportId,
		--["unitSource"] = tMessage.unitSource
	}

	if self.db.profile.windowAppearance.bUseMinimalStyle then
		self.wndWhispers[strChannelName] = Apollo.LoadForm(self.xmlDoc, "ChatDialogueMinimal", nil, self)
	else
		self.wndWhispers[strChannelName] = Apollo.LoadForm(self.xmlDoc, "ChatDialogueTabbed", nil, self)
		self.wndWhispers[strChannelName]:FindChild("AddFriend"):Show(false)
		self.wndWhispers[strChannelName]:FindChild("InviteGroup"):Show(false)
	end

	self.wndWhispers[strChannelName]:SetStyle("Escapable", self.db.profile.general.bCloseOnEscape)

	self.wndWhispers[strChannelName]:SetText(strChannelName)

	self.wndWhispers[strChannelName]:SetData(tChatData)

	self.wndWhispers[strChannelName]:SetOpacity(self.db.profile.windowAppearance.nOpacity)

	self.wndWhispers[strChannelName]:Show(false)

	local l, t, r, b = self.wndWhispers[strChannelName]:GetAnchorOffsets()
	self.wndWhispers[strChannelName]:SetAnchorOffsets(l, t, l+self.db.profile.windowAppearance.nWidth, t+self.db.profile.windowAppearance.nHeight)

	if not self.db.profile.windowAppearance.bUseMinimalStyle then
		self.wndWhispers[strChannelName]:FindChild("Title"):SetText(strChannelName)
	end

	for name, wndChat in pairs(self.wndWhispers) do
		wndChat:FindChild("EditBox1"):SetData(false)
	end
	self.wndWhispers[strChannelName]:FindChild("EditBox1"):SetData(true)

	--Add History (Chat Log)
	WildStarInstantMessenger:AddLogToWindow(self, strChannelName)
end

function WildStarInstantMessenger:GetTotalWindows(self, bOnlyShown)
	local i = 0
	for k, v in pairs(self.wndWhispers) do
		if bOnlyShown and v:IsShown() then
			i = i + 1
		elseif not bOnlyShown then
			i = i + 1
		end
	end
	return i
end

function WildStarInstantMessenger:UpdateNotificationList(self)
	--self.tNotifications = {}
	self.wndChatNotifications:FindChild("NotificationList"):FindChild("ScrollList"):DestroyChildren()
	for k, v in pairs(self.tNotifications) do
		self.tNotifications[k]["objListItem"] = Apollo.LoadForm(self.xmlDoc, "NameItem", self.wndChatNotifications:FindChild("NotificationList"):FindChild("ScrollList"), self)
		self.tNotifications[k]["objListItem"]:FindChild("Name"):SetText(k)
		if v.bNewMsg then
			self.tNotifications[k]["objListItem"]:FindChild("NewMessage"):Show(true)
		else
			self.tNotifications[k]["objListItem"]:FindChild("NewMessage"):Show(false)
		end
	end

	self.wndChatNotifications:FindChild("NotificationList"):FindChild("ScrollList"):ArrangeChildrenVert(0)
end

function WildStarInstantMessenger:UpdateNotificationAlert(self)
	--self.tNotifications = {}
	local bAlertMsg = false
	for k, v in pairs(self.tNotifications) do
		if v.bNewMsg then
			bAlertMsg = true
		end
	end

	if bAlertMsg and self.db.profile.conversationButton.bLightUp then
		self.wndChatNotifications:FindChild("Alert"):Show(true)
	else
		self.wndChatNotifications:FindChild("Alert"):Show(false)
	end
end

---------------------------------------------------------------------------------------------------
-- TestDialogue Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnInputReturn( wndHandler, wndControl, strText )
		local wndForm = wndControl:GetParent():GetParent()
		local tChatData = wndForm:GetData()
		local wndInput = wndForm:FindChild("EditBox1")
		local sendTo = tChatData.strSender


		strText = self:ReplaceLinks(strText, wndControl:GetAllLinks())

		local tInput = ChatSystemLib.SplitInput(strText)

		wndControl:SetText("")



		if strText ~= "" then
			local channelCurrent = tInput.channelCommand or tChatData.channelCurrent
			if sendTo and channelCurrent:GetType() == ChatSystemLib.ChatChannel_Whisper then
				tInput.strMessage = sendTo.." "..tInput.strMessage
			elseif sendTo and channelCurrent:GetType() == ChatSystemLib.ChatChannel_AccountWhisper then
				tInput.strMessage = sendTo.." "..tInput.strMessage
			end
			if channelCurrent and channelCurrent:GetType() == ChatSystemLib.ChatChannel_Command then
				ChatSystemLib.Command(strText)
			else
				self:SendText(channelCurrent, tInput)
			end
		end
end

function WildStarInstantMessenger:SaveLink(tLink)
	self.tLinks[self.nNextLinkIndex] = tLink
	self.nNextLinkIndex = self.nNextLinkIndex + 1
	return self.nNextLinkIndex - 1
end

function WildStarInstantMessenger:ReplaceLinks(strText, arEditLinks)
	local strReplacedText = ""

	local nCurrentIdx = 1
	local nLastIdx = strText:len()
	while nCurrentIdx <= nLastIdx do
		local nNextIdx = nCurrentIdx + 1

		local bFound = false

		for nEditIdx, tEditLink in pairs( arEditLinks ) do
			if tEditLink.iMin <= nCurrentIdx and nCurrentIdx < tEditLink.iLim then

				if tEditLink.data.uItem then
					strReplacedText = strReplacedText .. tEditLink.data.uItem:GetChatLinkString()
				elseif tEditLink.data.uQuest then
					strReplacedText = strReplacedText .. tEditLink.data.uQuest:GetChatLinkString()
				elseif tEditLink.data.uArchiveArticle then
					strReplacedText = strReplacedText .. tEditLink.data.uArchiveArticle:GetChatLinkString()
				end

				if nNextIdx < tEditLink.iLim then
					nNextIdx = tEditLink.iLim
				end

				bFound = true
				break
			end
		end

		if bFound == false then
			strReplacedText = strReplacedText .. strText:sub(nCurrentIdx, nCurrentIdx)
		end

		nCurrentIdx = nNextIdx
	end

	return strReplacedText
end

function WildStarInstantMessenger:SendText(channelCurrent, tInput)
	local strText = tInput.strMessage
	channelCurrent:Send(strText)
end

function WildStarInstantMessenger:UpdateScrollPos(wndForm)
	local wndChatList = wndForm:FindChild("EditBox")
	local bAtBottom = false
	local nPos = wndChatList:GetVScrollPos()

	if nPos == wndChatList:GetVScrollRange() then
		bAtBottom = true
	end

	wndChatList:ArrangeChildrenVert(2)

	if bAtBottom then
		wndChatList:SetVScrollPos(wndChatList:GetVScrollRange())
	end
end

function WildStarInstantMessenger:OnOptionsCloseClick( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
end

function WildStarInstantMessenger:OnCloseClick( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():GetParent():Show(false)
end

function WildStarInstantMessenger:OnInviteGroupClick( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetParent():FindChild("Title"):GetText()
	GroupLib.Invite(name)
end
--FriendshipLib.CharacterFriendshipType_Ignore
function WildStarInstantMessenger:OnAddFriendClick( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetParent():FindChild("Title"):GetText()
	FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Friend, name)
end

function WildStarInstantMessenger:OnIgnoreFriendClick( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetParent():FindChild("Title"):GetText()
	FriendshipLib.AddByName(FriendshipLib.CharacterFriendshipType_Ignore, name)
end

function WildStarInstantMessenger:OnChatWindowReturn( wndHandler, wndControl )
	if wndControl:IsShown() then
		wndControl:FindChild("EditBox1"):SetFocus()
	else
		wndControl:FindChild("EditBox1"):ClearFocus()
	end
end

function WildStarInstantMessenger:OnInputChanged( wndHandler, wndControl, strText )
	for idx, wndChat in pairs(self.wndWhispers) do
		wndChat:FindChild("EditBox1"):SetData(false)
	end
	wndControl:SetData(true)
end

---------------------------------------------------------------------------------------------------
-- ChatNotifications Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnChatNotificationsClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		self:ShowAllAlerts(self)
	elseif eMouseButton == 1 then
		self.wndOptions:Invoke()
	elseif self.wndChatNotifications and self.wndWhispers then
		local left, top, right, bottom
		WildStarInstantMessenger:UpdateNotificationList(self)
		if self.tPositionOptions[self.db.profile.conversationButton.strListPos] == "topleft" then
			left, top, right, bottom = -163, -108, -13, 17
		elseif self.tPositionOptions[self.db.profile.conversationButton.strListPos] == "topright" then
			left, top, right, bottom = 13, -108, 163, 17
		elseif self.tPositionOptions[self.db.profile.conversationButton.strListPos] == "bottomright" then
			left, top, right, bottom = 13, -17, 163, 108
		elseif self.tPositionOptions[self.db.profile.conversationButton.strListPos] == "bottomleft" then
			left, top, right, bottom = -163, -17, -13, 108
		end
		self.wndChatNotifications:FindChild("NotificationList"):SetAnchorOffsets(left, top, right, bottom)
		self.wndChatNotifications:FindChild("NotificationList"):Show(true)
	end
end

function WildStarInstantMessenger:OnNotificationButtonMoved( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.db.profile.conversationButton.tAnchorOffsets = {wndControl:GetAnchorOffsets()}
end

---------------------------------------------------------------------------------------------------
-- NameItem Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnNameItemClick( wndHandler, wndControl, eMouseButton )
	self.wndWhispers[wndControl:GetText()]:Show(true)
	WildStarInstantMessenger:UpdateScrollPos(self.wndWhispers[wndControl:GetText()])
	wndControl:GetParent():FindChild("NewMessage"):Show(false)
	self.tNotifications[wndControl:GetText()]["bNewMsg"] = false
	self.wndChatNotifications:FindChild("NotificationList"):Show(false)

	self:UpdateNotificationAlert(self)
end

function WildStarInstantMessenger:OnRemoveNameItemClick( wndHandler, wndControl, eMouseButton )
	local name = wndControl:GetParent():FindChild("Name"):GetText()
	self.tNotifications[name]["bNewMsg"] = false

	if self.wndWhispers[name]:IsAttached() then
		self.wndWhispers[name]:Detach()
	end
	self.wndWhispers[name]:Show(false)
	self.wndWhispers[name]:Destroy()
	--TabWindow:
	self.tNotifications[name] = nil
	--self.tChatData[name] = nil
	self.wndWhispers[name] = nil

	WildStarInstantMessenger:UpdateNotificationList(self)
	WildStarInstantMessenger:UpdateNotificationAlert(self)
end

---------------------------------------------------------------------------------------------------
-- OptionsControls Functions
---------------------------------------------------------------------------------------------------









---------------------------------------------------------------------------------------------------
-- DropdownItem Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- OptionsDialogue Functions
---------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- ChatLine Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnNodeClick( wndHandler, wndControl, strNode, tAttributes, eMouseButton )
	if strNode == "Source" and eMouseButton == 1 and tAttributes.CharacterName and tAttributes.nReportId then
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, tAttributes.CharacterName, nil, tAttributes.nReportId)
		return true
	end

	--Print("strNode = "..strNode)

	if strNode == "Link" then

		local nIndex = tonumber(tAttributes.strIndex)

		if self.tLinks[nIndex] and
			( self.tLinks[nIndex].uItem or self.tLinks[nIndex].uQuest or self.tLinks[nIndex].uArchiveArticle ) then

			if Apollo.IsShiftKeyDown() then

				local wndEdit = self:GetCurrentInput(self)

				if wndEdit then
					self:AppendLink( wndEdit, self.tLinks[nIndex] )
				end
			else
				if self.tLinks[nIndex].uItem then

					local bWindowExists = false
					for idx, wndCur in pairs(self.twndItemLinkTooltips or {}) do
						if wndCur:GetData() == self.tLinks[nIndex].uItem then
							bWindowExists = true
							break
						end
					end

					if not bWindowExists then
						local wndChatItemToolTip = Apollo.LoadForm(self.xmlDoc, "TooltipWindow", nil, self)
						wndChatItemToolTip:SetData(self.tLinks[nIndex].uItem)

						table.insert(self.twndItemLinkTooltips, wndChatItemToolTip)

						local itemEquipped = self.tLinks[nIndex].uItem:GetEquippedItemForItemType()

						local wndLink = Tooltip.GetItemTooltipForm(self, wndControl, self.tLinks[nIndex].uItem, {bPermanent = true, wndParent = wndChatItemToolTip, bSelling = false, bNotEquipped = true})

						local nLeftWnd, nTopWnd, nRightWnd, nBottomWnd = wndChatItemToolTip:GetAnchorOffsets()
						local nLeft, nTop, nRight, nBottom = wndLink:GetAnchorOffsets()

						wndChatItemToolTip:SetAnchorOffsets(nLeftWnd, nTopWnd, nLeftWnd + nRight + 15, nBottom + 75)

						if itemEquipped then
							wndChatItemToolTip:SetTooltipDoc(nil)
							Tooltip.GetItemTooltipForm(self, wndChatItemToolTip, itemEquipped, {bPrimary = true, bSelling = false, bNotEquipped = false})
						end
					end

				elseif self.tLinks[nIndex].uQuest then
					Event_FireGenericEvent("ShowQuestLog", self.tLinks[nIndex].uQuest)
					Event_FireGenericEvent("GenericEvent_ShowQuestLog", self.tLinks[nIndex].uQuest)
				elseif self.tLinks[nIndex].uArchiveArticle then
					Event_FireGenericEvent("HudAlert_ToggleLoreWindow")
					Event_FireGenericEvent("GenericEvent_ShowGalacticArchive", self.tLinks[nIndex].uArchiveArticle)
				end
			end
		end
	end

	if strNode == "URL" then
		--tAttributes.strUrl:CopyTextToClipboard()
		--EditBox:CopyTextToClipboard
		local wndCopyInput = Apollo.LoadForm(self.xmlDoc, "CopyWindow", nil, self)
		wndCopyInput:FindChild("EditBox"):SetText(tAttributes.strUrl)
		wndCopyInput:ToFront()
		wndCopyInput:FindChild("EditBox"):SetFocus()
		--Print("URL copied to clipboard")
	end
end

---------------------------------------------------------------------------------------------------
-- TooltipWindow Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnCloseItemTooltipWindow( wndHandler, wndControl, eMouseButton )
	local wndParent = wndControl:GetParent()
	local itemData = wndParent:GetData()

	for idx, wndCur in pairs(self.twndItemLinkTooltips) do
		if wndCur:GetData() == itemData then
			table.remove(self.twndItemLinkTooltips, idx)
		end
	end

	wndParent:Destroy()
end

---------------------------------------------------------------------------------------------------
-- ConfirmAlert1 Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnNo( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Show(false)
	wndControl:GetParent():Destroy()
	--wndControl:GetParent()= nil
end

---------------------------------------------------------------------------------------------------
-- ChannelColorsItem Functions
---------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- WildStarInstantMessenger Instance
-----------------------------------------------------------------------------------------------
local WildStarInstantMessengerInst = WildStarInstantMessenger:new()
WildStarInstantMessengerInst:Init()
