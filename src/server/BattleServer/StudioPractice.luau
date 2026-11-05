-- All developer actions are gated here on the SERVER, including every request.
-- Dependency injection keeps lifecycle tests independent of Roblox engine mocks.
local StudioPractice = {}
StudioPractice.__index = StudioPractice
local actions = { Start = true, ResetObjectives = true, Respawn = true, SwitchBase = true,
    DestroyOwnObjective = true, ReturnToHolding = true, EndPractice = true, Status = true }

function StudioPractice.new(context)
    return setmetatable({ Context = context, State = nil, Owner = nil, Requests = {}, Epoch = context.LiveMatch.Round }, StudioPractice)
end

function StudioPractice:enabled()
    return self.Context.Config.StudioPracticeEnabled == true and self.Context.IsStudio() == true
end

function StudioPractice:nextRound()
    self.Epoch = math.max(self.Epoch, self.Context.LiveMatch.Round) + 1
    return self.Epoch
end

function StudioPractice:sync(recipient, message)
    self.Context.Notify(recipient, {
        Enabled = self:enabled(), Active = self.State ~= nil, Owner = self.Owner or 0,
        Base = self.State and self.State.Members[self.Owner].Base or 0,
        Message = message or "",
    })
end

function StudioPractice:replace(base)
    if self.State then self.State:retire() end
    self.State = self.Context.NewState(self.Owner, base, self:nextRound())
    self.Context.SetMatch(self.State)
    self.Context.Refresh()
    self.Context.LoadOwner(self.Owner)
end

function StudioPractice:finish(message, disconnected)
    if not self.State then return end
    local owner = self.Owner
    self.State:retire()
    self.State, self.Owner = nil, nil
    -- Keep round IDs monotonic across the swap so old respawn tickets cannot match.
    local live = self.Context.LiveMatch
    live.Round = self:nextRound()
    live.Phase, live.Deadline = "Waiting", 0
    self.Context.SetMatch(live)
    self.Context.Refresh()
    if not disconnected then self.Context.ReturnHolding(owner) end
    self:sync(nil, message or "Practice ended. Normal multiplayer selection restored.")
end

function StudioPractice:remove(id)
    self.Requests[id] = nil
    if self.Owner == id then self:finish("Practice ended because the tester left.", true) end
end

function StudioPractice:step()
    if self.State and not self:enabled() then self:finish("Practice disabled.") end
end

function StudioPractice:handle(id, action, base)
    -- No UI visibility, client flag, or supplied user ID can authorize live-server tools.
    if not self:enabled() then return false, "Studio practice is disabled." end
    if type(action) ~= "string" or not actions[action] then return false, "Unknown practice action." end
    local now = self.Context.Clock()
    if now - (self.Requests[id] or -math.huge) < 0.3 then return false, "Please wait before another practice action." end
    self.Requests[id] = now
    if action == "Status" then self:sync(id); return true end
    if self.Owner and self.Owner ~= id then
        self:sync(id, "Another tester owns this practice session. Ask them to end it first.")
        return false, "Practice already in use."
    end
    if action == "Start" then
        if self.State then self:sync(id, "Practice is already running."); return false end
        local live = self.Context.LiveMatch
        if live.Phase ~= "Waiting" and live.Phase ~= "Countdown" then
            self:sync(id, "A normal match is running. Finish it before starting practice.")
            return false
        end
        local chosen = live.Choices[id]
        if not chosen then self:sync(id, "Choose a Brainrot team portal first."); return false end
        if not self.Context.InHolding(id) then self:sync(id, "Start practice from the holding area."); return false end
        self.Owner = id
        live.Phase, live.Deadline = "Waiting", 0
        self:replace(chosen)
        self:sync(nil, "STUDIO PRACTICE — NOT A LIVE MATCH")
        return true
    end
    if not self.State then self:sync(id, "Start solo practice first."); return false end
    if action == "EndPractice" or action == "ReturnToHolding" then
        self:finish()
    elseif action == "ResetObjectives" then
        self:replace(self.State.Members[id].Base)
        self:sync(nil, "All objectives reset to 50 HP. Tester health and loadout restored.")
    elseif action == "Respawn" then
        self.State:revive(self:nextRound())
        self.Context.LoadOwner(id)
        self:sync(nil, "Respawned at your base. Objective damage is preserved.")
    elseif action == "SwitchBase" then
        if type(base) ~= "number" or base % 1 ~= 0 or not self.Context.Config.Characters[base] then
            self:sync(id, "Choose a valid practice base."); return false
        end
        self:replace(base)
        self:sync(nil, "Switched practice team and reset objectives.")
    elseif action == "DestroyOwnObjective" then
        self.State:destroyOwnObjective()
        self.Context.Refresh()
        self:sync(nil, "Your Brainrot is destroyed. Your next death eliminates you.")
    end
    return true
end

return StudioPractice
