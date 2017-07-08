local MAJOR, MINOR = "Lib:LibGear-1.0", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local lg = APkg and APkg.tPackage or {}

-----------------------------------------------------------------------------------------------
-- print debug
function lg._debug(...)
	local arg={...} 
    if arg[1] == true and (arg[2] == arg[3] or arg[2] == nil) then
		for _=5, #arg do
			Print(arg[4]..": "..arg[_])
		end
	end
end

-----------------------------------------------------------------------------------------------
-- find is a addon is running
function lg._isaddonup(sAddOn)
  	local addon = Apollo.GetAddonInfo(sAddOn)
	if addon and addon.bRunning == 1 then return true end
	return nil
end

-----------------------------------------------------------------------------------------------
--- init plugin communication
function lg.initcomm(tData)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_READY", tData)
end

-----------------------------------------------------------------------------------------------
-- load plugin icon and return sprite icon name (25x25 pixel)
function lg._loadicon(sPlugIn)
  	local sWildstarDir = string.match(Apollo.GetAssetFolder(), "(.-)[\\/][Aa][Dd][Dd][Oo][Nn][Ss]")
	Apollo.LoadSprites(sWildstarDir.."\\Addons\\" .. sPlugIn .. "\\resource\\Sprite.xml") 
	return sPlugIn 
end

-----------------------------------------------------------------------------------------------
-- return items array from inventory/bank/equipped 
	local t_source = 
	{
		[1] = function(u) return u:GetInventoryItems() end,
		[2] = function(u) return u:GetBankItems() end,
		[3] = function(u) return u:GetEquippedItems() end,
	}
	-- return itemid from inventory/bank/equipped
	local t_itemid = 
	{
		[1] = function(i) return i.itemInBag:GetItemId() end,
		[2] = function(i) return i.itemInSlot:GetItemId() end,
		[3] = function(i) return i:GetItemId() end,
	}
    -- return item objet from inventory/bank/equipped
    local t_itemobj = 
	{
		[1] = function(i) return i.itemInBag end,
		[2] = function(i) return i.itemInSlot end,
		[3] = function(i) return i end,
	} 
	
-----------------------------------------------------------------------------------------------
-- search item in bag by chatlink, return nbagslot
function lg._EquipFromBag(sItemLink)
    local u = GameLib.GetPlayerUnit()
	local tBagItems = u:GetInventoryItems()
	for _=1, #tBagItems do
		local oItem = tBagItems[_].itemInBag
		if oItem:GetChatLinkString() == sItemLink then return tBagItems[_].nBagSlot end
	end
end

-----------------------------------------------------------------------------------------------
-- search item in bag/bank or equipped by chatlink, return item objet
function lg._SearchIn(sItemLink, nLoc)
	local u = GameLib.GetPlayerUnit()
	if u == nil then return nil end
	local tItems = t_source[nLoc](u) 
	for _=1, #tItems do
		local oItem = t_itemobj[nLoc](tItems[_])
		if oItem:GetChatLinkString() == sItemLink then return oItem end
	end
end

-----------------------------------------------------------------------------------------------
-- search location for a item by chatlink, return array (item objet, location)
function lg._FindItem(sItemLink)
   	local oItem, nFind = nil, 0
    for _=1, 3 do
	    oItem = lg._SearchIn(sItemLink, _) 
		if oItem ~= nil then
			nFind = _ 
			break
		end
	end
	local tFindItem = { item = oItem, find = nFind }
	return tFindItem	
end

-----------------------------------------------------------------------------------------------
-- search item by chatlink in all profile, return index array with ngearid/profile name
function lg._GetGearParent(sLink, tLastGear)
	if tLastGear == nil then return end
	local tGearParent = {}
    for nGearId, peCurrent in pairs(tLastGear) do	
		for _, oItemLink in pairs(tLastGear[nGearId]) do
			if tonumber(_) ~= nil then	
	    	   if sLink == oItemLink then 
					tGearParent[#tGearParent+1] = { ngearid = nGearId, name = tLastGear[nGearId].name}
			    end
		    end
	   	end
	end
	return tGearParent
end

-----------------------------------------------------------------------------------------------
-- watch if all item from a profil are correctly equipped
function lg._CheckEquipped(nGearId, tLastGear)
   	if nGearId == nil or tLastGear == nil or tLastGear[nGearId] == nil or lg.TableLength(tLastGear[nGearId]) == 0 then 
    	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nil, terror = nil })
		return 
	end
	local tActualSet = lg._GetAllEquipped()
    local bError = false
    local tError = {}	
    if tActualSet ~= nil or lg.TableLength(tActualSet) ~= 0 then  
		for _, oLink in pairs(tLastGear[nGearId]) do
			if tonumber(_) then	
				if tActualSet[_] ~= oLink then
					tError[_] = false 
					bError = true
				elseif tActualSet[_] == oLink then	
					tError[_] = true
				end
			end	
		end
	end
	if not bError then tError = nil	end
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_AFTER_EQUIP", nGearId, nil, nil, tError)
    Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nGearId, terror = tError })	
end

-----------------------------------------------------------------------------------------------
-- GetAllEquipped 
function lg._GetAllEquipped()
 	local u = GameLib.GetPlayerUnit()
	if u == nil then return nil end
	local tEquippedItems = u:GetEquippedItems()
    local tEquipped = {} 
    for _=1, #tEquippedItems do
        local nItemType = tEquippedItems[_]:GetItemType()
    	if nItemType ~= Item.CodeEnumItemType.TempBag then
			local nSlot = tEquippedItems[_]:GetSlot()			  
			if nSlot ~= 6 and nSlot ~= 9 then			  
				local sItemLink = tEquippedItems[_]:GetChatLinkString()
				tEquipped[nSlot] = sItemLink
       		end
		end
  	end
    return tEquipped
end

---------------------------------------------------------------------------------------------------
-- to prevent request to equip profile if in combat or dead.
function lg.canequip()
	local u = GameLib.GetPlayerUnit()
	return not u:IsInCombat() and not u:IsDead()
end

---------------------------------------------------------------------------------------------------
-- return only the length for numeric index if table have numeric and non numeric index 
function lg.TableLength(tTable)
  local count = 0
  for _ in pairs(tTable) do 
  	if tonumber(_) then count = count + 1 end 
  end
  return count
end

---------------------------------------------------------------------------------------------------
-- return the length for numeric/non numeric index of table  
function lg.TableLengthBoth(tTable)
  local count = 0
  for _ in pairs(tTable) do 
  	count = count + 1 
  end
  return count
end

---------------------------------------------------------------------------------------------------
-- return copy of an array (recursive copy)  
function lg.DeepCopy(tTable)
	if type(tTable) == "table" then
		local copy = {}
		for k, v in next, tTable do
			copy[lg.DeepCopy(k)] = lg.DeepCopy(v)
		end
		return copy
	else
		return tTable
	end
end

-----------------------------------------------------------------------------------------------
-- TableMerge 
function lg.TableMerge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == "table" then
    		if type(t1[k] or false) == "table" then
    			lg.TableMerge(t1[k] or {}, t2[k] or {})
    		else
    			t1[k] = v
    		end
    	else
    		t1[k] = v
    	end
    end
    return t1
end

-----------------------------------------------------------------------------------------------
function lg:OnLoad() end
Apollo.RegisterPackage(lg, MAJOR, MINOR, {})