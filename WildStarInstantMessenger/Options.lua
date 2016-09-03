local WildStarInstantMessenger = Apollo.GetAddon("WildStarInstantMessenger")

--self = WildStarInstantMessenger

--###############################################
--					DEFAULTS
--###############################################
ktADefaults = {
  char = {
	tChatLog = {},
	currentProfile = nil,
  },
  profile = {
	nMaxLines = 25,
	nMaxDates = 3,
	general = {
		bHideCombat = true,
		bShowOnFirst = true,
		bShowOnFirstWhisper = false,
		bShowEvery = false,
		bShowEveryWhisper = false,
		bFocusShow = false,
		bSuppressWhispers = true,
		bPlaySound = true,
		bPlaySoundHidden = true,
		bCloseOnEscape = true,	
	} ,
	conversationButton = {
		bLock = false,
		bLightUp = true,
		strListPos = "Bottom Right",
		tAnchorOffsets = {0, 0, 54, 54},
	},
	windowAppearance = {
		nWidth = 450,
		nHeight = 350,
		sIncTextColor = "ff66CCFF",
		sOutTextColor = "ff990066",
		sTimestamps = "Off",
		nOpacity = 1,
		bShowEmoticons = true,
		bUseMinimalStyle = false,
		bAutoGroupWhispers = false,
		tChannelColors = {
			tIncoming = {
				[ChatSystemLib.ChatChannel_Whisper] 		= ApolloColor.new("ChatWhisper"),
				[ChatSystemLib.ChatChannel_Party] 			= ApolloColor.new("ChatParty"),
				[ChatSystemLib.ChatChannel_Zone] 			= ApolloColor.new("ChatZone"),
				[ChatSystemLib.ChatChannel_ZonePvP] 		= ApolloColor.new("ChatPvP"),
				[ChatSystemLib.ChatChannel_Trade] 			= ApolloColor.new("ChatTrade"),
				[ChatSystemLib.ChatChannel_Guild] 			= ApolloColor.new("ChatGuild"),
				[ChatSystemLib.ChatChannel_GuildOfficer] 	= ApolloColor.new("ChatGuildOfficer"),
				--[ChatSystemLib.ChatChannel_Society] 		= "Society",
				--[ChatSystemLib.ChatChannel_Custom] 			= "Custom",
				--[ChatSystemLib.ChatChannel_Realm] 			= "Realm",
				[ChatSystemLib.ChatChannel_Instance] 		= ApolloColor.new("ChatParty"),
				[ChatSystemLib.ChatChannel_WarParty] 		= ApolloColor.new("ChatWarParty"),
				--[ChatSystemLib.ChatChannel_WarPartyOfficer] = "WarPartyOfficer",
				--removed scsc: [ChatSystemLib.ChatChannel_Advice] 			= ApolloColor.new("ChatAdvice"),
				[ChatSystemLib.ChatChannel_AccountWhisper]	= ApolloColor.new("ChatAccountWisper"),
				[40] 										= "ff474747",
			},
			tOutgoing = {
				[ChatSystemLib.ChatChannel_Whisper] 		= ApolloColor.new("ChatWhisper"),
				[ChatSystemLib.ChatChannel_Party] 			= ApolloColor.new("ChatParty"),
				[ChatSystemLib.ChatChannel_Zone] 			= ApolloColor.new("ChatZone"),
				[ChatSystemLib.ChatChannel_ZonePvP] 		= ApolloColor.new("ChatPvP"),
				[ChatSystemLib.ChatChannel_Trade] 			= ApolloColor.new("ChatTrade"),
				[ChatSystemLib.ChatChannel_Guild] 			= ApolloColor.new("ChatGuild"),
				[ChatSystemLib.ChatChannel_GuildOfficer] 	= ApolloColor.new("ChatGuildOfficer"),
				--[ChatSystemLib.ChatChannel_Society] 		= "Society",
				--[ChatSystemLib.ChatChannel_Custom] 			= "Custom",
				--[ChatSystemLib.ChatChannel_Realm] 			= "Realm",
				[ChatSystemLib.ChatChannel_Instance] 		= ApolloColor.new("ChatParty"),
				[ChatSystemLib.ChatChannel_WarParty] 		= ApolloColor.new("ChatWarParty"),
				--[ChatSystemLib.ChatChannel_WarPartyOfficer] = "WarPartyOfficer",
				--removed scsc [ChatSystemLib.ChatChannel_Advice] 			= ApolloColor.new("ChatAdvice"),
				[ChatSystemLib.ChatChannel_AccountWhisper]	= ApolloColor.new("ChatAccountWisper"),
				[40] 										= "ff474747",
			},
		},
	},
	messagePreview = {
		bEnableMsgPrev = true,
		strMsgPrevPos = "Right",
		nMsgPrevLength = "2.0",
	},
	chatChannels = {
		bShowWhisperChat = true,
		bShowZoneChat = false,
		bShowAdviceChat  = false,
		bShowGuildChat  = false,
		bShowPartyChat  = false,
		bShowWarPartyChat = false,
		bShowInstanceChat = false,
		bShowTradeChat = false,
		bShowGuildOfficerChat = false,
		bShowZonePvPChat = false,
	},
  }
}

