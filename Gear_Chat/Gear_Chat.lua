-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Chat
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "ChatSystemLib"

-----------------------------------------------------------------------------------------------
-- Gear_Chat Module Definition
-----------------------------------------------------------------------------------------------
local Gear_Chat = {} 

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Chat", true)
 
-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 3 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Chat"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = nil,                         -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"], -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {}, 
									},   
										 
					}

-- timer/var to init plugin	
local tComm, bCall

-- lats array for tgear.gear updated and itemslot				 
local tLastGear, tItemSlot = nil, nil	
local G_VER  
				
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_Chat:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function Gear_Chat:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_Chat:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Gear_Chat.xml")
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)      -- add event to communicate with gear
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 							-- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_Chat:_Comm() 
		
	if lGear._isaddonup("Gear")	then							                	-- if 'gear' is running , go next
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_Chat:ON_GEAR_PLUGIN(sAction, tData)
	
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		
		if bCall then return end
		bCall = true
		
		-- keep gear version
		G_VER = tData
	end
	
	
	-- answer come from gear, mouse click in gear profile item or name profile
	if sAction == "G_ITEM_CLICK" then
	
	    if not tPlugin.on then return end    
	
		-- get last gear array and itemslot
	    tLastGear = tData.tgear
		tItemSlot = tData.titemslot
		-- filter
		if tData.mouse == GameLib.CodeEnumInputMouse.Right and tData.ocontrol:GetName() ~= "Delete_btn" then
			-- keep control object to get data
			self.cControlLink = tData.ocontrol
			self:ShowMenu_CHAT()
		end
	end
		
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on 														
	end
end

-----------------------------------------------------------------------------------------------
-- GetAbb_CHAT
-----------------------------------------------------------------------------------------------
function Gear_Chat:GetAbb_CHAT()

    local tChannelTypeToColor = 
{
	[ChatSystemLib.ChatChannel_Say] 			= "ChannelSay", 
	[ChatSystemLib.ChatChannel_Yell] 			= "ChannelShout",
	[ChatSystemLib.ChatChannel_Whisper] 		= "ChannelWhisper", 
	[ChatSystemLib.ChatChannel_Party] 			= "ChannelParty", 
	[ChatSystemLib.ChatChannel_Emote] 			= "ChannelEmote",
	[ChatSystemLib.ChatChannel_Zone] 			= "ChannelZone", 
	[ChatSystemLib.ChatChannel_ZoneGerman]		= "ChannelZone", 
	[ChatSystemLib.ChatChannel_ZoneFrench]		= "ChannelZone", 
	[ChatSystemLib.ChatChannel_ZonePvP] 		= "ChannelPvP",
	[ChatSystemLib.ChatChannel_Trade] 			= "ChannelTrade",
	[ChatSystemLib.ChatChannel_Guild] 			= "ChannelGuild", 
	[ChatSystemLib.ChatChannel_GuildOfficer] 	= "ChannelGuildOfficer",
	[ChatSystemLib.ChatChannel_Society] 		= "ChannelCircle2",
	[ChatSystemLib.ChatChannel_Custom] 			= "ChannelCustom",
	[ChatSystemLib.ChatChannel_Realm] 			= "ChannelSupport", 
	[ChatSystemLib.ChatChannel_Instance] 		= "ChannelInstance", 
	[ChatSystemLib.ChatChannel_WarParty] 		= "ChannelWarParty",
	[ChatSystemLib.ChatChannel_WarPartyOfficer] = "ChannelWarPartyOfficer",
	[ChatSystemLib.ChatChannel_Nexus] 			= "ChannelNexus",
	[ChatSystemLib.ChatChannel_NexusGerman]		= "ChannelNexus",
	[ChatSystemLib.ChatChannel_NexusFrench]		= "ChannelNexus",
	[ChatSystemLib.ChatChannel_AccountWhisper] 	= "ChannelAccountWisper",
}
	
	local tChannels = ChatSystemLib.GetChannels()
	local tAbbreviation = {}
		
	for idx, channelCurrent in pairs(tChannels) do
	      
	    local sCommand = channelCurrent:GetCommand()
		if sCommand and sCommand ~= "" then
		    local sAbb = channelCurrent:GetAbbreviation()
		  	local sName = channelCurrent:GetName()
			local nType = channelCurrent:GetType()
			local sColor = tChannelTypeToColor[nType] or ApolloColor.new("white")
			
			if sAbb == "" then sAbb = sCommand end
			
			tAbbreviation[sName] = { type = nType, abbreviation = sAbb, color = sColor, }
		end
	end
	
	return tAbbreviation
