-----------------------------------------------------------------------------------------------
-- Client Lua Script for InfoPlates
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Unit"
require "GameLib"
require "Apollo"
require "string"
require "math"
 
-----------------------------------------------------------------------------------------------
-- InfoPlates Module Definition
-----------------------------------------------------------------------------------------------
local InfoPlates = {}

----------------------------------------------------------------------------------------------
-- Global functions
-----------------------------------------------------------------------------------------------

-- Sorted Pairs function, pass in the sort function
local function spairs(t, order)
	-- Collect keys
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end

	-- If order function given, sort by passing the table and keys a, b,
	-- otherwise just sort keys
	if order then
		table.sort(keys, function(a,b) return order(t, a, b) end)
	else
		table.sort(keys)
	end
	
	-- Return the iterator function
	local i = 0
	return function()
		i = i + 1
		if keys[i] then
			return keys[i], t[keys[i]]
		end
	end
end 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

local bDebug = false

local timerDelayedLoad

-- Maps player class to icon sprite name
local karClassToIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "IconSprites:Icon_Windows_UI_CRB_Warrior",
	[GameLib.CodeEnumClass.Engineer] 		= "IconSprites:Icon_Windows_UI_CRB_Engineer",
	[GameLib.CodeEnumClass.Esper] 			= "IconSprites:Icon_Windows_UI_CRB_Esper",
	[GameLib.CodeEnumClass.Medic] 			= "IconSprites:Icon_Windows_UI_CRB_Medic",
	[GameLib.CodeEnumClass.Stalker] 		= "IconSprites:Icon_Windows_UI_CRB_Stalker",
	[GameLib.CodeEnumClass.Spellslinger] 	= "IconSprites:Icon_Windows_UI_CRB_Spellslinger",
}

-- Maps unit rank to description strings, currently unused
local ktRankDescriptions =
{
	[Unit.CodeEnumRank.Fodder] 		= 	{Apollo.GetString("TargetFrame_Fodder"), 		Apollo.GetString("TargetFrame_VeryWeak")},
	[Unit.CodeEnumRank.Minion] 		= 	{Apollo.GetString("TargetFrame_Minion"), 		Apollo.GetString("TargetFrame_Weak")},
	[Unit.CodeEnumRank.Standard]	= 	{Apollo.GetString("TargetFrame_Grunt"), 		Apollo.GetString("TargetFrame_EasyAppend")},
	[Unit.CodeEnumRank.Champion] 	=	{Apollo.GetString("TargetFrame_Challenger"), 	Apollo.GetString("TargetFrame_AlmostEqual")},
	[Unit.CodeEnumRank.Superior] 	=  	{Apollo.GetString("TargetFrame_Superior"), 		Apollo.GetString("TargetFrame_Strong")},
	[Unit.CodeEnumRank.Elite] 		= 	{Apollo.GetString("TargetFrame_Prime"), 		Apollo.GetString("TargetFrame_VeryStrong")},
}

-- Maps unit rank to icon sprite name
local ktRanks =
{
	[Unit.CodeEnumRank.Fodder] 		= 	{ sIcon = "spr_TargetFrame_ClassIcon_Fodder", nRankValue = 0},
	[Unit.CodeEnumRank.Minion] 		= 	{ sIcon = "spr_TargetFrame_ClassIcon_Minion", nRankValue = 1},
	[Unit.CodeEnumRank.Standard]	= 	{ sIcon = "spr_TargetFrame_ClassIcon_Standard", nRankValue = 2},
	[Unit.CodeEnumRank.Champion] 	=	{ sIcon = "spr_TargetFrame_ClassIcon_Champion", nRankValue = 3},
	[Unit.CodeEnumRank.Superior] 	=  	{ sIcon = "spr_TargetFrame_ClassIcon_Superior", nRankValue = 4},
	[Unit.CodeEnumRank.Elite] 		= 	{ sIcon = "spr_TargetFrame_ClassIcon_Elite", nRankValue = 5},
}

local ktUnitTypes = 
{
	["NonPlayer"] 		= true,
	["Player"]			= true,
	["Pet"]				= false,
	["Taxi"] 			= false,
	["Mount"] 			= false,	-- We use the player's class, not the mount's class
	["Collectible"] 	= false,
	["PinataLoot"] 		= false,
}

