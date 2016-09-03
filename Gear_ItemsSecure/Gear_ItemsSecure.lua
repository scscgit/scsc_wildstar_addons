 -----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_OneVersion
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-- Module Definition
-----------------------------------------------------------------------------------------------
local Gear_ItemsSecure = {}

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_ItemsSecure", true)

-----------------------------------------------------------------------------------------------
-- Hook
-----------------------------------------------------------------------------------------------
local Hook = Apollo.GetPackage("Gemini:Hook-1.0").tPackage

-----------------------------------------------------------------------------------------------
-- Lib gear
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version
local Major, Minor, Patch = 1, 0, 2
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_ItemsSecure"

-----------------------------------------------------------------------------------------------
-- Plugin data
-----------------------------------------------------------------------------------------------
local tPlugin =     {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = L["GP_FLAVOR"],				-- addon description
						    icon = nil,   				        -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = L["GP_O_SETTINGS"], -- setting name to view in gear setting window
									-- parent setting
									[1] =  {
												[1] = { bActived = true, sDetail = L["GP_O_SETTING_1"],},  -- child setting
												[2] = { bActived = true, sDetail = L["GP_O_SETTING_2"],},
												[3] = { bActived = true, sDetail = L["GP_O_SETTING_3"],},
											},
									},
					}

-- addon to hook
local tAddon = {
					inventory = {
										    ["Inventory"] = {
															[1] = { hook = "OnSystemBeginDragDrop",     replaceby = "_NoDropSalvage_Inventory",   },
															[2] = { hook = "InvokeDeleteConfirmWindow", replaceby = "_NoDropDelete_Inventory",    },
														   },

									["ForgeUI_Inventory"] = {
															[1] = { hook = "OnSystemBeginDragDrop",     replaceby = "_NoDropSalvage_Inventory",    },
															[2] = { hook = "InvokeDeleteConfirmWindow", replaceby = "_NoDropDelete_Inventory",     },
														   },

								           ["KuronaBags"] = {
															[1] = { hook = "OnSystemBeginDragDrop",     replaceby = "_NoDropSalvage_KuronaBags",    },
															[2] = { hook = "InvokeDeleteConfirmWindow", replaceby = "_NoDropDelete_KuronaBags",     },
															[3] = { hook = "OnPreventSalvage",          replaceby = "_OnPreventSalvage_KuronaBags", },
														   },

								  ["SpaceStashInventory"] = {
															[1] = { hook = "OnSystemBeginDragDrop",     replaceby = "_NoDropSalvage_SpaceStashInventory",    },
															[2] = { hook = "InvokeDeleteConfirmWindow", replaceby = "_NoDropDelete_SpaceStashInventory",     },
															},
								},

					  salvage = {
								 	  ["ImprovedSalvage"] = {

									  						[1] = { hook = "OnSalvageAll",              replaceby = "_NoSalvage_Inventory",          },
									  					    },

								       ["KuronaSalvage"] = {
															[1] = { hook = "OnSalvageAll",              replaceby = "_NoSalvage_KuronaSalvage",      },
														   },
								},

					   vendor = {
					    			          ["Vendor"] = {
															[1] = { hook = "UpdateSellItems",           replaceby = "_NoSell_Vendor", keep = true, },
														   },

											  ["MyVendor"] = {
															[1] = { hook = "UpdateSellItems",           replaceby = "_NoSell_Vendor", keep = true, },
														   },
					   			},
				}

-- plugin enable/disable in setting panel
local bOn = true
-- comm timer to init plugin
local tComm, bCall
-- futur array for tgear.gear updated
local tLastGear = nil

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Gear_ItemsSecure:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end

-----------------------------------------------------------------------------------------------
-- OnLoad
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:OnLoad()
	Apollo.RegisterEventHandler("CloseVendorWindow",   "OnVendorClose", self)	   -- vendor close
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)     -- add event to communicate with gear
	Hook:Embed(self)															   -- init hook
	tComm  = ApolloTimer.Create(1, true, "_Comm", self) 						   -- init comm for plugin
end

