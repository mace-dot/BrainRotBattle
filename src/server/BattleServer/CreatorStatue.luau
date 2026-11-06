local Players=game:GetService("Players")
local Statue={}
local cached
function Statue.build(parent,config,part)
    local site=Instance.new("Model"); site.Name="CreatorMonument"; site.Parent=parent
    part(site,"CreatorPedestal",Vector3.new(28,5,28),CFrame.new(0,2.5,0),Color3.fromRGB(84,91,82),Enum.Material.Slate)
    site:SetAttribute("CreatorUsername",config.CreatorUsername)
    site:SetAttribute("AvatarStatus","Loading")
    task.spawn(function()
        local ok,avatar=pcall(function()
            if cached then return cached:Clone() end
            local model=Players:CreateHumanoidModelFromUserIdAsync(config.CreatorUserId)
            for _,item in ipairs(model:GetDescendants()) do
                if item:IsA("Script") or item:IsA("LocalScript") or item:IsA("Animator") then item:Destroy() end
            end
            cached=model:Clone()
            return model
        end)
        if not site.Parent then if ok then avatar:Destroy() end; return end
        if not ok then
            site:SetAttribute("AvatarStatus","Unavailable - rebuild preview or restart to retry")
            warn("[BrainRotBattle] Could not load creator avatar",avatar)
            return
        end
        avatar.Name=config.CreatorUsername
        local _,size=avatar:GetBoundingBox()
        avatar:ScaleTo(avatar:GetScale()*math.min(config.CreatorStatueHeight/size.Y,54/math.max(size.X,size.Z)))
        avatar:PivotTo(CFrame.new())
        local box,scaled=avatar:GetBoundingBox()
        avatar:PivotTo(avatar:GetPivot()+Vector3.new(-box.Position.X,5-box.Position.Y+scaled.Y/2,-box.Position.Z))
        for _,item in ipairs(avatar:GetDescendants()) do
            if item:IsA("BasePart") then item.Anchored=true; item.CanCollide=item.Name~="HumanoidRootPart"; item.CanTouch=false; item.CanQuery=item.Name~="HumanoidRootPart" end
        end
        local hum=avatar:FindFirstChildOfClass("Humanoid")
        if hum then hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; hum.HealthDisplayType=Enum.HumanoidHealthDisplayType.AlwaysOff end
        avatar.Parent=site
        site:SetAttribute("AvatarStatus","Loaded")
    end)
end
return Statue
