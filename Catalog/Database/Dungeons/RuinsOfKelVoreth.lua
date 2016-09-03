local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Database = Catalog:GetModule("Database")

-- [Dungeon] Ruins of Kel Voreth
Database.tEntries["RuinsOfKelVoreth"] = {
  ["name"] = {
    ["deDE"] = "Ruinen von Kel'Voreth",
    ["frFR"] = "Ruines de Kel Voreth",
    ["enUS"] = "Ruins of Kel Voreth",
  },
  ["type"] = "dungeon",
  ["bosses"] = {
    {
      ["name"] = {
        ["deDE"] = "Grond der Leichenmacher",
        ["frFR"] = "Grond le Boucher",
        ["enUS"] = "Grond the Corpsemaker",
      },
      ["veteran"] = true,
      ["drops"] = {
        34494,
        34497,
        34498,
        34499,
        34500,
        34501,
        34506,
        34507,
        38112,
        38113,
        38114,
        38118,
        38120,
        38131,
        42086,
        42839,
        42845,
        42847,
      },
    },
    {
      ["name"] = {
        ["deDE"] = "Dämmerhexe Gurka",
        ["frFR"] = "Sorcîère ténébreuse Gurka",
        ["enUS"] = "Darkwitch Gurka",
      },
      ["veteran"] = true,
      ["drops"] = {
        34496,
        34504,
        34509,
        34515,
        34530,
        34533,
        38126,
        42832,
        42843,
        42871,
      },
    },
    {
      ["name"] = {
        ["deDE"] = "Sklavenmeister Drokk",
        ["frFR"] = "Maître d'esclaves Drokk",
        ["enUS"] = "Slavemaster Drokk",
      },
      ["veteran"] = true,
      ["drops"] = {
        34508,
        34512,
        34513,
        34516,
        34517,
        34519,
        34520,
        34521,
        38119,
        38122,
        38123,
        38129,
        38138,
        42074,
        42535,
        42841,
        42842,
        42848,
        42851,
      },
    },
    {
      ["name"] = {
        ["deDE"] = "Schmiedemeister Trogun",
        ["frFR"] = "Maître-forgeron Trogun",
        ["enUS"] = "Forgemaster Trogun",
      },
      ["veteran"] = true,
      ["drops"] = {
        34518,
        34522,
        34523,
        34524,
        34525,
        34526,
        34527,
        34528,
        34529,
        34531,
        34532,
        34535,
        34536,
        34537,
        34539,
        34540,
        34541,
        34542,
        34543,
        34544,
        34545,
        34546,
        34548,
        38082,
        38091,
        38121,
        38125,
        38132,
        38134,
        38136,
        38139,
        38140,
        42064,
        42096,
        42830,
        42834,
        42835,
        42840,
        42844,
        42849,
        42852,
        42853,
        42856,
        42857,
        42858,
        42860,
        42861,
        42862,
        42863,
        42864,
        42865,
        42866,
        42867,
        42869,
        42870,
        42872,
        42873,
      },
    },
  },
}