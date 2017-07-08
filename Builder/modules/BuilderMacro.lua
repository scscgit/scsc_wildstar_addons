local Builder = Apollo.GetAddon("Builder")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Builder", true)

function Builder:OnMacroBeginDragDrop(wndHandler, wndControl, x, y, bDragDropStarted )
	if wndHandler ~= wndControl then return false end
	
	local nBuildId = wndControl:GetParent():GetData()
	local buildToMacro = self.builds[nBuildId]
	if buildToMacro.macro == nil or MacrosLib.GetMacro(buildToMacro.macro) == nil then
		buildToMacro.macro = self:AddMacroToBuild(nBuildId, buildToMacro.name)
	end
	
	Apollo.BeginDragDrop(wndControl, "DDMacro", wndControl:GetSprite(), buildToMacro.macro)
	return true
end

function Builder:AddMacroToBuild(nBuildId, sMacroName)
	
	local tParam = {
					sName = "Builder - " .. sMacroName,
					sSprite = "IconSpritesIconSprites:Icon_ItemMisc_Nesting_Bag_07",
					sCmds = "/builder " .. sMacroName,
					bGlobal = false,
					nId = MacrosLib.CreateMacro(),
				   }
				   
	self:SaveMacro(tParam)
	return tParam.nId
	
end

function Builder:SaveMacro(tParam)
	MacrosLib.SetMacroData( tParam.nId, tParam.bGlobal, tParam.sName, tParam.sSprite, tParam.sCmds )
    MacrosLib:SaveMacros()
end

function Builder:DeleteMacro(nMacroId)
    if nMacroId == nil then return end  
   
    MacrosLib.DeleteMacro(nMacroId)
 	MacrosLib:SaveMacros()
end