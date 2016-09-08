-----------------------------------------------------------------------------------------------
-- Client Lua Script for PratLite
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Apollo"
require "GameLib"
require "Window"
require "Unit"
require "Item"
require "ChatSystemLib"
require "GuildTypeLib"
require "FriendshipLib"

-------------------------------------------------------------------------------------
-- PratLite Module Definition
-----------------------------------------------------------------------------------------------
local PratLite = {}
----------------------------------------------------------------------------------------
local nAddonVersion = 03.02
local cassPkg = nil
local nOutInGuildSound = 193
local nEntryGuldSound = 174
local nFriendInSound = 174
local nFriendOutSound = 176
------------------------------------- URL --------------------------------------------
local patterns = {
  "%S+AppData%S+",
  "%S+%w%.%w%w%w?%:%S+", -- htps://
  "%w%wtps?%:%/%/%S+",
  "^(%a[%w+.-]+://%S+)",
  "(%a[%w+.-]+://%S+)",
  "%f[%S](%a[%w+.-]+://%S+)",
  "^(www%.[-%w_%%]+%.(%a%a+)",-- www.X.Y url
  "(www%.[-%w_%%]+%.%S+)",
  "%f[%S](www%.[-%w_%%]+%.(%a%a+))",
  '^(%"[^%"]+%"@[%w_.-%%]+%.(%a%a+))', -- "W X"@Y.Z email
  '%f[%S](%"[^%"]+%"@[%w_.-%%]+%.(%a%a+))',
  "(%S+@[%w_.-%%]+%.(%a%a+))",  -- X@Y.Z email
  "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)", -- XXX.YYY.ZZZ.WWW:VVVV/UUUUU IPv4
  "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d/%S+)", -- XXX.YYY.ZZZ.WWW:VVVV IPv4 
  "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]",
  "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d:[0-6]?%d?%d?%d?%d)%f[%D]",
  "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)", -- XXX.YYY.ZZZ.WWW/VVVVV IPv4 address with path
  "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%/%S+)",
  "^([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",-- X.Y.Z/WWWWW url with path
  "%f[%S]([0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%.[0-2]?%d?%d%)%f[%D]",
  "^([%w_.-%%]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",-- X.Y.Z/WWWWW url with path
  "%f[%S]([%w_.-%%]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d/%S+)",
  "^([%w_.-%%]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]", -- X.Y.Z/WWWWW url with path
  "%f[%S]([%w_.-%%]+[%w_-%%]%.(%a%a+):[0-6]?%d?%d?%d?%d)%f[%D]",
  "^([%w_.-%%]+[%w_-%%]%.(%a%a+)/%S+)", -- X.Y.Z/WWWWW url with path
  "%f[%S]([%w_.-%%]+[%w_-%%]%.(%a%a+)/%S+)",
  "^([-%w_%%]+%.[-%w_%%]+%.(%a%a+))", -- X.Y.Z url
  "%f[%S]([-%w_%%]+%.[-%w_%%]+%.(%a%a+))",
  "^([-%w_%%]+%.(%a%a+))",
  "%f[%S]([-%w_%%]+%.(%a%a+))",
  "%S+%.ру%/%S+", -- X.ру
  "%S+%.ру%/?",
  "%S+%.РУ%/%S+", -- X.РУ
  "%S+%.РУ%/?",
  "%w%wtps?%:%/%/%S+",  -- страховка
  "%S+%w%.%w%w%w%/%S+",
  "%S+%w%.%w%w%w%/",
  "%S+%w%.%w%w%w?%:%S+",
  "%S+%w%.%w%w%/%w+",
  "%S+%w%.%w%w%w",
  "%S+%w%.%w%w%/",
  "%S+%w%.%w%w",
  }
-------------------------------------------------------------------------------------------------------------------------
local tColorData = {
"AcidGreen", "AddonError", "AddonLoaded", "AddonNotLoaded", "AddonOk", "AddonWarning", "AlertOrangeYellow", "Amber", "AquaGreen", "AttributeDexterity", "AttributeMagic", "AttributeName", "AttributeStamina", "AttributeStrength", "AttributeTechnology", "AttributeWisdom", "Azure", "BabyGreen", "BabyPurple", "BananaYellow", "BarbiePink", "BattleshipGrey", "BlizzardBlue", "Bluegrey", "BlueyGreen", "BrightLightBlue", "BrightRed", "BrightSkyBlue", "BrightYellow", "Bronze", "BrownishRed", "BubbleTextRegular", "BubbleTextShout", "BurntYellow", "Butter", "CeruleanBlue", "ChatCustom", "ChatDebug", "ChatAdvice", "ChatEmote", "ChatGeneral", "ChatInstance", "ChatLoot", "ChatNPC", "ChatParty", "ChatPlayerName", "ChatPvP", "ChatSay", "ChatShout", "ChatSupport", "ChatSystem", "ChatTrade", "ChatUnknown", "ChatWhisper", "ChatZone", "InvalidChat", "ChatGuild", "ChatGuildOfficer", "ChatWarParty", "ChatWarPartyOfficer", "ChatAccountWisper", "ChatCircle1", "ChatCircle2", "ChatCircle3", "ChatCircle4", "ChatCircle5", "ChatCommand", "ConAverage", "ConEasy", "ConHard", "ConImpossible", "ConInferior", "ConMinor", "ConModerate", "ConTough", "ConTrivial", "CoolGrey", "cyan", "darkgray", "gray", "green", "magenta", "red", "vdarkgray", "white", "yellow", "DispositionFriendly", "DispositionFriendlyUnflagged", "DispositionHostile", "DispositionNeutra", "DispositionPvPFlagMismatch", "DuckEggBlue", "DullYellow", "DustyOrange", "EditSelection", "FadedRed", "FadedYellow", "Golden", "ItemQuality_Good", "ItemQuality_Legendary", "xkcdAmber", "xkcdBarbiePink", "xkcdBarneyPurple", "xkcdBarney", "xkcdBananaYellow", "xkcdBanana", "xkcdAzure", "xkcdBabyBlue", "xkcdAzul", "xkcdAvocadoGreen", "xkcdBloodOrange", "xkcdBrightRed", "xkcdBrightViolet", "xkcdBrightPink", "xkcdCerise", "xkcdCherryRed", "xkcdCranberry", "xkcdDarkForestGreen", "xkcdDarkCoral", "xkcdElectricPink", "xkcdEmerald", "xkcdEmeraldGreen", "xkcdEvergreen", "xkcdFadedRed", "xkcdFireEngineRed", "xkcdGolden", "xkcdGoldenrod", "xkcdGoldenYellow", "xkcdGreenishYellow", "xkcdGreenyYellow", "xkcdHotGreen", "xkcdHighlighterGreen", "xkcdIce", "xkcdIndigoBlue", "xkcdKeyLime"
}

local tSoundData = {
0, 12, 13, 14, 38, 43, 44, 48, 49, 74, 75, 76, 77, 78, 83, 84, 85, 86, 87, 88, 89, 96, 97, 99, 100, 101, 102, 105, 106, 107, 108, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 275
}

local karEvalColors =
{
	[Item.CodeEnumItemQuality.Inferior] 	    	= "ItemQuality_Inferior",
	[Item.CodeEnumItemQuality.Average] 	    		= "ItemQuality_Average",
	[Item.CodeEnumItemQuality.Good]     			= "ItemQuality_Good",
	[Item.CodeEnumItemQuality.Excellent]    		= "ItemQuality_Excellent",
	[Item.CodeEnumItemQuality.Superb]   			= "ItemQuality_Superb",
	[Item.CodeEnumItemQuality.Legendary] 		    = "ItemQuality_Legendary",
	[Item.CodeEnumItemQuality.Artifact]		    	= "ItemQuality_Artifact",
}

local tClassColors = {
	[GameLib.CodeEnumClass.Warrior]                 = "xkcdFireEngineRed",
	[GameLib.CodeEnumClass.Engineer]                = "FFEFAB48",
	[GameLib.CodeEnumClass.Esper]                   = "FF1591DB",
	[GameLib.CodeEnumClass.Medic]                   = "FFFFE757",
	[GameLib.CodeEnumClass.Stalker]                 = "FFD23EF4",
	[GameLib.CodeEnumClass.Spellslinger]            = "FF98C723"
}

local tPathToIcon = {
	[PlayerPathLib.PlayerPathType_Soldier] 		    = "BK3:UI_Icon_CharacterCreate_Path_Soldier",
	[PlayerPathLib.PlayerPathType_Settler]  		= "BK3:UI_Icon_CharacterCreate_Path_Settler", 
	[PlayerPathLib.PlayerPathType_Scientist]	    = "BK3:UI_Icon_CharacterCreate_Path_Scientist", 
	[PlayerPathLib.PlayerPathType_Explorer] 	    = "BK3:UI_Icon_CharacterCreate_Path_Explorer", 
}

local tChannelsRU = {
    ["Command"]           = "Команда",                 ["System"]            = "Система",      
    ["Debug"]             = "Отладка",                 ["Say"]               = "Сказать",      
    ["Yell"]              = "Крикнуть",                ["Whisper"]           = "Шепот",      
    ["Party"]             = "Группа",                  ["Emote"]             = "Эмоции",      
    ["Animated Emote"]    = "Аним. эмоции",            ["Zone"]              = "Зона",      
    ["Zone PvP"]          = "Зона PVP",                ["Trade"]             = "Торговля",      
    ["Guild"]             = "Гильдия",                 ["Guild Officer"]     = "Офиц. Гильдии",      
    ["Society"]           = "Круг",                    ["Custom"]            = "Пользовательский",      
    ["NPC Say"]           = "НиП говорит",             ["NPC Yell"]          = "НиП кричит",      
    ["NPC Whisper"]       = "НиП шепчет",              ["Datachron"]         = "Инфотрон",      
    ["Combat"]            = "Бой",                     ["Realm"]             = "Сервер",      
    ["Loot"]              = "Добыча",                  ["Player Path"]       = "Путь игрока",      
    ["Instance"]          = "Подземелье",              ["War Party"]         = "Боевая группа",      
    ["War Party Officer"] = "Офиц. боев. группы",      ["Advice"]            = "Совет",      
    ["Account Whisper"]   = "Шепот с аккаунта",      
}
-------------------------------------------------------------------------------------------
local tDefaultOptionChannelsEn = {}
local tDefaultOptionChannelsRu = {}
local tOptionChannels = {}
local tabCurrentChannal = {}
local tCurrentChanel = {}
local CurrentChannel = {}
local tChatHistory = {}
local tPlayerInfo = {}
local nRequestWB = {}
local CurrIndex = {}
local Queue = {}
local tTime = {}
local tCurrUpdate = {}
local iconShow = "Crafting_CoordSprites:sprCoord_AdditivePreviewMTX_SmallCombined"
local kstrBubbleFont = "CRB_Interface16_BBO"
local kstrGMIcon = "Icon_Windows_UI_GMIcon"
local strLocalization = Apollo.GetString(1)
local ChatLogAddon = Apollo.GetAddon("ChatLog")
local PLS = Apollo.GetAddon("PratLiteSocial")
local PLW = Apollo.GetAddon("PratLite_Whisper")
local WhoAddon = Apollo.GetAddon("Who")
local strUnitPlayerRealm = "xxxxxx"
local strUnitPlayerName = "qwerty"
local strLeaderGuildName = ""
local strLeaderGroupName = ""
local strSlashWho = "/who "
local strCurrNameWhisper = ""
local strPlayerGuild = ""
local strTimeAddon = "00:00"
local strHistory = ""
local strCapital = "Thayd"
local nCustomChannelCheck = 1
local NumberUpdateNewPlayers = 0
local NumberUpdatePlayers = 0
local NumberTotalPlayers = 0
local nItemLevelPlayer = 0
local nNumberRunsAddon = 0
local nNumberSimbol = 65
local nLimitHistory = 301
local nSelectedSound = 0
local nCurrentSound = 0
local nNumberLine = 0
local VolumeLevel = Apollo.GetConsoleVariable("sound.volumeUI")
local NumberHits = 0
local nTickTick = 0
local nOneStart = 1
local nCapit = 0
local nChime = 1
local registeredChatHandler = false
local PLInstance = nil
local bEnableNCFade = nil
local bRunsAddon = true
local bFirstInput = true
local bAnimation = true
local bAlertWB = true
local bSoundAnimation = true
local bLFM = false
local bMute = false
local bRus = false
local bStartMessage = false
local bLootText = false
local ApolloRegisterEventHandler = Apollo.RegisterEventHandler
local strColorClock, strFontChatSetting, strPathIconDisplay, strNicknameChat, strShortNamesCustom, nLinkSound, MessageOfTheDay, wndGrid, comboTextFont, comboColorText, comboColorClock, nStartUpdate, nSecondStart, strLastStatistic

 ---------------------------------------- Queue Message ---------------------
function Queue.new()
    return { first = 0, last = -1 }
end

function Queue.push( queue, value )
    queue.last = queue.last + 1
    queue[queue.last] = value
end

function Queue.pop( queue )
    if queue.first > queue.last then return nil end
    local val = queue[queue.first]
    queue[queue.first] = nil
    queue.first = queue.first + 1
    return val
end

function Queue.empty( queue )
    return queue.first > queue.last
end

local PLMessageQueue = Queue.new() --очередь сообщений
    Apollo.RegisterEventHandler = function (eventName,funcName,addonInstance) --подменяем регистрацию событий
	if (eventName ~= "ChatMessage") or PLInstance == nil then --не нужные события пропускаем на регистрацию
		ApolloRegisterEventHandler(eventName,funcName,addonInstance)
	else  -- чат событие регистрируем на нас 1 раз, а каждую регистрацию пишем в табличку, будем потом сами их вызывать
		local addonFunc = addonInstance[funcName]--ChatMessageHandlers[addonFunc]={event=eventName,funcName=funcName,addonInstance=addonInstance}
		if (not registeredChatHandler) then
			registeredChatHandler = true
			ApolloRegisterEventHandler("ChatMessage", "OnChatMessage", PLInstance)
		end
		ApolloRegisterEventHandler("ChatMessage_PratLite", "OnChatMessage", addonInstance)
	end
end

function PratLite:OnChatMessage(channelCurrent, tMessage) --по событию чата 
	local eChannelType = channelCurrent:GetType()
	local strCross = tMessage.bCrossFaction and "true" or "false"
	if strCross == "true" or tMessage.strSender == nil or tMessage.strSender == "" or tMessage.strSender:len() < 4 or (tMessage.unitSource ~= nil and not tMessage.unitSource:IsACharacter()) or tMessage.strRealmName:len() > 0 or eChannelType == 1 or eChannelType == 2 or eChannelType == 3 or eChannelType == 7 or eChannelType == 8 or eChannelType == 20 or eChannelType == 21 or eChannelType == 22 or eChannelType == 23 or eChannelType == 24 or eChannelType == 25 or eChannelType == 26 or eChannelType == 27 or eChannelType == 31 or eChannelType == 32 or eChannelType == 34 then 
	    Event_FireGenericEvent("ChatMessage_PratLite",channelCurrent,tMessage) 
	elseif tPlayerInfo[tMessage.strSender] ~= nil then
	        local pInfo = tPlayerInfo[tMessage.strSender]
	        if tonumber(pInfo.l) == 50 or pInfo.l == 50 then 
			    Event_FireGenericEvent("ChatMessage_PratLite",channelCurrent,tMessage)
            else local info = { channel=channelCurrent, msg=tMessage, ticks=0}
		        Queue.push( PLMessageQueue, info )
		        local strName = tMessage.strSender
		        local strName = '\"'..strName..'\"'
		        ChatSystemLib.Command(strSlashWho.." "..strName)
		    end
	else local info = { channel=channelCurrent, msg=tMessage, ticks=0}
		Queue.push( PLMessageQueue, info )
		local strName = tMessage.strSender
		local strName = '\"'..strName..'\"'
		ChatSystemLib.Command(strSlashWho.." "..strName)
	end 
end
--------------------------------------------- Initialize --------------
function PratLite:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	PLInstance = self -- это надо чтоб зарегать свой обработчик события, см выше
    -- initialize variables here
    o.tRanks = {}
    return o
end

