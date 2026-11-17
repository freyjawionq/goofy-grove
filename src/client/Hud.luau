-- Hud.luau (client)
-- Builds the whole ScreenGui in code: a stats bar across the top centre
-- (clear of Roblox's own menu buttons in the top-left corner), an event
-- banner under it, toasts, a carried-catch ribbon, and the shop panel with
-- eggs, upgrades, lock and rebirth. Buttons report presses through the
-- callback Main.client gives this module; nothing here talks to the server.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local Hud = {}
Hud.onAction = nil -- (action table) set by Main.client

local function label(parent, name, size, position, textSize, color)
	local text = Instance.new("TextLabel")
	text.Name = name
	text.Size = size
	text.Position = position
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextSize = textSize
	text.TextColor3 = color
	text.TextStrokeTransparency = 0.5
	text.Text = ""
	text.Parent = parent
	return text
end

local function button(parent, name, size, position, text, color)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size
	btn.Position = position
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 18
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = text
	btn.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn
	btn.Parent = parent
	return btn
end

function Hud.build(playerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "GoofyGroveGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	-- Stats bar: top centre, never under the Roblox menu (top-left corner).
	local bar = Instance.new("Frame")
	bar.Name = "StatsBar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 10)
	bar.Size = UDim2.fromOffset(560, 54)
	bar.BackgroundColor3 = Color3.fromRGB(24, 30, 24)
	bar.BackgroundTransparency = 0.25
	bar.BorderSizePixel = 0
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 12)
	barCorner.Parent = bar
	bar.Parent = gui

	local coins = label(bar, "Coins", UDim2.fromScale(0.36, 1), UDim2.fromScale(0.01, 0), 24, Color3.fromRGB(255, 225, 120))
	coins.TextXAlignment = Enum.TextXAlignment.Left
	local income = label(bar, "Income", UDim2.fromScale(0.3, 1), UDim2.fromScale(0.37, 0), 20, Color3.fromRGB(160, 255, 160))
	local rebirths = label(bar, "Rebirths", UDim2.fromScale(0.3, 1), UDim2.fromScale(0.68, 0), 20, Color3.fromRGB(255, 170, 240))
	rebirths.TextXAlignment = Enum.TextXAlignment.Right

	-- Event banner: big centred text for Gobbler hunts and steals.
	local banner = label(gui, "Banner", UDim2.fromOffset(900, 60), UDim2.new(0.5, -450, 0, 76), 34, Color3.fromRGB(255, 120, 90))
	banner.TextTransparency = 1

	-- Toasts stack under the banner.
	local toasts = Instance.new("Frame")
	toasts.Name = "Toasts"
	toasts.AnchorPoint = Vector2.new(0.5, 0)
	toasts.Position = UDim2.new(0.5, 0, 0, 140)
	toasts.Size = UDim2.fromOffset(620, 200)
	toasts.BackgroundTransparency = 1
	toasts.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	toastLayout.Padding = UDim.new(0, 4)
	toastLayout.Parent = toasts

	-- Carried ribbon: what is on your head and what to do with it.
	local carried = label(gui, "Carried", UDim2.fromOffset(700, 40), UDim2.new(0.5, -350, 1, -118), 22, Color3.fromRGB(255, 240, 170))

	-- Buttons, bottom right.
	local shopButton = button(gui, "ShopButton", UDim2.fromOffset(150, 52), UDim2.new(1, -166, 1, -64), "SHOP", Color3.fromRGB(46, 160, 80))
	local lockButton = button(gui, "LockButton", UDim2.fromOffset(150, 52), UDim2.new(1, -166, 1, -124), "LOCK BASE", Color3.fromRGB(60, 110, 200))

	-- Shop panel: hidden until the SHOP button opens it.
	local panel = Instance.new("Frame")
	panel.Name = "ShopPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.52)
	panel.Size = UDim2.fromOffset(620, 470)
	panel.BackgroundColor3 = Color3.fromRGB(26, 32, 26)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Visible = false
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 14)
	panelCorner.Parent = panel
	panel.Parent = gui

	local title = label(panel, "Title", UDim2.new(1, 0, 0, 44), UDim2.fromOffset(0, 4), 26, Color3.fromRGB(255, 225, 120))
	title.Text = "GOOFY GROVE SHOP"

	local rows = Instance.new("Frame")
	rows.Name = "Rows"
	rows.Position = UDim2.fromOffset(16, 52)
	rows.Size = UDim2.new(1, -32, 1, -110)
	rows.BackgroundTransparency = 1
	rows.Parent = panel
	local rowsLayout = Instance.new("UIListLayout")
	rowsLayout.Padding = UDim.new(0, 6)
	rowsLayout.Parent = rows

	local function shopRow(text, priceText, action)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundColor3 = Color3.fromRGB(40, 48, 40)
		row.BorderSizePixel = 0
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row
		local name = label(row, "Name", UDim2.new(0.62, 0, 1, 0), UDim2.fromOffset(10, 0), 16, Color3.fromRGB(240, 240, 230))
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = text
		local buy = button(row, "Buy", UDim2.fromOffset(130, 32), UDim2.new(1, -138, 0, 4), priceText, Color3.fromRGB(46, 160, 80))
		buy.TextSize = 15
		buy.MouseButton1Click:Connect(function()
			if Hud.onAction then
				Hud.onAction(action)
			end
		end)
		row.Parent = rows
		return row
	end

	for _, egg in ipairs(BrainrotDefs.Eggs) do
		shopRow(egg.name .. " - hatch a surprise brainrot", Format.coins(egg.price), { kind = "BuyEgg", id = egg.id })
	end
	for _, upgrade in ipairs(BrainrotDefs.Upgrades) do
		shopRow(upgrade.name .. " - " .. upgrade.blurb, Format.coins(upgrade.prices[1]) .. "+", { kind = "BuyUpgrade", id = upgrade.id })
	end
	local rebirthRow = shopRow("REBIRTH - reset for a permanent income boost", "see panel", { kind = "Rebirth" })
	local rebirthNote = rebirthRow:FindFirstChild("Name")

	local close = button(panel, "Close", UDim2.fromOffset(120, 36), UDim2.new(0.5, -60, 1, -48), "CLOSE", Color3.fromRGB(150, 60, 60))

	shopButton.MouseButton1Click:Connect(function()
		panel.Visible = not panel.Visible
	end)
	close.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)
	lockButton.MouseButton1Click:Connect(function()
		if Hud.onAction then
			Hud.onAction({ kind = "ToggleLock" })
		end
	end)

	local handles = {
		gui = gui,
		coins = coins,
		income = income,
		rebirths = rebirths,
		banner = banner,
		toasts = toasts,
		carried = carried,
		lockButton = lockButton,
		rebirthNote = rebirthNote,
	}
	return handles
