-- BrainrotDefs.luau
-- The whole Goofy Grove cast and economy in one module: rarities, mutations,
-- the fourteen original brainrots, eggs, upgrades and the rebirth ladder.
-- Server and client both read this, so a name, rate or price is written once.

local BrainrotDefs = {}

-- Rarity ladder, worst to best. Weight is the wild-spawn weight.
BrainrotDefs.Rarities = {
	{ id = "Common", weight = 5000, color = Color3.fromRGB(205, 205, 205) },
	{ id = "Uncommon", weight = 2100, color = Color3.fromRGB(105, 225, 105) },
	{ id = "Rare", weight = 850, color = Color3.fromRGB(80, 150, 255) },
	{ id = "Epic", weight = 310, color = Color3.fromRGB(175, 85, 255) },
	{ id = "Legendary", weight = 100, color = Color3.fromRGB(255, 190, 45) },
	{ id = "Mythic", weight = 30, color = Color3.fromRGB(255, 95, 205) },
	{ id = "GroveGod", weight = 6, color = Color3.fromRGB(255, 84, 60) },
}

BrainrotDefs.RarityById = {}
for index, rarity in ipairs(BrainrotDefs.Rarities) do
	rarity.rank = index
	BrainrotDefs.RarityById[rarity.id] = rarity
end

-- Mutations multiply a brainrot's income. Rolled on every catch and hatch.
BrainrotDefs.Mutations = {
	{ id = "Shiny", mult = 2, chance = 0.12, color = Color3.fromRGB(170, 240, 255) },
	{ id = "Golden", mult = 5, chance = 0.06, color = Color3.fromRGB(255, 215, 0) },
	{ id = "Void", mult = 10, chance = 0.025, color = Color3.fromRGB(120, 60, 200) },
}