function PratLite:Init()
	local bHasConfigureFunction = true
	local strConfigureButtonText = ""
	local tDependencies = {
		"CassPkg-1.1"
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
	if not GameLib.GetAccountRealmCharacter then local char = GameLib.GetPlayerUnit()
	    if not char then Apollo.RegisterEventHandler("CharacterCreated", "f", {f = RequestReloadUI}) end
	    function GameLib.GetAccountRealmCharacter()
	        return { strCharacter = char and char:GetName() or "Temp Name", strRealm = "Redmoon", strAccount = "never" }
	    end
	end
end
--------------------------- Save/Restore ------------------------------
function PratLite:OnSave(eType)
    if eType ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	local tSavedData =
	{   
	    tOptionChannels = tOptionChannels,
		MessageInput = bMessageInput,
		tColorCircle = tColorCircleChannel,
		tColorCustom = tColorCustomChannel,
		AddonVersion = nAddonVersion,
	    ShortNamesCustom = strShortNamesCustom,
	    NicknameChat = strNicknameChat,
		NumberRunsAddon = nNumberRunsAddon,
		FontAddon = strFontChatSetting,
		ColorClock = strColorClock,
		SoundAnimation = bSoundAnimation,
		LFM = bLFM,
		StartUpdate = nStartUpdate,
		LinkSound = nLinkSound,
		Animation = bAnimation,
		PathIconDisplay = strPathIconDisplay,
		AlertWB = bAlertWB,
		Mute = bMute,
		bToWhisper = self.bToWhisper,
		LootText = bLootText,
		LastStatistic = strLastStatistic,
	    tPlayerInfo = tPlayerInfo,
	}
	return tSavedData
end

function PratLite:OnRestore(eType,tSavedData)
    if eType == GameLib.CodeEnumAddonSaveLevel.Account then
        if tSavedData.NumberRunsAddon then
	        nNumberRunsAddon = tSavedData.NumberRunsAddon
	    else
	    	self:OnVerifySettings()
	        return
	    end
	    if tSavedData.AddonVersion then
	        if tSavedData.AddonVersion == nAddonVersion then bRunsAddon = false end
	    end
	    if tSavedData.tOptionChannels  then
	        tOptionChannels = tSavedData.tOptionChannels
	    	if tOptionChannels["Command"] == nil then self:OnDefaultSetting() end
        else self:OnDefaultSetting() end
	    if tSavedData.tOptionChannels then
	        tOptionChannels = tSavedData.tOptionChannels
	    	if tOptionChannels["Command"] == nil then self:OnDefaultSetting() end
        else self:OnDefaultSetting() end
	    if tSavedData.ShortNamesCustom then strShortNamesCustom = tSavedData.ShortNamesCustom
	    else strShortNamesCustom = "check" end
	    if tSavedData.NicknameChat then strNicknameChat = tSavedData.NicknameChat
	    else strNicknameChat = "check" end
	    if tSavedData.ColorClock then strColorClock = tSavedData.ColorClock
	    else strColorClock = "ff00ffa9" end
	    if tSavedData.PathIconDisplay then strPathIconDisplay = tSavedData.PathIconDisplay
	    else strPathIconDisplay = "show" end	
        if tSavedData.FontAddon then strFontChatSetting = tSavedData.FontAddon
	    else strFontChatSetting = "Default" end		
	    if tSavedData.tPlayerInfo then tPlayerInfo = tSavedData.tPlayerInfo end
	    if tSavedData.LinkSound then nLinkSound = tSavedData.LinkSound
	    else nLinkSound = 251 end
	    if tSavedData.MessageInput == true or tSavedData.MessageInput == false  then
	        bMessageInput = tSavedData.MessageInput
	    else bMessageInput = true
	    end
	    if tSavedData.LootText == true or tSavedData.LootText == false  then
	        bLootText = tSavedData.LootText
	    else bLootText = false
	    end
		if tSavedData.bToWhisper == true or tSavedData.bToWhisper == false  then
	        self.bToWhisper = tSavedData.bToWhisper
	    else self.bToWhisper = false
	    end
	    if tSavedData.LastStatistic ~= nil then strLastStatistic = tSavedData.LastStatistic
	    else strLastStatistic = "You have not updated your database"
	    end
	    if tSavedData.StartUpdate ~= nil then nStartUpdate = tSavedData.StartUpdate
	    else nStartUpdate = 0
	    end
	    if tSavedData.AlertWB == true or tSavedData.AlertWB == false then
	        bAlertWB = tSavedData.AlertWB
	    else bAlertWB = true
	    end
	    if tSavedData.SoundAnimation == true or tSavedData.SoundAnimation == false then
	        bSoundAnimation = tSavedData.SoundAnimation
	    else bSoundAnimation = true
	    end
	    if tSavedData.Mute == true or tSavedData.Mute == false then
	        bMute = tSavedData.Mute
	    else bMute = false
	    end
	    if tSavedData.Animation == true or tSavedData.Animation == false then
	        bAnimation = tSavedData.Animation
	    else bAnimation = true
	    end
	    if tSavedData.LFM == true or tSavedData.LFM == false then
	        bLFM = tSavedData.LFM
	    else bLFM = true
	    end
	    if tSavedData.tColorCustom then local tColorCustom = tSavedData.tColorCustom
	    	if tColorCustom[2] ~= nil then tColorCustomChannel = tSavedData.tColorCustom
	        else tColorCustomChannel = {[2] = "AttributeDexterity", [3] = "AlertOrangeYellow", [4] = "Amber", [5] = "AlertOrangeYellow"}
		    end
        end
	    if tSavedData.tColorCircle then local tColorCircle = tSavedData.tColorCircle
	    	if tColorCircle[2] ~= nil then tColorCircleChannel = tSavedData.tColorCircle
	        else tColorCircleChannel = {[2] = "ChatCircle2", [3] = "ChatCircle3", [4] = "ChatCircle4", [5] = "ChatCircle5", [6] = "ChatCircle5"}
	        end
        end
	end
end

function PratLite:OnDefaultSetting()
    tDefaultOptionChannelsRu = {
        ["Command"]            = {color = "ff888888",               name = "Команда",           sound = 0},
        ["System"]             = {color = "fffff6be",               name = "Sys",               sound = 0},
        ["Debug"]              = {color = "ff888888",               name = "Отладка",           sound = 0},
        ["Say"]                = {color = "White",                  name = "Скз",               sound = 190},
        ["Yell"]               = {color = "ffc4004a",               name = "Крик",              sound = 190},
        ["Whisper"]            = {color = "ffff0080",               name = "ш",                 sound = 223},
        ["Party"]              = {color = "ff005eff",               name = "Гр",                sound = 191}, 
        ["Emote"]              = {color = "FF9DE2FF",               name = "Эмоц",              sound = 0},
        ["Animated Emote"]     = {color = "FF9DE2FF",               name = "Эмоц",              sound = 0},
        ["Zone"]               = {color = "ChannelZone",            name = "Зона",              sound = 204},
        ["Zone PvP"]           = {color = "ChatPvP",                name = "PvP",               sound = 204},
        ["Trade"]              = {color = "ffffddaa",               name = "Торг",              sound = 0},
        ["Guild"]              = {color = "ChannelGuild",           name = "Ги",                sound = 186},
        ["Guild Officer"]      = {color = "ChannelGuildOfficer",    name = "О_Ги",              sound = 186},
        ["Society"]            = {color = "AquaGreen",              name = "NotEditable",       sound = 222},
        ["Custom"]             = {color = "ffffd7d3",               name = "NotEditable",       sound = 204},
        ["NPC Say"]            = {color = "ffff80c0",               name = "НиП",               sound = 0},
        ["NPC Yell"]           = {color = "ffff80c0",               name = "НиП",               sound = 0},
        ["NPC Whisper"]        = {color = "ffff80c0",               name = "НиП",               sound = 0},
        ["Datachron"]          = {color = "ffff80c0",               name = "Инф-н",             sound = 0},
        ["Combat"]             = {color = "ChannelGeneral",         name = "Бой",               sound = 0},
        ["Realm"]              = {color = "red",                    name = "Сервер",            sound = 206},
        ["Loot"]               = {color = "ffd8d8a3",               name = "Лут",               sound = 0},
        ["Player Path"]        = {color = "ChannelGeneral",         name = "Путь",              sound = 191},
        ["Instance"]           = {color = "ffff5000",               name = "Подз",              sound = 0},
        ["War Party"]          = {color = "ChannelWarParty",        name = "WP",                sound = 0},
        ["War Party Officer"]  = {color = "ChannelWarPartyOfficer", name = "O_WP",              sound = 0},
        ["Advice"]             = {color = "ChannelAdvice",          name = "Совет",             sound = 0},
        ["Account Whisper"]    = {color = "ffc458ff",               name = "Ш",                 sound = 223},
}
    tDefaultOptionChannelsEn = {
        ["Command"]            = {color = "ff888888",               name = "CM",                sound = 0},
        ["System"]             = {color = "fffff6be",               name = "SM",                sound = 0},
        ["Debug"]              = {color = "ff888888",               name = "D",                 sound = 0},
        ["Say"]                = {color = "White",                  name = "S",                 sound = 190},
        ["Yell"]               = {color = "ffc4004a",               name = "Y",                 sound = 190},
        ["Whisper"]            = {color = "ffff0080",               name = "W",                 sound = 223},
        ["Party"]              = {color = "ff005eff",               name = "P",                 sound = 191}, 
        ["Emote"]              = {color = "FF9DE2FF",               name = "E",                 sound = 0},
        ["Animated Emote"]     = {color = "FF9DE2FF",               name = "E",                 sound = 0},
        ["Zone"]               = {color = "ChannelZone",            name = "Z",                 sound = 204},
        ["Zone PvP"]           = {color = "ChatPvP",                name = "PvP",               sound = 204},
        ["Trade"]              = {color = "ffffddaa",               name = "T",                 sound = 0},
        ["Guild"]              = {color = "ChannelGuild",           name = "G",                 sound = 186},
        ["Guild Officer"]      = {color = "ChannelGuildOfficer",    name = "O",                 sound = 186},
        ["Society"]            = {color = "AquaGreen",              name = "NotEditable",       sound = 222},
        ["Custom"]             = {color = "ffffd7d3",               name = "NotEditable",       sound = 204},
        ["NPC Say"]            = {color = "ffff80c0",               name = "NPC",               sound = 0},
        ["NPC Yell"]           = {color = "ffff80c0",               name = "NPC",               sound = 0},
        ["NPC Whisper"]        = {color = "ffff80c0",               name = "NPC",               sound = 0},
        ["Datachron"]          = {color = "ffff80c0",               name = "NPC",               sound = 0},
        ["Combat"]             = {color = "ChannelGeneral",         name = "CL",                sound = 0},
        ["Realm"]              = {color = "red",                    name = "R",                 sound = 206},
        ["Loot"]               = {color = "ffd8d8a3",               name = "L",                 sound = 0},
        ["Player Path"]        = {color = "ChannelGeneral",         name = "PP",                sound = 0},
        ["Instance"]           = {color = "ffff5000",               name = "I",                 sound = 191},
        ["War Party"]          = {color = "ChannelWarParty",        name = "WP",                sound = 0},
        ["War Party Officer"]  = {color = "ChannelWarPartyOfficer", name = "OWP",               sound = 0},
        ["Advice"]             = {color = "ChannelAdvice",          name = "A",                 sound = 0},
        ["Account Whisper"]    = {color = "ffc458ff",               name = "WA",                sound = 223},
}   
    if Apollo.GetAddon("Gorynych Reborn") ~= nil or strPlayerGuild == "The Core" or strPlayerGuild == "Star Bears" then
	    tOptionChannels = tDefaultOptionChannelsRu
	else tOptionChannels = tDefaultOptionChannelsEn
	end
end
-----------------------------------------------------------------------------------------------
-- PratLite OnLoad
-----------------------------------------------------------------------------------------------
function PratLite:OnLoad()
    if ChatLogAddon == nil then
		Apollo.AddAddonErrorText(self, "No addon ChatLog.")
		return 
	end
	Apollo.RegisterTimerHandler("PratLiteMessageTimer",                        "QqueueTimerOut", self)
	Apollo.CreateTimer("PratLiteMessageTimer", 0.1, true)
	self:InitializeHooks()
	cassPkg = Apollo.GetPackage("CassPkg-1.1").tPackage
	self.xmlDoc = XmlDoc.CreateFromFile("PratLite.xml")
	Apollo.LoadSprites("PratLiteSprites.xml", "Sprites")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function PratLite:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "PratLiteForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.wndMain:Show(false)
        ChatLogAddon = Apollo.GetAddon("ChatLog")
        PLW = Apollo.GetAddon("PratLite_Whisper")
        WhoAddon = Apollo.GetAddon("Who")
		if WhoAddon == nil then WhoAddon = Apollo.GetAddon("ViragsSocial")
            Apollo.RegisterEventHandler("WhoResponse", "OnWhoResponse", self)
		end
		if WhoAddon == nil then 
			Apollo.AddAddonErrorText(self, "Not installed addon ' Who ' or substituting it..")
			return
		end
	    PLS = Apollo.GetAddon("PratLiteSocial")
        Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",               "OnInterfaceMenuListHasLoaded", self)
	    Apollo.RegisterEventHandler("PlayedTime",					            "OnPlayedtime", self)
	    Apollo.RegisterEventHandler("GuildRoster",                              "OnGuildRoster", self)
	    Apollo.RegisterEventHandler("Group_Updated",                            "OnGroupUpdated", self)
	    Apollo.RegisterEventHandler("UnitGroupChanged",                         "UnitGroupChangedPL" ,self)
	    Apollo.RegisterEventHandler("Group_Left",			 	                "OnGroupLeft", self)
	    Apollo.RegisterEventHandler("OnConfigurePratLite",	 	    	        "OnConfigure", self)
	    Apollo.RegisterEventHandler("OnCloseWind",			   	                "OnCloseWind", self)
	    Apollo.RegisterEventHandler("OnBarColorText",		                    "OnBarColorText", self)
	    Apollo.RegisterEventHandler("ButtonRestoreDefaultSettings",			    "OnButtonRestoreDefaultSettings", self)
	    Apollo.RegisterEventHandler("GenericEvent_InputChannel",			    "OnGenericEvent_InputChannel", self)
	    Apollo.RegisterEventHandler("GenericEvent_InputText",			        "OnGenericEvent_InputText", self)
	    Apollo.RegisterEventHandler("GenericEvent_CopyURL",				        "OnGenericEvent_CopyURL", self)
	    Apollo.RegisterEventHandler("OnResetHistory",				            "OnResetHistory", self)
	    Apollo.RegisterEventHandler("WindowManagementUpdate", 	              	"OnWindowManagementUpdate", self)
	    Apollo.RegisterEventHandler("OnFriendListOn", 	              	        "OnFriendListOn", self)
	    Apollo.RegisterEventHandler("OnOpenGuildPanelOn",			            "OnOpenGuildPanelOn", self)
	    Apollo.RegisterEventHandler("OnInstruction",                            "OnInstruction", self)
	    Apollo.RegisterEventHandler("UpdateFormationToolTip",                   "FormationToolTip", self)
        Apollo.RegisterSlashCommand("update",                                   "QuietDatabaseUpdate", self)
		Apollo.RegisterEventHandler("OnUpdateDataPlayers",                      "OnUpdateDataPlayers", self)
	    Apollo.RegisterSlashCommand("qwer",                                     "OnSlash", self)
		Apollo.RegisterEventHandler("MatchingGameReady",                        "OnMatchingGameReady", self)
		Apollo.RegisterEventHandler("MatchingLeaveQueue",                       "OnLeaveQueue", self)
		ChatSystemLib.Command("/played")
		self.wndCopyInput = Apollo.LoadForm(self.xmlDoc, "CopyWindow", nil, self)
		self.wndHistory = Apollo.LoadForm(self.xmlDoc, "ChatLogHistory", nil, self)
		self.wndPaste =  Apollo.LoadForm(self.xmlDoc, "PasteText", nil, self)
		self.wndInstruction =  Apollo.LoadForm(self.xmlDoc, "Instruction", nil, self)
		self.wndChannel = self.wndPaste:FindChild("ChannelDoc")
	    self.wndSound = self.wndMain:FindChild("SoundDoc")
		self.wndCopyInput:Show(false, true)
		self.wndHistory:Show(false, true)
		self.wndPaste:Show(false, true)
		self.wndChannel:Show(false, true)
		self.wndInstruction:Show(false, true)
	    self.bUdate = false
	    self.bQuiet = false
		self.tClassColors = tClassColors
        self.tPathToIcon = tPathToIcon
		if nNumberRunsAddon == 0 then self:OnVerifySettings() 
		    ChatLogAddon.bEnableBGFade = false
		    ChatLogAddon.bEnableNCFade = false
		end
		if strLocalization == "Annuler" then strSlashWho = "/qui" end -- Fr
		if strLocalization == "Abbrechen" then strSlashWho = "/wer" end -- De
		self.TimerStartUp = ApolloTimer.Create(6, true, "OnStartUp", self)
		self.TimerButtonUp = ApolloTimer.Create(5, true, "OnButtonUp", self)
		if not self.bToWhisper or self.bToWhisper == nil then self.bToWhisper = false end
	end
end
------------------------------- Button Chat -----------------------
function PratLite:OnButtonUp()
    if ChatLogAddon.tChatWindows then
		self.TimerButtonUp = nil
	    local chatWnds = ChatLogAddon.tChatWindows
	    local wndChat = chatWnds[1]
	    if not self.wndButtonHistory then
	        self.wndButtonHistory = Apollo.LoadForm(self.xmlDoc, "Chat_ButtonHistory", wndChat, self)
		end
	    self.wndButtonHistory:Show(true, false)
		self.wndButtonHistory:FindChild("ButtonHistory"):SetScale(0.85)
		self.wndButtonHistory:FindChild("ButtonPaste"):SetScale(0.9)local bBGFade = ChatLogAddon.bEnableBGFade
		local bNCFade = ChatLogAddon.bEnableNCFade
		self.wndButtonHistory:SetStyle("AutoFadeNC", bNCFade)
		if ChatLogAddon.bEnableNCFade then self.wndButtonHistory:SetNCOpacity(1) end
		self.wndButtonHistory:SetStyle("AutoFadeBG", bBGFade)
		if ChatLogAddon.bEnableBGFade then self.wndButtonHistory:SetBGOpacity(1) end
		self.wndButtonHistory:SetAnchorOffsets(-20, -15, wndChat:GetWidth()-20, wndChat:GetHeight()-20)
		self.wndButtonHistory:FindChild("ButtonAlertWB"):SetCheck(bAlertWB)
		if Apollo.GetAddon("Gorynych Reborn") ~= nil or strPlayerGuild == "The Core" or strPlayerGuild == "Star Bears" then 
		    self.wndButtonHistory:FindChild("ButtonAlertWB"):SetTooltip("Оповещение при создании группы на мирового босса.")
			self.wndButtonHistory:FindChild("ButtonHistory"):SetTooltip("История чата")
			self.wndButtonHistory:FindChild("ButtonPaste"):SetTooltip("Вставка длинного текста в сообщение чата")
			bRus = true
		end
	end
end
---------------------------------------- Start ------------------------------------------
function PratLite:OnStartUp()
    bStartMessage = true
    self.TimerStartUp = nil
	self:OnBGFade()
    local unitPlayer = GameLib.GetPlayerUnit()
	strUnitPlayerRealm = GameLib.GetRealmName()
	if unitPlayer and unitPlayer:GetName() ~= nil then
	    strUnitPlayerName = unitPlayer:GetName()
		local nFaction = unitPlayer:GetFaction()
        if nFaction == 167 then strCapital = Apollo.GetString("Lore_Thayd") 
        else strCapital = Apollo.GetString("Lore__Illium")
        end
        strCapital = string.gsub(strCapital, " ", "")
	    strCurrNameWhisper = strUnitPlayerName
	end
	if bRunsAddon then
	    self:OnInstruction()
	    if bMute == false then Sound.Play(222) end
	    bRunsAddon = false
	end
	self:OnUpdateButtonPanel(tColorCustomChannel)
	self.TimerFriendshipUpdate = ApolloTimer.Create(8, true, "OnFriendship", self)
	if bMessageInput == true and bFirstInput == true then
	    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, "MessagePratLite", "")
	end
	local nMembers = 0
    for name, data in pairs(tPlayerInfo) do
	    if string.find(name, " ") ~= 0 then nMembers = nMembers + 1 end
	end
	if self.nSecondsSession > 300 then strToolTip = strLastStatistic
	else strToolTip = "( /update - quiet update.)"
	    if bRus == true then strToolTip = "( /update - тихое обновление )" end
	end
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Update DataBase", {false, "last update: \n"..strToolTip.."\n Status of the database: "..nMembers.." players", 0})
	nNumberRunsAddon = nNumberRunsAddon + 1
	if tTime.bOneLoginGame == true then self:QuietDatabaseUpdate() end
end

function PratLite:OnPlayedtime(strCreationDate, strPlayedTime, strPlayedLevelTime, strPlayedSessionTime, dateCreation, nSecondsPlayed, nSecondsLevel, nSecondsSession)
    tTime.nSecondsSession = nSecondsSession
	tTime.nSecondsLevel = nSecondsLevel
	tTime.nSecondsPlayed = nSecondsPlayed
	tTime.dateCreation = dateCreation
	local LocalTime = GameLib.GetLocalTime()
	nSecondStart = (LocalTime.nHour*3600) + (LocalTime.nMinute*60) + LocalTime.nSecond
	if nSecondsSession < 300 or nStartUpdate == 0 then tTime.bOneLoginGame = true
	    nStartUpdate = nSecondStart
	else tTime.bOneLoginGame = false
	end
	local nRealTimeUpdate = nSecondStart - nStartUpdate
	if nSecondsSession > 3600 and (nRealTimeUpdate > 3540 or nSecondStart < nStartUpdate) then tTime.bOneLoginGame = true
	    nStartUpdate = nSecondStart
	end
	self.nSecondsSession = nSecondsSession
	if  (nSecondStart - nStartUpdate) < 240 then tTime.bOneLoginGame = true end
end

function PratLite:OnSlash()
    for n, d in pairs(WhoAddon) do
	    Print(n)
	end
end

function PratLite:OnFriendship()
    self.TimerFriendshipUpdate = nil
	Apollo.RegisterEventHandler("FriendshipUpdateOnline", 					"OnFriendshipUpdateOnline", self)
	Apollo.RegisterEventHandler("FriendshipUpdate",                         "OnFriendshipUpdateOnline", self)
    Apollo.RegisterEventHandler("FriendshipAccountDataUpdate",              "OnFriendshipUpdateOnline", self)
    self:OnFriendshipUpdateOnline()
end

function PratLite:OnConfigure()
    if self.wndMain:IsVisible() then
        self:OnCancel()
    else
	self:OnGotOn()
	end
end

function PratLite:OnMatchingGameReady()
    if bLFM == false then return end
    if nTickTick == 0 then self.timesoundalert = ApolloTimer.Create(3, true, "OnMatchingGameReady", self)
	    self.originalVolumeLevel = Apollo.GetConsoleVariable("sound.volumeMaster")
	    self.originalUIVolumeLevel = Apollo.GetConsoleVariable("sound.volumeUI")
		if self.originalVolumeLevel < 0.60 then
	        Apollo.SetConsoleVariable("sound.volumeMaster", 0.60)
		end
		if self.originalUIVolumeLevel < 0.60 then
	        Apollo.SetConsoleVariable("sound.volumeUI", 0.60)
		end
	end
	nTickTick = nTickTick + 1
	if nTickTick > 2 then self.timesoundalert = nil
	    nTickTick = 0
		self:OnLeaveQueue()
	end
	if bMute == false then Sound.Play(149) end
end

function PratLite:OnLeaveQueue()
	Apollo.SetConsoleVariable("sound.volumeMaster", self.originalVolumeLevel)
	Apollo.SetConsoleVariable("sound.volumeUI", self.originalUIVolumeLevel)
	nTickTick = 0
end
------------------------------------- Float Text --------------------------------
function PratLite:OnFloatText(strMessage, crColor, nYPosition, nTime)
    local FT = Apollo.GetAddon("FloatText")
	if FT == nil then return end
	local tTextOption = FT:GetDefaultTextOption()
	tTextOption.fDuration =  nTime or 5
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = nYPosition or -240
	tTextOption.nColor = crColor or 0xFF00AE
	tTextOption.strFontFace = "CRB_Interface16_BBO"
	tTextOption.bShowOnTop = true
    CombatFloater.ShowTextFloater(GameLib.GetPlayerUnit(), strMessage, tTextOption)
end
------------------------------ Elements InterfaceMenuList -----------------------
function PratLite:OnInterfaceMenuListHasLoaded()
    if Apollo.GetAddon("PratLitePanel") ~= nil then
        Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Channel buttons. On/Off", {"OnShowPanelOn", "", "icon_Panel"})
	end
	local strGuild = "OnOpenGuildPanelOn"
	local strSocial = "OnFriendListOn"
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "PratLite Description", {"OnInstruction", "", "icon_Description"})
	if Apollo.GetAddon("ViragsSocial") ~= nil then strGuild = "ToggleSocialWindow"
	   strSocial = "ToggleSocialWindow"
	end
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Guild", {strGuild, "", "icon_Guild"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Friends", {strSocial, "", "icon_Friends"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Update DataBase", {"OnUpdateDataPlayers", "", "CRB_WarriorSprites:xx_ImSF"})
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "PratLite Options", {"OnConfigurePratLite", "", "LoginIncentives:sprLoginIncentives_SpinnerComposite"})
	for key, tGuild in pairs(GuildLib.GetGuilds()) do
		if tGuild:GetType() == GuildLib.GuildType_Guild then
			tGuild:RequestMembers()
		end
	end
end
------------------------------------------------------------------------------
function PratLite:OnAlertWB()
    if self.wndButtonHistory:FindChild("ButtonAlertWB"):IsChecked() then bAlertWB = true
	else bAlertWB = false
	end
    if bMute == false then Sound.Play(89) end
