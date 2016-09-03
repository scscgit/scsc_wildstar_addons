-----------------------------------------------------------------------------------------------
-- Loop.collection.OrderedSet module repackaged for Wildstar by DoctorVanGogh
-----------------------------------------------------------------------------------------------
local MAJOR,MINOR = "DoctorVanGogh:Lib:Loop:Collection:OrderedSet", 1

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
-- Title  : Ordered Set Optimized for Insertions and Removals                 --
-- Author : Renato Maia <maia@inf.puc-rio.br>                                 --
--------------------------------------------------------------------------------
-- Notes:                                                                     --
--   Storage of strings equal to the name of one method prevents its usage.   --
--------------------------------------------------------------------------------

local oo   = Apollo.GetPackage("DoctorVanGogh:Lib:Loop:Base").tPackage 

--------------------------------------------------------------------------------
-- key constants ---------------------------------------------------------------
--------------------------------------------------------------------------------

local FIRST = newproxy()
local LAST = newproxy()

local package = APkg and APkg.tPackage or {}

oo.class(package)
--------------------------------------------------------------------------------
-- basic functionality ---------------------------------------------------------
--------------------------------------------------------------------------------

local function iterator(self, previous)
	return self[previous], previous
end

local function sequence(self)
	return iterator, self, FIRST
end

local function contains(self, element)
	return element ~= nil and (self[element] ~= nil or element == self[LAST])
end

local function first(self)
	return self[FIRST]
end

local function last(self)
	return self[LAST]
end

local function empty(self)
	return self[FIRST] == nil
end

local function insert(self, element, previous)
	if element ~= nil and not contains(self, element) then
		if previous == nil then
			previous = self[LAST]
			if previous == nil then
				previous = FIRST
			end
		elseif not contains(self, previous) and previous ~= FIRST then
			return
		end
		if self[previous] == nil
			then self[LAST] = element
			else self[element] = self[previous]
		end
		self[previous] = element
		return element
	end
end

local function previous(self, element, start)
	if contains(self, element) then
		local previous = (start == nil and FIRST or start)
		repeat
			if self[previous] == element then
				return previous
			end
			previous = self[previous]
		until previous == nil
	end
end

local function remove(self, element, start)
	local prev = previous(self, element, start)
	if prev ~= nil then
		self[prev] = self[element]
		if self[LAST] == element
			then self[LAST] = prev
			else self[element] = nil
		end
		return element, prev
	end
end

local function replace(self, old, new, start)
	local prev = previous(self, old, start)
	if prev ~= nil and new ~= nil and not contains(self, new) then
		self[prev] = new
		self[new] = self[old]
		if old == self[LAST]
			then self[LAST] = new
			else self[old] = nil
		end
		return old, prev
	end
end

local function pushfront(self, element)
	if element ~= nil and not contains(self, element) then
		if self[FIRST] ~= nil
			then self[element] = self[FIRST]
			else self[LAST] = element
		end
		self[FIRST] = element
		return element
	end
end

local function popfront(self)
	local element = self[FIRST]
	self[FIRST] = self[element]
	if self[FIRST] ~= nil
		then self[element] = nil
		else self[LAST] = nil
	end
	return element
end

local function pushback(self, element)
	if element ~= nil and not contains(self, element) then
		if self[LAST] ~= nil
			then self[ self[LAST] ] = element
			else self[FIRST] = element
		end
		self[LAST] = element
		return element
	end
end

--------------------------------------------------------------------------------
-- function aliases ------------------------------------------------------------
--------------------------------------------------------------------------------

-- set operations
local add = pushback

-- stack operations
local push = pushfront
local pop = popfront
local top = first

-- queue operations
local enqueue = pushback
local dequeue = popfront
local head = first
local tail = last

local firstkey = FIRST


package.sequence = sequence
package.contains = contains
package.first = first
package.last = last
package.empty = empty
package.insert = insert
package.previous = previous
package.remove = remove
package.replace = replace
package.pushfront = pushfront
package.popfront = popfront
package.pushback = pushback
package.add = add
package.push = push
package.pop = pop
package.top = top
package.enqueue = enqueue
package.dequeue = dequeue
package.head = head
package.tail = tail
package.firstkey = firstkey

Apollo.RegisterPackage(package, MAJOR, MINOR, {})
