-- Optional Studio panel. The server independently authorizes every action.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("BattleRemotes")
if remotes:GetAttribute("StudioPracticeEnabled") ~= true then return end
local remote = remotes:WaitForChild("Practice")
local player = Players.LocalPlayer
local selectedBase = 1
local state = { Active = false, Owner = 0 }
local gui = Instance.new("ScreenGui")
gui.Name = "StudioPracticeTools"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(0.975, 0, 0, 120)
local expanded = UDim2.new(0.46, 0, 0.60, 0)
panel.Size = expanded
panel.BackgroundColor3 = Color3.fromRGB(20, 29, 39)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(340, 500)
limit.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel
local function button(parent, caption, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 34)
    b.BackgroundColor3 = Color3.fromRGB(51, 76, 91)
    b.TextColor3 = Color3.fromRGB(235, 249, 255)
    b.Text = caption
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextWrapped = true
    b.AutoButtonColor = true
    b.BorderSizePixel = 0
    b.Parent = parent
    b.Activated:Connect(callback)
    return b
end
local body = Instance.new("ScrollingFrame")
body.Position = UDim2.fromOffset(5, 40)
body.Size = UDim2.new(1, -10, 1, -46)
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollBarThickness = 5
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Parent = panel
local order = Instance.new("UIListLayout")
order.Padding = UDim.new(0, 6)
order.SortOrder = Enum.SortOrder.LayoutOrder
order.Parent = body
local collapsed = false
local toggle = button(panel, "STUDIO TEST TOOLS  −", function()
    collapsed = not collapsed
    body.Visible = not collapsed
    panel.Size = collapsed and UDim2.new(0.46, 0, 0, 34) or expanded
end)
toggle.Position = UDim2.fromOffset(4, 0)
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -8, 0, 64)
status.BackgroundTransparency = 1
status.Font = Enum.Font.GothamBold
status.TextColor3 = Color3.fromRGB(255, 215, 126)
status.TextSize = 13
status.TextWrapped = true
status.Text = "Choose a team portal, then start solo practice."
status.Parent = body
local buttons = {}
local function action(caption, kind)
    local b = button(body, caption, function() remote:FireServer(kind) end)
    table.insert(buttons, { Button = b, Kind = kind })
end
action("Start Solo Practice", "Start")
action("Reset Objectives + Recover Player", "ResetObjectives")
action("Respawn at My Base", "Respawn")
action("Destroy My Brainrot (Final-life Test)", "DestroyOwnObjective")
local choose = button(body, "Choose Base: " .. Config.Characters[selectedBase].Name, function()
    selectedBase = selectedBase % #Config.Characters + 1
end)
local switch = button(body, "Switch to Chosen Base", function() remote:FireServer("SwitchBase", selectedBase) end)
table.insert(buttons, { Button = switch, Kind = "SwitchBase" })
action("Return to Holding", "ReturnToHolding")
action("End Practice", "EndPractice")
local function update()
    choose.Text = "Choose Base: " .. Config.Characters[selectedBase].Name .. " →"
    toggle.Text = "STUDIO TEST TOOLS  " .. (collapsed and "+" or "−")
    for _, entry in ipairs(buttons) do
        local allowed = state.Active and state.Owner == player.UserId and entry.Kind ~= "Start"
            or (not state.Active and entry.Kind == "Start")
        entry.Button.Active = allowed
        entry.Button.AutoButtonColor = allowed
        entry.Button.TextTransparency = allowed and 0 or 0.55
    end
end
choose.Activated:Connect(update)
toggle.Activated:Connect(update)
remote.OnClientEvent:Connect(function(data)
    state = data
    gui.Enabled = data.Enabled
    if data.Message ~= "" then status.Text = data.Message
    elseif data.Active then status.Text = data.Owner == player.UserId and "STUDIO PRACTICE — NOT A LIVE MATCH" or "Another tester is practicing."
    else status.Text = "Choose a team portal, then start solo practice." end
    update()
end)
update()
remote:FireServer("Status")
