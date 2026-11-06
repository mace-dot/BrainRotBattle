local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Layout = require(game:GetService("ReplicatedStorage").Shared.Layout)
local WeaponState = require(script.Parent.WeaponState)
local WeaponModels=require(script.Parent.WeaponModels)
local Projectile=require(script.Parent.ProjectileState)
local Combat = {}
Combat.__index = Combat

local function finite(n) return n == n and math.abs(n) < 1000000 end
local function validAim(v)
    return typeof(v) == "Vector3" and finite(v.X) and finite(v.Y) and finite(v.Z)
end

function Combat.new(match, world, feedback, dirty)
    return setmetatable({ Match = match, World = world, Feedback = feedback, Dirty = dirty,
        Weapons = WeaponState.new(Config), Requests = {}, Registered=setmetatable({},{__mode="k"}), Bolts={} }, Combat)
end

function Combat:clearTools(player)
    self.Weapons:cancel(player.UserId)
    self.Weapons:equip(player.UserId,nil)
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
    for _,id in ipairs(Config.Loadout) do
        local tool=WeaponModels.create(id,self.Match.Round,player.UserId)
        self.Registered[tool]=player.UserId
        tool.Equipped:Connect(function() self.Weapons:equip(player.UserId,id) end)
        tool.Unequipped:Connect(function() self.Weapons:equip(player.UserId,nil) end)
        tool.Destroying:Connect(function() self.Registered[tool]=nil end)
        tool.Parent=backpack
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
    if tool and self.Registered[tool]==player.UserId and tool:GetAttribute("BattleOwner")==player.UserId and tool:GetAttribute("BattleRound") == self.Match.Round then
        local id = tool:GetAttribute("BattleWeapon")
        if Config.Weapons[id] then return id,tool end
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
    if not char:GetAttribute("BattleReady") or not hum or hum.Health <= 0 or (victim:GetAttribute("ProtectedUntil") or 0) > now then return false end
    hum:TakeDamage(def.PlayerDamage)
    if id == "Bat" and root then
        root:ApplyImpulse((direction*def.Knockback+Vector3.new(0, 5, 0))*root.AssemblyMass)
    end
    self.Feedback:FireClient(victim, { Kind = "Hurt", Text = "Hit by "..player.DisplayName })
    return true
end

function Combat:launch(player,origin,direction,params)
    local def=Config.Weapons.Crossbow
    local visual=Instance.new("Part"); visual.Name="CrossbowBolt"
    visual.Size=Vector3.new(0.13,0.13,2.4); visual.Anchored=true
    visual.CanCollide=false; visual.CanTouch=false; visual.CanQuery=false
    visual.Material=Enum.Material.Neon; visual.Color=Color3.fromRGB(201,176,112)
    visual.CFrame=CFrame.lookAt(origin,origin+direction); visual.Parent=workspace
    game:GetService("Debris"):AddItem(visual,def.Lifetime+0.5)
    table.insert(self.Bolts,{Player=player,Character=player.Character,Round=self.Match.Round,
        Position=origin,Velocity=direction*def.Speed,Def=def,Age=0,Distance=0,Params=params,Visual=visual})
end
function Combat:step(dt,now)
    for i=#self.Bolts,1,-1 do
        local bolt=self.Bolts[i]
        local valid=bolt.Player.Character==bolt.Character and bolt.Round==self.Match.Round and self.Match:canFight(bolt.Player.UserId)
        local done,hit=true,nil
        if valid then done,hit=Projectile.advance(bolt,dt,function(origin,delta) return workspace:Raycast(origin,delta,bolt.Params) end) end
        if hit and self:damage(bolt.Player,hit,"Crossbow",now,bolt.Velocity.Unit) then
            self.Feedback:FireClient(bolt.Player,{Kind="Hit",Text="CROSSBOW HIT"})
        end
        if done then bolt.Visual:Destroy(); table.remove(self.Bolts,i)
        else bolt.Visual.CFrame=CFrame.lookAt(bolt.Position,bolt.Position+bolt.Velocity) end
    end
end
function Combat:handle(player,kind,aim,now)
    if not self:allowRequest(player.UserId,now) then return end
    if not self.Match:canFight(player.UserId) or (player:GetAttribute("ProtectedUntil") or 0)>now then return end
    local id,tool=self:equipped(player)
    local char=player.Character
    local root=char and char:FindFirstChild("HumanoidRootPart")
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not id or not root or not head or not hum or hum.Health<=0 or not char:GetAttribute("BattleReady") then return end
    if (head.Position-root.Position).Magnitude>6 or not Layout.inArena(Config,root.Position.X,root.Position.Y,root.Position.Z) then return end
    self.Weapons:equip(player.UserId,id)
    if kind=="Reload" then
        if self.Weapons:reload(player.UserId,now,id) and self.StopSprint then self.StopSprint(player.UserId) end
        return
    end
    if kind~="Attack" or not validAim(aim) then return end
    local def=Config.Weapons[id]
    local origin=head.Position
    local delta=aim-origin
    if delta.Magnitude<0.1 then return end
    local direction=delta.Unit
    if def.Kind=="Melee" and direction:Dot(root.CFrame.LookVector)<0.1 then return end
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={char}; params.IgnoreWater=true
    local obstruction
    if def.Kind~="Melee" then
        local handle=tool:FindFirstChild("Handle")
        local muzzle=handle and handle:FindFirstChild("Muzzle")
        if not muzzle or (muzzle.WorldPosition-head.Position).Magnitude>8 then return end
        if (muzzle.WorldPosition-head.Position).Magnitude>0.001 then obstruction=workspace:Raycast(head.Position,muzzle.WorldPosition-head.Position,params) end
        origin=muzzle.WorldPosition
        delta=aim-origin
        if delta.Magnitude<0.1 then return end
        direction=delta.Unit
    end
    if not self.Weapons:attack(player.UserId,id,now) then return end
    if self.StopSprint then self.StopSprint(player.UserId) end
    if def.Kind=="Melee" then
        -- One bounded contact sample per attack window: each ray stops at first cover,
        -- and returning on the first successful contact prevents repeated swing damage.
        for _,offset in ipairs({0,-0.16,0.16,-0.30,0.30}) do
            local ray=(direction+root.CFrame.RightVector*offset).Unit
            local hit=workspace:Raycast(origin,ray*def.Range,params)
            if hit and (hit.Position-origin).Magnitude<=def.Range+0.01 and self:damage(player,hit,id,now,ray) then
                self.Feedback:FireClient(player,{Kind="Hit",Text=string.upper(id).." HIT"}); return
            end
        end
        self.Feedback:FireClient(player,{Kind="Swing"})
    elseif def.Kind=="Projectile" and not obstruction then self:launch(player,origin,direction,params)
    else
        local result=obstruction or workspace:Raycast(origin,direction*def.Range,params)
        local success=self:damage(player,result,id,now,direction)
        self.Feedback:FireAllClients({Kind="Shot",From=head.Position,To=result and result.Position or origin+direction*def.Range})
        self.Feedback:FireClient(player,{Kind=success and "Hit" or "Miss",Text=success and string.upper(id).." HIT" or ""})
    end
end

return Combat
