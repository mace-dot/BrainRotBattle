local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("BattleRemotes")
local action = remotes:WaitForChild("Action")
local moveAction=remotes:WaitForChild("Movement")
local snapshot = remotes:WaitForChild("Snapshot")
local feedback = remotes:WaitForChild("Feedback")
local latest = { Active = false, Alive = false, Weapon = "" }
local scoped = false
local originalFOV, originalMode, originalSensitivity
local nextAttack = 0
local bound = setmetatable({}, { __mode = "k" })

local gui = Instance.new("ScreenGui")
gui.Name = "BrainRotBattleHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function frame(parent, position, size, color)
    local f = Instance.new("Frame")
    f.Position = position
    f.Size = size
    f.BackgroundColor3 = color or Color3.fromRGB(12, 26, 24)
    f.BackgroundTransparency = 0.12
    f.BorderSizePixel = 0
    f.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = f
    return f
end

local function text(parent, position, size, caption, fontSize, color)
    local t = Instance.new("TextLabel")
    t.Position = position
    t.Size = size
    t.BackgroundTransparency = 1
    t.Text = caption
    t.TextSize = fontSize or 18
    t.TextColor3 = color or Color3.fromRGB(235, 246, 235)
    t.Font = Enum.Font.GothamBold
    t.TextWrapped = true
    t.TextStrokeTransparency = 0.6
    t.Parent = parent
    return t
end

local header = frame(gui, UDim2.fromScale(0.5, 0.015), UDim2.new(0.92, 0, 0, 94))
header.AnchorPoint = Vector2.new(0.5, 0)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(680, 94)
limit.Parent = header
text(header, UDim2.fromOffset(8, 6), UDim2.new(1, -16, 0, 24), "BRAIN ROT BATTLES", 23, Color3.fromRGB(116, 255, 183))
local phaseLabel = text(header, UDim2.fromOffset(8, 34), UDim2.new(1, -16, 0, 21), "Waiting for server…", 16)
local statusLabel = text(header, UDim2.fromOffset(8, 57), UDim2.new(1, -16, 0, 30), "8 Brainrot teams • 4 players per team • Join a portal", 14)
local teamRoster = text(gui, UDim2.new(0.025, 0, 0, 115), UDim2.new(0.4, 0, 0, 110), "", 14)
teamRoster.TextXAlignment = Enum.TextXAlignment.Left
teamRoster.TextYAlignment = Enum.TextYAlignment.Top

local stats = frame(gui, UDim2.new(0.025, 0, 1, -20), UDim2.new(0.43, 0, 0, 205))
stats.AnchorPoint = Vector2.new(0, 1)
local statsLimit = Instance.new("UISizeConstraint")
statsLimit.MaxSize = Vector2.new(320, 205)
statsLimit.Parent = stats
local healthLabel = text(stats, UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 21), "PLAYER • 200 / 200", 16)
local healthTrack = frame(stats, UDim2.fromOffset(12, 31), UDim2.new(1, -24, 0, 8), Color3.fromRGB(43, 69, 57))
local healthFill = frame(healthTrack, UDim2.new(), UDim2.fromScale(1, 1), Color3.fromRGB(108, 238, 166))
local brainrotLabel = text(stats, UDim2.fromOffset(12, 44), UDim2.new(1, -24, 0, 36), "CHOOSE YOUR BRAINROT", 14)
local brainrotTrack = frame(stats, UDim2.fromOffset(12, 84), UDim2.new(1, -24, 0, 8), Color3.fromRGB(61, 62, 54))
local brainrotFill = frame(brainrotTrack, UDim2.new(), UDim2.fromScale(1, 1), Color3.fromRGB(255, 211, 101))
local weaponLabel = text(stats, UDim2.fromOffset(10, 101), UDim2.new(1, -20, 0, 30), "Five weapons supplied in battle", 14)