---------------------------------------------------------------------------------------------------
-- _Comm
---------------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_Comm()

	if lGear._isaddonup("Gear")	then												-- if 'gear' is running , go next
		tComm = nil 																-- stop init comm timer
		if bCall == nil then lGear.initcomm(tPlugin) end 							-- send information about me, setting etc..
	end
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:ON_GEAR_PLUGIN(sAction, tData)

	-- answer come from gear, the gear version, gear is up
	if sAction == "G_VER" and tData.owner == GP_NAME then

		if bCall ~= nil then return end
		bCall = true

		if tPlugin.on then
			-- we request we want last gear array
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			-- start items secure
			Apollo.RegisterEventHandler("RequestSalvageAll", "OnHookSalvage", self)
			self:_WhoHook()

		end
	end

	-- answer come from gear, the gear array updated
	if sAction == "G_GEAR" then
		tLastGear = tData
	end

	-- answer come from gear, the setting plugin are updated, if this information is for me go next
	if sAction == "G_SETTING" and tData.owner == GP_NAME then
		-- update setting status
		tPlugin.setting[1][tData.option].bActived = tData.actived
		-- update sell vendor window
		if self.aVendor and tData.option == 3 then self.aVendor:Redraw() end
	end

	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		-- update enable/disable status
		tPlugin.on = tData.on
		bOn = tData.on

		if tPlugin.on then
			-- we request we want last gear array
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			-- start items secure
			Apollo.RegisterEventHandler("RequestSalvageAll", "OnHookSalvage", self)
			self:_WhoHook()
		else
			-- stop items secure
			Apollo.RemoveEventHandler("RequestSalvageAll")
			self:UnhookAll()
			-- update sell vendor window
			if self.aVendor then self.aVendor:Redraw() self.aVendor = nil end
		end

		-- update sell vendor window
		if self.aVendor and self.aVendor.tWndRefs.wndVendor and self.aVendor.tWndRefs.wndVendor:FindChild("VendorTab1"):IsChecked() then self.aVendor:Redraw() end
	end
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear_ItemsSecure:OnSave(eLevel)

	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	-- save settings
	local tData_settings = {}
	for _, peChild in pairs(tPlugin.setting[1]) do
	   	if tonumber(_) then
			tData_settings[_] = peChild.bActived
		end
	end

	local tData = { }
	      tData.config = {
	                       settings = tData_settings,
							    ver = GP_VER,
								 on = tPlugin.on,
						 }
	return tData
end

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear_ItemsSecure:OnRestore(eLevel,tData)

	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	if tData.config.settings then
    	for _, peChild in pairs(tPlugin.setting[1]) do
			-- if index number exist then restore child from actual parent
			if tData.config.settings[_] ~= nil then tPlugin.setting[1][_].bActived = tData.config.settings[_] end
		end
	end

	if tData.config.on ~= nil then tPlugin.on = tData.config.on end
end

-----------------------------------------------------------------------------------------------
-- WhoHook
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_WhoHook()

	self:UnhookAll()
	-- in category
	for Category, pAddon in pairs(tAddon) do
		-- in addon name
		for sName, oCurrent in pairs(pAddon) do

		    local sAddonName = sName
			local aCheckAddon = Apollo.GetAddon(sAddonName)

			if aCheckAddon then
				-- in numeric index
				for _=1,#oCurrent do

					local toHook = oCurrent[_].hook
					local replaceBy = oCurrent[_].replaceby
					self:RawHook(aCheckAddon, toHook, replaceBy)

					if oCurrent[_].keep == true then self.aVendor = aCheckAddon end
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- NoSell_Vendor (carbine vendor API 11)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoSell_Vendor(luaCaller)

	local unitPlayer = GameLib.GetPlayerUnit()
	if not luaCaller.tWndRefs.wndVendor:GetData() or not unitPlayer then
		return
	end

	local tInvItems = unitPlayer:GetInventoryItems()
	local tNewSellItems = {}
	for key, tItemData in ipairs(tInvItems) do

		local itemCurr = luaCaller:ItemToVendorSellItem(tItemData.itemInBag)
		if itemCurr then

			local bSell = true

			if tPlugin.setting[1][3].bActived and bOn then
				local tGearName = lGear._IsKnowGear(tItemData.itemInBag:GetChatLinkString(), tLastGear)
				if #tGearName ~= 0 then
					bSell = false
				end
			end

			if bSell then
				table.insert(tNewSellItems, itemCurr)
			end
		end
	end

	local tSellGroups = {{idGroup = 0, strName = Apollo.GetString("Vendor_Junk")}, {idGroup = 1, strName = Apollo.GetString("Vendor_All")}}
	local tNewSellItemsByGroup = luaCaller:ArrangeGroups(tNewSellItems, tSellGroups)

	local bChanged = false
	local bItemCountChanged = false
	local bGroupCountChanged = false
	if luaCaller.tSellItemsByGroup == nil or not luaCaller:TableEquals(tNewSellItemsByGroup, luaCaller.tSellItemsByGroup) then
		bChanged = true
		bItemCountChanged = #tNewSellItems ~= (luaCaller.tSellItems ~= nil and #luaCaller.tSellItems or 0)
		bGroupCountChanged = #tNewSellItemsByGroup ~= (luaCaller.tSellItemsByGroup ~= nil and #luaCaller.tSellItemsByGroup or 0)
		luaCaller.tSellItems = tNewSellItems
		luaCaller.tSellItemsByGroup = tNewSellItemsByGroup
	end

	local tReturn = {}
	tReturn.bChanged = bChanged
	tReturn.bItemCountChanged = bItemCountChanged
	tReturn.bGroupCountChanged = bGroupCountChanged
	tReturn.tUpdatedItems = luaCaller.tSellItemsByGroup
	return tReturn
