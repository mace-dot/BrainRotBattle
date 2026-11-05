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
        function(_,_,position) statuePlacement=position.Position; return {GetAttribute=function() return 7 end} end,
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
            local padFound=false
            for _,p in ipairs(parts) do
                if p.Name=="SpawnPad" and p.Position.X==x and p.Position.Z==z then
                    assert(p.Size.X<4 and p.Size.Z<4)
                    padFound=true
                end
            end
            assert(padFound,"spawn slot must have its own compact pad")
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
        local counts={Tower=0,Bunker=0}
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
        eq(counts.Tower,2); eq(counts.Bunker,2)
        eq(HighGround.clearOfClimbs(Config,{X=0,Z=0}),true)
    end)
    local Forest=dofile("src/shared/ForestLayout.luau")
    test("one in fifteen built trees has a vine, spread across the forest",function()
        local sites=Forest.plan(Config,HighGround.locations(Config))
        local vines=0
        local quadrants={0,0,0,0}
        for i,site in ipairs(sites) do
            eq(site.Climbable,i%15==0)
            assert(math.abs(site.X)+16<Config.ArenaSize/2)
            assert(math.abs(site.Z)+16<Config.ArenaSize/2)
            if site.Climbable then
                vines=vines+1
                local q=(site.X<0 and 2 or 0)+(site.Z<0 and 1 or 0)+1
                quadrants[q]=quadrants[q]+1
                assert(site.Height>=40)
            end
        end
        eq(vines,math.floor(#sites/15))
        assert(vines>=15,"the island needs easy-to-find climbs")
        for _,count in ipairs(quadrants) do assert(count>=2) end
    end)
    test("objective bar follows health, hides for dormant bases and empties on destruction",function()
        local token={}
        local mockMath={}; for k,v in pairs(math) do mockMath[k]=v end
        mockMath.clamp=function(x,lo,hi) return math.max(lo,math.min(x,hi)) end
        local worldEnv=setmetatable({
            game={GetService=function() return {Shared={Config=token}} end},script={Parent={}},
            require=function(key) if key==token then return Config else return {} end end,
            math=mockMath,Color3={fromRGB=function(r,g,b) return {r,g,b} end},
            UDim2={fromScale=function(x,y) return {X=x,Y=y} end},
        },{__index=_G})
        local World=assert(loadfile("src/server/BattleServer/World.luau","t",worldEnv))()
        local b={Team=nil,HP=0,Hitbox={SetAttribute=function() end},
            Statue={GetChildren=function() return {} end},HealthBar={Gui={Enabled=false},Fill={}}}
        local world=setmetatable({Bases={b}},World)
        world:setObjective(1,1,Config.BrainrotHealth)
        eq(b.HealthBar.Gui.Enabled,true); eq(b.HealthBar.Fill.Size.X,1)
        world:setObjective(1,1,Config.BrainrotHealth/2)
        eq(b.HealthBar.Fill.Size.X,0.5)
        world:setObjective(1,1,0)
        eq(b.HealthBar.Fill.Size.X,0); eq(b.Hitbox.CanQuery,false)
        world:setObjective(1,nil,0)
        eq(b.HealthBar.Gui.Enabled,false)
    end)
end
