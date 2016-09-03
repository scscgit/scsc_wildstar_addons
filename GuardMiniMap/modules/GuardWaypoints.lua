require "Apollo"
require "GameLib"
require "Unit"
require "ICComm"
require "ICCommLib"
require "XmlDoc"

local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage
local GuardWaypointsPackage, GuardWaypointsPackageVersion = "GMM:GuardWaypoints-1.7", 1
local packageTest = Apollo.GetPackage(GuardWaypointsPackage)
-- if the package is already registered, there's no need to do so again
if packageTest ~= nil and packageTest.tPackage ~= nil then
	return
end

local GuardWaypoints = {}

-- set up our global table that will house the Waypoints
-- this lets us share them between the minimap and the zonemap very easily
if not g_tGuardWaypoints then
	g_tGuardWaypoints = {}
end

function GuardWaypoints:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("modules\\guardwaypoints.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self) 

	Apollo.RegisterSlashCommand("gway", "OnGuardWaypoints", self)
	
	self.WaypointTimer = ApolloTimer.Create(1.0, true, "OnWaypointCheck", self)
end

function GuardWaypoints:OnDocumentReady()
	self.wndContextMenu	= Apollo.LoadForm(self.xmlDoc, "WaypointContext", nil, self)
	self.wndContextMenu:Show(false)

	self.wndRenamePrompt	= Apollo.LoadForm(self.xmlDoc, "WaypointRename", nil, self)
	self.wndRenamePrompt:Show(false)
	
	self.wndColor = Apollo.LoadForm(self.xmlDoc, "WaypointColor", nil, self)
	self.wndColor:Show(false)
	self.wndColorSquare = self.wndColor:FindChild("ColorIndicator")
end

function GuardWaypoints:GetDefaultColor()
	if self.tDefaultColor ~= nil then
		return self.tDefaultColor
	else
		return { Red = 0, Green = 1, Blue = 0 }
	end
end

function GuardWaypoints:new(tWorldLoc, tZoneInfo, strName, tColorOverride, bPermanent)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	-- equivalency is determined if the x and z coordinates are the same and it is for the same continent
	self.__eq =	function(a,b)
					return a.tWorldLoc.x == b.tWorldLoc.x and a.tWorldLoc.z == b.tWorldLoc.z and a.nContinentId == b.nContinentId
				end

	-- if tZoneInfo wasn't supplied, use the current zone
	tLocalZoneInfo = tZoneInfo or GameLib.GetCurrentZoneMap()

	if bPermanent then
		o.bPermanent		= true
		o.strIcon			= "GMM_PermWaypointMarker"
	else
		o.bPermanent		= false
		o.strIcon			= "GMM_WaypointMarker"
	end

	if not tColorOverride then
		local tDefaultColor = self:GetDefaultColor()
		o.tColorOverride  = { Red = tDefaultColor.Red, Green = tDefaultColor.Green, Blue = tDefaultColor.Blue }
	else
		o.tColorOverride = tColorOverride
	end

	o.crObject			= CColor.new(o.tColorOverride.Red, o.tColorOverride.Green, o.tColorOverride.Blue, 1)

	o.nContinentId    = tLocalZoneInfo.continentId
	o.tWorldLoc       = tWorldLoc
	o.tZoneInfo       = tLocalZoneInfo
	o.nMinimapObjectId = nil
	o.nZoneMapObjectId = nil
	if not strName then
		if tZoneInfo then
			o.strName         = string.format("Waypoint for %s", tZoneInfo.strName)
		else
			o.strName         = string.format("Waypoint for %s", "Unknown Location")
		end
	else
		o.strName = strName
	end

	return o
end

----------------------------------------------------------------------------------------------------------
-- Functions for working with communicating waypoints between group members
----------------------------------------------------------------------------------------------------------

function GuardWaypoints:JoinChannel(strAddonName)
	self.Addon = Apollo.GetAddon(strAddonName)
	self.channel = ICCommLib.JoinChannel("GuardWaypoints_Comm", ICCommLib.CodeEnumICCommChannelType.Group)
	self.channelTimer = ApolloTimer.Create(1, true, "SetICCommCallback", self)
end

function GuardWaypoints:SetICCommCallback()

	if not self.channel then
		self.channel = ICCommLib.JoinChannel("GuardWaypoints_Comm", ICCommLib.CodeEnumICCommChannelType.Group)
	end
	
	if self.channel:IsReady() then
		self.channel:SetReceivedMessageFunction("OnICCommMessage", self.Addon)
        self.channel:SetSendMessageResultFunction("OnICCommSendMessageResult", self.Addon)
		self.channel:SetJoinResultFunction("JoinResultEvent", self.Addon)
		self.channelTimer = nil

		--self.MessageTimer = ApolloTimer.Create(5, true, "TestMessage", self)

	end
end

function GuardWaypoints:TestMessage()
	Print("TestMessage")
	self.channel:SendMessage("Testing")
end


function GuardWaypoints.FromTable(tData)
	return GuardWaypoints:new(tData.tWorldLoc, tData.tZoneInfo, tData.strName, tData.tOpt)
end

function GuardWaypoints:ToTable()
	return	{
				strName = self.strName,
				tWorldLoc = self.tWorldLoc,
				tZoneInfo = self.tZoneInfo,
				tOpt = self.tOpt
			}
end

function GuardWaypoints:SendWaypoint(tWaypoint, strRecipient)

	local tMsg = tWaypoint:ToTable()

	if strRecipient ~= nil then
		if type(strRecipient) == "string" then
			strRecipient = { strRecipient }
		end

		if type(strRecipient) ~= "table" then
			Print("[GuardWaypoints DEBUG]: Attempting to send waypoint to: " .. tostring(strRecipient))
			return
		end

		--self.channel:SendPrivateMessage(strRecipient, tMsg)
		self.channel:SendMessage(JSON.encode(tMsg))
	end
end

function GuardWaypoints:JoinResultEvent(iccomm, eResult)
	--Print("Join Result")
end

function GuardWaypoints:OnICCommSendMessageResult(iccomm, eResult, idMessage)
	--Print("Sent Message")
end

function GuardWaypoints:OnICCommMessage(channel, strMessage, idMessage) 
	local tMsg = JSON.decode(strMessage)

	if tMsg ~= nil and type(tMsg) == "table" then
			local tWaypoint = GuardWaypoints.FromTable(tMsg)
			GuardWaypoints:Add(tWaypoint)

			--Print("GuardWaypoints: Received waypoint from group member")

	end
end

function GuardWaypoints:BuildGroupMemberList()
	local nMemberCount = GroupLib.GetMemberCount()
	if nMemberCount > 0 then
		local strPlayerName = GameLib.GetPlayerUnit():GetName()
		local tGroupMembers = {}
		for idx = 1, nMemberCount do
			local tMemberInfo = GroupLib.GetGroupMember(idx)
			if tMemberInfo ~= nil and tMemberInfo.strCharacterName ~= strPlayerName then
				table.insert(tGroupMembers, tMemberInfo.strCharacterName)
			end
		end
		return tGroupMembers
	end
end

function GuardWaypoints:IsInYourGroup(strSender)
	if GroupLib.InGroup() then 
		local tMembers = self:BuildGroupMemberList()

		for idx, strName in ipairs(tMembers) do
			if strName == strSender then
				return true
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------
-- Functions relating to Waypoint location checks
----------------------------------------------------------------------------------------------------------
local function CalculateDistance2D(tPos1, tPos2)
	if not tPos1 or not tPos2 then
		return
	end
	
	local nDeltaX = tPos2.x - tPos1.x
	local nDeltaZ = tPos2.z - tPos1.z
	
	local nDistance = math.sqrt(math.pow(nDeltaX, 2) + math.pow(nDeltaZ, 2))
	return nDistance, nDeltaX, nDeltaZ
end

function GuardWaypoints:OnWaypointCheck()
	
	local tPosPlayer = GameLib.GetPlayerUnit():GetPosition()
	local iWaypointCount = #g_tGuardWaypoints
	
	for i=iWaypointCount, 1, -1 do
		local tPosWaypoint = g_tGuardWaypoints[i].tWorldLoc

		if g_tGuardWaypoints[i].bPermanent == nil or g_tGuardWaypoints[i].bPermanent == false then
			local nDistance, nDeltaX, nDeltaZ = CalculateDistance2D(tPosPlayer, tPosWaypoint)

			if nDistance <= 15 then
				self:Remove(g_tGuardWaypoints[i])
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------
-- Handle the /gway command
----------------------------------------------------------------------------------------------------------
function GuardWaypoints:OnGuardWaypoints(cmd, args)
	if args ~= nil then
		if args:lower() == "clear" then
			local iWaypointCount = #g_tGuardWaypoints
	
			for i=iWaypointCount, 1, -1 do
				if g_tGuardWaypoints[i].bPermanent == nil or g_tGuardWaypoints[i].bPermanent == false then
					self:Remove(g_tGuardWaypoints[1])
				end
			end
		elseif args:lower() == "clearall" then
			local iWaypointCount = #g_tGuardWaypoints
	
			for i=iWaypointCount, 1, -1 do
				self:Remove(g_tGuardWaypoints[1])
			end
		else
			-- Regex to match arguments in the format of coord, coord <Name>
			local x, z, strName = args:match("^(-?%d+%.?%d*)%s*,%s*(-?%d+%.?%d*)%s*(.*)$")
				
			x = math.floor(tonumber(x))
			z = math.floor(tonumber(z))

			if x ~= nil and z ~= nil then
				-- Check if the name ended in -p to indicate permanent
				local strPermName = strName:match("^(.*)%s-p$")
				local bPermWay = false

				if strPermName and strPermName:len() > 0 then
					bPermWay = true
					strName = strPermName:gsub("-", "")
				end
				
				if strName == nil or strName:len() == 0 then 
					strName = nil
				end

				GuardWaypoints:AddNew({x = x, z = z}, nil, strName, self.tDefaultColor, bPermWay)
			end
		end
	else
		
	end
end

----------------------------------------------------------------------------------------------------------
-- Functions relating to the context menu
----------------------------------------------------------------------------------------------------------

function GuardWaypoints:ShowContextMenu(iWaypointIndex, wndMain)

	if not self.wndContextMenu then
		Print("Error loading the context menu!")
		return
	end
	
	local tMouse = Apollo:GetMouse()
	self.wndContextMenu:SetAnchorOffsets(tMouse.x, tMouse.y - 25, tMouse.x + 164, tMouse.y + 183)
	self.wndContextMenu:SetData(iWaypointIndex)
	self.wndContextMenu:Show(true)
	if wndMain then
		wndMain:ToFront()
	end
	self.wndContextMenu:ToFront()
	self.wndContextMenu:SetData(iWaypointIndex)	
end

function GuardWaypoints:OnWaypointButtonClicked( wndHandler, wndControl, eMouseButton )
	local strCommand = wndControl:FindChild("lblButtonLabel"):GetText()

	if strCommand == "Share Waypoint" then
		local tWaypoint = g_tGuardWaypoints[self.wndContextMenu:GetData()]
		self:SendWaypoint(tWaypoint, "")
		self.wndContextMenu:Show(false)
	elseif strCommand == "Rename Waypoint" then	
		local tWaypoint = g_tGuardWaypoints[self.wndContextMenu:GetData()]
		self.wndRenamePrompt:SetData(self.wndContextMenu:GetData())
		self.wndRenamePrompt:FindChild("ebWaypointName"):SetText(tWaypoint.strName)
		self.wndContextMenu:Show(false)
		self.wndRenamePrompt:Show(true)
		self.wndRenamePrompt:ToFront()
	elseif strCommand == "Remove Waypoint" then
		local tWaypoint = g_tGuardWaypoints[self.wndContextMenu:GetData()]
		self:Remove(tWaypoint)
		self.wndContextMenu:Show(false)
	elseif strCommand == "Toggle Permanency" then
		local tWaypoint = g_tGuardWaypoints[self.wndContextMenu:GetData()]
		self:TogglePermanency(tWaypoint)
		self.wndContextMenu:Show(false)
	elseif strCommand == "Recolor Waypoint" then
		local tWaypoint = g_tGuardWaypoints[self.wndContextMenu:GetData()]
		local nRed = tWaypoint.tColorOverride.Red * 100
		local nGreen = tWaypoint.tColorOverride.Green * 100
		local nBlue = tWaypoint.tColorOverride.Blue * 100

		self.wndColor:FindChild("RedSliderBar"):SetValue(nRed)
		self.wndColor:FindChild("GreenSliderBar"):SetValue(nGreen)
		self.wndColor:FindChild("BlueSliderBar"):SetValue(nBlue)

		self.wndColor:SetData(self.wndContextMenu:GetData())
		self.wndContextMenu:Show(false)
		
		local crNewColor = CColor.new(nRed/100.0, nGreen/100.0, nBlue/100.0, 1)

		self.wndColorSquare:SetBGColor(crNewColor )

		self.wndColor:Show(true)
		self.wndColor:ToFront()

	end
end

function GuardWaypoints:OnConfirmRenameClick( wndHandler, wndControl, eMouseButton )
	local tWaypoint = g_tGuardWaypoints[self.wndRenamePrompt:GetData()]
	self:Rename(tWaypoint, self.wndRenamePrompt:FindChild("ebWaypointName"):GetText())
	self.wndRenamePrompt:Show(false)
end

function GuardWaypoints:OnCancelRenameClick( wndHandler, wndControl, eMouseButton )
	self.wndRenamePrompt:Show(false)
end

---------------------------------------------------------------------------------------------------
-- WaypointColor Functions
---------------------------------------------------------------------------------------------------

function GuardWaypoints:OnColorSliderChanged( wndHandler, wndControl, fNewValue, fOldValue )
	local nRed 		= self.wndColor:FindChild("RedSliderBar"):GetValue()/100.0
	local nGreen 	= self.wndColor:FindChild("GreenSliderBar"):GetValue()/100.0
	local nBlue 	= self.wndColor:FindChild("BlueSliderBar"):GetValue()/100.0
		
	local crNewColor = CColor.new(nRed, nGreen, nBlue, 1)

	self.wndColorSquare:SetBGColor(crNewColor )
end

function GuardWaypoints:btnApplyColorClicked( wndHandler, wndControl, eMouseButton )
	local tWaypoint = g_tGuardWaypoints[self.wndColor:GetData()]
	
	self:Recolor(tWaypoint)
	
	self.wndColor:Show(false)
end

function GuardWaypoints:btnCancelColorClicked( wndHandler, wndControl, eMouseButton )
	self.wndColor:Show(false)
end

function GuardWaypoints:Recolor(tWaypoint)
	local nRed 		= self.wndColor:FindChild("RedSliderBar"):GetValue()/100.0
	local nGreen 	= self.wndColor:FindChild("GreenSliderBar"):GetValue()/100.0
	local nBlue 	= self.wndColor:FindChild("BlueSliderBar"):GetValue()/100.0
		
	local crNewColor = CColor.new(nRed, nGreen, nBlue, 1)

	self:Remove(tWaypoint)
	tWaypoint.crObject = crNewColor
	tWaypoint.tColorOverride = { Red = nRed, Green = nGreen, Blue = nBlue }
	self:Add(tWaypoint)	
end

function GuardWaypoints:btnDefaultColorClicked( wndHandler, wndControl, eMouseButton )
	local nRed 		= self.wndColor:FindChild("RedSliderBar"):GetValue()/100.0
	local nGreen 	= self.wndColor:FindChild("GreenSliderBar"):GetValue()/100.0
	local nBlue 	= self.wndColor:FindChild("BlueSliderBar"):GetValue()/100.0

	self.tDefaultColor = { Red = nRed, Green = nGreen, Blue = nBlue }

	Event_FireGenericEvent("GuardWaypoints_DefaultColorSet", self.tDefaultColor)
end

----------------------------------------------------------------------------------------------------------
-- Functions relating to adding waypoints to the zone map and minimap
----------------------------------------------------------------------------------------------------------
function GuardWaypoints:AddToZoneMap(tCurrentZoneInfo, eMarkerType)
	-- Make sure the zone map global has been set correctly
	if g_wndTheZoneMap == nil then
		return
	end

	if self.nZoneMapObjectId then
		g_wndTheZoneMap:RemoveObject(self.nZoneMapObjectId)
	end
	
	if tCurrentZoneInfo.continentId  == self.nContinentId then
		local strName = self.strName and string.format("Waypoint: %s", self.strName) or "Unnamed Waypoint"
		self.nZoneMapObjectId = g_wndTheZoneMap:AddObject(	eMarkerType, 
															self.tWorldLoc, 
															strName, 
															{
																strIcon           = self.strIcon,
																strIconEdge       = self.strIcon,
																crObject          = self.crObject,
																crEdge            = self.crObject,
															}, 
															{ 
																bNeverShowOnEdge  = false 
															}
														 )
	end

end

function GuardWaypoints:AddToMinimap(eMarkerType)
	-- Make sure the mini map global has been set correctly
	if g_wndTheMiniMap == nil then
		return
	end

	if self.nMinimapObjectId then
		g_wndTheMiniMap:RemoveObject(self.nMinimapObjectId)
	end

	local tCurrentZoneInfo = GameLib.GetCurrentZoneMap()

	if not tCurrentZoneInfo then
		return
	end

	if tCurrentZoneInfo.continentId == self.nContinentId then

		local strName = self.strName and string.format("Waypoint: %s", self.strName) or "Unnamed Waypoint"
		self.nMinimapObjectId = g_wndTheMiniMap:AddObject(	eMarkerType, 
															self.tWorldLoc, 
															strName, 
															{
																strIcon			= self.strIcon,
																crObject		= self.crObject,
																crEdge			= self.crObject,
																strIconEdge		= "MiniMapObjectEdge",
																bAboveOverlay	= true
															}
														)
	end

end

----------------------------------------------------------------------------------------------------------
-- Functions for Creating / Adding waypoints into the table listing
----------------------------------------------------------------------------------------------------------
function GuardWaypoints:AddNew(...)
	local tWaypoint = GuardWaypoints:new(...)
	
	self:Add(tWaypoint)

	return tWaypoint
end

function GuardWaypoints:Add(tWaypoint)

	for idx, tCurWaypoint in ipairs(g_tGuardWaypoints) do
		-- if the waypoint already exists, bail out
		if tCurWaypoint == tWaypoint then
			return nil
		end
	end

	table.insert(g_tGuardWaypoints, tWaypoint)
	Event_FireGenericEvent("GuardWaypoints_WaypointAdded", tWaypoint)

end

function GuardWaypoints:Rename(tWaypoint, strNewName)

	self:Remove(tWaypoint)
	tWaypoint.strName = strNewName
	self:Add(tWaypoint)

end

function GuardWaypoints:TogglePermanency(tWaypoint)

	self:Remove(tWaypoint)
	if tWaypoint.bPermanent == nil or tWaypoint.bPermanent == false then
		tWaypoint.bPermanent = true
		tWaypoint.strIcon	 = "GMM_PermWaypointMarker"
	else
		tWaypoint.bPermanent = false
		tWaypoint.strIcon	 = "GMM_WaypointMarker"
	end

	self:Add(tWaypoint)

end

----------------------------------------------------------------------------------------------------------
-- Functions for removing waypoints from the table listing and the zone map / minimap
----------------------------------------------------------------------------------------------------------
function GuardWaypoints:Remove(tWaypoint)
	if tWaypoint == nil then
		return
	end

	for idx, tCurWaypoint in ipairs(g_tGuardWaypoints) do
		-- remove the waypoint from the global array
		if tCurWaypoint == tWaypoint then
			table.remove(g_tGuardWaypoints, idx)
			break
		end
	end

	if g_wndTheZoneMap ~= nil and tWaypoint.nZoneMapObjectId then
		g_wndTheZoneMap:RemoveObject(tWaypoint.nZoneMapObjectId)
	end

	if g_wndTheMiniMap ~= nil and tWaypoint.nMinimapObjectId then
		g_wndTheMiniMap:RemoveObject(tWaypoint.nMinimapObjectId)
	end

	Event_FireGenericEvent("GuardWaypoints_WaypointRemoved", tWaypoint)
end


-- Last step is to register the package with Apollo for consumption
Apollo.RegisterPackage(GuardWaypoints, GuardWaypointsPackage, GuardWaypointsPackageVersion, {})