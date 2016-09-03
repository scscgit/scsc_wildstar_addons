-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoMountHP Defaults
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

Defaults.name = "Mount Health"
Defaults.showFrame = 1
Defaults.border = {
	show = true,
	color = "000000",
	transparency = "67",
	size = 2
}
Defaults.background = {
	show = true,
	color = "000000",
	transparency = "47"
}
Defaults.texture = "Aluminum"
Defaults.color = "00FFFF"
Defaults.transparency = 100
Defaults.barGrowth = 1
Defaults.textLeft = {
	type = 1,
	font = {
		base = "CRB_Interface",
		size = "10",
		props = ""
	}
}
Defaults.textMid = {
	type = 0,
	font = {
			base = "CRB_Interface",
			size = "10",
			props = ""
		}
}
Defaults.textRight = {
	type = 2,
	font = {
		base = "CRB_Interface",
		size = "10",
		props = ""
	}
}
Defaults.anchors={0.5,0.5,0.5,0.5}
Defaults.offsets={-100,-12,100,12}


if _G["PUIDefaults"] == nil then
	_G["PUIDefaults"] = { }
end
_G["PUIDefaults"]["MountHP"] = Defaults
