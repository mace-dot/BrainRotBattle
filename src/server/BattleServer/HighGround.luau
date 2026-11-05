-- A few optional vantage points. Trusses provide native climbing on all devices.
local HighGround = {}
local wood = Color3.fromRGB(92,67,42)
local bark = Color3.fromRGB(69,53,35)
local leaf = Color3.fromRGB(40,91,47)

function HighGround.locations(config)
    local points={}
    for n=0,3 do
        local a=math.pi/8+n*math.pi/2
        local r=config.BaseRadius*0.56
        table.insert(points,{Kind=n%2==0 and "Tower" or "Bunker",X=math.cos(a)*r,Z=math.sin(a)*r,Clearance=35})
    end
    return points
end

function HighGround.clearOfClimbs(config,position)
    for _,point in ipairs(HighGround.locations(config)) do
        if (position.X-point.X)^2+(position.Z-point.Z)^2 < point.Clearance^2 then return false end
    end
    return true
end

local function climb(parent, name, cf, height, vine)
    local truss = Instance.new("TrussPart")
    truss.Name = name
    truss.Size = Vector3.new(2,height,2)
    truss.CFrame = cf*CFrame.new(0,height/2,0)
    truss.Anchored = true
    truss.CanCollide = true
    truss.CanTouch = true
    truss.Material = vine and Enum.Material.Grass or Enum.Material.Wood
    truss.Color = vine and leaf or wood
    truss.Transparency = vine and 1 or 0
    truss.Parent = parent
    return truss
end

local function model(parent,name)
    local m=Instance.new("Model")
    m.Name=name
    -- Stream climb, platform and supports together so a partial tower is not usable.
    m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    m.Parent=parent
    return m
end

function HighGround.tower(parent,cf,part)
    local m=model(parent,"ForestLookout")
    local function p(name,size,x,y,z,color)
        return part(m,name,size,cf*CFrame.new(x,y,z),color or wood,Enum.Material.WoodPlanks)
    end
    p("LookoutDeck",Vector3.new(14,1,14),0,15.5,0)
    for _,side in ipairs({-1,1}) do
        for _,z in ipairs({-6,6}) do
            p("LookoutPost",Vector3.new(1.4,16,1.4),side*6,8,z,bark)
        end
        p("SideCover",Vector3.new(0.7,3.25,14),side*6.6,17.625,0)
        p("FrontCover",Vector3.new(4.5,3.25,0.7),side*4.5,17.625,-6.6)
    end
    p("RearCover",Vector3.new(14,3.25,0.7),0,17.625,6.6)
    p("SupportBeam",Vector3.new(13,1,1),0,7,6)
    climb(m,"LookoutLadder",cf*CFrame.new(0,0,-8),18,false)
end

-- Low steel field fort inspired by a portable bunker: sheltered room, fighting
-- deck, rear ramp and chest-high parapets. The entry and ramp remain open.
function HighGround.bunker(parent,cf,part)
    local m=model(parent,"FieldBunker")
    local steel=Color3.fromRGB(94,105,103)
    local dark=Color3.fromRGB(47,57,57)
    local function p(name,size,x,y,z,color)
        return part(m,name,size,cf*CFrame.new(x,y,z),color or steel,Enum.Material.Metal)
    end
    p("BunkerFloor",Vector3.new(24,0.3,20),0,0.15,0,dark)
    p("FightingDeck",Vector3.new(25,0.8,21),0,7.6,0)
    p("RampLanding",Vector3.new(7,0.8,2),0,7.6,11)
    for _,side in ipairs({-1,1}) do
        p("ArmoredSide",Vector3.new(1,3,20),side*12,1.5,0)
        p("WindowLintel",Vector3.new(1,2,20),side*12,7,0)
        for _,z in ipairs({-9,0,9}) do
            p("SteelUpright",Vector3.new(1.5,8,1.3),side*12,4,z,dark)
        end
        p("FrontArmor",Vector3.new(9,8,1),side*7.5,4,-10)
        p("DeckSideCover",Vector3.new(1,3.5,21),side*12,9.75,0)
        p("RearCover",Vector3.new(8.5,3.5,1),side*8,9.75,10)
        for n=1,4 do
            p("ArmorRib",Vector3.new(0.3,7,0.4),side*(4+n*1.7),4,-10.6,dark)
        end
        p("WarningStripe",Vector3.new(5,0.4,0.15),side*7.5,6,-10.6,Color3.fromRGB(195,164,66))
    end
    p("FrontCover",Vector3.new(25,3.5,1),0,9.75,-10)
    p("DoorHeader",Vector3.new(6,1,1),0,7.5,-10,dark)
    for step=1,16 do
        local height=step*0.5
        p("BunkerRampStep",Vector3.new(7,height,1.1),0,height/2,29-(step-0.5)*1.1,dark)
    end
end

function HighGround.build(parent,config,part)
    for _,point in ipairs(HighGround.locations(config)) do
        local cf=CFrame.lookAt(Vector3.new(point.X,0,point.Z),Vector3.zero)
        if point.Kind=="Tower" then HighGround.tower(parent,cf,part)
        else HighGround.bunker(parent,cf,part) end
    end
end

return HighGround
