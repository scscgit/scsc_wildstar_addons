-----------------------------------------------------------------------------------------------
-- Loop.table module repackaged for Wildstar by DoctorVanGogh
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Lib:Loop:Table", 1

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
-- Project: LOOP - Lua Object-Oriented Programming                            --
-- Release: 2.3 beta                                                          --
-- Title  : General utilities functions for table manipulation                --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- These functions are used in many package implementations and may also be   --
-- usefull in applications.                                                   --
--------------------------------------------------------------------------------

local package = APkg and APkg.tPackage or {}

setmetatable(package, { __index = table })

--------------------------------------------------------------------------------
-- Copies all elements stored in a table into another.

-- Each pair of key and value stored in table 'source' will be set into table
-- 'destiny'.
-- If no 'destiny' table is defined, a new empty table is used.

-- @param source Table containing elements to be copied.
-- @param destiny [optional] Table which elements must be copied into.

-- @return Table containing copied elements.

-- @usage copied = loop.table.copy(results)
-- @usage loop.table.copy(results, newcopy)

local function copy(source, destiny)
	if source then
		if not destiny then destiny = {} end
		for field, value in pairs(source) do
			rawset(destiny, field, value)
		end
	end
	return destiny
end

--------------------------------------------------------------------------------
-- Clears all contens of a table.

-- All pairs of key and value stored in table 'source' will be removed by
-- setting nil to each key used to store values in table 'source'.

-- @param tab Table which must be cleared.
-- @usage return loop.table.clear(results)

local function clear(tab)
	local elem = next(tab)
	while elem ~= nil do
		tab[elem] = nil
		elem = next(tab)
	end
	return tab
end


package.copy = copy
package.clear = clear

Apollo.RegisterPackage(package, MAJOR, MINOR, {})