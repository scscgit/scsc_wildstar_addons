-----------------------------------------------------------------------------------------------
-- 'Gear' v2.4.1 [22/08/2016]
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Item"
require "Apollo"
require "GameLib"
require "MacrosLib"

-----------------------------------------------------------------------------------------------
-- Gear Module Definition
-----------------------------------------------------------------------------------------------
local Gear = {} 
 
-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Gear", true)

-----------------------------------------------------------------------------------------------
-- gear module
-----------------------------------------------------------------------------------------------
local lGear = Apollo.GetPackage("Lib:LibGear-1.0").tPackage

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- version 
local tVer = { major = 2, minor = 4, patch = 1, } 
local G_VER = string.format("%d.%d.%d", tVer.major, tVer.minor, tVer.patch)
local G_NAME = "Gear"

local tGear = {	
         		gear = { },
			  }       	
 
 
local tItemSlot = {
		
[GameLib.CodeEnumEquippedItems.WeaponPrimary]		= { bInSlot = false, sToolTip = Apollo.GetString("Character_WeaponEmpty"),  	sIcon = "NewSprite:Weapon_Hands", 	   		},	-- 16				 
[GameLib.CodeEnumEquippedItems.Shields]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ShieldEmpty"),  	sIcon = "NewSprite:Shield_Weapon_attachment", 	},	-- 15				 
[GameLib.CodeEnumEquippedItems.Head]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_HeadEmpty"),  		sIcon = "NewSprite:Head",              		},	-- 2
[GameLib.CodeEnumEquippedItems.Shoulder]			= { bInSlot = false, sToolTip = Apollo.GetString("Character_ShoulderEmpty"),  	sIcon = "NewSprite:Shoulders",          		},	-- 3
[GameLib.CodeEnumEquippedItems.Chest]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ChestEmpty"),  		sIcon = "NewSprite:Chest",             		},	-- 0
[GameLib.CodeEnumEquippedItems.Hands]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_HandsEmpty"),  		sIcon = "NewSprite:Weapon_Hands",       		},	-- 5
[GameLib.CodeEnumEquippedItems.Legs]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_LegsEmpty"),  		sIcon = "NewSprite:Legs", 		   		},	-- 1
[GameLib.CodeEnumEquippedItems.Feet]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_FeetEmpty"),  		sIcon = "NewSprite:Feet",              		},	-- 4
[GameLib.CodeEnumEquippedItems.WeaponAttachment]	= { bInSlot = false, sToolTip = Apollo.GetString("Character_AttachmentEmpty"),	sIcon = "NewSprite:Shield_Weapon_attachment",   },	-- 7 	
[GameLib.CodeEnumEquippedItems.System]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_SupportEmpty"),  	sIcon = "NewSprite:Support",           		},	-- 8	
[GameLib.CodeEnumEquippedItems.Gadget]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_GadgetEmpty"),  	sIcon = "NewSprite:Gadget",            		},	-- 11
[GameLib.CodeEnumEquippedItems.Implant]				= { bInSlot = false, sToolTip = Apollo.GetString("Character_ImplantEmpty"),  	sIcon = "NewSprite:Implant", 		   		},	-- 10				  }		
											
				   }


-- size	limit modal/settings window			
local tSize = {
				-- modal 
				modal = {  
						anchor = { l = 0, t = 0, r = 0, b = 0,},	
						   min = { width = 0, height = 0,}, 
						   max = { width = 430, height = 0,},
						},
				
				-- settings 
			 settings = { 
						anchor = { l = 0, t = 0, r = 0, b = 0,},
						   min = { width = 0, height = 0,}, 
						   max = { width = 430, height = 0,},
						},
				}						
				
								
				
-- color with section				
local tColor = {
				plugin = { ["true"] = "xkcdBabyBlue",  ["false"] = "xkcdBattleshipGrey",},  -- on/off color for text setting 
	       ui_selected = { ["true"] = 0.8, ["false"] = 0.5 , }, 							-- opacity ui setting button
		      ui_color = { ["true"] = "xkcdBoringGreen", ["false"] = "xkcdAquaBlue", }, 	-- color status for ui setting button

				}				
				
								
-- to keep plugin information 								
local tPlugIn = {}
-- to keep plugin ui setting  								
local tUI_Setting = {}
-- core option (all child is a index inc by 1, only for core setting)
local tOption = {}
							
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Gear:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function Gear:Init()
	Apollo.RegisterAddon(self, true, "Gear", nil)
end

-----------------------------------------------------------------------------------------------
-- Gear OnLoad
-----------------------------------------------------------------------------------------------
function Gear:OnLoad()
 	
    self.xmlDoc = XmlDoc.CreateFromFile("Gear.xml")
    Apollo.LoadSprites("NewSprite.xml")
		
	Apollo.RegisterSlashCommand("gear", 							 "OnSlash", self)
	Apollo.RegisterEventHandler("PlayerEquippedItemChanged", 		 "OnPlayerEquippedItemChanged", self)
	Apollo.RegisterEventHandler("UpdateInventory", 					 "OnUpdateInventory", self)
    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", 		 "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("Generic_OnShowGear", 				 "OnShowGear", self)	
   	Apollo.RegisterEventHandler("SpecChanged", 						 "OnSpecChanged", self)
 	Apollo.RegisterEventHandler("Generic_GEAR_UPDATE", 				 "ON_GEAR_UPDATE", self)
	Apollo.RegisterEventHandler("Generic_GEAR_PLUGIN", 				 "ON_GEAR_PLUGIN", self)
						
	self.bStopEquip 	= true
	self.bLockForUpdate = false
	self.bMenAtWork 	= false
	self.nLASMod 		= 1
	self.bReEquipOld 	= false
	self.bModal 		= true
end

-----------------------------------------------------------------------------------------------
--- all plugin communicate with gear in this function
-----------------------------------------------------------------------------------------------
function Gear:ON_GEAR_PLUGIN(sAction, tData)

	-- answer from a plugin, plugin ready
	if sAction == "G_READY" then
			
		-- we send gear version	to owner plugin
		local tVerToOwner = tVer
		tVerToOwner.owner = tData.name
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_VER", tVerToOwner)
		
		-- plugin setting detected, add new plugin and setting to toption
		if tData.setting then
			tOption[tData.setting.name] = tData.setting[1]
			tOption[tData.setting.name].plugin = tData.name
			-- keep information from this new plugin
			local sIcon = nil
			if tData.icon then sIcon = lGear._loadicon(tData.name) end
			tPlugIn[tData.name] = { settingname = tData.setting.name, ver = tData.version, flavor = tData.flavor, on = tData.on, icon = sIcon}
		end
				
		-- plugin ui setting detected, keep for profil
		if tData.ui_setting then
			tUI_Setting[tData.setting.name] = tData.ui_setting
			tUI_Setting[tData.setting.name].plugin = tData.name
		end
	end	
	
	-- answer from a plugin, set plugin to off
	if sAction == "G_SET_OFF" then
		tPlugIn[tData.owner].on = tData.on
				
		-- if settings open , refresh setting 
		if self.wndOption  then 
			self:SaveSize(self.wndOption, tSize.settings)
			-- remember scroll position	
			local nVScrollPos = self.wndOption:FindChild("OptionWnd_Frames"):GetVScrollPos() 
			self:ShowSettings() 
			-- restore scroll position
			self.wndOption:FindChild("OptionWnd_Frames"):SetVScrollPos(nVScrollPos)
			-- update plugin ui setting panel
			self:Update_UI_Setting()
		end
	end	
		
	-- answer from a plugin, a new gear array
	if sAction == "G_SET_ARRAY" then
		-- we update gear array
		tGear.gear = tData.gear	
	end	
		
	-- answer from a plugin, want gear array
	if sAction == "G_GET_GEAR" then
		-- we send gear array	
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", tGear.gear)
		
	end	
		
	-- answer from a plugin, want last gear
	if sAction == "G_GET_LASTGEAR" then
		-- we send last gear equipped
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_LASTGEAR", { ngearid = self.nGearId })
	end	
	
	-- answer from a plugin or gear, want know is actual equipped gear as no error
	if sAction == "G_GET_CHECK_GEAR" then
			
		-- we check status
		self:_CheckEquipped(self.nGearId)
	end	
		
	-- answer from a plugin, want gear launch a function array
	if sAction == "G_SET_FUNC" then
		
		-- to prevent erased gear set 
		if tGear.gear[tData.ngearid] == nil then 
			self:IsGearIdExist()
			tData.ngearid = self.nGearId
		end 
		
		-- we execute function gear array				
		for _=1,#tData.func do
				
				if tData.func[_] == "SELECT" then self:ShowSelectGear(tData.ngearid) end
				if tData.func[_] == "EQUIP" then 
				
					self:IniEquipGear(tData.ngearid, true)
					self.bIsGearSwitch = true
				end
				if tData.func[_] == "LAS" then self:Align_LAS(tData.ngearid) end
				if tData.func[_] == "LASMOD_AUTO" then self:Align_LAS_Mod(tData.lasmod, tData.lock) end
				if tData.func[_] == "SET_UI_TARGET" then 
				     
                    -- send to other plug-in 'Gear' have now a new main window.
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
		
	-- answer from a plugin, want update ui setting for a specific plugin
	if sAction == "G_SET_UI_SETTING" then
			
		-- var { owner = sOwner, uiid = nUIId, saved = {some array}, }
		-- keep saved var to use with tooltips after selected a new target in list button
		tUI_Setting[tPlugIn[tData.owner].settingname][tData.uiid].Saved = tData.saved
					
		-- update plugin ui setting button color status only
		if self.Gear_Panel == nil then return end
		local sPluginBtnName = tData.owner .. "_" .. tData.uiid
		local nGearId = tData.ngearid
		local cButton = self.Gear_Panel:FindChild("gear_" .. nGearId):FindChild(sPluginBtnName)
		if cButton == nil then return end	
				
		-- detect status (for push button with a list)
		local bSelected = false
		if tData.saved and tData.saved[nGearId] then
        	bSelected = true
		end
		
		-- update ui button status/color
		self:Set_UI_ColorStatus(cButton, bSelected)
		
	end
