require "Apollo"
require "Window"
require "Unit"
require "GameLib"
require "CombatFloater"
require "math"
 
-----------------------------------------------------------------------------------------------
-- ClairvoyanceEx Module Definition
-----------------------------------------------------------------------------------------------
local ClairvoyanceEx = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ClairvoyanceEx:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self 
  
  return o
end

function ClairvoyanceEx:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {	}
  
  Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function ClairvoyanceEx:OnLoad()
  -- load our form file
  self.xmlDoc = XmlDoc.CreateFromFile("ClairvoyanceEx.xml")
  Apollo.LoadSprites("ClairvoyanceSprites.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ClairvoyanceEx:OnDocLoaded()
	if self.xmlDoc == nil then
		return
	end
  
	Apollo.RegisterEventHandler("ApplyCCState", "OnCCApplied", self)
	Apollo.RegisterEventHandler("RemoveCCState", "OnCCRemove", self)
	Apollo.RegisterEventHandler("ChangeWorld", "OnChangeWorld", self)
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("SystemKeyDown", "OnKeyDown", self)
	
	self.wndClairvoyanceNotification = Apollo.LoadForm(self.xmlDoc, "ClairvoyanceNotification", nil, self)
	self.wndClairvoyanceNotification:Show(false)
	
	self.wndWeaponIndicator = Apollo.LoadForm(self.xmlDoc, "WeaponIndicator", nil, self)
	self.wndWeaponIndicator:Show(false)
	
	self.wndDisorient = Apollo.LoadForm(self.xmlDoc, "DisorientWindow", nil, self)
	self.wndDisorient:FindChild("forwardButton"):Enable(false)
	self.wndDisorient:FindChild("backButton"):Enable(false)
	self.wndDisorient:FindChild("strafeLeftButton"):Enable(false)
	self.wndDisorient:FindChild("strafeRightButton"):Enable(false)
	self.wndDisorient:Show(false)
	
	Apollo.RegisterSlashCommand("cv", "OnSlashCommand", self)
	Apollo.RegisterSlashCommand("clairvoyance", "OnSlashCommand", self)
	
	if self.bDisplayBackground == nil then
		self.bDisplayBackground = true
	end
	
	self.activeEffects = {}
	self:InitializeStateNames()
	self:InitializeStatePriority()
	self:InitializeKeyMapping()
end

function ClairvoyanceEx:OnSlashCommand(slashcommand, subcommand)
  
  -- If the 'background' or 'b' sub-command is used, then we will simply toggle
  -- the background of the Addon.
	if subcommand == "background" or subcommand == "b" then
		if self.bDisplayBackground == true then
			self.bDisplayBackground = false
			Print("ClairvoyanceEx - Background turned OFF for notification window.")
		elseif self.bDisplayBackground == false then
			self.bDisplayBackground = true
			Print("ClairvoyanceEx - Background turned ON for notification window.")
		end
		
		return
	end
	
	-- If the 'show' or 's' subcommand is used, then we will simply show the disorient
	-- window and allow the user to drag it around, so it's position can be saved.
  if subcommand == "show" or subcommand == "s" then
    if self.bConfigMode == true then
      self.bConfigMode = false
      self:StorePositions()
      self.wndDisorient:Show(false)
      self.wndClairvoyanceNotification:Show(false)
      self.wndWeaponIndicator:Show(false)
    else
      self.bConfigMode = true
      self:LoadPositions()
      self.wndDisorient:Show(true)
      self.wndClairvoyanceNotification:Show(true)
      self.wndWeaponIndicator:Show(true)
    end
    
    return
  end
end

-----------------------------------------------------------------------------------------------
-- Functionality
-----------------------------------------------------------------------------------------------
function ClairvoyanceEx:StorePositions()
  self.tLocations = {
    tNotificationLocation = self.wndClairvoyanceNotification:GetLocation():ToTable(),
    tDisorientLocation = self.wndDisorient:GetLocation():ToTable(),
    tWeaponLocation = self.wndWeaponIndicator:GetLocation():ToTable()
  }
end

function ClairvoyanceEx:LoadPositions()  
  if self.tLocations.tNotificationLocation then
    local tLocation = WindowLocation.new(self.tLocations.tNotificationLocation)
    self.wndClairvoyanceNotification:MoveToLocation(tLocation)
  end
  
  if self.tLocations.tDisorientLocation then
    local tLocation = WindowLocation.new(self.tLocations.tDisorientLocation)
    self.wndDisorient:MoveToLocation(tLocation)
  end
  
  if self.tLocations.tWeaponLocation then
    local tLocation = WindowLocation.new(self.tLocations.tWeaponLocation)
    self.wndWeaponIndicator:MoveToLocation(tLocation)
  end
end

function ClairvoyanceEx:OnCCApplied(code, userdata)
	local unitPlayer = GameLib.GetControlledUnit()
	if code == Unit.CodeEnumCCState.Stun or code == Unit.CodeEnumCCState.Knockback then
		return
	end
	if unitPlayer == userdata then
		if code == Unit.CodeEnumCCState.Disorient then
			self.originalKeybindings = GameLib.GetKeyBindings()
			self.modifiedKeybindings = GameLib.GetKeyBindings()
		end
		self.activeEffects[code] = true
		self:UpdateNotification()
	end
end

function ClairvoyanceEx:OnCCRemove(code, userdata)
	local unitPlayer = GameLib.GetControlledUnit()
	if code == Unit.CodeEnumCCState.Stun or code == Unit.CodeEnumCCState.Knockback then
		return
	end
	if unitPlayer == userdata then
		self.activeEffects[code] = nil
		self:UpdateNotification()
		if code == Unit.CodeEnumCCState.Subdue or code == Unit.CodeEnumCCState.Disarm then
			self.wndWeaponIndicator:Show(false)
		end
		if code == Unit.CodeEnumCCState.Disorient then
			GameLib:SetKeyBindings(self.originalKeybindings)
			self.lastLocation = nil
			self.wndDisorient:Show(false)
			self.wndDisorient:FindChild("forwardButton"):DestroyAllPixies()
			self.wndDisorient:FindChild("backButton"):DestroyAllPixies()
			self.wndDisorient:FindChild("strafeLeftButton"):DestroyAllPixies()
			self.wndDisorient:FindChild("strafeRightButton"):DestroyAllPixies()
		end
	end
end

function ClairvoyanceEx:UpdateNotification()
	local displayEffect = -1
	for key, value in pairs(self.activeEffects) do
		if (displayEffect == -1) or (self.statePriority[key] > self.statePriority[displayEffect]) then
			displayEffect = key
		end
	end
	
	if displayEffect == -1 then
		self:ShowNotification(false)
	else
		self:ShowNotification(false)
		
		if displayEffect == Unit.CodeEnumCCState.Knockdown then
			self.wndClairvoyanceNotification:FindChild("Advice"):SetText("Dodge to recover!")
		elseif displayEffect == Unit.CodeEnumCCState.Disorient then
			self.wndClairvoyanceNotification:FindChild("Advice"):SetText("Movement keys changed")
		elseif displayEffect == Unit.CodeEnumCCState.Subdue or displayEffect == Unit.CodeEnumCCState.Disarm then
			self.wndClairvoyanceNotification:FindChild("Advice"):SetText("Find your weapon!")
		elseif displayEffect == Unit.CodeEnumCCState.Tether then
			self.wndClairvoyanceNotification:FindChild("Advice"):SetText("Destroy the anchor!")
		else
			self.wndClairvoyanceNotification:FindChild("Advice"):SetText("")
		end
		if self.stateNames[displayEffect] ~= nil then
			self.wndClairvoyanceNotification:FindChild("StateName"):SetText(self.stateNames[displayEffect])
		else
			Print("Received code " .. displayEffect .. "...")
			self.wndClairvoyanceNotification:FindChild("StateName"):SetText("Undefined CC")
		end
		
		if self.bDisplayBackground == true then
			self.wndClairvoyanceNotification:SetSprite("BK3:UI_BK3_Holo_Framing_2_Blocker")
		elseif self.bDisplayBackground == false then
			self.wndClairvoyanceNotification:SetSprite("")
		end
		
		self:ShowNotification(true)
	end
end

function ClairvoyanceEx:OnChangeWorld()
	for key, value in pairs(self.activeEffects) do
		self.activeEffects[key] = nil
	end
	self:ShowNotification(false)
	self.wndWeaponIndicator:Show(false)
end

function ClairvoyanceEx:OnUnitCreated(unit)
	if unit:GetType() == "Pickup" then
		local playerName = GameLib.GetPlayerUnit():GetName()
		if string.sub(unit:GetName(), 1, string.len(playerName)) == playerName then
			self.wndWeaponIndicator:SetUnit(unit, 1)
			self.wndWeaponIndicator:Show(true)
		end
	end
end

function ClairvoyanceEx:OnKeyDown(iKey)
	if self.activeEffects[Unit.CodeEnumCCState.Disorient] == true then
		if self.keymapping ~= nil and self.keymapping[iKey] ~= nil then
			local key = self.keymapping[iKey]
			local strafeLeft = GameLib.GetKeyBinding("StrafeLeft")
			local strafeRight = GameLib.GetKeyBinding("StrafeRight")
			local moveForward = GameLib.GetKeyBinding("MoveForward")
			local moveBackward = GameLib.GetKeyBinding("MoveBackward")
			if key == strafeLeft or key == strafeRight or key == moveForward or key == moveBackward then
				self.wndDisorient:Show(true)
				self:AttemptRebind(key, strafeLeft, strafeRight, moveForward, moveBackward)
			end
		end
	end
end

function ClairvoyanceEx:AttemptRebind(direction, strafeLeft, strafeRight, moveForward, moveBackward)
	local unitPlayer = GameLib.GetControlledUnit()
	if self.lastLocation == nil or self.lastDirection == nil then
		self.lastLocation = unitPlayer:GetPosition()
		self.lastDirection = direction
	else
		if self.lastDirection ~= direction then
			self.lastDirection = direction
		else
			self.lastDirection = direction
			local currentPosition = unitPlayer:GetPosition()
			local actualDirection = self:CalculateDirection(self.lastLocation, currentPosition, unitPlayer:GetHeading())
			self.lastLocation = currentPosition
			if direction == moveForward then
				if actualDirection == "FORWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("forwardButton"), 0)
				elseif actualDirection == "BACKWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("forwardButton"), 180)
				elseif actualDirection == "LEFTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("forwardButton"), 270)
				elseif actualDirection == "RIGHTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("forwardButton"), 90)
				end
			elseif direction == moveBackward then
				if actualDirection == "FORWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("backButton"), 0)
				elseif actualDirection == "BACKWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("backButton"), 180)
				elseif actualDirection == "LEFTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("backButton"), 270)
				elseif actualDirection == "RIGHTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("backButton"), 90)
				end
			elseif direction == strafeLeft then
				if actualDirection == "FORWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeLeftButton"), 0)
				elseif actualDirection == "BACKWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeLeftButton"), 180)
				elseif actualDirection == "LEFTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeLeftButton"), 270)
				elseif actualDirection == "RIGHTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeLeftButton"), 90)
				end
			elseif direction == strafeRight then
				if actualDirection == "FORWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeRightButton"), 0)
				elseif actualDirection == "BACKWARD" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeRightButton"), 180)
				elseif actualDirection == "LEFTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeRightButton"), 270)
				elseif actualDirection == "RIGHTSTRAFE" then
					self:DrawArrowPixie(self.wndDisorient:FindChild("strafeRightButton"), 90)
				end
			end
		end
	end
