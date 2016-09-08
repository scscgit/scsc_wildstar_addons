-----------------------------------------------------------------------------------------------
-- Client Lua Script for PratLite_Whisper
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PratLite_Whisper Module Definition
-----------------------------------------------------------------------------------------------
local PratLite_Whisper = {}
 
local tWhisperName = {} 
local ChatAddon = Apollo.GetAddon("ChatLog")
local PL = Apollo.GetAddon("PratLite")
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PratLite_Whisper:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self 
	self.tChatBoxes = {}
	self.tTextBoxes = {}
	self.tChatLines = {}
	self.AlarmTimer = {}
	self.Alarm = {}
	return o
end

function PratLite_Whisper:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PratLite",
	}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
-----------------------------------------------------------------------------------------------
-- PratLite_Whisper OnLoad
-----------------------------------------------------------------------------------------------
function PratLite_Whisper:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PratLite_Whisper.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end
-----------------------------------------------------------------------------------------------
-- PratLite_Whisper OnDocLoaded
-----------------------------------------------------------------------------------------------
function PratLite_Whisper:OnDocLoaded()
    ChatAddon = Apollo.GetAddon("ChatLog")
    PL = Apollo.GetAddon("PratLite")
    if ChatAddon == nil then return end
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "Form", nil, self)
		if self.wndMain == nil then 
		    Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.wndMain:Show(false, true)
		Apollo.RegisterSlashCommand("plw", "OnPratLite_WhisperOn", self)
		Apollo.RegisterEventHandler("ChatMessage", 					"OnChatMessage", self)
	end
end
-----------------------------------------------------------------------------------------------
-- PratLite_Whisper Functions
-----------------------------------------------------------------------------------------------
function PratLite_Whisper:OnChatMessage(channelCurrent, tMessage)
	local eChannelType = channelCurrent:GetType()
	self.bToWhisper = PL.bToWhisper or false
	if eChannelType ~= 6 and eChannelType ~= 34 then return end
	local strAccName = ""
	local strRealmName = ""
	local strText = self:GetMessage(tMessage.arMessageSegments)
	if tMessage.bSelf == true then
		local strToFrom = Apollo.GetString("ChatLog_To")
		if eChannelType == 6 then
            if self.AlarmTimer[tMessage.strSender] ~= nil then self:OnStopTimer(strName) end	
			if self.tChatBoxes[tMessage.strSender] == nil then 
			    if self.bToWhisper == true then
			        self:GenerateMessage(tMessage.strSender, strRealmName, strText, 6, strToFrom)
				    self:ShowChatWhisper( tMessage.strSender, strAccName, strRealmName, 6)
				end
			else
			    self:GenerateMessage(tMessage.strSender, strRealmName, strText, 6, strToFrom)
            end
		elseif eChannelType == 34 then
			local strAccName = nil
			local tAccountFriends = FriendshipLib.GetAccountList()
			for idx, tAccountFriend in pairs(tAccountFriends) do
				if tAccountFriend.arCharacters ~= nil then
					for idx, tCharacter in pairs(tAccountFriend.arCharacters) do
						if tCharacter.strCharacterName == tMessage.strSender then
							strAccName = tAccountFriend.strCharacterName
							strRealmName = tCharacter.strRealm
						end
					end
				end
			end	
		    if self.AlarmTimer[strAccName] ~= nil then self:OnStopTimer(strName) end
			if self.tChatBoxes[strAccName] == nil then
			    if self.bToWhisper == true then
			        if strAccName ~= nil and (strRealmName ~= nil or strRealmName ~= "") then
				        self:GenerateMessage(strAccName, strRealmName, strText, 34, strToFrom)
			            self:ShowChatWhisper(strAccName, strAccName, strRealmName, eChannelType)
			        else 
				        self:GenerateMessage(tMessage.strSender, strRealmName, strText, 34, strToFrom)
			            self:ShowChatWhisper(tMessage.strSender, strAccName, strRealmName, eChannelType)
			        end
                end
            else
                if strAccName ~= nil and (strRealmName ~= nil or strRealmName ~= "") then
			        self:GenerateMessage(strAccName, strRealmName, strText, strTypeChat, strToFrom)
			    else
				    self:GenerateMessage(tMessage.strSender, strRealmName, strText, strTypeChat,strToFrom)
			    end
            end
		end
	else local strToFrom = Apollo.GetString("ChatLog_From")
    	if eChannelType == 6 then
			self:GenerateMessage(tMessage.strSender, strRealmName, strText, 6, strToFrom)
			if self.tChatBoxes[tMessage.strSender] == nil then
			    self:ShowChatWhisper(tMessage.strSender, strAccName, strRealmName, 6)
			end
		elseif eChannelType == 34 then
			local strRealmName = nil
			local tAccountFriends = FriendshipLib.GetAccountList()
			for idx, tAccountFriend in pairs(tAccountFriends) do
				if tAccountFriend.arCharacters ~= nil then
					for idx, tCharacter in pairs(tAccountFriend.arCharacters) do
						if tCharacter.strCharacterName == tMessage.strSender 
						and (tMessage.strRealmName:len() == 0 
						or tCharacter.strRealm == tMessage.strRealmName) then
							if not tMessage.bSelf or (tPreviousWhisperer and tPreviousWhisperer.strCharacterName == tMessage.strSender) then
								strAccName = tAccountFriend.strCharacterName
								strRealmName = tCharacter.strRealm
							end
						end
					end
				end
			end
			if strAccName ~= nil and strRealmName ~= nil then
				self:GenerateMessage(strAccName, strRealmName, strText, 34, strToFrom)
				if self.tChatBoxes[strAccName] == nil then
				    self:ShowChatWhisper(strAccName, strAccName, strRealmName, 34)
				end
			else 
				self:GenerateMessage(tMessage.strSender, "", strText, 34, strToFrom)
				if self.tChatBoxes[tMessage.strSender] == nil then
				   self:ShowChatWhisper(tMessage.strSender, strAccName, strRealmName, 34)
				end
			end
   		end
	end
