-----------------------------------------------------------------------------------------------
-- Client Lua Script for PratLiteSocial
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GuildLib"
require "FriendshipLib"
require "Apollo"
require "GameLib"
require "Unit"
 
-----------------------------------------------------------------------------------------------
-- PratLiteSocial Module Definition
-----------------------------------------------------------------------------------------------
local PratLiteSocial = {}

local WhoAddon = Apollo.GetAddon("Who")
local ChatLogAddon = Apollo.GetAddon("ChatLog")
local SocialPanel = Apollo.GetAddon("SocialPanel")
local GuildRoster = Apollo.GetAddon("GuildContentRoster")
local PL = Apollo.GetAddon("PratLite")
local guildCurrPLS, tRosterPLS
local circleCurr = {}
local tCircle = {}
local strLocalization = Apollo.GetString(1)
local strSlashWho = "/who "

local ktFaction =
{
	[Unit.CodeEnumFaction.DominionPlayer] = Apollo.GetString("CRB_Dominion"),
	[Unit.CodeEnumFaction.ExilesPlayer] = Apollo.GetString("CRB_Exiles")
}
local ktClass =
{
	[GameLib.CodeEnumClass.Medic] 			= Apollo.GetString("ClassMedic"),
	[GameLib.CodeEnumClass.Esper] 			= Apollo.GetString("CRB_Esper"),
	[GameLib.CodeEnumClass.Warrior] 		= Apollo.GetString("ClassWarrior"),
	[GameLib.CodeEnumClass.Stalker] 		= Apollo.GetString("ClassStalker"),
	[GameLib.CodeEnumClass.Engineer] 		= Apollo.GetString("ClassEngineer"),
	[GameLib.CodeEnumClass.Spellslinger] 	= Apollo.GetString("ClassSpellslinger"),
}
local karStatusColors =
{
	[FriendshipLib.AccountPresenceState_Available]	= "green",
	[FriendshipLib.AccountPresenceState_Away]		= "yellow",
	[FriendshipLib.AccountPresenceState_Busy]		= "red",
	[FriendshipLib.AccountPresenceState_Invisible]	= "gray",
} 
local karStatusText =
{
	[FriendshipLib.AccountPresenceState_Available]	= Apollo.GetString("Circles_Online"),
	[FriendshipLib.AccountPresenceState_Away]		= Apollo.GetString("Friends_StatusAwayBtn"),
	[FriendshipLib.AccountPresenceState_Busy]		= Apollo.GetString("Friends_StatusBusyBtn"),
	[FriendshipLib.AccountPresenceState_Invisible]	= Apollo.GetString("Friends_StatusInvisibleBtn"),
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PratLiteSocial:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function PratLiteSocial:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	    "PratLite",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
-----------------------------------------------------------------------------------------------
-- PratLiteSocial OnLoad
-----------------------------------------------------------------------------------------------
function PratLiteSocial:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("PratLiteSocial.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end
-----------------------------------------------------------------------------------------------
-- PratLiteSocial OnDocLoaded
-----------------------------------------------------------------------------------------------
function PratLiteSocial:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndGuild = Apollo.LoadForm(self.xmlDoc, "GuildRosterForm", nil, self)
	    self.wndGuild:Show(false, true)
	    PL = Apollo.GetAddon("PratLite")
        WhoAddon = Apollo.GetAddon("Who")
		ChatLogAddon = Apollo.GetAddon("ChatLog")
        SocialPanel = Apollo.GetAddon("SocialPanel")
        GuildRoster = Apollo.GetAddon("GuildContentRoster")
		Apollo.RegisterSlashCommand("pls",                              "OnSlash", self)
		Apollo.RegisterEventHandler("GuildRoster",                      "OnGuildRoster", self)
		Apollo.RegisterEventHandler("GuildResult",                      "OnCircleUpdateOn", self)
	    Apollo.RegisterEventHandler("FriendshipUpdateOnline", 	    	"CalcFriendInvites", self)
	    Apollo.RegisterEventHandler("FriendshipAccountDataUpdate",      "CalcFriendInvites", self)
	    Apollo.RegisterEventHandler("FriendshipUpdate",                 "CalcFriendInvites", self)
        self.showbutton = ApolloTimer.Create(3, true, "OnPratLiteSocialOn", self)
		if strLocalization == "Annuler" then strSlashWho = "/qui" end -- Fr
		if strLocalization == "Abbrechen" then strSlashWho = "/wer" end -- De
	    self.bGuild = false
	    self.bFriend = false
	    self.bCircle = false
	end
end

function PratLiteSocial:OnPratLiteSocialOn()
    self.showbutton = nil
	local wndChat = ChatLogAddon.tChatWindows
	local wndMain = wndChat[1]:FindChild("Options")
	if not self.wndMain then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PratLiteSocialForm", wndMain, self)
	end
	self.wndMain:Show(true)
	self.wndMain:FindChild("ButtonFriend"):SetSprite("icon_Friends")
	self.wndMain:FindChild("ButtonGuild"):SetSprite("icon_Guild")
	self.wndMain:FindChild("ButtonCircle"):SetSprite("icon_Circles")
	self.wndMain:FindChild("GuildTooltip"):SetStyle("IgnoreMouse", false)
	self.wndMain:FindChild("FriendsTooltip"):SetStyle("IgnoreMouse", false)
	self.wndMain:FindChild("CircleTooltip"):SetStyle("IgnoreMouse", false)
	self.TimerCircleUpdate = ApolloTimer.Create(1, true, "OnCircleUpdate", self)
	for key, guildCurr in pairs(GuildLib.GetGuilds()) do guildCurr:RequestMembers() end
	self:CalcFriendInvites()
end

function PratLiteSocial:OnSlash()
    for n = 1, 64 do
		Print(n.." <<"..string.char(n)..">>")
	end
end

function PratLiteSocial:OnGuildRoster(guildCurr, tRoster)
    if guildCurr:GetType() == GuildLib.GuildType_Guild then
	    guildCurrPLS = guildCurr
	    tRosterPLS = tRoster
	    self.strNameGuild = guildCurr:GetName()
	    self.nTotalMemberGuild = guildCurr:GetMemberCount()
	    self.nOnlineMemberGuild = guildCurr:GetOnlineMemberCount()
	    self:OnNumberIcon("Guild", self.nOnlineMemberGuild)
	elseif guildCurr:GetType() == GuildLib.GuildType_Circle then
        circleCurr[guildCurr:GetName()] = guildCurr
        tCircle[guildCurr:GetName()] = tRoster
	    self:OnCircleUpdate()
    else return
    end
	self.GenericTooltip = ApolloTimer.Create(5, true, "OnGenericTooltip", self)
end

function PratLiteSocial:OnGenericTooltip()
    self.GenericTooltip = nil
    local nOnline = 0
	if self.wndMain then
		local strToolTip = PL.GuildOnline or "" 
		if strToolTip ~= "" or string.find(strToolTip, "%w+") ~= nil then 
		    self.wndMain:FindChild("GuildTooltip"):SetTooltip("Guld "..strToolTip)
			nOnline = 0
		end
		strToolTip = self.CirclesOnline or "" 
		nOnline = self.nOnlineMemberCircles or 0
		if nOnline < 35 and strToolTip ~= "" and string.find(strToolTip, "%w+") ~= nil then 
			self.wndMain:FindChild("CircleTooltip"):SetTooltip("Circles: \n"..strToolTip)
		end
	    strToolTip = PL.FriendsOnline or ""
		if strToolTip ~= "" and string.find(strToolTip, "%w+") ~= nil then 
			self.wndMain:FindChild("FriendsTooltip"):SetTooltip("  "..strToolTip) 
		end
	end
end

function PratLiteSocial:OnNumberIcon(strWindName, nNumber)
    if not self.wndMain or nNumber == nil or nNumber == 0 then return end
	local n = 0
	for word in string.gmatch(nNumber, "%S") do n = n + 1
		self.wndMain:FindChild(strWindName..n):SetSprite("")
	    self.wndMain:FindChild(strWindName..n):SetSprite("number_"..word)
		self.wndMain:FindChild(strWindName..n):SetBGColor("green")
	end
end

function PratLiteSocial:OnCircleUpdateOn(guildCurr, strName, nRank, eResult)
    guildCurr:RequestMembers()
end
    
function PratLiteSocial:OnCircleUpdate()
    self.TimerCircleUpdate = nil
	local nMembers = 0
	local nCircle = 0
	local tMember = {}
	self.CirclesOnline = ""
	self.nOnlineMemberCircles = 0
	for n, d in pairs(circleCurr) do nCircle = nCircle + 1
	    local nCurrMembers = 0
	    local curr = circleCurr[n]
        local tRoster = tCircle[n]
		local strName = ""
		for key, tCurr in pairs(tRoster) do
		    if tCurr.fLastOnline == 0 then nCurrMembers = nCurrMembers + 1
			    strName = strName.."   ["..tCurr.nLevel..": "..tCurr.strName.."] \n"
			    if tMember[tCurr.strName] ~= true then nMembers = nMembers + 1 end
	        end
			tMember[tCurr.strName] = true
		end
		self.nOnlineMemberCircles = self.nOnlineMemberCircles + curr:GetOnlineMemberCount()
		self.CirclesOnline = self.CirclesOnline.."<<"..n..">> "..nCurrMembers.."("..curr:GetMemberCount()..") \n"..strName
	end
    if nMembers > 0 then self:OnNumberIcon("Circle", nMembers) end
end

function PratLiteSocial:OnGuildListlOn()
    if guildCurrPLS == nil then return end
    if self.wndGuild:IsVisible() and self.bGuild == true then self.wndGuild:Show(false)
	    self.bGuild = false return
    else self.bGuild = true
	    self.bFriend = false
	    self.bCircle = false
		self.wndGuild:Invoke()
		local x, y, w, h = self:OnGetCursor(self.wndGuild)
		local w = 420
		self.wndGuild:SetAnchorOffsets(x+20, y-h-100, x+w+20, y-100)
		self.wndGuild:FindChild("ButtonClose"):SetAnchorOffsets(w-6, -12, w+12, 6)
	    local guildCurr = guildCurrPLS
		local tRoster = tRosterPLS
		self.wndGuild:FindChild("Title"):SetText("  "..guildCurr:GetName())
		local wndGrid = self.wndGuild:FindChild("RosterGrid")
		local tSelectedRow = nil
	    wndGrid:DeleteAll()
	    local tRosterSort = self:RosterSort(tRosterPLS)
		local tRanks = guildCurr:GetRanks()
		for key, tCurr in pairs(tRosterSort) do tCurr.nRowIndex = key
		    local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
		    if tCurr.nRank == 1 then strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
			elseif tCurr.nRank == 2 then strIcon = "CRB_Basekit:kitIcon_Holo_Actions"
		    end
	    	local strRank = Apollo.GetString("Circles_UnknownRank")
		   	if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
			   	strRank = tRanks[tCurr.nRank].strName
			   	strRank = FixXMLString(strRank)
		    end
			local strTextColor = "UI_TextHoloBodyHighlight"
		    if tCurr.fLastOnline ~= 0 then strTextColor = "UI_BtnTextGrayNormal" end
	   	    local crLevelColor, strNameColor = self:OnColor(tCurr)
			local strTimeLast = ""
			if tCurr.fLastOnline ~= 0 then crLevelColor = "UI_BtnTextGrayNormal"
			    strNameColor = "UI_BtnTextGrayNormal"
				strTimeLast = "\n"..self:HelperConvertToTime(tCurr.fLastOnline)
			end
			local strNote = string.len(tCurr.strNote) > 0 and tCurr.strNote or "N/A"
			local strPVPDraws = tCurr.nPVPDraws or "N/A"
			local strPvPWins = tCurr.nPvPWins or "N/A"
			local strPvPLosses = tCurr.nPvPLosses or "N/A"
			local strTooltip = strNote.."\n PVP Draws: "..strPVPDraws.."\n PVP Wins: "..strPvPWins.."\n PVP Losses: "..strPvPLosses.."\n"..tCurr.strClass..strTimeLast
			local strPathIcon = PL.tPathToIcon[tCurr.ePathType]
			local strLevel = tCurr.nLevel.." "
			if tCurr.nLevel < 10 then strLevel = "0"..strLevel end
		    local iCurrRow = wndGrid:AddRow("")
		    wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
		    wndGrid:SetCellImage(iCurrRow, 1, strIcon)
			wndGrid:SetCellDoc(iCurrRow, 2, "<P Font=\"CRB_InterfaceMedium\"><A TextColor=\""..crLevelColor.."\">"..strLevel.."<T TextColor=\""..strNameColor.."\">"..tCurr.strName.."</T></A></P>")
	    	wndGrid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_Pixel\" TextColor=\""..strTextColor.."\">".. strRank.."</T>")
			wndGrid:SetCellImage(iCurrRow, 6, strPathIcon)
	   		wndGrid:SetCellDoc(iCurrRow, 8, "<T Font=\"CRB_Pixel\" TextColor=\""..strTextColor.."\">".. FixXMLString(tCurr.strNote) .."</T>")
	    	wndGrid:SetCellLuaData(iCurrRow, 8, String_GetWeaselString(Apollo.GetString("GuildRoster_ActiveNoteTooltip"), tCurr.strName, strTooltip)) -- For tooltip
	    end
	end
end

function PratLiteSocial:OnCircleListlOn()
    local strCircleName = ""
    for n, d in pairs(circleCurr) do strCircleName = d:GetName() end
    if self.wndGuild:IsVisible() and self.bCircle == true or strCircleName == "" then self.wndGuild:Show(false)
	    self.bCircle = false
		return
    else self.bCircle = true
	    self.bFriend = false
	    self.bGuild = false
		self.wndGuild:Invoke()
	    self.wndGuild:FindChild("Title"):SetText("")
		local x, y, w, h = self:OnGetCursor(self.wndGuild)
		self.wndGuild:SetAnchorOffsets(x+20, y-h-100, x+440, y-100)
		self.wndGuild:FindChild("ButtonClose"):SetAnchorOffsets(414, -12, 432, 6)
		local wndGrid = self.wndGuild:FindChild("RosterGrid")
		local tSelectedRow = nil
	    wndGrid:DeleteAll()
		local idx = 0
		for n, d in pairs(circleCurr) do
		    idx = idx + 1
		    local guildCurr = circleCurr[n]
            local tRosterSort = self:RosterSort(tCircle[n])
		    local tRanks = guildCurr:GetRanks()
			local data = {nRowIndex = idx, bNameCircle = true}
			local iCurrRow = wndGrid:AddRow("")
			local crColor = "xkcdBloodOrange"
			strCircleName = "    "..guildCurr:GetName()
		    wndGrid:SetCellLuaData(iCurrRow, 1, data)
			wndGrid:SetCellDoc(iCurrRow, 2, "<P Font=\"CRB_Interface16_BBO\"><A TextColor=\""..crColor.."\">"..strCircleName.."</A></P>")
		    for key, tCurr in pairs(tRosterSort) do idx = idx + 1
		        tCurr.nRowIndex = idx
				local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
		        if tCurr.nRank == 1 then strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
			    elseif tCurr.nRank == 2 then strIcon = "CRB_Basekit:kitIcon_Holo_Actions" 
				end
	    	    local strRank = Apollo.GetString("Circles_UnknownRank")
		   	    if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
			   	   	strRank = tRanks[tCurr.nRank].strName
			   	   	strRank = FixXMLString(strRank)
		       	end
			    local strTextColor = "UI_TextHoloBodyHighlight"
		       	if tCurr.fLastOnline ~= 0 then strTextColor = "UI_BtnTextGrayNormal" end
	   	       	local crLevelColor, strNameColor = self:OnColor(tCurr)
			   	local strTimeLast = ""
			   	if tCurr.fLastOnline ~= 0 then crLevelColor = "UI_BtnTextGrayNormal"
			   	    strNameColor = "UI_BtnTextGrayNormal"
			   		strTimeLast = "\n"..self:HelperConvertToTime(tCurr.fLastOnline)
			   	end
			   	local strNote = string.len(tCurr.strNote) > 0 and tCurr.strNote or "N/A"
			   	local strPVPDraws = tCurr.nPVPDraws or "N/A"
			   	local strPvPWins = tCurr.nPvPWins or "N/A"
			   	local strPvPLosses = tCurr.nPvPLosses or "N/A"
			   	local strTooltip = strNote.."\n PVP Draws: "..strPVPDraws.."\n PVP Wins: "..strPvPWins.."\n PVP Losses: "..strPvPLosses.."\n"..tCurr.strClass..strTimeLast
			   	local strPathIcon = PL.tPathToIcon[tCurr.ePathType]
			   	local strLevel = tCurr.nLevel.." "
			   	if tCurr.nLevel < 10 then strLevel = "0"..strLevel end
		       	local iCurrRow = wndGrid:AddRow("")
		       	wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
		       	wndGrid:SetCellImage(iCurrRow, 1, strIcon)
			   	wndGrid:SetCellDoc(iCurrRow, 2, "<P Font=\"CRB_InterfaceMedium\"><A TextColor=\""..crLevelColor.."\">"..strLevel.."<T TextColor=\""..strNameColor.."\">"..tCurr.strName.."</T></A></P>")
	    	   	wndGrid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_Pixel\" TextColor=\""..strTextColor.."\">".. strRank.."</T>")
			   	wndGrid:SetCellImage(iCurrRow, 6, strPathIcon)
	   		   	wndGrid:SetCellDoc(iCurrRow, 8, "<T Font=\"CRB_Pixel\" TextColor=\""..strTextColor.."\">".. FixXMLString(tCurr.strNote) .."</T>")
	    	   	wndGrid:SetCellLuaData(iCurrRow, 8, String_GetWeaselString(Apollo.GetString("GuildRoster_ActiveNoteTooltip"), tCurr.strName, strTooltip)) -- For tooltip
			end	
		end
	end
