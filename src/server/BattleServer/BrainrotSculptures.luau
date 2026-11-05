-- Shared procedural brainrot sculptures. Scale multiplies sizes and offsets.
-- No Humanoid, pathfinding, collision, or web image URLs.
local Sculptures = {}
Sculptures.PARADE_SCALE = 1.75

local WOOD = Color3.fromRGB(196, 148, 86)
local WOOD_DARK = Color3.fromRGB(92, 58, 32)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local SHARK = Color3.fromRGB(64, 168, 214)
local BELLY = Color3.fromRGB(245, 248, 252)
local SHOE = Color3.fromRGB(28, 108, 220)
local SOLE = Color3.fromRGB(32, 36, 42)
local HIDE = Color3.fromRGB(74, 122, 64)
local METAL = Color3.fromRGB(146, 152, 146)
local ELEPHANT = Color3.fromRGB(196, 176, 150)
local EAR_PINK = Color3.fromRGB(214, 160, 150)
local CACTUS = Color3.fromRGB(46, 140, 62)
local SANDAL = Color3.fromRGB(138, 84, 40)
local FUR = Color3.fromRGB(92, 58, 36)
local FACE = Color3.fromRGB(214, 164, 112)
local BANANA = Color3.fromRGB(245, 208, 48)
local PEEL = Color3.fromRGB(232, 220, 140)
local CUP = Color3.fromRGB(250, 250, 248)
local COFFEE = Color3.fromRGB(122, 72, 40)
local FOAM = Color3.fromRGB(255, 248, 236)
local TUTU = Color3.fromRGB(255, 150, 186)
local SLIPPER = Color3.fromRGB(255, 182, 196)
local SHRIMP = Color3.fromRGB(255, 126, 64)
local CAT = Color3.fromRGB(255, 214, 170)
local SKIN = Color3.fromRGB(186, 132, 92)
local LEAF = Color3.fromRGB(36, 130, 52)
local ROOT = Color3.fromRGB(110, 72, 40)

local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local MAT_WOOD = Enum.Material.Wood
local MAT_METAL = Enum.Material.Metal
local MAT_PLASTIC = Enum.Material.SmoothPlastic

local function emit(list, scale, name, sx, sy, sz, color, x, y, z, shape, material, rz, upright)
	local rx, ry = 0, 0
	if type(rz) == "table" then
		rx = rz.X or 0
		ry = rz.Y or 0
		upright = rz.Upright
		rz = rz.Z
	end
	local offset = CFrame.new(x * scale, y * scale, z * scale)
	if upright then
		offset = offset * CFrame.Angles(0, 0, math.rad(90))
	end
	if rx ~= 0 or ry ~= 0 or rz then
		offset = offset * CFrame.Angles(math.rad(rx), math.rad(ry), math.rad(rz or 0))
	end
	table.insert(list, {
		Name = name,
		Size = Vector3.new(sx * scale, sy * scale, sz * scale),
		Color = color,
		Offset = offset,
		Shape = shape,
		Material = material or MAT_PLASTIC,
	})
end

local function tung(list, scale)
	-- Upright oak log with bulging eyes and a baseball bat, matching the wooden Sahur figure.
	emit(list, scale, "Log", 4.2, 1.15, 1.15, WOOD, 0, 2.7, 0, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "LogCap", 0.28, 0.95, 0.95, WOOD_DARK, 0, 4.75, 0, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "EyeL", 0.62, 0.62, 0.62, WHITE, -0.28, 3.35, -0.62, BALL, MAT_PLASTIC)
	emit(list, scale, "EyeR", 0.62, 0.62, 0.62, WHITE, 0.28, 3.35, -0.62, BALL, MAT_PLASTIC)
	emit(list, scale, "PupilL", 0.24, 0.24, 0.24, BLACK, -0.28, 3.32, -0.9, BALL, MAT_PLASTIC)
	emit(list, scale, "PupilR", 0.24, 0.24, 0.24, BLACK, 0.28, 3.32, -0.9, BALL, MAT_PLASTIC)
	emit(list, scale, "Mouth", 0.42, 0.1, 0.08, WOOD_DARK, 0, 2.85, -0.62)
	emit(list, scale, "ArmL", 1.55, 0.38, 0.38, WOOD, -1.05, 2.55, 0, CYL, MAT_WOOD, {Z = 58})
	emit(list, scale, "ArmR", 1.55, 0.38, 0.38, WOOD, 1.05, 2.15, -0.15, CYL, MAT_WOOD, {Z = -28})
	emit(list, scale, "LegL", 1.25, 0.28, 0.28, WOOD, -0.28, 0.85, 0, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "LegR", 1.25, 0.28, 0.28, WOOD, 0.28, 0.85, 0, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "FootL", 0.5, 0.18, 0.72, WOOD_DARK, -0.28, 0.16, -0.12, nil, MAT_WOOD)
	emit(list, scale, "FootR", 0.5, 0.18, 0.72, WOOD_DARK, 0.28, 0.16, -0.12, nil, MAT_WOOD)
	emit(list, scale, "BatHandle", 1.1, 0.2, 0.2, WOOD_DARK, 1.35, 1.55, -0.35, CYL, MAT_WOOD, {Z = -62})
	emit(list, scale, "Club", 1.7, 0.48, 0.48, WOOD_DARK, 1.85, 2.55, -0.55, CYL, MAT_WOOD, {Z = -62})
	return 5.1 * scale
