require "Window"

local AuraMasteryConfig  = {}
AuraMasteryConfig .__index = AuraMasteryConfig

local IconText = nil

setmetatable(AuraMasteryConfig, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local keys = {}
keys[45] = "INS"
keys[46] = "DEL"
keys[36] = "HOME"
keys[35] = "END"
keys[33] = "PGUP"
keys[34] = "PGDN"
keys[112] = "F1"
keys[113] = "F2"
keys[114] = "F3"
keys[115] = "F4"
keys[116] = "F5"
keys[117] = "F6"
keys[118] = "F7"
keys[119] = "F8"
keys[120] = "F9"
keys[121] = "F10"
keys[122] = "F11"
keys[123] = "F12"
keys[96] = "N0"
keys[97] = "N1"
keys[98] = "N2"
keys[99] = "N3"
keys[100] = "N4"
keys[101] = "N5"
keys[102] = "N6"
keys[103] = "N7"
keys[104] = "N8"
keys[105] = "N9"
keys[110] = "N."
keys[111] = "N/"
keys[191] = "/"
keys[106] = "N*"
keys[109] = "N-"
keys[107] = "N+"
keys[13] = "ENTER"
keys[223] = "`"
keys[219] = "["
keys[221] = "]"
keys[186] = ";"
keys[192] = "'"
keys[222] = "#"
keys[188] = ","
keys[190] = "."
keys[220] = "\\"
keys[189] = "-"
keys[187] = "+"
keys[145] = "SCLK"
keys[19] = "PAUSE"
keys[37] = "LEFT"
keys[38] = "UP"
keys[39] = "RIGHT"
keys[40] = "DOWN"
keys[27] = "ESC"

local ExtraSounds = {
    Alarm = "alarm.wav",
    Alert = "alert.wav",
    Algalon = "algalon.wav",
    Beware = "beware.wav",
    Burn = "burn.wav",
    Destruction = "destruction.wav",
    DoorFutur = "doorfutur.wav",
    Inferno = "inferno.wav",
    Info = "info.wav",
    Long = "long.wav",
    RunAway = "runaway.wav"
}

local Zones = {
	["Arenas"] = {
		["All Arenas"] = "Arenas",
		["The Slaughterdome"] = {
			continentId = 39,
			parentZoneId = 0,
			id = 66,
		},
		["The Cryoplex"] = {
			continentId = 94,
			parentZoneId = 0,
			id = 478,
		},
	},
	["Battlegrounds"] = {
		["All Battlegrounds"] = { catchall = true },
		["Walatiki Temple"] = {
			continentId = 40,
			parentZoneId = 0,
			id = 69,
		},
		["Halls of the Bloodsworn"] = {
			continentId = 53,
			parentZoneId = 0,
			id = 99,
		},
		["Daggerstone Pass"] = {
			continentId = 57,
			parentZoneId = 0,
			id = 103,
		},
	},
	["Expeditions"] = {
		["All Expeditions"] = { catchall = true },
		["Fragment Zero"] = {
			continentId = 83,
			parentZoneId = 0,
			id = 277,
		},
		["Outpost M-13"] = {
			continentId = 38,
			parentZoneId = 63,
			id = 0,
		},
		["Infestation"] = {
			continentId = 18,
			parentZoneId = 0,
			id = 25,
		},
		["Rage Logic"] = {
			continentId = 51,
			parentZoneId = 93,
			id = 0,
		},
		["Space Madness"] = {
			continentId = 58,
			parentZoneId = 0,
			id = 121,
		},
		["Deepd Space Exploration"] = {
			continentId = 60,
			parentZoneId = 140,
			id = 0,
		},
		["Gauntlet"] = {
			continentId = 62,
			parentZoneId = 132,
			id = 0,
		},
	},
	["Adventures"] = {
		["All Adventures"] = { catchall = true },
		["War of the Wilds"] = {
			continentId = 23,
			parentZoneId = 0,
			id = 32,
		},
		["The Siege of Tempest Refuge"] = {
			continentId = 16,
			parentZoneId = 0,
			id = 23,
		},
		["Crimelords of Whitevale"] = {
			continentId = 26,
			parentZoneId = 0,
			id = 35,
		},
		["The Malgrave Trail"] = {
			continentId = 17,
			parentZoneId = 0,
			id = 24,
		},
		["Bay of Betrayal"] = {
			continentId = 84,
			parentZoneId = 0,
			id = 307,
		},
	},
	["Dungeons"] = {
		["All Dungeons"] = { catchall = true },
		["Protogames Academy"] = {
			continentId = 90,
			parentZoneId = 469,
			id = 0,
		},
		["Stormtalon's Lair"] = {
			continentId = 13,
			parentZoneId = 0,
			id = 19,
		},
		["Ruins of Kel Voreth"] = {
			continentId = 15,
			parentZoneId = 0,
			id = 21,
		},
		["Skullcano"] = {
			continentId = 14,
			parentZoneId = 0,
			id = 20,
		},
		["Sanctuary of the Swordmaiden"] = {
			continentId = 48,
			parentZoneId = 0,
			id = 85,
		},
		["Ultimate Protogames"] = {
			continentId = 69,
			parentZoneId = 154,
			id = 0,
		},
	},
	["Genetic Archives"] = {
		["All Subzones"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 0
        },
		["Experiment X-89"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 148
        },
		["Kuralak the Defiler"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 148
        },
		["Phagetech Prototypes"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 149
        },
		["Phagemaw"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 149
        },
		["Phageborn Convergence"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 149
        },
		["Dreadphage Ohmna"] = {
    		continentId = 67,
    		parentZoneId = 147,
            id = 149
        }
	},
	["Datascape"] = {
		["All Subzones"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 0
        },
		["System Daemons"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 105
        },
		["Limbo Infomatrix"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 114
        },
		["Volatillity Lattice"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 116
        },
		["Maelstrom Authority"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 120
        },
		["Gloomclaw"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 115
        },
		["Logic Wing"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 111
        },
		["Fire Wing"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 110
        },
		["Frost Wing"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 109
        },
		["Earth Wing"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 108
        },
		["Elemental Pairs"] = {117,118,119},
		["Avatus"] = {
    		continentId = 52,
    		parentZoneId = 98,
            id = 104
        },
	},
	["Initialization Core Y-83"] = {
		["All Subzones"] = {
    		continentId = 91,
    		parentZoneId = 0,
            id = 0
        },
	},
	["House"] = {
		["Home"] = {
			continentId = 36,
			parentZoneId = 0,
			id = 60
		}
	}
}

local function IndexOf(table, item)
    for idx, val in pairs(table) do
        if item == val then
            return idx
        end
    end
end

local function CatchError(func)
    local status, error = pcall(func)

    if not status then
        Print("[AuraMastery] An error has occured")
        Print(error)
    end
end

local random = math.random
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

function AuraMasteryConfig.new(auraMastery, xmlDoc)
	local self = setmetatable({}, AuraMasteryConfig)
    self.xmlDoc = xmlDoc
	self.auraMastery = auraMastery
    self.xmlDoc = xmlDoc
	self.configForm = Apollo.LoadForm(xmlDoc, "AuraMasteryForm", nil, self)
	self.colorPicker = Apollo.LoadForm(xmlDoc, "ColorPicker", nil, self)
	self.colorPicker:Show(false, true)
	Apollo.LoadSprites("Sprites.xml")
	self.colorPicker:FindChild("Color"):SetSprite("ColorPicker_Colors")
	self.colorPicker:FindChild("Gradient"):SetSprite("ColorPicker_Gradient")
	self:Init()
	return self
end

function AuraMasteryConfig:Show()
	self.configForm:FindChild("ShareConfirmDialog"):Show(false)
	self.timer = ApolloTimer.Create(0.1, true, "OnIconPreview", self)
	self.configForm:Show(true)
end

function AuraMasteryConfig:Init()
	for _, tab in pairs(self.configForm:FindChild("BuffEditor"):GetChildren()) do
		tab:Show(false)
	end
	self:SelectTab("General")

	self.configForm:FindChild("BuffShowWhen"):AddItem("Always", "", 1)
	self.configForm:FindChild("BuffShowWhen"):AddItem("All", "", 2)
	self.configForm:FindChild("BuffShowWhen"):AddItem("Any", "", 3)
	self.configForm:FindChild("BuffShowWhen"):AddItem("None", "", 4)

	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("All", "", 1)
	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("Any", "", 2)
	self.configForm:FindChild("BuffPlaySoundWhen"):AddItem("None", "", 3)

    local zoneDropdown = self.configForm:FindChild("ZoneDropdown"):FindChild("DropdownListItems")
    zoneDropdown:DestroyChildren()
    self.configForm:FindChild("SubZoneDropdown"):FindChild("DropdownListItems"):DestroyChildren()
    for key, zone in pairs(Zones) do
        local dropdownItem = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.GeneralTab.Options.Regions.ZoneDropdown.DropdownList.DropdownListItems.DropdownOption", zoneDropdown, self)
        dropdownItem:SetName("Dropdown" .. key)
        dropdownItem:SetText(key)
    end
    zoneDropdown:ArrangeChildrenVert()

	local soundList = self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList")
	local nextItem = 0

	local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)

	soundItem:SetData(-1)
	soundItem:FindChild("Label"):SetText("None")

    for name, sound in pairs(ExtraSounds) do
        local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)
        soundItem:SetData(sound)
        soundItem:FindChild("Label"):SetText(name)
    end

	for sound, soundNo in pairs(Sound) do
		if type(soundNo) == "number" then
			local soundItem = Apollo.LoadForm("AuraMastery.xml", "SoundListItem", soundList, self)
			soundItem:SetData(soundNo)
			soundItem:FindChild("Label"):SetText(sound)
		end
	end
	soundList:ArrangeChildrenVert()

	local soundSelectHeight = self.configForm:FindChild("SoundSelect"):GetHeight()
	self.configForm:FindChild("SoundSelect"):SetVScrollInfo(nextItem - soundSelectHeight, soundSelectHeight, soundSelectHeight)

	self.iconTextEditor = {}

	self.configForm:FindChild("SolidOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("SolidOverlay"):FindChild("ProgressBar"):SetProgress(75)

	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetProgress(75)
	self.configForm:FindChild("IconOverlay"):FindChild("ProgressBar"):SetFullSprite("icon_Crosshair")

	self.configForm:FindChild("LinearOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("LinearOverlay"):FindChild("ProgressBar"):SetProgress(75)

	self.configForm:FindChild("RadialOverlay"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("RadialOverlay"):FindChild("ProgressBar"):SetProgress(75)

	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetMax(100)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetMax(100)

	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)

	self.configForm:FindChild("SimpleTabButton"):Show(false)
    self:SelectTab("NoAuras")
	self.configForm:FindChild("BuffEditor"):Enable(false)

	self:CreateControls()
	--self:SelectFirstIcon()

	self.configForm:FindChild("ShareForm"):Show(false)
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)
	self.configForm:FindChild("TriggerEffectsDropdown"):Show(false)

	self.configForm:FindChild("TriggerEffectsDropdownList"):ArrangeChildrenVert()

	GeminiPackages:Require("AuraMastery:IconText", function(iconText)
		IconText = iconText
	end)
end

function AuraMasteryConfig:GetAbilitiesList()
	if self.abilitiesList == nil then
		self.abilitiesList = AbilityBook.GetAbilitiesList()
	end
	return self.abilitiesList
end

function AuraMasteryConfig:GetSpellIconByName(spellName)
	local abilities = self:GetAbilitiesList()
	if abilities ~= nil then
		for _, ability in pairs(abilities) do
			if ability.strName == spellName then
				return ability.tTiers[1].splObject:GetIcon()
			end
		end
	end
	return ""
end

function AuraMasteryConfig:OnOpenConfig()
	if self.auraMastery == nil then
		self.auraMastery = Apollo.GetAddon("AuraMastery")
	end

	if self.configForm == nil then
		Print("Not Loaded")
	end
	self:Show()
end

-----------------------------------------------------------------------------------------------
-- AuraMasteryForm Functions
-----------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnOK()
    CatchError(function()
    	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    	local icon = self.auraMastery.Icons[iconId]

        if icon == nil then
            return
        end
    	icon:SetIcon(self.configForm)
    	self.configForm:FindChild("ExportButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, self:Serialize(icon:GetSaveData()))
    	self:UpdateControls()
    	self:PopulateTriggers(icon)
    end)
end

function AuraMasteryConfig:OnCancel()
	self.timer:Stop()
	self.configForm:Show(false) -- hide the window
end

function AuraMasteryConfig:LoadSpriteIcons(spriteList)
    local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    local icon = self.auraMastery.Icons[iconId]

	local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
	spriteItem:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(self.configForm:FindChild("BuffName"):GetText()))
	spriteItem:FindChild("SpriteItemText"):SetText("Spell Icon")
	spriteItem:SetAnchorOffsets(0, 0, spriteItem:GetWidth(), spriteItem:GetHeight())

    if icon.iconSprite == "" then
        self:SelectSpriteIcon(spriteItem)
    end
	local iconsPerRow = math.floor(spriteList:GetWidth() / 110)
	local currentPos = 1

	spriteIcons = {}
    for n in pairs(self.auraMastery.spriteIcons) do table.insert(spriteIcons, n) end
    table.sort(spriteIcons)

	for i, spriteName in pairs(spriteIcons) do
		local spriteIcon = self.auraMastery.spriteIcons[spriteName]
		local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SpriteItem", spriteList, self)
		spriteItem:FindChild("SpriteItemIcon"):SetSprite(spriteIcon)
		spriteItem:FindChild("SpriteItemText"):SetText(spriteName)
		local x = math.floor(currentPos % iconsPerRow) * 110
		local y = math.floor(currentPos / iconsPerRow) * 140
		currentPos = currentPos + 1

        if spriteIcon == icon.iconSprite then
            self:SelectSpriteIcon(spriteItem)
        end
	end
    spriteList:ArrangeChildrenTiles()
end

function AuraMasteryConfig:CreateGroup(group)
    local iconList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
    local groupItem = Apollo.LoadForm("AuraMastery.xml", "IconListGroupItem", iconList, self)
    groupItem:FindChild("Label"):SetText(group.name)
    groupItem:SetData(group)
    return groupItem
end

function AuraMasteryConfig:CreateControls()
    for idx, group in pairs(self.auraMastery.IconGroups) do
		local groupItem = self:CreateGroup(group)

        local iconsList = groupItem:FindChild("Icons")
        for i, icon in pairs(self.auraMastery.Icons) do
            if icon.group == group.id then
                self:CreateIconItem(icon.iconId, icon, iconsList)
            end
    	end
	end
    self:UpdateControls()

	self:PopulateAuraSpellNameList()
	self:PopulateAuraNameList()
end

function AuraMasteryConfig:OnAddGroup( wndHandler, wndControl, eMouseButton )
    CatchError(function()
        GeminiPackages:Require("AuraMastery:IconGroup", function(IconGroup)
            local group = IconGroup.new()
            group.id = uuid()
            group.name = "Group " .. (#self.auraMastery.IconGroups + 1)
            table.insert(self.auraMastery.IconGroups, group)
            self:CreateGroup(group)
        end)
    end)
    self:UpdateControls()
end

function AuraMasteryConfig:OnRemoveGroup( wndHandler, wndControl, eMouseButton )
    if wndHandler == wndControl then
        CatchError(function()
            local groupTab = wndHandler:GetParent()
            local group = groupTab:GetData()

            table.remove(self.auraMastery.IconGroups, IndexOf(self.auraMastery.IconGroups, group))
            local groupList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
            for _, groupItem in pairs(groupList:GetChildren()) do
                if groupItem:GetData() == group then
                    for _, iconItem in pairs(groupItem:FindChild("Icons"):GetChildren()) do
                        self:RemoveIcon(iconItem)
                    end
                    groupItem:Destroy()
                    break
                end
            end
            groupList:SetData(nil)
            self:SelectTab("NoAuras")
        end)
    end
end

function AuraMasteryConfig:OnToggleIconGroup( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    if wndHandler == wndControl then
        CatchError(function()
            local groupItem = wndHandler:GetParent():GetParent()
            local groupList = groupItem:GetParent()
            local previousGroupItem = groupList:GetData()
            if previousGroupItem ~= nil then
                local previousGroup = previousGroupItem:GetData()
                if previousGroup.anchor ~= nil then
                    previousGroup.anchor:Show(false, false)
                end
                previousGroupItem:FindChild("StatusLabel"):SetText("+")
                previousGroupItem:FindChild("Icons"):Show(false, true)
                if previousGroupItem == groupItem then
                    groupList:SetData(nil)
                    self:UpdateControls()
                    self:SelectTab("NoAuras")
                    return
                end
            end
            local icons = groupItem:FindChild("Icons")
            icons:Show(not icons:IsShown(), true)
            groupItem:FindChild("StatusLabel"):SetText(icons:IsShown() and "-" or "+")
            groupList:SetData(groupItem)
            self:UpdateControls()
            local left, top, right, bottom = groupItem:GetAnchorOffsets()
            groupList:SetVScrollPos(top)

            local groupTab = self.configForm:FindChild("GroupTab")
            groupTab:SetData(groupItem:GetData())
            groupTab:FindChild("GroupName"):SetText(groupItem:GetData().name)
            self.configForm:FindChild("BuffEditor"):Enable(true)
            self:SelectTab("Group")
        end)
    end
end

function AuraMasteryConfig:OnGroupNameChanged( wndHandler, wndControl, strText )
    local groupTab = wndHandler:GetParent()
    local group = groupTab:GetData()

    group.name = strText

    self:UpdateControls()
end


function AuraMasteryConfig:CreateIconItem(i, icon, groupList)
	local iconList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
	local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", groupList, self)
	iconItem:FindChild("Id"):SetText(i)
	iconItem:FindChild("Label"):SetText(icon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	icon:SetConfigElement(iconItem)

    self:RebuildTriggerList(iconItem, icon)
    iconItem:FindChild("TriggerItemList"):Show(false)

    local left, top, right, bottom = iconItem:GetAnchorOffsets()
    iconItem:SetAnchorOffsets(left, top, right, top + 50)

	iconList:ArrangeChildrenVert()
	return iconItem
end

function AuraMasteryConfig:RebuildTriggerList(iconItem, icon)
    local triggerItemList = iconItem:FindChild("TriggerItemList")
    triggerItemList:DestroyChildren()
    for _, trigger in pairs(icon.Triggers) do
        local triggerItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem.TriggerItemList.TriggerItem", triggerItemList, self)
        triggerItem:SetData(trigger)
        triggerItem:FindChild("TriggerItemLabel"):SetText(trigger.Name == "" and trigger.Type or trigger.Name)
    end

    local triggerItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem.TriggerItemList.TriggerItem", triggerItemList, self)
    triggerItem:SetData("AddTrigger")
    triggerItem:FindChild("TriggerMoveUp"):Show(false)
    triggerItem:FindChild("TriggerMoveDown"):Show(false)
    triggerItem:FindChild("TriggerDelete"):Show(false)
    triggerItem:FindChild("TriggerItemLabel"):SetText("Add Trigger")

    triggerItemList:ArrangeChildrenVert()

    local left, top, right, bottom = iconItem:GetAnchorOffsets()
    iconItem:SetAnchorOffsets(left, top, right, top + 83 + (#icon.Triggers * 30))


    iconItem:GetParent():ArrangeChildrenVert()
end

function AuraMasteryConfig:PopulateAuraNameList()
	local spellNameList = self.configForm:FindChild("AuraNameList")
	spellNameList:DestroyChildren()

	for _, ability in pairs(self:GetAbilitiesList()) do
		local abilityOption = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.GeneralTab.AuraSpellName.AuraNameList.AuraNameButton", spellNameList, self)
		abilityOption:SetText(ability.strName)
		abilityOption:SetData(ability)
	end
	spellNameList:ArrangeChildrenVert()
end

function AuraMasteryConfig:UpdateControls()
    CatchError(function()
    	for _, iconItem in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
            iconItem:FindChild("Label"):SetText(iconItem:GetData().name)
            if iconItem:FindChild("Icons"):IsShown() then
                local height = 85
                for _, item in pairs(iconItem:FindChild("Icons"):GetChildren()) do
                    if item:FindChild("Id") ~= nil then
                		local icon = self.auraMastery.Icons[tonumber(item:FindChild("Id"):GetText())]
                        if icon ~= nil then
                            item:FindChild("Label"):SetText(icon:GetName())
                            for _, trigger in pairs(item:FindChild("TriggerItemList"):GetChildren()) do
                                local triggerData = trigger:GetData()
                                if triggerData ~= "AddTrigger" then
                                    trigger:FindChild("TriggerItemLabel"):SetText(triggerData.Name == "" and triggerData.Type or triggerData.Name)
                                end
                            end
                        end
                    end
                    height = height + item:GetHeight()
                end
                iconItem:SetAnchorOffsets(0, 0, 0, height)
            else
                iconItem:SetAnchorOffsets(0, 0, 0, 85)
            end

            iconItem:FindChild("Icons"):ArrangeChildrenVert()
    	end
        self.configForm:FindChild("IconListHolder"):FindChild("IconList"):ArrangeChildrenVert()
    end)
end

function AuraMasteryConfig:SelectFirstIcon()
	for _, icon in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
		if icon ~= nil then
			self:SelectIcon(icon)
			break
		end
	end
end

function AuraMasteryConfig:OnLockIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
    local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		icon:Lock()
	end
end

function AuraMasteryConfig:OnUnlockIcon( wndHandler, wndControl, eMouseButton )
	self.BarLocked = false
	local iconId = tonumber(wndHandler:GetParent():FindChild("Id"):GetText())
    local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		icon:Unlock()
	end
end

function AuraMasteryConfig:OnSoundPlay( wndHandler, wndControl, eMouseButton )
	local soundNo = tonumber(self.configForm:FindChild("SoundNo"):GetText())
	Sound.Play(soundNo)
end

function AuraMasteryConfig:OnAddIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
        CatchError(function()
            local groupItem = wndHandler:GetParent()
            local groupList = groupItem:GetParent()
    		local icon = self.auraMastery:AddIcon()
    		local iconItem = self:CreateIconItem(icon.iconId, icon, groupItem:FindChild("Icons"))
            icon.group = groupItem:GetData().id
    		local timeText = self:AddIconText(icon)
    		timeText.textAnchor = "OB"
    		timeText.textString = "{time}"
    		local stacksText = self:AddIconText(icon)
    		stacksText.textAnchor = "IBR"
    		stacksText.textString = "{stacks}"
    		local chargesText = self:AddIconText(icon)
    		timeText.textAnchor = "ITL"
    		timeText.textString = "{charges}"

            if groupList:GetData() ~= groupItem then
                local groupButton = groupItem:FindChild("Background")
                self:OnToggleIconGroup(groupButton, groupButton)
            end

    		self:SelectIcon(iconItem)
    		self:OnAddTrigger()
            self:SelectTab("General")
            self:OnOK()
        end)
	end
end

function AuraMasteryConfig:OnRemoveIcon( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		self:RemoveIcon(self.selectedIcon)
        self:UpdateControls()
	end
end

function AuraMasteryConfig:AddIcon()
	local newIcon = Icon.new(self.buffWatch, self.configForm, self.xmlDoc)
	newIcon:SetScale(1)

	local iconList = self.configForm:FindChild("IconListHolder"):FindChild("IconList")
	local iconItem = Apollo.LoadForm("AuraMastery.xml", "IconListItem", iconList, self)
	iconItem:FindChild("Id"):SetText(tostring(self.nextIconId))
	iconItem:FindChild("Label"):SetText(newIcon:GetName())
	iconItem:FindChild("LockButton"):SetCheck(true)
	newIcon:SetConfigElement(iconItem)
	self.auraMastery.Icons[self.nextIconId] = newIcon
	self.nextIconId = self.nextIconId + 1

	iconList:ArrangeChildrenVert()

	return newIcon
end

function AuraMasteryConfig:RemoveIcon(icon)
	local iconList = icon:GetParent()
	local iconId = tonumber(icon:FindChild("Id"):GetText())
	icon:Destroy()
	iconList:ArrangeChildrenVert()

	self.selectedIcon = nil

	self.auraMastery.Icons[iconId]:Delete()
	self.auraMastery.Icons[iconId] = nil

    self:SelectTab("NoAuras")
	self.configForm:FindChild("BuffEditor"):Enable(false)

	--self:SelectFirstIcon()
end

function AuraMasteryConfig:NumIcons()
	local numIcons = 0
	for _, icon in pairs(self.auraMastery.Icons) do
		if icon ~= nil then
			numIcons = numIcons + 1
		end
	end
	return numIcons
end

function AuraMasteryConfig:OnIconScale( wndHandler, wndControl, fNewValue, fOldValue )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]

	fNewValue = tonumber(string.format("%.1f", fNewValue))
	icon:SetScale(fNewValue)
	self.configForm:FindChild("BuffScaleValue"):SetText(string.format("%.1f", fNewValue))
end

function AuraMasteryConfig:OnScaleValueChanged( wndHandler, wndControl, strText )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	local value = tonumber(strText)

	if value == nil then
		value = tonumber(string.format("%.1f", self.configForm:FindChild("BuffScale"):GetValue()))
	end

	self.configForm:FindChild("BuffScaleValue"):SetText(tostring(value))
	icon:SetScale(value)
	self.configForm:FindChild("BuffScale"):SetValue(value)
end

function AuraMasteryConfig:OnPositionChanged( wndHandler, wndControl, strText )
    local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    local icon = self.auraMastery.Icons[iconId]

    local x, y = tonumber(self.configForm:FindChild("BuffPositionX"):GetText()), tonumber(self.configForm:FindChild("BuffPositionY"):GetText())
    if x ~= nil and y ~= nil then
        icon:SetPosition(x, y)
    end
end

function AuraMasteryConfig:OnPositionNudge( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    if wndHandler == wndControl then
        local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
        local icon = self.auraMastery.Icons[iconId]
        local x, y = icon:GetPosition()
        local moveType = wndHandler:GetName():sub(9)

        if moveType == "PlusY" then
            y = y - 10
        elseif moveType == "MinusY" then
            y = y + 10
        elseif moveType == "PlusX" then
            x = x - 10
        elseif moveType == "MinusX" then
            x = x + 10
        end

        icon:SetPosition(x, y)
        self.configForm:FindChild("BuffPositionX"):SetText(x)
        self.configForm:FindChild("BuffPositionY"):SetText(y)
    end
end

function AuraMasteryConfig:OnShownChanged( wndHandler, wndControl, selectedIndex )
	self:SetShownDescription(selectedIndex)
end

function AuraMasteryConfig:SetShownDescription(selectedIndex)
	local shownMsg = ""
	if selectedIndex == 1 then
		shownMsg = "This aura will always be shown."
	elseif selectedIndex == 2 then
		shownMsg = "This aura will be shown when all triggers pass."
	elseif selectedIndex == 3 then
		shownMsg = "This aura will be shown when any trigger passes."
	elseif selectedIndex == 4 then
		shownMsg = "This aura will be shown when all triggers fail."
	end
	self.configForm:FindChild("ShownDescription"):SetText(shownMsg)
end

function AuraMasteryConfig:OnPlaySoundChanged( wndHandler, wndControl, selectedIndex )
	self:SetPlayWhenDescription(selectedIndex)
end

function AuraMasteryConfig:SetPlayWhenDescription(selectedIndex)
	local playSoundDesc = ""
	if selectedIndex == 1 then
		playSoundDesc = "This sound will be played when all triggers pass."
	elseif selectedIndex == 2 then
		playSoundDesc = "This sound will be played when any trigger passes."
	elseif selectedIndex == 3 then
		playSoundDesc = "This sound will be played when all triggers fail."
	end

	self.configForm:FindChild("PlaySoundDescription"):SetText(playSoundDesc)
end

function AuraMasteryConfig:OnTabSelected( wndHandler, wndControl, eMouseButton )
	self:SelectTab(wndHandler:GetName():sub(0, -10))
end

function AuraMasteryConfig:OnTabUnselected( wndHandler, wndControl, eMouseButton )
end

function AuraMasteryConfig:SelectTab(tabName)
	if self.currentTab ~= nil then
        local tab = self.configForm:FindChild(self.currentTab .. "TabButton")
        if tab ~= nil then
		      tab:SetCheck(false)
        end
		self.configForm:FindChild("BuffEditor"):FindChild(self.currentTab .. "Tab"):Show(false)
	end

	self.currentTab = tabName
    if tabName ~= nil then
        self.configForm:FindChild("EditorTabs"):Show(tabName ~= "NoAuras" and tabName ~= "Group", true)
        self.configForm:FindChild("BuffEditor"):Enable(tabName ~= "NoAuras")
    	self.configForm:FindChild("BuffEditor"):FindChild(tabName .. "Tab"):Show(true)
        local tab = self.configForm:FindChild(self.currentTab .. "TabButton")
        if tab ~= nil then
              tab:SetCheck(true)
        end
    end
end

function AuraMasteryConfig:OnIconPreview()
	self.currentSampleNum = (self.currentSampleNum + 2) % 100
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetProgress(self.currentSampleNum)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetProgress(self.currentSampleNum)
end

function AuraMasteryConfig:OnColorUpdate()
	self.configForm:FindChild("BuffColorSample"):SetBGColor(self.selectedColor)
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetBGColor(self.selectedColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetBGColor(self.selectedColor)
end

function AuraMasteryConfig:OnColorSelect( wndHandler, wndControl, eMouseButton )
	self:OpenColorPicker(self.selectedColor, function() self:OnColorUpdate() end)
end

function AuraMasteryConfig:OnSpellNameChanged( wndHandler, wndControl, strText )
    local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
    if icon.iconSprite == "" then
    	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetSprite(self:GetSpellIconByName(strText))
    	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetSprite(self:GetSpellIconByName(strText))
    end
end

function AuraMasteryConfig:OnOverlaySelection( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		local overlaySelection = wndHandler:FindChild("OverlayIconText"):GetText()

		if overlaySelection == "Solid" then
			self.configForm:FindChild("SolidOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("IconOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")

		elseif overlaySelection == "Icon" then
			self.configForm:FindChild("SolidOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("IconOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
		end

		if overlaySelection == "Linear" then
			self.configForm:FindChild("LinearOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("RadialOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", false)
			self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", false)
		elseif overlaySelection == "Radial" then
			self.configForm:FindChild("LinearOverlay"):SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
			self.configForm:FindChild("RadialOverlay"):SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
			self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", true)
			self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetStyleEx("RadialBar", true)
		end
	end
end

function AuraMasteryConfig:OnOverlayColorUpdate()
	self.configForm:FindChild("OverlayColorSample"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconSample"):FindChild("ProgressBar"):SetBarColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetBGColor(self.selectedOverlayColor)
	self.configForm:FindChild("IconGeneralSample"):FindChild("ProgressBar"):SetBarColor(self.selectedOverlayColor)
end

function AuraMasteryConfig:OnOverlayColorSelect( wndHandler, wndControl, eMouseButton )
	self:OpenColorPicker(self.selectedOverlayColor, function() self:OnOverlayColorUpdate() end)
end

--------------------------------------------------------------------------------------------
-- IconListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnListItemSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self:SelectIcon(wndHandler:GetParent())
	end
end

function AuraMasteryConfig:SelectIcon(iconItem)
    CatchError(function()
        self:SelectTab("General")
    	self.configForm:FindChild("BuffEditor"):Enable(true)
    	local icon = self.auraMastery.Icons[tonumber(iconItem:FindChild("Id"):GetText())]
    	if icon ~= nil then
    		self.configForm:FindChild("BuffId"):SetText(tonumber(iconItem:FindChild("Id"):GetText()))

    		if self.selectedIcon ~= nil then
    			self.selectedIcon:FindChild("Background"):SetBGColor(ApolloColor.new(0.03, 0.16, 0.24, 1))

                local left, top, right, bottom = self.selectedIcon:GetAnchorOffsets()
                self.selectedIcon:SetAnchorOffsets(left, top, right, top + 50)
    		end
    		self.selectedIcon = iconItem
    		self.selectedIcon:FindChild("Background"):SetBGColor(ApolloColor.new(0.03, 0.5, 0.61, 1))

            local left, top, right, bottom = self.selectedIcon:GetAnchorOffsets()
            self.selectedIcon:SetAnchorOffsets(left, top, right, top + 83 + (#icon.Triggers * 30))
            self.selectedIcon:FindChild("TriggerItemList"):Show(true)

            self.configForm:FindChild("IconListHolder"):FindChild("IconList"):ArrangeChildrenVert()

    		self.configForm:FindChild("ExportButton"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, self:Serialize(icon:GetSaveData()))

    		if icon.SimpleMode then
    			self:SelectTab("Simple")
    			self.configForm:FindChild("GeneralTabButton"):Show(false)
    			self.configForm:FindChild("AppearanceTabButton"):Show(false)
    			self.configForm:FindChild("TextTabButton"):Show(false)
    			self.configForm:FindChild("SimpleTabButton"):Show(true)

    			self.configForm:FindChild("AuraEnabled"):SetCheck(icon.enabled)
    			self.configForm:FindChild("AuraOnlyInCombat"):SetCheck(icon.onlyInCombat)
    			self.configForm:FindChild("AuraActionSet1"):SetCheck(icon.actionSets[1])
    			self.configForm:FindChild("AuraActionSet2"):SetCheck(icon.actionSets[2])
    			self.configForm:FindChild("AuraActionSet3"):SetCheck(icon.actionSets[3])
    			self.configForm:FindChild("AuraActionSet4"):SetCheck(icon.actionSets[4])
    			self.configForm:FindChild("AuraAlwaysShow"):SetCheck(icon.showWhen == "Always")
    			self.configForm:FindChild("AuraSpriteScaleSlider"):SetValue(icon.iconScale)
    			self.configForm:FindChild("AuraSpriteScaleText"):SetText(string.format("%.1f", icon.iconScale))
    			self.configForm:FindChild("AuraSpellNameFilter"):SetText(icon.iconName)
    			self:SetAuraSpellNameFilter(icon.iconName)
    			self.configForm:FindChild("AuraSpellName_FilterOption"):SetCheck(true)
    			self.configForm:FindChild("AuraSpellNameList"):SetData(self.configForm:FindChild("AuraSpellName_FilterOption"))
    			self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(icon.iconName))
    			local spellList = self.configForm:FindChild("AuraSpellNameList")
    			for _, spell in pairs(spellList:GetChildren()) do
    				if spell:GetName() == "AuraSpellName_FilterOption" then
    					spell:SetCheck(true)
    				else
    					spell:SetCheck(false)
    				end
    			end

    			local simpleTab = self.configForm:FindChild("SimpleTab")
    			for _, auraType in pairs(simpleTab:FindChild("AuraType"):GetChildren()) do
    				auraType:SetCheck(false)
    			end

    			if #icon.Triggers == 0 then
    				simpleTab:FindChild("AuraType_Cooldown"):SetCheck(true)
    				self.configForm:FindChild("AuraBuffDetails"):Show(false)
    				simpleTab:FindChild("AuraType"):SetData(simpleTab:FindChild("AuraType_Cooldown"))
    			else
    				simpleTab:FindChild("AuraType_" .. icon.Triggers[1].Type):SetCheck(true)
    				simpleTab:FindChild("AuraType"):SetData(simpleTab:FindChild("AuraType_" .. icon.Triggers[1].Type))
    				if icon.Triggers[1].Type == "Buff" or icon.Triggers[1].Type == "Debuff" then
    					self.configForm:FindChild("AuraBuffDetails"):Show(true)
    					self.configForm:FindChild("AuraBuffUnit_Player"):SetCheck(icon.Triggers[1].TriggerDetails.Target.Player)
    					self.configForm:FindChild("AuraBuffUnit_Target"):SetCheck(icon.Triggers[1].TriggerDetails.Target.Target)
    				else
    					self.configForm:FindChild("AuraBuffDetails"):Show(false)
    					self.configForm:FindChild("AuraBuffUnit_Player"):SetCheck(false)
    					self.configForm:FindChild("AuraBuffUnit_Target"):SetCheck(false)
    				end
    			end

    			local soundSelect = self.configForm:FindChild("AuraSoundSelect")
    			if soundSelect:GetData() ~= nil then
    				soundSelect:GetData():SetCheck(false)
    			end

    			for _, sound in pairs(self.configForm:FindChild("AuraSoundSelect"):GetChildren()) do
    				if tonumber(sound:GetData()) == icon.iconSound then
    					sound:SetCheck(true)
    					soundSelect:SetData(sound)

    					local left, top, right, bottom = sound:GetAnchorOffsets()
    					soundSelect:SetVScrollPos(top)
    					break
    				end
    			end

    			local spriteSelect = self.configForm:FindChild("AuraIconSelect")
    			if spriteSelect:GetData() ~= nil then
    				spriteSelect:GetData():SetCheck(false)
    			end

    			if icon.iconSprite == "" then
    				self.configForm:FindChild("AuraSprite_Default"):SetCheck(true)
    				self.configForm:FindChild("AuraIconSelect"):SetData(self.configForm:FindChild("AuraSprite_Default"))
    			else
    				for _, sprite in pairs(self.configForm:FindChild("AuraIconSelect"):GetChildren()) do
    					if sprite:FindChild("SpriteItemIcon"):GetSprite() == icon.iconSprite then
    						sprite:SetCheck(true)
    						spriteSelect:SetData(sprite)

    						local left, top, right, bottom = sprite:GetAnchorOffsets()
    						spriteSelect:SetVScrollPos(top)
    						break
    					end
    				end
    			end
    		else
    			if self.currentTab == "Simple" then
    				self:SelectTab("General")
    			end
    			self.configForm:FindChild("GeneralTabButton"):Show(true)
    			self.configForm:FindChild("AppearanceTabButton"):Show(true)
    			self.configForm:FindChild("TextTabButton"):Show(true)
    			self.configForm:FindChild("SimpleTabButton"):Show(false)

                self.configForm:FindChild("BuffName"):SetText(icon.iconName)
                local descriptionField = self.configForm:FindChild("Description")
    			descriptionField:SetText(icon.description)
                self:OnPlaceholderEditorChanged(descriptionField, descriptionField, icon.description)
    			self:SetAuraNameFilter(icon.iconName)
    			self.configForm:FindChild("BuffShowWhen"):SelectItemByText(icon.showWhen)
    			self:SetShownDescription(self.configForm:FindChild("BuffShowWhen"):GetSelectedIndex() + 1)
    			self.configForm:FindChild("BuffPlaySoundWhen"):SelectItemByText(icon.playSoundWhen)
    			self:SetPlayWhenDescription(self.configForm:FindChild("BuffPlaySoundWhen"):GetSelectedIndex() + 1)
                self.configForm:FindChild("SelectedSprite"):SetText(icon.iconSprite)
                self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetSprite(icon:GetSprite())
                self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetSprite(icon:GetSprite())
    			self.configForm:FindChild("BuffScale"):SetValue(icon.iconScale)
                self.configForm:FindChild("BuffScaleValue"):SetText(string.format("%.1f", icon.iconScale))
                local x, y = icon:GetPosition()
                self.configForm:FindChild("BuffPositionX"):SetText(x)
    			self.configForm:FindChild("BuffPositionY"):SetText(y)

    			self.configForm:FindChild("BuffBackgroundShown"):SetCheck(icon.iconBackground)
    			self.configForm:FindChild("BuffBorderShown"):SetCheck(icon.iconBorder)
                self.configForm:FindChild("BuffShowInCombat"):SetCheck(icon.active.inCombat)
                self.configForm:FindChild("BuffShowNotInCombat"):SetCheck(icon.active.notInCombat)
                self.configForm:FindChild("BuffShowSolo"):SetCheck(icon.active.solo)
                self.configForm:FindChild("BuffShowInGroup"):SetCheck(icon.active.inGroup)
                self.configForm:FindChild("BuffShowInRaid"):SetCheck(icon.active.inRaid)
                self.configForm:FindChild("BuffShowPvpFlagged"):SetCheck(icon.active.pvpFlagged)
                self.configForm:FindChild("BuffShowNotPvpFlagged"):SetCheck(icon.active.notPvpFlagged)
    			self.configForm:FindChild("BuffEnabled"):SetCheck(icon.enabled)
    			self.selectedColor = icon.iconColor
    			self.selectedOverlayColor = icon.iconOverlay.overlayColor

    			self.configForm:FindChild("BuffActionSet1"):SetCheck(icon.actionSets[1])
    			self.configForm:FindChild("BuffActionSet2"):SetCheck(icon.actionSets[2])
    			self.configForm:FindChild("BuffActionSet3"):SetCheck(icon.actionSets[3])
    			self.configForm:FindChild("BuffActionSet4"):SetCheck(icon.actionSets[4])

                local regionList = self.configForm:FindChild("RegionList")
                regionList:DestroyChildren()
                for _, region in pairs(icon.Regions) do
                    self:AddRegionItem(region)
                end

    			self:OnColorUpdate()

                local soundSelect = self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList")
                local selectedSound = soundSelect:GetData()
    			if selectedSound ~= nil then
    				selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
    			end

                self.configForm:FindChild("CustomSoundEnabled"):SetCheck(icon.customSound)

                if icon.customSound then
                    self.configForm:FindChild("CustomSoundName"):SetText(icon.iconSound)
                    local sound = soundSelect:GetChildren()[1]
                    soundSelect:SetData(sound)
                    sound:SetBGColor(ApolloColor.new(1, 0, 1, 1))
                    local left, top, right, bottom = sound:GetAnchorOffsets()
                    soundSelect:SetVScrollPos(top)
                else
                    self.configForm:FindChild("CustomSoundName"):SetText("")
        			for _, sound in pairs(soundSelect:GetChildren()) do
        				if tonumber(sound:GetData()) == icon.iconSound or sound:GetData() == icon.iconSound then
                            soundSelect:SetData(sound)
        					sound:SetBGColor(ApolloColor.new(1, 0, 1, 1))

        					local left, top, right, bottom = sound:GetAnchorOffsets()
        					soundSelect:SetVScrollPos(top)
        					break
        				end
        			end
                end


    			for textEditorId, textEditor in pairs(self.iconTextEditor) do
    				textEditor:Destroy()
    				self.iconTextEditor[textEditorId] = nil
    			end

    			for iconTextId, iconText in pairs(icon.iconText) do
    				self:AddIconTextEditor()

    				local textEditor = self.configForm:FindChild("TextList"):GetChildren()[iconTextId]

    				for _, anchor in pairs(textEditor:FindChild("AnchorSelector"):GetChildren()) do
    					anchor:SetCheck(false)
    				end
    				local selectedTextAnchor = textEditor:FindChild("AnchorPosition_" .. icon.iconText[iconTextId].textAnchor)
    				if selectedTextAnchor ~= nil then
    					selectedTextAnchor:SetCheck(true)
    				end

    				for _, font in pairs(textEditor:FindChild("FontSelector"):GetChildren()) do
    					if font:GetText() == icon.iconText[iconTextId].textFont then
    						self:SelectFont(font)
    						local left, top, right, bottom = font:GetAnchorOffsets()
    						textEditor:FindChild("FontSelector"):SetVScrollPos(top)
    						break
    					end
    				end
    				textEditor:FindChild("FontColorSample"):SetBGColor(icon.iconText[iconTextId].textFontColor)
    				textEditor:FindChild("FontSample"):SetTextColor(icon.iconText[iconTextId].textFontColor)
    				textEditor:FindChild("TextString"):SetText(icon.iconText[iconTextId].textString)
    			end

    			self.configForm:FindChild("OverlayColorSample"):SetBGColor(icon.iconOverlay.overlayColor)
    			if icon.iconOverlay.overlayShape == "Icon" then
    				self.configForm:FindChild("IconOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
    				self.configForm:FindChild("SolidOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
    			else
    				self.configForm:FindChild("SolidOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
    				self.configForm:FindChild("IconOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
    			end

    			if icon.iconOverlay.overlayStyle == "Radial" then
    				self.configForm:FindChild("RadialOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
    				self.configForm:FindChild("LinearOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
    			else
    				self.configForm:FindChild("LinearOverlay"):SetSprite("kitBase_HoloOrange_TinyNoGlow");
    				self.configForm:FindChild("RadialOverlay"):SetSprite("kitBase_HoloBlue_TinyLitNoGlow");
    			end

                if icon.trackLine ~= nil then
                    self.configForm:FindChild("TrackLineEnabled"):SetCheck(icon.trackLine.Enabled)
                    self.configForm:FindChild("TrackLineNumberOfLines"):SetText(icon.trackLine:NumberOfLines())
                end

                if icon.inWorldIcon ~= nil then
                    self.configForm:FindChild("InWorldIconEnabled"):SetCheck(icon.inWorldIcon.Enabled)
                end

    			self:PopulateTriggers(icon)
    		end
    	end
        self:OnOK()
    end)
end

function AuraMasteryConfig:SelectFont(fontElement)
	local textEditor = fontElement:GetParent():GetParent():GetParent()
	local editorData = textEditor:GetData()
	if editorData.selectedFont ~= nil then
		editorData.selectedFont:SetBGColor(CColor.new(1,1,1,1))
	end
	textEditor:FindChild("FontSample"):SetFont(fontElement:GetText())
	textEditor:FindChild("SelectedFont"):SetText(fontElement:GetText())
	editorData.selectedFont = fontElement
	editorData.selectedFont:SetBGColor(CColor.new(1,0,1,1))

	textEditor:SetData(editorData)
end

function AuraMasteryConfig:OnTriggerItemSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        local trigger = wndHandler:GetData()
        if trigger == "AddTrigger" then
            self:OnAddTrigger()
        else
            self:SelectTriggerItem(wndHandler:GetData())
        end
    end
end

---------------------------------------------------------------------------------------------------
-- SoundListItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnSoundItemSelected( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
        local selectedSound = self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList"):GetData()
		if selectedSound ~= nil then
			selectedSound:SetBGColor(ApolloColor.new(1, 1, 1, 1))
		end
		wndHandler:SetBGColor(ApolloColor.new(1, 0, 1, 1))
		local soundId = wndHandler:GetData()
		self.configForm:FindChild("SoundSelect"):FindChild("SoundSelectList"):SetData(wndHandler)

        if type(soundId) == "string" then
            Sound.PlayFile("Sounds\\" .. soundId)
        else
		    Sound.Play(tonumber(soundId))
        end
	end
end

---------------------------------------------------------------------------------------------------
-- SpriteItem Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnSpriteIconSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectSpriteIcon(wndHandler:GetParent())
	end
end

function AuraMasteryConfig:SelectSpriteIcon(spriteIcon)
	if self.selectedSprite ~= nil then
		self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloBlue_TinyLitNoGlow")
	end
	self.selectedSprite = spriteIcon
	if self.selectedSprite:FindChild("SpriteItemText"):GetText() == "Spell Icon" then
		self.configForm:FindChild("SelectedSprite"):SetText("")
	else
		self.configForm:FindChild("SelectedSprite"):SetText(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
	end
	self.selectedSprite:SetSprite("CRB_Basekit:kitBase_HoloOrange_TinyNoGlow")
	self.selectedSprite:SetText("")
	self.configForm:FindChild("IconSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
	self.configForm:FindChild("IconGeneralSample"):FindChild("IconSprite"):SetSprite(self.selectedSprite:FindChild("SpriteItemIcon"):GetSprite())
    self:OnOK()
end

function AuraMasteryConfig:AddIconTextEditor()
	local nextIconTextId = # self.iconTextEditor + 1
	local textEditor = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor", self.configForm:FindChild("TextList"), self)
	textEditor:FindChild("IconTextId"):SetText(tostring(nextIconTextId))
	self.iconTextEditor[nextIconTextId] = textEditor
	local left, top, right, bottom = textEditor:GetAnchorOffsets()
	textEditor:SetAnchorOffsets(left, top + ((nextIconTextId - 1) * textEditor:GetHeight()), right, bottom + (nextIconTextId - 1) * textEditor:GetHeight())
	textEditor:SetData({selectedFont = nil})
	self:LoadFontSelector(nextIconTextId)
end

function AuraMasteryConfig:LoadFontSelector(textId)
	local fontSelector = self.iconTextEditor[textId]:FindChild("FontSelector")
	local currentIdx = 0
	for _, font in pairs(Apollo.GetGameFonts()) do
		local fontItem = Apollo.LoadForm("AuraMastery.xml", "AM_Config_TextEditor_Font", fontSelector, self)
		fontItem:SetAnchorOffsets(0, currentIdx * fontItem:GetHeight(), 0, currentIdx * fontItem:GetHeight() + fontItem:GetHeight())
		fontItem:SetText(font.name)
		currentIdx = currentIdx + 1
	end
end

---------------------------------------------------------------------------------------------------
-- AM_Config_TextEditor_Font Functions
---------------------------------------------------------------------------------------------------

function AuraMasteryConfig:OnIconTextAdd( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	self:AddIconText(icon)
	self:AddIconTextEditor()
end

function AuraMasteryConfig:AddIconText(icon)
	local iconText = IconText.new(icon)
	icon.iconText[#icon.iconText + 1] = iconText
	return iconText
end


function AuraMasteryConfig:OnFontSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self:SelectFont(wndHandler)
	end
end

function AuraMasteryConfig:OnFontColorSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		local iconTextId = tonumber(wndHandler:GetParent():GetParent():FindChild("IconTextId"):GetText())
		self.selectedFontColor = icon.iconText[iconTextId].textFontColor
		self:OpenColorPicker(self.selectedFontColor, function() self:OnFontColorUpdate(wndHandler:GetParent():GetParent()) end)
	end
end

function AuraMasteryConfig:OnFontColorUpdate(textEditor)
	textEditor:FindChild("FontColorSample"):SetBGColor(self.selectedFontColor)
	textEditor:FindChild("FontSample"):SetTextColor(self.selectedFontColor)
end

function AuraMasteryConfig:OnIconTextRemove( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
		local icon = self.auraMastery.Icons[iconId]
		local iconTextId = tonumber(wndHandler:GetParent():GetParent():FindChild("IconTextId"):GetText())
		table.remove(icon.iconText, iconTextId)

		self.iconTextEditor[iconTextId]:Destroy()
		table.remove(self.iconTextEditor, iconTextId)
	end
end

---------------------------------------------------------------------------------------------------
-- Trigger Tab Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:PopulateTriggers(icon)

end

function AuraMasteryConfig:SelectTrigger(triggerDropdownItem)
	local editor = self.configForm:FindChild("TriggerWindow")

	if triggerDropdownItem == nil then
		editor:FindChild("TriggerEditor"):Show(false)
		editor:FindChild("GeneralTriggerControls"):Show(false)
	else
        self:SelectTriggerItem(triggerDropdownItem:GetData())
	end
end

function AuraMasteryConfig:PopulateTriggerItem(trigger)
    CatchError(function()
        local editor = self.configForm:FindChild("TriggerWindow")

        editor:FindChild("TriggerEditor"):Show(true)
        editor:FindChild("GeneralTriggerControls"):Show(true)
        editor:SetData(trigger)
        editor:FindChild("TriggerName"):SetText(trigger.Name)
        editor:FindChild("TriggerName"):FindChild("Placeholder"):Show(trigger.Name == "")
        editor:FindChild("TriggerType"):SetText(trigger.Type)
        editor:FindChild("TriggerBehaviour"):SetText(trigger.Behaviour)

        self:PopulateTriggerDetails(trigger.Type)

        if trigger.Type == "Action Set" then
            editor:FindChild("ActionSet1"):SetCheck(trigger.TriggerDetails.ActionSets[1])
            editor:FindChild("ActionSet2"):SetCheck(trigger.TriggerDetails.ActionSets[2])
            editor:FindChild("ActionSet3"):SetCheck(trigger.TriggerDetails.ActionSets[3])
            editor:FindChild("ActionSet4"):SetCheck(trigger.TriggerDetails.ActionSets[4])
        elseif trigger.Type == "Cooldown" then
            editor:FindChild("SpellName"):SetText(trigger.TriggerDetails.SpellName)
            editor:FindChild("SpellName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.SpellName == "")
            editor:FindChild("ChargesEnabled"):SetCheck(trigger.TriggerDetails.Charges.Enabled)
            editor:FindChild("Charges"):Enable(trigger.TriggerDetails.Charges.Enabled)
            editor:FindChild("Charges"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Charges.Operator)
            editor:FindChild("Charges"):FindChild("ChargesValue"):SetTextRaw(trigger.TriggerDetails.Charges.Value)
        elseif trigger.Type == "Buff" then
            editor:FindChild("BuffName"):SetText(trigger.TriggerDetails.BuffName)
            editor:FindChild("BuffName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.BuffName == "")

            self:PopulateTriggerItemTargets(trigger, editor)

            editor:FindChild("StacksEnabled"):SetCheck(trigger.TriggerDetails.Stacks.Enabled)
            editor:FindChild("Stacks"):Enable(trigger.TriggerDetails.Stacks.Enabled)
            editor:FindChild("Stacks"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Stacks.Operator)
            editor:FindChild("Stacks"):FindChild("StacksValue"):SetTextRaw(trigger.TriggerDetails.Stacks.Value)
        elseif trigger.Type == "Debuff" then
            editor:FindChild("DebuffName"):SetText(trigger.TriggerDetails.DebuffName)
            editor:FindChild("DebuffName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.DebuffName == "")

            self:PopulateTriggerItemTargets(trigger, editor)

            editor:FindChild("StacksEnabled"):SetCheck(trigger.TriggerDetails.Stacks.Enabled)
            editor:FindChild("Stacks"):Enable(trigger.TriggerDetails.Stacks.Enabled)
            editor:FindChild("Stacks"):FindChild("Operator"):SetTextRaw(trigger.TriggerDetails.Stacks.Operator)
            editor:FindChild("Stacks"):FindChild("StacksValue"):SetTextRaw(trigger.TriggerDetails.Stacks.Value)
        elseif trigger.Type == "Resources" then
            self:InitializeTriggerDetailsWindow(trigger.Type, self.configForm)
            self:PopulateValueBasedEditor(trigger, editor, "Mana")
            self:PopulateValueBasedEditor(trigger, editor, "Resource")
        elseif trigger.Type == "Health" then
            self:InitializeTriggerDetailsWindow(trigger.Type, self.configForm)

            self:PopulateTriggerItemTargets(trigger, editor)

            self:PopulateValueBasedEditor(trigger, editor, "Health")
            self:PopulateValueBasedEditor(trigger, editor, "Shield")
        elseif trigger.Type == "Moment Of Opportunity" then
            editor:FindChild("TargetPlayer"):SetCheck(trigger.TriggerDetails.Target.Player)
            editor:FindChild("TargetTarget"):SetCheck(trigger.TriggerDetails.Target.Target)
        elseif trigger.Type == "Scriptable" then
            editor:FindChild("Script"):SetText(trigger.TriggerDetails.Script)
            editor:FindChild("InitScript"):SetText(trigger.TriggerDetails.InitScript)
            editor:FindChild("CleanupScript"):SetText(trigger.TriggerDetails.CleanupScript)
            local formsList = editor:FindChild("FormsList")
            formsList:DestroyChildren()
            for _, form in pairs(trigger.TriggerDetails.Forms) do
                self:AddScriptableForm(formsList, form)
            end
            formsList:ArrangeChildrenVert()
        elseif trigger.Type == "Keybind" then
            self:SetKeybindInput(trigger.TriggerDetails.Input)
            editor:FindChild("KeybindTracker_Duration"):SetText(trigger.TriggerDetails.Duration)
        elseif trigger.Type == "Limited Action Set Checker" then
            editor:FindChild("AbilityName"):SetText(trigger.TriggerDetails.AbilityName)
            if trigger.TriggerDetails.AbilityName ~= "" then
                editor:FindChild("AbilityName"):FindChild("Placeholder"):Show(false, false)
            end
        elseif trigger.Type == "Cast" then
            editor:FindChild("SpellName"):SetText(trigger.TriggerDetails.SpellName)
            editor:FindChild("SpellName"):FindChild("Placeholder"):Show(trigger.TriggerDetails.SpellName == "")

            self:PopulateTriggerItemTargets(trigger, editor)
        elseif trigger.Type == "ICD" then
            self:PopulateTriggerItemTargets(trigger, editor)
            self:SetDropdown(editor:FindChild("EventType"), trigger.TriggerDetails.EventType)
            editor:FindChild("Duration"):SetText(trigger.TriggerDetails.Duration)
            editor:FindChild("SpellName"):SetText(trigger.TriggerDetails.SpellName)
            if trigger.TriggerDetails.SpellName ~= "" then
                editor:FindChild("SpellName"):FindChild("Placeholder"):Show(false, false)
            end
        end

        self.configForm:FindChild("TriggerTypeDropdown"):Show(false)

        self.configForm:FindChild("TriggerEffectsList"):DestroyChildren()
        for _, triggerEffect in pairs(trigger.TriggerEffects) do
            self:AddTriggerEffect(triggerEffect)
        end

        local effectItems = self.configForm:FindChild("TriggerEffectsList"):GetChildren()
        if #effectItems > 0 then
            effectItems[1]:SetCheck(true)
            self:OnTriggerEffectSelect(effectItems[1], effectItems[1])
        else
            self.configForm:FindChild("TriggerEffectContainer"):Show(false)
        end
    end)
end

function AuraMasteryConfig:AddScriptableForm(formsList, form)
    local formItem = Apollo.LoadForm(self.xmlDoc, "TriggerDetails.Scriptable.FormsList.Form", formsList, self)
    formItem:FindChild("FormLabel"):SetText(form.Name)
    formItem:SetData(form)
    formsList:ArrangeChildrenVert()
end

function AuraMasteryConfig:PopulateTriggerItemTargets(trigger, editor)
    for type, val in pairs(trigger.TriggerDetails.Target) do
        local input = editor:FindChild("Target" .. type)
        if input.SetCheck ~= nil then
            input:SetCheck(val)
            if val then
                self:OnBuffTargetChanged(input)
            end
        else
            input:SetText(val)
        end
    end
    local targetGroup = editor:FindChild("TargetGroup")
    if targetGroup ~= nil then
        editor:FindChild("TargetGroup"):Enable(false)
    end
end

function AuraMasteryConfig:OnBuffTargetChanged(wndHandler)
    local currentGroup = wndHandler:GetParent()
    for _, group in pairs(wndHandler:GetParent():GetParent():GetChildren()) do
        if group ~= currentGroup then
            for _, target in pairs(group:GetChildren()) do
                if target.SetCheck ~= nil then
                    target:SetCheck(false)
                else
                    target:SetText("")
                    target:Enable(false)
                end
            end
        else
            for _, target in pairs(group:GetChildren()) do
                if target.SetCheck == nil then
                    target:Enable(true)
                end
            end
        end
    end
end

function AuraMasteryConfig:SelectTriggerItem(trigger)
    self:OnOK()
    self:PopulateTriggerItem(trigger)
    self:SelectTab("Triggers")
end

function AuraMasteryConfig:PopulateValueBasedEditor(trigger, editor, resourceType)
	local resourceEditor = editor:FindChild(resourceType)

	if trigger.TriggerDetails[resourceType] ~= nil then
		editor:FindChild(resourceType .. "Enabled"):SetCheck(true)
		self:ToggleResourceEditor(resourceEditor, true)
		resourceEditor:FindChild("Operator"):SetTextRaw(trigger.TriggerDetails[resourceType].Operator)
		resourceEditor:FindChild("Value"):SetText(trigger.TriggerDetails[resourceType].Value)
		resourceEditor:FindChild("Percent"):SetCheck(trigger.TriggerDetails[resourceType].Percent)
	else
		editor:FindChild(resourceType .. "Enabled"):SetCheck(false)
		self:ToggleResourceEditor(resourceEditor, false)
		resourceEditor:FindChild("Operator"):SetTextRaw(">")
		resourceEditor:FindChild("Value"):SetText("")
		resourceEditor:FindChild("Percent"):SetCheck(false)
	end
end

function AuraMasteryConfig:OnAddTrigger( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		GeminiPackages:Require('AuraMastery:IconTrigger', function(iconTrigger)
			local trigger = iconTrigger.new(icon, icon.buffWatch)
			trigger.Name = ""
			--trigger.TriggerDetails = { SpellName = "" }
			table.insert(icon.Triggers, trigger)

            self:RebuildTriggerList(self.selectedIcon, icon)

            local left, top, right, bottom = self.selectedIcon:GetAnchorOffsets()
            self.selectedIcon:SetAnchorOffsets(left, top, right, top + 83 + (#icon.Triggers * 30))
            self.configForm:FindChild("IconList"):ArrangeChildrenVert()
            self.configForm:FindChild("TriggerWindow"):SetData(trigger)
            self:PopulateTriggerItem(trigger)
            self:OnOK()
		end)
	end
end

function AuraMasteryConfig:OnDeleteTrigger( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				trigger:RemoveFromBuffWatch()
				table.remove(icon.Triggers, triggerId)
				self:PopulateTriggers(icon)
				break
			end
		end
        self:SelectTab("General")
        self:RebuildTriggerList(self.selectedIcon, icon)
        self:UpdateControls()
	end
end

function AuraMasteryConfig:OnTriggerMoveUp( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				if triggerId > 1 then
					icon.Triggers[triggerId] = icon.Triggers[triggerId-1]
					icon.Triggers[triggerId-1] = trigger

					self:PopulateTriggers(icon)
				end
				break
			end
		end
        self:RebuildTriggerList(self.selectedIcon, icon)
	end
end

function AuraMasteryConfig:OnTriggerMoveDown( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local trigger = wndHandler:GetParent():GetData()
		for triggerId, t in pairs(icon.Triggers) do
			if trigger == t then
				if triggerId < # icon.Triggers then
					icon.Triggers[triggerId] = icon.Triggers[triggerId+1]
					icon.Triggers[triggerId+1] = trigger

					self:PopulateTriggers(icon)
				end
				break
			end
		end
        self:RebuildTriggerList(self.selectedIcon, icon)
	end
end

function AuraMasteryConfig:OnTriggerType( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerType"):SetText(wndHandler:GetName():sub(12))
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)

	self:PopulateTriggerDetails(wndHandler:GetName():sub(12))
end

function AuraMasteryConfig:PopulateTriggerDetails(triggerType)
	local editor = self.configForm:FindChild("TriggerEditor")
	local triggerDetails = editor:FindChild("TriggerDetails")
	if triggerDetails ~= nil then
		triggerDetails:Destroy()
	end

	local triggerEffects = self.configForm:FindChild("TriggerEffects")
	local detailsEditor = Apollo.LoadForm("AuraMastery.xml", "TriggerDetails." .. triggerType, editor, self)
	if detailsEditor ~= nil then
		detailsEditor:SetName("TriggerDetails")
		detailsEditor:SetAnchorOffsets(0, 10, 0, 10 + detailsEditor:GetHeight())
		triggerEffects:SetAnchorOffsets(0, 10 + detailsEditor:GetHeight(), 0, 10 + detailsEditor:GetHeight() + triggerEffects:GetHeight())

		self:InitializeTriggerDetailsWindow(triggerType, self.configForm)
	else
		triggerEffects:SetAnchorOffsets(0, 10, 0, 10 + triggerEffects:GetHeight())
	end
end

function AuraMasteryConfig:InitializeTriggerDetailsWindow(triggerType, detailsEditor)
	detailsEditor:FindChild("TriggerTypeDropdown"):Show(false)
    local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    local icon = self.auraMastery.Icons[iconId]

	if triggerType == "Resources" then
		self:InitializeResourceEditor(detailsEditor:FindChild("Mana"))
		self:InitializeResourceEditor(detailsEditor:FindChild("Resource"))
	elseif triggerType == "Health" then
		self:InitializeResourceEditor(detailsEditor:FindChild("Health"))
		self:InitializeResourceEditor(detailsEditor:FindChild("Shield"))
	elseif triggerType == "Cooldown" then
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("SpellName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Buff" then
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("BuffName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Debuff" then
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("DebuffName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
		self:InitializeResourceEditor(detailsEditor)
	elseif triggerType == "Limited Action Set Checker" then
		if icon ~= nil then
			detailsEditor:FindChild("TriggerDetails"):FindChild("AbilityName"):FindChild("Placeholder"):SetText(icon.iconName)
		end
    elseif triggerType == "Cast" then
        if icon ~= nil then
            detailsEditor:FindChild("TriggerDetails"):FindChild("SpellName"):FindChild("Placeholder"):SetText(icon.iconName)
        end
	elseif triggerType == "ICD" then
        if icon ~= nil then
            detailsEditor:FindChild("TriggerDetails"):FindChild("SpellName"):FindChild("Placeholder"):SetText(icon.iconName)
            self:SetDropdownIndex(detailsEditor:FindChild("EventType"), 1)
        end
    end
end

function AuraMasteryConfig:InitializeResourceEditor(editor)
	editor:FindChild("Operator"):AddItem("==", "", 1)
	editor:FindChild("Operator"):AddItem("!=", "", 2)
	editor:FindChild("Operator"):AddItem(">", "", 3)
	editor:FindChild("Operator"):AddItem("<", "", 4)
	editor:FindChild("Operator"):AddItem(">=", "", 5)
	editor:FindChild("Operator"):AddItem("<=", "", 6)
end

function AuraMasteryConfig:OnCheckTriggerTypeButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEditor"):Enable(false)
	self.configForm:FindChild("TriggerTypeDropdown"):Show(true)
end

function AuraMasteryConfig:OnUncheckTriggerTypeButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerTypeDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerTypeDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerType"):SetCheck(false)
	self.configForm:FindChild("TriggerEditor"):Enable(true)
end

function AuraMasteryConfig:OnTriggerBehaviour( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerBehaviour"):SetText(wndHandler:GetName():sub(17))
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerBehaviourDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerBehaviour"):SetCheck(false)
	self.configForm:FindChild("TriggerEditor"):Enable(true)
end

function AuraMasteryConfig:OnCheckTriggerBehaviourButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEditor"):Enable(false)
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(true)
end

function AuraMasteryConfig:OnUncheckTriggerBehaviourButton( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerBehaviourDropdown"):Show(false)
end

function AuraMasteryConfig:OnResourceStateToggle( wndHandler, wndControl, eMouseButton )
	local resourceName = string.sub(wndControl:GetName(), 0, -8)
	local editor = wndControl:GetParent():FindChild(resourceName)
	if editor ~= nil then
		self:ToggleResourceEditor(editor, wndControl:IsChecked())
	end
end

function AuraMasteryConfig:ToggleResourceEditor(editor, enabled)
	editor:Enable(enabled)
	editor:SetSprite(enabled and "CRB_Basekit:kitBase_HoloOrange_TinyNoGlow" or "CRB_Basekit:kitBase_HoloBlue_TinyNoGlow")
end

function AuraMasteryConfig:OnImportIcon( wndHandler, wndControl, eMouseButton )
    CatchError(function()
    	self.configForm:FindChild("ClipboardExport"):SetText("")
    	self.configForm:FindChild("ClipboardExport"):PasteTextFromClipboard()
    	local iconData = self.configForm:FindChild("ClipboardExport"):GetText()
        local groupItem = self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetData()
        if groupItem == nil then
            Print("[AuraMastery] You must select a group before importing an Aura")
            return
        end
        self:ImportIcon(iconData, groupItem)
    end)
end

function AuraMasteryConfig:ImportIcon(iconData, groupItem)
    local result = self:ImportIconText(iconData)
    if result ~= nil then
        local newIcon = self.auraMastery:AddIcon()
        newIcon:Load(result)
        newIcon.group = groupItem:GetData().id
        self:CreateIconItem(newIcon.iconId, newIcon, groupItem:FindChild("Icons"))
        self:UpdateControls()
    end
end

function AuraMasteryConfig:ImportIconText(iconData)
    local iconScript, loadStringError = loadstring("return " .. iconData)
    if iconScript then
        local status, result = pcall(iconScript)
        if status then
            if result ~= nil and result.iconName ~= nil then
                return result
            else
                Print("Failed to import icon. Data deserialized but was invalid.")
            end
        else
            Print("Failed to import icon, invalid load data in clipboard: " .. tostring(result))
        end
    else
        Print("Failed to import icon, invalid load data in clipboard: " .. tostring(loadStringError))
    end
end

function AuraMasteryConfig:OnExportIcon( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		self.configForm:FindChild("ClipboardExport"):SetText(self:Serialize(icon:GetSaveData()))
		self.configForm:FindChild("ClipboardExport"):CopyTextToClipboard()
	end
end

function AuraMasteryConfig:OnSharingMessageReceived(channel, msg)
    CatchError(function()
    	if msg.Icon ~= nil then
    		if not self.configForm:FindChild("ShareConfirmDialog"):IsShown() then
    			self.configForm:FindChild("ShareConfirmDialog"):SetData(msg.Icon)
    			self.configForm:FindChild("ShareConfirmDialog"):Show(true)
    			self.configForm:FindChild("ShareConfirmDialog"):FindChild("ShareConfirmMessage"):SetText(msg.Sender .. " would like to share the icon '" .. msg.Icon.iconName .. "' with you.\n\nWould you like to accept this icon?")
    		end
    	end
    end)
end

function AuraMasteryConfig:OnAcceptIconShare( wndHandler, wndControl, eMouseButton )
	local shareConfirmDialog = self.configForm:FindChild("ShareConfirmDialog")
	local icon = shareConfirmDialog:GetData()
    local groupItem = self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetData()
    if groupItem == nil then
        Print("[AuraMastery] You must select a group before importing an Aura")
        return
    end

	if icon ~= nil then
		local newIcon = self.auraMastery:AddIcon()
		newIcon:Load(icon)
        newIcon.group = groupItem:GetData().id
		self:CreateIconItem(newIcon.iconId, newIcon, groupItem:FindChild("Icons"))
        self:UpdateControls()

		shareConfirmDialog:Show(false)
		shareConfirmDialog:SetData(nil)
	end
end

function AuraMasteryConfig:OnIgnoreIconShare( wndHandler, wndControl, eMouseButton )
	local shareConfirmDialog = self.configForm:FindChild("ShareConfirmDialog")
	shareConfirmDialog:Show(false)
	shareConfirmDialog:SetData(nil)
end

function AuraMasteryConfig:OnFormHide( wndHandler, wndControl )
	if wndControl == wndHandler then
		self.auraMastery.sharingCallback = nil
		self.configForm:FindChild("ShareForm"):FindChild("AllowShareRequests"):SetCheck(false)
		self.configForm:FindChild("ShareButton"):SetBGColor("ffffffff")
	end
end

function AuraMasteryConfig:OnShareIcon( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("ShareForm"):Show(true)
end

function AuraMasteryConfig:OnSendIcon( wndHandler, wndControl, eMouseButton )
    CatchError(function()
    	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    	local icon = self.auraMastery.Icons[iconId]
    	if icon ~= nil then
    		local msg = {}
    		msg.Icon = icon:GetSaveData()
    		self.auraMastery:SendCommsMessageToPlayer(self.configForm:FindChild("ShareForm"):FindChild("Name"):GetText(), msg)
    	end
    end)
end

function AuraMasteryConfig:OnSendIconToGroup( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	if icon ~= nil then
		local msg = {}
		msg.Icon = icon:GetSaveData()
		self.auraMastery:SendCommsMessageToGroup(msg)
	end
end

function AuraMasteryConfig:OnEnableShareRequests( wndHandler, wndControl, eMouseButton )
    self.auraMastery:ShareChannelConnect()
	self.auraMastery.sharingCallback = function(chan, msg) self:OnSharingMessageReceived(chan, msg) end
	self.configForm:FindChild("ShareButton"):SetBGColor("ffffff00")
end

function AuraMasteryConfig:OnDisableShareRequests( wndHandler, wndControl, eMouseButton )
	self.auraMastery.sharingCallback = nil
	self.configForm:FindChild("ShareButton"):SetBGColor("ffffffff")
end

function AuraMasteryConfig:Serialize(val, name)
	local tmp = ""
    if name then
		if type(name) == "number" then
			tmp = tmp .. "[" .. name .. "]" .. " = "
		else
			tmp = tmp .. "['" .. name .. "']" .. " = "
		end
	end

    if type(val) == "table" then
        tmp = tmp .. "{"

        for k, v in pairs(val) do
            tmp =  tmp .. self:Serialize(v, k) .. ","
        end

        tmp = tmp .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

function AuraMasteryConfig:OpenColorPicker(color, callback)
	self.colorPicker:Show(true)
	self.colorPicker:ToFront()
	self.editingColor = color
	self.originalColor = CColor.new(color.r, color.g, color.b, color.a)
	self.onColorChange = callback

	self.colorPicker:FindChild("PreviewOld"):SetBGColor(self.originalColor)
	self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)

	self.colorPicker:FindChild("Red"):SetText(string.format("%.f", math.max(0, color.r * 255)))
	self.colorPicker:FindChild("Green"):SetText(string.format("%.f", math.max(0, color.g * 255)))
	self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", math.max(0, color.b * 255)))
	self.colorPicker:FindChild("AlphaText"):SetText(string.format("%.f", math.max(0, color.a * 100)))
	self.colorPicker:FindChild("AlphaSlider"):SetValue(string.format("%.f", math.max(0, color.a * 100)))

	self:UnpackColor()
end

function AuraMasteryConfig:OnCloseColorPicker( wndHandler, wndControl, eMouseButton )
	self.editingColor.r, self.editingColor.g, self.editingColor.b = self.originalColor.r, self.originalColor.g ,self.originalColor.b
	self.onColorChange()
	self.colorPicker:Show(false)
end

function AuraMasteryConfig:OnColorPickerOk( wndHandler, wndControl, eMouseButton )
	self.editingColor = nil
	self.originalColor = nil
	self.colorPicker:Show(false)
end

function AuraMasteryConfig:OnColorPickerColorStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self.colorPickerColorSelected = true
		self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
	end
end

function AuraMasteryConfig:OnColorPickerColorStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.colorPickerColorSelected = false
	end
end

function AuraMasteryConfig:OnColorPickerColorMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.colorPickerColorSelected then
			self:OnColorMove(nLastRelativeMouseX, nLastRelativeMouseY)
		end
	end
end

function AuraMasteryConfig:OnColorMove(x, y)
	local indicator = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator")
	local offset = math.max(0, math.min(1, y / self.colorPicker:FindChild("Color"):GetHeight()))
	indicator:SetAnchorPoints(0, offset, 1, offset)
	self:UpdateColorPicker()
end

local function ConvertRGBToHSV(r, g, b)
    local h, s, v
    local min, max, delta

    min = math.min(r, g, b)
    max = math.max(r, g, b)

    v = max;
    delta = max - min;
    if max > 0.0 then
        s = (delta / max)
    else
        r, g ,b = 0, 0, 0
        s = 0.0
        h = nil
        return h, s, v
    end
    if r >= max then
        h = ( g - b ) / delta
    else
	    if g >= max then
	        h = 2.0 + ( b - r ) / delta
	    else
	        h = 4.0 + ( r - g ) / delta
	    end
	end

    h = h * 60.0

    if h < 0.0 then
        h = h + 360.0
    end

    return h, s, v
end

local function ConvertHSVToRGB(h, s, v)
    local hh, p, q, t, ff
    local i
    local r, g, b

    if s <= 0.0 then
        r, g, b = v, v, v
        return r, g, b
    end

    hh = h
    if hh >= 360.0 then hh = 0.0 end
    hh = hh / 60.0
    i = math.floor(hh)
    ff = hh - i;
    p = v * (1.0 - s);
    q = v * (1.0 - (s * ff));
    t = v * (1.0 - (s * (1.0 - ff)));

    if i == 0 then
    	r, g, b = v, t, p
    elseif i == 1 then
    	r, g, b = q, v, p
    elseif i == 2 then
    	r, g, b = p, v, t
    elseif i == 3 then
    	r, g, b = p, q, v
    elseif i == 4 then
    	r, g, b = t, p, v
    else
    	r, g, b = v, p, q
    end
    return r, g, b
end

function AuraMasteryConfig:UpdateColorPicker()
	local colorOffsetX, h = self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):GetAnchorPoints()
	local s, v = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):GetAnchorPoints()

	h = math.max(0, math.min(1, h))
	s = math.max(0, math.min(1, s))
	v = math.max(0, math.min(1, v))

	h = (1 - h) * 360
	v = (1 - v) * 255
	local r, g, b = ConvertHSVToRGB(h, s, v)

	self.colorPicker:FindChild("Red"):SetText(string.format("%.f", r))
	self.colorPicker:FindChild("Green"):SetText(string.format("%.f", g))
	self.colorPicker:FindChild("Blue"):SetText(string.format("%.f", b))
	local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
	self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

	self.editingColor.r = r / 255
	self.editingColor.g = g / 255
	self.editingColor.b = b / 255
	self:UpdateColor()
end

function AuraMasteryConfig:UnpackColor()
	local r = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Red"):GetText()) or 0))
	local g = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Green"):GetText()) or 0))
	local b = math.min(255, math.max(0, tonumber(self.colorPicker:FindChild("Blue"):GetText()) or 0))

	local h, s, v = ConvertRGBToHSV(r, g, b)
	local gradOffsetY = 1 - (v / 255)

	local gr, gg, gb = ConvertHSVToRGB(h, 1, 255)
	self.colorPicker:FindChild("Gradient"):SetBGColor(CColor.new(gr / 255, gg / 255, gb / 255, 1))

	self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator"):SetAnchorPoints(s, gradOffsetY, s, gradOffsetY)
	local colorPos = 1 - (h / 360)
	self.colorPicker:FindChild("Color"):FindChild("SelectIndicator"):SetAnchorPoints(0, colorPos, 1, colorPos)

	self.editingColor.r = r / 255
	self.editingColor.g = g / 255
	self.editingColor.b = b / 255

	self:UpdateColor()
end

function AuraMasteryConfig:UpdateColor()
	self.colorPicker:FindChild("PreviewNew"):SetBGColor(self.editingColor)
	self.colorPicker:FindChild("HexCode"):SetText(string.format("%02x%02x%02x%02x", self.editingColor.r * 255, self.editingColor.g * 255, self.editingColor.b * 255, self.editingColor.a * 255))

	self.onColorChange()
end

function AuraMasteryConfig:OnColorChange( wndHandler, wndControl, strText )
	self:UnpackColor()
end

function AuraMasteryConfig:OnColorPickerGradientStart( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler == wndControl then
		self.colorPickerGradientSelected = true
		self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
	end
end

function AuraMasteryConfig:OnColorPickerGradientStop( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		self.colorPickerGradientSelected = false
	end
end

function AuraMasteryConfig:OnColorPickerGradientMove( wndHandler, wndControl, nLastRelativeMouseX, nLastRelativeMouseY )
	if wndHandler == wndControl then
		if self.colorPickerGradientSelected then
			self:UpdateGradientPosition(nLastRelativeMouseX, nLastRelativeMouseY)
		end
	end
end

function AuraMasteryConfig:UpdateGradientPosition(x, y)
	local indicator = self.colorPicker:FindChild("Gradient"):FindChild("SelectIndicator")
	local offsetX = math.max(0, math.min(1, x / self.colorPicker:FindChild("Gradient"):GetWidth()))
	local offsetY = math.max(0, math.min(1, y / self.colorPicker:FindChild("Gradient"):GetHeight()))

	indicator:SetAnchorPoints(offsetX, offsetY, offsetX, offsetY)

	self:UpdateColorPicker()
end

function AuraMasteryConfig:OnAlphaSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", fNewValue))
	self.editingColor.a = fNewValue / 100
	self:UpdateColor()
end

function AuraMasteryConfig:OnAlphaTextChanged( wndHandler, wndControl, strText )
	local alpha = math.min(255, math.max(0, self.colorPicker:FindChild("AlphaText"):GetText() or 0))
	self.colorPicker:FindChild("AlphaSlider"):SetValue(alpha)
	self.editingColor.a = alpha / 100
	self:UpdateColor()
end

function AuraMasteryConfig:OnHexCodeChanged( wndHandler, wndControl, strText )
	if string.len(strText) == 8 then
		local r = tonumber(string.sub(strText, 1, 2), 16)
		local g = tonumber(string.sub(strText, 3, 4), 16)
		local b = tonumber(string.sub(strText, 5, 6), 16)
		local a = tonumber(string.sub(strText, 7, 8), 16)
		self.editingColor.r, self.editingColor.g, self.editingColor.b, self.editingColor.a = r / 255, g / 255, b / 255, a / 255


		self.colorPicker:FindChild("AlphaText"):SetText(string.format("%i", self.editingColor.a * 100))
		self.colorPicker:FindChild("AlphaSlider"):SetValue(self.editingColor.a * 100)

		self:UpdateColor()
	end
end

function AuraMasteryConfig:OnPlaceholderEditorChanged( wndHandler, wndControl, strText )
	if wndHandler == wndControl then
		wndHandler:FindChild("Placeholder"):Show(strText == "")
	end
end

---------------------------------------------------------------------------------------------------
-- Trigger Effect Functions
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnColorChanger( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		local oldColor = wndHandler:FindChild("ColorSample"):GetBGColor()
		local color = CColor.new(oldColor.r, oldColor.g, oldColor.b, oldColor.a)
		wndHandler:FindChild("ColorSample"):SetBGColor(color)
		self:OpenColorPicker(color, function() wndHandler:FindChild("ColorSample"):SetBGColor(color) end)
	end
end

function AuraMasteryConfig:OnCheckAddTriggerEffect( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(true)
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList"):Enable(false)
end

function AuraMasteryConfig:OnUncheckAddTriggerEffect( wndHandler, wndControl, eMouseButton )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(false)
end

function AuraMasteryConfig:OnTriggerEffectDropdownHidden( wndHandler, wndControl )
	self.configForm:FindChild("TriggerEffects"):FindChild("AddTriggerEffect"):SetCheck(false)
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList"):Enable(true)
end

function AuraMasteryConfig:OnAddTriggerEffect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsDropdown"):Show(false)
	local triggerEffectsList = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList")
	triggerEffectsList:Enable(true)
	GeminiPackages:Require("AuraMastery:TriggerEffect", function(TriggerEffect)
		local selectedTrigger = self.configForm:FindChild("TriggerWindow"):GetData()
		if selectedTrigger ~= nil then
			local triggerEffect = TriggerEffect.new(selectedTrigger, wndHandler:GetText())
			table.insert(selectedTrigger.TriggerEffects, triggerEffect)
			self:AddTriggerEffect(triggerEffect)
		end
	end)
end

function AuraMasteryConfig:AddTriggerEffect(triggerEffect)
	local triggerEffectsList = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectsList")
	local option = Apollo.LoadForm("AuraMastery.xml", "TriggerEffects.TriggerEffectOption", triggerEffectsList, self)
	triggerEffectsList:ArrangeChildrenVert()
	option:SetText(triggerEffect.Type)
	option:SetData(triggerEffect)
end

function AuraMasteryConfig:GetNextEffect(selectedEffectItem)
	local currentEffect, lastEffect
	local found
	for id, effect in pairs(self.configForm:FindChild("TriggerEffectsList"):GetChildren()) do
		lastEffect = currentEffect
		currentEffect = effect
		if found then
			return effect
		end
		if selectedEffectItem == effect then
			found = true
		end
	end

	if selectedEffectItem == currentEffect then
		return lastEffect
	else
		return nil
	end
end

function AuraMasteryConfig:OnRemoveTriggerEffect( wndHandler, wndControl, eMouseButton )
	local selectedTrigger = self.configForm:FindChild("TriggerWindow"):GetData()
	if selectedTrigger ~= nil then
		local selectedEffectItem = self.configForm:FindChild("TriggerEffectsList"):GetData()
		if selectedEffectItem ~= nil then
			local selectedEffect = selectedEffectItem:GetData()
			selectedTrigger:RemoveEffect(selectedEffect)
			local nextEffect = self:GetNextEffect(selectedEffectItem)
			selectedEffectItem:Destroy()
			local numEffects = #self.configForm:FindChild("TriggerEffectsList"):GetChildren()
			if numEffects > 0 then
				self.configForm:FindChild("TriggerEffectsList"):ArrangeChildrenVert()
				nextEffect:SetCheck(true)
				self:OnTriggerEffectSelect(nextEffect, nextEffect, 1)
			else
				triggerEffects:FindChild("TriggerEffectContainer"):Show(true)
			end
		end
	end
end

function AuraMasteryConfig:OnTriggerEffectSelect( wndHandler, wndControl, eMouseButton )
	local triggerEffects = self.configForm:FindChild("TriggerEffects")
	local triggerEffectEditor = self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectEditor")
	if triggerEffectEditor ~= nil then
		triggerEffectEditor:Destroy()
	end
	self.configForm:FindChild("TriggerEffectsList"):SetData(wndHandler)
	triggerEffectEditor = Apollo.LoadForm("AuraMastery.xml", "TriggerEffects." .. wndHandler:GetText(), self.configForm:FindChild("TriggerEffects"):FindChild("TriggerEffectOptions"), self)
	if triggerEffectEditor ~= nil then
		triggerEffectEditor:SetName("TriggerEffectEditor")
	end
	local triggerEffect = wndHandler:GetData()
	if triggerEffect ~= nil then
		if triggerEffect.When == "Pass" then
			triggerEffects:FindChild("TriggerEffectOnPass"):SetCheck(true)
			triggerEffects:FindChild("TriggerEffectOnFail"):SetCheck(false)
		else
			triggerEffects:FindChild("TriggerEffectOnPass"):SetCheck(false)
			triggerEffects:FindChild("TriggerEffectOnFail"):SetCheck(true)
		end
		triggerEffects:FindChild("TriggerEffectIsTimed"):SetCheck(triggerEffect.isTimed)
		triggerEffects:FindChild("TriggerEffectTimerLength"):SetText(triggerEffect.timerLength)
		if triggerEffect.Type == "Icon Color" then
			local color = CColor.new(triggerEffect.EffectDetails.Color.r, triggerEffect.EffectDetails.Color.g, triggerEffect.EffectDetails.Color.b, triggerEffect.EffectDetails.Color.a)
			triggerEffectEditor:FindChild("IconColor"):FindChild("ColorSample"):SetBGColor(color)
		elseif triggerEffect.Type == "Activation Border" then
			for _, border in pairs(triggerEffectEditor:FindChild("BorderSelect"):GetChildren()) do
				if border:FindChild("Window"):GetSprite() == triggerEffect.EffectDetails.BorderSprite then
					border:SetCheck(true)
				else
					border:SetCheck(false)
				end
			end
		end
	end
	triggerEffects:FindChild("TriggerEffectContainer"):Show(true)
end

function AuraMasteryConfig:OnCooldownChargesToggle( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():FindChild("Charges"):Enable(wndHandler:IsChecked())
	end
end

function AuraMasteryConfig:OnTriggerDetailsStacksToggle( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():FindChild("Stacks"):Enable(wndHandler:IsChecked())
	end
end

---------------------------------------------------------------------------------------------------
---- Simple Tab
---------------------------------------------------------------------------------------------------
function AuraMasteryConfig:OnAuraTypeSelect( wndHandler, wndControl, eMouseButton )
	local auraType = string.sub(wndHandler:GetName(), 10)
	wndHandler:GetParent():SetData(wndHandler)
	if auraType == "Buff" or auraType == "Debuff" then
		self.configForm:FindChild("AuraBuffDetails"):Show(true)
	else
		self.configForm:FindChild("AuraBuffDetails"):Show(false)
	end
end

function AuraMasteryConfig:PopulateAuraSpellNameList()
	local spellNameList = self.configForm:FindChild("AuraSpellNameList")

	local filterOption = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSpellName_Template", spellNameList, self)
	filterOption:SetName("AuraSpellName_FilterOption")
	filterOption:SetText("")

	for _, ability in pairs(self:GetAbilitiesList()) do
		local abilityOption = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSpellName_Template", spellNameList, self)
		abilityOption:SetText(ability.strName)
		abilityOption:SetData(ability)
	end
	spellNameList:ArrangeChildrenVert()

	local spriteList = self.configForm:FindChild("AuraIconSelect")

	local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSprite_Template", spriteList, self)
	spriteItem:FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(self.configForm:FindChild("BuffName"):GetText()))
	spriteItem:SetName("AuraSprite_Default")
	spriteItem:FindChild("SpriteItemText"):SetText("Spell Icon")

	for spriteName, spriteIcon in pairs(self.auraMastery.spriteIcons) do
		local spriteItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSprite_Template", spriteList, self)
		spriteItem:FindChild("SpriteItemIcon"):SetSprite(spriteIcon)
		spriteItem:FindChild("SpriteItemText"):SetText(spriteName)
	end
	spriteList:ArrangeChildrenTiles()

	local soundList = self.configForm:FindChild("AuraSoundSelect")

	local soundItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSound_Template", soundList, self)
	soundItem:SetData(-1)
	soundItem:SetText("None")

	for sound, soundNo in pairs(Sound) do
		if type(soundNo) == "number" then
			local soundItem = Apollo.LoadForm("AuraMastery.xml", "SimpleTabParameters.AuraSound_Template", soundList, self)
			soundItem:SetData(soundNo)
			soundItem:SetText(sound)
		end
	end
	soundList:ArrangeChildrenVert()
end

function AuraMasteryConfig:OnAuraSpellNameFilterChanged( wndHandler, wndControl, filterText )
	self:SetAuraSpellNameFilter(filterText)
end

function AuraMasteryConfig:SetAuraSpellNameFilter(filterText)
	if filterText ~= "" then
		self.configForm:FindChild("AuraSpellNameFilter"):FindChild("Placeholder"):Show(false)
	else
		self.configForm:FindChild("AuraSpellNameFilter"):FindChild("Placeholder"):Show(true)
	end

	local spellNameList = self.configForm:FindChild("AuraSpellNameList")
	for _, abilityOption in pairs(spellNameList:GetChildren()) do
		if abilityOption:GetName() == "AuraSpellName_FilterOption" then
			abilityOption:SetText(filterText)
		elseif abilityOption:GetText():lower():find(filterText:lower()) ~= nil then
			abilityOption:Show(true)
		else
			abilityOption:Show(false)
		end
	end
	spellNameList:ArrangeChildrenVert()

	if self.configForm:FindChild("AuraSpellName_FilterOption"):IsChecked() then
		self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(filterText))
	end
end

function AuraMasteryConfig:OnAuraNameFilterChanged( wndHandler, wndControl, filterText )
	self:SetAuraNameFilter(filterText)
end

function AuraMasteryConfig:SetAuraNameFilter(filterText)
	if filterText ~= "" then
		self.configForm:FindChild("BuffName"):FindChild("Placeholder"):Show(false)
	else
		self.configForm:FindChild("BuffName"):FindChild("Placeholder"):Show(true)
	end

	local spellNameList = self.configForm:FindChild("AuraNameList")
	for _, abilityOption in pairs(spellNameList:GetChildren()) do
		if abilityOption:GetText():lower():find(filterText:lower()) ~= nil then
			abilityOption:Show(true)
		else
			abilityOption:Show(false)
		end
	end
	spellNameList:ArrangeChildrenVert()
end

function AuraMasteryConfig:OnGenerateAuraSpellTooltip(wndHandler, wndControl)
	-- if wndControl == wndHandler then
	-- 	splTarget = wndControl:GetData()
	-- 	local currentTier = splTarget.nCurrentTier
	-- 	splObject = splTarget.tTiers[currentTier].Spell.CodeEnumCastResult.ItemObjectiveComplete
    --
	-- 	Tooltip.GetSpellTooltipForm(self, wndHandler, GameLib.GetSpell(splObject:GetId()), false)
	-- end
end

function AuraMasteryConfig:OnAuraSoundSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		Sound.Play(wndHandler:GetData())
		wndHandler:GetParent():SetData(wndHandler)
	end
end

function AuraMasteryConfig:OnAuraScaleChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]

	fNewValue = tonumber(string.format("%.1f", fNewValue))
	icon:SetScale(fNewValue)
	wndHandler:GetParent():FindChild("AuraSpriteScaleText"):SetText(fNewValue)
end

function AuraMasteryConfig:OnAuraScaleTextChanged( wndHandler, wndControl, strText )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]
	local value = tonumber(strText)
	local scaleSlider = wndHandler:GetParent():FindChild("AuraSpriteScaleSlider")
	if value == nil then
		value = tonumber(string.format("%.1f", scaleSlider:GetValue()))
	end

	wndHandler:SetText(tostring(value))
	icon:SetScale(value)
	scaleSlider:SetValue(value)
end

function AuraMasteryConfig:OnAuraSpellNameSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():SetData(wndHandler)
		self.configForm:FindChild("AuraSprite_Default"):FindChild("SpriteItemIcon"):SetSprite(self:GetSpellIconByName(wndHandler:GetText()))
	end
end

function AuraMasteryConfig:OnAuraNameSelect( wndHandler, wndControl, eMouseButton )
	wndHandler:GetParent():GetParent():FindChild("BuffName"):SetText(wndHandler:GetText())
	self:OnSpellNameChanged(nil, nil, wndHandler:GetText())
end

function AuraMasteryConfig:OnAuraSpriteSelect( wndHandler, wndControl, eMouseButton )
	if wndHandler == wndControl then
		wndHandler:GetParent():SetData(wndHandler)
	end
end

function AuraMasteryConfig:OnAdvancedMode( wndHandler, wndControl, eMouseButton )
	local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
	local icon = self.auraMastery.Icons[iconId]

	icon.SimpleMode = false
	self:SelectIcon(self.selectedIcon)
end

function AuraMasteryConfig:OnKeybindKeySelect( wndHandler, wndControl, eMouseButton )
	Apollo.RegisterEventHandler("SystemKeyDown", "OnKeybindKeySet", self)
	Apollo.RegisterEventHandler("MouseButtonDown", "OnKeybindMouseButtonSet", self)
	wndControl:SetFocus()
	wndControl:ClearFocus()
end

function AuraMasteryConfig:OnKeybindKeySet(iKey)
	if iKey ~= 16 and iKey ~= 17 then
		Apollo.RemoveEventHandler("SystemKeyDown", self)
		Apollo.RemoveEventHandler("MouseButtonDown", self)
		local keyText = ""
		local input = {
			Key = iKey,
			Shift = false,
			Control = false,
			Alt = false
		}
		if Apollo.IsShiftKeyDown() then
			input.Shift = true
		end
		if Apollo.IsControlKeyDown() then
			input.Control = true
		end
		if Apollo.IsAltKeyDown() then
			input.Alt = true
		end
		self:SetKeybindInput(input)
	end
end

function AuraMasteryConfig:OnKeybindMouseButtonSet(mouseButton)
	Apollo.RemoveEventHandler("SystemKeyDown", self)
	Apollo.RemoveEventHandler("MouseButtonDown", self)
	local keyText = ""
	local input = {
		Key = "MB:" .. mouseButton,
		Shift = false,
		Control = false,
		Alt = false
	}
	if Apollo.IsShiftKeyDown() then
		input.Shift = true
	end
	if Apollo.IsControlKeyDown() then
		input.Control = true
	end
	if Apollo.IsAltKeyDown() then
		input.Alt = true
	end
	self:SetKeybindInput(input)
end

function AuraMasteryConfig:SetKeybindInput(input)
	local keyText = ""
	if input.Shift then
		keyText = keyText .. "Shift+"
	end
	if input.Control then
		keyText = keyText .. "CTRL+"
	end
	if input.Alt then
		keyText = keyText .. "Alt+"
	end

	if string.sub(input.Key, 1, 2) == "MB" then
		keyText = input.Key
	elseif (input.Key >= 48 and input.Key <= 57) or (input.Key >= 65 and input.Key <= 90) then
		keyText = keyText .. string.char(input.Key)
	elseif keys[input.Key] ~= nil then
		keyText = keyText .. tostring(keys[input.Key])
	else
		keyText = keyText .. tostring(input.Key)
	end
	local keySelect = self.configForm:FindChild("KeybindTracker_KeySelect")
	keySelect:SetText(keyText)
	keySelect:SetData(input)
end

function AuraMasteryConfig:OnIconSelectorOpen( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    self.iconSelector = Apollo.LoadForm("AuraMastery.xml", "IconSelector", nil, self)
    self.iconSelector:Show(true)

    self:LoadSpriteIcons(self.iconSelector:FindChild("IconList"))
    self.lastSelectedSprite = self.selectedSprite
end

function AuraMasteryConfig:OnIconSelectorClose( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    self:SelectSpriteIcon(self.lastSelectedSprite)
    self.iconSelector:Destroy()
end

function AuraMasteryConfig:OnIconSelectorConfirm( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    self.iconSelector:Destroy()
end

function AuraMasteryConfig:TrackLineNumberAdjust( wndHandler, wndControl, eMouseButton )
    if wndHandler == wndControl then
        local field = wndHandler:GetParent():FindChild("TrackLineNumberOfLines")
        if wndHandler:GetName() == "TrackLinesMinus" then
            field:SetText(math.max(0, field:GetText() - 1))
        elseif wndHandler:GetName() == "TrackLinesPlus" then
            field:SetText(math.min(20, field:GetText() + 1))
        end
    end
end

function AuraMasteryConfig:OnDropdownOpen( wndHandler, wndControl, eMouseButton )
    if wndHandler == wndControl then
        local dropdown = wndHandler:GetParent()
        local list = dropdown:FindChild("DropdownList")
        if not list:IsShown() then
            list:Show(true, false)
        end
    end
end

function AuraMasteryConfig:OnDropdownOptionSelected( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
    if wndHandler == wndControl then
        local optionValue = wndHandler:GetText()

        local dropdown = wndHandler:GetParent():GetParent():GetParent()
        local dropdownButton = dropdown:FindChild("DropdownButton")
        local dropdownList = dropdown:FindChild("DropdownList")
        dropdown:SetData(wndHandler:GetName():sub(9))
        dropdownButton:SetText(optionValue)
        dropdownList:Show(false, false)
    end
end

function AuraMasteryConfig:SetDropdown(dropdown, value)
    local dropdownListItems = dropdown:FindChild("DropdownListItems"):GetChildren()
    for _, item in pairs(dropdownListItems) do
        if item:GetName():sub(9) == value then
            dropdown:SetData(value)
            dropdown:FindChild("DropdownButton"):SetText(item:GetText())
            return
        end
    end
    Print("[AuraMastery] Failed to set option for '" .. dropdown:GetName() .. "', invalid option: '" .. tostring(value) .. "'")
end

function AuraMasteryConfig:SetDropdownIndex(dropdown, index)
    local dropdownListItems = dropdown:FindChild("DropdownListItems"):GetChildren()
    for i, item in pairs(dropdownListItems) do
        if i == index then
            dropdown:SetData(item:GetName():sub(9))
            dropdown:FindChild("DropdownButton"):SetText(item:GetText())
            return
        end
    end
    Print("[AuraMastery] Failed to set option for '" .. dropdown:GetName() .. "', invalid index: '" .. index .. "'")
end

function AuraMasteryConfig:OnEventTypeChanged( wndHandler, wndControl )
    CatchError(function()
        local dropdown = wndHandler:GetParent()
        local triggerDetails = dropdown:GetParent():GetParent()
        triggerDetails:ArrangeChildrenVert()
    end)
end


function AuraMasteryConfig:OnCatalogOpen( wndHandler, wndControl, eMouseButton )
    if self.catalog == nil then
        self.catalog = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryCatalog", nil, self)
        self.catalog:FindChild("AuraList"):DestroyChildren()
    end

    local importGroupDropdown = self.catalog:FindChild("ImportGroup")
    local importGroupList = importGroupDropdown:FindChild("DropdownListItems")
    importGroupList:DestroyChildren()

    for idx, group in pairs(self.auraMastery.IconGroups) do
        local groupItem = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryCatalog.Footer.ImportGroup.DropdownList.DropdownListItems.DropdownOption", importGroupList, self)
        groupItem:SetName("Dropdown" .. group.id)
        groupItem:SetText(group.name)
	end

    if #self.auraMastery.IconGroups > 0 then
        self:SetDropdownIndex(importGroupDropdown, 1)
    end

    importGroupList:ArrangeChildrenVert()

    self.catalog:Show(true, false)
    self.catalog:BringToFront()
end

function AuraMasteryConfig:OnCatalogClose( wndHandler, wndControl, eMouseButton )
    self.catalog:Show(false, false)
end

function AuraMasteryConfig:OnImportGroupChanged( wndHandler, wndControl )
    CatchError(function()
        local dropdown = wndHandler:GetParent()
        local groupId = dropdown:GetData()
        for _, groupItem in pairs(self.configForm:FindChild("IconListHolder"):FindChild("IconList"):GetChildren()) do
            if groupItem:GetData().id == groupId then
                self.catalogImportGroup = groupItem
                break;
            end
        end
    end)
end

function AuraMasteryConfig:OnCategorySelectOpen( wndHandler, wndControl )
    self.catalog:FindChild("AuraList"):Enable(false)
end

function AuraMasteryConfig:OnCatalogChanged( wndHandler, wndControl )
    CatchError(function()
        self.catalog:FindChild("AuraList"):Enable(true)
        local dropdown = wndHandler:GetParent()
        self.catalogDoc = XmlDoc.CreateFromFile("Catalog/" .. dropdown:GetData() .. ".xml")
    	self.catalogDoc:RegisterCallback("OnCatalogLoaded", self)
    end)
end

function AuraMasteryConfig:OnCatalogLoaded()
    CatchError(function()
        if self.catalogDoc:IsLoaded() then
            local auraList = self.catalog:FindChild("AuraList")
            auraList:DestroyChildren()
            for _, aura in ipairs(self.catalogDoc:ToTable()[1]) do
                local icon = self:ImportIconText(aura[1].__XmlText)
                if icon ~= nil then
                    local item = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryCatalog.AuraList.AuraListItem", auraList, self)
                    item:FindChild("AuraName"):SetText(icon.iconName)
                    item:FindChild("AuraDescription"):SetText(icon.description)
                    item:FindChild("AuraIcon"):SetSprite(icon.iconSprite)
                    item:SetData(aura[1].__XmlText)
                end
            end
            auraList:ArrangeChildrenVert()
    	end
    end)
end

function AuraMasteryConfig:OnCatalogImport( wndHandler, wndControl, eMouseButton )
    local auraList = self.catalog:FindChild("AuraList")
    for _, item in pairs(auraList:GetChildren()) do
        if item:FindChild("Background"):IsChecked() then
            local auraData = item:GetData()
            if self.catalogImportGroup == nil then
                Print("[AuraMastery] You must select a group before importing an Aura")
                return
            end
            self:ImportIcon(auraData, self.catalogImportGroup)
            item:FindChild("Background"):SetCheck(false)
        end
    end
end

function AuraMasteryConfig:OnCatalogAuraSelect( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY )
    if wndHandler == wndControl then
        local auraList = wndHandler:GetParent()
        auraList:SetData(wndHandler)
    end
end

function AuraMasteryConfig:OnCatalogSelectAll( wndHandler, wndControl, eMouseButton )
    local auraList = self.catalog:FindChild("AuraList")
    for _, item in pairs(auraList:GetChildren()) do
        item:FindChild("Background"):SetCheck(true)
    end
end

function AuraMasteryConfig:OnToggleLockGroup( wndHandler, wndControl, eMouseButton )
    if wndHandler == wndControl then
        CatchError(function()
            local groupTab = wndHandler:GetParent()
            local group = groupTab:GetData()
            if group.anchor == nil then
                group.anchor = Apollo.LoadForm(self.xmlDoc, "IconGroup", nil, self)
                group.anchor:SetData(group)
            else
                group.anchor:Show(not group.anchor:IsShown())
            end

            local unlocked = group.anchor:IsShown()
            for _, icon in pairs(self.auraMastery.Icons) do
                if icon.group == group.id then
                    if unlocked then
                        icon:Unlock(false)
                    else
                        icon:Lock()
                    end
                end
            end


            local maxLeft, maxTop, maxRight, maxBottom = 99999, 99999, -99999, -99999
            for _, icon in pairs(self.auraMastery.Icons) do
                if icon.group == group.id then
                    local iconLeft, iconTop, iconRight, iconBottom = icon.icon:GetAnchorOffsets()
                    if iconLeft < maxLeft then maxLeft = iconLeft end
                    if iconTop < maxTop then maxTop = iconTop end
                    if iconRight > maxRight then maxRight = iconRight end
                    if iconBottom > maxBottom then maxBottom = iconBottom end
                end
            end

            group.anchor:SetAnchorOffsets(maxLeft - 2, maxTop - 2, maxRight + 2, maxBottom + 2)
            local left, top, right, bottom = group.anchor:GetAnchorOffsets()
            self.groupPosition = {
                left = left,
                top = top,
                right = right,
                bottom = bottom
            }
        end)
    end
end

function AuraMasteryConfig:OnIconGroupMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom, nX )
    if wndHandler == wndControl then
        CatchError(function()
            local group = wndHandler:GetData()
            local left, top, right, bottom = wndHandler:GetAnchorOffsets()
            local deltaLeft, deltaTop, deltaRight, deltaBottom = left - self.groupPosition.left, top - self.groupPosition.top, right - self.groupPosition.right, bottom - self.groupPosition.bottom

            for _, icon in pairs(self.auraMastery.Icons) do
                if icon.group == group.id then
                    local iconLeft, iconTop, iconRight, iconBottom = icon.icon:GetAnchorOffsets()
                    icon.icon:SetAnchorOffsets(iconLeft + deltaLeft, iconTop + deltaTop, iconRight + deltaRight, iconBottom + deltaBottom)
                end
            end

            self.groupPosition = {
                left = left,
                top = top,
                right = right,
                bottom = bottom
            }
        end)
    end
end

function AuraMasteryConfig:OnRegionZoneChanged( wndHandler, wndControl )
    CatchError(function()
        local zoneDropdown = wndHandler:GetParent()
        if zoneDropdown:GetData() == nil then return end

        local subZoneDropdown = zoneDropdown:GetParent():FindChild("SubZoneDropdown")

        local subZoneDropdownItems = subZoneDropdown:FindChild("DropdownListItems")
        subZoneDropdownItems:DestroyChildren()
        for key, subZone in pairs(Zones[zoneDropdown:GetData()]) do
            local dropdownItem = Apollo.LoadForm("AuraMastery.xml", "AuraMasteryForm.BuffEditor.GeneralTab.Options.Regions.SubZoneDropdown.DropdownList.DropdownListItems.DropdownOption", subZoneDropdownItems, self)
            dropdownItem:SetName("Dropdown" .. key)
            dropdownItem:SetText(key)
        end
        subZoneDropdownItems:ArrangeChildrenVert()
    end)
end

function AuraMasteryConfig:OnRegionSubZoneChanged( wndHandler, wndControl )
    CatchError(function()
        local subZoneDropdown = wndHandler:GetParent()
        if subZoneDropdown:GetData() == nil then return end

        local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    	local icon = self.auraMastery.Icons[iconId]

        local zoneDropdown = subZoneDropdown:GetParent():FindChild("ZoneDropdown")

        local zone, subZone = zoneDropdown:GetData(), subZoneDropdown:GetData()
        local zoneInfo = Zones[zone][subZone]
        if zoneInfo.catchall then
            for subZone, zoneInfo in pairs(Zones[zone]) do
                if not zoneInfo.catchall then
                    local region = {
                        zone = zone,
                        subZone = subZone,
                        id = zoneInfo.id,
                        continentId = zoneInfo.continentId,
                        parentZoneId = zoneInfo.parentZoneId,
                    }
                    icon:AddRegion(region)
                    self:AddRegionItem(region)
                end
            end
        else
            local region = {
                zone = zone,
                subZone = subZone,
                id = zoneInfo.id,
                continentId = zoneInfo.continentId,
                parentZoneId = zoneInfo.parentZoneId,
            }
            icon:AddRegion(region)
            self:AddRegionItem(region)
        end
    end)
end

function AuraMasteryConfig:RemoveRegion( wndHandler, wndControl, eMouseButton )
    if wndHandler == wndControl then
        CatchError(function()
            local regionItem = wndHandler:GetParent()
            local region = regionItem:GetData()
            local regionList = regionItem:GetParent()
            local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
        	local icon = self.auraMastery.Icons[iconId]
            icon:RemoveRegion(region)
            regionItem:Destroy()
            regionList:ArrangeChildrenVert()
        end)
    end
end

function AuraMasteryConfig:AddRegionItem(region)
    local regionList = self.configForm:FindChild("RegionList")
    local regionItem = Apollo.LoadForm(self.xmlDoc, "AuraMasteryForm.BuffEditor.GeneralTab.Options.Regions.RegionList.RegionItem", regionList, self)
    regionItem:FindChild("RegionLabel"):SetText(region.zone .. ": " .. region.subZone)
    regionItem:SetData(region)
    regionList:ArrangeChildrenVert()
end

function AuraMasteryConfig:GetIcon()
    local iconId = tonumber(self.configForm:FindChild("BuffId"):GetText())
    return self.auraMastery.Icons[iconId]
end

function AuraMasteryConfig:OnScriptableFormAdd( wndHandler, wndControl, strText )
    CatchError(function()
        if wndHandler == wndControl then
            local icon = self:GetIcon()
            local trigger = wndHandler:GetParent():GetParent():GetParent():GetData()
            local formList = wndHandler:GetParent():FindChild("FormsList")
            local form = {
                Name = strText,
                Text = ""
            }
            table.insert(trigger.TriggerDetails.Forms, form)
            self:AddScriptableForm(formList, form)
            wndHandler:SetText("")
            self:OnPlaceholderEditorChanged(wndHandler, wndHandler, "")
        end
    end)
end

function AuraMasteryConfig:OnScriptableFormRemove(wndHandler, wndControl, strText)
    CatchError(function()
        if wndHandler == wndControl then
            local trigger = wndHandler:GetParent():GetParent():GetParent():GetParent():GetParent():GetData()
            local form = wndHandler:GetParent():GetData()
            local formIndex = IndexOf(trigger.TriggerDetails.Forms, form)
            if formIndex ~= nil then
                table.remove(trigger.TriggerDetails.Forms, formIndex)
            end
            local formsList = wndHandler:GetParent():GetParent()
            wndHandler:GetParent():Destroy()
            formsList:ArrangeChildrenVert()
        end
    end)
end

function AuraMasteryConfig:OnScriptableFormSelect(wndHandler, wndControl)
    CatchError(function()
        --if wndHandler == wndControl then
            local trigger = wndHandler:GetParent():GetParent():GetParent():GetParent():GetData()
            local formEditorWindow = wndHandler:GetParent():GetParent():GetParent():FindChild("FormsScript")
            formEditorWindow:SetText(wndHandler:GetData().Text)
            formEditorWindow:SetData(wndHandler:GetData())
        --end
    end)
end

function AuraMasteryConfig:OnScriptableFormChanged( wndHandler, wndControl, strText )
    CatchError(function()
        if wndHandler == wndControl then
            local form = wndHandler:GetData()
            form.Text = strText
        end
    end)
end

local GeminiPackages = _G["GeminiPackages"]
GeminiPackages:NewPackage(AuraMasteryConfig, "AuraMastery:Config", 1)
