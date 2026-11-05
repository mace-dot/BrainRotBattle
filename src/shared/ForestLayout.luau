-- Deterministic tree placement, also testable without the Roblox engine.
local Forest = {}
function Forest.plan(config, landmarks)
    local trees = {}
    for sector=1,#config.Characters do
        local angle=-math.pi/2+(sector-1)*2*math.pi/#config.Characters+math.pi/#config.Characters
        for ring=1,7 do
            for column=1,5 do
                local radius=55+ring*(config.BaseRadius-90)/7+((column*7+ring*3)%13-6)
                local tangent=(column-3)*16
                local x=math.cos(angle)*radius-math.sin(angle)*tangent
                local z=math.sin(angle)*radius+math.cos(angle)*tangent
                local clear=true
                for _,point in ipairs(landmarks or {}) do
                    if (x-point.X)^2+(z-point.Z)^2<(point.Clearance+8)^2 then clear=false end
                end
                if clear then
                    local index=#trees+1
                    local climb=index%15==0
                    table.insert(trees,{X=x,Z=z,Index=index,Climbable=climb,
                        Height=(climb and 40 or 28)+((sector*7+ring*3+column)%11),
                        Variant=(sector+ring+column)%3})
                end
            end
        end
    end
    return trees
end
return Forest