end

function PratLite_Whisper:ShowChatWhisper( strName, strAccName, strRealm, eChannelType)
	local MainChat = self:GetInputWnd()
	if strName ~= nil then
		if self.tChatBoxes[strName] ~= nil then
			self.tChatBoxes[strName]:Detach()
			self.tChatBoxes[strName]:Show(true)
			local nOpacity = ChatAddon.nBGOpacity
			self.tChatBoxes[strName]:FindChild("BGArt"):SetBGColor(CColor.new(1.0, 1.0, 1.0, nOpacity))
			local bBGFade = ChatAddon.bEnableBGFade
			local bNCFade = ChatAddon.bEnableNCFade
			self.tChatBoxes[strName]:SetStyle("AutoFadeNC", bNCFade)
			if ChatAddon.bEnableNCFade then self.tChatBoxes[strName]:SetNCOpacity(1) end
			self.tChatBoxes[strName]:SetStyle("AutoFadeBG", bBGFade)
			if ChatAddon.bEnableBGFade then self.tChatBoxes[strName]:SetBGOpacity(1) end
			MainChat:AttachTab(self.tChatBoxes[strName], false)
		elseif self.tTextBoxes[strName] ~= nil then
			self.tChatBoxes[strName] = Apollo.LoadForm(self.xmlDoc, "ChatWindow", nil, self)
			self.tChatBoxes[strName]:Show(true)
			self:CopyText(strName, eChannelType)
			local nOpacity = ChatAddon.nBGOpacity
			self.tChatBoxes[strName]:FindChild("BGArt"):SetBGColor(CColor.new(1.0, 1.0, 1.0, nOpacity))
			local bBGFade = ChatAddon.bEnableBGFade
			local bNCFade = ChatAddon.bEnableNCFade
			self.tChatBoxes[strName]:SetStyle("AutoFadeNC", bNCFade)
			if ChatAddon.bEnableNCFade then self.tChatBoxes[strName]:SetNCOpacity(1) end
			self.tChatBoxes[strName]:SetStyle("AutoFadeBG", bBGFade)
			if ChatAddon.bEnableBGFade then self.tChatBoxes[strName]:SetBGOpacity(1) end
			self.tChatBoxes[strName]:SetText(strName)
			if strName:len() > 9 then self.tChatBoxes[strName]:SetFont("CRB_Pixel") end
			self.tChatBoxes[strName]:SetData(strRealm)
            self.tChatBoxes[strName]:Detach()
			MainChat:AttachTab(self.tChatBoxes[strName], false)
		end
		self.tChatBoxes[strName]:FindChild("Input"):SetTextColor(ChatAddon.arChatColor[eChannelType])
	end