local kt

-- Control types
-- 0 - custom
-- 1 - single check/binary
-- 2 - numeric value
-- 3 - combo box selection
-- TODO: Make them enums

local karSavedProperties =
{
	-- Player, NPC, and disposition
	["bShowFriendlyPlayerPlates"] = { default = false, nControlType=1, strControlName="Check_ShowFriendlyPlayerPlates"},
	["bShowEnemyPlayerPlates"] = { default = true, nControlType=1, strControlName="Check_ShowEnemyPlayerPlates"},
	["bShowEnemyNpcPlates"] = { default = true, nControlType=1, strControlName="Check_ShowEnemyNpcPlates"},
	["bShowFriendlyNpcPlates"] = { default = false, nControlType=1, strControlName="Check_ShowFriendlyNpcPlates",},
	--["bShowNeutralPlates"] = { default = true, nControlType=1, strControlName="Check_ShowNeutralPlates",},
	
	-- Minimum rank
	["nMinimumRank"] = { default = 0 },
	
	-- Draw distance
	["nMaxRange"] = { default = 70.0, nControlType = 2, strControlName="Slider_DrawDistance" },
	
	-- Minimum level
	
	-- Icon position and scaling
	
	-- Advanced
	--["nRefreshTimerSeconds"] = { default = 1.0, nControlType = 2 },
}
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function InfoPlates:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.arPendingUnits = {}			-- Holds units to be processed, such as those created during load
	self.arUnitToInfoPlates  = {}		-- Maps Unit ID to the class plate we've created for that unit
	self.arWndToPlate = {}				-- Maps plate window ID to its class plate structure
	self.arUnitToMounted = {}
	self.tCombatLogData = nil
	--o.xmlDoc = nil
	
	return o
end

