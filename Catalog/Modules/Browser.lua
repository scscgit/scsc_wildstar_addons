local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Browser = Catalog:NewModule("Browser")

Browser.ItemColor = {
  [Item.CodeEnumItemQuality.Inferior] = ApolloColor.new("ItemQuality_Inferior"),
  [Item.CodeEnumItemQuality.Average] = ApolloColor.new("ItemQuality_Average"),
  [Item.CodeEnumItemQuality.Good] = ApolloColor.new("ItemQuality_Good"),
  [Item.CodeEnumItemQuality.Excellent] = ApolloColor.new("ItemQuality_Excellent"),
  [Item.CodeEnumItemQuality.Superb] = ApolloColor.new("ItemQuality_Superb"),
  [Item.CodeEnumItemQuality.Legendary] = ApolloColor.new("ItemQuality_Legendary"),
  [Item.CodeEnumItemQuality.Artifact] = ApolloColor.new("ItemQuality_Artifact")
}

function Browser:OnInitialize()
  self.Xml = XmlDoc.CreateFromFile("Forms/Browser.xml")
  if self.Xml == nil then
    Apollo.AddAddonErrorText(Catalog, "Could not load the Catalog browser")
    return
  end
  self.Xml:RegisterCallback("OnDocumentReady", self)
  Apollo.RegisterSlashCommand("catalog", "Open", self.Browser)
  Apollo.RegisterSlashCommand("loot", "Open", self.Browser)
end

function Browser:OnEnable()
  Apollo.RegisterEventHandler("Catalog_ToggleBrowser", "Toggle", self)
end

function Browser:OnDocumentReady()
  self.Window = Apollo.LoadForm(self.Xml, "CatalogBrowser", nil, self)
  self.Window:FindChild("AdventureButton"):SetData("adventure")
  self.Window:FindChild("DungeonButton"):SetData("dungeon")
  self.Window:FindChild("RaidButton"):SetData("raid")
  self:OnCategoryCheck(self, self.Window:FindChild("AdventureButton"))
end

function Browser:Open()
  if self.Window and self.Window:IsValid() then
    local left = Catalog.Options.Account.Position.X
    local top = Catalog.Options.Account.Position.Y
    local form = Apollo.LoadForm(self.Xml, "CatalogBrowser", nil, self)
    local _, _, right, bottom = form:GetAnchorOffsets()
    form:Destroy()
    self.Window:SetAnchorOffsets(left, top, left + right, top + bottom)
    self.Window:SetScale(Catalog.Options.Account.Scale)
    if Catalog.Options.Account.Locked then
      self.Window:RemoveStyle("Moveable")
    end
    self.Window:FindChild("ShowHiddenButton"):SetCheck(Catalog.Options.Character.ShowHidden)
    self:Localize()
    self.Window:Show(true)
  end
end

function Browser:Close()
  local Settings = Catalog:GetModule("Settings")
  local Wishlist = Catalog:GetModule("Wishlist")
  if self.Window and self.Window:IsValid() then
    Settings:Close()
    Wishlist:Close()
    self.Window:Show(false)
  end
end

function Browser:Toggle()
  if self.Window and self.Window:IsValid() then
    if self.Window:IsShown() then
      self:Close()
    else
      self:Open()
    end
  end
end

function Browser:Localize()
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("Catalog", true)
  GeminiLocale:TranslateWindow(L, self.Window)
  self:BuildSubcategoryList()
  self:BuildBossList(self.Window:FindChild("SubcategoryButton"):GetData())
end

function Browser:BuildSubcategoryList()
  local Database = Catalog:GetModule("Database")
  local Utility = Catalog:GetModule("Utility")
  local locale = Catalog:GetLocale()
  local list = self.Window:FindChild("SubcategoryList")
  list:DestroyChildren()
  local entries = {}
  for _, entry in pairs(Database.tEntries) do
    if entry.type == self.Window:FindChild("CategoryButton"):GetData() then
      local tbl = Utility:TableCopyRecursive(entry)
      tbl.name = entry.name[locale]
      table.insert(entries, tbl)
    end
  end
  for name, entry in Utility:TableSortPairs(entries, "name") do
    local form = Apollo.LoadForm(self.Xml, "Subcategory", list, self)
    form:SetText(name)
    form:SetData(entry)
  end
  list:ArrangeChildrenVert()
  self:SizeToFit(list, 3)
  self:OnSubcategoryCheck(self, list:GetChildren()[1])
end

function Browser:BuildBossList(subcategory)
  local locale = Catalog:GetLocale()
  local list = self.Window:FindChild("BossList")
  list:DestroyChildren()
  if subcategory == nil then
    return
  end
  for _, boss in ipairs(subcategory.bosses) do
    local form = Apollo.LoadForm(self.Xml, "Boss", list, self)
    form:SetData(boss)
    form:FindChild("BossText"):SetText(boss.name[locale])
  end
  list:ArrangeChildrenVert()
  local wndButton = list:GetChildren()[1]:FindChild("BossButton")
  wndButton:SetCheck(true)
  self:OnBossSelect(self, wndButton)
