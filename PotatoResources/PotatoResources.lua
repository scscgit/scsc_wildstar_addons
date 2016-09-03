-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoResources
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
require "GameLib"
require "Unit"
require "Spell"
 
-----------------------------------------------------------------------------------------------
-- PotatoResources Module Definition
-----------------------------------------------------------------------------------------------
local PotatoResources = {} 

local DrawClass = {
	[GameLib.CodeEnumClass.Medic] = function(self, arg) self:DrawMedic(arg) end,
	[GameLib.CodeEnumClass.Spellslinger] = function(self, arg) self:DrawSpellslinger2(arg) end,
	[GameLib.CodeEnumClass.Esper] = function(self, arg) self:DrawEsper(arg) end,
	[GameLib.CodeEnumClass.Engineer] = function(self, arg) self:DrawEngineer(arg) end,
	[GameLib.CodeEnumClass.Warrior] = function(self, arg) self:DrawWarrior(arg) end,
	[GameLib.CodeEnumClass.Stalker] = function(self, arg) self:DrawStalker(arg) end
}

local showFrame = 1
local showEngiFrame = 1
local bEditorMode = false

local ktDefaultResourceData = {
	type = 1
}
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PotatoResources:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoResources:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = { "PotatoLib", "Util" }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function PotatoResources:OnLoad()
	-- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
	Apollo.RegisterEventHandler("CharacterCreated", 	"OnCharacterCreated", self)
	Apollo.RegisterEventHandler("VarChange_FrameCount",	"OnFrame", self)
	
	Apollo.RegisterEventHandler("PotatoEditor", 		"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset", 			"ResetFrames", self)
	
	--load our forms
    self.wndMain = Apollo.LoadForm("PotatoResources.xml", "ContainerNew1", "FixedHudStratum", self)
	self.wndMain:SetAnchorPoints(0.5, 1, 0.5, 1)
	self.wndMain:SetAnchorOffsets(-370,-232,-10,-202)
    self.wndMain:Show(true)

	self.wndContent = self.wndMain:FindChild("Bars")
	
	self.wndEngineer = Apollo.LoadForm("PotatoResources.xml", "EngineerButtons", nil, self)
	
	if GameLib.GetPlayerUnit() then
		self:OnCharacterCreated()
	end
	
	self.resourceData = {}
	self.tBarTypeBtns = {}
	self.tAccountData = {}
	
	self.bCRBEnable = false
	self.bPUIEnable = true

	self.resourceData = TableUtil:Copy(ktDefaultResourceData)
end

--P: happens once, when character is made
function PotatoResources:OnCharacterCreated()

	--P: checks if unit is player
	local unitPlayer = GameLib.GetPlayerUnit()
	self.playerClassId = unitPlayer:GetClassId()
	local playerClass = PotatoLib.ktClassNames[self.playerClassId]

	if unitPlayer:GetClassId() == GameLib.CodeEnumClass.Spellslinger or unitPlayer:GetClassId() == GameLib.CodeEnumClass.Esper then
		Apollo.LoadForm("PotatoResources.xml", playerClass .. "2", self.wndMain:FindChild("Bars"), self)
		if not unitPlayer then
			return
		else
			self.wndMain:FindChild(playerClass .. "2"):Show(true)
		end

	else
		Apollo.LoadForm("PotatoResources.xml", playerClass, self.wndMain:FindChild("Bars"), self)
	
		if not unitPlayer then
			return
		else
			self.wndMain:FindChild(playerClass):Show(true)
		end
	end	
	
	local strResource = string.format("<T Font=\"CRB_InterfaceSmall\">%s</T>", Apollo.GetString("CRB_" .. playerClass .. "Resource"))
	self.wndMain:FindChild("Bars"):SetTooltip(strResource)
	
	if playerClass == "Warrior" then
		Apollo.RegisterTimerHandler("WarriorResource_StartOverDriveTimer", 	"OnWarriorResource_StartOverDriveTimer", self)
		Apollo.CreateTimer("WarriorResource_StartOverDriveTimer", 0.01, false)
	
		PotatoLib:SetBarVars("OverdriveBar", self.wndMain, 0, 1, self)
		self.wndMain:FindChild("OverdriveBar"):SetProgress(0)
	end
	
	if playerClass == "Medic" then
		self.tCores = {} -- windows
	
		for idx = 1,4 do
			self.tCores[idx] = 
			{
				--Gives each of the 4 CoreContainer windows an instance of MedicCore window stored in self.tCores[idx].wndCore
				wndCore = Apollo.LoadForm("PotatoResources.xml", "MedicCore",  self.wndMain:FindChild("CoreContainer" .. idx), self),
			}
			self.tCores[idx].wndCore:FindChild("PowerSurge"):SetMax(3)
			self.tCores[idx].wndCore:FindChild("PowerSurge"):SetProgress(0)
		end
	end
	
	if playerClass == "Engineer" then
		if not self.tSavedData then
			self.wndMain:SetAnchorPoints(0.5, 1, 0.5, 1)
			self.wndMain:SetAnchorOffsets(-370,-232,-130,-202)
	
			self.wndEngineer:Show(true)
		end
	else
		self.wndEngineer:Destroy()
		self.wndEngineer = nil
	end		
