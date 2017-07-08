local Builder = Apollo.GetAddon("Builder")
local L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("Builder", true)

function Builder:IsAbilitiesOpen()
	if self.abilitiesAddon ~= nil then
		if self.abilitiesAddon.tWndRefs.wndMain ~= nil and self.abilitiesAddon.tWndRefs.wndMain:IsShown() then
			return true
		else
			return false
		end
	else
		return false
	end
end

function Builder:GetAddonHook(addon)
	local tAddon = cAddons
	for i=1,#tAddon do
		local aCheckAddon = Apollo.GetAddon(tAddon[i])
		if aCheckAddon ~= nil then
			return aCheckAddon
		else
			return nil
		end
	end
end

function Builder.ResetSpellTiers()
	for key, ability in ipairs(AbilityBook.GetAbilitiesList()) do
		if ability.bIsActive and ability.nCurrentTier > 1 then
			AbilityBook.UpdateSpellTier(ability.nId, 1)
		end
	end
end

-----------------------------------------------------------------------------------------------
-- SetName Functions
-----------------------------------------------------------------------------------------------
-- SetBuildName : Validate the build name
function Builder:SetBuildName(sBuildName, nBuildId)

    local sBuildName = sBuildName

	if sBuildName == nil then sBuildName = L["BUILD"] .. nBuildId end
 	sBuildName = sBuildName:match("^%s*(.-)%s*$")

	for _,oBuild in pairs(self.builds) do

		if oBuild.name ~= nil  then

			local sNickName = oBuild.name
	   		local nNickName = string.len(sNickName)
	 		local nLen = string.len(sBuildName)
	    	local nMatchName = string.find(sNickName, sBuildName)

	    	if nNickName == nLen and nMatchName ~= nil then

				sNickName = " "
	    	end
		end
	end

	self.builds[nBuildId].name = sBuildName

	return sBuildName
end
-- SetBuildName : Validate the tag name
function Builder:SetTagName(sTagName, nTagId)
	local sTagName = sTagName
	if sTagName == nil then sTagName = "Tag " .. nTagId end
 	sTagName = sTagName:match("^%s*(.-)%s*$")

	for _,oTag in pairs(self.config.tags) do

		if oTag ~= nil  then

			local sNickName = oTag
	   		local nNickName = string.len(sNickName)
	 		local nLen = string.len(sTagName)
	    	local nMatchName = string.find(sNickName, sTagName)

	    	if nNickName == nLen and nMatchName ~= nil then
				sNickName = " "
	    	end
		end
	end

	self.config.tags[nTagId] = sTagName 

	return sTagName
end


-----------------------------------------------------------------------------------------------
-- Utils Functions
-----------------------------------------------------------------------------------------------
function Builder:ToMap(list, defaultValue)
	local map = {}
	for key, value in ipairs(list) do
		map[value] = defaultValue or key
	end
	return map
end

function Builder:TableLength(tTable)
	if tTable == nil then return 0 end
  	local count = 0
  	for _ in pairs(tTable) do count = count + 1 end
  	return count
end

function Builder:DeepCopy(t)
	if type(t) == "table" then
		local copy = {}
		for k, v in next, t do
			copy[self:DeepCopy(k)] = self:DeepCopy(v)
		end
		return copy
	else
		return t
	end
end

function Builder:Extend(...)
	local args = {...}
	for i = 2, #args do
		for key, value in pairs(args[i]) do
			args[1][key] = value
		end
	end
	return args[1]
end

function Builder:TableSet(t)
	local u = { }
	for _, v in ipairs(t) do u[v] = true end
	return u
end

function Builder:TableFind(t, f, findIndex)
	for _, v in ipairs(t) do
		if f(v) then
			if not findIndex then
				return v
			else
				return _
			end
		end
	end
	return nil
end

function Builder:print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            Print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        Print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        Print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        Print(indent.."["..pos..'] => "'..val..'"')
                    else
                        Print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                Print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        Print(tostring(t).." {")
        sub_print_r(t,"  ")
        Print("}")
    else
        sub_print_r(t,"  ")
    end
    Print()
end

