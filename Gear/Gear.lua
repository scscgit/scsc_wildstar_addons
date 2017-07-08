-----------------------------------------------------------------------------------------------
-- 'Gear' v2.5.0 [21/03/2017] 
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Item"
require "Apollo"
require "GameLib"
require "MacrosLib"

-----------------------------------------------------------------------------------------------
-- Gear Module Definition
local Gear = {} 

-----------------------------------------------------------------------------------------------
-- module
local m_L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear", true) 
local m_lg = Apollo.GetPackage("Lib:LibGear-1.0").tPackage						  	

-----------------------------------------------------------------------------------------------
-- local function
local _FindItem			= m_lg._FindItem
local _SearchIn			= m_lg._SearchIn
local _TableLengthBoth	= m_lg.TableLengthBoth
local _TableLength		= m_lg.TableLength
local _EquipFromBag		= m_lg._EquipFromBag
local _CheckEquipped	= m_lg._CheckEquipped
local _GetAllEquipped	= m_lg._GetAllEquipped
local _EquipBagItem		= GameLib.EquipBagItem
local _LoadForm			= Apollo.LoadForm

-----------------------------------------------------------------------------------------------
-- constant
local tVer = { major = 2, minor = 5, patch = 0, } 
local G_VER = string.format("%d.%d.%d", tVer.major, tVer.minor, tVer.patch)
local G_NAME = "Gear"

-----------------------------------------------------------------------------------------------
-- local
local t_gear = {gear={}} 
local t_plugin = {} 	 
local t_uisetting = {} 	 
local t_settings = {} 	 
local n_zorder = 0 		 
local o_delayed          
local xmlDoc
 
local t_itemslot = 
{
	[GameLib.CodeEnumEquippedItems.WeaponPrimary]		= { bInSlot = false, sToolTip = Apollo.GetString("Character_WeaponEmpty"),  	sIcon = "NewSprite:Weapon_Hands",				},					 
	[GameLib.CodeEnumEquippedItems.Shields]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ShieldEmpty"),  	sIcon = "NewSprite:Shield_Weapon_attachment", 	},					 
	[GameLib.CodeEnumEquippedItems.Head]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_HeadEmpty"),  		sIcon = "NewSprite:Head",              		    },	
	[GameLib.CodeEnumEquippedItems.Shoulder]			= { bInSlot = false, sToolTip = Apollo.GetString("Character_ShoulderEmpty"),  	sIcon = "NewSprite:Shoulders",          		},	
	[GameLib.CodeEnumEquippedItems.Chest]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ChestEmpty"),  		sIcon = "NewSprite:Chest",             		    },	
	[GameLib.CodeEnumEquippedItems.Hands]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_HandsEmpty"),  		sIcon = "NewSprite:Weapon_Hands",       		},	
	[GameLib.CodeEnumEquippedItems.Legs]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_LegsEmpty"),  		sIcon = "NewSprite:Legs", 		   		        },	
	[GameLib.CodeEnumEquippedItems.Feet]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_FeetEmpty"),  		sIcon = "NewSprite:Feet",              		    },	
	[GameLib.CodeEnumEquippedItems.WeaponAttachment]	= { bInSlot = false, sToolTip = Apollo.GetString("Character_AttachmentEmpty"),	sIcon = "NewSprite:Shield_Weapon_attachment",   },		
	[GameLib.CodeEnumEquippedItems.System]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_SupportEmpty"),  	sIcon = "NewSprite:Support",           		    },	
	[GameLib.CodeEnumEquippedItems.Gadget]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_GadgetEmpty"),  	sIcon = "NewSprite:Gadget",            		    },	
	[GameLib.CodeEnumEquippedItems.Implant]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ImplantEmpty"),  	sIcon = "NewSprite:Implant", 		   		    },			
}
		
local t_size = { 	     
				modal = {   
						anchor = { l = 0, t = 0, r = 0, b = 0,},	
						   min = { width = 0, height = 0,}, 
						   max = { width = 430, height = 0,},
						},
			 settings = { 
						anchor = { l = 0, t = 0, r = 0, b = 0,},
						   min = { width = 0, height = 0,}, 
						   max = { width = 430, height = 0,},
						},
				}						
			
local t_color = { 		  
					plugin      = { ["true"] = "xkcdBabyBlue",  ["false"] = "xkcdBattleshipGrey",},  
					plugin_icon = { ["true"] = "xkcdAquaBlue",  ["false"] = "xkcdBattleshipGrey",},  
					ui_selected = { ["true"] = 0.8, ["false"] = 0.5 , }, 							 
					ui_color    = { ["true"] = "xkcdBoringGreen", ["false"] = "xkcdAquaBlue", }, 	
				}				
								
local t_quality = { 	  
                  	[Item.CodeEnumItemQuality.Inferior]		= "ItemQuality_Inferior",
					[Item.CodeEnumItemQuality.Average]		= "ItemQuality_Average",
					[Item.CodeEnumItemQuality.Good] 		= "ItemQuality_Good",
					[Item.CodeEnumItemQuality.Excellent]	= "ItemQuality_Excellent",
					[Item.CodeEnumItemQuality.Superb] 		= "ItemQuality_Superb",
					[Item.CodeEnumItemQuality.Legendary]	= "ItemQuality_Legendary",
					[Item.CodeEnumItemQuality.Artifact]	 	= "ItemQuality_Artifact",
	             }
							
-----------------------------------------------------------------------------------------------
-- new instance
function Gear:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

-----------------------------------------------------------------------------------------------
-- init instance
function Gear:Init()
	Apollo.RegisterAddon(self, true, "Gear", nil)
end

