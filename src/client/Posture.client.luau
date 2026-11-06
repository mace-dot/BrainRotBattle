local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Posture=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Posture"))
local rigs={}
local function track(character)
    if rigs[character] then return end
    local record={Joints={},Last="Stand"}; rigs[character]=record
    for _,item in ipairs(character:GetDescendants()) do if Posture.isJoint(item) then record.Joints[item]=true end end
    record.Added=character.DescendantAdded:Connect(function(item) if Posture.isJoint(item) then record.Joints[item]=true end end)
end
local function playerAdded(player)
    player.CharacterAdded:Connect(track)
    if player.Character then track(player.Character) end
end
Players.PlayerAdded:Connect(playerAdded)
for _,player in ipairs(Players:GetPlayers()) do playerAdded(player) end
RunService.PreSimulation:Connect(function()
    local time=workspace:GetServerTimeNow()
    for character,record in pairs(rigs) do
        if not character.Parent then record.Added:Disconnect(); rigs[character]=nil
        else
            local root=character:FindFirstChild("HumanoidRootPart")
            local hum=character:FindFirstChildOfClass("Humanoid")
            local stance=character:GetAttribute("BattleStance") or "Stand"
            if hum and hum.Health<=0 then stance="Stand" end
            if root and (stance~="Stand" or record.Last~="Stand") then
                local velocity=root.AssemblyLinearVelocity
                Posture.apply(record.Joints,root,stance,time,Vector3.new(velocity.X,0,velocity.Z).Magnitude>0.5)
            end
            if hum and character==Players.LocalPlayer.Character then
                -- SetStateEnabled intentionally does not replicate between peers.
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping,stance=="Stand")
                hum:SetStateEnabled(Enum.HumanoidStateType.Climbing,stance=="Stand")
            end
            record.Last=stance
        end
    end
end)
