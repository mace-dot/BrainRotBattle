-- Shared scalar geometry; also exercised without Roblox in the test runner.
local Layout = {}
function Layout.spawnOffset(slot)
    return { X = ((slot-1)%2 == 0 and -7 or 7), Z = (math.floor((slot-1)/2) == 0 and -5 or 5) }
end
function Layout.base(config, index)
    local angle = -math.pi / 2 + (index - 1) * math.pi * 2 / #config.Characters
    return { X = math.cos(angle) * config.BaseRadius, Z = math.sin(angle) * config.BaseRadius, Angle = angle }
end
function Layout.portal(config, index)
    local h = config.Holding
    local column = (index - 1) % 4
    local row = math.floor((index - 1) / 4)
    return { X = h.X + (column - 1.5) * 48, Y = h.Y, Z = h.Z + (row == 0 and -48 or 48) }
end
function Layout.inArena(config, x, y, z)
    local half = config.ArenaSize / 2
    return math.abs(x) <= half and math.abs(z) <= half and y > -30 and y < 100
end
function Layout.inHolding(config, x, y, z)
    local h = config.Holding
    return math.abs(x-h.X) < h.Width/2 and math.abs(z-h.Z) < h.Depth/2 and y > h.Y-8 and y < h.Y+60
end
return Layout
