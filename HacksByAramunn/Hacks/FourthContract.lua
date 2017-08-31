local Hack = {
  nId = 201612112,
  strName = "Fourth Contract",
  strDescription = "Allows four accepted contracts to be shown on the contract board",
  strXmlDocName = nil,
  tSave = nil,
}

function Hack:Initialize()
  self.addonContracts = Apollo.GetAddon("Contracts")
  if not self.addonContracts then return false end
  local funcOriginal = self.addonContracts.OpenContracts
  self.addonContracts.OpenContracts = function(...)
    funcOriginal(...)
    if self.bIsLoaded then
      self:ShowFourthContract()
    end
  end
  return true
end

function Hack:Load()
end

function Hack:ShowFourthContract()
  local arrContractWindows = {
    self.addonContracts.tWndRefs.wndPvEContracts,
    self.addonContracts.tWndRefs.wndPvPContracts,
  }
  for idx, wndContracts in ipairs(arrContractWindows) do
    local wndActiveContracts = wndContracts:FindChild("ActiveContracts")
    wndActiveContracts:SetSprite("")
    local wndActiveContainer = wndActiveContracts:FindChild("ActiveContractContainer")
    wndActiveContainer:SetAnchorOffsets(-220,54,205,194)
    for idx, wndContract in ipairs(wndActiveContainer:GetChildren()) do
      wndContract:SetAnchorOffsets(-62,0,40,129)
      wndContract:FindChild("TypeIcon"):SetAnchorOffsets(-43,-47,51,47)
      wndContract:FindChild("TypeRepeatable"):SetAnchorOffsets(-9,13,16,37)
      wndContract:FindChild("QualityIcon"):SetAnchorOffsets(-9,56,17,82)
      wndContract:FindChild("AchievedGlow"):SetAnchorOffsets(-80,-31,90,39)
    end
    wndActiveContainer:ArrangeChildrenHorz(Window.CodeEnumArrangeOrigin.Middle)
  end
end

function Hack:Unload()
end

function Hack:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function Hack:Register()
  local addonMain = Apollo.GetAddon("HacksByAramunn")
  addonMain:RegisterHack(self)
end

local HackInst = Hack:new()
HackInst:Register()
