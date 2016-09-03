local MAJOR, MINOR = "Lib:LibGear-1.0", 1
local APkg = Apollo.GetPackage(MAJOR)
if APkg and (APkg.nVersion or 0) >= MINOR then return end
local LibGear = APkg and APkg.tPackage or {}

-----------------------------------------------------------------------------------------------
-- find is a addon is running
-----------------------------------------------------------------------------------------------
function LibGear._isaddonup(sAddOn)
  
	local oAddon = Apollo.GetAddonInfo(sAddOn)
	if oAddon and oAddon.bRunning == 1 then return true end
	return nil
end

-----------------------------------------------------------------------------------------------
--- init plugin communication
-----------------------------------------------------------------------------------------------
function LibGear.initcomm(tData)
	
	-- send ready request to 'gear'
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_READY", tData)
end

-----------------------------------------------------------------------------------------------
-- load plugin icon and return sprite icon name (25x25 pixel)
-----------------------------------------------------------------------------------------------
function LibGear._loadicon(sPlugIn)
  	local sWildstarDir = string.match(Apollo.GetAssetFolder(), "(.-)[\\/][Aa][Dd][Dd][Oo][Nn][Ss]")
	Apollo.LoadSprites(sWildstarDir.."\\Addons\\" .. sPlugIn .. "\\resource\\Sprite.xml") 
	return sPlugIn -- sample name sprite: "Gear_Mount"
end

-----------------------------------------------------------------------------------------------
-- search item in bag by chatlink, return nbagslot
-----------------------------------------------------------------------------------------------
function LibGear._EquipFromBag(sItemLink)
  
    local   uPlayer = GameLib.GetPlayerUnit()
	local tBagItems = uPlayer:GetInventoryItems()
			
	for _=1, #tBagItems do
		local oItem = tBagItems[_].itemInBag
					   
		if oItem:GetChatLinkString() == sItemLink then return tBagItems[_].nBagSlot end
	end
end

-----------------------------------------------------------------------------------------------
-- search item in bag by chatlink, return item objet
-----------------------------------------------------------------------------------------------
function LibGear._SearchInBag(sItemLink)
  
    local   uPlayer = GameLib.GetPlayerUnit()
	if uPlayer == nil then return nil end
	local tBagItems = uPlayer:GetInventoryItems()
			
	for _=1, #tBagItems do
		local oItem = tBagItems[_].itemInBag
			   
		if oItem:GetChatLinkString() == sItemLink then return oItem end
	end
end

-----------------------------------------------------------------------------------------------
-- search item in bank by chatlink, return item objet
-----------------------------------------------------------------------------------------------
function LibGear._SearchInBank(sItemLink)
  
    local uPlayer = GameLib.GetPlayerUnit()
	if uPlayer == nil then return nil end
	local tBankItems = uPlayer:GetBankItems()
			
	for _=1, #tBankItems do
		local oItem = tBankItems[_].itemInSlot
			   
		if oItem:GetChatLinkString() == sItemLink then return oItem end
	end
end

-----------------------------------------------------------------------------------------------
-- search item in equipped by chatlink, return item objet
-----------------------------------------------------------------------------------------------
function LibGear._SearchInEquipped(sItemLink)
  
    local uPlayer = GameLib.GetPlayerUnit()
	if uPlayer == nil then return nil end
	local tEquippedItems = uPlayer:GetEquippedItems()
		
	for _=1, #tEquippedItems do
		local oItem = tEquippedItems[_]
									
	    if oItem:GetChatLinkString() == sItemLink then return oItem end
	end
end

-----------------------------------------------------------------------------------------------
-- search localisation for a item by chatlink
-----------------------------------------------------------------------------------------------
function LibGear._FindItem(sItemLink)
    		
    -- 0 = not find
	-- 1 = equipped
	-- 2 = bag
	-- 3 = bank
	
	local nFind = 0
	local oItem = lGear._SearchInBag(sItemLink)
   	if oItem then 
 	   	nFind = 2
	else	
		oItem = lGear._SearchInBank(sItemLink)
		if oItem then 
			nFind = 3
		else
			oItem = lGear._SearchInEquipped(sItemLink)
		    if oItem then 
				nFind = 1
			else
				return nil	
			end
		end
	end	
			
	-- item find
	local tFindItem = { item = oItem, find = nFind }
	return tFindItem	
end

-----------------------------------------------------------------------------------------------
-- search item by chatlink in all gear set, return array with name of set contain items find 
-----------------------------------------------------------------------------------------------
function LibGear._IsKnowGear(sLink, tLastGear)
	
	if tLastGear == nil then return end
	
	local tGearParent = {}
    for nGearId, peCurrent in pairs(tLastGear) do	
				
		for _, oItemLink in pairs(tLastGear[nGearId]) do
			
			if tonumber(_) ~= nil then	
	    	    local sItemLink = oItemLink
		       	if sLink == sItemLink then table.insert(tGearParent, tLastGear[nGearId].name) end
		    end
	   	end
	end
	return tGearParent
end

---------------------------------------------------------------------------------------------------
-- return only the length for numeric index if table have numeric and non numeric index 
---------------------------------------------------------------------------------------------------
function LibGear.TableLength(tTable)
  local count = 0
  for _ in pairs(tTable) do 
  	if tonumber(_) then count = count + 1 end 
  end
  return count
end

---------------------------------------------------------------------------------------------------
-- return the length for numeric/non numeric index of table  
---------------------------------------------------------------------------------------------------
function LibGear.TableLengthBoth(tTable)
  local count = 0
  for _ in pairs(tTable) do 
  	count = count + 1 
  end
  return count
end

---------------------------------------------------------------------------------------------------
-- return copy of an array (recursive copy)  
---------------------------------------------------------------------------------------------------
function LibGear.DeepCopy(tTable)
	if type(tTable) == "table" then
		local copy = {}
		for k, v in next, tTable do
			copy[LibGear.DeepCopy(k)] = LibGear.DeepCopy(v)
		end
		return copy
	else
		return tTable
	end
end

-----------------------------------------------------------------------------------------------
-- TableMerge 
-----------------------------------------------------------------------------------------------
function LibGear.TableMerge(t1, t2)
    for k,v in pairs(t2) do
    	if type(v) == "table" then
    		if type(t1[k] or false) == "table" then
    			LibGear.TableMerge(t1[k] or {}, t2[k] or {})
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

function LibGear:OnLoad() end
Apollo.RegisterPackage(LibGear, MAJOR, MINOR, {})