-- Pure rules tests run on Lua 5.3/5.4 or texlua; production modules use the Lua/Luau subset.
local Config = dofile("src/shared/Config.luau")
local Match = dofile("src/server/BattleServer/MatchState.luau")
local WeaponState = dofile("src/server/BattleServer/WeaponState.luau")
local Layout = dofile("src/shared/Layout.luau")
local passed = 0
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err), 0) end
    passed = passed+1
    print("PASS " .. name)
end
local function eq(actual, expected)
    assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function active()
    local s = Match.new(Config)
    assert(s:select(101, 1))
    assert(s:select(202, 2))
    assert(s:start(0))
    return s
end

test("200 player HP, 50 team HP, 8 teams of 4", function()
    eq(Config.PlayerHealth,200); eq(Config.BrainrotHealth,50); eq(Config.TeamSize,4); eq(Config.Capacity,32); eq(#Config.Characters,8)
end)
test("eight independent character teams", function()
    local s=Match.new(Config); for i=1,8 do assert(s:select(i,i)) end; assert(s:start(0))
    for i=1,8 do eq(s.Members[i].Base,i); eq(s.Teams[i].HP,50) end
end)
test("four players share the same character and objective",function()
    local s=Match.new(Config); for id=1,4 do assert(s:select(id,1)) end; s:select(5,2); assert(s:start(0))
    eq(#s.Teams[1].Roster,4); for id=1,4 do eq(s.Members[id].Base,1) end
end)
test("fifth teammate is rejected atomically", function()
    local s=Match.new(Config); for id=1,4 do assert(s:select(id,1)) end
    eq(s:select(5,1),false); eq(s:seats(1),4); eq(s.Choices[5],nil)
end)
test("full team change preserves the previous seat", function()
    local s=Match.new(Config); s:select(10,2); for id=1,4 do s:select(id,1) end
    eq(s:select(10,1),false); eq(s.Choices[10],2); eq(s:seats(2),1)
end)
test("team switch releases only that player's seat",function()
    local s=Match.new(Config); s:select(1,1); s:select(2,1); assert(s:select(1,2)); eq(s:seats(1),1); eq(s.Choices[2],1)
end)
test("repeated portal touches do not consume extra seats",function()
    local s=Match.new(Config); for _=1,8 do assert(s:select(1,1)) end; eq(s:seats(1),1)
end)
test("all 32 seats can be filled",function()
    local s=Match.new(Config)
    for base=1,8 do for slot=1,4 do assert(s:select((base-1)*4+slot,base)) end end
    assert(s:start(0)); eq(#s:survivors(),32); eq(#s:survivingTeams(),8)
end)
test("invalid choices rejected", function()
    local s=Match.new(Config); for _,i in ipairs({0,-1,1.1,9,math.huge,0/0,"1"}) do eq(s:select(1,i),false) end
end)
test("capacity is configurable",function()
    local c={}; for k,v in pairs(Config) do c[k]=v end; c.Capacity=2
    local s=Match.new(c); assert(s:select(1,1)); assert(s:select(2,2)); eq(s:select(3,3),false)
end)
test("disconnect releases only one selected seat",function()
    local s=Match.new(Config); s:select(1,1); s:select(2,1); s:leave(1); eq(s:seats(1),1); eq(s.Choices[2],1)
end)
test("requires two opposing teams, not just two players",function()
    local s=Match.new(Config); for id=1,4 do s:select(id,1) end; eq(s:start(0),false); s:step(1); eq(s.Phase,"Waiting")
end)
test("countdown cancels when only one selected team remains",function()
    local s=Match.new(Config); s:select(1,1); s:select(2,2); s:step(0); eq(s.Phase,"Countdown")
    s:select(2,1); s:step(1); eq(s.Phase,"Waiting"); eq(s.Deadline,0)
end)
test("countdown locks selected teams and distinct spawn slots",function()
    local s=Match.new(Config); s:select(3,1); s:select(1,1); s:select(2,2); s:step(0)
    eq(s:step(Config.Countdown),"Started"); eq(s.Members[3].Base,1); eq(s.Members[1].Slot,1); eq(s.Members[3].Slot,2)
end)
test("active roster cannot switch or restart",function()
    local s=active(); eq(s:select(101,3),false); eq(s:start(2),false); eq(s.Round,1)
end)
test("late arrivals select next round without joining active teams",function()
    local s=active(); assert(s:select(303,1)); eq(s:canFight(303),false); eq(s.Members[303],nil)
    eq(s:seats(1),1); eq(#s.Teams[1].Roster,1)
end)
test("team members cannot damage their own shared objective",function()
    local s=active(); eq(s:damageObjective(101,1,10),false); eq(s.Teams[1].HP,50)
end)
test("waiting players cannot damage objectives",function() eq(active():damageObjective(303,1,10),false) end)
test("invalid objective damage rejected",function()
    local s=active(); for _,n in ipairs({-1,0,0/0,math.huge,"50"}) do eq(s:damageObjective(101,2,n),false) end
end)
test("objective loss does not kill living teammates",function()
    local s=Match.new(Config); s:select(101,1); s:select(202,2); s:select(203,2); s:start(0)
    assert(s:damageObjective(101,2,100)); eq(s.Teams[2].HP,0); eq(s:canFight(202),true); eq(s:canFight(203),true)
end)
test("five objective hits destroy shared brainrot",function()
    local s=active(); for _=1,5 do assert(s:damageObjective(101,2,10)) end
    eq(s.Teams[2].HP,0); eq(s:damageObjective(101,2,10),false)
end)
test("death grants respawn while team brainrot survives",function()
    local s=active(); local t=s:die(202); eq(t.CanRespawn,true); eq(s:canFight(202),false)
    assert(s:respawn(202,t.Round,t.Token)); eq(s:canFight(202),true)
end)
test("respawn token cannot be reused",function()
    local s=active(); local t=s:die(202); assert(s:respawn(202,t.Round,t.Token)); eq(s:respawn(202,t.Round,t.Token),false)
end)
test("destroyed team brainrot disables subsequent respawns",function()
    local s=active(); s:damageObjective(101,2,50); local t=s:die(202); eq(t.CanRespawn,false); eq(s:participant(202),nil)
end)
test("brainrot loss cancels every pending teammate respawn",function()
    local s=Match.new(Config); s:select(101,1); for id=201,204 do s:select(id,2) end; s:start(0)
    local a,b=s:die(201),s:die(202); s:damageObjective(101,2,50)
    eq(s:respawn(201,a.Round,a.Token),false); eq(s:respawn(202,b.Round,b.Token),false)
    eq(s.Members[201].Eliminated,true); eq(s.Members[202].Eliminated,true); eq(s:canFight(203),true); eq(s:canFight(204),true)
end)
test("friendly teams detected independently of player identity",function()
    local s=active(); s.Members[303]={Base=1}; eq(s:sameTeam(101,303),true); eq(s:sameTeam(101,202),false)
end)
test("dead player cannot deal damage",function() local s=active(); s:die(101); eq(s:damageObjective(101,2,10),false) end)
test("duplicate death callbacks are idempotent",function() local s=active(); s:die(101); eq(s:die(101),nil) end)
test("last surviving team wins even with multiple teammates alive",function()
    local s=Match.new(Config); s:select(101,1); s:select(102,1); s:select(202,2); s:start(0)
    s:damageObjective(101,2,50); s:die(202); eq(s:step(1),"Finished"); eq(s.Outcome.WinnerTeam,1)
end)
test("one eliminated teammate does not eliminate their team",function()
    local s=Match.new(Config); s:select(101,1); s:select(202,2); s:select(203,2); s:start(0)
    s:damageObjective(101,2,50); s:die(202); eq(s:step(1),nil); eq(#s:survivingTeams(),2)
end)
test("simultaneous final team elimination produces a draw",function()
    local s=active(); s:damageObjective(101,2,50); s:damageObjective(202,1,50); s:die(101); s:die(202)
    s:step(1); eq(s.Outcome.WinnerTeam,nil); eq(s.Outcome.Reason,"simultaneous elimination")
end)
test("waiting respawns keep team in contention",function() local s=active(); s:die(202); eq(s:step(1),nil); eq(s.Phase,"Active") end)
test("timeout produces explicit team draw",function()
    local s=active(); s:step(Config.RoundDuration); eq(s.Phase,"Results"); eq(s.Outcome.Reason,"time limit reached")
end)
test("teammate disconnect preserves objective and other respawns",function()
    local s=Match.new(Config); s:select(101,1); s:select(202,2); s:select(203,2); s:start(0); s:leave(202)
    eq(s.Teams[2].HP,50); local t=s:die(203); assert(s:respawn(203,t.Round,t.Token)); eq(s:step(1),nil)
end)
test("entire team disconnect disables objective and resolves winner",function()
    local s=active(); local t=s:die(202); s:leave(202); eq(s.Teams[2].HP,0); eq(s:respawn(202,t.Round,t.Token),false)
    s:step(1); eq(s.Outcome.WinnerTeam,1)
end)
test("new round resets shared HP and rejects old respawn tickets",function()
    local s=active(); local old=s:die(202); s:finish(1,nil,"test"); s:select(303,3); s:select(404,4)
    eq(s:step(1+Config.ResultsDuration),"Intermission"); local t=1+Config.ResultsDuration+Config.Intermission
    s:step(t); s:step(t); eq(s:step(t+Config.Countdown),"Started"); eq(s.Round,2)
    eq(s.Teams[3].HP,50); eq(s.Members[101],nil); eq(s:respawn(202,old.Round,old.Token),false)
end)
test("four spawn slots do not overlap",function()
    for a=1,4 do for b=a+1,4 do local p,q=Layout.spawnOffset(a),Layout.spawnOffset(b)
        assert(math.sqrt((p.X-q.X)^2+(p.Z-q.Z)^2)>=10)
    end end
end)
test("weapons reset to full magazine", function()
    local w=WeaponState.new(Config); w:reset(1); eq(w:get(1,0).Ammo,5); w:attack(1,"Sniper",0); w:reset(1); eq(w:get(1,1).Ammo,5)
end)
test("sniper cooldown and cross-weapon swap protection", function()
    local w=WeaponState.new(Config); w:reset(1); assert(w:attack(1,"Sniper",0)); eq(w:attack(1,"Bat",0.1),false)
    eq(w:get(1,0.1).Ammo,4); assert(w:attack(1,"Bat",1.2))
end)
test("reload holds empty magazine until timer completes", function()
    local w=WeaponState.new(Config); w:reset(1)
    for i=0,4 do assert(w:attack(1,"Sniper",i*2)) end
    eq(w:attack(1,"Sniper",10),false); eq(w:get(1,11).Ammo,0)
    eq(w:attack(1,"Bat",11),false); eq(w:get(1,13).Ammo,5)
end)
test("manual reload cannot be spammed or shorten timer", function()
    local w=WeaponState.new(Config); w:reset(1); eq(w:reload(1,0),false); w:attack(1,"Sniper",0)
    assert(w:reload(1,1)); eq(w:reload(1,2),false); eq(w:get(1,2).ReloadUntil,3.8)
end)
test("uninitialized weapons cannot fire",function() eq(WeaponState.new(Config):attack(1,"Sniper",0),false) end)
test("both weapons have separate objective damage", function()
    for _,id in ipairs({"Bat","Sniper"}) do assert(Config.Weapons[id].ObjectiveDamage < 50); assert(Config.Weapons[id].PlayerDamage > 0) end
end)
test("all bases fit arena with clearance", function()
    for i=1,8 do local p=Layout.base(Config,i); assert(math.abs(p.X)+45 < Config.ArenaSize/2); assert(math.abs(p.Z)+45 < Config.ArenaSize/2) end
end)
test("base separation substantially exceeds old layout", function()
    local minimum=math.huge
    for i=1,8 do for j=i+1,8 do local a,b=Layout.base(Config,i),Layout.base(Config,j); minimum=math.min(minimum,math.sqrt((a.X-b.X)^2+(a.Z-b.Z)^2)) end end
    assert(minimum > 250)
end)
test("all portals fit isolated holding area", function()
    for i=1,8 do local p=Layout.portal(Config,i); assert(Layout.inHolding(Config,p.X,p.Y+2,p.Z)); eq(Layout.inArena(Config,p.X,p.Y+2,p.Z),false) end
end)
test("bounds reject holding-area combat and arena escape", function()
    eq(Layout.inArena(Config,0,5,0),true); eq(Layout.inArena(Config,451,5,0),false); eq(Layout.inArena(Config,0,-40,0),false)
end)

-- Exercise the production combat handler with a minimal Roblox boundary mock.
local function combatTests()
    local vector = {}; vector.__index = function(v,k)
        if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
        if k=="Unit" then return v/v.Magnitude end
        if k=="Dot" then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
        return vector[k]
    end
    local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z},vector) end
    vector.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    vector.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
    vector.__mul=function(a,b) return vec(a.X*b,a.Y*b,a.Z*b) end
    vector.__div=function(a,b) return vec(a.X/b,a.Y/b,a.Z/b) end
    local function fixture()
        local match=active()
        local world={Bases={}}
        local feedback={FireClient=function() end,FireAllClients=function() end}
        local players={}
        local lookup={}
        function players:GetPlayerFromCharacter(c) return lookup[c] end
        local modules={Config={},Layout={},WeaponState={}}
        local rayResult, rayOrigin, rayDirection
        local env=setmetatable({script={Parent={WeaponState=modules.WeaponState}}, Vector3={new=vec},
            game={GetService=function(_,service)
                if service=="Players" then return players end
                return {Shared={Config=modules.Config,Layout=modules.Layout}}
            end},
            require=function(key)
                if key==modules.Config then return Config elseif key==modules.Layout then return Layout else return WeaponState end
            end,
            typeof=function(v) return getmetatable(v)==vector and "Vector3" or type(v) end,
            workspace={Raycast=function(_,origin,direction) rayOrigin=origin; rayDirection=direction; return rayResult end},
            RaycastParams={new=function() return {} end},Enum={RaycastFilterType={Exclude=1}},
        },{__index=_G})
        local Combat=assert(loadfile("src/server/BattleServer/Combat.luau","t",env))()
        local service=Combat.new(match,world,feedback,function() end)
        local function player(id)
            local attributes={ProtectedUntil=0}
            local tool={GetAttribute=function(_,key) return key=="BattleRound" and match.Round or "Sniper" end}
            local hum={Health=200,TakeDamage=function(self,n) self.Health=self.Health-n end}
            local root={Position=vec(0,5,0),CFrame={LookVector=vec(0,0,-1),RightVector=vec(1,0,0)},AssemblyMass=1,ApplyImpulse=function() end}
            local head={Position=vec(0,6,0)}
            local char={IsA=function(_,class) return class=="Model" end,GetAttribute=function() return true end,
                FindFirstChild=function(_,name) return name=="Head" and head or root end,
                FindFirstChildOfClass=function(_,class) return class=="Humanoid" and hum or tool end}
            local p={UserId=id,DisplayName=tostring(id),Character=char,GetAttribute=function(_,key) return attributes[key] end}
            lookup[char]=p
            service.Weapons:reset(id)
            return p,hum,attributes,root,head,tool
        end
        local attacker,_,attrs,root,head,tool=player(101)
        local victim,hum,vattrs=player(202)
        local hit={Parent=victim.Character,IsA=function() return false end,GetAttribute=function() return nil end}
        rayResult={Instance=hit,Position=vec(0,6,-20)}
        return {Service=service,Match=match,World=world,Attacker=attacker,Victim=victim,Hum=hum,Attrs=attrs,VAttrs=vattrs,Root=root,Head=head,Tool=tool,
            Shoot=function(t,aim) service:handle(attacker,"Attack",aim or vec(0,6,-30),t or 0) end,
            Ray=function() return rayOrigin,rayDirection end,
            SetHit=function(part) rayResult={Instance=part,Position=vec(0,6,-20)} end}
    end
    test("production sniper applies configured player damage",function() local f=fixture(); f.Shoot(); eq(f.Hum.Health,130) end)
    test("production sniper derives origin/range on server",function()
        local f=fixture(); f.Shoot(); local origin,direction=f.Ray(); eq(origin,f.Head.Position); eq(direction.Magnitude,650)
    end)
    test("production ray hits cover instead of victim behind it",function()
        local f=fixture(); f.SetHit({GetAttribute=function() return nil end,IsA=function() return false end}); f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("spawn shield rejects outgoing and incoming damage",function()
        local f=fixture(); f.Attrs.ProtectedUntil=5; f.Shoot(); eq(f.Hum.Health,200)
        f.Attrs.ProtectedUntil=0; f.VAttrs.ProtectedUntil=5; f.Shoot(2); eq(f.Hum.Health,200)
    end)
    test("production sniper cannot hurt a teammate",function()
        local f=fixture(); f.Match.Members[202].Base=1; f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("production bat cannot hurt a teammate",function()
        local f=fixture(); f.Match.Members[202].Base=1
        f.Tool.GetAttribute=function(_,key) return key=="BattleRound" and 1 or "Bat" end
        f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("production handler rejects NaN and fake aim values",function()
        local f=fixture(); f.Shoot(0,vec(0/0,0,0)); f.Shoot(0,"fake"); eq(f.Hum.Health,200); eq(f.Service.Weapons:get(101,0).Ammo,5)
    end)
    test("production handler rejects outside-arena attackers",function()
        local f=fixture(); f.Root.Position=vec(0,75,-650); f.Head.Position=vec(0,76,-650); f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("production handler rejects displaced head origins",function()
        local f=fixture(); f.Head.Position=vec(0,6,-200); f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("production handler rejects wrong-round tools",function()
        local f=fixture(); f.Tool.GetAttribute=function(_,key) return key=="BattleRound" and 999 or "Sniper" end; f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("production handler rejects waiting and eliminated attackers",function()
        local f=fixture(); f.Match:leave(101); f.Shoot(); eq(f.Hum.Health,200)
    end)
    test("objective hitbox uses objective damage not sniper player damage",function()
        local f=fixture(); local hit={GetAttribute=function() return 2 end}; f.World.Bases[2]={Hitbox=hit,Team=2}
        f.SetHit(hit); f.Shoot(); eq(f.Match.Teams[2].HP,40); eq(f.Hum.Health,200)
    end)
    test("practice targets use the production weapon raycast and damage path",function()
        local f=fixture()
        local Practice=dofile("src/server/BattleServer/PracticeState.luau")
        local s=Practice.new(Config,Match,101,1,1)
        f.Service.Match=s
        local hit={GetAttribute=function() return 2 end}
        f.World.Bases[2]={Hitbox=hit,Team=2}; f.SetHit(hit); f.Shoot()
        eq(s.Teams[2].HP,40); eq(s.Teams[1].HP,50)
    end)
    test("bat fan damages at most one player per swing",function()
        local f=fixture(); f.Tool.GetAttribute=function(_,key) return key=="BattleRound" and 1 or "Bat" end
        f.Shoot(); eq(f.Hum.Health,175); f.Shoot(0.1); eq(f.Hum.Health,175)
    end)
    test("server limits abusive request bursts",function()
        local f=fixture(); for _=1,12 do assert(f.Service:allowRequest(55,0)) end; eq(f.Service:allowRequest(55,0),false); assert(f.Service:allowRequest(55,1))
    end)
end
combatTests()
dofile("tests/practice.lua")(test, eq, Config, Match)

-- Compilation catches accidental syntax errors even in engine-dependent scripts.
for _, path in ipairs({
    "src/shared/Config.luau", "src/shared/Layout.luau", "src/server/Main.server.luau",
    "src/server/BattleServer/PracticeState.luau", "src/server/BattleServer/StudioPractice.luau",
    "src/server/BattleServer/StudioPreview.luau", "src/client/StudioPractice.client.luau",
    "src/server/BattleServer/Combat.luau", "src/server/BattleServer/World.luau",
    "src/server/BattleServer/MatchState.luau", "src/server/BattleServer/WeaponState.luau",
    "src/server/BattleServer/BrainrotSculptures.luau", "src/client/Battle.client.luau",
}) do
    test("syntax: "..path,function() assert(loadfile(path)) end)
end
print(string.format("\n%d tests passed",passed))