-----------------------------------------------------------------------------------------------
-- onload
function Gear:OnLoad()
 	Apollo.LoadSprites("resource/NewSprite.xml")
    xmlDoc = XmlDoc.CreateFromFile("Gear.xml")
   	Apollo.RegisterSlashCommand("gear", 							 "OnSlash", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 		 "OnPlayerEquippedItemChanged", self)
	Apollo.RegisterEventHandler("UpdateInventory", 					 "OnUpdateInventory", self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 		 "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("Generic_OnShowGear", 				 "OnShowGear", self)	
   	Apollo.RegisterEventHandler("SpecChanged", 						 "OnSpecChanged", self)
	Apollo.RegisterEventHandler("ChangeWorld", 						 "OnCanEquip", self) 
	Apollo.RegisterEventHandler("PlayerResurrected",                 "OnCanEquip", self)
    Apollo.RegisterEventHandler("UnitEnteredCombat", 				 "OnEnteredCombat", self)
 	Apollo.RegisterEventHandler("Generic_GEAR_UPDATE", 				 "ON_GEAR_UPDATE", self)
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", 				 "ON_GEAR_PLUGIN", self)
	self.bStopEquip 	= true
	self.bLockForUpdate = false
	self.bMenAtWork 	= false
	self.nLASMod 		= 1
	self.bReEquipOld 	= false
	self.bModal 		= true
	self.bCanEquip      = true
end

-----------------------------------------------------------------------------------------------
-- event fired if players enter/leave combat  
function Gear:OnEnteredCombat(unit, bInCombat)
	if unit:IsThePlayer() then
		self.bCanEquip = not bInCombat and not unit:IsDead()
	end
end

-----------------------------------------------------------------------------------------------
-- event fired after changeworld/playerresurrected 
function Gear:OnCanEquip()
	self.bCanEquip = true 
end

-----------------------------------------------------------------------------------------------
-- all plugin communicate with gear in this function
function Gear:ON_GEAR_PLUGIN(sAction, tData)
	if sAction == "G_READY" then
		local tVerToOwner = tVer
		tVerToOwner.owner = tData.name
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_VER", tVerToOwner)
		if tData.setting then
		    t_settings[tData.name] = tData.setting[1]   
			t_settings[tData.name].plugin = tData.name 
			t_settings[tData.name].translatename = tData.setting.name 
			local sIcon = nil
			if tData.icon then sIcon = m_lg._loadicon(tData.name) end
			t_plugin[tData.name] = { ver = tData.version, flavor = tData.flavor, on = tData.on, icon = sIcon}
			if tData.ui_setting then
			    n_zorder = n_zorder + 1
				t_plugin[tData.name].zorder = n_zorder
			end
		end
		if tData.ui_setting then
			t_uisetting[tData.name] = tData.ui_setting
			t_uisetting[tData.name].plugin = tData.name
		end
	end
	
	if sAction == "G_SET_OFF" then
		t_plugin[tData.owner].on = tData.on
		if self.wndOption  then 
			self:SaveSize(self.wndOption, t_size.settings)
			local nVScrollPos = self.wndOption:FindChild("OptionWnd_Frames"):GetVScrollPos() 
			self:ShowSettings() 
			self.wndOption:FindChild("OptionWnd_Frames"):SetVScrollPos(nVScrollPos)
			if t_uisetting[tData.owner] then 
				self:Update_UI_Plugin(tData.owner, 2)
			end
		end
	end	
		
	if sAction == "G_SET_ARRAY" then
		t_gear.gear = tData.gear	
	end	
		
	if sAction == "G_GET_GEAR" then
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", t_gear.gear)
	end	
		
	if sAction == "G_GET_LASTGEAR" then
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_LASTGEAR", { ngearid = self.nGearId })
	end	
		
	if sAction == "G_GET_CHECK_GEAR" then
		_CheckEquipped(self.nGearId, t_gear.gear)
	end	
		
	if sAction == "G_SET_FUNC" then
	   	if t_gear.gear[tData.ngearid] == nil then 
			self:IsGearIdExist()
			tData.ngearid = self.nGearId
		end 
		for _=1,#tData.func do
			if tData.func[_] == "SELECT" and self.bCanEquip then self:ShowSelectGear(tData.ngearid) end
			if tData.func[_] == "EQUIP" and self.bCanEquip then 
				self:IniEquipGear(tData.ngearid, true)
				self.bIsGearSwitch = true
			end
			if tData.func[_] == "LAS" and self.bCanEquip then self:Align_LAS(tData.ngearid) end
			if tData.func[_] == "LASMOD_AUTO" then self:Align_LAS_Mod(tData.lasmod, tData.lock) end
			if tData.func[_] == "SET_UI_TARGET" then 
				Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_REMOVED", nil)
				if tData.uiremoved then 
					self.wndGear, self.Gear_Panel = nil, nil
					self.bModal = true
					return
				else
					if self.wndGear then self.wndGear:Destroy() end	
					self.wndGear, self.Gear_Panel = nil, nil
				end					 
				self.bModal = false
				self:IniWindow(tData.uitarget)
			end
		end
	end	
		
	if sAction == "G_SET_UI_SETTING" then
		if tData.saved == nil then
			t_uisetting[tData.owner][tData.uiid].Saved[tData.ngearid] = nil
		else
			t_uisetting[tData.owner][tData.uiid].Saved = tData.saved	
		end
		if self.Gear_Panel == nil then return end
		local sPluginBtnName = tData.owner .. "_" .. tData.uiid
		local nGearId = tData.ngearid
		local cButton = self.Gear_Panel:FindChild("gear_" .. nGearId):FindChild(sPluginBtnName)
		if cButton == nil then return end	
		local bSelected = nil
		if tData.saved and tData.saved[nGearId] then
        	bSelected = true
		end
		if tData.custom then
			cButton:GetData().custom = tData.custom
		end
		self:Set_UI_ColorStatus(cButton, bSelected, tData.custom)
	end
end

-----------------------------------------------------------------------------------------------
-- set color/status for profile plugin 
function Gear:Set_UI_ColorStatus(cButton, bSelected, tCustom)
	local sPlugin = cButton:GetData().owner	         
	local   nUIId = cButton:GetData().uiid		     
	local nGearId = cButton:GetData().ngearid         
	local bStatus = cButton:GetData().status         
	local sStatusText
   	local sColor = t_color.ui_color[tostring(bSelected or false)] 
	local nOpacity = t_color.ui_selected[tostring(bSelected or false)] 
   	if tCustom then 
		sColor = tCustom.color
		nOpacity = tCustom.opacity
	end
	cButton:SetBGColor(sColor)
	cButton:SetOpacity(nOpacity,60) 
	if bStatus then
		if bSelected then 
			sStatusText = t_uisetting[sPlugin][nUIId].Saved[nGearId].root
		end	
		cButton:SetText(sStatusText or "")
	end
end

-----------------------------------------------------------------------------------------------
-- align lasmod
function Gear:Align_LAS_Mod(nLasMod, bLock)
	self.nLASMod = nLasMod
	self.bLock = bLock
	if self.Gear_Panel then 
		local cControl = self.Gear_Panel:FindChild("LasMod_Btn")
		cControl:SetData(nLasMod - 1)
		self:OnLasModClick( nil, cControl, nil )
		cControl:Enable(not bLock)
	end
end

-----------------------------------------------------------------------------------------------
-- show settings
function Gear:OnConfigure()
	self:ShowSettings()
end

-----------------------------------------------------------------------------------------------
-- create settings window
function Gear:ShowSettings()
	if self.wndOption then self.wndOption:Destroy() end
	self.wndOption = _LoadForm(xmlDoc, "OptionWnd", nil, self)
	self.wndOption:FindChild("TitleWnd"):SetText("'Gear' " .. m_L["G_O_SETTINGS"])
	for _, peCurrent in pairs(t_settings) do
		local wndFrame_O = _LoadForm(xmlDoc, "Frame_wnd", self.wndOption:FindChild("OptionWnd_Frames"), self)
		wndFrame_O:FindChild("FrameTitle_wnd"):SetText(peCurrent.translatename)
		local sOwner = nil
		if peCurrent.plugin then
			local wndPlugin = _LoadForm(xmlDoc, "Plugin_wnd", wndFrame_O:FindChild("FrameTitle_wnd"), self)
			wndPlugin:SetSprite("PlayerPathContent_TEMP:spr_PathIconExpDefault")
			sOwner = peCurrent.plugin
			wndPlugin:SetData({ name = sOwner,})
			if t_plugin[sOwner].icon then
				local wndPlugin = _LoadForm(xmlDoc, "Plugin_Icon_wnd", wndFrame_O:FindChild("FrameTitle_wnd"), self)
				wndPlugin:SetSprite(t_plugin[sOwner].icon)
				wndPlugin:SetBGColor(t_color.plugin_icon[tostring(t_plugin[sOwner].on)])
				wndPlugin:SetOpacity(0.5,25)
			end			
			wndFrame_O:FindChild("FrameTitle_wnd"):SetTextColor(t_color.plugin[tostring(t_plugin[sOwner].on)])
		end
		local sIndex = _
		local nHeightBtn = 0
		local tControlType = {
								["toggle"] = "Option_toggle_Btn",
					  		      ["push"] = "Option_push_Btn",  
					            ["slider"] = "Option_slider_Btn", 
				             }
		for _, peOption in pairs(peCurrent) do
			if tonumber(_) then
				local btnOption =  _LoadForm(xmlDoc, tControlType[peOption.sType] , wndFrame_O, self)
				local sAppend = ""
				if peOption.sType == "toggle" then
					btnOption:SetCheck(peOption.bActived)
				elseif peOption.sType == "push" then
									
				elseif peOption.sType == "slider" then
				 	btnOption:FindChild("Slider_Sb"):SetMinMax(peOption.tValue.min, peOption.tValue.max, peOption.tValue.tick )
					btnOption:FindChild("Slider_Sb"):SetValue(peOption.tValue.last)	
					sAppend = " " .. string.format("%.f", math.floor(peOption.tValue.last)).." %"
				end
				nHeightBtn = nHeightBtn + btnOption:GetHeight()		
				btnOption:SetText(peOption.sDetail .. sAppend)
				btnOption:SetData({ sIdx = sIndex, nOption = _, plugin = sOwner,})
				if peCurrent.plugin then 
					btnOption:Enable(t_plugin[sOwner].on) 
					btnOption:SetTextColor(t_color.plugin[tostring(t_plugin[sOwner].on)])
				end
			end
		end
		wndFrame_O:ArrangeChildrenVert()
		if nHeightBtn ~= 0 then
			local l,t,r,b = wndFrame_O:GetAnchorOffsets()
			wndFrame_O:SetAnchorOffsets(l,t,r,b + (nHeightBtn))
		end
	end
	self.wndOption:FindChild("OptionWnd_Frames"):ArrangeChildrenVert()
	self:SetSize(self.wndOption, t_size.settings)
	self.wndOption:SetInterrupt(true)
	self.wndOption:Show(true, true)
end

-----------------------------------------------------------------------------------------------
-- settings control 'toggle' check/uncheck
function Gear:OnOptionClick( wndHandler, wndControl, eMouseButton )
	local nOption = wndControl:GetData().nOption
	local sIndex = wndControl:GetData().sIdx
	local sOwner = wndControl:GetData().plugin
	t_settings[sIndex][nOption].bActived = wndControl:IsChecked()
	if sOwner then
		local tSetting = { owner = sOwner, option = nOption, actived = t_settings[sIndex][nOption].bActived }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SETTING", tSetting)
	end
end

-----------------------------------------------------------------------------------------------
-- settings control 'slider' changed
function Gear:OnOptionSlide( wndHandler, wndControl, fNewValue, fOldValue )
	local tData = wndControl:GetParent():GetData()
	t_settings[tData.sIdx][tData.nOption].tValue.last = fNewValue
	local sDetail = t_settings[tData.sIdx][tData.nOption].sDetail
	wndControl:GetParent():SetText(sDetail .. " " .. string.format("%.f", math.floor(fNewValue)).." %")
	if tData.plugin then
		local tSetting = { owner = tData.plugin, option = tData.nOption, last = fNewValue}
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SETTING", tSetting)
	end
end

-----------------------------------------------------------------------------------------------
-- close settings/modal window
function Gear:OnOptionClose( wndHandler, wndControl, eMouseButton )
	if self.wndGear  == nil or self.wndOption == nil then 
		wndControl:GetParent():SetInterrupt(false)
	end	
	if wndControl:GetData() == "modal" then
		self:SaveSize(self.wndGear, t_size.modal)
		self.wndGear, self.Gear_Panel = nil, nil
	else
		self:SaveSize(self.wndOption, t_size.settings)
		self.wndOption = nil	
	end
	wndControl:GetParent():Destroy()
end

-----------------------------------------------------------------------------------------------
-- create all plugins for a profile
function Gear:Set_UI_Settings(nGearId, wndControl)
	for sPlugin, pOption in pairs(t_uisetting) do
	   if t_plugin[sPlugin].on then self:Update_UI_Add(nGearId, wndControl, sPlugin) end 
	end
	wndControl:FindChild("Plugin_Frame"):ArrangeChildrenHorz(0, function(a,b) return (a:GetData().zorder < b:GetData().zorder) end) 
end

-----------------------------------------------------------------------------------------------
-- create plugin for a profile
function Gear:Update_UI_Add(nGearId, wndControl, sPlugin)
    local tControlType = {
							["toggle_unique"] = "UI_toggle_unique_Btn",
							["toggle"] 		  = "UI_toggle_Btn",
							["push"]          = "UI_push_Btn",
							["none"]          = "UI_none_Btn",
							["action"]        = "UI_action_Btn",
							["list"]          = "UI_list_Btn",
	    				 }
	local wndIcon_Frame = wndControl:FindChild("Plugin_Frame")
	local sControlToUse = tControlType[t_uisetting[sPlugin][1].sType]
	local UI_Btn = _LoadForm(xmlDoc, sControlToUse, wndIcon_Frame, self)
	UI_Btn:ChangeArt(t_plugin[sPlugin].icon)
	UI_Btn:SetOpacity(t_color.ui_selected["false"], 25)
	UI_Btn:SetBGColor(t_color.ui_color["false"])
	local sUIId   = 1 					                 
	local sOwner  = sPlugin                    	      
	local sType   = t_uisetting[sPlugin][1].sType         
	local sStatus = t_uisetting[sPlugin][1].sStatus      
	local nZorder = t_plugin[sPlugin].zorder              
	local tSaved  = t_uisetting[sPlugin].Saved           
	local tData   = { uiid = sUIId ,type = sType, status = sStatus, zorder = nZorder, ngearid = nGearId, owner = sOwner,}
	UI_Btn:SetData(tData)
	UI_Btn:SetName(sOwner .. "_" .. sUIId )
end

-----------------------------------------------------------------------------------------------
-- click on profile item or profile name
function Gear:OnProfileClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
  	local tData = { mouse = eMouseButton, ocontrol = wndControl, tgear = t_gear.gear, titemslot = t_itemslot } 
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_ITEM_CLICK", tData)
end

-----------------------------------------------------------------------------------------------
-- return array of all profile for partner addon
function Gear:GetGear()
	if _TableLength(t_gear.gear) == 0 then return nil end
	local tGearUpdate = {}
	for _, pGear in pairs(t_gear.gear) do
		tGearUpdate[_] = { name = pGear.name }
	end
	return tGearUpdate
end

-----------------------------------------------------------------------------------------------
-- all event from partner addon come here
function Gear:ON_GEAR_UPDATE(sAction, nGearId, tGearUpdate, nLasMod, tError)
	if sAction == "G_EQUIP" then 
		if _TableLength(t_gear.gear) ~= 0 and t_gear.gear[nGearId] and self.bCanEquip then 
		   	self:IniEquipGear(nGearId, false)
			self.bIsGearSwitch = true
			self:Align_LAS_Mod(nLasMod, false)
			if nLasMod and nLasMod ~= 3 then self:Align_LAS(nGearId) end
		end
	end

	if sAction == "G_GETGEAR" then 
		local tGearUpdate = self:GetGear()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_GEAR", self.nGearId, tGearUpdate, nil, nil)
	end
		
	if sAction == "G_AFTER_EQUIP" then 
	    if tError == nil then 
		
		else 
			for nSlot, bEquipped in pairs(tError) do
				if not bEquipped then 
				
				else
					
				end 
			end
			local wnd = Apollo.FindWindowByName("gear_" .. nGearId)
			if wnd then 
				wnd:FindChild("GearName_Btn"):SetTextColor("red")
			end
		end
	end
end

-----------------------------------------------------------------------------------------------
-- event fired after las changed
function Gear:OnSpecChanged(newSpecIndex, specError)
   if self.bIsGearSwitch or self.nLASMod >= 2 then self.bIsGearSwitch = false return end
   for _, oGear in pairs(t_gear.gear) do
		if oGear.las[1] and oGear.las[1] == newSpecIndex then 
			self:IniEquipGear(_, true)
			return 
		end
	end
end

-----------------------------------------------------------------------------------------------
-- create las popup menu
function Gear:ShowMenu(nGearId, nCount, nTarget)
	local nXYmouse = Apollo.GetMouse()
    local nLeft = nXYmouse.x
 	local nTop = nXYmouse.y
    if self.wndMenu then self.wndMenu:Destroy() end
	self.wndMenu = _LoadForm(xmlDoc, "LAS_wnd", nil, self)
	local nCount = nCount
	for nId =1, nCount + 1 do
		self.wndBtnMenu = _LoadForm(xmlDoc, "LAS_Btn", self.wndMenu:FindChild("LAS_Frame"), self)
		if nId == nCount + 1 then nId = 0 end
		local tData = { gearid = nGearId, id = nId, target = nTarget}				
		self.wndBtnMenu:SetData(tData)
		if nId ~= 0 then self.wndBtnMenu:SetText(nId) end
	end
	self.wndMenu:FindChild("LAS_Frame"):ArrangeChildrenHorz(0)
	local nHeightSize = self.wndMenu:GetHeight()
	local nBtnMenuSize = self.wndBtnMenu:GetWidth() 
	local nWidthSize = nBtnMenuSize * (nCount + 1)
	self.wndMenu:Move(nLeft, nTop-38, nWidthSize + 55, nHeightSize)
	self.wndMenu:Show(true, true)
end

-----------------------------------------------------------------------------------------------
-- destroy las popup menu
function Gear:DestroyMenu()
    if Apollo.FindWindowByName("LAS_wnd") then 
    	self.wndMenu:DestroyChildren()		
		self.wndMenu:Destroy()
	end
end

-----------------------------------------------------------------------------------------------
-- on click las button
function Gear:OnSelect_LASCOS( wndHandler, wndControl, eMouseButton )
    local nGearId = wndControl:GetData().gearid
    local nId = wndControl:GetData().id
    local nTarget = wndControl:GetData().target
    if nTarget == 1 then self:Modif_LAS(nGearId, nId) end
end

-----------------------------------------------------------------------------------------------
-- Modif_LAS
function Gear:Modif_LAS(nGearId, nId)
    local nIdMod = self.nLASMod
    local nGearId = nGearId
    local nLasId = nId
   	local nGearModif = self:LinkGear_LAS(nGearId, nLasId, nIdMod)
	if nLasId == 0 then nLasId = "" end
	self.cLast:SetText(nLasId) 
	self:Align_LAS(nGearId)
	self:DestroyMenu()
	if nGearModif == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
    for _=1, #tChildren do
		if tChildren[_]:GetData() == nGearModif then tChildren[_]:FindChild("Macro_Btn"):SetText("") return end
	end
end

-----------------------------------------------------------------------------------------------
-- use las
function Gear:Align_LAS(nGearId)
    local nIdMod = self.nLASMod
	if nIdMod == 3 then return end
	local nSpeActual = AbilityBook.GetCurrentSpec() 
	local nLasGear = t_gear.gear[nGearId].las[nIdMod]
	if nLasGear == nil then return end
	if nSpeActual ~= nLasGear then
	    self.bIsGearSwitch = true 
		AbilityBook.SetCurrentSpec(nLasGear)
	end
end

-----------------------------------------------------------------------------------------------
-- link las/profile
function Gear:LinkGear_LAS(nGearId, nLasId, nIdMod)
   if nIdMod == 3 then return end
   if nLasId == 0 then t_gear.gear[nGearId].las[nIdMod] = nil return end
   t_gear.gear[nGearId].las[nIdMod] = nLasId
   if nIdMod == 1 then
   		for _, oGear in pairs(t_gear.gear) do
			if _ ~= nGearId and oGear.las[nIdMod] and oGear.las[nIdMod] == nLasId then 
				t_gear.gear[_].las[nIdMod] = nil
				return _
			end
		end
	end	
end

-----------------------------------------------------------------------------------------------
-- set las text 
function Gear:UpdateText_LAS(nIdMod)
   local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   for _=1, #tChildren do
		local nGearId = tChildren[_]:GetData()
 		local nLasId = t_gear.gear[nGearId].las[nIdMod]
        if nLasId == nil then nLasId = "" end
		local wndMacro_Btn = tChildren[_]:FindChild("Macro_Btn")
        wndMacro_Btn:SetText(nLasId)  
   end 
end

-----------------------------------------------------------------------------------------------
-- fired after interface menu list loaded
function Gear:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", G_NAME, {"Generic_OnShowGear", "", "BK3:sprHolo_Icon_Costume"})
	self:UpdateInterfaceMenuAlerts()
end

-----------------------------------------------------------------------------------------------
-- OnShowGear
function Gear:OnShowGear()
	self:ShowSelectGear(self.nGearId)
	if self.bModal then 
		local oWndTarget = _LoadForm(xmlDoc, "OptionWnd", nil, self)
		self:IniWindow(oWndTarget)
	else
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_SHOW", nil)
	end
end

-----------------------------------------------------------------------------------------------
-- UpdateInterfaceMenuAlerts
function Gear:UpdateInterfaceMenuAlerts()
  	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", G_NAME, {nil, "v"..G_VER, nil})
end

-----------------------------------------------------------------------------------------------
-- OnPlayerEquippedItemChanged 
function Gear:OnPlayerEquippedItemChanged(eSlot, itemNew, itemOld)
    if self.bReEquipOld == true then self.bReEquipOld = false return end
	if self.bStopEquip == false and self.nEquippedCount == self.nGearCount then 
		self.bStopEquip = true 
		_CheckEquipped(self.nGearId, t_gear.gear)
	end
    if self.bStopEquip == false then
		self:_EquipGear(self.nGearId)
	end
	if self.bStopEquip == true and not self.bLockForUpdate then
	  	if (itemOld and itemNew == nil) or
		    t_itemslot[eSlot] == nil or
		   (t_gear.gear[self.nGearId] == nil) or	
		    self.nGearId == nil then	
			return
		end	
		self.nSlot = eSlot
		if itemNew then	self.oNewItemLink = itemNew:GetChatLinkString()	end
		if itemOld then	self.oOldItemLink = itemOld:GetChatLinkString()	end
		if itemNew and itemNew:GetChatLinkString() ~= t_gear.gear[self.nGearId][eSlot] or t_gear.gear[self.nGearId][eSlot] == nil then
		    self:_DialogUpdate(self.nGearId, itemOld, itemNew) 
		end
		self:Update_UI_AllPreview()
 	end
end

-----------------------------------------------------------------------------------------------
-- event fired after deleted, moved, added, removed item in inventory
function Gear:OnUpdateInventory()
	if self.bStopEquip == false and self.bMenAtWork == true then 
	    return
	end 
	if o_delayed then 
		o_delayed:Stop()
		o_delayed = nil
	end 
	o_delayed  = ApolloTimer.Create(1, false, "f_delayedpreview", self) 	
end

-----------------------------------------------------------------------------------------------
-- update all preview frame after inventory update
function Gear:f_delayedpreview()
   	o_delayed:Stop()
	o_delayed = nil
	self:Update_UI_AllPreview()
end

-----------------------------------------------------------------------------------------------
-- _DialogUpdate 
function Gear:_DialogUpdate(nGearId, itemOld, itemNew)
	self.UpdateWnd = _LoadForm(xmlDoc, "Dialog_wnd", nil, self)
	local wndInside = _LoadForm(xmlDoc, "Update_wnd", self.UpdateWnd, self)
	self.UpdateWnd:FindChild("CloseButton"):SetData("Update")
	self.UpdateWnd:FindChild("YesButton"):SetText(m_L["G_YES"])
	self.UpdateWnd:FindChild("NoButton"):SetText(m_L["G_NO"])
	local sBy = m_L["G_UPDATE_BY"]
	local sReplace = m_L["G_UPDATE_REPLACE"]
	local ItemOldWnd = self.UpdateWnd:FindChild("Item_Actual"):FindChild("ItemWnd")
	local tData = { }
	local sSprite = nil 
	local bOnlyAdd = nil
	if itemOld == nil then 
	   	if t_gear.gear[nGearId][self.nSlot] then
			local sItemLink = t_gear.gear[nGearId][self.nSlot]
			local oItem = _SearchIn(sItemLink, 1) 
          	if oItem then 
				tData = { item = oItem }
	        	sSprite = oItem:GetIcon()
			elseif oItem == nil then
				tData = { slot = self.nSlot }
				sSprite = "ClientSprites:LootCloseBox_Holo"
        	end 
        else
			bOnlyAdd = true
		end
	end
	if itemOld then 	
		if itemOld:GetChatLinkString() == t_gear.gear[nGearId][self.nSlot] then
			tData = { item = itemOld }
			sSprite = itemOld:GetIcon()
		elseif itemOld:GetChatLinkString() ~= t_gear.gear[nGearId][self.nSlot] then	
			bOnlyAdd = true
		end
    end
	if bOnlyAdd then
		tData = { slot = self.nSlot }
		sSprite = ""
		sReplace = ""
		sBy = m_L["G_UPDATE_ADD"]
	end
	local UpdateReplace = self.UpdateWnd:FindChild("Item_Actual"):FindChild("ItemTxt")
	UpdateReplace:SetText(sReplace)
	ItemOldWnd:SetData(tData)
	ItemOldWnd:FindChild("ItemIcon"):SetSprite(sSprite) 
	local UpdateBy = self.UpdateWnd:FindChild("Item_New"):FindChild("ItemTxt")
    UpdateBy:SetText(sBy)
    local ItemNewWnd = self.UpdateWnd:FindChild("Item_New"):FindChild("ItemWnd")
	local tData = { item = itemNew, compare = false }
	ItemNewWnd:SetData(tData)
	ItemNewWnd:FindChild("ItemIcon"):SetSprite(itemNew:GetIcon()) 
	local sGearName = t_gear.gear[nGearId].name
	self.UpdateWnd:FindChild("SetTargetTxt"):SetTextRaw(m_L["G_UPDATE"] .. "[" .. sGearName .. "]?" )
	if self.Gear_Panel then self.Gear_Panel:Enable(false) end	
	self.bLockForUpdate = true
	self.UpdateWnd:Show(true)
end

-----------------------------------------------------------------------------------------------
-- OnClickUpdate
function Gear:OnClick_Dialog( wndHandler, wndControl, eMouseButton )
	local cSelect = wndControl:GetName()
	if cSelect == "NoButton" or (cSelect == "CloseButton" and  wndControl:GetData() == "Update") then
	    if t_gear.gear[self.nGearId][self.nSlot] and self.oOldItemLink == t_gear.gear[self.nGearId][self.nSlot] then
			local nBagSlot = _EquipFromBag(self.oOldItemLink)
	    	if nBagSlot then
				self.bReEquipOld = true
	            _EquipBagItem(nBagSlot + 1)
			end
	    end
	end
	if cSelect == "YesButton" then
		t_gear.gear[self.nGearId][self.nSlot] = self.oNewItemLink
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", t_gear.gear)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UPDATE_PROFILE", { ngearid = self.nGearId, slot = self.nSlot})
	end
	local n_slot = self.nSlot
	self.nSlot = nil
	self.oNewItemLink = nil
	self.oOldItemLink = nil
	if self.Gear_Panel then self.Gear_Panel:Enable(true) end
	self.bLockForUpdate = false
	if self.UpdateWnd then 
		self.UpdateWnd:Destroy()
		self:Update_UI_PreviewItemSingle(self.nGearId, nil, n_slot)
		self:Update_UI_LockItemFrame()
	end
