-- Shared scalar geometry; also exercised without Roblox in the test runner.
local Layout = {}
function Layout.spawnOffset(slot)
    return { X = ((slot-1)%2 == 0 and -12 or 12), Z = (math.floor((slot-1)/2) == 0 and -22 or 22) }
end
function Layout.base(config, index)
    local angle = -math.pi / 2 + (index - 1) * math.pi * 2 / #config.Characters
    -- Cardinal foundations allow exact rectangular excavation for the basements.
    local yaw = math.floor(( -angle - math.pi/2) / (math.pi/2) + 0.5) * math.pi/2
    return { X = math.cos(angle) * config.BaseRadius, Z = math.sin(angle) * config.BaseRadius, Angle = angle, Yaw = yaw + math.pi }
end
function Layout.portal(config, index)
    local h = config.Holding
    local column = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    return { X = h.X + (column - 1.5) * 48, Y = h.Y, Z = h.Z + (row == 0 and -48 or 48) }
end
function Layout.inArena(config, x, y, z)
    local half = config.ArenaSize / 2
    return math.abs(x) <= half and math.abs(z) <= half and y > -30 and y < 100
end
function Layout.inHolding(config, x, y, z)
    local h = config.Holding
    return math.abs(x-h.X) < h.Width/2 and math.abs(z-h.Z) < h.Depth/2 and y > h.Y-8 and y < h.Y+60
end
function Layout.transform(base, x, z)
    return {X=base.X+math.cos(base.Yaw)*x+math.sin(base.Yaw)*z,
        Z=base.Z-math.sin(base.Yaw)*x+math.cos(base.Yaw)*z}
end
function Layout.approach(config,index)
    local b=Layout.base(config,index)
    return {{X=math.cos(b.Angle)*55,Z=math.sin(b.Angle)*55},
        {X=math.cos(b.Angle)*(config.BaseRadius-145),Z=math.sin(b.Angle)*(config.BaseRadius-145)},
        Layout.transform(b,0,-100),Layout.transform(b,0,-32)}
end
function Layout.segmentDistance(x,z,a,b)
    local dx,dz=b.X-a.X,b.Z-a.Z
    local t=math.max(0,math.min(1,((x-a.X)*dx+(z-a.Z)*dz)/math.max(0.001,dx*dx+dz*dz)))
    return math.sqrt((x-a.X-t*dx)^2+(z-a.Z-t*dz)^2)
end
function Layout.sceneryClear(config,x,z,radius)
    if math.abs(x)+radius>config.ArenaSize/2-config.WallThickness-30 or math.abs(z)+radius>config.ArenaSize/2-config.WallThickness-30 then return false end
    if x*x+z*z<(55+radius)^2 then return false end
    for i=1,#config.Characters do
        local b=Layout.base(config,i)
        if math.abs(x-b.X)<32+radius+12 and math.abs(z-b.Z)<32+radius+12 then return false end
        local path=Layout.approach(config,i)
        for n=1,#path-1 do if Layout.segmentDistance(x,z,path[n],path[n+1])<8+radius then return false end end
    end
    return true
end
return Layout
