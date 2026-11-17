-- ModelForge.luau (server)
-- Builds a brainrot's 3D model from its BrainrotDefs recipe: one anchored
-- Root part, every extra part welded to it, a face, and a floating label
-- with its name, rarity and income rate. Wild spawns, base displays and the
-- carried catch all come from here, so a character looks the same everywhere.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotDefs = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotDefs"))
local Format = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Format"))

local ModelForge = {}

local function makePart(shape, size, color, material)
	local part = Instance.new("Part")
	part.Shape = if shape == "Ball" then Enum.PartType.Ball else Enum.PartType.Block
	part.Size = Vector3.new(size[1], size[2], size[3])
	part.Color = Color3.fromRGB(color[1], color[2], color[3])
	part.Material = Enum.Material[material or "SmoothPlastic"]
	part.CanCollide = false
	part.CastShadow = true
	return part
end

local function weldTo(part, root, offset)
	part.CFrame = root.CFrame * CFrame.new(offset[1], offset[2], offset[3])
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = root.Parent
end

-- The floating label every brainrot wears: name, rarity, coins per second.
local function makeLabel(root, entry, scale)
	local def = BrainrotDefs.ById[entry.defId]
	local rarity = BrainrotDefs.RarityById[def.rarity]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220 * scale, 74 * scale)
	gui.StudsOffset = Vector3.new(0, root.Size.Y / 2 + 1.6 * scale, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 90

	local name = Instance.new("TextLabel")
	name.Name = "NameLine"
	name.Size = UDim2.fromScale(1, 0.42)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextSize = 20 * scale
	name.TextColor3 = rarity.color
	name.TextStrokeTransparency = 0.4
	name.Text = BrainrotDefs.displayName(entry)
	name.Parent = gui

	local rate = Instance.new("TextLabel")
	rate.Name = "RateLine"
	rate.Position = UDim2.fromScale(0, 0.44)
	rate.Size = UDim2.fromScale(1, 0.4)
	rate.BackgroundTransparency = 1
	rate.Font = Enum.Font.FredokaOne
	rate.TextSize = 17 * scale
	rate.TextColor3 = Color3.fromRGB(255, 235, 150)
	rate.TextStrokeTransparency = 0.4
	rate.Text = "$" .. Format.number(BrainrotDefs.rateOf(entry, 0)) .. "/s"
	rate.Parent = gui

	gui.Parent = root
	return gui
end

-- build(entry, scale) -> Model with PrimaryPart "Root", ready to place.
-- entry is { defId = ..., mutation = ... } as BrainrotDefs rolls them.
function ModelForge.build(entry, scale)
	scale = scale or 1
	local def = BrainrotDefs.ById[entry.defId]
	assert(def, "unknown brainrot " .. tostring(entry.defId))

	local model = Instance.new("Model")
	model.Name = def.id

	local root = makePart(def.body.shape, def.body.size, def.body.color, def.body.material)
	root.Name = "Root"
	root.Anchored = true
	root.Size = root.Size * scale
	root.Parent = model
	model.PrimaryPart = root

	-- A mutation tints the whole body toward its colour.
	if entry.mutation then
		for _, mutation in ipairs(BrainrotDefs.Mutations) do
			if mutation.id == entry.mutation then
				root.Color = root.Color:Lerp(mutation.color, 0.45)
			end
		end
	end

	for _, extra in ipairs(def.extras or {}) do
		local part = makePart(extra.shape, extra.size, extra.color, extra.material)
		part.Name = "Extra"
		part.Size = part.Size * scale
		part.Parent = model
		weldTo(part, root, { extra.offset[1] * scale, extra.offset[2] * scale, extra.offset[3] * scale })
	end

	-- Eyes: two dark beads on the front face, so every character reads as a face.
	local faceZ = root.Size.Z / 2
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Ball", { 0.34, 0.34, 0.34 }, { 25, 20, 30 }, "SmoothPlastic")
		eye.Name = "Eye"
		eye.Size = eye.Size * scale
		eye.Parent = model
		weldTo(eye, root, { side * root.Size.X * 0.22, root.Size.Y * 0.12, faceZ })
	end

	makeLabel(root, entry, scale)
	model:SetAttribute("DefId", entry.defId)
	model:SetAttribute("Mutation", entry.mutation or "")
	return model
end

-- The Gobbler: the Grove's threat, a big sludge blob with a wide mouth.
-- Not part of the cast; nothing earns from it and it earns from you.
function ModelForge.buildGobbler()
	local model = Instance.new("Model")
	model.Name = "Gobbler"

	local root = makePart("Ball", { 7, 5.5, 7 }, { 84, 130, 60 }, "Slimy")
	root.Name = "Root"
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root

	local belly = makePart("Ball", { 5.6, 4.4, 5.6 }, { 104, 155, 74 }, "Slimy")
	belly.Parent = model
	weldTo(belly, root, { 0, 1.8, 0.6 })

	local mouth = makePart("Box", { 4.4, 1.1, 0.6 }, { 26, 14, 20 }, "SmoothPlastic")
	mouth.Name = "Mouth"
	mouth.Parent = model
	weldTo(mouth, root, { 0, -0.4, 3.4 })

	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Ball", { 1.1, 1.1, 1.1 }, { 255, 240, 120 }, "Neon")
		eye.Name = "Eye"
		eye.Parent = model
		weldTo(eye, root, { side * 1.7, 2.6, 2.9 })
	end

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(260, 60)
	gui.StudsOffset = Vector3.new(0, 5.4, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextSize = 26
	text.TextColor3 = Color3.fromRGB(160, 255, 130)
	text.TextStrokeTransparency = 0.35
	text.Text = "THE GOBBLER"
	text.Parent = gui
	gui.Parent = root

	return model
end

return ModelForge
