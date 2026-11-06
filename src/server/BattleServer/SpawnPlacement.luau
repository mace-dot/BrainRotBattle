local Layout=require(game:GetService("ReplicatedStorage").Shared.Layout)
local Spawn={}
function Spawn.find(base,slot,character)
    local o=Layout.spawnOffset(slot)
    local params=OverlapParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.RespectCanCollide=true
    -- Every candidate stays in this slot's own quadrant on the ground floor.
    for _,shift in ipairs({{0,0},{0,3},{3,0},{3,3},{0,6},{3,6}}) do
        local x=o.X-(o.X>0 and 1 or -1)*shift[1]
        local z=o.Z-(o.Z>0 and 1 or -1)*shift[2]
        local cf=base.Transform*CFrame.lookAt(Vector3.new(x,4,z),Vector3.new(0,4,0))
        if #workspace:GetPartBoundsInBox(cf,Vector3.new(4.5,6,4.5),params)==0 then return cf end
    end
    return nil -- The caller waits safely until one of these positions clears.
end
return Spawn
