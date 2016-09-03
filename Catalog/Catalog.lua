local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("Catalog", true)

Catalog.Version = {
  ["Major"] = 1,
  ["Minor"] = 1,
  ["Build"] = 4
}

Catalog.Defaults = {
  ["Account"] = {
    ["Locked"] = false,
    ["Position"] = {
      ["X"] = 100,
      ["Y"] = 100
    },
    ["Scale"] = 1.0
  },
  ["Character"] = {
    ["ItemTypes"] = {},
    ["ShowHidden"] = true,
    ["Wishlist"] = {}
  }
}

Catalog.Locales = {
  [1] = "enUS",
  [2] = "deDE",
  [3] = "frFR"
}

Catalog.Options = Catalog.Defaults

local Database = Catalog:NewModule("Database")
Database.tEntries = {}

function Catalog:OnInitialize()
  Apollo.RegisterSlashCommand("catalog", "Toggle", self:GetModule("Browser"))
  Apollo.RegisterSlashCommand("loot", "Toggle", self:GetModule("Browser"))
  Apollo.RegisterSlashCommand("catalogreset", "Reset", self)
end

function Catalog:OnEnable()
  Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
end

function Catalog:OnInterfaceMenuListHasLoaded()
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Catalog", {
    "Catalog_ToggleBrowser",
    "",
    "IconSprites:Icon_Windows32_UI_CRB_InterfaceMenu_Lore"
  })
end

function Catalog:OnSave(type)
  local Utility = self:GetModule("Utility")
  if type == GameLib.CodeEnumAddonSaveLevel.Character then
    return Utility:TableCopyRecursive(self.Options.Character)
  elseif type == GameLib.CodeEnumAddonSaveLevel.Account then
    return Utility:TableCopyRecursive(self.Options.Account)
  end
  return nil
end

function Catalog:OnRestore(type, table)
  local Utility = self:GetModule("Utility")
  if type == GameLib.CodeEnumAddonSaveLevel.Character then
    for k, v in pairs(Catalog.Defaults.Character) do
      if table[k] == nil then
        table[k] = v
      end
    end
    self.Options.Character = Utility:TableCopyRecursive(table, self.Options.Character)
  elseif type == GameLib.CodeEnumAddonSaveLevel.Account then
    for k, v in pairs(Catalog.Defaults.Account) do
      if table[k] == nil then
        table[k] = v
      end
    end
    self.Options.Account = Utility:TableCopyRecursive(table, self.Options.Account)
  end
end

function Catalog:OnConfigure()
  local Browser = self:GetModule("Browser")
  Browser:Toggle()
end

function Catalog:GetLocale()
  local localeId = Apollo.GetConsoleVariable("locale.languageId") or 1
  return self.Locales[localeId]
end

function Catalog:Reset()
  local Browser = self:GetModule("Browser")
  self.Options.Account.Position = self.Defaults.Account.Position
  self.Options.Account.Scale = self.Defaults.Account.Scale
  Browser:Close()
  Browser:Open()
end
