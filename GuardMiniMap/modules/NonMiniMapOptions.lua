require "Apollo"
require "GameLib"
require "Unit"

local NonMiniMapPackage, NonMinimapPackageVersion = "GMM:NonMinimapOptions-1.1", 1

local NonMiniMapOptions	= {}

-----------------------------------------------------------------------------------------------
-- Taxi nodes taken from NavMate
-----------------------------------------------------------------------------------------------
local ktTaxiNodes = {
  Neutral = {
    { nTextId = 351586, nX =   3467, nY =  -940, nZ =   -418, nContinentId = 6,  },
    { nTextId = 351587, nX =   3145, nY = -1041, nZ =    865, nContinentId = 6,  },
    { nTextId = 331373, nX =   1690, nY =  -820, nZ =   2827, nContinentId = 33, },
    { nTextId = 331369, nX =   1591, nY =  -969, nZ =   4142, nContinentId = 33, },
  },
  [Unit.CodeEnumFaction.ExilesPlayer] = {
    { nTextId = 442011, nX =   2069, nY =  -844, nZ =  -1616, nContinentId = 8,  },
    { nTextId = 442097, nX =   2718, nY =  -786, nZ =  -3893, nContinentId = 8,  },
    { nTextId = 197905, nX =   4203, nY = -1044, nZ =  -4006, nContinentId = 6,  },
    { nTextId = 307926, nX =   3801, nY =  -998, nZ =  -4550, nContinentId = 6,  },
    { nTextId = 310145, nX =   2618, nY =  -927, nZ =  -2395, nContinentId = 6,  }, 
    { nTextId = 313222, nX =   5377, nY =  -979, nZ =  -2829, nContinentId = 6,  },
    { nTextId = 313223, nX =   5740, nY =  -848, nZ =  -2611, nContinentId = 6,  },
    { nTextId = 313221, nX =   5107, nY =  -875, nZ =  -2871, nContinentId = 6,  },
    { nTextId = 351524, nX =   4494, nY =  -936, nZ =   -572, nContinentId = 6,  },
    { nTextId = 197956, nX =   5169, nY =  -883, nZ =  -2279, nContinentId = 6,  },
    { nTextId = 310144, nX =   1105, nY =  -943, nZ =  -2496, nContinentId = 6,  }, 
    { nTextId = 310146, nX =   3073, nY =  -920, nZ =  -2980, nContinentId = 6,  },
--    { nTextId = 306975, nX =   3095, nY =  -880, nZ =  -1496, nContinentId = 6,  }, -- camp viridian
    { nTextId = 197911, nX =   3896, nY =  -770, nZ =  -2391, nContinentId = 6,  },
    { nTextId = 563951, nX =    223, nY =  -890, nZ =  -4159, nContinentId = 33, },
    { nTextId = 568692, nX =   3142, nY =  -763, nZ =   2937, nContinentId = 33, },
    { nTextId = 561004, nX =    949, nY =  -924, nZ =     14, nContinentId = 33, },
    { nTextId = 561647, nX =    984, nY =  -970, nZ =  -1744, nContinentId = 33, },
    { nTextId = 519297, nX =   4449, nY =  -712, nZ =  -5673, nContinentId = 19, },
    { nTextId = 519296, nX =   5832, nY =  -495, nZ =  -4907, nContinentId = 19, },
  }, 
  [Unit.CodeEnumFaction.DominionPlayer] = {
    { nTextId = 283647, nX =  -2476, nY = -873, nZ = -1969, nContinentId = 8,  },
    { nTextId = 283651, nX =  -1266, nY = -888, nZ = -1026, nContinentId = 8,  },
    { nTextId = 283649, nX =  -1932, nY = -879, nZ = -2012, nContinentId = 8,  },
    { nTextId = 293816, nX =  -2601, nY = -790, nZ = -3586, nContinentId = 8,  },
    { nTextId = 291768, nX =  -5126, nY = -943, nZ = -1526, nContinentId = 8,  },
    { nTextId = 284862, nX =  -4898, nY = -931, nZ =   -79, nContinentId = 8,  },
    { nTextId = 291769, nX =  -5750, nY = -971, nZ =  -616, nContinentId = 8,  },
    { nTextId = 283650, nX =  -2202, nY = -904, nZ =  -836, nContinentId = 8,  },
    { nTextId = 442557, nX =   1130, nY = -712, nZ = -2009, nContinentId = 8,  },
    { nTextId = 442607, nX =   2713, nY = -787, nZ = -3913, nContinentId = 8,  },
    { nTextId = 293412, nX =  -3385, nY = -882, nZ =  -649, nContinentId = 8,  },
    { nTextId = 351584, nX =   1774, nY = -993, nZ =  -628, nContinentId = 6,  },
    { nTextId = 559601, nX =   2740, nY = -100, nZ =   419, nContinentId = 33, },
    { nTextId = 563950, nX =    223, nY = -890, nZ = -4032, nContinentId = 33, },
    { nTextId = 568600, nX =    372, nY = -954, nZ =  3150, nContinentId = 33, },
    { nTextId = 561645, nX =   1291, nY = -984, nZ = -1751, nContinentId = 33, },
    { nTextId = 519278, nX =   4072, nY = -721, nZ = -5170, nContinentId = 19, },
    { nTextId = 519247, nX =   5296, nY = -495, nZ = -4501, nContinentId = 19, },
  },
}