local movementLabel=text(stats,UDim2.fromOffset(10,135),UDim2.new(1,-20,0,20),"STAND / STAMINA 100%",13)
local staminaTrack=frame(stats,UDim2.fromOffset(12,159),UDim2.new(1,-24,0,7),Color3.fromRGB(48,61,67))
local staminaFill=frame(staminaTrack,UDim2.new(),UDim2.fromScale(1,1),Color3.fromRGB(105,196,236))
local controlsLabel=text(stats,UDim2.fromOffset(8,172),UDim2.new(1,-16,0,28),"Shift: sprint / C: crouch / X: prone / R: reload",11)
local function inputLayout()
    local touch=UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    stats.AnchorPoint=touch and Vector2.new(0,0) or Vector2.new(0,1)
    stats.Position=touch and UDim2.new(0.02,0,0,114) or UDim2.new(0.025,0,1,-20)
    stats.Size=touch and UDim2.new(0.5,0,0,112) or UDim2.new(0.43,0,0,205)
    healthLabel.Position=UDim2.fromOffset(10,touch and 0 or 7); healthLabel.TextSize=touch and 12 or 16
    brainrotLabel.Position=UDim2.fromOffset(10,touch and 20 or 44)
    brainrotLabel.Size=UDim2.new(1,-20,0,touch and 26 or 36); brainrotLabel.TextSize=touch and 11 or 14
    weaponLabel.Position=UDim2.fromOffset(10,touch and 48 or 101)
    weaponLabel.Size=UDim2.new(1,-20,0,28); weaponLabel.TextSize=touch and 12 or 14
    movementLabel.Position=UDim2.fromOffset(10,touch and 78 or 135); movementLabel.TextSize=touch and 11 or 13
    staminaTrack.Position=UDim2.fromOffset(12,touch and 101 or 159)
    healthTrack.Visible=not touch; brainrotTrack.Visible=not touch; controlsLabel.Visible=not touch; teamRoster.Visible=not touch
    local gamepad=string.find(UserInputService:GetLastInputType().Name,"Gamepad")~=nil
    controlsLabel.Text=gamepad and "L3: sprint / B: crouch / D-pad down: prone / X: reload / L2: scope" or "Shift: sprint / C: crouch / X: prone / R: reload"
end
UserInputService.LastInputTypeChanged:Connect(inputLayout)
inputLayout()

local alert = text(gui, UDim2.fromScale(0.5, 0.25), UDim2.new(0.9, 0, 0, 44), "", 22, Color3.fromRGB(255, 125, 111))
alert.AnchorPoint = Vector2.new(0.5, 0)
local toast = text(gui, UDim2.fromScale(0.5, 0.36), UDim2.new(0.88, 0, 0, 50), "", 20, Color3.fromRGB(255, 231, 161))
toast.AnchorPoint = Vector2.new(0.5, 0)
local reticle = text(gui, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(40, 40), "+", 30)
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Visible = false
local hitMarker = text(gui, UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(60, 60), "×", 48, Color3.fromRGB(255, 212, 104))
hitMarker.AnchorPoint = Vector2.new(0.5, 0.5)
hitMarker.Visible = false
local scopeRing = frame(gui, UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.56, 0.56))
scopeRing.AnchorPoint = Vector2.new(0.5, 0.5)
scopeRing.BackgroundTransparency = 1
scopeRing.Visible = false
scopeRing:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(1, 0)
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.Parent = scopeRing
local ringStroke = Instance.new("UIStroke")
ringStroke.Thickness = 4
ringStroke.Color = Color3.fromRGB(10, 18, 16)
ringStroke.Parent = scopeRing
text(scopeRing, UDim2.new(0.5, -1, 0, 0), UDim2.new(0, 2, 1, 0), "│", 30)

local function currentTool()
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    if tool and tool:GetAttribute("BattleWeapon") then return tool end
    return nil
end

