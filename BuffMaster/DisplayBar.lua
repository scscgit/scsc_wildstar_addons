local DisplayItem = {}

local DisplayBar = {} 
setmetatable(DisplayBar, { __index = DisplayItem })

local DisplayIcon = {}
setmetatable(DisplayIcon, { __index = DisplayItem })

function DisplayBar.new(xmlDoc, spell, id, maxTime, block)
    local self = setmetatable({}, { __index = DisplayBar })
    self.spell = spell
    self.Id = id
    self.isSet = false
    self.MaxTime = maxTime

    self.Frame = Apollo.LoadForm(xmlDoc, "BarTemplate", block.buffFrame:FindChild("ItemList"), self)
    self:Initialise(spell, maxTime)
    self.Frame:FindChild("Text"):SetText(spell:GetName())
    self.Frame:SetData(spell)
    return self
end

function DisplayIcon.new(xmlDoc, spell, id, maxTime, block)
    local self = setmetatable({}, { __index = DisplayIcon })
    self.spell = spell
    self.Id = id
    self.isSet = false
    self.MaxTime = maxTime

    self.Frame = Apollo.LoadForm(xmlDoc, "IconTemplate", block.buffFrame:FindChild("ItemList"), self)
    self:Initialise(spell, maxTime)
    self.Frame:SetData(spell)
    return self
end

function DisplayItem:Initialise(spell, maxTime)
    self.Frame:FindChild("Icon"):SetSprite(spell:GetIcon())
    self.Frame:FindChild("RemainingOverlay"):SetMax(maxTime)
end

function DisplayItem:OnGenerateSpellTooltip( wndHandler, wndControl, eToolTipType, x, y )
    if wndControl == wndHandler then
        Tooltip.GetSpellTooltipForm(self, wndHandler, GameLib.GetSpell(self.spell:GetId()), false)
    end
end

function DisplayItem:SetBuff(buff, buffPosition)
    self.Frame:FindChild("RemainingOverlay"):SetProgress(buff.fTimeRemaining)
    self.spell = buff.splEffect
    if buff.nCount > 1 then
        self.Frame:FindChild("Text"):SetText(buff.splEffect:GetName() .. " (" .. buff.nCount .. ")")
    else
        self.Frame:FindChild("Text"):SetText(buff.splEffect:GetName())
    end

    if buff.fTimeRemaining ~= 0 then
        self.Frame:FindChild("Timer"):SetText(string.format("%.1fs", buff.fTimeRemaining))
    else
        self.Frame:FindChild("Timer"):SetText("")
    end
end

function DisplayItem:SetSpell(spell, cooldownRemaining, chargesRemaining)
    self.Frame:FindChild("RemainingOverlay"):SetProgress(cooldownRemaining)
    self.spell = spell
    if chargesRemaining > 0 then
        self.Frame:FindChild("Text"):SetText(spell:GetName() .. " (" .. chargesRemaining .. ")")
    else
        self.Frame:FindChild("Text"):SetText(spell:GetName())
    end

    if cooldownRemaining ~= 0 then
        self.Frame:FindChild("Timer"):SetText(string.format("%.1fs", cooldownRemaining))
    else
        self.Frame:FindChild("Timer"):SetText("")
    end
end

function DisplayBar:SetHeight(height)
    DisplayItem.SetHeight(self, height)

    local icon = self.Frame:FindChild("Icon")
    local iconHeight = icon:GetHeight()
    local left, top, right, bottom = icon:GetAnchorOffsets()
    icon:SetAnchorOffsets(left, top, left + iconHeight, bottom)

    local text = self.Frame:FindChild("Text")
    local left, top, right, bottom = text:GetAnchorOffsets()
    text:SetAnchorOffsets(iconHeight + 9, top, right, bottom)
end

function DisplayItem:SetHeight(height)
    local left, top, right, bottom = self.Frame:GetAnchorOffsets()
    self.Frame:SetAnchorOffsets(left, top, right, top + height)
end

function DisplayItem:SetBGColor(color)
    self.Frame:SetBGColor(color)
end

function DisplayItem:SetBarColor(color)
    test = self.Frame:FindChild("RemainingOverlay")
    self.Frame:FindChild("RemainingOverlay"):SetBarColor(color)
end

if _G["BuffMasterLibs"] == nil then
    _G["BuffMasterLibs"] = { }
end
_G["BuffMasterLibs"]["DisplayBar"] = DisplayBar
_G["BuffMasterLibs"]["DisplayIcon"] = DisplayIcon