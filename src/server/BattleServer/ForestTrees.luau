-- Branch-built silhouettes with tapered, leaning trunks and layered foliage.
-- All trees use this builder; the configured fraction of trees has vines and several branch perches.
local Trees = {}
local bark=Color3.fromRGB(91,72,50)
local shadow=Color3.fromRGB(60,49,34)
local greens={Color3.fromRGB(57,87,42),Color3.fromRGB(68,103,48),Color3.fromRGB(80,113,53)}

function Trees.build(parent,site,part)
    local model=Instance.new("Model")
    model.Name=site.Climbable and "VineTree" or "ForestTree"
    model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("Climbable",site.Climbable)
    model.Parent=parent
    local cf=CFrame.lookAt(Vector3.new(site.X,0,site.Z),Vector3.zero)
    local h=site.Height
    local function rod(name,a,b,width,color,collide)
        local delta=b-a
        local p=part(model,name,Vector3.new(delta.Magnitude,width,width),
            cf*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(0,math.pi/2,0),color or bark,Enum.Material.Wood)
        p.Shape=Enum.PartType.Cylinder
        p.CanCollide=collide==true; p.CanQuery=collide==true
        return p
    end
    local function leaf(name,position,size,rotation,tint)
        local p=Instance.new("WedgePart")
        p.Name=name; p.Size=size; p.CFrame=cf*CFrame.new(position)*CFrame.Angles(rotation.X,rotation.Y,rotation.Z)
        p.Color=tint; p.Material=Enum.Material.Grass; p.Anchored=true; p.CanTouch=false; p.Parent=model
        p.CanCollide=false; p.CanQuery=false
        return p
    end
    -- Decreasing segment widths and a subtle bend replace the single straight pole.
    local bend=(site.Index%5-2)*0.45
    local nodes={Vector3.zero,Vector3.new(0,h*0.3,0),Vector3.new(bend,h*0.58,0.7),Vector3.new(bend*2,h*0.84,1.3)}
    for n=1,3 do rod("TaperedTrunk",nodes[n],nodes[n+1],4.2-(n-1)*0.95,bark,true) end
    for n=1,5 do
        local a=n*math.pi*2/5+site.Index*0.3
        rod("FlaredRoot",Vector3.new(math.cos(a)*5,0.3,math.sin(a)*5),Vector3.new(0,3,0),0.8,shadow,false)
    end
    local pine=site.Variant==0 and not site.Climbable
    local branches=pine and 9 or 7
    for n=1,branches do
        local a=n*2.399+site.Index*0.61
        local y=pine and (h*0.38+n*h*0.055) or (h*0.57+(n%4)*h*0.075)
        local reach=pine and (12-n*0.8) or (7+(n%3)*2)
        local start=Vector3.new(bend,y,0.6)
        local elbow=Vector3.new(math.cos(a)*reach*0.6,y+2.5,math.sin(a)*reach*0.6)
        local tip=Vector3.new(math.cos(a)*reach,y+5,math.sin(a)*reach)
        rod("BranchFork",start,elbow,1.5-(n%3)*0.14,bark,true)
        rod("BranchTip",elbow,tip,0.7,bark,true)
        -- Flat, offset clusters expose branch gaps instead of forming giant balls.
        for cluster=1,4 do
            local offset=Vector3.new(math.cos(a+cluster)*2.7,(cluster-2)*0.85,math.sin(a+cluster)*2.7)
            local size=pine and Vector3.new(7-n*0.35,2.4,4.5) or Vector3.new(5.5+(n%3),2.8,4.8)
            leaf("LeafSpray",tip+offset,size,Vector3.new(0.08*cluster,a+cluster*0.4,0.1*(cluster-2)),greens[(n+cluster)%3+1])
        end
    end
    leaf("LeaderFoliage",Vector3.new(bend*2,h*0.96,1.3),Vector3.new(5,6,4),Vector3.new(0,site.Index,0.1),greens[2])
    if not site.Climbable then return model end

    local function p(name,size,x,y,z,color)
        return part(model,name,size,cf*CFrame.new(x,y,z),color or bark,Enum.Material.Wood)
    end
    -- Broad split branches are their real collision surfaces, with clear step-offs.
    for tier,y in ipairs({8,16,24}) do
        local side=tier%2==0 and 1 or -1
        rod("WalkableBranch",Vector3.new(0,y-3,0),Vector3.new(side*5,y,-7),2.2,bark,true)
        for strand=1,3 do
            p("BranchPerch",Vector3.new(3,0.8,7),side*3+(strand-2)*2.2,y,-6,bark)
        end
    end
    local seat=Instance.new("Seat")
    seat.Name="BranchSeat"; seat.Size=Vector3.new(2.5,0.7,2.5)
    seat.Anchored=true; seat.Material=Enum.Material.Wood; seat.Color=bark
    seat.CFrame=cf*CFrame.new(3.6,16.8,-4.5); seat.Parent=model
    local vine=Instance.new("TrussPart")
    vine.Name="ClimbableVine"; vine.Size=Vector3.new(2,28,2)
    vine.CFrame=cf*CFrame.new(0,14,-10)
    vine.Anchored=true; vine.CanCollide=true; vine.CanTouch=true
    vine.Transparency=1; vine.Parent=model
    -- Thick leaf-covered twin stems are visible from normal play distance.
    for n=1,19 do
        for _,side in ipairs({-1,1}) do
            local a=Vector3.new(side*0.75+math.sin(n)*0.18,(n-1)*1.5,-10)
            local b=Vector3.new(side*0.75+math.sin(n+1)*0.18,n*1.5,-10)
            rod("VineStem",a,b,0.52,Color3.fromRGB(85,129,42),false)
            leaf("VineLeaf",b+Vector3.new(side*0.65,0,0),Vector3.new(1.8,0.5,1.15),Vector3.new(0,side*0.5,side*0.35),Color3.fromRGB(114,159,53))
        end
    end
    rod("VineSupport",Vector3.new(0,28,0),Vector3.new(0,28,-10),1.5,bark,true)
    return model
end
return Trees