end

local function shark(list, scale)
	-- Horizontal blue shark walking on three blue sneakers with white swooshes.
	emit(list, scale, "Body", 1.05, 0.9, 3.5, SHARK, 0, 1.85, 0.15)
	emit(list, scale, "Belly", 0.72, 0.32, 2.5, BELLY, 0, 1.38, 0.05)
	emit(list, scale, "Snout", 0.55, 0.42, 1.15, SHARK, 0, 1.72, -1.95)
	emit(list, scale, "Fin", 0.12, 0.95, 0.7, SHARK, 0, 2.55, 0.15)
	emit(list, scale, "Tail", 0.12, 0.95, 0.7, SHARK, 0, 1.95, 2.15, nil, nil, {Y = 18})
	emit(list, scale, "TailLobe", 0.1, 0.7, 0.55, SHARK, 0, 1.7, 2.35, nil, nil, {Y = -22})
	emit(list, scale, "Gill", 0.08, 0.35, 0.5, Color3.fromRGB(40, 110, 150), -0.58, 1.75, -0.35)
	emit(list, scale, "EyeL", 0.26, 0.26, 0.16, WHITE, -0.72, 1.95, -1.15, BALL, MAT_PLASTIC)
	emit(list, scale, "EyeR", 0.26, 0.26, 0.16, WHITE, 0.72, 1.95, -1.15, BALL, MAT_PLASTIC)
	emit(list, scale, "PupilL", 0.12, 0.12, 0.08, BLACK, -0.82, 1.95, -1.2, BALL, MAT_PLASTIC)
	emit(list, scale, "PupilR", 0.12, 0.12, 0.08, BLACK, 0.82, 1.95, -1.2, BALL, MAT_PLASTIC)
	local shoes = {
		{ "L", -0.62, -0.45 },
		{ "M", 0, 0.35 },
		{ "R", 0.62, -0.1 },
	}
	for _, shoe in ipairs(shoes) do
		local id, x, z = shoe[1], shoe[2], shoe[3]
		emit(list, scale, "LegShoe" .. id, 0.16, 0.42, 0.16, SHARK, x, 1.22, z, CYL, MAT_PLASTIC, nil, true)
		emit(list, scale, "Shoe" .. id, 0.78, 0.32, 1.28, SHOE, x, 0.92, z - 0.08)
		emit(list, scale, "Sole" .. id, 0.82, 0.1, 1.36, SOLE, x, 0.72, z - 0.06)
		emit(list, scale, "Swoosh" .. id, 0.5, 0.08, 0.14, WHITE, x, 1.05, z - 0.22)
		emit(list, scale, "Toe" .. id, 0.28, 0.22, 0.28, SHOE, x, 0.96, z - 0.62, BALL, MAT_PLASTIC)
	end
	return 3.2 * scale
end