end

local KIND_COLORS = {
	good = Color3.fromRGB(150, 255, 150),
	warn = Color3.fromRGB(255, 210, 110),
	bad = Color3.fromRGB(255, 130, 120),
	event = Color3.fromRGB(255, 120, 90),
}

-- A fading line in the toast stack.
function Hud.toast(handles, kind, text)
	local toast = label(handles.toasts, "Toast", UDim2.new(1, 0, 0, 30), UDim2.new(), 19, KIND_COLORS[kind] or Color3.fromRGB(255, 255, 255))
	toast.Text = text
	task.delay(4, function()
		toast:Destroy()
	end)
end

-- The big centre banner, for events everyone should see.
function Hud.showBanner(handles, text)
	handles.banner.Text = text
	handles.banner.TextTransparency = 0
	task.delay(3.5, function()
		handles.banner.TextTransparency = 1
	end)
end

-- Refresh every number from the player's attributes (set by PlayerState).
function Hud.refresh(handles, player)
	handles.coins.Text = Format.coins(player:GetAttribute("Coins") or 0)
	handles.income.Text = "+$" .. Format.number(player:GetAttribute("IncomePerSec") or 0) .. "/s"
	local rebirths = player:GetAttribute("Rebirths") or 0
	handles.rebirths.Text = "Rebirths: " .. rebirths
	local carrying = player:GetAttribute("CarryingName") or ""
	if carrying ~= "" then
		handles.carried.Text = "Carrying " .. carrying .. " - dash home to bank it!"
	else
		handles.carried.Text = ""
	end
	local lockSeconds = player:GetAttribute("LockSeconds") or 0
	if lockSeconds > 0 then
		handles.lockButton.Text = "LOCKED " .. Format.clock(lockSeconds)
	else
		handles.lockButton.Text = "LOCK BASE"
	end
	if handles.rebirthNote then
		handles.rebirthNote.Text = "REBIRTH - next costs " .. Format.coins(BrainrotDefs.rebirthCost(rebirths))
			.. ", income x" .. string.format("%.2g", BrainrotDefs.incomeMult(rebirths + 1))
	end
end

return Hud
