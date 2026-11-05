-- Deterministic survival-arena dressing. Each sector has equivalent cover.
local Details = {}
local stone = Color3.fromRGB(79,86,75)
local wood = Color3.fromRGB(89,62,38)
local metal = Color3.fromRGB(88,97,88)
local function decor(p)
    p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
    return p
end
local function crate(parent,cf,size,part)
    part(parent,"SupplyCrate",size,cf,wood,Enum.Material.WoodPlanks)
    for _, side in ipairs({-1,1}) do
        part(parent,"CrateStrap",Vector3.new(size.X+0.1,0.3,size.Z+0.1),cf*CFrame.new(0,side*size.Y*0.3,0),metal,Enum.Material.Metal)
    end
end

function Details.center(parent,part)
    local hub = Instance.new("Model"); hub.Name = "CentralSupplyRuins"; hub.Parent = parent
    local disk = part(hub,"Clearing",Vector3.new(0.18,94,94),CFrame.new(0,0.09,0)*CFrame.Angles(0,0,math.pi/2),Color3.fromRGB(131,118,86),Enum.Material.Ground)
    disk.Shape = Enum.PartType.Cylinder
    -- Angular, weathered metal cornucopia shelter, open to the south.
    part(hub,"SupplyDais",Vector3.new(28,1,25),CFrame.new(0,0.5,0),stone,Enum.Material.Concrete)
    part(hub,"ShelterBack",Vector3.new(28,14,1),CFrame.new(0,8,-12),metal,Enum.Material.CorrodedMetal)
    for _, side in ipairs({-1,1}) do
        part(hub,"ShelterWing",Vector3.new(1,13,24),CFrame.new(side*14,7.5,0),metal,Enum.Material.CorrodedMetal)
        part(hub,"FoldedCanopy",Vector3.new(16,1,27),CFrame.new(side*7,15,0)*CFrame.Angles(0,0,side*math.rad(-14)),Color3.fromRGB(109,115,94),Enum.Material.CorrodedMetal)
        crate(hub,CFrame.new(side*8,3,4),Vector3.new(6,4,6),part)
        crate(hub,CFrame.new(side*9,2.5,-6),Vector3.new(4,3,4),part)
    end
    for n=1,16 do
        local a=n*math.pi/8
        local cf=CFrame.new(math.cos(a)*39,0.5,math.sin(a)*39)*CFrame.Angles(0,-a,0)
        local plinth=part(hub,"TributePlinth",Vector3.new(1,5,5),cf*CFrame.Angles(0,0,math.pi/2),stone,Enum.Material.Concrete)
        plinth.Shape=Enum.PartType.Cylinder
        if n%2==0 then
            crate(hub,CFrame.new(math.cos(a)*27,2,math.sin(a)*27),Vector3.new(4,4,4),part)
        end
    end
end

function Details.sector(parent,angle,part,config)
    local model=Instance.new("Model"); model.Name="ForestSector"; model.Parent=parent
    local a=angle+math.pi/8
    local campRadius=config.BaseRadius*0.64
    local origin=CFrame.new(math.cos(a)*campRadius,0,math.sin(a)*campRadius)*CFrame.Angles(0,-a,0)
    -- Broken stone arch, camp and crates create usable cover off the main trail.
    for _, side in ipairs({-1,1}) do
        part(model,"RuinedArchPier",Vector3.new(5,15,5),origin*CFrame.new(side*10,7.5,0),stone,Enum.Material.Cobblestone)
        part(model,"MossCap",Vector3.new(5.2,0.4,5.2),origin*CFrame.new(side*10,15.2,0),Color3.fromRGB(63,90,45),Enum.Material.Grass)
        part(model,"ArchFragment",Vector3.new(9,3,5),origin*CFrame.new(side*6,15.5,0)*CFrame.Angles(0,0,side*0.13),stone,Enum.Material.Cobblestone)
        part(model,"CampSeat",Vector3.new(9,2,3),origin*CFrame.new(side*9,1,23),wood,Enum.Material.Wood)
        crate(model,origin*CFrame.new(side*18,2,12),Vector3.new(5,4,5),part)
    end
    for n=1,8 do
        local t=n*math.pi/4
        part(model,"FireRingStone",Vector3.new(1.8,1.2,1.6),origin*CFrame.new(math.cos(t)*3,0.6,23+math.sin(t)*3),stone,Enum.Material.Rock)
    end
    for _, t in ipairs({-0.6,0.6}) do
        part(model,"CharredLog",Vector3.new(5,0.8,1),origin*CFrame.new(0,0.6,23)*CFrame.Angles(0,t,0),Color3.fromRGB(37,32,26),Enum.Material.Wood)
    end
    -- A shallow marsh patch with stepping stones; no deep-water trap or extra mechanics.
    local marsh=decor(part(model,"MarshWater",Vector3.new(22,0.1,34),origin*CFrame.new(42,0.08,-20),Color3.fromRGB(65,107,104),Enum.Material.Glass))
    marsh.Transparency=0.25
    for n=1,5 do
        part(model,"MarshSteppingStone",Vector3.new(5,0.6,4),origin*CFrame.new(42+(n%2)*2,0.3,-38+n*6),stone,Enum.Material.Rock)
    end
    -- Small clustered detail stays non-colliding and out of weapon raycasts.
    for ring=1,7 do
        local radius=65+ring*(config.BaseRadius-80)/7
        local cf=CFrame.new(math.cos(a)*radius,0,math.sin(a)*radius)*CFrame.Angles(0,-a,0)
        for n=1,6 do
            local patch=cf*CFrame.new((n%3-1)*18,0,math.floor((n-1)/3)*25-12)
            for leaf=1,4 do
                local t=leaf*math.pi/2
                local fern=decor(part(model,"FernFrond",Vector3.new(0.45,3,2.2),patch*CFrame.new(math.cos(t),1,math.sin(t))*CFrame.Angles(0,-t,0.65),Color3.fromRGB(54,94+leaf*5,47),Enum.Material.Grass))
                fern.Shape=Enum.PartType.Ball
            end
            local rock=part(model,"ForestStone",Vector3.new(2+n%2,1.3,2.5),patch*CFrame.new(5,0.5,3),stone,Enum.Material.Rock)
            rock.Shape=Enum.PartType.Ball
            for k=1,2 do
                local cap=decor(part(model,"MushroomCap",Vector3.new(0.8,0.35,0.8),patch*CFrame.new(-3+k,0.8,k),Color3.fromRGB(174,111,71),Enum.Material.SmoothPlastic))
                cap.Shape=Enum.PartType.Ball
                decor(part(model,"MushroomStem",Vector3.new(0.2,0.6,0.2),patch*CFrame.new(-3+k,0.3,k),Color3.fromRGB(214,200,166)))
            end
        end
    end
    -- Outlying cliff stacks frame the arena beyond the forts.
    for n=1,5 do
        local t=a+(n-3)*0.06
        local radius=config.ArenaSize/2-44
        local cf=CFrame.new(math.cos(t)*radius,0,math.sin(t)*radius)*CFrame.Angles(0,-t,0)
        local height=15+(n%3)*5
        part(model,"OuterCliff",Vector3.new(22,height,15),cf*CFrame.new(0,height/2,0),stone,Enum.Material.Rock)
        part(model,"CliffMoss",Vector3.new(23,0.5,16),cf*CFrame.new(0,height+0.2,0),Color3.fromRGB(64,89,48),Enum.Material.Grass)
    end
end

return Details
