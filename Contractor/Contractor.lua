-----------------------------------------------------------------------------------------------
-- Contractor
--- © 2015 Vim
--- Idea by Godofal <Codex>
--
--- Contractor is free software, all files licensed under the GPLv3. See LICENSE for details.
--

Contractor = {
	name = "Contractor",
	version = {0,8,6},
	bVisible = true,
	tContracts = {},
	nContracts = 0,
}

local karClassToIcon =
{
	[GameLib.CodeEnumClass.Warrior] 		= "IconSprites:Icon_Windows16_UI_CRB_ClassWarrior",
	[GameLib.CodeEnumClass.Engineer] 		= "IconSprites:Icon_Windows16_UI_CRB_ClassEngineer",
	[GameLib.CodeEnumClass.Esper] 			= "IconSprites:Icon_Windows16_UI_CRB_ClassEsper",
	[GameLib.CodeEnumClass.Medic] 			= "IconSprites:Icon_Windows16_UI_CRB_ClassMedic",
	[GameLib.CodeEnumClass.Stalker] 		= "IconSprites:Icon_Windows16_UI_CRB_ClassStalker",
	[GameLib.CodeEnumClass.Spellslinger] 	= "IconSprites:Icon_Windows16_UI_CRB_ClassSpellslinger",
}

local karContractTypeToString =
{
	[ContractsLib.ContractType.None] = "None",
	[ContractsLib.ContractType.Pve] = "PvE",
	[ContractsLib.ContractType.Pvp] = "PvP",
}

function Contractor:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Contractor.xml")
	Apollo.RegisterEventHandler("ObjectiveTrackerLoaded", "OnObjectiveTrackerLoaded", self)
	Apollo.RegisterEventHandler("ToggleContractor",        "OnToggleContractor", self)
	Apollo.RegisterEventHandler("ToggleContractorOptions", "OnToggleContractorOptions", self)
	Event_FireGenericEvent("OneVersion_ReportAddonInfo", self.name, unpack(self.version))
end

function Contractor:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	return {version = self.version, bVisible = self.bVisible, tContracts = self.tContracts}
end

function Contractor:OnRestore(eLevel, tData)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Account then return end
	if type(tData.version) ~= "table" or tData.version[3] ~= self.version[3] then 
		tData.version = self.version
		tData.tContracts = {} 
	end
	for k,v in pairs(tData) do self[k] = v end

	self:OnCharacterCreated()
	
	Event_FireGenericEvent("ObjectiveTracker_RequestParent")
end

function Contractor:OnCharacterCreated()
	local unit = GameLib.GetPlayerUnit()
	if not unit then Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterCreated", self); return end
	Apollo.RemoveEventHandler("CharacterCreated", self)

	self.tCurrentAlt = {strName = unit:GetName(), eClass = unit:GetClassId()}
	self.tmrOnContractsLoaded = ApolloTimer.Create(0.5, true, "OnContractsLoaded", self)
end

function Contractor:OnContractsLoaded()
	local tContracts = ContractsLib.GetActiveContracts()
	if tContracts then
		self:AddActiveContracts(tContracts)
		Apollo.RegisterEventHandler("ContractStateChanged",     "OnContractStateChanged", self)
		Apollo.RegisterEventHandler("ContractObjectiveUpdated", "OnContractStateChanged", self)
		self.tmrOnContractsLoaded = nil
		self:Redraw(self.bVisible)
	end
end

function Contractor:OnObjectiveTrackerLoaded(wndObjectiveTracker) 
	if not self.bLoaded then
			
		Event_FireGenericEvent("ObjectiveTracker_NewAddOn", {
			["strAddon"] = self.name,
			["strEventMouseLeft"] = "ToggleContractor",
			["strEventMouseRight"] = "ToggleContractorOptions",
			["strIcon"] =  "spr_ObjectiveTracker_IconContract",
			["strDefaultSort"] = "032ContractsContainer",
		})
		
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "Contractor", wndObjectiveTracker, self)
		self.wndContainer = self.wndMain:FindChild("EpisodeGroupContainer")
		local _,__,___,bottom = self.wndMain:GetAnchorOffsets()
		self.nHeaderHeight = bottom
		
		self.bLoaded = true 
		self:Redraw(self.bVisible)
	end
end

