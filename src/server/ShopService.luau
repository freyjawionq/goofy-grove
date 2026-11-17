-- ShopService.luau (server)
-- Everything coins are spent on: hatching eggs, buying upgrades, locking the
-- base and rebirthing. Clients ask through the ShopAction RemoteFunction;
-- this module alone decides what is affordable and what happens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local CatchService = require(script.Parent:WaitForChild("CatchService"))
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local ShopService = {}
ShopService.notify = nil -- (player, kind, text) set by Main.server

local LOCK_SECONDS = 60
local LOCK_COOLDOWN = 120

local function fail(player, message)
	if ShopService.notify then
		ShopService.notify(player, "warn", message)
	end
	return { ok = false, message = message }
end

-- Hatch an egg: the new brainrot goes on a free pad, else on the player's
-- head, else it is auto-sold so a full base never eats the purchase.
function ShopService.buyEgg(player, eggId)
	local state = PlayerState.byPlayer[player]
	local egg = BrainrotDefs.EggById[eggId]
	if not state or not egg then
		return fail(player, "Unknown egg.")
	end
	if state.coins < egg.price then
		return fail(player, "Need " .. Format.coins(egg.price) .. " for the " .. egg.name .. ".")
	end
	state.coins -= egg.price
	local rarityId = BrainrotDefs.rollRarity(egg.table)
	local luck = PlayerState.mutationLuck(state) * egg.mutationBoost
	local entry = BrainrotDefs.rollEntry(rarityId, luck)
	local name = BrainrotDefs.displayName(entry)
	if #state.placed < PlayerState.padCount(state) then
		table.insert(state.placed, entry)
		BaseManager.refreshDisplays(player)
		if ShopService.notify then
			ShopService.notify(player, "good", egg.name .. " hatched a " .. name .. "!")
		end
	elseif CatchService.giveCarried(player, entry) then
		if ShopService.notify then
			ShopService.notify(player, "good", egg.name .. " hatched a " .. name .. " - carry it home!")
		end
	else
		local sellValue = math.floor(BrainrotDefs.rateOf(entry, state.rebirths) * 24)
		state.coins += sellValue
		if ShopService.notify then
			ShopService.notify(player, "warn", "Base full! The " .. name .. " was sold for " .. Format.coins(sellValue) .. ".")
		end
	end
	PlayerState.sync(player)
	return { ok = true }
end

function ShopService.buyUpgrade(player, upgradeId)
	local state = PlayerState.byPlayer[player]
	local upgrade = BrainrotDefs.UpgradeById[upgradeId]
	if not state or not upgrade then
		return fail(player, "Unknown upgrade.")
	end
	local level = state.upgrades[upgradeId] or 0
	local price = upgrade.prices[level + 1]
	if not price then
		return fail(player, upgrade.name .. " is fully upgraded.")
	end
	if state.coins < price then
		return fail(player, "Need " .. Format.coins(price) .. " for " .. upgrade.name .. ".")
	end
	state.coins -= price
	state.upgrades[upgradeId] = level + 1
	if upgradeId == "SwiftBoots" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = PlayerState.walkSpeed(state)
		end
	end
	if upgradeId == "ExtraPad" then
		BaseManager.refreshDisplays(player)
	end
	if ShopService.notify then
		ShopService.notify(player, "good", upgrade.name .. " level " .. (level + 1) .. "!")
	end
	PlayerState.sync(player)
	return { ok = true }
end

-- Lock the base: steal-proof for a minute, then a cooldown before relocking.
function ShopService.toggleLock(player)
	local state = PlayerState.byPlayer[player]
	if not state then
		return { ok = false }
	end
	local now = os.clock()
	if PlayerState.isLocked(state) then
		return fail(player, "Your base is already locked.")
	end
	if now < state.lockReadyAt then
		return fail(player, "Lock recharges in " .. Format.clock(state.lockReadyAt - now) .. ".")
	end
	state.lockUntil = now + LOCK_SECONDS
	state.lockReadyAt = now + LOCK_COOLDOWN
	BaseManager.updateDome(player)
	if ShopService.notify then
		ShopService.notify(player, "good", "Base locked for " .. LOCK_SECONDS .. " seconds!")
	end
	PlayerState.sync(player)
	return { ok = true }
end

-- Rebirth: coins and brainrots reset; the income multiplier is forever.
function ShopService.rebirth(player)
	local state = PlayerState.byPlayer[player]
	if not state then
		return { ok = false }
	end
	local cost = BrainrotDefs.rebirthCost(state.rebirths)
	if state.coins < cost then
		return fail(player, "Rebirth needs " .. Format.coins(cost) .. ".")
	end
	state.rebirths += 1
	state.coins = BrainrotDefs.StartCoins
	state.placed = {}
	if state.carrying then
		CatchService.dropCarried(player)
	end
	BaseManager.refreshDisplays(player)
	if ShopService.notify then
		ShopService.notify(player, "good", "Rebirth " .. state.rebirths .. "! Income is now x" .. string.format("%.2g", BrainrotDefs.incomeMult(state.rebirths)) .. ".")
	end
	PlayerState.sync(player)
	PlayerState.save(player)
	return { ok = true }
end

-- One RemoteFunction entry point for every shop action.
function ShopService.handleAction(player, action)
	if type(action) ~= "table" or type(action.kind) ~= "string" then
		return { ok = false }
	end
	if action.kind == "BuyEgg" then
		return ShopService.buyEgg(player, action.id)
	elseif action.kind == "BuyUpgrade" then
		return ShopService.buyUpgrade(player, action.id)
	elseif action.kind == "ToggleLock" then
		return ShopService.toggleLock(player)
	elseif action.kind == "Rebirth" then
		return ShopService.rebirth(player)
	end
	return { ok = false }
end

-- Egg nests in the world get ProximityPrompts, so the shop also exists in
-- the 3D world and not only in the HUD.
function ShopService.wireNests()
	local nests = Workspace:WaitForChild("Nests")
	for _, egg in ipairs(BrainrotDefs.Eggs) do
		local nest = nests:FindFirstChild(egg.id)
		if nest then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "HatchPrompt"
			prompt.ActionText = "Hatch - " .. Format.coins(egg.price)
			prompt.ObjectText = egg.name
			prompt.HoldDuration = 0.4
			prompt.MaxActivationDistance = 12
			prompt.Parent = nest
			prompt.Triggered:Connect(function(player)
				ShopService.buyEgg(player, egg.id)
			end)
		end
	end
end

return ShopService