-----------------------------------------------------------------------------------------------
-- Utility / Helper functions
-- Pulled from NavMate
-----------------------------------------------------------------------------------------------

local function GetAddon(strAddonName)
	local info = Apollo.GetAddonInfo(strAddonName)

	if info and info.bRunning == 1 then 
		return Apollo.GetAddon(strAddonName)
	end
end

-----------------------------------------------------------------------------------------------
--	Initialization and Definitions
-----------------------------------------------------------------------------------------------
function NonMiniMapOptions:Initialize()		
	if not self.gmm then
		self.gmm = Apollo.GetAddon("GuardMiniMap")
	end

	Apollo.RegisterSlashCommand("gmm", "OnNonMiniMapOptions", self)
	self.wndNonMinimapOptions = Apollo.LoadForm(self.gmm.xmlDoc, "NonMiniMapOptions", nil, self)
	self.wndNonMinimapOptions:Show(false)
	
	self.wndNonMinimapOptions:FindChild("MiniMapOpacitySlider"):SetValue(self.gmm.nMapOpacity * 100)
		
	if self.gmm.bShowTaxisOnZoneMap and self.gmm.bShowTaxisOnZoneMap == true then
		self.wndNonMinimapOptions:FindChild("NMMO_TaxisOnMap"):SetCheck(true)
	else
		self.gmm.bShowTaxisOnZoneMap = false
	end
	
	if self.gmm.bHideCoordFrame and self.gmm.bHideCoordFrame == true then
		self.wndNonMinimapOptions:FindChild("NMMO_CoordFrame"):SetCheck(true)
	end
	
	if self.gmm.bShowCoords and self.gmm.bShowCoords == true then
		self.wndNonMinimapOptions:FindChild("NMMO_ShowCoords"):SetCheck(true)
	end
	
	if self.gmm.bShowTime == nil or self.gmm.bShowTime == true then
		self.wndNonMinimapOptions:FindChild("NMMO_ShowTime"):SetCheck(true)
	end
	
	if not self.gmm.strMapFont then
		self.gmm.strMapFont = "CRB_InterfaceSmall_O"
	end
	
	self.wndNonMinimapOptions:FindChild("btnFontSelection"):AttachWindow(self.wndNonMinimapOptions:FindChild("MiniMapFontListing"))
	self.wndNonMinimapOptions:FindChild("btnFontSelection"):SetText(self.gmm.strMapFont)
	self.wndNonMinimapOptions:FindChild("btnFontSelection"):SetFont(self.gmm.strMapFont or "CRB_InterfaceSmall_O")

	
	local tFonts = Apollo.GetGameFonts()
	table.sort(tFonts , function(a,b) return a.name < b.name end)
	
	for idx, fontCurr in pairs(tFonts) do
		local iTop = (idx - 1)*35
		local wndFont = Apollo.LoadForm(self.gmm.xmlDoc, "FontSelectionButton", self.wndNonMinimapOptions:FindChild("NamedFontList"), self)
		wndFont:FindChild("FontSelectionButtonText"):SetText(fontCurr.name)
		wndFont:FindChild("FontSelectionButtonText"):SetFont(fontCurr.name or "CRB_InterfaceSmall_O")
		wndFont:SetAnchorOffsets(0, iTop , 0, iTop  + 35)
		wndFont:SetData(fontCurr)
		bAdded = true
	end


	Apollo.RegisterEventHandler("ToggleZoneMap", 	"HookMainMap", self)
	
	self.HookTimer = ApolloTimer.Create(1.0, true, "OnHookTimer", self)
