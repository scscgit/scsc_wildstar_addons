-----------------------------------------------------------------------------------------------
-- Client Lua Script for Gear_Durability
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
  
-----------------------------------------------------------------------------------------------
-- gear_durability module definition
local Gear_Durability = {} 

-----------------------------------------------------------------------------------------------
-- module
local m_L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear_Durability", true)	
local m_lg = Apollo.GetPackage("Lib:LibGear-1.0").tPackage  									

-----------------------------------------------------------------------------------------------
-- constant
local Major, Minor, Patch = 1, 0, 3 
local GP_VER = string.format("%d.%d.%d", Major, Minor, Patch)
local GP_NAME = "Gear_Durability"
local GP_PARENT = "Gear"

-----------------------------------------------------------------------------------------------
-- local
local o_com, o_check, o_delayed_loc, o_delayed_dura, b_call 	
local t_tmpdura = {}                    						
local t_lastgear = nil 	 										
local t_durability = {} 	 									
local t_savedexp = {} 											
local xmlDoc 

local t_sett_default = { -- default plugin setting
						[1] = { min = 10, max = 90, tick = 1, init = 50, last = 50 },	-- durability alarm in %	
						[2] = false, 										-- show durabilty in %
						[3] = false, 										-- show item location
						[4] = false, 										-- show item progress
					   }	

local t_slotnotallowed = {15,7,8,11,10} -- dont check durability for this slot 
 				
local t_color = -- durability color
 {
	alarm = 
	{
		normal = "xkcdAquaBlue",    
		 fired = "xkcdBloodOrange",  
	}, 
	
	progress = 
	{ 
		p100 = {a=1,r=18/255,g=159/255,b=175/255}, --  100%
		 p50 = {a=1,r=215/255,g=208/255,b=23/255}, --  50%
		 p25 = {a=1,r=255/255,g=186/255,b=0/255},  --  25%				
		 p10 = {a=1,r=175/255,g=18/255,b=18/255},  --  10%
	},  
}
				
-----------------------------------------------------------------------------------------------
-- set plugin variable sending to gear addon
local t_plugin =   {
							name = GP_NAME,						-- addon name
						 version = GP_VER,						-- addon version
						  flavor = m_L["GP_FLAVOR"],			-- addon description
						    icon = "LOADED FROM GEAR",          -- icon plugin name for setting and ui_setting, loaded from 'gear'
						      on = true,						-- enable/disable
						 setting = {
									name = m_L["GP_O_SETTINGS"],  -- setting name to view in gear setting window
									-- parent setting 
									[1] =  {
											 [1] = { sType = "slider",   tValue = t_sett_default[1], sDetail = m_L["GP_O_SETTING_1"],}, -- durablity % alarm
											 [2] = { sType = "toggle", bActived = t_sett_default[2], sDetail = m_L["GP_O_SETTING_2"],}, -- show durabilty in %
											 [3] = { sType = "toggle", bActived = t_sett_default[3], sDetail = m_L["GP_O_SETTING_3"],}, -- show item location
											 [4] = { sType = "toggle", bActived = t_sett_default[4], sDetail = m_L["GP_O_SETTING_4"],}, -- show item progress
											}, 
									},   
										
					
					   ui_setting = {							-- ui setting for gear profil
																								  									 
									[1] = { sType = "none", Saved = nil,}, 
																	
									},   			
					
					}

					
-----------------------------------------------------------------------------------------------
-- array used with f_istrue() 
local t_condition =
{   
	[1] = function() return GameLib.IsCharacterLoaded() end, 
	[2] = function() return GameLib.GetPlayerUnit() end,     
	[3] = function() return t_lastgear end,                  
	[4] = function() return o_check end,                     
	[5] = function(...) 
					local n_gearid, n_slot = arg[1][1], arg[1][2]
					if t_lastgear[n_gearid][n_slot] and 
					t_durability[n_gearid] and
					t_durability[n_gearid][n_slot] then
					return true else return false end
	end,
	[6] = function(...) 
					local n_gearid, n_slot = arg[1][1], arg[1][2]
					if t_durability[n_gearid][n_slot].family ~= 26 then
					return true else return false end
	end,
}

local t_condition_var = {}

-----------------------------------------------------------------------------------------------
-- check all condition in order call, return true if all good or false for first condition error
local function f_istrue(...)
    local arg={...}
    local b_con
    for _=1, #arg do
        local o_con = t_condition[arg[_]](t_condition_var[arg[_]] or nil)
		if o_con == nil or o_con == false then b_con = false break else b_con = true end
	end
	return b_con
