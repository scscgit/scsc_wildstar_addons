-----------------------------------------------------------------------------------------------
-- Client Lua Script for PratLitePanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GuildLib"
require "Apollo" 

-----------------------------------------------------------------------------------------------
-- PratLitePanel Module Definition
-----------------------------------------------------------------------------------------------
local PratLitePanel = {} 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local scalePanel = 1.1
local ChatLogAaddon = Apollo.GetAddon("ChatLog")
local strLocalization = Apollo.GetString(1)
local strPlayerGuild = ""
local tColorCustom = {
    [2] = "AttributeDexterity",
    [3] = "AlertOrangeYellow",
    [4] = "AlertOrangeYellow",
    [5] = "AlertOrangeYellow",
	}
local tColorCircle = {
    [2] = "ChatCircle2",
    [3] = "ChatCircle3",
    [4] = "ChatCircle4",
    [5] = "ChatCircle5",
	}
local strWindowPanel = "show"
local nNumberRuns = 0
local tSavedData = {}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PratLitePanel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end
 
function PratLitePanel:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"PratLite",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
-----------------------------------------------------------------------------------------------
-- PratLitePanel OnLoad
-----------------------------------------------------------------------------------------------
function PratLitePanel:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("PratLitePanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end
-----------------------------------------------------------------------------------------------
-- PratLitePanel OnDocLoaded
-----------------------------------------------------------------------------------------------
function PratLitePanel:OnDocLoaded()
    if Apollo.GetAddon("PratLite") == nil then
	    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, "PratLiteButton: Not main addon PratLite!", "")
		Sound.Play(266)
	    return
	end
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PratLitePanelForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
		if self.locSavedWindowLoc then
			self.wndMain:MoveToLocation(self.locSavedWindowLoc)
		end
		self.supertimer = ApolloTimer.Create(10, true, "OnStartupPLL", self)
		
		Apollo.RegisterSlashCommand("plp", "OnShowPanelOn", self)
	    Apollo.RegisterEventHandler("OnShowPanelOn", "OnShowPanelOn", self)
        Apollo.RegisterEventHandler("GenericEvent_OnChannelsNames", "OnChannelsNames", self)
        Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	    self:OnWindowManagementReady()
	end
end
-----------------------------------------------------------------------------------------------
-- PratLitePanel Functions
-----------------------------------------------------------------------------------------------
function PratLitePanel:OnWindowManagementReady()
    if Apollo.GetAddon("Gorynych Reborn") ~= nil or strPlayerGuild == "The Core" or strPlayerGuild == "Star Bears" then
        Event_FireGenericEvent("WindowManagementRegister", { wnd = self.wndMain, strName = "Кнопки каналов"})
        Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = "Кнопки каналов"})
	else
        Event_FireGenericEvent("WindowManagementRegister", { wnd = self.wndMain, strName = "Channel buttons"})
        Event_FireGenericEvent("WindowManagementAdd", { wnd = self.wndMain, strName = "Channel buttons"})
	end   
end

function PratLitePanel:OnStartupPLL()
    for key, tGuild in pairs(GuildLib.GetGuilds()) do
		if tGuild:GetType() == GuildLib.GuildType_Guild then
			strPlayerGuild = tGuild:GetName() or ""
		end
	end
	self.supertimer = nil
	self.wndMain:Show(true)
	self.wndMain:SetScale(scalePanel)
	self:OnChannelsNames()
	if nNumberRuns < 2 then 
	    local strTextTooltip ="Panel movement: Esc -> Interface -> Positioning -> Channel buttons"
		if Apollo.GetAddon("Gorynych Reborn") ~= nil or strPlayerGuild == "The Core" or strPlayerGuild == "Star Bears" then
		   strTextTooltip = "Перемещение панели: Esc -> Interface -> Положение окон -> Кнопки каналов"
		elseif strLocalization == "Annuler" then -- FR
		   strTextTooltip = "Panneau de mouvement: Esc -> Interface -> Placement -> Channel buttons"
		elseif strLocalization == "Abbrechen" then -- Ge
		   strTextTooltip = "Verschieben Tafel: Esc -> Benutzeroberfläshe -> Positionierung -> Channel buttons"
		end
	    self.wndMain:SetTooltip(strTextTooltip)
	end
	if strWindowPanel == "hide" then self:OnShowPanelOn() end