end

function NonMiniMapOptions:OnNonMiniMapOptions()
	-- /gmm toggles the window
	self.wndNonMinimapOptions:Show(not self.wndNonMinimapOptions:IsVisible())
end

function NonMiniMapOptions:OnHookTimer()
	if g_wndTheZoneMap ~= nil then
		self.HookTimer:Stop()
		self.HookTimer = nil
		
		self:HookMainMap()
	end
end

function NonMiniMapOptions:HookMainMap()
	self.addon = self.addon or GetAddon("ZoneMap")

	if 	self.addon 
		and self.addon.wndZoneMap 
		and self.addon.wndZoneMap:IsValid() then
	
		self:AddTaxiToVisibilityLevels()	
		self:HookContinentButtons()		
		self:UpdateTaxiMarkers()	
	end
end


function NonMiniMapOptions:GetTaxiMapObjectType()
  if not self.eObjectTypeTaxi  and self.addon then
    self.eObjectTypeTaxi  = self.addon.wndZoneMap:CreateOverlayType()
  end

  return self.eObjectTypeTaxi or 969
end

---------------------------------------------------------------------------------------------------
-- NonMiniMapOptions Functions
---------------------------------------------------------------------------------------------------


function NonMiniMapOptions:OnOpacityChanged( wndHandler, wndControl, fNewValue, fOldValue )
	self.gmm.nMapOpacity = fNewValue/100.0
	self.gmm.wndMain:SetOpacity(self.gmm.nMapOpacity)
end


function NonMiniMapOptions:OnNMMO_CloseButton_Clicked( wndHandler, wndControl, eMouseButton )
	self.wndNonMinimapOptions:Show(false)
end

