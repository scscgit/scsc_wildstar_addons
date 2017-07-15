-----------------------------------------------------------------------------------------------
--Owner: j05ch
--Edit & updated by: Nikolai Kondich (NexTLab)
-- Copyright informations: GNU GPL (General Public)
-----------------------------------------------------------------------------------------------

require "Window"
require "ICComm"
require "ICCommLib"
require "CombatFloater"
-----------------------------------------------------------------------------------------------
-- WorldBossNotifier Module Definition
-----------------------------------------------------------------------------------------------
local WorldBossNotifier = {} 

local version = {2, "Ver. 1.1.0"}

local JSON = Apollo.GetPackage("Lib:dkJSON-2.5").tPackage

local WbData = {} -- note: this is not saved beyond logout 

local dbg_vars = {
	msgReceived = 0, 
	throttledCount = 0,
	msgSent = 0,
	msgBlocked = 0,
	msgSentRegardless = 0,
	broadcastSent = 0,
	broadcastBlocked = 0,
	unrecognized_msg_type = 0,
	bossMsgReceived = 0,
	structureNotReady = 0
}

local is_in_global_channel = false -- will be set within the script
local global_channel_cmd = "" -- "   "

local msg_types = {
	boss			= 1, -- typical boss message
	version 		= 2, -- for version check
	person			= 3, -- to generate list of "online" people
	announcement	= 4  -- when people use the addon to announce stuff
}
-- no time to wait my friend!
local joinWaitTime = 30 -- Waiting Time in the Syncchannel

-------------------------------------------------------------------
----------------------Initialization-------------------------------
-------------------------------------------------------------------
function WorldBossNotifier:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

	if(self.storedVars == nil) then
		self.storedVars = {}
	end
	
	-- init options if needed
	if self.storedVars["settings"] == nil then 
		self.storedVars["settings"] = {
			keep_notification_btn = false, -- do not hide the notification button when there are no events live
			penetration_notification_threshold = 38, -- the particle amount which shall cause a penetrant alarm
			ready_check_sound = true,
			play_sound_on_threshold_exceed = true,
			play_sound_on_boss_incoming = true,
			play_sound_on_summon = true,
			use_smart_view = true,
				use_smart_view_vertical = true,
				use_smart_view_horizontal = false
			
		}
	end
	
	self.nearby_players = {}
	self.nearby_teleporters = {}
	self.announce_block = {}
	self.player_list = {}
	
	self.commchan = { -- fake commchan obj
		SendMessage = function() end,
		IsReady = function() return false end,
		SetReceivedMessageFunction = function() end,
		SetThrottledFunction = function() end
	}

    return o
end

local eventStati = { -- TODO perhaps create a extra file for this.. 
	[13]		= "On Cooldown OR Spawning shortly",
	[7]			= "Farming Particles",
	[0]			= "Up for the kill",
	
	-- custom stati used within the string to status parsing function........ [....]
	[20]		= "CD",
	[30]		= "Spawn",
	[90]		= "Unknown Status"
}
local eventStatiSmart = {
	[13]		= "CD OR Spawn",
	[7]			= "Farm",
	[0]			= "Up",
	
	--
	[20]		= "CD",
	[30]		= "Spawn",
	[90]		= "Unknown"
}