end
-------------------------------- Friend Update Online ------------------------------
function PratLite:OnFriendshipUpdateOnline()
	local strFriends = ""
	local nOnlineFriendCount = 0
	local nFriendTotal = 0
	for idx,tSearchAccountFriend in pairs(FriendshipLib.GetAccountList()) do
	    for idx, tFriend in pairs(tSearchAccountFriend.arCharacters or {}) do
			tPlayerInfo[tFriend.strCharacterName] = {
			    c = tFriend.nClassId  or "",
				l = tFriend.nLevel or 0,
				p = tFriend.nPathId or ""}
		    if tSearchAccountFriend.arCharacters and tFriend.strCharacterName  then
			    nOnlineFriendCount = nOnlineFriendCount + 1
			    if nOnlineFriendCount == 1 then  strFriends = "Account Friends: \n"..strFriends end
				strFriends = strFriends.."   ["..tFriend.nLevel..": "..tFriend.strCharacterName.."("..tSearchAccountFriend.strCharacterName..") \n"
		    end
			nFriendTotal = nFriendTotal + 1
	    end
	end
	local strFriends = strFriends.."Friends: \n"
	for idx, tFriend in pairs(FriendshipLib.GetList()) do
	    if tFriend.bFriend == true then
		    if tFriend.nPathId then
		        tPlayerInfo[tFriend.strCharacterName] = {
		    	    c = tFriend.nClassId  or "",
		    	    l = tFriend.nLevel or 0,
		    	    p = tFriend.nPathId or 0}
			end
		    if tFriend.fLastOnline == 0 then nOnlineFriendCount = nOnlineFriendCount + 1
		       strFriends = strFriends.."   ["..tFriend.nLevel..": "..tFriend.strCharacterName.."] \n"
		    end
		    nFriendTotal = nFriendTotal + 1
		end
	end
	local strToolTip = "  Total: "..nFriendTotal.." Online: "..nOnlineFriendCount..". \n"..strFriends
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Friends", {false, strToolTip, nOnlineFriendCount})
	self.FriendsOnline = strToolTip or nil
	if PLS ~= nil then PLS:OnGenericTooltip() end
end
--------------------- Group_Updated Data-------------------------------
function PratLite:UnitGroupChangedPL()
    NumberHits = 0
    self:OnGroupUpdated()
end

function PratLite:OnGroupUpdated()
	NumberHits = NumberHits + 1
	if GroupLib.GetMemberCount() < 2 then return end
	local nGroupMemberCount = GroupLib.GetMemberCount()
	for idx = 1, nGroupMemberCount do
    	local tMemberInfo = GroupLib.GetGroupMember(idx)
		if tMemberInfo ~= nil then
		    local strPlayerName = tMemberInfo.strCharacterName
			if tMemberInfo.bIsLeader then
			    strLeaderGroupName = tMemberInfo.strCharacterName				end
			if NumberHits < 3 and tMemberInfo.nLevel ~= nil and tonumber(tMemberInfo.nLevel) ~= nil then
		        tPlayerInfo[strPlayerName] = {
		            c = tMemberInfo.eClassId  or "",
		            l = tMemberInfo.nLevel or 0,
				    p = tMemberInfo.ePathType or ""}
		    end
		end
	end
end

function PratLite:OnGroupLeft(eReason)
	local unitMe = GameLib.GetPlayerUnit()
	if unitMe == nil then return end
    strLeaderGroupName = ""
	if bMute == false then Sound.Play(176) end
end
----------------------------- Guild Update Data --------------------------------
function PratLite:OnGuildRoster(guildCurr, tRoster)
    local tMembersGuildOnline = {}
	if self.nVerificationGuild == nil then self.nVerificationGuild = 0 end
	self.nVerificationGuild = self.nVerificationGuild + 1
    if guildCurr:GetType() ~= GuildLib.GuildType_Guild then return end
	strPlayerGuild = guildCurr:GetName() or ""
	MessageOfTheDay = guildCurr:GetMessageOfTheDay(guildCurr)
	if Apollo.GetAddon("Gorynych Reborn") ~= nil or strPlayerGuild == "The Core" or strPlayerGuild == "Star Bears" then
	    bRus = true
	end
	local nClass
	local bColor = false
	local nTotalCountPlayers = guildCurr:GetMemberCount()
	local nOnlineCountPlayers = guildCurr:GetOnlineMemberCount()
	for key, tCurr in pairs(tRoster) do
		local PlayerName = tCurr.strName
		if self.nVerificationGuild < 2 or tCurr.fLastOnline == 0 then
		    if tCurr.fLastOnline == 0 then
	    	    tMembersGuildOnline[PlayerName] = {
	    		    r = tCurr.nRank,
	    		    l = tCurr.nLevel}
	    	end
            if tCurr.nRank == 1 then 
                trLeaderGuildName = PlayerName
            end				
  		    local strClass = tCurr.strClass
	   	    if strClass == "Warrior" or strClass == Apollo.GetString("CRB_Warrior") then
                nClass = GameLib.CodeEnumClass.Warrior
            elseif strClass == "Engineer" or strClass == Apollo.GetString("CRB_Engineer") then
	    	    nClass = GameLib.CodeEnumClass.Engineer
            elseif strClass == "Esper" or strClass == Apollo.GetString("CRB_Esper") then
                nClass = GameLib.CodeEnumClass.Esper
            elseif strClass == "Medic" or strClass == Apollo.GetString("CRB_Medic") then
   	            nClass = GameLib.CodeEnumClass.Medic
            elseif strClass == "Stalker" or strClass == Apollo.GetString("CRB_Stalker") then
                nClass = GameLib.CodeEnumClass.Stalker
            elseif strClass == "Spellslinger" or strClass == Apollo.GetString("CRB_Spellslinger") then
                nClass = GameLib.CodeEnumClass.Spellslinger
            end
		    if tPlayerInfo[PlayerName] == nil then
	            tPlayerInfo[PlayerName] = {
	                c = nClass or "",
        	        l = tCurr.nLevel or 0,
	       	        p = tCurr.ePathType or "",}
		    else local info = tPlayerInfo[PlayerName]
		        if info.l ~= tCurr.nLevel then
			    tPlayerInfo[PlayerName] = {
	                c = nClass or "",
    	   	        l = tCurr.nLevel or 0,
	       	        p = tCurr.ePathType or "",}
			    end
		    end
		end
	end
	local strMembers = ""
	local tRanks = guildCurr:GetRanks()
	for name, data in cassPkg.spairs(tMembersGuildOnline, function(t,a,b) return t[b].r > t[a].r or t[b].r == t[a].r and a < b end) do
	    local nLevel = data.l
		local strName = name
		local strPrefixFriend = ""
		for idx, tFriend in pairs(FriendshipLib.GetList()) do
		    if tFriend.bFriend == true and tFriend.strCharacterName then
		        if strName == tFriend.strCharacterName then strPrefixFriend = " (Friend)" end
				break
			end
        end
        for idx,tSearchAccountFriend in pairs(FriendshipLib.GetAccountList()) do
	        for idx, tFriend in pairs(tSearchAccountFriend.arCharacters or {}) do
		        if strName == tFriend.strCharacterName then strPrefixFriend = " (Friend)" end
				break
			end
        end	
		if data.r < 10 and tRanks[data.r] and tRanks[data.r].strName then
		    local strPrefix = "* "
			if strName ~= strUnitPlayerName then bColor = true end
			strRank = tRanks[data.r].strName
			strRank = FixXMLString(strRank)
			if data.r == 1 then
    			strPrefix = "# " 
				strRank = "Guild Master"
			end
			strMembers = strMembers..strPrefix.."["..nLevel..": "..strName.."]    "..strRank..strPrefixFriend.."\n"
		else
		    local strPrefix = ", "
		    if nOnlineCountPlayers < 100 then strPrefix = " \n" end
     		strMembers = strMembers.."   ["..nLevel..": "..strName.."]"..strPrefixFriend..strPrefix
		end
	end
	local strTooltip = "<<"..guildCurr:GetName()..">>  "..nOnlineCountPlayers.."("..nTotalCountPlayers..") \n"..strMembers
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Guild", {bColor, strTooltip, nOnlineCountPlayers})
	self.GuildOnline = strTooltip or nil
end
---------------------------------------------- Database update Players ------------------------
function PratLite:QuietDatabaseUpdate()
    if self.timerupdate == nil and self.bUdate == false and self.bQuiet == false then Print("Quiet database update ...")
        self:ResettingData()
		self.bQuiet = true
	end
end

function PratLite:ResettingData()
    self.ticktime = 1
    self.amplitude = 5 + (GameLib.GetLatency()/1000) + (GameLib.GetPingTime()/1000)
	self.time = math.modf(self.amplitude * 58 / self.ticktime)
	NumberTotalPlayers = 0
	tCurrUpdate = {}
    NumberUpdatePlayers = 0
	NumberUpdateNewPlayers = 0
	nCapit = 0
    self.timerupdate = ApolloTimer.Create(self.amplitude, true, "OnUpdatePlayers", self)
	if (nSecondStart - nStartUpdate) > 300 then 
		nSecondStart = nSecondStart - 240
	end
end

function PratLite:OnUpdateDataPlayers()
    if self.timerupdate == nil and self.bQuiet == false and self.bUdate == false then
        self:ResettingData()
	    if bMute == false then Sound.Play(246) end
		self.bUdate = true
        local strMessage = "Updating the database Players(turn the channel 'Debug') \n Estimated time: "..(string.format("%02d min. %02d sec.", tostring(self.time/60), tostring(self.time%60)))
	    if bRus == true then
		    strMessage = "Обновление базы данных игроков \n (для подробного анализа включите канал 'Отладка') \n РасчЁтное время: "..(string.format("%02d мин. %02d сек.", tostring(self.time/60), tostring(self.time%60)))
	    end
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, strMessage, "")
		self:OnFloatText(strMessage, 0xFFD000, -240, 7)
	else 
	    if bMute == false then Sound.Play(231) end
	    local strMessage = "Wait for the end of the previous update"
		if bRus == true then strMessage = "Дождитесь окончания предыдущего обновления!" end
	    self:OnFloatText(strMessage, 0xFF0000, -240, 7)
	end
end

function PratLite:OnUpdatePlayers()
    self.time = self.time - self.amplitude
	if self.time < 0.1 then self.time = 0 end
    local strLetter = string.char(math.modf(nNumberSimbol))
	if nNumberSimbol == 91 then strLetter = "l"
	elseif nNumberSimbol == 92 then strLetter = "a"
	elseif nNumberSimbol == 93 then strLetter = "o"
	elseif nNumberSimbol == 94 then strLetter = "i"
	elseif nNumberSimbol == 95 then strLetter = "e"
	elseif nNumberSimbol == 96 then strLetter = "u"
	end
    if nNumberSimbol > math.modf(nNumberSimbol) then strLetter = string.lower(strLetter) end
	ChatSystemLib.Command(strSlashWho.." "..strLetter)
	nNumberSimbol = nNumberSimbol + self.ticktime
	if nNumberSimbol >= 123 then 
	    nNumberSimbol = 65
	    self.timerupdate = nil
	end  
end

function PratLite:RestTimeToolTip()
    local strRestTime = string.format("00:%02d:%02d", tostring(self.time/60), tostring(self.time%60))
	local strToolTip = "... It is updated ...\n Time left: \n "..strRestTime
	if bRus == true then strToolTip = "... идёт обновление ...\n Осталось времени: \n "..strRestTime end
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Update DataBase", {true, strToolTip, 0})
end

function PratLite:QuietUpdates(tWhoPlayers)
	for _, tResult in ipairs(tWhoPlayers) do
		if tCurrUpdate[tResult.strName] == nil then
		    NumberTotalPlayers = NumberTotalPlayers + 1
			self:OnLocation(tResult)
			tCurrUpdate[tResult.strName] = tResult.strName
		end
	end
    if self.timerupdate ~= nil then self:RestTimeToolTip() end
	if self.timerupdate == nil and self.bQuiet == true and NumberTotalPlayers > 2 then
	    self.bQuiet = false
        local nCurNumber, CurrentStatistic = self:CountingStatistic(tCurrUpdate, NumberTotalPlayers, nCapit)
	    strLastStatistic = ""
		for n = 1, 19 do strLastStatistic = strLastStatistic..CurrentStatistic[n].."\n" end
	    self:FormationToolTip(NumberTotalPlayers, nCurNumber)
	    NumberTotalPlayers = 0
	end
end
	
function PratLite:OnLocation(tResult)   
	local strSubZone = tResult.strSubZone or nil
	local strLocation = strSubZone and string.format("%s: %s", tResult.strZone, strSubZone) or tResult.strZone
	if string.find(strLocation, strCapital) ~= nil then
		nCapit = nCapit + 1
	end
end
	
function PratLite:VisibilityUpdates(tWhoPlayers)
    Print(string.format("%02d min. %02d sec.", tostring(self.time/60), tostring(self.time%60)))
	for _, tResult in ipairs(tWhoPlayers) do
		if tCurrUpdate[tResult.strName] == nil then
	        NumberTotalPlayers = NumberTotalPlayers + 1
			self:OnLocation(tResult)
			tCurrUpdate[tResult.strName] = tResult.strName
		    if tPlayerInfo[tResult.strName] ~= nil then
	            local info = tPlayerInfo[tResult.strName]
	        	if tResult.nLevel > info.l then NumberUpdatePlayers = NumberUpdatePlayers + 1
		        Print(NumberUpdatePlayers..". ["..tResult.nLevel..": "..tResult.strName.."] (up the level "..info.l.." ==> "..tResult.nLevel..")")
	        	end
    	    else NumberUpdatePlayers = NumberUpdatePlayers + 1
			    NumberUpdateNewPlayers = NumberUpdateNewPlayers + 1
    	        Print(NumberUpdatePlayers..". ["..tResult.nLevel..": "..tResult.strName.."] (new player)")
		    end
		end
    end
    if self.timerupdate ~= nil then self:RestTimeToolTip() end
	if self.timerupdate == nil and self.bUdate == true and NumberTotalPlayers > 2 then
		self.bUdate = false
		local nLVL = NumberUpdatePlayers - NumberUpdateNewPlayers
		ChatSystemLib.PostOnChannel(25, "Updated players: "..NumberUpdatePlayers.." (New players: "..NumberUpdateNewPlayers..", Up the level: "..nLVL..")", "")
		local nCurNumber, CurrentStatistic = self:CountingStatistic(tCurrUpdate, NumberTotalPlayers, nCapit)
		ChatSystemLib.PostOnChannel(25, "Total repository database: "..nCurNumber.." players.", "")
		strLastStatistic = ""
		for n = 1, 19 do strLastStatistic = strLastStatistic..CurrentStatistic[n].."\n" end
		for n = 2, 18 do ChatSystemLib.PostOnChannel(25, CurrentStatistic[n], "") end
		ChatSystemLib.PostOnChannel(25, "++++++ End of renovation ++++++", "")
		self:FormationToolTip(NumberTotalPlayers, nCurNumber)
		NumberUpdatePlayers = 0
		NumberUpdateNewPlayers = 0
		NumberTotalPlayers = 0
	    local strMessage = "Updating the database of players is complete!"
	    if bRus == true then strMessage = "Обновление базы данных игроков завершено!" end
	    self:OnFloatText(strMessage, 0x00CD00, -240, 5)
	end
end

function PratLite:CountingStatistic(tCurrUpdate, NumberTotalPlayers, nCapit)
    local nCurNumber = 0
	local tClass = { Warrior = 0, Engineer = 0, Esper = 0, Medic = 0, Stalker = 0, Spellslinger = 0}
	local dClass = { Warrior = 0, Engineer = 0, Esper = 0, Medic = 0, Stalker = 0, Spellslinger = 0}
	local tLevel = { lvl_1_9 = 0, lvl_10_19 = 0, lvl_20_29 = 0, lvl_30_39 = 0, lvl_40_49 = 0, lvl_50 = 0}
	local dLevel = { lvl_1_9 = 0, lvl_10_19 = 0, lvl_20_29 = 0, lvl_30_39 = 0, lvl_40_49 = 0, lvl_50 = 0}
	for name, data in pairs(tPlayerInfo) do
	    if string.find(name, " ") ~= nil then
		    nCurNumber = nCurNumber + 1
		    if data.c == 1 then dClass.Warrior = dClass.Warrior + 1
		    elseif data.c == 2 then dClass.Engineer = dClass.Engineer + 1
		    elseif data.c == 3 then dClass.Esper = dClass.Esper + 1
	    	elseif data.c == 4 then dClass.Medic = dClass.Medic + 1 
	    	elseif data.c == 5 then dClass.Stalker = dClass.Stalker + 1
	    	elseif data.c == 7 then dClass.Spellslinger = dClass.Spellslinger + 1
	    	end
			if data.l > 49 then dLevel.lvl_50 = dLevel.lvl_50 + 1
			elseif data.l > 39 then dLevel.lvl_40_49 = dLevel.lvl_40_49 + 1
			elseif data.l > 29 then dLevel.lvl_30_39 = dLevel.lvl_30_39 + 1
			elseif data.l > 19 then dLevel.lvl_20_29 = dLevel.lvl_20_29 + 1
			elseif data.l > 9 then dLevel.lvl_10_19 = dLevel.lvl_10_19 + 1
			elseif data.l > 0 then  dLevel.lvl_1_9 = dLevel.lvl_1_9 + 1
			end
	    	if tCurrUpdate[name] ~= nil then
	    		if data.c == 1 then tClass.Warrior = tClass.Warrior + 1
	    		elseif data.c == 2 then tClass.Engineer = tClass.Engineer + 1
	    		elseif data.c == 3 then tClass.Esper = tClass.Esper + 1
	    		elseif data.c == 4 then tClass.Medic = tClass.Medic + 1 
	    		elseif data.c == 5 then tClass.Stalker = tClass.Stalker + 1
	    		elseif data.c == 7 then tClass.Spellslinger = tClass.Spellslinger + 1
                end
				if data.l > 49 then tLevel.lvl_50 = tLevel.lvl_50 + 1
			    elseif data.l > 39 then tLevel.lvl_40_49 = tLevel.lvl_40_49 + 1
			    elseif data.l > 29 then tLevel.lvl_30_39 = tLevel.lvl_30_39 + 1
			    elseif data.l > 19 then tLevel.lvl_20_29 = tLevel.lvl_20_29 + 1
			    elseif data.l > 9 then tLevel.lvl_10_19 = tLevel.lvl_10_19 + 1
			    elseif data.l > 0 then  tLevel.lvl_1_9 = tLevel.lvl_1_9 + 1
			    end
            end
        end
	end
	for n,d in pairs(tClass) do tClass[n] = string.format("%.1f", d*100/NumberTotalPlayers).."%" end
	for n,d in pairs(tLevel) do tLevel[n] = string.format("%.1f", d*100/NumberTotalPlayers).."%" end
	for n,d in pairs(dClass) do dClass[n] = string.format("%.1f", d*100/nCurNumber).."%" end
	for n,d in pairs(dLevel) do dLevel[n] = string.format("%.1f", d*100/nCurNumber).."%" end
	local tServerTime = GameLib.GetServerTime()
	--local CurrentStatistic = {}
	local strDate = tServerTime.nMonth.."/"..tServerTime.nDay.."/"..tServerTime.nYear
	if strUnitPlayerRealm == "Jabbit" or strUnitPlayerRealm == "Luminai" then 
		strDate = tServerTime.nDay.."/"..tServerTime.nMonth.."/"..tServerTime.nYear
	end
	local CurrentStatistic = {
	[1]  = strDate.."  Server Time: "..tServerTime.strFormattedTime.." ("..strUnitPlayerRealm..")",
	[2]  = "Total server online: "..NumberTotalPlayers.." players. "..strCapital..":"..nCapit,
	[3]  = "++++++++++++++++++++++",
	[4]  = "Current (General) Statistics:",
	[5]  = "   "..Apollo.GetString("Tutorials_Warrior").."       - "..tClass.Warrior.." ("..dClass.Warrior..")",
	[6]  = "   "..Apollo.GetString("Tutorials_Engineer").."     - "..tClass.Engineer.." ("..dClass.Engineer..")",
	[7]  = "   "..Apollo.GetString("Tutorials_Esper").."           - "..tClass.Esper.." ("..dClass.Esper..")",
	[8]  = "   "..Apollo.GetString("Tutorials_Medic").."          - "..tClass.Medic.." ("..dClass.Medic..")",
	[9]  = "   "..Apollo.GetString("Tutorials_Stalker").."         - "..tClass.Stalker.." ("..dClass.Stalker..")",
	[10] = "   "..Apollo.GetString("Tutorials_Spellslinger").." - "..tClass.Spellslinger.." ("..dClass.Spellslinger..")",
	[11] = "----------------------",
	[12] = "   1-9 level      - "..tLevel.lvl_1_9.." ("..dLevel.lvl_1_9..")",
	[13] = "   10-19 level  - "..tLevel.lvl_10_19.." ("..dLevel.lvl_10_19..")",
	[14] = "   20-29 level  - "..tLevel.lvl_20_29.." ("..dLevel.lvl_20_29..")",
	[15] = "   30-39 level  - "..tLevel.lvl_30_39.." ("..dLevel.lvl_30_39..")",
	[16] = "   40-49 level  - "..tLevel.lvl_40_49.." ("..dLevel.lvl_40_49..")",
	[17] = "   50 level       - "..tLevel.lvl_50.." ("..dLevel.lvl_50..")",
	[18] = "++++++++++++++++++++++",
	[19] = "The statistics are based on a database of players (PratLite)"}
	tTime.bOneLoginGame = false
	tCurrUpdate = {}
	nCapit = 0
	return  nCurNumber, CurrentStatistic
