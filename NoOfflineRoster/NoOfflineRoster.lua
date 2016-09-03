-----------------------------------------------------------------------------------------------
-- Client Lua Script for NoOfflineRoster
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- NoOfflineRoster Module Definition
-----------------------------------------------------------------------------------------------
NoOfflineRoster = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("NoOfflineRoster", false, {"GuildContentRoster", "Circles", "Gemini:Hook-1.0"}, "Gemini:Hook-1.0")


-----------------------------------------------------------------------------------------------
-- NoOfflineRoster OnLoad
-----------------------------------------------------------------------------------------------
function NoOfflineRoster:OnInitialize()
    --local GeminiHook = Apollo.GetPackage("Gemini:Hook-1.0").tPackage
    self.GuildRoster = Apollo.GetAddon("GuildContentRoster")
    
    self:PostHook(self.GuildRoster, "Initialize", "OnReady")
    self.xml = XmlDoc.CreateFromFile("NoOfflineRoster.xml")
	
	self.Circles = Apollo.GetAddon("Circles")
	self:PostHook(self.Circles, "OnGenericEvent_InitializeCircles", "OnReadyCircles")

end

function NoOfflineRoster:OnReady() 
	--Print("GuildRoster Ready!")
    self.GuildRoster.config = self.GuildRoster.config or {showOffline = false}
    self.GuildRoster.wndCheckbox = Apollo.LoadForm(self.xml, "InsertForm", self.GuildRoster.tWndRefs.wndMain:FindChild("RosterBottom"), self.GuildRoster)
    --self.GuildRoster.wndCheckbox:SetCheck(self.GuildRoster.config.showOffline)
	self.GuildRoster.wndCheckbox:FindChild("Text"):SetText("Show\nOffline")

    self.GuildRoster.BuildRosterList = function(self, guildCurr, tRoster)
	if self.tWndRefs.wndMain == nil or not self.tWndRefs.wndMain:IsValid() or not self.tWndRefs.wndMain:GetData() then
		return
	end
	
	if not guildCurr or tRoster == nil or #tRoster == 0 then
		return
	end

	local tRanks = guildCurr:GetRanks()
	if tRanks == nil then
		return --New guild and we have not yet recieved the data
	end

    local showOfflineCheck = self.tWndRefs.wndMain:FindChild("RosterBottom:InsertForm:showOffline")
    showOfflineCheck:SetCheck(self.config.showOffline)

    local wndGrid = self.tWndRefs.wndMain:FindChild("RosterGrid")
    wndGrid:DeleteAll() -- TODO remove this for better performance eventually

    for key, tCurr in pairs(tRoster) do
        local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
        if tCurr.nRank == 1 then -- Special icons for guild leader and council (TEMP Placeholder)
            strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
        elseif tCurr.nRank == 2 then
            strIcon = "CRB_Basekit:kitIcon_Holo_Actions"
        end

        local strRank = Apollo.GetString("Circles_UnknownRank")
        if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
            strRank = tRanks[tCurr.nRank].strName
        end

        if not self.strPlayerName then
            self.strPlayerName = GameLib.GetPlayerUnit():GetName()
        end

        if self.strPlayerName == tCurr.strName then
            self.tWndRefs.wndMain:FindChild("EditNotesEditbox"):SetText(tCurr.strNote)
        end
        
        local strTextColor = "ffffffff"
        if tCurr.fLastOnline ~= 0 then -- offline
            strTextColor = "9d9d9d9d"
        end
        
        
        if tCurr.fLastOnline == 0 or self.config.showOffline then
            local iCurrRow = wndGrid:AddRow("")
            wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
            wndGrid:SetCellImage(iCurrRow, 1, strIcon)
            wndGrid:SetCellDoc(iCurrRow, 2, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..tCurr.strName.."</T>")
            wndGrid:SetCellDoc(iCurrRow, 3, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..FixXMLString(strRank).."</T>") --temporary fix
            wndGrid:SetCellDoc(iCurrRow, 4, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..tCurr.nLevel.."</T>")
            wndGrid:SetCellDoc(iCurrRow, 5, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..tCurr.strClass.."</T>")
            wndGrid:SetCellDoc(iCurrRow, 6, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..self:HelperConvertPathToString(tCurr.ePathType).."</T>")
            wndGrid:SetCellDoc(iCurrRow, 7, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..self:HelperConvertToTime(tCurr.fLastOnline).."</T>")
            wndGrid:SetCellDoc(iCurrRow, 8, "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">"..FixXMLString(tCurr.strNote).."</T>") --temporary fix
            wndGrid:SetCellLuaData(iCurrRow, 8, String_GetWeaselString(Apollo.GetString("GuildRoster_ActiveNoteTooltip"), tCurr.strName, string.len(tCurr.strNote) > 0 and tCurr.strNote or "N/A")) -- For tooltip
        end
    end

    self.tWndRefs.wndMain:FindChild("AddMemberYesBtn"):SetData(self.tWndRefs.wndMain:FindChild("AddMemberEditBox"))
    self.tWndRefs.wndMain:FindChild("AddMemberEditBox"):SetData(self.tWndRefs.wndMain:FindChild("AddMemberEditBox")) -- Since they have the same event handler
    self.tWndRefs.wndMain:FindChild("RosterHeaderContainer"):SetData(tRoster)

    self:ResetRosterMemberButtons()
    end --function end


    -- load our form file
    
    self.GuildRoster.OnCheckboxChange = function (self, wndHandler, wndControl, eMouseButton)
    self.config[wndControl:GetName()] = wndControl:IsChecked()    
    self:BuildRosterList(self.tWndRefs.wndMain:GetData(), self:SortRoster(self.tWndRefs.wndMain:FindChild("RosterHeaderContainer"):GetData(), "RosterSortBtnName"))
    end
    --self:Unhook(self.GuildRoster, "Initialize")
    --self.xml = nil

end

function NoOfflineRoster:OnReadyCircles()  
--Print("Ready Cirles!") 
    self.Circles.config = self.Circles.config or {showOffline = false}
    --self.Circles.wndCheckbox = (self.Circles.wndCheckbox and self.Circles.wndCheckbox:IsValid() and self.Circles.wndCheckbox) or Apollo.LoadForm(self.xml, "InsertForm", self.Circles.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom"), self.Circles)
	--self.Circles.wndCheckbox:FindChild("Text"):SetText("Show\nOffline")
	self.Circles.XmlCheckbox = self.xml

    self.Circles.BuildRosterList = function(self, guildCurr, tRoster)
	if not guildCurr or #tRoster == 0 then
		return
	end


	self.wndCheckbox = (self.wndCheckbox and self.wndCheckbox:IsValid() and self.wndCheckbox) or Apollo.LoadForm(self.XmlCheckbox, "InsertForm", self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom"), self)
	self.wndCheckbox:FindChild("Text"):SetText("Show\nOffline")
	self.wndCheckbox:FindChild("showOffline"):SetCheck(self.config.showOffline)
	
	local tRanks = guildCurr:GetRanks()
	local wndGrid = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterGrid")
	wndGrid:DeleteAll() -- TODO remove this for better performance eventually

	for key, tCurr in pairs(tRoster) do
		local strIcon = "CRB_DEMO_WrapperSprites:btnDemo_CharInvisibleNormal"
		if tCurr.nRank == 1 then -- Special icons for guild leader and council (TEMP Placeholder)
			strIcon = "CRB_Basekit:kitIcon_Holo_Profile"
		elseif tCurr.nRank == 2 then
			strIcon = "CRB_Basekit:kitIcon_Holo_Actions"
		end

		local strRank = Apollo.GetString("Circles_UnknownRank")
		if tRanks[tCurr.nRank] and tRanks[tCurr.nRank].strName then
			strRank = tRanks[tCurr.nRank].strName
		end

		local strTextColor = "UI_TextHoloBodyHighlight"
		if tCurr.fLastOnline ~= 0 then -- offline
			strTextColor = "UI_BtnTextGrayNormal"
		end
		
        if tCurr.fLastOnline == 0 or self.config.showOffline then
			local iCurrRow = wndGrid:AddRow("")
			wndGrid:SetCellLuaData(iCurrRow, 1, tCurr)
			wndGrid:SetCellImage(iCurrRow, 1, strIcon)
			wndGrid:SetCellDoc(iCurrRow, 2, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tCurr.strName))
			wndGrid:SetCellDoc(iCurrRow, 3, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, strRank))
			wndGrid:SetCellDoc(iCurrRow, 4, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tCurr.nLevel))
			wndGrid:SetCellDoc(iCurrRow, 5, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, tCurr.strClass))
			wndGrid:SetCellDoc(iCurrRow, 6, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, self:HelperConvertPathToString(tCurr.ePathType)))
			wndGrid:SetCellDoc(iCurrRow, 7, string.format("<T Font=\"CRB_InterfaceSmall\" TextColor=\"%s\">%s</T>", strTextColor, self:HelperConvertToTime(tCurr.fLastOnline)))
		end
	end
	local wndAddContainer = self.tWndRefs.wndMain:FindChild("RosterScreen:RosterBottom:RosterOptionBtnAdd:AddMemberContainer")
	local wndAddMemberEditBox = wndAddContainer:FindChild("AddMemberEditBox")
	wndAddContainer:FindChild("AddMemberYesBtn"):SetData(wndAddMemberEditBox)
	wndAddMemberEditBox:SetData(wndAddMemberEditBox) -- Since they have the same event handler
	self.tWndRefs.wndMain:FindChild("RosterScreen:RosterHeaderContainer"):SetData(tRoster)

	self:ResetRosterMemberButtons()

    end --function end


    -- load our form file
    
    self.Circles.OnCheckboxChange = function (self, wndHandler, wndControl, eMouseButton) --check this
    self.config[wndControl:GetName()] = wndControl:IsChecked()    
    self:BuildRosterList(self.tWndRefs.wndMain:GetData(), self:SortRoster(self.tWndRefs.wndMain:FindChild("RosterScreen:RosterHeaderContainer"):GetData(), "RosterSortBtnName"))
    end
    --self:Unhook(self.GuildRoster, "Initialize")
    --self.xml = nil

end