end

-----------------------------------------------------------------------------------------------
-- UnSelectGear 
function Gear:UnSelectGear()
    if self.bStopEquip == false then self.bStopEquip = true end
    if self.nGearId then self.bPreviousGear = self.nGearId end
    self.nGearId = nil
 	self:ShowSelectGear(nil)	
   	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nil, terror = nil })
end

-----------------------------------------------------------------------------------------------
-- IsGearIdExist 
function Gear:IsGearIdExist()
	if self.nGearId == nil then 
		self.nGearId = self.bPreviousGear
	end
end

-----------------------------------------------------------------------------------------------
-- _SaveAllEquipped 
function Gear:_SaveAllEquipped(tEquipped, nGearId)
 	local bIsNewGear = false
	if nGearId == nil then 		     	
		local nGear = _TableLength(t_gear.gear)  
		for _=1, nGear do  
		    if t_gear.gear[1] == nil then nGearId = 1 
		    else 
				if t_gear.gear[_ + 1] == nil then nGearId = _ + 1 end
			end	
		end
		if nGear == 0 then nGearId = 1 end  
		bIsNewGear = true	
	end	
	t_gear.gear[nGearId] = {} 			 
    t_gear.gear[nGearId] = tEquipped      
    t_gear.gear[nGearId].las = {} 		
    if t_gear.gear[nGearId].macro == nil then
    	t_gear.gear[nGearId].macro = self:_AddMacroToGear(nGearId, nil)
    end
	return nGearId, bIsNewGear 
