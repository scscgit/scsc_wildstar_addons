-----------------------------------------------------------------------------------------------
-- Craft Queue Item implementation
-- Copyright (c) 2014 DoctorVanGogh on Wildstar forums - all rights reserved
-----------------------------------------------------------------------------------------------

require "GameLib"
require "CraftingLib"

local MAJOR,MINOR = "DoctorVanGogh:Hephaestus:CraftQueueItem", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end
local oo = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage
local ooModelCraftQueue = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Multiple").tPackage

local CraftQueueItem = APkg and APkg.tPackage or oo.class{}

local CraftUtil = Apollo.GetPackage("DoctorVanGogh:Hephaestus:CraftUtil").tPackage	

-------------------------------------------------------------
-- local values declarations
-------------------------------------------------------------


local glog

function CraftQueueItem:OnLoad()
	-- import GeminiLogging
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
	glog = GeminiLogging:GetLogger({
		level = GeminiLogging.INFO,
		pattern = "%d [%c:%n] %l - %m",
		appender = "GeminiConsole"
	})	
	
	self.log = glog	
end

function CraftQueueItem:Serialize()
	return {
		nSchematicId = self.tSchematicInfo.nSchematicId,
		nAmount = self.nAmount
	}	
end 

function CraftQueueItem:Deserialize(tStorage, tQueue)
	if tStorage and tStorage.nSchematicId and tStorage.nAmount then
		return CraftQueueItem(CraftingLib.GetSchematicInfo(tStorage.nSchematicId), tStorage.nAmount, tQueue)
	end
end

function CraftQueueItem:__init(tSchematicInfo, nAmount, tQueue)

	glog:debug("__init(%s, %s, %s, ...)", tostring(tSchematicInfo), tostring(nAmount), tostring(tQueue))

	ci = oo.rawnew(
		self, 
		{
			tSchematicInfo = tSchematicInfo,
			nAmount = nAmount,
			tQueue = tQueue		
		}
	)
	return ci
end

function CraftQueueItem:Remove()
	self.tQueue:Remove(self)
end

function CraftQueueItem:GetQueue()
	return self.tQueue
end

function CraftQueueItem:MoveForward()
	return self:GetQueue():Forward(self)
end

function CraftQueueItem:MoveBackward()
	return self:GetQueue():Backward(self)
end

function CraftQueueItem:GetSchematicInfo()
	return self.tSchematicInfo
end

function CraftQueueItem:GetAmount()
	return self.nAmount
end

function CraftQueueItem:SetAmount(nAmount)
	self.nAmount = nAmount
end

function CraftQueueItem:CraftComplete()
	glog:debug("CraftQueueItem:CraftComplete()")


	self:SetAmount(self:GetAmount() - (self:GetCurrentCraftAmount() or 0))
	self:SetCurrentCraftAmount(nil)

	-- GOTCHA: we dont have a dependency on CraftQueue (intentionally!), so we got to get the eventname in a roundabout way ;)
	local queue = self:GetQueue()
	local CraftQueue = ooModelCraftQueue.classof(queue)		
	queue:FireCollectionChangedEvent(CraftQueue.CollectionChanges.Refreshed, self)
end

function CraftQueueItem:GetMaxCraftable()
	return CraftUtil:GetMaxCraftableForSchematic(self:GetSchematicInfo())
end

function CraftQueueItem:GetCurrentCraftAmount()
	return self.nCurrentCraftAmount
end

function CraftQueueItem:SetCurrentCraftAmount(nCount)
	glog:debug("CraftQueueItem:SetCurrentCraftAmount(%s)", tostring(nCount))
	self.nCurrentCraftAmount = nCount
end