end

function PratLiteSocial:OnShowFriendList()
    if not FriendshipLib.IsLoaded() then return end
	if self.wndGuild:IsVisible() and self.bFriend == true then self.wndGuild:Show(false)
	    self.bFriend = false return
    else self.bFriend = true
	    self.bCircle = false
	    self.bGuild = false
		self.wndGuild:Invoke()
	    self.wndGuild:FindChild("Title"):SetText("")
		local x, y, w, h = self:OnGetCursor(self.wndGuild)
		local w = 420
		self.wndGuild:SetAnchorOffsets(x+20, y-h-100, x+w+20, y-100)
		self.wndGuild:FindChild("ButtonClose"):SetAnchorOffsets(w-6, -12, w+12, 6)
        local wndGrid = self.wndGuild:FindChild("RosterGrid")
		wndGrid:DeleteAll()
		local tFriendList = FriendshipLib.GetList()
		table.sort(tFriendList, function(a,b) return (a.strCharacterName < b.strCharacterName) end)
	    for key, tFriend in pairs(tFriendList) do
		    if tFriend.bFriend == true and tFriend.fLastOnline  == 0 then
                local strIcon = "BK3:sprHolo_Friends_Single"						
			    self:DrawFriendList(tFriend, wndGrid, strIcon)
			end
	    end
		local tAccountFriendList = FriendshipLib.GetAccountList()
		table.sort(tAccountFriendList, function(a,b) return (a.strCharacterName < b.strCharacterName) end)
		for key, tSearchAccountFriend in pairs(tAccountFriendList) do
		    for idx, tFriend in pairs(tSearchAccountFriend.arCharacters or {}) do
			    if tFriend.strCharacterName then
			        tFriend["strAccountName"] = tSearchAccountFriend.strCharacterName
					tFriend["arCharacters"] = tSearchAccountFriend.arCharacters
			        tFriend["strNote"] = tFriend.strPrivateNote
					tFriend["nPresenceState"] = tSearchAccountFriend.nPresenceState
				    local strIcon = "BK3:sprHolo_Friends_Account"			
			        self:DrawFriendList(tFriend, wndGrid, strIcon)
				end
		    end
	    end 
	    for key, tFriend in pairs(tFriendList) do
			if tFriend.bFriend == true and tFriend.fLastOnline  ~= 0 then
                local strIcon = "BK3:sprHolo_Friends_Single"			
			    self:DrawFriendList(tFriend, wndGrid, strIcon)
			end   
	    end
		for key, tFriend in pairs(tAccountFriendList) do
		    if tFriend.fLastOnline ~= 0 then
			    local strPublicNote = ""
				tFriend["bOffline"] = true
			    if tFriend.strPublicNote ~= nil and tFriend.strPublicNote ~=  "" then 
			        strPublicNote = tFriend.strPublicNote.."\n"
				end
				local strPrivateNote = ""
			    if tFriend.strPrivateNote ~= nil and tFriend.strPrivateNote ~=  "" then
                    strPrivateNote = tFriend.strPrivateNote
                end
				local strLastOnline = "\n"..self:HelperConvertToTime(tFriend.fLastOnline)
				strTooltip = strPublicNote..strPrivateNote..strLastOnline
				local strNameColor = "UI_BtnTextGrayNormal"
			    local strIcon = "BK3:sprHolo_Friends_Account"			
			    local iCurrRow = wndGrid:AddRow("")
	            wndGrid:SetCellLuaData(iCurrRow, 1, tFriend)
	            wndGrid:SetCellImage(iCurrRow, 1, strIcon)
				wndGrid:SetCellDoc(iCurrRow, 2, "<P Font=\"CRB_InterfaceMedium\"><T TextColor=\""..strNameColor.."\">"..tFriend.strCharacterName.."</T></P>")
				wndGrid:SetCellLuaData(iCurrRow, 8, strTooltip)
			end
	    end
    end
