local Hack = {
  nId = 20170323,
  strName = "Movable HUD Alerts",
  strDescription = "Allows the HUD Alerts (E.g. Vacuum Loot) to be movable via Interface Options",
  strXmlDocName = nil,
  tSave = nil,
}

local kstrWndMgmtName = "HUD Alerts (HbA)"
local knWndMgmtSaveVersion = 1

function Hack:Initialize()
  self.addonHUDAlerts = Apollo.GetAddon("HUDAlerts")
  if not self.addonHUDAlerts then return false end
  return true
end

function Hack:Load()
  Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
  Apollo.RegisterEventHandler("WindowManagementUpdate", "OnWindowManagementUpdate", self)
  self:OnWindowManagementReady()
end

function Hack:OnWindowManagementReady()
  Event_FireGenericEvent("WindowManagementRegister", {
    strName = kstrWndMgmtName,
    nSaveVersion = knWndMgmtSaveVersion,
  })
  Event_FireGenericEvent("WindowManagementAdd", {
    wnd = self.addonHUDAlerts.wndAlertContainer,
    strName = kstrWndMgmtName,
    nSaveVersion = knWndMgmtSaveVersion,
  })
end

function Hack:OnWindowManagementUpdate(tSettings)
  local wndAlerts = self.addonHUDAlerts.wndAlertContainer
  if tSettings and tSettings.wnd and tSettings.wnd == wndAlerts then
    local bMoveable = wndAlerts:IsStyleOn("Moveable")
    local bHasMoved = tSettings.bHasMoved
    wndAlerts:SetSprite(bMoveable and "BK3:UI_BK3_Holo_Snippet" or "")
    wndAlerts:SetStyle("IgnoreMouse", not bMoveable)
  end
end

function Hack:Unload()
  Apollo.RemoveEventHandler("WindowManagementReady", self)
  Apollo.RemoveEventHandler("WindowManagementUpdate", self)
  Event_FireGenericEvent("WindowManagementRemove", {
    strName = kstrWndMgmtName,
    nSaveVersion = knWndMgmtSaveVersion,
  })
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