end

function PratLite:FormationToolTip(NumberTotalPlayers, nCurNumber)
    local strToolTip = "\n Total online players: "..NumberTotalPlayers..". \n Status of the database: "..nCurNumber.." players."
	if bRus == true then strToolTip = "\n Статус базы данных: "..nCurNumber.." игроков." end
    local n = NumberTotalPlayers
	if n > 899 then n = tonumber(string.format("%.2f", n/1000)) end
    Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Update DataBase", {true, "last update: \n"..strLastStatistic..strToolTip, n})
end
             ---------------------------- Hooks -----------------------------
function PratLite:InitializeHooks()	
	if ChatLogAddon ~= nil then
	    ChatLogAddon.HelperGenerateChatMessage = self.HelperGenerateChatMessage
		ChatLogAddon.OnNodeClick = self.OnNodeClick
		ChatLogAddon.OnBGFade = self.OnBGFade
		--ChatLogAddon.OnInputChanged = self.OnInputChanged
	end
	if WhoAddon == nil then WhoAddon = Apollo.GetAddon("ViragsSocial") end
    if WhoAddon ~= nil then
	    WhoAddon.OnWhoResponse = self.OnWhoResponse
	    --[[WhoAddon == Apollo.GetAddon("ViragsSocial") then
	       WhoAddon.OnViragsSocialOn = self.OnViragsSocialOn
		end ]]
	end
	local IML = Apollo.GetAddon("InterfaceMenuList")
	if IML ~= nil then
	    IML.OnDrawAlert = self.OnDrawAlert
	end
end

function PratLite:OnInputChanged(wndHandler, wndControl, strText)
	local wndForm = wndControl:GetParent()
    local knCountSpaces = 2
	local kcrValidColor = ApolloColor.new("white")
	local kcrInvalidColor = ApolloColor.new("red")
	if wndControl:GetName() ~= "Input" then return end
	for idx, wndChat in pairs(self.tChatWindows) do
		wndChat:FindChild("Input"):SetData(false)
	end
	wndControl:SetData(true)
	local wndForm = wndControl:GetParent()
	local wndInput = wndForm:FindChild("Input")
	if Apollo.StringToLower(strText) == Apollo.GetString("ChatLog_Reply") and self.tLastWhisperer and self.tLastWhisperer.strCharacterName ~= "" then
		local strName = self.tLastWhisperer.strCharacterName
		local channel = self.channelWhisper
		if self.tLastWhisperer.eChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
			channel = self.channelAccountWhisper
			self.tAccountWhisperContex =
			{
				["strDisplayName"]		= self.tLastWhisperer.strDisplayName,
				["strCharacterName"]	= self.tLastWhisperer.strCharacterName,
				["strRealmName"]		= self.tLastWhisperer.strRealmName,
			}
			strName = self.tLastWhisperer.strDisplayName
		end
		local strWhisper = String_GetWeaselString(Apollo.GetString("ChatLog_MessageToPlayer"), channel:GetAbbreviation(), strName)
		wndInput:SetPrompt(channel:GetCommand())
		wndInput:SetPromptColor(self.arChatColor[self.tLastWhisperer.eChannelType])
		wndInput:SetTextColor(self.arChatColor[self.tLastWhisperer.eChannelType])
		wndInput:SetText(strWhisper)
		wndInput:SetFocus()
		wndInput:SetSel(strWhisper:len(), -1)
		return
	end
	local tChatData = wndForm:GetData()
	local tInput = ChatSystemLib.SplitInput(strText)
	local channelInput = tInput.channelCommand or tChatData.channelCurrent
	local crText = ChatLogAddon.arChatColor[channelInput:GetType()] or ApolloColor.new("white")
	wndInput:SetStyleEx("PromptColor", crText)
	wndInput:SetTextColor(crText)
	if channelInput:GetType() == ChatSystemLib.ChatChannel_Command then -- command or emote
		if tInput.bValidCommand then
			if not self.tEmotes[tInput.strCommand] then
				wndInput:SetPrompt(String_GetWeaselString(Apollo.GetString("CRB_CurlyBrackets"), "", tInput.strCommand))
				wndInput:SetPromptColor(kcrValidColor)
				wndInput:SetTextColor(kcrValidColor)
			end
		else
			--if there was a last channel, use that. otherwise default to say.
			wndInput:SetPrompt(self.channelLastChannel and self.channelLastChannel:GetCommand() or self.channelSay:GetCommand())
		end
	else -- chatting in a channel; check for visibility
		if self.tAllViewedChannels[ channelInput:GetType() ] ~= nil then -- channel is viewed
			wndInput:SetPrompt(channelInput:GetCommand())
		else -- channel is hidden
			wndInput:SetPrompt(String_GetWeaselString(Apollo.GetString("ChatLog_Invalid"), channelInput:GetCommand()))
			wndInput:SetPromptColor(kcrInvalidColor)
		end
	end
	local luaSubclass = wndInput:GetWindowSubclass()
	if luaSubclass and tInput then
		if not self.tSuggestedFilterRules then
			self.tSuggestedFilterRules = self:HelperLoadSetRules(luaSubclass)
		end
		if tInput.bValidCommand then
			strCommandName = tInput.channelCommand and tInput.channelCommand:GetCommand() ~= "" and tInput.channelCommand:GetCommand() or tInput.strCommand
		end
	    local eChannelType = channelInput:GetType()
        if eChannelType == ChatSystemLib.ChatChannel_Society then
		    local strCommandName = tInput.strCommand or tInput.channelCommand:GetCommand()
			local strCh = string.upper(strCommandName)
			local strCh = string.gsub(strCh, "%a", "")
			if tonumber(strCh) ~= nil then 
			    local nChannelNumber = tonumber(strCh)
			    if nChannelNumber > 1 and nChannelNumber < 6 then
			        crChannel = tColorCircleChannel[nChannelNumber]
			        wndInput:SetTextColor(crChannel)
			    end
			end
		end
		if eChannelType == ChatSystemLib.ChatChannel_Custom then
			local nChannelNumber = tonumber(string.upper(strCommandName))
			if nChannelNumber > 1 and nChannelNumber < 6 then
			    crChannel = tColorCustomChannel[nChannelNumber]
			    wndInput:SetTextColor(crChannel)	
			end
		end
		if strCommandName ~= "" then
			local strLowerCaseCommand = Apollo.StringToLower(strCommandName)
			if self.tSuggestedFilterRules and self.tSuggestedFilterRules[strLowerCaseCommand] then
				local strPlaceHolder, nCountSpaces = string.gsub(strText, " ", " ")
				if tInput.bValidCommand  and nCountSpaces <= knCountSpaces then
					local tSuggestFilterInfo = self.tSuggestedFilterRules[strLowerCaseCommand]
					self.tLastFilteredInfo = tSuggestFilterInfo
					luaSubclass:SetFilters(tSuggestFilterInfo)
					luaSubclass:OnEditBoxChanged(wndHandler, wndControl, tInput.strMessage)
				elseif tInput.bValidCommand and nCountSpaces > knCountSpaces or not tInput.bValidCommand and luaSubclass:IsSuggestedMenuShown() then
					luaSubclass:HideSuggestedMenu()
				end
			end
		end
	end
end
    
function PratLite:OnDrawAlert(strAddonName, tParams)-- Should be reserved for AddOns pushing updates.
	if type(strAddonName) ~= "string" or type(tParams) ~= "table" then
		return
	end
	local wndButtonList = self.wndMain:FindChild("ButtonList")		
	local wndButtonListItem = wndButtonList:FindChild("InterfaceMenuButton_" .. strAddonName)
	local nPinIndex = self:GetPinIndex(self.tPinnedAddons, strAddonName)
	if wndButtonListItem and nPinIndex ~= nil then
		local wndButton = wndButtonListItem:FindChild("ShortcutBtn")
		--if tParams[3] and self.tMenuAlerts[strAddonName][3] < tParams[3] then -- Make sure # of alerts is going up before displaying blip
		if tParams[3] and tParams[3] > 0 then
			local wndFlash = self:LoadByName("AlertBlip", wndButton:FindChild("Alert"), "AlertBlip")
			wndFlash:FindChild("Sonar"):SetSprite("PlayerPathContent_TEMP:spr_Crafting_TEMP_Stretch_QuestZoneNoLoop")
		elseif wndButton:FindChild("AlertBlip") ~= nil then
			wndButton:FindChild("AlertBlip"):Destroy()
		end
	end
	self.tMenuAlerts[strAddonName] = tParams
	self:OnDrawAlertVisual(strAddonName, tParams) 
end
-------------------------------------- Ubdate Button History ------------------------------------
function PratLite:OnBGFade(wndHandler, wndControl)
    if wndHandler and wndControl then
	    local wndParent = wndControl:GetParent()
	    self.bEnableBGFade = wndControl:GetData()
	    self.bEnableNCFade = wndControl:GetData()
	    for idx, wndChatWindow in pairs(self.tChatWindows) do
		wndChatWindow:SetStyle("AutoFadeNC", self.bEnableNCFade)
		    if self.bEnableNCFade then wndChatWindow:SetNCOpacity(1) end
		    wndChatWindow:SetStyle("AutoFadeBG", self.bEnableBGFade)
		    if self.bEnableBGFade then wndChatWindow:SetBGOpacity(1) end
	    end
	end
    local PratLiteAddon = Apollo.GetAddon("PratLite")
	PratLiteAddon.wndButtonHistory:Show(false)
	PratLiteAddon:OnButtonUp()
end

function PratLite:OnWindowManagementUpdate(tSettings)
    if self.wndButtonHistory then
	    local chatWnds = ChatLogAddon.tChatWindows
	    local wndChat = chatWnds[1]
	    self.wndButtonHistory:SetAnchorOffsets(-20, -15, wndChat:GetWidth()-20, wndChat:GetHeight()-20)
	end
end
--------------------------------------   WhoResponse ------------------------------------------
function PratLite:OnWhoResponse(arResponse, eWhoResult, strResponse, tResult)
        local tWhoPlayers  = {}
        if eWhoResult == GameLib.CodeEnumWhoResult.OK or eWhoResult == GameLib.CodeEnumWhoResult.Partial then
		    tWhoPlayers  = arResponse
	    else return
	    end
	    local PratLiteAddon = Apollo.GetAddon("PratLite")
		if WhoAddon == Apollo.GetAddon("Who") then
		    self.tWhoPlayers = arResponse
	        self.bShowSearchResults = true
	        self:HelperResetUI()
		else --WhoAddon:OnCloseSettingsWnd()
		end
	    if PratLiteAddon.bUdate == true then PratLiteAddon:VisibilityUpdates(tWhoPlayers) end
	    if PratLiteAddon.bQuiet == true then PratLiteAddon:QuietUpdates(tWhoPlayers) end
	    for _, tResult in ipairs(tWhoPlayers) do
			local PlayerName = tResult.strName
			if tPlayerInfo[PlayerName] ~= nil then
				if tonumber(tResult.nLevel) < 50 or tResult.nLevel < 50 then
			        tPlayerInfo[PlayerName] = {
			            c = tResult.eClassId  or "",
				        l = tResult.nLevel or 0,
				        p = tResult.ePlayerPathType or ""}
			    end
			else tPlayerInfo[PlayerName] = {
			    c = tResult.eClassId  or "",
				l = tResult.nLevel or 0,
				p = tResult.ePlayerPathType or ""}
			end
		end
	    if self.timer ~= nil then self.timer:Stop() end
end
------------------------------ Queue Timer ----------------------------------
function PratLite:QqueueTimerOut()
	if Queue.empty( PLMessageQueue ) then return end
	local info = PLMessageQueue[PLMessageQueue.first] -- берем значение не вынимая
	local channelCurrent = info.channel
	local tMessage=info.msg
	local pInfo = tPlayerInfo[tMessage.strSender]
	local needToSend = pInfo ~= nil or info.ticks > 10 --10*0.1=1 сек
	if not needToSend then
		info.ticks=info.ticks + 1
		return
	else 
		local info = Queue.pop(PLMessageQueue) --вынимаем из очереди
		Event_FireGenericEvent("ChatMessage_PratLite",channelCurrent,tMessage)
	end
end
---------------------------- Generate Chat Message -----------------------------
function PratLite:HelperGenerateChatMessage(tQueuedMessage)
    if tOptionChannels["Command"] == nil then return end
	--------------------------- Setting Channels --------------------------
	local ChannelCommand                            = tOptionChannels["Command"]
    local ChannelSystem                             = tOptionChannels["System"]
    local ChannelDebug                              = tOptionChannels["Debug"]
    local ChannelSay                                = tOptionChannels["Say"]
    local ChannelYell                               = tOptionChannels["Yell"]
    local ChannelWhisper                            = tOptionChannels["Whisper"]
    local ChannelParty                              = tOptionChannels["Party"] 
    local ChannelEmote                              = tOptionChannels["Emote"]
    local ChannelAnimatedEmote                      = tOptionChannels["Animated Emote"]
    local ChannelZone                               = tOptionChannels["Zone"]
    local ChannelZonePvP                            = tOptionChannels["Zone PvP"]
    local ChannelTrade                              = tOptionChannels["Trade"]
    local ChannelGuild                              = tOptionChannels["Guild"]
    local ChannelGuildOfficer                       = tOptionChannels["Guild Officer"]
    local ChannelSociety                            = tOptionChannels["Society"]
    local ChannelCustom                             = tOptionChannels["Custom"]
    local ChannelNPCSay                             = tOptionChannels["NPC Say"]
    local ChannelNPCYell                            = tOptionChannels["NPC Yell"]
    local ChannelNPCWhisper                         = tOptionChannels["NPC Whisper"]
    local ChannelDatachron                          = tOptionChannels["Datachron"]
    local ChannelCombat                             = tOptionChannels["Combat"]
    local ChannelRealm                              = tOptionChannels["Realm"]
    local ChannelLoot                               = tOptionChannels["Loot"]
    local CurrentChannelPlayerPath                  = tOptionChannels["Player Path"]
    local ChannelInstance                           = tOptionChannels["Instance"]
    local ChannelWarParty                           = tOptionChannels["War Party"]
    local ChannelWarPartyOfficer                    = tOptionChannels["War Party Officer"]
    local ChannelAdvice                             = tOptionChannels["Advice"]
    local ChannelAccountWhisper                     = tOptionChannels["Account Whisper"]
	----------------------------------------- short Name channels -----------------------------------------------
    local tShortNames = {
	    [ChatSystemLib.ChatChannel_Command] 		= ChannelCommand.name, 		
	    [ChatSystemLib.ChatChannel_System] 			= ChannelSystem.name, 		
	    [ChatSystemLib.ChatChannel_Debug] 			= ChannelDebug.name, 			
	    [ChatSystemLib.ChatChannel_Say] 			= ChannelSay.name, 			
	    [ChatSystemLib.ChatChannel_Yell] 			= ChannelYell.name, 			
	    [ChatSystemLib.ChatChannel_Whisper] 		= ChannelWhisper.name, 		
	    [ChatSystemLib.ChatChannel_Party] 			= ChannelParty.name, 			
	    [ChatSystemLib.ChatChannel_Emote] 			= ChannelEmote.name, 			
	    [ChatSystemLib.ChatChannel_AnimatedEmote] 	= ChannelAnimatedEmote.name, 			
	    [ChatSystemLib.ChatChannel_Zone] 			= ChannelZone.name, 			
	    [ChatSystemLib.ChatChannel_ZonePvP] 		= ChannelZonePvP.name, 			
	    [ChatSystemLib.ChatChannel_Trade] 			= ChannelTrade.name,			
	    [ChatSystemLib.ChatChannel_Guild] 			= ChannelGuild.name, 			
	    [ChatSystemLib.ChatChannel_GuildOfficer] 	= ChannelGuildOfficer.name,	
	    [ChatSystemLib.ChatChannel_Society] 		= ChannelSociety.name,
        [ChatSystemLib.ChatChannel_Custom] 			= ChannelCustom.name,	
	    [ChatSystemLib.ChatChannel_NPCSay] 			= ChannelNPCSay.name, 			
	    [ChatSystemLib.ChatChannel_NPCYell] 		= ChannelNPCYell.name,		 	
	    [ChatSystemLib.ChatChannel_NPCWhisper]		= ChannelNPCWhisper.name, 			
	    [ChatSystemLib.ChatChannel_Datachron] 		= ChannelDatachron.name, 			
	    [ChatSystemLib.ChatChannel_Combat] 			= ChannelCombat.name, 		
	    [ChatSystemLib.ChatChannel_Realm] 			= ChannelRealm.name, 		
	    [ChatSystemLib.ChatChannel_Loot] 			= ChannelLoot.name, 			
	    [ChatSystemLib.ChatChannel_PlayerPath] 		= CurrentChannelPlayerPath.name, 		
	    [ChatSystemLib.ChatChannel_Instance] 		= ChannelInstance.name, 			
	    [ChatSystemLib.ChatChannel_WarParty] 		= ChannelWarParty.name,		
	    [ChatSystemLib.ChatChannel_WarPartyOfficer] = ChannelWarPartyOfficer.name,
	    [ChatSystemLib.ChatChannel_Advice] 			= ChannelAdvice.name, 		
	    [ChatSystemLib.ChatChannel_AccountWhisper] 	= ChannelAccountWhisper.name,
	}
	self.arChatColor = {
		[ChatSystemLib.ChatChannel_Command] 		= ChannelCommand.color,
		[ChatSystemLib.ChatChannel_System] 			= ChannelSystem.color,
		[ChatSystemLib.ChatChannel_Debug] 			= ChannelDebug.color,
		[ChatSystemLib.ChatChannel_Say] 			= ChannelSay.color,
		[ChatSystemLib.ChatChannel_Yell] 			= ChannelYell.color,
		[ChatSystemLib.ChatChannel_Whisper] 		= ChannelWhisper.color,
		[ChatSystemLib.ChatChannel_Party] 			= ChannelParty.color,
		[ChatSystemLib.ChatChannel_AnimatedEmote] 	= ChannelAnimatedEmote.color,
		[ChatSystemLib.ChatChannel_Zone] 			= ChannelZone.color,
		[ChatSystemLib.ChatChannel_ZoneGerman]		= ChannelZone.color,
		[ChatSystemLib.ChatChannel_ZoneFrench]		= ChannelZone.color,
		[ChatSystemLib.ChatChannel_ZonePvP] 		= ChannelZonePvP.color,
		[ChatSystemLib.ChatChannel_Trade] 			= ChannelTrade.color,
		[ChatSystemLib.ChatChannel_Guild] 			= ChannelGuild.color,
		[ChatSystemLib.ChatChannel_GuildOfficer] 	= ChannelGuildOfficer.color,
		[ChatSystemLib.ChatChannel_Society] 		= ChannelSociety.color,
		[ChatSystemLib.ChatChannel_Custom] 			= ChannelCustom.color,
		[ChatSystemLib.ChatChannel_NPCSay] 			= ChannelNPCSay.color,
		[ChatSystemLib.ChatChannel_NPCYell] 		= ChannelNPCYell.color,
		[ChatSystemLib.ChatChannel_NPCWhisper] 		= ChannelNPCWhisper.color,
		[ChatSystemLib.ChatChannel_Datachron] 		= ChannelDatachron.color,
		[ChatSystemLib.ChatChannel_Combat] 			= ChannelCommand.color,
		[ChatSystemLib.ChatChannel_Realm] 			= ChannelRealm.color,
		[ChatSystemLib.ChatChannel_Loot] 			= ChannelLoot.color,
		[ChatSystemLib.ChatChannel_Emote] 			= ChannelEmote.color,
		[ChatSystemLib.ChatChannel_PlayerPath] 		= CurrentChannelPlayerPath.color,
		[ChatSystemLib.ChatChannel_Instance] 		= ChannelInstance.color,
		[ChatSystemLib.ChatChannel_WarParty] 		= ChannelWarParty.color,
		[ChatSystemLib.ChatChannel_WarPartyOfficer] = ChannelWarPartyOfficer.color,
		[ChatSystemLib.ChatChannel_Advice] 			= ChannelAdvice.color,
		[ChatSystemLib.ChatChannel_AdviceGerman]	= ChannelAdvice.color,
		[ChatSystemLib.ChatChannel_AdviceFrench]	= ChannelAdvice.color,
		[ChatSystemLib.ChatChannel_AccountWhisper]	= ChannelAccountWhisper.color,
	}
	local tSoundCannels = {
	    [ChatSystemLib.ChatChannel_Command] 		= ChannelCommand.sound, 		
	    [ChatSystemLib.ChatChannel_System] 			= ChannelSystem.sound, 		
	    [ChatSystemLib.ChatChannel_Debug] 			= ChannelDebug.sound, 			
	    [ChatSystemLib.ChatChannel_Say] 			= ChannelSay.sound, 			
	    [ChatSystemLib.ChatChannel_Yell] 			= ChannelYell.sound, 			
	    [ChatSystemLib.ChatChannel_Whisper] 		= ChannelWhisper.sound, 		
	    [ChatSystemLib.ChatChannel_Party] 			= ChannelParty.sound, 			
	    [ChatSystemLib.ChatChannel_Emote] 			= ChannelEmote.sound, 			
	    [ChatSystemLib.ChatChannel_AnimatedEmote] 	= ChannelAnimatedEmote.sound, 			
	    [ChatSystemLib.ChatChannel_Zone] 			= ChannelZone.sound, 			
	    [ChatSystemLib.ChatChannel_ZonePvP] 		= ChannelZonePvP.sound, 			
	    [ChatSystemLib.ChatChannel_Trade] 			= ChannelTrade.sound,			
	    [ChatSystemLib.ChatChannel_Guild] 			= ChannelGuild.sound, 			
	    [ChatSystemLib.ChatChannel_GuildOfficer] 	= ChannelGuildOfficer.sound,	
	    [ChatSystemLib.ChatChannel_Society] 		= ChannelSociety.sound,
        [ChatSystemLib.ChatChannel_Custom] 			= ChannelCustom.sound,		
	    [ChatSystemLib.ChatChannel_NPCSay] 			= ChannelNPCSay.sound, 			
	    [ChatSystemLib.ChatChannel_NPCYell] 		= ChannelNPCYell.sound,		 	
	    [ChatSystemLib.ChatChannel_NPCWhisper]		= ChannelNPCWhisper.sound, 			
	    [ChatSystemLib.ChatChannel_Datachron] 		= ChannelDatachron.sound, 			
	    [ChatSystemLib.ChatChannel_Combat] 			= ChannelCombat.sound, 		
	    [ChatSystemLib.ChatChannel_Realm] 			= ChannelRealm.sound, 		
	    [ChatSystemLib.ChatChannel_Loot] 			= ChannelLoot.sound, 			
	    [ChatSystemLib.ChatChannel_PlayerPath] 		= CurrentChannelPlayerPath.sound, 		
	    [ChatSystemLib.ChatChannel_Instance] 		= ChannelInstance.sound, 			
	    [ChatSystemLib.ChatChannel_WarParty] 		= ChannelWarParty.sound,		
	    [ChatSystemLib.ChatChannel_WarPartyOfficer] = ChannelWarPartyOfficer.sound,
	    [ChatSystemLib.ChatChannel_Advice] 			= ChannelAdvice.sound, 		
	    [ChatSystemLib.ChatChannel_AccountWhisper] 	= ChannelAccountWhisper.sound,
	}
	local tChannelLink = {
	    [ChatSystemLib.ChatChannel_Command] 		= "NoLink", 		
	    [ChatSystemLib.ChatChannel_System] 			= "NoLink",		
	    [ChatSystemLib.ChatChannel_Debug] 			= "NoLink", 			
	    [ChatSystemLib.ChatChannel_Say] 			= "s", 			
	    [ChatSystemLib.ChatChannel_Yell] 			= "y",			
	    [ChatSystemLib.ChatChannel_Whisper] 		= "NoLink", 		
	    [ChatSystemLib.ChatChannel_Party] 			= "p",			
	    [ChatSystemLib.ChatChannel_Emote] 			= "NoLink", 			
	    [ChatSystemLib.ChatChannel_AnimatedEmote] 	= "NoLink", 			
	    [ChatSystemLib.ChatChannel_Zone] 			= "z", 			
	    [ChatSystemLib.ChatChannel_ZonePvP] 		= "v", 			
	    [ChatSystemLib.ChatChannel_Trade] 			= "tr",			
	    [ChatSystemLib.ChatChannel_Guild] 			= "g", 			
	    [ChatSystemLib.ChatChannel_GuildOfficer] 	= "go",	
	    [ChatSystemLib.ChatChannel_Society] 		= "Society",
        [ChatSystemLib.ChatChannel_Custom] 			= "Custom",		
	    [ChatSystemLib.ChatChannel_NPCSay] 			= "NoLink",			
	    [ChatSystemLib.ChatChannel_NPCYell] 		= "NoLink",		 	
	    [ChatSystemLib.ChatChannel_NPCWhisper]		= "NoLink", 			
	    [ChatSystemLib.ChatChannel_Datachron] 		= "NoLink", 			
	    [ChatSystemLib.ChatChannel_Combat] 			= "NoLink", 		
	    [ChatSystemLib.ChatChannel_Realm] 			= "NoLink", 		
	    [ChatSystemLib.ChatChannel_Loot] 			= "NoLink", 			
	    [ChatSystemLib.ChatChannel_PlayerPath] 		= "NoLink", 		
	    [ChatSystemLib.ChatChannel_Instance] 		= "i", 			
	    [ChatSystemLib.ChatChannel_WarParty] 		= "NoLink",		
	    [ChatSystemLib.ChatChannel_WarPartyOfficer] = "NoLink",
	    [ChatSystemLib.ChatChannel_Advice] 			= "a", 		
	    [ChatSystemLib.ChatChannel_AccountWhisper] 	= "NoLink",
	}
	if nNumberLine == 0 then Event_FireGenericEvent("GenericEvent_OnChannelsNames", tColorCustomChannel, tColorCircleChannel) end
	if tQueuedMessage.xml or bStartMessage == false then return end
	---------------------------------- Unicode ------------------------------------------
    local function FixPunctuation(strText)
        local strSymbol = "` & ' * @ , ^ } : $ = ! > < # { ( + ; / ~ _ %] \\ %% %{ %] %) %." -- удаляет из текста символы пунктуации
    	for symbol in string.gmatch(strSymbol, "%S+") do
    	    strText = string.gsub(strText, symbol, "")
    	end
    	strText =  string.gsub(strText, '\"', "")
    	return strText
    end

    local function StringLower(strText) -- заменяет буквы верхней раскладки на буквы нжней раскладки
        local tUnicodeLeter = {
    	["А"] = "а", ["Б"] = "б", ["В"] = "в", ["Г"] = "г", ["Д"] = "д", ["Е"] = "е", ["Ё"] = "ё", ["Ж"] = "ж", ["З"] = "з", ["И"] = "и", ["Й"] = "й", ["К"] = "к", ["Л"] = "л", ["М"] = "м", ["Н"] = "н", ["О"] = "о", ["П"] = "п", ["Р"] = "р", ["С"] = "с", ["Т"] = "т", ["У"] = "у", ["Ф"] = "ф", ["Х"] = "х", ["Ц"] = "ц", ["Ч"] = "ч", ["Ш"] = "ш", ["Щ"] = "щ", ["Ъ"] = "ъ", ["Ы"] = "ы", ["Ь"] = "ь", ["Э"] = "э", ["Ю"] = "ю", ["Я"] = "я"}
	    for leter, data in pairs(tUnicodeLeter) do
	        strText = string.gsub(strText, leter, tUnicodeLeter[leter])
	    end
	    return strText
    end
