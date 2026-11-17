-- ScreenshotStage.luau (server)
-- Poses the game for its screenshots and for make.fun's reviewers (TOUR.json
-- names these functions): fills the first player's base with a showcase
-- cast, starts a Gobbler hunt on demand, and hands out a carried Mythic.
-- It changes only live state, never saved data.

local Players = game:GetService("Players")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local CatchService = require(script.Parent:WaitForChild("CatchService"))
local WildSpawner = require(script.Parent:WaitForChild("WildSpawner"))

local ScreenshotStage = {}

local function firstPlayer()
	return Players:GetPlayers()[1]
end

-- A base dressed for the cover: one brainrot of every rarity, two mutated.
function ScreenshotStage.showcase(_arg)
	local player = firstPlayer()
	if not player then
		return
	end
	local state = PlayerState.byPlayer[player]
	if not state then
		return
	end
	state.coins = 250000
	state.placed = {
		{ defId = "Bopple" },
		{ defId = "Turnip", mutation = "Shiny" },
		{ defId = "Banana" },
		{ defId = "Cactus" },
		{ defId = "Waffleton", mutation = "Golden" },
		{ defId = "MechaPotato" },
		{ defId = "Jellybean" },
		{ defId = "Gloob", mutation = "Void" },
	}
	BaseManager.refreshDisplays(player)
end

-- A Mythic on the head and the Gobbler awake: the dash-home screenshot.
function ScreenshotStage.hunt(_arg)
	local player = firstPlayer()
	if not player then
		return
	end
	ScreenshotStage.showcase()
	CatchService.giveCarried(player, { defId = "Bagel", mutation = "Golden" })
	local gobbler = WildSpawner.gobbler
	if gobbler then
		gobbler.hunting = true
		gobbler.speed = 13
		task.delay(25, function()
			if WildSpawner.gobbler then
				WildSpawner.gobbler.hunting = false
				WildSpawner.gobbler.speed = 5
			end
		end)
	end
end

-- Coins enough for every egg: the shop screenshot.
function ScreenshotStage.rich(_arg)
	local player = firstPlayer()
	if not player then
		return
	end
	local state = PlayerState.byPlayer[player]
	if state then
		state.coins = 500000
		PlayerState.sync(player)
	end
end

return ScreenshotStage
