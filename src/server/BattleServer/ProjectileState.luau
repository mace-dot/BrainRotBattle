-- Sweep every traveled segment, including under a long server frame.
local Projectile={}
function Projectile.advance(bolt,dt,raycast)
    local remaining=math.min(dt,bolt.Def.Lifetime-bolt.Age)
    while remaining>0.000001 do
        local step=math.min(remaining,1/60)
        local gravity=Vector3.new(0,-bolt.Def.Gravity,0)
        local delta=bolt.Velocity*step+gravity*(step*step/2)
        local available=bolt.Def.Range-bolt.Distance
        if delta.Magnitude>available then delta=delta.Unit*available end
        local hit=raycast(bolt.Position,delta)
        bolt.Age=bolt.Age+step; bolt.Distance=bolt.Distance+delta.Magnitude
        bolt.Position=hit and hit.Position or bolt.Position+delta
        bolt.Velocity=bolt.Velocity+gravity*step
        if hit then return true,hit end
        if bolt.Distance>=bolt.Def.Range or bolt.Age>=bolt.Def.Lifetime then return true end
        remaining=remaining-step
    end
    return bolt.Age>=bolt.Def.Lifetime
end
return Projectile
