-- Command Bar entry point for the stopped Studio editor. Uses live geometry builders.
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local World = require(script.Parent.World)
local Preview = { Name = "BrainRotBattle_EditorPreview" }

function Preview.remove()
    assert(RunService:IsStudio(), "Editor preview is Studio-only")
    local model = workspace:FindFirstChild(Preview.Name)
    if model then
        if model:GetAttribute("BrainRotGenerated") ~= true then return false, "Unrelated preview-name object preserved" end
        model:Destroy()
    end
    return true
end

function Preview.build()
    assert(RunService:IsStudio() and not RunService:IsRunning(), "Stop Play before building the editor preview")
    assert(Config.StudioPracticeEnabled == true, "Enable Config.StudioPracticeEnabled first")
    local built = World.build(workspace, { Name = Preview.Name })
    built.RoundLabel.Text = "EDITOR MAP PREVIEW\nPress Play for combat and Studio practice"
    print("[BrainRotBattle] Preview built. Select Workspace." .. Preview.Name .. " and press F to frame it.")
    return built.Model
end

return Preview
