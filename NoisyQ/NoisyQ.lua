-----------------------------------------------------------------------------------------------
-- Client Lua Script for NoisyQ
-- Created by boe2. For questions/comments, mail me at apollo@boe2.be
-----------------------------------------------------------------------------------------------
require "Window"
require "Sound"
 

local NoisyQ = {}  

function NoisyQ:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.alarmTypes = {}
    self.alarmTypes.Disabled = 0
    self.alarmTypes.Once = 1
    self.alarmTypes.Repeating = 2

    self.settings = {}
	self.settings.soundID = 149
	self.settings.alarmType = self.alarmTypes.Once
	self.settings.confirmAfterQueue = true
	self.settings.useCustomVolume = true
	self.settings.customeVolumeLevel = 1
	self.originalGeneralVolumeLevel = 1
	self.originalVoiceVolumeLevel = 1
    return o
end

function NoisyQ:Init()
    Apollo.RegisterAddon(self)
end
 
function NoisyQ:OnLoad()
	Apollo.CreateTimer("AlarmSoundTimer", 3, true)
    Apollo.RegisterSlashCommand("noisyq", "OnNoisyQOn", self)
	Apollo.RegisterEventHandler("MatchingJoinQueue", "OnJoinQueue", self)
	Apollo.RegisterEventHandler("MatchingLeaveQueue", "OnLeaveQueue", self)
	Apollo.RegisterEventHandler("MatchingGameReady", "OnMatchingGameReady", self)
	Apollo.RegisterEventHandler("MatchEntered", "OnMatchEntered", self)
	Apollo.RegisterTimerHandler("AlarmSoundTimer", "OnAlarmTick", self)
end


function NoisyQ:OnCancel()
	self.wndMain:Show(false)
end

function NoisyQ:OnNoisyQOn()
	if self.wndMain == nil then
		self.wndMain = Apollo.LoadForm("NoisyQ.xml", "NoisyQForm", nil, self)
	end
	self.wndMain:Show(true)
	
	local askButton = self.wndMain:FindChild("btnAsk")
	local onceButton = self.wndMain:FindChild("btnOnce")
	local continuousButton = self.wndMain:FindChild("btnContinuous")
	local noneButton = self.wndMain:FindChild("btnNothing")
	if self.settings.confirmAfterQueue then
		self.wndMain:SetRadioSelButton("SoundSelectionGroup", askButton)
	elseif self.settings.alarmType == self.alarmTypes.Disabled then
		self.wndMain:SetRadioSelButton("SoundSelectionGroup", noneButton)
	elseif self.settings.alarmType == self.alarmTypes.Once then
		self.wndMain:SetRadioSelButton("SoundSelectionGroup", onceButton)
	else
		self.wndMain:SetRadioSelButton("SoundSelectionGroup", continuousButton)
	end

end

function NoisyQ:OnMatchingGameReady(bInProgress)
	self:AlertUser()
	self:DismissOptions()
end

function NoisyQ:OnMatchEntered()
	self:DismissAlert()
	self:DismissOptions()
end

function NoisyQ:OnJoinQueue()
	if self.settings.confirmAfterQueue then
		if self.wndOptions == nil then
			self.wndOptions = Apollo.LoadForm("NoisyQ.xml", "OptionsDialog", nil, self)
		end
		self.wndOptions:Show(true)
		self.wndOptions:ToFront()
	end
end

function NoisyQ:OnLeaveQueue()
	self:DismissAlert();
	self:DismissOptions();
end

function NoisyQ:OnAlarmTick()
	if self.wndAlert ~= nil then
		if self.wndAlert:IsVisible() then
			Sound.Play(self.settings.soundID) 
		end
	end
end

function NoisyQ:OnSave(eLevel)
	if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil
    end
	
	local save = {}
	save.settings = self.settings
	save.saved = true
	
	return save
end

function NoisyQ:OnRestore(eLevel, tData)
	if tData.saved ~= nil then
		self.settings = tData.settings
	end
end