end

-----------------------------------------------------------------------------------------------
-- Set_UI_ColorStatus
-----------------------------------------------------------------------------------------------
function Gear:Set_UI_ColorStatus(cButton, bSelected)
	
	cButton:SetBGColor(tColor.ui_color[tostring(bSelected)])	  
	cButton:SetOpacity(tColor.ui_selected[tostring(bSelected)],60)
			
	-- show text or not for actual button 
	if cButton:GetData().status then
	
		local  sOwner = cButton:GetData().owner	    -- get plugin owner
		local   nUIId = cButton:GetData().uiid		-- get index of ui setting array, to identify control
	 	local nGearId = cButton:GetData().ngearid
	
		local sStatusText = ""
		if bSelected then 
			sStatusText = tUI_Setting[tPlugIn[sOwner].settingname][nUIId].Saved[nGearId].root
		end	
		
		cButton:SetText(sStatusText)
	end
end

-----------------------------------------------------------------------------------------------
-- Align_LAS_Mod
-----------------------------------------------------------------------------------------------
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
-- OnConfigure
-----------------------------------------------------------------------------------------------
function Gear:OnConfigure()
	self:ShowSettings()
end

-----------------------------------------------------------------------------------------------
-- ShowSettings
-----------------------------------------------------------------------------------------------
function Gear:ShowSettings()

	-- init option window
	if self.wndOption then self.wndOption:Destroy() end
	self.wndOption = Apollo.LoadForm(self.xmlDoc, "OptionWnd", nil, self)
	self.wndOption:FindChild("TitleWnd"):SetText("'Gear' " .. L["G_O_SETTINGS"])
				
	-- create each parent with child option
	for _, peCurrent in pairs(tOption) do
	
		local wndFrame_O = Apollo.LoadForm(self.xmlDoc, "Frame_wnd", self.wndOption:FindChild("OptionWnd_Frames"), self)
		wndFrame_O:FindChild("FrameTitle_wnd"):SetText(_)
				
		-- keep if this setting is a plugin, to communicate setting status to owner plugin
		local sOwner = nil
		-- if this a plugin setting, add an icon and keep plugin reference
		if peCurrent.plugin then
			-- information icon
			local wndPlugin = Apollo.LoadForm(self.xmlDoc, "Plugin_wnd", wndFrame_O:FindChild("FrameTitle_wnd"), self)
			wndPlugin:SetSprite("PlayerPathContent_TEMP:spr_PathIconExpDefault")
			sOwner = peCurrent.plugin
			wndPlugin:SetData({ name = sOwner,})
			
			-- add plugin icon (usable for setting and ui setting)
			if tPlugIn[sOwner].icon then
				local wndPlugin = Apollo.LoadForm(self.xmlDoc, "Plugin_Icon_wnd", wndFrame_O:FindChild("FrameTitle_wnd"), self)
				wndPlugin:SetSprite(tPlugIn[sOwner].icon)
				wndPlugin:SetOpacity(0.5,25)
			end			
						
			-- set title color enable/disable status if is a plugin
			wndFrame_O:FindChild("FrameTitle_wnd"):SetTextColor(tColor.plugin[tostring(tPlugIn[sOwner].on)])

		end
				
		local sIndex = _
		
		local nHeightBtn = nil
		for _, peOption in pairs(peCurrent) do
			-- look if an a option, numeric index 
			if tonumber(_) then
			
				local btnOption = nil
				-- advanced option button, only push button..
				if peOption.sType then 
					btnOption =  Apollo.LoadForm(self.xmlDoc, "Option_Adv_Btn", wndFrame_O, self)
				else
				-- toggle button 
					btnOption =  Apollo.LoadForm(self.xmlDoc, "Option_Btn", wndFrame_O, self)
					btnOption:SetCheck(peOption.bActived)
				end
							
				btnOption:SetText(peOption.sDetail)
				btnOption:SetData({ sIdx = sIndex, nOption = _, plugin = sOwner,})
				nHeightBtn = btnOption:GetHeight()
				-- set enable/disable status if is a option plugin
				if peCurrent.plugin then btnOption:Enable(tPlugIn[sOwner].on) end
				
			end
		end
		wndFrame_O:ArrangeChildrenVert()
		
		-- resize only if we have child option
		if nHeightBtn then 
			local nBtn = lGear.TableLength(peCurrent)
			local l,t,r,b = wndFrame_O:GetAnchorOffsets()
			wndFrame_O:SetAnchorOffsets(l , t, r, b + (nBtn * nHeightBtn))
		end
	end
				
	self.wndOption:FindChild("OptionWnd_Frames"):ArrangeChildrenVert()
	self:SetSize(self.wndOption, tSize.settings)
	self.wndOption:Show(true, true)
end

---------------------------------------------------------------------------------------------------
-- OnOptionClick
---------------------------------------------------------------------------------------------------
function Gear:OnOptionClick( wndHandler, wndControl, eMouseButton )
	
	local nOption = wndControl:GetData().nOption
	local sIndex = wndControl:GetData().sIdx
	local sOwner = wndControl:GetData().plugin
		
	tOption[sIndex][nOption].bActived = wndControl:IsChecked()
			
	-- setting from plugin modified, alert the plugin owner
	if sOwner then
		-- we get option status 	
		local tSetting = { owner = sOwner, option = nOption, actived = tOption[sIndex][nOption].bActived }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_SETTING", tSetting)
	end
end

---------------------------------------------------------------------------------------------------
-- OnOptionClose
---------------------------------------------------------------------------------------------------
function Gear:OnOptionClose( wndHandler, wndControl, eMouseButton )
	-- if we close modal gear, init 	
	if wndControl:GetData() == "modal" then
		self:SaveSize(self.wndGear, tSize.modal)
		self.wndGear, self.Gear_Panel = nil, nil
	else
		self:SaveSize(self.wndOption, tSize.settings)
		self.wndOption = nil	
	end
	wndControl:GetParent():Destroy()
end

-----------------------------------------------------------------------------------------------
-- Set_UI_Settings (construct plugin ui setting)
-----------------------------------------------------------------------------------------------
function Gear:Set_UI_Settings(nGearId, wndControl)

	-- sType = 'toggle_unique' (on/off state, only once can be enabled in all profil, but all can be disabled)
	-- sType = 'toggle' (on/off state)
	-- sType = 'push' (on click state)
	-- sType = 'none' (no state, only icon to identify the plugin)	
    -- to assign the good control with type
	local tControlType = {
							["toggle_unique"] = "UI_toggle_unique_Btn",
							["toggle"] 		  = "UI_toggle_Btn",
							["push"]          = "UI_push_Btn",
							["none"]          = "UI_none_Btn",
							["action"]        = "UI_action_Btn",
							["list"]          = "UI_list_Btn",
	    				 }
		

	-- set ui setting frame
	local wndIcon_Frame = wndControl:FindChild("Plugin_Frame")
		
    -- get each ui first setting control and create in frame
    for _, pOption in pairs(tUI_Setting) do
  	    						
				-- create only if plugin is actived	
				if tPlugIn[tUI_Setting[_].plugin].on then	
					-- get the good control from type
					local sControlToUse = tControlType[pOption[1].sType]
					local UI_Btn = Apollo.LoadForm(self.xmlDoc, sControlToUse, wndIcon_Frame, self)
			
					-- add plugin icon for the first ui setting button only
					UI_Btn:ChangeArt(tPlugIn[pOption.plugin].icon)
					UI_Btn:SetOpacity(tColor.ui_selected["false"], 25)
					UI_Btn:SetBGColor(tColor.ui_color["false"])

				
					-- set data to button  
					local sUIId   = 1 					   -- index of ui setting array, identify each control
					local sOwner  = pOption.plugin		   -- plugin name
					local sType   = pOption[1].sType       -- button type  
					local sStatus = pOption[1].sStatus     -- show status text in button
					local tSaved  = pOption[1].Saved       -- must be array or single variable
					local tData   = { uiid = sUIId ,type = sType, status = sStatus, ngearid = nGearId, owner = sOwner,}
					UI_Btn:SetData(tData)
								
					-- set control name (ex: "Gear_Mount_1" for the first control from ui setting array)
            		UI_Btn:SetName(sOwner .. "_" .. sUIId )

                	-- set enable/disable with button type
					local bSelected = false
					if sType == "toggle_unique" then 
						if tSaved == nGearId then  
							bSelected = true
						end	  
						UI_Btn:SetCheck(bSelected)
					end     
				
					-- push button 
					if sType == "push" then 
						if tSaved and tSaved[nGearId] then
        					bSelected = true
						end
					end  
										
					-- update ui button status color
					self:Set_UI_ColorStatus(UI_Btn, bSelected)
					
				end	     
			end		
		
	wndIcon_Frame:ArrangeChildrenHorz()
