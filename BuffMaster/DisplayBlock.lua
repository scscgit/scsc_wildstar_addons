local DisplayBlock = {} 

DisplayBlock.__index = DisplayBlock

setmetatable(DisplayBlock, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})

local ItemSortEnum = {
	None = 1,
	Name = 2,
	Duration = 3
}

local SortFunctions = {}
SortFunctions[ItemSortEnum.None] = nil
SortFunctions[ItemSortEnum.Name] = function(item1, item2)
	local spell1 = item1:GetData()
	local spell2 = item2:GetData()
	return spell1:GetName() < spell2:GetName()
end

SortFunctions[ItemSortEnum.Duration] = function(item1, item2)
	local spell1 = item1:GetData()
	local spell2 = item2:GetData()
	return spell1:GetCooldownRemaining() < spell2:GetCooldownRemaining()
end

function DisplayBlock.new(xmlDoc)
	local self = setmetatable({}, DisplayBlock)

    self.xmlDoc = xmlDoc
    self.buffs = { }
    self.buffFrame = Apollo.LoadForm(self.xmlDoc, "BuffBar", nil, self)
    self.itemList = self.buffFrame:FindChild("ItemList")

    self.bgColor = CColor.new(1,1,1,0.8)
    self.barColor = CColor.new(1,0,0,0.5)
    self.isEnabled = true
    self.Exclusions = { }
    self.anchorFromTop = true
    self.includeFilter = false
    self.displayAsBar = true
    self.barSize = {
    	Width = 300,
    	Height = 25
	}

    return self
end

function DisplayBlock:Load(saveData)
	if saveData.bgColor ~= nil then
		self:SetBGColor(CColor.new(saveData.bgColor[1], saveData.bgColor[2], saveData.bgColor[3], saveData.bgColor[4]))
	end

	if saveData.barColor ~= nil then
		self:SetBarColor(CColor.new(saveData.barColor[1], saveData.barColor[2], saveData.barColor[3], saveData.barColor[4]))
	end

	if saveData.isEnabled ~= nil then
		self:SetEnabled(saveData.isEnabled)
	end

	if saveData.barSize ~= nil then
		self.barSize = saveData.barSize
	end

	if saveData.Position ~= nil then
		self.buffFrame:SetAnchorOffsets(saveData.Position[1], saveData.Position[2], saveData.Position[1] + self.barSize.Width, saveData.Position[2] + self.buffFrame:GetHeight())
	end

	if saveData.Exclusions ~= nil then
		self.Exclusions = saveData.Exclusions
	end

	if saveData.anchorFromTop ~= nil then
		self.anchorFromTop = saveData.anchorFromTop
	end

	if saveData.includeFilter ~= nil then
		self.includeFilter = saveData.includeFilter
	end

	if saveData.displayAsBar ~= nil then
		self.displayAsBar = saveData.displayAsBar
	end
end

function DisplayBlock:GetSaveData()
	local left, top, right, bottom = self.buffFrame:GetAnchorOffsets()
	local saveData = {
		bgColor = { self.bgColor.r, self.bgColor.g, self.bgColor.b, self.bgColor.a },
		barColor = { self.barColor.r, self.barColor.g, self.barColor.b, self.barColor.a },
		isEnabled = self.isEnabled,
		Position = { left, top },
		Exclusions = self.Exclusions,
		anchorFromTop = self.anchorFromTop,
		barSize = self.barSize,
		includeFilter = self.includeFilter,
		displayAsBar = self.displayAsBar
	}
	return saveData
end

function DisplayBlock:SetName(name)
	self.buffFrame:FindChild("MoveAnchor"):SetText(name)
end

function DisplayBlock:SetPosition(x, y)
	self.buffFrame:SetAnchorPoints(x, y, x, y)
end

function DisplayBlock:ResetPosition()
	self.buffFrame:SetAnchorOffsets(-150, -200, 150, 200)
	self:SetBarWidth(self.barSize.Width)
	if not self.anchorFromTop then
		self:AnchorFromTop(false, true)
	end