end

-----------------------------------------------------------------------------------------------
-- OnHookSalvage
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:OnHookSalvage()
	-- if kuronabags virtual bags preventsalvage is not actived
	if self.bPreventSalvage	~= true or self.bPreventSalvage == nil and bOn then
		self:_WhoHook()
	end
end

-----------------------------------------------------------------------------------------------
-- NoSalvage_Inventory (carbine inventory API 11)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoSalvage_Inventory(luaCaller)

	luaCaller.arItemList = {}
	luaCaller.tSelection = { nIndex = luaCaller.nStartIndex, nBagPos = luaCaller.nStartIndex}

	local tInvItems = GameLib.GetPlayerUnit():GetInventoryItems()
	for idx, tItem in ipairs(tInvItems) do

		if tItem and tItem.itemInBag and tItem.itemInBag:CanSalvage() and not tItem.itemInBag:CanAutoSalvage() then

			local bSalvage = true

			if tPlugin.setting[1][1].bActived and bOn then

				local tGearName = lGear._IsKnowGear(tItem.itemInBag:GetChatLinkString(), tLastGear)
				if #tGearName ~= 0 then
					bSalvage = false
				end
			end

			if bSalvage then
				table.insert(luaCaller.arItemList, tItem.itemInBag)
			end
		end
	end

	luaCaller.wndMain:FindChild("SortQualityBtn"):SetCheck(luaCaller.bSortByQuality)
	luaCaller:RedrawAll()
end

-----------------------------------------------------------------------------------------------
-- NoSalvage_KuronaSalvage (kuronasalvage v411)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoSalvage_KuronaSalvage(luaCaller)

	local improvedSalvage = Apollo.GetAddon("ImprovedSalvage")
	if improvedSalvage then
		improvedSalvage.wndMain:Show(false)
	end

	luaCaller.arItemList = {}
	luaCaller.nItemIndex = 1

	luaCaller.KuronaBags = Apollo.GetAddon("KuronaBags")
	local preventSalvage = luaCaller.KuronaBags.PreventSalvageList

	local tInvItems = GameLib.GetPlayerUnit():GetInventoryItems()
	for idx, tItem in ipairs(tInvItems) do

		if tItem and tItem.itemInBag and tItem.itemInBag:CanSalvage() and not(luaCaller.IgnoreList[tItem.itemInBag:GetItemId()] or preventSalvage[tItem.itemInBag:GetItemId()]) then
			if not preventSalvage[tItem.itemInBag:GetItemId()] then

				local bSalvage = true

				if tPlugin.setting[1][1].bActived and bOn then

					local tGearName = lGear._IsKnowGear(tItem.itemInBag:GetChatLinkString(), tLastGear)
					if #tGearName ~= 0 then
						bSalvage = false
					end
				end

				if bSalvage then
					table.insert(luaCaller.arItemList, tItem.itemInBag)
				end
			end
		end
	end

	luaCaller:RedrawAll()
end

