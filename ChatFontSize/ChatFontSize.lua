-----------------------------------------------------------------------------------------------
-- Client Lua Script for ChatFontSize
-----------------------------------------------------------------------------------------------
 
require "Window"
require "ChatSystemLib"
 
-----------------------------------------------------------------------------------------------
-- ChatFontSize Module Definition
-----------------------------------------------------------------------------------------------
local ChatFontSize = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local ktFontResourceNames = {
	[1] = "CRB_InterfaceSmall",
	[2] = "CRB_InterfaceMedium",
	[3] = "CRB_InterfaceLarge",
	[12] = "CRB_Interface12",
	[14] = "CRB_Interface14",
	[16] = "CRB_Interface16",
}

local ktFontNames = {
	[1] = "Small",
	[2] = "Medium",
	[3] = "Large",
	[12] = "12",
	[14] = "14",
	[16] = "16",
}

-- Bottom anchor coordinate of the input window
local kBottomOffsetDefault = -5
local kBottomOffsetModified = 0

-- Top anchor coordinate of the input window
local kTopOffsetDefault = -25
local kTopOffsetModified = -30
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ChatFontSize:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
	
    -- initialize variables here
	o.nCurrentFontSize = 2	-- Medium is the default
	o.bSetInputSize = false	-- Whether or not to set the input font size equal to output
	o.bSetSizeFromTimer = false
	o.strChatAddon = "ChatLog"
	--o.codeMarker = ""
    return o
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize Init
-----------------------------------------------------------------------------------------------
function ChatFontSize:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		"ChatLog",
		-- "UnitOrPackageName",
	}
	
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
	return true	
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnLoad
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnLoad()
	-- Register handlers for events, slash commands and timer, etc.
    -- load our form file
	Apollo.RegisterSlashCommand("fontsize", "OnFontSize", self)
	
	self.xmlDoc = XmlDoc.CreateFromFile("ChatFontSize.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)	
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnSave
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnSave(eType)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return nil end
	
	local tSave =
	{
		nCurrentFontSize = self.nCurrentFontSize,
		bSetInputSize = self.bSetInputSize,
		nVersion = 1,
	}

	return tSave
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnRestore
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnRestore(eType, tSavedData)
	if eType ~= GameLib.CodeEnumAddonSaveLevel.Character then return nil end

	if tSavedData and tSavedData.nVersion == 1 then
		--self.codeMarker = self.codeMarker .. ", OnRestore"
		if tSavedData.nCurrentFontSize ~= nil then
			self.nCurrentFontSize = tSavedData.nCurrentFontSize
		end
		
		if tSavedData.bSetInputSize ~= nil then
			self.bSetInputSize = tSavedData.bSetInputSize
		end
		
		self:SetFontSize(self.nCurrentFontSize)
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnDocLoaded
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
		self.wndFontData = Apollo.LoadForm(self.xmlDoc, "FontData", self, self)
		self:ReplaceChatLogOnConfigure()
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		
		-- Set a timer to set the font when the ChatLog addon is finished loading
		self.timer = ApolloTimer.Create(1.0, true, "OnTimer", self)
		
		self:SetFontSize(self.nCurrentFontSize)
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnTimer
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnTimer()
	local chatAddon = Apollo.GetAddon(self.strChatAddon)
	if self.bSetSizeFromTimer == true then
		if chatAddon.wndChatOptions ~= nil then
			--Print("OnTimer: Setting font size from timer to font size " .. tostring(self.nCurrentFontSize))
			self:SetFontSize(self.nCurrentFontSize)
			self.bSetSizeFromTimer = false
		end
	else
		-- Once we can get the chatlog window, we don't need the timer
		if chatAddon.wndChatOptions ~= nil then
			--Print("OnTimer: Deleting timer, chatAddon is loaded")
			self.timer = nil
		end
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-----------------------------------------------------------------------------------------------
-- ChatFontSize ReplaceChatLogOnConfigure
-----------------------------------------------------------------------------------------------
function ChatFontSize:ReplaceChatLogOnConfigure()
	-- Replace the ChatLog:OnConfigure routine with ours
	local chatAddon = Apollo.GetAddon(self.strChatAddon)
	self.ChatLogOnConfigure = chatAddon.OnConfigure
	chatAddon.OnConfigure = function(...)

		if self.wndFontSizeContainer == nil then
			-- Load our font selector form
			self.wndFontSizeContainer = Apollo.LoadForm(self.xmlDoc, "FontSizeContainer", chatAddon.wndChatOptions:FindChild("ChatOptionsContent"), self)
			
			-- Hide the default font size radio buttons			
			chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeSmall"):Show(false)
			chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeMedium"):Show(false)
			chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeLarge"):Show(false)
			
			-- Display it
			self.wndFontSizeContainer:Show(true)
		end

		-- Set the button text to the current font size
		self:UpdateFontButtonText()
			
		-- Make sure the button isn't checked
		self.wndFontSizeContainer:FindChild("OutputSizeButton"):SetCheck(false)
		
		-- Set the "input matches output" button to the right state
		self.wndFontSizeContainer:FindChild("InputSizeButton"):SetCheck(self.bSetInputSize)
			
		-- Call the original OnConfigure
		self.ChatLogOnConfigure(...)
	end
end				

-----------------------------------------------------------------------------------------------
-- ChatFontSize UpdateFontButtonText
-----------------------------------------------------------------------------------------------
function ChatFontSize:UpdateFontButtonText()
	if self.wndFontSizeContainer ~= nil then
		local outputSizeButton = self.wndFontSizeContainer:FindChild("OutputSizeButton")
		outputSizeButton:SetText(self:GetCurrentFontStr())
		self.wndFontSizeContainer:Show(true)
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize GetCurrentFontStr
-----------------------------------------------------------------------------------------------
function ChatFontSize:GetCurrentFontStr()
	local chatAddon = Apollo.GetAddon(self.strChatAddon)
	
	-- 1..3 are the defaults for "Small", "Medium", and "Large"
	if self.nCurrentFontSize == 1 then
		return chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeSmall"):GetText()
	elseif self.nCurrentFontSize == 2 then
		return chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeMedium"):GetText()
	elseif self.nCurrentFontSize == 3 then
		return chatAddon.wndChatOptions:FindChild("ChatOptionsContent:FontSizeLarge"):GetText()
	else
		-- The remainder are our custom sizes
		return tostring(self.nCurrentFontSize)
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize OnFontSize
-----------------------------------------------------------------------------------------------
function ChatFontSize:OnFontSize(strCmd, strArg)
	local size = tonumber(strArg)
	if size == nil and strArg ~= "small" and strArg ~= "medium" and strArg ~= "large" then
		self:DisplayHelp()
		return
	end

	if size == nil then
		-- Small, Medium, or Large
		local newSize = 0
		if strArg == "small" then
			newSize = 1
		elseif strArg == "medium" then
			newSize = 2
		else	-- "large"
			newSize = 3
		end	
		self:SetFontSize(newSize)
	elseif size == 12 or size == 14 or size == 16 then
		self:SetFontSize(size)
	else
		-- Invalid size
		self:DisplayHelp()
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize SetFontSize
-----------------------------------------------------------------------------------------------
function ChatFontSize:SetFontSize(size)
	--self.codeMarker = self.codeMarker .. ", SetFontSize(" .. tostring(self.nCurrentFontSize) .. "->" .. size .. ")"
	local bChangedFontSize = self.nCurrentFontSize ~= size
	self.nCurrentFontSize = size
	
	local chatAddon = Apollo.GetAddon(self.strChatAddon)
	if not chatAddon then
		--self.codeMarker = "SetFontSize: Failed to get addon " .. self.strChatAddon
		return
	end

	if chatAddon.wndChatOptions == nil then
		-- Try again from the timer (let chatAddon have a chance to load)
		self.bSetSizeFromTimer = true
		return
	end
	
	if size >= 1 and size <= 3 then
		local wndChatOptionsContent = chatAddon.wndChatOptions:FindChild("ChatOptionsContent")
		local wndFontControl = nil
		if size == 1 then
			wndFontControl = wndChatOptionsContent:FindChild("FontSizeSmall")
		elseif size == 2 then
			wndFontControl = wndChatOptionsContent:FindChild("FontSizeMedium")
		else
			wndFontControl = wndChatOptionsContent:FindChild("FontSizeLarge")
		end	
		
		chatAddon:OnFontSizeOption(wndFontControl, wndFontControl)
	else
		local tFont = { 
			strNormal = "CRB_Interface" .. size, 
			strAlien = "CRB_AlienLarge", 	-- Largest alien font available
			strRP = "CRB_Interface" .. size .. "_I",
		}
		
		self.wndFontData:SetData(tFont)
		chatAddon:OnFontSizeOption(self.wndFontData, self.wndFontData)
	end

	-- Update the button text
	self:UpdateFontButtonText()	
	
	-- Adjust the input font size as appropriate
	self:UpdateInputFontSize(chatAddon, size)
	
	if bChangedFontSize then
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, "Way to go, cupcake! You're at font size: " .. ktFontNames[self.nCurrentFontSize])
	end
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize UpdateInputFontSize
-----------------------------------------------------------------------------------------------
function ChatFontSize:UpdateInputFontSize( chatAddon, size )
	if chatAddon == nil or chatAddon.tChatWindows == nil then return end
	
	-- If input size is set to output size, adjust the font
	-- in all the input controls, too.
	for idx, wnd in ipairs(chatAddon.tChatWindows) do
		local w = wnd:FindChild("Input")
		if w ~= nil then
			local offsets = {w:GetAnchorOffsets()}
			if self.bSetInputSize then
				w:SetFont(ktFontResourceNames[size])
				-- Adjust the height of the input box for larger fonts
				offsets[2] = (size == 14 or size == 16) and kTopOffsetModified or kTopOffsetDefault
				offsets[4] = (size == 14 or size == 16) and kBottomOffsetModified or kBottomOffsetDefault
			else
				w:SetFont(ktFontResourceNames[2])	-- Medium, default
				offsets[2] = kTopOffsetDefault
				offsets[4] = kBottomOffsetDefault
			end
			w:SetAnchorOffsets(offsets[1], offsets[2], offsets[3], offsets[4])
		end
	end
