local Builder = Apollo.GetAddon("Builder")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Builder", true)

function Builder:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", self.addonName, {"Builder_Show", "", "BuilderSprites:BarIcon"})
	self:UpdateInterfaceMenuAlerts()
	Event_FireGenericEvent("OneVersion_ReportAddonInfo", self.addonName, self.majorVersion, self.minorVersion, self.patchVersion, self.suffixVersion)
end

function Builder:UpdateInterfaceMenuAlerts()
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", self.addonName, {nil, self.version, nil})
end

function Builder:OnAbilityWindowToggled()
	if self.wndMain:IsShown() then
		self:RedrawCurrentBuildPanel()
		self:OnAbilityChangedEvent()
	end
end

function Builder:OnAbilityChangedEvent()
	-- Waiting to build to be commit in LAS
	self.waitingBuild = ApolloTimer.Create(.3, false, "waitingBuild", { waitingBuild = function()
			self:RedrawCurrentBuildPanel()
	end})
end

function Builder:OnToggleBars(isBlocked)
	if not isBlocked then
		self.waitingForOverwrite = ApolloTimer.Create(.3, false, "waitingForOverwrite", {waitingForOverwrite = function()
			if not self:IsAbilitiesOpen() then		
				self.buildIsDirty = self:DetectBuildChange()
				if self.buildIsDirty then
					self:OpenOverwritePopUp(L["OVERWRITEMSG"])
				end
			end
			self:RedrawCurrentBuildPanel()
		end})
	end
end

function Builder:OnStanceChange()
	if self.wndMain:IsShown() then
		self:RedrawCurrentBuildPanel()
	end
end

--------------------------------------------------------------------------------------------------------
-- Waiting Build Change
--------------------------------------------------------------------------------------------------------
function Builder:ShowWaitingIcon(bVisible)
	self.wndHotSwap:FindChild("HSDropDown:LoadingIcon"):Show(bVisible,true)
end

function Builder:OnEnteredCombat(gameUnit, bInCombat)
	if gameUnit and gameUnit:IsValid() and gameUnit:IsThePlayer() and self.isLoadingBuild then
		if bInCombat then
			self:ShowWaitingIcon(true)
		else
			self.waitingCombat = ApolloTimer.Create(1, false, "waitingCombat", {waitingCombat = function()
				self:UpdateBuild(self.builds[self.currentBuild])
			end})
		end
	end
	
	-- Hide HotSwap during combat
	if gameUnit and gameUnit:IsValid() and gameUnit:IsThePlayer() and self.config.hideHotSwapCombat then
		self.wndHotSwap:Show(not bInCombat, true)
	end
end

function Builder:OnResurrected()
	-- Need to way before resurrected delay
	self.waitingResurrected= ApolloTimer.Create(1, false, "waitingResurrected", {waitingResurrected= function()
		if self.isLoadingBuild then
			self:UpdateBuild(self.builds[self.currentBuild])
		end
	end})
end

--------------------------------------------------------------------------------------------
-- Generic Builder Event Handler
--------------------------------------------------------------------------------------------
function Builder:OnBuilderUpdate(sAction, nBuildId, tBuildUpdate)
	if sAction == "B_ACTIVATE" then
		if self:TableLength(self.builds) ~= 0 and self.builds[nBuildId] ~= nil then
			--self:UpdateBuildWithId(nBuildId, false)
			-- call from extern addon to equip
			self.changeGear = false	
			self:UpdateBuildWithId(nBuildId)
		end
	end
	
	if sAction == "B_GETBUILD" then
		Event_FireGenericEvent("GenericBuilderUpdate", "B_BUILD", self.currentBuild, self.builds)
	end
	
	if sAction == "B_IMPORT" then
		self:ImportBuild(tBuildUpdate)
		self:UpdateBuildList()
		self:UpdateHotSwap()
	end
end