-----------------------------------------------------------------------------------------------
-- OnPreventSalvage_KuronaBags (kuronasalvage v411)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_OnPreventSalvage_KuronaBags(luaCaller, wndHandler, wndControl, eMouseButton)

	if wndHandler ~= nil then
		local bag = wndHandler:GetParent():GetParent()
		local num = luaCaller:FindExtraBag(bag)
		luaCaller.ExtraBags[num].psalvage = wndHandler:IsChecked()
	end
	luaCaller.PreventSalvageList = {}

	-- init prevent salvage to not actived by default for actual bag
	self.bPreventSalvage = false

	if luaCaller.ExtraBags == nil or not luaCaller.tSettings.bEnableVB then return end

	for i = 1, #luaCaller.ExtraBags do

		if luaCaller.ExtraBags[i].psalvage then
			local clist = luaCaller.ExtraBags[i].Bag:FindChild("BagHolder"):GetChildren()
			-- prevent salvage is actived for actual bag
			self.bPreventSalvage = true

			for x=1,#clist do
				local item = clist[x]:GetChildren()[1]:GetData()

				if item and (item:CanSalvage() or  item:CanAutoSalvage()) then
					luaCaller.PreventSalvageList[item:GetItemId()] = true
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- _NoDropSalvage_Inventory (carbine inventory API 11)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropSalvage_Inventory(luaCaller, wndSource, strType, iData)

	if strType ~= "DDBagItem" then return end
	luaCaller.wndMain:FindChild("TextActionPrompt_Trash"):Show(false)
	luaCaller.wndMain:FindChild("TextActionPrompt_Salvage"):Show(false)

	local item = luaCaller.wndMainBagWindow:GetItem(iData)

	if item and item:CanSalvage() then

		local bSalvage = true
		local bDelete = true

		-- items secure
		local tGearName = lGear._IsKnowGear(item:GetChatLinkString(), tLastGear)

		if #tGearName ~= 0 then
			-- items secure drop salvage
			if tPlugin.setting[1][1].bActived and bOn then
				luaCaller.wndSalvageAllBtn:Enable(false)
				bSalvage = false
			end
			-- items secure drop trash
			if tPlugin.setting[1][2].bActived and bOn then
				luaCaller.wndMain:FindChild("TrashIcon"):Enable(false)
				bDelete = false
			end
		end

		if bSalvage then
			luaCaller.wndMain:FindChild("SalvageIcon"):SetData(true)
			luaCaller.wndSalvageAllBtn:Enable(true)
		end

		if bDelete then
			luaCaller.wndMain:FindChild("TrashIcon"):SetSprite("CRB_Inventory:InvBtn_TrashTogglePressed")
			luaCaller.wndMain:FindChild("TrashIcon"):Enable(true)
		end
	end

	Sound.Play(Sound.PlayUI45LiftVirtual)
end

-----------------------------------------------------------------------------------------------
-- _NoDropSalvage_SpaceStashInventory (SpaceStashInventory)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropSalvage_SpaceStashInventory(luaCaller, wndSource, strType, iData)

	if strType ~= "DDBagItem" then return end

	local item = luaCaller.wndBagWindow:GetItem(iData)

	if item and item:CanSalvage() then

		local bSalvage = true
		-- items secure
		local tGearName = lGear._IsKnowGear(item:GetChatLinkString(), tLastGear)

		if #tGearName ~= 0 then
			-- items secure drop salvage
			if tPlugin.setting[1][1].bActived and bOn then
				bSalvage = false
			end
		end

		if bSalvage then
			luaCaller.btnSalvage:SetData(true)
			luaCaller.btnSalvage:Enable(true)
		end
	end
	Sound.Play(Sound.PlayUI45LiftVirtual)
end

-----------------------------------------------------------------------------------------------
-- _NoDropDelete_SpaceStashInventory (SpaceStashInventory API 11)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropDelete_SpaceStashInventory(luaCaller, iData)

	local itemData = Item.GetItemFromInventoryLoc(iData)
	-- items secure
	local tGearName = lGear._IsKnowGear(itemData:GetChatLinkString(), tLastGear)
	if #tGearName ~= 0 and tPlugin.setting[1][2].bActived and bOn then

		luaCaller.wndDeleteConfirm:SetData(nil)
		luaCaller.wndDeleteConfirm:Close()
		return
	end

	if itemData and not itemData:CanDelete() then
		return
	end

	luaCaller.wndDeleteConfirm:SetData(iData)
	luaCaller.wndDeleteConfirm:Invoke()
	luaCaller.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

-----------------------------------------------------------------------------------------------
-- NoDropSalvage_KuronaBag (kuronabags v411)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropSalvage_KuronaBags(luaCaller, wndSource, strType, iData)

	if strType ~= "DDBagItem" then return end
	local item = luaCaller.NVB:GetItem(iData)

	if item and item:CanSalvage() then

		local bSalvage = true

		-- items secure
		local tGearName = lGear._IsKnowGear(item:GetChatLinkString(), tLastGear)

		if #tGearName ~= 0 then

			if tPlugin.setting[1][1].bActived and bOn then
				luaCaller.BagForm:FindChild("SalvageAllButton"):Enable(false)
				bSalvage = false
			end
		end

		if bSalvage then
			luaCaller.BagForm:FindChild("SalvageIcon"):SetData(true)
		    luaCaller.BagForm:FindChild("SalvageAllButton"):Enable(true)
		end
	end
	Sound.Play(Sound.PlayUI45LiftVirtual)
end