function Contractor:Redraw(bVisible)
	if self.bLoaded then
		self.bVisible = bVisible
		self.wndMain:Show(bVisible)
		self.wndMain:FindChild("EpisodeGroupMinimizeBtn"):SetCheck(self.bMinimized)
		
		self.wndContainer:DestroyChildren()
		
		local nHeight = 0
		if not self.bMinimized and self.bVisible then
			self.nContracts = 0
			for nId,tContract in pairs(self.tContracts) do
				local wndContractItem = Apollo.LoadForm(self.xmlDoc, "ContractItem", self.wndContainer, self)
			
				wndContractItem:SetText("["..tContract.strType.."] "..self.Utils.ShortenString(tContract.strObjective,47,"..."))
				wndContractItem:SetTooltip(tContract.strObjective)
			
				self.nContractItemHeight = self.nContractItemHeight or self.Utils.GetWindowHeight(wndContractItem)
				nHeight = nHeight + self.nContractItemHeight
			
				for strName,tAlt in pairs(tContract.tAlts) do
					local wndAltItem = Apollo.LoadForm(self.xmlDoc, "AltItem", self.wndContainer, self)
				
					wndAltItem:FindChild("Icon"):SetSprite(karClassToIcon[tAlt.eClass])
					wndAltItem:FindChild("Name"):SetText(strName)
				
					self.nAltItemHeight = self.nAltItemHeight or self.Utils.GetWindowHeight(wndAltItem)
					nHeight = nHeight + self.nAltItemHeight
				
					self.nContracts = self.nContracts + 1
				end
			end
		end
		
		self.wndMain:SetAnchorOffsets(0,0,0,self.nHeaderHeight+nHeight)
		self.wndContainer:ArrangeChildrenVert()
		
		Event_FireGenericEvent("ObjectiveTracker_UpdateAddOn", {
			["strAddon"]	= "Contractor",
			["strText"]		= self.nContracts,
			["bChecked"]	= self.bVisible,
		})

	end
end

-- Event handling

function Contractor:OnContractStateChanged(contractActive, eState)
	if eState == Quest.QuestState_Completed
	or eState == Quest.QuestState_Abandoned then
		self:RemoveContract(contractActive)
		Contractor:Redraw(self.bVisible)
	elseif eState == Quest.QuestState_Accepted then
		self:AddContract(contractActive)
		Contractor:Redraw(self.bVisible)
	end	
end

-- Contracts handling

function Contractor:AddContract(contract)
	local nId = contract:GetId()
	local quest = contract:GetQuest()
			
	local tAltItem = {eClass = self.tCurrentAlt.eClass}
	
	local tContract = self.tContracts[nId]

	if tContract then tContract.tAlts[self.tCurrentAlt.strName] = tAltItem
	else 
		self.tContracts[nId] = { 
			strType = karContractTypeToString[contract:GetType()],
			strTitle = quest:GetTitle(),
			strObjective = quest:GetObjectiveShortDescription(0),
			tAlts = { [self.tCurrentAlt.strName] = tAltItem },
		}
	end
end

function Contractor:RemoveContract(contract, id)
	local nId = id or contract:GetId()
	if self.tContracts[nId] then
		self.tContracts[nId].tAlts[self.tCurrentAlt.strName] = nil
		if not next(self.tContracts[nId].tAlts) then
			self.tContracts[nId] = nil
		end
	end
end

function Contractor:AddActiveContracts(tActiveContracts)
	for _,tCategory in pairs(tActiveContracts) do
		for _,contract in pairs(tCategory) do
			self:AddContract(contract)
		end
	end
end

function Contractor:ReloadContracts()
	for nId, tContract in pairs(self.tContracts) do
		self:RemoveContract(nil, nId)
	end
	self:AddActiveContracts(ContractsLib.GetActiveContracts())
end

-- UI Callbacks

function Contractor:OnToggleContractor() self:Redraw(not self.bVisible) end
function Contractor:OnToggleContractorOptions()
	if self.wndContextMenu then self:CloseOptions()
	else
		self.wndContextMenu = Apollo.LoadForm(self.xmlDoc, "ContextMenu", nil, self)
		local nWidth = self.wndContextMenu:GetWidth()
		local nHeight = self.wndContextMenu:GetHeight()
		
		local tCursor = Apollo.GetMouse()
		self.wndContextMenu:Move(
			tCursor.x - nWidth,
			tCursor.y - nHeight - 5,
			nWidth,
			nHeight
		)
	end
		
	-- TODO
	-- Hide certain alts
	-- show PvE or PvP contracts only
end

function Contractor:CloseOptions(wndHandler, wndControl)
	if self.wndContextMenu and self.wndContextMenu:IsValid() then
		self.wndContextMenu:Destroy()
		self.wndContextMenu = nil
	end
end

function Contractor:OnEpisodeGroupControlBackerMouseEnter(wndHandler, wndControl)
	if wndHandler == wndControl then
		wndHandler:FindChild("EpisodeGroupMinimizeBtn"):Show(true)
	end
end

function Contractor:OnEpisodeGroupControlBackerMouseExit(wndHandler, wndControl)
	if wndHandler == wndControl then
		local wndBtn = wndHandler:FindChild("EpisodeGroupMinimizeBtn")
		wndBtn:Show(wndBtn:IsChecked())
	end
end

function Contractor:OnEpisodeGroupMinimizedBtnClick(wndHandler, wndControl, eMouseButton)
	self.bMinimized = wndControl:IsChecked()
	self:Redraw(true)
end

function Contractor:OnReloadContracts()
	self:ReloadContracts()
	self:CloseOptions()
	self:Redraw(self.bVisible)
end

-- Helper functions

Contractor.Utils = {
	GetWindowHeight = function(window)
		local _,top,__,bottom = window:GetAnchorOffsets()
		return bottom-top
	end,
	ShortenString = function(str, len, pad)
		if str:len() > len then
			return str:sub(0,len-pad:len()) .. pad
		else
			return str
		end
	end,
}
	
Apollo.RegisterAddon(Contractor)
