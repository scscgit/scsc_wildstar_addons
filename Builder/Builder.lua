-----------------------------------------------------------------------------------------------
-- Client Lua Script for Builder
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Apollo"
require "GameLib"
require "MacrosLib"

-----------------------------------------------------------------------------------------------
-- Builder Module Definition
-----------------------------------------------------------------------------------------------
local Builder = {}

-----------------------------------------------------------------------------------------------
-- Localisation
-----------------------------------------------------------------------------------------------
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Builder", true)

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
local cAddons = { abilities = {[1] = "Abilities", } }

HSColor = {Blue = 0, Black = 1, Green = 2 }

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Builder:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.majorVersion = 0
	self.minorVersion = 4
	self.patchVersion = 4
	self.suffixVersion = 0 -- 0 = Rien 1 = a
	self.versionLetter = ""
	self.version = "v" .. string.format("%d.%d.%d", self.majorVersion, self.minorVersion, self.patchVersion) .. self.versionLetter 
	self.author = "YellowKiwi"
	self.addonName = "Builder"
	
	self.builds = {}
	
	self:DefaultConfig()
	
    return o
end

function Builder:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
	
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

-----------------------------------------------------------------------------------------------
-- Builder OnLoad
-----------------------------------------------------------------------------------------------
function Builder:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Builder.xml")
	self.xmlConfigDoc = XmlDoc.CreateFromFile("BuilderConfig.xml")
	Apollo.LoadSprites("BuilderSprites.xml")
	self.xmlDoc:RegisterCallback("OnDocumentReady", self)
end

function Builder:OnDocumentReady()
	if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end

	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
	Apollo.RegisterEventHandler("Builder_Show", "OnBuilderOn", self)

	--Gear Hook Event
	Apollo.RegisterEventHandler("Generic_GEAR_UPDATE", "OnGearUpdate", self)

	--This is need because AMP Abilites unlock
	Apollo.RegisterEventHandler("SpecChanged", "OnAMPPageChanged", self)
	self.hasGear = self:IsGearLoaded()
	
	Apollo.RegisterEventHandler("GenericBuilderUpdate", "OnBuilderUpdate", self)

	--TODO Message Gear not decteced
	if not self.hasGear then
		self.currentGearId = 0
	end
	
end

function Builder:OnWindowManagementReady()
	Apollo.RegisterSlashCommand("builder", "OnBuilderSlash", self)
	self:InitUI()
end



function Builder:OnBuilderOn()
	if self.wndMain:IsShown() then
		self.wndMain:Close()
	else
		self:RestoreAllBuilds()
		self.wndMain:Invoke()
		Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_GETGEAR", nil, nil, nil)
	end
end

function Builder:OnBuilderSlash(strCommand, strBuildName)

	if strBuildName ~= nil and strBuildName ~= '' then
		-- Find if the build exist
		local predicate = function(b) return b.name == strBuildName  end
		local buildId = self:TableFind(self.builds, predicate, true)
		if buildId ~= nil then
			--self:UpdateBuildWithId(buildId, true)
			-- call from builder to equip
			self.changeGear = true
			self:UpdateBuildWithId(buildId)
			self.currentBuild = buildId
			self:UpdateHotSwap()
		else
			Print(L["MACROERROR"] .. strBuildName)
		end
	else 
		-- /builder without buildName
		self:OnBuilderOn()
	end	

end

function Builder:InitUI()

	self.wndMain = Apollo.LoadForm(self.xmlDoc, "BuilderForm", nil, self)
	self.wndOverwrite = Apollo.LoadForm(self.xmlDoc, "OverwritePopUp", nil, self)

	if self.wndMain == nil then
		Apollo.AddAddonErrorText(self, L["MAINERROR"])
		return
	end

	self.wndMain:Show(false, true)
	self.wndOverwrite:Show(false,true)
	if self.config ~= nil then
		if self.config.mainWindowOffset and self.config.mainWindowOffset ~= nil then
			self.wndMain:SetAnchorOffsets(unpack(self.config.mainWindowOffset))
		end
	end
	
	-- Localisation
	self.wndMain:FindChild("BuilderPanel:TopPanel:btnCreate"):SetText(L["CREATENEW"])
	self.btnOverwriteBuild = self.wndMain:FindChild("BuilderPanel:TopPanel:btnOverwrite")
	self.btnOverwriteBuild:SetTooltip(L["OVERWRITE"])
	
	self:ToggleOverwriteButton()

	self:HotSwapInit()

	--Capture Build Change
	Apollo.RegisterEventHandler("SpecChanged", "OnAbilityChangedEvent", self)
	Apollo.RegisterEventHandler("StanceChanged", "OnStanceChange", self)
	Apollo.RegisterEventHandler("AbilityWindowHasBeenToggled", "OnAbilityWindowToggled", self)
	--Apollo.RegisterEventHandler("GenericEvent_OpenEldanAugmentation", "OnAbilityChangedEvent", self)
	--Apollo.RegisterEventHandler("InterfaceMenuList_AlertAddOn", "OnAbilityChangedEvent", self)
	Apollo.RegisterEventHandler("ToggleBlockBarsVisibility","OnToggleBars",self)
	Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
	Apollo.RegisterEventHandler("PlayerResurrected", "OnResurrected", self)

	Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_GETGEAR", nil, nil, nil)

	self.abilitiesAddon = Apollo.GetAddon("Abilities")
end

