local Config=require(game:GetService("ReplicatedStorage").Shared.Config)
local State=require(script.Parent.MovementState)
local Rig=require(script.Parent.MovementRig)
local Movement={}; Movement.__index=Movement
function Movement.new() return setmetatable({State=State.new(Config),Rigs={},Requests={}},Movement) end
function Movement:remove(player)
    local rig=self.Rigs[player.UserId]
    if rig then rig:restore() end
    self.Rigs[player.UserId]=nil; self.State:remove(player.UserId); self.Requests[player.UserId]=nil
end
function Movement:reset(player)
    self:remove(player)
    self.State:reset(player.UserId)
    self.Rigs[player.UserId]=Rig.new(player.Character)
end
function Movement:handle(player,action,now,canFight)
    local id=player.UserId
    local rig=self.Rigs[id]
    if not canFight or not rig or rig.Character~=player.Character or not rig.Character:GetAttribute("BattleReady") or rig.Hum.Health<=0 then return end
    if action=="SprintOff" then self.State:stop(id); return end
    if type(action)~="string" or #action>12 or now-(self.Requests[id] or 0)<0.08 then return end
    self.Requests[id]=now
    self.State:request(id,action,function(stance) return rig:clear(stance) end,rig:grounded())
    rig:pose(self.State.Players[id].Stance)
end
function Movement:step(player,dt,blocked)
    local id=player.UserId; local rig=self.Rigs[id]
    if not rig or rig.Character~=player.Character or rig.Hum.Health<=0 or not rig.Character:GetAttribute("BattleReady") then return end
    local grounded=rig:grounded()
    local velocity=rig.Root.AssemblyLinearVelocity
    self.State:step(id,dt,Vector3.new(velocity.X,0,velocity.Z).Magnitude>0.5,grounded,blocked)
    local speed=self.State:speed(id)
    rig.Hum.WalkSpeed=speed
    local p=rig.Root.Position
    -- Limit sustained ground speed while allowing short impulses, stairs and network bursts.
    if grounded and rig.LastPosition and rig.WasGrounded then
        local delta=Vector3.new(p.X-rig.LastPosition.X,0,p.Z-rig.LastPosition.Z).Magnitude
        rig.TravelBudget=math.min(10,(rig.TravelBudget or 10)+speed*dt*1.35)-delta
        if rig.TravelBudget < -2 then
            rig.Character:PivotTo(rig.LastSafe)
            rig.Root.AssemblyLinearVelocity=Vector3.zero
            rig.TravelBudget=0; p=rig.Root.Position
        end
    else rig.TravelBudget=10 end
    rig.LastPosition=p; rig.LastSafe=rig.Character:GetPivot(); rig.WasGrounded=grounded
end
return Movement