end

function Browser:BuildItemList(boss)
  local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Catalog", true)
  local list = self.Window:FindChild("ItemList")
  list:DestroyChildren()
  if boss == nil then
    return
  end
  list:SetData(boss)
  local veteran = self.Window:FindChild("ModeButton"):IsChecked()
  local items = {}
  for i = Item.CodeEnumItemQuality.Legendary, Item.CodeEnumItemQuality.Good, -1 do
    for _, id in pairs(boss.drops) do
      local item = Item.GetDataFromId(id)
      if item ~= nil and item:GetItemQuality() == i then
        if boss.veteran and veteran and item:GetRequiredLevel() < 50 then
          -- Ignore it. Not a veteran drop.
        elseif boss.veteran and not veteran and item:GetRequiredLevel() >= 50 then
          -- Ignore it. Not a normal drop.
        else
          if items[item:GetItemType()] == nil then
            items[item:GetItemType()] = {}
          end
          table.insert(items[item:GetItemType()], item)
        end
      end
    end
  end
  for type, tbl in pairs(items) do
    local formType = Apollo.LoadForm(self.Xml, "ItemType", list, self)
    formType:SetData({})
    local rows = math.ceil(#tbl / 2)
    for row = 1, rows do
      local form = Apollo.LoadForm(self.Xml, "ItemRow", list, self)
      for i = 1, 2 do
        local num = ((row - 1) * 2) + i
        if num <= #tbl then
          local item = tbl[num]
          local info = item:GetDetailedInfo()
          formType:FindChild("ItemTypeButton"):SetText(item:GetItemTypeName())
          formType:FindChild("ItemTypeButton"):SetData(item:GetItemType())
          formType:FindChild("StatusIcon"):SetData(true)
          form:SetName("CatalogItems_"..item:GetItemType().."_"..row)
          form:FindChild("Item"..i):SetData(item)
          form:FindChild("Item"..i):FindChild("ItemIcon"):SetSprite(item:GetIcon())
          form:FindChild("Item"..i):FindChild("ItemText"):SetText(item:GetName())
          form:FindChild("Item"..i):FindChild("ItemText"):SetTextColor(self.ItemColor[item:GetItemQuality()])
          local found = false
          for _, i in pairs(Catalog.Options.Character.Wishlist) do
            if i["Id"] == info.tPrimary.nId then
              found = true
            end
          end
          form:FindChild("Item"..i):FindChild("WishlistButton"):SetTooltip(L["addWishlist"])
          form:FindChild("Item"..i):FindChild("WishlistButton"):SetCheck(found)
          form:FindChild("Item"..i):Show(true)
        else
          form:FindChild("Item"..i):Show(false)
        end
      end
      local forms = formType:GetData()
      table.insert(forms, form:GetName())
      formType:SetData(forms)
      local status = Catalog.Options.Character.ItemTypes[tostring(formType:FindChild("ItemTypeButton"):GetData())]
      if status ~= nil then
        form:Show(status)
        formType:FindChild("StatusIcon"):SetData(status)
        if status then
          formType:FindChild("StatusIcon"):SetSprite("achievements:sprAchievements_Icon_Complete")
        else
          formType:FindChild("StatusIcon"):SetSprite("ClientSprites:LootCloseBox_Holo")
          formType:Show(self.Window:FindChild("ShowHiddenButton"):IsChecked())
        end
      end
    end
  end
  list:ArrangeChildrenVert()
end

function Browser:SizeToFit(list, offset)
  offset = offset or 0
  if #list:GetChildren() > 0 then
    local height = 0
    for _, child in pairs(list:GetChildren()) do
      local _, top, _, bottom = child:GetAnchorOffsets()
      height = height + (bottom - top)
    end
    local left, top, right = list:GetAnchorOffsets()
    list:SetAnchorOffsets(left, top, right, top + height + offset)
  end
end

function Browser:Expand(list, sublist)
  local left, top, right, bottom = list:GetAnchorOffsets()
  local _, _, _, height = sublist:GetAnchorOffsets()
  list:SetAnchorOffsets(left, top, right, bottom + height)
end

function Browser:Collapse(list, sublist)
  local left, top, right, bottom = list:GetAnchorOffsets()
  local _, _, _, height = sublist:GetAnchorOffsets()
  list:SetAnchorOffsets(left, top, right, bottom - height)
end

function Browser:OnToggleItemType(handler, control)
  local status = not control:GetParent():FindChild("StatusIcon"):GetData()
  local type = tostring(control:GetParent():FindChild("ItemTypeButton"):GetData())
  control:GetParent():FindChild("StatusIcon"):SetData(status)
  Catalog.Options.Character.ItemTypes[type] = status
  for _, name in pairs(control:GetParent():GetData()) do
    self.Window:FindChild(name):Show(status)
  end
  self.Window:FindChild("ItemList"):ArrangeChildrenVert()
  if status then
    control:GetParent():FindChild("StatusIcon"):SetSprite("achievements:sprAchievements_Icon_Complete")
  else
    control:GetParent():FindChild("StatusIcon"):SetSprite("ClientSprites:LootCloseBox_Holo")
  end
end

function Browser:OnWishlistCheck(handler, control)
  local Wishlist = Catalog:GetModule("Wishlist")
  Wishlist:Open()
end

function Browser:OnWishlistUncheck(handler, control)
  local Wishlist = Catalog:GetModule("Wishlist")
  Wishlist:Close()
end

function Browser:OnWishlistAdd(handler, control)
  local Wishlist = Catalog:GetModule("Wishlist")
  local item = control:GetParent():GetData()
  local info = item:GetDetailedInfo()
  table.insert(Catalog.Options.Character.Wishlist, {
    ["Id"] = info.tPrimary.nId,
    ["Alert"] = true
  })
  if Catalog.Wishlist.Window:IsShown() then
    Catalog.Wishlist:BuildItemList()
  end
end

function Browser:OnWishlistRemove(handler, control)
  local Wishlist = Catalog:GetModule("Wishlist")
  local item = control:GetParent():GetData()
  local info = item:GetDetailedInfo()
  for k, i in pairs(Catalog.Options.Character.Wishlist) do
    if i["Id"] == info.tPrimary.nId then
      table.remove(Catalog.Options.Character.Wishlist, k)
    end
  end
  if Wishlist.Window:IsShown() then
    Wishlist:BuildItemList()
  end
end

function Browser:OnCategoryListOpen(handler, control)
  self.Window:FindChild("CategoryList"):Show(true)
end

function Browser:OnCategoryListClose(handler, control)
  self.Window:FindChild("CategoryList"):Show(false)
end

function Browser:OnCategoryCheck(handler, control)
  self.Window:FindChild("CategoryButton"):SetText(control:GetText())
  self.Window:FindChild("CategoryButton"):SetData(control:GetData())
  self.Window:FindChild("CategoryButton"):SetCheck(false)
  self.Window:FindChild("SubcategoryButton"):SetText("")
  self.Window:FindChild("SubcategoryButton"):SetData(nil)
  self.Window:FindChild("CategoryList"):Show(false)
  self.Window:FindChild("ModeText"):Show(false)
  self.Window:FindChild("ModeButton"):Show(false)
  self:BuildSubcategoryList()
end

function Browser:OnSubcategoryListOpen(handler, control)
  self.Window:FindChild("SubcategoryList"):Show(true)
end

function Browser:OnSubcategoryListClose(handler, control)
  self.Window:FindChild("SubcategoryList"):Show(false)
end

function Browser:OnSubcategoryCheck(handler, control)
  self.Window:FindChild("SubcategoryButton"):SetText(control:GetText())
  self.Window:FindChild("SubcategoryButton"):SetData(control:GetData())
  self.Window:FindChild("SubcategoryButton"):SetCheck(false)
  self.Window:FindChild("SubcategoryList"):Show(false)
  self.Window:FindChild("ModeText"):Show(false)
  self.Window:FindChild("ModeButton"):Show(false)
  self:BuildBossList(control:GetData())
end

function Browser:OnModeChange(handler, control)
  self:BuildItemList(self.Window:FindChild("ItemList"):GetData())
end

function Browser:OnBossSelect(handler, control)
  local boss = control:GetParent():GetData()
  self:BuildItemList(boss)
  self.Window:FindChild("ModeText"):Show(boss.veteran)
  self.Window:FindChild("ModeButton"):Show(boss.veteran)
end

function Browser:OnMouseButtonDown(handler, control, button)
  if button ~= GameLib.CodeEnumInputMouse.Right then
    return
  end
  local item = control:GetParent():GetData()
  if Apollo.IsControlKeyDown() then
    if item:GetHousingDecorInfoId() ~= nil and item:GetHousingDecorInfoId() ~= 0 then
      Event_FireGenericEvent("DecorPreviewOpen", item:GetHousingDecorInfoId())
    else
      Event_FireGenericEvent("ShowItemInDressingRoom", item)
    end
  elseif Apollo.IsShiftKeyDown() then
    Event_FireGenericEvent("ItemLink", item)
  end
end

function Browser:OnToggleHidden(handler, control)
  self:BuildItemList(self.Window:FindChild("ItemList"):GetData())
  Catalog.Options.Character.ShowHidden = control:IsChecked()
end

function Browser:OnToggleSettings(handler, control)
  local Settings = Catalog:GetModule("Settings")
  if control:IsChecked() then
    Settings:Open()
  else
    Settings:Close()
  end
end

function Browser:OnWindowMove(handler, control)
  local Settings = Catalog:GetModule("Settings")
  local left, top = self.Window:GetAnchorOffsets()
  Catalog.Options.Account.Position.X = left
  Catalog.Options.Account.Position.Y = top
  Settings:Position()
end

function Browser:OnGenerateTooltip(handler, control)
  local item = control:GetParent():GetData()
  local equipped = item:GetEquippedItemForItemType()
  Tooltip.GetItemTooltipForm(self, control, item, {
    bPrimary = true,
    bSelling = false,
    itemCompare = equipped
  })
end