end

function PratLiteSocial:OnRosterGridItemClick(wndControl, wndHandler, iRow, iCol, eMouseButton)
    local wndGrid = self.wndGuild:FindChild("RosterGrid")
	local tRowData = wndGrid:GetCellData(iRow, 1)
	if tRowData.bNameCircle then return end
	if eMouseButton == GameLib.CodeEnumInputMouse.Right and tRowData and tRowData.strName and tRowData.strName ~= GameLib.GetPlayerUnit():GetName() then
		local unitTarget = nil
		local tOptionalCharacterData = { guildCurr = guildCurrPLS, tPlayerGuildData = tRowData }
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayerDetailed", self.wndGuild, tRowData.strName, unitTarget, tOptionalCharacterData)
		return
	end
	if tRowData.nId and eMouseButton == GameLib.CodeEnumInputMouse.Right then
	    Event_FireGenericEvent("GenericEvent_NewContextMenuFriend", self.wndGuild, tRowData.nId)
	end
	if tRowData.strName then strName = tRowData.strName end
	if tRowData.strCharacterName then strName = tRowData.strCharacterName end
	if eMouseButton == GameLib.CodeEnumInputMouse.Left and tRowData then 
	    if not tRowData.strAccountName and (not tRowData.bOffline and tRowData.fLastOnline == 0) then
	        self:OnClick(strName, "")
	    elseif not tRowData.bOffline and tRowData.strAccountName then self:OnClick(strName, tRowData.strAccountName)
	    elseif Apollo.IsShiftKeyDown() and not Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() and (tRowData.bOffline or tRowData.fLastOnline ~= 0) then
	        Event_FireGenericEvent("GenericEvent_InputText", strName)
        end			
	end
	if wndGrid:GetData() == tRowData then tRowData = nil end
	self.strSelectedName = tRowData and strName or nil
	self.nSelectedIndex = tRowData and tRowData.nRowIndex or 0
	wndGrid:SetData(tRowData)
	if not tRowData then wndGrid:SetCurrentRow(self.nSelectedIndex) end
