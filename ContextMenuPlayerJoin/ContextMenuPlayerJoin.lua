-----------------------------------------------------------------------------------------------
-- Client Lua Script for ContextMenuPlayerJoin
-----------------------------------------------------------------------------------------------

require "Apollo"
require "GameLib"
require "GroupLib"

local ContextMenuPlayerJoin = {}

function ContextMenuPlayerJoin:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self

	return o
end

function ContextMenuPlayerJoin:Init()
	Apollo.RegisterAddon(self)
end

function ContextMenuPlayerJoin:OnLoad()
	self.crb = Apollo.GetAddon("ContextMenuPlayer")
	if self.crb ~= nil then
		self:ContextMenuAdd()
	end
end

function ContextMenuPlayerJoin:ContextMenuAdd()
	-- Add an extra button to the player context menu
    local oldRedrawAll = self.crb.RedrawAll
    self.crb.RedrawAll = function(context)
		if ( self.crb.unitTarget == nil or self.crb.unitTarget ~= GameLib.GetPlayerUnit() ) and not GroupLib.InGroup() then
			if self.crb.wndMain ~= nil then
	            local wndButtonList = self.crb.wndMain:FindChild("ButtonList")
	            if wndButtonList ~= nil then
	                local wndNew = wndButtonList:FindChildByUserData("BtnGroupJoin")
	                if not wndNew then
	                    wndNew = Apollo.LoadForm(self.crb.xmlDoc, "BtnRegularContainer", wndButtonList, self.crb)
	                    wndNew:SetData("BtnGroupJoin")
	                end
	                wndNew:FindChild("BtnText"):SetText("Join Group")
	            end
	        end
		end
		oldRedrawAll(context)
    end

	-- Add an extra button to the friend context menu
	local oldRedrawAllFriend = self.crb.RedrawAllFriend
    self.crb.RedrawAllFriend = function(context)
		if not GroupLib.InGroup() then
			if self.crb.wndMain ~= nil then
	            local wndButtonList = self.crb.wndMain:FindChild("ButtonList")
	            if wndButtonList ~= nil then
	                local wndNew = wndButtonList:FindChildByUserData("BtnGroupJoin")
	                if not wndNew then
	                    wndNew = Apollo.LoadForm(self.crb.xmlDoc, "BtnRegularContainer", wndButtonList, self.crb)
	                    wndNew:SetData("BtnGroupJoin")
	                end
	                wndNew:FindChild("BtnText"):SetText("Join Group")
	            end
	        end
		end
		oldRedrawAllFriend(context)
    end

    -- catch the event fired when the player clicks the context menu
    local oldContextClick = self.crb.ProcessContextClick
    self.crb.ProcessContextClick = function(context, eButtonType)
        if eButtonType == "BtnGroupJoin" then
			GroupLib.Join(self.crb.strTarget)
        else
            oldContextClick(context, eButtonType)
        end
    end
end


local ContextMenuPlayerJoinInstance = ContextMenuPlayerJoin:new()
ContextMenuPlayerJoinInstance:Init()



