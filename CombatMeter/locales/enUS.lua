-----------------------------------------------------------------------------------------------
-- Client Lua Script for CombatMeter
-- Copyright Celess. Portions (C) Vince,Vim via CC 3.0 VortexMeter,
-- and Bradley Smith <brad@brad-smith.co.uk> via 2014 Apache 2.0.  All rights reserved.
-----------------------------------------------------------------------------------------------

local L,Addon = Apollo.GetAddon("CombatMeter"):NewLocale("enUS", true)
if not L then return end

L["CombatMeter Options"] = "CombatMeter " .. Apollo.GetString("CRB_Options")

L["Clear"] = Apollo.GetString("CRB_Clear")
L["Close"] = Apollo.GetString("CRB_Close")
L["Off"] = Apollo.GetString("Options_AddonOff")
L["Options"] = Apollo.GetString("CRB_Options")
L["Start"] = Apollo.GetString("ProgressClick_Start")
L["Stop"] = Apollo.GetString("CRB_Stop")
L["Combat"] = Apollo.GetString("Tutorials_Combat")
--L["Clone"] = "Clone"

L["damagePerSecond"] = "DPS"
L["damageAbsorbed"] = "Damage Absorbned"
L["damageBlocked"] = "Damage Blocked"
L["damageDeflected"] = "Damage Deflected"
L["damageIntercepted"] = "Damage Intercepted"
L["damageModified"] = "Damage Modified"
L["damageTakenPerSecond"] = "DTPS"

L["overkillPerSecond"] = "OKPS"
L["healPerSecond"] = "HPS"
L["healTakenPerSecond"] = "HTPS"
L["overhealPerSecond"] = "OHPS"
L["deaths"] = "Deaths"
L["total"] = "Total"
L["max"] = "Max Hit"
L["average"] = "Average Hit"
L["average crit"] = "Average Crit"
L["min"] = "Min Hit"

L["crit rate"] = "Crit Rate"
L["swings"] = "Swings"
L["hits"] = "Hits"
L["crits"] = "Crits"
L["deflects"] = "Deflects"
L["absorbed"] = "Absorbed"
L["intercepted"] = "Intercepted"

--L["filtered"] = "Filtered"					-- unused
--L["filter"] = "Filter by Targets"				-- unused

--L["Total"] = "Total"
--L["Min / Avg / Max"] = "Min / Avg / Max"
--L["Avg Hit / Crit / Multi-Hit"] = "Avg Hit / Crit / Multi-Hit"
--L["Crit Total (%)"] = "Crit Total (%)"
--L["Crit Rate"] = "Crit Rate"
--L["Multi-Hit Total (%)"] = "Multi-Hit Total (%)"
--L["Multi-Hit Rate"] = "Multi-Hit Rate"
--L["Swings (Per second)"] = "Swings (Per second)"
--L["Hits / Crits / Multi-Hits"] = "Hits / Crits / Multi-Hits"
--L["Deflects (%)"] = "Deflects (%)"
--L["Interrupts Landed"] = "Interrupts Landed"

--L["Total"] = "Total"
--L["%s's Abilities"] = "%s's Abilities"
--L["Combats"] = "Combats"
--L["Targets"] = "Targets"
--L["Unknown"] = "Unknown"
--L["%s: Interactions: %s"] = "%s: Interactions: %s"
--L["%s v%s loaded. /vm for commands"] = "%s v%s loaded. /vm for commands"
--L["Type /vm show to reactivate %s."] = "Type /vm show to reactivate %s."
--L["Available commands:"] = "Available commands:"
--L["Clear data?"] = "Clear data?"
--L["Top 3 Abilities:"] = "Top 3 Abilities:"
--L["Top 3 Interactions:"] = "Top 3 Interactions:"
--L["Middle-Click for interactions"] = "Middle-Click for interactions"

-- Ability stat lables
--   these must align with the ability stat ui mode array exactly
Addon._arLAbilityStatLabels = {
	L["Total"],
	L["Min / Avg / Max"],
	L["Avg Hit / Crit / Multi-Hit"],
	L["Crit Total (%)"],
	L["Crit Rate"],
	L["Multi-Hit Total (%)"],
	L["Multi-Hit Rate"],
	L["Swings (Per second)"],
	L["Hits / Crits / Multi-Hits"],
	L["Deflects (%)"],
	L["Interrupts Landed"],
}

-- Sort modes
--L["Sort Modes"] = "Sort Modes"
Addon._tLSortModes = {
	["damage"] = Apollo.GetString("PublicEventStats_DamageDone"),			--"Damage Done"
	["heal"] = Apollo.GetString("PublicEventStats_HealingDone"),			--"Healing Done"
	["damageTaken"] = Apollo.GetString("PublicEventStats_DamageTaken"),		--"Damage Taken"
	["healTaken"] = Apollo.GetString("PublicEventStats_HealingTaken"),		--"Healing Taken"
	["overheal"] = "Overhealing Done",
	["overkill"] = "Overkill Done",
	["interrupts"] = "Interrupts Landed",
	["deflects"] = "Deflects",
}

-- Tooltip buttons
Addon._tLButtonTooltips = {
	["CloseButton"] = L["Close"],
	["ReportButton"] = L["Report"],
	["ClearButton"] = L["Clear"],
	["CurrentButton"] = "Jump to current fight",
	["ConfigButton"] = L["Options"],
	["PlayersButton"] = "Show enemies or players",
	["StartButton"] = "Start and stop combat",
	["SoloButton"] = Apollo.GetString("CombatLogOptions_OtherPlayers"),		--"Log Other Players",
	["FilterButton"] = "Show combats list",
	["ButtonOpen"] = "Create a new window based on this one",
}

-- Configuration
--L["CombatMeter: Configuration"] = "CombatMeter: Configuration"
--L["Set background transparent"] = "Set background transparent"
--L["Lock frame in position"] = "Lock frame in position"
--L["Always show yourself"] = "Always show yourself"
--L["Show rank number"] = "Show rank number"
--L["Show absolute"] = "Show absolute"
--L["Show percent"] = "Show percent"
--L["Merge abilities by name"] = "Merge abilities by name"
--L["Add Window"] = "Add Window"