-- The cast. Every character is original to Goofy Grove: a body (Ball or Box)
-- plus extra parts the ModelForge bolts on, described in studs relative to
-- the body's centre. rate is coins per second before mutations and rebirths.
BrainrotDefs.Cast = {
	{ id = "Bopple", name = "Sir Bopple", rarity = "Common", rate = 2,
		body = { shape = "Ball", size = { 2.2, 2.2, 2.2 }, color = { 214, 48, 49 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 0.3, 0.9, 0.3 }, color = { 111, 66, 35 }, offset = { 0, 1.4, 0 } },
			{ shape = "Ball", size = { 0.9, 0.4, 0.6 }, color = { 46, 204, 113 }, offset = { 0.45, 1.75, 0 } },
		} },
	{ id = "Newt", name = "Noodle Newt", rarity = "Common", rate = 3,
		body = { shape = "Box", size = { 3.2, 1.1, 1.4 }, color = { 88, 214, 141 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 1.6, 0.5, 0.8 }, color = { 88, 214, 141 }, offset = { -2.2, -0.2, 0 } },
			{ shape = "Ball", size = { 0.8, 0.8, 0.8 }, color = { 250, 219, 100 }, offset = { 0.4, 0.85, 0.35 } },
			{ shape = "Ball", size = { 0.8, 0.8, 0.8 }, color = { 250, 219, 100 }, offset = { 0.4, 0.85, -0.35 } },
		} },
	{ id = "Pigeon", name = "Pudding Pigeon", rarity = "Common", rate = 4,
		body = { shape = "Ball", size = { 2, 1.8, 2.4 }, color = { 133, 160, 190 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 1.1, 1.1, 1.1 }, color = { 105, 135, 175 }, offset = { 0, 0.9, 0.9 } },
			{ shape = "Box", size = { 0.5, 0.3, 0.7 }, color = { 245, 176, 65 }, offset = { 0, 0.75, 1.65 } },
			{ shape = "Box", size = { 1.4, 0.25, 0.9 }, color = { 95, 125, 165 }, offset = { 0, 0.3, -1.4 } },
		} },
	{ id = "Crumb", name = "Captain Crumb", rarity = "Uncommon", rate = 8,
		body = { shape = "Ball", size = { 2.6, 1.1, 2.6 }, color = { 220, 164, 96 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 0.45, 0.45, 0.45 }, color = { 90, 55, 30 }, offset = { 0.6, 0.6, 0.5 } },
			{ shape = "Ball", size = { 0.45, 0.45, 0.45 }, color = { 90, 55, 30 }, offset = { -0.7, 0.6, -0.3 } },
			{ shape = "Box", size = { 1.5, 0.5, 1.5 }, color = { 52, 73, 94 }, offset = { 0, 0.85, 0 } },
		} },
	{ id = "Turnip", name = "Disco Turnip", rarity = "Uncommon", rate = 11,
		body = { shape = "Ball", size = { 2.2, 2.4, 2.2 }, color = { 175, 130, 220 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 1.1, 1.1, 1.1 }, color = { 255, 120, 220 }, material = "Neon", offset = { 0, 1.6, 0 } },
			{ shape = "Box", size = { 0.4, 1, 0.4 }, color = { 46, 204, 113 }, offset = { 0.5, 1.5, 0.3 } },
			{ shape = "Box", size = { 0.4, 1, 0.4 }, color = { 46, 204, 113 }, offset = { -0.5, 1.5, -0.3 } },
		} },
	{ id = "Banana", name = "Baron von Banana", rarity = "Rare", rate = 25,
		body = { shape = "Ball", size = { 1.8, 3, 1.8 }, color = { 250, 219, 100 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 0.5, 0.8, 0.5 }, color = { 111, 66, 35 }, offset = { 0, 1.8, 0 } },
			{ shape = "Box", size = { 2.4, 0.5, 0.6 }, color = { 20, 20, 20 }, offset = { 0, 0.9, 0 } },
			{ shape = "Ball", size = { 0.7, 0.7, 0.7 }, color = { 255, 255, 255 }, offset = { 0.95, 0.9, 0.3 } },
		} },
	{ id = "ToasterGhost", name = "Toaster Ghost", rarity = "Rare", rate = 34,
		body = { shape = "Box", size = { 2.4, 2.2, 1.8 }, color = { 240, 244, 248 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 1.8, 0.3, 0.4 }, color = { 40, 40, 40 }, offset = { 0, 1.2, 0.3 } },
			{ shape = "Box", size = { 1.8, 0.3, 0.4 }, color = { 40, 40, 40 }, offset = { 0, 1.2, -0.3 } },
			{ shape = "Box", size = { 1.4, 1, 0.3 }, color = { 230, 160, 80 }, offset = { 0, 1.6, 0.3 } },
			{ shape = "Box", size = { 1.4, 1, 0.3 }, color = { 230, 160, 80 }, offset = { 0, 1.6, -0.3 } },
		} },
	{ id = "Cactus", name = "DJ Cactus Prime", rarity = "Epic", rate = 90,
		body = { shape = "Box", size = { 1.8, 3.4, 1.8 }, color = { 39, 174, 96 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 0.9, 1.6, 0.9 }, color = { 39, 174, 96 }, offset = { 1.3, 0.6, 0 } },
			{ shape = "Box", size = { 0.9, 1.2, 0.9 }, color = { 39, 174, 96 }, offset = { -1.3, 1, 0 } },
			{ shape = "Box", size = { 2.2, 0.7, 0.4 }, color = { 15, 15, 20 }, offset = { 0, 1.1, 0.95 } },
			{ shape = "Ball", size = { 0.9, 0.9, 0.9 }, color = { 255, 95, 205 }, material = "Neon", offset = { 0, 2.1, 0 } },
		} },
	{ id = "Waffleton", name = "Count Waffleton", rarity = "Epic", rate = 120,
		body = { shape = "Box", size = { 2.6, 2.6, 1.2 }, color = { 235, 180, 100 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 0.5, 2.6, 0.3 }, color = { 200, 140, 60 }, offset = { -0.65, 0, 0.65 } },
			{ shape = "Box", size = { 0.5, 2.6, 0.3 }, color = { 200, 140, 60 }, offset = { 0.65, 0, 0.65 } },
			{ shape = "Box", size = { 2.6, 0.5, 0.3 }, color = { 200, 140, 60 }, offset = { 0, 0.65, 0.65 } },
			{ shape = "Box", size = { 2.6, 0.5, 0.3 }, color = { 200, 140, 60 }, offset = { 0, -0.65, 0.65 } },
			{ shape = "Box", size = { 1, 1, 0.5 }, color = { 255, 240, 160 }, offset = { 0, 1.7, 0 } },
		} },
	{ id = "MechaPotato", name = "Mecha Potato MK-7", rarity = "Legendary", rate = 450,
		body = { shape = "Ball", size = { 2.8, 2.4, 2.8 }, color = { 185, 140, 90 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Box", size = { 3.2, 0.6, 3.2 }, color = { 140, 150, 160 }, material = "Metal", offset = { 0, -1.2, 0 } },
			{ shape = "Ball", size = { 1, 1, 1 }, color = { 0, 230, 255 }, material = "Neon", offset = { 0, 0.4, 1.35 } },
			{ shape = "Box", size = { 0.3, 1.4, 0.3 }, color = { 140, 150, 160 }, material = "Metal", offset = { 0.8, 1.7, 0 } },
			{ shape = "Ball", size = { 0.5, 0.5, 0.5 }, color = { 255, 60, 60 }, material = "Neon", offset = { 0.8, 2.5, 0 } },
		} },
	{ id = "Raincloud", name = "Sir Reginald Raincloud", rarity = "Legendary", rate = 600,
		body = { shape = "Ball", size = { 3.4, 2, 2.6 }, color = { 150, 160, 175 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 2, 1.6, 2 }, color = { 170, 180, 195 }, offset = { -1.2, 0.5, 0 } },
			{ shape = "Ball", size = { 2, 1.6, 2 }, color = { 165, 175, 190 }, offset = { 1.2, 0.5, 0 } },
			{ shape = "Box", size = { 0.25, 1.1, 0.25 }, color = { 80, 150, 255 }, material = "Neon", offset = { -0.8, -1.6, 0.4 } },
			{ shape = "Box", size = { 0.25, 1.1, 0.25 }, color = { 80, 150, 255 }, material = "Neon", offset = { 0.2, -1.6, -0.3 } },
			{ shape = "Box", size = { 0.25, 1.1, 0.25 }, color = { 80, 150, 255 }, material = "Neon", offset = { 0.9, -1.6, 0.3 } },
		} },
	{ id = "Jellybean", name = "Empress Jellybean", rarity = "Mythic", rate = 2600,
		body = { shape = "Ball", size = { 2.4, 3, 2.4 }, color = { 255, 130, 190 }, material = "Glass" },
		extras = {
			{ shape = "Box", size = { 1.6, 0.5, 1.6 }, color = { 255, 215, 0 }, material = "Metal", offset = { 0, 1.75, 0 } },
			{ shape = "Box", size = { 0.4, 0.9, 0.4 }, color = { 255, 215, 0 }, material = "Metal", offset = { -0.6, 2.3, 0 } },
			{ shape = "Box", size = { 0.4, 0.9, 0.4 }, color = { 255, 215, 0 }, material = "Metal", offset = { 0.6, 2.3, 0 } },
			{ shape = "Box", size = { 0.4, 1.1, 0.4 }, color = { 255, 215, 0 }, material = "Metal", offset = { 0, 2.4, 0 } },
		} },
	{ id = "Bagel", name = "The Eternal Bagel", rarity = "Mythic", rate = 3400,
		body = { shape = "Ball", size = { 3.2, 1.2, 3.2 }, color = { 232, 190, 120 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 1.2, 1.3, 1.2 }, color = { 90, 60, 35 }, offset = { 0, 0, 0 } },
			{ shape = "Ball", size = { 0.35, 0.2, 0.35 }, color = { 255, 250, 230 }, offset = { 1, 0.65, 0.4 } },
			{ shape = "Ball", size = { 0.35, 0.2, 0.35 }, color = { 255, 250, 230 }, offset = { -0.9, 0.65, -0.5 } },
			{ shape = "Ball", size = { 0.35, 0.2, 0.35 }, color = { 255, 250, 230 }, offset = { 0.2, 0.65, 1 } },
		} },
	{ id = "Gloob", name = "GLOOB, Devourer of Snacks", rarity = "GroveGod", rate = 16000,
		body = { shape = "Ball", size = { 4.6, 4, 4.6 }, color = { 130, 70, 220 }, material = "SmoothPlastic" },
		extras = {
			{ shape = "Ball", size = { 3.4, 2.6, 3.4 }, color = { 150, 95, 235 }, offset = { 0, 2.4, 0 } },
			{ shape = "Ball", size = { 2.2, 1.8, 2.2 }, color = { 170, 120, 250 }, offset = { 0, 4.2, 0 } },
			{ shape = "Ball", size = { 1, 1, 1 }, color = { 255, 220, 80 }, material = "Neon", offset = { -1, 4.4, 1.9 } },
			{ shape = "Ball", size = { 1, 1, 1 }, color = { 255, 220, 80 }, material = "Neon", offset = { 1, 4.4, 1.9 } },
			{ shape = "Box", size = { 2.6, 0.8, 0.5 }, color = { 30, 10, 50 }, offset = { 0, 3.4, 2.1 } },
		} },
}

