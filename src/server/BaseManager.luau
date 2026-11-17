-- BaseManager.luau (server)
-- Owns the six base plots: claims one for each player, stands their caught
-- brainrots on its pads, runs the once-a-second income tick, and raises or
-- lowers the lock dome that makes a base steal-proof.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ModelForge = require(script.Parent:WaitForChild("ModelForge"))
local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))

local BaseManager = {}
BaseManager.plotOfPlayer = {} -- player -> plot folder
BaseManager.ownerOfPlot = {} -- plot folder -> player

local basesFolder = Workspace:WaitForChild("Bases")

local function plotPads(plot)
	local pads = {}
	for i = 1, 14 do
		local pad = plot:FindFirstChild("Pad" .. i)
		if pad then
			pads[i] = pad
		end
	end
	return pads
end

-- Rebuild the models standing on a player's pads from their state.
function BaseManager.refreshDisplays(player)
	local state = PlayerState.byPlayer[player]
	local plot = BaseManager.plotOfPlayer[player]
	if not state or not plot then
		return
	end
	local displays = plot:FindFirstChild("Displays")
	if displays then
		displays:ClearAllChildren()
	else
		displays = Instance.new("Folder")
		displays.Name = "Displays"
		displays.Parent = plot
	end
	local pads = plotPads(plot)
	for index, entry in ipairs(state.placed) do
		local pad = pads[index]
		if pad then
			local model = ModelForge.build(entry, 0.9)
			local root = model.PrimaryPart
			root.CFrame = CFrame.new(pad.Position + Vector3.new(0, pad.Size.Y / 2 + root.Size.Y / 2, 0))
				* CFrame.Angles(0, math.rad(pad.Orientation.Y), 0)
			model:SetAttribute("PadIndex", index)
			model:SetAttribute("OwnerUserId", player.UserId)
			model.Parent = displays
		end
	end
	local sign = plot:FindFirstChild("SignPost")
	if sign then
		sign:SetAttribute("IncomePerSec", math.floor(PlayerState.incomePerSecond(state)))
	end
	PlayerState.sync(player)
end

-- Give a joining player the first free plot and dress it with their name.
function BaseManager.claim(player)
	local state = PlayerState.byPlayer[player]
	if not state then
		return nil
	end
	for index = 1, 6 do
		local plot = basesFolder:FindFirstChild("Base" .. index)
		if plot and not BaseManager.ownerOfPlot[plot] then
			BaseManager.ownerOfPlot[plot] = player
			BaseManager.plotOfPlayer[player] = plot
			state.baseIndex = index
			local sign = plot:FindFirstChild("SignPost")
			if sign then
				sign:SetAttribute("OwnerName", player.DisplayName)
			end
			BaseManager.refreshDisplays(player)
			BaseManager.updateDome(player)
			return plot
		end
	end
	return nil
end

-- Free a leaving player's plot and wipe its displays.
function BaseManager.release(player)
	local plot = BaseManager.plotOfPlayer[player]
	if plot then
		BaseManager.ownerOfPlot[plot] = nil
		BaseManager.plotOfPlayer[player] = nil
		local displays = plot:FindFirstChild("Displays")
		if displays then
			displays:ClearAllChildren()
		end
		local sign = plot:FindFirstChild("SignPost")
		if sign then
			sign:SetAttribute("OwnerName", "")
		end
	end
end

-- The lock dome is visible exactly while the base is steal-proof.
function BaseManager.updateDome(player)
	local state = PlayerState.byPlayer[player]
	local plot = BaseManager.plotOfPlayer[player]
	if not state or not plot then
		return
	end
	local dome = plot:FindFirstChild("LockDome")
	if dome then
		local locked = PlayerState.isLocked(state)
		dome.Transparency = locked and 0.55 or 1
		dome.CanCollide = locked
	end
end

-- Once a second: pay every player their base's income and tick lock domes.
function BaseManager.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local state = PlayerState.byPlayer[player]
				if state then
					state.coins += PlayerState.incomePerSecond(state)
					PlayerState.sync(player)
					BaseManager.updateDome(player)
				end
			end
		end
	end)
end

return BaseManager