local tTimestampsOptions = {
	["Off"] = "off",
	["Server"] = "sever",
	["Local"] = "local",
}

WildStarInstantMessenger.tMsgPreviewPos = {
	["Left"] = "left",
	["Right"] = "right",
}

WildStarInstantMessenger.tPositionOptions = {
	["Top Left"] = "topleft",
	["Top Right"] = "topright",
	["Bottom Right"] = "bottomright",
	["Bottom Left"] = "bottomleft"
}

--%%%%%%%%%%%
--   ROUND
--%%%%%%%%%%%
local function round(num, idp)
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end
--%%%%%%%%%%%
function WildStarInstantMessenger:SetOptionControls()
	local tOptions = self.db.profile
	
--General
	local generalControls = self.wndControls:FindChild("MainControls")
	--Hide Combat
	generalControls:FindChild("HideCombatToggle"):SetCheck(tOptions.general.bHideCombat)
	--show on first message
	generalControls:FindChild("PopWindowToggle"):SetCheck(tOptions.general.bShowOnFirst)
	generalControls:FindChild("PopWindowWhisperToggle"):SetCheck(tOptions.general.bShowOnFirstWhisper)
	--Show Every
	generalControls:FindChild("ShowEveryToggle"):SetCheck(tOptions.general.bShowEvery)
	generalControls:FindChild("ShowEveryWhisperToggle"):SetCheck(tOptions.general.bShowEveryWhisper)
	--generalControls:FindChild("FocusReturnToggle"):Enable(false)
	
	--Hide Combat
	generalControls:FindChild("FocusShowToggle"):SetCheck(tOptions.general.bFocusShow)
	
	--Suppress Whispers
	--generalControls:FindChild("SuppressWhispersToggle"):SetCheck(tOptions.general.bSuppressWhispers)
	
	--Play Sound
	generalControls:FindChild("PlaySoundToggle"):SetCheck(tOptions.general.bPlaySound)
	generalControls:FindChild("PlaySoundHiddenToggle"):SetCheck(tOptions.general.bPlaySoundHidden)
	--Close On Escape
	generalControls:FindChild("CloseOnEscapeToggle"):SetCheck(tOptions.general.bCloseOnEscape)
	
--Conv Button
	local convControls = self.wndControls:FindChild("NotificationControls")
	--Anchor Offsets
	self.wndMove:SetAnchorOffsets(unpack(tOptions.conversationButton.tAnchorOffsets))
	--Lock
	convControls:FindChild("LockToggle"):SetCheck(tOptions.conversationButton.bLock)
	self.wndMove:SetStyle("Picture", not tOptions.conversationButton.bLock)
	self.wndMove:SetStyle("Moveable", not tOptions.conversationButton.bLock)
	--Light Up
	convControls:FindChild("LightUpToggle"):SetCheck(tOptions.conversationButton.bLightUp)
	--list pos
	self.wndListPositionDropdown = self.wndControls:FindChild("NotificationControls"):FindChild("ListPosition"):FindChild("ListPositionDropdown")
	self.wndListPositionDropdownBox = self.wndControls:FindChild("NotificationControls"):FindChild("ListPosition"):FindChild("DropdownBox")
	
	self.wndListPositionDropdown:SetText(tOptions.conversationButton.strListPos)