function InfoPlates:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- InfoPlates OnLoad
-----------------------------------------------------------------------------------------------
function InfoPlates:OnLoad()
	-- Catch units that are created while we're loading
	Apollo.RegisterEventHandler("UnitCreated", 	"OnPreloadUnitCreated", self)

    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("InfoPlates.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- InfoPlates OnDocLoaded
-----------------------------------------------------------------------------------------------
function InfoPlates:OnDocLoaded()
	
	-- un-register the pre-load event
	
	--Print(Apollo.GetString("InfoPlates:OnDocLoaded" ))
	
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "InfoPlatesSettingsForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end

		-- Register handlers for events, slash commands etc.
		Apollo.RegisterEventHandler("UnitGibbed",			"OnUnitGibbed", self)
		Apollo.RegisterEventHandler("UnitDestroyed", 		"OnUnitDestroyed", self)
		Apollo.RegisterEventHandler("CharacterCreated", 	"OnCharacterCreated", self)
		Apollo.RegisterEventHandler("TargetUnitChanged", 	"OnTargetUnitChanged", self)
		Apollo.RegisterEventHandler("CombatLogMount", 		"OnCombatLogMount", self)
		
		Apollo.RegisterSlashCommand("ip", 					"OnInfoPlatesOn", self)
		Apollo.RegisterSlashCommand("infoplates", 			"OnInfoPlatesOn", self)
		Apollo.RegisterSlashCommand("infoplate", 			"OnInfoPlatesOn", self)
		
		-- load user settings
		
		-- 	-- timer to update mount state
	    Apollo.RegisterTimerHandler("MountUpdater", "UpdateMountPlates", self)
		Apollo.CreateTimer("MountUpdater", 1, true)
		
		-- Update distance check infrequently
		Apollo.RegisterTimerHandler("DistanceChecker", "CheckPlatesDrawable", self)
		Apollo.CreateTimer("DistanceChecker", 1, true)
		
		-- Load class plate form once so it's cached
		wndTemp = Apollo.LoadForm(self.xmlDoc, "InfoPlatesBase", nil, self)
		if wndTemp ~= nil then 
			--Print(Apollo.GetString("InfoPlatesBase cached" ))
			wndTemp:Destroy() 
		end
		
		self:LoadSavedProperties()
		
		-- Build minimum rank ComboBox
		self:BuildRankDropdown()
		
		-- Hide all the things so the user can open them
	    self.wndMain:Show(false, true)
		self.wndMain:FindChild("ComboListFrame"):Show(false)

		-- We don't trust unit information until well after everything has loaded
		timerDelayedLoad = ApolloTimer.Create(5, false, "OnDelayedLoad", self)

	end
end

function InfoPlates:OnDelayedLoad()
	if bDebug then Print(Apollo.GetString("InfoPlates DelayedLoad")) end

	Apollo.RemoveEventHandler("UnitCreated", self)
	Apollo.RegisterEventHandler("UnitCreated", 			"OnUnitCreated", self)

	-- Process units created during doc load
	self:CreateUnitsFromPreload()
end

function InfoPlates:OnSave(eLevel)
	Print(Apollo.GetString("OnSave"))
	-- save settings at the character level
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
		Print(Apollo.GetString("eType wrong"))
        return nil
    end

    local tSave = {}
	for property,tData in pairs(karSavedProperties) do
		tSave[property] = self[property]
	end

	return tSave
end

function InfoPlates:OnRestore(eType, tSavedData)
	Print(Apollo.GetString("OnRestore"))
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return
	end
		
	for property,tData in pairs(karSavedProperties) do
		if tSavedData[property] ~= nil then
			self[property] = tSavedData[property]
		end
	end
	--self:RefreshSettingsInterface()
	self:CreateUnitsFromPreload()
end

function InfoPlates:LoadSavedProperties()
	for property, tData in pairs(karSavedProperties) do
		if self[property] == nil then
			self[property] = tData.default
		end
		if tData.nControlType == 1 or tData.nControlType == 2 then
			local wndControl = self.wndMain:FindChild(tData.strControlName)
			if wndControl ~= nil then
				--Print(Apollo.GetString(wndControl:GetName() .. ":SetData " .. property))
				wndControl:SetData(property)
			end
		end
	end
end


---------------------------------------------------------------------------------------
-- Plate Management Functions
-----------------------------------------------------------------------------------------------

function InfoPlates:OnPreloadUnitCreated(unitNew)
	self.arPendingUnits[unitNew:GetId()] = unitNew
end

function InfoPlates:CreateUnitsFromPreload()
	for idUnit, unitNew in pairs(self.arPendingUnits) do
		self:OnUnitCreated(unitNew)
		self.arPendingUnits[idUnit] = nil
	end
	--self.arPendingUnits = nil
end

-- create a InfoPlates for new units and add them to the tables
function InfoPlates:OnUnitCreated(unitNew)
	--Print(Apollo.GetString("OnUnitCreated"))
	
	--TODO: determine if this check is valuable, and handle it properly
	if GameLib.GetPlayerUnit() == nil then
		--Print(Apollo.GetString("Player not created yet"))
	end

	-- don't do any work for units that will never get a plate
	bValidUnit = InfoPlates:ShouldTrackUnit(unitNew)
	if not bValidUnit then return end
	
	tPlate = InfoPlates:CreateInfoPlatesObject(unitNew)
	--Print(Apollo.GetString("Unit Created: " .. unitNew:GetType() ))
	
	-- give it a window
	if tPlate == nil or tPlate.unitOwner == nil then return	end
	InfoPlates:CreateInfoPlatesWindow(tPlate)

	-- add it to the list
	self.arUnitToInfoPlates[tPlate.idUnit] = tPlate
	self.arWndToPlate[tPlate.wndInfoPlates:GetId()] = tPlate
	
	-- Assign plate to mount if player is mounted
	InfoPlates:HandlePlayerMount(unitOwner)
	
end

function InfoPlates:ProcessNewUnits()

end

-- Create InfoPlates structure for the given unit
function InfoPlates:CreateInfoPlatesObject(unit)
	
	local unitPlayer = GameLib.GetPlayerUnit()

	-- extract class/rank info from unit
	nRank = nil
	local tRank = ktRanks[unit:GetRank()]
	if tRank ~= nil then nRank = tRank.nRankValue end
	
	local tPlate = 
	{
		unitOwner 		= unit,
		idUnit 			= unit:GetId(),
		eRank 			= unit:GetRank(),
		nRankValue		= nRank,
		eClass			= unit:GetClassId(),
		eDisposition 	= unit:GetDispositionTo(unitPlayer),
		bIsPlayer 		= unit:GetType() == "Player",
		bIsFriendly 	= unit:GetDispositionTo(unitPlayer) == Unit.CodeEnumDisposition.Friendly,
	}
	
	return tPlate;
end

-- Creates an InfoPlates window for the unit in the tPlate structure
function InfoPlates:CreateInfoPlatesWindow(tPlate)

	-- Handle error cases
	---------------------------------
	if tPlate.wndInfoPlates ~= nil then return end -- Already has a window
	if tPlate.unitOwner == nil then return end -- No owner

	-- Load plate XML
	---------------------------------
	if self.xmlDoc == nil then
		--Print(Apollo.GetString("CreateInfoPlatesWindow: self.xmlDoc is nil"))
		-- Commenting out next line results in nil error 
		self.xmlDoc = XmlDoc.CreateFromFile("InfoPlates.xml")
	end
	
	local wndPlate = Apollo.LoadForm(self.xmlDoc, "InfoPlatesBase", "InWorldHudStratum", self)
	tPlate.wndInfoPlates = wndPlate
	if wndPlate == nil then 
		Print(Apollo.GetString("CreateInfoPlatesWindow: InfoPlatesBase form load failure"))
	end
	
	-- To reduce typing
	local unitOwner = tPlate.unitOwner
	local wndInfoPlates = tPlate.wndInfoPlates
	
	-- Determine class/rank sprite
	---------------------------------
	local strPlayerIconSprite = ""
	local strRankIconSprite = ""

	-- Class Icon is based on player class or NPC rank
	if tPlate.bIsPlayer then
		strPlayerIconSprite = karClassToIcon[tPlate.eClass]
	else
		if ktRanks[tPlate.eRank] ~= nil then 
			strRankIconSprite = ktRanks[tPlate.eRank].sIcon
		else
			strRankIconSprite = ktRanks[0].sIcon
		end
	end
	
	wndInfoPlates:FindChild("PlayerClassIcon"):SetSprite(strPlayerIconSprite)
	wndInfoPlates:FindChild("NPCClassIcon"):SetSprite(strRankIconSprite)
	wndInfoPlates:SetData(tPlate.unitOwner) -- relevant for handling mounting/dismounting
	wndInfoPlates:SetUnit(tPlate.unitOwner)
	-- TODO: Draw above/around other nameplates
	-- tPlate.wndInfoPlates:Move(0,30,0,0)

	--local wndContanier = tPlate.wndInfoPlates:FindChild("InfoPlatesContainer")
	--wndContanier:ArrangeChildrenVert(1)
	
	-- Hide plates for units that aren't on screen, otherwise we get stray plates on screen
	bOnScreen = self:ShouldDrawPlate(tPlate)
	wndInfoPlates:Show(bOnScreen)
end


function InfoPlates:RemovePlate(unitRem)
	--Print(Apollo.GetString("RemovePlate: " .. unitRem:GetName()))

	-- handle nil cases
	local idUnit = unitRem:GetId()
	if idUnit == nil then return end
	
	local tPlate = self.arUnitToInfoPlates[idUnit]
	if tPlate == nil then return end
	
	-- nil-out all the things
	local idWnd = tPlate.wndInfoPlates:GetId()
	InfoPlates:RemovePlateWindow(tPlate)
	self.arUnitToInfoPlates[idUnit] = nil
	self.arWndToPlate[idWnd] = nil
end

function InfoPlates:RemovePlateWindow(tPlate)
	--Print(Apollo.GetString("RemovePlateWindow"))
	if tPlate.wndInfoPlates ~= nil then
		tPlate.wndInfoPlates:SetNowhere()
		tPlate.wndInfoPlates:SetUnit(nil)
		tPlate.wndInfoPlates:Show(false)
		tPlate.wndInfoPlates:Destroy()
		tPlate.wndInfoPlates = nil
	end
end

-- Game/unit state event handlers
---------------------------------

function InfoPlates:OnUnitDestroyed(unitDead)
	InfoPlates:RemovePlate(unitDead)
end

-- if unit is mounted, re-target the plate to the mount
-- otherwise target the rider
function InfoPlates:HandlePlayerMount(unitOwner, bIsMounted)
	if unitOwner == nil then return end
	local tPlate = self.arUnitToInfoPlates[unitOwner:GetId()]
	if tPlate == nil then return end
	
	if bIsMounted then
		--Print(Apollo.GetString(unitOwner:GetName() .. " mounted"))
		local unitMount = unitOwner:GetUnitMount()
		
		if unitMount == nil then return end	
		
		tPlate.wndInfoPlates:SetUnit(unitMount, 1) 
	else
		--Print(Apollo.GetString(unitOwner:GetName() .. " DISmounted"))
		tPlate.wndInfoPlates:SetUnit(unitOwner, 1)
	end
end

function InfoPlates:OnCombatLogMount(tEventArgs)
	self.tCombatLogData = tEventArgs
	-- if bDebug then SendVarToRover("tCombatLogMount", self.tCombatLogData ) end
	
	-- unit:IsMounted() will return true when a character dismounts, and false 
	-- when they mount. Here we store mount state so that plates can be attached
	-- to the mount after the character has fully mounted, or the char on dismount
	self.arUnitToMounted[tEventArgs.unitCaster] = not tEventArgs.bDismounted
end

function InfoPlates:UpdateMountPlates()
	for idPlayer,bMounted in pairs(self.arUnitToMounted) do
		InfoPlates:HandlePlayerMount(unitPlayer, bMounted)
	end
end

function InfoPlates:CheckPlatesDrawable()
	for idPlayer, tPlate in pairs(self.arUnitToInfoPlates) do
		bShow = self:ShouldShowPlate(tPlate)
		tPlate.wndInfoPlates:Show(bShow)
	end
end

function InfoPlates:ShouldShowPlate(tPlate)
	bShouldShow = self:ShouldDrawPlate(tPlate) and self:UnitPlateEnabled(tPlate)
	return bShouldShow
end

function InfoPlates:UnitPlateEnabled(tPlate)

	local bEnabled = false
	
	-- Update unit's disposition
	local unitPlayer = GameLib.GetPlayerUnit()
	
	local eOrigDisp = tPlate.eDisposition
	tPlate.eDisposition = tPlate.unitOwner:GetDispositionTo(unitPlayer)
	tPlate.bIsFriendly 	= (tPlate.eDisposition == Unit.CodeEnumDisposition.Friendly)

	-- check against user show/hide settings
	if self.bShowFriendlyPlayerPlates and tPlate.bIsFriendly and tPlate.bIsPlayer then
		bEnabled = true
	end
	
	if self.bShowEnemyPlayerPlates and not tPlate.bIsFriendly and tPlate.bIsPlayer then
		bEnabled = true
	end
	
	if self.bShowEnemyNpcPlates and not tPlate.bIsFriendly and not tPlate.bIsPlayer then
		bEnabled = true
	end
	
	if self.bShowFriendlyNpcPlates and tPlate.bIsFriendly and not tPlate.bIsPlayer then
		bEnabled = true
	end

	local sUnitType = tPlate.unitOwner:GetType()
	return bEnabled and ktUnitTypes[sUnitType] and not tPlate.unitOwner:IsThePlayer()
end

function InfoPlates:IsDrawable(tPlate)
	return self:ShouldTrackUnit(tPlate.unitOwner) and self:ShouldDrawPlate(tPlate)
end

-- return true if we should track a class plate for the unit, and possibly show it
-- Filters out units we'll never be interested in, like invisible units, or the taxi driver
function InfoPlates:ShouldTrackUnit(unit)

	local unitOwner = unit
	if unitOwner == nil then return false end
	
	-- handle odd unit states
	local bHiddenUnit = not unitOwner:ShouldShowNamePlate() 
		or unitOwner:GetHealth() == nil
		or unitOwner:IsDead()
		or unitOwner:IsThePlayer()
	
	if bHiddenUnit then return false end
	
	local sUnitType = unitOwner:GetType()

	-- only certain types are drawable
	bDrawableType = ktUnitTypes[sUnitType]
	if bDrawableType == nil then return false end -- handle unknown unit types
	
	return bDrawableType
	
end

-- Checked at regular intervals
function InfoPlates:ShouldDrawPlate(tPlate)
	return tPlate.wndInfoPlates:IsOnScreen() 
		and not tPlate.wndInfoPlates:IsOccluded()
		and self:IsInRange(tPlate)
		and self:MeetsMinimumRank(tPlate)
end	

function InfoPlates:MeetsMinimumRank(tPlate)
	if tPlate.bIsPlayer then return true end
	if tPlate.nRankValue == nil then return false end
	
	return tPlate.nRankValue >= self.nMinimumRank
end

function InfoPlates:IsInRange(tPlate)
	local unitPlayer = GameLib.GetPlayerUnit()
	local unitOwner = tPlate.unitOwner

	if not unitOwner or not unitPlayer or self.nMaxRange == nil then
		--self.nMaxRange = 70
	    return false
	end

	tPosTarget = unitOwner:GetPosition()
	tPosPlayer = unitPlayer:GetPosition()

	if tPosTarget == nil then
		return
	end

	local nDeltaX = tPosTarget.x - tPosPlayer.x
	local nDeltaY = tPosTarget.y - tPosPlayer.y
	local nDeltaZ = tPosTarget.z - tPosPlayer.z

	local nDistance = (nDeltaX * nDeltaX) + (nDeltaY * nDeltaY) + (nDeltaZ * nDeltaZ)

	-- TODO: different distance threshold for targeted units
	bInRange = nDistance < (self.nMaxRange * self.nMaxRange ) -- squaring for quick maths
	return bInRange
end

function InfoPlates:OnUnitGibbed(unitUpdated)
	--Print(Apollo.GetString("OnUnitGibbed " .. unitDead:GetName()))
	InfoPlates:RemovePlate(unitUpdated)
end

function InfoPlates:OnTargetUnitChanged(unitOwner)
	--if unitOwner == nil then return end
end

function InfoPlates:OnCharacterCreated()
	--Print(Apollo.GetString("Character created"))
end

---------------------------------------------------------------------------------------------------
-- InfoPlatesBase Functions
---------------------------------------------------------------------------------------------------

-- Currently unnecessary and potentially buggy
function InfoPlates:OnUnitOcclusionChanged(wndHandler, wndControl, bOccluded)
	--Print(Apollo.GetString("OnUnitOcclusionChanged"))
	--wndHandler:Show(not bOccluded)
end

function InfoPlates:OnWorldLocationOnScreen( wndHandler, wndControl, bOnScreen )
	--Print(Apollo.GetString("OnWorldLocationOnScreen"))
	wndHandler:Show(bOnScreen and self:IsDrawable(tPlate))
end

---------------------------------------------------------------------------------------------------
-- InfoPlatesSettingsForm Functions
---------------------------------------------------------------------------------------------------


function InfoPlates:RefreshSettingsInterface()

	for property,tData in pairs(karSavedProperties) do
		--Print(Apollo.GetString("Refreshing : " .. property))
		
		if self[property] ~= nil then
			if tData.nControlType == 1 then
				local wndControl = self.wndMain:FindChild(tData.strControlName)
				if wndControl ~= nil then
					wndControl:SetCheck(self[property])
					--Print(Apollo.GetString(property .. " set to " .. tostring(self[property]) ))
				end
			elseif tData.nControlType == 2 then
				local wndControl = self.wndMain:FindChild(tData.strControlName)
				if wndControl ~= nil then
					wndControl:SetValue(self[property])
				end
			elseif tData.nControlType == 3 then -- combo box
				local wndControl = self.wndMain:FindChild(tData.strControlName)
				if wndControl ~= nil then

					wndControl:SelectItemByData(self[property])
				end
			end

		end
	end
	
	-- Draw distance value display
	self.wndMain:FindChild("Label_DrawDistanceDisplay"):SetText(string.format("%sm",  self.nMaxRange))
end

function InfoPlates:OnGenericSingleCheck(wndHandler, wndControl, eMouseButton)
	--Print(Apollo.GetString(wndControl:GetName() .. " toggled " .. tostring(wndControl:IsChecked())))
	
	local strSettingName = wndControl:GetData()
	if strSettingName ~= nil then
		self[strSettingName] = wndControl:IsChecked()
		local fnCallback = karSavedProperties[strSettingName].fnCallback
		if fnCallback ~= nil then
			self[fnCallback](self)
		end
	end
end

function InfoPlates:OnDrawDistanceSlider( wndContainer, wndHandler, nValue, nOldvalue)
	self.nMaxRange = math.floor(nValue)
	self.wndMain:FindChild("Label_DrawDistanceDisplay"):SetText(string.format("%sm",  self.nMaxRange))
end

-- Show Settings Window
function InfoPlates:OnInfoPlatesOn()
	self.wndMain:Show(true)
	self:RefreshSettingsInterface()
end

-- when the Cancel button is clicked
function InfoPlates:OnCancel()
	self.wndMain:Close() -- hide the window
end

----------------------------
-- Button-based combo box functions
----------------------------

-- Build rank list
function InfoPlates:BuildRankDropdown()

	-- Set main combobox text to the currently selected rank
	local strMinRank = ktRankDescriptions[self.nMinimumRank][1]
	self.wndMain:FindChild("ComboButtonText"):SetText(strMinRank)

	-- clear dropdown list
	local wndComboList = self.wndMain:FindChild("RankComboList")
	wndComboList:DestroyChildren()

	-- For each rank, add a button to the dropdown
	-- Table iteration isn't guaranteed to be in order, so use spairs to sort ranks by value (desc.)
	----------------------------------------------
	for eKey, nValue in spairs(Unit.CodeEnumRank, function(t,a,b) return t[b] < t[a] end) do
		-- Load dropdown item button as child of dropdown list form
		local wndItem = Apollo.LoadForm(self.xmlDoc, "ComboSelectorButton", wndComboList, self)
		
		-- Store rank info in the selector button for later access
		local nRankIndex = nValue 
		wndItem:SetData(nRankIndex)

		-- Set button rank text
		local strRank = ktRankDescriptions[nRankIndex][1]
		wndItem:SetText(strRank)

		-- For the currently selected item use parent text color as the button text color 
		if nValue == self.nMinimumRank then
			wndItem:SetStyleEx("UseWindowTextColor", true)
		else
			wndItem:SetStyleEx("UseWindowTextColor", false)
		end
		
	end
	
	-- Align everything and scroll to the selected item
	-----------------------------------------------------
	
	wndComboList:ArrangeChildrenVert(0)

	-- Calculate the height of a combo box item
	-- Not currently useful as there isn't a need to scroll
	--[[ 	
	local nLeft, nTop, nRight, nBottom = wndComboList:FindChild("ComboSelectorButton"):GetAnchorOffsets()
	local nHeight = nBottom - nTop
	
	wndComboList:SetVScrollPos( (self.nMinimumRank - 1) * nHeight)
	--]]

end

-- Opens the combo box dropdown. Called by main combo box button.
function InfoPlates:OnComboButtonCheck( wndHandler, wndControl, eMouseButton )
	local wndListFrame = self.wndMain:FindChild("ComboListFrame")
	if (wndListFrame ~= nil) then
		wndListFrame:Show(true)
	end
end

-- Closes the combo box dropdown
function InfoPlates:OnComboButtonUncheck( wndHandler, wndControl, eMouseButton )
	local wndListFrame = self.wndMain:FindChild("ComboListFrame")
	if (wndListFrame ~= nil) then
		wndListFrame:Show(false)
	end
end

-- Called when an item in the combo box drop-down is clicked
function InfoPlates:OnComboItemButton( wndHandler, wndControl, eMouseButton )
	
	-- Update setting with chosen value
	self.nMinimumRank = wndControl:GetData()

	-- hide frame holding dropdown list, reset combo box button
	self.wndMain:FindChild("ComboListFrame"):Show(false)
	self.wndMain:FindChild("ComboButton"):SetCheck(false)
	self.wndMain:FindChild("ComboButtonText"):SetText(ktRankDescriptions[self.nMinimumRank][1])
	
	-- Set every combo box item's text to their defaults
	for idx, wndItem in pairs(self.wndMain:FindChild("RankComboList"):GetChildren()) do
		wndItem:SetStyleEx("UseWindowTextColor", false)
	end

	-- Set the selected minimum rank to the parent window's text color
	wndHandler:SetStyleEx("UseWindowTextColor", true)

end

------------------------------------------------------------------------------------------------
-- InfoPlates Instance
-----------------------------------------------------------------------------------------------
local InfoPlatesInst = InfoPlates:new()
InfoPlatesInst:Init()
