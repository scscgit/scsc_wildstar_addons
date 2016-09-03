local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Wishlist = Catalog:NewModule("Wishlist")

Wishlist.RecentAlerts = {}
Wishlist.AlertForm = nil
Wishlist.AlertTimer = nil

function Wishlist:OnInitialize()
  self.Xml = XmlDoc.CreateFromFile("Forms/Wishlist.xml")
  if self.Xml == nil then
    Apollo.AddAddonErrorText(Catalog, "Could not load the Catalog wishlist window")
    return
  end
  self.Xml:RegisterCallback("OnDocumentReady", self)
end

function Wishlist:OnEnable()
  Apollo.RegisterEventHandler("LootRollUpdate", "OnGroupLoot", self)
  Apollo.RegisterEventHandler("LootedItem", "OnItemLooted", self)
end

function Wishlist:OnDocumentReady()
  self.Window = Apollo.LoadForm(self.Xml, "CatalogWishlist", nil, self)
end

function Wishlist:Open()
  local Settings = Catalog:GetModule("Settings")
  if self.Window and self.Window:IsValid() then
    Settings:Close()
    self:Position()
    self:Localize()
    self:BuildItemList()
    self.Window:Show(true)
  end
end

function Wishlist:Close()
  local Browser = Catalog:GetModule("Browser")
  if self.Window and self.Window:IsValid() then
    Browser.Window:FindChild("OpenWishlistButton"):SetCheck(false)
    self.Window:Show(false)
  end
end

function Wishlist:Localize()
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("Catalog", true)
  GeminiLocale:TranslateWindow(L, self.Window)
end

function Wishlist:Position()
  local Browser = Catalog:GetModule("Browser")
  local _, top, right = Browser.Window:GetAnchorOffsets()
  local offset = (right - 15) * (1 - Browser.Window:GetScale())
  local form = Apollo.LoadForm(self.Xml, "CatalogWishlist", nil, self)
  local _, _, width, height = form:GetAnchorOffsets()
  form:Destroy()
  self.Window:SetAnchorOffsets(right - 15 - offset, top, right - 15 - offset + width, top + height)
  self.Window:SetScale(Browser.Window:GetScale())
end

function Wishlist:BuildItemList()
  local Browser = Catalog:GetModule("Browser")
  local Utility = Catalog:GetModule("Utility")
  local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Catalog", true)
  local list = self.Window:FindChild("ItemList")
  list:DestroyChildren()
  for _, i in pairs(Catalog.Options.Character.Wishlist) do
    local item = Item.GetDataFromId(i["Id"])
    local form = Apollo.LoadForm(self.Xml, "Item", list, self)
    form:SetData(item)
    form:FindChild("ItemIcon"):SetSprite(item:GetIcon())
    form:FindChild("ItemText"):SetText(item:GetName())
    form:FindChild("ItemText"):SetTextColor(Browser.ItemColor[item:GetItemQuality()])
    local tooltip = ""
    for _, drop in pairs(Utility:FindDropLocations(i["Id"])) do
      tooltip = tooltip..drop["Boss"].."\n"..drop["Location"].."\n\n"
    end
    form:FindChild("InfoButton"):SetTooltip(tooltip)
    form:FindChild("AlertButton"):SetTooltip(L["alertWishlist"])
    form:FindChild("AlertButton"):SetCheck(i["Alert"])
  end
  list:ArrangeChildrenVert()
end

function Wishlist:OnToggleAlert(handler, control)
  local item = control:GetParent():GetData()
  local info = item:GetDetailedInfo()
  for k, v in pairs(Catalog.Options.Character.Wishlist) do
    if v["Id"] == info.tPrimary.nId then
      Catalog.Options.Character.Wishlist[k]["Alert"] = control:IsChecked()
    end
  end
end

function Wishlist:OnWishlistRemove(handler, control)
  local Browser = Catalog:GetModule("Browser")
  local item = control:GetParent():GetData()
  local info = item:GetDetailedInfo()
  for k, i in ipairs(Catalog.Options.Character.Wishlist) do
    if i["Id"] == info.tPrimary.nId then
      table.remove(Catalog.Options.Character.Wishlist, k)
    end
  end
  self:BuildItemList()
  Browser:BuildItemList(Browser.Window:FindChild("ItemList"):GetData())
end

function Wishlist:OnAlertClose()
  self.AlertForm:Close()
  self.AlertForm:Destroy()
  self.AlertForm = nil
end

function Wishlist:OnGroupLoot()
  for _, roll in pairs(GameLib.GetLootRolls()) do
    self:OnItemLooted(roll.itemDrop, 1)
  end
end

function Wishlist:OnItemLooted(item, count)
  local Browser = Catalog:GetModule("Browser")
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("Catalog", true)
  if item ~= nil and count > 0 and self.AlertForm == nil then
    local info = item:GetDetailedInfo()
    local found = nil
    for _, i in pairs(Catalog.Options.Character.Wishlist) do
      if i["Id"] == info.tPrimary.nId then
        found = i
      end
    end
    if found ~= nil and found["Alert"] then
      local last = self.RecentAlerts[tostring(found["Id"])]
      if last == nil or (last ~= nil and (last + 300) < os.time()) then
        self.AlertForm = Apollo.LoadForm(self.Xml, "ItemDropAlert", nil, self)
        self.AlertForm:FindChild("ItemIcon"):SetSprite(item:GetIcon())
        self.AlertForm:FindChild("ItemName"):SetText(item:GetName())
        self.AlertForm:FindChild("ItemName"):SetTextColor(Browser.ItemColor[item:GetItemQuality()])
        GeminiLocale:TranslateWindow(L, self.AlertForm)
        self.AlertTimer = ApolloTimer.Create(5.0, false, "OnAlertClose", self)
        self.RecentAlerts[tostring(found["Id"])] = os.time()
        Sound.Play(Sound.PlayUIAlertPopUpMessageReceived)
      end
    end
  end
end

function Wishlist:OnGenerateTooltip(handler, control)
  local Browser = Catalog:GetModule("Browser")
  Browser:OnGenerateTooltip(handler, control)
end