end

-----------------------------------------------------------------------------------------------
-- OnProfileClick (click on profile item or name profile)
-----------------------------------------------------------------------------------------------
function Gear:OnProfileClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
  	
	-- click in item profile or name profile
	local tData = { mouse = eMouseButton, ocontrol = wndControl, tgear = tGear.gear, titemslot = tItemSlot } 
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_ITEM_CLICK", tData)
end

-----------------------------------------------------------------------------------------------
-- GetGear 
-----------------------------------------------------------------------------------------------
function Gear:GetGear()
	
	if lGear.TableLength(tGear.gear) == 0 then return nil end
	
	local tGearUpdate = {}
	for _, pGear in pairs(tGear.gear) do
	    	tGearUpdate[_] = { name = pGear.name }
	end
	return tGearUpdate
end

-----------------------------------------------------------------------------------------------
-- ON_GEAR_UPDATE 
-----------------------------------------------------------------------------------------------
function Gear:ON_GEAR_UPDATE(sAction, nGearId, tGearUpdate, nLasMod, tError)
		
	if sAction == "G_EQUIP" then 
			    
		if lGear.TableLength(tGear.gear) ~= 0 and tGear.gear[nGearId] then 
			
			-- this request to equip a set not come from gear ui, but come from another addon.
		   	self:ShowSelectGear(nGearId)	
	    	self:IniEquipGear(nGearId, false)
			self.bIsGearSwitch = true
			-- set lasmod		
			self:Align_LAS_Mod(nLasMod, false)
						
			if nLasMod and nLasMod ~= 3 then self:Align_LAS(nGearId) end
		end
	end

	if sAction == "G_GETGEAR" then 
		
		local tGearUpdate = self:GetGear()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_GEAR", self.nGearId, tGearUpdate, nil, nil)
	end
	
	-- event after equip a gear set
	-- if error we get array terror with status from all slot from a specific gear set and ngearid 
	-- or terror = nil if no error
	if sAction == "G_AFTER_EQUIP" then 
	--
	end
end

-----------------------------------------------------------------------------------------------
-- OnSpecChanged
-----------------------------------------------------------------------------------------------
function Gear:OnSpecChanged(newSpecIndex, specError)
   	
   if self.bIsGearSwitch or self.nLASMod >= 2 then self.bIsGearSwitch = false return end

   for _, oGear in pairs(tGear.gear) do
		
		if oGear.las[1] and oGear.las[1] == newSpecIndex then 
			
			self:ShowSelectGear(_)	
		   	self:IniEquipGear(_, true)
			return 
		end
	end
end

-----------------------------------------------------------------------------------------------
-- ShowMenu 
-----------------------------------------------------------------------------------------------
function Gear:ShowMenu(nGearId, nCount, nTarget)

	local nXYmouse = Apollo.GetMouse()
    local nLeft = nXYmouse.x
 	local nTop = nXYmouse.y

    if self.wndMenu then self.wndMenu:Destroy() end
	self.wndMenu = Apollo.LoadForm(self.xmlDoc, "LAS_wnd", nil, self)
	local nCount = nCount
	
	for nId =1, nCount + 1 do
			
		self.wndBtnMenu = Apollo.LoadForm(self.xmlDoc, "LAS_Btn", self.wndMenu:FindChild("LAS_Frame"), self)
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

---------------------------------------------------------------------------------------------------
-- DestroyMenu
---------------------------------------------------------------------------------------------------
function Gear:DestroyMenu()
	
    if Apollo.FindWindowByName("LAS_wnd") then 
    	self.wndMenu:DestroyChildren()		
		self.wndMenu:Destroy()
	end
end

---------------------------------------------------------------------------------------------------
-- OnSelect_LASCOS
---------------------------------------------------------------------------------------------------
function Gear:OnSelect_LASCOS( wndHandler, wndControl, eMouseButton )
    
    local nGearId = wndControl:GetData().gearid
    local nId = wndControl:GetData().id
    local nTarget = wndControl:GetData().target

    if nTarget == 1 then self:Modif_LAS(nGearId, nId) end
end

---------------------------------------------------------------------------------------------------
-- Modif_LAS
---------------------------------------------------------------------------------------------------
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

---------------------------------------------------------------------------------------------------
-- Align_LAS
---------------------------------------------------------------------------------------------------
function Gear:Align_LAS(nGearId)
   
    local nIdMod = self.nLASMod
	if nIdMod == 3 then return end
	
	local nSpeActual = AbilityBook.GetCurrentSpec() 
	local nLasGear = tGear.gear[nGearId].las[nIdMod]
	
	if nLasGear == nil then return end
	if nSpeActual ~= nLasGear then
	    self.bIsGearSwitch = true 
		AbilityBook.SetCurrentSpec(nLasGear)
	end
end

---------------------------------------------------------------------------------------------------
-- LinkGear_LAS
---------------------------------------------------------------------------------------------------
function Gear:LinkGear_LAS(nGearId, nLasId, nIdMod)
      
   if nIdMod == 3 then return end
   if nLasId == 0 then tGear.gear[nGearId].las[nIdMod] = nil return end
   tGear.gear[nGearId].las[nIdMod] = nLasId
  
   if nIdMod == 1 then
   		
		for _, oGear in pairs(tGear.gear) do
		
			if _ ~= nGearId and oGear.las[nIdMod] and oGear.las[nIdMod] == nLasId then 
				tGear.gear[_].las[nIdMod] = nil
				return _
			end
		end
	end	
end

---------------------------------------------------------------------------------------------------
-- UpdateText_LAS 
---------------------------------------------------------------------------------------------------
function Gear:UpdateText_LAS(nIdMod)
   
   local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()

   for _=1, #tChildren do
		
		local nGearId = tChildren[_]:GetData()
 		local nLasId = tGear.gear[nGearId].las[nIdMod]
        if nLasId == nil then nLasId = "" end
		
		local wndMacro_Btn = tChildren[_]:FindChild("Macro_Btn")
        wndMacro_Btn:SetText(nLasId)  
   end 
end

-----------------------------------------------------------------------------------------------
-- OnInterfaceMenuListHasLoaded
-----------------------------------------------------------------------------------------------
function Gear:OnInterfaceMenuListHasLoaded()
		
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "Gear", {"Generic_OnShowGear", "", "BK3:sprHolo_Icon_Costume"})
	self:UpdateInterfaceMenuAlerts()
end

-----------------------------------------------------------------------------------------------
-- OnShowGear
-----------------------------------------------------------------------------------------------
function Gear:OnShowGear()
	   
    --self:IsGearIdExist()
	self:ShowSelectGear(self.nGearId)
		
	if self.bModal then 
		local oWndTarget = Apollo.LoadForm(self.xmlDoc, "OptionWnd", nil, self)
		self:IniWindow(oWndTarget)
	else
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_SHOW", nil)
	end
end

-----------------------------------------------------------------------------------------------
-- UpdateInterfaceMenuAlerts
-----------------------------------------------------------------------------------------------
function Gear:UpdateInterfaceMenuAlerts()
  	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "Gear", {nil, "v"..G_VER, nil})
end

-----------------------------------------------------------------------------------------------
-- OnPlayerEquippedItemChanged 
-----------------------------------------------------------------------------------------------
function Gear:OnPlayerEquippedItemChanged(eSlot, itemNew, itemOld)

    if self.bReEquipOld == true then self.bReEquipOld = false return end
	
	-- to check missing item after equip a gear set   	
    if self.bStopEquip == false and self.nEquippedCount == self.nGearCount then 
		self.bStopEquip = true 
		self:_CheckEquipped(self.nGearId)
	end
    
	if self.bStopEquip == false then
		self:_EquipGear(self.nGearId)
	end
					
	if self.bStopEquip == true and not self.bLockForUpdate then
	    
	  	if (itemOld and itemNew == nil) or
		    tItemSlot[eSlot] == nil or
		   (tGear.gear[self.nGearId] == nil) or	
		    self.nGearId == nil then	
			return
		end	
				
		self.nSlot = eSlot
		if itemNew then	self.oNewItemLink = itemNew:GetChatLinkString()	end
		if itemOld then	self.oOldItemLink = itemOld:GetChatLinkString()	end
						
		if itemNew and itemNew:GetChatLinkString() ~= tGear.gear[self.nGearId][eSlot] or tGear.gear[self.nGearId][eSlot] == nil then
		    self:_DialogUpdate(self.nGearId, itemOld, itemNew) 
		end
				
 		self:Update_AllPreview()
 	end
