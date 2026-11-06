-- Server-authored joint poses and collision hulls replicate to every observer.
local Posture=require(game:GetService("ReplicatedStorage").Shared.Posture)
local Rig={}; Rig.__index=Rig
function Rig.new(character)
    local hum=character:FindFirstChildOfClass("Humanoid")
    local root=character:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return nil end
    local self=setmetatable({Character=character,Hum=hum,Root=root,Hip=hum.HipHeight,JumpPower=hum.JumpPower,JumpHeight=hum.JumpHeight,Motors={},Parts={},Stance="Stand"},Rig)
    for _,item in ipairs(character:GetDescendants()) do
        if Posture.isJoint(item) then self.Motors[item]=true end
        if item:IsA("BasePart") then self.Parts[item]=item.CanCollide end
    end
    local hull=Instance.new("Part")
    hull.Name="PostureCollision"; hull.Transparency=1; hull.CanCollide=false; hull.CanTouch=false; hull.CanQuery=false; hull.Massless=true
    hull.Size=Vector3.new(3,2,5.5); hull.CFrame=root.CFrame*CFrame.new(0,0,-0.5); hull.Parent=character
    local weld=Instance.new("WeldConstraint"); weld.Part0=root; weld.Part1=hull; weld.Parent=hull
    self.Hull=hull
    self.Animate=character:FindFirstChild("Animate")
    self.AnimateDisabled=self.Animate and self.Animate.Disabled
    self.JointAdded=character.DescendantAdded:Connect(function(item)
        if Posture.isJoint(item) then self.Motors[item]=true end
    end)
    return self
end
function Rig:grounded()
    if self.Hum:GetState()==Enum.HumanoidStateType.Climbing or math.abs(self.Root.AssemblyLinearVelocity.Y)>6 then return false end
    local leg=self.Character:FindFirstChild("Left Leg")
    local height=self.Hum.HipHeight+self.Root.Size.Y/2+(leg and leg.Size.Y or 0)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={self.Character}; params.RespectCanCollide=true
    return workspace:Raycast(self.Root.Position,Vector3.new(0,-math.max(1,height+0.65),0),params)~=nil
end
function Rig:clear(stance)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={self.Character}; params.RespectCanCollide=true
    local ground=workspace:Raycast(self.Root.Position,Vector3.new(0,-7,0),params)
    if not ground then return false end
    local height=stance=="Stand" and 7 or stance=="Crouch" and 4.8 or 2.6
    local size=Vector3.new(3.5,height,stance=="Prone" and 6.5 or 3.5)
    local position=Vector3.new(self.Root.Position.X,ground.Position.Y+height/2+0.15,self.Root.Position.Z)
    local overlap=OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances={self.Character}; overlap.RespectCanCollide=true
    return #workspace:GetPartBoundsInBox(CFrame.new(position)*self.Root.CFrame.Rotation,size,overlap)==0
end
function Rig:pose(stance)
    if self.Stance==stance then return end
    self.Stance=stance
    local low=stance~="Stand"
    if self.Animate then self.Animate.Disabled=low or self.AnimateDisabled end
    local animator=self.Hum:FindFirstChildOfClass("Animator")
    if low and animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.1) end end
    self.Hum.HipHeight=self.Hip-(stance=="Prone" and 1.8 or stance=="Crouch" and 0.9 or 0)
    for part,collide in pairs(self.Parts) do if part.Parent then part.CanCollide=not low and collide end end
    self.Hull.CanCollide=low
    self.Hull.CanQuery=low
    self.Hum.JumpPower=low and 0 or self.JumpPower
    self.Hum.JumpHeight=low and 0 or self.JumpHeight
    self.Hull.Size=stance=="Prone" and Vector3.new(3,1.5,5.5) or Vector3.new(3,3.5,3)
    Posture.apply(self.Motors,self.Root,stance,workspace:GetServerTimeNow(),false)
    self.Hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,not low)
    self.Hum:SetStateEnabled(Enum.HumanoidStateType.Climbing,not low)
    self.Character:SetAttribute("BattleStance",stance)
end
function Rig:animate(time)
    if self.Stance~="Stand" and self.Root.Parent then
        local velocity=self.Root.AssemblyLinearVelocity
        Posture.apply(self.Motors,self.Root,self.Stance,time,Vector3.new(velocity.X,0,velocity.Z).Magnitude>0.5)
    end
end
function Rig:restore()
    self:pose("Stand")
    self.Hum.WalkSpeed=20
    if self.Hull then self.Hull:Destroy() end
    if self.JointAdded then self.JointAdded:Disconnect() end
end
return Rig
