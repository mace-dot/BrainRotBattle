-- Geometry invariants; Studio still owns avatar physics and visual verification.
return function(test, eq, Config, Layout)
    local function vec(x,y,z) return {X=x,Y=y,Z=z} end
    local frame={}
    frame.__mul=function(a,b) return setmetatable({Position=vec(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z)},frame) end
    local function cf(x,y,z)
        return setmetatable({Position=type(x)=="table" and x or vec(x or 0,y or 0,z or 0)},frame)
    end
    local env=setmetatable({
        Vector3={new=vec,one=vec(1,1,1)},CFrame={new=cf},
        Color3={fromRGB=function(...) return {...} end},
        Enum={Material={Slate=1,Grass=2,Wood=3,WoodPlanks=4,Metal=5,Neon=6,Fabric=7},ModelStreamingMode={Persistent=1}},
        Instance={new=function(class) return {ClassName=class} end},
    },{__index=_G})
    local Architecture=assert(loadfile("src/server/BattleServer/ArenaArchitecture.luau","t",env))()
    local function capture()
        local parts={}
        return parts,function(parent,name,size,position)
            local p={Name=name,Size=size,Position=position.Position,Attributes={}}
            function p:SetAttribute(k,v) self.Attributes[k]=v end
            table.insert(parts,p)
            return p
        end
    end
    test("excavated ground covers arena except eight basement footprints",function()
        local parts,part=capture()
        Architecture.ground({},Config,Layout,part)
        local area=0
        for _,p in ipairs(parts) do
            area=area+p.Size.X*p.Size.Z
            for i=1,8 do
                local b=Layout.base(Config,i)
                local overlapX=math.min(p.Position.X+p.Size.X/2,b.X+32)-math.max(p.Position.X-p.Size.X/2,b.X-32)
                local overlapZ=math.min(p.Position.Z+p.Size.Z/2,b.Z+32)-math.max(p.Position.Z-p.Size.Z/2,b.Z-32)
                assert(overlapX<0.001 or overlapZ<0.001,"grass blocks a basement")
            end
        end
        assert(math.abs(area-(Config.ArenaSize^2-8*64^2))<0.01)
    end)
    test("base foundations remain aligned with their excavations",function()
        for i=1,8 do
            local b=Layout.base(Config,i)
            local quarter=b.Yaw/(math.pi/2)
            assert(math.abs(quarter-math.floor(quarter+0.5))<0.0001)
        end
    end)
    local parts,part=capture()
    local statuePlacement
    local built=Architecture.base({},Config.Characters[1],1,cf(),{},part,
        function(_,_,position) statuePlacement=position.Position; return {} end,
        function() return {} end)
    test("objective and matching statue are on second floor",function()
        eq(statuePlacement.Y,17.5)
        eq(built.Hitbox.Position.Y,22)
        eq(built.Hitbox.Attributes.ObjectiveBase,1)
        eq(built.Hitbox.CanCollide,false)
        assert(Layout.inArena(Config,0,-9,0))
        assert(Layout.inArena(Config,0,23,0))
    end)
    test("both staircases reach their landings with avatar headroom",function()
        local counts={BasementStair=0,UpperStair=0}
        local last={}
        for _,p in ipairs(parts) do
            if counts[p.Name] then
                counts[p.Name]=counts[p.Name]+1
                local top=p.Position.Y+p.Size.Y/2
                if last[p.Name] then assert(top-last[p.Name]<=0.81) end
                last[p.Name]=top
                for _,floor in ipairs(parts) do
                    if floor.Name=="GroundFloor" or floor.Name=="SecondFloor" or floor.Name=="ShelterRoof" then
                        local inX=math.abs(p.Position.X-floor.Position.X)<floor.Size.X/2-0.01
                        local inZ=math.abs(p.Position.Z-floor.Position.Z)<floor.Size.Z/2-0.01
                        local bottom=floor.Position.Y-floor.Size.Y/2
                        assert(not(inX and inZ and bottom>top+0.01 and bottom<top+6),"staircase has blocked headroom")
                    end
                end
            end
        end
        eq(counts.BasementStair,16); eq(counts.UpperStair,20)
        eq(last.BasementStair,0); eq(last.UpperStair,16)
    end)
    test("all four spawn slots stay on the ground floor away from stairwells",function()
        for slot=1,4 do
            local offset=Layout.spawnOffset(slot)
            local x,z=built.Spawn.Position.X+offset.X,built.Spawn.Position.Z+offset.Z
            assert(math.abs(x)<14 and z>=-20 and z<=0)
            eq(built.Spawn.Position.Y,4)
        end
    end)
    test("engine spawn is inside the base rather than a fallback sky spawn",function()
        local spawn=built.SpawnLocation
        eq(spawn.ClassName,"SpawnLocation")
        eq(spawn.CFrame.Position.X,0); eq(spawn.CFrame.Position.Z,-10)
        assert(spawn.CFrame.Position.Y<1)
        eq(spawn.Neutral,true); eq(spawn.AllowTeamChangeOnTouch,false)
        eq(spawn.CanCollide,false); eq(spawn.Duration,0)
    end)
    local HighGround=assert(loadfile("src/server/BattleServer/HighGround.luau","t",env))()
    test("limited high ground stays away from bases and within the island",function()
        local counts={Tower=0,Tree=0}
        for _,point in ipairs(HighGround.locations(Config)) do
            counts[point.Kind]=counts[point.Kind]+1
            assert(math.abs(point.X)+point.Clearance<Config.ArenaSize/2)
            assert(math.abs(point.Z)+point.Clearance<Config.ArenaSize/2)
            eq(HighGround.clearOfClimbs(Config,point),false)
            for i=1,#Config.Characters do
                local b=Layout.base(Config,i)
                assert((point.X-b.X)^2+(point.Z-b.Z)^2>(point.Clearance+46)^2)
            end
        end
        eq(counts.Tower,4); eq(counts.Tree,2)
        eq(HighGround.clearOfClimbs(Config,{X=0,Z=0}),true)
    end)
end