end

-----------------------------------------------------------------------------------------------
-- OnUpdateInventory 
-----------------------------------------------------------------------------------------------
function Gear:OnUpdateInventory()
	if self.bStopEquip == true and self.bMenAtWork == false then 
		self:Update_AllPreview()  
	end
end

-----------------------------------------------------------------------------------------------
-- _DialogUpdate 
-----------------------------------------------------------------------------------------------
function Gear:_DialogUpdate(nGearId, itemOld, itemNew)
	
    self.UpdateWnd = Apollo.LoadForm(self.xmlDoc, "Dialog_wnd", nil, self)

	local wndInside = Apollo.LoadForm(self.xmlDoc, "Update_wnd", self.UpdateWnd, self)
	self.UpdateWnd:FindChild("CloseButton"):SetData("Update")
	self.UpdateWnd:FindChild("YesButton"):SetText(L["G_YES"])
	self.UpdateWnd:FindChild("NoButton"):SetText(L["G_NO"])
		
	local sBy = L["G_UPDATE_BY"]
	local sReplace = L["G_UPDATE_REPLACE"]
	
	local ItemOldWnd = self.UpdateWnd:FindChild("Item_Actual"):FindChild("ItemWnd")
	local tData = { }
	local sSprite = nil 
	local bOnlyAdd = nil
		
	if itemOld == nil then 
	   	if tGear.gear[nGearId][self.nSlot] then
			
			local sItemLink = tGear.gear[nGearId][self.nSlot]
			local oItem = lGear._SearchInBag(sItemLink)
           		
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
		if itemOld:GetChatLinkString() == tGear.gear[nGearId][self.nSlot] then
			tData = { item = itemOld }
			sSprite = itemOld:GetIcon()
			
		elseif itemOld:GetChatLinkString() ~= tGear.gear[nGearId][self.nSlot] then	
			bOnlyAdd = true
		end
    end
	
    if bOnlyAdd then
		tData = { slot = self.nSlot }
		sSprite = ""
		sReplace = ""
		sBy = L["G_UPDATE_ADD"]
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
					
	local sGearName = tGear.gear[nGearId].name
	self.UpdateWnd:FindChild("SetTargetTxt"):SetTextRaw(L["G_UPDATE"] .. "[" .. sGearName .. "]?" )
			
	if self.Gear_Panel then self.Gear_Panel:Enable(false) end	
	self.bLockForUpdate = true
	self.UpdateWnd:Show(true)
end

-----------------------------------------------------------------------------------------------
-- OnClickUpdate
-----------------------------------------------------------------------------------------------
function Gear:OnClick_Dialog( wndHandler, wndControl, eMouseButton )
		
	local cSelect = wndControl:GetName()
			
	-- update			
	if cSelect == "NoButton" or (cSelect == "CloseButton" and  wndControl:GetData() == "Update") then
	   	    
	    if tGear.gear[self.nGearId][self.nSlot] and self.oOldItemLink == tGear.gear[self.nGearId][self.nSlot] then
			local nBagSlot = lGear._EquipFromBag(self.oOldItemLink)
	    	if nBagSlot then
				self.bReEquipOld = true
	            GameLib.EquipBagItem(nBagSlot + 1)
			end
	    end
	end
	-- update
	if cSelect == "YesButton" then
		tGear.gear[self.nGearId][self.nSlot] = self.oNewItemLink
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", tGear.gear)
	end
	
	self.nSlot = nil
	self.oNewItemLink = nil
	self.oOldItemLink = nil
		
	if self.Gear_Panel then self.Gear_Panel:Enable(true) end
	self.bLockForUpdate = false
	
	if self.UpdateWnd then 
		self.UpdateWnd:Destroy()
		self:Update_AllPreview()
		self:Update_LockItemFrame()
	end	
end

-----------------------------------------------------------------------------------------------
-- UnSelectGear 
-----------------------------------------------------------------------------------------------
function Gear:UnSelectGear()
   
    if self.bStopEquip == false then self.bStopEquip = true end
    if self.nGearId then self.bPreviousGear = self.nGearId end
    self.nGearId = nil
 	self:ShowSelectGear(nil)	
    
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nil, terror = nil })
end

-----------------------------------------------------------------------------------------------
-- IsGearIdExist 
-----------------------------------------------------------------------------------------------
function Gear:IsGearIdExist()
	
    if self.nGearId == nil then 
		self.nGearId = self.bPreviousGear
	end
end

-----------------------------------------------------------------------------------------------
-- GetAllEquipped 
-----------------------------------------------------------------------------------------------
function Gear:_GetAllEquipped()
 
	local uPlayer = GameLib.GetPlayerUnit()
	if uPlayer == nil then return nil end
	
	local tEquippedItems = uPlayer:GetEquippedItems()
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

-----------------------------------------------------------------------------------------------
-- _SaveAllEquipped 
-----------------------------------------------------------------------------------------------
function Gear:_SaveAllEquipped(tEquipped, nGearId)
 
	local tEquipped = tEquipped
	local nGearId = nGearId
	local bIsNewGear = false
		
	if nGearId == nil then 		     	
		
		 local nGear = lGear.TableLength(tGear.gear)  
			
		 for _=1, nGear do  
		    if tGear.gear[1] == nil then nGearId = 1 
		    else 
				if tGear.gear[_ + 1] == nil then nGearId = _ + 1 end
			end	
		 end
		
		 if nGear == 0 then nGearId = 1 end  
		 bIsNewGear = true	
	end	

	tGear.gear[nGearId] = {} 			 
    tGear.gear[nGearId] = tEquipped      
    tGear.gear[nGearId].las = {} 		
   	    
    if tGear.gear[nGearId].macro == nil then
    		tGear.gear[nGearId].macro = self:_AddMacroToGear(nGearId, nil)
    end
		
	return nGearId, bIsNewGear 
end

-----------------------------------------------------------------------------------------------
-- _SetGearName 
-----------------------------------------------------------------------------------------------
function Gear:_SetGearName(sNickName, nGearId)

    local sNickName = sNickName
	local nGear = lGear.TableLength(tGear.gear)  
	
	if sNickName == nil then sNickName = L["G_TABNAME"] .. " " .. nGearId end
 	sNickName = sNickName:match("^%s*(.-)%s*$") 
	
	for _,oGear in pairs(tGear.gear) do
		
		if oGear.name then		
		
			local sGearName = oGear.name
	   		local nGearName = string.len(sGearName)
	 		local nLen = string.len(sNickName) 
	    	local nMatchName = string.find(sGearName, sNickName)
	
	    	if nGearName == nLen and nMatchName then
				sNickName = " "
	    	end 
		end
	end
 		
	tGear.gear[nGearId].name = sNickName 
	return sNickName	
end

-----------------------------------------------------------------------------------------------
-- _RemoveItem
-----------------------------------------------------------------------------------------------
function Gear:_RemoveItem(nGearId, nSlot)
	 
	if tGear.gear[nGearId][nSlot] then 
		tGear.gear[nGearId][nSlot] = nil 
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", tGear.gear)
	end
end

-----------------------------------------------------------------------------------------------
-- _DeleteGear 
-----------------------------------------------------------------------------------------------
function Gear:_DeleteGear(nGearId)
 
	if tGear.gear[nGearId] then 
		tGear.gear[nGearId] = nil 
	end
	
	local tGearUpdate = self:GetGear()
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_DELETE", nGearId, tGearUpdate, nil, nil)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_DELETE", nGearId)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", tGear.gear)
	
	
	-- cleanup saved
    for _, pOption in pairs(tUI_Setting) do

		if tUI_Setting[_][1].Saved then
			-- toggle_unique
			if tonumber(tUI_Setting[_][1].Saved) then
				if tUI_Setting[_][1].Saved == nGearId then tUI_Setting[_][1].Saved = nil end
			else	
				-- push	
				if tUI_Setting[_][1].Saved[nGearId] then tUI_Setting[_][1].Saved[nGearId] = nil end
			end
		end 		
	end
end

