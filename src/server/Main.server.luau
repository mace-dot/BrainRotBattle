-- Standalone PvP bootstrap. No dummy, tomb, merchant, mode popup or legacy saves.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TeamsService = game:GetService("Teams")
Players.CharacterAutoLoads = false

local Config = require(ReplicatedStorage.Shared.Config)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Server = script.Parent.BattleServer
local Match = require(Server.MatchState)
local World = require(Server.World)
local Combat = require(Server.Combat)
local match = Match.new(Config)
local liveMatch = match
local practice
local robloxTeams = {}
for index, def in ipairs(Config.Characters) do
    local team = Instance.new("Team")
    team.Name = def.Name
    team.TeamColor = BrickColor.new(Color3.fromHex(def.Color))
    team.AutoAssignable = false
    team.Parent = TeamsService
    robloxTeams[index] = team
end
local remotes = Instance.new("Folder")
remotes.Name = "BattleRemotes"
local function remote(name)
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = remotes
    return event
end
local action, snapshot, feedback = remote("Action"), remote("Snapshot"), remote("Feedback")
local practiceEnabled = Config.StudioPracticeEnabled == true and RunService:IsStudio()
remotes:SetAttribute("StudioPracticeEnabled", practiceEnabled)
local practiceRemote = practiceEnabled and remote("Practice") or nil
local world, combat
local initialized, loading, selectionAt, deathGeneration, teleportAt = {}, {}, {}, {}, {}
local function now() return workspace:GetServerTimeNow() end
local function notice(player, text) feedback:FireClient(player, { Kind = "Notice", Text = text }) end
local function rootOf(player) return player.Character and player.Character:FindFirstChild("HumanoidRootPart") end

local function nearHolding(player, position, radius)
    local root = rootOf(player)
    return root and not match:participant(player.UserId)
        and Layout.inHolding(Config, root.Position.X, root.Position.Y, root.Position.Z)
        and (root.Position-position).Magnitude <= radius
end

local function selectBase(player, index, position)
    local t = now()
    if t-(selectionAt[player] or 0) < 0.7 or not nearHolding(player, position, 22) then return end
    selectionAt[player] = t
    local _, message = match:select(player.UserId, index)
    notice(player, message)
    world:update(match, t)
end

local function travel(player, position)
    if not nearHolding(player, position, 16) or now()-(teleportAt[player] or 0) < 5 then return end
    if Config.SinglePlayerPlaceId <= 0 then notice(player, "Single player destination is not configured."); return end
    teleportAt[player] = now()
    notice(player, "Traveling to Single player…")
    task.spawn(function()
        local ok = pcall(function() TeleportService:TeleportAsync(Config.SinglePlayerPlaceId, {player}) end)
        if not ok and player.Parent then notice(player, "Travel failed. Please try the portal again.") end
    end)
end

-- Remove only our generated edit preview before constructing the runtime world.
if RunService:IsStudio() then require(Server.StudioPreview).remove() end
world = World.new(selectBase, travel)
combat = Combat.new(match, world, feedback, function() world:update(match, now()) end)

local function place(player, character)
    character:SetAttribute("BattleReady", false)
    local root = character:WaitForChild("HumanoidRootPart", 10)
    local hum = character:WaitForChild("Humanoid", 10)
    if not player.Parent or player.Character ~= character or not root or not hum then return end
    local member = match:participant(player.UserId)
    hum.MaxHealth = Config.PlayerHealth
    hum.Health = Config.PlayerHealth
    hum.WalkSpeed = Config.WalkSpeed
    hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
    hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
    -- Loading is finished before placement. Reset momentum so a falling old body
    -- cannot carry its velocity into the selected base.
    root.Anchored = true
    if member and member.Alive then
        local offset = Layout.spawnOffset(member.Slot)
        player.Team = robloxTeams[member.Base]
        player.Neutral = false
        local base = world.Bases[member.Base]
        player.RespawnLocation = base.SpawnLocation
        character:PivotTo(base.Spawn*CFrame.new(offset.X, 0, offset.Z))
        player:SetAttribute("ProtectedUntil", now()+Config.SpawnProtection)
        local shield = Instance.new("ForceField")
        shield.Name = "SpawnShield"
        shield.Parent = character
        game:GetService("Debris"):AddItem(shield, Config.SpawnProtection)
        combat:grant(player)
    else
        player.Neutral = true
        player.Team = nil
        player.RespawnLocation = world.HoldingSpawnLocation
        local offset = Vector3.new(((player.UserId%5)-2)*4, 0, 0)
        character:PivotTo(world.HoldingSpawn+offset)
        player:SetAttribute("ProtectedUntil", 0)
        combat:clearTools(player)
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.Anchored = false
    character:SetAttribute("BattleReady", true)
