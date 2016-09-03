-----------------------------------------------------------------------------------------------
-- Client Lua Script for MailHelper
-----------------------------------------------------------------------------------------------

 
require "Window"
require "string"
require "math"
require "Sound"
require "Item"
require "Money"
require "GameLib"

-----------------------------------------------------------------------------------------------
-- MailHelper Module Definition
-----------------------------------------------------------------------------------------------
local MailHelper = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("MailHelper", false, "Gemini:Hook-1.0")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("MailHelper", true)
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage

-- Configure our default values
	local defaults = {
		global = {
			version = 0.9
		},
		profile = {
			config = {
				TextLableNewMail = "Compose Mail",
				HarvestLoot = true,
				StuffLoot = true,
				OtherGoldAndAttachments = true,
				OptionLableNewMail = false,
				MailSubject = "Dummy",
				MailText = "Dummy"
			}
		},
		realm = {
			alts = {
			[Unit.CodeEnumFaction.ExilesPlayer] = {},
			[Unit.CodeEnumFaction.DominionPlayer] = {}
			}
			
		}
	}
	
	local version = 1.3
	local resetVersion = 0.9
	local isReset = false
	
	local debug = false
	
 
-----------------------------------------------------------------------------------------------
-- MailHelper OnLoad
-----------------------------------------------------------------------------------------------
--function MailHelper:OnLoad()
function MailHelper:OnInitialize()
	
	self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, defaults, true)
		
	self.xmlDoc = XmlDoc.CreateFromFile("MailHelper.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- MailHelper OnDocLoaded
-----------------------------------------------------------------------------------------------
--function MailHelper:OnDocLoaded()
function MailHelper:OnEnable()
	if self.db.global.version < version then 
		if self.db.global.version <= resetVersion then
			self.db:RegisterDefaults(defaults) 
			self.db:ResetDB() 
			isReset = true
		end
	
		self.db.global.version = version
	end	

    self.faction = GameLib.GetPlayerUnit():GetFaction()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.mailAddon = Apollo.GetAddon("Mail")
		self.mailComposeAddon = Apollo.GetAddon("MailCompose")
	    Apollo.RegisterEventHandler("MailBoxActivate",	"OnInvokeMailWindow", self)
		--Apollo.RegisterEventHandler("MailBoxDeactivate", "OnCloseMailWindow", self)

	    --Apollo.RegisterSlashCommand("mailhelper", "OnSlashCmd", self)
	    -- Lazy Load waits for the Mail Addon to be loaded
	    -- TODO: Load with a hook
	
	    -- Get Char name and save it to people.alts
	    self.charName = GameLib.GetPlayerCharacterName().strCharacter

	    self:PostHook(self.mailAddon , "ComposeMail", "SetupAltContainer" )
		self:PostHook(self.mailAddon , "OnDocumentReady", "SetupMailWindow")
		
		self:SetupMailWindow()
		
	
-- ALTS
	    local found = nil
		local altCount = #self.db.realm.alts[self.faction]
        for i=1,altCount do
			
			if self.db.realm.alts[self.faction][i] == self.charName then
				found = i
			end
		end
		
		if found == nil then
			if (altCount == 14) then
				for i=2,altCount do
					self.db.realm.alts[self.faction][i-1] = self.db.realm.alts[self.faction][i]
				end
				self.db.realm.alts[self.faction][altCount] = self.charName
			else
				self.db.realm.alts[self.faction][altCount+1] = self.charName
			end
		end
------
	end
end

function MailHelper:VersionUpdateInfo()
	
end




function MailHelper:SetupMailWindow()
	timer2 = nil
	if (self.mailAddon.wndMain ~= nil) then
		self.wndMain = Apollo.LoadForm(self.xmlDoc, "MailHelperForm", self.mailAddon.wndMain:FindChild("BGArt_Frame"), self)
    	self.wndMain:Show(false, true)

    	self.wndOptionsButton = Apollo.LoadForm(self.xmlDoc, "OptionsOverlay", self.mailAddon.wndMain:FindChild("BGArt_Frame"), self)
    	self.wndOptionsButton:Show(true)

		-- BUGFIX: Thanks to imukai
		self.wndOpenAllButton = Apollo.LoadForm(self.xmlDoc, "OpenAllOverlay", self.mailAddon.wndMain, self)
		self.wndOpenAllButton:SetAnchorPoints(0,1,1,1)
		self.wndOpenAllButton:SetAnchorOffsets(200,-78,0,-23)
		self.wndOpenAllButton:Show(true)
	 
    	self:SetupConfigWindow()
    	self:SetupLableChanges()
	
   	 	GeminiLocale:TranslateWindow(L, self.wndMain)
    	GeminiLocale:TranslateWindow(L, self.wndOpenAllButton)
	else
		ApolloTimer.Create(1.0, false, "SetupMailWindow", self)
	end

end


function MailHelper:SetupConfigWindow()
	for k,v in pairs(self.db.profile.config) do
		-- Boolean options are the checkboxes, so set the check appropriately
		if (type(v) == "boolean") then
			if self.wndMain:FindChild(k) ~= nil then
				self.wndMain:FindChild(k):SetCheck(v)
			end
		end
	end
	self.wndMain:FindChild("TextLableNewMail"):SetText(self.db.profile.config.TextLableNewMail)
end	

function MailHelper:SetupLableChanges()
	self.oldTextLableNewMail = self.mailAddon.wndMain:FindChild("NewMailBtn"):GetText()
	self:UpdateLableChanges()
end

function MailHelper:SetupAltContainer()	
	if (isReset) then
		Print("[Info] MailHelper Settings had to reset. Your alts will apear again, as soon as you logged in once with every other character.")
		Print("[Info] MailHelper Settings had to reset. Your alts will apear again, as soon as you logged in once with every other character.")
		Print("[Info] MailHelper Settings had to reset. Your alts will apear again, as soon as you logged in once with every other character.")
		isReset = false
	end
	
	self.composeMail = self.mailAddon.luaComposeMail
	self.wndAltContainer = Apollo.LoadForm(self.xmlDoc, "AltContainer", self.composeMail.wndMain:FindChild("ArtBG_Frame"), self)
	-- Hide all buttons first
	self.wndAltContainer:DestroyChildren()
	
	-- Loop over all alt characters stored in our profile.
	local nIndex = 0
	for i = 1, #self.db.realm.alts[self.faction] do
		if self.db.realm.alts[self.faction][i] ~= self.charName then

			-- Load the button from the XML and inject it into the AltContainer Window.
			local wndAlt = Apollo.LoadForm(self.xmlDoc, "wndAlt", self.wndAltContainer, self)			

			local nTopOffset = ((i - nIndex) * 35) + 5
			local nBottomOffset = nTopOffset + 30
			
			wndAlt:SetAnchorOffsets(30, nTopOffset, 275, nBottomOffset)
			wndAlt:FindChild("AltButton"):SetText(self.db.realm.alts[self.faction][i])

			wndAlt:Show(true)
		else
			nIndex = 1
		end
	end
	
	-- Calculate the offset for our window, and draw it.
	local nOffset = (#self.db.realm.alts[self.faction] * 40) + 35
	self.wndAltContainer:SetAnchorOffsets(-30, 35, 300, nOffset)
	self.wndAltContainer:Show(true)
end

--function MailHelper:OnSlashCmd(strCommand, strParam)
--	if strParam == "altreset" then
--		self.db.realm.people.alts = {}
--	else
--		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, 
--			[[
--			/mailhelper : Show this help\n
--			/mailhelper altreset : Clear all saved Alts
--			]]
--		)
--	end
--end
	

-----------------------------------------------------------------------------------------------
-- MailHelper Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function MailHelper:OnInvokeMailWindow()
     --self:SetupWindows()
end

function MailHelper:UpdateLableChanges()
	if self.db.profile.config.OptionLableNewMail then
		self.mailAddon.wndMain:FindChild("NewMailBtn"):SetText(self.db.profile.config.TextLableNewMail)
	elseif self.oldTextLableNewMail ~= nil then
		self.mailAddon.wndMain:FindChild("NewMailBtn"):SetText(self.oldTextLableNewMail)
	end
end

--function MailHelper:OnCloseMailWindow()
--	self:EndOpenMail()
--end

---------------------------------------------------------------------------------------------------
-- OpenAllOverlay Functions
---------------------------------------------------------------------------------------------------

function MailHelper:OnOpenAllBtn( wndHandler, wndControl, eMouseButton )
	self.currentMailIdx = 1
	self.mailsToDelete = {}
	self:OpenMail2()
	
	
end


function MailHelper:OpenMail2()

		for idx, wndMail in pairs(self.mailAddon.tMailItemWnds) do
				local mail = wndMail:GetData()
			local tInfo = mail:GetMessageInfo()
			wndMail:FindChild("SelectMarker"):SetCheck(self:ProcessMail(mail))
		end
		self.mailAddon:TakeSelectedMail (true)
		self.mailAddon:DeleteSelectedMail(true)
end

--function MailHelper:OpenMail()
--	local  arMessages = MailSystemLib.GetInbox()
--	local nMailCount = 0
--	local msgMail
--	
--	
--	local curIds = self.currentMailIdx or 1
--	local lastIdx = 1
----Print("Timer started")	
--	for i=curIds,#arMessages do
--		msgMail = arMessages[i]
--		lastIdx = i
--		if (self:ProcessMail(msgMail)) then
--			break
--		end
--	end
--	
--	if lastIdx < #arMessages then
--		self.currentMailIdx = lastIdx + 1
--		if not self.timerOpenMessages then
--			self.timerOpenMessages = ApolloTimer.Create(0.4, true, "OpenMail", self)
--		end
--	else
--		self:EndOpenMail()
--	end
--end

function MailHelper:ProcessMail(msgMail)
	local tMsgInfo
	local msgSender
	local msgSubject 
	local msgBodyLength = 10
	local msgHasMoney = false
	local msgAttachmentCount = 0

	tMsgInfo = msgMail:GetMessageInfo()
		
	msgSender = tMsgInfo.strSenderName
	msgSubject = tMsgInfo.strSubject
	msgBodyLength = #tMsgInfo.strBody
	msgHasMoney= not tMsgInfo.monGift:IsZero()
	msgAttachmentCount = #tMsgInfo.arAttachments

	if msgSender == "Phineas T. Rotostar" and self.db.profile.config.HarvestLoot then
		-- Harvest Loot
		if debug then Print("Opening Harvest and Auction House Loot") end
		return true
	
	elseif msgSubject == L["Here's your stuff!"] and self.db.profile.config.StuffLoot then
		-- Full Inventory Loot
		if debug then Print("Opening Full Inventory Loot") end
		return true
		
	elseif (msgAttachmentCount > 0 or msgHasMoney) and self.db.profile.config.OtherGoldAndAttachments and msgBodyLength <= 3 then
		-- Other Attachments and Money
		if debug then Print("Opening Other Stuff and Mony Mail") end
		return true
	end
	
	return false
end

--function MailHelper:EndOpenMail()
--    local mailsDelete = {}
--	Print("Opening Mails Ended")
--	if self.timerOpenMessages then
--		self.timerOpenMessages:Stop()
--		self.timerOpenMessages = nil
--	end
--	
--
--	if self.mailsToDelete then
--	  for id,mail in pairs(self.mailsToDelete) do
--	   	 if #mail:GetMessageInfo().arAttachments == 0 then
--	    	Print ("delete this" .. id)
--			table.insert(mailsDelete ,mail)
--	    end
--	  end
--	
--      if #mailsDelete > 0 then
--		Print("Deleting "..#mailsDelete.." messages.");
--		MailSystemLib.DeleteMultipleMessages(mailsDelete)
--    end
-- end
-- self.mailsToDelete = {}
--end

---------------------------------------------------------------------------------------------------
-- Alt Functions
---------------------------------------------------------------------------------------------------

function MailHelper:OnAltClick( wndHandler, wndControl, eMouseButton )
	self.composeMail.wndMain:FindChild("NameEntryText"):SetText(wndControl:GetText())
	self.composeMail.wndMain:FindChild("SubjectEntryText"):SetText(self.db.profile.config.MailSubject)
	self.composeMail.wndMain:FindChild("MessageEntryText"):SetText("MH")
end
---------------------------------------------------------------------------------------------------
-- Options
---------------------------------------------------------------------------------------------------

function MailHelper:OnOptionsMenuToggle( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(self.wndOptionsButton:FindChild("OptionsButton"):IsChecked())
end

function MailHelper:OnOptionsMenuClose()
	self.wndOptionsButton:FindChild("OptionsButton"):SetCheck(false)
	self:OnOptionsMenuToggle()
end

function MailHelper:CfgButtonChecked( wndHandler, wndControl, eMouseButton )
      self.db.profile.config[wndControl:GetName()] = wndControl:IsChecked()
end

---------------------------------------------------------------------------------------------------
-- MailHelperForm Functions
---------------------------------------------------------------------------------------------------

function MailHelper:OnChangeNewMailLable( wndHandler, wndControl, strKeyName, nScanCode, nMetakeys )
	self.db.profile.config.TextLableNewMail = wndControl:GetText()
    self:UpdateLableChanges()
end

