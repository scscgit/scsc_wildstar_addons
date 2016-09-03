-----------------------------------------------------------------------------------------------
-- Client Lua Script for PotatoSprint
-- Copyright (c) Tyler T. Hardy. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- PotatoSprint Module Definition
-----------------------------------------------------------------------------------------------
local PotatoSprint = {} 

-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local eEnduranceFlash =
{
	EnduranceFlashZero = 1,
	EnduranceFlashOne = 2,
	EnduranceFlashTwo = 3,
	EnduranceFlashThree = 4,
}

local showFrame = 1
local showFull = 1
local bEditorMode = false
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PotatoSprint:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function PotatoSprint:Init()
    local bHasConfigureFunction = false
    local strConfigureButtonText = ""
    local tDependencies = { "PotatoLib", "Util" }
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
-----------------------------------------------------------------------------------------------
-- PotatoSprint OnLoad
-----------------------------------------------------------------------------------------------
function PotatoSprint:OnLoad()
    -- Register handlers for events, slash commands and timer, etc.
    -- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
    --Apollo.RegisterEventHandler("VarChange_FrameCount", 		"OnFrame", self)
	Apollo.RegisterTimerHandler("FrameUpdate", 					"OnFrame", self)

	Apollo.CreateTimer("FrameUpdate", 0.013, true)

	Apollo.RegisterEventHandler("PotatoEditor",					"EditorModeToggle", self)
	Apollo.RegisterEventHandler("PotatoReset",					"Reset", self)
	Apollo.RegisterEventHandler("PotatoResetPopulate",			"PopulateResetFeatures", self)
	
    -- load our forms
    	
	self.wndSprintDash = Apollo.LoadForm("PotatoSprint.xml", "SprintDash", nil, self)
	self.wndSprintDash:Show(true)
	
	self.wndSprintDash:SetAnchorPoints(0.5, 0.7, 0.5, 0.7)
	self.wndSprintDash:SetAnchorOffsets(-100, -15 - 65, 100, 15 - 65)
	
	self.texture = "Aluminum"
	self.tAccountData = {}
end

function PotatoSprint:PopulateResetFeatures()
	PotatoLib:AddResetItem("Sprint/Dash Module", nil, self)
end

function PotatoSprint:OnPRFReset()
	self:Reset()
end

-----------------------------------------------------------------------------------------------
-- PotatoSprint Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

function PotatoSprint:OnFrame()
	local unitPlayer = GameLib.GetPlayerUnit()
	if not unitPlayer or unitPlayer == nil then return end
	if self.strCharacterName == nil then self.strCharacterName = unitPlayer:GetName() end
	local nEvadeCurr = unitPlayer:GetResource(7)
	local nEvadeMax = unitPlayer:GetMaxResource(7)
	local nRunCurr = unitPlayer:GetResource(0)
	local nRunMax = unitPlayer:GetMaxResource(0)
	local bShowFull = showFull == 1 and true or (nRunCurr ~= nRunMax or nEvadeCurr ~= nEvadeMax)
	
	if (showFrame == 1 and bShowFull) or (showFrame == 2 and PotatoLib.bInCombat and bShowFull) or bEditorMode then
		self.wndSprintDash:Show(true)
		PotatoLib:SetBarVars("Sprint", self.wndSprintDash, nRunCurr, nRunMax)
		PotatoLib:SetBarAppearance("Sprint", self.wndSprintDash, self.texture, "00ffff", 100)
		
		PotatoLib:SetBarVars("Dodge1", self.wndSprintDash, nEvadeCurr, nEvadeMax-100)
		PotatoLib:SetBarAppearance("Dodge1", self.wndSprintDash, self.texture, nEvadeCurr >= 100 and "ffff00" or "ff00dd", 100)
		self.wndSprintDash:FindChild("DodgeBack1"):SetSprite("WhiteFill")
		self.wndSprintDash:FindChild("DodgeBack1"):SetBGColor("AA000000")
		
		PotatoLib:SetBarVars("Dodge2", self.wndSprintDash, nEvadeCurr-100, 100)
		PotatoLib:SetBarAppearance("Dodge2", self.wndSprintDash, self.texture, nEvadeCurr-100 == 100 and "ffff00" or "ff00dd", 100)
		self.wndSprintDash:FindChild("DodgeBack2"):SetSprite("WhiteFill")
		self.wndSprintDash:FindChild("DodgeBack2"):SetBGColor("AA000000")
	else
		self.wndSprintDash:Show(false)
	end