----------------------------------
	local PL = Apollo.GetAddon("PratLite")
	local tMessage = tQueuedMessage.tMessage
	local tTime = GameLib.GetLocalTime()
	local eChannelType = tQueuedMessage.eChannelType
----------------------- Different handling for combat log ------------------------------------------
	if eChannelType == ChatSystemLib.ChatChannel_Combat then   -- no formats in combat, roll it all up into one. ---
		local strMessage = ""
		for idx, tSegment in ipairs(tMessage.arMessageSegments) do
			strMessage = strMessage .. tSegment.strText
		end
		tQueuedMessage.strMessage = strMessage
		return
	end
	local xml = XmlDoc.new()
    local strPlayerRealm = ""
	local crText = ChatLogAddon.arChatColor[eChannelType] or ApolloColor.new("white")
	local crChannel = crText
	local crPlayerName = ApolloColor.new("ChatPlayerName")
	local nLevel = 0
	local strPathToIcon = ""
	local strCurrentName = ""
	local strFontChat = ChatLogAddon.strFontOption
------------------------------------- Time format -------------------------------------
	local strTime = string.gsub(ChatLogAddon:HelperGetTimeStr(), " ", "") or ""
	if strTime ~= "" then strTime = "["..strTime.."] " end
	for idx, tSegment in ipairs( tMessage.arMessageSegments ) do
		if string.find(tSegment.strText, "MessagePratLite") ~= nil then strTime = "" end
    end
	local crTime = ApolloColor.new(strColorClock)
	PL.TimeColor = strColorClock
	strTimeAddon = strTime
------------------------------------------------------------------------------------------------
	local strWhisperName = tMessage.strSender
	if tMessage.strRealmName:len() > 0 and eChannelType ~= ChatSystemLib.ChatChannel_AccountWhisper then
		strWhisperName = strWhisperName .. "@" .. tMessage.strRealmName
	end
	local strDisplayName = strWhisperName
	local strDisplayNameAcc = ""
	local strPresenceState = ""
	if tMessage.bAutoResponse then
		strPresenceState = '('..Apollo.GetString("AutoResponse_Prefix")..')'
	end
	if tMessage.nPresenceState == FriendshipLib.AccountPresenceState_Away then
		strPresenceState = '<'..Apollo.GetString("Command_Friendship_AwayFromKeyboard")..'>'
	elseif tMessage.nPresenceState == FriendshipLib.AccountPresenceState_Busy then
		strPresenceState = '<'..Apollo.GetString("Command_Friendship_DoNotDisturb")..'>'
	end
	if eChannelType == ChatSystemLib.ChatChannel_Whisper then
		self.tLastWhisperer = { strCharacterName = strWhisperName, eChannelType = ChatSystemLib.ChatChannel_Whisper }--record the last incoming whisperer for quick response
		self:InsertIntoRecent(strWhisperName, false)
	elseif eChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
		local tPreviousWhisperer = self.tLastWhisperer
		self.tLastWhisperer =
		{
			strCharacterName = tMessage.strSender,
			strRealmName = nil,
			strDisplayName = nil,
			eChannelType = ChatSystemLib.ChatChannel_AccountWhisper
		}
		local tAccountFriends = FriendshipLib.GetAccountList()
		for idx, tAccountFriend in pairs(tAccountFriends) do
			if tAccountFriend.arCharacters ~= nil then
				for idx, tCharacter in pairs(tAccountFriend.arCharacters) do
					if tCharacter.strCharacterName == tMessage.strSender and (tMessage.strRealmName:len() == 0 or tCharacter.strRealm == tMessage.strRealmName) then 
					    self.tLastWhisperer.strDisplayName = tAccountFriend.strCharacterName
					    self.tLastWhisperer.strRealmName = tCharacter.strRealm
						strDisplayName = tAccountFriend.strCharacterName
					end
				end
			end
		end
		strDisplayNameAcc = "@"..strDisplayName  --  Name & NameAcc
		strDisplayName = tMessage.strSender
		self:InsertIntoRecent(strWhisperName, true)
	end
	------------------------------ Font  ------------------
	if strFontChatSetting == "Default" or strFontChatSetting == "Defaul" then
	    strFontChat = ChatLogAddon.strFontOption
	else strFontChat = strFontChatSetting
	end
	PL.CurrentFont = strFontChat
	local ChatSoundPL = tSoundCannels[eChannelType] or 0
	local strChatHistory = ""
	if eChannelType == ChatSystemLib.ChatChannel_AnimatedEmote then -- emote animated channel gets special formatting
		xml:AddLine(strTime, crTime, strFontChat, "Left")
        strChatHistory = strChatHistory..strTime
	elseif eChannelType == ChatSystemLib.ChatChannel_Emote then -- emote channel gets special formatting
		xml:AddLine(strTime, crTime, strFontChat, "Left")
		strChatHistory = strChatHistory..strTime
		if strDisplayName:len() > 0 then
			if tMessage.bGM then
				xml:AppendImage(kstrGMIcon, 16, 16)
			end
			local strCross = tMessage.bCrossFaction and "true" or "false"--has to be a string or a number due to code restriction
			xml:AppendText(strDisplayName, crPlayerName, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId, strCrossFaction = strCross}, "Source")
			strChatHistory = strChatHistory..strDisplayName
		end
		xml:AppendText(" ")
	else 
		local strChannel = tShortNames[eChannelType]
		if eChannelType == ChatSystemLib.ChatChannel_Society then
		    strChannel = (string.format("%s ", String_GetWeaselString(Apollo.GetString("ChatLog_GuildCommand"), tQueuedMessage.strChannelName, tQueuedMessage.strChannelCommand))) --String DB removed empty characters at
			strChannel = string.gsub(strChannel, "%[", "")
			strChannel = string.gsub(strChannel, "%]", "")
			local strCh = string.upper(tQueuedMessage.strChannelCommand)
			local strCh = string.gsub(strCh, "%a", "")
			local nChannelNumber = tonumber(strCh)
			if nChannelNumber > 1 and nChannelNumber < 6 then
			    crChannel = tColorCircleChannel[nChannelNumber] --or self.arChatColor[eChannelType]
				crText = crChannel
			end
		end
		if eChannelType == ChatSystemLib.ChatChannel_Custom then
		    strChannel = tQueuedMessage.strChannelName
			local nChannelNumber = tonumber(string.upper(tQueuedMessage.strChannelCommand))
			if nChannelNumber > 1 and nChannelNumber < 6 then
			    crChannel = tColorCustomChannel[nChannelNumber] or self.arChatColor[eChannelType]
				crText = tColorCustomChannel[nChannelNumber] or self.arChatColor[eChannelType]
			end
		end
		if eChannelType == ChatSystemLib.ChatChannel_Society and strShortNamesCustom == "check" then
			strChannel = string.upper(tQueuedMessage.strChannelCommand) -- Workaround for circles
		end
		if eChannelType == ChatSystemLib.ChatChannel_Custom and strShortNamesCustom == "check" then
		    strChannel = string.upper(tQueuedMessage.strChannelCommand) -- Workaround for custom channels
		end
		strChannel = "["..strChannel.."] "
		if self.bShowChannel ~= true then
			strChannel = ""
		end
		for idx, tSegment in ipairs( tMessage.arMessageSegments ) do
		    if string.find(tSegment.strText, "MessagePratLite") ~= nil then strChannel = "" end
        end
		xml:AddLine("", crTime, strFontChat, "Left")
		if self.bShowTimestamp then
		    xml:AppendText(strTime, crTime, strFontChat, "Left")
	    end
		if tChannelLink[eChannelType] == "NoLink" or tChannelLink[eChannelType] == nil or tChannelLink[eChannelType] == "" then 
		    xml:AppendText(strChannel, crChannel, strFontChat)
			elseif tChannelLink[eChannelType] == "Custom" or tChannelLink[eChannelType] == "Society" then
			    xml:AppendText(strChannel, crChannel, strFontChat, {strChannelName = string.upper(tQueuedMessage.strChannelCommand)} , "Channel")
			else xml:AppendText(strChannel, crChannel, strFontChat, {strChannelName = tChannelLink[eChannelType]} , "Channel")
		end
		strChatHistory = strChatHistory..strTime..strChannel
		if strDisplayName:len() > 0 then
            local strWhisperNamePrefix = ""
			if eChannelType == ChatSystemLib.ChatChannel_Whisper or eChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
				if tMessage.bSelf then
					strWhisperNamePrefix = Apollo.GetString("ChatLog_To")
				else
					strWhisperNamePrefix = Apollo.GetString("ChatLog_From")
				end
			end
			xml:AppendText( strWhisperNamePrefix, crText, strFontChat)
			strChatHistory = strChatHistory..strWhisperNamePrefix
			if tMessage.bGM then
				xml:AppendImage(kstrGMIcon, 16, 16)
			end
			local strCross = tMessage.bCrossFaction and "true" or "false"
----------------------------- Plaer from someone else's realm --------------------------------
			if string.find(strDisplayName, "@") ~= nil then
			    local strCurrName = strDisplayName
	            strCurrName = string.gsub(strCurrName, "@Jabbit", "")
	            strCurrName = string.gsub(strCurrName, "@Luminai", "")
	            strCurrName = string.gsub(strCurrName, "@Entity", "")
	            strCurrName = string.gsub(strCurrName, "@Warhound", "")
	            strCurrName = string.gsub(strCurrName, "%@%S+", "")  
		        strPlayerRealm = string.gsub(strDisplayName, strCurrName, "")
				strDisplayName = strCurrName
	        end
---------------------------------------- read Data Players ------------------------------
			if tPlayerInfo[strDisplayName] ~= nil then
			local infoPlayer = tPlayerInfo[strDisplayName]
			    crPlayerName = tClassColors[infoPlayer.c]
				nLevel = tonumber(infoPlayer.l) or 0
				if strPathIconDisplay == "show" then
				    strPathToIcon = tPathToIcon[infoPlayer.p]
				end
				if nLevel ~= nil then
				    if nLevel < 40 then
				    crLevelColor = "ff888888"
				    elseif nLevel < 50 then
					crLevelColor = "xkcdSilver"
				    else crLevelColor = "xkcdGoldenrod"
                    end
				else nLevel = 0
				end
				if strLeaderGroupName == strDisplayName then
				xml:AppendImage("ClientSprites:GroupLeaderIcon", 16, 16)
				end
				if strLeaderGuildName == strDisplayName then
                    xml:AppendImage("icon_Guild_Medium")	
                end				
			end
			strChatHistory = strChatHistory.."["
