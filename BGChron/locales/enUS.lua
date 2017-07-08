-----------------------------------------------------------------------------------------------
-- Client Lua Script for BGChron
-- Copyright Celess. All rights reserved
-----------------------------------------------------------------------------------------------

local L,Addon = Apollo.GetAddon("BGChron"):NewLocale("enUS", true)
if not L then return end

-- Options

L["BGChron Options"] = "BGChron " .. Apollo.GetString("CRB_Options")

------------------------------
--- FIXED START --------------

-- these dont need translation
-- either are functional or need to follow Carbine translations

-- Filter drop-downs

Addon._tGameSet2Name = {
	["4.1"]  = Apollo.GetString("MatchMaker_Arenas"),
	["5.1"]	 = Apollo.GetString("MatchMaker_RatedArenas"),
	["6.1"]	 = Apollo.GetString("MatchMaker_Battlegrounds"),
	["7.1"]  = Apollo.GetString("CRB_Battlegrounds"),
	["8.1"]	 = Apollo.GetString("MatchMaker_Warplots"),
}

--- FIXED END ----------------
------------------------------