function WorldBossNotifier:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

	
	Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self) -- for the check if someone wrote "join"	
	Apollo.RegisterEventHandler("Group_ReadyCheck",	"OnReadyCheck", self)
	
	Apollo.RegisterEventHandler("ProgressClickWindowDisplay", "OnCSI", self) -- to check for the summoning prompt
	
	Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self) -- for being able to create a list of nearby players
	Apollo.RegisterEventHandler("UnitActivationTypeChanged", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitNameChanged", "OnUnitCreated", self)
	Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
	
	-- lang stuff
	if(Apollo.GetString(1) == "Abbrechen") then
		self.lang = "de"
		--self.time_format = "%d.%m.%Y - %H:%M"
	elseif (Apollo.GetString(1) == "Cancel") then
		self.lang = "en"
		--self.time_format = "%m/%d/%Y - %H:%M"
	elseif(Apollo.GetString(1) == "Annuler") then
		self.lang = "fr"
		--self.time_format = "%m/%d/%Y - %H:%M" -- ? 
	end

end
---------------------------------------------------------------------
------------------------------- LOADER-------------------------------
---------------------------------------------------------------------
function WorldBossNotifier:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("WorldBossNotifier.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
--	self.wbnVersion = "1.0.5"
--	self.connectTimer = ApolloTimer.Create(1, true, "ConnectVer", self)
--	self.connectTimer:Start()
--	self.bNotified = false
--	self.highestVer = self.wbnVersion
end
-- Versionschecker = WIP ... its very instable
----------------------------------------------------------------------
----------------------------WBN Versionscheck-------------------------
----------------------------------------------------------------------
--[[
function WorldBossNotifier:ConnectVer()
	if not self.verComm then
		self.verComm = ICCommLib.JoinChannel("WBNVersion", ICCommLib.CodeEnumICCommChannelType.Global);
		if self.verComm then
			self.verComm:SetReceivedMessageFunction("OnVersionReceived", self)
			self.verComm:SendMessage(tostring(self.wbnVersion))
		end
	elseif not self.xferComm then
		self.xferComm = ICCommLib.JoinChannel("WBNXFer", ICCommLib.CodeEnumICCommChannelType.Global);
		if self.xferComm then
			self.xferComm:SetReceivedMessageFunction("OnXFerReceived", self)
		end
	else
		self.connectTimer:Stop()
	end 
end

function WorldBossNotifier:Vent(player, text)
	local target = GameLib.GetPlayerUnit():GetTarget()
	if target ~= nil then
		self.verComm:SendPrivateMessage(player, "wbnspeak " .. target:GetId() .. " " .. text)
	end
end

function WorldBossNotifier:VentAll(text)
	local target = GameLib.GetPlayerUnit():GetTarget()
	if target ~= nil then
		self.verComm:SendMessage("wbnspeak " .. target:GetId() .. " " .. text)
	end
end

function WorldBossNotifier:OnVersionReceived(iccomm, strMessage, strSender)
	local seenVer = tonumber(strMessage)
	if seenVer then
		if seenVer > self.highestVer then
			self.highestVer = seenVer
			if not self.bNotified then
				self.wndMain:FindChild("Title"):SetText("UPDATE NEEDED")
				self.wndMain:FindChild("Title"):SetTextColor({r=1,b=0,g=0,a=1})
				self.bNotified = true
			end
		end
	elseif strMessage == "request" then
		self.verComm:SendPrivateMessage(strSender, "running version " .. tostring(self.wbnVersion))
	elseif strMessage == "showerrors" then
		local errors = Apollo.GetAddonInfo("NexTLab_WBN").arErrors
		if errors ~= nil then
			for _, e in pairs(errors) do
				self.verComm:SendPrivateMessage(strSender, e)
			end
		end
	elseif string.sub(strMessage, 1, 9) == "wbnspeak " and 
		(strSender == "Nikolai Kondich" or strSender == "Thea Gewittersturm" or strSender == "Naya Redhall") then
		local args = string.sub(strMessage, 10, -1)
		local spaceInd = string.find(args, " ")
		if spaceInd ~= nil and spaceInd > 1 then
			local id = tonumber(string.sub(args, 1, spaceInd - 1))
			local message = string.sub(args, spaceInd + 1)
			if id ~= nil then
				local unit = GameLib.GetUnitById(id)
				if unit ~= nil then
					unit:AddTextBubble(message)
				end
			end
		end
	elseif string.find(GameLib.GetPlayerUnit():GetName(), "Nikolai") ~= nil then -- Assuming nobody else wants to see this stuff:P
		Print(strSender .. ": " .. strMessage)
	end
end
--]]
--------------------------------------------------------------------------
------------------------ WIP Versioncheck Close---------------------------
--------------------------------------------------------------------------

function WorldBossNotifier:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "WorldBossNotifierForm", nil, self)
	    self.wndMain:Show(false, true)
		self.wndMain:SetSizingMinimum(400, 280)
		self.wndMain:AddEventHandler("WindowMove", "OnMainWindowMove")
		Apollo.LoadForm(self.xmlDoc, "Spacer", self.wndMain:FindChild("JoinWatch"), self)
		self.wndMain:FindChild("Version"):SetText("("..version[2]..")")
		
		self.wndWayTo = Apollo.LoadForm(self.xmlDoc, "WayToForm", nil, self)
		self.wndWayTo:Show(false)

		self.wndNotifyBtn = Apollo.LoadForm(self.xmlDoc, "NotifyButton", nil, self)
		self.wndNotifyBtn:Show(false)
		
		self.debugWin = Apollo.LoadForm(self.xmlDoc, "DebugWin", nil, self)
		self.debugWin:Show(false)
		
		self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsWindow", nil, self)
		self.wndOptions:Show(false)	
		self.wndMain:FindChild("OptionsBtn"):AttachWindow(self.wndOptions)
		
		self.wndHelp = Apollo.LoadForm(self.xmlDoc, "HelpForm", nil, self)
		self.wndHelp:Show(false)
		
		self.wndChange = Apollo.LoadForm(self.xmlDoc, "HelpForm", nil, self)
		self.wndChange:Show(false)
		
		self.wndTools = Apollo.LoadForm(self.xmlDoc, "ToolFrame", nil, self)
		self.wndTools:Show(false)
		self.wndMain:FindChild("UtilsBtn"):AttachWindow(self.wndTools)
		
		self.wndSmart = Apollo.LoadForm(self.xmlDoc, "SmartOverview", nil, self)
		self.wndSmart:Show(false)
		
		Apollo.RegisterSlashCommand("wbn", "OnWorldBossNotifierOn", self)
		Apollo.RegisterSlashCommand("wbnplayers", "OnCmdWbnPlayers", self)
		
		Apollo.RegisterSlashCommand("wbndebug", "OnCmdWbndebug", self)
		Apollo.RegisterSlashCommand("wbntest", "OnCmdWbntest", self) -- TODO remove later..

		-- TIMERS
		self.pe_timer = ApolloTimer.Create(2.0, true, "CheckPublicEventsTimer", self) -- the main timer
		self.gui_update_timer = ApolloTimer.Create(1.0, true, "UpdateBossView", self)
		self.version_bc_timer = ApolloTimer.Create(30*60, true, "TellVersion", self)
		self.player_list_timer = ApolloTimer.Create(10*60, true, "IAmOnline", self)
			--self.broadcast_data_timer = ApolloTimer.Create(1*60, true, "BroadcastData", self) -- TODO EDIT BACK TO 10*60

		--self:JoinICCChannel()
		self.join_wait_timer = ApolloTimer.Create(1.0, true, "JoinCountDown", self)
		
		-- loading data
		self.dataLoaderTimer = ApolloTimer.Create(0.5, true, "LoadAddonDataStructure", self) 
		
		-- join custom channel
		--ChatSystemLib.JoinChannel("WorldBossNotifier")
	end
end

local join_watch_blacklist = { -- todo put into another file
	"recruit",
	"guild",
	"vet",
	"veteran",
	"expedition",
	"dungeon",
	"shiphand"
}
function WorldBossNotifier:OnChatMessage(channelCurrent, tMessage)
	if channelCurrent:GetName() == "Nexus" or channelCurrent:GetName() == "Nexus" then
		local m = tMessage["arMessageSegments"][1]["strText"]
		if string.find(string.lower(m), "join") then
			local string_seems_legit = true
			for i, blword in pairs(join_watch_blacklist) do
				if string.find(string.lower(m), blword) then
					string_seems_legit = false
				end
			end
			if string_seems_legit then
				local entry = Apollo.LoadForm(self.xmlDoc, "PlayerEntry", self.wndMain:FindChild("JoinWatch"), self)
				if string.sub(m, 2,4) == "WBN" then
					entry:SetText(string.sub(m,20))
					entry:SetTooltip("["..(os.date("%H:%M", os.time())).."] "..tMessage["strSender"]..": "..string.sub(m,20)) 
				else
					entry:SetText("["..(os.date("%H:%M", os.time())).."] "..tMessage["strSender"])
					entry:SetTooltip(tMessage["arMessageSegments"][1]["strText"])
				end
				entry:SetData({playerName = tMessage["strSender"]})
				self.wndMain:FindChild("JoinWatch"):ArrangeChildrenVert()
			end
		end
	end
end

function WorldBossNotifier:JoinCountDown()
	if joinWaitTime == 0 then
		self.join_wait_timer:Stop() 
		self.wndMain:FindChild("JoinWait"):Destroy()
		self:JoinICCChannel()
	else
		joinWaitTime = joinWaitTime - 1 
		self.wndMain:FindChild("JoinWait:JoinWaitSeconds"):SetText(joinWaitTime)
	end
end

function WorldBossNotifier:CheckForWbEvent(event)
	if(event:GetEventType() == PublicEvent.PublicEventType_WorldEvent) then

		for ev_id,ev_data in pairs(wbEventIds) do -- iterate over the addons boss data (defined at the addons start)
			if(event:GetId() == ev_id) then -- found that a event we see in the tracker matches a worldboss event
				-- find the current active objective 
				for k,v2 in pairs(event:GetObjectives()) do
				
				  if v2:GetStatus() == 1 then -- > the objective is active
					
					-- parse the event objective shot description string to find out what we are on if necessary. If not necessary just take the right status ID out of the definition structure
					local status = v2:GetObjectiveType()
					if status == 13 then -- status 13 is both used for "on CD" and for "boss coming shortly" so we need something else to identify what currently going on
						status = self:GetStatusByString(v2:GetShortDescription())
					end
					
					local health = "??%"
					-- new version
					if v2:GetTrackedUnits()[1] ~= nil then 
						local tu = v2:GetTrackedUnits()[1]
						if tu then -- somehow redundant
							if tu:GetHealth() and tu:GetMaxHealth() then
								health = self:round((tu:GetHealth() / tu:GetMaxHealth()) * 100, 2)
							end
						end 
					end
					
					local json_data = {
						type = msg_types["boss"],
						--en = ev_data["boss_name"], -- event name / later refactored to "boss name"
						s = status, -- status id (for "up for the kill", "spawning" ... )
						cc = v2:GetCount(), -- current count of objective
						rc = v2:GetRequiredCount(), -- required count
						eId = event:GetId(), -- event id / boss id of the addons boss info structure (top of the addon)
						hp = health, -- calculated health of the boss
						msgsrc = "wbn"
					}
					
					local encoded_json_data = JSON.encode(json_data) -- shorthand var for performance
					
					-- perhaps send a message (by condition)
					if WbData[ev_id] ~= nil then
						-- block sending of messages when you already received a message from someone else within the last x seconds
						if WbData[ev_id]["time"] + 3 < os.time() then
							self.commchan:SendMessage(encoded_json_data) -- remember: this is ONLY sent to OTHER clients! We as our self do NOT receive that message
							dbg_vars["msgSent"] = dbg_vars["msgSent"] + 1
							self:ReceivedMessageEvent(nil, encoded_json_data, -1)
						else
							dbg_vars["msgBlocked"] = dbg_vars["msgBlocked"] + 1
						end
					else
						self.commchan:SendMessage(encoded_json_data) -- remember: see a few lines above
						dbg_vars["msgSentRegardless"] = dbg_vars["msgSentRegardless"] + 1
						self:ReceivedMessageEvent(nil, encoded_json_data, -2)
					end
				  end
				end
			end
		end
	end
end

function WorldBossNotifier:BroadcastData()
end

function WorldBossNotifier:ReceivedMessageEvent(channel, strMessage, msgSender)

	if not wbEventIds then -- if the data structure is not yet ready
		dbg_vars["structureNotReady"] = dbg_vars["structureNotReady"] + 1
		return
	end

	local data = JSON.decode(strMessage)
	
	dbg_vars["msgReceived"] = dbg_vars["msgReceived"] + 1
	
	if data ~= nil then  
		if data["msgsrc"] == "wbn" then
			if data["type"] == msg_types["boss"] then
				local boss_id = data["eId"]
				
					WbData[boss_id] = { 
						status = data["s"],
						current_count = data["cc"],
						required_count = data["rc"],
						event_id = data["eId"], -- bzw boss id (of addons data structure)
						time = os.time(),
						health = data["hp"]
					}
				
					dbg_vars["bossMsgReceived"] = dbg_vars["bossMsgReceived"] + 1
				--end
				
				
			elseif data["type"] == msg_types["announcement"] then
				self.announce_block[data["bId"]] = os.time()
			elseif data["type"] == msg_types["version"] then
				if data["vId"] > version[1] then
					local versionInfo = Apollo.LoadForm(self.xmlDoc, "OldVersionNoti", nil, self)
					versionInfo:FindChild("YourVersion"):SetText(version[2])
					versionInfo:FindChild("NewVersion"):SetText(data["vStr"])
				end
			elseif data["type"] == msg_types["person"] then
				self.player_list[msgSender] = os.time()
			else
				dbg_vars["unrecognized_msg_type"] = dbg_vars["unrecognized_msg_type"] + 1
			end
		end
	end
end

function WorldBossNotifier:UpdateBossView() 
	-- clear button stuff
	self.wndNotifyBtn:FindChild("RelevanceContainer"):DestroyChildren()

	-- mainwindow boss buttons
	local mainw_scroll = self.wndMain:FindChild("BossList"):GetVScrollPos()
	self.wndMain:FindChild("BossList"):DestroyChildren()
	-- smartview boss buttons
	local sv_scroll_v = self.wndSmart:FindChild("SVContent"):GetVScrollPos()
	local sv_scroll_h = self.wndSmart:FindChild("SVContent"):GetHScrollPos()
	self.wndSmart:FindChild("SVContent"):DestroyChildren()
	
	Apollo.LoadForm(self.xmlDoc, "Spacer", self.wndMain:FindChild("BossList"), self)
			
	local count_of_not_oos_events = 0
	for event_boss_id, event_data in pairs(WbData) do 
	
		local entry = Apollo.LoadForm(self.xmlDoc, "BossEntry", self.wndMain:FindChild("BossList"), self)
		
		local smartEntry = nil
		if self.storedVars["settings"]["use_smart_view_vertical"] then
			smartEntry = Apollo.LoadForm(self.xmlDoc, "SmartViewEntry", self.wndSmart:FindChild("SVContent"), self) 
		else
			smartEntry = Apollo.LoadForm(self.xmlDoc, "SmartViewEntryHorz", self.wndSmart:FindChild("SVContent"), self)
		end
		
		local oos = false
		if event_data["time"] + 8 < os.time() then 
			-- out of sync
			entry:SetSprite("BK3:UI_BK3_Holo_Options_ExitGameGlow")
			entry:SetTooltip("OUT OF SYNC!\nCannot get details on this event right now! The rest-time is calculated")
			entry:FindChild("OutOfSync"):Show(true) -- icon
			entry:SetBGColor("black")
			entry:SetTextColor("CoolGrey")
			
			-- for later usage
			oos = true
		else
			count_of_not_oos_events = count_of_not_oos_events +1
		end
		
		local boss_name = wbEventIds[event_boss_id]["boss_name"]
		local ev_stat = event_data["status"]
		
		entry:SetText(
			boss_name.." ("..wbEventIds[event_data["event_id"]]["location"]..")\n".. 
			(eventStati[ev_stat] or "" ) .. "\n"
		)

		smartEntry:SetText(
--			wbEventIds[event_data["event_id"]]["boss_short"].."\n"..
			(eventStatiSmart[ev_stat] or "" ) .. "\n"
		)
--		smartEntry:SetTooltip(boss_name)
		
		if ev_stat==7 then -- 7 = farming particles
			entry:SetText(entry:GetText() .. event_data["current_count"] .. "/" .. event_data["required_count"])
			smartEntry:SetText(smartEntry:GetText() .. event_data["current_count"] .. "/" .. event_data["required_count"])
			if oos then
				local ts = (os.time() - event_data["time"]) * 1000
				--entry:SetText(entry:GetText() .. " [@" .. os.date("%H:%M", event_data["time"]) .. "]")
				entry:SetText(entry:GetText() .. " [out of sync since " .. self:HelperConvertTimeToString(ts) .. "]")
			end
			if(event_data["current_count"] > self.storedVars["settings"]["penetration_notification_threshold"]+0) then
				Apollo.LoadForm(self.xmlDoc, "Star", self.wndNotifyBtn:FindChild("RelevanceContainer"), self)
				self:NotifyWbSound(event_boss_id)
			end
		elseif ev_stat==0 then -- 0 = up for the kill
			if event_data["health"] then
				entry:SetText(entry:GetText() .. "health: " .. event_data["health"].."%")
				smartEntry:SetText(smartEntry:GetText() .. event_data["health"].."%")
			else
				entry:SetText(entry:GetText() .. "health: ??%") 
			end
		else
			if oos then
				local ts = (event_data["required_count"] - event_data["current_count"]) * 1000 - (os.time() - event_data["time"]) * 1000
				entry:SetText(entry:GetText() .. "Time left (calculated): " .. self:HelperConvertTimeToString(ts) )
			else
				entry:SetText(entry:GetText() .. "Time left: " .. self:HelperConvertTimeToString((event_data["required_count"]-event_data["current_count"])*1000) )
				smartEntry:SetText(smartEntry:GetText() .. self:HelperConvertTimeToString((event_data["required_count"]-event_data["current_count"])*1000) )
				
				-- perhaps play sound..
				if ev_stat == 30 then -- this function does also handle the "boss incoming" sound -> so also call the func here
					self:NotifyWbSound(event_boss_id)
				end
			end
		end
		
		local announce_permitted = nil
		if self.announce_block[event_boss_id] then
			announce_permitted = self.announce_block[event_boss_id] + 30 < os.time()
		else
			announce_permitted = true
		end
		
		entry:FindChild("TellBtn"):Show((not oos) and is_in_global_channel and announce_permitted) -- perhaps show the tell button (according to some condition)
		entry:FindChild("TellPlusBtn"):Show((not oos) and is_in_global_channel and announce_permitted)
		if ev_stat == 20 then -- hide A+ for on CD
			entry:FindChild("TellPlusBtn"):Show(false)
		end
		
		entry:SetData({bossId = event_data["event_id"]})
		smartEntry:SetData({bossId = event_data["event_id"]})
		
		if oos then -- make only none OOS entries appear an the smart view
			smartEntry:Destroy()
		end
		
	end -- end of loop
	
	-- auto arrange elements
	self.wndMain:FindChild("BossList"):ArrangeChildrenVert()
	self.wndNotifyBtn:FindChild("RelevanceContainer"):ArrangeChildrenHorz()

	if self.storedVars["settings"]["use_smart_view_vertical"] then
		self.wndSmart:FindChild("SVContent"):ArrangeChildrenVert()
			self.wndSmart:FindChild("SVContent"):SetStyle("VScroll", true)
			self.wndSmart:FindChild("SVContent"):SetStyle("HScroll", false)
	else
		self.wndSmart:FindChild("SVContent"):ArrangeChildrenHorz()
			self.wndSmart:FindChild("SVContent"):SetStyle("VScroll", false)
			self.wndSmart:FindChild("SVContent"):SetStyle("HScroll", true)
	end
	
	-- show the button which opens the main menu to the left of the screen if there is any event synced (otherwise hide the button)
	self.wndNotifyBtn:FindChild("ActiveCountBtn"):SetText(count_of_not_oos_events)
	if count_of_not_oos_events > 0 then
		self.wndNotifyBtn:Show(not self.storedVars["settings"]["use_smart_view"])
		
		-- show or hide smart view according to the settings
		self.wndSmart:Show(self.storedVars["settings"]["use_smart_view"])
	else
		if not self.storedVars["settings"]["keep_notification_btn"] then
			self.wndNotifyBtn:Show(false)
		end
		self.wndSmart:Show(false)
	end
	
	-- check if we are even online and set marker according
    if self.commchan then
		local led_elem = self.wndMain:FindChild("OnlineMarker")
        if self.commchan:IsReady() then
            led_elem:SetSprite("Crafting_CircuitSprites:sprCircuit_Terminal_Green")
			led_elem:SetTooltip("Communication Channel established! You are online!")			
		else
            led_elem:SetSprite("CRB_Basekit:kitIcon_NewDisabled")
			led_elem:SetTooltip("Communication Channel not established! You are offline!")
        end
    end

	-- restore the scroll position after repaint
	self.wndSmart:FindChild("SVContent"):SetVScrollPos(sv_scroll_v)
	self.wndSmart:FindChild("SVContent"):SetHScrollPos(sv_scroll_h)
	self.wndMain:FindChild("BossList"):SetVScrollPos(mainw_scroll)

	-- set up global channel join note if needed
	self:CheckGlobalChannel()

	-- debug stuff
	self:UpdateDebugWindow()
	
end

-- on SlashCommand "/wbn"
function WorldBossNotifier:OnWorldBossNotifierOn()
	self.wndMain:Invoke() -- show the window
end

-- TIMER 1
function WorldBossNotifier:CheckPublicEventsTimer()
	for k,v in pairs(PublicEvent.GetActiveEvents()) do
	  self:CheckForWbEvent(v)
	end
end

function WorldBossNotifier:OnWindowManagementReady() -- persists the window state
	Event_FireGenericEvent("WindowManagementRegister", {strName = "WorldBossNotifier"})
    Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "WorldBossNotifier"})

	Event_FireGenericEvent("WindowManagementRegister", {strName = "WorldBossNotifierButton"})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndNotifyBtn, strName = "WorldBossNotifierButton"})
	
	Event_FireGenericEvent("WindowManagementRegister", {strName = "WorldBossNotifierWayTo"})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndWayTo, strName = "WorldBossNotifierWayTo"})
	
	Event_FireGenericEvent("WindowManagementRegister", {strName = "WorldBossNotifierSmartView"})
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndSmart, strName = "WorldBossNotifierSmartView"})
end

