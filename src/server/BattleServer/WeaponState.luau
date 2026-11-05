-- Server-owned weapon clock / ammo; no client damage, ammo or timestamps accepted.
local Weapons = {}
Weapons.__index = Weapons
function Weapons.new(config)
    return setmetatable({ Config = config, Players = {} }, Weapons)
end
function Weapons:reset(id)
    self.Players[id] = { Ammo = self.Config.Weapons.Sniper.Magazine, ReadyAt = 0, ReloadUntil = 0 }
end
function Weapons:remove(id) self.Players[id] = nil end
function Weapons:get(id, now)
    local s = self.Players[id]
    if s and s.ReloadUntil > 0 and now >= s.ReloadUntil then
        s.Ammo = self.Config.Weapons.Sniper.Magazine
        s.ReloadUntil = 0
    end
    return s
end
function Weapons:reload(id, now)
    local s = self:get(id, now)
    if not s or s.ReloadUntil > 0 or s.Ammo >= self.Config.Weapons.Sniper.Magazine then return false end
    s.ReloadUntil = now + self.Config.Weapons.Sniper.Reload
    s.ReadyAt = math.max(s.ReadyAt, s.ReloadUntil)
    return true
end
function Weapons:attack(id, weapon, now)
    local def = self.Config.Weapons[weapon]
    local s = self:get(id, now)
    if not def or not s or now < s.ReadyAt or s.ReloadUntil > 0 then return false end
    if weapon == "Sniper" then
        if s.Ammo <= 0 then self:reload(id, now); return false end
        s.Ammo = s.Ammo - 1
    end
    -- Shared ready time prevents weapon swapping to bypass attack cooldowns.
    s.ReadyAt = now + def.Cooldown
    return true
end
return Weapons
