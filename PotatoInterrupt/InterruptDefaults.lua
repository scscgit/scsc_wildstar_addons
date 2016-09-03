-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoFramesV2 Defaults
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

--[[
	{ name = "Player Frame", anchors = {0.5, 1, 0.5, 1}, offsets = {-370, -202,  -10, -128}, portraitType = 1, showIcons = true},
	{ name = "Target Frame", anchors = {0.5, 1, 0.5, 1}, offsets = {  10, -202,  370, -128}, portraitType = 1, showIcons = true},
	{ name = "ToT Frame", anchors = {0.5, 1, 0.5, 1}, offsets =    { 270, -300,  500, -240}, portraitType = 1, showIcons = true},
	{ name = "Focus Frame", anchors = {0.5, 0, 0.5, 0}, offsets =  {-100,  70,  100,  130}, portraitType = 1, showIcons = true},
	{ name = "Pet Frame 1", anchors = {0.5, 1, 0.5, 1}, offsets =  {-320, -300, -190, -250}, portraitType = 4, showIcons = false},
	{ name = "Pet Frame 2", anchors = {0.5, 1, 0.5, 1}, offsets =  {-190, -300, -60, -250}, portraitType = 4, showIcons = false},
]]--

Defaults.luaPlayerIA = {
	name = "Player IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {-430, -194, -370, -134},
}
Defaults.luaTargetIA = {
	name = "Target IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {370, -194, 430, -134},
}
Defaults.luaToTIA = {
	name = "ToT IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {500, -298, 560, -238},
}
Defaults.luaFocusIA = {
	name = "Focus IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,0,0.5,0},
	offsets = {-85,  75,  -45,  115},
}
--[[Defaults.luaPet1IA = {
	name = "Player IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {-752, -822,  -697, -762},
}
Defaults.luaPet2IA = {
	name = "Player IA",
	showFrame = 1,
	background = {
		show = false,
		color = "BEEFED",
		transparency = "FF"
	},
	border = {
		show = false,
		color = "BEEFEE",
		transparency = "FF",
		size = 2
	},
	anchors = {0.5,1,0.5,1},
	offsets = {-752, -822,  -697, -762},
}]]--

if _G["PUIDefaults"] == nil then
	_G["PUIDefaults"] = { }
end
_G["PUIDefaults"]["Interrupt"] = Defaults