function WorldBossNotifier:JoinICCChannel()

    self.commchan = ICCommLib.JoinChannel("Nexus", ICCommLib.CodeEnumICCommChannelType.Global)
		
    if self.commchan then
        if self.commchan:IsReady() then
            self:JoinSuccess()
        end
	else
		_CommChannelTimer = ApolloTimer.Create(8, false, "JoinICCChannel", self)
    end
end

function WorldBossNotifier:JoinSuccess()
	if _CommChannelTimer then
		_CommChannelTimer:Stop()
	end
	self.commchan:SetReceivedMessageFunction("ReceivedMessageEvent",self)
	self.commchan:SetThrottledFunction("ThrottledHandler", self)
	
end

function WorldBossNotifier:CheckGlobalChannel()
	-- check if the char already joined the global channel
	if not is_in_global_channel then
		for i, channelName in pairs(ChatSystemLib.GetChannels()) do
			if channelName:GetName() == "Nexus" then
				is_in_global_channel = true
				global_channel_cmd = channelName:GetCommand()
			end
		end
	end
	
	if is_in_global_channel then
		self.wndMain:FindChild("JoinWatch"):SetText("")
	else
		self.wndMain:FindChild("JoinWatch"):SetText("You did not join the\nNexus Channel yet!\nYou better do so!\nMost communication\non worldbosses\nis done in\nthe Nexus channel.\nuse:\n /chjoin Nexus\nAs soon as you\njoined the Nexus\nchat, this addon\nwill observe its\nmessages for the keyword\n'join' and display\npeople who wrote it.")
	end