end

-----------------------------------------------------------------------------------------------
-- ShowMenu_CHAT 
-----------------------------------------------------------------------------------------------
function Gear_Chat:ShowMenu_CHAT()

    if self.wndMenuLink then self.wndMenuLink:Destroy() end

    -- dont create menu if is a empty item slot
	if self.cControlLink:GetName() == "ItemWnd" then
    	local nSlot = self.cControlLink:GetData().slot
		local sIcon = "NewSprite:" .. self.cControlLink:GetPixieInfo(1).strSprite
    	if sIcon == tItemSlot[nSlot].sIcon then 
			return
		end
	end

	local nXYmouse = Apollo.GetMouse()
    local nLeft = nXYmouse.x
 	local nTop = nXYmouse.y
   
	self.wndMenuLink = Apollo.LoadForm(self.xmlDoc, "LinkMenu_wnd", "TooltipStratum", self)
			
	-- chat	
	local tMenuItem = self:GetAbb_CHAT()
	for idx, channelCurrent in pairs(tMenuItem) do
			
		self.wndBtnLink = Apollo.LoadForm(self.xmlDoc, "LinkMenu_btn", self.wndMenuLink:FindChild("ButtonList"), self)
		self.wndBtnLink:SetData({abb = channelCurrent.abbreviation, type = channelCurrent.type,})
		
		self.wndBtnLink:FindChild("Chan"):SetText(idx) 
		self.wndBtnLink:FindChild("Chan"):SetTextColor(channelCurrent.color)
		self.wndBtnLink:FindChild("Abb"):SetText("/" .. channelCurrent.abbreviation) 
		self.wndBtnLink:FindChild("Abb"):SetTextColor(channelCurrent.color)
	end
			
	self.wndMenuLink:FindChild("ButtonList"):ArrangeChildrenVert()
	local nBtnMenuSize = self.wndBtnLink:GetHeight()
	-- 8 button maximum, after you see scroll
	local nHeightSize = nBtnMenuSize * 8
	local nWidthSize = self.wndMenuLink:GetWidth()	
		
	self.wndMenuLink:Move(nLeft, nTop, nWidthSize, nHeightSize + 60)
	self.wndMenuLink:Show(true, true)
end

---------------------------------------------------------------------------------------------------
-- OnClickLinkMenuBtn
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnClickLinkMenuBtn( wndHandler, wndControl, eMouseButton )
	
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
	
	    local oChannel = wndControl:GetData()
		local tToChat = {}
		local sGearName = nil
		
		if self.cControlLink:GetName() == "GearName_Btn" then
			
			local nGearId = self.cControlLink:GetParent():GetData()
			sGearName = tLastGear[nGearId].name
			local sOwner = "\'Gear v".. G_VER.major .. "." .. G_VER.minor .. "." ..  G_VER.patch .. "\'  ["  .. sGearName .. "]"
			tToChat[1] = sOwner
						
			local nInc = 1
			for _, oItemLink in pairs(tLastGear[nGearId]) do
				if tonumber(_) then
					nInc = nInc + 1 
					tToChat[nInc] = oItemLink 
				end
			end
							
		elseif self.cControlLink:GetName() == "ItemWnd" then
			
		    local oItem = self.cControlLink:GetData().item
			if oItem == nil or type(oItem) ~= "userdata" then self:DestroyMenuLink() return end
			tToChat[1] = oItem:GetChatLinkString()
			sGearName = oItem:GetName()
		end
		
		-- Whisper
		if oChannel.type == ChatSystemLib.ChatChannel_AccountWhisper or oChannel.type == ChatSystemLib.ChatChannel_Whisper then
			local tData = {type = oChannel.type, abb = oChannel.abb, chat = tToChat, profile_item = sGearName}
			self:ShowWhisper_CHAT(tData)
			self:DestroyMenuLink()
			return
		end
				
		self:Link_ItemToChat(oChannel.abb, tToChat)
		self:DestroyMenuLink()
	end
