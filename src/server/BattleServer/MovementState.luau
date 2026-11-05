-- Pure server movement rules; rig geometry is handled separately.
local Movement={}; Movement.__index=Movement
function Movement.new(config) return setmetatable({Config=config,Players={}},Movement) end
function Movement:reset(id) self.Players[id]={Stamina=1,Stance="Stand",Sprint=false,Exhausted=false} end
function Movement:remove(id) self.Players[id]=nil end
function Movement:stop(id) local s=self.Players[id]; if s then s.Sprint=false end end
function Movement:request(id, action, clear, grounded)
    local s=self.Players[id]
    if not s then return false end
    if action=="SprintOff" then s.Sprint=false; return true end
    if action=="SprintOn" then
        if s.Stance~="Stand" or s.Exhausted or not grounded then return false end
        s.Sprint=true; return true
    end
    if action~="Crouch" and action~="Prone" then return false end
    local nextStance = s.Stance==action and "Stand" or action
    if not grounded or not clear(nextStance) then return false end
    s.Stance=nextStance; s.Sprint=false
    return true
end
function Movement:step(id,dt,moving,grounded,blocked)
    local s=self.Players[id]; if not s then return end
    local c=self.Config.Movement
    if blocked or not grounded then s.Sprint=false end
    if s.Sprint and moving then
        s.Stamina=math.max(0,s.Stamina-c.Drain*dt)
        if s.Stamina < 0.000001 then s.Stamina=0; s.Sprint=false; s.Exhausted=true end
    else s.Stamina=math.min(1,s.Stamina+c.Recharge*dt) end
    if s.Stamina+0.000001>=c.RestartThreshold then s.Exhausted=false end
end
function Movement:speed(id)
    local s=self.Players[id]; if not s then return self.Config.WalkSpeed end
    local c=self.Config.Movement
    return self.Config.WalkSpeed*(s.Stance=="Crouch" and c.CrouchMultiplier or s.Stance=="Prone" and c.ProneMultiplier or s.Sprint and c.SprintMultiplier or 1)
end
return Movement
