local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Database = Catalog:GetModule("Database")

-- [Raid] The Datascape
Database.tEntries["TheDatascape"] = {
  ["name"] = {
    ["deDE"] = "Datenzone",
    ["frFR"] = "L'Infosphère",
    ["enUS"] = "The Datascape",
  },
  ["type"] = "raid",
  ["bosses"] = {
  },
}