local function croc(list, scale)
	-- Olive crocodile head on a grey bomber: long snout, open jaw, wings, props, belly bomb.
	emit(list, scale, "Fuselage", 0.85, 0.72, 4.6, METAL, 0, 1.9, 0.55, nil, MAT_METAL)
	emit(list, scale, "Wing", 4.4, 0.1, 1.35, METAL, 0, 1.85, 0.2, nil, MAT_METAL)
	emit(list, scale, "TailFin", 0.1, 0.85, 0.7, METAL, 0, 2.35, 2.7, nil, MAT_METAL)
	emit(list, scale, "Cockpit", 0.45, 0.28, 0.7, Color3.fromRGB(170, 210, 220), 0, 2.32, -0.4)
	emit(list, scale, "Head", 0.7, 0.55, 2.15, HIDE, 0, 1.95, -2.15)
	emit(list, scale, "SnoutRidge", 0.28, 0.16, 1.4, Color3.fromRGB(58, 96, 50), 0, 2.25, -2.35)
	emit(list, scale, "Jaw", 0.62, 0.22, 1.55, HIDE, 0, 1.52, -2.35)
	emit(list, scale, "Teeth", 0.48, 0.1, 1.15, WHITE, 0, 1.68, -2.55)
	emit(list, scale, "EyeL", 0.2, 0.16, 0.16, Color3.fromRGB(230, 190, 40), -0.28, 2.15, -1.7, BALL)
	emit(list, scale, "EyeR", 0.2, 0.16, 0.16, Color3.fromRGB(230, 190, 40), 0.28, 2.15, -1.7, BALL)
	emit(list, scale, "PropL", 1.15, 0.1, 0.1, Color3.fromRGB(36, 36, 40), -1.7, 1.85, -0.35, CYL, MAT_METAL)
	emit(list, scale, "PropR", 1.15, 0.1, 0.1, Color3.fromRGB(36, 36, 40), 1.7, 1.85, -0.35, CYL, MAT_METAL)
	emit(list, scale, "Bomb", 0.38, 0.38, 0.95, Color3.fromRGB(62, 74, 42), 0, 1.15, 0.35, nil, MAT_METAL)
	return 2.9 * scale
end

local function elephant(list, scale)
	-- Elephant head on a cactus body, floppy ears, hanging trunk, sandals.
	emit(list, scale, "Cactus", 1.7, 0.7, 0.7, CACTUS, 0, 1.85, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "Head", 1.25, 1.05, 1.2, ELEPHANT, 0, 3.45, -0.05, BALL, MAT_PLASTIC)
	emit(list, scale, "EarL", 0.14, 1.15, 0.85, ELEPHANT, -0.78, 3.4, 0.05)
	emit(list, scale, "EarR", 0.14, 1.15, 0.85, ELEPHANT, 0.78, 3.4, 0.05)
	emit(list, scale, "EarInL", 0.06, 0.7, 0.48, EAR_PINK, -0.86, 3.4, -0.02)
	emit(list, scale, "EarInR", 0.06, 0.7, 0.48, EAR_PINK, 0.86, 3.4, -0.02)
	emit(list, scale, "Trunk", 1.35, 0.28, 0.28, ELEPHANT, 0, 2.7, -0.55, CYL, MAT_PLASTIC, {X = 28, Upright = true})
	emit(list, scale, "TrunkTip", 0.55, 0.22, 0.22, ELEPHANT, 0, 1.95, -0.95, CYL, MAT_PLASTIC, {X = 70, Upright = true})
	emit(list, scale, "TuskL", 0.1, 0.48, 0.1, WHITE, -0.22, 2.85, -0.72)
	emit(list, scale, "TuskR", 0.1, 0.48, 0.1, WHITE, 0.22, 2.85, -0.72)
	emit(list, scale, "EyeL", 0.16, 0.16, 0.1, BLACK, -0.28, 3.6, -0.55, BALL)
	emit(list, scale, "EyeR", 0.16, 0.16, 0.1, BLACK, 0.28, 3.6, -0.55, BALL)
	emit(list, scale, "LegL", 1.45, 0.4, 0.4, CACTUS, -0.32, 1.15, 0.05, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "LegR", 1.45, 0.4, 0.4, CACTUS, 0.32, 1.15, 0.05, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "SandalL", 0.62, 0.16, 0.9, SANDAL, -0.32, 0.38, -0.05)
	emit(list, scale, "SandalR", 0.62, 0.16, 0.9, SANDAL, 0.32, 0.38, -0.05)
	emit(list, scale, "StrapL", 0.5, 0.08, 0.16, Color3.fromRGB(92, 52, 28), -0.32, 0.5, -0.2)
	emit(list, scale, "StrapR", 0.5, 0.08, 0.16, Color3.fromRGB(92, 52, 28), 0.32, 0.5, -0.2)
	return 4.3 * scale
