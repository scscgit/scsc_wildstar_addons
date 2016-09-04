-----------------------------------------------------------------------------------------------
-- Client Lua Script for DeathRecap
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- DeathRecap Module Definition
-----------------------------------------------------------------------------------------------
local DeathRecap = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local tClass = 	{ 
	[GameLib.CodeEnumClass.Warrior]      = { strName = Apollo.GetString("ClassWarrior"), 	    strLogo = "CRB_Raid:sprRaid_Icon_Class_Warrior" },		
	[GameLib.CodeEnumClass.Engineer]     = { strName = Apollo.GetString("ClassEngineer"), 	 	strLogo = "CRB_Raid:sprRaid_Icon_Class_Engineer" },		
	[GameLib.CodeEnumClass.Esper]        = { strName = Apollo.GetString("ClassESPER"), 		 	strLogo = "CRB_Raid:sprRaid_Icon_Class_Esper" },		
	[GameLib.CodeEnumClass.Medic]        = { strName = Apollo.GetString("ClassMedic"), 		 	strLogo = "CRB_Raid:sprRaid_Icon_Class_Medic" },		
	[GameLib.CodeEnumClass.Stalker]      = { strName = Apollo.GetString("ClassStalker"), 	    strLogo = "CRB_Raid:sprRaid_Icon_Class_Stalker" },		
	[GameLib.CodeEnumClass.Spellslinger] = { strName = Apollo.GetString("ClassSpellslinger"),  	strLogo = "CRB_Raid:sprRaid_Icon_Class_Spellslinger" },	
}

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function DeathRecap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	-- GameLib.GetSpell(id)
	self.lstDamage = {}
	self.lstDamageCount = {}
	self.lstUNIT = {}
	self.lstSpellIcon = {}
	self.lstName = {}
	self.lstClass = {}
	self.lstLevel = {}
	self.closeTimer = 0
	self.combatTime = 0
	self.duelState = GameLib.CodeEnumDuelState.None
	
    return o
end

