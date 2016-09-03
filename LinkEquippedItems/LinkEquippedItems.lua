-----------------------------------------------------------------------------------------------
-- Client Lua Script for LinkEquippedItems
-- Copyright (c) Athica ( Athica Amnell @ Jabbit (EU) )
-- Version 0.1.1
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- LinkEquippedItems Module Definition
-----------------------------------------------------------------------------------------------
local LinkEquippedItems = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local WEAPON 		= 16
local SHIELD 		= 15
local HEAD 			= 2
local SHOULDERS		= 3
local CHEST			= 0
local HANDS			= 5
local LEGS			= 1
local FEET			= 4
local WEAPATTACH	= 7
local SUPPORTSYSTEM	= 8
local IMPLANT		= 10
local GADGET		= 11

local tArgsToSlot = {
	[ "w"				] = WEAPON,
	[ "weapon"			] = WEAPON,
	[ "weap"			] = WEAPON,
	[ "psyblade"		] = WEAPON,
	[ "shotgun"			] = WEAPON,
	[ "gun"				] = WEAPON,
	[ "guns"			] = WEAPON,
	[ "heavy gun"		] = WEAPON,
	[ "heavygun"		] = WEAPON,
	[ "pistol"			] = WEAPON,
	[ "pistols"			] = WEAPON,
	[ "claw"			] = WEAPON,
	[ "claws"			] = WEAPON,
	[ "sword"			] = WEAPON,
	[ "greatsword"		] = WEAPON,
	[ "blade"			] =	WEAPON,
	[ "resonator"		] = WEAPON,
	[ "resonators"		] = WEAPON,
	
	[ "shield"			] = SHIELD,
	[ "energyshield"	] = SHIELD,
	[ "energy shield"	] = SHIELD,
	[ "es"				] = SHIELD,
	[ "sh"				] = SHIELD,
	
	[ "h"				] = HEAD,
	[ "he"				] = HEAD,
	[ "head"			] = HEAD,
	[ "helm"			] = HEAD,
	[ "helmet"			] = HEAD,
	[ "hat"				] = HEAD,
	[ "cap"				] = HEAD,
	
	[ "s"				] = SHOULDERS,
	[ "shoulder"		] = SHOULDERS,
	[ "shoulders"		] = SHOULDERS,
	[ "spaulder"		] = SHOULDERS,
	[ "spaulders"		] = SHOULDERS,
	[ "pauldron"		] = SHOULDERS,
	[ "pauldrons"		] = SHOULDERS,

	[ "c"				] = CHEST,
	[ "ch"				] = CHEST,
	[ "chest"			] = CHEST,
	[ "jacket"			] = CHEST,
	[ "coat"			] = CHEST,
	[ "chestplate"		] = CHEST,

	[ "ha"				] = HANDS,
	[ "hand"			] = HANDS,
	[ "hands"			] = HANDS,
	[ "gl"				] = HANDS,
	[ "glove"			] = HANDS,
	[ "gloves"			] = HANDS,
	[ "gauntlet"		] = HANDS,
	[ "gauntlets"		] = HANDS,
	
	[ "l"				] = LEGS,
	[ "leg"				] = LEGS,
	[ "legs"			] = LEGS,
	[ "pants"			] = LEGS,
	[ "trousers"		] = LEGS,

	[ "f"				] = FEET,
	[ "foot"			] = FEET,
	[ "feet"			] = FEET,
	[ "b"				] = FEET,
	[ "boot"			] = FEET,
	[ "boots"			] = FEET,
	[ "shoe"			] = FEET,
	[ "shoes"			] = FEET,
	
	[ "weaponattachment"	] = WEAPATTACH,
	[ "weapon attachment"	] = WEAPATTACH,
	[ "attachment"		] = WEAPATTACH,
	[ "attach"			] = WEAPATTACH,
	[ "wa"				] = WEAPATTACH,
	[ "at"				] = WEAPATTACH,

	[ "support system"	] = SUPPORTSYSTEM,
	[ "supportsystem"	] = SUPPORTSYSTEM,
	[ "support"			] = SUPPORTSYSTEM,
	[ "ss"				] = SUPPORTSYSTEM,
	
	[ "i"				] = IMPLANT,
	[ "imp"				] = IMPLANT,
	[ "implant"			] = IMPLANT,
	
	[ "g"				] = GADGET,
	[ "gad"				] = GADGET,
	[ "gadget"			] = GADGET,
	[ "trinket"			] = GADGET,
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function LinkEquippedItems:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function LinkEquippedItems:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- LinkEquippedItems OnLoad
-----------------------------------------------------------------------------------------------
function LinkEquippedItems:OnLoad()

	Apollo.RegisterSlashCommand("link",					"SlashHandler", self)
	Apollo.RegisterSlashCommand("lei",  				"SlashHandler", self)
	Apollo.RegisterSlashCommand("linkequippeditem",		"SlashHandler", self)
	Apollo.RegisterSlashCommand("linkequippeditems",	"SlashHandler", self)
	
end

-----------------------------------------------------------------------------------------------
-- LinkEquippedItems Functions
-----------------------------------------------------------------------------------------------

-- on SlashCommand "/link"
function LinkEquippedItems:SlashHandler(cmd, arg)

	if not arg or arg == "" then
	
		Print( 'LinkEquippedItems: indicate a slot, e.g. /link weapon ' )
		return
		
	end

	local slot = tArgsToSlot[ arg:lower() ]
	if not slot then
	
		Print( 'LinkEquippedItems: "'.. arg .. '" is not a known slot ' )
		return
		
	end
	
	local equipped = GameLib.GetPlayerUnit():GetEquippedItems() 
	if not equipped then return end
	
	local count = 0
	for _, iteminfo in pairs( equipped ) do
	
		local inventoryid = iteminfo:GetInventoryId()
		if inventoryid  == slot then
		
			Event_FireGenericEvent( "ItemLink" , iteminfo )
			count = count + 1
			
		end
		
	end
	
	if count == 0 then
	
		Print( 'LinkEquippedItems: you have nothing equipped in slot "'.. arg .. '" ' )
		
	end
	
end

-----------------------------------------------------------------------------------------------
-- LinkEquippedItems Instance
-----------------------------------------------------------------------------------------------
local LinkEquippedItemsInst = LinkEquippedItems:new()
LinkEquippedItemsInst:Init()