end

function PratLiteSocial:OnClick(strName, strAccountName)
    Sound.Play(185)
    if Apollo.IsControlKeyDown() and Apollo.IsAltKeyDown() and not Apollo.IsShiftKeyDown() then
	    if strLocalization == "Annuler" then ChatSystemLib.Command("/rejoindre "..strName)
	    elseif strLocalization == "Abbrechen" then ChatSystemLib.Command("/beitreten "..strName)
	    else  ChatSystemLib.Command("/join "..strName)
		end
	elseif Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() and not Apollo.IsShiftKeyDown() then 
	    GroupLib.Invite(strName)
	elseif Apollo.IsShiftKeyDown() and not Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() then
    	Event_FireGenericEvent("GenericEvent_InputText", strName)
	elseif not Apollo.IsShiftKeyDown() and not Apollo.IsAltKeyDown() and Apollo.IsControlKeyDown() then
	    local strOut = '\"'..strName..'\"'
	 	ChatSystemLib.Command(strSlashWho.." "..strOut)
	    WhoAddon.tWndRefs.wndMain:Invoke()
	elseif not Apollo.IsShiftKeyDown() and not Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() then
	    if strAccountName and strAccountName ~= "" then
		    Event_FireGenericEvent("GenericEvent_InputChannel", "aw "..strAccountName)
		else Event_FireGenericEvent("GenericEvent_ChatLogWhisper", strName)
		end
	end