----------------------------------------------------------------------	
			xml:AppendText("[", "white", strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			if nLevel ~= 0 then
			    strChatHistory = strChatHistory.. nLevel..":"
			    xml:AppendText( nLevel, crLevelColor, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
				xml:AppendText(":", crChannel, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			end
			strChatHistory = strChatHistory..strDisplayName
			xml:AppendText( strDisplayName, crPlayerName, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			if strPlayerRealm ~= "" or strPlayerRealm ~= nil then
			    local strPRN = strDisplayName..strPlayerRealm
				local crPlayerRealm = ApolloColor.new("ChatPlayerName")
			    strChatHistory = strChatHistory..strPlayerRealm
			    xml:AppendText( strPlayerRealm, crPlayerRealm, strFontChat, {strCharacterName = strPRN, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			end
			if eChannelType == ChatSystemLib.ChatChannel_AccountWhisper then
			    strChatHistory = strChatHistory..strDisplayNameAcc
			    local crPlayerNameAcc = ApolloColor.new("ChatPlayerName")
			    xml:AppendText( strDisplayNameAcc, crPlayerNameAcc, strFontChat, {strCharacterName = strDisplayNameAcc, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			end
		    xml:AppendImage(strPathToIcon, 16, 16)
			strChatHistory = strChatHistory.."]"
------------------------------------------------------------------------------------------------
			xml:AppendText("]", "white", strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
			xml:AppendText(":", crChannel, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId , strCrossFaction = strCross}, "Source")
		end
		xml:AppendText( strPresenceState .. " ", crChannel, strFontChat, "Left")
	end
    nLevel = 0
	strPathToIcon = ""
	crPlayerName = ApolloColor.new("ChatPlayerName")
	local xmlBubble = nil
	if tMessage.bShowChatBubble then
		xmlBubble = XmlDoc.new() -- This is the speech bubble form
		xmlBubble:AddLine("", crChannel, strFontChat, "Center")
	end
	local bHasVisibleText = false
	for idx, tSegment in ipairs( tMessage.arMessageSegments ) do
	    local bBuble = true
		local strText = tSegment.strText
		local bAlien = tSegment.bAlien or tMessage.bCrossFaction
		local bShow = false
		if self.eRoleplayOption == 3 then
			bShow = not tSegment.bRolePlay
		elseif self.eRoleplayOption == 2 then
			bShow = tSegment.bRolePlay
		else
			bShow = true;
		end
		if bShow and strText:len() > 0 then
			local crChatText = crText;
			local crBubbleText = crChatText
			local strBubbleFont = kstrBubbleFont
			local tLink = {}
            
			if tSegment.uItem ~= nil then -- item link
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uItem:GetName())
				crChatText = karEvalColors[tSegment.uItem:GetItemQuality()]
				crBubbleText = ApolloColor.new("white")
				tLink.strText = strText
				tLink.uItem = tSegment.uItem
				local id = tSegment.uItem:GetItemId()
				local strLinkIndex = tostring(self:HelperSaveLink(tLink))
				CurrIndex[Item.GetIcon(id)] = strLinkIndex
				xml:AppendText(" [", crChatText, strFontChat, {strIndex=strLinkIndex}, "Link")
				xml:AppendImage(Item.GetIcon(id), 16, 16)
				xml:AppendText("]", crChatText, strFontChat, {strIndex=strLinkIndex}, "Link")
				if eChannelType == ChatSystemLib.ChatChannel_Loot and bLootText == false then strText = "" end
				if xmlBubble then bBuble = false
				    xmlBubble:AppendImage(Item.GetIcon(id), 36, 36)
				end
                if bMute == false then Sound.Play(84) end
			elseif tSegment.uQuest ~= nil then -- quest link
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uQuest:GetTitle())-- replace me with correct colors
				crChatText = ApolloColor.new("green")
				crBubbleText = ApolloColor.new("green")
				tLink.strText = strText
				tLink.uQuest = tSegment.uQuest
			elseif tSegment.uArchiveArticle ~= nil then -- archive article
				strText = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), tSegment.uArchiveArticle:GetTitle())-- replace me with correct colors
				crChatText = ApolloColor.new("ffb7a767")
				crBubbleText = ApolloColor.new("ffb7a767")
				tLink.strText = strText
				tLink.uArchiveArticle = tSegment.uArchiveArticle
			else
				if tSegment.bRolePlay then
					crBubbleText = "ff58e3b0"
				end
				if tSegment.bProfanity then -- Weak filter. Note only profanity is scrambled.
					strText = "!@#$%^"
					crChatText = ApolloColor.new("xkcdBloodOrange")
				end
			end
			if strText ~= nil or strText ~= "" then
			    strChatHistory = strChatHistory.." "..strText
			end
			strChatHistory = string.gsub(strChatHistory, "\n", "")
			if strChatHistory:len() > 6 then 
			    tChatHistory[nNumberLine] = strChatHistory
			    if nNumberLine >= nLimitHistory then 
			        for i = 2, nLimitHistory do
				        tChatHistory[i-1] = tChatHistory[i]
				    end
			    else nNumberLine = nNumberLine + 1
			    end
			end
		    strChatHistory = ""
			--[[ if string.find(strText, "pl_link") ~= nil then strText = string.gsub(strText, "pl_link", "")
			    xml:AppendText("["..strText.."] ", "ff00c8ff", strFontChat, {strUrl=strLink} , "URL")
			    strText = ""
			end ]]
----------------------------- World Boss -------------------------------------------------------
			if bAlertWB == true and (eChannelType == ChatSystemLib.ChatChannel_Society or eChannelType  == ChatSystemLib.ChatChannel_Custom or eChannelType  == ChatSystemLib.ChatChannel_Zone or eChannelType  == ChatSystemLib.ChatChannel_Guild) and strDisplayName ~=strUnitPlayerName then
			    local tWorldBossAbbreviation = { "World Boss", "world boss", "/75", "Metal", "Maw", "MM", "Maw", "Dreamspore", "DS", "Spore", "Kraggar", "Grendelus", "Guardian", "King", "Honeygrave", "KH", "Bee", "Honey", "King", "Plush", "KP", "Metal", "Maw", "Prime", "MMP", "mmp", "Mechathorn", "Mecha", "Thorn", "Gargantua", "Garg", "Scorchwing", "WorldBoss", "WB"}
			    local tJoin = { "join", "beitreten", "rejoindre" }
			    for _, name in pairs(tJoin) do
			        if string.find(string.lower(strText), string.lower(name)) ~= nil then
				        for _,abbreviation in pairs(tWorldBossAbbreviation) do
					        if string.find(strText, abbreviation) ~= nil then 
                                if bAnimation == true then xml:AppendImage("PratLiteWorldBoss") else xml:AppendImage("PratLiteWorldBossImage") end
								local strImg = "PratLiteWorldBoss"
								    if nRequestWB[strDisplayName] == nil then
								    nRequestWB[strDisplayName]  = 1
								    if bMute == false and bSoundAnimation == true then Sound.Play(141)  end --175, 216
								elseif nRequestWB[strDisplayName] < 3 then nRequestWB[strDisplayName] = nRequestWB[strDisplayName] + 1
								    if bMute == false and bSoundAnimation == true then Sound.Play(141) end  --175, 216
								else nRequestWB[strDisplayName] = nRequestWB[strDisplayName] + 1
								    if nRequestWB[strDisplayName] > 6 then  nRequestWB[strDisplayName]  = 1 end
								end
						        break
						    end
					    end
				        break
				    end
			    end
			end
---------------------------------- Formating Loot ----------------------------------------------
			if eChannelType == ChatSystemLib.ChatChannel_Loot and tSegment.uItem == nil then
			    local tCurrency = {
				    ["CRB_Renown"]                    = "icon_Renown",-- Известность
				    ["Renown"]                        = "icon_Renown",
                    ["CRB_Elder_Gems"]                = "icon_Elder_Gems",-- Древние самоцветы
                    ["Elder Gem"]                     = "icon_Elder_Gems",
					["CRB_Glory"]                     = "icon_Glory",-- Слава
					["Glory"]                         = "icon_Glory",
				    ["CRB_Prestige"]                  = "icon_Prestige",-- Престиж
				    ["Prestige"]                      = "icon_Prestige",
					["CRB_Crafting_Vouchers"]         = "icon_Crafting_Vouchers", -- Ваучеры
					["Crafting Vouchers"]             = "icon_Crafting_Vouchers", 
					["Vouchers"]                      = "icon_Crafting_Vouchers", 
				    ["CRB_OmniBits"]                  = "icon_OmniBits", -- Омничастицы
				    ["AccountInventory_OmniBits"]     = "icon_OmniBits", 
				    ["OmniBit"]                       = "icon_OmniBits",
					["AccountInventory_ServiceToken"] = "icon_ServiceToken", -- Жетон услуг
					["Service Token"]                 = "icon_ServiceToken", 
					["CRB_FortuneCoin"]               = "icon_FortuneCoin", -- Монета судьбы
					["Fortune Coin"]                  = "icon_FortuneCoin",
					["Platine"]		        		  = "CRB_CurrencySprites:sprCashPlatinum",  
				    ["CRB_Platinum"]				  = "CRB_CurrencySprites:sprCashPlatinum", -- Платина 
				    ["Platinum"]                      = "CRB_CurrencySprites:sprCashPlatinum", 
				    ["CurrencyString_Gold"]           = "CRB_CurrencySprites:sprCashGold", -- Золото
				    ["CRB_Gold"]                      = "CRB_CurrencySprites:sprCashGold",
				    ["Gold"]                          = "CRB_CurrencySprites:sprCashGold",
				    ["CRB_Silver"]                    = "CRB_CurrencySprites:sprCashSilver", --Серебро
				    ["Argent"]                        = "CRB_CurrencySprites:sprCashSilver",
				    ["Silver"]                        = "CRB_CurrencySprites:sprCashSilver",
				    ["CRB_Copper"]                    = "CRB_CurrencySprites:sprCashCopper", --Медь
				    ["Cuivre"]                        = "CRB_CurrencySprites:sprCashCopper", 
				    ["Copper"]                        = "CRB_CurrencySprites:sprCashCopper" }
				local tNameCurrency = {"CRB_Renown","Renown","CRB_Elder_Gems","Elder,Gem","CRB_Glory","Glory","CRB_Prestige","Prestige","CRB_Crafting_Vouchers","Crafting,Vouchers","CRB_OmniBits","AccountInventory_OmniBits","OmniBit","AccountInventory_ServiceToken","Service,Token","CRB_FortuneCoin","Fortune,Coin","Platine","CRB_Platinum","Platinum","CurrencyString_Gold","CRB_Gold","Gold","Argent","CRB_Silver","Silver","Cuivre","CRB_Copper","Copper"}
				if bRus == true then strText = FixPunctuation(strText) end
			    for idx,name in pairs(tNameCurrency) do
				    local strCurrency = Apollo.GetString(name)
					strCurrency = string.gsub(strCurrency, "1c", "")
					strCurrency = string.gsub(strCurrency, "#", "")
					strCurrency = string.gsub(strCurrency, ":", "")
					strCurrency = string.gsub(strCurrency, "%$", "")
					strCurrency = string.gsub(strCurrency, " ", "")
					for Link in string.gmatch(strText, strCurrency) do
                        local n = 0
                        local strText1 = ""
                        local strText2 = ""
                        local strLink = Link
	                    for word in string.gmatch(string.gsub(strText, ",", ""), "%S+") do
			            local strWord = word
		                    if n == 1 then
							    if strText2 == "" then strText2 = strWord
                                else strText2 = strText2.." "..strWord
								end
				            end
	                        if strWord ~= strLink and n == 0 then
							    if strText1 == "" then strText1 = strWord
								else strText1 = strText1.." "..strWord
								end
			                else n = 1
			    	        end
	                    end
	                xml:AppendText(strText1, crChatText, strFontChat)
					xml:AppendImage(tCurrency[name], 16, 16)
		            xml:AppendText(" ", "ff00c8ff", strFontChat)
		            strText = strText2
                    end				
	            end
			end
-----------------------------------------------------------------------------------------------------------------------
			if string.find(strText, "You are now 'away from keyboard.'") ~= nil then    -- on/afk
		        ChatSoundPL = nFriendOutSound
			    crChatText = "ffd0ff00"
				strText = "You are now 'away from keyboard.'"
	            if bRus == true then strText = "Вы отошли от клавиатуры, оставив сообщение <afk>" end
				ChatSystemLib.Command("/update")
			end
			if string.find(strText, Apollo.GetString("Friends_NoLongerAway")) ~= nil or string.find(strText, "You are no longer 'away from keyboard.'") ~= nil then    
			    ChatSoundPL = nFriendInSound
			    crChatText = "ffd0ff00"
				strText = Apollo.GetString("Friends_NoLongerAway")
	            if bRus == true then strText = "Вы вернулись к игре" end
			end
            if eChannelType == ChatSystemLib.ChatChannel_Debug and string.find(strText, "%d+%smin%p%s%d+%ssec") ~= nil then crChatText = "FFFFE46E" end
-------------------------- The mention of the Nickname in text -------------------------------
            if strNicknameChat == "check" and strText:len() > 2 and (eChannelType == 4 or eChannelType == 5 or eChannelType == 6 or eChannelType == 7 or eChannelType == 9 or eChannelType == 10 or eChannelType == 11 or eChannelType == 15 or eChannelType == 16 or eChannelType == 17 or eChannelType == 18 or eChannelType == 31 or eChannelType == 33 or eChannelType == 34) then
			    if  string.find(string.lower(strText), string.lower(strUnitPlayerName)) ~= nil then
		            if bAnimation == true then xml:AppendImage("PratLiteYourName") else xml:AppendImage("PratLiteYourNameImage") end
		            if bMute == false and bSoundAnimation == true then Sound.Play(222) end
                else local n = 0 
				    for PartNickname in string.gmatch(strUnitPlayerName, "%S+") do
			            if PartNickname:len() > 3 then
						    for word in string.gmatch(strText, "%S+") do
							    local strWord = word
					            strWord = string.gsub(strWord, "%c", "")
					            strWord = string.gsub(strWord, "%p", "")
						        if string.lower(strWord) == string.lower(PartNickname) then
								   if bAnimation == true then xml:AppendImage("PratLiteYourName") else xml:AppendImage("PratLiteYourNameImage") end
		   	                       if bMute == false and bSoundAnimation == true then Sound.Play(222) end
								   n = 1
				    	           break 
			                    end
                            end
                        end
                        if n ~= 0 then break end					
                    end
                end					
            end
---------------------------------------------------------------------------------------------------------------------------------
		 	if string.find(strText, "MessagePratLite") ~= nil then
			    if bFirstInput == true then strText = ""
			        bFirstInput = false
			        xml:AppendText(" \n", "xkcdGoldenrod", "ArialUnicodeMS_10")
				    xml:AppendImage("PratLiteBlow")
				    xml:AppendText(" \n", "xkcdGoldenrod", "xkcdGoldenrod", "CRB_Pixel")
				    if bRus == true then
				        xml:AppendImage("PratLite_Options_RU")
		    			xml:AppendImage("abilities:sprAbility_Frame", 20, 28)
			    		xml:AppendImage("PratLite_Description_RU") 
				    else 
    				    xml:AppendImage("PratLite_Options")
	    				xml:AppendImage("abilities:sprAbility_Frame", 20, 28)
		    			xml:AppendImage("PratLite_Description")
			    	end
				    if strPlayerGuild ~= "" then
					crChatText = "FFAAFF00"
					xml:AppendText(" \n <"..strPlayerGuild..">", "FF3B31FF", "CRB_Interface14_BBO")
				    strFontChat = "CRB_Interface12_BBO"
					xml:AppendText(" \n", "FF3B31FF", strFontChat)
					strText = MessageOfTheDay
				    end
				    ChatSoundPL = 255
				else 
				    ChatSoundPL = 0
			        strText = ""
				end
			end
--------------------------------------- URL ----------------------------------
			if strText:len() > 4 and (eChannelType == 4 or eChannelType == 5 or eChannelType == 6 or eChannelType == 7 or eChannelType == 9 or eChannelType == 10 or eChannelType == 11 or eChannelType == 15 or eChannelType == 16 or eChannelType == 17 or eChannelType == 18 or eChannelType == 25 or eChannelType == 31 or eChannelType == 33 or eChannelType == 34) then
			    for idx, pattern in pairs(patterns) do
				    for Link in string.gmatch (strText, pattern) do
                    local n = 0
                    local strText1 = ""
                    local strText2 = "" 
                    local strLink = Link
	                    for word in string.gmatch(strText, "%S+") do
			            local strWord = word
		                    if n == 1 then 
                                strText2 = strText2..strWord.." "
				            end
	                        if strWord ~= strLink and n == 0 then 
    		                    strText1 = strText1..strWord.." "
			                else n = 1
			    	        end
	                    end
	                xml:AppendText(strText1, crChatText, strFontChat)
		            xml:AppendText("["..strLink.."] ", "ff00c8ff", strFontChat, {strUrl=strLink} , "URL")
					if xmlBubble then
				        if bBuble then xmlBubble:AppendText(strText1, crBubbleText, strBubbleFont) end
				        xmlBubble:AppendText("["..strLink.."] ", "ff00c8ff", strBubbleFont)
			        end
		            strText = strText2
		   	        if bMute == false then Sound.Play(nLinkSound) end
                    end				
	            end
			end
------------------------------------- Allocation of NickNames from text --------------------------
            if eChannelType == ChatSystemLib.ChatChannel_Guild or eChannelType == ChatSystemLib.ChatChannel_Society or eChannelType == ChatSystemLib.ChatChannel_System then
                local tGuildAlert = {
		    	    ["GuildResult_MemberOffline"] = nOutInGuildSound,
			    	["Friends_HasGoneOffline"] = nOutInGuildSound,
			        ["GuildResult_MemberOnline"] = nOutInGuildSound,
	    			["Friends_HasComeOnline"] = nOutInGuildSound,
		    	    ["Guild_InviteAccepted"] = nEntryGuldSound,
			        ["Guild_Kicked"] = 84,
					["Group_CharacterKicked"] = 89,
                    ["Guild_Quit"] = nFriendOutSound,
	    			[" присоединился к гильдия."] = nEntryGuldSound}
		    	for name, data in pairs(tGuildAlert) do
			    	local strAlert = string.gsub(Apollo.GetString(name), "$1n", "")
				    strAlert = string.gsub(strAlert, "%%%w", "")
				    strAlert = string.gsub(strAlert, "%#", "")
				    if string.find(strText, strAlert) then
				        strText = string.gsub(strText, strAlert, "")
    					if tPlayerInfo[strText] ~= nil then
	    			        local infoPlayer = tPlayerInfo[strText]
		    	            crPlayerName = tClassColors[infoPlayer.c]
			    	        nLevel = tonumber(infoPlayer.l) or 0
				    	    if strPathIconDisplay == "show" then
					            strPathToIcon = tPathToIcon[infoPlayer.p]
				   	        end
    					    if nLevel ~= nil then
	    				        if nLevel < 40 then
		    			            crLevelColor = "ff888888"
			    		        elseif nLevel < 50 then
				    		        crLevelColor = "xkcdSilver"
				            	else crLevelColor = "xkcdGoldenrod"
    	                    	end
						    else nLevel = 0
						    end
					    end
			    	    xml:AppendText("[", "white", strFontChat,  {strUrl=strText} , "URL")
			    	    if nLevel ~= 0 then
			        	    xml:AppendText( nLevel, crLevelColor, strFontChat, {strUrl=strText} , "URL")
				    	    xml:AppendText(":", crChannel, strFontChat, {strUrl=strText} , "URL")
			    	    end
    				   	xml:AppendText( strText, crPlayerName, strFontChat, {strUrl=strText} , "URL")
	    		       	xml:AppendImage(strPathToIcon, 16, 16)
		    		   	xml:AppendText("] ", "white", strFontChat, {strUrl=strText} , "URL")
			    		strText = strAlert
		    	    	crChatText = "8800ff00"
			    	    ChatSoundPL = tGuildAlert[name]
    			    	if eChannelType == ChatSystemLib.ChatChannel_System then crChatText = "ffd0ff00"
                            if name == "Friends_HasGoneOffline" or name == "GuildResult_MemberOffline" then ChatSoundPL = nFriendOutSound
		    				    strText = string.gsub(Apollo.GetString("GuildResult_MemberOffline"), "$1n", "")
			    	            strText = string.gsub(strText, "%%%w", "")
				    		else ChatSoundPL = nFriendInSound
					    	    strText = string.gsub(Apollo.GetString("GuildResult_MemberOnline"), "$1n", "")
				                strText = string.gsub(strText, "%%%w", "")
					    	end
	    	    	    end
					    break
				    end
			    end
			end
--------------------------------------------------------------------------------------------------------
			if next(tLink) == nil then
				if eChannelType == ChatSystemLib.ChatChannel_AnimatedEmote then
					local strCross = tMessage.bCrossFaction and "true" or "false"--has to be a string or a number due to code restriction
					xml:AppendText(strText, crChatText, strFontChat, {strCharacterName = strWhisperName, nReportId = tMessage.nReportId, strCrossFaction = strCross}, "Source")
				else
					xml:AppendText(strText, crChatText, strFontChat)
				end 
			else
				local strLinkIndex = tostring( self:HelperSaveLink(tLink))
				xml:AppendText(strText, crChatText, strFontChat, {strIndex=strLinkIndex} , "Link")
			end
			if xmlBubble and bBuble then
				xmlBubble:AppendText(strText, crBubbleText, strBubbleFont) -- Format for bubble; regular
			end
			bHasVisibleText = bHasVisibleText or self:HelperCheckForEmptyString(strText)
		end
	end
	tQueuedMessage.bHasVisibleText = bHasVisibleText
	tQueuedMessage.xml = xml
	tQueuedMessage.xmlBubble = xmlBubble
	if ChatSoundPL ~= nil and ChatSoundPL ~= 0  then
	    if bMute == false then Sound.Play(ChatSoundPL) end
	    ChatSoundPL = 0
	end
end
                     --------------------------------- Options ------------------------------
function PratLite:OnGotOn()
	self:SetupLoadFormList()
    local curr, hud	
	local count = 0
    for curr, hud in cassPkg.spairs(tOptionChannels,function(t,a,b) return t[b].name > t[a].name end) do
		count = count + 1
		if count == 1 then	
			self:SetupLoadForm(curr)
		end
	end
	self.wndMain:ToFront()
	self.wndMain:Show(true,true)
	self.wndHistory:Show(false)
    self.wndPaste:Show(false)
	self.wndChannel:Show(false)
    self.wndInstruction:Show(false)
	self.wndSound:Show(false)
end

function PratLite:SetupLoadFormList()
	wndGrid = self.wndMain:FindChild("Grid_Channel")
	wndGrid:DeleteAll()
	for name, hud in cassPkg.spairs(tOptionChannels,function(t,a,b) return t[b].name > t[a].name end) do
		local strName = "Channel '"..name.."' ["..hud.name.."]"
		if bRus == true then self:OnTitleRu()
		    strName = "Канал '"..tChannelsRU[name].."' ["..hud.name.."]"
		end
		local text = wndGrid:AddRow(name)
		wndGrid:SetCellDoc(text, 1, "<T TextColor=\""..hud.color.."\">"..strName.."</T>")
	end
	self.wndMain:FindChild("EditorFrame"):Enable(wndGrid:GetRowCount() > 0)
end

function PratLite:OnChannelClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, iRow )
	wndGrid = self.wndMain:FindChild("Grid_Channel")
	local row = wndGrid:GetCurrentRow()
	if row ~= nil and row <= wndGrid:GetRowCount() then
		local curr = wndGrid:GetCellText(row)
		self:SetupLoadForm(curr)
		self.wndSound:Show(false)
	end
end

function PratLite:OnSoundClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, iRow )
    local wndGridSound = self.wndSound:FindChild("Grid_Sound")
    local row = wndGridSound:GetCurrentRow()
	if row ~= nil and row <= wndGridSound:GetRowCount() then
		local tone = wndGridSound:GetCellText(row)
		nSelectedSound = tone
		if bMute == false then Sound.Play(tone) end
	end
end

function PratLite:OnSignalButtons()
    if self.wndMain:FindChild("Button_ShortNames"):IsChecked() then strShortNamesCustom = "check"
    else strShortNamesCustom = "uncheck"
    end
    if self.wndMain:FindChild("Button_NicknameChat"):IsChecked() then strNicknameChat = "check"
    else strNicknameChat = "uncheck"
    end
    if self.wndMain:FindChild("Button_ShowPathIcon"):IsChecked() then strPathIconDisplay = "show"
    else strPathIconDisplay = "true"
    end
    if self.wndMain:FindChild("Button_ LinkURL"):IsChecked() then nLinkSound = 251
    else nLinkSound = 0
    end
    if self.wndMain:FindChild("Button_ MessageInput"):IsChecked() then bMessageInput = true
    else bMessageInput = false
    end
    if self.wndMain:FindChild("Button_Animation"):IsChecked() then bAnimation = true
    else bAnimation = false
    end
    if self.wndMain:FindChild("Button_ LFM"):IsChecked() then bLFM = true
    else bLFM = false
    end
    if self.wndMain:FindChild("Button_Mute"):IsChecked() then bMute = true
    else bMute = false
    end
	if self.wndMain:FindChild("Button_SoundAnimation"):IsChecked() then bSoundAnimation = true
    else bSoundAnimation = false
    end 
	if self.wndMain:FindChild("Button_ LootText"):IsChecked() then bLootText = true
    else bLootText = false
    end  
	if self.wndMain:FindChild("Button_Whisper"):IsChecked() then self.bToWhisper = true
    else self.bToWhisper = false
    end     
end

function PratLite:OnCheckChannel()
	self.wndMain:FindChild("Number1"):SetCheck(nCustomChannelCheck == 1)
	self.wndMain:FindChild("Number2"):SetCheck(nCustomChannelCheck == 2)
	self.wndMain:FindChild("Number3"):SetCheck(nCustomChannelCheck == 3)
	self.wndMain:FindChild("Number4"):SetCheck(nCustomChannelCheck == 4)
	self.wndMain:FindChild("Number5"):SetCheck(nCustomChannelCheck == 5)
end

function PratLite:OnButtonNumber()
    if self.wndMain:FindChild("Number1"):IsChecked() then
	    nCustomChannelCheck = 1
    elseif self.wndMain:FindChild("Number2"):IsChecked() then
	    nCustomChannelCheck = 2
    elseif self.wndMain:FindChild("Number3"):IsChecked() then
	    nCustomChannelCheck = 3
    elseif self.wndMain:FindChild("Number4"):IsChecked() then
	    nCustomChannelCheck = 4
    elseif self.wndMain:FindChild("Number5"):IsChecked() then
	    nCustomChannelCheck = 5
	end
	self:SetupLoadForm(self.editPL)
end

function PratLite:OnVolumeSliderBar(wndHandler, wndControl, fValue)
	if bMute == false then Sound.Play(192) end
    Apollo.SetConsoleVariable("sound.volumeUI", fValue)
	self.wndMain:FindChild("Volume"):SetText(math.modf(Apollo.GetConsoleVariable("sound.volumeUI")*100))
	nChime = nChime + 1
end

function PratLite:SetupLoadForm(curr)
    if bMute == false then Sound.Play(77) end
    self.editPL = curr
	Event_FireGenericEvent("GenericEvent_OnChannelsNames", tColorCustomChannel, tColorCircleChannel)
	self.supertimer = ApolloTimer.Create(3, true, "OnUpdateButtonPanel", self)
	CurrentChannel = tOptionChannels[curr]
	local strCurrentColor = CurrentChannel.color
	local strPrefix1 = ""
	local strNameEdit = CurrentChannel.name
	self.wndMain:FindChild("NumberChannel"):Show(false)
	if curr == "Custom" then
	    self.wndMain:FindChild("NumberChannel"):Show(true)
		self:OnCheckChannel()
		strPrefix1 = " ["..nCustomChannelCheck.."]"
		strNameEdit = strPrefix1
		if nCustomChannelCheck > 1 then
		strCurrentColor = tColorCustomChannel[nCustomChannelCheck]
		end
	end
	if curr == "Society" then
	    self.wndMain:FindChild("NumberChannel"):Show(true)
		self:OnCheckChannel()
		strPrefix1 = " [С"..nCustomChannelCheck.."]"
		strNameEdit = strPrefix1
		if nCustomChannelCheck > 1 then
		strCurrentColor = tColorCircleChannel[nCustomChannelCheck]
		end
	end
	local fValue = Apollo.GetConsoleVariable("sound.volumeUI")
	local strReview = " ["..CurrentChannel.name.."] Channel name '"..curr.."'"..strPrefix1.."..."
	self.wndMain:FindChild("Volume"):SetText(math.modf(fValue*100))
	self.wndMain:FindChild("VolumeSliderBar"):SetValue(fValue)
	self.wndMain:FindChild("TextChat"):SetText(strReview)
	self.wndMain:FindChild("TextChat"):SetTextColor(strCurrentColor)
	self.wndMain:FindChild("ClockChat"):SetTextColor(strColorClock)
	self.wndMain:FindChild("EditBox_Name"):SetText(strNameEdit)
	self.wndMain:FindChild("EditBox_Name"):SetTextColor(strCurrentColor)
	self.wndMain:FindChild("Button_Animation"):SetCheck(bAnimation == true)
	self.wndMain:FindChild("Button_Mute"):SetCheck(bMute == true)
	self.wndMain:FindChild("Button_ShortNames"):SetCheck(strShortNamesCustom == "check")
	self.wndMain:FindChild("Button_NicknameChat"):SetCheck(strNicknameChat == "check")
	self.wndMain:FindChild("Button_ShowPathIcon"):SetCheck(strPathIconDisplay == "show")
	self.wndMain:FindChild("Button_ LinkURL"):SetCheck(nLinkSound == 251)
    self.wndMain:FindChild("Button_ MessageInput"):SetCheck(bMessageInput == true)
    self.wndMain:FindChild("Button_ LFM"):SetCheck(bLFM == true)
    self.wndMain:FindChild("Button_SoundAnimation"):SetCheck(bSoundAnimation == true)
    self.wndMain:FindChild("Button_ LootText"):SetCheck(bLootText == true)
    self.wndMain:FindChild("Button_Whisper"):SetCheck(self.bToWhisper == true)
	comboColorText = self.wndMain:FindChild("ComboBox_ColorText")
	comboColorText:DeleteAll()
	for _,color in cassPkg.spairs(tColorData,function(t,a,b) return t[b] > t[a] end) do
	   local text = comboColorText:AddItem(color)
	   local coloring = ApolloColor.new(color):ToTable()
	   comboColorText:SetCellTextColor(text,0,CColor.new(coloring.r, coloring.g, coloring.b))
	end
	comboColorText:FindChild("CurrentColorText"):SetBGColor(strCurrentColor)
	comboColorClock = self.wndMain:FindChild("ComboBox_ColorClock")
	comboColorClock:DeleteAll()
	for _,color in cassPkg.spairs(tColorData,function(t,a,b) return t[b] > t[a] end) do
	   local text = comboColorClock:AddItem(color)
	   local coloring = ApolloColor.new(color):ToTable()
	   comboColorClock:SetCellTextColor(text,0,CColor.new(coloring.r, coloring.g, coloring.b))
	end
	comboColorClock:FindChild("CurrentColorClock"):SetBGColor(strColorClock)
	nCurrentSound = CurrentChannel.sound
	local srtTextCurrent = "Current sound:"
	if bRus == true then srtTextCurrent = "Текущий звук:" end
	local strSoundText = srtTextCurrent.." Tone "..nCurrentSound
	if nCurrentSound == 0 then 
	    strSoundText = srtTextCurrent.." No sound"
	end
	self.wndMain:FindChild("ButtonSelectSound"):SetText(strSoundText)
	local gameFonts = Apollo.GetGameFonts()
	comboTextFont = self.wndMain:FindChild("ComboBox_TextFont")
	comboTextFont:DeleteAll()
	for _,font in cassPkg.spairs(gameFonts,function(t,a,b) return t[b].name > t[a].name end) do 
		if not comboTextFont:HasItem(font.name) then
		    if bRus == true then 
			    if string.find(font.name, "CRB_Interface") ~= nil or string.find(font.name, "Courier") ~= nil or string.find(font.name, "Dialog") ~= nil or string.find(font.name, "Default") ~= nil or string.find(font.name, "Pixel") ~= nil then 
				    comboTextFont:AddItem(font.name)
				end
			else 
			    comboTextFont:AddItem(font.name) 
			end
		end
	end
	comboTextFont:FindChild("CurrentFont"):SetText(strFontChatSetting)
end

function PratLite:OnColorTextChanged( wndHandler, wndControl )
	local curr = self.editPL
    if curr == "Custom" and nCustomChannelCheck > 1 then
	    tColorCustomChannel[nCustomChannelCheck] = comboColorText:GetSelectedText()
	    Print(" Changing color channel ["..nCustomChannelCheck.."]...")
	    self:SetupLoadForm(curr)
    elseif curr == "Society" and nCustomChannelCheck > 1 then
	    tColorCircleChannel[nCustomChannelCheck] = comboColorText:GetSelectedText()
	    Print(" Changing color channel [C"..nCustomChannelCheck.."]...")
	    self:SetupLoadForm(curr)
    else CurrentChannel.color = comboColorText:GetSelectedText()
	    Print(" Changing colors channel ["..curr.."]...")
	    self:SetupLoadFormList(curr)
	    self:SetupLoadForm(curr)
	end
end

function PratLite:OnUpdateButtonPanel()
    Event_FireGenericEvent("GenericEvent_OnChannelsNames", tColorCustomChannel, tColorCircleChannel)
	self.supertimer = nil
end

function PratLite:OnChangeSound( wndHandler, wndControl )
    CurrentChannel.sound = nSelectedSound
	self.wndSound:Show(false)
	if bMute == false then Sound.Play(nSelectedSound) end
	local curr = self.editPL
	self:SetupLoadForm(curr)
end

function PratLite:OnPlayCurrentSound()
    if nCurrentSound == nil or nCurrentSound == 0 then return end
    if bMute == false then Sound.Play(nCurrentSound) end
end

function PratLite:OnFrameSound()
    if self.wndSound:IsVisible() then
	    self.wndSound:Show(false)
	else self.wndSound:Show(true)
    	self.wndSound:FindChild("Grid_Sound"):DeleteAll()
    	for _,tone in cassPkg.spairs(tSoundData,function(t,a,b) return t[b] > t[a] end) do
	        local strPtefix = ""
			if tone == nCurrentSound then
			    strPtefix = " •"
			end
	    	local text = self.wndSound:FindChild("Grid_Sound"):AddRow(tone)
    		local strName = "Tone "..tone..strPtefix
	    	if tone == 0 then 
	    	    strName = "No sound"..strPtefix
	        end
		self.wndSound:FindChild("Grid_Sound"):SetCellDoc(text, 1, "<T TextColor=\"".."ChatCommand".."\">"..strName.."</T>")
	    end
	end
	if bMute == false then Sound.Play(241) end
end

function PratLite:OnColorClockChanged( wndHandler, wndControl )
    strColorClock = comboColorClock:GetSelectedText()
	local curr = self.editPL
	self:SetupLoadForm(curr)
end

function PratLite:OnButtonRestoreDefaultSettings( wndHandler, wndControl, eMouseButton )
    self:OnDefaultSetting()
    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, "PratLite: Reset settings to default!!!", "")
	strShortNamesCustom = "check"
    strNicknameChat = "check"
    strColorClock = "ff00ffa9"
    strPathIconDisplay = "show"
    strFontChatSetting = "Default"
	bAnimation = true
	bLFM = true
	bSoundAnimation = true
	bLootText = false
	self.bToWhisper = false
	bMute = false
	tColorCustomChannel = {[2] = "AttributeDexterity", [3] = "AlertOrangeYellow", [4] = "Amber", [5] = "AlertOrangeYellow"}
	tColorCircleChannel = {[2] = "ChatCircle2", [3] = "ChatCircle3", [4] = "ChatCircle4", [5] = "ChatCircle5", [6] = "ChatCircle5"}
    nLinkSound = 251
	bAlertWB = true
	bMessageInput = true
	self:OnGotOn()
	if bMute == false then Sound.Play(228) end
end

function PratLite:EditBox_NameChanged( wndHandler, wndControl, strText )
	self.wndMain:FindChild("EditorFrame"):ClearFocus()
	self.wndMain:FindChild("CancelButton"):SetFocus()
    if CurrentChannel.name ~= "NotEditable" then
    CurrentChannel.name = self.wndMain:FindChild("EditBox_Name"):GetText()
	end
	local curr = self.editPL
	self:SetupLoadFormList(curr)
	self:SetupLoadForm(curr)
end

function PratLite:OnFontChanged( wndHandler, wndControl )
	strFontChatSetting = self.wndMain:FindChild("ComboBox_TextFont"):GetSelectedText()
	local curr = self.editPL
	self:SetupLoadForm(curr)
end

function PratLite:OnTitleRu()
    self.wndMain:FindChild("RecreateButton"):SetText("Сброс настроек")
    self.wndMain:FindChild("TextText"):SetText("Текст:")
    self.wndMain:FindChild("TextFont"):SetText("Шрифт:")
    self.wndMain:FindChild("TextClock"):SetText("Часы:")
    self.wndMain:FindChild("TextEdit"):SetText("Изменить имя канала:")
    self.wndMain:FindChild("TitleSound"):SetText("Изменить звук:")
    self.wndMain:FindChild("Button_ShortNames"):SetText("        Короткое имя польз. каналов")
	self.wndMain:FindChild("Button_NicknameChat"):SetText("        Упоминание Вашего имени в чате")
	self.wndMain:FindChild("Button_ShowPathIcon"):SetText("        Значок 'Путь игрока'")
	self.wndMain:FindChild("Button_ LinkURL"):SetText("        Звук: URL")
	self.wndMain:FindChild("Button_ MessageInput"):SetText("        Логотип при входе")
	self.wndMain:FindChild("Button_ LFM"):SetText("        Звуковое оповещение 'вызов Поиск Группы'")
	self.wndMain:FindChild("Button_SoundAnimation"):SetText("        звук + анимация/значок")
	self.wndMain:FindChild("Button_Animation"):SetText("        Анимация в чате")
	self.wndMain:FindChild("Button_Animation"):SetTooltip("(Анимированные/Без анимации) иконки оповещения в сообщениях.")
	self.wndMain:FindChild("Button_Update"):SetText("         Обновление базы данных игроков.")
	self.wndMain:FindChild("Button_Mute"):SetText("       Отключить все звуки аддона!")
	self.wndMain:FindChild("Button_Plugins"):SetText("Вкл/Выкл плагины")
	self.wndMain:FindChild("Button_ LootText"):SetText("       Иконка лута + название")
	self.wndMain:FindChild("Button_ LootText"):SetTooltip("Добавляет к иконке дабычи - название добычи.")
	self.wndMain:FindChild("Button_Whisper"):SetText("       Окно 'Шепот': Вх+Исх / Вх (сообщения).")
	self.wndMain:FindChild("Button_Whisper"):SetTooltip("Открывать отдельное окно 'Шепот' при первом входящем или исходящем сообщених или только при входящем сообщении")
end

function PratLite:OnCancel()
	self.wndMain:Show(false) -- hide the window
	if bMute == false then Sound.Play(252) end
end
---------------------------------- Click Mouse Window Chat --------------------
function PratLite:OnNodeClick(wndHandler, wndControl, strNode, tAttributes, eMouseButton)
    local PratLiteAddon = Apollo.GetAddon("PratLite")
    local ktValidItemPreviewSlots = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [16] = true }
	if strNode == "IMG" and eMouseButton == GameLib.CodeEnumInputMouse.Left then
	    if tAttributes.Image == "PratLite_Description_RU" or tAttributes.Image == "PratLite_Description" then PratLiteAddon:OnInstruction() 
	    elseif tAttributes.Image == "PratLite_Options_RU" or tAttributes.Image == "PratLite_Options" then PratLiteAddon:OnConfigure()
		elseif tAttributes.Image == "PratLiteWorldBoss" or tAttributes.Image == "PratLiteWorldBossImage" then 
		    ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, "To join the group, press Ctrl + Alt + left click on the nickname in the chat window.", "")
	    end
	end
	if strNode == "Channel" and eMouseButton == GameLib.CodeEnumInputMouse.Left and tAttributes.strChannelName then
	    local strOut = tAttributes.strChannelName
		Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
	end
	if strNode == "Source" and eMouseButton == GameLib.CodeEnumInputMouse.Right and tAttributes.strCharacterName and tAttributes.strCrossFaction and not Apollo.IsAltKeyDown() then
		local bCross = tAttributes.strCrossFaction == "true"
		local nReportId = nil
		if tAttributes ~= nil and tAttributes.nReportId ~= nil then
			nReportId = tAttributes.nReportId
		end
		local tOptionalData = {nReportId = tAttributes.nReportId, bCrossFaction = bCross}
		Event_FireGenericEvent("GenericEvent_NewContextMenuPlayer", wndHandler, tAttributes.strCharacterName, nil, tOptionalData)
		return true
	end
	if strNode == "Source" and eMouseButton == GameLib.CodeEnumInputMouse.Right and tAttributes.strCharacterName and tAttributes.strCrossFaction and Apollo.IsAltKeyDown() then
		ChatSystemLib.Command("/ginvite".." "..tAttributes.strCharacterName)
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Emote, "Guild Invitation sent ["..tAttributes.strCharacterName.."]", "")
		if bMute == false then Sound.Play(175) end
	end
	if (strNode == "Link" or (strNode == "IMG" and CurrIndex[tAttributes.Image] ~=nil)) and eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local nIndex = tonumber(tAttributes.strIndex)
		if strNode  == "IMG" then nIndex = tonumber(CurrIndex[tAttributes.Image]) end
		if self.tLinks[nIndex] and ( self.tLinks[nIndex].uItem or self.tLinks[nIndex].uQuest or self.tLinks[nIndex].uArchiveArticle or self.tLinks[nIndex].tNavPoint ) then
			if Apollo.IsShiftKeyDown() then
				local wndEdit = self:HelperGetCurrentEditbox()
				if wndEdit then
					self:HelperAppendLink( wndEdit, self.tLinks[nIndex] )
				end
			else
				if self.tLinks[nIndex].uItem then
					local bWindowExists = false
					if self.twndItemLinkTooltips == nil then self.twndItemLinkTooltips = {} end
					for idx, wndCur in pairs(self.twndItemLinkTooltips or {}) do
						if wndCur:GetData() == self.tLinks[nIndex].uItem then
							bWindowExists = true
							break
						end
					end
					local item = self.tLinks[nIndex].uItem
					local nDecorId = item:GetHousingDecorInfoId()
					local bValidItemPreview = ktValidItemPreviewSlots[item:GetSlot()]
					if Apollo.IsControlKeyDown() and nDecorId and nDecorId ~= 0 then
					    Event_FireGenericEvent("GenericEvent_LoadDecorPreview", nDecorId)
					elseif Apollo.IsControlKeyDown()  and bValidItemPreview then
						Event_FireGenericEvent("GenericEvent_LoadItemPreview", self.tLinks[nIndex].uItem)
					elseif bWindowExists == false then
					    local itemEquipped = self.tLinks[nIndex].uItem:GetEquippedItemForItemType()
						local wndChatItemToolTip = Apollo.LoadForm("ChatLog.xml", "TooltipWindow", nil, self)
					    wndChatItemToolTip:SetData(self.tLinks[nIndex].uItem)
					    table.insert(self.twndItemLinkTooltips, wndChatItemToolTip)
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
					Event_FireGenericEvent("ShowQuestLog", wndHandler:GetData()) -- Codex (todo: deprecate this)
					Event_FireGenericEvent("GenericEvent_ShowQuestLog", self.tLinks[nIndex].uQuest)
				elseif self.tLinks[nIndex].uArchiveArticle then
					Event_FireGenericEvent("HudAlert_ToggleLoreWindow")
					Event_FireGenericEvent("GenericEvent_ShowGalacticArchive", self.tLinks[nIndex].uArchiveArticle)
				elseif self.tLinks[nIndex].tNavPoint then
					GameLib.SetNavPoint(self.tLinks[nIndex].tNavPoint.tPosition, self.tLinks[nIndex].tNavPoint.nMapZoneId)
					GameLib.ShowNavPointHintArrow()
				end
			end
		end
	end
	if strNode == "URL" and eMouseButton == GameLib.CodeEnumInputMouse.Left then
	    local strOut = tAttributes.strUrl
		if  Apollo.IsShiftKeyDown() then
	        strOut = strOut.." "
		    Event_FireGenericEvent("GenericEvent_InputText", strOut)
		elseif string.find(strOut, " ") ~= nil then
			Event_FireGenericEvent("GenericEvent_ChatLogWhisper", strOut)
		else Event_FireGenericEvent("GenericEvent_CopyURL", strOut)
		end
	end
	-------------------
	if strNode == "Source" and eMouseButton == GameLib.CodeEnumInputMouse.Left and tAttributes.strCharacterName and tAttributes.strCrossFaction and Apollo.IsAltKeyDown() and Apollo.IsControlKeyDown() then
	    local strOut = tAttributes.strCharacterName
	    if strLocalization == "Annuler" then ChatSystemLib.Command("/rejoindre "..strOut)
	    elseif strLocalization == "Abbrechen" then ChatSystemLib.Command("/beitreten "..strOut)
	    else  ChatSystemLib.Command("/join "..strOut)
		end
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Emote, "You have submitted a request to join the group to "..strOut, "")
		if bMute == false then Sound.Play(175) end
	end
	if strNode == "Source" and eMouseButton == GameLib.CodeEnumInputMouse.Left and tAttributes.strCharacterName and tAttributes.strCrossFaction then
		local strOut = tAttributes.strCharacterName
    	if Apollo.IsControlKeyDown() and not Apollo.IsAltKeyDown() then
	        local strOut = '\"'..strOut..'\"'
	 	    ChatSystemLib.Command(strSlashWho.." "..strOut)
	    	WhoAddon.tWndRefs.wndMain:Invoke()
	    	elseif Apollo.IsShiftKeyDown() then
	    	    local strOut = strOut.." "
		        Event_FireGenericEvent("GenericEvent_InputText", strOut)
		    elseif Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() then GroupLib.Invite(strOut)
			elseif string.find(strOut, "@") ~= nil and string.find(strOut, "%S+@")  == nil and not Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() then
			    strOut = "aw " .. string.gsub(strOut, "@", "")
		        Event_FireGenericEvent("GenericEvent_InputChannel", strOut)
	        elseif not Apollo.IsAltKeyDown() and not Apollo.IsControlKeyDown() then
			    Event_FireGenericEvent("GenericEvent_ChatLogWhisper", tAttributes.strCharacterName)
		end
	end
	if strNode == "URL" or strNode == "Source" or strNode == "Link" or strNode == "Channel" or (strNode == "IMG" and CurrIndex[tAttributes.Image] ~=nil) then
    if bMute == false then Sound.Play(185) end
	end
    return false