-----------------------------------------------------------------------------------------------
-- _EquipGear 
-----------------------------------------------------------------------------------------------
function Gear:_EquipGear(nGearId)
	
    self.bStopEquip = true
    
    for _, oLink in pairs(tGear.gear[nGearId]) do
			    
		local nSlot = tonumber(_)
									
		-- Search only item have not already checked
	    if nSlot and tItemSlot[nSlot].bInSlot == false then
			
			local sItemLink = oLink
			local nBagSlot = lGear._EquipFromBag(sItemLink)
						
			-- Keep trace to item equipped or not found already check
			tItemSlot[nSlot].bInSlot = true
			self.nEquippedCount = self.nEquippedCount + 1
																											       			
			if nBagSlot then 
					       			
		    	self.bStopEquip = false
				GameLib.EquipBagItem(nBagSlot + 1)
							
				return
			else
				-- to check missing item after equip a gear set for item not found in bag    
				if self.nEquippedCount == self.nGearCount then self:_CheckEquipped(nGearId) end
			end	 
		end
	end	
end

-----------------------------------------------------------------------------------------------
-- _CheckEquipped
-----------------------------------------------------------------------------------------------
function Gear:_CheckEquipped(nGearId)

    if nGearId == nil then 
    	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nil, terror = nil })
		return 
	end

   -- get equipped items	
   local tActualSet = self:_GetAllEquipped()
   local bError = false
   local tError = {}	
   	
   for _, oLink in pairs(tGear.gear[nGearId]) do
		-- filter to prevent not array returned in self:_GetAllEquipped() if unit == nil	
		if tActualSet == nil then break end
		if tonumber(_) then	
			if tActualSet[_] ~= oLink then
				tError[_] = false 
				bError = true
							
			elseif tActualSet[_] == oLink then	
				tError[_] = true
			end
		end	
	end
	
	-- no error, we send nothing
	if not bError then tError = nil	end
	-- event fired after equip a specific set ngearid
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_AFTER_EQUIP", nGearId, nil, nil, tError)
    Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nGearId, terror = tError })	
end

-----------------------------------------------------------------------------------------------
-- _AddMacroToGear 
-----------------------------------------------------------------------------------------------
function Gear:_AddMacroToGear(nGearId, sNickName)

   if sNickName == nil then sNickName = L["G_TABNAME"] .. nGearId end
	
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
-----------------------------------------------------------------------------------------------
function Gear:_SaveMacro(tParam)
    MacrosLib.SetMacroData( tParam.nId, tParam.bGlobal, tParam.sName, tParam.sSprite, tParam.sCmds )
    MacrosLib:SaveMacros()
end

-----------------------------------------------------------------------------------------------
-- _DeleteMacro 
-----------------------------------------------------------------------------------------------
function Gear:_DeleteMacro(nMacroId)
   
    if nMacroId == nil then return end  
   
    MacrosLib.DeleteMacro(nMacroId)
 	MacrosLib:SaveMacros()
end

-----------------------------------------------------------------------------------------------
-- _RenameMacro 
-----------------------------------------------------------------------------------------------
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
		tGear.gear[nGearId].macro = self:_AddMacroToGear(nGearId, sNickName)
	end
end

-----------------------------------------------------------------------------------------------
-- Collapse_AllPreview 
-----------------------------------------------------------------------------------------------
function Gear:Collapse_AllPreview(bCheck)
   
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
    	
    for _=1, #tChildren do
        		
		local wnd = tChildren[_]:FindChild("Preview_Btn")
		
		-- open or close preview only if not already in bcheck state
		if bCheck ~= wnd:IsChecked() then 
			wnd:SetCheck(bCheck)
			self:OnCheckPreview( nil, wnd, 2)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- SetPreviewItem 
-----------------------------------------------------------------------------------------------
function Gear:SetPreviewItem(nGearId, wndControl)
    
	local wndItem_Frame = wndControl:FindChild("Item_Frame")

    for _, oSlot in pairs(tItemSlot) do
  	   
		local wndItem = Apollo.LoadForm(self.xmlDoc, "ItemWnd", wndItem_Frame, self)
		-- add pixie for item icon
		local tOptions = {
  							loc = {
    								fPoints = {0,0,1,1},
    								nOffsets = {5,5,-5,-5},
  						  		  },
  						 }
		wndItem:AddPixie(tOptions) 
				
		self.tData = { slot = _,}
		wndItem:SetData(self.tData) 
	end	
		
	wndItem_Frame:ArrangeChildrenTiles()
end

-----------------------------------------------------------------------------------------------
-- Update_AllPreview 
-----------------------------------------------------------------------------------------------
function Gear:Update_AllPreview()

    -- check actual equipped profile
    self:_CheckEquipped(self.nGearId)
  
    
    if self.Gear_Panel == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   		
    for _=1, #tChildren do
		
		local bChecked = tChildren[_]:FindChild("Preview_Btn"):IsChecked()
       
		-- if preview is open set all item prewiew and alert
		if bChecked then 
			
			local nGearId = tChildren[_]:GetData()
 		    local wndControl =  tChildren[_]
			self:Update_PreviewItem(nGearId, wndControl)
		else
			-- preview closed update only alert
			self:CheckMissing(tChildren[_])
		end
    end
end

-----------------------------------------------------------------------------------------------
-- Update_PreviewItem (set all icon for each item in preview frame)
-----------------------------------------------------------------------------------------------
function Gear:Update_PreviewItem(nGearId, wndControl)
	
	self.bMenAtWork = true
	local tChildren = wndControl:FindChild("Item_Frame"):GetChildren()

	-- alert level to set button macro color status for missing or not item	
	local nLevel = 1
   	local nAlert = 1
			
    for _=1, #tChildren do
		
		local nSlot = tChildren[_]:GetData().slot	
		local wndItem = tChildren[_]
		local sSprite = nil
		local nOpacity = nil
						
		if tGear.gear[nGearId][nSlot] then   
			
		    -- 0 = not find
			-- 1 = equipped
			-- 2 = bag
			-- 3 = bank
		   
			-- search item
			local sItemLink = tGear.gear[nGearId][nSlot]
			local tItemFind = self:FindItem(sItemLink)
			
			-- we have find item
			if tItemFind then 
	        	 
	            if tItemFind.find == 2 then -- in bag
					nOpacity = 0.3
					nLevel = 1
				end	
				
				if tItemFind.find == 1 then -- equipped
					nOpacity = 1.0
					nLevel = 1
				end	
				
				if tItemFind.find == 3 then -- in bank
					nOpacity = 0.3
					nLevel = 2
				end	
				
				-- set data 
				sSprite = tItemFind.item:GetIcon()
	           	self.tData = { slot = nSlot, item = tItemFind.item, }
			
			else -- missing
				sSprite = "ClientSprites:LootCloseBox_Holo"
				self.tData = { slot = nSlot,}
				nOpacity = 1.0
				nLevel = 3
			end
					
		-- slot with no item		
		else
			sSprite = tItemSlot[nSlot].sIcon
			self.tData = { slot = nSlot,}
			nOpacity = 0.3
			nLevel = 1
		end
		
		-- update item 
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
				
		-- keep always high alert level 
		if nLevel >= nAlert then nAlert = nLevel end
			
	end	
	-- set alert color 
	self:Update_Alert(wndControl, nAlert) 
		
	wndControl:FindChild("Item_Frame"):ArrangeChildrenTiles()
	self.bMenAtWork = false
end

-----------------------------------------------------------------------------------------------
-- Update_LockItemFrame
-----------------------------------------------------------------------------------------------
function Gear:Update_LockItemFrame()
    
    if self.Gear_Panel == nil then return end
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
   		
    for _=1, #tChildren do
		
		local bChecked = tChildren[_]:FindChild("Preview_Btn"):IsChecked()
       
		if bChecked then 
			
			local nGearId = tChildren[_]:GetData()
 		    local wndControl =  tChildren[_]
			self:Update_LockItem(nGearId, wndControl)
		end
    end
end

-----------------------------------------------------------------------------------------------
-- Update_LockItem 
-----------------------------------------------------------------------------------------------
function Gear:Update_LockItem(nGearId, wndControl)
	
	local tChildren = wndControl:FindChild("Item_Frame"):GetChildren()
			
    for _=1, #tChildren do
		
		local nSlot = tChildren[_]:GetData().slot		
		local wndItem = tChildren[_]
		local bDelete = self.bLockDel
		
		-- slot with no item				
		if tGear.gear[nGearId][nSlot] == nil then   
			bDelete = false
		end
		
		-- update lock
		wndItem:FindChild("Delete_btn"):Show(bDelete)
	end	
end

-----------------------------------------------------------------------------------------------
-- Update_UI_Setting 
-----------------------------------------------------------------------------------------------
function Gear:Update_UI_Setting()
	
	if self.Gear_Panel == nil then return end	
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
			
	for _=1, #tChildren do
		
		local nGearId = tChildren[_]:GetData()
		self:Remove_UI_Settings(tChildren[_])
		self:Set_UI_Settings(nGearId, tChildren[_])
	end	
end

-----------------------------------------------------------------------------------------------
-- Remove_PreviewItem 
-----------------------------------------------------------------------------------------------
function Gear:Remove_PreviewItem(wndControl)
  	
	local wndFrame = wndControl:FindChild("Item_Frame")
	wndFrame:DestroyChildren()
end

