-- Reusable three-level fort and excavated ground. No gameplay state lives here.
local Architecture = {}
local stone = Color3.fromRGB(79, 87, 80)
local dark = Color3.fromRGB(43, 51, 47)
local wood = Color3.fromRGB(100, 73, 47)

function Architecture.spawnLocation(parent, cf)
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SafeSpawnLocation"
    spawn.Size = Vector3.new(4, 0.2, 4)
    spawn.CFrame = cf
    spawn.Anchored = true
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.CanTouch = false
    spawn.CanQuery = false
    spawn.Neutral = true -- Assigned explicitly through Player.RespawnLocation.
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0 -- The game supplies its own timed spawn shield.
    spawn.Parent = parent
    return spawn
end

function Architecture.ground(parent, config, layout, part)
    local half = config.ArenaSize/2
    local rectangles = {{-half, half, -half, half}}
    -- Subtract each 64x64 foundation from the grass, rather than covering a basement
    -- with a solid arena slab. The cardinal bases exactly fill these openings.
    for i = 1, #config.Characters do
        local b = layout.base(config, i)
        local x0, x1, z0, z1 = b.X-32, b.X+32, b.Z-32, b.Z+32
        local nextRects = {}
        local function add(a,b,c,d)
            if b-a > 0.001 and d-c > 0.001 then table.insert(nextRects, {a,b,c,d}) end
        end
        for _, r in ipairs(rectangles) do
            local a,b,c,d = math.max(r[1],x0),math.min(r[2],x1),math.max(r[3],z0),math.min(r[4],z1)
            if a >= b or c >= d then table.insert(nextRects,r)
            else
                add(r[1],a,r[3],r[4]); add(b,r[2],r[3],r[4])
                add(a,b,r[3],c); add(a,b,d,r[4])
            end
        end
        rectangles = nextRects
    end
    for _, r in ipairs(rectangles) do
        part(parent, "WildernessFloor", Vector3.new(r[2]-r[1],18,r[4]-r[3]),
            CFrame.new((r[1]+r[2])/2,-9,(r[3]+r[4])/2), Color3.fromRGB(65,93,54), Enum.Material.Grass)
    end
end