end

local loadCharacter, characterAdded
loadCharacter = function(player, attempt)
    if not player.Parent or loading[player] then return end
    loading[player] = true
    -- Retire the old holding/arena body before an asynchronous load. Otherwise the
    -- bounds watchdog can kill it using the NEW round's membership while loading.
    deathGeneration[player] = (deathGeneration[player] or 0)+1
    if player.Character then player.Character:SetAttribute("BattleReady", false) end
    task.spawn(function()
        local ok, err = pcall(function()
            local member = match:participant(player.UserId)
            player.RespawnLocation = member and member.Alive
                and world.Bases[member.Base].SpawnLocation or world.HoldingSpawnLocation
            player:LoadCharacterAsync()
            -- CharacterAdded fires BEFORE Roblox's final spawn positioning. Moving
            -- there can be overwritten, leaving the tester in the sky/out of bounds.
            if player.Parent and player.Character then characterAdded(player, player.Character) end
        end)
        loading[player] = nil
        if not ok and player.Parent then
            warn("[BrainRotBattle] character load failed", player.UserId, err)
            if (attempt or 0) < 2 then
                task.delay(1, function() loadCharacter(player, (attempt or 0)+1) end)
            else
                notice(player, "Character loading failed. Please rejoin.")
            end
        end
    end)
end

characterAdded = function(player, character)
    deathGeneration[player] = (deathGeneration[player] or 0)+1
    local generation = deathGeneration[player]
    place(player, character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or player.Character ~= character then return end
    hum.Died:Once(function()
        if player.Character ~= character or deathGeneration[player] ~= generation then return end
        combat:clearTools(player)
        local ticket = match:die(player.UserId)
        local round = match.Round
        task.delay(Config.RespawnDelay, function()
            if not player.Parent or player.Character ~= character or deathGeneration[player] ~= generation then return end
            if ticket and ticket.CanRespawn and match:respawn(player.UserId, ticket.Round, ticket.Token) then
                loadCharacter(player)
            elseif match.Round == round and not match:canFight(player.UserId) then
                loadCharacter(player) -- safe holding-area body; never an arena respawn
            end
        end)
    end)
end

local function added(player)
    if initialized[player] then return end
    initialized[player] = true
    player.Neutral = true
    player.Team = nil
    player.CharacterAdded:Connect(function(character)
        -- The loader owns final placement and death binding once loading completes.
        character:SetAttribute("BattleReady", false)
    end)
    loadCharacter(player)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player)
    if practice then practice:remove(player.UserId) end
    match:leave(player.UserId)
    combat:remove(player)
    initialized[player], loading[player], selectionAt[player], deathGeneration[player], teleportAt[player] = nil, nil, nil, nil, nil
    world:update(match, now())
end)
for _, player in ipairs(Players:GetPlayers()) do added(player) end

TeleportService.TeleportInitFailed:Connect(function(player)
    if player.Parent then notice(player, "Travel could not start. You can try the portal again.") end
end)
action.OnServerEvent:Connect(function(player, kind, aim)
    if type(kind) ~= "string" or #kind > 12 then return end
    combat:handle(player, kind, aim, now())
end)

local function holding(player)
    combat:clearTools(player)
    combat.Weapons:remove(player.UserId)
    player:SetAttribute("ProtectedUntil", 0)
    player.Neutral = true
    player.Team = nil
    player.RespawnLocation = world.HoldingSpawnLocation
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        char:PivotTo(world.HoldingSpawn+Vector3.new(((player.UserId%5)-2)*4, 0, 0))
        local root = rootOf(player)
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    else loadCharacter(player) end
end