end

function PratLite:OnGenericEvent_InputText(strOut)
    local wndParent = nil
	for idx, wndCurr in pairs(ChatLogAddon.tChatWindows) do
		if wndCurr and wndCurr:IsValid() then
		    if PLW ~= nil then
			    for n, d in pairs(PLW.tChatBoxes) do
				    if n == wndCurr:GetName() then return end
				end
			end
			wndParent = wndCurr
			break
		 end
	end
	if wndParent == nil then return end
	local strOutput = ""
	local wndEdit = wndParent:FindChild("Input")
    if wndEdit:GetText() and wndEdit:GetText() ~= nil then  	
	    strOutput = wndEdit:GetText().." "..strOut
	end
	wndEdit:SetText(strOutput)
	wndEdit:SetFocus()
	wndEdit:SetSel(strOutput:len(), -1)
	ChatLogAddon:OnInputChanged(nil, wndEdit, strOutput)
end

function PratLite:OnGenericEvent_InputChannel(strOut)
    local wndParent = nil
	for idx, wndCurr in pairs(ChatLogAddon.tChatWindows) do
		if wndCurr and wndCurr:IsValid() then
		    if PLW ~= nil then
			    for n, d in pairs(PLW.tChatBoxes) do
				    if n == wndCurr:GetName() then return end
				end
			end
			wndParent = wndCurr
			break
		 end
	end
	if wndParent == nil then return end
	local wndEdit = wndParent:FindChild("Input")
	local strText = wndEdit:GetText()
	if strText == "" then
		strText = String_GetWeaselString(Apollo.GetString("ChatLog_SlashPrefix"), strOut.." ")
	else
		local tInput = ChatSystemLib.SplitInput(strText) -- get the existing message, ignore the old command
		strText = String_GetWeaselString(Apollo.GetString("ChatLog_SlashPrefix"), strOut).." "..tInput.strMessage
	end
	local strText = string.gsub(strText, "/с ", "/s ")
	wndEdit:SetText(strText)
	wndEdit:SetFocus()
	wndEdit:SetSel(strText:len(), -1)
	ChatLogAddon:OnInputChanged(nil, wndEdit, strText)
