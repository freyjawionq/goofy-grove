-- Main.client.luau (client)
-- Builds the HUD and connects it to the server: shop buttons go through the
-- ShopAction RemoteFunction, server notices arrive on the Notify RemoteEvent,
-- and the numbers follow the attributes PlayerState keeps on the player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Hud = require(script.Parent:WaitForChild("Hud"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyEvent = remotes:WaitForChild("Notify")
local shopAction = remotes:WaitForChild("ShopAction")

local handles = Hud.build(player:WaitForChild("PlayerGui"))

Hud.onAction = function(action)
	task.spawn(function()
		shopAction:InvokeServer(action)
	end)
end

notifyEvent.OnClientEvent:Connect(function(kind, text)
	if kind == "event" then
		Hud.showBanner(handles, text)
	else
		Hud.toast(handles, kind, text)
	end
end)

local function refresh()
	Hud.refresh(handles, player)
end

for _, attribute in ipairs({ "Coins", "IncomePerSec", "Rebirths", "CarryingName", "LockSeconds" }) do
	player:GetAttributeChangedSignal(attribute):Connect(refresh)
end

-- The lock countdown changes every second even when nothing else does.
task.spawn(function()
	while true do
		task.wait(1)
		refresh()
	end
end)

refresh()
