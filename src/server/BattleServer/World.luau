local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Layout = require(Shared.Layout)
local Sculptures = require(script.Parent.BrainrotSculptures)
local Architecture = require(script.Parent.ArenaArchitecture)
local Details = require(script.Parent.ArenaDetails)
local HighGround = require(script.Parent.HighGround)
local ForestLayout = require(Shared.ForestLayout)
local ForestTrees = require(script.Parent.ForestTrees)
local Landscape=require(script.Parent.ArenaLandscape)
local CreatorStatue=require(script.Parent.CreatorStatue)
local CoverLayout=require(Shared.CoverLayout)
local World = {}
World.__index = World

local function part(parent, name, size, cf, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.CFrame = cf
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.CanTouch = false
    p.Parent = parent
    return p
end

local function label(anchor, text, color, width, height, distance, worldSized)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ReadableSign"
    -- World-sized character signs recede with the portal when the camera zooms out.
    gui.Size = worldSized and UDim2.fromScale(width, height) or UDim2.fromOffset(width or 320, height or 100)
    gui.StudsOffsetWorldSpace = Vector3.new(0, worldSized and 0 or 5, 0)
    gui.AlwaysOnTop = not worldSized
    gui.LightInfluence = 0
    gui.MaxDistance = distance or 280
    gui.Parent = anchor
    local t = Instance.new("TextLabel")
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundColor3 = Color3.fromRGB(12, 23, 24)
    t.BackgroundTransparency = 0.12
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamBlack
    t.TextColor3 = color
    t.TextStrokeColor3 = Color3.fromRGB(5, 10, 12)
    t.TextStrokeTransparency = 0
    t.TextScaled = true
    t.TextWrapped = true
    t.Text = text
    t.Parent = gui
    local cap = Instance.new("UITextSizeConstraint")
    cap.MaxTextSize = worldSized and 22 or 38
    cap.MinTextSize = worldSized and 1 or 10
    cap.Parent = t
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = t
    return t
end

local function healthBar(anchor)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ObjectiveHealth"
    gui.Size = UDim2.fromOffset(90, 9)
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.MaxDistance = 100
    gui.Enabled = false
    gui.Parent = anchor
    local track = Instance.new("Frame")
    track.Size = UDim2.fromScale(1, 1)
    track.BackgroundColor3 = Color3.fromRGB(25, 29, 26)
    track.BorderSizePixel = 0
    track.Parent = gui
    local fill = Instance.new("Frame")
    fill.Name = "HealthFill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = Color3.fromRGB(88, 211, 107)
    fill.BorderSizePixel = 0
    fill.Parent = track
    return {Gui = gui, Fill = fill}
end

local function sculpture(parent, name, cf, scale)
    local model = Instance.new("Model")
    model.Name = name
    local specs = Sculptures.specs(name, scale)
    -- Rest each different silhouette on its pedestal instead of floating above it.
    local minY, maxY = math.huge, -math.huge
    for _, spec in ipairs(specs) do
        local r,u,l = spec.Offset.RightVector,spec.Offset.UpVector,spec.Offset.LookVector
        local half = (math.abs(r.Y)*spec.Size.X + math.abs(u.Y)*spec.Size.Y + math.abs(l.Y)*spec.Size.Z)/2
        minY = math.min(minY, spec.Offset.Position.Y-half)
        maxY = math.max(maxY, spec.Offset.Position.Y+half)
    end
    for _, spec in ipairs(specs) do
        local p = part(model, spec.Name, spec.Size, cf * CFrame.new(0, -minY, 0) * spec.Offset, spec.Color, spec.Material)
        p.Shape = spec.Shape or Enum.PartType.Block
        p.CanCollide = false
        p.CanQuery = false
    end
    model:SetAttribute("VisualHeight", maxY-minY)
    model.Parent = parent
    return model
end

local grass = Color3.fromRGB(72, 112, 63)
local stone = Color3.fromRGB(83, 96, 91)
local wood = Color3.fromRGB(94, 65, 40)

-- Geometry-only entry point. Nil callbacks produce no interactive connections.
function World.build(parent, options)
    options = options or {}
    local name = options.Name or "BrainRotBattles"
    local old = parent:FindFirstChild(name)
    if old then
        assert(old:GetAttribute("BrainRotGenerated") == true, "Refusing to replace unrelated model: " .. name)
        old:Destroy()
    end
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("BrainRotGenerated", true)
    model.Parent = parent
    local self = setmetatable({ Model = model, Bases = {}, Portals = {} }, World)
    self:arena()
    self:holding(options.OnSelect, options.OnExit)
    return self
end

function World.new(onSelect, onExit)
    local self = World.build(workspace, { OnSelect = onSelect, OnExit = onExit })
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = 16.4
    lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(115, 135, 121)
    lighting.OutdoorAmbient = Color3.fromRGB(145, 155, 142)
    local atmosphere = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Density = 0.28
    atmosphere.Color = Color3.fromRGB(197, 222, 199)
    atmosphere.Parent = lighting
    return self
end

function World:arena()
    local m = self.Model
    Architecture.ground(m, Config, Layout, part)
    Details.center(m, part)
    HighGround.build(m, Config, part)
    local landmarks=HighGround.locations(Config)
    for i=1,#Config.Characters do
        local a=Layout.base(Config,i).Angle+math.pi/8
        table.insert(landmarks,{X=math.cos(a)*Config.BaseRadius*0.64,Z=math.sin(a)*Config.BaseRadius*0.64,Clearance=58})
    end
    local trees=ForestLayout.plan(Config,landmarks)
    local climbCount=0
    for _,site in ipairs(trees) do
        ForestTrees.build(m,site,part)
        if site.Climbable then climbCount=climbCount+1 end
    end
    m:SetAttribute("TreeCount",#trees); m:SetAttribute("VineTreeCount",climbCount)
    Landscape.walls(m,Config,part)
    Landscape.paths(m,Config,Layout,part)
    Landscape.cover(m,CoverLayout.plan(Config,trees,landmarks),part)
    CreatorStatue.build(m,Config,part)
    for i,def in ipairs(Config.Characters) do
        local layout=Layout.base(Config,i)
        local cf=CFrame.new(layout.X,0,layout.Z)*CFrame.Angles(0,layout.Yaw,0)
        self.Bases[i]=Architecture.base(m,def,i,cf,Color3.fromHex(def.Color),part,sculpture,healthBar)
        Details.sector(m,layout.Angle,part,Config)
    end
end

function World:holding(onSelect, onExit)
    local h = Config.Holding
    local room = Instance.new("Model")
    room.Name = "HoldingSpace"
    room.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    room.Parent = self.Model
    part(room, "HoldingFloor", Vector3.new(h.Width, 3, h.Depth), CFrame.new(h.X, h.Y-1.5, h.Z), Color3.fromRGB(26, 45, 43), Enum.Material.Slate)
    for _, sign in ipairs({-1, 1}) do
        part(room, "Railing", Vector3.new(h.Width, 5, 2), CFrame.new(h.X, h.Y+2.5, h.Z+sign*h.Depth/2), stone)
        part(room, "Railing", Vector3.new(2, 5, h.Depth), CFrame.new(h.X+sign*h.Width/2, h.Y+2.5, h.Z), stone)
    end
    for _, side in ipairs({-1, 1}) do
        local north = part(room, "InvisibleBoundary", Vector3.new(h.Width+4, 64, 2),
            CFrame.new(h.X, h.Y+30, h.Z+side*(h.Depth/2+1)), stone)
        local east = part(room, "InvisibleBoundary", Vector3.new(2, 64, h.Depth+4),
            CFrame.new(h.X+side*(h.Width/2+1), h.Y+30, h.Z), stone)
        for _, wall in ipairs({north,east}) do
            wall.Transparency = 1
            wall.CanCollide = true
            wall.CanQuery = false
            wall.CastShadow = false
        end
    end
    local banner = part(room, "BattleTitle", Vector3.new(1, 1, 1), CFrame.new(h.X, h.Y+22, h.Z), stone)
    banner.Transparency = 1
    banner.CanCollide = false
    banner.CanQuery = false
    self.RoundLabel = label(banner, "BRAIN ROT BATTLES\n8 TEAMS • 4 PLAYERS PER TEAM", Color3.fromRGB(123, 255, 190), 620, 130, 450)
    self.HoldingSpawn = CFrame.new(h.X, h.Y+5, h.Z+8)
    self.HoldingSpawnLocation = Architecture.spawnLocation(room, CFrame.new(h.X,h.Y+0.2,h.Z+8))
    for i, def in ipairs(Config.Characters) do
        local position = Layout.portal(Config, i)
        local cf = CFrame.new(position.X, position.Y, position.Z) * CFrame.Angles(0, i <= 4 and math.pi or 0, 0)
        local color = Color3.fromHex(def.Color)
        local model = Instance.new("Model")
        model.Name = def.Id .. "SelectionPortal"
        model.Parent = room
        local pad = part(model, "SelectionPad", Vector3.new(24, 0.5, 20), cf*CFrame.new(0, 0.25, 0), color, Enum.Material.Neon)
        for _, side in ipairs({-1, 1}) do
            part(model, "PortalPillar", Vector3.new(2.5, 14, 4), cf*CFrame.new(side*11, 7, 0), stone, Enum.Material.Slate)
        end
        part(model, "PortalLintel", Vector3.new(24.5, 2, 4), cf*CFrame.new(0, 15, 0), stone, Enum.Material.Slate)
        for _, side in ipairs({-1,1}) do
            part(model, "PortalLightStrip", Vector3.new(0.3, 12, 0.25), cf*CFrame.new(side*9.6, 7, -2.1), color, Enum.Material.Neon)
            part(model, "PortalFoot", Vector3.new(4, 1, 6), cf*CFrame.new(side*11, 0.5, 0), stone)
        end
        part(model, "PortalLightHeader", Vector3.new(19.5, 0.3, 0.25), cf*CFrame.new(0, 14.1, -2.1), color, Enum.Material.Neon)
        part(model, "DisplayPlinth", Vector3.new(11, 0.6, 11), cf*CFrame.new(0, 0.8, 3), stone)

        sculpture(model, def.Name, cf*CFrame.new(0, 1.1, 3), 1.8)
        local anchor = part(model, "SignAnchor", Vector3.one, cf*CFrame.new(0, 18, 0), color)
        anchor.Transparency = 1
        anchor.CanCollide = false
        anchor.CanQuery = false
        local status = label(anchor, def.Name .. "\nJOIN TEAM • 0 / 4", color, 21, 3.5, 120, true)
        local prompt
        if onSelect then
            prompt = Instance.new("ProximityPrompt")
            prompt.ActionText = "Join team"
            prompt.ObjectText = "" -- The compact sign already names the character.
            prompt.MaxActivationDistance = 10
            prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
            prompt.HoldDuration = 0.2
            prompt.RequiresLineOfSight = false
            prompt.Parent = pad
            prompt.Triggered:Connect(function(player) onSelect(player, i, pad.Position) end)
        end
        local trigger = part(model, "WalkInSelection", Vector3.new(18, 8, 3), cf*CFrame.new(0, 4, -4), color)
        trigger.Transparency = 1
        trigger.CanCollide = false
        trigger.CanQuery = false
        trigger.CanTouch = onSelect ~= nil
        if onSelect then
            trigger.Touched:Connect(function(hit)
                local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                if player then onSelect(player, i, pad.Position) end
            end)
        end
        self.Portals[i] = { Label = status, Prompt = prompt }
    end
    if Config.SinglePlayerPlaceId > 0 and onExit then
        local exit = part(room, "SinglePlayerExit", Vector3.new(15, 1, 15), CFrame.new(h.X+92, h.Y+0.5, h.Z), Color3.fromRGB(255, 144, 71), Enum.Material.Neon)
        label(exit, "Single player\nRETURN", Color3.fromRGB(255, 188, 104), 290, 90, 260)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = "Travel to Single player"
        prompt.MaxActivationDistance = 12
        prompt.Parent = exit
        prompt.Triggered:Connect(function(player) onExit(player, exit.Position) end)
    end
end

function World:setObjective(index, team, hp)
    local base = self.Bases[index]
    if base.Team == team and base.HP == hp then return end
    base.Team = team
    base.HP = hp
    base.Hitbox.CanQuery = team ~= nil and hp > 0
    base.Hitbox:SetAttribute("TeamBase", team)
    for _, p in ipairs(base.Statue:GetChildren()) do
        p.Transparency = (not team or hp > 0) and 0 or 0.78
    end
    local ratio = math.clamp(hp/Config.BrainrotHealth, 0, 1)
    base.HealthBar.Gui.Enabled = team ~= nil
    base.HealthBar.Fill.Size = UDim2.fromScale(ratio, 1)
    base.HealthBar.Fill.BackgroundColor3 = ratio > 0.5 and Color3.fromRGB(88,211,107)
        or (ratio > 0.25 and Color3.fromRGB(239,192,72) or Color3.fromRGB(222,74,65))
end

function World:update(state, now)
    local seconds = math.max(0, math.ceil(state.Deadline-now))
    local caption = state.Phase .. (state.Deadline > 0 and (" • "..seconds.."s") or "")
    self.RoundLabel.Text = "BRAIN ROT BATTLES\n" .. caption .. "\n8 teams • 4 players each • Choose a team portal"
    if state.IsPractice then self.RoundLabel.Text = "STUDIO PRACTICE — NOT A LIVE MATCH\nUse Studio Test Tools to reset or exit" end
    for i, def in ipairs(Config.Characters) do
        local seats = state:seats(i)
        self.Portals[i].Label.Text = def.Name .. "\n" .. seats .. " / " .. Config.TeamSize .. (seats >= Config.TeamSize and " • TEAM FULL" or " • JOIN TEAM")
        if self.Portals[i].Prompt then self.Portals[i].Prompt.ActionText = seats >= Config.TeamSize and "Team full" or "Join team" end
        local team, hp = nil, 0
        if state.Phase == "Active" or state.Phase == "Results" then
            local active = state.Teams[i]
            if active then team, hp = i, active.HP end
        end
        self:setObjective(i, team, hp)
    end
end

return World