function NoisyQ:AlertUser()
	if self.settings.alarmType ~= self.alarmTypes.Disabled then
		self:SetCustomVolumeLevels()
		if self.settings.alarmType == self.alarmTypes.Once then
			Sound.Play(self.settings.soundID)
		elseif self.settings.alarmType == self.alarmTypes.Repeating then
			if self.wndAlert == nil then
				self.wndAlert = Apollo.LoadForm("NoisyQ.xml", "AlertForm", nil, self)
			end
			self.wndAlert:Show(true)
			self.wndAlert:ToFront()
			Apollo.StartTimer("AlarmSoundTimer")
		end
	end
end

function NoisyQ:DismissAlert()
	if self.wndAlert ~= nil then
		self.wndAlert:Show(false)
		Apollo.StopTimer("AlarmSoundTimer")
	end
	self:RestoreVolumeLevels()
end

function NoisyQ:DismissOptions()
	if self.wndOptions ~= nil then
		if self.wndOptions:IsVisible() then
		 	self.wndOptions:Show(false)
		end
	end
end

function NoisyQ:SetCustomVolumeLevels()
	if self.settings.useCustomVolume then
		self.originalVolumeLevel = Apollo.GetConsoleVariable("sound.volumeMaster")
		self.originalVoiceVolumeLevel = Apollo.GetConsoleVariable("sound.volumeVoice")
		Apollo.SetConsoleVariable("sound.volumeMaster", self.settings.customeVolumeLevel)
		Apollo.SetConsoleVariable("sound.volumeVoice", self.settings.customeVolumeLevel)
	end
end

function NoisyQ:RestoreVolumeLevels()
	if self.settings.useCustomVolume then
		Apollo.SetConsoleVariable("sound.volumeMaster", self.originalVolumeLevel)
		Apollo.SetConsoleVariable("sound.volumeVoice", self.originalVoiceVolumeLevel)
	end
end


---------------------------------------------------------------------------------------------------
-- AlertForm Functions
---------------------------------------------------------------------------------------------------

function NoisyQ:OnDismissAlert( wndHandler, wndControl, eMouseButton )
	self:DismissAlert()
end


---------------------------------------------------------------------------------------------------
-- OptionsDialog Functions
---------------------------------------------------------------------------------------------------

function NoisyQ:OnAudioPrefSet( wndHandler, wndControl, eMouseButton )
	local control = wndControl:GetName()
	if control == "btnAudioNone" then
		self.settings.alarmType = self.alarmTypes.Disabled
	elseif control == "btnAudioOnce" then
		self.settings.alarmType = self.alarmTypes.Once
	else
		self.settings.alarmType = self.alarmTypes.Repeating
	end
	
	self:DismissOptions()
end

function NoisyQ:OnRememberChoiceToggle( wndHandler, wndControl, eMouseButton )
	self.settings.confirmAfterQueue = not wndControl:IsChecked()
end
---------------------------------------------------------------------------------------------------
-- NoisyQForm Functions
---------------------------------------------------------------------------------------------------

function NoisyQ:OnOKClicked( wndHandler, wndControl, eMouseButton )
	self.wndMain:Show(false)
end

function NoisyQ:OnAudioPrefSelected( wndHandler, wndControl, eMouseButton )
	local selectedButton = wndControl:GetParent():GetRadioSelButton("SoundSelectionGroup")
	if selectedButton ~= nil then
        local name = selectedButton:GetName()
		self.settings.confirmAfterQueue = name == "btnAsk"
		
		if name == "btnOnce" then
			self.settings.alarmType = self.alarmTypes.Once
		elseif name == "btnContinuous" then
			self.settings.alarmType = self.alarmTypes.Repeating
		else
			self.settings.alarmType = self.alarmTypes.Disabled
		end
    end

end

-----------------------------------------------------------------------------------------------
-- NoisyQ Instance
-----------------------------------------------------------------------------------------------
local NoisyQInst = NoisyQ:new()
NoisyQInst:Init()
