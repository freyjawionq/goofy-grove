-- Format.luau
-- Small display helpers shared by the server labels and the client HUD.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

-- 950 -> "950", 1500 -> "1.5K", 2,300,000 -> "2.3M"
function Format.number(value)
	value = math.floor(value)
	if value < 1000 then
		return tostring(value)
	end
	local tier = 0
	local scaled = value
	while scaled >= 1000 and tier < #SUFFIXES - 1 do
		scaled /= 1000
		tier += 1
	end
	if scaled >= 100 then
		return string.format("%d%s", math.floor(scaled), SUFFIXES[tier + 1])
	end
	return string.format("%.1f%s", scaled, SUFFIXES[tier + 1])
end

-- Coins with the game's coin word, for HUD text.
function Format.coins(value)
	return Format.number(value) .. " coins"
end

-- Seconds -> "1:05" for lock and event timers.
function Format.clock(seconds)
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

return Format
