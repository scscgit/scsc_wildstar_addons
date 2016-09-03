-----------------------------------------------------------------------------------------------
-- Loop.simple module repackaged for Wildstar by DoctorVanGogh
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Lib:Loop:Simple", 2

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
-- Title  : Simple Inheritance Class Model                                    --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Exported API:                                                              --
--   class(class, super)                                                      --
--   new(class, ...)                                                          --
--   classof(object)                                                          --
--   isclass(class)                                                           --
--   instanceof(object, class)                                                --
--   memberof(class, name)                                                    --
--   members(class)                                                           --
--   superclass(class)                                                        --
--   subclassof(class, super)                                                 --
--------------------------------------------------------------------------------

local table = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Table").tPackage

local package = APkg and APkg.tPackage or {}

--------------------------------------------------------------------------------
local ObjectCache = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Collection:ObjectCache").tPackage
local base        = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage
--------------------------------------------------------------------------------
table.copy(base, package)
--------------------------------------------------------------------------------
local DerivedClass = ObjectCache {
	retrieve = function(self, super)
		return base.class { __index = super, __call = base.new }
	end,
}
local function class(class, super)
	if super
		then return DerivedClass[super](base.initclass(class))
		else return base.class(class)
	end
end
--------------------------------------------------------------------------------
local function isclass(class)
	local metaclass = classof(class)
	if metaclass then
		return metaclass == rawget(DerivedClass, metaclass.__index) or
		       base.isclass(class)
	end
end
--------------------------------------------------------------------------------
local function superclass(class)
	local metaclass = base.classof(class)
	if metaclass then return metaclass.__index end
end
--------------------------------------------------------------------------------
local function subclassof(class, super)
	while class do
		if class == super then return true end
		class = superclass(class)
	end
	return false
end
--------------------------------------------------------------------------------
local function instanceof(object, class)
	return subclassof(base.classof(object), class)
end

package.class = class
package.isclass = isclass
package.superclass = superclass
package.subclassof = subclassof
package.instanceof = instanceof

Apollo.RegisterPackage(package, MAJOR, MINOR, {})