end

function ClairvoyanceEx:CalculateDirection(fromLoc, toLoc, heading)
	local angle = self:ComputeAngle(fromLoc, toLoc)
	local backward = self:FindBackward(heading)
	local leftStrafe = self:FindLeftStrafe(heading)
	local rightStrafe = self:FindRightStrafe(heading)
	
	local match = self:CompareAngles(angle, heading, 0.2)
	if match == true then
		return "FORWARD"
	end
	match = self:CompareAngles(angle, backward, 0.2)
	if match == true then
		return "BACKWARD"
	end
	match = self:CompareAngles(angle, leftStrafe, 0.2)
	if match == true then
		return "LEFTSTRAFE"
	end
	match = self:CompareAngles(angle, rightStrafe, 0.2)
	if match == true then
		return "RIGHTSTRAFE"
	end
	
	return "?"
end

function ClairvoyanceEx:ComputeAngle(fromLoc, toLoc)
	local dX = toLoc.x - fromLoc.x
	local dZ = toLoc.z - fromLoc.z
	local radians = -math.atan2(dZ, dX)
	if radians >= -(math.pi / 2) then
		radians = radians - (math.pi / 2)
	elseif radians < -(math.pi / 2) then
		local remainder = -radians - (math.pi / 2)
		radians = math.pi - remainder
	end
	return radians
