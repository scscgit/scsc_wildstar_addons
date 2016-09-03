-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoBuffs Defaults
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"

local Defaults  = {} 
Defaults.__index = Defaults

setmetatable(Defaults, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

Defaults.luaPlayerBuffs = {
	name = "Player Buffs",
	showFrame = 1,
	buffs = true,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {-370, -262, -10, -232},
}
Defaults.luaPlayerDebuffs = {
	name = "Player Debuffs",
	showFrame = 1,
	buffs = false,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {-370, -292, -10, -262},
}


Defaults.luaTargetBuffs = {
	name = "Target Buffs",
	showFrame = 1,
	buffs = true,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {10, -232, 370, -202},
}
Defaults.luaTargetDebuffs = {
	name = "Target Debuffs",
	showFrame = 1,
	buffs = false,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {10, -262, 370, -232},
}

Defaults.luaToTBuffs = {
	name = "ToT Buffs",
	showFrame = 1,
	buffs = true,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = { 270, -330,  500, -300},
}
Defaults.luaToTDebuffs = {
	name = "ToT Debuffs",
	showFrame = 1,
	buffs = false,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = { 270, -360,  500, -330},
}

Defaults.luaFocusBuffs = {
	name = "Focus Buffs",
	showFrame = 1,
	buffs = true,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,0,0.5,0},
	offsets = {-100,  50,  100,  70},
}
Defaults.luaFocusDebuffs = {
	name = "Focus Debuffs",
	showFrame = 1,
	buffs = false,
	alignRight = false,
	background = {
		show = false,
		color = "000000",
		transparency = "47"
	},
	border = {
		show = false,
		color = "000000",
		transparency = "67",
		size = 2
	},
	anchors = {0.5,0,0.5,0},
	offsets = {-100,  30,  100,  50},
}

--[[{ name = "Pet Frame 1", anchors = {0.5, 1, 0.5, 1}, offsets =  {-320, -300, -190, -250}, portraitType = 4, showIcons = false},
{ name = "Pet Frame 2", anchors = {0.5, 1, 0.5, 1}, offsets =  {-190, -300, -60, -250}, portraitType = 4, showIcons = false},]]--

if _G["PUIDefaults"] == nil then
	_G["PUIDefaults"] = { }
end
_G["PUIDefaults"]["Buffs"] = Defaults