end

-----------------------------------------------------------------------------------------------
-- ShowWhisper_CHAT
-----------------------------------------------------------------------------------------------
function Gear_Chat:ShowWhisper_CHAT(tData)
	
    if self.WhisperWnd then self.WhisperWnd:Destroy() end  

    self.WhisperWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)
	local wndInside = Apollo.LoadForm(self.xmlDoc, "Whisper_wnd", self.WhisperWnd, self)
	
	self.WhisperWnd:FindChild("TitleUp"):SetText(L["GP_O_SETTINGS"])
	self.WhisperWnd:FindChild("CloseButton"):SetData("Whisper")
	
	local sPlayer = L["G_WHISPER_PLAYER"]
	if tData.type == ChatSystemLib.ChatChannel_AccountWhisper then
		sPlayer = L["G_WHISPER_ACCOUNT"]	
	end
	
	local sWhisperInfo = L["G_WHISPER_INFO"] .. sPlayer .. L["G_WHISPER_RETURN"]
	
	wndInside:FindChild("TitleUp"):SetText(tData.profile_item)	
	wndInside:FindChild("WhisperInfo_Wnd"):SetText(sWhisperInfo)
	wndInside:FindChild("Whisper_EditBox"):SetData(tData)
	wndInside:FindChild("Whisper_EditBox"):SetPrompt(sPlayer)
	wndInside:FindChild("Whisper_EditBox"):SetPromptColor("xkcdBluegreen")
	wndInside:FindChild("Whisper_EditBox"):SetMaxTextLength(30)
	wndInside:FindChild("Whisper_EditBox"):SetFocus()	
	
	if self.sWhisperName then 
		wndInside:FindChild("Whisper_EditBox"):SetText(self.sWhisperName)
	end			
			
	local l,t,r,b = self.WhisperWnd:GetAnchorOffsets()
	self.WhisperWnd:SetAnchorOffsets(l - 30, t, 230, 40)
	
	self.WhisperWnd:Show(true)
end

---------------------------------------------------------------------------------------------------
-- OnWhisperReturn
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnWhisperReturn( wndHandler, wndControl, strText )
	
	self.sWhisperName = strText
	if strText == "" then return end
		
	local sAbbWhisper = wndControl:GetData().abb .. " " .. strText 
	self:Link_ItemToChat(sAbbWhisper, wndControl:GetData().chat)
	self.WhisperWnd:Destroy()
end

---------------------------------------------------------------------------------------------------
-- OnLinkMenuClose
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnLinkMenuClose( wndHandler, wndControl )
	self:DestroyMenuLink()
end

-----------------------------------------------------------------------------------------------
-- DestroyMenuLink
-----------------------------------------------------------------------------------------------
function Gear_Chat:DestroyMenuLink()
	
	self.wndMenuLink:Destroy()
	self.cControlLink = nil
end

-----------------------------------------------------------------------------------------------
-- Link_ItemToChat 
-----------------------------------------------------------------------------------------------
function Gear_Chat:Link_ItemToChat(oChannel, tToChat)
   	
	for _= 1, #tToChat do
	   	Apollo.ParseInput("/" .. oChannel .. " " .. tToChat[_])	
	end
end

---------------------------------------------------------------------------------------------------
-- OnClick_Dialog
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnClick_Dialog( wndHandler, wndControl, eMouseButton )
	
	local cSelect = wndControl:GetName()
	-- whisper
	if cSelect == "CloseButton" and wndControl:GetData() == "Whisper" then self.WhisperWnd:Destroy() return end
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
		
	local tData = {}
	      tData.config = {
							 ver = GP_VER,
							  on = tPlugin.on,
					     }
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_Chat:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end 

-----------------------------------------------------------------------------------------------
-- Gear_Chat Instance
-----------------------------------------------------------------------------------------------
local Gear_ChatInst = Gear_Chat:new()
Gear_ChatInst:Init()
