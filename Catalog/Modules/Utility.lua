local Catalog = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("Catalog")
local Utility = Catalog:NewModule("Utility")

function Utility:Capitalize(str)
  return string.gsub(tostring(str), "^%l", string.upper)
end

function Utility:TableSortPairs(tbl, key)
  local keys = {}
  for _, v in pairs(tbl) do
    if v[key] ~= nil then
      table.insert(keys, v[key])
    end
  end
  table.sort(keys)
  local i = 0
  local iterator = function()
    i = i + 1
    if keys[i] ~= nil then
      for _, v in pairs(tbl) do
        if v[key] == keys[i] then
          return keys[i], v
        end
      end
      return nil
    else
      return nil
    end
  end
  return iterator
end

function Utility:TableCopyRecursive(source, destination)
  destination = destination or {}
  for k, v in pairs(source) do
    if type(k) ~= "table" then
      if type(v) ~= "table" then
        destination[k] = v
      else
        destination[k] = self:TableCopyRecursive(v, destination[k])
      end
    end
  end
  return destination
end

function Utility:FindDropLocations(id)
  local Database = Catalog:GetModule("Database")
  local locale = Catalog:GetLocale()
  local drops = {}
  for _, location in pairs(Database.tEntries) do
    for _, boss in pairs(location.bosses) do
      local found = false
      for _, item in pairs(boss.drops) do
        if tostring(item) == tostring(id) then
          found = true
        end
      end
      if found then
        table.insert(drops, {
          ["Location"] = location.name[locale],
          ["Boss"] = boss.name[locale]
        })
      end
    end
  end
  return drops
end