-- ##############################################################################################################################
-- REGION : Main Panel
-- ##############################################################################################################################
------------------------------
-- User Interface
------------------------------
function Builder:DrawBuildItem(nBuildId)

	local newBuildItem = nil	
	if self.config.useTag then
		newBuildItem = Apollo.LoadForm(self.xmlDoc,"BuildTagTemplateFrame", self.lstBuilds, self)
		local tagDropDown = newBuildItem:FindChild("btnDropDownTag")
		
		if self.builds[nBuildId].tagId == nil or self.builds[nBuildId].tagId == 0  then
			tagDropDown:SetText(L["NONE"])
		else
			tagDropDown:SetText(self.config.tags[self.builds[nBuildId].tagId])

		end
		
	else
		newBuildItem = Apollo.LoadForm(self.xmlDoc, "BuildTemplateFrame", self.lstBuilds, self)
	end

	local sBuildName = self.builds[nBuildId].name
	if sBuildName == nil then
		sBuildName = self:SetBuildName(nil, nBuildId)
	end
	newBuildItem:FindChild("btnUse"):SetTooltip(L["USEBUILD"] .. sBuildName .. L["CREATEMACRO"])
	newBuildItem:SetData(nBuildId)
	newBuildItem:SetName("build_" .. nBuildId)

	local txtBuildName = newBuildItem:FindChild("txtBuildName")
	txtBuildName:SetMaxTextLength(40)
	txtBuildName:SetTextRaw(sBuildName);


	if nBuildId == self.currentBuild then
		txtBuildName:SetTextColor("AddonOk")
		-- TODO Maybe do something with the use button
	else
		txtBuildName:SetTextColor("white")
	end

	self.lstBuilds:ArrangeChildrenVert()
end

function Builder:DrawDetailPanel(buildId, fraTemplate)
	local detailFrame = fraTemplate:FindChild("DetailFrame")
	local detailContainer = Apollo.LoadForm(self.xmlDoc, "DetailContainer", detailFrame, self)
	detailContainer:SetData(buildId)

	self:DrawBuildDetail(self.builds[buildId],detailContainer,false)
end

function Builder:RedrawCurrentBuildPanel()

	if self.currentLAS ~= nil then
		self.currentLAS:DestroyChildren()
	end
	self.currentLAS = self.wndMain:FindChild("BuilderPanel:TopPanel:CurrentLAS")
	local currentLASFrame = Apollo.LoadForm(self.xmlDoc, "DetailContainer", self.currentLAS, self)
	local currentLASBuild = self:GetCurrentLAS()

	self:DrawBuildDetail(currentLASBuild, currentLASFrame, true)

	if self:IsAbilitiesOpen() then
		self.wndMain:FindChild("BuilderPanel:TopPanel:EditingBackground"):Show(true,true)
	else
		self.wndMain:FindChild("BuilderPanel:TopPanel:EditingBackground"):Show(false,true)
	end
	
	
	if self:DetectBuildChange() then
		self.wndMain:FindChild("BuilderPanel:TopPanel:btnOverwrite"):Show(true,true)
	else
		self.wndMain:FindChild("BuilderPanel:TopPanel:btnOverwrite"):Show(false,true)
	end
end

function Builder:DrawBuildDetail(build, detailContainer, isCurrentLAS)

	if build ~= nil then
		-- Innnate Ability
		local innateIcon = detailContainer:FindChild("InnateIcon")
		local nSpell = GameLib.GetClassInnateAbilitySpells().nSpellCount	
		if nSpell >= 2 then nSpell = 2 end
		innateIcon:SetSprite(GameLib.GetClassInnateAbilitySpells().tSpells[build.innateIndex * nSpell]:GetIcon())
		
		-- Abilites
		local actionBarContainer = detailContainer:FindChild("ActionBarContainer")
	
		for idx = 1, 8 do
			local currentSlot = Apollo.LoadForm(self.xmlDoc, "BuildItem", actionBarContainer, self)
			currentSlot:SetData(idx)
			local abilityCase = currentSlot:FindChild("AbilityCase")
			local abilityId = build.abilities[idx]
			abilityCase:SetAbilityId(abilityId)
			local txtTier = currentSlot:FindChild("TierText")
			local tier = build.abilitiesTiers[abilityId]
			local tierText = L["BASE"]
	
			if tier > 1 then
				tier = tier - 1
				tierText = L["TIER"] .. tier
			end
			txtTier:SetText(tierText)
		end
		actionBarContainer:ArrangeChildrenHorz(0)
	
		--AMP Page
		detailContainer:FindChild("AmpPage"):SetText(L["ACTIONSET"] .. build.actionSetIndex)
	
		--Gear
		local gearSet = detailContainer:FindChild("GearSet")
		local btnGearSet = detailContainer:FindChild("btnDropDownGear")
	
		gearSet:Show(false,false)
		btnGearSet:Show(false,false)
	
		if self.hasGear then
			if isCurrentLAS then
				gearSet:Show(true,true)
				local gearText = ""
				if self.gearSets == nil then
					gearText = L["NOEQUIPMENT"]
				elseif self.currentGearId == 0 or self.currentGearId == nil then
					gearText = L["NOTSET"]
				else
					gearText = self.gearSets[self.currentGearId].name
				end
				gearSet:SetText(gearText)
			else
				local gearText = ""
				btnGearSet:Show(true,true)
				if build.gearId == 0 or build.gearId == nil then
					gearText = L["NONE"]
				else
					if self.gearSets ~= nil then
						gearText = self.gearSets[build.gearId].name
					else
						gearText = L["NONE"]
					end
				end
				btnGearSet:SetText(gearText)
			end
		end
	end
end

function Builder:EraseDetailPanel(fraTemplate)
	local detailFrame = fraTemplate:FindChild("DetailFrame")
	detailFrame:DestroyChildren()
end

function Builder:UpdateBuildList()
	self.lstBuilds = self.wndMain:FindChild("BuilderPanel:BuildsList")
	self.lstBuilds:DestroyChildren()

	for i, peCurrent in pairs(self.builds) do
		self:DrawBuildItem(i)
	end