--Message Preview
	local msgPrevControls = self.wndControls:FindChild("MsgPreviewControls")
	--Enable
	msgPrevControls:FindChild("PrevEnableToggle"):SetCheck(tOptions.messagePreview.bEnableMsgPrev)
	--Msg Prev Pos
	self.wndMsgPrevPosDropdown = msgPrevControls:FindChild("MsgPosition"):FindChild("MsgPositionDropdown")
	self.wndMsgPrevPosDropdownBox = msgPrevControls:FindChild("MsgPosition"):FindChild("DropdownBox")
	
	self.wndMsgPrevPosDropdown:SetText(tOptions.messagePreview.strMsgPrevPos)
	--msg prev length
	msgPrevControls:FindChild("PrevLengthBar"):FindChild("SliderBar"):SetValue(tOptions.messagePreview.nMsgPrevLength)
	msgPrevControls:FindChild("PrevLengthBar"):FindChild("EditBox"):SetText(tOptions.messagePreview.nMsgPrevLength)
--Window Appearance
	local appControls = self.wndControls:FindChild("AppearanceControls")
	--width
	appControls:FindChild("Width"):FindChild("WidthInput"):SetText(tOptions.windowAppearance.nWidth)
	--height
	appControls:FindChild("Height"):FindChild("HeightInput"):SetText(tOptions.windowAppearance.nHeight)
	--Channel Colors

	for k, wndCurr in pairs(self.wndChannelColors:FindChild("OptionsDialogueControls"):GetChildren()) do
		local nChannelType = wndCurr:GetData()["nChannelType"]
		WildStarInstantMessenger:SetSwatchColor(wndCurr, tOptions.windowAppearance.tChannelColors.tIncoming[nChannelType], tOptions.windowAppearance.tChannelColors.tOutgoing[nChannelType])
	end
	--timestamps
	self.wndTimestampsDropdown = appControls:FindChild("Timestamps"):FindChild("TimestampsDropdown")
	self.wndTimestampsDropdownBox = appControls:FindChild("Timestamps"):FindChild("DropdownBox")
		
	for name, value in pairs(tTimestampsOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndTimestampsDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		
		currButton:AddEventHandler("ButtonUp", "OnTimestampItemClick")
	end
		
	self.wndTimestampsDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndTimestampsDropdown:SetText(tOptions.windowAppearance.sTimestamps)
	--Opacity
	appControls:FindChild("OpacityBar"):FindChild("SliderBar"):SetValue(self.db.profile.windowAppearance.nOpacity*100)
	appControls:FindChild("OpacityBar"):FindChild("EditBox"):SetText(self.db.profile.windowAppearance.nOpacity*100)
	self:SetAllOpacities(self)
	--Show Emoticons
	appControls:FindChild("ShowEmoticonsToggle"):SetCheck(tOptions.windowAppearance.bShowEmoticons)
	--Minimal Style
	appControls:FindChild("UseMinimalStyleToggle"):SetCheck(tOptions.windowAppearance.bUseMinimalStyle)
--Chat Channels
	local channelControls = self.wndControls:FindChild("ChatChannelControls")
	
	--Show Zone Chat
	channelControls:FindChild("ShowZoneChatToggle"):SetCheck(tOptions.chatChannels.bShowZoneChat)
	--Show Advice Chat
	channelControls:FindChild("ShowAdviceChatToggle"):SetCheck(tOptions.chatChannels.bShowAdviceChat)
	--Show Guild Chat
	channelControls:FindChild("ShowGuildChatToggle"):SetCheck(tOptions.chatChannels.bShowGuildChat)
	--Show Party Chat
	channelControls:FindChild("ShowPartyChatToggle"):SetCheck(tOptions.chatChannels.bShowPartyChat)
	--Show Party Chat
	channelControls:FindChild("ShowWarPartyChatToggle"):SetCheck(tOptions.chatChannels.bShowWarPartyChat)
	--Show Party Chat
	channelControls:FindChild("ShowInstanceChatToggle"):SetCheck(tOptions.chatChannels.bShowInstanceChat)
	--Show Party Chat
	channelControls:FindChild("ShowTradeChatToggle"):SetCheck(tOptions.chatChannels.bShowTradeChat)
	--Show Party Chat
	channelControls:FindChild("ShowGuildOfficerChatToggle"):SetCheck(tOptions.chatChannels.bShowGuildOfficerChat)
	--Show Party Chat
	channelControls:FindChild("ShowZonePvPChatToggle"):SetCheck(tOptions.chatChannels.bShowZonePvPChat)	
--Profiles
	--current
	self.wndCurrentProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Current"):FindChild("CurrentDropdown")
	self.wndCurrentProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Current"):FindChild("DropdownBox")
	
	self.wndCurrentProfileDropdown:SetText(self.db:GetCurrentProfile())
	
	--delete
	self.wndDeleteProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Delete"):FindChild("DeleteDropdown")
	self.wndDeleteProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Delete"):FindChild("DropdownBox")
	--copy
	self.wndCopyProfileDropdown = self.wndControls:FindChild("ProfileControls"):FindChild("Copy"):FindChild("CopyDropdown")
	self.wndCopyProfileDropdownBox = self.wndControls:FindChild("ProfileControls"):FindChild("Copy"):FindChild("DropdownBox")
end

function WildStarInstantMessenger:OnDefaultClick( wndHandler, wndControl, eMouseButton )
	self.db:ResetProfile()
	self:SetOptionControls()
end

function WildStarInstantMessenger:ColorPickerCallback(strColor)
	for idx, wndCurr in pairs(self.wndChannelColors:FindChild("OptionsDialogueControls"):GetChildren()) do
		local nChannelType = wndCurr:GetData()["nChannelType"]
		if nChannelType == self.sColorPickerTargetType then
			if self.sColorPickerTargetInOut == "IncSwatch" then
				self.db.profile.windowAppearance.tChannelColors.tIncoming[nChannelType] = strColor
				WildStarInstantMessenger:SetSwatchColor(wndCurr, strColor, nil)
			else
				self.db.profile.windowAppearance.tChannelColors.tOutgoing[nChannelType] = strColor
				WildStarInstantMessenger:SetSwatchColor(wndCurr, nil, strColor)
			end
			break
		end
	end
end

function WildStarInstantMessenger:OnShowEveryClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowEvery = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnShowEveryWhisperClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowEveryWhisper = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnFocusShowClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bFocusShow = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnHideCombatClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bHideCombat = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnShowFirstClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowOnFirst = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnShowFirstWhisperClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bShowOnFirstWhisper = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnSuppressWhispersClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bSuppressWhispers = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnPlaySoundClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bPlaySound = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnPlaySoundHiddenClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bPlaySoundHidden = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnShowWhisperChatClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.chatChannels.bShowWhisperChat = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnShowZoneChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Zone
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
				break
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowZoneChat)
		self.db.profile.chatChannels.bShowZoneChat = true
	else
		self.db.profile.chatChannels.bShowZoneChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowAdviceChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Advice
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowAdviceChat)
		self.db.profile.chatChannels.bShowAdviceChat = true
	else
		self.db.profile.chatChannels.bShowAdviceChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowGuildChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Guild
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end

		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowGuildChat)
		self.db.profile.chatChannels.bShowGuildChat = true
	else
		self.db.profile.chatChannels.bShowGuildChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowPartyChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Party
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowPartyChat)
		self.db.profile.chatChannels.bShowPartyChat = true
	else
		self.db.profile.chatChannels.bShowPartyChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowTradeChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Trade
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowTradeChat)
		self.db.profile.chatChannels.bShowTradeChat = true
	else
		self.db.profile.chatChannels.bShowTradeChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowGuildOfficerChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_GuildOfficer
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowGuildOfficerChat)
		self.db.profile.chatChannels.bShowGuildOfficerChat = true
	else
		self.db.profile.chatChannels.bShowGuildOfficerChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowZonePvPChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_ZonePvP
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowZonePvPChat)
		self.db.profile.chatChannels.bShowZonePvPChat = true
	else
		self.db.profile.chatChannels.bShowZonePvPChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowInstanceChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_Instance
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			--Print(strChannelName)
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false,
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowInstanceChat)
		self.db.profile.chatChannels.bShowInstanceChat = true
	else
		self.db.profile.chatChannels.bShowInstanceChat = wndControl:IsChecked()
	end
