-----------------------------------------------------------------------------------------------
-- Client Lua Script for FailCheck (by Tavi)
----------------------------------------------------------------------------------------------- 

require "Window"
local FailCheck = {} 

function FailCheck:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end


function FailCheck:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

function FailCheck:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("FailCheck.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end


function FailCheck:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "FailCheckForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Error loading window.")
			return
		end
		
		if self.Options == nil then
			self.Options = {
				["ReportFails"]=true,
				["ReportDeaths"]=false,
				["ReportDebug"]=false,
			}
		end	
		
		self.buttons = self.wndMain:FindChild("Buttons")
		
		for option, value in pairs(self.Options) do
			self.buttons:FindChild(option):SetCheck(value)
		end		
		
		self.wndMain:Show(false, true)

		Apollo.RegisterSlashCommand("FailCheck", "OnFailCheckOn", self)
		Apollo.RegisterSlashCommand("failcheck", "OnFailCheckOn", self)
		Apollo.RegisterSlashCommand("fail", "OnFailCheckOn", self)
		Apollo.RegisterSlashCommand("Failcheck", "OnFailCheckOn", self)
		Apollo.RegisterSlashCommand("Fail", "OnFailCheckOn", self)
		Apollo.RegisterSlashCommand("fc", "OnFailCheckOn", self)

		Apollo.RegisterEventHandler("CombatLogDamage", "OnCombatLogDamage", self)
		Apollo.RegisterEventHandler("CombatLogFallingDamage", "OnCombatLogFallingDamage", self)
		Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombat", self)

		self.ListArea = self.wndMain:FindChild("ListArea")
		self.grid = self.ListArea:FindChild("wndGrid")

--List of challenge fails ["Ability"]="Caster"
		self.tChallengeFails = {
			["Seismic Tremor"]="Thunderfoot",
			["Dark Fireball"]="Laveka the Dark-Hearted",
			["Twister"]="Aethros Twister",
			["Lightning Strike"]="Stormtalon",
			["Plague Splatter"]="Ondu - Plague Splatter",
			["Molten Wave"]="Rayna Darkspeaker",
			["Bone Clamp"]="Bone Cage",
			["Seared Eyes"]="Terraformer",
			["Homing Barrage"]="Slavemaster Drokk",
			["Phase Blast"]="Eldan Phase Blaster",
		}	

		self:Reset()
	end
end


function FailCheck:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	local tData = TableUtil:Copy(self.Options)	
	return tData
end


function FailCheck:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	if tData then
		self.Options = tData
	end
end


-----------------------------------------------------------------------------------------------
-- FailCheck Functions
-----------------------------------------------------------------------------------------------

function FailCheck:OnFailCheckOn()
	self:UpdateGrid()
	self.wndMain:Invoke()

end


function FailCheck:OnCombatLogDamage(tEventArgs)
	local validTarget = tEventArgs.unitTarget ~= nil
	local validCaster = tEventArgs.unitCaster ~= nil
	local validSpell = tEventArgs.splCallingSpell:GetName() ~= nil
	if validTarget and validCaster and validSpell then
		if tEventArgs.unitTarget:IsInYourGroup() then
			self.ChallengeFailed = false
			for ListedSpell, ListedCaster in pairs(self.tChallengeFails) do
				local getSpell = tEventArgs.splCallingSpell:GetName()
				local getCaster = tEventArgs.unitCaster:GetName()
				if getSpell == ListedSpell then 
					if getCaster == ListedCaster then
						self.ChallengeFailed = true
					end
				end
			end
			if tEventArgs.bTargetKilled or self.ChallengeFailed then
				local tVars = self.tVars
				tVars = { 	--Make this a for loop
					tEventArgs.unitTarget:GetName(),		--1
					tEventArgs.unitCaster:GetName(),		--2
					tEventArgs.splCallingSpell:GetName(),	--3
					tEventArgs.nDamageAmount,				--4
					tEventArgs.nAbsorption,					--5
					tEventArgs.nShield,						--6
					tEventArgs.nOverkill,					--7
				}
				local n = table.getn(tVars)
				for i = 1, n do	
					local value = tVars[i]
					table.insert(self.DeathList[i], 1, value)
				end
				if tEventArgs.bTargetKilled then
					if self.Options["ReportDeaths"] == true then
						self:FormatReport(1)
					end
				end
				if self.ChallengeFailed then
					if self.Options["ReportFails"] == true then
						self.FoundInList = 0
						local playerName = tVars[1]
						local n = table.getn(self.tDeadThisFight)
						for i = 1, n do
							local isDead = self.tDeadThisFight[i]			
							if playerName == isDead then
								self.FoundInList = 1
							end
						end
						if self.FoundInList == 0 then
							table.insert(self.tDeadThisFight, playerName)
							self:FormatReport(1)
						end
					end
				end
				self:UpdateGrid()
			end
		end
	end
