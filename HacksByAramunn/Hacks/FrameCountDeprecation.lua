local Hack = {
  nId = 201612111,
  strName = "Frame Count Deprecation",
  strDescription = "Fixes addons that use the VarChange_FrameCount event",
  strXmlDocName = nil,
  tSave = nil,
}

function Hack:Initialize()
  return true
end

function Hack:Load()
  Apollo.RegisterEventHandler("FrameCount", "OnFrameCount", self)
end

function Hack:OnFrameCount()
  Event_FireGenericEvent("VarChange_FrameCount")
end

function Hack:Unload()
  Apollo.RemoveEventHandler("FrameCount", self)
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