function DeathRecap:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

	Apollo.RegisterEventHandler("CombatLogDamage", "OnDamage", self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnCombatStart", self)
	Apollo.RegisterEventHandler("ShowResurrectDialog", 		"OnDeath", self)
end

function DeathRecap:OpenDR()
	self:Calculate()
	self.wndMain:Show(true, true)
	self.closeTimer = 4
	self.wndMain:FindChild("closeTimer"):Show(true, true)
	self.wndMain:FindChild("Title"):SetText("                                           Death Recap")
end

function DeathRecap:OnDeath(bPlayerIsDead, bEnableRezHere, bEnableRezHoloCrypt, bEnableRezExitInstance, bEnableCasterRez, bHasCasterRezRequest, nRezCost, fTimeBeforeRezable, fTimeBeforeWakeHere, fTimeBeforeForceRez)
	if bPlayerIsDead then
		local playerCount = 0
		for Index, Value in pairs(self.lstDamage) do
		  playerCount = playerCount + 1
		end
		if playerCount > 0 then
			self:OpenDR()
		end
	end
end

function DeathRecap:OnCombatStart(unitChecked, bInCombat)
	if unitChecked == GameLib.GetPlayerUnit() then
		if bInCombat then
			self.lstDamage = {}
			self.lstUNIT = {}
			self.lstSpellIcon = {}
			self.lstName = {}
			self.lstClass = {}
			self.lstLevel = {}
			self.combatTime = GameLib.GetGameTime()
		end
	end
end

function DeathRecap:GetSpellIDByName(spellName)
	for aid, ability in pairs(AbilityBook.GetAbilitiesList()) do
		if ability.strName == spellName then
			return ability.tTiers[1].splObject:GetId()
		end
	end
end

function DeathRecap:OnDamage(tEventArgs) 
	local casterUnit = tEventArgs.unitCaster
	local targetUnit = tEventArgs.unitTarget
	local spellUnit = tEventArgs.splCallingSpell
	local damageAmount = tEventArgs.nDamageAmount + tEventArgs.nShield + tEventArgs.nAbsorption
	if casterUnit ~= nil then
		-- Si il s'agit d'un joueur
		if casterUnit:GetType() == "Player" then
			
			-- Si il s'agit de soit-meme qui a pris les dommages
			if GameLib.GetPlayerUnit() == targetUnit then
				
					local casterId = casterUnit:GetId()
					local spellName = spellUnit:GetName()
					
					if spellUnit:GetIcon() ~= nil then
						self.lstSpellIcon[spellName] = spellUnit:GetIcon()
					end
					
					if self.lstDamage[casterId] == nil then
						self.lstDamage[casterId] = {}
						self.lstDamageCount[casterId] = {}
					end
					
					if self.lstDamage[casterId][spellName] == nil then
						self.lstDamage[casterId][spellName] = 0
						self.lstDamageCount[casterId][spellName] = 0
					end
		
					self.lstDamage[casterId][spellName] = self.lstDamage[casterId][spellName] + damageAmount
					self.lstDamageCount[casterId][spellName] = self.lstDamageCount[casterId][spellName] + 1
					self.lstUNIT[casterId] = casterUnit		
					self.lstName[casterId] = casterUnit:GetName()
					self.lstClass[casterId] = casterUnit:GetClassId()
					self.lstLevel[casterId] = casterUnit:GetLevel()
				
			end
			
		end
	end
end

function DeathRecap:round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function DeathRecap:Calculate()
	self.wndMain:FindChild("playerFrames"):DestroyChildren()

	local totalDamage = 0
	local playerCount = 0
	-- Calcul des dommages total de tout les joueurs
	for playerName, lstSpell in pairs(self.lstDamage) do
		playerCount = playerCount + 1
		for sortID, sortDamage in pairs(self.lstDamage[playerName]) do
			local damageAmount = self.lstDamage[playerName][sortID]
			totalDamage = totalDamage + damageAmount
		end
	end
	
	-- Chaque joueur
	for playerId, lstSpell in pairs(self.lstDamage) do

		local playerUnit = GameLib.GetUnitById(playerId)--self.lstUNIT[playerId]
		local playerName = self.lstName[playerId]
		local playerClass = self.lstClass[playerId]
		local playerLevel = self.lstLevel[playerId]
		local playerDamage = 0

		-- Calcul du total de dommage du joueur
		for spellNameb, sortDamageb in pairs(self.lstDamage[playerId]) do
			playerDamage = playerDamage + sortDamageb
		end
		
		-- Calcul du pourcentage de dommage du joueur
		local playerPourcentageDamage = self:round(100/(totalDamage/playerDamage))

		-- Création de la box du joueur
		local wndPlayerFrame = Apollo.LoadForm(self.xmlDoc, "playerFrame", self.wndMain:FindChild("playerFrames"), self)
		wndPlayerFrame:SetData(playerPourcentageDamage)
		wndPlayerFrame:FindChild("playerName"):SetText(playerName)
		wndPlayerFrame:FindChild("playerDamage"):SetText(playerDamage.." dmg")
		wndPlayerFrame:FindChild("playerPourcentageDamage"):SetText(playerPourcentageDamage.."%")
		wndPlayerFrame:FindChild("playerClassLevel"):SetText(tClass[playerClass].strName.." - "..playerLevel) 
		wndPlayerFrame:FindChild("playerFace"):SetCostume(playerUnit)
		wndPlayerFrame:FindChild("playerClassIcon"):SetSprite(tClass[playerClass].strLogo)

		for spellName, spellDamage in pairs(self.lstDamage[playerId]) do
			local spellIcon = self.lstSpellIcon[spellName]
			local spellPourcentageDamage = self:round(100/(playerDamage/spellDamage))
			local spellCount = self.lstDamageCount[playerId][spellName]		
			
			-- Ajout d'un sort a la liste du joueur
			local wndPlayerSpell = Apollo.LoadForm(self.xmlDoc, "spellFrame", wndPlayerFrame:FindChild("playerSpell"), self)
			wndPlayerSpell:FindChild("spellName"):SetText(spellName)
			wndPlayerSpell:FindChild("spellDamage"):SetText(spellDamage.." dmg ("..spellPourcentageDamage.."%)")
			wndPlayerSpell:FindChild("spellCount"):SetText(spellCount)
			wndPlayerSpell:SetData(spellPourcentageDamage)
			
			if spellIcon == nil or spellIcon == "" then
				wndPlayerSpell:FindChild("spellIcon"):SetSprite("IconSprites:Icon_ItemWeapon_Unidentified_Weapon_0007")
			else 
				wndPlayerSpell:FindChild("spellIcon"):SetSprite(spellIcon)
			end
			
		end
		
		wndPlayerFrame:FindChild("playerSpell"):ArrangeChildrenVert(0, function(a,b) return a:GetData() > b:GetData() end)
	end
	
	self.wndMain:FindChild("playerFrames"):ArrangeChildrenHorz(0, function(a,b) return a:GetData() > b:GetData() end)	
	
	local timeElapsed = self:round(GameLib.GetGameTime() - self.combatTime)
	self.wndMain:FindChild("DeathResume"):SetText(totalDamage.." damages taken in "..timeElapsed.." seconds, by "..playerCount.." players")
end

-----------------------------------------------------------------------------------------------
-- DeathRecap OnLoad
-----------------------------------------------------------------------------------------------
function DeathRecap:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("DeathRecap.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- DeathRecap OnDocLoaded
-----------------------------------------------------------------------------------------------
function DeathRecap:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "DeathRecapForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)
	
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("test", "Calculate", self)
		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- DeathRecap Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on timer
function DeathRecap:OnTimer()
	if self.closeTimer > 0 then
		self.closeTimer = self.closeTimer - 1
		
		self.wndMain:FindChild("closeTimer"):SetText("Auto close in "..self.closeTimer.." seconds (Click to stop)")
		
		if self.closeTimer == 0 then
			self:CloseDR()
		end
	end
	
	local eNewState = GameLib.GetDuelState()
	
	-- Detection end of duel
	if self.duelState == GameLib.CodeEnumDuelState.Dueling and eNewState == GameLib.CodeEnumDuelState.None then
		self:OpenDR()
	end

		-- New state or not
	self.duelState = eNewState

end

---------------------------------------------------------------------------------------------------
-- DeathRecapForm Functions
---------------------------------------------------------------------------------------------------

function DeathRecap:CloseDR( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(false, true)
end

function DeathRecap:StopTimer( wndHandler, wndControl, eMouseButton )
	self.closeTimer = 0
	self.wndMain:FindChild("closeTimer"):Show(false, true)
	self.wndMain:FindChild("Title"):SetText("Death Recap")
end

-----------------------------------------------------------------------------------------------
-- DeathRecap Instance
-----------------------------------------------------------------------------------------------
local DeathRecapInst = DeathRecap:new()
DeathRecapInst:Init()
