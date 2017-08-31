-----------------------------------------------------------------------------------------------
-- 'PPet' v0.3 [11/11/2016]
-----------------------------------------------------------------------------------------------
 
require "Window"
require "CollectiblesLib"
 
-----------------------------------------------------------------------------------------------
-- PPet Module Definition
-----------------------------------------------------------------------------------------------
local PPet = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function PPet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 
    return o
end

function PPet:Init()
	 Apollo.RegisterAddon(self)
end

-----------------------------------------------------------------------------------------------
-- PPet OnLoad
-----------------------------------------------------------------------------------------------
function PPet:OnLoad()
   	self.xmlDoc = XmlDoc.CreateFromFile("PPet.xml")
	self:Hook_Tooltips()
end

-----------------------------------------------------------------------------------------------
-- Hook_Tooltips
-----------------------------------------------------------------------------------------------
function PPet:Hook_Tooltips()
				
	local aTooltips = Apollo.GetAddon("ToolTips")
	if aTooltips == nil then return end
	
	local origCreateCallNames = aTooltips.CreateCallNames
	aTooltips.CreateCallNames = function(luaCaller)
		origCreateCallNames(luaCaller)
		local origItemTooltip = Tooltip.GetItemTooltipForm
		Tooltip.GetItemTooltipForm = function(luaCaller, wndControl, item, bStuff, nCount)
		
		   	local nPreviewCreatureId = nil
			if item ~= nil then nPreviewCreatureId = self:_IsPet(item:GetName()) end
			if (item ~= nil) and  (nPreviewCreatureId ~= nil) then
			
				wndControl:SetTooltipDoc(nil)
										
				local wndTooltip, wndTooltipComp = origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
				local wndPetPreview = Apollo.LoadForm(self.xmlDoc, "PetPreview_Wnd", wndTooltip, self)
							
    			wndPetPreview:FindChild("Preview_Wnd"):SetCostumeToCreatureId(nPreviewCreatureId)
    			wndPetPreview:FindChild("Preview_Wnd"):SetModelSequence(150)

				local nWidth = wndTooltip:GetWidth()
				local nHeight = wndTooltip:GetHeight()
				local l,t,r,b = wndPetPreview:GetAnchorOffsets()
				wndPetPreview:Move(l - 20, nHeight - 20, nWidth + 42, nHeight + b)
				
				return wndTooltip, wndTooltipComp
			else
				return origItemTooltip(luaCaller, wndControl, item, bStuff, nCount)
			end
		end
	end
end 

-----------------------------------------------------------------------------------------------
-- IsPet
-----------------------------------------------------------------------------------------------
function PPet:_IsPet(sItemName)

	local arPetList = CollectiblesLib.GetVanityPetList()
	for idx = 1, #arPetList do
		local tPetInfo = arPetList[idx]
		if tPetInfo.strName == sItemName then 
			return tPetInfo.nPreviewCreatureId 
		end
	end		
	return nil	
end

-----------------------------------------------------------------------------------------------
-- PPet Instance
-----------------------------------------------------------------------------------------------
local PPetInst = PPet:new()
PPetInst:Init()