-- One optional integration boundary: disabling the flag never loads practice rules.
if practiceEnabled then
    local PracticeState = require(Server.PracticeState)
    local StudioPractice = require(Server.StudioPractice)
    practice = StudioPractice.new({
        Config = Config, LiveMatch = liveMatch, IsStudio = function() return RunService:IsStudio() end, Clock = now,
        NewState = function(owner, base, round) return PracticeState.new(Config, Match, owner, base, round) end,
        SetMatch = function(current) match = current; combat.Match = current end,
        InHolding = function(id)
            local p = Players:GetPlayerByUserId(id)
            local root = p and rootOf(p)
            return root ~= nil and Layout.inHolding(Config, root.Position.X, root.Position.Y, root.Position.Z)
        end,
        LoadOwner = function(id)
            local p = Players:GetPlayerByUserId(id)
            if p then combat:clearTools(p); combat.Weapons:remove(id); loadCharacter(p) end
        end,
        ReturnHolding = function(id)
            local p = Players:GetPlayerByUserId(id)
            if p then
                local shield = p.Character and p.Character:FindFirstChild("SpawnShield")
                if shield then shield:Destroy() end
                holding(p)
            end
        end,
        Refresh = function() world:update(match, now()) end,
        Notify = function(id, data)
            if id then
                local p = Players:GetPlayerByUserId(id)
                if p then practiceRemote:FireClient(p, data) end
            else practiceRemote:FireAllClients(data) end
        end,
    })
    practiceRemote.OnServerEvent:Connect(function(player, kind, base)
        practice:handle(player.UserId, kind, base)
    end)
end

local function publish(t)
    local seconds = math.max(0, math.ceil(match.Deadline-t))
    local survivors = #match:survivingTeams()
    local result = match.Result
    local choices = {}
    for i, def in ipairs(Config.Characters) do
        choices[i] = { Name = def.Name, Count = match:seats(i), Capacity = Config.TeamSize }
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local member = match:participant(player.UserId)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local weapons = combat.Weapons:get(player.UserId, t)
        local health = hum and math.ceil(hum.Health) or 0
        local base = member and member.Base or match.Choices[player.UserId]
        local team = member and match.Teams[member.Base]
        local teammates = {}
        if team then
            for _, id in ipairs(team.Roster) do
                local p, m = Players:GetPlayerByUserId(id), match.Members[id]
                if p and m then table.insert(teammates, { Name = p.DisplayName, Alive = m.Alive, Eliminated = m.Eliminated }) end
            end
        end
        snapshot:FireClient(player, {
            Practice = match.IsPractice == true,
            Phase = match.Phase, Round = match.Round, Seconds = seconds, Result = result,
            Active = member ~= nil, Alive = member and member.Alive or false,
            Eliminated = match.Phase == "Active" and match.Members[player.UserId] ~= nil and member == nil,
            Base = base or 0, ObjectiveHP = team and team.HP or 0, Health = health,
            Opponents = math.max(0, survivors-(member and 1 or 0)), Choices = choices,
            Teammates = teammates, TeamSize = Config.TeamSize,
            Weapon = combat:equipped(player) or "",
            Ammo = weapons and weapons.Ammo or 0,
            Reloading = weapons and math.max(0, weapons.ReloadUntil-t) or 0,
            Protection = math.max(0, (player:GetAttribute("ProtectedUntil") or 0)-t),
        })
    end
end

local accumulated = 0
RunService.Heartbeat:Connect(function(dt)
    accumulated = accumulated+dt
    if accumulated < 0.15 then return end
    accumulated = 0
    local t = now()
    if practice then practice:step() end
    -- Resolve deaths/disconnects together on this tick before choosing a winner.
    for _, player in ipairs(Players:GetPlayers()) do
        local root = rootOf(player)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        local member = match:participant(player.UserId)
        if root and hum and hum.Health > 0 and player.Character:GetAttribute("BattleReady") then
            if member and member.Alive then
                if not Layout.inArena(Config, root.Position.X, root.Position.Y, root.Position.Z) then hum.Health = 0 end
            elseif not member and not Layout.inHolding(Config, root.Position.X, root.Position.Y, root.Position.Z) then
                holding(player)
            end
        end
    end
    local event = match:step(t)
    if event == "Started" then
        for _, player in ipairs(Players:GetPlayers()) do
            if match:participant(player.UserId) then
                combat:clearTools(player)
                loadCharacter(player)
            end
        end
    elseif event == "Finished" then
        for _, player in ipairs(Players:GetPlayers()) do holding(player) end
    end
    world:update(match, t)
    publish(t)
end)

if practiceEnabled then
    print("[BrainRotBattle] Choose a portal, then Studio Test Tools > Start Solo Practice. Use two opposing clients for normal PvP.")
elseif RunService:IsStudio() then
    print("[BrainRotBattle] Practice disabled. Start Server + 2 Players and choose opposing team portals.")
end
remotes.Parent = ReplicatedStorage
print("[BrainRotBattle] Ready", Config.BuildId, "PlaceId", game.PlaceId)
