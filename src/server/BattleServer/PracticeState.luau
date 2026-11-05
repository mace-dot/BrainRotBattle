-- Studio sandbox rules. MatchState (the production team rules) stays unchanged.
local Practice = {}
Practice.__index = Practice

function Practice.new(config, Match, owner, base, round)
    local state = Match.new(config)
    state.Phase, state.Round, state.Deadline = "Active", round, 0
    state.IsPractice = true
    state.Owner = owner
    state.Members[owner] = { Base = base, Slot = 1, Alive = true, Eliminated = false, SpawnToken = 1 }
    -- Explicit training objectives, never fake players or normal roster entries.
    for i in ipairs(config.Characters) do
        state.Teams[i] = { HP = config.BrainrotHealth, Roster = i == base and {owner} or {}, PracticeTarget = i ~= base }
    end
    return setmetatable(state, { __index = function(_, key) return Practice[key] or Match[key] end })
end

function Practice:step(_) return nil end -- no automatic victory or timer in the sandbox
function Practice:select(_id, _base) return false, "Practice is running. End practice to resume team selection." end
function Practice:start(_) return false end

function Practice:destroyOwnObjective()
    local member = self.Members[self.Owner]
    self.Teams[member.Base].HP = 0
    if not member.Alive then
        member.Eliminated = true
        member.SpawnToken = member.SpawnToken + 1
    end
end

function Practice:revive(round)
    local member = self.Members[self.Owner]
    self.Round = round
    member.SpawnToken = member.SpawnToken + 1
    member.Alive, member.Eliminated = true, false
end

function Practice:retire()
    self.Phase = "Disabled"
    for _, member in pairs(self.Members) do member.SpawnToken = member.SpawnToken + 1 end
end

return Practice