end

function WorldBossNotifier:GetStatusByString(objString) -- this is really pfui
	if self.lang == "de" then
		
		if string.find(objString, "zur\195\188ckgesetzt") then
			return 20
		else
			--considering its spawning shorty
			return 30
		end
	
	elseif self.lang == "en" then
		
		if string.find(objString, "resetting") then
			return 20
		else
			return 30
		end
		
	elseif self.lang == "fr" then
		
		if string.find(objString, "red\195\169marre") then 
			return 20
		else
			return 30
		end
		
		--return 13 
	
	end
	-- http://www.utf8-zeichentabelle.de/unicode-utf8-table.pl?names=-&utf8=dec
	-- encodig...
end


-- when the Cancel button is clicked
function WorldBossNotifier:OnCancel()
	self.wndMain:Close() -- hide the window
end

function WorldBossNotifier:EntryBtnClicked( wndHandler, wndControl, eMouseButton ) -- player entry
	local data = wndHandler:GetData()

	local cmd = ""
	if self.lang == "de" then
		cmd = "/beitreten "
	elseif self.lang == "en" then
		cmd = "/join "
	elseif self.lang == "fr" then
		cmd = "/rejoindre "
	end
	ChatSystemLib.Command(cmd .. data["playerName"])
end

function WorldBossNotifier:BossEntryBtnClick( wndHandler, wndControl, eMouseButton )

	local boss_id = wndHandler:GetData()["bossId"]

	self.wndWayTo:FindChild("UpperArea:WindowTitle"):SetText(wbEventIds[boss_id]["boss_name"])
	
	local contentArea = self.wndWayTo:FindChild("WTContent:WTContentInner")
	
	contentArea:DestroyChildren()
	
	for elem_type, elem_detail in ipairs(wbEventIds[boss_id]["way_to"]) do -- generate the way to window according to the elements its config contains
		if elem_detail["text"] ~= nil then -- text elems
			local t = Apollo.LoadForm(self.xmlDoc, "WTTextSegment", contentArea, self)
			t:SetText(elem_detail["text"].."\n \0")
			t:SetHeightToContentHeight()
		elseif elem_detail["button"] ~= nil then -- button elems
			local b = nil
			if elem_detail["button"]["unit_enum"] then
				b = Apollo.LoadForm(self.xmlDoc, "WTButton", contentArea, self)
			else
				b = Apollo.LoadForm(self.xmlDoc, "WTCoordsBtn", contentArea, self)
			end
			b:SetText(elem_detail["button"]["bText"])
			
			b:SetData({
				coords = elem_detail["button"]["coords"],
				unit_enum = elem_detail["button"]["unit_enum"]
			})
		end
	end
	
	contentArea:ArrangeChildrenVert()

	self.wndWayTo:Show(true)
	self.wndWayTo:ToFront()
	
