-----------------------------------------------------------------------------------------------
-- Loop.collection.ObjectCache module repackaged for Wildstar by DoctorVanGogh
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Lib:Loop:Collection:ObjectCache", 1

-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion or 0) >= MINOR then
	return -- no upgrade needed
end

--------------------------------------------------------------------------------
---------------------- ##       #####    #####   ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##   ## -----------------------
---------------------- ##      ##   ##  ##   ##  ######  -----------------------
---------------------- ##      ##   ##  ##   ##  ##      -----------------------
---------------------- ######   #####    #####   ##      -----------------------
----------------------                                   -----------------------
----------------------- Lua Object-Oriented Programming ------------------------
--------------------------------------------------------------------------------
-- Project: LOOP Class Library                                                --
-- Release: 2.3 beta                                                          --
-- Title  : Cache of Objects Created on Demand                                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Storage of keys 'retrieve' and 'default' are not allowed.                --
--------------------------------------------------------------------------------

local oo   = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage 

local package = APkg and APkg.tPackage or {}

oo.class(package)

local __mode = "k"

local function __index(self, key)
	if key ~= nil then
		local value = rawget(self, "retrieve")
		if value then
			value = value(self, key)
		else
			value = rawget(self, "default")
		end
		rawset(self, key, value)
		return value
	end
end


package.__mode = __mode
package.__index = __index

Apollo.RegisterPackage(package, MAJOR, MINOR, {})