end
									
-----------------------------------------------------------------------------------------------
-- new instance
function Gear_Durability:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

-----------------------------------------------------------------------------------------------
-- init instance
function Gear_Durability:Init()
	Apollo.RegisterAddon(self, false, nil, {"Gear"})
end
 
-----------------------------------------------------------------------------------------------
-- fired after restore
function Gear_Durability:OnLoad()
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", "ON_GEAR_PLUGIN", self)          
	o_com  = ApolloTimer.Create(1, true, "f_com", self)									
end

-----------------------------------------------------------------------------------------------
-- wait message from gear addon
function Gear_Durability:f_com() 
	if m_lg._isaddonup(GP_PARENT)	then					
	    o_com:Stop()                                    	
		o_com = nil 
		if b_call == nil then								
			m_lg.initcomm(t_plugin)
		end 	
	end
end

-----------------------------------------------------------------------------------------------
-- all plugin communicate with gear in this function
function Gear_Durability:ON_GEAR_PLUGIN(sAction, tData)
	
    ----------------------------------------------------
	-- answer come from gear, the gear version, gear is up 
	if sAction == "G_VER" and tData.owner == GP_NAME then
		if b_call ~= nil then return end
		b_call = true
		self:GD_Event(t_plugin.on) 
		if t_plugin.on then
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			o_check  = ApolloTimer.Create(0.1, true, "_Check", self) 							    
		end	
	end
	
	----------------------------------------------------	
	-- answer of gear from 'G_GET_GEAR' request, the gear array updated
	if sAction == "G_GEAR" then
		t_lastgear = tData
	end
	
	----------------------------------------------------
	-- fired by 'gear' after profile created
	if sAction == "G_CREATE" then
		if t_plugin.on then
			t_durability[tData] = self:GearDurability(tData) 		
			if t_durability[tData] then 
				self:UpdateUI(tData)
			end	
		end
	end
	
	----------------------------------------------------
	-- fired by 'gear' after replaced/added a item in profile with dialog
	if sAction == "G_UPDATE_PROFILE" then
		if t_plugin.on then
		  	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			t_durability[tData.ngearid] = self:GearDurability(tData.ngearid)
			t_condition_var[5] = {tData.ngearid, tData.slot}
			if f_istrue(5) then
			   	self:UpdateUI(tData.ngearid)
			    local n_choice, b_show = 2, true 
			    t_condition_var[6] = {tData.ngearid, tData.slot} 
			    if not f_istrue(6) then n_choice, b_show = 3, false end  
			    self:Progress_Pixie(tData.ngearid, tData.slot, n_choice, b_show) 
			end	
		end
	end
	
	----------------------------------------------------	
	-- fired by 'gear' after a item is removed from a profile
	if sAction == "G_DELETE_SLOT" then
		local bUpdate = true
		for _=1, #t_slotnotallowed do	
			if tData.slot == t_slotnotallowed[_] then 
			  	bUpdate = false
				break 
			end
		end
	   	if bUpdate then
		    self:UpdateUI(tData.ngearid)
			self:Progress_Pixie(tData.ngearid, tData.slot, 3, false)
		end
	end
	
	----------------------------------------------------
    -- answer come from gear, the setting plugin are updated, if this information is for me go next
	if sAction == "G_SETTING" and tData.owner == GP_NAME then
		if tData.option == 1 then 
			t_plugin.setting[1][tData.option].tValue.last = tData.last
		else 
			t_plugin.setting[1][tData.option].bActived = tData.actived
		end
		if tData.option <= 3 then self:GD_UpdateAllProfile() end  
		if tData.option == 4 then self:GD_UpdateAllProgress() end 
	end
    
	----------------------------------------------------	
	-- action request come from gear, the plugin are enable or disable, if this information is for me go next
	if sAction == "G_ON" and tData.owner == GP_NAME then
		t_plugin.on = tData.on 
		self:GD_Event(t_plugin.on) 
		if t_plugin.on then
			Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
			o_check  = ApolloTimer.Create(0.1, true, "_Check", self) 
		else
			self:GD_UpdateAllProgress()
		end	
	end
		
	----------------------------------------------------		
	-- answer come from gear, the setting plugin update, if this information is for me go next
	if sAction == "G_UI_ACTION" and tData.owner == GP_NAME then
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GET_GEAR", nil)
	end
	
	----------------------------------------------------
	-- fired by 'gear', after created a modal/non modal window and show
	if sAction == "G_UI_VISIBLE" then
		self:GD_UpdateAllProfile()
	end
	
	----------------------------------------------------
	-- fired by 'gear', after created a preview item
	if sAction == "G_PREVIEW_ITEM" then
	   	t_condition_var[5] = {tData.ngearid, tData.slot}
		if f_istrue(5) then
		    local b_doshow = nil
		    if t_durability[tData.ngearid][tData.slot].family == 26 then b_doshow = false end
		    self:Progress_Pixie(tData.ngearid, tData.slot, 1, t_plugin.setting[1][4].bActived and t_plugin.on and b_doshow) -- add progress
		    self:GD_UpdateAllProgress()
        end
	end