end

function PratLitePanel:OnShowPanelOn()
    if self.wndMain:IsVisible() then 
	    strWindowPanel = "hide"
        self.wndMain:Show(false)
    else
        self.wndMain:Show(true)
		strWindowPanel = "show"
		self:OnChannelsNames()
	    self.wndMain:SetStyle("Moveable",  true)
	    self.wndMain:SetStyle("RequireMetaKeyToMove",  true)
	    self.wndMain:SetScale(scalePanel)
    end
	Sound.Play(77)
end

function PratLitePanel:OnChannelsNames(tColorCustomChannel, tColorCircleChannel)
    if tColorCustomChannel ~= nil then
        tColorCustom = tColorCustomChannel 
	end
    if tColorCircleChannel ~= nil then
        tColorCircle = tColorCircleChannel 
	end
    local wndChannel = self.wndMain:FindChild("PratLitePanelForm")
    if self.wndMain:IsVisible() then
	    wndChannel:FindChild("ButtonSay"):SetTooltip(Apollo.GetString("ChatType_Say"))
	    wndChannel:FindChild("ButtonYell"):SetTooltip(Apollo.GetString("ChatType_Shout"))
	    wndChannel:FindChild("ButtonWhisper"):SetTooltip(Apollo.GetString("ChatType_Tell"))
	    wndChannel:FindChild("ButtonParty"):SetTooltip(Apollo.GetString("ChatType_Party"))
	    wndChannel:FindChild("ButtoInstance"):SetTooltip(Apollo.GetString("ChatType_Say"))
	    wndChannel:FindChild("ButtoGuild"):SetTooltip(Apollo.GetString("ChatType_Guild"))
	    wndChannel:FindChild("ButtonZone"):SetTooltip("Zone")
	    wndChannel:FindChild("ButtonTrade"):SetTooltip(Apollo.GetString("Trading_TradeBtn"))
	    wndChannel:FindChild("ButtonAdvice"):SetTooltip("Advice")
	    wndChannel:FindChild("ButtonEmote"):SetTooltip("Emote")
		---------
		local tColor = ChatLogAaddon.arChatColor
		wndChannel:FindChild("Say"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Say])
	    wndChannel:FindChild("Yell"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Yell])
	    wndChannel:FindChild("Whisper"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Whisper])
	    wndChannel:FindChild("Party"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Party])
	    wndChannel:FindChild("Instance"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Instance])
	    wndChannel:FindChild("Guild"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Guild])
	    wndChannel:FindChild("Zone"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Zone])
	    wndChannel:FindChild("PVP"):SetTextColor(tColor[ChatSystemLib.ChatChannel_ZonePvP])
	    wndChannel:FindChild("Trade"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Trade])
	    wndChannel:FindChild("Advice"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Advice])
	    wndChannel:FindChild("Emote"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Emote])
	    wndChannel:FindChild("1"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Custom])
	    wndChannel:FindChild("2"):SetTextColor(tColorCustom[2])
	    wndChannel:FindChild("3"):SetTextColor(tColorCustom[3])
	    wndChannel:FindChild("C1"):SetTextColor(tColor[ChatSystemLib.ChatChannel_Society])
	    wndChannel:FindChild("C2"):SetTextColor(tColorCircle[2])
	    wndChannel:FindChild("C3"):SetTextColor(tColorCircle[3])
		------------------
		--strPlayerGuild = ""
		if Apollo.GetAddon("Gorynych Reborn") == nil and strPlayerGuild ~= "The Core" and strPlayerGuild ~= "Star Bears" then
			wndChannel:FindChild("Say"):SetText("S")
		    wndChannel:FindChild("Yell"):SetText("Y")
		    wndChannel:FindChild("Whisper"):SetText("W")
		    wndChannel:FindChild("Party"):SetText("P")
		    wndChannel:FindChild("Instance"):SetText("I")
		    wndChannel:FindChild("Guild"):SetText("G")
		    wndChannel:FindChild("Zone"):SetText("Z")
		    wndChannel:FindChild("PVP"):SetText("PvP")
		    wndChannel:FindChild("Trade"):SetText("T")
		    wndChannel:FindChild("Advice"):SetText("A")
		    wndChannel:FindChild("Emote"):SetText("E")
		end
		if strLocalization == "Annuler" then -- FR
			wndChannel:FindChild("Say"):SetText("D")
		    wndChannel:FindChild("Yell"):SetText("Cr")
		    wndChannel:FindChild("Whisper"):SetText("M")
		    wndChannel:FindChild("Party"):SetText("Éq")
		    wndChannel:FindChild("Instance"):SetText("I")
		    wndChannel:FindChild("Guild"):SetText("G")
		    wndChannel:FindChild("PVP"):SetText("JcJ")
		    wndChannel:FindChild("Trade"):SetText("Éch")
		    wndChannel:FindChild("Advice"):SetText("C")
		    wndChannel:FindChild("Emote"):SetText("É")
	        wndChannel:FindChild("ButtonAdvice"):SetTooltip("Conseil")
	        wndChannel:FindChild("ButtonEmote"):SetTooltip("Émote")
	        wndChannel:FindChild("ButtonParty"):SetTooltip("Équipe")
		end
		if strLocalization == "Abbrechen" then -- Ge
		    wndChannel:FindChild("Yell"):SetText("R")
		    wndChannel:FindChild("Whisper"):SetText("Flü")
		    wndChannel:FindChild("Party"):SetText("Gr")
		    wndChannel:FindChild("Instance"):SetText("I")
		    wndChannel:FindChild("Guild"):SetText("G")
		    wndChannel:FindChild("Zone"):SetText("Geb")
		    wndChannel:FindChild("Trade"):SetText("H")
		    wndChannel:FindChild("Advice"):SetText("Hi")
		    wndChannel:FindChild("C1"):SetText("Z1")
		    wndChannel:FindChild("C2"):SetText("Z2")
		    wndChannel:FindChild("C3"):SetText("Z3")
	        wndChannel:FindChild("ButtonZone"):SetTooltip("Gebiet")
	        wndChannel:FindChild("ButtonAdvice"):SetTooltip("Hilfe")
		end
	end