end

local function banana(list, scale)
	-- Brown chimp head sitting in a peeled yellow banana.
	emit(list, scale, "Head", 1.15, 1.05, 1.05, FUR, 0, 3.25, 0, BALL, MAT_PLASTIC)
	emit(list, scale, "Face", 0.7, 0.55, 0.28, FACE, 0, 3.1, -0.48)
	emit(list, scale, "Muzzle", 0.42, 0.28, 0.28, FACE, 0, 2.85, -0.62, BALL, MAT_PLASTIC)
	emit(list, scale, "EyeL", 0.16, 0.16, 0.1, WHITE, -0.2, 3.28, -0.55, BALL)
	emit(list, scale, "EyeR", 0.16, 0.16, 0.1, WHITE, 0.2, 3.28, -0.55, BALL)
	emit(list, scale, "EarL", 0.42, 0.42, 0.14, Color3.fromRGB(168, 110, 90), -0.62, 3.4, -0.05, BALL, MAT_PLASTIC)
	emit(list, scale, "EarR", 0.42, 0.42, 0.14, Color3.fromRGB(168, 110, 90), 0.62, 3.4, -0.05, BALL, MAT_PLASTIC)
	emit(list, scale, "Banana", 1.35, 1.7, 1.45, BANANA, 0, 1.85, 0.05, BALL, MAT_PLASTIC)
	emit(list, scale, "PeelL", 0.16, 1.55, 0.7, PEEL, -0.85, 1.7, 0.1, nil, MAT_PLASTIC, {Z = 28})
	emit(list, scale, "PeelR", 0.16, 1.55, 0.7, PEEL, 0.85, 1.7, 0.1, nil, MAT_PLASTIC, {Z = -28})
	emit(list, scale, "PeelFront", 0.7, 1.2, 0.14, PEEL, 0, 1.45, -0.75, nil, MAT_PLASTIC, {X = -18})
	return 4.0 * scale
end

local function ballerina(list, scale)
	-- White cappuccino cup, foam, pink tutu, one arm in a ballet line, slippers.
	emit(list, scale, "Cup", 1.45, 1.2, 1.2, CUP, 0, 3.15, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "Coffee", 0.1, 0.9, 0.9, COFFEE, 0, 3.78, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "Foam", 0.35, 0.85, 0.85, FOAM, 0, 3.95, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "EyeL", 0.16, 0.18, 0.08, BLACK, -0.22, 3.2, -0.62, BALL)
	emit(list, scale, "EyeR", 0.16, 0.18, 0.08, BLACK, 0.22, 3.2, -0.62, BALL)
	emit(list, scale, "Smile", 0.32, 0.08, 0.06, Color3.fromRGB(180, 90, 110), 0, 2.9, -0.62)
	emit(list, scale, "Handle", 0.12, 0.55, 0.12, CUP, 0.78, 3.25, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "Handle0", 0.42, 0.12, 0.12, CUP, 0.95, 3.15, 0, CYL, MAT_PLASTIC)
	emit(list, scale, "Tutu", 0.22, 1.85, 1.85, TUTU, 0, 2.15, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "TutuPleat0", 0.16, 0.7, 0.35, TUTU, 0, 2.05, 0.95)
	emit(list, scale, "TutuPleat1", 0.35, 0.7, 0.16, TUTU, 0.9, 2.05, 0.15)
	emit(list, scale, "TutuPleat2", 0.35, 0.7, 0.16, TUTU, -0.9, 2.05, 0.15)
	emit(list, scale, "ArmUp", 0.95, 0.14, 0.14, CUP, 0.45, 2.85, 0, CYL, MAT_PLASTIC, {Z = -70})
	emit(list, scale, "ArmOut", 0.9, 0.14, 0.14, CUP, -0.7, 2.35, 0, CYL, MAT_PLASTIC, {Z = 18})
	emit(list, scale, "LegStand", 0.85, 0.16, 0.16, CUP, -0.12, 1.15, 0, CYL, MAT_PLASTIC, nil, true)
	emit(list, scale, "LegPoint", 0.7, 0.14, 0.14, CUP, 0.28, 0.85, -0.15, CYL, MAT_PLASTIC, {X = 55, Upright = true})
	emit(list, scale, "BalletShoe0", 0.26, 0.14, 0.48, SLIPPER, -0.12, 0.7, -0.08)
	emit(list, scale, "BalletShoe1", 0.24, 0.12, 0.5, SLIPPER, 0.42, 0.48, -0.42)
	return 4.3 * scale
