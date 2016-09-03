-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoLib
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoLib Module Definition
-----------------------------------------------------------------------------------------------
PotatoLib = {} 

local bRecentPing = false
local bShowToolbox = true
local strVersion = "2.7.0c"

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local daCColor =  CColor.new(0, 0, 1, 1)

local ktTextPos = {"Left", "Mid", "Right"}

PotatoLib.ktTextures = { --New PUI v2.0 function
	[1] = "Aluminum", Aluminum = 1,
	[2] = "Bantobar", Bantobar = 2,
	[3] = "Charcoal", Charcoal = 3,
	[4] = "Striped", Striped = 4,
	[5] = "Minimalist", Minimalist = 5,
	[6] = "Smooth", Smooth = 6,
	[7] = "Frost", Frost = 7,
	[8] = "TrueFrost", TrueFrost = 8,
	[9] = "Glaze", Glaze = 9,
	[10] = "HealBot", HealBot = 10,
	[11] = "LiteStep", LiteStep = 11,
	[12] = "Otravi", Otravi = 12,
	[13] = "Rocks", Rocks = 13,
	[14] = "Runes", Runes = 14,
	[15] = "Smudge", Smudge = 15,
	[16] = "Xeon", Xeon = 16,
	[17] = "Xus", Xus = 17,
	[18] = "Skullflower", Skullflower = 18,
	[19] = "WhiteFill", WhiteFill = 19
}

PotatoLib.ktClassNames = {  --New PUI v2.0 function
	[GameLib.CodeEnumClass.Esper] = "Esper",
	[GameLib.CodeEnumClass.Engineer] = "Engineer",
	[GameLib.CodeEnumClass.Medic] = "Medic",
	[GameLib.CodeEnumClass.Spellslinger] = "Spellslinger",
	[GameLib.CodeEnumClass.Stalker] = "Stalker",
	[GameLib.CodeEnumClass.Warrior] = "Warrior"
}

PotatoLib.classColors = {
	Carbine = {			
		[GameLib.CodeEnumClass.Engineer] = "FF9900",			
		[GameLib.CodeEnumClass.Esper] = "00BFFF",			
		[GameLib.CodeEnumClass.Medic] = "FFFF00",			
		[GameLib.CodeEnumClass.Spellslinger] = "7FFF00",			
		[GameLib.CodeEnumClass.Stalker] = "BF00FF",			
		[GameLib.CodeEnumClass.Warrior] = "FF0000",
		Hostile = "CC0000",
		Friendly = "005C00",
		Neutral = "FFCC00"
	},
	BijiPlates = {
		[GameLib.CodeEnumClass.Engineer] = "A83C09",
		[GameLib.CodeEnumClass.Esper] = "C875C4",
		[GameLib.CodeEnumClass.Medic] = "01386A",
		[GameLib.CodeEnumClass.Spellslinger] = "CDC50A",
		[GameLib.CodeEnumClass.Stalker] = "703BE7",
		[GameLib.CodeEnumClass.Warrior] = "9A0200",
		Hostile = "E50000",
		Friendly = "15B01A",
		Neutral = "F3D829"
	},
	Grid =
	{
		[GameLib.CodeEnumClass.Engineer] = "A41A31",
		[GameLib.CodeEnumClass.Esper] = "74DDFF",
		[GameLib.CodeEnumClass.Medic] = "FFFFFF",
		[GameLib.CodeEnumClass.Stalker] = "DDD45F",
		[GameLib.CodeEnumClass.Spellslinger] = "826FAC",
		[GameLib.CodeEnumClass.Warrior] = "AB855E",
		Hostile = "CC0000",
		Friendly = "005C00",
		Neutral = "FFCC00"
	},
	Custom =
	{
		[GameLib.CodeEnumClass.Engineer] = "FFFFFF",
		[GameLib.CodeEnumClass.Esper] = "FFFFFF",
		[GameLib.CodeEnumClass.Medic] = "FFFFFF",
		[GameLib.CodeEnumClass.Stalker] = "FFFFFF",
		[GameLib.CodeEnumClass.Spellslinger] = "FFFFFF",
		[GameLib.CodeEnumClass.Warrior] = "FFFFFF",
		Hostile = "FFFFFF",
		Friendly = "FFFFFF",
		Neutral = "FFFFFF"
	}
}  -- TRANSPARENCY VALUES MUST BE APPENDED TO BEGINNING

PotatoLib.resourceColors = {
	[GameLib.CodeEnumClass.Engineer] = "FF3D0D",
	[GameLib.CodeEnumClass.Esper] = "BE03FD",
	[GameLib.CodeEnumClass.Medic] = "BE03FD",
	[GameLib.CodeEnumClass.Spellslinger] = "BE03FD",
	[GameLib.CodeEnumClass.Stalker] = "FAC205",
	[GameLib.CodeEnumClass.Warrior] = "FF3D0D",
	[6] = "000000"
}  -- TRANSPARENCY VALUES MUST BE APPENDED TO BEGINNING

PotatoLib.factionNames = {
	[166] = "Dominion",
	[170] = "Dominion",
	[171] = "Exile", --Exile NPC
	[189] = "redenemy",
	[167] = "Exile"
}

PotatoLib.pathNames =
{
	[0] = "Soldier",
	[1] = "Colonist",
	[2] = "Scientist",
	[3] = "Explorer"
}

PotatoLib.frame = { --TODO: Remove on PotatoFrames redo.
	anchors = {},
	offsets = {},
	showPortrait = nil,
	icons = {},
	barStyles = {},
	textFields = {}
}

PotatoLib.ktDefaultBorder = { --TODO: Remove on PotatoFrames redo.
	show = true,
	color = "000000",
	transparency = "67",
	size = 2
}
		
PotatoLib.ktDefaultBackground = { --TODO: Remove on PotatoFrames redo.
	show = true,
	color = "000000",
	transparency = "47"
}