-----------------------------------------------------------------------------------------------
-- Remove_UI_Settings 
-----------------------------------------------------------------------------------------------
function Gear:Remove_UI_Settings(wndControl)
  	
	local wndFrame = wndControl:FindChild("Plugin_Frame")
	wndFrame:DestroyChildren()
end

-----------------------------------------------------------------------------------------------
-- CheckMissing 
-----------------------------------------------------------------------------------------------
function Gear:CheckMissing(wndControl)
  
	local nLevel = 1
   	local nAlert = 1
	local nGearId = wndControl:GetData() 
										
		for _, sItemLink in pairs(tGear.gear[nGearId]) do
		   			    
			if tonumber(_) then	 -- nSlot
				-- search item
				local tItemFind = self:FindItem(sItemLink)
			
				-- we have find item
				if tItemFind then 
	        		if tItemFind.find == 2 then -- in bag
						nLevel = 1
					end	
				
					if tItemFind.find == 1 then -- equipped
						nLevel = 1
					end	
				
					if tItemFind.find == 3 then -- in bank
						nLevel = 2
					end	
				else -- missing
					nLevel = 3
				end
		
				
				-- keep always high alert level for all items
				if nLevel >= nAlert then nAlert = nLevel end
			end
		end
			
	-- set alert color
	self:Update_Alert(wndControl, nAlert)
end