end

function ClairvoyanceEx:FindBackward(angle)
	local convertedAngle = nil
	if angle == 0 then
		convertedAngle = math.pi
	elseif angle == math.pi then
		convertedAngle = 0
	elseif angle > 0 then
		local remainder = math.pi - angle
		convertedAngle = 0 - remainder
	elseif angle < 0 then
		local remainder = -math.pi - angle
		convertedAngle = 0 - remainder
	end
	return convertedAngle
end

function ClairvoyanceEx:FindLeftStrafe(angle)
	local convertedAngle = nil
	if angle > (math.pi / 2) then
		local remainder = angle - (math.pi / 2)
		convertedAngle = -math.pi + remainder
	else
		convertedAngle = angle + (math.pi / 2)
	end
	return convertedAngle
end

function ClairvoyanceEx:FindRightStrafe(angle)
	local convertedAngle = nil
	if angle < (-math.pi / 2) then
		local remainder = angle - (-math.pi / 2)
		convertedAngle = math.pi + remainder
	else
		convertedAngle = angle - (math.pi / 2)
	end
	return convertedAngle
end

function ClairvoyanceEx:CompareAngles(angle, heading, faultTolerance)
	local min = nil
	local max = nil
	min, max = self:FindBoundaries(heading, faultTolerance)
	if min > max then
		if (angle >= min and angle <= math.pi) or (angle <= max and angle >= -math.pi) then
			return true
		end
	else
		if angle >= min and angle <= max then
			return true
		end
	end
	
	return false
