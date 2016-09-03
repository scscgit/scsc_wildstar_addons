require "ChatSystemLib"


local VILib = {}
local pairs, math, type, setmetatable, getmetatable, string, tonumber, unpack = pairs, math, type, setmetatable, getmetatable, string, tonumber, unpack


function VILib:Round(n, nDecimals, bForceDecimals)
	local nMult = 1
	if nDecimals and nDecimals > 0 then
		for i = 1, nDecimals do nMult = nMult * 10 end
	end
	n = math.floor((n * nMult) + 0.5) / nMult
	if bForceDecimals then n = string.format("%." .. nDecimals .. "f", n) end
	return n
end

function VILib:ConvertColorToHex(color)
	return string.format("%02x%02x%02x%02x", self:Round(255 * color.a), self:Round(255 * color.r), self:Round(255 * color.g), self:Round(255 * color.b))
end

function VILib:ConvertARGBColorToHex(color)
	return string.format("%02x%02x%02x%02x", color.a, color.r, color.g, color.b)
end

function VILib:ConvertRGBColorToHex(color)
	return string.format("%02x%02x%02x%02x", 255, color[1], color[2], color[3])
end

function VILib:ConvertRGBColorToCColor(color)
	return color[1] / 255, color[2] / 255, color[3] / 255, 1
end

function VILib:ConvertCColorToARGB(color)
	return {r = self:Round(255 * color.r), g = self:Round(255 * color.g), b = self:Round(255 * color.b), a = self:Round(255 * color.a)}
end

function VILib:ConvertCColorToRGB(color)
	return {self:Round(255 * color.r), self:Round(255 * color.g), self:Round(255 * color.b)}
end

function VILib:ConvertHexToColor(hex)
	local a = string.sub(hex, 1, 2)
	hex = string.sub(hex, -6)
	local r, g, b = 0, 0, 0
	local n = tonumber(hex, 16)
	if n then
		r = math.floor(n / 65536)
		g = math.floor((n / 256) % 256)
		b = n % 256
	end
	return r / 255, g / 255, b / 255, 1
end

function VILib:ConvertRGBToHSV(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max

	local d = max - min
	if max == 0 then s = 0 else s = d / max end

	if max == min then
		h = 0
	else
		if max == r then
			h = (g - b) / d
			if g < b then h = h + 6 end
			elseif max == g then h = (b - r) / d + 2
			elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end

	return {h = h, s = s, v = v}
end

function VILib:ConvertHSVToRGB(h, s, v)
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

	return {r = r * 255, g = g * 255, b = b * 255}
end

function VILib:GetTransitionColorFromHSV(colorA, colorB, fPercent, bAsRGB)
	local h1, s1, v1 = colorA.h, colorA.s, colorA.v
	local h2, s2, v2 = colorB.h, colorB.s, colorB.v
	local h3 = h1 - (h1 - h2) * fPercent
	if math.abs(h1 - h2) > 180 then
		local radius = (360 - math.abs(h1 - h2)) * fPercent
		if h1 < h2 then
			h3 = math.floor(h1 - radius)
			if h3 < 0 then
				h3 = 360 + h3
			end
		else
			h3 = math.floor(h1 + radius)
			if h3 > 360 then
				h3 = h3 - 360
			end
		end
	end  
	local s3 = s1 - (s1 - s2) * fPercent
	local v3 = v1 - (v1 - v2) * fPercent
	if bAsRGB then
		return self:ConvertHSVToRGB(h3, s3, v3)
	end
	return {h = h3, s = s3, v = v3}
end

function VILib:GetTransitionColorFromRGB(colorA, colorB, fPercent)
	local r1, g1, b1 = colorA[1], colorA[2], colorA[3]
	local r2, g2, b2 = colorB[1], colorB[2], colorB[3]
	local r3, g3, b3 = r2 - r1, g2 - g1, b2 - b1
	r3 = self:Round(r1 + (r3 * fPercent))
	g3 = self:Round(g1 + (g3 * fPercent))
	b3 = self:Round(b1 + (b3 * fPercent))
	return {r = r3, g = g3, b = b3}
end

function VILib:CopyTable(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:CopyTable(orig_key)] = self:CopyTable(orig_value)
        end
        setmetatable(copy, self:CopyTable(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function VILib:MergeTables(t1, t2)
    for k, v in pairs(t2) do
    	if type(v) == "table" then
			if t1[k] then
	    		if type(t1[k] or false) == "table" then
	    			self:MergeTables(t1[k] or {}, t2[k] or {})
	    		else
	    			t1[k] = v
	    		end
			else
				t1[k] = {}
    			self:MergeTables(t1[k] or {}, t2[k] or {})
			end
    	else
    		t1[k] = v
    	end
    end
    return t1
end

function VILib:UpperCaseFirstLetter(str, bForceLoverCase)
	local str1 = str:sub(1, 1):upper()
	local str2 = str:sub(2)
	if bForceLoverCase then str2 = str2:lower() end
	return str1 .. str2
end

function VILib:WriteToChat(text)
	if not text then return end
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, text)
end

function VILib:Pack(...)
	return {...}
end

function VILib:GetTableKey(tTable, ID)
	for k, v in pairs(tTable) do
		if ID == v then return k end
	end
	return nil
end

function VILib:GetTableCount(tTable)
	local i = 0
	for k, v in pairs(tTable) do
		i = i + 1
	end
	return i
end

function VILib:AdjustForUIScale(wndRef)
	local fScale = 1 / Apollo.GetConsoleVariable("ui.Scale")
	wndRef:SetScale(fScale)
	fScale = 1 - fScale
	local nOL, nOT, nOR, nOB = wndRef:GetAnchorOffsets()
	local nWidth, nHeight = nOR - nOL, nOB - nOT
	local nOX, nOY = self:Round(math.abs(nWidth * fScale) / 2), self:Round(math.abs(nHeight * fScale) / 2)
	wndRef:SetAnchorOffsets(nOL - nOX, nOT - nOY, nOR - nOX, nOB - nOY)
end

VILib.tAnchors = {
	{sLabel = "Center", tPoints = {0.5, 0.5, 0.5, 0.5}, tOffsetMults = {-0.5, -0.5, 0.5, 0.5}},
	{sLabel = "Left", tPoints = {0, 0.5, 0, 0.5}, tOffsetMults = {0, -0.5, 1, 0.5}},
	{sLabel = "Top Left", tPoints = {0, 0, 0, 0}, tOffsetMults = {0, 0, 1, 1}},
	{sLabel = "Top", tPoints = {0.5, 0, 0.5, 0}, tOffsetMults = {-0.5, 0, 0.5, 1}},
	{sLabel = "Top Right", tPoints = {1, 0, 1, 0}, tOffsetMults = {-1, 0, 0, 1}},
	{sLabel = "Right", tPoints = {1, 0.5, 1, 0.5}, tOffsetMults = {-1, -0.5, 0, 0.5}},
	{sLabel = "Bottom Right", tPoints = {1, 1, 1, 1}, tOffsetMults = {-1, -1, 0, 0}},
	{sLabel = "Bottom", tPoints = {0.5, 1, 0.5, 1}, tOffsetMults = {-0.5, -1, 0.5, 0}},
	{sLabel = "Bottom Left", tPoints = {0, 1, 0, 1}, tOffsetMults = {0, -1, 1, 0}},
}

Apollo.RegisterPackage(VILib, "Viper:Lib:VILib-1.9", 1, {})
