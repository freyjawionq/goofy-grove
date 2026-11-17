-- WildSpawner.luau (server)
-- Keeps the Grove stocked with wandering wild brainrots and walks the
-- Gobbler on its patrol. Wild brainrots are the game's catchable stock:
-- CatchService reads WildSpawner.wild to resolve touches and tags.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ModelForge = require(script.Parent:WaitForChild("ModelForge"))
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local WildSpawner = {}
WildSpawner.wild = {} -- array of { entry, model, root, target, speed, bornAt }
WildSpawner.gobbler = nil -- { model, root, target, speed, hunting }
WildSpawner.onGobblerTouch = nil -- set by CatchService

local GROVE_RADIUS = 62
local MAX_WILD = 10
local rng = Random.new()

local wildFolder = Instance.new("Folder")
wildFolder.Name = "WildBrainrots"

local function grovePoint(radius)
	local angle = rng:NextNumber(0, math.pi * 2)
	local dist = rng:NextNumber(6, radius or GROVE_RADIUS)
	return Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

function WildSpawner.spawnOne()
	local entry = BrainrotDefs.rollEntry(BrainrotDefs.rollWildRarity(), 1)
	local model = ModelForge.build(entry, 1)
	local root = model.PrimaryPart
	local at = grovePoint()
	root.CFrame = CFrame.new(at + Vector3.new(0, root.Size.Y / 2 + 0.2, 0))
		* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0)
	model.Parent = wildFolder
	table.insert(WildSpawner.wild, {
		entry = entry,
		model = model,
		root = root,
		target = grovePoint(),
		speed = rng:NextNumber(2.2, 4),
		bornAt = os.clock(),
		bobPhase = rng:NextNumber(0, math.pi * 2),
	})
	return model
end

function WildSpawner.remove(wildEntry)
	for index, candidate in ipairs(WildSpawner.wild) do
		if candidate == wildEntry then
			table.remove(WildSpawner.wild, index)
			break
		end
	end
	if wildEntry.model then
		wildEntry.model:Destroy()
	end
end

function WildSpawner.findNear(position, radius)
	local best, bestDist = nil, radius
	for _, candidate in ipairs(WildSpawner.wild) do
		local dist = (candidate.root.Position - position).Magnitude
		if dist < bestDist then
			best, bestDist = candidate, dist
		end
	end
	return best
end

-- Drop a brainrot as a wild one at a spot (a stolen catch knocked loose).
function WildSpawner.dropAsWild(entry, position)
	local model = ModelForge.build(entry, 1)
	local root = model.PrimaryPart
	root.CFrame = CFrame.new(Vector3.new(position.X, root.Size.Y / 2 + 0.2, position.Z))
	model.Parent = wildFolder
	table.insert(WildSpawner.wild, {
		entry = entry,
		model = model,
		root = root,
		target = grovePoint(),
		speed = 3,
		bornAt = os.clock(),
		bobPhase = rng:NextNumber(0, math.pi * 2),
	})
end

local WAYPOINTS = {}
for i = 1, 8 do
	local angle = (i / 8) * math.pi * 2
	table.insert(WAYPOINTS, Vector3.new(math.cos(angle) * 46, 0, math.sin(angle) * 46))
end

function WildSpawner.spawnGobbler()
	if WildSpawner.gobbler then
		return
	end
	local model = ModelForge.buildGobbler()
	local root = model.PrimaryPart
	root.CFrame = CFrame.new(WAYPOINTS[1] + Vector3.new(0, root.Size.Y / 2, 0))
	model.Parent = Workspace
	WildSpawner.gobbler = {
		model = model,
		root = root,
		waypoint = 2,
		target = WAYPOINTS[2],
		speed = 5,
		hunting = false,
		huntTarget = nil,
	}
end

-- Move everything: wild brainrots wander and bob; the Gobbler patrols its
-- ring, or chases its hunt target while a hunt runs (CatchService drives it).
function WildSpawner.startLoops()
	wildFolder.Parent = Workspace
	WildSpawner.spawnGobbler()
	task.spawn(function()
		while true do
			task.wait(2.5)
			if #WildSpawner.wild < MAX_WILD then
				WildSpawner.spawnOne()
			end
			for index = #WildSpawner.wild, 1, -1 do
				if os.clock() - WildSpawner.wild[index].bornAt > 120 then
					WildSpawner.remove(WildSpawner.wild[index])
				end
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for _, candidate in ipairs(WildSpawner.wild) do
			local root = candidate.root
			local pos = root.Position
			local flat = Vector3.new(candidate.target.X, pos.Y, candidate.target.Z)
			local delta = flat - pos
			if delta.Magnitude < 2 then
				candidate.target = grovePoint()
			else
				local step = delta.Unit * math.min(candidate.speed * dt, delta.Magnitude)
				local bob = math.sin(now * 3 + candidate.bobPhase) * 0.18
				local groundY = root.Size.Y / 2 + 0.2 + bob
				root.CFrame = CFrame.new(pos.X + step.X, groundY, pos.Z + step.Z)
					* CFrame.Angles(0, math.atan2(-delta.X, -delta.Z), 0)
			end
		end
		local gobbler = WildSpawner.gobbler
		if gobbler then
			local root = gobbler.root
			local target = gobbler.target
			if gobbler.hunting and gobbler.huntTarget then
				target = gobbler.huntTarget
			end
			local pos = root.Position
			local flat = Vector3.new(target.X, pos.Y, target.Z)
			local delta = flat - pos
			if delta.Magnitude < 3 then
				if not gobbler.hunting then
					gobbler.waypoint = gobbler.waypoint % #WAYPOINTS + 1
					gobbler.target = WAYPOINTS[gobbler.waypoint]
				end
			else
				local step = delta.Unit * math.min(gobbler.speed * dt, delta.Magnitude)
				root.CFrame = CFrame.new(pos.X + step.X, root.Size.Y / 2, pos.Z + step.Z)
					* CFrame.Angles(0, math.atan2(-delta.X, -delta.Z), 0)
			end
			if WildSpawner.onGobblerTouch then
				WildSpawner.onGobblerTouch(root.Position)
			end
		end
	end)
end

return WildSpawner
