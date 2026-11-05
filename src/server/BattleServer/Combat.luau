local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Layout = require(game:GetService("ReplicatedStorage").Shared.Layout)
local WeaponState = require(script.Parent.WeaponState)
local Combat = {}
Combat.__index = Combat

local function finite(n) return n == n and math.abs(n) < 1000000 end
local function validAim(v)
    return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z)
end

function Combat.new(match, world, feedback, dirty)
    return setmetatable({ Match = match, World = world, Feedback = feedback, Dirty = dirty,
        Weapons = WeaponState.new(Config), Requests = {} }, Combat)
end

function Combat:clearTools(player)
    for _, container in pairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Tool") then child:Destroy() end
            end
        end
    end
end

function Combat:grant(player)
    self:clearTools(player)
    self.Weapons:reset(player.UserId)
    local backpack = player:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    for _, id in ipairs({"Bat", "Sniper"}) do
        local tool = Instance.new("Tool")
        tool.Name = id
        tool.CanBeDropped = false
        tool.RequiresHandle = true
        tool:SetAttribute("BattleWeapon", id)
        tool:SetAttribute("BattleRound", self.Match.Round)
        local handle = Instance.new("Part")
        handle.Name = "Handle"
        handle.Size = id == "Bat" and Vector3.new(0.6, 4.5, 0.6) or Vector3.new(0.65, 0.8, 4)
        handle.Color = id == "Bat" and Color3.fromRGB(181, 117, 61) or Color3.fromRGB(38, 47, 48)
        handle.Material = id == "Bat" and Enum.Material.Wood or Enum.Material.Metal
        handle.CanCollide = false
        handle.CanTouch = false
        handle.CanQuery = false
        handle.Massless = true
        handle.Parent = tool
        if id == "Sniper" then
            local scope = handle:Clone()
            scope.Name = "Scope"
            scope.Size = Vector3.new(0.45, 0.45, 1.3)
            scope.CFrame = handle.CFrame * CFrame.new(0, 0.6, 0)
            scope.Parent = tool
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = scope
            weld.Parent = handle
        end
        tool.Grip = CFrame.new(0, -0.5, 0) * (id == "Bat" and CFrame.Angles(math.rad(15), 0, 0) or CFrame.new())
        tool.Parent = backpack
    end
end

function Combat:remove(player)
    self.Weapons:remove(player.UserId)
    self.Requests[player.UserId] = nil
end

function Combat:allowRequest(id, now)
    local bucket = self.Requests[id]
    if not bucket then bucket = { Tokens = 12, Time = now }; self.Requests[id] = bucket end
    bucket.Tokens = math.min(12, bucket.Tokens + (now-bucket.Time)*8)
    bucket.Time = now
    if bucket.Tokens < 1 then return false end
    bucket.Tokens = bucket.Tokens - 1
    return true
end

function Combat:equipped(player)
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool and tool:GetAttribute("BattleRound") == self.Match.Round then
        local id = tool:GetAttribute("BattleWeapon")
        if id == "Bat" or id == "Sniper" then return id end
    end
    return nil
end

function Combat:damage(player, result, id, now, direction)
    if not result then return false end
    local def = Config.Weapons[id]
    local hit = result.Instance
    local baseIndex = hit:GetAttribute("ObjectiveBase")
    if baseIndex then
        local base = self.World.Bases[baseIndex]
        if base and hit == base.Hitbox and base.Team then
            local changed = self.Match:damageObjective(player.UserId, baseIndex, def.ObjectiveDamage)
            if changed then self.Dirty(); return true end
        end
        return false
    end
    local model = hit
    local victim
    while model and not victim do
        if model:IsA("Model") then victim = Players:GetPlayerFromCharacter(model) end
        model = model.Parent
    end
    if not victim or victim == player or not self.Match:canFight(victim.UserId) then return false end
    if self.Match:sameTeam(player.UserId, victim.UserId) then return false end
    local char = victim.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or hum.Health <= 0 or (victim:GetAttribute("ProtectedUntil") or 0) > now then return false end
    hum:TakeDamage(def.PlayerDamage)
    if id == "Bat" and root then
        root:ApplyImpulse((direction*def.Knockback+Vector3.new(0, 5, 0))*root.AssemblyMass)
    end
    self.Feedback:FireClient(victim, { Kind = "Hurt", Text = "Hit by "..player.DisplayName })
    return true
end

function Combat:handle(player, kind, aim, now)
    if not self:allowRequest(player.UserId, now) then return end
    if not self.Match:canFight(player.UserId) or (player:GetAttribute("ProtectedUntil") or 0) > now then return end
    local id = self:equipped(player)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not id or not root or not head or not hum or hum.Health <= 0 or not char:GetAttribute("BattleReady") then return end
    if (head.Position-root.Position).Magnitude > 6 then return end
    if not Layout.inArena(Config, root.Position.X, root.Position.Y, root.Position.Z) then return end
    if kind == "Reload" then
        if id == "Sniper" then self.Weapons:reload(player.UserId, now) end
        return
    end
    if kind ~= "Attack" or not validAim(aim) then return end
    local origin = head.Position
    local delta = aim-origin
    if delta.Magnitude < 0.1 then return end
    local direction = delta.Unit
    if id == "Bat" and direction:Dot(root.CFrame.LookVector) < 0.1 then return end
    if not self.Weapons:attack(player.UserId, id, now) then return end
    local def = Config.Weapons[id]
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {char}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction*def.Range, params)
    -- A small melee fan accepts close targets while preserving occlusion on every ray.
    if id == "Bat" then
        local right = root.CFrame.RightVector
        for _, offset in ipairs({0, -0.16, 0.16, -0.30, 0.30}) do
            local ray = (direction+right*offset).Unit
            local candidate = workspace:Raycast(origin, ray*def.Range, params)
            if candidate and self:damage(player, candidate, id, now, ray) then
                self.Feedback:FireClient(player, { Kind = "Hit", Text = "BAT HIT" })
                return
            end
        end
        self.Feedback:FireClient(player, { Kind = "Swing" })
    else
        local success = self:damage(player, result, id, now, direction)
        self.Feedback:FireAllClients({ Kind = "Shot", From = origin, To = result and result.Position or origin+direction*def.Range })
        self.Feedback:FireClient(player, { Kind = success and "Hit" or "Miss", Text = success and "SNIPER HIT" or "" })
    end
end

return Combat
