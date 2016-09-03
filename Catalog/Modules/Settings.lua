local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Settings = Catalog:NewModule("Settings")

function Settings:OnInitialize()
  self.Xml = XmlDoc.CreateFromFile("Forms/Settings.xml")
  if self.Xml == nil then
    Apollo.AddAddonErrorText(Catalog, "Could not load the Catalog settings window")
    return
  end
  self.Xml:RegisterCallback("OnDocumentReady", self)
end

function Settings:OnDocumentReady()
  self.Window = Apollo.LoadForm(self.Xml, "CatalogSettings", nil, self)
  local version = Catalog.Version.Major.."."..Catalog.Version.Minor.."."..Catalog.Version.Build
  self.Window:FindChild("VersionText"):SetText(version)
end

function Settings:Open()
  local Wishlist = Catalog:GetModule("Wishlist")
  if self.Window and self.Window:IsValid() then
    Wishlist:Close()
    self:Position()
    self:Localize()
    self:ApplyCurrent()
    self.Window:Show(true)
  end
end

function Settings:Close()
  local Browser = Catalog:GetModule("Browser")
  if self.Window and self.Window:IsValid() then
    Browser.Window:FindChild("SettingsButton"):SetCheck(false)
    self.Window:Show(false)
  end
end

function Settings:Localize()
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("Catalog", true)
  GeminiLocale:TranslateWindow(L, self.Window)
end

function Settings:Position()
  local Browser = Catalog:GetModule("Browser")
  local _, top, right = Browser.Window:GetAnchorOffsets()
  local offset = (right - 15) * (1 - Browser.Window:GetScale())
  local form = Apollo.LoadForm(self.Xml, "CatalogSettings", nil, self)
  local _, _, width, height = form:GetAnchorOffsets()
  form:Destroy()
  self.Window:SetAnchorOffsets(right - 15 - offset, top + 5, right - 15 -offset + width, top + 5 + height)
  self.Window:SetScale(Browser.Window:GetScale())
end

function Settings:ApplyCurrent()
  self.Window:FindChild("ScaleValueText"):SetText(tostring(Catalog.Options.Account.Scale))
  self.Window:FindChild("ScaleSlider"):SetValue(Catalog.Options.Account.Scale)
  self.Window:FindChild("LockedButton"):SetCheck(Catalog.Options.Account.Locked)
end

function Settings:OnScaleChanged(handler, control, scale)
  local Browser = Catalog:GetModule("Browser")
  scale = math.floor(scale * math.pow(10, 1) + 0.5) / math.pow(10, 1)
  self.Window:FindChild("ScaleValueText"):SetText(tostring(scale))
  self.Window:SetScale(scale)
  Browser.Window:SetScale(scale)
  Catalog.Options.Account.Scale = scale
  self:Position()
end

function Settings:OnToggleLocked(handler, control)
  local Browser = Catalog:GetModule("Browser")
  Catalog.Options.Account.Locked = control:IsChecked()
  if not Catalog.Options.Account.Locked then
    Browser.Window:AddStyle("Moveable")
  else
    Browser.Window:RemoveStyle("Moveable")
  end
end