BrainrotDefs.ById = {}
BrainrotDefs.ByRarity = {}
for _, def in ipairs(BrainrotDefs.Cast) do
	BrainrotDefs.ById[def.id] = def
	local bucket = BrainrotDefs.ByRarity[def.rarity]
	if not bucket then
		bucket = {}
		BrainrotDefs.ByRarity[def.rarity] = bucket
	end
	table.insert(bucket, def)
end

-- Eggs: price and the rarity table they hatch from.
BrainrotDefs.Eggs = {
	{ id = "GroveEgg", name = "Grove Egg", price = 250, mutationBoost = 1,
		table = { Common = 55, Uncommon = 28, Rare = 12, Epic = 4, Legendary = 1 } },
	{ id = "RoyalEgg", name = "Royal Egg", price = 5000, mutationBoost = 1.25,
		table = { Rare = 45, Epic = 32, Legendary = 16, Mythic = 6, GroveGod = 1 } },
	{ id = "CosmicEgg", name = "Cosmic Egg", price = 60000, mutationBoost = 2,
		table = { Epic = 40, Legendary = 35, Mythic = 20, GroveGod = 5 } },
}
BrainrotDefs.EggById = {}
for _, egg in ipairs(BrainrotDefs.Eggs) do
	BrainrotDefs.EggById[egg.id] = egg