end

function DisplayBlock:SetEnabled(isEnabled)
	self.isEnabled = isEnabled
	if not isEnabled then
		for _, buff in pairs(self.buffs) do
			self.buffs[buff.Id] = nil
			buff.Frame:Destroy()
			self:ArrangeItems()
		end
	end
end

function DisplayBlock:IsEnabled()
	return self.isEnabled
end

function DisplayBlock:SetMovable(isMovable)
	self.buffFrame:FindChild("MoveAnchor"):Show(isMovable)
	self.buffFrame:SetStyle("Picture", isMovable)
	self.buffFrame:SetStyle("Moveable", isMovable)
end

function DisplayBlock:SetBarWidth(width)
	local left, top, right, bottom = self.buffFrame:GetAnchorOffsets()
	right = left + width
	self.buffFrame:SetAnchorOffsets(left, top, right, bottom)
	self.barSize.Width = width
end

function DisplayBlock:SetBarHeight(height)
	self.barSize.Height = height
	for _, buff in pairs(self.buffs) do
		buff:SetHeight(height)
	end
	self:ArrangeItems()
end

function DisplayBlock:SetIncludeFilter(includeFilter)
	self.includeFilter = includeFilter
end

function DisplayBlock:IsIncluded(name)
	if self.includeFilter then
		return self:IsFiltered(name)
	else
		return not self:IsFiltered(name)
	end
end

function DisplayBlock:IsFiltered(name)
	for _, exclusion in pairs(self.Exclusions) do
		if exclusion == name then
			return true
		end
	end
	return false
end

function DisplayBlock:ProcessBuffs(buffs)
	if self.isEnabled then
		self.currentPass = not self.currentPass
		local currentPosition = 0
		for _, buff in pairs(buffs) do
			currentPosition = currentPosition + 1
			if self:IsIncluded(buff.splEffect:GetName()) then
				local buffBar = self.buffs[buff.idBuff]
				if buffBar == nil then
					buffBar = self:CreateBar(buff.splEffect, buff.idBuff, buff.fTimeRemaining)
					self.buffs[buff.idBuff] = buffBar

					self:ArrangeItems()
				end

				buffBar.isSet = self.currentPass
				buffBar:SetBuff(buff, currentPosition)
			end
		end

		for _, buff in pairs(self.buffs) do
			if buff.isSet ~= self.currentPass then
				self.buffs[buff.Id] = nil
				buff.Frame:Destroy()
				self:ArrangeItems()
			end
		end
	end
end

function DisplayBlock:ClearAll()
	for _, buff in pairs(self.buffs) do
		self.buffs[buff.Id] = nil
		buff.Frame:Destroy()
	end
	self:ArrangeItems()
end

function DisplayBlock:GetAbilitiesList()
	if self.abilitiesList == nil then
		self.abilitiesList = AbilityBook.GetAbilitiesList()
	end
	return self.abilitiesList
end

function DisplayBlock:ProcessSpells(spells)
	if self.isEnabled then
		local abilitiesList = self:GetAbilitiesList()
		if abilitiesList ~= nil then
			for _, ability in pairs(abilitiesList) do
				if ability.bIsActive and ability.nCurrentTier > 0 then
					local spell = ability.tTiers[ability.nCurrentTier].splObject
					self:ProcessSpell(spell)
				end
			end
		end

		local innateAbilities = GameLib.GetClassInnateAbilitySpells()
		for i = 1, innateAbilities.nSpellCount * 2, 2 do
			local s = innateAbilities.tSpells[i]
			self:ProcessSpell(s)
		end
	end
end

