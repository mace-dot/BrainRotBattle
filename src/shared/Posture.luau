-- Evaluate the same bounded pose on the server and all clients. Supports both
-- classic Motor6D and upgraded AnimationConstraint avatars without changing C0.
local Posture={}
function Posture.isJoint(item) return item:IsA("Motor6D") or item:IsA("AnimationConstraint") end
function Posture.apply(joints,root,stance,time,moving)
    local stride=moving and math.sin(time*8)*0.12 or 0
    for joint in pairs(joints) do
        if joint.Parent then
            local pose=CFrame.new()
            local name=joint.Name
            if joint.Part0==root then
                if stance=="Prone" then pose=CFrame.new(0,0,-0.4)*CFrame.Angles(-math.pi/2,0,0)
                elseif stance=="Crouch" then pose=CFrame.Angles(math.rad(-18),0,0) end
                -- Convert a root-space bend into the joint's own basis.
                joint.Transform=joint.C0:Inverse()*pose*joint.C0
            else
                local side=name:find("Left") and 1 or -1
                if stance=="Crouch" then
                    if name:find("Hip") then pose=CFrame.Angles(math.rad(-50)+stride*side,0,0)
                    elseif name:find("Knee") then pose=CFrame.Angles(math.rad(85)-stride*side,0,0) end
                elseif stance=="Prone" then
                    if name:find("Shoulder") then pose=CFrame.Angles(math.rad(70)+stride*side,0,0)
                    elseif name:find("Hip") then pose=CFrame.Angles(0,0,stride*side*0.5) end
                end
                joint.Transform=pose
            end
        end
    end
end
return Posture