end

function WildStarInstantMessenger:OnShowWarPartyChatClick( wndHandler, wndControl, eMouseButton )
	if Apollo.IsShiftKeyDown() then
		local nChannelType = ChatSystemLib.ChatChannel_WarParty
		local strChannelName
		local channelCurrent
		for id, channel in pairs(ChatSystemLib.GetChannels()) do
			local type = channel:GetType()
			if nChannelType == type then
				strChannelName = channel:GetName()
				channelCurrent = channel
			end
		end
		
		if strChannelName == nil then
			Print("<CandyBars> Can't open chat window. [type: "..nChannelType.."]")
			return
		end
		
		if self.wndWhispers[strChannelName] then
			self.wndWhispers[strChannelName]:Show(true)
		else
			self.tNotifications[strChannelName] = {
				["strName"] = strChannelName,
				["bNewMsg"] = false
			}
			self:PopOther(channelCurrent)
			self.wndWhispers[strChannelName]:Show(true)
		end
		wndControl:SetCheck(true) --self.db.profile.chatChannels.bShowWarPartyChat)
		self.db.profile.chatChannels.bShowWarPartyChat = true
	else
		self.db.profile.chatChannels.bShowWarPartyChat = wndControl:IsChecked()
	end
end


function WildStarInstantMessenger:OnLockButtonClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.conversationButton.bLock = wndControl:IsChecked()
	
	self.wndMove:SetStyle("Picture", not wndControl:IsChecked())
	self.wndMove:SetStyle("Moveable", not wndControl:IsChecked())
