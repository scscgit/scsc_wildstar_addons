----------------------------------------------------------------------------------------------
-- Speed
--- © 2015 Vim
--
--- Speed is free software, all files licensed under the GPLv3. See LICENSE for details.

Speed = {
	name = "Speed",
	version = {0,4,1},
	fTimer = 0.5,
}
 
function Speed:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("Speed.xml")
    self.wndMain = Apollo.LoadForm(self.xmlDoc, "Main", nil, self)
	self.wndSpeed = self.wndMain:FindChild("Speed")
	Apollo.RegisterSlashCommand("speed", "OnSlashCommand", self)
	Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
	Event_FireGenericEvent("OneVersion_ReportAddonInfo", self.name, unpack(self.version))
end

function Speed:OnWindowManagementReady()
	Event_FireGenericEvent("WindowManagementAdd", {wnd = self.wndMain, strName = "Speed"})
end

function Speed:OnTimer(nTicks)
	if nTicks > 0 then
		local unitPlayer = GameLib.GetPlayerUnit()
		if unitPlayer and unitPlayer:IsValid() then
			local vNewPos = Vector3.New(unitPlayer:GetPosition())
			local fSpeed = 1000 * (vNewPos - self.vLastPos):Length() / nTicks
			self.vLastPos = vNewPos
			self.wndSpeed:SetText(string.format("%0.2f", fSpeed))
		end
	end
end

function Speed:OnSlashCommand()
	if self.wndMain:IsVisible() then
		self.tmrSpeed = nil
		self.wndMain:Close()
	else
		self.vLastPos = Vector3.New(GameLib.GetPlayerUnit():GetPosition())
		self.tmrSpeed = ApolloTimer.Create(self.fTimer, true, "OnTimer", self)
		self.wndMain:Invoke()
	end
end

Apollo.RegisterAddon(Speed) 
