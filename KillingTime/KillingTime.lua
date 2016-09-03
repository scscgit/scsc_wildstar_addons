-----------------------------------------------------------------------------------------------
-- Client Lua Script for KillingTime
-- Copyright (c) NCsoft. All rights reserved
----------------------------------------------------------------------------------------------- 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- KillingTime Module Definition
-----------------------------------------------------------------------------------------------
local KillingTime = {} 

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function KillingTime:new(NewKillingTime)
    NewKillingTime = NewKillingTime or {}
    setmetatable(NewKillingTime, self)
    self.__index = self 

	NewKillingTime.ConsoleTag = "[KillingTime]";
	NewKillingTime.Settings = { };
	NewKillingTime.Loaded = false;

	NewKillingTime.Time = 0;
	NewKillingTime.UpdateFrequency = 1;		-- In Seconds
	
	NewKillingTime.LastTargetID = '';
	NewKillingTime.TargetID = '';
	NewKillingTime.LastHealth = 0;
	NewKillingTime.CurrentHealth = 0;
		
	NewKillingTime.EstimatedKillTime = 0;	
	NewKillingTime.Minutes = 0;
	NewKillingTime.Seconds = 0;	
	NewKillingTime.DisplayMinutes = '';
	NewKillingTime.DisplaySeconds = '';
	NewKillingTime.DPSDisplay = '';
	
	NewKillingTime.Ticks = 0;
	NewKillingTime.DamageDealt = 0;
	NewKillingTime.DPS = 0;
	
    return NewKillingTime;
end

function KillingTime:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {	}
    Apollo.RegisterAddon(self, bHasConfigureButton, strConfigureButtonText, tDependencies)
end 

-----------------------------------------------------------------------------------------------
-- KillingTime OnLoad
-----------------------------------------------------------------------------------------------
function KillingTime:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("KillingTime.xml");
	self.xmlDoc:RegisterCallback("OnDocLoaded", self);
end

function KillingTime:OnRestore(level, savedData)
	if level ~= GameLib.CodeEnumAddonSaveLevel.Character then
		return nil;
	end

	self.Settings = savedData;
	
	if self.Loaded == true then
		self:PublishSettings(true);
	end
end

-----------------------------------------------------------------------------------------------
-- KillingTime OnSave
-----------------------------------------------------------------------------------------------
function KillingTime:OnSave(level)
	if level ~= GameLib.CodeEnumAddonSaveLevel.Character then
        return nil;
    end
	
	self.Settings["TimeForm"]["Left"],
    self.Settings["TimeForm"]["Top"],
    self.Settings["TimeForm"]["Right"],
	self.Settings["TimeForm"]["Bottom"] = self.TimeForm:GetAnchorOffsets();
	
	self.Settings["DPSForm"]["Left"],
    self.Settings["DPSForm"]["Top"],
    self.Settings["DPSForm"]["Right"],
	self.Settings["DPSForm"]["Bottom"] = self.DPSForm:GetAnchorOffsets();

	return self.Settings;
end

-----------------------------------------------------------------------------------------------
-- KillingTime OnDocLoaded
-----------------------------------------------------------------------------------------------
function KillingTime:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.TimeForm = Apollo.LoadForm(self.xmlDoc, "TimeForm", nil, self);
		self.DPSForm = Apollo.LoadForm(self.xmlDoc, "DPSForm", nil, self);
		
		self:CheckSettings();
		self:PublishSettings(true);
		
		Apollo.RegisterEventHandler("VarChange_FrameCount", "UpdateUI", self);
		--Apollo.RegisterEventHandler("CombatLogDamage", "UpdateUI", self);
		--Apollo.RegisterEventHandler("UnitEnteredCombat", "UpdateUI", self);	
	
		Apollo.RegisterSlashCommand("kt", "SlashCommand", self);	
		
		self.Loaded = true;	
	end
end

-----------------------------------------------------------------------------------------------
-- KillingTime Functions
-----------------------------------------------------------------------------------------------
function KillingTime:UpdateUI()	
	self:Update(Apollo.GetTickCount() / 1000);
end

function KillingTime:CheckSettings()
	if self.Settings["TimeForm"] == nil or self.Settings["DPSForm"] == nil then
		self.Settings = { 
			["TimeForm"] = {
				["Display"] = true,
				["Top"] = 0,
				["Bottom"] = 46,
				["Left"] = 0,
				["Right"] = 100,	
			},
			["DPSForm"] = {
				["Display"] = true,
				["Top"] = 0,
				["Bottom"] = 46,
				["Left"] = 0,
				["Right"] = 100,
			},
			["Moveable"] = true;
		};
	end
end

function KillingTime:PublishSettings(publishAnchors)	
	self.TimeForm:Show(self.Settings["TimeForm"]["Display"]);
	self.DPSForm:Show(self.Settings["DPSForm"]["Display"]);	
	self.TimeForm:SetStyle("Moveable", self.Settings["Moveable"]);
	self.DPSForm:SetStyle("Moveable", self.Settings["Moveable"]);
	
	if self.Settings["Moveable"] == true then
		self.TimeForm:SetStyle("IgnoreMouse", false);
		self.DPSForm:SetStyle("IgnoreMouse", false);
	else
		self.TimeForm:SetStyle("IgnoreMouse", true);
		self.DPSForm:SetStyle("IgnoreMouse", true);
	end	
	
	if publishAnchors then
		self.TimeForm:SetAnchorOffsets(self.Settings["TimeForm"]["Left"],
									   self.Settings["TimeForm"]["Top"],
									   self.Settings["TimeForm"]["Right"],
  									   self.Settings["TimeForm"]["Bottom"]);
		self.DPSForm:Show(self.Settings["DPSForm"]["Display"]);
		self.DPSForm:SetAnchorOffsets(self.Settings["DPSForm"]["Left"],
									  self.Settings["DPSForm"]["Top"],
									  self.Settings["DPSForm"]["Right"],
  									  self.Settings["DPSForm"]["Bottom"]);	
	end