end

function ClairvoyanceEx:FindBoundaries(angle, faultTolerance)
	local min = nil
	local max = nil
	if (angle + faultTolerance) > math.pi then
		min = angle - faultTolerance
		local remainder = math.pi - angle
		remainder = faultTolerance - remainder
		max = -math.pi + remainder
	elseif (angle - faultTolerance) < -math.pi then
		max = angle + faultTolerance
		local remainder = -math.pi - angle
		remainder = faultTolerance - remainder
		min = math.pi - remainder
	else
		min = angle - faultTolerance
		max = angle + faultTolerance
	end
	return min, max
end

function ClairvoyanceEx:round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function ClairvoyanceEx:ShowNotification(show)
	self.wndClairvoyanceNotification:Show(show)
	self.wndClairvoyanceNotification:FindChild("Icon"):Show(show)
	self.wndClairvoyanceNotification:FindChild("StateName"):Show(show)
	self.wndClairvoyanceNotification:FindChild("Advice"):Show(show)
end

function ClairvoyanceEx:DrawArrowPixie(component, rotation)
	component:DestroyAllPixies()
	
	local loc = {
		fPoints = {0.5, 0.5, 0.5, 0.5},
		nOffsets = {-14, -14, 14, 14}
	}
	
	component:AddPixie({
	iLayer = 2,
	bLine = false,
	strSprite = "ClairvoyanceSprites:Arrow",
	fRotation = rotation,
	loc = loc})