end
	
function PotatoResources:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer or unitPlayer == nil then return end
	if self.strCharacterName == nil then self.strCharacterName = GameLib.GetPlayerUnit():GetName() end
		
	if self.bPUIEnable then
		if showFrame == 1 or (showFrame == 2 and PotatoLib.bInCombat) or bEditorMode then
			self.wndMain:Show(true)
		else
			self.wndMain:Show(false)
		end
		DrawClass[unitPlayer:GetClassId()](self, unitPlayer)	
	else
		if self.wndMain:IsVisible() then
			self.wndMain:Show(false)
		end
	end
	
	if self.bCRBEnable then
		if Apollo.GetConsoleVariable("hud.resourceBarDisplay") ~= 1 then
			Apollo.SetConsoleVariable("hud.resourceBarDisplay", 1)
			Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
		end
	else
		if Apollo.GetConsoleVariable("hud.resourceBarDisplay") ~= 2 then
			Apollo.SetConsoleVariable("hud.resourceBarDisplay", 2)
			Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
		end
	end
end

function PotatoResources:EditorModeToggle(bState)
	bEditorMode = bState
	
	if bEditorMode then
		self.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", self.wndMain, self)
		self.wndCover:FindChild("Reset"):Show(false)
		self.wndCover:SetText("Resource Frame")
		--[[if self.border.show then
			self.wndCover:SetAnchorOffsets(self.border.size, self.border.size, -self.border.size, -self.border.size)
		else]]--
			self.wndCover:SetAnchorOffsets(2,2,-2,-2)--self.wndCover:SetAnchorOffsets(0,0,0,0)
		--end
		self.wndMain:Show(true)
	else
		if self.wndCover then
			self.wndCover:Destroy()
			self.wndCover = nil
		end
		if self.wndEditor then
			self.wndEditor:Destroy()
			self.wndEditor = nil
		end
	end
	self.wndMain:SetStyle("Moveable", bEditorMode)
	self.wndMain:SetStyle("Sizable", bEditorMode)

	if self.wndEngineer then
		if bEditorMode then
			self.wndEngiCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", self.wndEngineer, self)
			self.wndEngiCover:FindChild("Reset"):Show(false)
			self.wndEngiCover:SetText("Pet Controls Frame")
			--[[if self.border.show then
				self.wndEngiCover:SetAnchorOffsets(self.border.size, self.border.size, -self.border.size, -self.border.size)
			else]]--
				self.wndEngiCover:SetAnchorOffsets(2,2,-2,-2)--self.wndCover:SetAnchorOffsets(0,0,0,0)
			--end
			self.wndEngineer:Show(true)
		else
			if self.wndEngiCover then
				self.wndEngiCover:Destroy()
				self.wndEngiCover = nil
			end
		end
		self.wndEngineer:SetStyle("Moveable", bEditorMode)
		self.wndEngineer:SetStyle("Sizable", bEditorMode)
		self.wndEngineer:FindChild("PetBarIcons"):Show(not bEditorMode)
		self.wndEngineer:FindChild("Stance"):Show(not bEditorMode)
		self.wndEngineer:FindChild("FakePetBarIcons"):Show(bEditorMode)
		self.wndEngineer:FindChild("FakeStance"):Show(bEditorMode)
	end
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------

