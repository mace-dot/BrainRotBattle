-- Ammunition and all completion clocks belong to the server.
local Weapons = {}; Weapons.__index = Weapons
function Weapons.new(config) return setmetatable({Config=config, Players={}}, Weapons) end
function Weapons:reset(id)
    local p = {ReadyAt=0, Weapons={}}
    for name, def in pairs(self.Config.Weapons) do
        p.Weapons[name] = {Ammo=def.Magazine or 0, Reserve=def.Reserve or 0, ReloadUntil=0}
    end
    self.Players[id] = p
end
function Weapons:remove(id) self.Players[id] = nil end
function Weapons:cancel(id)
    local p = self.Players[id]
    if p then for _, s in pairs(p.Weapons) do s.ReloadUntil=0 end end
end
function Weapons:equip(id, weapon)
    local p = self.Players[id]
    if p and p.Equipped ~= weapon then self:cancel(id); p.Equipped=weapon end
end
function Weapons:get(id, now, weapon)
    local p = self.Players[id]
    weapon = weapon or (p and p.Equipped) or "Sniper"
    local s = p and p.Weapons[weapon]
    if s and s.ReloadUntil > 0 and now >= s.ReloadUntil then
        local transfer = math.min(self.Config.Weapons[weapon].Magazine-s.Ammo, s.Reserve)
        s.Ammo=s.Ammo+transfer; s.Reserve=s.Reserve-transfer; s.ReloadUntil=0
    end
    return s
end
function Weapons:reload(id, now, weapon)
    local p = self.Players[id]
    weapon = weapon or (p and p.Equipped) or "Sniper"
    local def, s = self.Config.Weapons[weapon], self:get(id, now, weapon)
    if not s or not def.Magazine or s.ReloadUntil > 0 or s.Ammo >= def.Magazine or s.Reserve <= 0 then return false end
    s.ReloadUntil=now+def.Reload
    return true
end
function Weapons:attack(id, weapon, now)
    local p, def = self.Players[id], self.Config.Weapons[weapon]
    if not p or not def then return false end
    self:equip(id, weapon)
    local s=self:get(id,now,weapon)
    if now < p.ReadyAt or s.ReloadUntil > 0 then return false end
    if def.Magazine then
        if s.Ammo <= 0 then return false end
        s.Ammo=s.Ammo-1
    end
    p.ReadyAt=now+def.Cooldown
    return true
end
return Weapons
