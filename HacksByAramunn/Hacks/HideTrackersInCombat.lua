local Hack = {
  nId = 20161217,
  strName = "Hide Trackers in Combat",
  strDescription = "Hides all but the Public Event Tracker when you're in combat",
  strXmlDocName = nil,
  tSave = {},
}

function Hack:Initialize()
  self.strEventTracker = Apollo.GetString("PublicEventTracker_PublicEvents")
  self.addonObjectiveTracker = Apollo.GetAddon("ObjectiveTracker")
  if not self.addonObjectiveTracker then return false end
  return true
end

function Hack:Load()
  Apollo.RegisterEventHandler("UnitEnteredCombat", "OnUnitEnteredCombat", self)
end

function Hack:OnUnitEnteredCombat(unit, bEnteredCombat)
  if not unit:IsThePlayer() then return end
  for strKey, tData in pairs(self.addonObjectiveTracker.tAddons) do
    self:UpdateTracker(tData, bEnteredCombat)
  end
end

function Hack:UpdateTracker(tData, bEnteredCombat)
  if not tData.strEventMouseLeft then return end
  if tData.strAddon == self.strEventTracker then return end
  if bEnteredCombat then
    self.tSave[tData.strAddon] = tData.bChecked
  end
  if self.tSave[tData.strAddon] then
    if bEnteredCombat ~= tData.bChecked then return end
  else
    if not (bEnteredCombat and tData.bChecked) then return end
  end
  Event_FireGenericEvent(tData.strEventMouseLeft)
end

function Hack:Unload()
  Apollo.RemoveEventHandler("UnitEnteredCombat", self)
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