end

local function shrimp(list, scale)
	-- Cat face on a curved shrimp, fan tail, exactly three legs.
	emit(list, scale, "Head", 1.05, 0.95, 1.0, CAT, 0, 2.15, -0.85, BALL, MAT_PLASTIC)
	emit(list, scale, "EarL", 0.16, 0.48, 0.28, SHRIMP, -0.38, 2.7, -0.8)
	emit(list, scale, "EarR", 0.16, 0.48, 0.28, SHRIMP, 0.38, 2.7, -0.8)
	emit(list, scale, "EarInL", 0.08, 0.28, 0.16, EAR_PINK, -0.38, 2.68, -0.9)
	emit(list, scale, "EarInR", 0.08, 0.28, 0.16, EAR_PINK, 0.38, 2.68, -0.9)
	emit(list, scale, "EyeL", 0.16, 0.2, 0.08, Color3.fromRGB(80, 190, 70), -0.2, 2.2, -1.28, BALL)
	emit(list, scale, "EyeR", 0.16, 0.2, 0.08, Color3.fromRGB(80, 190, 70), 0.2, 2.2, -1.28, BALL)
	emit(list, scale, "Nose", 0.12, 0.1, 0.1, Color3.fromRGB(255, 140, 160), 0, 2.0, -1.32, BALL)
	emit(list, scale, "WhiskerL", 0.55, 0.04, 0.04, WHITE, -0.45, 1.95, -1.15, CYL, MAT_PLASTIC)
	emit(list, scale, "WhiskerR", 0.55, 0.04, 0.04, WHITE, 0.45, 1.95, -1.15, CYL, MAT_PLASTIC)
	emit(list, scale, "Shell", 0.8, 0.62, 1.55, SHRIMP, 0, 1.75, 0.35)
	emit(list, scale, "Segment", 0.65, 0.5, 0.7, Color3.fromRGB(230, 100, 48), 0, 1.65, 1.15)
	emit(list, scale, "Tail", 0.12, 0.85, 0.7, SHRIMP, 0, 1.7, 1.7)
	emit(list, scale, "TailFan", 0.7, 0.12, 0.55, SHRIMP, 0, 1.55, 2.0)
	local legs = { {0, -0.42, 0.15}, {1, 0.4, 0.55}, {2, -0.05, 0.95} }
	for _, leg in ipairs(legs) do
		emit(list, scale, "Leg" .. leg[1], 0.14, 0.72, 0.14, SHRIMP, leg[2], 1.15, leg[3], CYL, MAT_PLASTIC, nil, true)
	end
	return 3.2 * scale
end

local function patapim(list, scale)
	-- Tree monkey: leafy crown, long nose, root legs, and feet larger than the body.
	emit(list, scale, "FootL", 1.7, 0.32, 2.6, SKIN, -0.85, 0.22, 0.15)
	emit(list, scale, "FootR", 1.7, 0.32, 2.6, SKIN, 0.85, 0.22, 0.15)
	emit(list, scale, "ToeL", 0.35, 0.2, 0.4, SKIN, -0.85, 0.28, -1.05, BALL, MAT_PLASTIC)
	emit(list, scale, "ToeR", 0.35, 0.2, 0.4, SKIN, 0.85, 0.28, -1.05, BALL, MAT_PLASTIC)
	emit(list, scale, "RootL", 0.32, 1.35, 0.32, ROOT, -0.4, 1.05, 0.05, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "RootR", 0.32, 1.35, 0.32, ROOT, 0.4, 1.05, 0.05, CYL, MAT_WOOD, nil, true)
	emit(list, scale, "Canopy", 1.45, 1.25, 1.35, LEAF, 0, 2.55, 0.05, BALL, MAT_PLASTIC)
	emit(list, scale, "LeafL", 0.7, 0.35, 0.55, Color3.fromRGB(28, 110, 44), -0.7, 3.05, 0.1, BALL, MAT_PLASTIC)
	emit(list, scale, "LeafR", 0.7, 0.35, 0.55, Color3.fromRGB(28, 110, 44), 0.7, 3.05, 0.1, BALL, MAT_PLASTIC)
	emit(list, scale, "Face", 0.7, 0.55, 0.25, SKIN, 0, 2.45, -0.55)
	emit(list, scale, "Nose", 0.28, 0.28, 1.35, SKIN, 0, 2.4, -1.15, CYL, MAT_PLASTIC)
	emit(list, scale, "EyeL", 0.16, 0.16, 0.08, BLACK, -0.2, 2.65, -0.68, BALL, MAT_PLASTIC)
	emit(list, scale, "EyeR", 0.16, 0.16, 0.08, BLACK, 0.2, 2.65, -0.68, BALL, MAT_PLASTIC)
	return 3.4 * scale