-----------------------------------------------------------------------------------------------
-- _NoDropDelete_Inventory (carbine inventory API 11)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropDelete_Inventory(luaCaller, iData)

	local itemData = Item.GetItemFromInventoryLoc(iData)
	-- items secure
	local tGearName = lGear._IsKnowGear(itemData:GetChatLinkString(), tLastGear)
	if #tGearName ~= 0 and tPlugin.setting[1][2].bActived and bOn then

		luaCaller.wndDeleteConfirm:SetData(nil)
		luaCaller.wndDeleteConfirm:Close()
		luaCaller.wndMain:FindChild("DragDropMouseBlocker"):Show(false)
		return
	end

	if itemData and not itemData:CanDelete() then
		return
	end

	luaCaller.wndDeleteConfirm:SetData(iData)
	luaCaller.wndDeleteConfirm:Invoke()
	luaCaller.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	luaCaller.wndMain:FindChild("DragDropMouseBlocker"):Show(true)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

-----------------------------------------------------------------------------------------------
-- NoDropDelete_KuronaBag (kuronabag v411)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:_NoDropDelete_KuronaBags(luaCaller, iData)

	local item = Item.GetItemFromInventoryLoc(iData)
	local quality = item:GetItemQuality()
	-- items secure
	local tGearName = lGear._IsKnowGear(item:GetChatLinkString(), tLastGear)
	if #tGearName ~= 0 and tPlugin.setting[1][2].bActived and bOn then

		luaCaller.wndDeleteConfirm:SetData(nil)
		luaCaller.wndDeleteConfirm:Close()
		luaCaller.BagForm:FindChild("DragDropMouseBlocker"):Show(false)
		return
	end

	if item and not item:CanDelete() then
		return
	end

	local ItemQualityFrames = {
		[1] = "CRB_Tooltips:sprTooltip_Header_Silver",
		[2] = "CRB_Tooltips:sprTooltip_Header_White",
		[3] = "CRB_Tooltips:sprTooltip_Header_Green",
		[4] = "CRB_Tooltips:sprTooltip_Header_Blue",
		[5] = "CRB_Tooltips:sprTooltip_Header_Purple",
		[6] = "CRB_Tooltips:sprTooltip_Header_Orange",
		[7] = "CRB_Tooltips:sprTooltip_Header_Pink",
						      }

	local QualityColors = {
		[0] = "00000000",
		[1] = "ccc0c0c0",
		[2] = "ccFFFFFF",
		[3] = "cc00ff00",
		[4] = "cc0000ff",
		[5] = "cc800080",
		[6] = "ccff8000",
		[7] = "ccff00ff",
						  }

	luaCaller.wndDeleteConfirm:FindChild("RarityBracket"):SetSprite(ItemQualityFrames[quality])
	luaCaller.wndDeleteConfirm:FindChild("LootIcon"):SetSprite(item:GetIcon())
	luaCaller.wndDeleteConfirm:FindChild("ColorBG"):SetBGColor(QualityColors[quality])
	luaCaller.wndDeleteConfirm:FindChild("IconFrame"):SetBGColor(QualityColors[quality])
	luaCaller.wndDeleteConfirm:FindChild("ItemName"):SetText(item:GetName())
	luaCaller.wndDeleteConfirm:FindChild("ItemType"):SetText(item:GetItemTypeName())
	luaCaller.wndDeleteConfirm:FindChild("DeleteLootItem"):SetOpacity(0.85)

	luaCaller.wndDeleteConfirm:SetData(iData)
	luaCaller.wndDeleteConfirm:Show(true)
	luaCaller.wndDeleteConfirm:ToFront()
	luaCaller.wndDeleteConfirm:FindChild("DeleteBtn"):SetActionData(GameLib.CodeEnumConfirmButtonType.DeleteItem, iData)
	luaCaller.BagForm:FindChild("DragDropMouseBlocker"):Show(true)
	for i = 1, #luaCaller.ExtraBags do
		-- scsc: was crashing on nil in combination with KuronaBags, probably not compatible; maybe this functionality will break
		local bag = luaCaller.ExtraBags[i].Bag
		if bag then
			bag:FindChild("DragDropMouseBlocker"):Show(true)
		end
	end

	luaCaller.BagForm:FindChild("SalvageAllButton"):Enable(false)
	Sound.Play(Sound.PlayUI55ErrorVirtual)
end

-----------------------------------------------------------------------------------------------
-- OnVendorWindow (close vendor)
-----------------------------------------------------------------------------------------------
function Gear_ItemsSecure:OnVendorClose()
    self.aVendor = nil
end

-----------------------------------------------------------------------------------------------
-- Instance
-----------------------------------------------------------------------------------------------
local Gear_ItemsSecureInst = Gear_ItemsSecure:new()
Gear_ItemsSecureInst:Init()