function NonMiniMapOptions:OnNMMO_TaxisOnMap_Check( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowTaxisOnZoneMap = true
end

function NonMiniMapOptions:OnNMMO_TaxisOnMap_Uncheck( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowTaxisOnZoneMap = false
end

function NonMiniMapOptions:OnNMMO_CoordFrame_Check( wndHandler, wndControl, eMouseButton )
	self.gmm.bHideCoordFrame = true
	self.gmm.wndMiniMapCoords:RemoveStyle("Border")

end

function NonMiniMapOptions:OnNMMO_CoordFrame_Uncheck( wndHandler, wndControl, eMouseButton )
	self.gmm.bHideCoordFrame = false
	self.gmm.wndMiniMapCoords:AddStyle("Border")
end

function NonMiniMapOptions:OnShowCoordsCheck( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowCoords = true
	self.gmm.wndMiniMapCoords:Show(true)
end

function NonMiniMapOptions:OnShowCoordsUncheck( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowCoords = false
	self.gmm.wndMiniMapCoords:Show(false)
end

function NonMiniMapOptions:OnFontSelected( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then
		return
	end
	
	self.wndNonMinimapOptions:FindChild("btnFontSelection"):SetText(wndControl:GetData().name)	
	self.wndNonMinimapOptions:FindChild("btnFontSelection"):SetFont(wndControl:GetData().name or "CRB_InterfaceSmall_O")
	self.wndNonMinimapOptions:FindChild("MiniMapFontListing"):Close()
	wndControl:SetCheck(false)
	
	self.gmm:SetMapFont(wndControl:GetData().name or "CRB_InterfaceSmall_O")
end

function NonMiniMapOptions:OnNMMO_DisplayTime_Uncheck( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowTime = false	
	self.gmm.wndMain:FindChild("Time"):Show(false)
end

function NonMiniMapOptions:OnNMMO_DisplayTime_Check( wndHandler, wndControl, eMouseButton )
	self.gmm.bShowTime = true
	self.gmm.wndMain:FindChild("Time"):Show(true)
end


-----------------------------------------------------------------------------------------------
-- General functions / workers here
-----------------------------------------------------------------------------------------------

local zm_oldOnContinentNormalBtn, zm_oldOnContinentCustomBtn
-- Capture the continent button click from the real zone map
-- This works like a trampoline and we can execute our code
-- and then allow it to pass through to the original method
function NonMiniMapOptions:HookContinentButtons()
	if self.addon and zm_oldOnContinentNormalBtn == nil then
		zm_oldOnContinentNormalBtn = self.addon.OnContinentNormalBtn
		
		local zmhook = self
		self.addon.OnContinentNormalBtn = 	function(self, wndHandler, wndControl)
												zm_oldOnContinentNormalBtn(self, wndHandler, wndControl)
												zmhook:UpdateTaxiMarkers()
											end
	end
	
	if self.addon and zm_oldOnContinentCustomBtn == nil then
		zm_oldOnContinentCustomBtn = self.addon.OnContinentCustomBtn
		local zmhook = self
		self.addon.OnContinentCustomBtn = 	function(self, wndHandler, wndControl)
												zm_oldOnContinentCustomBtn(self, wndHandler, wndControl)
												zmhook:UpdateTaxiMarkers()
											end
	end
	
end

function NonMiniMapOptions:UpdateTaxiMarkers()
	
	if self.addon == nil then 
		return 
	end
	
	local eObjectType = self:GetTaxiMapObjectType()
	
	if  not self.gmm.bShowTaxisOnZoneMap or self.gmm.bShowTaxisOnZoneMap == false then
	    self.addon.wndZoneMap:RemoveObjectsByType(eObjectType)
	    self.addon:SetTypeVisibility(eObjectType, false)
	else
		self.addon:SetTypeVisibility(eObjectType, self.gmm.bShowTaxisOnZoneMap)
		
		local idCurrentZone = self.addon.wndMain:FindChild("ZoneComplexToggle"):GetData()
		local tCurrentInfo = self.addon.wndZoneMap:GetZoneInfo(idCurrentZone) or GameLib.GetCurrentZoneMap(idCurrentZone)
		
		if tCurrentInfo == nil then 
			return 
		end
		
		if not self.nFactionId then
			if GameLib.GetPlayerUnit() and GameLib.GetPlayerUnit():IsValid() then
				self.nFactionId = GameLib.GetPlayerUnit():GetFaction()
			else
				self.HookTimer = ApolloTimer.Create(1.0, true, "OnHookTimer", self)
				return
			end
		end
				
		local tCurrentContinent = self.addon.wndZoneMap:GetContinentInfo(tCurrentInfo.continentId)
	
		-- if we have a continent change
		self.addon.wndZoneMap:RemoveObjectsByType(eObjectType)
		-- figure out what continent the zonemap is in
		local tInfo = 	{
							strIcon           = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered",
							strIconEdge       = "IconSprites:Icon_MapNode_Map_Taxi_Undiscovered",
							crObject          = "white",
							crEdge            = "white"
						}
		
		for idx, tTaxiNode in ipairs(ktTaxiNodes.Neutral) do
			if tTaxiNode.nContinentId == tCurrentInfo.continentId then
				self.addon.wndZoneMap:AddObject(eObjectType, { x = tTaxiNode.nX, y = tTaxiNode.nY, z = tTaxiNode.nZ }, Apollo.GetString(tTaxiNode.nTextId), tInfo, { bNeverShowOnEdge  = true, bFixedSizeLarge = true })
			end
		end
		
		for idx, tTaxiNode in ipairs(ktTaxiNodes[self.nFactionId]) do
			if tTaxiNode.nContinentId == tCurrentInfo.continentId then
				self.addon.wndZoneMap:AddObject(eObjectType, { x = tTaxiNode.nX, y = tTaxiNode.nY, z = tTaxiNode.nZ }, Apollo.GetString(tTaxiNode.nTextId), tInfo, { bNeverShowOnEdge  = true, bFixedSizeLarge = true })
			end
		end
		
		self.HookTimer = ApolloTimer.Create(1.0, true, "OnHookTimer", self)
	end
end

function NonMiniMapOptions:AddTaxiToVisibilityLevels()
  if not self.addon or self.bAddedTaxiVisibility then 
	return 
  end

  self.bAddedTaxiVisibility = true
  
  local eObjectType = self:GetTaxiMapObjectType()
  table.insert(self.addon.arAllowedTypesSuperPanning, eObjectType)
  table.insert(self.addon.arAllowedTypesPanning,      eObjectType)
  table.insert(self.addon.arAllowedTypesScaled,       eObjectType)
  table.insert(self.addon.arAllowedTypesContinent,    eObjectType)
end

Apollo.RegisterPackage(NonMiniMapOptions, NonMiniMapPackage, NonMinimapPackageVersion, {})