end

-----------------------------------------------------------------------------------------------
-- event fired after deleted, moved, added, removed item in inventory
function Gear_Durability:OnUpdateInventory()
	if o_delayed_loc then 
		o_delayed_loc:Stop()
		o_delayed_loc = nil
	end 
	o_delayed_loc  = ApolloTimer.Create(2, false, "f_delayedlocation", self) 	
end

-----------------------------------------------------------------------------------------------
-- update durability after inventory update to get new location for item
function Gear_Durability:f_delayedlocation()
    o_delayed_loc:Stop()
	o_delayed_loc = nil
	self:GD_UpdateAll()
end

-----------------------------------------------------------------------------------------------
-- check durability for all profile
function Gear_Durability:_Check()
   	if f_istrue(1,2,3,4) then
	   	self:GD_UpdateAll()
		o_check:Stop()
		o_check = nil
	end	
end

-----------------------------------------------------------------------------------------------
-- turn on/off event  
function Gear_Durability:GD_Event(bActivate)
	if bActivate then 
		Apollo.RegisterEventHandler("ItemDurabilityUpdate",	"OnItemDurabilityUpdate", self) 
		Apollo.RegisterEventHandler("UpdateInventory", 	"OnUpdateInventory", self)
	else
		Apollo.RemoveEventHandler("ItemDurabilityUpdate", self)
		Apollo.RemoveEventHandler("UpdateInventory", self)
	end
end

-- update durability progress for all profile open 
function Gear_Durability:GD_UpdateAllProgress()
    if self.o_addon == nil then self.o_addon = Apollo.GetAddon(GP_PARENT) end
    if self.o_addon.Gear_Panel == nil then return end
	local tChildren = self.o_addon.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   	for _=1, #tChildren do
		local bChecked = tChildren[_]:FindChild("Preview_Btn"):IsChecked()
       	if bChecked then 
			local nGearId = tChildren[_]:GetData()
			local tChildrenItem = tChildren[_]:FindChild("Item_Frame"):GetChildren()
			for _=1, #tChildrenItem do
               	local n_slot = tChildrenItem[_]:GetData().slot
 		    	t_condition_var[5] = {nGearId, n_slot}
				t_condition_var[6] = {nGearId, n_slot}
				if f_istrue(5,6) then
					if t_plugin.on == true and t_plugin.setting[1][4].bActived == true then
						self:Progress_Pixie(nGearId, n_slot, 2, true)
					end
					if t_plugin.on == false or t_plugin.setting[1][4].bActived == false then
						self:Progress_Pixie(nGearId, n_slot, 3, false)
					end
				end	
			end
		end
    end
	self.o_addon = nil
end

local t_pixie =
{
	[2] = 
	 {
  		strSprite = "CRB_Basekit:kitIProgBar_Simple_Base", 
		cr = {a=1.0,r=1,g=1,b=1},
		loc = {
    			fPoints = {0,0,0,0},
    			nOffsets = {0,35,50,50},
  	  		  },
  	 },
	 
	[3] =
	{
		strSprite = "BasicSprites:WhiteFill",
    	cr = {a=1.0,r=0,g=0,b=0},
		loc = {
    			fPoints = {0,0,0,0},
    			nOffsets = {6,41,43,45},
  	  		  },
  	 },	
		
	[4] =
	{
		strSprite = "BasicSprites:WhiteFill",
		cr = t_color.progress.p100,
		loc = {
				fPoints = {0,0,0,0},
				nOffsets = {6,41,43,45},
	  		  },
	 },	
}

-----------------------------------------------------------------------------------------------
-- set progress size/color
local function f_progress_size(n_gearid, n_slot)
    local n_size = 44 
    local n_dura = math.floor((t_durability[n_gearid][n_slot].durability / t_durability[n_gearid][n_slot].durabilitymax * 100) + 0.5)
    local n_sizep = math.floor((n_size / 100 * n_dura) + 0.5)
    local s_color
    if n_dura <= 10 then s_color =  t_color.progress.p10
    elseif n_dura <= 25 then s_color = t_color.progress.p25
    elseif n_dura <= 50 then s_color = t_color.progress.p50
    else s_color = t_color.progress.p100 
	end
   	return n_sizep, s_color
