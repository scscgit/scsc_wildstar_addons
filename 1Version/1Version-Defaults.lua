------------------------------------------------------------------------------------------------
--  1Version ver. OneVersion-1.6.0
--  Authored by Chrono Syz -- Entity-US / Wildstar
--  Build a50c7d6d094803b86bf8936f1fb180ac508c272c
--  Copyright (c) Chronosis. All rights reserved
--
--  https://github.com/chronosis/1Version
------------------------------------------------------------------------------------------------
-- 1Version-Defaults.lua
------------------------------------------------------------------------------------------------

require "Window"
require "Item"
require "GameLib"

local OneVersion = Apollo.GetAddon("1Version")
local Info = Apollo.GetAddonInfo("1Version")


local tBaseAddonInfo = {
  type = "",
  label = "",
  mine = {
    major = 0,
    minor = 0,
    patch = 0,
    suffix = 0
  },
  reported = {
    major = 0,
    minor = 0,
    patch = 0,
    suffix = 0
  },
  upgrade = false
}

function OneVersion:LoadDefaults()
  self:RefreshUI()
end

function OneVersion:GetBaseAddonInfo()
  return deepcopy(tBaseAddonInfo)
end