end

function PratLiteSocial:CalcFriendInvites()
    local nUnseenFriendInviteCount = 0
	for idx, tInvite in pairs(FriendshipLib.GetInviteList()) do
		if tInvite.bIsNew then nUnseenFriendInviteCount = nUnseenFriendInviteCount + 1 end
	end
	for idx, tInvite in pairs(FriendshipLib.GetAccountInviteList()) do
		if tInvite.bIsNew then nUnseenFriendInviteCount = nUnseenFriendInviteCount + 1 end
	end
	local nOnlineFriendCount = 0
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
		if tFriend.fLastOnline == 0 then nOnlineFriendCount = nOnlineFriendCount + 1 end
	end
	for idx, tFriend in pairs(FriendshipLib.GetAccountList()) do
		if tFriend.arCharacters then nOnlineFriendCount = nOnlineFriendCount + 1 end
	end
	self.nFriendOnline = nOnlineFriendCount
	if self.nFriendOnline > 0 and self.wndMain then self:OnNumberIcon("Friend", self.nFriendOnline) end
	self.GenericTooltip = ApolloTimer.Create(2, true, "OnGenericTooltip", self)
end

function PratLiteSocial:OnGenerateGridTooltip(wndHandler, wndControl, eType, iRow, iColumn)
	wndHandler:SetTooltip(self.wndGuild:FindChild("RosterGrid"):GetCellData(iRow + 1, 8) or "")
