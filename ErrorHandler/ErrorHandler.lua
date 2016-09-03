-----------------------------------------------------------------------------------------------
-- Client Lua Script for ErrorHandler
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- ErrorHandler Module Definition
-----------------------------------------------------------------------------------------------
local ErrorHandler = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ErrorHandler:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here
	self.tErrors = {}
    return o
end

function ErrorHandler:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 
function ErrorHandler:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ErrorHandler.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function ErrorHandler:GetAsyncLoadStatus()
	local luaErrorDialog = Apollo.GetAddon("ErrorDialog")
	if not luaErrorDialog then
		return Apollo.AddonLoadStatus.Loading
	end
	if not luaErrorDialog.wndReportBug then
		return Apollo.AddonLoadStatus.Loading
	end
	Apollo.RemoveEventHandler("LuaError",luaErrorDialog)
	Apollo.RegisterEventHandler("LuaError","OnLuaError",self)
	return Apollo.AddonLoadStatus.Loaded
end

function ErrorHandler:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "ErrorHandlerForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.wndMain:Show(false, true)
		Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded", "OnInterfaceMenuListHasLoaded", self)
		Apollo.RegisterEventHandler("ErrorHandler_InterfaceMenuClick", "ToggleWindow", self)
		Apollo.RegisterSlashCommand("errorhandler","ToggleWindow", self)
	end
end

function ErrorHandler:OnInterfaceMenuListHasLoaded()
	Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "ErrorHandler", {"ErrorHandler_InterfaceMenuClick", "" , "" })
end
-----------------------------------------------------------------------------------------------
-- ErrorHandler Functions
-----------------------------------------------------------------------------------------------

function ErrorHandler:OnLuaError(tAddon, strError, bCanIgnore)
	Print(String_GetWeaselString(Apollo.GetString("LuaError_DebugOutput"), tAddon.strName))
	local tError = {}
	tError.tAddon = tAddon
	tError.strError = strError
	tError.bCanIgnore = bCanIgnore
	tError.tLocalTime = GameLib.GetLocalTime()
	table.insert(self.tErrors, tError)
	self:RedrawWindow()
	self:UpdateInterfaceMenu()
end

function ErrorHandler:UpdateInterfaceMenu()
	local strTooltip
	if #self.tErrors > 0 then
		strTooltip = #self.tErrors .. " Errors"
	end
	Event_FireGenericEvent("InterfaceMenuList_AlertAddOn", "ErrorHandler", { #self.tErrors > 0, strTooltip, #self.tErrors } )
end

function ErrorHandler:RedrawWindow()
	if not self.wndMain and self.wndMain:IsVisible() then
		return
	end
	local wndList = self.wndMain:FindChild("ErrorList")
	wndList:DestroyChildren()
	if #self.tErrors < 1 then
		return
	end
	for k,tError in ipairs(self.tErrors) do
		local wndListEntry = Apollo.LoadForm(self.xmlDoc, "ListEntry",wndList,self)
		wndListEntry:FindChild("Text"):SetText(k..". "..tError.tAddon.strName.." ("..tError.tLocalTime.strFormattedTime..")")
		wndListEntry:SetData(k)
	end
	wndList:ArrangeChildrenVert()
end

function ErrorHandler:ToggleWindow()
	if not self.wndMain then
		return
	end
	if self.wndMain:IsVisible() then
		self.wndMain:Show(false)
		return
	end
	self:RedrawWindow()
	self.wndMain:Show(true)
	self.wndMain:ToFront()
end


function ErrorHandler:CreateCarbineErrorDialog(tAddon,strError,bCanIgnore)
	local luaErrorDialog = Apollo.GetAddon("ErrorDialog")
	if not luaErrorDialog then
		return
	end

	local strMessage = String_GetWeaselString(Apollo.GetString("LuaError_Oops"), tAddon.strName)
	if tAddon.bCarbine then
		strMessage = String_GetWeaselString(Apollo.GetString("LuaError_CarbineAddon"), strMessage)
	else
		strMessage = String_GetWeaselString(Apollo.GetString("LuaError_AddonAuthor"), strMessage, tAddon.strAuthor)
	end

	local strPrompt = ""
	
	luaErrorDialog.wndErrorDialog = Apollo.LoadForm(luaErrorDialog.xmlDoc, "AddonError", nil, luaErrorDialog)
	
	if bCanIgnore then
		strPrompt = Apollo.GetString("LuaError_YouMayIgnore")
	else
		strPrompt = Apollo.GetString("LuaError_AddonSuspended")
		luaErrorDialog.wndErrorDialog:FindChild("Ignore"):SetText(Apollo.GetString("CRB_Close"))
		luaErrorDialog.wndErrorDialog:FindChild("Suspend"):Enable(false)
	end

	luaErrorDialog.wndErrorDialog:FindChild("Message"):SetText(String_GetWeaselString(strPrompt, strMessage))
	local strPartialError = string.sub(strError, 0, 1000)
	luaErrorDialog.wndErrorDialog:FindChild("ErrorText"):SetText(strPartialError)
	luaErrorDialog.wndErrorDialog:FindChild("CopyToClipboard"):SetActionData(GameLib.CodeEnumConfirmButtonType.CopyToClipboard, strPartialError)
	
	if luaErrorDialog.locAddonError then
		luaErrorDialog.wndErrorDialog:MoveToLocation(self.locAddonError)
	end

	luaErrorDialog.wndErrorDialog:SetData(tAddon)

	luaErrorDialog.wndErrorDialog:ToFront()
end

-----------------------------------------------------------------------------------------------
-- ErrorHandler Form Functions
-----------------------------------------------------------------------------------------------

-- when the Cancel button is clicked
function ErrorHandler:OnCloseBtn()
	self.wndMain:Close() -- hide the window
end

function ErrorHandler:OnDetailsButton( wndHandler, wndControl)
	local nError = wndControl:GetParent():GetData()
	if not (nError and self.tErrors[nError]) then
		return
	end
	self:CreateCarbineErrorDialog(self.tErrors[nError].tAddon,self.tErrors[nError].strError,self.tErrors[nError].bCanIgnore)
end

function ErrorHandler:OnIgnoreButton( wndHandler, wndControl)
	local nError = wndControl:GetParent():GetData()
	if not (nError and self.tErrors[nError]) then
		return
	end
	table.remove(self.tErrors,nError)
	self:RedrawWindow()
	self:UpdateInterfaceMenu()
end

function ErrorHandler:OnClearAllErrors( wndHandler, wndControl, eMouseButton )
	self.tErrors = {}
	self:RedrawWindow()
	self:UpdateInterfaceMenu()
end

-----------------------------------------------------------------------------------------------
-- ErrorHandler Instance
-----------------------------------------------------------------------------------------------
local ErrorHandlerInst = ErrorHandler:new()
ErrorHandlerInst:Init()
