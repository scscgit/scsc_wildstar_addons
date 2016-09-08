-----------------------------------------------------------------------------------------------
-- CassPkg Definition
-----------------------------------------------------------------------------------------------
local CassPkg = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------
-- CassPkg OnLoad
-----------------------------------------------------------------------------------------------
function CassPkg:OnLoad()
	-- called when all dependencies are loaded
	-- if something has gone wrong, return a string with 
	-- the strError that will be passed to YOUR dependencies
end

function CassPkg:OnDependencyError(strDep, strError)
	-- if you don't care about this dependency, return true.
	-- if you return false, or don't define this function
	-- any Addons/Packages that list you as a dependency
	-- will also receive a dependency error
	return false
end

-----------------------------------------------------------------------------------------------
-- CassPkg functions
-----------------------------------------------------------------------------------------------

function CassPkg.round(num, idp)
  	local mult = 10^(idp or 0)
  	return math.floor(num * mult + 0.5) / mult
end

function CassPkg.spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function CassPkg.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CassPkg.deepcopy(orig_key)] = CassPkg.deepcopy(orig_value)
        end
        setmetatable(copy, CassPkg.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function CassPkg.trim(s)
	if s == nil then
		return ""
	end
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- p - percent, p = 100% then fromColor, p = 0% then toColor
function CassPkg.gradient (from, to, p)
	if from == to then
		return from
	end

	-- calculate hsv	
    local R,G,B,A = CassPkg.hex2rgb(from)
	local fH,fS,fV,fA = CassPkg.rgb2hsv(R,G,B,A)
	R,G,B,A = CassPkg.hex2rgb(to)
	local tH,tS,tV,tA = CassPkg.rgb2hsv(R,G,B,A)
 
	-- perform a simple linear conversion
	local H = fH * p + tH * (1-p)
	local S = fS * p + tS * (1-p)
	local V = fV * p + tV * (1-p)
	local A = fA * p + tA * (1-p)
	
	-- convert back to rgb
	R,G,B,A = CassPkg.hsv2rgb(H, S, V, A)
    return CassPkg.rgb2hex(R,G,B,A)
end

function CassPkg.rgb2hsv(r, g, b, a)
  r, g, b, a = r / 255, g / 255, b / 255, a / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then s = 0 else s = d / max end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
    h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, v, a
end

function CassPkg.hsv2rgb(h, s, v, a)
  local r, g, b
  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);
  i = i % 6
  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end
  return r * 255, g * 255, b * 255, a * 255
end

function CassPkg.hex2rgb (hexColor)
 	local hex = hexColor:gsub("#","")
	local a = tonumber("0x"..hex:sub(1,2))
	local r = tonumber("0x"..hex:sub(3,4))
	local g = tonumber("0x"..hex:sub(5,6))
	local b = tonumber("0x"..hex:sub(7,8))
	return r,g,b,a
end

function CassPkg.rgb2hex (r, g, b, a)
	local rh = string.format("%02x",r)
	local gh = string.format("%02x",g)
	local bh = string.format("%02x",b)
	local ah = string.format("%02x",a)
	return ah .. rh .. gh .. bh
end

function CassPkg.convertCColorToString(c)
	return string.format("%02x%02x%02x%02x", math.floor(c.a * 255 + 0.5), math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end

function CassPkg.convertStringToCColor(s)
	local a = tonumber(string.sub(s,1,2), 16)
	local r = tonumber(string.sub(s,3,4), 16)
	local g = tonumber(string.sub(s,5,6), 16)
	local b = tonumber(string.sub(s,7,8), 16)
	return CColor.new(r / 255, g / 255, b / 255, a / 255)
end

function CassPkg.TableLength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function CassPkg.NullToZero(d) 
	if d == nil then
		return 0
	end
	return d
end

-- from http://help.interfaceware.com/kb/112
function CassPkg.SaveTable(Table)
   local savedTables = {} -- used to record tables that have been saved, so that we do not go into an infinite recursion
   local outFuncs = {
      ['string']  = function(value) return string.format("%q",value) end;
      ['boolean'] = function(value) if (value) then return 'true' else return 'false' end end;
      ['number']  = function(value) return string.format('%f',value) end;
      ['userdata']  = function(value) return 'nil' end;
   }
   local outFuncsMeta = {
      __index = function(t,k) error('Invalid Type For SaveTable: '..k ) end      
   }
   setmetatable(outFuncs,outFuncsMeta)
   local tableOut = function(value)
      if (savedTables[value]) then
         error('There is a cyclical reference (table value referencing another table value) in this set.');
      end
      local outValue = function(value) return outFuncs[type(value)](value) end
      local out = '{'
      for i,v in pairs(value) do out = out..'['..outValue(i)..']='..outValue(v)..',' end
      savedTables[value] = true; --record that it has already been saved
      return out..'}'
   end
   outFuncs['table'] = tableOut;
   return CassPkg.enc(tableOut(Table))
end

function CassPkg.LoadTable(Input)
   -- note that this does not enforce anything, for simplicity
   local decoded = CassPkg.dec(Input)
   return assert(loadstring('return '.. decoded ))()
end

-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2
-- encoding
function CassPkg.enc(data)
	local b='0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/-'
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

-- decoding
function CassPkg.dec(data)
	-- character table string
	local b='0123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+/-'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-----------------------------------------------------------------------------------------------
-- CassPkg Instance
-----------------------------------------------------------------------------------------------
Apollo.RegisterPackage(CassPkg, "CassPkg-1.1", 1, {})


