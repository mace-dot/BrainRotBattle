local Layout=require(game:GetService("ReplicatedStorage").Shared.Layout)
local Cover={}
function Cover.plan(config,trees,landmarks)
    local sites={}
    for sector=1,#config.Characters do
        local angle=Layout.base(config,sector).Angle
        for ring=1,8 do
            local radius=85+ring*(config.BaseRadius-210)/8
            for _,side in ipairs({-1,1}) do
                local tangent=side*(32+(ring%2)*12)
                local x,z=math.cos(angle)*radius-math.sin(angle)*tangent,math.sin(angle)*radius+math.cos(angle)*tangent
                local clear=Layout.sceneryClear(config,x,z,11)
                for _,tree in ipairs(trees) do
                    if (x-tree.X)^2+(z-tree.Z)^2<(tree.Climbable and 27 or 18)^2 then clear=false end
                end
                for _,landmark in ipairs(landmarks) do
                    if (x-landmark.X)^2+(z-landmark.Z)^2<(landmark.Clearance+12)^2 then clear=false end
                end
                if clear then table.insert(sites,{X=x,Z=z,Sector=sector,Kind=(ring+(side==1 and 1 or 0))%3,Angle=angle}) end
            end
        end
    end
    return sites
end
return Cover