function PotatoResources:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:PopulateEditor(wndHandler:GetParent():GetParent())
	
	self:SelectFrame(wndHandler:GetParent():GetParent())
end

function PotatoResources:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	PotatoLib:HandleLockedWnd(wndHandler:GetParent():GetParent(), wndHandler:GetParent():GetParent():GetName())
end

function PotatoResources:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	--self:Reset()
end

function PotatoResources:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			self:PopulateEditor(wndHandler:GetParent())
		end
		self:SelectFrame(wndHandler:GetParent())
	end
end

function PotatoResources:SelectFrame(wndHandler)
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		self:PopulateEditor(wndHandler)
	end
end

function PotatoResources:DrawMedic(unitPlayer)
	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)

	local playerBuffs = unitPlayer:GetBuffs()
	local powerCharge = 0
	local beneficialBuffs = playerBuffs["arBeneficial"]
	
	for key, value in pairs(beneficialBuffs) do
		if value.splEffect:GetId() == 42569 then 
			powerCharge = value.nCount
		end
	end

	for idx = 1, #self.tCores do
		local wndCoreBar = self.tCores[idx].wndCore:FindChild("PowerSurge")
				
		if idx <= nResourceCurr then --if the current core is filled
			--mark core as full
			wndCoreBar:SetProgress(3)
		else
			if idx == nResourceCurr + 1 then --if the core is the next (filling) core
				--partial core full via buffcount
				wndCoreBar:SetProgress(powerCharge)
			else
				wndCoreBar:SetProgress(0)
			end
		end
	end
	
	--[[PotatoLib:SetBarVars("MedicFocus", self.wndMain, unitPlayer:GetFocus(), unitPlayer:GetMaxFocus())
	PotatoLib:SetBarAppearance("MedicFocus", self.wndMain, "Smooth", "ffff44ff", 100)
	self.wndMain:FindChild("MedicFocus"):SetText(math.floor(unitPlayer:GetFocus()) .. "/" .. math.floor(unitPlayer:GetMaxFocus()))]]--
end

function PotatoResources:DrawEsper(unitPlayer)
	PotatoLib:SetBarVars("EsperManaBar", self.wndMain, unitPlayer:GetFocus(), unitPlayer:GetMaxFocus())
	PotatoLib:SetBarAppearance("EsperManaBar", self.wndMain, "Charcoal", "ffff44ff", 100)
	local nResourceCurr = unitPlayer:GetResource(1)
	local nResourceMax = unitPlayer:GetMaxResource(1)
	local type = "Disabled"
	for idx = 1, nResourceMax do
		type = idx<=nResourceCurr and "PressedFlyby" or "Disabled"
		self.wndMain:FindChild("EsperContainer"..idx):SetSprite("CRB_UIKitSprites:btn_radioLARGE"..type)
	end
end

function PotatoResources:DrawStalker(unitPlayer)
	PotatoLib:SetBarVars("StalkerResBar", self.wndMain, unitPlayer:GetResource(3), unitPlayer:GetMaxResource(3))
	PotatoLib:SetBarAppearance("StalkerResBar", self.wndMain, "Aluminum", PotatoLib.resourceColors[GameLib.CodeEnumClass.Stalker], 100)
end

function PotatoResources:DrawWarrior(unitPlayer)
	local nCurr, nMax = unitPlayer:GetResource(1), unitPlayer:GetMaxResource(1)
	local strColor = "FF3D0D"
	
	if nCurr < 500 then
		strColor = "FFFFFF"
	elseif nCurr < 750 then
		strColor = "FFC70D"
	end
	
	PotatoLib:SetBarVars("WarriorResBar", self.wndMain, nCurr, nMax)
	PotatoLib:SetBarAppearance("WarriorResBar", self.wndMain, "Aluminum", strColor, 100)
			
	local bOverdrive = GameLib.IsOverdriveActive()
	
	local bLastKnownOverdriveState = self.wndMain:FindChild("OverdriveBar"):GetData()
	if bOverdrive and not bLastKnownOverdriveState then
		self.wndMain:FindChild("OverdriveBar"):SetData(true)
		self.wndMain:FindChild("OverdriveBar"):SetProgress(1)
		self.wndMain:FindChild("OverdriveBar"):Show(true)
		Apollo.StartTimer("WarriorResource_StartOverDriveTimer")
	elseif not bOverdrive and bLastKnownOverdriveState then
		self.wndMain:FindChild("OverdriveBar"):SetData(false)
		self.wndMain:FindChild("OverdriveBar"):Show(false)
	end