end

function WildStarInstantMessenger:OnLightUpClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.conversationButton.bLightUp = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnDefaultWidthChanged( wndHandler, wndControl, strText )
	if tonumber(strText) == nil then strText = 300 end
	if tonumber(strText) < 300 then strText = 300 end
	self.db.profile.windowAppearance.nWidth = strText
end

function WildStarInstantMessenger:OnDefaultHeightChanged( wndHandler, wndControl, strText )
	if tonumber(strText) == nil then strText = 250 end
	if tonumber(strText) < 250 then strText = 250 end
	self.db.profile.windowAppearance.nHeight = strText
end

function WildStarInstantMessenger:SetSwatchColor(wndCurr, strIncColor, strOutColor)
	if wndCurr == nil then
		return
	end
	if strIncColor then
		wndCurr:FindChild("IncSwatch"):SetBGColor(strIncColor)
	end
	if strOutColor then
		wndCurr:FindChild("OutSwatch"):SetBGColor(strOutColor)
	end
end

function WildStarInstantMessenger:OnSwatchButtonClick( wndHandler, wndControl, eMouseButton )
	local strInOut = wndControl:GetName()
	local strChannelType = wndControl:GetParent():GetData()["nChannelType"]
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
	self.sColorPickerTargetType = strChannelType
	self.sColorPickerTargetInOut = strInOut
end

function WildStarInstantMessenger:OnTimestampsDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndTimestampsDropdownBox:Show(true)
	self.wndControls:FindChild("NotificationControls"):Enable(false)
	self.wndControls:FindChild("AppearanceControls"):FindChild("ShowEmoticonsToggle"):Enable(false)
end

function WildStarInstantMessenger:OnTimestampItemClick( wndHandler, wndControl, eMouseButton )
	self.wndTimestampsDropdown:SetText(wndControl:GetText())
	
	self.db.profile.windowAppearance.sTimestamps = wndControl:GetText()
	
	self.wndTimestampsDropdownBox:Show(false)
end


function WildStarInstantMessenger:OnTimestampDropHide( wndHandler, wndControl )
	self.wndControls:FindChild("NotificationControls"):Enable(true)
	self.wndControls:FindChild("AppearanceControls"):FindChild("ShowEmoticonsToggle"):Enable(true)
end

function WildStarInstantMessenger:OnOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue)/100
	self.db.profile.windowAppearance.nOpacity = value
	
	wndControl:GetParent():FindChild("EditBox"):SetText(value*100)
	
	self:SetAllOpacities(self)
	
end

function WildStarInstantMessenger:SetAllOpacities(self)
	if self.wndWhispers then
		for k, v in pairs(self.wndWhispers) do
			v:SetOpacity(self.db.profile.windowAppearance.nOpacity)
		end
		return true
	else
		return false
	end
