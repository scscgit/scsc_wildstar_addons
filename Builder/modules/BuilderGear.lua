local Builder = Apollo.GetAddon("Builder")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Builder", true)
-------------------------------------------------
-- IsGearLoaded, looking for GearAddon
-------------------------------------------------
function Builder:IsGearLoaded()

    -- verification que l'addon 'gear' est charg�
    local aCheckAddon = Apollo.GetAddon("Gear")
	if aCheckAddon ~= nil then
			-- on libere l'addon
			aCheckAddon = nil
			-- Addon trouvé
			return true
	end

	return nil
 end

--------------------------------------------------------------
-- Gear Update Notification
--------------------------------------------------------------
function Builder:OnGearUpdate(sAction, nGearId, tGearUpdate, nLasMod)

	if tGearUpdate then self.gearSets = tGearUpdate end

	if sAction == "G_CREATE" then
		self:RedrawCurrentBuildPanel()
	end

	if sAction == "G_DELETE" then
		if	self.currentGearId == nGearId then
			self.currentGearId = 0
		end

		for i, build in pairs(self.builds) do
			if nGearId == build.gearId then
				build.gearId = 0
			end
		end
		self:RedrawCurrentBuildPanel()
		self:UpdateBuildList()
	end

	if sAction == "G_RENAME" then
		self:RedrawCurrentBuildPanel()
		self:UpdateBuildList()
	end

	-- GearSet has change
	if sAction == "G_CHANGE" then
		self.currentGearId = nGearId
		self:RedrawCurrentBuildPanel()
		self.isLoadingGear = false
		self:ShowWaitingIcon(self.isLoadingBuild or self.isLoadingGear)
	end

	-- GearSet Callback
	if sAction == "G_GEAR" then
		self.currentGearId = nGearId
	end
end

function Builder:OnGearDropDown( wndHandler, wndControl, eMouseButton )
	local buildId = wndControl:GetParent():GetData()

	local mousePosition = Apollo.GetMouse()
	local x = mousePosition.x
	local y = mousePosition.y

	if self.dropDownGear ~= nil then self.dropDownGear:Destroy() end
	self.dropDownGear = Apollo.LoadForm(self.xmlDoc, "CustomDropDown", nil, self)
	wndControl:AttachWindow(self.dropDownGear)

	-- None button
	self:CreateGearDropDownButton(buildId, 0, L["NONE"], wndControl)

	if self.gearSets ~= nil then
		for i, gear in pairs(self.gearSets) do
			self:CreateGearDropDownButton(buildId, i, gear.name, wndControl)
		end
	end

	self.dropDownGear:FindChild("CustomList"):ArrangeChildrenVert(0)
	self.dropDownGear:Move(x, y + 10, 175, 150)
	self.dropDownGear:Show(true, true)
end

function Builder:CreateGearDropDownButton(pBuildId, pGearId, pText, pButton)
	self.btnGearDropDown = Apollo.LoadForm(self.xmlDoc, "btnGearDropDown", self.dropDownGear:FindChild("CustomList"), self)
	self.btnGearDropDown:SetText(pText)
	self.btnGearDropDown:SetData({buildId = pBuildId, gearId = pGearId, button = pButton})
end

function Builder:OnGearSelectButton( wndHandler, wndControl, eMouseButton )
	local data = wndControl:GetData()

	self.builds[data.buildId].gearId = data.gearId
	if data.gearId ~= 0 then
		data.button:SetText(self.gearSets[data.gearId].name)
	else
		data.button:SetText(L["NONE"])
	end

	wndControl:GetParent():GetParent():Show(false,false)
end

function Builder:ImportBuild(tBuild)
	local buildTag
	local buildName
	
	local nBuild = self:TableLength(self.builds)

	for _=1, nBuild do
		if self.builds[1] == nil then nBuildId = 1
		else
			if self.builds[_ + 1] == nil then nBuildId = _ + 1 end
		end
		if nBuild == 0 then nBuildId = 1 end
	end

	self.builds[nBuildId] = {}
	self.builds[nBuildId] = tBuild
end	