end

function Builder:RestoreAllBuilds()
	self:RedrawCurrentBuildPanel()
	self:UpdateBuildList()
end
------------------------------
-- UI EVENTS
------------------------------
function Builder:OnCheckDetails( wndHandler, wndControl, eMouseButton )
	local nBuildId = wndControl:GetParent():GetData()
	local fraTemplate = wndControl:GetParent()
	local width = fraTemplate:GetWidth()
	local l,t,r,b = fraTemplate:GetAnchorOffsets()
	local height = 45

	if wndControl:IsChecked() then
		height = 137
		self:DrawDetailPanel(nBuildId, fraTemplate)
	else
		self:EraseDetailPanel(fraTemplate)
	end

	fraTemplate:Move(l, t, width, height)
	self.lstBuilds:ArrangeChildrenVert()
end

function Builder:OnBuildNameConfirm(wndHandler, wndControl, strText)
	local nBuildId = wndControl:GetParent():GetData()
	local newName = strText:match("^%s*(.-)%s*$")
	local oldName = self.builds[nBuildId].name

	if newName == oldName then return end

	local buildName = self:SetBuildName(strText, nBuildId)
	wndControl:SetTextRaw(buildName)

	--Rename Macro
	if(self.builds[nBuildId].macro ~= nil) then
		local macro = MacrosLib.GetMacro(self.builds[nBuildId].macro)
		if macro then
			local tParam = {
						  sName = "Builder - " .. newName,
						sSprite = macro.strSprite, 
						  sCmds = "/builder " .. newName,
    					bGlobal = macro.bIsGlobal,
    						nId = macro.nId,
   						}
    	
        	self:SaveMacro(tParam)
		end
	end

	-- Send Generic Event
	Event_FireGenericEvent("GenericBuilderUpdate","B_RENAME", nBuildId, self.builds)

	self:UpdateHotSwap()
	self:UpdateBuildList()
end

function Builder:OnCreateNewBuild(wndHandler, wndControl, eMouseButton)
	local buildToSave = self:GetCurrentLAS()
	local nBuildId = self:SaveBuild(buildToSave,nil)

	self.currentBuild = nBuildId
	self:UpdateBuildList()
	self:UpdateHotSwap()
	Event_FireGenericEvent("GenericBuilderUpdate", "B_CREATE", nBuildId, self.builds)
end

function Builder:OnDeleteBuild(wndHandler, wndControl, eMouseButton)
	if eMouseButton == 0 then
		local nBuildId = wndControl:GetParent():GetData()
		
		--Delete Macro
		if(self.builds[nBuildId].macro ~= nil) then
			local macro = MacrosLib.GetMacro(self.builds[nBuildId].macro)
			if macro then
				self:DeleteMacro(self.builds[nBuildId].macro)
			end
		end
		
		self:DeleteBuild(nBuildId);
		
		Event_FireGenericEvent("GenericBuilderUpdate", "B_DELETE", nBuildId, self.builds)
	end
end