end

-----------------------------------------------------------------------------------------------
-- _SetGearName 
function Gear:_SetGearName(sNickName, nGearId)
    local sOldName = t_gear.gear[nGearId].name  
	if sNickName == nil then sNickName = m_L["G_TABNAME"] .. " " .. nGearId end
 	sNickName = sNickName:match("^%s*(.-)%s*$") 
	for _,oGear in pairs(t_gear.gear) do
		if oGear.name then		
			local sGearName = oGear.name
	   		local nGearName = string.len(sGearName)
	 		local nLen = string.len(sNickName) 
	    	local nMatchName = string.find(sGearName, sNickName)
	    	if nGearName == nLen and nMatchName then
				sNickName = sOldName
	    	end 
		end
	end
 	t_gear.gear[nGearId].name = sNickName 
	return sNickName	
end

-----------------------------------------------------------------------------------------------
-- _RemoveItem
function Gear:_RemoveItem(nGearId, nSlot)
	if t_gear.gear[nGearId][nSlot] then 
		t_gear.gear[nGearId][nSlot] = nil 
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", t_gear.gear)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_DELETE_SLOT", { ngearid = nGearId, slot = nSlot})
	end
end

-----------------------------------------------------------------------------------------------
-- delete a profile 
function Gear:_DeleteGear(nGearId)
 	if t_gear.gear[nGearId] then 
		t_gear.gear[nGearId] = nil 
	end
	local tGearUpdate = self:GetGear()
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_DELETE", nGearId, tGearUpdate, nil, nil)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_DELETE", nGearId)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", t_gear.gear)
	for _, pOption in pairs(t_uisetting) do
		if t_uisetting[_][1].Saved then
			if tonumber(t_uisetting[_][1].Saved) then
				if t_uisetting[_][1].Saved == nGearId then t_uisetting[_][1].Saved = nil end
			else	
				if t_uisetting[_][1].Saved[nGearId] then t_uisetting[_][1].Saved[nGearId] = nil end
			end
		end 		
	end
end

