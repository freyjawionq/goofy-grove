-- CatchService.luau (server)
-- The game's tension: catch a wild brainrot by walking into it, carry it on
-- your head, and dash home to bank it on a base pad. While you carry, other
-- players can tag the catch loose and the Gobbler hunts you; while your base
-- stands unlocked, other players can lift a brainrot off its pads.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local WildSpawner = require(script.Parent:WaitForChild("WildSpawner"))
local ModelForge = require(script.Parent:WaitForChild("ModelForge"))
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local CatchService = {}
CatchService.notify = nil -- (player, kind, text) set by Main.server
CatchService.broadcast = nil -- (kind, text) set by Main.server

local tagCooldowns = {} -- [thief][victim] = os.clock() ready time
local carryModels = {} -- player -> model riding on their head

local function characterRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

-- Stand a mini brainrot on the player's head while they carry one.
local function showCarried(player)
	hideCarried(player)
	local state = PlayerState.byPlayer[player]
	local character = player.Character
	if not state or not state.carrying or not character then
		return
	end
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local model = ModelForge.build(state.carrying, 0.55)
	local root = model.PrimaryPart
	root.CFrame = head.CFrame * CFrame.new(0, head.Size.Y / 2 + root.Size.Y / 2 + 0.15, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = root
	weld.Parent = root
	model.Parent = character
	carryModels[player] = model
end

function hideCarried(player)
	local model = carryModels[player]
	if model then
		model:Destroy()
		carryModels[player] = nil
	end
end

-- Give a player a carried brainrot (from a catch, a steal or an egg).
function CatchService.giveCarried(player, entry)
	local state = PlayerState.byPlayer[player]
	if not state or state.carrying then
		return false
	end
	state.carrying = entry
	showCarried(player)
	PlayerState.sync(player)
	return true
end

-- Put the carried brainrot on a free base pad. Returns true when banked.
function CatchService.bankCarried(player)
	local state = PlayerState.byPlayer[player]
	if not state or not state.carrying then
		return false
	end
	if #state.placed >= PlayerState.padCount(state) then
		if CatchService.notify then
			CatchService.notify(player, "warn", "Your base is full - buy an Extra Pad!")
		end
		return false
	end
	table.insert(state.placed, state.carrying)
	local name = BrainrotDefs.displayName(state.carrying)
	state.carrying = nil
	hideCarried(player)
	BaseManager.refreshDisplays(player)
	if CatchService.notify then
		CatchService.notify(player, "good", "Banked " .. name .. "!")
	end
	return true
end

-- Knock a player's carried brainrot loose as a wild one at their feet.
function CatchService.dropCarried(player)
	local state = PlayerState.byPlayer[player]
	if not state or not state.carrying then
		return nil
	end
	local root = characterRoot(player)
	local entry = state.carrying
	state.carrying = nil
	hideCarried(player)
	PlayerState.sync(player)
	if root then
		WildSpawner.dropAsWild(entry, root.Position)
	end
	return entry
end

local function tryCatch(player, root)
	local state = PlayerState.byPlayer[player]
	if not state or state.carrying then
		return
	end
	local wild = WildSpawner.findNear(root.Position, PlayerState.reach(state))
	if wild then
		local entry = wild.entry
		WildSpawner.remove(wild)
		CatchService.giveCarried(player, entry)
		if CatchService.notify then
			CatchService.notify(player, "good", "Caught " .. BrainrotDefs.displayName(entry) .. " - dash home to bank it!")
		end
	end
end

local function tryBank(player, root)
	local state = PlayerState.byPlayer[player]
	if not state or not state.carrying then
		return
	end
	local plot = BaseManager.plotOfPlayer[player]
	if not plot then
		return
	end
	local zone = plot:FindFirstChild("BankZone")
	if zone and (zone.Position - root.Position).Magnitude < 9 then
		CatchService.bankCarried(player)
	end
end

local function tryTag(thief, thiefRoot)
	local thiefState = PlayerState.byPlayer[thief]
	if not thiefState or thiefState.carrying then
		return
	end
	tagCooldowns[thief] = tagCooldowns[thief] or {}
	for _, victim in ipairs(Players:GetPlayers()) do
		if victim ~= thief then
			local victimState = PlayerState.byPlayer[victim]
			local victimRoot = characterRoot(victim)
			if victimState and victimState.carrying and victimRoot
				and (victimRoot.Position - thiefRoot.Position).Magnitude < PlayerState.reach(thiefState)
				and os.clock() >= (tagCooldowns[thief][victim] or 0)
			then
				tagCooldowns[thief][victim] = os.clock() + 5
				local entry = CatchService.dropCarried(victim)
				if entry and CatchService.notify then
					CatchService.notify(victim, "bad", "Tagged! Your " .. BrainrotDefs.displayName(entry) .. " got knocked loose!")
					CatchService.notify(thief, "good", "You knocked a brainrot loose - grab it!")
				end
				return
			end
		end
	end
end

local function tryBaseSteal(thief, thiefRoot)
	local thiefState = PlayerState.byPlayer[thief]
	if not thiefState or thiefState.carrying then
		return
	end
	for owner, plot in pairs(BaseManager.plotOfPlayer) do
		if owner ~= thief then
			local ownerState = PlayerState.byPlayer[owner]
			if ownerState and not PlayerState.isLocked(ownerState) and #ownerState.placed > 0 then
				local displays = plot:FindFirstChild("Displays")
				if displays then
					for _, model in ipairs(displays:GetChildren()) do
						local rootPart = model.PrimaryPart
						if rootPart and (rootPart.Position - thiefRoot.Position).Magnitude < 5.5 then
							local index = model:GetAttribute("PadIndex")
							local entry = table.remove(ownerState.placed, index)
							if entry then
								BaseManager.refreshDisplays(owner)
								CatchService.giveCarried(thief, entry)
								if CatchService.notify then
									CatchService.notify(owner, "bad", BrainrotDefs.displayName(entry) .. " was stolen from your base! Lock it next time!")
									CatchService.notify(thief, "good", "Stole " .. BrainrotDefs.displayName(entry) .. " - run it home!")
								end
								return
							end
						end
					end
				end
			end
		end
	end
end

-- The Gobbler eats the carried brainrot of anyone it reaches on a hunt.
local function gobblerTouch(gobblerPosition)
	local gobbler = WildSpawner.gobbler
	if not gobbler or not gobbler.hunting then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.byPlayer[player]
		local root = characterRoot(player)
		if state and state.carrying and root and (root.Position - gobblerPosition).Magnitude < 7 then
			local entry = state.carrying
			state.carrying = nil
			hideCarried(player)
			PlayerState.sync(player)
			if CatchService.notify then
				CatchService.notify(player, "bad", "The Gobbler ate your " .. BrainrotDefs.displayName(entry) .. "!")
			end
		end
	end
end

-- Hunt cycle: every few minutes the Gobbler wakes for 20 seconds and runs
-- at the richest carrier it can see. Everyone is told; carriers run home.
local function startHuntCycle()
	task.spawn(function()
		while true do
			task.wait(Random.new():NextInteger(150, 210))
			local gobbler = WildSpawner.gobbler
			if not gobbler then
				continue
			end
			gobbler.hunting = true
			gobbler.speed = 13
			if CatchService.broadcast then
				CatchService.broadcast("event", "THE GOBBLER AWAKENS - carriers, dash home!")
			end
			local endsAt = os.clock() + 20
			while os.clock() < endsAt do
				local bestPlayer, bestRate = nil, -1
				for _, player in ipairs(Players:GetPlayers()) do
					local state = PlayerState.byPlayer[player]
					if state and state.carrying then
						local rate = BrainrotDefs.rateOf(state.carrying, state.rebirths)
						if rate > bestRate then
							bestRate = rate
							bestPlayer = player
						end
					end
				end
				local targetRoot = bestPlayer and characterRoot(bestPlayer)
				gobbler.huntTarget = targetRoot and targetRoot.Position or nil
				task.wait(0.4)
			end
			gobbler.hunting = false
			gobbler.huntTarget = nil
			gobbler.speed = 5
			if CatchService.broadcast then
				CatchService.broadcast("event", "The Gobbler settles back to its patrol... for now.")
			end
		end
	end)
end

-- The proximity loop that resolves every touch in the game, four times a
-- second: catches, banking, tags and base steals.
function CatchService.start()
	WildSpawner.onGobblerTouch = gobblerTouch
	startHuntCycle()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in ipairs(Players:GetPlayers()) do
				local root = characterRoot(player)
				if root then
					tryCatch(player, root)
					tryBank(player, root)
					tryTag(player, root)
					tryBaseSteal(player, root)
				end
			end
		end
	end)
end

-- Re-dress a respawned character with its carried brainrot and speed.
function CatchService.onCharacterAdded(player, character)
	local state = PlayerState.byPlayer[player]
	if not state then
		return
	end
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.WalkSpeed = PlayerState.walkSpeed(state)
	if state.carrying then
		task.defer(function()
			showCarried(player)
		end)
	end
end

return CatchService