function Builder:OnUseBuild(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local nBuildId = wndControl:GetParent():GetData()
		--self:UpdateBuildWithId(nBuildId, true)
		-- call from builder to equip
		self.changeGear = true
		self:UpdateBuildWithId(nBuildId)
		Event_FireGenericEvent("GenericBuilderUpdate", "B_USE", self.currentBuild, self.builds)
	end
end

function Builder:OnMoveBuildUp( wndHandler, wndControl, eMouseButton )
	if eMouseButton == 0 then
		local nBuildId = wndControl:GetParent():GetData()
		if nBuildId > 1 then
			local buildToMoveUp = self.builds[nBuildId]
			local buildToMoveDown = self.builds[nBuildId - 1]

			self.builds[nBuildId] = buildToMoveDown
			self.builds[nBuildId - 1] = buildToMoveUp
			if self.currentBuild == nBuildId then
				self.currentBuild = self.currentBuild - 1
				-- UP build just under current
			elseif self.currentBuild == nBuildId - 1  then
				self.currentBuild = self.currentBuild + 1
			end

			self:UpdateBuildList();

		end
	end
end

function Builder:OnMoveBuildDown( wndHandler, wndControl, eMouseButton )
	if eMouseButton == 0 then
		local nBuildId = wndControl:GetParent():GetData()
		local nbBuild = table.getn(self.builds)
		if nBuildId < nbBuild then
			local buildToMoveUp = self.builds[nBuildId+1]
			local buildToMoveDown = self.builds[nBuildId]

			self.builds[nBuildId + 1] = buildToMoveDown
			self.builds[nBuildId] = buildToMoveUp

			if self.currentBuild == nBuildId then
				self.currentBuild = self.currentBuild + 1
			-- Down build just above current
			elseif self.currentBuild == nBuildId + 1 then
				self.currentBuild = self.currentBuild -1
			end
			self:UpdateBuildList();
		end
	end
end

function Builder:OnGenerateTooltip( wndHandler, wndControl, tType, splTarget)
	if wndControl == wndHandler then
		if wndControl:GetAbilityTierId() and splTarget:GetId() ~= wndControl:GetAbilityTierId() then
			splTarget = GameLib.GetSpell(wndControl:GetAbilityTierId())
		end
		Tooltip.GetSpellTooltipForm(self, wndHandler, splTarget, {bTiers = true})
	end
end

function Builder:OnBuilderCloseBtn(wndHandler, wndControl, eMouseButton)
	self.wndMain:Close()
end
----------------------------------
-- Overwrite build functions
----------------------------------
function Builder:OnOverwriteBuildClick(wndHandler, wndControl, eMouseButton)
	self:OpenOverwritePopUp(L["OVERWRITEMSG"])
end

function Builder:OpenOverwritePopUp(message)
	self.wndOverwrite:FindChild("lblOverwriteMessage"):SetText(message .. self.builds[self.currentBuild].name)
	self.wndOverwrite:FindChild("btnYes"):SetText(L["ACCEPT"])
	self.wndOverwrite:FindChild("btnNo"):SetText(L["DECLINE"])
	self.wndOverwrite:Show(true, true)
end

function Builder:OnAcceptOverwriteClick(wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self:SaveBuild(self:GetCurrentLAS(),self.currentBuild)
		self:RedrawCurrentBuildPanel()
		self:UpdateBuildList()
		self:UpdateHotSwap()
		
		self.wndOverwrite:Show(false,true)
		self.btnOverwriteBuild:Show(false,true)
	end
end

function Builder:OnDeclineOverwriteClick( wndHandler, wndControl, eMouseButton)
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		self.currentBuild = nil
		self:UpdateBuildList()
		self:RedrawCurrentBuildPanel()
		self:UpdateHotSwap()
		
		self.wndOverwrite:Show(false,true)
	end
end

function Builder:ToggleOverwriteButton()
	-- Hide Overwrite Buid button
	if self.currentBuild == nil or self.currentBuild == 0 then
		self.btnOverwriteBuild:Show(false,true)
	else
		self.btnOverwriteBuild:Show(true,true)
	end
end

------------------------------
-- Tag Events
------------------------------
function Builder:OnTagDropDown( wndHandler, wndControl, eMouseButton )
	local buildId = wndControl:GetParent():GetData()

	local mousePosition = Apollo.GetMouse()
	local x = mousePosition.x
	local y = mousePosition.y

	if self.dropDownTag ~= nil then self.dropDownTag:Destroy() end
	self.dropDownTag = Apollo.LoadForm(self.xmlDoc, "CustomDropDown", nil, self)
	wndControl:AttachWindow(self.dropDownTag)

	-- None button
	self:CreateTagDropDownButton(buildId, 0, L["NONE"], wndControl)

	if self.config.tags ~= nil then
		for i, tag in pairs(self.config.tags) do
			self:CreateTagDropDownButton(buildId, i, tag, wndControl)
		end
	end

	self.dropDownTag:FindChild("CustomList"):ArrangeChildrenVert(0)
	self.dropDownTag:FindChild("CustomList")
	self.dropDownTag:Move(x, y+10, 125, 150)
	
	self.dropDownTag:Show(true,true)
end

function Builder:CreateTagDropDownButton(pBuildId, pTagId, pText, pButton)
	self.btnTagDropDown = Apollo.LoadForm(self.xmlDoc, "btnTagDropDown", self.dropDownTag:FindChild("CustomList"), self)
	self.btnTagDropDown:SetText(pText)
	self.btnTagDropDown:SetData({buildId = pBuildId, tagId = pTagId, button = pButton})
end

function Builder:OnTagSelectClick( wndHandler, wndControl, eMouseButton )
	local data = wndControl:GetData()
	
	self.builds[data.buildId].tagId = data.tagId
	
	if data.tagId ~= 0 then
		data.button:SetText(self.config.tags[data.tagId])
	else
		data.button:SetText(L["NONE"])
	end
	
	wndControl:GetParent():GetParent():Show(false,false)
end

-- ##############################################################################################################################
-- REGION : HotSwap
-- ##############################################################################################################################
function Builder:HotSwapInit()

	self.wndHotSwap = Apollo.LoadForm(self.xmlDoc, "HotSwapFrame", nil, self)
	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	if self.config == nil then
		self.config = {}
		self.config.useHotSwap = true
		self.config.hotSwapColor = HSColor.Blue
	end
	self.wndHotSwap:Show(self.config.useHotSwap,true)
	if self.config.hotSwapColor == HSColor.Blue then
		hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallNormal")
	elseif self.config.hotSwapColor == HSColor.Black then
		hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallDisabled")
	elseif self.config.hotSwapColor == HSColor.Green then
		hsDropDown:SetSprite("BK3:btnHolo_Green_SmallNormal")
	end
	
	if self.config ~= nil then
		if self.config.hotSwapOffset and self.config.hotSwapOffset ~= nil then
			self.wndHotSwap:SetAnchorOffsets(unpack(self.config.hotSwapOffset))
		end
	end
	self:UpdateHotSwap()
end

function Builder:UpdateHotSwap()
	local HSDropDown = self.wndHotSwap:FindChild("HSDropDown")
	-- Builder has no build saved
	if self.builds ~= nil and self.currentBuild ~= nil and self:TableLength(self.builds) > 0 then
		HSDropDown:SetText(self.builds[self.currentBuild].name)
	else
		HSDropDown:SetText(L["NOBUILD"])
	end
end

function Builder:HotSwapTagList()

	local noneTagsCount = 0
	for i, peCurrent in pairs(self.builds) do
		if peCurrent.tagId == 0 or peCurrent.tagId == nil then
			noneTagsCount = 1
			break
		end
	end

	
	if noneTagsCount == 1 then
		local btnTag = Apollo.LoadForm(self.xmlDoc, "HSTagButton", self.lstHSBuilds, self)
		btnTag:SetData(0)
		btnTag:SetText(L["NONE"])
	end
	
	for i, peTag in pairs(self.config.tags) do
		btnTag = Apollo.LoadForm(self.xmlDoc, "HSTagButton", self.lstHSBuilds, self)
		btnTag:SetData(i)
		btnTag:SetText(peTag)
	end
end

function Builder:OnHotSwapClick(wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation)
	if wndControl ~= self.wndHotSwap then
		return
	end

	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	--hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallPressed")
	-- Change Sprite

	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local buildsContainer = self.wndHotSwap:FindChild("HSContainer")
		buildsContainer:Show(true,true)

		self.lstHSBuilds = buildsContainer:FindChild("HSBuildList")
		self.lstHSBuilds:DestroyChildren()

		
		if self.config.useTag then
			self:HotSwapTagList(self.lstHSBuilds)
		else 
			-- Builds list construction
			for i, peCurrent in pairs(self.builds) do
				local btnBuild = Apollo.LoadForm(self.xmlDoc, "HSBuildButton", self.lstHSBuilds, self)
				btnBuild:SetData(i)
				btnBuild:SetText(self.builds[i].name)
			end
		end

		self.lstHSBuilds:ArrangeChildrenVert()

		local oLeft, oTop, oRight, oBottom = self.wndHotSwap:GetAnchorOffsets()
		local topOffset  = 145
		if 	self.config.hotSwapHeight ~= nil then
			topOffset = self.config.hotSwapHeight
		end
		local bottomOffset  = 40

		oLeft = 0
		oRight = 0
		if oTop > 0 then
			oTop = -topOffset
			oBottom = -bottomOffset
		else
			oTop = bottomOffset + 2
			oBottom = topOffset	+ 2
		end

		buildsContainer:SetAnchorOffsets(oLeft, oTop, oRight, oBottom)
	elseif eMouseButton == GameLib.CodeEnumInputMouse.Right then
		self:OnBuilderOn()
	end
end

function Builder:OnHotSwapTagClick( wndHandler, wndControl, eMouseButton )
	local tagId = wndControl:GetData()
	
	self.lstHSBuilds:DestroyChildren()
	if tagId ~= 0 then
		for i, peCurrent in pairs(self.builds) do
			if self.builds[i].tagId == tagId then 
				local btnBuild = Apollo.LoadForm(self.xmlDoc, "HSBuildButton", self.lstHSBuilds, self)
				btnBuild:SetData(i)
				btnBuild:SetText(self.builds[i].name)
			end
		end
	else
		for i, peCurrent in pairs(self.builds) do
			if self.builds[i].tagId == tagId or self.builds[i].tagId == nil then 
				local btnBuild = Apollo.LoadForm(self.xmlDoc, "HSBuildButton", self.lstHSBuilds, self)
				btnBuild:SetData(i)
				btnBuild:SetText(self.builds[i].name)
			end
		end
	end

	self.lstHSBuilds:ArrangeChildrenVert()
	
end

function Builder:OnHotSwapMouseEnter( wndHandler, wndControl, x, y )
	if wndControl ~= self.wndHotSwap then
		return
	end

	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	--TODO: MaybeChnage for theme
	--hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallFlyby")

end

function Builder:OnHotSwapMouseExit( wndHandler, wndControl, x, y )
	if wndControl ~= self.wndHotSwap then
		return
	end

	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	--TODO: MaybeChnage for theme
	--hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallNormal")
end

function Builder:OnHotSwapUse( wndHandler, wndControl, eMouseButton )
	if eMouseButton == GameLib.CodeEnumInputMouse.Left then
		local nBuildId = wndControl:GetData()
		--self:UpdateBuildWithId(nBuildId, true)
		-- call from builder to equip
		self.changeGear = true
		self:UpdateBuildWithId(nBuildId)
		
		Event_FireGenericEvent("GenericBuilderUpdate","B_USE", self.currentBuild, self.builds)
		self:UpdateHotSwap()

		if self.wndMain:IsShown() then
			self:RestoreAllBuilds()
		end

		--Close Container
		local buildsContainer = self.wndHotSwap:FindChild("HSContainer")
		buildsContainer:Show(false,true)

	end
end


-- ##############################################################################################################################
-- REGION : Config Panel
-- ##############################################################################################################################
function Builder:OnConfigToggle(wndHandler, wndControl, eMouseButton)
	self.builderPanel = self.wndMain:FindChild("BuilderPanel")
	self.builderConfigPanel = self.wndMain:FindChild("BuilderConfigPanel")
	
	local builderTitle = self.wndMain:FindChild("BuilderTitle")
	
	if not self.builderConfigPanel:IsVisible() then
		self:OpenConfigPanel()
		builderTitle:SetText(L["CONFIG"])
	else
		self.builderPanel:Show(true,true)		
		self.builderConfigPanel:Show(false,false)		
		builderTitle:SetText(L["BUILDER"])
	end
end

function Builder:OpenConfigPanel()
	self.builderPanel:Show(false,false)		
	self.builderConfigPanel:Show(true,true)
	
	
	--Default value
	if self.config.hotSwapHeight == nil then
		self.config.hotSwapHeight = 145
	end
	
	if self.config.useHotSwap == nil then
		self.config.useHotSwap = true
	end
	
	if not self.config.useTag == nil then
		self.config.useTag = false
	end
	
	if not self.config.useHotSwap == nil then
		self.config.useHotSwap = true
	end
	
	if not self.config.hideHotSwapCombat == nil then
		self.config.hideHotSwapCombat = false
	end
	
		
	--Restore config values
	self.builderConfigPanel:FindChild("TagFrame:btnTag"):SetCheck(self.config.useTag)
	self.builderConfigPanel:FindChild("TagFrame:btnCreateNewTag"):Enable(self.config.useTag)
	self.builderConfigPanel:FindChild("GeneralFrame:btnHotSwap"):SetCheck(self.config.useHotSwap)
	self.builderConfigPanel:FindChild("GeneralFrame:btnHideHotSwapCombat"):SetCheck(self.config.hideHotSwapCombat) 
	
	local pgbHeight = self.builderConfigPanel:FindChild("GeneralFrame:SliderHotSwapHeight")
	pgbHeight:SetMax(400)
	pgbHeight:SetProgress(self.config.hotSwapHeight - 100)
	pgbHeight:FindChild("Slider"):SetValue(self.config.hotSwapHeight - 100)
	pgbHeight:FindChild("Value"):SetText(self.config.hotSwapHeight)
	
	--HS Color
	if self.config.hotSwapColor == HSColor.Blue then
		self.builderConfigPanel:FindChild("GeneralFrame:Colors:optBlue"):SetCheck(true)
	elseif self.config.hotSwapColor == HSColor.Black then
		self.builderConfigPanel:FindChild("GeneralFrame:Colors:optBlack"):SetCheck(true)		
	elseif self.config.hotSwapColor == HSColor.Green then
		self.builderConfigPanel:FindChild("GeneralFrame:Colors:optGreen"):SetCheck(true)
	else
		self.builderConfigPanel:FindChild("GeneralFrame:Colors:optBlue"):SetCheck(true)
		self.config.hotSwapColor = HSColor.Blue
	end

	
	-- Version Number value
	self.builderConfigPanel:FindChild("VersionLabel"):SetText(self.version)
	
	self:RefreshTagList()
end

function Builder:OnUseTagToggle( wndHandler, wndControl, eMouseButton )
	local isChecked = self.builderConfigPanel:FindChild("TagFrame:btnTag"):IsChecked()
	local btnAddNewTag = self.builderConfigPanel:FindChild("TagFrame:btnCreateNewTag")
	self.config.useTag = isChecked
	btnAddNewTag:Enable(self.config.useTag)
	self:UpdateBuildList()
end

function Builder:OnHotSwapToggle(wndHandler, wndControl, eMouseButton)
	local isChecked = self.builderConfigPanel:FindChild("GeneralFrame:btnHotSwap"):IsChecked()
	self.config.useHotSwap = isChecked
	self.wndHotSwap:Show(self.config.useHotSwap,true)
end

function Builder:OnHotSwapHideCombat(wndHandler, wndControl, eMouseButton)
	local isChecked = self.builderConfigPanel:FindChild("GeneralFrame:btnHideHotSwapCombat"):IsChecked()
	self.config.hideHotSwapCombat = isChecked
end

function Builder:OnTagNameConfirm( wndHandler, wndControl, strText)
	local nTagId = wndControl:GetParent():GetData()
	local newName = strText:match("^%s*(.-)%s*$")
	local oldName = self.config.tags[nTagId]

	if newName == oldName then return end

	local tagName = self:SetTagName(strText, nTagId)
	wndControl:SetTextRaw(tagName)

	self:RefreshTagList()
end

function Builder:OnCreateNewTag( wndHandler, wndControl, eMouseButton )
	local nTagId = 0
	local nbTag = self:TableLength(self.config.tags)
	for i=1, nbTag do
		if self.config.tags[1] == nil then nTagId = 1
		else
			if self.config.tags[i + 1] == nil then nTagId = i + 1 end
		end
	end
	if nTagId == 0 then nTagId = 1 end
	
	self.config.tags[nTagId] = L["NEWTAG"]
	self:RefreshTagList()
end

function Builder:RefreshTagList()
	self.lstConfigTags = self.wndMain:FindChild("BuilderConfigPanel:TagFrame:TagList")
	self.lstConfigTags:DestroyChildren()

	for id, peCurrent in pairs(self.config.tags) do
		local newTagListItem = Apollo.LoadForm(self.xmlDoc,"TagListItem", self.lstConfigTags, self)	
		newTagListItem:SetData(id)
		newTagListItem:SetName("tag_" .. id)
	
		local sTagName = self.config.tags[id]
		if sTagName == nil then
			sTagName = self:SetTagName(nil, id)
		end
	
		local txtTagName = newTagListItem:FindChild("txtTagName")
		txtTagName:SetMaxTextLength(10)
		txtTagName:SetTextRaw(sTagName)
		
	end
	self.lstConfigTags:ArrangeChildrenVert()	
	
end

function Builder:OnDeleteTagClick( wndHandler, wndControl, eMouseButton )
	if eMouseButton == 0 then
		local tagId = wndControl:GetParent():GetData()
		local nbTags = self:TableLength(self.config.tags)
	
		self.config.tags[tagId] = nil 

		-- Arrange builds tag ids
		for i, peCurrent in pairs(self.builds) do
			if self.builds[i].tagId ~= nil then
					if self.builds[i].tagId == tagId  then 
						self.builds[i].tagId = 0
					elseif self.builds[i].tagId > tagId then
						self.builds[i].tagId = self.builds[i].tagId - 1			
					end
			else
					self.builds[i].tagId = 0
			end
		end

		
		-- Reorder the tag array			
		for i = tagId, nbTags - 1 do
			self.config.tags[i] = self.config.tags[i+1]
		end
	
		self.config.tags[nbTags] = nil	
		self:RefreshTagList()
		self:UpdateBuildList()
		
	end
end

function Builder:OnMoveTagUp(wndHandler, wndControl, eMouseButton)
	if eMouseButton == 0 then
		local nTagId = wndControl:GetParent():GetData()
		if nTagId > 1 then
			local tagToMoveUp = self.config.tags[nTagId]
			local tagToMoveDown = self.config.tags[nTagId - 1]

			self.config.tags[nTagId] = tagToMoveDown
			self.config.tags[nTagId - 1] = tagToMoveUp 

			-- Arrange builds tag ids
			for i, peCurrent in pairs(self.builds) do
				if peCurrent.tagId == nTagId then
					peCurrent.tagId = nTagId - 1
				elseif peCurrent.tagId == nTagId - 1 then
					peCurrent.tagId = nTagId 
				end
			end
			
			self:RefreshTagList();
			self:UpdateBuildList()

		end
	end
end

function Builder:OnMoveTagDown(wndHandler, wndControl, eMouseButton)
	if eMouseButton == 0 then
		local nTagId = wndControl:GetParent():GetData()
		local nbTags = table.getn(self.config.tags)
		if nTagId < nbTags then
			local tagToMoveUp = self.config.tags[nTagId + 1]
			local tagToMoveDown = self.config.tags[nTagId]

			self.config.tags[nTagId + 1] = tagToMoveDown
			self.config.tags[nTagId] = tagToMoveUp
			
			-- Arrange builds tag ids
			for i, peCurrent in pairs(self.builds) do
				if peCurrent.tagId == nTagId then
					peCurrent.tagId = nTagId + 1
				elseif peCurrent.tagId == nTagId + 1 then
					peCurrent.tagId = nTagId 
				end
			end
			
			self:RefreshTagList();
			self:UpdateBuildList();
		end
	end
end

function Builder:OnHSSliderHeightChanged( wndHandler, wndControl, fNewValue, fOldValue)
	self.config.hotSwapHeight = fNewValue + 100
	local pgbHeight = wndControl:GetParent()
	pgbHeight:SetProgress(fNewValue)
	pgbHeight:FindChild("Value"):SetText(self.config.hotSwapHeight)
end

-- ##############################################################################################################################
-- REGION : Utilies Functions
-- ##############################################################################################################################
function Builder:SaveBuild(tBuild, nBuildId)
	local buildTag
	local buildName
	
	if nBuildId == nil then
		local nBuild = self:TableLength(self.builds)

		 for _=1, nBuild do
		    if self.builds[1] == nil then nBuildId = 1
		    else
				if self.builds[_ + 1] == nil then nBuildId = _ + 1 end
			end
		 end

		 if nBuild == 0 then nBuildId = 1 end
	else
		self.currentGearId = self.builds[nBuildId].gearId
		buildName = self.builds[nBuildId].name
		buildTag = self.builds[nBuildId].tagId
	end

	self.builds[nBuildId] = {}
	tBuild.gearId = self.currentGearId
	self.builds[nBuildId] = tBuild
	
	if nBuildId ~= nil then
		self.builds[nBuildId].name = buildName
		self.builds[nBuildId].tagId = buildTag
	end
	
	return nBuildId
end

function Builder:GetCurrentLAS()
	local actionSetIndex = AbilityBook.GetCurrentSpec()
	local actionSet = ActionSetLib.GetCurrentActionSet()
	local abilities = nil
	local abilitiesTiers = nil
	local innateSpell = nil
	
	if actionSet ~= nil then
		abilities = {unpack(actionSet, 1, 8)}
		abilitiesTiers = self:ToMap(abilities,1)
		innateSpell = GameLib.GetCurrentClassInnateAbilitySpell()
		for key, ability in ipairs(AbilityBook.GetAbilitiesList()) do
			if abilitiesTiers [ability.nId] then
				abilitiesTiers[ability.nId] = ability.nCurrentTier
			end
		end
	end

	return {
		actionSetIndex = actionSetIndex ,
		abilities = abilities,
		abilitiesTiers = abilitiesTiers ,
		innateIndex = GameLib.GetCurrentClassInnateAbilityIndex(),
	}

end

---------------------------------------------------
-- Delete a Build
---------------------------------------------------
function Builder:DeleteBuild(nBuildId)
	--local nbBuilds = self:TableLength(self.builds)

	if self.builds[nBuildId] ~= nil then
		self.builds[nBuildId] = nil
	end
	
	-- Reorder the builder array
	-- for i = nBuildId, nbBuilds - 1 do
	--	self.builds[i] = self.builds[i+1]
	-- end

	-- self.builds[nbBuilds] = nil

	if self.currentBuild ~= nil then
		if nBuildId == self.currentBuild then
			self.currentBuild = nil
			self:UpdateHotSwap()
	--	elseif nBuildId < self.currentBuild then
	--		self.currentBuild = self.currentBuild - 1
		end
	end
   	
	self:UpdateBuildList()
end

---------------------------------------------------
-- Update Build With Build ID
---------------------------------------------------
--function Builder:UpdateBuildWithId(nBuildId, changeGear)
function Builder:UpdateBuildWithId(nBuildId)
	
	self.currentBuild = nBuildId
	--self:UpdateBuild(self.builds[nBuildId], changeGear)
	self:UpdateBuild(self.builds[nBuildId])
	self:UpdateHotSwap()
	self:OnBuilderCloseBtn()
end

---------------------------------------------------
-- Update Player 
---------------------------------------------------
--function Builder:UpdateBuild(build, changeGear)
function Builder:UpdateBuild(build)
   
	self.isLoadingBuild = true
	self.isLoadingActionSet = true
	self:ShowWaitingIcon(self.isLoadingBuild)

	local player = GameLib.GetPlayerUnit()
	
	if player:IsDead() or player:IsInCombat() then
		self:ShowWaitingIcon(true)
	else
		self:ShowWaitingIcon(true)

		--Gear Set
		--if build.gearId ~= 0 and build.gearId ~= nil and self.currentGearId ~= build.gearId and changeGear then
		if build.gearId ~= 0 and build.gearId ~= nil and self.currentGearId ~= build.gearId and self.changeGear then
			self.isLoadingGear = true
			Event_FireGenericEvent("Generic_GEAR_UPDATE", "G_EQUIP", build.gearId, nil, 3)
		else
			self.isLoadingGear = false
		end

		if build.actionSetIndex ~= AbilityBook.GetCurrentSpec() then
			AbilityBook.SetCurrentSpec(build.actionSetIndex)
			-- Need to wait on callback to continue
			return
		else
			self.isLoadingActionSet = false
		end
		
		self.ResetSpellTiers()	

		local currentActionSet = ActionSetLib.GetCurrentActionSet()
		for key, abilityId in ipairs(build.abilities) do
			currentActionSet[key] = abilityId
		end
	
		for abilityId, tier in pairs(build.abilitiesTiers) do
			AbilityBook.UpdateSpellTier(abilityId, tier)
		end
	
		local result = ActionSetLib.RequestActionSetChanges(currentActionSet)
		

		if build.innateIndex and currentActionSet.innateIndex ~= GameLib.GetCurrentClassInnateAbilityIndex() then
			GameLib.SetCurrentClassInnateAbilityIndex(build.innateIndex)
		end
	
		self.isLoadingActionSet = false
		self.isLoadingBuild = false
		self:ShowWaitingIcon(self.isLoadingBuild or self.isLoadingGear)
		
	end

end

function Builder:DetectBuildChange()
	if self.currentBuild == 0 or self.currentBuild == nil then
		return false
		-- TODO MAYBE : Ask to create a new one
	end

	local oldBuild = self.builds[self.currentBuild]
	local currentBuild = self:GetCurrentLAS()
	
	-- Action Set
	if oldBuild.actionSetIndex ~= currentBuild.actionSetIndex then
		return true
	end
	
	-- Validate Innate
	if oldBuild.innateIndex ~= currentBuild.innateIndex then
		return true
	end
	
	-- Validate Abilities & Tiers
	for idx = 1, 8 do
		if oldBuild.abilities[idx] ~= currentBuild.abilities[idx] then
			return true
		else
			local abilityId = oldBuild.abilities[idx]
			if oldBuild.abilitiesTiers[abilityId] ~= currentBuild.abilitiesTiers[abilityId] then
				return true
			end
		end
	end
	return false

end

function Builder:OnAMPPageChanged()

	if not self.isLoadingActionSet then
		return
	end

	self:RedrawCurrentBuildPanel()
	-- We need to callback to change the rest after a AMP Page change
	self.waitingAMP = ApolloTimer.Create(.3, false, "waitingAMP", {waitingAMP = function()
		--self:UpdateBuildWithId(self.currentBuild, true)
		self:UpdateBuildWithId(self.currentBuild)
	end})
	
end

-- ##############################################################################################################################
-- REGION : Persistance
-- ##############################################################################################################################
---------------------------------------------------------------------------------------------------
-- OnSave Data to AddonSavedData
---------------------------------------------------------------------------------------------------
function Builder:OnSave(eLevel)

	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	local tData = {}

	self.config = {
					currentBuild = self.currentBuild,
					mainWindowOffset = {self.wndMain:GetAnchorOffsets()},
					hotSwapOffset = {self.wndHotSwap:GetAnchorOffsets()},
					hotSwapHeight = self.config.hotSwapHeight,
					useHotSwap = self.config.useHotSwap,
					hideHotSwapCombat = self.config.hideHotSwapCombat, 
					useTag = self.config.useTag,
					tags = self.config.tags,
					version = self.version,
					hotSwapColor = self.config.hotSwapColor,
				  }

	tData.config = self.config
	tData.builds = self.builds

	return tData
end
---------------------------------------------------------------------------------------------------
-- OnRestore Data from AddonSavedData
---------------------------------------------------------------------------------------------------
function Builder:OnRestore(eLevel,tData)

	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return end

	if tData.builds == nil then
		self.builds = tData
		return
	end

	if tData.builds then
		self.builds = tData.builds
	else
		self.builds = nil
	end

	if tData.config.currentBuild and tData.config.currentBuild >=1 then
		self.currentBuild = tData.config.currentBuild
	else
		self.currentBuild = nil
	end

	if tData.config then
		self.config = self:DeepCopy(tData.config)

		-- Check Version MissMatch
		if self.config.version ~= self.version then
			if self.version == "0.2" then
				self.config.hotSwapOffset = {-30, -19, 255, 37}
			elseif self.version == "0.3" then
				self.config.useHotSwap = true
				self.config.useTag = false
			elseif self.version == "v0.3.5a" then
				self.config.hotSwapHeight = 145
			elseif self.version == "v0.4" then
				self.config.hideHotSwapCombat = false
				self.config.hotSwapColor = HSColor.Blue
			end			
		end
		
		if self.config.tags == nil then
			self.config.tags = {}
		end
	else
		self:DefaultConfig()
	end	
end

-----------------------------------------------------------------------------------------------
-- Reset Default Config
-----------------------------------------------------------------------------------------------
function Builder:DefaultConfig()
	self.config = {}
	self.config.useTag = false
	self.config.useHotSwap = true
	self.config.hotSwapHeight = 145					
	self.config.hideHotSwapCombat = false
	self.config.tags = {}
	self.config.hotSwapOffset = {-30, -19, 255, 37}
	self.config.hotSwapColor = HSColor.Blue
end

---------------------------------------------------------------------------------------------------
-- BuilderForm Functions
---------------------------------------------------------------------------------------------------

function Builder:OnHotSwapBlueCheck( wndHandler, wndControl, eMouseButton )
	self.config.hotSwapColor = HSColor.Blue
	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallNormal")
end

function Builder:OnHotSwapBlackCheck( wndHandler, wndControl, eMouseButton )
	self.config.hotSwapColor = HSColor.Black
	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	hsDropDown:SetSprite("BK3:btnHolo_Blue_SmallDisabled")
end

function Builder:OnHotSwapGreenCheck( wndHandler, wndControl, eMouseButton )
	self.config.hotSwapColor = HSColor.Green
	local hsDropDown = self.wndHotSwap:FindChild("HSDropDown")
	hsDropDown:SetSprite("BK3:btnHolo_Green_SmallNormal")
end

-----------------------------------------------------------------------------------------------
-- Builder Instance
-----------------------------------------------------------------------------------------------
local BuilderInst = Builder:new()
BuilderInst:Init()