end

function PotatoResources:OnWarriorResource_StartOverDriveTimer()
	local bOverdrive = GameLib.IsOverdriveActive()
	if bOverdrive then
	self.wndMain:FindChild("OverdriveBar"):Show(true)
	self.wndMain:FindChild("OverdriveBar"):SetProgress(0, 1 / 8) -- 2nd arg is rate for animation
	end
end

function PotatoResources:DrawSpellslinger(unitPlayer)
	local currSS = unitPlayer:GetResource(4)
	local maxSS = unitPlayer:GetMaxResource(4)
	
	PotatoLib:SetBarVars("Spellsurge", self.wndMain, currSS, maxSS)
	PotatoLib:SetBarAppearance("Spellsurge", self.wndMain, "Bantobar", "ffffcc00", 100)
	self.wndMain:FindChild("SpellsurgeActive"):Show(GameLib.IsSpellSurgeActive())
	
	for idx=1, 3 do
		self.wndMain:FindChild("Breaker" .. idx):SetAnchorPoints(25/maxSS*idx, 0, 25/maxSS*idx, 1)
	end
end

function PotatoResources:DrawSpellslinger2(unitPlayer)
	local currSP  = unitPlayer:GetResource(4) --150
	local maxSP  = unitPlayer:GetMaxResource(4)
		
	local currOFSP = currSP - 25
	local maxOFSP = maxSP - 25
	
	local curr25SP = currSP
	local max25SP = 25	
	
	PotatoLib:SetBarVars("MainSP", self.wndMain, curr25SP, max25SP)
	PotatoLib:SetBarVars("OFSP", self.wndMain, currOFSP, maxOFSP)
	PotatoLib:SetBarAppearance("MainSP", self.wndMain, "Bantobar", "ffff3300", 100)
	PotatoLib:SetBarAppearance("OFSP", self.wndMain, "Bantobar", "ffffcc00", 100)
	self.wndMain:FindChild("SSActive"):Show(GameLib.IsSpellSurgeActive())
	
	--[[for idx=1, 3 do
		self.wndMain:FindChild("Breaker" .. idx):SetAnchorPoints(25/maxSS*idx, 0, 25/maxSS*idx, 1)
	end]]--
end

