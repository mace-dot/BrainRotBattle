-- Asset-free loadout: distinct silhouettes, grips, muzzle attachments and hotbar labels.
local Models={}
function Models.create(id,round,owner)
    local tool=Instance.new("Tool"); tool.Name=id; tool.ToolTip=id; tool.CanBeDropped=false
    tool:SetAttribute("BattleWeapon",id); tool:SetAttribute("BattleRound",round); tool:SetAttribute("BattleOwner",owner)
    local function piece(name,size,offset,color,material)
        local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=offset
        p.Color=color; p.Material=material or Enum.Material.Metal
        p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.Parent=tool
        return p
    end
    local metal=Color3.fromRGB(49,59,61); local wood=Color3.fromRGB(119,79,43); local steel=Color3.fromRGB(187,201,205)
    local handle=piece("Handle",Vector3.new(0.45,1,0.5),CFrame.new(),metal)
    local muzzleZ=-1
    if id=="Bat" then
        handle.Size=Vector3.new(0.5,3.5,0.5); handle.Material=Enum.Material.Wood; handle.Color=wood
        piece("Barrel",Vector3.new(0.85,2.1,0.85),CFrame.new(0,1.6,0),wood,Enum.Material.Wood)
        piece("GripWrap",Vector3.new(0.55,1.3,0.55),CFrame.new(0,-1.1,0),metal,Enum.Material.Fabric)
        tool.Grip=CFrame.new(0,-0.7,0)*CFrame.Angles(math.rad(15),0,0)
    elseif id=="Sword" then
        piece("Blade",Vector3.new(0.65,4.2,0.15),CFrame.new(0,2.5,0),steel)
        piece("BladeEdge",Vector3.new(0.12,4.3,0.18),CFrame.new(0.34,2.5,0),Color3.fromRGB(229,237,238))
        piece("Guard",Vector3.new(1.8,0.2,0.4),CFrame.new(0,0.55,0),Color3.fromRGB(181,145,59))
        tool.Grip=CFrame.new(0,-0.1,0)*CFrame.Angles(0,0,math.rad(-12))
    elseif id=="Crossbow" then
        piece("Stock",Vector3.new(0.65,0.65,3.4),CFrame.new(0,0.5,-0.6),wood,Enum.Material.Wood)
        for _,side in ipairs({-1,1}) do
            piece("BowLimb",Vector3.new(2.2,0.25,0.45),CFrame.new(side*1.15,0.55,-1.4)*CFrame.Angles(0,side*0.23,0),metal)
            piece("BowString",Vector3.new(2.5,0.05,0.05),CFrame.new(side*1.1,0.55,-0.55)*CFrame.Angles(0,-side*0.5,0),steel)
        end
        piece("LoadedBolt",Vector3.new(0.1,0.1,2.8),CFrame.new(0,0.9,-1),steel)
        muzzleZ=-2.4; tool.Grip=CFrame.new(0,-0.2,0.2)
    elseif id=="Handgun" then
        piece("Slide",Vector3.new(0.55,0.5,1.7),CFrame.new(0,0.65,-0.5),steel)
        piece("Sight",Vector3.new(0.12,0.15,0.15),CFrame.new(0,0.98,-1.15),metal)
        muzzleZ=-1.4; tool.Grip=CFrame.new(0,-0.2,0)
    else
        piece("RifleBody",Vector3.new(0.65,0.65,3.3),CFrame.new(0,0.6,-0.7),metal)
        piece("Barrel",Vector3.new(0.25,0.25,2.5),CFrame.new(0,0.65,-3),steel)
        piece("Stock",Vector3.new(0.65,1,1.4),CFrame.new(0,0.4,1.4),wood,Enum.Material.Wood)
        piece("Scope",Vector3.new(0.4,0.4,1.4),CFrame.new(0,1.25,-0.5),metal)
        muzzleZ=-4.3; tool.Grip=CFrame.new(0,-0.3,0.5)
    end
    local muzzle=Instance.new("Attachment"); muzzle.Name="Muzzle"; muzzle.Position=Vector3.new(0,0.65,muzzleZ); muzzle.Parent=handle
    for _,p in ipairs(tool:GetChildren()) do
        if p:IsA("BasePart") and p~=handle then local weld=Instance.new("WeldConstraint"); weld.Part0=handle; weld.Part1=p; weld.Parent=p end
    end
    return tool
end
return Models
