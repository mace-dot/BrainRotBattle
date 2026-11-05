-- Pure multiplayer rules: eight character teams, four seats and one shared objective each.
local Match = {}
Match.__index = Match
local function count(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end
function Match.new(config)
    return setmetatable({ Config = config, Phase = "Waiting", Round = 0, Deadline = 0,
        Choices = {}, Reservations = {}, Members = {}, Teams = {}, Result = "", Outcome = nil }, Match)
end
function Match:seats(base) return count(self.Reservations[base]) end
function Match:eligible()
    return count(self.Choices) >= self.Config.MinimumPlayers and count(self.Reservations) >= self.Config.MinimumTeams
end
function Match:releaseChoice(id)
    local old = self.Choices[id]
    if old then
        local seats = self.Reservations[old]
        if seats then
            seats[id] = nil
            if next(seats) == nil then self.Reservations[old] = nil end
        end
        self.Choices[id] = nil
    end
end
function Match:select(id, base)
    if type(base) ~= "number" or base % 1 ~= 0 or not self.Config.Characters[base] then
        return false, "Unknown Brainrot team."
    end
    local member = self.Members[id]
    if self.Phase == "Active" and member and not member.Eliminated then
        return false, "Your current team is locked until the round ends."
    end
    if self.Choices[id] == base then return true, "Already on team " .. self.Config.Characters[base].Name end
    if self:seats(base) >= self.Config.TeamSize then return false, "That team is full (4/4). Choose another portal." end
    if not self.Choices[id] and count(self.Choices) >= self.Config.Capacity then
        return false, "The next round is full."
    end
    -- Validate before releasing the previous seat. No yields: simultaneous joins are atomic.
    self:releaseChoice(id)
    self.Reservations[base] = self.Reservations[base] or {}
    self.Reservations[base][id] = true
    self.Choices[id] = base
    return true, "Joined " .. self.Config.Characters[base].Name .. " (" .. self:seats(base) .. "/4)"
end
function Match:leave(id)
    self:releaseChoice(id)
    local member = self.Members[id]
    if member then
        member.Eliminated = true
        member.Alive = false
        member.SpawnToken = member.SpawnToken + 1
        -- A disconnect never destroys the objective of teammates who are still playing.
        local occupied = false
        for _, other in pairs(self.Members) do
            if other.Base == member.Base and not other.Eliminated then occupied = true end
        end
        if not occupied and self.Teams[member.Base] then self.Teams[member.Base].HP = 0 end
    end
end
function Match:participant(id)
    local member = self.Members[id]
    if self.Phase == "Active" and member and not member.Eliminated then return member end
    return nil
end
function Match:canFight(id)
    local member = self:participant(id)
    return member ~= nil and member.Alive
end
function Match:sameTeam(a, b)
    local first, second = self.Members[a], self.Members[b]
    return first ~= nil and second ~= nil and first.Base == second.Base
end
function Match:survivors()
    local result = {}
    for id, member in pairs(self.Members) do
        if not member.Eliminated then table.insert(result, id) end
    end
    return result
end
function Match:survivingTeams()
    local seen, result = {}, {}
    for _, member in pairs(self.Members) do
        if not member.Eliminated and not seen[member.Base] then
            seen[member.Base] = true
            table.insert(result, member.Base)
        end
    end
    table.sort(result)
    return result
end
function Match:start(now)
    if self.Phase ~= "Waiting" and self.Phase ~= "Countdown" then return false end
    if not self:eligible() then return false end
    self.Round = self.Round + 1
    self.Phase = "Active"
    self.Deadline = now + self.Config.RoundDuration
    self.Members, self.Teams = {}, {}
    self.Result, self.Outcome = "", nil
    for base, seats in pairs(self.Reservations) do
        local roster = {}
        for id in pairs(seats) do table.insert(roster, id) end
        table.sort(roster)
        self.Teams[base] = { HP = self.Config.BrainrotHealth, Roster = roster }
        for slot, id in ipairs(roster) do
            self.Members[id] = { Base = base, Slot = slot, Alive = true, Eliminated = false, SpawnToken = 1 }
        end
    end
    self.Choices, self.Reservations = {}, {}
    return true
end
function Match:damageObjective(attacker, base, amount)
    local member = self:participant(attacker)
    local target = self.Teams[base]
    if not member or not member.Alive or member.Base == base or not target or target.HP <= 0
        or type(amount) ~= "number" or amount ~= amount or amount <= 0 or amount == math.huge then return false end
    target.HP = math.max(0, target.HP - amount)
    if target.HP == 0 then
        -- Invalidate every dead teammate's pending respawn; living teammates keep their final life.
        for _, other in pairs(self.Members) do
            if other.Base == base and not other.Alive and not other.Eliminated then
                other.Eliminated = true
                other.SpawnToken = other.SpawnToken + 1
            end
        end
    end
    return true
end
function Match:die(id)
    local member = self:participant(id)
    if not member or not member.Alive then return nil end
    member.Alive = false
    member.SpawnToken = member.SpawnToken + 1
    if self.Teams[member.Base].HP <= 0 then member.Eliminated = true end
    return { Round = self.Round, Token = member.SpawnToken, CanRespawn = not member.Eliminated }
end
function Match:respawn(id, round, token)
    local member = self:participant(id)
    if round ~= self.Round or not member or member.SpawnToken ~= token
        or member.Alive or self.Teams[member.Base].HP <= 0 then return false end
    member.Alive = true
    return true
end
function Match:finish(now, winner, reason)
    if self.Phase ~= "Active" then return end
    self.Phase = "Results"
    self.Deadline = now + self.Config.ResultsDuration
    self.Outcome = { WinnerTeam = winner, Reason = reason, Round = self.Round }
    self.Result = winner and ("TEAM WINS: " .. self.Config.Characters[winner].Name) or ("Draw: " .. reason)
    for _, member in pairs(self.Members) do member.SpawnToken = member.SpawnToken + 1 end
end
function Match:step(now)
    if self.Phase == "Active" then
        local alive = self:survivingTeams()
        if #alive <= 1 then
            self:finish(now, alive[1], #alive == 0 and "simultaneous elimination" or "last surviving team")
            return "Finished"
        elseif now >= self.Deadline then
            self:finish(now, nil, "time limit reached")
            return "Finished"
        end
    elseif self.Phase == "Results" and now >= self.Deadline then
        self.Phase = "Intermission"
        self.Deadline = now + self.Config.Intermission
        self.Members, self.Teams = {}, {}
        return "Intermission"
    elseif self.Phase == "Intermission" and now >= self.Deadline then
        self.Phase, self.Deadline = "Waiting", 0
        return "Waiting"
    elseif self.Phase == "Waiting" or self.Phase == "Countdown" then
        if not self:eligible() then self.Phase, self.Deadline = "Waiting", 0
        elseif self.Phase == "Waiting" then self.Phase, self.Deadline = "Countdown", now+self.Config.Countdown
        elseif now >= self.Deadline and self:start(now) then return "Started" end
    end
    return nil
end
return Match