end

function WorldBossNotifier:TESTBTNCLICKED( wndHandler, wndControl, eMouseButton )

	local entry = Apollo.LoadForm(self.xmlDoc, "PlayerEntry", self.wndMain:FindChild("JoinWatch"), self)
	entry:SetText("TEST!")
	entry:SetData({playerName = "Amadeus Bernstein"})
		local entry = Apollo.LoadForm(self.xmlDoc, "PlayerEntry", self.wndMain:FindChild("JoinWatch"), self)
	entry:SetText("TEST2!")
	entry:SetData({playerName = "Amadeus Bernstein"})
		local entry = Apollo.LoadForm(self.xmlDoc, "PlayerEntry", self.wndMain:FindChild("JoinWatch"), self)
	entry:SetText("TEST3!")
	entry:SetData({playerName = "Amadeus Bernstein"})
	
	local evStat = {
		7,0,20,30
	}
	
	for boss_id, boss_data in pairs(wbEventIds) do
		WbData[boss_id] = {
			status = evStat[math.random(4)],
			current_count = math.random(75),
			required_count = 75,
			event_id = boss_id,
			time = os.time()
		}
	end
	
end

function WorldBossNotifier:ThrottledHandler(iccomm, strSender, idMessage)
	dbg_vars["throttledCount"] = dbg_vars["throttledCount"] + 1
end

function WorldBossNotifier:HelperConvertTimeToString(fTime) -- copied from Carbine's PublicEventStats Addon
	fTime = math.floor(fTime / 1000) 
	return string.format("%d:%02d", math.floor(fTime / 60), math.floor(fTime % 60))
end