end 

-----------------------------------------------------------------------------------------------
-- set durability progress to item control 
function Gear_Durability:Progress_Pixie(nGearId, nSlot, nAction, bShow)
    local t_pix = m_lg.DeepCopy(t_pixie)
    local t_action =
    {
		[1] = function(o,i) 
						o:AddPixie(t_pix[i])        		     
			  end,
		[2] = function(o,i) 
						o:UpdatePixie(i,t_pix[i])        	    
			  end,
		[3] = function(o,i) 
						o:UpdatePixie(i,t_pix[i])        	   
			  end,
    }
  	if self.o_addon == nil then self.o_addon = Apollo.GetAddon(GP_PARENT) end
	if self.o_addon.Gear_Panel == nil then return end
	local s_name = tostring(nGearId) .."_".. tostring(nSlot)
	local o_control = self.o_addon.Gear_Panel:FindChild("gear_" .. nGearId):FindChild(s_name)
	 
	if o_control == nil then return end
	if o_control:GetPixieInfo(2) == nil then nAction = 1 end
	
	if nAction <=2 then t_pix[4].loc.nOffsets[3], t_pix[4].cr = f_progress_size(nGearId, nSlot) end	
	for _=2, 4 do
	    if bShow == false then t_pix[_].strSprite = "" end
		t_action[nAction](o_control, _)
	end
end 

-----------------------------------------------------------------------------------------------
-- get all durability already find and recreate tsaved with new option selected/unselect to update tooltips 
function Gear_Durability:GD_UpdateAllProfile()
   	if m_lg.TableLength(t_lastgear) == 0 then return end
    for nGearId, pGearId in pairs(t_lastgear) do
	   	if t_durability[nGearId] then self:UpdateUI(nGearId) end	
	end
end 

-----------------------------------------------------------------------------------------------
-- get durability for all profile
function Gear_Durability:GD_UpdateAll()
   	if m_lg.TableLength(t_lastgear) == 0 then return end
    for nGearId, pGearId in pairs(t_lastgear) do
	    t_durability[nGearId] = self:GearDurability(nGearId) 		
		if t_durability[nGearId] then self:UpdateUI(nGearId) end		
	end
	self:GD_UpdateAllProgress()
end 

-----------------------------------------------------------------------------------------------
-- update 'gear' ui profile setting status button (saved contains all save)
function Gear_Durability:UpdateUI(nGearId)
   	local tData = { owner = GP_NAME, uiid = 1, ngearid = nGearId, custom = self:SetAlarmColor(nGearId), saved = self:Update_tSaved(nGearId),}
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SET_UI_SETTING", tData)	
end

-----------------------------------------------------------------------------------------------
-- set durability alarm color
function Gear_Durability:SetAlarmColor(nGearId)
    local tCcolor = {color = t_color.alarm.normal, opacity = 0.5}
   	for nSlot, pCurrent in pairs(t_durability[nGearId]) do
	    if t_lastgear[nGearId][nSlot] and t_durability[nGearId][nSlot].family ~= 26 then
			local nDura = math.floor((t_durability[nGearId][nSlot].durability / t_durability[nGearId][nSlot].durabilitymax * 100) + 0.5)
			if nDura <= math.floor(t_plugin.setting[1][1].tValue.last) then tCcolor = {color = t_color.alarm.fired, opacity = 0.8} break end
		end
	end
	return tCcolor
end