end

function PratLite_Whisper:OnAlarmWhisper()
    for n,d in pairs(self.AlarmTimer) do
	    if d ~= nil then
		    if self.Alarm[n] == n then self.Alarm[n] = "" else self.Alarm[n] = n end
		    self.tChatBoxes[n]:SetText(self.Alarm[n])
		end
	end
end

function PratLite_Whisper:OnStopAlarm( wndHandler, wndControl)
    strName = wndControl:GetText()
	for n,d in pairs(self.tChatBoxes) do
	    if n == strName then self:OnStopTimer(strName) end
	end
end 

function PratLite_Whisper:OnStopTimer(strName)
    if self.AlarmTimer[strName] ~= nil then self.AlarmTimer[strName] = nil
	    self.Alarm[strName] = nil
        self.tChatBoxes[strName]:SetText(strName)
	end
end
	
function PratLite_Whisper:GenerateMessage(strName, strRealm, strMessage, eChannelType, strToFrom)
	if self.tTextBoxes[strName] == nil then
		self.tTextBoxes[strName] = Apollo.LoadForm(self.xmlDoc, "Chat", self.wndMain, self)
		self.tTextBoxes[strName]:Show(false)
		self.tTextBoxes[strName]:SetData(eChannelType)
	end
	local strTime = string.gsub(ChatAddon:HelperGetTimeStr(), " ", "") or ""
	if strTime ~= "" then strTime = "["..strTime.."]" end
	local nCount = 1
	self.tChatLines[nCount] = Apollo.LoadForm("PratLite_Whisper.xml", "ChatLine", self.tTextBoxes[strName], self)
	self.tChatLines[nCount]:Show(false)
	self.tChatLines[nCount]:SetText(strMessage)
	self.tChatLines[nCount]:SetData(strToFrom)
	self.tChatLines[nCount]:FindChild("HeldData"):SetText(strTime)
	self:Resize(self.tChatLines, self.tTextBoxes)
	if self.tChatBoxes[strName] ~= nil then 
		self.tChatBoxes[strName]:FindChild("Chat"):DestroyChildren()
		self:CopyText(strName, eChannelType)
	end
	if self.AlarmTimer[strName] == nil and strToFrom ~= Apollo.GetString("ChatLog_To") then
	    self.Alarm[strName] = strName
	    self.AlarmTimer[strName] = ApolloTimer.Create(1.5, true, "OnAlarmWhisper", self)
	end
	if self.AlarmTimer[strName] ~= nil and strToFrom == Apollo.GetString("ChatLog_To") then 
	    self:OnStopTimer(strName) 
	end
end

function PratLite_Whisper:CopyText(strName, eChannelType)
	eChannelType = self.tTextBoxes[strName]:GetData() or eChannelType
	local tLines = self.tTextBoxes[strName]:GetChildren()
	if eChannelType ~= 6 then eChannelType = 34 end
	local strText = ChatAddon.arChatColor[eChannelType] or "xkcdBarbiePink"
	if strText == nil or strText:len() ~= 8 then strText = "xkcdBarbiePink" end
	local crTime = PL.TimeColor or ApolloColor.new("xkcdAqua")
	if crTime == nil or not crTime then ApolloColor.new("xkcdAqua") end
	for idx, value in pairs(tLines) do
	    local strMessage = tLines[idx]:GetText() or ""
		local strToFrom = tLines[idx]:GetData() or ""
		local strTime = tLines[idx]:FindChild("HeldData"):GetText() or ""
		local nCount = 1
		self.tChatLines[nCount] = Apollo.LoadForm(self.xmlDoc, "ChatLine", self.tChatBoxes[strName]:FindChild("Chat"), self)
		local FontTime = PL.CurrentFont or "Default"
		local strMessage = "<l Font=\""..FontTime.."\" TextColor=\""..crTime.."\">".. strTime .." </l> ".."<l Font=\""..FontTime.."\" TextColor=\""..strText.."\">"..strToFrom.."</l>" .. "<l Font=\""..FontTime.."\" TextColor=\"White\">[".. strName .."]</l> " .. "<l Font=\""..FontTime.."\" TextColor=\""..strText.."\"> ".. strMessage .."</l>"
		self.tChatLines[nCount]:SetText(strMessage)
		self:Resize(self.tChatLines, self.tChatBoxes)
	end