end

local BUILDERS = {
	["Tung Tung Tung Sahur"] = tung,
	["Tralalero Tralala"] = shark,
	["Bombardiro Crocodilo"] = croc,
	["Lirili Larila"] = elephant,
	["Chimpanzini Bananini"] = banana,
	["Ballerina Cappuccina"] = ballerina,
	["Trippi Troppi"] = shrimp,
	["Brr Brr Patapim"] = patapim,
}

-- Extra silhouette and surface detail, shared by selection displays and objectives.
-- All geometry is generated locally; no downloaded meshes or texture dependencies.
local function detail(list, scale, name)
    local function add(id,sx,sy,sz,color,x,y,z,shape,material,rotation,upright)
        emit(list,scale,id,sx,sy,sz,color,x,y,z,shape,material,rotation,upright)
    end
    if name == "Tung Tung Tung Sahur" then
        for n=1,9 do
            local a=n*math.pi*2/9
            add("BarkGrain"..n,0.045,2.1+(n%3)*0.4,0.045,WOOD_DARK,math.cos(a)*0.57,2.55,math.sin(a)*0.57,nil,MAT_WOOD)
        end
        for _,side in ipairs({-1,1}) do
            add("Brow"..side,0.55,0.12,0.16,WOOD_DARK,side*0.29,3.78,-0.69,nil,MAT_WOOD,{Z=side*12})
            add("Hand"..side,0.42,0.5,0.4,WOOD,side*1.55,side==1 and 1.85 or 1.95,-0.12,BALL,MAT_WOOD)
            for n=1,3 do
                add("Finger"..side..n,0.09,0.3,0.13,WOOD_DARK,side*1.55+(n-2)*0.11,1.72,-0.32,BALL,MAT_WOOD)
            end
        end
        add("Nose",0.22,0.4,0.27,WOOD,0,3.02,-0.76,BALL,MAT_WOOD)
        add("LowerLip",0.4,0.07,0.13,WOOD,0,2.76,-0.66)
        add("BatKnob",0.13,0.32,0.32,WOOD,1.08,1.07,-0.35,CYL,MAT_WOOD,{Z=-62})
    elseif name == "Tralalero Tralala" then
        for _,spec in ipairs(list) do
            if spec.Name=="Body" or spec.Name=="Snout" then spec.Shape=BALL end
        end
        for _,side in ipairs({-1,1}) do
            add("PectoralFin"..side,0.85,0.13,1.05,SHARK,side*0.72,1.6,0.2,nil,nil,{Z=side*22,Y=side*25})
            add("MouthLine"..side,0.035,0.14,0.8,BLACK,side*0.26,1.55,-1.92)
            for n=1,4 do
                add("Tooth"..side..n,0.07,0.12,0.08,WHITE,side*0.28,1.57,-1.6-n*0.16)
                add("GillSlit"..side..n,0.04,0.32,0.045,Color3.fromRGB(34,91,120),side*0.52,1.87,-0.25-n*0.14)
            end
        end
        for _,shoe in ipairs({{"L",-0.62,-0.45},{"M",0,0.35},{"R",0.62,-0.1}}) do
            for n=1,3 do
                add("Lace"..shoe[1]..n,0.45,0.035,0.045,WHITE,shoe[2],1.095,shoe[3]-0.1-n*0.12)
            end
            add("ShoeHeel"..shoe[1],0.65,0.33,0.18,SHOE,shoe[2],1.06,shoe[3]+0.43)
        end
    elseif name == "Bombardiro Crocodilo" then
        for _,side in ipairs({-1,1}) do
            add("Engine"..side,0.48,0.48,1.3,HIDE,side*1.6,1.8,-0.12,BALL,MAT_METAL)
            add("PropBlade"..side,0.12,1.2,0.1,BLACK,side*1.6,1.8,-0.82,nil,MAT_METAL)
            add("TailPlane"..side,1.2,0.1,0.7,HIDE,side*0.7,1.95,2.6,nil,MAT_METAL)
            add("Nostril"..side,0.1,0.06,0.16,BLACK,side*0.2,2.25,-3.05,BALL)
            add("Pupil"..side,0.07,0.14,0.08,BLACK,side*0.3,2.17,-1.77,BALL)
            for n=1,7 do
                add("Fang"..side..n,0.07,0.17,0.08,WHITE,side*0.28,1.68,-1.7-n*0.18)
                add("HullRivet"..side..n,0.06,0.06,0.06,METAL,side*0.43,2.08,-0.5+n*0.4,BALL,MAT_METAL)
            end
        end
        for n=1,7 do
            add("DorsalScute"..n,0.25,0.16,0.21,HIDE,0,2.33,-1.25+n*0.48)
        end
    elseif name == "Lirili Larila" then
        for _,side in ipairs({-1,1}) do
            add("CactusArm"..side,0.7,0.3,0.3,CACTUS,side*0.55,2.05,0,CYL)
            add("CactusArmTip"..side,0.65,0.3,0.3,CACTUS,side*0.85,2.3,0,CYL,nil,nil,true)
            add("EarFold"..side,0.13,0.7,0.46,EAR_PINK,side*0.82,3.35,-0.22,BALL)
            add("EyeHighlight"..side,0.055,0.06,0.04,WHITE,side*0.26,3.64,-0.6,BALL)
            for n=1,4 do
                add("CactusSpine"..side..n,0.22,0.035,0.035,FOAM,side*0.37,1.3+n*0.3,-0.19,nil,nil,{Z=side*25})
                add("TrunkCrease"..side..n,0.09,0.035,0.05,Color3.fromRGB(146,125,105),side*0.08,2.12+n*0.18,-0.82)
            end
        end
        for n=-1,1 do
            add("CactusRib"..n,0.035,1.2,0.035,Color3.fromRGB(109,175,83),n*0.17,1.95,-0.34)
        end
    elseif name == "Chimpanzini Bananini" then
        for _,side in ipairs({-1,1}) do
            add("Pupil"..side,0.08,0.1,0.07,BLACK,side*0.2,3.28,-0.61,BALL)
            add("Brow"..side,0.25,0.09,0.12,FUR,side*0.2,3.45,-0.55,BALL)
            add("Nostril"..side,0.065,0.05,0.05,BLACK,side*0.085,2.95,-0.76,BALL)
            add("ChimpArm"..side,1.1,0.25,0.25,FUR,side*0.78,2.4,-0.15,CYL,nil,{Z=side*35})
            add("ChimpHand"..side,0.35,0.4,0.3,FACE,side*1.15,2.1,-0.15,BALL)
            add("CurledPeel"..side,0.22,0.75,0.7,BANANA,side*1.1,1.04,0.1,nil,nil,{Z=side*65})
            add("PeelEdge"..side,0.08,1.45,0.72,BANANA,side*0.95,1.72,0.1,nil,nil,{Z=side*-28})
        end
        add("Smile",0.3,0.04,0.04,FUR,0,2.79,-0.77)
        add("BananaTip",0.36,0.38,0.4,WOOD_DARK,0,0.94,0.05,BALL)
        for n=1,5 do
            add("HairTuft"..n,0.2,0.28,0.2,FUR,(n-3)*0.13,3.79+(n%2)*0.06,0,BALL)
        end
    elseif name == "Ballerina Cappuccina" then
        -- Segmented circular handle and pleated skirt create a recognisable cup/dancer.
        for n=1,12 do
            local a=n*math.pi/6
            add("CupRim"..n,0.25,0.08,0.12,CUP,math.cos(a)*0.56,3.9,math.sin(a)*0.56,nil,nil,{Y=-math.deg(a)})
            add("TutuFold"..n,0.26,0.5,0.3,n%2==0 and SLIPPER or TUTU,math.cos(a)*0.8,1.98,math.sin(a)*0.8,nil,nil,{Y=-math.deg(a),Z=18})
        end
        for n=1,7 do
            local a=-math.pi/2+n*math.pi/8
            add("HandleCurve"..n,0.18,0.2,0.18,CUP,0.67+math.cos(a)*0.4,3.2+math.sin(a)*0.42,0,BALL)
        end
        for _,side in ipairs({-1,1}) do
            add("Blush"..side,0.2,0.1,0.035,SLIPPER,side*0.38,3.01,-0.58,BALL)
            add("Eyelash"..side,0.12,0.035,0.06,BLACK,side*0.29,3.3,-0.64,nil,nil,{Z=side*25})
        end
        add("Bodice",0.55,0.55,0.45,TUTU,0,2.53,0,BALL)
        for n=1,4 do
            add("LatteFoamPetal"..n,0.14,0.045,0.3,COFFEE,(n%2==0 and 1 or -1)*0.1,4.14,(n-2.5)*0.12,BALL)
        end
    elseif name == "Trippi Troppi" then
        for _,spec in ipairs(list) do
            if spec.Name=="Shell" or spec.Name=="Segment" then spec.Shape=BALL end
        end
        for n=1,6 do
            add("ShellBand"..n,0.82-n*0.045,0.57-n*0.025,0.15,n%2==0 and SHRIMP or Color3.fromRGB(232,100,56),0,1.78-(n-1)*0.025,0.05+n*0.22,BALL)
        end
        for _,side in ipairs({-1,1}) do
            add("CatPupil"..side,0.045,0.16,0.04,BLACK,side*0.2,2.2,-1.32,BALL)
            add("Muzzle"..side,0.29,0.2,0.16,FOAM,side*0.12,1.94,-1.3,BALL)
            for n=1,3 do
                add("WhiskerFine"..side..n,0.65,0.025,0.025,WHITE,side*0.48,1.91+(n-2)*0.1,-1.35,nil,nil,{Z=side*(n-2)*12})
            end
            add("Antenna"..side,0.04,0.85,0.04,SHRIMP,side*0.28,2.94,-0.6,nil,nil,{Z=side*25})
            add("TailPetal"..side,0.45,0.14,0.65,SHRIMP,side*0.3,1.6,2.06,nil,nil,{Y=side*30})
        end
    elseif name == "Brr Brr Patapim" then
        -- Repair the long nose's axis (cylinders run along local X).
        for _,spec in ipairs(list) do
            if spec.Name=="Nose" then
                spec.Size=Vector3.new(1.35,0.28,0.28)*scale
                spec.Offset=CFrame.new(0,2.4*scale,-1.15*scale)*CFrame.Angles(0,math.pi/2,0)
            end
        end
        for _,side in ipairs({-1,1}) do
            add("BranchArm"..side,1.1,0.25,0.25,ROOT,side*0.9,2.0,0,CYL,MAT_WOOD,{Z=side*32})
            add("Ear"..side,0.26,0.4,0.2,SKIN,side*0.52,2.5,-0.4,BALL)
            for n=1,5 do
                add("ToeDetail"..side..n,0.28,0.24,0.5,SKIN,side*0.85+(n-3)*0.29,0.28,-1.18,BALL)
                add("RootBark"..side..n,0.045,0.8,0.045,WOOD_DARK,side*0.4+(n-3)*0.04,1.14,-0.12,nil,MAT_WOOD)
            end
        end
        for n=1,10 do
            local a=n*math.pi/5
            add("LeafCrown"..n,0.6,0.45,0.65,n%2==0 and LEAF or Color3.fromRGB(57,151,60),math.cos(a)*0.65,2.85+(n%3)*0.15,0.1+math.sin(a)*0.6,BALL)
        end
        add("Mouth",0.28,0.06,0.08,WOOD_DARK,0,2.22,-0.71)
    end
end

function Sculptures.names()
	local list = {}
	for name in pairs(BUILDERS) do
		table.insert(list, name)
	end
	table.sort(list)
	return list
end

function Sculptures.specs(name, scale)
	local build = BUILDERS[name]
	assert(build, "unknown sculpture " .. tostring(name))
	scale = scale or 1
	local list = {}
	local caption = build(list, scale)
	detail(list, scale, name)
	return list, caption
end

return Sculptures