end

function WildStarInstantMessenger:OnListPositionDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndListPositionDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(WildStarInstantMessenger.tPositionOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndListPositionDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		
		currButton:AddEventHandler("ButtonUp", "OnListPositionItemClick")
	end
		
	self.wndListPositionDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	--self.wndCurrentProfileDropdown:Enable(false)
	
	self.wndListPositionDropdownBox:Show(true)
end

function WildStarInstantMessenger:OnListPositionItemClick( wndHandler, wndControl, eMouseButton )
	self.wndListPositionDropdown:SetText(wndControl:GetText())
	
	self.db.profile.conversationButton.strListPos = wndControl:GetText()
	
	self.wndListPositionDropdownBox:Show(false)
end

function WildStarInstantMessenger:OnListPositionDropdownBoxHide( wndHandler, wndControl )
	--self.wndCurrentProfileDropdown:Enable(true)
end

function WildStarInstantMessenger:OnShowEmoticonsClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.windowAppearance.bShowEmoticons = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnCloseOnEscapeClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.general.bCloseOnEscape = wndControl:IsChecked()
	for k, v in pairs(self.wndWhispers) do
		self.wndWhispers[k]:SetStyle("Escapable", wndControl:IsChecked())
	end
end

function WildStarInstantMessenger:OnUseMinimalStyleClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.windowAppearance.bUseMinimalStyle = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnAutoGroupWhispersClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.windowAppearance.bAutoGroupWhispers = wndControl:IsChecked()
	Print("Auto grouping will be added in the next version. Thank you!")
end

---------------------------------------------------
--				Msg Preview
---------------------------------------------------

function WildStarInstantMessenger:OnEnableMsgPrevClick( wndHandler, wndControl, eMouseButton )
	self.db.profile.messagePreview.bEnableMsgPrev = wndControl:IsChecked()
end

function WildStarInstantMessenger:OnMsgPrevPosDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndMsgPrevPosDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(WildStarInstantMessenger.tMsgPreviewPos) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndMsgPrevPosDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(name)
		
		currButton:AddEventHandler("ButtonUp", "OnMsgPrevPosItemClick")
	end
		
	self.wndMsgPrevPosDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	--self.wndCurrentProfileDropdown:Enable(false)
	
	self.wndMsgPrevPosDropdownBox:Show(true)
end

function WildStarInstantMessenger:OnMsgPrevPosItemClick( wndHandler, wndControl, eMouseButton )
	self.wndMsgPrevPosDropdown:SetText(wndControl:GetText())
	
	self.db.profile.messagePreview.strMsgPrevPos = wndControl:GetText()
	
	self.wndMsgPrevPosDropdownBox:Show(false)
end

function WildStarInstantMessenger:OnMsgPrevLengthChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nVal = round(fNewValue, 1)
	self.db.profile.messagePreview.nMsgPrevLength = nVal
	wndControl:GetParent():FindChild("EditBox"):SetText(tostring(nVal))
	
	self.timerMsgPrevHide:Set(nVal)
end

---------------------------------------------------
--				Profiles
---------------------------------------------------

function WildStarInstantMessenger:OnNewProfileReturn( wndHandler, wndControl, strText )
	if strText == "" then return end
	self.db:SetProfile(strText)
	wndControl:SetText("")
	WildStarInstantMessenger:SetOptionControls()
end

function WildStarInstantMessenger:OnDeleteProfileDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndDeleteProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		--currButton:RemoveEventHandler("ButtonUp")
		currButton:AddEventHandler("ButtonUp", "OnDeleteProfileItemClick")
		end
	end
		
	self.wndDeleteProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndDeleteProfileDropdownBox:Show(true)
end

function WildStarInstantMessenger:OnDeleteProfileItemClick( wndHandler, wndControl, eMouseButton )
	--self.wndCurrentProfileDropdown:SetText(wndControl:GetText())
	
	--self.db.profile.profiles.sCurrentP = wndControl:GetText()
	--self.db:SetProfile(wndControl:GetText())
	
	self.wndDeleteProfileDropdownBox:Show(false)
	self.wndConfirmAlert:FindChild("NoticeText"):SetText("Are you sure you want to delete "..wndControl:GetText().."?")
	self.wndConfirmAlert:FindChild("Profile"):SetText(wndControl:GetText())
	self.wndConfirmAlert:FindChild("YesButton"):AddEventHandler("ButtonUp", "OnConfirmYes")
	self.wndConfirmAlert:FindChild("NoButton"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:FindChild("NoButton2"):AddEventHandler("ButtonUp", "OnConfirmNo")
	self.wndConfirmAlert:Show(true)
	self.wndConfirmAlert:ToFront()
	--WildStarInstantMessenger:SetOptionControls()
end

function WildStarInstantMessenger:OnConfirmYes(wndHandler, wndControl, eMouseButton)
	local profile = wndControl:GetParent():FindChild("Profile"):GetText()
	self.db:DeleteProfile(profile, true)
	wndControl:GetParent():Show(false)
end

function WildStarInstantMessenger:OnConfirmNo(wndHandler, wndControl, eMouseButton)
	wndControl:GetParent():Show(false)
end

function WildStarInstantMessenger:OnCurrentProfileDropdownClick( wndHandler, wndControl, eMouseButton )
	
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCurrentProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		--currButton:RemoveEventHandler("ButtonUp")
		currButton:AddEventHandler("ButtonUp", "OnCurrentProfileItemClick")
		end
	end
		
	self.wndCurrentProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	self.wndCopyProfileDropdown:Enable(false)
	self.wndCurrentProfileDropdownBox:Show(true)
	--self.wndCurrentProfileDropdown:SetText(tOptions.windowAppearance.sTimestamps)
end

function WildStarInstantMessenger:OnCurrentProfileItemClick( wndHandler, wndControl, eMouseButton )
	--Print("click")
	self.wndCurrentProfileDropdown:SetText(wndControl:GetText())
	
	--self.db.profile.profiles.sCurrentP = wndControl:GetText()
	self.db:SetProfile(wndControl:GetText())
	
	self.wndCurrentProfileDropdownBox:Show(false)
	
	self.db.char.currentProfile = wndControl:GetText()
	
	WildStarInstantMessenger:SetOptionControls()
end

function WildStarInstantMessenger:OnCurrentDropHide( wndHandler, wndControl )
	self.wndCopyProfileDropdown:Enable(true)
end

function WildStarInstantMessenger:OnCopyFromDropdownClick( wndHandler, wndControl, eMouseButton )
	self.wndCopyProfileDropdownBox:FindChild("ScrollList"):DestroyChildren()	
	
	for name, value in pairs(self.db:GetProfiles()) do
		if value ~= self.db:GetCurrentProfile() then
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", self.wndCopyProfileDropdownBox:FindChild("ScrollList"), self)
			
		currButton:SetText(value)
		
		--currButton:RemoveEventHandler("ButtonUp")
		currButton:AddEventHandler("ButtonUp", "OnCopyProfileItemClick")
		end
	end
		
	self.wndCopyProfileDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
	self.wndCopyProfileDropdownBox:Show(true)
end

function WildStarInstantMessenger:OnCopyProfileItemClick( wndHandler, wndControl, eMouseButton )
	self.wndCopyProfileDropdown:SetText(wndControl:GetText())
	
	self.db:CopyProfile(wndControl:GetText(), false)
	
	self.wndCopyProfileDropdownBox:Show(false)
	
	WildStarInstantMessenger:SetOptionControls()
end

---------------------------------------------------------------------------------------------------
-- ChannelColorsItem Functions
---------------------------------------------------------------------------------------------------

function WildStarInstantMessenger:OnChannelColorsClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
	self.wndChannelColors:Show(true)
	self.wndChannelColors:SetAnchorOffsets(self.wndOptions:GetAnchorOffsets())
end

function WildStarInstantMessenger:OnChannelColorsCloseClick( wndHandler, wndControl, eMouseButton )
	self.wndChannelColors:Show(false)
	self.wndOptions:Show(true)
	self.wndOptions:SetAnchorOffsets(self.wndChannelColors:GetAnchorOffsets())
end

function WildStarInstantMessenger:OnChannelColorSwatchClick( wndHandler, wndControl, eMouseButton )
end