local function setScope(enabled)
    local tool = currentTool()
    enabled = enabled and latest.Active and latest.Alive and tool ~= nil and tool.Name == "Sniper"
    local camera = workspace.CurrentCamera
    if enabled == scoped then return end
    scoped = enabled
    if enabled then
        originalFOV = camera.FieldOfView
        originalMode = player.CameraMode
        originalSensitivity = UserInputService.MouseDeltaSensitivity
        camera.FieldOfView = 25
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        UserInputService.MouseDeltaSensitivity = 0.35
    else
        if camera then camera.FieldOfView = originalFOV or 70 end
        player.CameraMode = originalMode or Enum.CameraMode.Classic
        UserInputService.MouseDeltaSensitivity = originalSensitivity or 1
    end
    scopeRing.Visible = enabled
end

local function aimPoint()
    local camera = workspace.CurrentCamera
    local center = camera.ViewportSize/2
    local ray = camera:ViewportPointToRay(center.X, center.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and {player.Character} or {}
    local result = workspace:Raycast(ray.Origin, ray.Direction*Config.Weapons.Sniper.Range, params)
    return result and result.Position or ray.Origin+ray.Direction*Config.Weapons.Sniper.Range
end

local function attack()
    local tool = currentTool()
    if not tool or not latest.Active or not latest.Alive or (latest.Protection or 0) > 0 or os.clock() < nextAttack then return end
    local def = Config.Weapons[tool.Name]
    if not def then return end
    nextAttack = os.clock()+def.Cooldown
    action:FireServer("Attack", aimPoint())
    if def.Kind == "Melee" then
        local grip = tool.Grip
        local swing = TweenService:Create(tool, TweenInfo.new(def.Window*0.7), { Grip = grip*CFrame.Angles(math.rad(-85), 0, math.rad(20)) })
        swing:Play()
        task.delay(0.15, function()
            if tool.Parent then TweenService:Create(tool, TweenInfo.new(0.22), { Grip = grip }):Play() end
        end)
    else
        local grip=tool.Grip
        TweenService:Create(tool,TweenInfo.new(0.06),{Grip=grip*CFrame.Angles(math.rad(-7),0,0)}):Play()
        task.delay(0.08,function() if tool.Parent then TweenService:Create(tool,TweenInfo.new(0.16),{Grip=grip}):Play() end end)
    end
end

local function bindTool(tool)
    if not tool:IsA("Tool") or bound[tool] then return end
    bound[tool] = true
    tool.Activated:Connect(attack)
    tool.Unequipped:Connect(function() setScope(false) end)
end
local function characterAdded(char)
    setScope(false)
    nextAttack = 0
    for _, child in ipairs(char:GetChildren()) do bindTool(child) end
    char.ChildAdded:Connect(bindTool)
end
local backpack = player:WaitForChild("Backpack")
for _, child in ipairs(backpack:GetChildren()) do bindTool(child) end
backpack.ChildAdded:Connect(bindTool)
player.CharacterAdded:Connect(characterAdded)
if player.Character then characterAdded(player.Character) end

local function bindControls(enabled)
    if not enabled then
        ContextActionService:UnbindAction("BattleFire")
        ContextActionService:UnbindAction("BattleReload")
        ContextActionService:UnbindAction("BattleScope")
        for _,name in ipairs({"Sprint","Crouch","Prone"}) do ContextActionService:UnbindAction("Battle"..name) end
        moveAction:FireServer("SprintOff")
        return
    end
    ContextActionService:BindAction("BattleFire", function(_, state)
        if state == Enum.UserInputState.Begin then attack() end
        return Enum.ContextActionResult.Sink
    end, true, Enum.KeyCode.ButtonR2)
    ContextActionService:SetTitle("BattleFire", "FIRE")
    ContextActionService:SetPosition("BattleFire", UDim2.new(1, -65, 1, -140))
    ContextActionService:BindAction("BattleReload", function(_, state)
        if state == Enum.UserInputState.Begin then
            action:FireServer("Reload")
            local tool=currentTool()
            if tool and Config.Weapons[tool.Name].Magazine and latest.Ammo<Config.Weapons[tool.Name].Magazine and latest.Reserve>0 then
                local grip=tool.Grip
                TweenService:Create(tool,TweenInfo.new(0.2),{Grip=grip*CFrame.Angles(0,0,math.rad(25))}):Play()
                task.delay(0.4,function() if tool.Parent then TweenService:Create(tool,TweenInfo.new(0.2),{Grip=grip}):Play() end end)
            end
        end
        return Enum.ContextActionResult.Sink
    end, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
    ContextActionService:SetTitle("BattleReload", "RELOAD")
    ContextActionService:SetPosition("BattleReload", UDim2.new(1, -135, 1, -140))
    ContextActionService:BindAction("BattleScope", function(_, state)
        if state == Enum.UserInputState.Begin then setScope(not scoped) end
        return Enum.ContextActionResult.Sink
    end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)
    ContextActionService:SetTitle("BattleScope", "SCOPE")
    ContextActionService:SetPosition("BattleScope", UDim2.new(1, -205, 1, -140))
    ContextActionService:BindAction("BattleSprint",function(_,state,input)
        if state==Enum.UserInputState.Begin then
            local toggle=input.UserInputType==Enum.UserInputType.Touch or input.KeyCode==Enum.KeyCode.ButtonL3
            moveAction:FireServer(toggle and latest.Sprint and "SprintOff" or "SprintOn")
        elseif (state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel) and input.KeyCode==Enum.KeyCode.LeftShift then moveAction:FireServer("SprintOff") end
        return Enum.ContextActionResult.Sink
    end,true,Enum.KeyCode.LeftShift,Enum.KeyCode.ButtonL3)
    ContextActionService:SetTitle("BattleSprint","SPRINT")
    ContextActionService:SetPosition("BattleSprint",UDim2.new(1,-65,1,-210))
    for index,name in ipairs({"Crouch","Prone"}) do
        ContextActionService:BindAction("Battle"..name,function(_,state)
            if state==Enum.UserInputState.Begin then moveAction:FireServer(name) end
            return Enum.ContextActionResult.Sink
        end,true,index==1 and Enum.KeyCode.C or Enum.KeyCode.X,index==1 and Enum.KeyCode.ButtonB or Enum.KeyCode.DPadDown)
        ContextActionService:SetTitle("Battle"..name,string.upper(name))
        ContextActionService:SetPosition("Battle"..name,UDim2.new(1,-65-index*70,1,-210))
    end
end

local controlsEnabled = false
snapshot.OnClientEvent:Connect(function(data)
    latest = data
    local controls = data.Active and data.Alive
    if controls ~= controlsEnabled then controlsEnabled = controls; bindControls(controls) end
    if not controls or data.Weapon ~= "Sniper" then setScope(false) end
    reticle.Visible = controls and data.Weapon ~= ""
    phaseLabel.Text = string.upper(data.Phase) .. " • Round "..data.Round .. (data.Seconds > 0 and (" • "..data.Seconds.."s") or "")
    healthLabel.Text = "PLAYER • " .. data.Health .. " / 200 HP"
    healthFill.Size = UDim2.fromScale(math.clamp(data.Health/Config.PlayerHealth, 0, 1), 1)
    local def = Config.Characters[data.Base]
    if data.Active and def then
        brainrotLabel.Text = def.Name .. " • " .. data.ObjectiveHP .. " / 50 HP"
        brainrotFill.BackgroundColor3 = Color3.fromHex(def.Color)
        brainrotFill.Size = UDim2.fromScale(data.ObjectiveHP/Config.BrainrotHealth, 1)
        statusLabel.Text = data.Alive and (data.Opponents .. " enemy teams remaining • Protect your team's Brainrot") or "Respawning at your team's base…"
    else
        brainrotLabel.Text = def and ("TEAM: "..def.Name) or "CHOOSE YOUR BRAINROT TEAM"
        brainrotFill.Size = UDim2.fromScale(def and 1 or 0, 1)
        local seats = def and data.Choices[data.Base].Count or 0
        statusLabel.Text = def and ("TEAM JOINED • "..seats.."/4 • Waiting for at least 2 teams") or "Walk into a Brainrot portal to join a team (up to 4 players)."
    end
    local roster = {}
    for _, mate in ipairs(data.Teammates or {}) do
        table.insert(roster, (mate.Eliminated and "OUT • " or (mate.Alive and "ALIVE • " or "RESPAWNING • ")) .. mate.Name)
    end
    teamRoster.Text = #roster > 0 and ("YOUR TEAM\n"..table.concat(roster, "\n")) or ""
    teamRoster.TextColor3 = def and Color3.fromHex(def.Color) or Color3.new(1, 1, 1)
    alert.Text = ""
    if data.Active and data.ObjectiveHP <= 0 then alert.Text = "TEAM BRAINROT DESTROYED — NO MORE RESPAWNS"
    elseif data.Eliminated then alert.Text = "ELIMINATED • Choose a portal for the next round"
    elseif data.Protection > 0 then alert.Text = "SPAWN SHIELD • Combat unlocks in "..math.ceil(data.Protection).."s" end
    if data.Phase == "Results" or data.Phase == "Intermission" then statusLabel.Text = data.Result end
    if data.Practice then
        phaseLabel.Text = "STUDIO PRACTICE — NOT A LIVE MATCH"
        statusLabel.Text = data.Active and "Test enemy objectives, cover and respawns • No timer or automatic victory" or "Studio practice is running • Use the test tools to reset or exit"
    end
    local weapon=Config.Weapons[data.Weapon]
    if weapon and weapon.Magazine then
        weaponLabel.Text=string.upper(data.Weapon).." / "..data.Ammo.." loaded / "..data.Reserve.." reserve"..(data.Reloading>0 and (" / Reload "..string.format("%.1fs",data.Reloading)) or "")
    elseif weapon then weaponLabel.Text=string.upper(data.Weapon).." / SWING"
    else weaponLabel.Text=controls and "Equip a weapon from your backpack" or "Five weapons supplied in battle" end
    local stamina=math.clamp(data.Stamina or 1,0,1)
    staminaFill.Size=UDim2.fromScale(stamina,1)
    movementLabel.Text=string.upper(data.Sprint and "Sprint" or data.Stance or "Stand").." / STAMINA "..math.floor(stamina*100+0.5).."%"
    local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.CameraOffset=Vector3.new(0,data.Stance=="Prone" and 0.25 or data.Stance=="Crouch" and -0.15 or 0,0) end

end)

local toastVersion, hitVersion = 0, 0
feedback.OnClientEvent:Connect(function(event)
    if event.Kind == "Shot" then
        local distance = (event.To-event.From).Magnitude
        if distance > 0.01 then
            local tracer = Instance.new("Part")
            tracer.Name = "LocalTracer"
            tracer.Anchored = true
            tracer.CanCollide = false
            tracer.CanQuery = false
            tracer.CanTouch = false
            tracer.Size = Vector3.new(0.07, 0.07, distance)
            tracer.CFrame = CFrame.lookAt(event.From, event.To)*CFrame.new(0, 0, -distance/2)
            tracer.Color = Color3.fromRGB(255, 222, 130)
            tracer.Material = Enum.Material.Neon
            tracer.Parent = workspace
            Debris:AddItem(tracer, 0.1)
        end
    elseif event.Kind == "Hit" then
        hitVersion = hitVersion+1
        local version = hitVersion
        hitMarker.Visible = true
        task.delay(0.2, function() if version == hitVersion then hitMarker.Visible = false end end)
    elseif event.Kind == "Notice" or event.Kind == "Hurt" then
        toastVersion = toastVersion+1
        local version = toastVersion
        toast.Text = event.Text or ""
        task.delay(3.5, function() if version == toastVersion then toast.Text = "" end end)
    end
end)