end


function FailCheck:Reset()
	Targets			= { }
	Casters			= { }
	Spells			= { }
	Damages			= { }
	Aborbs			= { }
	Shields			= { }
	Overkills		= { }
	self.DeathList	= {
		Targets,
		Casters,
		Spells,
		Damages,
		Aborbs,
		Shields,
		Overkills,
	}
	self.tDeadThisFight = { }
	local n = table.getn(self.DeathList)
	for i = 1, n do
		self.DeathList[i][0] = tostring(self.DeathList[i])
	end
	self:UpdateGrid()
end


function FailCheck:UpdateGrid()
	local h = table.getn(Targets)
	local w = table.getn(self.DeathList)
	self:ClearGrid()
	for i = 1, h do
		self.grid:AddRow("")
	end
	for y = 1, h do
		for x = 1, w do
			self.grid:SetCellText(y, x, self.DeathList[x][y])
		end
	end
end 


function FailCheck:ClearGrid()
	local h = self.grid:GetRowCount()
	if h then
		for i = 1, h do
			self.grid:DeleteRow(1)
		end
	end
end


function FailCheck:OnCombat()
	self.tDeadThisFight = { }
end


function FailCheck:OnGridSelection(wndControl, wndHandler, iRow, iCol, eMouseButton)
	self:FormatReport(iRow)
end


function FailCheck:FormatReport(fnRow)
	if self.DeathList[7][fnRow] == 0 then	-- Zero Overkill means challenge was failed
		local sToChat = string.format("[Challenge]: %s was hit by %s.",
			self.DeathList[1][fnRow],
			self.DeathList[3][fnRow]
		)
		self:SendToChat(sToChat)
	elseif self.DeathList[7][fnRow] ~= 0 then	-- Non-zero overkill means they died
		local nDamageTotal = self.DeathList[7][fnRow] + self.DeathList[6][fnRow] + self.DeathList[5][fnRow] + self.DeathList[4][fnRow]
		local sToChat = string.format("[Death]: %s was killed by %s with %s for %s (%s Overkill)", 
			self.DeathList[1][fnRow],
			self.DeathList[2][fnRow],
			self.DeathList[3][fnRow],
			nDamageTotal,
			self.DeathList[7][fnRow]
		)
		self:SendToChat(sToChat)
	end
end


function FailCheck:SendToChat(fnString)
	if self.Options["ReportDebug"] == true then
		Print(fnString)
	elseif GroupLib.InInstance() then
		ChatSystemLib.Command("/i "..fnString)
	elseif GroupLib.InGroup() or GroupLib.InRaid() then
		ChatSystemLib.Command("/p "..fnString)
	else
		Print(fnString)
	end
end


function FailCheck:OnCancel()
	self.wndMain:Close()
end


function FailCheck:OnCheckBox( wndHandler, wndControl, eMouseButton )
	local ckbox = wndHandler:GetName()
	self.Options[ckbox] = wndHandler:IsChecked()	
end


local FailCheckInst = FailCheck:new()
FailCheckInst:Init()
