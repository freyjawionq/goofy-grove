-- Main.server.luau (server)
-- Goofy Grove bootstrap: makes the remotes, loads each player's state,
-- claims their base, and starts the spawner, catch and income loops.
-- Every other server module is required from here and wired together here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local WildSpawner = require(script.Parent:WaitForChild("WildSpawner"))
local CatchService = require(script.Parent:WaitForChild("CatchService"))
local ShopService = require(script.Parent:WaitForChild("ShopService"))

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = remotes

local shopAction = Instance.new("RemoteFunction")
shopAction.Name = "ShopAction"
shopAction.Parent = remotes

remotes.Parent = ReplicatedStorage

local function notify(player, kind, text)
	notifyEvent:FireClient(player, kind, text)
end

local function broadcast(kind, text)
	notifyEvent:FireAllClients(kind, text)
end

CatchService.notify = notify
CatchService.broadcast = broadcast
ShopService.notify = notify
shopAction.OnServerInvoke = function(player, action)
	return ShopService.handleAction(player, action)
end

local function onPlayerAdded(player)
	local state = PlayerState.load(player)
	BaseManager.claim(player)
	player.CharacterAdded:Connect(function(character)
		CatchService.onCharacterAdded(player, character)
	end)
	if player.Character then
		CatchService.onCharacterAdded(player, player.Character)
	end
	PlayerState.sync(player)
	notify(player, "good", "Welcome to Goofy Grove! Catch a brainrot in the Grove and dash it home!")
end

local function onPlayerRemoving(player)
	CatchService.dropCarried(player)
	BaseManager.release(player)
	PlayerState.unload(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

WildSpawner.startLoops()
CatchService.start()
BaseManager.startIncomeLoop()
ShopService.wireNests()

-- Autosave so a long session never loses a base.
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerState.save(player)
		end
	end
end)

print("Goofy Grove is open: the Gobbler is on patrol.")