end

function PotatoSprint:EditorModeToggle(bState)
	bEditorMode = bState
	
	if bEditorMode then
		self.wndCover = Apollo.LoadForm("../PotatoLib/PotatoLib.xml", "EditorCover", self.wndSprintDash, self)
		self.wndCover:SetText("Sprint/Dash")
		--[[if self.border.show then
			self.wndCover:SetAnchorOffsets(self.border.size, self.border.size, -self.border.size, -self.border.size)
		else]]--
			self.wndCover:SetAnchorOffsets(2,2,-2,-2)--self.wndCover:SetAnchorOffsets(0,0,0,0)
		--end
		self.wndSprintDash:Show(true)
	else
		self.wndCover:Destroy()
		self.wndCover = nil
		if self.wndEditor then
			self.wndEditor:Destroy()
			self.wndEditor = nil
		end
	end
	self.wndSprintDash:SetStyle("Moveable", bEditorMode)
	self.wndSprintDash:SetStyle("Sizable", bEditorMode)
end


function PotatoSprint:OnResetBtn()
	self:Reset()
end

function PotatoSprint:OnSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	local wndTarget = self.wndSprintDash
		
	self:PopulateEditor(wndTarget)
end

function PotatoSprint:OnLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:HandleLockedWnd(wndHandler)
end

function PotatoSprint:Reset()
	self.wndSprintDash:SetAnchorPoints(0.5, 0.7, 0.5, 0.7)
	self.wndSprintDash:SetAnchorOffsets(-100, -15 - 65, 100, 15 - 65)
	showFrame = 1
	self.texture = "Aluminum"
end

function PotatoSprint:OnSave(eLevel)
    -- create a table to hold our data
    local tSave = {}

	-- Save target location
	
	local a,b,c,d = self.wndSprintDash:GetAnchorPoints()
	local e,f,g,h = self.wndSprintDash:GetAnchorOffsets()
	tSave = { points = {a,b,c,d}, offsets = {e,f,g,h}, showFrame = showFrame, showFull = showFull }
	tSave.texture = self.texture
		
   	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
        return tSave
    elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData[self.strCharacterName] = tSave
		return self.tAccountData
	else
		return nil
	end
end

function PotatoSprint:OnRestore(eLevel, tData)
	if eLevel == GameLib.CodeEnumAddonSaveLevel.Character then
	   -- just store this and use it later
		self.tSavedData = tData
		
		--Restore Target
	
		if self.tSavedData then
			local savedPoints = self.tSavedData.points
			local savedOffsets = self.tSavedData.offsets
			self.wndSprintDash:SetAnchorPoints(unpack(self.tSavedData.points))
			self.wndSprintDash:SetAnchorOffsets(unpack(self.tSavedData.offsets))
			showFrame = self.tSavedData.showFrame
			showFull = self.tSavedData.showFull
			if self.tSavedData.texture then
				self.texture = self.tSavedData.texture
			end
		end
	elseif eLevel == GameLib.CodeEnumAddonSaveLevel.Account then
		self.tAccountData = tData
	end
end

---------------------------------------------------------------------------------------------------
-- EditorCover Functions
---------------------------------------------------------------------------------------------------

function PotatoSprint:OnEditorSettingsBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	self:PopulateEditor(self.wndSprintDash)
	
	self:SelectFrame(self.wndSprintDash)
end

function PotatoSprint:OnEditorLockBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	PotatoLib:HandleLockedWnd(self.wndSprintDash, "SprintDash")
end

