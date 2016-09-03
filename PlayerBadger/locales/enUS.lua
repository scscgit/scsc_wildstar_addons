-----------------------------------------------------------------------------------------------
-- Client Lua Script for PlayerBadger
-- Copyright Celess. All rights reserved
-----------------------------------------------------------------------------------------------

local L = Apollo.GetAddon("PlayerBadger"):NewLocale("enUS", true)
if not L then return end

L["PlayerBadger Options"] = "PlayerBadger " .. Apollo.GetString("CRB_Options")


--L["Stop Testing"]
--L["Test Target"]