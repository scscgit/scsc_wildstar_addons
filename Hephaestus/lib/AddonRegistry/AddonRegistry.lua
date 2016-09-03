-----------------------------------------------------------------------------------------------
-- Registration package for Addons containing multiple files that usually don't register separately
-- Copyright (c) DoctorVanGogh on Wildstar forums
-----------------------------------------------------------------------------------------------

local MAJOR,MINOR = "DoctorVanGogh:Lib:AddonRegistry", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

local AddonRegistry = APkg and APkg.tPackage or {}

AddonRegistry.addons = AddonRegistry.addons or {}

local function FormatKey(strContainer, strName)
	if not strContainer then
		error("AddonRegistry - strContainer is not defined")
		return
	elseif type(strContainer) ~= "string" then
		error("AddonRegistry - strContainer is not a string")
		return
	end	

	if not strName then
		error("AddonRegistry - strName is not defined")
		return
	elseif type(strContainer) ~= "string" then
		error("AddonRegistry - strName is not a string")
		return		
	end	

	return string.format("%s:%s", strContainer, strName)
end

function AddonRegistry:RegisterAddon(tAddon, strContainer, strName)
	 
	self.addons[FormatKey(strContainer, strName)] = tAddon
end

function AddonRegistry:GetAddon(strContainer, strName)
	return self.addons[FormatKey(strContainer, strName)]
end

function AddonRegistry:GetAddons()
	return self.addons
end

Apollo.RegisterPackage(AddonRegistry, MAJOR, MINOR, {})