end

function ClairvoyanceEx:InitializeStateNames()
	self.stateNames = {}
	for key, value in pairs(Unit.CodeEnumCCState) do
		self.stateNames[value] = key
	end
end

function ClairvoyanceEx:InitializeStatePriority()
	self.statePriority = {}
	for key, value in pairs(Unit.CodeEnumCCState) do
		self.statePriority[value] = 1
	end
	self.statePriority[Unit.CodeEnumCCState.Knockdown] = 6
	self.statePriority[Unit.CodeEnumCCState.Subdue] = 5
	self.statePriority[Unit.CodeEnumCCState.Disarm] = 4
	self.statePriority[Unit.CodeEnumCCState.Tether] = 3
	self.statePriority[Unit.CodeEnumCCState.Disorient] = 2
end

-- Initializes the key mapping for the various keys known to be used by the disorient effect.
-- We simply store them in our key-map array using the key value as index and the string representation
-- as value.
function ClairvoyanceEx:InitializeKeyMapping()
	self.keymapping = {}
	self.keymapping[81] = "Q"
	self.keymapping[87] = "W"
	self.keymapping[69] = "E"
	self.keymapping[82] = "R"
	self.keymapping[84] = "T"
	self.keymapping[89] = "Y"
	self.keymapping[85] = "U"
	self.keymapping[73] = "I"
	self.keymapping[79] = "O"
	self.keymapping[80] = "P"
	self.keymapping[65] = "A"
	self.keymapping[83] = "S"
	self.keymapping[68] = "D"
	self.keymapping[70] = "F"
	self.keymapping[71] = "G"
	self.keymapping[72] = "H"
	self.keymapping[74] = "J"
	self.keymapping[75] = "K"
	self.keymapping[76] = "L"
	self.keymapping[90] = "Z"
	self.keymapping[88] = "X"
	self.keymapping[67] = "C"
	self.keymapping[86] = "V"
	self.keymapping[66] = "B"
	self.keymapping[78] = "N"
	self.keymapping[77] = "M"
end

-- This function is called whenever we the Addon needs to store information in it's local files.
function ClairvoyanceEx:OnSave(eType)
  -- We only care about storing our settings on Character level. In all other cases, we simply
  -- leave the function and return no data to be stored.
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil
	end

  -- Collection the locations of the two windows of our Addon and store it
  -- inside our internal table structure.
  self:StorePositions()
	
	-- Create the local data structure we will be returning to hold all data and return it
	-- once it's populated with all information we want to track.
	local tSaved = {
		tLocations = self.tLocations,
		bDisplayBackground = self.bDisplayBackground
	}

	return tSaved
end

-- This function is called whenever the Addon needs to restore data from it's local files.
-- Because a difference in version might destroy the data structure, we will check our versions
-- before loading the information.
function ClairvoyanceEx:OnRestore(eLevel, tData)
  -- We only care about data that's being loaded on Character level.
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
    if tData.tLocations then
      self.tLocations = {
        tNotificationLocation = tData.tLocations.tNotificationLocation,
        tDisorientLocation = tData.tLocations.tDisorientLocation,
        tWeaponLocation = tData.tLocations.tWeaponLocation
      }
    end
		
    if tData.bDisplayBackground ~= nil then
      self.bDisplayBackground = tData.bDisplayBackground
    end
	end
end

-----------------------------------------------------------------------------------------------
-- ClairvoyanceEx Instance
-----------------------------------------------------------------------------------------------
local ClairvoyanceInst = ClairvoyanceEx:new()
ClairvoyanceInst:Init()