-----------------------------------------------------------------------------------------------
-- Update_Alert (set
-----------------------------------------------------------------------------------------------
function Gear:Update_Alert(wndControl, nAlert)
	
	local tAlert = { 
				     [1] = { color = "xkcdApple", icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Green", }, -- green, all item are in inventory bag
				     [2] = { color = "White",     icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Blue", },  -- blue, some item are in bank
				     [3] = { color = "red",       icon = "Crafting_CircuitSprites:btnCircuit_SquareGlass_Red", },   -- red, some item are missing
			       } 	
		
	-- set alert color
	local wnd = wndControl:FindChild("Macro_Btn")
	wnd:ChangeArt(tAlert[nAlert].icon)
	wnd:SetBGColor(tAlert[nAlert].color)
end

-----------------------------------------------------------------------------------------------
-- FindItem 
-----------------------------------------------------------------------------------------------
function Gear:FindItem(sItemLink)
    		
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
-- OnSlash
-----------------------------------------------------------------------------------------------
function Gear:OnSlash(strCommand, strOption)
	   
    local nGearId = tonumber(strOption)	
    if self.bLockForUpdate == true then return end

	-- /gear 1 (equip profile)
	if nGearId and nGearId >= 1 and tGear.gear[nGearId] then 
	   
	    -- request to equip a set come from gear ui
	   	
		self:ShowSelectGear(nGearId)	
	    self:IniEquipGear(nGearId, true)
		self.bIsGearSwitch = true
		self:Align_LAS(nGearId)
	
	-- /gear unselect (unselect actual profile)	
	elseif strOption == "unselect" then	
		self:UnSelectGear()
		
	-- /gear sett (show settings)	
	elseif strOption == "sett" then	
		self:ShowSettings()
	
	-- /gear (show/hide)		
	elseif nGearId == nil then 
		self:OnShowGear()	
	end
end

---------------------------------------------------------------------------------------------------
-- CreatePanel
---------------------------------------------------------------------------------------------------
function Gear:CreatePanel(wndTarget)
	
    if self.Gear_Panel == nil then 
		
		self.Gear_Panel = Apollo.LoadForm(self.xmlDoc, "Gear_Frame", self.wndTarget, self)
		self.Gear_Panel:FindChild("Add_Btn"):SetText(L["G_ADD"])
		self.Gear_Panel:FindChild("ReloadUI_Btn"):SetText(L["G_RELOADUI"])
						
		-- add 'gear' logo
		local tOptions = {
  							strSprite = "NewSprite:Gear_Logo",
  							cr = {a=0.1,r=0,g=0,b=0},
  							loc = {
    								fPoints = {0.5,0,0.5,0},
    								nOffsets = {-109,220,86,492},
  						  		  },
  						 }
						
		self.Gear_Panel:AddPixie(tOptions) 
				
		-- set lasmod		
		self:Align_LAS_Mod(self.nLASMod, self.bLock)
		self:RestoreGear()
	end
end

---------------------------------------------------------------------------------------------------
-- CreateGearWnd
---------------------------------------------------------------------------------------------------
function Gear:CreateGearWnd(nGearId, bIsNewGear)
	 
	self.wndSet = self.wndTarget:FindChild("Set_Frame")
	local wndNewSet = Apollo.LoadForm(self.xmlDoc, "SetTemplate_Frame", self.wndSet, self)	
	wndNewSet:SetData(nGearId)
	wndNewSet:SetName("gear_" .. nGearId)
	
	local wndMacro = wndNewSet:FindChild("Macro_Btn")
	local nIdMod = self.nLASMod
	local nLasId = tGear.gear[nGearId].las[nIdMod]
	if nLasId then wndMacro:SetText(nLasId) end
		
	-- add plugins 
	self:Set_UI_Settings(nGearId, wndNewSet)
	
	local sGearName = tGear.gear[nGearId].name
	if sGearName == nil then
		sGearName = self:_SetGearName(nil, nGearId)
	end	
	local wndGearName = wndNewSet:FindChild("GearName_Btn")
	wndGearName:SetPrompt(L["G_SETNAME"])
	wndGearName:SetPromptColor("xkcdBluegreen")
	wndGearName:SetMaxTextLength(20)
	wndGearName:SetTextRaw(sGearName)
				
	self:LockDelete()
	self.wndSet:ArrangeChildrenVert()
		
	if bIsNewGear then
	
		self:ShowSelectGear(nGearId)
		self.nGearId = nGearId
		
		local tGearUpdate = self:GetGear()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_CREATE", nGearId, tGearUpdate, nil, nil)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_GEAR", tGear.gear)
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHECK_GEAR", { ngearid = nGearId, terror = nil })
	end
end

---------------------------------------------------------------------------------------------------
-- OnClickAddNewSet
---------------------------------------------------------------------------------------------------
function Gear:OnClickAddNewSet( wndHandler, wndControl, eMouseButton )
  
	local tToSave = self:_GetAllEquipped()  
	local nGearId, bIsNewGear = self:_SaveAllEquipped(tToSave, nil) 
	self:CreateGearWnd(nGearId, bIsNewGear)
end

---------------------------------------------------------------------------------------------------
-- OnGearNameValidate 
---------------------------------------------------------------------------------------------------
function Gear:OnGearNameValidate( wndHandler, wndControl, strText )
  
    local nGearId = wndControl:GetParent():GetData()
   	local sNewName = strText:match("^%s*(.-)%s*$")
	local sOldName = tGear.gear[nGearId].name
	
	if sNewName == sOldName then return end

	local sGearName = self:_SetGearName(strText, nGearId)
	wndControl:SetTextRaw(sGearName)
	self:_RenameMacro(nGearId, tGear.gear[nGearId].macro, sGearName)
	
	local tGearUpdate = self:GetGear()
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_RENAME", nGearId, tGearUpdate, nil, nil)
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_RENAME", tGear.gear)
end

---------------------------------------------------------------------------------------------------
-- ShowSelectGear 
---------------------------------------------------------------------------------------------------
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
	
    if self.bStopEquip == false then self.bStopEquip = true end

    for _, oSlot in pairs(tItemSlot) do
			tItemSlot[_].bInSlot = false
	end

	self.nGearId = nGearId
    self.bStopEquip = false
	-- var for check missing item after equip a gear set
	self.nEquippedCount = 0
	self.nGearCount = lGear.TableLength(tGear.gear[nGearId]) 
	self:_EquipGear(nGearId)
	
	local tGearUpdate = self:GetGear()
	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_CHANGE", nGearId, tGearUpdate, nil, nil)
	
	-- send to other plug-in, gear have equipped a set, and this request come from gear or external addon
	local tData = { ngearid = nGearId, fromui = bComeFromUI, }
	Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_CHANGE", tData )
end

---------------------------------------------------------------------------------------------------
-- OnGearEquip 
---------------------------------------------------------------------------------------------------
function Gear:OnGearEquip( wndHandler, wndControl, eMouseButton )

	local nGearId = wndControl:GetParent():GetData()
	-- request to equip a set come from gear ui
			
	self:ShowSelectGear(nGearId)	
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
---------------------------------------------------------------------------------------------------
function Gear:OnGearDelete( wndHandler, wndControl, eMouseButton )

	if (eMouseButton == 0) then	

    	local nGearId = wndControl:GetParent():GetData()
       	local nMacroId = tGear.gear[nGearId].macro
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
---------------------------------------------------------------------------------------------------
function Gear:OnItemRemove( wndHandler, wndControl, eMouseButton )
	
	if (eMouseButton == 0) then	

    	local nGearId = wndControl:GetParent():GetParent():GetParent():GetData()
       	local nSlot = wndControl:GetParent():GetData().slot
    	
		self:_RemoveItem(nGearId, nSlot) 
		self:Update_PreviewItem(nGearId, wndControl:GetParent():GetParent():GetParent())
		self:Update_LockItem(nGearId, wndControl:GetParent():GetParent():GetParent())
	end	
end

---------------------------------------------------------------------------------------------------
-- OnClickReloadUI 
---------------------------------------------------------------------------------------------------
function Gear:OnClickReloadUI( wndHandler, wndControl, eMouseButton )
	RequestReloadUI()
end

---------------------------------------------------------------------------------------------------
-- OnMacroBeginDragDrop
---------------------------------------------------------------------------------------------------
function Gear:OnMacroBeginDragDrop( wndHandler, wndControl, x, y, bDragDropStarted )

	if wndHandler ~= wndControl then return false end
	local nGearId = wndControl:GetParent():GetData()
	local nMacroId = tGear.gear[nGearId].macro

	Apollo.BeginDragDrop(wndControl, "DDMacro", wndControl:GetSprite(), nMacroId)
	return true
end

---------------------------------------------------------------------------------------------------
-- OnSave
---------------------------------------------------------------------------------------------------
function Gear:OnSave(eLevel)
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end 
			
	-- 'gear settings', get each parent and save only child index number
	local tData_settings = {} 
	for sParent, peParent in pairs(tOption) do
	   	for _, peChild in pairs(peParent) do
			-- save only core option
			if peParent.plugin then break end
			tData_settings[_] = peChild.bActived
		end
	end
	
	-- 'size', get size for modal window
	self:SaveSize(self.wndGear, tSize.modal)
	local tData_size = tSize.modal.anchor 
		
	local tData = {}
	      tData.config = {
	                       lastgear = self.nGearId,
	                         lasmod = self.nLASMod, 
						   settings = tData_settings,
						       size = tData_size,
							    ver = G_VER,
								
	                     }
		
	if lGear.TableLength(tGear.gear) ~= 0 then 
		tData.gear = tGear.gear 
	end

	return tData
end 

---------------------------------------------------------------------------------------------------
-- OnRestore
---------------------------------------------------------------------------------------------------
function Gear:OnRestore(eLevel,tData) 
	
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end
	
	-- gear set		
	if tData.gear then tGear.gear = tData.gear end
	
	-- lastgear		
	if tData.config.lastgear and tData.config.lastgear >= 1 then 
		if tGear.gear[tData.config.lastgear] then
			if tData.config.lastgear then self.nGearId = tData.config.lastgear end
		else
			self.nGearId = nil
		end	
	end	
	
	-- lasmod	
	if tData.config.lasmod then	
		self.nLASMod = tData.config.lasmod
	end
	
	-- settings
	if tData.config.settings then
    	for sParent, peParent in pairs(tOption) do
			for _, peChild in pairs(peParent) do
				-- if index number exist then restore child from actual parent
			    if tData.config.settings[_] then tOption[sParent][_].bActived = tData.config.settings[_] end
			end
        end 	
	end 
	
	-- size
	if tData.config.size then
		tSize.modal.anchor = tData.config.size 
    end
end 

---------------------------------------------------------------------------------------------------
-- RestoreGear
---------------------------------------------------------------------------------------------------
function Gear:RestoreGear() 

    if lGear.TableLength(tGear.gear) == 0 then return end 
	
	for _, peCurrent in pairs(tGear.gear) do
		self:CreateGearWnd(_, false)
	end
	
	self:ShowSelectGear(self.nGearId)
	self:Update_AllPreview()
	self:Update_UI_Setting()
end

---------------------------------------------------------------------------------------------------
-- OnCheckPreview
---------------------------------------------------------------------------------------------------
function Gear:OnCheckPreview( wndHandler, wndControl, eMouseButton )
   
	local nGearId = wndControl:GetParent():GetData()
	local wndTemplate = wndControl:GetParent()
	local nHeight = 80
							
	if wndControl:IsChecked() then  
	
		nHeight = 186 
		self:SetPreviewItem(nGearId, wndTemplate)
		self:Update_PreviewItem(nGearId, wndTemplate)
		self:Update_LockItem(nGearId, wndTemplate)
	else
		self:Remove_PreviewItem(wndTemplate)
	end
		
	local l,t,r,b = wndTemplate:GetAnchorPoints()
	wndTemplate:SetAnchorOffsets(l, t, r, nHeight)
	self.wndSet:ArrangeChildrenVert()
end

---------------------------------------------------------------------------------------------------
-- OnLockDeleteCheck
---------------------------------------------------------------------------------------------------
function Gear:OnLockDeleteCheck( wndHandler, wndControl, eMouseButton )
	
	self.bLockDel = wndControl:IsChecked()
	wndControl:SetCheck(self.bLockDel)
	self:LockDelete()
	self:Update_LockItemFrame()
end

---------------------------------------------------------------------------------------------------
-- LockDelete
---------------------------------------------------------------------------------------------------
function Gear:LockDelete()
		
	local tChildren = self.Gear_Panel:FindChild("Set_Frame"):GetChildren()
    for _=1, #tChildren do
        tChildren[_]:FindChild("Delete_Btn"):Enable(self.bLockDel)
	end
end

---------------------------------------------------------------------------------------------------
-- OnClickForUnselectGear
---------------------------------------------------------------------------------------------------
function Gear:OnClickForUnselectGear( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	self:UnSelectGear()
end

---------------------------------------------------------------------------------------------------
-- OnCollapseCheck
---------------------------------------------------------------------------------------------------
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
-- OnLasModClick 
---------------------------------------------------------------------------------------------------
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
						[1] = L["G_LASMOD_1"],
						[2] = L["G_LASMOD_2"], 
						[3] = L["G_LASMOD_3"],
					}
				
	wndControl:SetText(tLASMod[nIdMod])
	self:UpdateText_LAS(nIdMod)
		
	if lGear.TableLength(tGear.gear) == 0 or self.nGearId == nil then return end 
	
	if not self.bNoSwitch then 
		self.bIsGearSwitch = true
		self.bNoSwitch = false
	end	
    	
	self:Align_LAS(self.nGearId)
end

---------------------------------------------------------------------------------------------------
-- OnClick_UI_Settings (all ui settings button clik come here)
---------------------------------------------------------------------------------------------------
function Gear:OnClick_UI_Settings( wndHandler, wndControl, eMouseButton )

	local sType = wndControl:GetData().type		-- get button type (toggle_unique, toggle, push, none) 
	local sOwner = wndControl:GetData().owner	-- get plugin owner
	local nUIId = wndControl:GetData().uiid		-- get index of ui setting array, to identify control
	
	local nGearId = wndControl:GetData().ngearid
	local nNewSelect, nOldSelect 	

	----------------------------------------------------------------------------------------------	
	-- like mount button..
	if sType == "toggle_unique" then
		
		-- get selected or not
		local bChecked = wndControl:IsChecked()
			
		-- selected
		if bChecked then
					
			-- get/save gearid selected to use with mount
			nNewSelect = nGearId
			nOldSelect = tUI_Setting[tPlugIn[sOwner].settingname][nUIId].Saved
						
			-- unselect old selected 
			if nOldSelect and tGear.gear[nOldSelect] then 
						    
				if self.Gear_Panel:FindChild("Set_Frame"):FindChild("gear_" .. nOldSelect):FindChild(sOwner .. "_" .. nUIId) then	
					self.wndPrev_toggle_unique = self.Gear_Panel:FindChild("Set_Frame"):FindChild("gear_" .. nOldSelect):FindChild(sOwner .. "_" .. nUIId)
					-- update ui button status color
					self:Set_UI_ColorStatus(self.wndPrev_toggle_unique, false)
					self.wndPrev_toggle_unique:SetCheck(false)
				end
			end
	    								
		-- unselected
		elseif not bChecked then
			-- init mount selected to nil
			nNewSelect = nil
			nOldSelect = nil
		end	
				
		-- update ui button status color
		self:Set_UI_ColorStatus(wndControl, bChecked)
								
		-- save selected ngearid to tui_setting
	    tUI_Setting[tPlugIn[sOwner].settingname][nUIId].Saved = nNewSelect
		-- we send to plugin owner the new status for actual plugin control
		local tUISetting = { owner = sOwner, uiid = nUIId, saved = nNewSelect, }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_SETTING", tUISetting)
	end
	----------------------------------------------------------------------------------------------
		
	if sType == "toggle" then
		--
	end
 
	-- like armory button..
	if sType == "push" then
		-- we send to plugin owner the action to set for actual plugin control
		local tUISetting = { owner = sOwner, uiid = nUIId, ngearid = nGearId, name = tGear.gear[nGearId].name}
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_UI_ACTION", tUISetting)
	end

	if sType == "none" then
		--
	end
end

---------------------------------------------------------------------------------------------------
-- Plugin_OnClick (All click event from plugin come in)
---------------------------------------------------------------------------------------------------
function Gear:Plugin_OnClick( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
		
	-- get target control for filter
	sControl = wndControl:GetName()
	
	-- click in plugin icon to turn on/off plugin in setting panel
	if sControl == "Plugin_wnd" then
		-- get title parent wnd
		local cParent = wndControl:GetParent():GetParent()
		-- get plugin name
		local sOwner = wndControl:GetData().name
		-- set new plugin status to on or off
		tPlugIn[sOwner].on = not tPlugIn[sOwner].on
						
		-- get all children option and set to enable/disable
		local tChildren = cParent:GetChildren()
		for _=1,#tChildren do
			if tChildren[_]:GetName() ~= "FrameTitle_wnd" then 
				-- enable or disable
				tChildren[_]:Enable(tPlugIn[sOwner].on)
			else
				-- change title color
				tChildren[_]:SetTextColor(tColor.plugin[tostring(tPlugIn[sOwner].on)])
			end
		end
		
		-- we send to plugin owner the new status on or off	
		local tSetting = { owner = sOwner, on = tPlugIn[sOwner].on }
		Event_FireGenericEvent("Generic_GEAR_PLUGIN", "G_ON", tSetting)
				
		self:Update_UI_Setting()
	end
end

---------------------------------------------------------------------------------------------------
-- IniWindow (create/destroy gear window)
---------------------------------------------------------------------------------------------------
function Gear:IniWindow(oWndTarget)
		
	-- toggle gear modal window (close)
	if self.wndGear and self.bModal then
		self:SaveSize(self.wndGear, tSize.modal)
		self.wndGear:Destroy()
		self.wndGear, self.Gear_Panel = nil, nil
		return
	-- create modal window (open)
	elseif self.wndGear == nil and self.bModal then
		self.wndGear = oWndTarget
		self.wndGear:FindChild("TitleWnd"):SetText(L["G_TABNAME"])
		self.wndTarget = self.wndGear:FindChild("OptionWnd_Frames")
		self.wndTarget:SetStyle("VScroll", false) 
		self.wndGear:FindChild("CloseBtn"):SetData("modal")
		self:SetSize(self.wndGear, tSize.modal)
		self.bLockDel = false
		self:CreatePanel(self.wndTarget)
		self.wndGear:Show(true)
	-- create non modal window (only once)
	elseif not self.bModal then
		self.wndTarget = oWndTarget
		self.wndTarget:SetStyle("VScroll", false) 
		self.bLockDel = false
		self:CreatePanel(self.wndTarget)
		self.wndTarget:Show(true)
	end
end

---------------------------------------------------------------------------------------------------
-- SetSize
---------------------------------------------------------------------------------------------------
function Gear:SetSize(oWnd, tWndSize)
  
	-- we get size from houston UI form
	local nWidth = oWnd:GetWidth() 
	local nHeight = oWnd:GetHeight()
	local nLimitWidth, nLimitHeight = tWndSize.max.width, tWndSize.max.height
	local nScreenWidth, nScreenHeight = Apollo.GetScreenSize()
	
	-- set size limit
    oWnd:SetSizingMinimum(nWidth, nHeight)
	-- if no max size limit
	if tWndSize.max.width == 0 and tWndSize.max.height == 0 then 
		nLimitWidth, nLimitHeight = nScreenWidth, nScreenHeight
	elseif tWndSize.max.width ~= 0 then
		nLimitHeight = nScreenHeight
	end
	oWnd:SetSizingMaximum(nLimitWidth, nLimitHeight) 
		
	-- restore anchor/size saved
	if tWndSize.anchor.b == 0 then return end
	oWnd:SetAnchorOffsets(tWndSize.anchor.l, tWndSize.anchor.t, tWndSize.anchor.r, tWndSize.anchor.b)
end

---------------------------------------------------------------------------------------------------
-- SaveSize
---------------------------------------------------------------------------------------------------
function Gear:SaveSize(oWnd, tWndSize)
 	if oWnd then 
		tWndSize.anchor.l, tWndSize.anchor.t, tWndSize.anchor.r, tWndSize.anchor.b = oWnd:GetAnchorOffsets()
	end
end

---------------------------------------------------------------------------------------------------
-- OnWndMove
---------------------------------------------------------------------------------------------------
function Gear:OnWndMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )

	if wndControl:FindChild("CloseBtn"):GetData() == "modal" then
		self:SaveSize(self.wndGear, tSize.modal)
	else
		self:SaveSize(self.wndOption, tSize.settings)
	end	
end

---------------------------------------------------------------------------------------------------
-- OnItemToolTip
---------------------------------------------------------------------------------------------------
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
		wndControl:SetTooltip(tItemSlot[oSlot].sToolTip)
	end
end

---------------------------------------------------------------------------------------------------
-- OnLeaveItemToolTip
---------------------------------------------------------------------------------------------------
function Gear:OnLeaveItemToolTip( wndHandler, wndControl, x, y )
	wndControl:SetTooltipDoc(nil)
end

---------------------------------------------------------------------------------------------------
-- OnShowGear_UI_ToolTips
---------------------------------------------------------------------------------------------------
function Gear:OnShowGear_UI_ToolTips( wndHandler, wndControl, x, y )
		
	local tData = wndControl:GetData()
	if tData == nil then return end 
	
	local xml = XmlDoc.new()
	local sPlugin = tPlugIn[tData.owner].settingname
	local sTooltips = {}
		
	if tData then
		local tSaved = tUI_Setting[tPlugIn[tData.owner].settingname][tData.uiid].Saved
		if tSaved and tonumber(tSaved) == nil and tSaved[tData.ngearid] then 
				
			-- if saved is a data array	
			if tSaved[tData.ngearid].target[1] then
				sTooltips = tSaved[tData.ngearid].target
								
			-- single data
			else
				sTooltips[1] = tSaved[tData.ngearid].target
			end
		end
	end
	-- set tooltip	
	xml:AddLine(sPlugin, "xkcdAmber", "CRB_InterfaceSmall", "Left")	
	for _=1, #sTooltips	do
		xml:AddLine(sTooltips[_], "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
	end
	
	wndControl:SetTooltipDoc(xml)
end

---------------------------------------------------------------------------------------------------
-- OnShowGear_ToolTips
---------------------------------------------------------------------------------------------------
function Gear:OnShowGear_ToolTips( wndHandler, wndControl, x, y )
	local sWndName = wndControl:GetName()
		
	local tToolTipId = {     
							 ["Lock_Btn"] = L["G_LOCK"],
						 ["Collapse_Btn"] = L["G_COLLAPSE"], 
						 ["Unselect_Btn"] = L["G_UNSELECT"],
						   ["Delete_Btn"] = L["G_DELETE"],  
						   ["LasMod_Btn"] = L["G_LASMOD"],
					    }
	
	if tToolTipId[sWndName] then
		wndControl:SetTooltip(tToolTipId[sWndName])
		return
	else
		
		local xml = XmlDoc.new()					
		if sWndName == "Macro_Btn" then 
		
			local nMacro = wndControl:GetParent():GetData()
			local sGear = "\/gear " .. nMacro
		    	
			xml:AddLine(sGear, "xkcdAmber", "CRB_InterfaceSmall", "Left")
	    	xml:AddLine(L["G_MACRO"], "White", "CRB_InterfaceSmall", "Left")
	    			
	    	if self.nLASMod == 3 then
				xml:AddLine(L["G_LASPARTNER"], "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
			else
				xml:AddLine(L["G_LAS"], "White", "CRB_InterfaceSmall", "Left")
	    	end
			
		elseif sWndName == "GearName_Btn" then 
			xml:AddLine(L["G_NAME"], "White", "CRB_InterfaceSmall", "Left")
	    						
		elseif sWndName == "Preview_Btn" then 
	   		xml:AddLine(L["G_PREVIEW"], "White", "CRB_InterfaceSmall", "Left")
	    			
		elseif sWndName == "Plugin_wnd" then
			local sPlugIn = wndControl:GetData().name
						
			xml:AddLine(sPlugIn .. " v" ..tPlugIn[sPlugIn].ver , "White", "CRB_InterfaceSmall", "Left")
	    	xml:AddLine(tPlugIn[sPlugIn].flavor, "xkcdAquaBlue", "CRB_InterfaceSmall", "Left")
	
		elseif sWndName == "Settings_Btn" then
					
			local nPlugIn = lGear.TableLengthBoth(tPlugIn)
			xml:AddLine(nPlugIn .." " .. L["G_UI_SETTINGS"], "xkcdAmber", "CRB_InterfaceSmall", "Left")
					
			for sPlugIn, oPlugIn in pairs(tPlugIn) do
				xml:AddLine(sPlugIn .. " v" ..tPlugIn[sPlugIn].ver, tColor.plugin[tostring(oPlugIn.on)], "CRB_InterfaceSmall", "Left")
	    	end
		end
			
		wndControl:SetTooltipDoc(xml)
	end	
end

-----------------------------------------------------------------------------------------------
-- Gear Instance
-----------------------------------------------------------------------------------------------
local GearInst = Gear:new()
GearInst:Init()