end

function PratLite_Whisper:Resize(tLines, tBox)
	for idx, value in pairs(tLines) do
		tLines[idx]:SetHeightToContentHeight()
	end
	for idx, value in pairs(tBox) do
		tBox[idx]:FindChild("Chat"):ArrangeChildrenVert()
		tBox[idx]:FindChild("Chat"):SetVScrollPos(tBox[idx]:FindChild("Chat"):GetVScrollRange())
	end	
end

function PratLite_Whisper:OnChat( wndHandler, wndControl, strText )
    if wndControl:GetName() ~= "Input" then return end
	local nGaps = string.find(strText, "%S") or 1
	if nGaps > 1 then strText = string.gsub(strText, string.char(32), "", nGaps) end
	if  strText:len() < 1 or strText == "" then strText = wndControl:GetText() end
	if  strText:len() < 1 or strText == "" then return end 
	local wndInput = wndControl:GetParent()
	local strCharacterName = wndInput:GetText()
	local strRealm = wndInput:GetData()
    if strCharacterName == nil or strCharacterName:len() < 3 then return end 
	if strRealm  ~= "" then
	    self:OnAccountWhisper("aw", strCharacterName, strText)
	else
	    self:OnAccountWhisper("w", strCharacterName, strText)
	end
	local strName = wndHandler:GetParent()
	if self.AlarmTimer[strName] ~= nil then self:OnStopTimer(strName) end
	wndControl:SetText("")
	wndInput:SetData(strRealm)
	wndInput:SetText(strCharacterName)
end

function PratLite_Whisper:OnAccountWhisper(command, strCharacterName, strText)    
	local strSlashCommand = String_GetWeaselString(Apollo.GetString("ChatLog_SlashPrefix"), command.." "..strCharacterName)
	ChatSystemLib.Command(strSlashCommand.." "..string.char(28, 32)..strText)
end

function PratLite_Whisper:OnCloseChatWindow( wndHandler, wndControl, eMouseButton )
	local strName = wndControl:GetParent():GetText()
	if strName ~= nil then
		if self.tTextBoxes[strName] ~= nil then
			self.tTextBoxes[strName]:Destroy()
			self.tTextBoxes[strName] = nil
		end		
		if self.tChatBoxes[strName] ~= nil then
			self.tChatBoxes[strName]:Detach()
			self.tChatBoxes[strName]:Destroy()
			self.tChatBoxes[strName] = nil
		end
	end
	self:OnStopTimer(strName)
end

function PratLite_Whisper:GetMessage(tMessage)
	local strNewMessage = ""
	for idx, tChat in pairs(tMessage) do
		strNewMessage = strNewMessage .. tChat.strText
	end
	return strNewMessage 
end
-- on SlashCommand "/plw"
function PratLite_Whisper:OnPratLite_WhisperOn()
	    
end

function PratLite_Whisper:GetInputWnd()
	local chatWnds = ChatAddon.tChatWindows
	local wndEdit = nil
	for idx, wndCurrent in pairs(chatWnds) do
		if wndCurrent:FindChild("Input"):GetData() then
			wndEdit = wndCurrent:FindChild("Input")
			break
		end
	end	
	if wndEdit == nil then
		for idx, wndCurrent in pairs(chatWnds) do
			wndEdit = wndCurrent:FindChild("Input")
			break
		end
	end
	return wndEdit:GetParent()
end
-----------------------------------------------------------------------------------------------
-- PratLite_Whisper Instance
-----------------------------------------------------------------------------------------------
local PratLite_WhisperInst = PratLite_Whisper:new()
PratLite_WhisperInst:Init()
