-- Geometry invariants; Studio still owns avatar physics and visual verification.
return function(test, eq, Config, Layout)
    local function vec(x,y,z) return {X=x,Y=y,Z=z} end
    local frame={}
    frame.__mul=function(a,b) return setmetatable({Position=vec(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z)},frame) end
    local function cf(x,y,z)
        return setmetatable({Position=type(x)=="table" and x or vec(x or 0,y or 0,z or 0)},frame)
    end
    local env=setmetatable({
        Vector3={new=vec,one=vec(1,1,1)},CFrame={new=cf,lookAt=function(position) return cf(position) end},
        game={GetService=function() return {Shared={Layout={}}} end},require=function() return Layout end,
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
            assert(math.abs(x)==12 and math.abs(z)==22)
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
        eq(spawn.CFrame.Position.X,-12); eq(spawn.CFrame.Position.Z,-22)
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
    local Forest=assert(loadfile("src/shared/ForestLayout.luau","t",env))()
    local landmarks=HighGround.locations(Config)
    for sector=1,8 do
        local a=Layout.base(Config,sector).Angle+math.pi/8
        table.insert(landmarks,{X=math.cos(a)*Config.BaseRadius*0.64,Z=math.sin(a)*Config.BaseRadius*0.64,Clearance=58})
    end
    local sites=Forest.plan(Config,landmarks)
    test("approximately one in five trees is climbable in every sector",function()
        local counts,vines={},{}
        for _,site in ipairs(sites) do
            counts[site.Sector]=(counts[site.Sector] or 0)+1
            if site.Climbable then vines[site.Sector]=(vines[site.Sector] or 0)+1 end
            assert(Layout.sceneryClear(Config,site.X,site.Z,16))
            for _,landmark in ipairs(landmarks) do
                assert((site.X-landmark.X)^2+(site.Z-landmark.Z)^2>=(landmark.Clearance+8)^2)
            end
        end
        for sector=1,8 do eq(vines[sector],math.floor(counts[sector]/Config.ClimbableTreeEvery)); assert(vines[sector]>=3) end
    end)
    test("final paths squarely meet all doors using each base transform",function()
        for sector=1,8 do
            local b=Layout.base(Config,sector); local route=Layout.approach(Config,sector)
            local door=Layout.transform(b,0,-32); local a,c=route[#route-1],route[#route]
            assert(math.abs(c.X-door.X)<0.001 and math.abs(c.Z-door.Z)<0.001)
            local dx,dz=c.X-a.X,c.Z-a.Z
            assert(math.abs(dx*math.cos(b.Yaw)-dz*math.sin(b.Yaw))<0.001)
            for slot=1,4 do
                local o=Layout.spawnOffset(slot); local p=Layout.transform(b,o.X,o.Z)
                local x=(p.X-b.X)*math.cos(b.Yaw)-(p.Z-b.Z)*math.sin(b.Yaw)
                local z=(p.X-b.X)*math.sin(b.Yaw)+(p.Z-b.Z)*math.cos(b.Yaw)
                assert(math.abs(x-o.X)<0.001 and math.abs(z-o.Z)<0.001)
            end
        end
    end)
    test("relocated bases have full rear clearance from perimeter",function()
        eq(Config.BaseRadius,568)
        for i=1,8 do
            local b=Layout.base(Config,i)
            assert(Config.ArenaSize/2-Config.WallThickness-math.abs(b.X)-32>=39.999)
            assert(Config.ArenaSize/2-Config.WallThickness-math.abs(b.Z)-32>=39.999)
        end
        assert(Config.PerimeterHeight>70)
    end)
    local Cover=assert(loadfile("src/shared/CoverLayout.luau","t",env))()
    test("large cover keeps trails excavations landmarks and climbs clear",function()
        local counts={}
        for _,site in ipairs(Cover.plan(Config,sites,landmarks)) do
            counts[site.Sector]=(counts[site.Sector] or 0)+1
            assert(Layout.sceneryClear(Config,site.X,site.Z,11))
            for _,tree in ipairs(sites) do
                assert((site.X-tree.X)^2+(site.Z-tree.Z)^2>=(tree.Climbable and 27 or 18)^2)
            end
        end
        for sector=1,8 do assert((counts[sector] or 0)>=6,"insufficient cover in sector "..sector) end
    end)
    test("objective glass is solid and queryable; protective room reaches roof",function()
        local count=0
        for _,p in ipairs(parts) do
            if p.Name=="ObjectiveGlass" then
                count=count+1; eq(p.CanCollide,true); eq(p.CanQuery,true)
                eq(p.Position.Y+p.Size.Y/2,38)
            end
            if p.Name=="ObjectiveBaffle" then eq(p.Position.Y-p.Size.Y/2,16); eq(p.Position.Y+p.Size.Y/2,38) end
        end
        eq(count,2)
    end)
    test("no exterior firing lane reaches any corner of objective hitbox",function()
        local function intersects(a,b,p)
            local lo,hi=0,1
            for _,axis in ipairs({"X","Y","Z"}) do
                local d=b[axis]-a[axis]; local min=p.Position[axis]-p.Size[axis]/2; local max=p.Position[axis]+p.Size[axis]/2
                if math.abs(d)<0.00001 then if a[axis]<min or a[axis]>max then return false end
                else
                    local x,y=(min-a[axis])/d,(max-a[axis])/d; if x>y then x,y=y,x end
                    lo=math.max(lo,x); hi=math.min(hi,y); if lo>hi then return false end
                end
            end
            return hi>=0 and lo<=1
        end
        for side=0,31 do for _,height in ipairs({4,18,28,48,68}) do
            local angle=side*math.pi/16; local start=vec(math.cos(angle)*110,height,math.sin(angle)*110)
            for _,x in ipairs({-4.5,0,4.5}) do for _,y in ipairs({17.5,22,26.5}) do for _,z in ipairs({13,18,23}) do
                local blocked=false
                for _,p in ipairs(parts) do
                    if p.Name=="SecondFloor" or p.Name:find("ObjectiveRoom") or p.Name=="ObjectiveGlass" or p.Name=="ObjectiveBaffle" or p.Name=="ObjectiveDoorJamb" or p.Name=="ObjectiveDoorLintel" then
                        if intersects(start,vec(x,y,z),p) then blocked=true; break end
                    end
                end
                assert(blocked,string.format("unprotected objective ray: side %d height %d target %f %f %f",side,height,x,y,z))
            end end end
        end end
    end)
    test("occupied spawn uses a nearby interior candidate and all blocked waits",function()
        local queries=0
        local spawnEnv=setmetatable({
            game=env.game,require=function() return Layout end,
            Vector3=env.Vector3,CFrame=env.CFrame,Enum={RaycastFilterType={Exclude=1}},
            OverlapParams={new=function() return {} end},
            workspace={GetPartBoundsInBox=function(_,position,size,params)
                queries=queries+1; assert(params.RespectCanCollide); eq(size.Y,6)
                assert(math.abs(position.Position.X)<=12 and math.abs(position.Position.Z)<=22)
                return queries==1 and {"occupant"} or {}
            end},
        },{__index=_G})
        local Spawn=assert(loadfile("src/server/BattleServer/SpawnPlacement.luau","t",spawnEnv))()
        local destination=Spawn.find({Transform=cf()},1,{})
        eq(queries,2); eq(destination.Position.X,-12); eq(destination.Position.Z,-19)
        spawnEnv.workspace.GetPartBoundsInBox=function() return {"occupied"} end
        eq(Spawn.find({Transform=cf()},4,{}),nil)
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
