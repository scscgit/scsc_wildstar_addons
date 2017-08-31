local Hack = {
  nId = 20170307,
  strName = "Hide Player Unit Frame in Group",
  strDescription = "Hides the player's unit frame when in a group/raid",
  strXmlDocName = nil,
  tSave = nil,
}

function Hack:Initialize()
  self.addonTargetFrame = Apollo.GetAddon("TargetFrame")
  if self.addonTargetFrame then return true end
  self.addonPotatoFrames = Apollo.GetAddon("PotatoFrames")
  if self.addonPotatoFrames then return true end
  return false
end

function Hack:Load()
  Apollo.RegisterEventHandler("Group_Join", "OnGroupJoin", self)
  Apollo.RegisterEventHandler("Group_Left", "OnGroupLeft", self)
  if GroupLib.InGroup() then self:OnGroupJoin() end
end

function Hack:OnGroupJoin()
  if self.addonTargetFrame then
    local wndFrame = self.addonTargetFrame.luaUnitFrame.wndMainClusterFrame
    if wndFrame then wndFrame:Destroy() end
  end
  if self.addonPotatoFrames then
    self.addonPotatoFrames.tFrames[1].frameData.showFrame = 0
  end
end

function Hack:OnGroupLeft()
  if GroupLib.InGroup() then return end
  if self.addonTargetFrame then
    self.addonTargetFrame:OnUnitFrameOptionsUpdated()
  end
  if self.addonPotatoFrames then
    self.addonPotatoFrames.tFrames[1].frameData.showFrame = 1
  end
end

function Hack:Unload()
  Apollo.RemoveEventHandler("Group_Join", self)
  Apollo.RemoveEventHandler("Group_Left", self)
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
