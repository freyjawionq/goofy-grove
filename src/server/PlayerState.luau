-- PlayerState.luau (server)
-- Every player's game state, kept in exactly one place: coins, the brainrots
-- on their base, the one on their head, upgrades, rebirths and base lock.
-- Other services ask this module; nothing else holds a second copy.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local PlayerState = {}
PlayerState.byPlayer = {}

local STORE_NAME = "GoofyGrove_v1"
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local function freshState()
	return {
		coins = BrainrotDefs.StartCoins,
		placed = {}, -- array of { defId, mutation }, one per base pad
		carrying = nil, -- one { defId, mutation } or nil
		upgrades = {}, -- upgrade id -> level bought
		rebirths = 0,
		baseIndex = nil, -- set by BaseManager
		lockUntil = 0, -- os.clock() deadline; steal-proof while in the future
		lockReadyAt = 0, -- os.clock() time the lock button may be pressed again
		droppedAt = {}, -- per-player steal tag cooldowns live in CatchService
	}
end

-- The number of display pads this player's base has.
function PlayerState.padCount(state)
	local extra = (state.upgrades.ExtraPad or 0) * 2
	return math.min(BrainrotDefs.BasePads + extra, 14)
end

-- Catch / steal reach in studs, grown by the Coin Magnet upgrade.
function PlayerState.reach(state)
	return 6 + (state.upgrades.Magnet or 0) * 2
end

-- Walk speed with Swift Boots.
function PlayerState.walkSpeed(state)
	return 16 + (state.upgrades.SwiftBoots or 0) * 3
end

-- Mutation luck multiplier from Golden Gloves.
function PlayerState.mutationLuck(state)
	return 1 + (state.upgrades.GoldenGlove or 0) * 0.5
end

-- Total coins per second from everything on the base.
function PlayerState.incomePerSecond(state)
	local total = 0
	for _, entry in ipairs(state.placed) do
		total += BrainrotDefs.rateOf(entry, state.rebirths)
	end
	return total
end

function PlayerState.isLocked(state)
	return os.clock() < state.lockUntil
end

-- Load (or start) a player's state and wire their leaderstats.
function PlayerState.load(player)
	local state = freshState()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("player_" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			state.coins = saved.coins or state.coins
			state.placed = saved.placed or {}
			state.upgrades = saved.upgrades or {}
			state.rebirths = saved.rebirths or 0
		end
	end
	PlayerState.byPlayer[player] = state

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = math.floor(state.coins)
	coins.Parent = leaderstats
	local income = Instance.new("IntValue")
	income.Name = "PerSec"
	income.Value = math.floor(PlayerState.incomePerSecond(state))
	income.Parent = leaderstats
	leaderstats.Parent = player
	state.leaderstats = leaderstats
	return state
end

-- Push state numbers into leaderstats after any change.
function PlayerState.sync(player)
	local state = PlayerState.byPlayer[player]
	if not state or not state.leaderstats then
		return
	end
	state.leaderstats.Coins.Value = math.floor(state.coins)
	state.leaderstats.PerSec.Value = math.floor(PlayerState.incomePerSecond(state))
	player:SetAttribute("Coins", math.floor(state.coins))
	player:SetAttribute("IncomePerSec", math.floor(PlayerState.incomePerSecond(state)))
	player:SetAttribute("Rebirths", state.rebirths)
	player:SetAttribute("CarryingName", state.carrying and BrainrotDefs.displayName(state.carrying) or "")
	player:SetAttribute("LockSeconds", math.max(0, math.ceil(state.lockUntil - os.clock())))
end

function PlayerState.save(player)
	local state = PlayerState.byPlayer[player]
	if not state or not store then
		return
	end
	pcall(function()
		store:SetAsync("player_" .. player.UserId, {
			coins = math.floor(state.coins),
			placed = state.placed,
			upgrades = state.upgrades,
			rebirths = state.rebirths,
		})
	end)
end

function PlayerState.unload(player)
	PlayerState.save(player)
	PlayerState.byPlayer[player] = nil
end

return PlayerState