function DisplayBlock:ProcessSpell(spell)
	local cooldownRemaining, maxCooldown, chargesRemaining, maxCharges = self:GetSpellCooldown(spell)
	if cooldownRemaining > 0 or chargesRemaining < maxCharges then
		if self:IsIncluded(spell:GetName()) then
			local buffBar = self.buffs[spell:GetId()]
			if buffBar == nil then
				buffBar = self:CreateBar(spell, spell:GetId(), maxCooldown)

				self.buffs[spell:GetId()] = buffBar

				self:ArrangeItems()
			end
			buffBar:SetSpell(spell, cooldownRemaining, chargesRemaining)
		end
	else
		local buffBar = self.buffs[spell:GetId()]
		if buffBar ~= nil then
			self.buffs[spell:GetId()] = nil
			buffBar.Frame:Destroy()
			self:ArrangeItems()
		end
	end
end

function DisplayBlock:GetSpellCooldown(spell)
	local charges = spell:GetAbilityCharges()
	if charges and charges.nChargesMax > 0 then
		return charges.fRechargePercentRemaining * charges.fRechargeTime, charges.fRechargeTime, charges.nChargesRemaining, charges.nChargesMax
	else
		return spell:GetCooldownRemaining(), spell:GetCooldownTime(), 0, 0
	end
end

function DisplayBlock:CreateBar(spell, id, maxTime)
	local bar = nil
	if self.displayAsBar then
		bar = BuffMasterLibs.DisplayBar.new(self.xmlDoc, spell, id, maxTime, self)
	else
		bar = BuffMasterLibs.DisplayIcon.new(self.xmlDoc, spell, id, maxTime, self)
	end
	bar:SetBGColor(self.bgColor)
	bar:SetBarColor(self.barColor)
	bar:SetHeight(self.barSize.Height)
	return bar
end

function DisplayBlock:SetBGColor(color)
	self.bgColor = color
	for _, buff in pairs(self.buffs) do
		buff:SetBGColor(color)
	end
end

function DisplayBlock:SetBarColor(color)
	self.barColor = color
	for _, buff in pairs(self.buffs) do
		buff:SetBarColor(color)
	end
end

function DisplayBlock:SetBarDisplay(displayAsBar)
	if displayAsBar ~= self.displayAsBar then
		self.displayAsBar = displayAsBar

		local oldBuffs = self.buffs
		self.buffs = {}

		for _, buff in pairs(oldBuffs) do
			buff.Frame:Destroy()
		end
	end
end

function DisplayBlock:AddExclusion(exclusion)
	test = self.Exclusions
	table.insert(self.Exclusions, exclusion)
end

function DisplayBlock:RemoveExclusion(exclusion)
	for id, ex in pairs(self.Exclusions) do
		if ex == exclusion then
			table.remove(self.Exclusions, id)
			break
		end
	end
end

function DisplayBlock:AnchorFromTop(anchorTop, force)
	if self.anchorFromTop ~= anchorTop or force then
		self.anchorFromTop = anchorTop
		local left, top, right, bottom = self.buffFrame:GetAnchorOffsets()
		if anchorTop then
			self.buffFrame:SetAnchorOffsets(left, top + self.buffFrame:GetHeight(), right, top + self.buffFrame:GetHeight() + self.buffFrame:GetHeight())
		else
			self.buffFrame:SetAnchorOffsets(left, top - self.buffFrame:GetHeight(), right, top - self.buffFrame:GetHeight() + self.buffFrame:GetHeight())
		end
		self:ArrangeItems()
	end
end

function DisplayBlock:ArrangeItems()
	if self.displayAsBar then
		self.itemList:ArrangeChildrenVert(self:GetAnchorPoint(), SortFunctions[ItemSortEnum.Duration])
	else
		self.itemList:ArrangeChildrenHorz(self:GetAnchorPoint(), SortFunctions[ItemSortEnum.Duration])
	end
end

function DisplayBlock:GetAnchorPoint()
	return self.anchorFromTop and Window.CodeEnumArrangeOrigin.LeftOrTop or Window.CodeEnumArrangeOrigin.RightOrBottom
end

if _G["BuffMasterLibs"] == nil then
	_G["BuffMasterLibs"] = { }
end
_G["BuffMasterLibs"]["DisplayBlock"] = DisplayBlock