end    
--------------------------------------------- Button Channels -------------
function PratLitePanel:OnSay()
    local strOut = "s"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnYell()
    local strOut = "y"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnWhisper()
	local wndParent = nil
	for idx, wndCurr in pairs(ChatLogAaddon.tChatWindows) do
		if wndCurr and wndCurr:IsValid() then
			wndParent = wndCurr
			break
		end
	end
	if not wndParent then
		return
	end
	if not ChatLogAaddon.tRecent or not ChatLogAaddon.tRecent[1] then
        local strOut = "w"
	    Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
		return
	end
	local strOut = "w "..ChatLogAaddon.tRecent[1].strCharacterName.." "
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnParty()
    local strOut = "p"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnInstance()
    local strOut = "i"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnGuild()
    local strOut = "g"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnZone()
    local strOut = "z"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnPVP()
    local strOut = "v"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnTrade()
    local strOut = "tr"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnAdvice()
    local strOut = "a"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnEmote()
    local strOut = "e"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:On1()
    local strOut = "1"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:On2()
    local strOut = "2"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:On3()
    local strOut = "3"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnC1()
    local strOut = "C1"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnC2()
    local strOut = "C2"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end

function PratLitePanel:OnC3()
    local strOut = "C3"
	Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
end
----------------------------- Save/Restore--------------------------------------------
function PratLitePanel:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	    tSavedData = {
		    PlayerGuild = strPlayerGuild,
			NumberRuns = nNumberRuns,
		    WindowPanel = strWindowPanel,
	    }
	return tSavedData
end
function PratLitePanel:OnRestore(eType,tSavedData)
	if not tSavedData then return end
	if tSavedData.WindowPanel then
	    strWindowPanel =  tSavedData.WindowPanel
	end
	if tSavedData.NumberRuns then
	    nNumberRuns =  tSavedData.NumberRuns
	end
	if tSavedData.PlayerGuild then
	    strPlayerGuild =  tSavedData.PlayerGuild
	end
	nNumberRuns = nNumberRuns + 1 or 0
end
--------------------------------------------------------------------------------------------
-- PratLitePanel Instance
-----------------------------------------------------------------------------------------------
local PratLitePanelInst = PratLitePanel:new()
PratLitePanelInst:Init()