end	

-----------------------------------------------------------------------------------------------
-- ChatFontSize DisplayHelp
-----------------------------------------------------------------------------------------------
function ChatFontSize:DisplayHelp()
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, "ChatFontSize usage: /fontsize [small|medium|large|12|14|16]")
end


---------------------------------------------------------------------------------------------------
-- ChatFontSize OnOutputSizeDropdownButton
---------------------------------------------------------------------------------------------------
function ChatFontSize:OnOutputSizeDropdownButton( wndHandler, wndControl, eMouseButton )
	local strNewFontSize = string.match(wndControl:GetName(), '%d+')
	local nNewFontSize = tonumber(strNewFontSize)
	self:SetFontSize(nNewFontSize)
	
	-- Hide the flyout window
	self.wndOutputSizeDropdown:Show(false)
	self.wndFontSizeContainer:FindChild("OutputSizeButton"):SetCheck(false)
end

---------------------------------------------------------------------------------------------------
-- ChatFontSize ToggleOutputSizeDropdown
---------------------------------------------------------------------------------------------------
function ChatFontSize:ToggleOutputSizeDropdown( wndHandler, wndControl, eMouseButton )
	-- Toggle the drop-down
	self.wndOutputSizeDropdown = self.wndFontSizeContainer:FindChild("OutputSizeDropdown")
	
	local isVisible = self.wndOutputSizeDropdown:IsVisible()
	self.wndOutputSizeDropdown:Show(not isVisible)

	wndControl:SetCheck(not isVisible)
end

---------------------------------------------------------------------------------------------------
-- ChatFontSize OnInputSizeButton
---------------------------------------------------------------------------------------------------
function ChatFontSize:OnInputSizeButton( wndHandler, wndControl, eMouseButton )
	if wndHandler ~= wndControl then return end
	self.bSetInputSize = not self.bSetInputSize
	wndControl:SetCheck(self.bSetInputSize)
	self:SetFontSize(self.nCurrentFontSize)
end

-----------------------------------------------------------------------------------------------
-- ChatFontSize Instance
-----------------------------------------------------------------------------------------------
local ChatFontSizeInst = ChatFontSize:new()
if ChatFontSizeInst:Init() == false then
	ChatFontSizeInst = nil
end