end

function PratLiteSocial:OnGetCursor(wndCurr)
    local w = wndCurr:GetWidth() 
	local h = wndCurr:GetHeight()
    local tCursor = Apollo.GetMouse()
	return tCursor.x, tCursor.y, w, h
end

function PratLiteSocial:OnColor(tCurr)    
	if tCurr.strClass == "Warrior" or tCurr.strClass == Apollo.GetString("CRB_Warrior") then
        nClass = GameLib.CodeEnumClass.Warrior
    elseif tCurr.strClass == "Engineer" or tCurr.strClass == Apollo.GetString("CRB_Engineer") then
	    nClass = GameLib.CodeEnumClass.Engineer
    elseif tCurr.strClass == "Esper" or tCurr.strClass == Apollo.GetString("CRB_Esper") then
        nClass = GameLib.CodeEnumClass.Esper
    elseif tCurr.strClass == "Medic" or tCurr.strClass == Apollo.GetString("CRB_Medic") then
   	    nClass = GameLib.CodeEnumClass.Medic
    elseif tCurr.strClass == "Stalker" or tCurr.strClass == Apollo.GetString("CRB_Stalker") then
        nClass = GameLib.CodeEnumClass.Stalker
    elseif tCurr.strClass == "Spellslinger" or tCurr.strClass == Apollo.GetString("CRB_Spellslinger") then
        nClass = GameLib.CodeEnumClass.Spellslinger
    end
    local crLevelColor = "xkcdGoldenrod"
	if tCurr.nLevel < 40 then crLevelColor = "ff888888"
	elseif tCurr.nLevel < 50 then crLevelColor = "xkcdSilver"
	end
	local strNameColor = PL.tClassColors[nClass]
	return crLevelColor, strNameColor