-----------------------------------------------------------------------------------------------
-- equip a profile 
function Gear:_EquipGear(nGearId)
	self.bStopEquip = true
	local _EFB 	 = _EquipFromBag 
	local _EBI	 = _EquipBagItem
	local _CE	 = _CheckEquipped
	local _tGear = t_gear.gear[nGearId]
    for _, oLink in pairs(_tGear) do
		local nSlot = tonumber(_)
		if nSlot and t_itemslot[nSlot].bInSlot == false then
			local sItemLink = oLink
			local nBagSlot = _EFB(sItemLink)
			t_itemslot[nSlot].bInSlot = true
			self.nEquippedCount = self.nEquippedCount + 1
			if nBagSlot then 
				self.bStopEquip = false
				_EBI(nBagSlot + 1)
				return
			else
				if self.nEquippedCount == self.nGearCount then _CE(nGearId, t_gear.gear) end
			end	 
		end
	end	
end

-----------------------------------------------------------------------------------------------
-- _AddMacroToGear 
function Gear:_AddMacroToGear(nGearId, sNickName)
   if sNickName == nil then sNickName = m_L["G_TABNAME"] .. nGearId end
   local tParam = {
      			     sName = sNickName,
     		       sSprite = "IconSprites:Icon_ItemArmor_Light_Armor_Chest_01",
 	  			     sCmds = "/gear " .. nGearId,
 	 			   bGlobal = false,
      			       nId = MacrosLib.CreateMacro(),
                  } 
	self:_SaveMacro(tParam) 
    return tParam.nId
end

-----------------------------------------------------------------------------------------------
-- _SaveMacro 
function Gear:_SaveMacro(tParam)
    MacrosLib.SetMacroData( tParam.nId, tParam.bGlobal, tParam.sName, tParam.sSprite, tParam.sCmds )
    MacrosLib:SaveMacros()
end

-----------------------------------------------------------------------------------------------
-- _DeleteMacro 
function Gear:_DeleteMacro(nMacroId)
    if nMacroId == nil then return end  
    MacrosLib.DeleteMacro(nMacroId)
 	MacrosLib:SaveMacros()
end

-----------------------------------------------------------------------------------------------
-- _RenameMacro 
function Gear:_RenameMacro(nGearId, nMacroId, sNickName)
    local tMacro = MacrosLib.GetMacro(nMacroId)
   	if tMacro then
    	local tParam = {
						  sName = sNickName,
						sSprite = tMacro.strSprite, 
						  sCmds = tMacro.arCommands[1],
    					bGlobal = tMacro.bIsGlobal,
    						nId = tMacro.nId,
   						}
    	self:_SaveMacro(tParam)
    else
		t_gear.gear[nGearId].macro = self:_AddMacroToGear(nGearId, sNickName)
	end
end

-----------------------------------------------------------------------------------------------
-- Collapse_AllPreview 
function Gear:Collapse_AllPreview(bCheck)
   	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
    for _=1, #tChildren do
        local wnd = tChildren[_]:FindChild("Preview_Btn")
		if bCheck ~= wnd:IsChecked() then 
			wnd:SetCheck(bCheck)
			self:OnCheckPreview( nil, wnd, 2)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- SetPreviewItem 
function Gear:SetPreviewItem(nGearId, wndControl)
    local wndItem_Frame = wndControl:FindChild("Item_Frame")
    for _, oSlot in pairs(t_itemslot) do
		local wndItem = _LoadForm(xmlDoc, "ItemWnd", wndItem_Frame, self)
		local tOptions = {
  							loc = {
    								fPoints = {0,0,1,1},
    								nOffsets = {5,5,-5,-5},
  						  		  },
  						 }
		wndItem:AddPixie(tOptions) 
		self.tData = { slot = _,}
		wndItem:SetData(self.tData)
		wndItem:SetName(tostring(nGearId) .."_".. tostring(_))
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_PREVIEW_ITEM", { ngearid = nGearId, slot = _ }) 
	end	
	wndItem_Frame:ArrangeChildrenTiles()
end

-----------------------------------------------------------------------------------------------
-- Update_UI_AllPreview 
function Gear:Update_UI_AllPreview()
    _CheckEquipped(self.nGearId, t_gear.gear)
    if self.Gear_Panel == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   	for _=1, #tChildren do
		local bChecked = tChildren[_]:FindChild("Preview_Btn"):IsChecked()
       	if bChecked then 
			local nGearId = tChildren[_]:GetData()
 		    local wndControl =  tChildren[_]
			self:Update_UI_PreviewItem(nGearId, wndControl)
		else
			self:CheckMissing(tChildren[_])
		end
    end
end

-- item location with alert level and location color/opacity
local tStatus =  {
					[0] = { level = 3, opacity = 1.0},	
					[1] = { level = 1, opacity = 0.2},	
					[2] = { level = 2, opacity = 0.2},	
					[3] = { level = 1, opacity = 1.0},	
				}

-----------------------------------------------------------------------------------------------
-- Update_UI_PreviewItem (set all icon for each item in preview frame)
function Gear:Update_UI_PreviewItem(nGearId, wndControl)
	self.bMenAtWork = true
	local tChildren = wndControl:FindChild("Item_Frame"):GetChildren()
	local nLevel, nAlert = 1, 1
   	for _=1, #tChildren do
		local nSlot = tChildren[_]:GetData().slot	
		local wndItem = tChildren[_]
		local sSprite = nil
		local nOpacity = nil
		local sQualityColor = "White"
		local sQualityBorder = "BK3:UI_BK3_Holo_InsetSimple"
		if t_gear.gear[nGearId][nSlot] then  
			local sItemLink = t_gear.gear[nGearId][nSlot]
			local tItemFind = _FindItem(sItemLink)
			if tItemFind.find >=1 then 
	        	sSprite = tItemFind.item:GetIcon() 
				sQualityBorder = "BK3:UI_RarityBorder_White"
	           	self.tData = { slot = nSlot, item = tItemFind.item, }
	            sQualityColor = t_quality[tItemFind.item:GetItemQuality()]
			else 
				sSprite = "ClientSprites:LootCloseBox_Holo"
				self.tData = { slot = nSlot,}
			end
			nOpacity = tStatus[tItemFind.find].opacity
            nLevel = tStatus[tItemFind.find].level
		else
			sSprite = t_itemslot[nSlot].sIcon
			self.tData = { slot = nSlot,}
			nOpacity = 0.3
			nLevel = 1
		end
		local tOptions = {
  							strSprite = sSprite,
  							cr = {a=nOpacity,r=1,g=1,b=1},
							loc = {
    								fPoints = {0,0,1,1},
    								nOffsets = {5,5,-5,-5},
  						  		  },
  						 }
		wndItem:UpdatePixie(1, tOptions)
		wndItem:SetData(self.tData)	
		wndItem:SetSprite(sQualityBorder)
		wndItem:SetBGColor(sQualityColor)
		if nLevel >= nAlert then nAlert = nLevel end
	end	
	self:Update_UI_Alert(wndControl, nAlert) 
	wndControl:FindChild("Item_Frame"):ArrangeChildrenTiles()
	self.bMenAtWork = false
end

-----------------------------------------------------------------------------------------------
-- set icon for a removed/updated item in profile
function Gear:Update_UI_PreviewItemSingle(nGearId, wndControl, nSlot)
    if self.Gear_Panel == nil then return end
	local sName = tostring(nGearId) .."_"..tostring(nSlot)
	local wndItem 
	if wndControl == nil then wndItem = self.Gear_Panel:FindChild("gear_" .. nGearId):FindChild(sName)
	else
		wndItem = wndControl:GetParent()
	end
	if wndItem == nil then return end
	local tData = { slot = nSlot,}
	local sSprite = t_itemslot[nSlot].sIcon
	local nOpacity = 0.3
	local sQualityColor = "White"
	local sQualityBorder = "BK3:UI_BK3_Holo_InsetSimple"
	local sItemLink = t_gear.gear[nGearId][nSlot]
	local tItemFind = _FindItem(sItemLink)
	if tItemFind.find >=1 then 
	  	sSprite = tItemFind.item:GetIcon()
		nOpacity = tStatus[tItemFind.find].opacity
 		sQualityBorder = "BK3:UI_RarityBorder_White"
	    tData = { slot = nSlot, item = tItemFind.item, }
	    sQualityColor = t_quality[tItemFind.item:GetItemQuality()]
	end
  	local tOptions = {
						strSprite = sSprite,
						cr = {a=nOpacity,r=1,g=1,b=1},
						loc = {
   								fPoints = {0,0,1,1},
   								nOffsets = {5,5,-5,-5},
					  		  },
					 }
	wndItem:UpdatePixie(1, tOptions)
	wndItem:SetData(tData)	
	wndItem:SetSprite(sQualityBorder)
	wndItem:SetBGColor(sQualityColor)
end

-----------------------------------------------------------------------------------------------
-- Update_UI_LockItemFrame
function Gear:Update_UI_LockItemFrame()
    if self.Gear_Panel == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   	for _=1, #tChildren do
		local bChecked = tChildren[_]:FindChild("Preview_Btn"):IsChecked()
       	if bChecked then 
			local nGearId = tChildren[_]:GetData()
 		    local wndControl =  tChildren[_]
			self:Update_UI_LockItem(nGearId, wndControl)
		end
    end
end