function CraftQueueItem:TryCraft()
	glog:debug("CraftQueueItem:TryCraft")

	if self:GetMaxCraftable() == 0 then
		glog:warn(Apollo.GetString("GenericError_Craft_MissingMaterials"))
		self:GetQueue():Stop()
		return
	end
		
	local bCanCraft, bAtCraftingStation, bNotMounted, bNotBusy = CraftUtil:CanCraft()
	glog:debug("CanCraft: %s (%s, %s, %s)", tostring(bCanCraft), tostring(bAtCraftingStation), tostring(bNotMounted), tostring(bNotBusy))
	if not bCanCraft then
		if not bAtCraftingStation then
			glog:warn(Apollo.GetString("CBCrafting_NoStation"))
		end
		if not bNotMounted then
			glog:warn("Player mounted")
		end
		if not bNotBusy then
			glog:warn(Apollo.GetString("GenericError_PlayerBusy"))
		end			
		self:GetQueue():Stop()
		return
	end	
	
	
	local tSchematicInfo = self:GetSchematicInfo()
	
	if tSchematicInfo.nParentSchematicId and tSchematicInfo.nParentSchematicId ~= 0 and tSchematicInfo.nSchematicId ~= tSchematicInfo.nParentSchematicId then
		glog:warn("Cannot create variant items (yet) - stopping")
		self:GetQueue():Stop()
		return
	end
	
	local nAmount = self:GetAmount()
	
	if not nAmount or nAmount <= 0 then
		glog:warn("Nothing to craft...")
		return
	end
	
	--[[ 
		available keys:
		- nSchematicId
		- strName
		- itemOutput
		- bIsAutoCraft
		- nCraftAtOnceMax 	
		- nParentSchematicId 
	]]
	local bIsAutoCraft = tSchematicInfo.bIsAutoCraft or false
	local nCraftAtOnceMax = bIsAutoCraft and tSchematicInfo.nCraftAtOnceMax or 1
	local tItemOutput = tSchematicInfo.itemOutput
	local nRoomForOutputItems = 0
	local unitPlayer = GameLib.GetPlayerUnit()
	local nCraftCount = math.max(tSchematicInfo.nCreateCount or 1, tSchematicInfo.nCritCount or 1) -- calculate defensively, in case there are ever crit crafts with more output
	
	-- *some* recipes use the same material for input as they produce - correctly reduce the output amount by this
	local nOutputDifference = nCraftCount
	for idx, tMaterial in ipairs(tSchematicInfo.tMaterials) do
		if tItemOutput:GetItemId() == tMaterial.itemMaterial:GetItemId() then
			nOutputDifference = nOutputDifference - tMaterial.nAmount
			break
		end
	end		
	-- make sure we have enough space in inventory
	local nInventoryCount, nFirstPartialStackCountAvailable = CraftUtil:GetInventoryCountForItem(tItemOutput)		
	local nMaxCraftCountsStashableInInventory 
	if nFirstPartialStackCountAvailable then
		glog:debug("Partial stack room remaining: %.f", nFirstPartialStackCountAvailable)
		--[[ HACK: Workaround/damage mitigation for Carbine bug sometimes not returning full number of output items if crafting would start a new stack
			Sequence:
				- 	Try crafting only so many items we just do *not* start new stack 
					math.floor(nFirstPartialStackCountAvailable / nOutputDifference)
				-	Next try above number will be '0', so craft just '1' item
					math.max(1, ....)			
		]]
		nMaxCraftCountsStashableInInventory = math.max(1, math.floor(nFirstPartialStackCountAvailable / nOutputDifference))
	else
		nMaxCraftCountsStashableInInventory = math.floor(nInventoryCount / nOutputDifference)
	end		
	
	local nMaxCraftable = self:GetMaxCraftable() or 0

	local nCount = math.min(nAmount, nCraftAtOnceMax, nMaxCraftable, nMaxCraftCountsStashableInInventory)	
	
	glog:debug("Amount: %.f, MaxAtOnce: %.f, MaxMaterialsAvailable: %.f, MaxCraftsStashable: %.f => Final Count: %.f", nAmount, nCraftAtOnceMax, nMaxCraftable, nMaxCraftCountsStashableInInventory, nCount)	
	if not nCount then
		return
	else
		if nCount == 0 then
			if nMaxCraftCountsStashableInInventory == 0 then
				glog:warn(Apollo.GetString("ItemSetInventory_InventoryFull"))
				self:GetQueue():Stop()
				return
			elseif nMaxCraftable == 0 then
				glog:warn(Apollo.GetString("GenericError_Craft_MissingMaterials"))
				self:GetQueue():Stop()
				return
			
			end
		end	
	end
	
	
	
	self:SetCurrentCraftAmount(nCount)	
	
	if bIsAutoCraft then
		glog:debug("CraftingLib.CraftItem(%s, nil, %s)", tostring(tSchematicInfo.nSchematicId), tostring(nCount))	

		CraftingLib.CraftItem(tSchematicInfo.nSchematicId, nil, nCount)
	else	
		glog:debug("CraftingLib.CraftItem(%s)", tostring(tSchematicInfo.nSchematicId))	
		
	
		CraftingLib.CraftItem(tSchematicInfo.nSchematicId, nil)	
		-- TODO: make some moves (later)
		
		glog:debug("CraftingLib.CompleteCraft()")		
		CraftingLib.CompleteCraft()
	end			
	
	-- GOTCHA: we dont have a dependency on CraftQueue (intentionally!), so we got to get the eventname in a roundabout way ;)
	local queue = self:GetQueue()
	local CraftQueue = ooModelCraftQueue.classof(queue)
	queue:FireCollectionChangedEvent(CraftQueue.CollectionChanges.Refreshed, self)		
end


Apollo.RegisterPackage(
	CraftQueueItem, 
	MAJOR, 
	MINOR, 
	{
		"Gemini:Logging-1.2",
		"DoctorVanGogh:Lib:Loop:Base",				-- for self
		"DoctorVanGogh:Lib:Loop:Multiple",			-- for craftqueue
		"DoctorVanGogh:Hephaestus:CraftUtil"
	}
)