PotatoLib.ktDefaultFramesMess = { --TODO: Remove on PotatoFrames redo.
	{
		name = "HP",
		colorType = "classcolor",
		color = "00FF00",
		textLeft = {
			type = 1,
			font = {
				base = "CRB_Interface",
				size = "10",
				props = "BBO"
			}
		},
		textMid = {
			type = 0,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textRight = {
			type = 4,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		texture = "Aluminum",
		transparency = "100",
		barGrowth = 1
	},
	{
		name = "SP",
		colorType = "customcolor",
		color = "00FFFF",
		textLeft = {
			type = 2,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textMid = {
			type = 0,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textRight = {
			type = 4,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		texture = "Aluminum",
		transparency = "100",
		barGrowth = 1
	},
	{
		name = "AP",
		colorType = "customcolor",
		color = "FFFFFF",
		textLeft = {
			type = 2,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textMid = {
			type = 0,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textRight = {
			type = 4,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		texture = "Aluminum",
		transparency = "100",
		barGrowth = 1
	},
	{
		name = "RP",
		colorType = "resourcecolor",
		color = "FF00FF",
		textLeft = {
			type = 2,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textMid = {
			type = 0,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		textRight = {
			type = 4,
			font = {
				base = "CRB_Pixel",
				size = "",
				props = "O"
			}
		},
		texture = "Aluminum",
		transparency = "100",
		barGrowth = 1,
		showResBar = true
	}
}

--------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PotatoLib:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
    return o
end

function PotatoLib:Init()
    Apollo.RegisterAddon(self)
end
 
local editorMode = false
-----------------------------------------------------------------------------------------------
-- PotatoLib OnLoad
-----------------------------------------------------------------------------------------------
function PotatoLib:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
	Apollo.RegisterSlashCommand("potatoui", "ToggleToolbox", self)
	Apollo.RegisterSlashCommand("pui", "ToggleToolbox", self)
	Apollo.RegisterSlashCommand("potatoedit", "PotatoEditor", self)
	Apollo.RegisterSlashCommand("potatoreset", "PotatoReset", self)
	
	Apollo.RegisterSlashCommand("potatoping", "PotatoPing", self)
	Apollo.RegisterSlashCommand("potatosend", "PotatoSend", self)
	
	Apollo.RegisterEventHandler("SystemKeyDown",				"OnSystemKeyDown", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", 			"OnEnteredCombat", self)
	if GameLib.GetPlayerUnit() == nil then
		Apollo.RegisterEventHandler("CharacterCreated",				"OnCharacterCreated", self)
	else
		self:OnCharacterCreated()
	end
	
	Apollo.CreateTimer("TargetFrameUpdate", 1, true)
	Apollo.RegisterTimerHandler("TargetFrameUpdate", 						"MainThread", self)
	Apollo.CreateTimer("PingTimer", 20, false)
	Apollo.RegisterTimerHandler("PingTimer", "OnPingTimerEnd", self)
	Apollo.CreateTimer("AHToolboxTimer", 4, false) --AH = autohide
	Apollo.RegisterTimerHandler("AHToolboxTimer", "OnAHToolboxEnd", self)
	
	Apollo.LoadSprites("PotatoSprites.xml", "BarSprites")
	
	--load communications
	--self.chanPotato = ICCommLib.JoinChannel("PotatoChannel", "OnPotatoMessage", self)
	
	-- load our forms
	
	--self.wndContent = Apollo.LoadForm("PotatoLib.xml", "FrameOptionsForm", nil, self)
	--self.wndContent:Show(true)	

	self.wndEditorBtns = Apollo.LoadForm("PotatoLib.xml", "TempEditorBtns", nil, self)
	
	self.wndCustomize = Apollo.LoadForm("PotatoLib.xml", "EditorFrame", nil, self)
	self.wndCustomize:Show(false)
	
	self.wndCopySettings = Apollo.LoadForm("PotatoLib.xml", "Profiles", nil, self)
	
	self.wndPing = Apollo.LoadForm("PotatoLib.xml", "PingFrame", nil, self)
	
	self.wndDropdown = Apollo.LoadForm("PotatoLib.xml", "TempEditorBtns1", nil, self)
	self.wndDropdown:Show(false)
		
	self.tCharacters = {}
	self.tLockedWindows = {}
	self.pongCounter = 0
	self.bPositionCenter = false
	self.bTruncateText = false
	self.bLowHPandCC = true
	self.bInCombat = false
	self.strColorStyle = self.strColorStyle or "Carbine"
	
	self.xmlDoc = XmlDoc.CreateFromFile("PotatoLib.xml")
	self.xmlDoc:RegisterCallback("OnMainDocumentReady", self)
end

function PotatoLib:OnMainDocumentReady()
	Print("PotatoUI by Potato <Phobos> on Stormtalon is now loaded.")
end

-----------------------------------------------------------------------------------------------
-- PotatoLib Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PotatoLib:MainThread()
	if GameLib.GetPlayerUnit() == nil then return end
	if self.strCharacterName == nil then self.strCharacterName = GameLib.GetPlayerUnit():GetName() end
	
	if self.strCharacterName == "Potato" then
		self.wndDropdown:Show(true)
	end
end

function PotatoLib:ToggleToolbox()
	bShowToolbox = not bShowToolbox
	self.wndEditorBtns:Show(bShowToolbox)
	if not bShowToolbox then
		if editorMode then
			self:PotatoEditor()
		end
		Print("[PotatoUI] To show the PotatoUI toolbox again, type /potatoui or /pui.")
	end
end

function PotatoLib:PotatoEditor()
	editorMode = not editorMode
	Event_FireGenericEvent("PotatoEditor", editorMode)
	
	local wndResetBtn =	self.wndEditorBtns:FindChild("Reset")
	local wndResetBtn2 = self.wndDropdown:FindChild("Reset")
	
	if editorMode then
		wndResetBtn:SetTextColor("FFFFFFFF")
		wndResetBtn:SetBGColor("FFFFFFFF")
		wndResetBtn2:SetTextColor("FFFFFFFF")
		wndResetBtn2:SetBGColor("FFFFFFFF")
		GameLib.PauseGameActionInput(true)
	else
		wndResetBtn:SetTextColor("FF555555")
		wndResetBtn:SetBGColor("FF555555")
		wndResetBtn2:SetTextColor("FF555555")
		wndResetBtn2:SetBGColor("FF555555")
		GameLib.PauseGameActionInput(false)
		if self.previousElement ~= nil then
			self.previousElement:FindChild("CustomizeBorder"):Show(false)
			self.previousElement = nil
		end
		self.wndCustomize:Show(false)
		if self.bForceSave then
			RequestReloadUI()
		end
		self.tLockedWindows = {}
	end
end

function PotatoLib:PotatoReset()
	if editorMode then
		self.wndConfirmReset = Apollo.LoadForm("PotatoLib.xml", "ConfirmReset", nil, self)
	else
		Print("[PotatoUI] You must be in editor mode to reset frame positions.")
	end
end

function PotatoLib:CopySettingsStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if not self.wndCopySettings:IsVisible() then
		--Reset "Are you sure?" frame as if 'No' was pressed. 
		self:OnCopyNoBtn()
		self.wndCopySettings:Show(true)
		self.wndCopySettings:FindChild("CopySettings"):Enable(false)
		--Reset the Character and Addon Lists
		local tCharacters = {}
		self.wndCopySettings:FindChild("CharacterList"):DestroyChildren()
		self.wndCopySettings:FindChild("AddonList"):DestroyChildren()
		local counter = 1
		for key, val in pairs(self.tCharacters) do
			if key ~= self.strCharacterName then
				tCharacters[counter] = Apollo.LoadForm("PotatoLib.xml", "ProfileCharacter", self.wndCopySettings:FindChild("CharacterList"), self)
				tCharacters[counter]:SetText(key)
				counter = counter+1
			end
		end
		self.wndCopySettings:FindChild("CharacterList"):ArrangeChildrenVert(0)
	else
		self.wndCopySettings:Show(false)
	end
end

function PotatoLib:OnSelectSettingsCharacter( wndHandler, wndControl, eMouseButton )
	local strCharacterName = wndHandler:GetText()
	local tAddons = {}
	self.wndCopySettings:FindChild("AddonList"):DestroyChildren()
	--Populate Addon List
	for key, val in pairs(self.tCharacters[strCharacterName]) do
		if Apollo.GetAddon(val)~= nil then
			tAddons[key] = Apollo.LoadForm("PotatoLib.xml", "ProfileAddon", self.wndCopySettings:FindChild("AddonList"), self)
			tAddons[key]:SetText(val)
		end
	end
	self.wndCopySettings:FindChild("AddonList"):ArrangeChildrenVert(0)
	self.wndCopySettings:FindChild("AreYouSure"):SetData(strCharacterName)
end

function PotatoLib:OnCopySettingsBtn( wndHandler, wndControl, eMouseButton )
	if not self.wndCopySettings:FindChild("AreYouSure"):IsVisible() then
		--Arrange frames
		self.wndCopySettings:FindChild("AddonList"):SetAnchorOffsets(0,0,0,200)
		self.wndCopySettings:FindChild("AreYouSure"):SetAnchorOffsets(0,235,0,0)
		self.wndCopySettings:FindChild("RightSide"):ArrangeChildrenVert(0)
		self.wndCopySettings:FindChild("AreYouSure"):Show(true)	
	end
	
	--Populate string
	local strSettingsCharName = self.wndCopySettings:FindChild("AreYouSure"):GetData()
	local strCurrCharName = GameLib.GetPlayerUnit():GetName()
	local tAddonsSelected = {}
	for idx=1, #self.wndCopySettings:FindChild("AddonList"):GetChildren() do
		local currAddon = self.wndCopySettings:FindChild("AddonList"):GetChildren()[idx]
		if currAddon:IsChecked() then
			table.insert(tAddonsSelected, currAddon:GetText())
		end			
	end
	self.wndCopySettings:FindChild("AreYouSure"):SetText(string.format("Are you sure you want to copy settings from the %s addons "..
																		"selected above from %s to your current character, %s?",
																		#tAddonsSelected,
																		strSettingsCharName,
																		strCurrCharName))
	self.wndCopySettings:FindChild("CopyYes"):SetData({name=strSettingsCharName, addons=tAddonsSelected})
end

function PotatoLib:OnCopyYesBtn( wndHandler, wndControl, eMouseButton )
	--Do the copy stuff
	local tAddonsSelected = self.wndCopySettings:FindChild("CopyYes"):GetData().addons
	local strSettingsCharName = self.wndCopySettings:FindChild("CopyYes"):GetData().name
	for idx=1, #tAddonsSelected do
		local addonInstance = Apollo.GetAddon(tAddonsSelected[idx])
		if addonInstance.tAccountData ~= nil then --Check to see if addon data exists
			if addonInstance.tAccountData[strSettingsCharName] ~= nil then --Check to see if character data exists
				addonInstance:OnRestore(GameLib.CodeEnumAddonSaveLevel.Character, addonInstance.tAccountData[strSettingsCharName])
			end
		end
	end
	--Reset the frame as if 'No' was pressed
	self:OnCopyNoBtn()	
end

function PotatoLib:OnCopyNoBtn( wndHandler, wndControl, eMouseButton )
	self.wndCopySettings:FindChild("AddonList"):SetAnchorOffsets(0,0,0,320)
	self.wndCopySettings:FindChild("AreYouSure"):SetAnchorOffsets(0,0,0,0)
	self.wndCopySettings:FindChild("AreYouSure"):Show(false)	
	self.wndCopySettings:FindChild("RightSide"):ArrangeChildrenVert(0)
end

function PotatoLib:OnAddonCheck( wndHandler, wndControl, eMouseButton )
	local bAddonsChecked = wndHandler:IsChecked() --Check if current button is checked.
	
	if not bAddonsChecked then --If not, check the others.
		for idx=1, #self.wndCopySettings:FindChild("AddonList"):GetChildren() do
			local currAddon = self.wndCopySettings:FindChild("AddonList"):GetChildren()[idx]
			if currAddon:IsChecked() then
				bAddonsChecked = true
				break
			end			
		end
	end
	
	self.wndCopySettings:FindChild("CopySettings"):Enable(bAddonsChecked) --Enable CopySettings button if any are checked.
end

function PotatoLib:PotatoReloadUI( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	RequestReloadUI()
end

function PotatoLib:ElementSelected(element, addon)
	local bShowCover = not self.wndCustomize:IsShown()
	if self.previousElement ~= element and self.previousElement ~= nil then
		self.previousElement:FindChild("EditorCover"):Show(true)
		self.previousElement:FindChild("CustomizeBorder"):Show(false)
	end
	self.previousElement = element
		
	--Place frame around element
	element:FindChild("CustomizeBorder"):Show(true)
	element:FindChild("EditorCover"):Show(bShowCover)
end

function PotatoLib:GetFontTable(strFont)
	local final = {}
	local strBase = ""
	local nSize = nil
	local strProps = ""
	
	for key,val in pairs(self.ktFonts) do
		if string.find(strFont, val.base) then
		strBase = val.base --CRB_Interface // CRB_Alien
		strRemainder = string.gsub(strFont, val.base, "") --10_BBO // Small
		for size,props in pairs(val.sizeProp) do
			local nMatchStart, nMatchEnd = string.find(strRemainder, size)
			if nMatchStart == 1 then
					nSize = string.sub(strRemainder, nMatchStart, nMatchEnd)
					strRemainder = string.gsub(strRemainder, nSize, "")
					strRemainder = string.gsub(strRemainder, "_", "")
					strProps = strRemainder
				end
			end
			final.base = strBase
			final.size = nSize
			final.props = strProps
		end
	end
	
	return final
end

function PotatoLib:GetFontDataByBase(strBase)
	for key,val in pairs(self.ktFonts) do
		if val.base == strBase then
			return val
		end
	end
end

function PotatoLib:GetFontKeyByBase(strBase)
	for key,val in pairs(self.ktFonts) do
		if val.base == strBase then
			return key
		end
	end
end

function PotatoLib:GetSizeKeyByBaseSize(nBase, strSize)
	for key,val in pairs(self.ktFonts[nBase].sizes) do
		if val.."" == strSize.."" then
			return key
		end
	end
end
	
function PotatoLib:FontTableToString(tFont)
	local strFont = ""
	strFont = tFont.base .. tFont.size
	if tFont.props ~= "" and tFont.props ~= nil then
		strFont = strFont.."_"..tFont.props
	end
	return strFont
end

function PotatoLib:SetBarFonts(wnd, tData) --PUI v2.8
	if wnd == nil then return end
	
	for _, strPos in pairs(ktTextPos) do
		local strTextLoc = "text"..strPos
		if tData[strTextLoc] and wnd:FindChild(strTextLoc) then
			wnd:FindChild(strTextLoc):SetFont(PotatoLib:FontTableToString(tData[strTextLoc].font))
		else
			if tData[strTextLoc] then
				wnd:SetFont(PotatoLib:FontTableToString(tData[strTextLoc].font))
			end
		end
	end
end

function PotatoLib:ChangeTxtWeight( wndHandler, addon ) --PUI v2.8
	local strTextLoc = wndHandler:GetParent():GetParent():GetName()
	
	local tFontData = addon[strTextLoc].font
	
	local tProps = {
		[0] = "",
		[1] = "B",
		[2] = "BB",
		[3] = "I"
	}
	
	local nWeight = wndHandler:GetParent():GetRadioSel("TxtWeight")
	local strProp = tProps[nWeight]
	
	if nWeight == 3 then
		wndHandler:GetParent():FindChild("Outline"):Enable(false)
	else
		wndHandler:GetParent():FindChild("Outline"):Enable(true)
	end

	if wndHandler:GetParent():FindChild("Outline"):IsChecked() then
		strProp = strProp .. "O"
	end

	tFontData.props = strProp
end

function PotatoLib:TextOptScroll( wndHandler, tTextType, addon) --PUI v2.8
	local strTextLoc = wndHandler:GetParent():GetParent():GetName()	
	local nTextVal = addon[strTextLoc].type
	
	local nChange = wndHandler:GetName() == "RightScroll" and 1 or -1
	local nNewTextVal = nTextVal + nChange

	if nNewTextVal == #tTextType or nNewTextVal == 0 then
		wndHandler:Enable(false)
	else
		for key, val in pairs(wndHandler:GetParent():GetChildren()) do
			val:Enable(true)
		end
	end
	
	--Set the Data
	addon[strTextLoc].type = nNewTextVal
	--Set the Editor
	local strText = tTextType[nNewTextVal][2]
	wndHandler:GetParent():FindChild("CurrentVal"):SetText(tTextType[nNewTextVal][1])
end	

function PotatoLib:FontScroll( wndHandler, addon ) --PUI v2.8
	local strTextLoc = wndHandler:GetParent():GetParent():GetParent():GetName()
	
	local tFontData = addon[strTextLoc].font
	
	local nBaseKey = nil
	for key,val in pairs(self.ktFonts) do
		if tFontData.base == val.base then
			nBaseKey = key
		end
	end
		
	if nBaseKey ~= nil then			
		local nChange = wndHandler:GetName() == "RightScroll" and 1 or -1
		
		nBaseKey = nBaseKey + nChange
		
		if nBaseKey == #self.ktFonts or nBaseKey == 1 then
			wndHandler:Enable(false)
		else
			for key, val in pairs(wndHandler:GetParent():GetChildren()) do
				val:Enable(true)
			end
		end
		
		wndHandler:GetParent():FindChild("CurrentVal"):SetText(self.ktFonts[nBaseKey].name)
		wndHandler:GetParent():FindChild("CurrentVal"):SetFont(self.ktFonts[nBaseKey].defaultStr)
		
		local wndSizeOpts = wndHandler:GetParent():GetParent():FindChild("TxtSize")
		local strSize = self.ktFonts[nBaseKey].defaultSettings.size
		local nSizeId = self:GetSizeKeyByBaseSize(nBaseKey,strSize)		
		wndSizeOpts:FindChild("TextValue"):SetText(strSize)
		wndSizeOpts:FindChild("TextValueDown"):Enable(nSizeId > 1)
		wndSizeOpts:FindChild("TextValueUp"):Enable(nSizeId < #self.ktFonts[nBaseKey].sizes)
		
		--Reset Text Properties
		local wndPropOpts = wndHandler:GetParent():GetParent():GetParent():FindChild("TxtProps")
		for key, wnd in pairs(wndPropOpts:GetChildren()) do
			wnd:Enable(false)
		end
		wndPropOpts:SetRadioSel("TxtWeight", 0)
		wndPropOpts:FindChild("Outline"):SetCheck(false)
		
		for key,val in pairs(self.ktFonts[nBaseKey].sizeProp[strSize]) do
			if val == "B" then
				wndPropOpts:FindChild("Bold"):Enable(true)
			elseif val == "BB" then
				wndPropOpts:FindChild("BigBold"):Enable(true)
			elseif val == "BO" then
				wndPropOpts:FindChild("Bold"):Enable(true)
				wndPropOpts:FindChild("Outline"):Enable(true)
			elseif val == "BBO" then
				wndPropOpts:FindChild("BigBold"):Enable(true)
				wndPropOpts:FindChild("Outline"):Enable(true)
			elseif val == "I" then
				wndPropOpts:FindChild("Italic"):Enable(true)
			elseif val == "O" then
				wndPropOpts:FindChild("Outline"):Enable(true)
			end
		end		
		
		addon[strTextLoc].font = TableUtil:Copy(self.ktFonts[nBaseKey].defaultSettings)
	else
		Print("[PotatoUI] ERROR NBASEKEY")
	end
end

function PotatoLib:IncrementFontSize(wndHandler, addon) --PUI v2.8
	local strTextLoc = wndHandler:GetParent():GetParent():GetParent():GetName()
	
	local tFontData = addon[strTextLoc].font
	
	local nBaseKey = nil
	for key,val in pairs(self.ktFonts) do
		if tFontData.base == val.base then
			nBaseKey = key
		end
	end
	
	if nBaseKey ~= nil and self.ktFonts[nBaseKey] ~= nil then
		local tSizes = PotatoLib.ktFonts[nBaseKey].sizes
		for key,val in pairs(tSizes) do
			if tFontData.size.."" == val.."" then
				nSizeKey = key
			end
		end
		if nSizeKey ~= nil then
			local nChange = wndHandler:GetName() == "TextValueUp" and 1 or -1
			nSizeKey = nSizeKey + nChange
			
			if nSizeKey == #tSizes or nSizeKey == 1 then
				wndHandler:Enable(false)
			else
				for key, val in pairs(wndHandler:GetParent():GetChildren()) do
					val:Enable(true)
				end
			end
			
			--Set Editor Value
			wndHandler:GetParent():FindChild("TextValue"):SetText(self.ktFonts[nBaseKey].sizes[nSizeKey])
			--Set Data Value
			tFontData.size = self.ktFonts[nBaseKey].sizes[nSizeKey]	
			
			--Populate Text Options for Size	
			local wndPropOpts = wndHandler:GetParent():GetParent():GetParent():FindChild("TxtProps")
			wndPropOpts:FindChild("Bold"):Enable(false)
			wndPropOpts:FindChild("BigBold"):Enable(false)
			wndPropOpts:FindChild("Italic"):Enable(false)
			wndPropOpts:FindChild("Outline"):Enable(false)
			wndPropOpts:SetRadioSel("TxtWeight", 0)
			
			for key,val in pairs(self.ktFonts[nBaseKey].sizeProp[tFontData.size..""]) do
				if val == "B" then
					wndPropOpts:FindChild("Bold"):Enable(true)
				elseif val == "BB" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
				elseif val == "BO" then
					wndPropOpts:FindChild("Bold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "BBO" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "I" then
					wndPropOpts:FindChild("Italic"):Enable(true)
				elseif val == "O" then
					wndPropOpts:FindChild("Outline"):Enable(true)
				end
			end
		else
			Print("[PotatoUI] ERROR NSIZEKEY")
		end
	else
		Print("[PotatoUI] ERROR NBASEKEY")
	end	
end

function PotatoLib:PopulateTextOptions(wnd, tData, tTextType) --PUI v2.8
	for idx2=1, 3 do
		local strTextLoc = "text"..ktTextPos[idx2]
		if tData[strTextLoc] then
			local tCurrText = tData[strTextLoc]
			
			wnd:FindChild(strTextLoc):SetData({nFrameId, idx})
			
			if tTextType then
				local nType = tCurrText.type
				local wndTypeOpts = wnd:FindChild(strTextLoc):FindChild("TxtType")
				wndTypeOpts:FindChild("CurrentVal"):SetText(tTextType[nType][1])
				wndTypeOpts:FindChild("LeftScroll"):Enable(nType > 0)
				wndTypeOpts:FindChild("RightScroll"):Enable(nType < #tTextType)
			end
			
			local strBase = tCurrText.font.base
			local nBaseId = PotatoLib:GetFontKeyByBase(strBase)
			local ktFontData = PotatoLib:GetFontDataByBase(strBase)						
			local wndFontOpts = wnd:FindChild(strTextLoc):FindChild("TxtFont")
			wndFontOpts:FindChild("CurrentVal"):SetText(ktFontData.name)
			wndFontOpts:FindChild("CurrentVal"):SetFont(ktFontData.defaultStr)
			wndFontOpts:FindChild("LeftScroll"):Enable(nBaseId > 1)
			wndFontOpts:FindChild("RightScroll"):Enable(nBaseId < #PotatoLib.ktFonts)
			
			local strSize = tCurrText.font.size
			local nSizeId = PotatoLib:GetSizeKeyByBaseSize(nBaseId,strSize)
			local wndSizeOpts = wnd:FindChild(strTextLoc):FindChild("TxtSize")
			wndSizeOpts:FindChild("TextValue"):SetText(strSize)
			wndSizeOpts:FindChild("TextValueDown"):Enable(nSizeId > 1)
			wndSizeOpts:FindChild("TextValueUp"):Enable(nSizeId < #PotatoLib.ktFonts[nBaseId].sizes)
														
			local strProps = tCurrText.font.props
			local wndPropOpts = wnd:FindChild(strTextLoc):FindChild("TxtProps")
			wndPropOpts:FindChild("Bold"):Enable(false)
			wndPropOpts:FindChild("BigBold"):Enable(false)
			wndPropOpts:FindChild("Italic"):Enable(false)
			wndPropOpts:FindChild("Outline"):Enable(false)
			wndPropOpts:SetRadioSel("TxtWeight", 0)
			wndPropOpts:FindChild("Outline"):SetCheck(false)
	
			for key,val in pairs(PotatoLib.ktFonts[nBaseId].sizeProp[strSize..""]) do
				if val == "B" then
					wndPropOpts:FindChild("Bold"):Enable(true)
				elseif val == "BB" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
				elseif val == "BO" then
					wndPropOpts:FindChild("Bold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "BBO" then
					wndPropOpts:FindChild("BigBold"):Enable(true)
					wndPropOpts:FindChild("Outline"):Enable(true)
				elseif val == "I" then
					wndPropOpts:FindChild("Italic"):Enable(true)
				elseif val == "O" then
					wndPropOpts:FindChild("Outline"):Enable(true)
				end
			end
			local _, count = string.gsub(strProps, "I", "")
			if count == 1 then
				wndPropOpts:SetRadioSel("TxtWeight", 3)
				wndPropOpts:FindChild("Outline"):Enable(false)
			else
				_, count = string.gsub(strProps, "B", "")
				if count > 0 then
					wndPropOpts:SetRadioSel("TxtWeight", count)
				else
					wndPropOpts:SetRadioSel("TxtWeight", 0)
				end
			end
			_, count = string.gsub(strProps, "O", "")
			wndPropOpts:FindChild("Outline"):SetCheck(count == 1)
		end
	end
end

function PotatoLib:CloseEditorWnd()
	if self.previousElement and self.previousElement:FindChild("CustomizeBorder") then
		self.previousElement:FindChild("CustomizeBorder"):Show(false)
		self.previousElement:FindChild("EditorCover"):Show(true)
	end
	self.wndCustomize:Show(false)
end

function PotatoLib:PotatoPing()
	--[[local myName = GameLib.GetPlayerUnit():GetName()
	if myName == "Otatop" or myName == "Potato" or myName == "Perterter" or myName == "Pootato" or myName == "Tabbouleh" then
		if not bRecentPing then
			Print("[PotatoUI] PING SENT!")
			local t = {}
			t.strUser = GameLib.GetPlayerUnit():GetName()
			t.strMessage = "ping"
			self.chanPotato:SendMessage(t) --send to others
			
			self:OnPotatoMessage(nil, t) --"send" to self
			self.pongCounter = 0
			self.wndPing:FindChild("Grid"):DeleteAll()
			
			bRecentPing = true
			Apollo.StartTimer("PingTimer")
		else
			Print("[PotatoUI] Pung too soon.")
		end
	end]]--
end

function PotatoLib:OnPotatoMessage(channel, tMsg, strSender)
	--[[
	local myName = GameLib.GetPlayerUnit():GetName()
	local myLevel = GameLib.GetPlayerUnit():GetLevel()
	local myClass = GameLib.GetClassName(GameLib.GetPlayerUnit():GetClassId())
	local myLocation = GameLib.GetCurrentZoneMap().strName
	
	local senderName = tMsg.strUser
	local senderLevel = tMsg.strLevel and tMsg.strLevel or "nil" --TODO: Remove this when significantly into updates
	local senderClass = tMsg.strClass and tMsg.strClass or "nil" --TODO: Remove this when significantly into updates
	local senderLocation = tMsg.strLocation and tMsg.strLocation or "nil" --TODO: Remove this when significantly into updates
	local senderVersion = tMsg.strVersion and tMsg.strVersion or "<=2.5.4" --TODO: Remove this when significantly into updates
	
	local strMessage = tMsg.strMessage
	
	if myName == "Otatop" or myName == "Potato" or myName == "Perterter" or myName == "Pootato" or myName == "Tabbouleh" then
		if strMessage == "ping" then
			Print(senderName)
		end
		if strMessage == "PONG!" then
			self.pongCounter = self.pongCounter+1
			
			local wndGrid = self.wndPing:FindChild("Grid")
			local iCurrRow = wndGrid:AddRow(self.pongCounter)
			
			wndGrid:SetCellText(iCurrRow, 1, senderName)
			if senderLevel < 10 then
				senderLevel = "0"..senderLevel
			end
			wndGrid:SetCellText(iCurrRow, 2, senderLevel)
			wndGrid:SetCellText(iCurrRow, 3, senderClass)
			wndGrid:SetCellText(iCurrRow, 4, senderLocation)
			wndGrid:SetCellText(iCurrRow, 5, senderVersion)
			wndGrid:SetCellText(iCurrRow, 6, self.pongCounter)
			
			self.wndPing:FindChild("UserNo"):SetText(self.pongCounter)
			self.wndPing:Show(true)
		end
	else
		if not bRecentPing and strMessage == "ping" then
			local t = {}
			t.strUser = myName
			t.strMessage = "PONG!"
			t.strLevel = myLevel
			t.strClass = myClass
			t.strLocation = myLocation
			t.strVersion = strVersion
			self.chanPotato:SendMessage(t)
			bRecentPing = true
			Apollo.StartTimer("PingTimer")
		end
	end]]--
end

function PotatoLib:OnPingTimerEnd()
	bRecentPing = false
end

function PotatoLib:OnAHToolboxEnd()
	if not self.wndDropdown:ContainsMouse() and self.strCharacterName == "Potato" then
		--self.wndDropdown:TransitionMove(!)!!
		--self:ShowToolbox(false)
		self:ToolboxTransition(false)
	end
end

function PotatoLib:ToolboxTransition(bShow)
	if self.strCharacterName == "Potato" then
		local tShown = WindowLocation.new({ fPoints = { 0, 0, 0, 0 }, nOffsets = { 0, 0, 370, 75 }})
		local tHidden = WindowLocation.new({ fPoints = { 0, 0, 0, 0 }, nOffsets = { 0, 0, 370, 30 }})
		if bShow then
			self.wndDropdown:FindChild("Container"):TransitionMove(tShown, 0.25)
		else
			self.wndDropdown:FindChild("Container"):TransitionMove(tHidden, 0.25)
		end
		self.wndDropdown:ToFront()
	end
end

function PotatoLib:PotatoSend(slashCommand, strMsg)
	local myName = GameLib.GetPlayerUnit():GetName()

	if myName == "Otatop" or myName == "Potato" or myName == "Perterter" or myName == "Pootato" then
		local t = {}
		t.strUser = myName
		t.strMessage = "PotatoAnnounce:" .. strMsg
		
		self.chanPotato:SendMessage(t)
	end
end	

function PotatoLib:OnSave(eLevel)  --TODO: Improve this code, it's hacky.
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
	    local tSave = {}
			tSave = {anchors = {self.wndEditorBtns:GetAnchorPoints()}, offsets = {self.wndEditorBtns:GetAnchorOffsets()}}
			tSave.bShowToolbox = bShowToolbox
			tSave.customColors = self.classColors.Custom
			tSave.colorStyle = self.strColorStyle
			
			tSave.bOldToolbox = self.bOldToolbox
			tSave.bForceSave = self.bForceSave
			tSave.bPositionCenter = self.bPositionCenter
			tSave.bTruncateText = self.bTruncateText
			tSave.bLowHPandCC = self.bLowHPandCC
						
	    return tSave
    elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		--[[local tAddons = {}
		
		for key, val in pairs(self.AddonsList) do
			if Apollo.GetAddon(val) ~= nil then
				table.insert(tAddons, val)
			end
		end
		
		self.tCharacters[self.strCharacterName] = tAddons]]--
		
		return nil
	else
		return nil
	end
end

function PotatoLib:OnRestore(eLevel, tData)  --TODO: Improve this code, it's hacky.
    if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
	    self.tSavedData = tData
		if tData.anchors and (tData.offsets[3]-tData.offsets[1] < 233) then
			self.wndEditorBtns:SetAnchorPoints(unpack(tData.anchors))
			self.wndEditorBtns:SetAnchorOffsets(tData.offsets[1], tData.offsets[2], tData.offsets[1]+233, tData.offsets[4])
		else
			self.wndEditorBtns:SetAnchorPoints(unpack(tData.anchors))
			self.wndEditorBtns:SetAnchorOffsets(unpack(tData.offsets))
		end
		
		bShowToolbox = tData.bShowToolbox
		self.wndEditorBtns:Show(bShowToolbox)
		
		if tData.colorStyle then
			self.strColorStyle = tData.colorStyle
		end
		if tData.customColors then
			self.classColors.Custom = tData.customColors
		end
		
		self.bOldToolbox = tData.bOldToolbox
		self.bForceSave = tData.bForceSave
		self.bPositionCenter = tData.bPositionCenter
		self.bTruncateText = tData.bTruncateText
		self.bLowHPandCC = tData.bLowHPandCC
				
	end
end

--Utility Functions
-- Convert a color object into a hex-encoded string using format "rrggbb"
function PotatoLib:Convert_CColor_To_String(c)
	return string.format("%02X%02X%02X", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end

function PotatoLib:Convert_String_To_CColor(hex)
	local r, g, b = 0, 0, 0 -- invalid strings will result in these values being returned
	local n = tonumber(hex, 16)
	if n then r = math.floor(n / 65536); g = math.floor(n / 256) % 256; b = n % 256 end
	return CColor.new(r / 255, g / 255, b / 255, 1)
end

function PotatoLib:RandomColor()
	local strColor = ""
	local tBuilder = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
	for idx=1,6 do
		strColor = strColor .. tBuilder[math.random(1,#tBuilder)]
	end
	return strColor
end

function PotatoLib:IsBarFull(tBars, unit)
	local bFull = true
	
	if type(tBars) == "string" then
		tBars = {tBars}
	end

	for key,val in pairs(tBars) do
		if val == "HP" or val == "Health" or val == "health" then
			if unit:GetHealth() ~= nil then
				if unit:GetHealth() < unit:GetMaxHealth() then
					return false
				end
			end
		end
		if val == "SP" or val == "Shield" or val == "shield" then
			if unit:GetShieldCapacity() ~= nil then
				if unit:GetShieldCapacity() < unit:GetShieldCapacityMax() then
					return false
				end
			end
		end
		if val == "mountHealth" or val == "MountHealth" or val == "MountHP" then
			if unit:GetMountHealth() ~= nil then
				if unit:GetMountHealth() < unit:GetMountMaxHealth() then
					return false
				end
			end

		end
		--TODO: Round this out if you need it.
	end
	return true
end

function PotatoLib:PrintAnchorStats(wnd)
	Print(wnd:GetName())
	Print(string.format("Anchors: %s, %s, %s, %s",wnd:GetAnchorPoints()))
	Print(string.format("Offsets: %s, %s, %s, %s",wnd:GetAnchorOffsets()))
end

function PotatoLib:PercentToHex(nPercent)
	return string.format("%X", 255*nPercent/100)
end

function PotatoLib:HexStr2RGBTable(hex)
  hex = hex:gsub("#","")
  return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)), tonumber("0x"..hex:sub(7,8))}
end

function PotatoLib:HexStr2ColorTable(hex)
  hex = hex:gsub("#","")
  return {a=tonumber("0x"..hex:sub(1,2))/255, r=tonumber("0x"..hex:sub(3,4))/255, g=tonumber("0x"..hex:sub(5,6))/255, b=tonumber("0x"..hex:sub(7,8))/255}
end

function PotatoLib:RGBTable2HexStr(tColor)
    local sColor = ""
	for idx=1, #tColor do
	    local strColor = string.format ( "%X", tColor[idx] )
	    sColor = ( ( string.len ( strColor ) == 1 ) and ( "0" .. strColor ) or strColor )
	end
    return sColor
end


function PotatoLib:SetBarVars(bar, barWnd, curr, max)
	barWnd:FindChild(bar):SetMax(max)
	barWnd:FindChild(bar):SetProgress(curr)
end

function PotatoLib:SetBarVars2(barWnd, curr, max)
	barWnd:SetMax(max)
	barWnd:SetProgress(curr)
end

function PotatoLib:DrawPixie(wnd, tAnchors, tOffsets, strColor)
	local tLoc = {
		fPoints = tAnchors,
		nOffsets = tOffsets
	}
	
	self:HexStr2RGBTable(strColor)

	wnd:AddPixie({
		iLayer = 2,
		bLine = false,
		strSprite = "ClientSprites:WhiteFill",
		cr = tColor,
		loc = tLoc})
end

function PotatoLib:UpdateBorder(wnd, wndContent, tBorderData) --New PUI v2.0 function
	local bShow = tBorderData.show
	local strTrans = PotatoLib:PercentToHex(tBorderData.transparency)
	local strColor = tBorderData.color
	local nBorderSize = tBorderData.size
	local tBorderColor = PotatoLib:HexStr2ColorTable(strTrans..strColor)
						--Right, Left, Top, Bottom
	local tOffsetFormat = {{-1,1,0,-1},{0,1,1,-1},{0,0,0,1},{0,-1,0,0}}
	for idx=1,4 do
		local tPixie = wnd:GetPixieInfo(idx)
		tPixie.cr = bShow and tBorderColor or {a=0,r=0,g=0,b=0}
		for idx2, val in pairs(tPixie.loc.nOffsets) do
			tPixie.loc.nOffsets[idx2] = tOffsetFormat[idx][idx2]*nBorderSize
		end
		wnd:UpdatePixie(idx, tPixie)
	end
	
	if bShow then
		wndContent:SetAnchorOffsets(nBorderSize, nBorderSize, -nBorderSize, -nBorderSize)
		if wnd:FindChild("EditorCover") then
			wnd:FindChild("EditorCover"):SetAnchorOffsets(nBorderSize, nBorderSize, -nBorderSize, -nBorderSize)
		end
	else
		wndContent:SetAnchorOffsets(0,0,0,0)
		if wnd:FindChild("EditorCover") then
			wnd:FindChild("EditorCover"):SetAnchorOffsets(0,0,0,0)
		end
	end
end

function PotatoLib:SetBarAppearance(bar, barWnd, texture, color, percentTrans) 
    --Consider: input from Colorpicker will be at least 6 hex, possibly 8 hex. You can append 2 hex transparency with slider value stored to percentTrans.
    
    local transHex = "ff"
    local colorStr = "pink"
    
    if percentTrans and type(percentTrans) == "number" then
    	transHex = string.format("%x", (percentTrans/100)*255)
    end
    
    if tonumber("0x"..color) then
    	if string.len(color) == 6 then
    	    colorStr = transHex .. color
    	else
    	    colorStr = color
    	end
    else
    	colorStr = color
    end  	

    --Set Bar Color/transparency
	if texture == "TrueFrost" then
    	barWnd:FindChild(bar):SetBarColor("FFFFFFFF")
	else
    	barWnd:FindChild(bar):SetBarColor(colorStr)
	end
    
    --Set Bar Texture
    barWnd:FindChild(bar):SetFillSprite("BarSprites:" .. texture)
    barWnd:FindChild(bar):SetFullSprite("BarSprites:" .. texture)
end

function PotatoLib:SetBarAppearance2(barWnd, texture, color, percentTrans) 
    --Consider: input from Colorpicker will be at least 6 hex, possibly 8 hex. You can append 2 hex transparency with slider value stored to percentTrans.
    
    local transHex = "ff"
    local colorStr = "pink"
    
    if percentTrans and type(percentTrans) == "number" then
    	transHex = string.format("%x", (percentTrans/100)*255)
    end
    
    if tonumber("0x"..color) then
    	if string.len(color) == 6 then
    	    colorStr = transHex .. color
    	else
    	    colorStr = color
    	end
    else
    	colorStr = color
    end  	

    --Set Bar Color/transparency
	if texture == "TrueFrost" then
    	barWnd:SetBarColor("FFFFFFFF")
	else
    	barWnd:SetBarColor(colorStr)
	end
    
    --Set Bar Texture
	self:SetBarSprite(barWnd, texture)
end

function PotatoLib:SetSprite(wnd, sprite)
	wnd:SetSprite("BarSprites:" .. sprite)
end

function PotatoLib:SetBarSprite(wnd, sprite)
	if wnd == nil then return end
	
	if sprite == "WhiteFill" then
		wnd:SetFillSprite("WhiteFill")
		wnd:SetFullSprite("WhiteFill")
	else
		wnd:SetFillSprite("BarSprites:" .. sprite)
		wnd:SetFullSprite("BarSprites:" .. sprite)
	end
end

function PotatoLib:SetSpriteAppearance(wnd, container, texture, color, percentTrans)
    local transHex = "ff"
    local colorStr = "pink"
    
    if percentTrans and type(percentTrans) == "number" then
    	transHex = string.format("%x", (percentTrans/100)*255)
    end
    
    if tonumber("0x"..color) then
    	if string.len(color) == 6 then
    	    colorStr = transHex .. color
    	else
    	    colorStr = color
    	end
    else
    	colorStr = color
    end  	

    --Set Bar Color/transparency
    container:FindChild(wnd):SetBGColor(colorStr)
    
    --Set Bar Texture
    container:FindChild(wnd):SetSprite("BarSprites:" .. texture)
end

function PotatoLib:GetClassResource(unit)
	local classID = unit:GetClassId()
	
	if classID == GameLib.CodeEnumClass.Engineer or	classID == GameLib.CodeEnumClass.Warrior then
		return unit:GetResource(1), unit:GetMaxResource(1)
	elseif classID == GameLib.CodeEnumClass.Stalker then
		return unit:GetResource(3), unit:GetMaxResource(3)
	else
		if unit:GetFocus() == nil then
			return 0,0
		else
			return unit:GetFocus(), unit:GetMaxFocus() ~= 0 and unit:GetMaxFocus() or 1000
		end
	end
end

function PotatoLib:TextTruncate(strFont, strText, nWidth)
	local strCurrText = ""
	for c in strText:gmatch"." do
		if Apollo.GetTextWidth(strFont, strCurrText..c.."...") > nWidth then
			break
		end
	    strCurrText = strCurrText..c
	end

	return strCurrText.."..."
end

function PotatoLib:TextSquish(strText, wnd, strType, nPadding)
	strType = strType or ""
	nPadding = nPadding or 0
	
	local tCRBFonts = {
		{size=9, height=13},
		{size=10, height=14},
		{size=11, height=15},
		{size=12, height=17},
		{size=14, height=20},
		{size=16, height=22}
	}
	local nWndWidth = wnd:GetWidth()
	local nWndHeight = wnd:GetHeight()
	local previousFont = "CRB_Pixel_O"
	
	for idx=1, #tCRBFonts do
		--Print(idx)
		local fontName = "CRB_Interface"..tCRBFonts[idx].size
		local tVariations = { fontName..strType} --fontName,	fontName.."_O",	fontName.."_B",	fontName.."_BO",	fontName.."_BB",	fontName.."_BBO"}
		
		for idx2=1, #tVariations do
			local fontHeight = tCRBFonts[idx].height + nPadding
			if string.find(tVariations[idx2], "O") then fontHeight = fontHeight + 1 end
			local fontWidth = Apollo.GetTextWidth(tVariations[idx2], strText) + nPadding
			
			if nWndWidth >= fontWidth and nWndHeight >= fontHeight then
				previousFont = tVariations[idx2]
			else
				break
			end
		end
		--Print("end: " ..previousFont)
		wnd:SetText(strText)
		wnd:SetFont(previousFont)
	end
end

function PotatoLib:WindowMove(wndHandler)
	self:MoveLockedWnds(wndHandler)
	
	if editorMode and self.wndCustomize then
		local wndEditorContent = self.wndCustomize:FindChild("EditorContent")
		
		local nScreenX, nScreenY = Apollo.GetScreenSize()
		local nX1, nY1, nX2, nY2 = wndHandler:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndHandler:GetAnchorPoints()
		
		if self.bPositionCenter then
			nAX1 = nAX1-0.5
			nAY1 = nAY1-0.5
			nAX2 = nAX2-0.5
			nAY2 = nAY2-0.5
		end	
		
		if self.wndCustomize:FindChild("XPos") ~= nil then
			self.wndCustomize:FindChild("XPos"):SetText(nX1+(nAX1*nScreenX))
			self.wndCustomize:FindChild("YPos"):SetText(nY1+(nAY1*nScreenY))
			self.wndCustomize:FindChild("Width"):SetText(nX2-nX1)
			self.wndCustomize:FindChild("Height"):SetText(nY2-nY1)
		end
	end
end

function PotatoLib:HandleLockedWnd(wndTarget, strName) --PUI v2.8	
	if self.tLockedWindows[strName] then
		wndTarget:FindChild("EditorCover"):FindChild("Lock:Sprite"):SetSprite("CRB_AMPs:spr_AMPs_LockStretch_Grey")
		self.tLockedWindows[strName] = nil
		return
	else
		self.tLockedWindows[strName] = {offsets={wndTarget:GetAnchorOffsets()}, window=wndTarget}
		wndTarget:FindChild("Sprite"):SetSprite("CRB_AMPs:spr_AMPs_LockStretch_Blue")	
	end
end

function PotatoLib:MoveLockedWnds(wndMover, nOldLeft, nOldTop) --PUI v2.8
	local nOldLeft, nOldTop = nil, nil
	
	for key,val in pairs(self.tLockedWindows) do
		if val.window == wndMover then
			nOldLeft, nOldTop = val.offsets[1], val.offsets[2]
		end
	end
	
	if nOldLeft == nil or nOldTop == nil then return end 

	local nNewLeft, nNewTop, nNewRight, nNewBottom = wndMover:GetAnchorOffsets()
	local nLDiff, nTDiff = nNewLeft-nOldLeft, nNewTop-nOldTop

	for key,val in pairs(self.tLockedWindows) do
		if val.window ~= wndMover then
			local wndCurrwnd = val.window
			local nLeft, nTop, nRight, nBottom = wndCurrwnd:GetAnchorOffsets()
			wndCurrwnd:SetAnchorOffsets(nLeft+nLDiff, nTop+nTDiff, nRight+nLDiff, nBottom+nTDiff)
			self.tLockedWindows[key].offsets = {nLeft+nLDiff, nTop+nTDiff, nRight+nLDiff, nBottom+nTDiff}
		else
			val.offsets = {nNewLeft, nNewTop, nNewRight, nNewBottom}
		end
	end
end

function PotatoLib:OnSystemKeyDown(iKey)
	if editorMode and self.previousElement ~= nil then
		local tLoc = {self.previousElement:GetAnchorOffsets()}
		if (iKey >= 37 and iKey <= 40) or (iKey == 98 or iKey == 100 or iKey == 102 or iKey == 104) then
			if iKey == 38 then --Move UP
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2]-1, tLoc[3], tLoc[4]-1)
			end
			if iKey == 40 then --Move DOWN
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2]+1, tLoc[3], tLoc[4]+1)
			end
			if iKey == 37 then --Move Left
				self.previousElement:SetAnchorOffsets(tLoc[1]-1, tLoc[2], tLoc[3]-1, tLoc[4])
			end
			if iKey == 39 then --Move Right
				self.previousElement:SetAnchorOffsets(tLoc[1]+1, tLoc[2], tLoc[3]+1, tLoc[4])
			end
			if iKey == 104 then --Resize UP
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2]-1, tLoc[3], tLoc[4])
			end
			if iKey == 98 then -- Resize DOWN
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2]+1, tLoc[3], tLoc[4])
			end
			if iKey == 100 then --Resize Left
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2], tLoc[3]-1, tLoc[4])
			end
			if iKey == 102 then --Resize Right
				self.previousElement:SetAnchorOffsets(tLoc[1], tLoc[2], tLoc[3]+1, tLoc[4])
			end
			self:WindowMove(self.previousElement)
		end
	end
end 
	

---------------------------------------------------------------------------------------------------
-- PingFrame Functions
---------------------------------------------------------------------------------------------------

function PotatoLib:ClosePingFrame( wndHandler, wndControl, eMouseButton )
	self.pongCounter = 0
	self.wndPing:Show(false)
end

---------------------------------------------------------------------------------------------------
-- Form4 Functions
---------------------------------------------------------------------------------------------------

function PotatoLib:CloseSettingsWnd( wndHandler, wndControl, eMouseButton )
end

PotatoLib.ktFonts = {
	{
		name = "Standard",
		base = "CRB_Interface",
		defaultStr = "CRB_Interface12",
		defaultSettings = {base="CRB_Interface",size="12",props=""},
		sizeProp = {["9"]={"B","BB","BBO","O","I","BO"},["10"]={"B","BB","BBO","O","I","BO"},
					["11"]={"B","BB","BBO","O","I","BO"},["12"]={"B","BB","BBO","O","I","BO"},
					["14"]={"B","BB","BBO","O","I","BO"},["16"]={"B","BB","BBO","O","I","BO"}},
		sizes = {9,10,11,12,14,16}
	},
	{
		name = "Wildstar",
		base = "CRB_Header",
		defaultStr = "CRB_Header12",
		defaultSettings = {base="CRB_Header",size="12",props=""},
		sizeProp = {["9"]={},["10"]={},["11"]={"O"},["12"]={"O"},["13"]={"O"},["14"]={"O"},["16"]={"O"},["20"]={"O"},
					["24"]={"O"}},
		sizes = {9,10,11,12,13,14,16,20,24}
	},
	{
		name = "Pixel",
		base = "CRB_Pixel",
		defaultStr = "CRB_Pixel",
		defaultSettings = {base="CRB_Pixel",size="",props=""},
		sizeProp = {[""]={"O"}},
		sizes = {""}
	},
	{
		name = "Action",
		base = "CRB_Floater",
		defaultStr = "CRB_FloaterSmall",
		defaultSettings = {base="CRB_Floater",size="Small",props=""},
		sizeProp = {["Small"]={},["Medium"]={},["Large"]={},["Huge"]={"O"},["Gigantic"]={"O"}},
		sizes = {"Small","Medium","Large","Huge","Gigantic"}
	},
	{
		name = "Courier",
		base = "Courier",
		defaultStr = "Courier",
		defaultSettings = {base="Courier",size="",props=""},
		sizeProp = {[""]={}},
		sizes = {""}
	},
	{
		name = "Alien",
		base = "CRB_Alien",
		defaultStr = "CRB_AlienMedium",
		defaultSettings = {base="CRB_Alien",size="Medium",props=""},
		sizeProp = {["Small"]={},["Medium"]={},["Large"]={}},
		sizes = {"Small", "Medium", "Large"}
	},
}

---------------------------------------------------------------------------------------------------
-- TempEditorBtns1 Functions
---------------------------------------------------------------------------------------------------

function PotatoLib:OnHoverTrigger( wndHandler, wndControl, x, y )
	--self:ShowToolbox(true)
	self:ToolboxTransition(true)
end

function PotatoLib:OnToolboxExit( wndHandler, wndControl, x, y )
	if wndHandler == wndControl and wndHandler:FindChild("Buttons"):IsVisible() then
		Apollo.CreateTimer("AHToolboxTimer", 2, false) --AH = autohide
		Apollo.StartTimer("AHToolboxTimer")
	end
end

function PotatoLib:ShowToolbox(bShow)
	if self.strCharacterName == "Potato" then
		self.wndDropdown:FindChild("Container"):Show(bShow)
	end
end

function PotatoLib:ToolboxMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if self.strCharacterName == "Potato" then
		local nLeft, nTop, nRight, nBottom = wndHandler:GetAnchorOffsets()
		if nTop ~= -20 then
			wndHandler:SetAnchorOffsets(nLeft, -20, nRight, 55)
		end
	end
end

function PotatoLib:OnPUISettings()
	if self.wndSettings == nil or #self.wndSettings:GetChildren() == 0 then
		self.wndSettings = Apollo.LoadForm(self.xmlDoc, "Settings", nil, self)
		self.wndSettings:FindChild("GeneralBtn"):AttachWindow(self.wndSettings:FindChild("GeneralSettings"))
		self.wndSettings:FindChild("EnableDisableBtn"):AttachWindow(self.wndSettings:FindChild("EnableDisableSettings"))
		self.wndSettings:FindChild("ClassColorsBtn"):AttachWindow(self.wndSettings:FindChild("ClassColors"))
		self.wndSettings:FindChild("StyleSelection"):AttachWindow(self.wndSettings:FindChild("StyleDropdown")) -- MOVE ME
		self.wndSettings:FindChild("ResetFeaturesBtn"):AttachWindow(self.wndSettings:FindChild("ResetFeatures"))
		self.wndSettings:FindChild("ProfilesBtn"):Enable(false)
	end
	self.wndSettings:Show(true)
	self:PopulateGeneralSetings()
	self:PopulateEnableDisableSetings()
	self:PopulateResetFeatures()
end

---------------------------------------------------------------------------------------------------
-- ConfirmReset Functions
---------------------------------------------------------------------------------------------------

function PotatoLib:OnResetYesBtn( wndHandler, wndControl, eMouseButton )
	Event_FireGenericEvent("PotatoReset")
	if self.previousElement ~= nil then
		self.previousElement:FindChild("EditorCover"):Show(true)
		self.previousElement:FindChild("CustomizeBorder"):Show(false)
		self.previousElement = nil
	end
	
	--Clear locked window icons and destroy information
	for key, val in pairs(self.tLockedWindows) do
		if #val.window:GetChildren() > 0 then
			val.window:FindChild("Lock"):FindChild("Sprite"):SetSprite("CRB_AMPs:spr_AMPs_LockStretch_Grey")
		end
	end
	self.tLockedWindows = {}
	
	--Close + Destroy Customize Window
	self:OnCloseReset()
end

function PotatoLib:OnCloseReset( wndHandler, wndControl, eMouseButton )
	self.wndConfirmReset:Show(false)
end

---------------------------------------------------------------------------------------------------
-- Settings Functions
---------------------------------------------------------------------------------------------------
function PotatoLib:SettingsListHover(bHover, wndListItem)
	wndListItem:FindChild("Text"):SetTextColor(bHover and "AttributeDexterity" or "FFFFFFFF")
	
	local strItemName = wndListItem:GetName()
	
	if strItemName == "GeneralSettings" or strItemName == "EnableDisable" or strItemName == "Profiles" or strItemName == "MenuItem" then --Has arrow
		wndListItem:FindChild("Arrow"):SetBGColor(bHover and "AttributeName" or "FFFFFFFF")
	elseif strItemName == "MenuItemExpand" then --Has expander
		local bExpanded = nil --Factor in when doing expansion.
		local strState = bHover and "Flyby" or "Normal"
		wndListItem:FindChild("Expand"):SetSprite("BK3:btnHolo_ExpandCollapse"..strState)
	end
end

function PotatoLib:OnSettingListEnter( wndHandler, wndControl, x, y )
	local wndListItem = wndHandler:GetParent()
	
	self:SettingsListHover(true, wndListItem)
end

function PotatoLib:OnSettingListExit( wndHandler, wndControl, x, y )
	local wndListItem = wndHandler:GetParent()
	
	self:SettingsListHover(false, wndListItem)
end

function PotatoLib:OnHeaderToggle( wndHandler, wndControl, eMouseButton )
	local bActivated = true
	local tActivatedData = wndHandler:GetData()
	
	local nCurrHeight = wndHandler:GetParent():GetHeight()
	local nLeft,nTop,nRight,nBottom = wndHandler:GetParent():GetAnchorOffsets()
	
	if tActivatedData ~= nil then --Check to see if frame has activation state data.
		bActivated = tActivatedData.bActivated
	else
		tActivatedData = {bActivated=bActivated, nHeight = nCurrHeight}
		wndHandler:SetData(tActivatedData) --If not, store it.
	end
	
	bActivated = not bActivated
	tActivatedData.bActivated = bActivated
	
	wndHandler:GetParent():SetAnchorOffsets(0, 0, 0, bActivated and tActivatedData.nHeight or 35)
	wndHandler:SetData(tActivatedData) --Update activated status, while retaining height.
	
	wndHandler:GetParent():GetParent():ArrangeChildrenVert()
end

function PotatoLib:OnCloseSettings( wndHandler, wndControl, eMouseButton )
	self.wndSettings:Close()
end

function PotatoLib:OnSettingsClosed( wndHandler, wndControl )
	if wndHandler ~= wndControl then return end
	self.wndSettings:Destroy()
end


---------------------------------------------------------------------------------------------------
-- Enable/Disable Functions
---------------------------------------------------------------------------------------------------
function PotatoLib:PopulateEnableDisableSetings()
	local wndResources = self.wndSettings:FindChild("EnableDisableItem")
	local PRes = Apollo.GetAddon("PotatoResources")
	if PRes then
		wndResources:FindChild("Enabled"):FindChild("CheckBox"):SetCheck(PRes.bPUIEnable)
		wndResources:FindChild("RetainCarbine"):FindChild("CheckBox"):SetCheck(PRes.bCRBEnable)
	end
end

function PotatoLib:OnToggleResources( wndHandler, wndControl, eMouseButton )
	local bCheck = wndHandler:IsChecked()
	
	Apollo.GetAddon("PotatoResources").bPUIEnable = bCheck
end

function PotatoLib:OnToggleCRBResources( wndHandler, wndControl, eMouseButton )
	local bCheck = wndHandler:IsChecked()
	
	Apollo.GetAddon("PotatoResources").bCRBEnable = bCheck
end

---------------------------------------------------------------------------------------------------
-- GeneralSettings Functions
---------------------------------------------------------------------------------------------------
function PotatoLib:PopulateGeneralSetings()
	--Populate General section
	self.wndSettings:FindChild("ForcedEditorSave"):SetCheck(self.bForceSave)
	self.wndSettings:FindChild("OldPUIToolboxBtn"):SetCheck(self.bOldToolbox)
	self.wndSettings:FindChild("FramePositionBase"):SetCheck(self.bPositionCenter)
	self.wndSettings:FindChild("TruncateText"):SetCheck(self.bTruncateText)
	self.wndSettings:FindChild("LowHPandCC"):SetCheck(self.bLowHPandCC)
	
	--Populate Class Colors section
	self:UpdateClassColors()
end

function PotatoLib:OnForcedSaveChange( wndHandler, wndControl, eMouseButton )
	local bState = wndHandler:IsChecked()
	
	self.bForceSave = bState
end

function PotatoLib:OnFrameBaseChange( wndHandler, wndControl, eMouseButton )
	local bState = wndHandler:IsChecked()
	
	self.bPositionCenter = bState
end

function PotatoLib:OnTruncateChange( wndHandler, wndControl, eMouseButton )
	local bState = wndHandler:IsChecked()
	
	self.bTruncateText = bState
end

function PotatoLib:OnLowHPandCCChange( wndHandler, wndControl, eMouseButton )
	local bState = wndHandler:IsChecked()
	
	self.bLowHPandCC = bState
end
---------------------------------------------------------------------------------------------------
-- ClassColor Functions
---------------------------------------------------------------------------------------------------

function PotatoLib:OnClassColorSwatch( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local strClass = wndHandler:GetParent():GetName()
	local tColorData = {window=wndHandler, class=strClass}
	
	if self.strColorStyle ~= "Custom" then		
		--Prompt user to copy settings
		self.wndSettings:FindChild("CustomWarning"):Show(true)
		self.wndSettings:FindChild("CustomWarning"):SetData(tColorData)
	else
		self:EditColorSwatch(tColorData)
	end
end

function PotatoLib:ConfirmColorCopy( wndHandler, wndControl, eMouseButton )
	--Switch to custom and copy current style colors
	self.classColors.Custom = TableUtil:Copy(self.classColors[self.strColorStyle]) --Copy over previous style
	self.wndSettings:FindChild(self.strColorStyle):SetCheck(false) --Unselect previous style in style list
	self.strColorStyle = "Custom" --Change style to Custom
	self:UpdateClassColors()

	--Edit color here if not on 
	local tColorData = wndHandler:GetParent():GetData()
	self:EditColorSwatch(tColorData)
	
	self:CloseColorCopyWarning()
end

function PotatoLib:CloseColorCopyWarning( wndHandler, wndControl, eMouseButton )
	self.wndSettings:FindChild("CustomWarning"):Show(false)
end

function PotatoLib:EditColorSwatch(tColorData)
	self:OnSetColor(tColorData)
end

local function OnSetColorUpdate(tColorData)
	local self = Apollo.GetAddon("PotatoLib")
	
	local vClass = GameLib.CodeEnumClass[tColorData.class] or tColorData.class
	local strNewColor = PotatoLib:Convert_CColor_To_String(daCColor)
	
	tColorData.window:SetBGColor("FF"..strNewColor)
	self.classColors.Custom[vClass] = strNewColor
end

function PotatoLib:OnSetColor(tColorData)
	local vClass = GameLib.CodeEnumClass[tColorData.class] or tColorData.class
	local strInitialColor = self.classColors[self.strColorStyle][vClass]
	daCColor = PotatoLib:Convert_String_To_CColor(strInitialColor)
	if ColorPicker then	ColorPicker.AdjustCColor(daCColor, false, OnSetColorUpdate, tColorData)	else Print("[Potato UI] ColorPicker addon is not installed, please redownload/install PotatoUI") end
end

function PotatoLib:UpdateClassColors()
	local wndClassColors = self.wndSettings:FindChild("ClassColors"):FindChild("Settings")
	local strStyle = self.strColorStyle
	
	--Populate style field and dropdown
	wndClassColors:FindChild("StyleDropdown"):FindChild(strStyle):SetCheck(true)
	wndClassColors:FindChild("StyleSelection"):SetText(strStyle == "Carbine" and "Carbine (Default)" or strStyle)
	
	--Check to see if addon is present to extract colors from
	local bAddonPresent = false
	local addonAddon = nil
	if strStyle ~= "Custom" and strStyle ~= "Carbine" then
		addonAddon = Apollo.GetAddon(strStyle)
		bAddonPresent = addonAddon ~= nil
	end	
	
	--Cycle through classes and populate colors
	for key,wnd in pairs(wndClassColors:GetChildren()) do
		local strClass = wnd:GetName()
		strClass = GameLib.CodeEnumClass[strClass] or strClass
		if strClass ~= "Styles" then
			if self.strColorStyle ~= "Custom" then
				if bAddonPresent then
					local strAddonColor = self:GetAddonColor(strStyle, addonAddon, strClass)
					wnd:FindChild("Color"):SetBGColor("FF"..strAddonColor)
					self.classColors[strStyle][strClass] = strAddonColor
				else
					wnd:FindChild("Color"):SetBGColor("FF"..self.classColors[strStyle][strClass])
				end
			else
				strClass = GameLib.CodeEnumClass[strClass] or strClass
				local strColor = self.classColors["Custom"][strClass]
				local strTrans = #tostring(strColor) == 6 and "FF" or ""
				wnd:FindChild("Color"):SetBGColor(strTrans..strColor)
			end
		end
	end
end

function PotatoLib:GetAddonColor(strStyle, addonAddon, strClass)
	if strStyle == "BijiPlates" then
		if strClass ~= "Hostile" and strClass ~= "Neutral" and strClass ~= "Friendly" then
			strClass = GameLib.GetClassName(strClass)
		end
		return addonAddon["setColor"..strClass.."Bar"]
	elseif strStyle =="Grid" then
		local strColor = ""
		if strClass == "Hostile" or strClass == "Neutral" or strClass == "Friendly" then
			strColor = "FF"..self.classColors.Carbine[strClass]
		else
			strClass = GameLib.GetClassName(strClass)
			strColor = addonAddon.settings.classColors[GameLib.CodeEnumClass[strClass]]
		end
		return string.sub(strColor,3,#strColor)
	end
end

function PotatoLib:OnClassColorStyleBtn( wndHandler, wndControl, eMouseButton )
	local bChecked = wndHandler:IsChecked()
	
	--Disable or enable class color fields
	for key, val in pairs(self.wndSettings:FindChild("ClassColors"):FindChild("Settings"):GetChildren()) do
		if val:GetName() ~= "Styles" then
			val:Enable(not bChecked)
		end
	end
end

function PotatoLib:OnClassColorSelection( wndHandler, wndControl, eMouseButton )
	self.wndSettings:FindChild("StyleDropdown"):Close()
	
	local strNewStyle = wndHandler:GetName()
	self.strColorStyle = strNewStyle
	
	self:UpdateClassColors()
	
	--Reenable class color fields
	for key, val in pairs(self.wndSettings:FindChild("ClassColors"):FindChild("Settings"):GetChildren()) do
		if val:GetName() ~= "Styles" then
			val:Enable(true)
		end
	end
end

local colorWIP = CColor.new(0, 1, 1, 1)

function PotatoLib:ColorUpdate()
	local tParent = self.tCurrColor.tParent
	local strColorName = self.tCurrColor.strColorName
	local fCallback = self.tCurrColor.fCallback
	local wndSwatch = self.tCurrColor.wndSwatch
	
	local strColor = self:Convert_CColor_To_String(colorWIP)
	
	tParent[strColorName] = strColor
	
	if wndSwatch then
		wndSwatch:SetBGColor("FF"..strColor)
		local wndTextureBar = wndSwatch:GetParent():GetParent():GetParent()
		if wndTextureBar then
			wndTextureBar:FindChild("BarTexture:BarType:CurrentVal"):SetBGColor("FF"..strColor)
		end
	end
	
	if fCallback ~= nil and type(fCallback) == "function" then
		fCallback(tParent)
	end
end

function PotatoLib:ColorPicker(strColorName, tParent, fCallback, wndSwatch) --PUI v2.8 E.g. if you wanted to set PotatoCastbar.BGColor, you would call PotatoLib:ColorPicker("BGColor", self, ...) where self = PotatoCastbar
	self.tCurrColor = {strColorName=strColorName, tParent=tParent, fCallback=fCallback, wndSwatch=wndSwatch, vArg}
	
	local vColor = tParent[strColorName]
	
	if type(vColor) == "string" then
		colorWIP = self:Convert_String_To_CColor(vColor)
	elseif type(vColor) == "table" then
		colorWIP = CColor.new(vColor.r, vColor.g, vColor.b, vColor.a)
	else
		Print("[Potato UI] ColorPicker error.")
		return
	end

	if ColorPicker then	ColorPicker.AdjustCColor(colorWIP, false, PotatoLib.ColorUpdate, self)	else Print("[Potato UI] ColorPicker addon is not installed, please redownload/install PotatoUI") end
end

function PotatoLib:OnCharacterCreated() --PUI v2.8
	self.bInCombat = GameLib.GetPlayerUnit():IsInCombat()
end

function PotatoLib:OnEnteredCombat(unit, bInCombat) --PUI v2.8
	if unit:GetName() == GameLib.GetPlayerUnit():GetName() then
		self.bInCombat = bInCombat
	end
end

-----------------------------------------------------------------------------------------------
-- Reset Features Functions --PUI v2.8.1
-----------------------------------------------------------------------------------------------

function PotatoLib:PopulateResetFeatures() --PUI v2.8.1
	Print("PRFSend")
	Event_FireGenericEvent("PotatoResetPopulate")
end

function PotatoLib:OnPRFReset()
	Print("PLib")
end

function PotatoLib:AddResetParent(strName) --PUI v2.8.1
	local wndResetFeatures = self.wndSettings:FindChild("ResetFeatures")
	local wndContainer = wndResetFeatures:FindChild("FeatureList")

	local wndParent = Apollo.LoadForm(self.xmlDoc, "FeatureResetParent", wndContainer, self)
	wndParent:FindChild("Feature"):SetText(strName)
	wndParent:SetName(strName)
	
	wndContainer:ArrangeChildrenVert()
end

function PotatoLib:ResetParentToggle(wndHandler) --PUI v2.8.1
	local wndResetFeatures = self.wndSettings:FindChild("ResetFeatures")
	local wndContainer = wndResetFeatures:FindChild("FeatureList")

	local bCheck = wndHandler:IsChecked()
	local wndParent = wndHandler:GetParent()
	
	if bCheck then
		local nHeight = wndParent:FindChild("Container"):ArrangeChildrenVert()
		wndParent:SetAnchorOffsets(0,0,0,30+10+nHeight)
	else
		wndParent:SetAnchorOffsets(0,0,0,30)
	end
	
	wndContainer:ArrangeChildrenVert()
end

function PotatoLib:AddResetItem(strName, strParent, addonAddon) --PUI v2.8.1
	local wndResetFeatures = self.wndSettings:FindChild("ResetFeatures")
	local wndContainer = wndResetFeatures:FindChild("FeatureList")

	local wndParent = strParent and wndContainer:FindChild(strParent):FindChild("Container") or wndContainer
	local wndItem = Apollo.LoadForm(self.xmlDoc, "FeatureResetItem", wndParent, addonAddon)
	
	wndItem:FindChild("FeatureName"):SetText(strName)
	wndItem:SetName(strName)
	
	wndContainer:ArrangeChildrenVert()
end


-----------------------------------------------------------------------------------------------
-- PotatoLib Instance
-----------------------------------------------------------------------------------------------
local PotatoLibInst = PotatoLib:new()
PotatoLibInst:Init()