end

function PratLiteSocial:HelperConvertToTime(nDays)
	if nDays == 0 or nDays == nil then return Apollo.GetString("Friends_Online") end
	local tTimeData = { ["name"]	= "", ["count"]	= nil, }
	local nYears = math.floor(nDays / 365)
	local nMonths = math.floor(nDays / 30)
	local nWeeks = math.floor(nDays / 7)
	local nDaysRounded = math.floor(nDays / 1)
	local fHours = nDays * 24
	local nHoursRounded = math.floor(fHours)
	local nMinutes = math.floor(fHours * 60)
	if nYears > 0 then tTimeData["name"] = Apollo.GetString("CRB_Year")
		tTimeData["count"] = nYears
	elseif nMonths > 0 then tTimeData["name"] = Apollo.GetString("CRB_Month")
		tTimeData["count"] = nMonths
	elseif nWeeks > 0 then tTimeData["name"] = Apollo.GetString("CRB_Week")
		tTimeData["count"] = nWeeks
	elseif nDaysRounded > 0 then tTimeData["name"] = Apollo.GetString("CRB_Day")
		tTimeData["count"] = nDaysRounded
	elseif nHoursRounded > 0 then tTimeData["name"] = Apollo.GetString("CRB_Hour")
		tTimeData["count"] = nHoursRounded
	elseif nMinutes > 0 then tTimeData["name"] = Apollo.GetString("CRB_Min")
		tTimeData["count"] = nMinutes
	else tTimeData["name"] = Apollo.GetString("CRB_Min")
		tTimeData["count"] = 1
	end
	return String_GetWeaselString(Apollo.GetString("CRB_TimeOffline"), tTimeData)