-----------------------------------------------------------------------------------------------
-- Update_UI_LockItem 
function Gear:Update_UI_LockItem(nGearId, wndControl)
	local tChildren = wndControl:FindChild("Item_Frame"):GetChildren()
	for _=1, #tChildren do
		local nSlot = tChildren[_]:GetData().slot		
		local bDelete = self.bLockDel
		if t_gear.gear[nGearId][nSlot] == nil then   
			bDelete = false
		end
		self:Update_UI_Lock(tChildren[_], "ItemDelete_Btn", bDelete)
	end	
end

-----------------------------------------------------------------------------------------------
-- Update_UI_Lock (create or remove delete btn for profil and item) 
function Gear:Update_UI_Lock(wndControl, sBtnName, bLock)
	local oDelBtn = wndControl:FindChild(sBtnName)
 	if bLock == true and oDelBtn == nil then
		oDelBtn = _LoadForm(xmlDoc, sBtnName, wndControl, self)
	elseif bLock == false and oDelBtn then
		oDelBtn:Destroy()	
	end
end

-----------------------------------------------------------------------------------------------
-- create/remove/update a single plugin for all profile or update all plugin for all profile  
function Gear:Update_UI_Plugin(sPlugin, nAction)
	if self.Gear_Panel == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
	for _=1, #tChildren do
	    local wndFrame = tChildren[_]:FindChild("Plugin_Frame")
	    local nGearId = tChildren[_]:GetData()
	    if nAction == 1 then 
	        self:Update_UI_Add(nGearId, wndFrame, sPlugin)
		end
		local tChildrenPlugin = wndFrame:GetChildren()
	    for _=1, #tChildrenPlugin do
            local  sOwner = tChildrenPlugin[_]:GetData().owner   
            local   nUIId = tChildrenPlugin[_]:GetData().uiid	 
            local  tSaved = t_uisetting[sOwner][nUIId].Saved     
            local bCustom = tChildrenPlugin[_]:GetData().custom  		
            local   sType = tChildrenPlugin[_]:GetData().type    
            local bSelected = nil	
            if (sOwner == sPlugin and nAction ~= 2) or sPlugin == nil then  
           		if sType == "toggle_unique" then 
					if tSaved == nGearId then  
						bSelected = true
					end	  
					tChildrenPlugin[_]:SetCheck(bSelected or false)
				end     
				if sType == "push" then 
					if tSaved and tSaved[nGearId] then
     					bSelected = true
					end
				end  
				self:Set_UI_ColorStatus(tChildrenPlugin[_], bSelected, bCustom)
				if sOwner == sPlugin then 
				    break
				end
			end
			if nAction == 2 and sOwner == sPlugin then
	        	tChildrenPlugin[_]:Destroy()
	            break
			end
		end 
	    wndFrame:ArrangeChildrenHorz(0, function(a,b) return (a:GetData().zorder < b:GetData().zorder) end) 
   	end
end

-----------------------------------------------------------------------------------------------
-- remove preview frame 
function Gear:Remove_PreviewItem(wndControl)
  	local wndFrame = wndControl:FindChild("Item_Frame")
	wndFrame:DestroyChildren()
end

-----------------------------------------------------------------------------------------------
-- search missing item from a profile 
function Gear:CheckMissing(wndControl)
  	local nLevel, nAlert = 1, 1
   	local nGearId = wndControl:GetData() 
	for _, sItemLink in pairs(t_gear.gear[nGearId]) do
		if tonumber(_) then	
        	local tItemFind = _FindItem(sItemLink)
			nLevel = tStatus[tItemFind.find].level		
			if nLevel >= nAlert then nAlert = nLevel end
		end
	end
	self:Update_UI_Alert(wndControl, nAlert)
end

local tAlert = { 
			     [1] = { color = "xkcdApple", icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Green", }, 
			     [2] = { color = "White",     icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Blue", },  
			     [3] = { color = "red",       icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Red", },   
		       } 
			   
-----------------------------------------------------------------------------------------------
-- set color alert for macro button 
function Gear:Update_UI_Alert(wndControl, nAlert)
	local wnd = wndControl:FindChild("Macro_Btn")
	wnd:ChangeArt(tAlert[nAlert].icon)
	wnd:SetBGColor(tAlert[nAlert].color)
end

-----------------------------------------------------------------------------------------------
-- fired after enter a chat /command
function Gear:OnSlash(strCommand, strOption)
	local nGearId = tonumber(strOption)	
    if self.bLockForUpdate == true then return end
	if nGearId and nGearId >= 1 and t_gear.gear[nGearId] and self.bCanEquip then 
	    self:IniEquipGear(nGearId, true)
		self.bIsGearSwitch = true
		self:Align_LAS(nGearId)
	elseif strOption == "unselect" then	
		self:UnSelectGear()
	elseif strOption == "sett" then	
		self:ShowSettings()
	elseif nGearId == nil then 
		self:OnShowGear()	
	end
end

---------------------------------------------------------------------------------------------------
-- create gear panel in character window or modal window
function Gear:CreatePanel(wndTarget)
	if self.Gear_Panel == nil then 
		self.Gear_Panel = _LoadForm(xmlDoc, "Gear_Frame", wndTarget, self)
		self.Gear_Panel:FindChild("Add_Btn"):SetText(m_L["G_ADD"])
		self.Gear_Panel:FindChild("ReloadUI_Btn"):SetText(m_L["G_RELOADUI"])
		local tOptions = {
  							strSprite = "NewSprite:Logo",
							cr = {a=0.150, r=0, g=0, b=0},
							loc = {
    								 fPoints = {.2,.2,1,1},
    								nOffsets = {0,0,0,0},
							      },
  						 }
		self.Gear_Panel:FindChild("Set_Frame"):AddPixie(tOptions)
		self:Align_LAS_Mod(self.nLASMod, self.bLock)
		self:RestoreGear()
	end
end

---------------------------------------------------------------------------------------------------
-- create profile frame
function Gear:CreateGearWnd(nGearId, bIsNewGear)
	self.wndSet = self.wndTarget:FindChild("Set_Frame")
	local wndNewSet = _LoadForm(xmlDoc, "SetTemplate_Frame", self.wndSet, self)	
	wndNewSet:SetData(nGearId)
	wndNewSet:SetName("gear_" .. nGearId)
	local wndMacro = wndNewSet:FindChild("Macro_Btn")
	local nIdMod = self.nLASMod
	local nLasId = t_gear.gear[nGearId].las[nIdMod]
	if nLasId then wndMacro:SetText(nLasId) end
	self:Set_UI_Settings(nGearId, wndNewSet)
	local sGearName = t_gear.gear[nGearId].name
	if sGearName == nil then
		sGearName = self:_SetGearName(nil, nGearId)
	end	
	local wndGearName = wndNewSet:FindChild("GearName_Btn")
	wndGearName:SetPrompt(m_L["G_SETNAME"])
	wndGearName:SetPromptColor("xkcdBluegreen")
	wndGearName:SetMaxTextLength(20)
	wndGearName:SetTextRaw(sGearName)
	self:Update_UI_Lock(wndNewSet, "Delete_Btn", self.bLockDel)
	self.wndSet:ArrangeChildrenVert()
	if bIsNewGear then
		self:ShowSelectGear(nGearId)
		self.nGearId = nGearId
		local tGearUpdate = self:GetGear()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_CREATE", nGearId, tGearUpdate, nil, nil)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", t_gear.gear)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CREATE", nGearId) 
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nGearId, terror = nil })
	end
end

---------------------------------------------------------------------------------------------------
-- fired after click in add profile button
function Gear:OnClickAddNewSet( wndHandler, wndControl, eMouseButton )
  	local tToSave = _GetAllEquipped()  
	local nGearId, bIsNewGear = self:_SaveAllEquipped(tToSave, nil) 
	self:CreateGearWnd(nGearId, bIsNewGear)
end

---------------------------------------------------------------------------------------------------
-- fired after loose focus in profile name control 
function Gear:OnGearNameLostFocus( wndHandler, wndControl )
    local nGearId = wndControl:GetParent():GetData()
	if t_gear.gear[nGearId] == nil then return end
    local sNewName = wndControl:GetText():match("^%s*(.-)%s*$")
	local sOldName = t_gear.gear[nGearId].name 
	local sGearName
	if sNewName == "" or sNewName == sOldName then 
		sGearName = sOldName
    else
		sGearName = self:_SetGearName(sNewName, nGearId) 
		self:_RenameMacro(nGearId, t_gear.gear[nGearId].macro, sGearName)
		local tGearUpdate = self:GetGear()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_RENAME", nGearId, tGearUpdate, nil, nil)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_RENAME", {ngearid = nGearId, selected = self.nGearId, gear = t_gear.gear})
	end
	wndControl:SetTextRaw(sGearName)
end

---------------------------------------------------------------------------------------------------
-- set profile name color 
function Gear:ShowSelectGear(nGearId)
    if self.wndPrev then 
		local wndPrev = Apollo.FindWindowByName(self.wndPrev:GetName())
        if wndPrev then
        	wndPrev:FindChild("GearName_Btn"):SetTextColor("white")
		end
	end
 	if nGearId == nil then return end
	local wnd = Apollo.FindWindowByName("gear_" .. nGearId)
	if wnd then 
		wnd:FindChild("GearName_Btn"):SetTextColor("xkcdApple")
		self.wndPrev = wnd
	end
end

