-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoCmbNotice Defaults
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

Defaults.name = "Combat"
Defaults.showFrame = 1

--[[Defaults.border = {
	show = true,
	color = "000000",
	transparency = "67",
	size = 2
}
Defaults.background = {
	show = true,
	color = "000000",
	transparency = "47"
}]]--
--Defaults.color = "00FFFF"
--Defaults.transparency = 100

Defaults.anchors={0.5,1,0.5,1}
Defaults.offsets={-16,-462,16,-430}


if _G["PUIDefaults"] == nil then
	_G["PUIDefaults"] = { }
end
_G["PUIDefaults"]["CmbNotice"] = Defaults
