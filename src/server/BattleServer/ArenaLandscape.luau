local Landscape={}
local stone=Color3.fromRGB(90,96,83)
function Landscape.walls(parent,config,part)
    local thickness,height=config.WallThickness,config.PerimeterHeight
    local edge=config.ArenaSize/2-thickness/2
    for _,side in ipairs({-1,1}) do
        -- Unbroken collision cores overlap at all corners; facing blocks are decoration.
        part(parent,"PerimeterWall",Vector3.new(config.ArenaSize,height,thickness),CFrame.new(0,height/2,side*edge),stone,Enum.Material.Cobblestone)
        part(parent,"PerimeterWall",Vector3.new(thickness,height,config.ArenaSize),CFrame.new(side*edge,height/2,0),stone,Enum.Material.Cobblestone)
        for n=-12,12 do
            local a=n*50
            for turn=0,1 do
                local cf=turn==0 and CFrame.new(a,0,side*(edge-thickness/2)) or CFrame.new(side*(edge-thickness/2),0,a)*CFrame.Angles(0,math.pi/2,0)
                part(parent,"StoneButtress",Vector3.new(7,height,5),cf*CFrame.new(0,height/2,0),Color3.fromRGB(73,80,70),Enum.Material.Slate)
                for tier=1,3 do
                    part(parent,"WeatheredStoneFacing",Vector3.new(42,20,0.6),cf*CFrame.new(24,tier*24-10,-side*0.4),Color3.fromRGB(82+tier*4,88+tier*3,76+tier*3),Enum.Material.Cobblestone)
                end
            end
        end
    end
end
function Landscape.paths(parent,config,layout,part)
    for sector=1,#config.Characters do
        local path=layout.approach(config,sector)
        for n=1,#path-1 do
            local a,b=Vector3.new(path[n].X,0.07,path[n].Z),Vector3.new(path[n+1].X,0.07,path[n+1].Z)
            part(parent,"ApproachTrail",Vector3.new(14,0.12,(b-a).Magnitude+0.3),CFrame.lookAt((a+b)/2,b),Color3.fromRGB(128,117,83),Enum.Material.Ground)
        end
    end
end
function Landscape.cover(parent,sites,part)
    for _,site in ipairs(sites) do
        local cf=CFrame.new(site.X,0,site.Z)*CFrame.Angles(0,-site.Angle,0)
        if site.Kind==0 then
            part(parent,"StandingCover",Vector3.new(11,8,9),cf*CFrame.new(0,4,0)*CFrame.Angles(0,0.2,0),stone,Enum.Material.Rock)
            part(parent,"BoulderShoulder",Vector3.new(7,5,7),cf*CFrame.new(6,2.5,0)*CFrame.Angles(0,0.5,0),stone,Enum.Material.Rock)
        elseif site.Kind==1 then
            part(parent,"CrouchingCover",Vector3.new(13,3.5,7),cf*CFrame.new(0,1.75,0)*CFrame.Angles(0,0.15,0),stone,Enum.Material.Rock)
        else
            local log=part(parent,"ProneCoverLog",Vector3.new(17,1.8,1.8),cf*CFrame.new(0,0.9,0),Color3.fromRGB(91,72,50),Enum.Material.Wood)
            log.Shape=Enum.PartType.Cylinder
        end
    end
end
return Landscape