-- Handler for buttons in the Way To Form that shall show the way to a teleporter to take
function WorldBossNotifier:WTBtnClicked( wndHandler, wndControl, eMouseButton )
	if wndHandler:GetData()["unit_enum"] then --hint arrow to target unit
		local teleporter_enum = wndHandler:GetData()["unit_enum"]
						rover("enum", teleporter_enum)
						rover("teleporters", self.nearby_teleporters)
		
		local teleporter_coord_calced_id = teleporterData[teleporter_enum] -- this converts the (for example <<defile>> to the id it stands for...
						rover("enum_to_calced_id", teleporter_coord_calced_id)
		
		local tuObj = self.nearby_teleporters[teleporter_coord_calced_id]

		
		if tuObj then
			tuObj:ShowHintArrow()
		else
			Print("WBN: Unit not in sight/too far away. Get the teleporter in sight and click again.")
		end
	elseif wndHandler:GetData()["coords"] then
		GameLib.SetNavPoint(wndHandler:GetData()["coords"], wndHandler:GetData()["zone_id"])
		GameLib.ShowNavPointHintArrow()
	end
end

function WorldBossNotifier:CloseWTFormBtn( wndHandler, wndControl, eMouseButton )
	self.wndWayTo:Show(false)
end

function WorldBossNotifier:ShowMainWindowBtn( wndHandler, wndControl, eMouseButton )
	if self.wndMain:IsShown() then
		self.wndMain:Show(false)
	else
		self.wndMain:Show(true)
	end
end

function WorldBossNotifier:OpenDebugWinBtn( wndHandler, wndControl, eMouseButton )
	self.debugWin:Show(true)
end

function WorldBossNotifier:round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function WorldBossNotifier:OnTellInChatBtn( wndHandler, wndControl, eMouseButton )
	local boss_id = wndHandler:GetParent():GetData()["bossId"]
	local boss_name = wbEventIds[boss_id]["boss_name"]
	local data = WbData[boss_id]

	local chatString = nil
	if data["status"] == 7 then
		if wndHandler:GetName() == "TellPlusBtn" then
			chatString = "Join me for "..boss_name..": "..data["current_count"].."/" ..data["required_count"] .. " (@"..wbEventIds[boss_id]["location"]..") / Group: "..GroupLib.GetMemberCount().."/40"
		else
			chatString = "Info: "..boss_name.." "..data["current_count"].."/" ..data["required_count"] .. " (@"..wbEventIds[boss_id]["location"]..")"
		end
	elseif data["status"] == 20 or data["status"] == 30 then -- timer status (on cd and spawning shortly)
		local ts = (data["required_count"] - data["current_count"]) * 1000 - (os.time() - data["time"]) * 1000
		chatString = boss_name.." (@"..wbEventIds[boss_id]["location"]..") "..eventStati[data["status"]]..": "..self:HelperConvertTimeToString(ts)
		if data["status"] == 30 then -- shortly spawning
			if wndHandler:GetName() == "TellPlusBtn" then
				chatString = "Join me for " .. chatString .. " / Group: "..GroupLib.GetMemberCount().."/40"
			else
				chatString = "Info: " .. chatString
			end
		elseif data["status"] == 20 then
			chatString = "Info: " .. chatString
		end
	elseif data["status"] == 0 then -- up for the kill
		chatString = boss_name.." "..eventStati[data["status"]] .. " (@"..wbEventIds[boss_id]["location"]..")"
		if wndHandler:GetName() == "TellPlusBtn" then
			chatString = "Join me for " .. chatString .. " / Group: "..GroupLib.GetMemberCount().."/40"
		else
			chatString = "Info: " .. chatString
		end
	end
	if chatString then
		ChatSystemLib.Command("/"..global_channel_cmd.." [N-WBN] "..chatString)
	end
	
	-- send message to let other know that the announce function shall be blocked for a time
	local json_data = {
		type = msg_types["announcement"],
		bId = boss_id,
		msgsrc = "wbn"
	}
	local encoded_json_data = JSON.encode(json_data) 
	self.commchan:SendMessage(encoded_json_data) -- you dont receive the message your self!
	self:ReceivedMessageEvent(nil, encoded_json_data, -3)
	wndHandler:GetParent():FindChild("TellBtn"):Show(false)
	wndHandler:GetParent():FindChild("TellPlusBtn"):Show(false)
end

function WorldBossNotifier:OnSaveSettingsBtn( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(false)
end

-- handle restore settings to the ui elems in the settings form when it is opened
function WorldBossNotifier:OnOptionsBtn( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Show(true)
	self.wndOptions:ToFront()
	
	for k, v in pairs(self.storedVars["settings"]) do
		local elem = self.wndOptions:FindChild(k)
		if type(elem.IsChecked) == "function" then -- got a checkbox
			elem:SetCheck(v)
		else
			elem:SetText(v)
		end
	end
end

-- handling checkbox ticks in the options window
function WorldBossNotifier:OptCheckBoxClicked( wndHandler, wndControl, eMouseButton )
	local opt_name = wndHandler:GetName()
	self.storedVars["settings"][opt_name] = wndHandler:IsChecked()
	
	-- little hack for radio groups 
	if wndHandler:GetParent():GetName() == "radio_group" then
		for k,v in pairs(wndHandler:GetParent():GetChildren()) do
			self.storedVars["settings"][v:GetName()] = v:IsChecked()
		end
	end
	
end
-- same for inputs
function WorldBossNotifier:OptInputChange( wndHandler, wndControl, strNewText, strOldText, bAllowed )
	local opt_name = wndHandler:GetName()
	self.storedVars["settings"][opt_name] = wndHandler:GetText()
end

local soundNotificationBlock = {}
function WorldBossNotifier:NotifyWbSound(boss_id)
	local d = WbData[boss_id]
	local cur_count = d["current_count"]
	local status = d["status"]
	local threshold = self.storedVars["settings"]["penetration_notification_threshold"] + 0
	
	if soundNotificationBlock[boss_id] == nil then
		soundNotificationBlock[boss_id] = {
			block_threshold_exceed_sound = false,
			block_boss_incoming_sound = false
		}
	end
	
	if status == 7 then -- farming particles
		if cur_count >= threshold and not soundNotificationBlock[boss_id]["block_threshold_exceed_sound"] then
			if self.storedVars["settings"]["play_sound_on_threshold_exceed"] then
				Sound.PlayFile("wbinc.wav")
			end 
			soundNotificationBlock[boss_id]["block_threshold_exceed_sound"] = true
		else
			if cur_count < threshold then -- reset when you do the boss again
				soundNotificationBlock[boss_id]["block_threshold_exceed_sound"] = false
			end
		end
	elseif status == 30 then -- boss incoming
		if not soundNotificationBlock[boss_id]["block_boss_incoming_sound"] then
			if self.storedVars["settings"]["play_sound_on_boss_incoming"] then 
				Sound.PlayFile("wbspawning.wav")
				soundNotificationBlock[boss_id]["block_boss_incoming_sound"] = true
			end
		else
			if status ~= 30 then
				soundNotificationBlock[boss_id]["block_boss_incoming_sound"] = false
			end
		end
	end
		
end

function WorldBossNotifier:OnRemovePlayerBtn( wndHandler, wndControl, eMouseButton )
	wndControl:GetParent():Destroy()
	self.wndMain:FindChild("JoinWatch"):ArrangeChildrenVert()
end

function WorldBossNotifier:OnSave(eType)
	if(eType == GameLib.CodeEnumAddonSaveLevel.Character) then
		return self.storedVars 
	end
end

function WorldBossNotifier:OnRestore(eType, tSavedData)
	if(eType == GameLib.CodeEnumAddonSaveLevel.Character) then
		self.storedVars = tSavedData
	end
end

function WorldBossNotifier:OnReadyCheck()
	if self.storedVars["settings"]["ready_check_sound"] then
		Sound.PlayFile("rc.wav")
	end
end

function WorldBossNotifier:UpdateDebugWindow()
	local table = self.debugWin:FindChild("Grid")
	table:DeleteAll()
	for k,v in pairs(dbg_vars) do 
		local row = table:AddRow("")
		table:SetCellText(row, 1, k)
		table:SetCellText(row, 2, v)
	end
end

function WorldBossNotifier:OnCmdWbndebug()
	self.debugWin:Show(true)
end

function WorldBossNotifier:LoadAddonDataStructure()
	if GameLib.GetPlayerUnit() ~= nil then
		if GameLib.GetPlayerUnit():GetFaction() == 167 then
			-- exile
			wbEventIds = Apollo.GetPackage("wbEventIdsExile").tPackage
		else
			-- dominion
			wbEventIds = Apollo.GetPackage("wbEventIdsDominion").tPackage
		end
		
		teleporterData = Apollo.GetPackage("teleporterData").tPackage
		
		self:OnWindowManagementReady() -- because fuck you WindowManagement ~~
		
		self.dataLoaderTimer:Stop()
	end
end

function WorldBossNotifier:OnCmdWbntest(cmd, param)
	if param == "1" then
		-- get the objectives under the current event and their ids
		Print("TODO: GET THE ID OF THE RESETTING OBJECTIVE")
		if PublicEvent.GetActiveEvents()[1] then
			for k,v in pairs(PublicEvent.GetActiveEvents()[1]:GetObjectives()) do
			  Print(v:GetShortDescription().." -> "..v:GetObjectiveId())
			end
		end
	end
	
	if param == "2" then
		for k,v in pairs(PublicEvent.GetActiveEvents()[1]:GetObjectives()) do
			for k2,v2 in pairs(v:GetTrackedUnits()) do 
				Print(v2:GetName() .. " -> ".. (v2:IsRare() and "is rare " or "is not rare ") .. " -> type: "..v2:GetType() )
			end
		end	
	end
	
	if param == "3" then
		--rover("ev", PublicEventsLib.GetActivePublicEventList()[177])
		for k,v in pairs(PublicEventsLib.GetActivePublicEventList()) do 
			--rover ("asdasd", v)
			if wbEventIds[k] then
				for k2,v2 in pairs(v:GetObjectives()) do
					if string.len(v2:GetShortDescription()) > 5 then
						-- v2:GetCategory()
						Print(v2:GetShortDescription() .. "  st:" .. v2:GetStatus().. " count:" .. v2:GetCount() .. "/"..v2:GetRequiredCount())
					end
					--rover("asdwerfsd", v2)
				end
			end
		end
	end
	
	if param == "4" then
		local tu = GameLib.GetTargetUnit()
		Print("Calced Coord ID: ".. self:HelperGetCalcedCoordId(tu))
		self.debugWin:FindChild("CalcedCoordId"):SetText(self:HelperGetCalcedCoordId(tu))
	end
	
	if param == "5" then
		Print("see rover!")
		
		--
		if(SendVarToRover == nil) then 
			SendVarToRover = function (a,b)
			end
			
			rover = function (a,b)
			end
		else
			rover = SendVarToRover
		end
		--
		
		rover("position", GameLib.GetPlayerUnit():GetPosition())
		rover("zoneId", GameLib.GetCurrentZoneId())
	end
	
	rover("teleporter", self.nearby_teleporters)
	
end

-- :GetId() on a unit returns another int after each patch. So I created this to get a never changing ID by coords (Note: this is threatened by colosions!)
function WorldBossNotifier:HelperGetCalcedCoordId(unit)
	local ct = unit:GetPosition()
	-- local zId = GameLib.GetCurrentZoneId()
	
	local calcedId = nil
	
	if ct ~= nil then
		calcedId = self:round(ct["x"],0) + self:round(ct["y"],0) + self:round(ct["z"],0) -- +zId
	end
	
	return calcedId
end

function WorldBossNotifier:TellVersion()
	local json_data = { 
		type = msg_types["version"],
		vId = version[1],
		vStr = version[2],
		msgsrc = "wbn"
	}
	
	local encoded_json_data = JSON.encode(json_data)

	self.commchan:SendMessage(encoded_json_data)
end

function WorldBossNotifier:ShowHelpBtn( wndHandler, wndControl, eMouseButton )
	self.wndHelp:Show(true)
	self.wndHelp:ToFront()
	
	local cont = self.wndHelp:FindChild("HelpContent"):SetAML(
--[[	"<T Font=\"CRB_HeaderGigantic\">Changelog</T> \n\n"..
	"Add, editoring and delete funktions:\n\n"..
	"-<T TextColor=\"red\">Delete maaaany commands an ghoststrings in the Luacode.</T> \n\n"..
	"+<T TextColor=\"green\"> Prepare for additing new bosses and Dominionteleportation.</T>\n\n"..
	"-<T TextColor=\"yellow\">Editing the Mainwindow description. Here is now the patchnote for everyone</T>.\n\n"..
	"/<T TextColor=\"green\">Change the syncsystem and the Update system.</T> \n\n"
--]]	
	
	"<T Font=\"CRB_HeaderGigantic\">The Mainwindow</T> \n"..
	"The mainwindow consists of two containers:\n"..
	"The first one contains the <T TextColor=\"red\">bosses you got a notification about.</T> \n"..
	"The second one contains the <T TextColor=\"red\">names of people who wrote something containing 'join'</T> in the Nexus chat.\n\n"..
	"Both containers are filled with buttons that can be clicked.\n\n"..
	"Clicking the left part of a button within the left list will result in a <T TextColor=\"red\">'Way To Guide' window opening up</T> while clicking "..
	"a button within the right list results in your game trying to <T TextColor=\"red\">join the players raidgroup.</T> \n\n"..
	"Further more there are two button placed on top of the Boss button (in the left list) called [A] and [A+].\n"..
	"The <T TextColor=\"red\">[A] button</T> makes you post a information about the boss you clicked within the Nexus chat channel. This post contains the "..
	"name of the Boss, where it is located and whats it's current status is (the amount of particles).\n"..
	"The <T TextColor=\"red\">[A+] button</T> also creates a automatic post in the Nexus chat channel but adds some more text to the post: It demands other player to join you and "..
	"also adds the free spots you got left in your raid group.\n\n"..
	"Button status <T TextColor=\"red\">'out of sync':</T> \n"..
	"The information shown in the left list is build by notifications you are sent by other players. You guess it: In order to get those information (and also "..
	"keep them up to date it requires someone to be in place. And thats nearly it. As soon as no one is left in place to send you updates on the boss status, it becomes "..
	"<T TextColor=\"red\">out of sync</T> which is also indicated by grey text and a red megaphone on the right.\n"..
	"All information that you still see can therefor only be calculated (in best case).\n"..
	"As soon as somebody is in place again (at the worldboss spot) the event becomes white and 'normal' again and you can see its current and correct status.\n\n"..
	
	"<T Font=\"CRB_HeaderGigantic\">The Notification Button</T> \n".. -- headline
	"This little moveable overlay to the very left of your screen shows the <T TextColor=\"red\">number of bosses you got notifications about</T> (as long as there are more then one events up to date).\n"..
	"As soon as the threshold (that can be setup within the options) is reached, it will show a <T TextColor=\"red\">little blinky exclamation mark</T> beneath the golden frame <T TextColor=\"red\">to drag your attention</T>. \n"..
	"<T TextColor=\"red\">Clicking the number results in the Mainwindow showing up</T>. \n\n" ..
	
	"<T Font=\"CRB_HeaderGigantic\">Known Issues</T> \n".. -- headline
	"=> The Boss info Buttons <T TextColor=\"red\">keeps jumping between differnt statuses steadily</T>. \n\n"..
	"Reason: This is because Bosses spawn in different phases. When there are many players online Bosses are created in different instances. If the status of boss keeps changeing again and again there are different players in different phases."

	)
end


function WorldBossNotifier:OnCSI(soh)
	if self.storedVars["settings"]["play_sound_on_summon"] then
		if soh then -- show=true or hide=false
			local csi = CSIsLib.GetActiveCSI()
			if csi then
				if self.lang == "de" then
					if string.find(csi["strContext"], "Zu deinem Gruppenmitglied teleportieren?") then
						Sound.PlayFile("summon.wav")
					end
				elseif self.lang == "en" then
					if string.find(csi["strContext"], "Teleport to your group member?") then
						Sound.PlayFile("summon.wav")
					end			
				elseif self.lang == "fr" then
					Print("WORLDBOSSNOTIFIER: Please tell the addon author this exactly sentence: " .. string.lower(csi["strContext"]))
				end
			end
		end
	end
end

function WorldBossNotifier:CloseHelpFormBtn( wndHandler, wndControl, eMouseButton )
	self.wndHelp:Show(false)
end

function WorldBossNotifier:CloseChangeFormBtn( wndHandler, wndControl, eMouseButton )
	self.wndChange:Show(false)
end

function WorldBossNotifier:OnMainWindowMove()
	self:HelperConcatWindows(self.wndMain, self.wndTools)
end

function WorldBossNotifier:HelperConcatWindows(leftWindow, rightWindow)
	-- adjust window
	local lwLeft, lwTop, lwRight, lwBottom
	lwLeft, lwTop, lwRight, lwBottom = leftWindow:GetAnchorOffsets()
	
	local rwLeft, rwTop, rwRight, rwBottom
	rwLeft, rwTop, rwRight, rwBottom = rightWindow:GetAnchorOffsets()
	
	rightWindow:SetAnchorOffsets(lwLeft, lwTop-70, lwRight, lwTop-2)
end

function WorldBossNotifier:UtilsBtnClick( wndHandler, wndControl, eMouseButton )
	self.wndTools:Show(not self.wndTools:IsShown())
	self:HelperConcatWindows(self.wndMain, self.wndTools)
end

function WorldBossNotifier:ClearPlayerListBtn( wndHandler, wndControl, eMouseButton )
	self.wndMain:FindChild("JoinWatch"):DestroyChildren()
end

local auto_join_next_player = nil
local remapped_players = nil
function WorldBossNotifier:ToolJoinSmbsRaidBtn( wndHandler, wndControl, eMouseButton )
	

	
	if self.autojointimer then -- stop the join / invite attempts when the button is clicked again
		self.autojointimer:Stop()
	end
	
	remapped_players = {}
	for playerName, nul in pairs(self.nearby_players) do
		table.insert(remapped_players, playerName)
	end
	
	auto_join_next_player = 1
	self.autojointimer = ApolloTimer.Create(4, true, "TryJoin", self)
end
function WorldBossNotifier:TryJoin()
	local cmd = ""
	local cmd_inv = ""
	if self.lang == "de" then
		cmd = "/beitreten "
		cmd_inv = "/einladen "
	elseif self.lang == "en" then
		cmd = "/join "
		cmd_inv = "/invite "
	elseif self.lang == "fr" then
		cmd = "/rejoindre "
		cmd_inv = "/inviter "
	end
	
	local playerName = remapped_players[auto_join_next_player]
	auto_join_next_player = auto_join_next_player + 1
	
	if playerName == nil then
		self.autojointimer:Stop()
	elseif GroupLib.InGroup() or GroupLib.InRaid() then
		ChatSystemLib.Command(cmd_inv .. playerName)
	else
		ChatSystemLib.Command(cmd .. playerName)
	end
end

function WorldBossNotifier:OnUnitCreated(unit)
	if unit:IsACharacter() and not unit:IsRival() then
		self.nearby_players[unit:GetName()] = 1
	elseif unit:IsVisibleInstancePortal() or string.find(unit:GetName(),"porte") or string.find(unit:GetName(),"Taxi") then
		local calcedId = self:HelperGetCalcedCoordId(unit)
		self.nearby_teleporters[calcedId] = unit
		--table.insert(self.nearby_teleporters, unit)

		if calcedId == -463 or calcedId == -458 or calcedId == -452 then
			Apollo.LoadSprites("sprites.xml")
			local bossSprite = Apollo.LoadForm(self.xmlDoc, "TeleporterSprite", nil, self)
			if calcedId == -463 then
				bossSprite:SetSprite("sprite:mm")
				bossSprite:SetText("Metal Maw")
			elseif calcedId == -458 then
				bossSprite:SetSprite("sprite:ds")
				bossSprite:SetText("Dreamspore")
			else
				bossSprite:SetSprite("sprite:khg")
				bossSprite:SetText("King Honeygrave")
			end

			bossSprite:SetUnit(unit)
		end
	end
end

function WorldBossNotifier:OnUnitDestroyed(unit)
	self.nearby_players[unit:GetName()] = nil
	self.nearby_teleporters[self:HelperGetCalcedCoordId(unit)] = nil
end

function WorldBossNotifier:DonateBtnClicked( wndHandler, wndControl, eMouseButton )
	if GameLib.GetRealmName() == "Jabbit" then
		self.wndDonation = Apollo.LoadForm(self.xmlDoc, "DonationForm", nil, self)
		self.wndDonation:FindChild("UserMsg"):SetText("Great addon!\nHere, take my grateful\ndonation and keep\nup the work! :)\n\n* Please list me on your\ndonators list on curse: <YES/NO>")
	else
		self.wndDonation = Apollo.LoadForm(self.xmlDoc, "NoDonationPossibleForm", nil, self)
	end
end

function WorldBossNotifier:DonateAmountChanged( wndHandler, wndControl )

	if self.wndDonation:FindChild("Currency"):GetAmount() >= 10000 then
		self.wndDonation:FindChild("DonateBtn"):Enable(true)
	else
		self.wndDonation:FindChild("DonateBtn"):Enable(false)
	end

	local faction = GameLib.GetPlayerUnit():GetFaction()

	self.wndDonation:FindChild("DonateBtn"):SetActionData(
		GameLib.CodeEnumConfirmButtonType.SendMail, 
		(faction == 167 and "Nikolai Kondich" or "Thea Gewittersturm"), 
		"Jabbit", -- GameLib.GetRealmName()
		"Donation for WorldBossNotifier",
		self.wndDonation:FindChild("UserMsg"):GetText(),
		nil,
		MailSystemLib.MailDeliverySpeed_Instant,
		0, 
		self.wndDonation:FindChild("Currency"):GetCurrency()
	)
end

function WorldBossNotifier:IAmOnline()
	local json_data = { 
		type = msg_types["person"],
		msgsrc = "wbn"
	}
		
	local encoded_json_data = JSON.encode(json_data)
	
	self.commchan:SendMessage(encoded_json_data)
end

function WorldBossNotifier:OnCmdWbnPlayers()
	local pl = Apollo.LoadForm(self.xmlDoc, "PlayerList", nil, self)
			
	local amount = 0
	for pl_name, time in pairs(self.player_list) do 
		if time + 9*60 < os.time() then
			local entry = Apollo.LoadForm(self.xmlDoc, "PlayerEntry", pl:FindChild("PLlist"), self)
			entry:SetText(pl_name .. "last: " .. os.date("%H:%M", time))
			amount = amount + 1
		else
			-- self.player_list[pl_name] = nil -- delete entry if too old
		end
	end
	pl:FindChild("PLlist"):ArrangeChildrenVert()
	pl:FindChild("Amount"):SetText(amount)
end

function WorldBossNotifier:OnDonationSent( wndHandler, wndControl )
	self.wndDonation:FindChild("DonateBtn"):Show(false)
	self.wndDonation:FindChild("ThanksLabel"):Show(true)
end

-- TODO remove
function WorldBossNotifier:DebugSetAddonFakeVersion( wndHandler, wndControl, eMouseButton )
	--version[1] = 0
	--version[2] = "0.3.1"
end

-----------------------------------------------------------------------------------------------
-- WorldBossNotifier Instance
-----------------------------------------------------------------------------------------------
local WorldBossNotifierInst = WorldBossNotifier:new()
WorldBossNotifierInst:Init()