-----------------------------------------------------------------------------------------------
-- create array to export to 'gear'
function Gear_Durability:Update_tSaved(nGearId)
  	if m_lg.TableLength(t_lastgear) == 0 then return end
	if m_lg.TableLength(t_lastgear[nGearId]) == 0 then return end
	t_savedexp[nGearId] = {root = "", target = {}}
	local nId = t_savedexp[nGearId].target
	for nSlot, pCurrent in pairs(t_durability[nGearId]) do
	    if t_lastgear[nGearId][nSlot] then
			if  t_durability[nGearId][nSlot].family ~= 26 then
				local sDurability = tostring(t_durability[nGearId][nSlot].durability .. "/" .. t_durability[nGearId][nSlot].durabilitymax)
				if t_plugin.setting[1][2].bActived then
					sDurability = tostring(math.floor((t_durability[nGearId][nSlot].durability / t_durability[nGearId][nSlot].durabilitymax * 100) + 0.5)) .. " %"
				end 			
				local sLocation = ""
				if t_plugin.setting[1][3].bActived then 
					sLocation = String_GetWeaselString(Apollo.GetString("CRB_Brackets"), " " .. m_L["GP_LOC_" .. tostring(t_durability[nGearId][nSlot].location) .. ""] .. " ")
				end
				local sSlotName = t_durability[nGearId][nSlot].slotname
				t_savedexp[nGearId].target[#nId+1] = sDurability .. " : " .. sSlotName .. " " .. sLocation
			end	
		end
	end  
	if #t_savedexp[nGearId].target == 0 then return nil end
	t_savedexp[nGearId].target[#nId+1] = "<P></P>" .. m_L["GP_FIRED"] .. tostring(math.floor(t_plugin.setting[1][1].tValue.last)) .." %"
	return t_savedexp
end

-----------------------------------------------------------------------------------------------
-- event fired when a equipped item durability change (repaired or damaged in/after combat or death)
function Gear_Durability:OnItemDurabilityUpdate(itemUpdated, nPreviousDurability)
    t_tmpdura[#t_tmpdura+1] = itemUpdated:GetChatLinkString()
    if o_delayed_dura then  
		o_delayed_dura:Stop()
		o_delayed_dura = nil
	end
	o_delayed_dura  = ApolloTimer.Create(2, true, "f_delayeddurability", self)
end

-----------------------------------------------------------------------------------------------
-- update durability after item durability event to get new durability for item
function Gear_Durability:f_delayeddurability()
    local o_unit = GameLib:GetPlayerUnit()	
	if o_unit == nil or o_unit:IsInCombat() then
       	return
	end
	o_delayed_dura:Stop()
	o_delayed_dura = nil
	for _=1, #t_tmpdura do
	    local t_other = m_lg._GetGearParent(t_tmpdura[_], t_lastgear) 
		for _=1, #t_other do
			local n_gearid = t_other[_].ngearid
			t_durability[n_gearid] = self:GearDurability(n_gearid) 
			self:UpdateUI(n_gearid)
		end 
	end
	self:GD_UpdateAllProgress()
	t_tmpdura = {}
end

-----------------------------------------------------------------------------------------------
-- get durability for a specific profile, return array (nslot {slotname, durability number, durablity max, location number})
function Gear_Durability:GearDurability(nGearId)
   	if m_lg.TableLength(t_lastgear[nGearId]) == 0 then return end
  	local tLastGearTmp = m_lg.DeepCopy(t_lastgear)
	for _=1, #t_slotnotallowed do	
		tLastGearTmp[nGearId][t_slotnotallowed[_]] = nil
	end
	local tDura = {}
	for nSlot, sItemLink in pairs(tLastGearTmp[nGearId]) do
		if tonumber(nSlot) ~= nil then	
	    	local tItemFind = m_lg._FindItem(sItemLink)
	       	if tItemFind.find >=1 then 
				tDura[nSlot] = { family = tItemFind.item:GetItemFamily(), slotname = tItemFind.item:GetSlotName(), durability = tItemFind.item:GetDurability(), durabilitymax = tItemFind.item:GetMaxDurability(), location = tItemFind.find }
			end
		end
	end
    return tDura
end

-----------------------------------------------------------------------------------------------
-- save
function Gear_Durability:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
	local tData = { }
	      tData.config = {
	                            ver = GP_VER,
								 on = t_plugin.on,
						      alarm = t_plugin.setting[1][1].tValue.last or nil, 
						    percent = t_plugin.setting[1][2].bActived or nil, 	
						   location = t_plugin.setting[1][3].bActived or nil, 	
						   progress = t_plugin.setting[1][4].bActived or nil, 	
						 }
	return tData
end 

-----------------------------------------------------------------------------------------------
-- restore
function Gear_Durability:OnRestore(eLevel,tData) 
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.config.on ~= nil then t_plugin.on = tData.config.on end
	t_plugin.setting[1][1].tValue.last = tData.config.alarm or t_sett_default[1].init
	t_plugin.setting[1][2].bActived = tData.config.percent or t_sett_default[2]
	t_plugin.setting[1][3].bActived = tData.config.location or t_sett_default[3]
	t_plugin.setting[1][4].bActived = tData.config.progress or t_sett_default[4]
end 

-----------------------------------------------------------------------------------------------
-- gear_durability instance
local Gear_DurabilityInst = Gear_Durability:new()
Gear_DurabilityInst:Init()