---------------------------------------------------------------------------------------------------
-- IniEquipGear 
---------------------------------------------------------------------------------------------------
function Gear:IniEquipGear(nGearId, bComeFromUI)
    self:ShowSelectGear(nGearId)
	if self.bStopEquip == false then self.bStopEquip = true end
    for _, oSlot in pairs(t_itemslot) do
		t_itemslot[_].bInSlot = false
	end
	self.nGearId = nGearId
    self.bStopEquip = false
	self.nEquippedCount = 0
	self.nGearCount = _TableLength(t_gear.gear[nGearId]) 
	self:_EquipGear(nGearId)
	local tGearUpdate = self:GetGear()
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_CHANGE", nGearId, tGearUpdate, nil, nil)
	local tData = { ngearid = nGearId, fromui = bComeFromUI, }
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHANGE", tData )
end

---------------------------------------------------------------------------------------------------
-- OnGearEquip 
function Gear:OnGearEquip( wndHandler, wndControl, eMouseButton )
    if not self.bCanEquip then return end
	local nGearId = wndControl:GetParent():GetData()
	self:IniEquipGear(nGearId, true)
	self.bIsGearSwitch = true
	self:Align_LAS(nGearId)
	if eMouseButton == 1 then 
	    self.cLast = wndControl
		if self.nLASMod == 3 then return end
	    local nCount = AbilityBook.GetNumUnlockedSpecs()
	   	self:ShowMenu(nGearId, nCount, 1)
    end
 end

---------------------------------------------------------------------------------------------------
-- OnGearDelete 
function Gear:OnGearDelete( wndHandler, wndControl, eMouseButton )
	if (eMouseButton == 0) then	
    	local nGearId = wndControl:GetParent():GetData()
       	local nMacroId = t_gear.gear[nGearId].macro
    	self:_DeleteMacro(nMacroId) 
    	self:_DeleteGear(nGearId) 
		wndControl:GetParent():Destroy()
		if nGearId == self.nGearId then
        	self:UnSelectGear()
        end
       	self.wndSet:ArrangeChildrenVert()
	end	
end

---------------------------------------------------------------------------------------------------
-- OnItemRemove
function Gear:OnItemRemove( wndHandler, wndControl, eMouseButton )
	if (eMouseButton == 0) then	
    	local nGearId = wndControl:GetParent():GetParent():GetParent():GetData()
       	local nSlot = wndControl:GetParent():GetData().slot
    	self:_RemoveItem(nGearId, nSlot) 
		self:Update_UI_PreviewItemSingle(nGearId, wndControl, nSlot)
		wndControl:Destroy()
	end	
end

---------------------------------------------------------------------------------------------------
-- OnClickReloadUI 
function Gear:OnClickReloadUI( wndHandler, wndControl, eMouseButton )
	RequestReloadUI()
end

---------------------------------------------------------------------------------------------------
-- OnMacroBeginDragDrop
function Gear:OnMacroBeginDragDrop( wndHandler, wndControl, x, y, bDragDropStarted )
	if wndHandler ~= wndControl then return false end
	local nGearId = wndControl:GetParent():GetData()
	local nMacroId = t_gear.gear[nGearId].macro
	Apollo.BeginDragDrop(wndControl, "DDMacro", wndControl:GetSprite(), nMacroId)
	return true
end

---------------------------------------------------------------------------------------------------
-- OnSave
function Gear:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
	local tData_settings = {} 
	for sParent, peParent in pairs(t_settings) do
	   	for _, peChild in pairs(peParent) do
			if peParent.plugin then break end
			tData_settings[_] = peChild.bActived
		end
	end
	self:SaveSize(self.wndGear, t_size.modal)
	local tData_size = t_size.modal.anchor 
	local tData = {}
	      tData.config = {
	                       lastgear = self.nGearId,
	                         lasmod = self.nLASMod, 
						   settings = tData_settings,
						       size = tData_size,
							    ver = G_VER,
	                     }
	if _TableLength(t_gear.gear) ~= 0 then 
		tData.gear = t_gear.gear 
	end
	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
function Gear:OnRestore(eLevel,tData) 
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	if tData.gear then t_gear.gear = tData.gear end
	if tData.config.lastgear and tData.config.lastgear >= 1 then 
		if t_gear.gear[tData.config.lastgear] then
			if tData.config.lastgear then self.nGearId = tData.config.lastgear end
		else
			self.nGearId = nil
		end	
	end	
	if tData.config.lasmod then	
		self.nLASMod = tData.config.lasmod
	end
	if tData.config.settings then
    	for sParent, peParent in pairs(t_settings) do
			for _, peChild in pairs(peParent) do
				if tData.config.settings[_] then t_settings[sParent][_].bActived = tData.config.settings[_] end
			end
        end 	
	end 
	if tData.config.size then
		t_size.modal.anchor = tData.config.size 
    end
end 

---------------------------------------------------------------------------------------------------
-- RestoreGear
function Gear:RestoreGear() 
    if _TableLength(t_gear.gear) == 0 then return end 
	for _, peCurrent in pairs(t_gear.gear) do
		self:CreateGearWnd(_, false)
	end
	self:ShowSelectGear(self.nGearId)
	self:Update_UI_AllPreview()
	self:Update_UI_Plugin(nil, nil)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_VISIBLE")
end

---------------------------------------------------------------------------------------------------
-- OnCheckPreview
function Gear:OnCheckPreview( wndHandler, wndControl, eMouseButton )
   	local nGearId = wndControl:GetParent():GetData()
	local wndTemplate = wndControl:GetParent()
	local nHeight = 80
	if wndControl:IsChecked() then  
		nHeight = 186 
		self:SetPreviewItem(nGearId, wndTemplate)
		self:Update_UI_PreviewItem(nGearId, wndTemplate)
		self:Update_UI_LockItem(nGearId, wndTemplate)
	else
		self:Remove_PreviewItem(wndTemplate)
	end
	local l,t,r,b = wndTemplate:GetAnchorPoints()
	wndTemplate:SetAnchorOffsets(l, t, r, nHeight)
	self.wndSet:ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- OnLockDeleteCheck
function Gear:OnLockDeleteCheck( wndHandler, wndControl, eMouseButton )
	self.bLockDel = wndControl:IsChecked()
	wndControl:SetCheck(self.bLockDel)
	self:Update_LockProfile()
	self:Update_UI_LockItemFrame()
end

---------------------------------------------------------------------------------------------------
-- Update_LockProfile
function Gear:Update_LockProfile()
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
    for _=1, #tChildren do
		self:Update_UI_Lock(tChildren[_], "Delete_Btn", self.bLockDel)
	end
end