end

-- Upgrades: each level's price, in order. Effects live in PlayerState.
BrainrotDefs.Upgrades = {
	{ id = "ExtraPad", name = "Extra Base Pad", blurb = "+2 display pads per level",
		prices = { 1500, 6000, 20000 } },
	{ id = "SwiftBoots", name = "Swift Boots", blurb = "+3 walk speed per level",
		prices = { 800, 3000, 10000 } },
	{ id = "Magnet", name = "Coin Magnet", blurb = "+2 catch reach per level",
		prices = { 2000, 8000 } },
	{ id = "GoldenGlove", name = "Golden Glove", blurb = "+50% mutation luck per level",
		prices = { 7500, 25000 } },
}
BrainrotDefs.UpgradeById = {}
for _, upgrade in ipairs(BrainrotDefs.Upgrades) do
	BrainrotDefs.UpgradeById[upgrade.id] = upgrade
end

BrainrotDefs.StartCoins = 100
BrainrotDefs.BasePads = 8

-- Rebirth: the coin cost of the (rebirths + 1)-th rebirth, and the income
-- multiplier a player with that many rebirths earns at.
function BrainrotDefs.rebirthCost(rebirths)
	return math.floor(25000 * (rebirths + 1) ^ 1.7)
end

function BrainrotDefs.incomeMult(rebirths)
	return 1 + 0.75 * rebirths
end

-- The coins per second one caught brainrot earns a player.
function BrainrotDefs.rateOf(entry, rebirths)
	local def = BrainrotDefs.ById[entry.defId]
	if not def then
		return 0
	end
	local mult = 1
	if entry.mutation then
		for _, mutation in ipairs(BrainrotDefs.Mutations) do
			if mutation.id == entry.mutation then
				mult = mutation.mult
				break
			end
		end
	end
	return def.rate * mult * BrainrotDefs.incomeMult(rebirths or 0)
end

-- A display name like "Golden Baron von Banana (Rare)".
function BrainrotDefs.displayName(entry)
	local def = BrainrotDefs.ById[entry.defId]
	if not def then
		return "Unknown Brainrot"
	end
	local prefix = ""
	if entry.mutation then
		prefix = entry.mutation .. " "
	end
	return prefix .. def.name .. " (" .. def.rarity .. ")"
end

local rng = Random.new()

-- Roll a rarity from a weight table of rarity id -> weight.
function BrainrotDefs.rollRarity(weightTable)
	local total = 0
	for _, weight in pairs(weightTable) do
		total += weight
	end
	local roll = rng:NextNumber(0, total)
	for rarityId, weight in pairs(weightTable) do
		roll -= weight
		if roll <= 0 then
			return rarityId
		end
	end
	return "Common"
end

-- Roll a wild rarity from the spawn weights.
function BrainrotDefs.rollWildRarity()
	local table_ = {}
	for _, rarity in ipairs(BrainrotDefs.Rarities) do
		table_[rarity.id] = rarity.weight
	end
	return BrainrotDefs.rollRarity(table_)
end

-- Roll a mutation id (or nil), with a luck multiplier on the chances.
function BrainrotDefs.rollMutation(luckMult)
	local roll = rng:NextNumber()
	local cumulative = 0
	for _, mutation in ipairs(BrainrotDefs.Mutations) do
		cumulative += mutation.chance * (luckMult or 1)
		if roll < cumulative then
			return mutation.id
		end
	end
	return nil
end

-- Roll one full entry { defId, mutation } for a rarity.
function BrainrotDefs.rollEntry(rarityId, luckMult)
	local bucket = BrainrotDefs.ByRarity[rarityId] or BrainrotDefs.ByRarity.Common
	local def = bucket[rng:NextInteger(1, #bucket)]
	return { defId = def.id, mutation = BrainrotDefs.rollMutation(luckMult) }
end

return BrainrotDefs