end

function KillingTime:SlashCommand(mainCommand, subCommand)	
	if subCommand ~= nil then
		if subCommand == 'hide' then
			self.Settings["TimeForm"]["Display"] = false;
			self.Settings["DPSForm"]["Display"] = false;			
		elseif subCommand == 'show' then
			self.Settings["TimeForm"]["Display"] = true;
			self.Settings["DPSForm"]["Display"] = true;			
		elseif subCommand == 'lock' then
			if self.Settings["Moveable"] == true then
				self.Settings["Moveable"] = false;
			else
				self.Settings["Moveable"] = true;
			end			
		elseif subCommand == 'time' then
			if self.Settings["TimeForm"]["Display"] == true then
				self.Settings["TimeForm"]["Display"] = false;
			else
				self.Settings["TimeForm"]["Display"] = true;
			end			
		elseif subCommand == 'dps' then		
			if self.Settings["DPSForm"]["Display"] == true then
				self.Settings["DPSForm"]["Display"] = false;
			else
				self.Settings["DPSForm"]["Display"] = true;
			end
		end
	end
	
	self:PublishSettings(false);
end

function KillingTime:GetTargetHealth() 
	local target = GameLib.GetTargetUnit();

	if target ~= nil then
		local health = target:GetHealth();
		if health ~= nil then
			return health;
		end
	end
	
	return 0;
end

function KillingTime:GetTargetId() 
	local target = GameLib.GetTargetUnit();

	if target ~= nil then
		local targetId = target:GetId();
		if targetId ~= nil then
			return targetId;
		end
	end
	
	return '';
end

function KillingTime:Update(elapsedTime)
	self.LastTargetID = self.TargetID;
	self.TargetID = self:GetTargetId();
	
	if self.TargetID ~= self.LastTargetID then
		-- Target has changed		
		self.LastHealth 		= self:GetTargetHealth();
		self.Ticks 				= 0;
		self.DamageDealt 		= 0;		
		self.Time 				= 0; -- Allow update
		
		if self.TargetID ~= '' then
			-- Keep the DPS displayed if the target dies. Only reset the dps when a new target is selected
			self.DPS = 0;
		end
	end
	
	if elapsedTime >= self.Time + self.UpdateFrequency then
		self.Time = elapsedTime;
		self.CurrentHealth = self:GetTargetHealth();
						
		if self.CurrentHealth <= 0 or self.TargetID == '' then
			-- Target is dead or we have no target			
			self.EstimatedKillTime = 0;
			self.Ticks = 0;
			self.DamageDealt = 0;			
		else
			self.DamageDealt = self.DamageDealt + (self.LastHealth - self.CurrentHealth);
			if self.DamageDealt == 0 then			
				self.EstimatedKillTime = 0;
			else
				self.Ticks = self.Ticks + 1;
				self.DPS = self.DamageDealt / (self.Ticks * self.UpdateFrequency);
				self.EstimatedKillTime = self.CurrentHealth / self.DPS;
			end			
		end
				
		self:UpdateDisplay();
		self.LastHealth = self.CurrentHealth;
	end
end

function KillingTime:UpdateDisplay()
	-- Calculate the display values and update the UI
	self.Seconds = 0;
	self.Minutes = 0;
	
	if self.EstimatedKillTime ~= nil then
		if self.EstimatedKillTime > 0 then
			-- Calculate remaining seconds
			self.Seconds = math.fmod(self.EstimatedKillTime, 60);
			
			-- Calculate remaining minutes
			self.Minutes = self.EstimatedKillTime - self.Seconds;
			self.Minutes = self.Minutes / 60;
						
			-- Round seconds
			self.Seconds = math.floor(self.Seconds);
			
			-- Validate results
			if self.Seconds <= 0 then
				self.Seconds = 1;
			end
			
			if self.Minutes < 0 then
				self.Minutes = 0;
			end	
			
			if self.Minutes > 99 then
				self.Minutes = 99;
				self.Seconds = 59;
			end
		end
	end
	
	-- Build display string
	self.DisplayMinutes = '00';
	self.DisplaySeconds = '00';
	
	if self.Minutes <= 9 then
		self.DisplayMinutes = '0'..self.Minutes;
	else
		self.DisplayMinutes = self.Minutes;
	end				
	
	if self.Seconds <= 9 then
		self.DisplaySeconds = '0'..self.Seconds;
	else
		self.DisplaySeconds = self.Seconds;
	end
	
	-- Calculate DPS display value
	if self.DPS < 1000 then
		self.DPSDisplay = math.ceil(self.DPS / 10);
	else
		self.DPSDisplay = math.ceil(self.DPS / 1000);
	end
	
	if self.DPSDisplay < 0 then
		self.DPSDisplay = 0;
	end
	
	if self.DPS < 1000 then
		self.DPSDisplay = "0."..self.DPSDisplay;
	end
	self.DPSDisplay = self.DPSDisplay .. "k";
	
	-- Update UI
	self.TimeForm:SetText(self.DisplayMinutes..':'..self.DisplaySeconds);
	self.DPSForm:SetText(self.DPSDisplay);
end

-----------------------------------------------------------------------------------------------
-- KillingTime Instance
-----------------------------------------------------------------------------------------------
local KillingTimeInst = KillingTime:new();
KillingTimeInst:Init();