---------------------------------------------------------------------------------------------------
-- click on 'unselect' ui option
function Gear:OnClickForUnselectGear( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self:UnSelectGear()
end

---------------------------------------------------------------------------------------------------
-- click on 'collapse' ui option
function Gear:OnCollapseCheck( wndHandler, wndControl, eMouseButton )
	local bCheck = wndControl:IsChecked()
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
	local nIsOpen, nIsClosed = 0, 0
	for _=1, #tChildren do
		local wnd = tChildren[_]:FindChild("Preview_Btn")
		if wnd:IsChecked() then 
			nIsOpen = nIsOpen + 1 
		else
			nIsClosed = nIsClosed + 1
		end
	end
   	if nIsOpen > nIsClosed then bCheck = false else bCheck = true end
	self:Collapse_AllPreview(bCheck)
end

---------------------------------------------------------------------------------------------------
-- click on 'lasmod' ui option 
function Gear:OnLasModClick( wndHandler, wndControl, eMouseButton )
	local nIdMod = wndControl:GetData()
    nIdMod = nIdMod + 1
	if nIdMod == 3 then 
		wndControl:SetData(0)
	else
		wndControl:SetData(nIdMod)
	end
	self.nLASMod =  nIdMod
	local tLASMod = {     
						[1] = m_L["G_LASMOD_1"],
						[2] = m_L["G_LASMOD_2"], 
						[3] = m_L["G_LASMOD_3"],
					}
	wndControl:SetText(tLASMod[nIdMod])
	self:UpdateText_LAS(nIdMod)
	if _TableLength(t_gear.gear) == 0 or self.nGearId == nil then return end 
	if not self.bNoSwitch then 
		self.bIsGearSwitch = true
		self.bNoSwitch = false
	end	
    self:Align_LAS(self.nGearId)
end

---------------------------------------------------------------------------------------------------
-- all click event from profile ui settings come here
function Gear:OnClick_UI_Settings( wndHandler, wndControl, eMouseButton )
	local sType = wndControl:GetData().type		
	local sOwner = wndControl:GetData().owner	
	local nUIId = wndControl:GetData().uiid		
	local nGearId = wndControl:GetData().ngearid
	local nNewSelect, nOldSelect 	
	if sType == "toggle_unique" then
		local bChecked = wndControl:IsChecked()
		if bChecked then
			nNewSelect = nGearId
			nOldSelect = t_uisetting[sOwner][nUIId].Saved
			if nOldSelect and t_gear.gear[nOldSelect] then 
				if self.Gear_Panel:FindChild("Set_Frame"):FindChild("gear_" .. nOldSelect):FindChild(sOwner .. "_" .. nUIId) then	
					self.wndPrev_toggle_unique = self.Gear_Panel:FindChild("Set_Frame"):FindChild("gear_" .. nOldSelect):FindChild(sOwner .. "_" .. nUIId)
					self:Set_UI_ColorStatus(self.wndPrev_toggle_unique, false)
					self.wndPrev_toggle_unique:SetCheck(false)
				end
			end
	   	elseif not bChecked then
			nNewSelect = nil
			nOldSelect = nil
		end	
		self:Set_UI_ColorStatus(wndControl, bChecked)
		t_uisetting[sOwner][nUIId].Saved = nNewSelect
		local tUISetting = { owner = sOwner, uiid = nUIId, saved = nNewSelect, }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_SETTING", tUISetting)
	end
	if sType == "toggle" then
		
	end
 	if sType == "push" then
		local tUISetting = { owner = sOwner, uiid = nUIId, ngearid = nGearId, name = t_gear.gear[nGearId].name}
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_ACTION", tUISetting)
	end
	if sType == "none" then
		
	end
end

---------------------------------------------------------------------------------------------------
-- all click event from settings plugin come here
function Gear:Plugin_OnClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	local sControl = wndControl:GetName()
	if sControl == "Plugin_wnd" then
		local cParent = wndControl:GetParent():GetParent()
		local sOwner = wndControl:GetData().name
		t_plugin[sOwner].on = not t_plugin[sOwner].on
		local tChildren = cParent:GetChildren()
		for _=1,#tChildren do
			if tChildren[_]:GetName() ~= "FrameTitle_wnd" then 
				tChildren[_]:Enable(t_plugin[sOwner].on)
			end	
			tChildren[_]:SetTextColor(t_color.plugin[tostring(t_plugin[sOwner].on)])
			local cPluginIcon = tChildren[_]:FindChild("Plugin_Icon_wnd")			
			if cPluginIcon then
				cPluginIcon:SetBGColor(t_color.plugin_icon[tostring(t_plugin[sOwner].on)])
			end		
		end
		if t_uisetting[sOwner] then
			local nAction = 2	
			if t_plugin[sOwner].on then nAction = 1 end 
			self:Update_UI_Plugin(sOwner, nAction)
		end
		local tSetting = { owner = sOwner, on = t_plugin[sOwner].on }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_ON", tSetting)
	end
end

---------------------------------------------------------------------------------------------------
-- create/destroy gear window
function Gear:IniWindow(oWndTarget)
	if self.wndGear and self.bModal then
		self:SaveSize(self.wndGear, t_size.modal)
		self.wndGear:SetInterrupt(false)
		self.wndGear:Destroy()
		self.wndGear, self.Gear_Panel = nil, nil
		return
	elseif self.wndGear == nil and self.bModal then
		self.wndGear = oWndTarget
		self.wndGear:FindChild("TitleWnd"):SetText(m_L["G_TABNAME"])
		self.wndTarget = self.wndGear:FindChild("OptionWnd_Frames")
		self.wndTarget:SetStyle("VScroll", false) 
		self.wndGear:FindChild("CloseBtn"):SetData("modal")
		self:SetSize(self.wndGear, t_size.modal)
		self.bLockDel = false
		self:CreatePanel(self.wndTarget)
		self.wndGear:SetInterrupt(true)
		self.wndGear:Show(true)
	elseif not self.bModal then
		self.wndTarget = oWndTarget
		self.wndTarget:SetStyle("VScroll", false) 
		self.bLockDel = false
		self:CreatePanel(self.wndTarget)
		self.wndTarget:Show(true)
	end
end

---------------------------------------------------------------------------------------------------
-- set size/position for setting/gear window
function Gear:SetSize(oWnd, tWndSize)
  	local nWidth = oWnd:GetWidth() 
	local nHeight = oWnd:GetHeight()
	local nLimitWidth, nLimitHeight = tWndSize.max.width, tWndSize.max.height
	local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()
	oWnd:SetSizingMinimum(nWidth, nHeight)
	if tWndSize.max.width == 0 and tWndSize.max.height == 0 then 
		nLimitWidth, nLimitHeight = nScreenWidth, nScreenHeight
	elseif tWndSize.max.width ~= 0 then
		nLimitHeight = nScreenHeight
	end
	oWnd:SetSizingMaximum(nLimitWidth, nLimitHeight) 
	if tWndSize.anchor.b == 0 then return end
	oWnd:SetAnchorOffsets(tWndSize.anchor.l, tWndSize.anchor.t, tWndSize.anchor.r, tWndSize.anchor.b)
end

---------------------------------------------------------------------------------------------------
-- save size/postion for setting/gear
function Gear:SaveSize(oWnd, tWndSize)
 	if oWnd then 
		tWndSize.anchor.l, tWndSize.anchor.t, tWndSize.anchor.r, tWndSize.anchor.b = oWnd:GetAnchorOffsets()
	end
end

---------------------------------------------------------------------------------------------------
-- event fired when setting/gear window is resizing
function Gear:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	if wndControl:FindChild("CloseBtn"):GetData() == "modal" then
		self:SaveSize(self.wndGear, t_size.modal)
	else
		self:SaveSize(self.wndOption, t_size.settings)
	end	
end

---------------------------------------------------------------------------------------------------
-- OnItemToolTip
function Gear:OnItemToolTip( wndHandler, wndControl, x, y )
	if wndControl ~= wndHandler then return end
	local oItem = wndControl:GetData().item
	local oSlot = wndControl:GetData().slot
	local bCompare = wndControl:GetData().compare
	if oItem and type(oItem) == "userdata" then
		local itemEquipped = oItem:GetEquippedItemForItemType()
		if bCompare == false then itemEquipped = nil end
		Tooltip.GetItemTooltipForm(self, wndControl, oItem, {bPrimary = true, bSelling = false, itemCompare = itemEquipped})
	else
		wndControl:SetTooltip(t_itemslot[oSlot].sToolTip)
	end
end

---------------------------------------------------------------------------------------------------
-- OnLeaveItemToolTip
function Gear:OnLeaveItemToolTip( wndHandler, wndControl, x, y )
	wndControl:SetTooltipDoc(nil)
end

---------------------------------------------------------------------------------------------------
-- OnShowGear_UI_ToolTips
function Gear:OnShowGear_UI_ToolTips( wndHandler, wndControl, x, y )
	local tData = wndControl:GetData()
	if tData == nil then return end 
	local xml = XmlDoc.new()
	local sTranslate = t_settings[tData.owner].translatename
	local sTooltips = {}
	if tData then
		local tSaved = t_uisetting[tData.owner][tData.uiid].Saved
		if tSaved and tonumber(tSaved) == nil and tSaved[tData.ngearid] then 
			if tSaved[tData.ngearid].target[1] then
				sTooltips = tSaved[tData.ngearid].target
			else
				sTooltips[1] = tSaved[tData.ngearid].target
			end
		end
	end
	xml:AddLine(sTranslate, "xkcdAmber", "CRB_InterfaceSmall", "Left")	
	for _=1, #sTooltips	do
		xml:AddLine(sTooltips[_], "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
	end
	wndControl:SetTooltipDoc(xml)
end

---------------------------------------------------------------------------------------------------
-- OnShowGear_ToolTips
function Gear:OnShowGear_ToolTips( wndHandler, wndControl, x, y )
	local sWndName = wndControl:GetName()
	local tToolTipId = {     
							 ["Lock_Btn"] = m_L["G_LOCK"],
						 ["Collapse_Btn"] = m_L["G_COLLAPSE"], 
						 ["Unselect_Btn"] = m_L["G_UNSELECT"],
						   ["Delete_Btn"] = m_L["G_DELETE"],  
						   ["LasMod_Btn"] = m_L["G_LASMOD"],
					    }
	if tToolTipId[sWndName] then
		wndControl:SetTooltip(tToolTipId[sWndName])
	else
		local xml = XmlDoc.new()					
		if sWndName == "Macro_Btn" then 
			local nMacro = wndControl:GetParent():GetData()
			local sGear = "\/gear " .. nMacro
		  	xml:AddLine(sGear, "xkcdAmber", "CRB_InterfaceSmall", "Left")
	    	xml:AddLine(m_L["G_MACRO"], "White", "CRB_InterfaceSmall", "Left")
	       	if self.nLASMod == 3 then
				xml:AddLine(m_L["G_LASPARTNER"], "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
			else
				xml:AddLine(m_L["G_LAS"], "White", "CRB_InterfaceSmall", "Left")
	    	end
		elseif sWndName == "GearName_Btn" then 
			xml:AddLine(m_L["G_NAME"], "White", "CRB_InterfaceSmall", "Left")
	 	elseif sWndName == "Preview_Btn" then 
	   		xml:AddLine(m_L["G_PREVIEW"], "White", "CRB_InterfaceSmall", "Left")
	  	elseif sWndName == "Plugin_wnd" then
			local sPlugIn = wndControl:GetData().name
			xml:AddLine(sPlugIn .. " v" ..t_plugin[sPlugIn].ver , "White", "CRB_InterfaceSmall", "Left")
	    	xml:AddLine(t_plugin[sPlugIn].flavor, "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
		elseif sWndName == "Settings_Btn" then
		   	local nPlugIn = _TableLengthBoth(t_plugin)
			xml:AddLine(nPlugIn .." " .. m_L["G_UI_SETTINGS"], "xkcdAmber", "CRB_InterfaceSmall", "Left")
			for sPlugIn, oPlugIn in pairs(t_plugin) do
				xml:AddLine(sPlugIn .. " v" ..t_plugin[sPlugIn].ver, t_color.plugin[tostring(t_plugin[sPlugIn].on)], "CRB_InterfaceSmall", "Left")
	    	end
		end
		wndControl:SetTooltipDoc(xml)
	end	
end

-----------------------------------------------------------------------------------------------
-- Gear Instance
local GearInst = Gear:new()
GearInst:Init()