end

function PratLite:OnGenericEvent_CopyURL(strData)
    self.wndCopyInput:FindChild("CopyButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, strData)
	self.wndCopyInput:FindChild("EditBox"):SetText(strData)
	self.wndCopyInput:ToFront()
	self.wndCopyInput:FindChild("EditBox"):SetFocus()
	self.wndCopyInput:Invoke()
end

function PratLite:OnNo( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Close()
end
------------------------------------------ Verify Settings ----------------------------------------
function PratLite:OnVerifySettings()
    bAlertWB = true
	self:OnDefaultSetting()
	bMessageInput = true
	bAnimation = true
	strShortNamesCustom = "check"
	strNicknameChat = "check"
	strColorClock = "ff00ffa9"
	strFontChatSetting = "Defaul"
	nLinkSound = 251
	bLFM = true
	self.bToWhisper = false
	bSoundAnimation = true
	bLootText = false
	bMute = false
	strPathIconDisplay = "show"
	tColorCustomChannel = {[2] = "AttributeDexterity", [3] = "AlertOrangeYellow", [4] = "Amber", [5] = "AlertOrangeYellow"}
	tColorCircleChannel = {[2] = "ChatCircle2", [3] = "ChatCircle3", [4] = "ChatCircle4", [5] = "ChatCircle5", [6] = "ChatCircle5"}
	Event_FireGenericEvent("GenericEvent_OnChannelsNames", tColorCustomChannel, tColorCircleChannel)
end
--------------------- Binding a button to the chat window ------------------
function PratLite:GetInputWnd()
	local chatWnds = ChatLogAddon.tChatWindows
	local wndEdit = nil
	for idx, wndCurrent in pairs(chatWnds) do
		if wndCurrent:FindChild("BGArt_SidePanel"):GetData() then
			wndEdit = wndCurrent:FindChild("BGArt_SidePanel")
			break
		end
	end	
	if wndEdit == nil then
		for idx, wndCurrent in pairs(chatWnds) do
			wndEdit = wndCurrent:FindChild("Input")
			break
		end
	end
end
--------------------------------------- ChatLog History --------------------------------
function PratLite:OnResetHistory()
    tChatHistory = {}
	nNumberLine = 0
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Realm, "The history of the ChatLog cleaned...", "")
	self.wndHistory:FindChild("Input"):SetText("")
	if bMute == false then Sound.Play(228) end
end

function PratLite:OnCloseWind()
    if self.wndHistory:IsVisible() then
        self.wndHistory:Show(false)
	else 
	    strHistory = ""
	    if nNumberLine > 1 and tChatHistory[1] ~= nil then
	        for i = 1, nNumberLine-1 do
			    tChatHistory[i] = string.gsub(tChatHistory[i], "\n", "")
	            if i < nNumberLine-1 and tChatHistory[i]:len()  > 6 then
	                strHistory = strHistory..tChatHistory[i].."\n"
		        else strHistory = strHistory..tChatHistory[i]
		        end
	        end
            self.wndHistory:Show(true)
	        self.wndMain:Show(false)
	        self.wndPaste:Show(false)
	        self.wndChannel:Show(false)
	        self.wndInstruction:Show(false)
            self.wndHistory:FindChild("Input"):SetText(strHistory)
			self.wndHistory:FindChild("NuberMessage"):SetText(nNumberLine-1)
	        self.wndHistory:FindChild("Input"):SetVScrollPos(strHistory:len())
			if bRus == true then self.wndHistory:FindChild("Button"):SetText("Сбросить историю")
			    self.wndHistory:FindChild("Text"):SetText("Ctrl+C - копировать, Crl+V - вставить текст; Ctrl+Alt - выделить.")
			end
			self.openwind = ApolloTimer.Create(1, true, "OnUpdateWind", self)
	    end
	end
	if bMute == false then Sound.Play(241) end
end

function PratLite:OnUpdateWind()
    self.openwind = nil
	self.wndHistory:FindChild("Input"):SetText(strHistory)
	self.wndHistory:FindChild("Input"):SetFocus()
	self.wndHistory:FindChild("Input"):SetSel(strHistory:len(), -1)
	self.wndHistory:FindChild("Input"):SetVScrollPos(strHistory:len())
	local nVPos = self.wndHistory:FindChild("Input"):GetVScrollPos()
	self.wndHistory:FindChild("AllLines"):SetText(strHistory:len())
end
--------------------------------------- Open Guild Panel ------------------------------------
function PratLite:OnOpenGuildPanelOn()
    local SocialPanelAddon = Apollo.GetAddon("SocialPanel")
	SocialPanelAddon:OnToggleSocialWindow("ContactsFrame")
	self.toggleframe = ApolloTimer.Create(0.5, true, "OnToggleFrameOn", self)
end

function PratLite:OnToggleFrameOn() 
    self.toggleframe = nil
    local SocialPanelAddon = Apollo.GetAddon("SocialPanel")
	SocialPanelAddon.tWndRefs.wndMain:Show(false)
	self.guildframe = ApolloTimer.Create(0.8, true, "OnGuildFrameOn", self)
end

function PratLite:OnGuildFrameOn() 
    self.guildframe = nil
    local SocialPanelAddon = Apollo.GetAddon("SocialPanel")
	Event_FireGenericEvent("GenericEvent_OpenGuildPanel")
end

--------------------------------------- Open Friends Panel ----------------------------------
function PratLite:OnFriendListOn()
    local SocialPanelAddon = Apollo.GetAddon("SocialPanel")
	SocialPanelAddon:OnToggleSocialWindow("ContactsFrame")
end
---------------------------------------- Invoke Options -------------------------------
function PratLite:InvokeOptionsScreen()
    InvokeOptionsScreen()
end

-------------------------------- Paste Long Text --------------------
function PratLite:OnWindPasteText()
    if self.wndPaste:IsVisible() then 
	    if bMute == false then Sound.Play(268) end
	    self.wndPaste:Show(false)
	else self.wndPaste:Show(true)
	    self.wndChannel:Show(false)
	    self.wndMain:Show(false)
	    self.wndHistory:Show(false)
	    self.wndChannel:Show(false)
	    self.wndInstruction:Show(false)
		if bRus == true then  self.wndPaste:FindChild("Button_Statistics"):SetText("Онлайн сервера")
		    self.wndPaste:FindChild("Name"):SetText("Имя игрока(Имя аккаунта)")
		    self.wndPaste:FindChild("CurrentChannel"):SetText("Канал для сообщения")
		end
        local chatWnds = ChatLogAddon.tChatWindows
    	local wndChat = chatWnds[1]
    	local wndInput = wndChat:FindChild("Input")
        local wndForm = wndInput:GetParent()
    	local tChatData = wndForm:GetData()
    	tabCurrentChannal = { name = tChatData.channelCurrent:GetName() or "Say",
	        command = tChatData.channelCurrent:GetCommand() or "s",
	        color = ChatLogAddon.arChatColor[tChatData.channelCurrent:GetType()] or "White", eChannel = tChatData.channelCurrent:GetType()}
	    self.wndPaste:FindChild("CurrChannel"):SetText(tabCurrentChannal.name)
    	self.wndPaste:FindChild("CurrChannel"):SetTextColor(tabCurrentChannal.color)
		self.wndPaste:FindChild("EditName"):SetTextColor("darkgray")
		if bRus == true then self.wndPaste:FindChild("ButtonClean"):SetText("Очистить окно")
		    self.wndPaste:FindChild("Title"):SetText("Втавка длинного текста")
		end
        if ChatLogAddon.tLastWhisperer ~= nil then
	        if ChatLogAddon.tLastWhisperer.strDisplayName ~= "" and ChatLogAddon.tLastWhisperer.strDisplayName ~= nil and tabCurrentChannal.eChannel == 34 then 
			    self.wndPaste:FindChild("EditName"):SetText(ChatLogAddon.tLastWhisperer.strDisplayName)
	        else self.wndPaste:FindChild("EditName"):SetText(ChatLogAddon.tLastWhisperer.strCharacterName)
	        end
		else 
		   if strCurrNameWhisper == "" then strCurrNameWhisper = strUnitPlayerName end
           ChatLogAddon.tLastWhisperer = { strCharacterName = strCurrNameWhisper, strDisplayName = strCurrNameWhisper}
           self.wndPaste:FindChild("EditName"):SetText(ChatLogAddon.tLastWhisperer.strDisplayName)
	    end
		if tabCurrentChannal.eChannel == 6 or tabCurrentChannal.eChannel == 34 then
		    self.wndPaste:FindChild("EditName"):SetFocus()
			self.wndPaste:FindChild("EditName"):SetTextColor("White")
		end
        if bMute == false then Sound.Play(267) end
    end
end

function PratLite:OnFrameChannel()
    if self.wndChannel:IsVisible() then
	    self.wndChannel:Show(false)
	else self.wndChannel:Show(true)
    	self.wndChannel:FindChild("Grid_Channel"):DeleteAll()
		local n = 0
		for idx, channelCurrent in ipairs(ChatSystemLib.GetChannels()) do
	    local strChannelCommand = channelCurrent:GetCommand()
		local eChannelType = channelCurrent:GetType()
		    if strChannelCommand ~= "" then n = n + 1
		    local strName = channelCurrent:GetName()
			local text = self.wndChannel:FindChild("Grid_Channel"):AddRow(strChannelCommand)
			local strColor = ChatLogAddon.arChatColor[eChannelType]
			self.wndChannel:FindChild("Grid_Channel"):SetCellDoc(text, 1, "<T TextColor=\""..strColor.."\">"..strName.."</T>")
			tCurrentChanel[n] = { name = strName, command = strChannelCommand, color = strColor, eChannel = eChannelType}
		    end
		end
	end
	if bMute == false then Sound.Play(241) end
end

function PratLite:OnPasteChannelClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, iRow )
	local wndGrid = self.wndChannel:FindChild("Grid_Channel")
	local row = wndGrid:GetCurrentRow()
	if row ~= nil and row <= wndGrid:GetRowCount() and tonumber(row) > 0 then
		tabCurrentChannal = tCurrentChanel[row]
		self.wndPaste:FindChild("EditName"):ClearFocus()
		self.wndPaste:FindChild("EditName"):SetText(ChatLogAddon.tLastWhisperer.strCharacterName)
		self.wndPaste:FindChild("EditName"):SetTextColor("darkgray")
		if tabCurrentChannal.eChannel == 34 and ChatLogAddon.tLastWhisperer.strDisplayName ~= nil then 
		    self.wndPaste:FindChild("EditName"):SetText(ChatLogAddon.tLastWhisperer.strDisplayName)
		end
		if tabCurrentChannal.eChannel == 6 or tabCurrentChannal.eChannel == 34 then
		    self.wndPaste:FindChild("EditName"):SetFocus()
			self.wndPaste:FindChild("EditName"):SetTextColor("White")
		end
		self.wndChannel:Show(false)
		self.wndPaste:FindChild("CurrChannel"):SetText(tabCurrentChannal.name)
		self.wndPaste:FindChild("CurrChannel"):SetTextColor(tabCurrentChannal.color)
	end
end

function PratLite:OnPasteText()
    local nNum = 0
    local strOriginal = self.wndPaste:FindChild("InputText"):GetText() 
	local tReplacement = {"\n+", "\r\n", "\r", "\n%s+\n", "\n%s+$", "\n%s+", "%s+\n"}
	for _, replace in pairs(tReplacement) do
	    strOriginal = string.gsub(strOriginal, replace, " pratenterlite ")
	end
    strOriginal = string.gsub(strOriginal, "^%s+", "")  
    strOriginal = string.gsub(strOriginal, "%s+$", "")
    strOriginal = string.gsub(strOriginal, "%s+", " ")
    strOriginal = string.gsub(strOriginal, "Р", "P")
    strOriginal = string.gsub(strOriginal, "р", "p")
	local text = ""
	for word in string.gmatch(strOriginal, ".") do
	    local strWord = word
	    if string.find(strWord, "\n") ~= nil then nNum = nNum +1 end
	    local strWord = string.gsub(strWord, "\n", " pratenterlite ")	    
		local strWord = string.gsub(strWord, "%z", "")
	    text = text..strWord
	end
	local tLinkText = {}
	local n = 1
	local strCurrText = ""
	for word in string.gmatch(text, "%S+") do
		local strWord = word
		strCurrText = strCurrText..strWord.." "
		    if string.find(strWord, "ratenterli") ~= nil then 
				n = n + 1
				strCurrText = ""
			elseif strCurrText:len() < 500 then tLinkText[n] = strCurrText
			else strCurrText = strWord.." "
			    n = n + 1
				tLinkText[n] = strCurrText
			end
    end
	for i = 1, n do
	    local strPost = tLinkText[i]
		if strPost and strPost ~= nil and strPost ~= "" and string.find(strPost, ".") ~= nil then
		    local strCurrNameWhisper = self.wndPaste:FindChild("EditName"):GetText()
		    local strSlashCommand = "/say"
			local n = tabCurrentChannal.eChannel
		    if tabCurrentChannal.command ~= nil and tabCurrentChannal.command:len() > 0 and n ~= nil then
			    if n == 6 or n == 34 then 
				    strSlashCommand = String_GetWeaselString(Apollo.GetString("ChatLog_SlashPrefix"), tabCurrentChannal.command.." "..strCurrNameWhisper)
				    ChatSystemLib.Command(strSlashCommand.." "..string.char(28, 32)..strPost)
				else strSlashCommand = String_GetWeaselString(Apollo.GetString("ChatLog_SlashPrefix"), tabCurrentChannal.command)
				    ChatSystemLib.Command(strSlashCommand.." "..strPost)
			    end
		    end
		end
	end
end
function PratLite:OnButtonStatistics()
    if strLastStatistic ~= nil or strLastStatistic ~= "" then
       self.wndPaste:FindChild("InputText"):SetText(strLastStatistic)
	end
end
    
function PratLite:OnCleanWindow()
    self.wndPaste:FindChild("InputText"):SetText("")
end
----------------------------------------- Description ----------------------------------------
function PratLite:OnInstruction() 
    if self.wndInstruction:IsVisible() then
	    self.wndInstruction:Show(false)
	else self.wndInstruction:Show(true)
	    self.wndMain:Show(false)
	    self.wndHistory:Show(false)
	    self.wndPaste:Show(false)
	    self.wndChannel:Show(false)
		if bRus == true then
		    self.wndInstruction:FindChild("Title"):SetText("Описание")
		    self.wndInstruction:FindChild("ButtonRU"):SetCheck(true)
			self.wndInstruction:FindChild("ButtonEN"):SetCheck(false)
			self.wndInstruction:FindChild("InstructionList"):SetSprite("DescriptionRU")
		else self.wndInstruction:FindChild("ButtonEN"):SetCheck(true)
            self.wndInstruction:FindChild("ButtonRU"):SetCheck(false)
			self.wndInstruction:FindChild("InstructionList"):SetSprite("DescriptionEN")
		end
	end
	if bMute == false then Sound.Play(241) end
end

function PratLite:OnButtonRU()
	if self.wndInstruction:FindChild("ButtonEN"):IsChecked() then 
	    self.wndInstruction:FindChild("InstructionList"):SetSprite("DescriptionEN")
        self.wndInstruction:FindChild("ButtonRU"):SetCheck(false)
	else self.wndInstruction:FindChild("ButtonRU"):SetCheck(true)
    end
end

function PratLite:OnButtonEN()
    if self.wndInstruction:FindChild("ButtonRU"):IsChecked() then 
	    self.wndInstruction:FindChild("InstructionList"):SetSprite("DescriptionRU")
		self.wndInstruction:FindChild("ButtonEN"):SetCheck(false)
	else self.wndInstruction:FindChild("ButtonEN"):SetCheck(true)
    end
end
------------------------------ Float Message -------------------
function PratLite:ShowFloatMessage( strMessage, crColor, strFont, nTime, yPosition)
    local FT = Apollo.GetAddon("FloatText")
	if FT == nil then return end
    --FT:OnAlertTitle(strMessage)
	--FT:OnCountdownTick(strMessage)
	--FT:OnTradeSkillFloater(GameLib.GetPlayerUnit(), strMessage)
	--FT:OnQuestShareFloater(GameLib.GetPlayerUnit(), strMessage)
	--FT:OnGenericFloater(GameLib.GetPlayerUnit(), strMessage)
	self.tTextOption = FT:GetDefaultTextOption()
	self.tTextOption.fDuration = nTime or 5 -- time
	self.tTextOption.bUseScreenPos = true
	self.tTextOption.fOffset = yPosition or -240 -- Y position
	self.tTextOption.nColor = crColor or 0x00FFFF
	self.tTextOption.strFontFace = strFont or "CRB_Interface16_BBO"
	self.tTextOption.bShowOnTop = true
    CombatFloater.ShowTextFloater(GameLib.GetPlayerUnit(), strMessage, self.tTextOption)
end	
-----------------------------------------------------------------------
-- PratLite Instance
---------------------------------------------------------------------
local PratLiteInst = PratLite:new()
PratLiteInst:Init()