function PotatoResources:DrawEngineer(unitPlayer)
    local currRP, maxRP = PotatoLib:GetClassResource(unitPlayer)
    PotatoLib:SetBarVars("EngineerResBar", self.wndMain, currRP, maxRP)
    
    local rescolor = PotatoLib.resourceColors[GameLib.CodeEnumClass.Engineer]
    local curra = maxRP/100*30
    local currb = maxRP/100*70
    if currRP >= curra and currRP <= currb then rescolor = "00EE00" end
        
    PotatoLib:SetBarAppearance("EngineerResBar", self.wndMain, "Aluminum", rescolor, 100)

	local ktEngineerStanceToShortString =
	{
		[0] = "",
		[1] = Apollo.GetString("EngineerResource_Aggro"),
		[2] = Apollo.GetString("EngineerResource_Defend"),
		[3] = Apollo.GetString("EngineerResource_Passive"),
		[4] = Apollo.GetString("EngineerResource_Assist"),
		[5] = Apollo.GetString("EngineerResource_Stay"),
	}
	local tPetStances = {}
	local strStance = "None"
	for key, unitPet in pairs(GameLib.GetPlayerPets()) do
		if unitPet:GetUnitRaceId() == 298 then
			tPetStances[key] = Pet_GetStance(unitPet:GetId())
		end	
	end	
	if tPetStances[2] ~= nil and tPetStances[1] ~= tPetStances[2] then
		strStance = "Mixed"
	else
		strStance = ktEngineerStanceToShortString[tPetStances[1] or 0]
		for idx=1, 5 do
			local nCurrPetStance = tPetStances[1]
	
			self.wndEngineer:FindChild("Stance"..idx):FindChild("StanceText"):SetTextColor(idx == nCurrPetStance and "FFFFFF00" or "FFFFFFFF")
			self.wndEngineer:FindChild("Stance"..idx):ChangeArt(idx == nCurrPetStance and "CRB_Basekit:kitBtn_List_HoloSort" or "CRB_Basekit:kitBtn_List_Holo")
		end
	end
	self.wndEngineer:FindChild("Stance"):SetText(strStance)

	if showEngiFrame == 1 or (showEngiFrame == 2 and PotatoLib.bInCombat) or (showEngiFrame == 3 and #GameLib.GetPlayerPets() > 0) or bEditorMode then
		self.wndEngineer:Show(true)
	else
		self.wndEngineer:Show(false)
	end
end

--[[function PotatoResources:EditorModeToggle()
	bEditorMode = not bEditorMode

	self.wndMain:FindChild("Bars"):GetChildren()[1]:SetStyle("IgnoreMouse", bEditorMode)
	self.wndMain:SetStyle("Moveable", bEditorMode)
	self.wndMain:FindChild("EditorCover"):Show(bEditorMode)
	self.wndMain:SetStyle("Sizable", bEditorMode)
	
	if GameLib.GetPlayerUnit():GetClassId() == GameLib.CodeEnumClass.Engineer then
		self.wndEngineer:SetStyle("Moveable", bEditorMode)
		self.wndEngineer:FindChild("EditorCover"):Show(bEditorMode)
		self.wndEngineer:SetStyle("Sizable", bEditorMode)
		self.wndEngineer:FindChild("PetBarIcons"):Show(not bEditorMode)
		self.wndEngineer:FindChild("Stance"):Show(not bEditorMode)
		self.wndEngineer:FindChild("FakePetBarIcons"):Show(bEditorMode)
		self.wndEngineer:FindChild("FakeStance"):Show(bEditorMode)
	end
end]]--

function PotatoResources:OnSave(eLevel)  --TODO: Improve this code, it's hacky.
	Apollo.SetConsoleVariable("hud.resourceBarDisplay", 1)
	--Event_FireGenericEvent("OptionsUpdated_HUDPreferences")
   -- create a table to hold our data
    local tSave = {}

	--Save location
	tSave.resourceFrame = { points = {self.wndMain:GetAnchorPoints()}, offsets = {self.wndMain:GetAnchorOffsets()}, showFrame = showFrame }
	if self.playerClassId == GameLib.CodeEnumClass.Engineer then
		tSave.engineerFrame = { points = {self.wndEngineer:GetAnchorPoints()}, offsets = {self.wndEngineer:GetAnchorOffsets()}}
		tSave.engineerFrame.bShow = showEngiFrame
	end

	tSave.bCRBEnable = self.bCRBEnable
	tSave.bPUIEnable = self.bPUIEnable
	
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
        return tSave
    elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData[self.strCharacterName] = tSave
		return self.tAccountData
	else
		return nil
	end
end

function PotatoResources:OnRestore(eLevel, tData)  --TODO: Improve this code, it's hacky.
    if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
		self.tSavedData = tData

		self.wndMain:SetAnchorPoints(unpack(self.tSavedData.resourceFrame.points))
		self.wndMain:SetAnchorOffsets(unpack(self.tSavedData.resourceFrame.offsets))
		showFrame = self.tSavedData.resourceFrame.showFrame	~= nil and self.tSavedData.resourceFrame.showFrame or 1

		if self.tSavedData.bCRBEnable ~= nil and self.tSavedData.bPUIEnable ~= nil then
			self.bCRBEnable = tData.bCRBEnable
			self.bPUIEnable = tData.bPUIEnable
		end
		
		if self.tSavedData.engineerFrame then
			self.wndEngineer:SetAnchorPoints(unpack(self.tSavedData.engineerFrame.points))
			self.wndEngineer:SetAnchorOffsets(unpack(self.tSavedData.engineerFrame.offsets))
			showEngiFrame = tData.engineerFrame.bShow
		end
	elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData = tData
	end
end

function PotatoResources:ResetFrames()
	if GameLib.GetPlayerUnit():GetClassId() ~= GameLib.CodeEnumClass.Engineer then
		self.wndMain:SetAnchorPoints(0.5,1,0.5,1)
		self.wndMain:SetAnchorOffsets(-370,-232,-10,-202)
		showFrame = 1
	else
		self.wndMain:SetAnchorPoints(0.5,1,0.5,1)
		self.wndMain:SetAnchorOffsets(-370,-232,-130,-202)
		self.wndEngineer:SetAnchorPoints(0.5,1,0.5,1)
		self.wndEngineer:SetAnchorOffsets(-130,-232,-10,-202)
		showFrame = 1
		showEngiFrame = 1
	end
end

--[[function PotatoResources:MouseDownTest(wndHandler, wndControl, eButton, x, y, bDouble)
	local elementName = wndControl:GetName()

	if ((wndHandler:GetName() == "ContainerNew1" and elementName == "Bars") or wndHandler:GetName() == "EngineerButtons") and bEditorMode then
		self:PopulateEditor(wndHandler, wndControl)
	end
end]]--

function PotatoResources:PopulateEditor(wndHandler, wndControl)
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:Show(true)
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	PLib:ElementSelected(wndHandler, self)
		
	if wndHandler:GetName() == "ContainerNew1" then
		--Populate PotatoLib editor frame; Set title
		self.wndCustomize = Apollo.LoadForm("PotatoResources.xml", "ResourceCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
		PLib.wndCustomize:FindChild("EditorContent"):ArrangeChildrenVert()
				
		self.wndBarTypes = self.wndCustomize:FindChild("BarType"):FindChild("Options")
		self.wndTypeOptions = self.wndCustomize:FindChild("TypeOptions")
		
		--[[self.wndBasicBarOptions = Apollo.LoadForm("PotatoResources.xml", "BasicBarOptions", self.wndTypeOptions, self) --Basic Bar
		self.wndBrokenBarOptions = Apollo.LoadForm("PotatoResources.xml", "BrokenBarOptions", self.wndTypeOptions, self) --Broken Bar
		self.wndColorBarOptions = Apollo.LoadForm("PotatoResources.xml", "ColorBarOptions", self.wndTypeOptions, self) --Color Bar
		self.wndMultiBarOptions = Apollo.LoadForm("PotatoResources.xml", "MultiBarOptions", self.wndTypeOptions, self) --Multi Bar]]--
		
		PLib.wndCustomize:FindChild("Title"):SetText("Resource Frame Settings")
		self.wndCustomize:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", showFrame)
		
		--[[--Populate Bar Type Options based on the type
		self:PopulateWarrior()
		
		--Set Bar Type
		self.wndCustomize:FindChild("BarType"):FindChild("Options"):SetRadioSel("BarType",self.resourceData.type) --Set button
		self.wndCustomize:FindChild("BarType"):FindChild("Options"):GetChildren()[self.resourceData.type]:FindChild("Arrow"):Show(true) --Set arrow]]--

	end
	if wndHandler:GetName() == "EngineerButtons" then
		--Populate PotatoLib editor frame; Set title
		self.wndCustomize = Apollo.LoadForm("PotatoResources.xml", "PetBarCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
		PLib.wndCustomize:FindChild("Title"):SetText("Pet Bar Settings")
		self.wndCustomize:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", showEngiFrame)
	end
	
	local nX1, nY1, nX2, nY2 = wndHandler:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = wndHandler:GetAnchorPoints()
	
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	if self.wndCustomize:FindChild("XPos") ~= nil then
		local PLib = Apollo.GetAddon("PotatoLib")
		if PLib.bPositionCenter then
			nAX1 = nAX1-0.5
			nAY1 = nAY1-0.5
		end
		self.wndCustomize:FindChild("XPos"):SetText((nAX1*nScreenX)+nX1)
		self.wndCustomize:FindChild("YPos"):SetText((nAY1*nScreenY)+nY1)
		self.wndCustomize:FindChild("Width"):SetText(nX2-nX1)
		self.wndCustomize:FindChild("Height"):SetText(nY2-nY1)
	end
end

function PotatoResources:PopulateBarTypeOptions()
	--[[local nClassId = GameLib.GetPlayerUnit():GetClassId()
	if nClassId == GameLib.CodeEnumClass.Medic or nClassId == GameLib.CodeEnumClass.Esper or 
	self:AddBarType("Basic", ]]--
end

--Something to populate "Basic" to all

--[[function PotatoResources:PopulateEngineer()
	self:AddBarType("Multi-bar", **MULTIBAR**)
	self:AddBarType("Value Changing", **COLORBYVALUE**)
end

function PotatoResources:PopulateEsper()
	self:AddBarType("Sprites", **ESPERSPRITES**)
	self:AddBarType("Number", **ESPERNUMBER**)
	self:AddBarType("Broken Bar", **ESPERBAR**)
end

function PotatoResources:PopulateMedic()
	self:AddBarType("Broken Bar", **MEDICBAR**)
end

function PotatoResources:PopulateSpellslinger()
	self:AddBarType("Multi-bar", **MULTIBAR**)
	self:AddBarType("Value Changing", **COLORBYVALUE**)
	self:AddBarType("Broken Bar", **SPELLSLINGERBAR**)
end

function PotatoResources:PopulateStalker()
	self:AddBarType("Multi-bar", **MULTIBAR**)
	self:AddBarType("Value Changing", **COLORBYVALUE**)
end

function PotatoResources:PopulateWarrior()
	self:AddBarType("Multi-bar", **MULTIBAR**)
	self:AddBarType("Value Changing", **COLORBYVALUE**)
end]]--

function PotatoResources:PopulateWarrior()
	self:AddBarType("Basic", self.wndBasicBarOptions)
	self:AddBarType("Value Changing", self.wndColorBarOptions)
	self:AddBarType("MultiBar", self.wndMultiBarOptions)
end

function PotatoResources:AddBarType(strText, wndOptions)
	local wndBar = Apollo.LoadForm("PotatoResources.xml", "BarTypeForm", self.wndBarTypes, self)
	wndBar:FindChild("Text"):SetText(strText)
	wndBar:AttachWindow(wndOptions)
	self.wndBarTypes:ArrangeChildrenVert()
end

function PotatoResources:OnShowChange( wndHandler, wndControl, eMouseButton )
	local nShowFrame = wndHandler:GetParent():GetRadioSel("ShowFrame") --1 = Always; 2 = Combat; 3 = Never
	
	showFrame = nShowFrame
end

function PotatoResources:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local wndTarget = self.wndMain
	
	if wndTarget ~= nil then	
		local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndTarget:GetAnchorPoints()
	
		local nWidth = nX2-nX1
		local nHeight = nY2-nY1
		local nScreenX, nScreenY = Apollo.GetScreenSize()
		
		local PLib = Apollo.GetAddon("PotatoLib")
		if PLib.bPositionCenter then
			nAX1 = nAX1-0.5
			nAX2 = nAX2-0.5
			nAY1 = nAY1-0.5
			nAY2 = nAY2-0.5
		end
		
		strPos = string.gsub(strPos, "[^\-0-9]", "")
		if #strPos > 1 and string.sub(strPos, 1, 1) == "0" then
			strPos = string.gsub(strPos, "0", "", 1)
		end
		
		if strPos == "" then
			strPos = "0"
		end
		
		if strPos ~= "-" then
			if strChange == "XPos" then
				wndTarget:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
			elseif strChange == "YPos" then
				wndTarget:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
			end
			PLib:MoveLockedWnds(wndTarget)
		end

		wndHandler:SetText(strPos)
		wndHandler:SetSel(#strPos,#strPos)
	end
end

function PotatoResources:TxtHWChanged( wndHandler, wndControl, strHW )

	local strChange = wndHandler:GetName()
	
	local wndTarget = self.wndMain
	
	local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()

	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 0 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		wndTarget:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		wndTarget:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
		
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end

function PotatoResources:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)
	--[[if bEditorMode and self.wndCustomize then
		local wndTarget = self.wndMain
		
		local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndTarget:GetAnchorPoints()
		local nScreenX, nScreenY = Apollo.GetScreenSize()
		
		local PLib = Apollo.GetAddon("PotatoLib")
		if PLib.bPositionCenter then
			nAX1 = nAX1-0.5
			nAY1 = nAY1-0.5
			nAX2 = nAX2-0.5
			nAY2 = nAY2-0.5
		end	
		
		if self.wndCustomize:FindChild("XPos") ~= nil then
			self.wndCustomize:FindChild("XPos"):SetText(nX1+(nAX1*nScreenX))
			self.wndCustomize:FindChild("YPos"):SetText(nY1+(nAY1*nScreenY))
			self.wndCustomize:FindChild("Width"):SetText(nX2-nX1)
			self.wndCustomize:FindChild("Height"):SetText(nY2-nY1)
		end
	end]]--
end

---------------------------------------------------------------------------------------------------
-- EngineerButtons Functions
---------------------------------------------------------------------------------------------------

function PotatoResources:ShowStanceBG( wndHandler, wndControl, eMouseButton )
	if not bEditorMode then
		self.wndEngineer:FindChild("StanceMenuBG"):Show(not self.wndEngineer:FindChild("StanceMenuBG"):IsVisible())
	end
end

function PotatoResources:OnStanceBtn( wndHandler, wndControl, eMouseButton )
	local nStance = string.gsub(wndHandler:GetName(), "Stance", "") + 0
	Pet_SetStance(0, nStance) --Pet_SetStance(nPetId, nStance) where nPetId == 0 is all pets
	self.wndEngineer:FindChild("StanceMenuBG"):Show(false)
end

---------------------------------------------------------------------------------------------------
-- ResourceCustomize Functions
---------------------------------------------------------------------------------------------------

function PotatoResources:OnStyleChange( wndHandler, wndControl, eMouseButton )
	--Disable previous arrow
	wndHandler:GetParent():GetChildren()[self.resourceData.type]:FindChild("Arrow"):Show(false)
	
	self.resourceData.type = wndHandler:GetParent():GetRadioSel("BarType") --Get new type
	wndHandler:FindChild("Arrow"):Show(true) --Enable new arrow
end

function PotatoResources:OnDisableResources( wndHandler, wndControl, eMouseButton )
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:OnPUISettings()
	PLib.wndSettings:FindChild("GeneralBtn"):SetCheck(false)
	PLib.wndSettings:FindChild("EnableDisableBtn"):SetCheck(true)
end

--[[function PotatoResources:IncrementBorderSize( wndHandler, wndControl, eMouseButton )
	local nChange = wndHandler:GetName() == "SizeValueUp" and 1 or -1
	
	--Set data value
	self.border.size = self.border.size + nChange
	
	if self.border.size == 1 or self.border.size == 20 then
		wndHandler:Enable(false)
	else
		for key, val in pairs(wndHandler:GetParent():GetChildren()) do
			if val.Enable then
				val:Enable(true)
			end
		end
	end	
	
	--Set editor window
	wndHandler:GetParent():FindChild("SizeValue"):SetText(self.border.size)
	
	self:UpdateCastbarAppearance()
end

function PotatoResources:OnShowBorder( wndHandler, wndControl, eMouseButton ) --TODO: REVAMP
	Print("OnShowBorder")
	local bCheck = wndHandler:IsChecked()
	self.border.show = bCheck
	
	self:UpdateCastbarAppearance()
end]]--


---------------------------------------------------------------------------------------------------
-- PetBarCustomize Functions
---------------------------------------------------------------------------------------------------

function PotatoResources:OnShowEngiChange( wndHandler, wndControl, eMouseButton )
	local nShowFrame = wndHandler:GetParent():GetRadioSel("ShowFrame") --1 = Always; 2 = Combat; 3 = Never
	
	showEngiFrame = nShowFrame
end

-----------------------------------------------------------------------------------------------
-- PotatoResources Instance
-----------------------------------------------------------------------------------------------
local PotatoResourcesInst = PotatoResources:new()
PotatoResourcesInst:Init()