function PotatoSprint:OnEditorResetBtn( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	self:Reset()
end

function PotatoSprint:EditorSelectWindow( wndHandler, wndControl, eMouseButton, nLastRelativeMouseX, nLastRelativeMouseY, bDoubleClick, bStopPropagation )
	if wndHandler ~= wndControl then return end
	
	if bEditorMode then
		if eMouseButton == 1 then --Right-clicked
			self:PopulateEditor(self.wndSprintDash)
		end
		self:SelectFrame(self.wndSprintDash)
	end
end

---------------------------------------------------------------------------------------------------
-- SprintDash Functions
---------------------------------------------------------------------------------------------------

function PotatoSprint:MouseDownTest(wndHandler, wndControl, eButton, x, y, bDouble)
	local elementName = wndControl:GetName()

	if wndHandler:GetName() == "Form1" and elementName == "Content" and bEditorMode then
		--self:PopulateEditor(wndHandler, wndControl)
		self:SelectFrame(wndHandler,wndControl)
	end
end


function PotatoSprint:SelectFrame(wndHandler)
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib:ElementSelected(wndHandler, self, true)
	
	if PLib.wndCustomize:IsVisible() then
		self:PopulateEditor(wndHandler)
	end
end

function PotatoSprint:PopulateEditor(wndHandler, wndControl)
	local PLib = Apollo.GetAddon("PotatoLib")
	PLib.wndCustomize:Show(true)
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren()
	PLib:ElementSelected(wndHandler, self)
	
	self.wndCustomize = Apollo.LoadForm("PotatoSprint.xml", "SprintDashCustomize", PLib.wndCustomize:FindChild("EditorContent"), self) --Ghetto fix.
	PLib.wndCustomize:FindChild("EditorContent"):DestroyChildren() --Oh well.
	
	--Populate PotatoLib editor frame; Set title
	self.wndCustomize = Apollo.LoadForm("PotatoSprint.xml", "SprintDashCustomize", PLib.wndCustomize:FindChild("EditorContent"), self)
	PLib.wndCustomize:FindChild("Title"):SetText("Sprint/Dash Settings")
	
	self.wndCustomize:FindChild("ShowFrame"):FindChild("Options"):SetRadioSel("ShowFrame", showFrame)
	self.wndCustomize:FindChild("ShowFull"):FindChild("Options"):SetRadioSel("ShowFull", showFull)
	
	PotatoLib:SetSprite(self.wndCustomize:FindChild("BarTexture"):FindChild("CurrentVal"),self.texture)
	self.wndCustomize:FindChild("BarTexture"):FindChild("CurrentVal"):SetText(self.texture == "WhiteFill" and "Flat" or self.texture)
	--self.wndCustomize:FindChild("BarTexture"):FindChild("CurrentVal"):SetBGColor("FF"..tCurrBarData.color)

	local nX1, nY1, nX2, nY2 = wndHandler:GetAnchorOffsets()
	local nAX1, nAY1, nAX2, nAY2 = wndHandler:GetAnchorPoints()
	
	local nScreenX, nScreenY = Apollo.GetScreenSize()
	if self.wndCustomize then
		if self.wndCustomize:FindChild("XPos") ~= nil then
			local PLib = Apollo.GetAddon("PotatoLib")
			if PLib.bPositionCenter then
				nAX1 = nAX1-0.5
				nAY1 = nAY1-0.5
			end
			self.wndCustomize:FindChild("XPos"):SetText(math.floor((nAX1*nScreenX)+nX1))
			self.wndCustomize:FindChild("YPos"):SetText(math.floor((nAY1*nScreenY)+nY1))
			self.wndCustomize:FindChild("Width"):SetText(nX2-nX1)
			self.wndCustomize:FindChild("Height"):SetText(nY2-nY1)
		end
	end
end

function PotatoSprint:OnShowChange( wndHandler, wndControl, eMouseButton )
	local nShowFrame = wndHandler:GetParent():GetRadioSel("ShowFrame") --1 = Always; 2 = Combat; 3 = Never
	
	showFrame = nShowFrame
end

function PotatoSprint:OnFullChange( wndHandler, wndControl, eMouseButton )
	local nShowFull = wndHandler:GetParent():GetRadioSel("ShowFull") --1 = Always; 2 = Combat; 3 = Never
	
	showFull = nShowFull
end

function PotatoSprint:BarTextureScroll( wndHandler, wndControl )
	local ktTextures = PotatoLib.ktTextures
	local wndTarget = self.wndSprintDash
	
	local nCurrBar = ktTextures[self.texture]

	if wndHandler:GetName() == "RightScroll" then
		nCurrBar = nCurrBar == #ktTextures and 1 or (nCurrBar + 1)
	elseif wndHandler:GetName() == "LeftScroll" then
		nCurrBar = nCurrBar == 1 and #ktTextures or (nCurrBar - 1)
	end
	
	local strTexture = ktTextures[nCurrBar]
	
	--Set bar texture
	PotatoLib:SetBarSprite(wndTarget:FindChild("Sprint"), strTexture)
	PotatoLib:SetBarSprite(wndTarget:FindChild("Dodge1"), strTexture)
	PotatoLib:SetBarSprite(wndTarget:FindChild("Dodge2"), strTexture)
	
	--Set data value
	self.texture = strTexture
	
	--Set editor window
	wndHandler:GetParent():FindChild("CurrentVal"):SetSprite(strTexture)
	wndHandler:GetParent():FindChild("CurrentVal"):SetText(nCurrBar == ktTextures["WhiteFill"] and "Flat" or strTexture)
end

function PotatoSprint:WindowMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	PotatoLib:WindowMove(wndHandler)
end

function PotatoSprint:TxtPositionChanged( wndHandler, wndControl, strPos )
	local strChange = wndHandler:GetName()
	
	local wndTarget = self.wndSprintDash
	
	if wndTarget ~= nil then	
		local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()
		local nAX1, nAY1, nAX2, nAY2 = wndTarget:GetAnchorPoints()
	
		local nWidth = nX2-nX1
		local nHeight = nY2-nY1
		local nScreenX, nScreenY = Apollo.GetScreenSize()
		
		local PLib = Apollo.GetAddon("PotatoLib")
		if PLib.bPositionCenter then
			nAX1 = nAX1-0.5
			nAX2 = nAX2-0.5
			nAY1 = nAY1-0.5
			nAY2 = nAY2-0.5
		end
		
		strPos = string.gsub(strPos, "[^\-0-9]", "")
		if #strPos > 1 and string.sub(strPos, 1, 1) == "0" then
			strPos = string.gsub(strPos, "0", "", 1)
		end
		
		if strPos == "" then
			strPos = "0"
		end
		
		if strPos ~= "-" then
			if strChange == "XPos" then
				wndTarget:SetAnchorOffsets(strPos-(nAX1*nScreenX), nY1, strPos-(nAX2*nScreenX)+nWidth, nY2)
			elseif strChange == "YPos" then
				wndTarget:SetAnchorOffsets(nX1, strPos-(nAY1*nScreenY), nX2, strPos-(nAY2*nScreenY)+nHeight)
			end
			PLib:MoveLockedWnds(wndTarget)
		end

		wndHandler:SetText(strPos)
		wndHandler:SetSel(#strPos,#strPos)
	end
end

function PotatoSprint:TxtHWChanged( wndHandler, wndControl, strHW )

	local strChange = wndHandler:GetName()
	
	local wndTarget = self.wndSprintDash
	
	local nX1, nY1, nX2, nY2 = wndTarget:GetAnchorOffsets()

	strHW = string.gsub(strHW, "[^0-9]", "")
	if #strHW > 0 and string.sub(strHW, 1, 1) == "0" then
		strHW = string.gsub(strHW, "0", "", 1)
	end
	
	if strHW == "" then
		strHW = "0"
	end	
		
	if strChange == "Width" then
		wndTarget:SetAnchorOffsets(nX1, nY1, nX1+strHW, nY2)
	elseif strChange == "Height" then
		wndTarget:SetAnchorOffsets(nX1, nY1, nX2, nY1+strHW)
	end	
		
	wndHandler:SetText(strHW)
	wndHandler:SetSel(#strHW,#strHW)
end
-----------------------------------------------------------------------------------------------
-- PotatoSprint Instance
-----------------------------------------------------------------------------------------------
local PotatoSprintInst = PotatoSprint:new()
PotatoSprintInst:Init()
