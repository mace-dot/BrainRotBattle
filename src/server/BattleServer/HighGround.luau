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
        table.insert(points,{Kind="Tower",X=math.cos(a)*r,Z=math.sin(a)*r,Clearance=25})
    end
    for n=0,1 do
        local a=-3*math.pi/8+n*math.pi
        local r=config.BaseRadius*0.74
        table.insert(points,{Kind="Tree",X=math.cos(a)*r,Z=math.sin(a)*r,Clearance=48})
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
        p("SideCover",Vector3.new(0.7,2.5,14),side*6.6,17.25,0)
        p("FrontCover",Vector3.new(4.5,2.5,0.7),side*4.5,17.25,-6.6)
    end
    p("RearCover",Vector3.new(14,2.5,0.7),0,17.25,6.6)
    p("SupportBeam",Vector3.new(13,1,1),0,7,6)
    climb(m,"LookoutLadder",cf*CFrame.new(0,0,-8),18,false)
end

function HighGround.tree(parent,cf,part)
    local m=model(parent,"AncientClimbingTree")
    local function p(name,size,x,y,z,color,material)
        return part(m,name,size,cf*CFrame.new(x,y,z),color or bark,material or Enum.Material.Wood)
    end
    local trunk=part(m,"AncientTrunk",Vector3.new(60,14,14),cf*CFrame.new(0,30,0)*CFrame.Angles(0,0,math.pi/2),bark,Enum.Material.Wood)
    trunk.Shape=Enum.PartType.Cylinder
    for n=1,6 do
        local a=n*math.pi/3
        local root=part(m,"AncientRoot",Vector3.new(16,2,3),cf*CFrame.new(math.cos(a)*7,1,math.sin(a)*7)*CFrame.Angles(0,-a,0),wood,Enum.Material.Wood)
        -- Keep the vine's ground approach open.
        root.CanCollide=false; root.CanQuery=false
        local crown=p("AncientCrown",Vector3.new(30,22,30),math.cos(a)*13,48+(n%2)*9,math.sin(a)*13,leaf,Enum.Material.Grass)
        crown.Shape=Enum.PartType.Ball; crown.CanCollide=false; crown.CanQuery=false
        local branch=part(m,"AncientBranch",Vector3.new(23,3,3),cf*CFrame.new(math.cos(a)*10,36,math.sin(a)*10)*CFrame.Angles(0,-a,0.15),wood,Enum.Material.Wood)
        branch.CanCollide=false; branch.CanQuery=false
    end
    -- Broad natural nook in front of the trunk, reached from its outward edge.
    p("TreePerch",Vector3.new(20,1,12),0,26.5,-13,wood)
    p("PerchBranch",Vector3.new(4,3,22),0,24.5,-9,wood)
    for _,side in ipairs({-1,1}) do
        p("PerchSide",Vector3.new(1,2.5,12),side*9.5,28.25,-13)
        p("PerchFront",Vector3.new(7.5,2.5,1),side*6,28.25,-18.5)
        p("PerchBack",Vector3.new(3,2.5,1),side*8,28.25,-7.5)
        local seat=Instance.new("Seat")
        seat.Name="BranchSeat"
        seat.Anchored=true
        seat.Size=Vector3.new(3,1,3)
        seat.CFrame=cf*CFrame.new(side*5,28,-11)
        seat.Material=Enum.Material.Wood
        seat.Color=wood
        seat.Parent=m
        p("SeatBack",Vector3.new(3,2,0.7),side*5,29,-9.3)
    end
    local vineCF=cf*CFrame.new(0,0,-20)
    climb(m,"ClimbableVine",vineCF,30,true)
    -- Visible twisting ropes/leaves wrap an invisible native climbing volume.
    -- Decoration does not collide, so the avatar cannot snag on individual knots.
    for n=1,20 do
        for _,side in ipairs({-1,1}) do
            local x=side*0.7+math.sin(n*0.8)*0.16
            local stem=part(m,"VineStem",Vector3.new(0.28,1.65,0.28),vineCF*CFrame.new(x,n*1.5-0.75,0),Color3.fromRGB(53,89,35),Enum.Material.Wood)
            stem.CanCollide=false; stem.CanQuery=false
            if n%2==0 then
                local frond=part(m,"VineLeaf",Vector3.new(1.2,0.35,0.8),vineCF*CFrame.new(x+side*0.5,n*1.5,0)*CFrame.Angles(0,0,side*0.4),leaf,Enum.Material.Grass)
                frond.Shape=Enum.PartType.Ball; frond.CanCollide=false; frond.CanQuery=false
            end
        end
    end
    p("VineAnchorBranch",Vector3.new(3,2,19),0,35,-11,wood)
end

function HighGround.build(parent,config,part)
    for _,point in ipairs(HighGround.locations(config)) do
        local cf=CFrame.lookAt(Vector3.new(point.X,0,point.Z),Vector3.zero)
        if point.Kind=="Tower" then HighGround.tower(parent,cf,part)
        else HighGround.tree(parent,cf,part) end
    end
end

return HighGround