function Architecture.base(parent, def, index, cf, color, part, sculpture, healthBar)
    local base = Instance.new("Model")
    base.Name = def.Id .. "Base"
    base.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    base.Parent = parent
    local function block(name, size, offset, tint, material)
        return part(base,name,size,cf*CFrame.new(offset),tint or stone,material or Enum.Material.Slate)
    end
    local function floor(name,y,side)
        -- A 12-stud stairwell along one wall, with a landing at either end.
        block(name,Vector3.new(49,1,64),Vector3.new(-side*7.5,y-0.5,0))
        block(name,Vector3.new(3,1,64),Vector3.new(side*30.5,y-0.5,0))
        block(name,Vector3.new(12,1,8),Vector3.new(side*23,y-0.5,-28))
        block(name,Vector3.new(12,1,24),Vector3.new(side*23,y-0.5,20))
    end
    block("BasementFloor",Vector3.new(64,1,64),Vector3.new(0,-12.5,0),dark)
    floor("GroundFloor",0,-1)
    floor("SecondFloor",16,1)
    for _, side in ipairs({-1,1}) do
        block("BasementWall",Vector3.new(2,12,64),Vector3.new(side*31,-6,0),dark)
        block("BasementWall",Vector3.new(60,12,2),Vector3.new(0,-6,side*31),dark)
        for _, z in ipairs({-20,20}) do
            block("GroundSideWall",Vector3.new(2,15,24),Vector3.new(side*31,7.5,z))
        end
        block("FrontWall",Vector3.new(19,15,2),Vector3.new(side*22.5,7.5,-31))
        block("UpperParapet",Vector3.new(2,3,64),Vector3.new(side*31,17.5,0))
        block("UpperParapet",Vector3.new(60,3,2),Vector3.new(0,17.5,side*31))
        for _, z in ipairs({-30,0,30}) do
            block("TimberPost",Vector3.new(2,30,2),Vector3.new(side*30,15,z),wood,Enum.Material.Wood)
        end
        block("ColorTrim",Vector3.new(1,0.35,60),Vector3.new(side*32.05,16,0),color,Enum.Material.Neon)
        -- Rail guards along the inside of each stairwell; ends stay open.
        local stairY = side == -1 and 0 or 16
        block("StairGuard",Vector3.new(0.6,3,32),Vector3.new(side*16.7,stairY+1.5,-8),wood,Enum.Material.Wood)
    end
    block("RearWall",Vector3.new(60,15,2),Vector3.new(0,7.5,31))
    block("DoorLintel",Vector3.new(26,4,2),Vector3.new(0,13,-31),wood,Enum.Material.Wood)
    block("ShelterRoof",Vector3.new(66,1,66),Vector3.new(0,30.5,0),wood,Enum.Material.WoodPlanks)
    for x = -24,24,12 do
        block("RoofBeam",Vector3.new(1.3,1.3,64),Vector3.new(x,29.4,0),dark,Enum.Material.Wood)
    end
    -- Walkable steps, with the full rise exposed through the matching floor opening.
    for flight = 1,2 do
        local count, rise, bottom, x = 16,12,-12,-23
        if flight == 2 then count,rise,bottom,x = 20,16,0,23 end
        for n = 1,count do
            local height = rise*n/count
            block(flight == 1 and "BasementStair" or "UpperStair",
                Vector3.new(12,height,32/count),Vector3.new(x,bottom+height/2,-24+(n-0.5)*32/count),wood,Enum.Material.WoodPlanks)
        end
    end
    -- Shelving and supplies leave the middle and both staircase approaches open.
    for _, x in ipairs({-10,10}) do
        block("BasementSupplyCrate",Vector3.new(5,4,5),Vector3.new(x,-10,22),wood,Enum.Material.WoodPlanks)
        block("CrateBand",Vector3.new(5.1,0.3,5.1),Vector3.new(x,-9,22),dark,Enum.Material.Metal)
        block("GroundCover",Vector3.new(5,4,6),Vector3.new(x,2,12),wood,Enum.Material.WoodPlanks)
        for _, y in ipairs({-7,8,24}) do
            local lamp = block("WallLantern",Vector3.new(1,1.5,1),Vector3.new(x,y,29),Color3.fromRGB(255,201,115),Enum.Material.Neon)
            lamp.CanCollide = false
            local light = Instance.new("PointLight")
            light.Color = lamp.Color; light.Brightness = 0.7; light.Range = 24; light.Parent = lamp
        end
    end
    block("TeamBanner",Vector3.new(8,6,0.3),Vector3.new(0,24,30),color,Enum.Material.Fabric)
    -- Team headquarters details stay against the back wall, clear of both stairs.
    block("CommandTable",Vector3.new(8,0.6,4),Vector3.new(0,3.2,24),wood,Enum.Material.WoodPlanks)
    for _, x in ipairs({-3,3}) do
        block("TableLeg",Vector3.new(0.6,3,3),Vector3.new(x,1.5,24),dark,Enum.Material.Metal)
    end
    block("MapBoard",Vector3.new(6,0.08,3),Vector3.new(0,3.55,24),Color3.fromRGB(150,159,117),Enum.Material.Fabric)
    for n=1,4 do
        block("MapMarker",Vector3.new(0.3,0.3,0.3),Vector3.new((n-2.5)*1.1,3.74,24+(n%2-0.5)),color,Enum.Material.Neon)
    end
    for _,side in ipairs({-1,1}) do
        block("EquipmentLocker",Vector3.new(5,7,2.5),Vector3.new(side*18,3.5,28),dark,Enum.Material.Metal)
        block("LockerPanel",Vector3.new(4.4,5.8,0.15),Vector3.new(side*18,3.6,26.65),color,Enum.Material.Metal)
        block("LockerHandle",Vector3.new(0.15,1,0.2),Vector3.new(side*18+1.4,3.6,26.5),stone,Enum.Material.Metal)
        for n=1,3 do
            block("LockerVent",Vector3.new(3,0.1,0.15),Vector3.new(side*18,5.2+n*0.3,26.5),dark,Enum.Material.Metal)
        end
        block("BasementBench",Vector3.new(5,0.5,3),Vector3.new(side*19,-10,25),wood,Enum.Material.WoodPlanks)
        block("BenchSupport",Vector3.new(4,2,1),Vector3.new(side*19,-11,25),dark)
        block("BunkFrame",Vector3.new(6,0.5,8),Vector3.new(side*10,-10.8,-23),wood,Enum.Material.WoodPlanks)
        block("Bedroll",Vector3.new(5.4,0.5,7),Vector3.new(side*10,-10.3,-23),color,Enum.Material.Fabric)
        block("Pillow",Vector3.new(4.2,0.4,1.6),Vector3.new(side*10,-9.85,-25.5),Color3.fromRGB(179,177,150),Enum.Material.Fabric)
        block("UpperBanner",Vector3.new(5,6,0.2),Vector3.new(side*18,25,30),color,Enum.Material.Fabric)
        block("DisplayFrame",Vector3.new(6,0.4,0.6),Vector3.new(side*18,28.2,29.9),wood,Enum.Material.Wood)
    end
    block("BasementRunner",Vector3.new(8,0.06,30),Vector3.new(0,-11.96,0),color,Enum.Material.Fabric)
    block("GroundRunner",Vector3.new(6,0.06,20),Vector3.new(0,0.04,9),color,Enum.Material.Fabric)
    -- Inset ritual floor and low lights frame the upstairs Brainrot without walls
    -- that would prevent bat hits or obstruct the stair landing.
    block("ObjectiveInlay",Vector3.new(18,0.08,16),Vector3.new(0,16.05,18),dark,Enum.Material.Metal)
    for _,side in ipairs({-1,1}) do
        block("ObjectiveLight",Vector3.new(0.3,0.12,15),Vector3.new(side*8.5,16.12,18),color,Enum.Material.Neon)
    end
    block("BrainrotPedestal",Vector3.new(14,1.5,12),Vector3.new(0,16.75,18),color)
    local statue = sculpture(base,def.Name,cf*CFrame.new(0,17.5,18),1.6)
    local hit = block("ObjectiveHitbox",Vector3.new(9,9,10),Vector3.new(0,22,18),color)
    hit.Transparency = 1; hit.CanCollide = false; hit.CanQuery = false
    hit:SetAttribute("ObjectiveBase",index)
    local anchor = block("ObjectiveHealthAnchor",Vector3.one,Vector3.new(0,18.2+statue:GetAttribute("VisualHeight"),18),color)
    anchor.Transparency = 1; anchor.CanCollide = false; anchor.CanQuery = false
    local status = healthBar(anchor)
    for _,x in ipairs({-3,3}) do
        for _,z in ipairs({-13,-7}) do
            block("SpawnPad",Vector3.new(3.6,0.12,3.6),Vector3.new(x,0.06,z),color,Enum.Material.Neon)
        end
    end
    local spawnLocation = Architecture.spawnLocation(base, cf*CFrame.new(0,0.22,-10))
    return {Model=base,Spawn=cf*CFrame.new(0,4,-10),SpawnLocation=spawnLocation,Hitbox=hit,Statue=statue,HealthBar=status,Team=nil,HP=0}
end

return Architecture