end

function PratLiteSocial:DrawFriendList(tFriend, wndGrid, strIcon)
    if tFriend.strCharacterName == "Unknown" then return end
    local strTextColor = "UI_TextHoloBodyHighlight"
	local strNameColor = PL.tClassColors[tFriend.nClassId]
	local strStateColor = strTextColor 
	local crLevelColor = "xkcdGoldenrod"
	local strFont = "CRB_InterfaceMedium"
	local strPrefix = ""
	if tFriend.nLevel < 40 then crLevelColor = "ff888888"
	elseif tFriend.nLevel < 50 then crLevelColor = "xkcdSilver"
	end
	local strNote = ""
    if tFriend.strNote ~= nil and tFriend.strNote ~= "" then		
		strNote = "Note: "..(string.len(tFriend.strNote) > 0 and tFriend.strNote or "N/A")
	end
	local strRealmName = " ("..ktFaction[tFriend.nFactionId]..")"
	if tFriend.strRealmName then strRealmName = "\n Realm: "..tFriend.strRealmName..strRealmName end
	local strWorldZone = ""
	if tFriend.strWorldZone ~= nil and tFriend.strWorldZone ~= "" then
        strWorldZone = "\n Zone: "..tFriend.strWorldZone
    end
	local strClass = ""
    if tFriend.fLastOnline ~= 0	and not tFriend.arCharacters then strNameColor = "UI_BtnTextGrayNormal"
	    strTextColor = "UI_BtnTextGrayNormal"
	    crLevelColor = "UI_BtnTextGrayNormal"
	    strClass = "\n"..self:HelperConvertToTime(tFriend.fLastOnline).."\n"..ktClass[tFriend.nClassId] 
	end
	local strStatus = ""
	if tFriend.nPresenceState then strStatus = "\n"..karStatusText[tFriend.nPresenceState] 
	    strStateColor = karStatusColors[tFriend.nPresenceState] or "UI_TextHoloBodyHighlight"
	end
	local strTooltip = strNote..strRealmName..strWorldZone..strClass..strStatus
	local strPathIcon = PL.tPathToIcon[tFriend.nPathId]
	local strLevel = tFriend.nLevel.." "
	if tFriend.nLevel < 10 then strLevel = "0"..strLevel end
	local iCurrRow = wndGrid:AddRow("")
	wndGrid:SetCellLuaData(iCurrRow, 1, tFriend)
	wndGrid:SetCellImage(iCurrRow, 1, strIcon)
	wndGrid:SetCellDoc(iCurrRow, 2, "<P Font=\""..strFont.."\"><A TextColor=\""..crLevelColor.."\">"..strLevel.."<T TextColor=\""..strNameColor.."\">"..tFriend.strCharacterName..strPrefix.."</T></A></P>")
	if tFriend.strAccountName then
	    wndGrid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_Pixel\" TextColor=\""..strStateColor.."\">".. tFriend.strAccountName.."</T>")
	end
	wndGrid:SetCellImage(iCurrRow, 6, strPathIcon)
	wndGrid:SetCellLuaData(iCurrRow, 8, strTooltip) -- For tooltip
end

function PratLiteSocial:RosterSort(tRoster)
    local bRosterSortAsc = true
	table.sort(tRoster, function(a,b) return (a.fLastOnline < b.fLastOnline) or (a.fLastOnline == b.fLastOnline and a.strName < b.strName) end)
	return tRoster
end

function PratLiteSocial:OnWndClose()
	self.bGuild = false
	self.bFriend = false
	self.bCircle = false
	self.wndGuild:FindChild("RosterGrid"):DeleteAll()
    self.wndGuild:Show(false)
end

-----------------------------------------------------------------------------------------------
-- PratLiteSocial Instance
-----------------------------------------------------------------------------------------------
local PratLiteSocialInst = PratLiteSocial:new()
PratLiteSocialInst:Init()
