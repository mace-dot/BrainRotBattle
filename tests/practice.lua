-- Called by run.lua with its test/eq helpers.
return function(test, eq, Config, Match)
    local PracticeState = dofile("src/server/BattleServer/PracticeState.luau")
    local Controller = dofile("src/server/BattleServer/StudioPractice.luau")
    local function fixture()
        local config = {}; for k,v in pairs(Config) do config[k]=v end
        local live = Match.new(config)
        live:select(101,1)
        local current = live
        local state = { Time = 0, Studio = true, Holding = true, Loads = {}, Returns = {}, Notices = {}, Refreshes = 0 }
        local ctx = {
            Config=config, LiveMatch=live, IsStudio=function() return state.Studio end, Clock=function() return state.Time end,
            NewState=function(owner,base,round) return PracticeState.new(config,Match,owner,base,round) end,
            SetMatch=function(nextMatch) current=nextMatch end,
            Refresh=function() state.Refreshes=state.Refreshes+1 end,
            LoadOwner=function(id) table.insert(state.Loads,id) end,
            ReturnHolding=function(id) table.insert(state.Returns,id) end,
            InHolding=function() return state.Holding end,
            Notify=function(id,data) table.insert(state.Notices,{Id=id,Data=data}) end,
        }
        local service=Controller.new(ctx)
        state.Service,state.Config,state.Live=service,config,live
        state.Current=function() return current end
        state.Send=function(kind,base,id) state.Time=state.Time+1; return service:handle(id or 101,kind,base) end
        return state
    end
    test("practice is rejected outside Studio even with flag enabled",function()
        local f=fixture(); f.Studio=false; eq(f.Send("Start"),false); eq(f.Current(),f.Live); eq(#f.Loads,0)
    end)
    test("one flag disables every practice action",function()
        local f=fixture(); f.Config.StudioPracticeEnabled=false
        for _,kind in ipairs({"Start","ResetObjectives","Respawn","SwitchBase","DestroyOwnObjective","ReturnToHolding","EndPractice","Status"}) do
            eq(f.Send(kind,2),false)
        end
        eq(f.Current(),f.Live)
    end)
    test("solo practice requires server-owned team selection",function()
        local f=fixture(); f.Live:releaseChoice(101); eq(f.Send("Start",3),false); eq(f.Service.Owner,nil)
    end)
    test("practice must start from holding",function()
        local f=fixture(); f.Holding=false; eq(f.Send("Start"),false); eq(f.Service.State,nil)
    end)
    test("solo practice admits one player at the selected real base",function()
        local f=fixture(); assert(f.Send("Start")); local s=f.Current()
        eq(s.IsPractice,true); eq(s.Members[101].Base,1); eq(s:canFight(101),true); eq(#f.Loads,1)
    end)
    test("practice creates objectives without fake players",function()
        local f=fixture(); f.Send("Start"); local s=f.Current(); eq(#s:survivors(),1)
        local members,roster=0,0
        for _ in pairs(s.Members) do members=members+1 end
        for _,team in pairs(s.Teams) do eq(team.HP,50); roster=roster+#team.Roster end
        eq(members,1); eq(roster,1); eq(s.Teams[2].PracticeTarget,true)
    end)
    test("solo practice never auto-wins or expires",function()
        local f=fixture(); f.Send("Start"); local s=f.Current()
        eq(s:step(1000000),nil); eq(s.Phase,"Active"); eq(s.Outcome,nil); eq(s.Deadline,0)
    end)
    test("practice enemy objectives use normal damage and ownership rules",function()
        local f=fixture(); f.Send("Start"); local s=f.Current()
        assert(s:damageObjective(101,2,10)); eq(s.Teams[2].HP,40)
        eq(s:damageObjective(101,1,10),false); eq(s.Teams[1].HP,50)
        eq(s:damageObjective(999,2,10),false)
    end)
    test("practice can destroy every enemy objective without ending",function()
        local f=fixture(); f.Send("Start"); local s=f.Current()
        for i=2,8 do assert(s:damageObjective(101,i,50)); eq(s.Teams[i].HP,0) end
        eq(s:step(99999),nil); eq(s.Phase,"Active")
    end)
    test("practice death respawns through normal ticket validation",function()
        local f=fixture(); f.Send("Start"); local s=f.Current(); local ticket=s:die(101)
        assert(ticket.CanRespawn); assert(s:respawn(101,ticket.Round,ticket.Token)); eq(s:canFight(101),true)
    end)
    test("destroy-own test causes final-life elimination",function()
        local f=fixture(); f.Send("Start"); assert(f.Send("DestroyOwnObjective")); local s=f.Current()
        eq(s.Teams[1].HP,0); eq(s:canFight(101),true); local t=s:die(101)
        eq(t.CanRespawn,false); eq(s:participant(101),nil); eq(s:step(99999),nil)
    end)
    test("destroy-own test cancels pending practice respawn",function()
        local f=fixture(); f.Send("Start"); local s=f.Current(); local t=s:die(101)
        f.Send("DestroyOwnObjective"); eq(s:respawn(101,t.Round,t.Token),false)
    end)
    test("reset restores all objectives and recovers an eliminated tester",function()
        local f=fixture(); f.Send("Start"); local old=f.Current(); f.Send("DestroyOwnObjective"); old:die(101)
        f.Send("ResetObjectives"); local s=f.Current(); eq(s:canFight(101),true)
        for _,team in pairs(s.Teams) do eq(team.HP,50) end
        eq(old.Phase,"Disabled"); eq(#f.Loads,2)
    end)
    test("reset invalidates old respawn callbacks",function()
        local f=fixture(); f.Send("Start"); local old=f.Current(); local t=old:die(101)
        f.Send("ResetObjectives"); eq(old:respawn(101,t.Round,t.Token),false)
        eq(f.Current():respawn(101,t.Round,t.Token),false)
    end)
    test("manual practice respawn preserves objective damage",function()
        local f=fixture(); f.Send("Start"); local s=f.Current(); s:damageObjective(101,2,20)
        f.Send("DestroyOwnObjective"); s:die(101); f.Send("Respawn")
        eq(s.Teams[1].HP,0); eq(s.Teams[2].HP,30); eq(s:canFight(101),true); eq(#f.Loads,2)
    end)
    test("switch base uses chosen character and fresh practice epoch",function()
        local f=fixture(); f.Send("Start"); local old=f.Current(); f.Send("SwitchBase",8)
        local s=f.Current(); eq(s.Members[101].Base,8); eq(s.Teams[8].PracticeTarget,false)
        eq(s.Teams[1].PracticeTarget,true); assert(s.Round>old.Round); eq(old.Phase,"Disabled")
    end)
    test("malformed base switches preserve practice session",function()
        local f=fixture(); f.Send("Start"); local old=f.Current()
        for _,base in ipairs({0,-1,9,1.5,"1",math.huge,0/0}) do eq(f.Send("SwitchBase",base),false); eq(f.Current(),old) end
    end)
    test("practice cannot overlap active normal matches",function()
        local f=fixture(); f.Live:select(202,2); assert(f.Live:start(0)); eq(f.Send("Start"),false); eq(f.Current(),f.Live)
    end)
    test("practice pauses countdown but preserves real reservations",function()
        local f=fixture(); f.Live:select(202,2); f.Live:step(0); eq(f.Live.Phase,"Countdown")
        assert(f.Send("Start")); eq(f.Live.Phase,"Waiting"); eq(f.Live.Choices[202],2)
    end)
    test("non-owner cannot control another tester's session",function()
        local f=fixture(); f.Send("Start"); local s=f.Current()
        eq(f.Send("EndPractice",nil,202),false); eq(f.Send("SwitchBase",3,202),false); eq(f.Current(),s)
    end)
    test("normal selection cannot mutate sandbox roster",function()
        local f=fixture(); f.Send("Start"); eq(f.Current():select(202,2),false); eq(f.Current().Members[202],nil)
    end)
    test("ending practice restores multiplayer and preserves selected seats",function()
        local f=fixture(); f.Send("Start"); local old=f.Current(); assert(f.Send("EndPractice"))
        eq(f.Current(),f.Live); eq(f.Live.Phase,"Waiting"); eq(f.Live.Choices[101],1)
        eq(f.Service.Owner,nil); eq(old.Phase,"Disabled"); eq(#f.Returns,1)
        eq(f.Live:start(100),false); f.Live:select(202,2); assert(f.Live:start(100))
    end)
    test("return-to-holding also ends and cleans practice",function()
        local f=fixture(); f.Send("Start"); f.Send("ReturnToHolding"); eq(f.Current(),f.Live); eq(#f.Returns,1)
    end)
    test("tester disconnect clears practice without loading disconnected player",function()
        local f=fixture(); f.Send("Start"); f.Service:remove(101); eq(f.Current(),f.Live); eq(f.Service.State,nil); eq(#f.Returns,0)
    end)
    test("disabled flag retracts a running session",function()
        local f=fixture(); f.Send("Start"); f.Config.StudioPracticeEnabled=false; f.Service:step()
        eq(f.Current(),f.Live); eq(f.Service.State,nil); eq(#f.Returns,1)
    end)
    test("stale tickets cannot match normal matches after practice",function()
        local f=fixture(); f.Send("Start"); local old=f.Current(); local t=old:die(101)
        f.Send("EndPractice"); f.Live:select(202,2); f.Live:start(1)
        eq(f.Live:respawn(101,t.Round,t.Token),false); assert(f.Live.Round>old.Round)
    end)
    test("practice action spam is rate limited",function()
        local f=fixture(); assert(f.Service:handle(101,"Start")); eq(f.Service:handle(101,"ResetObjectives"),false); eq(#f.Loads,1)
    end)
    test("unknown practice actions are rejected",function()
        local f=fixture(); eq(f.Send("setDamage"),false); eq(f.Send({}),false)
    end)

    -- Exercise the real preview/build boundary with lightweight geometry stubs.
    local function previewFixture()
        local objects={}
        local root={FindFirstChild=function(_,name)
            for _,obj in ipairs(objects) do if not obj.Dead and obj.Name==name then return obj end end
        end}
        local function model(name,marked)
            local obj={Name=name,Attrs={BrainRotGenerated=marked},GetAttribute=function(self,k) return self.Attrs[k] end,
                SetAttribute=function(self,k,v) self.Attrs[k]=v end,Destroy=function(self) self.Dead=true end}
            table.insert(objects,obj); return obj
        end
        local control={Studio=true,Running=false,Builds=0,Connections=0,LightingReads=0}
        local cfg={}; for k,v in pairs(Config) do cfg[k]=v end
        local tokens={Config={},Layout={},World={},Sculptures={}}
        local run={IsStudio=function() return control.Studio end,IsRunning=function() return control.Running end}
        local game={GetService=function(_,key)
            if key=="RunService" then return run end
            if key=="Lighting" then control.LightingReads=control.LightingReads+1 end
            return {Shared={Config=tokens.Config,Layout=tokens.Layout}}
        end}
        local world
        local env=setmetatable({game=game,workspace=root,script={Parent={BrainrotSculptures=tokens.Sculptures,World=tokens.World}},
            Color3={fromRGB=function() return {} end},Instance={new=function() return model("",nil) end},
            require=function(key) if key==tokens.Config then return cfg elseif key==tokens.World then return world else return {} end end,
        },{__index=_G})
        world=assert(loadfile("src/server/BattleServer/World.luau","t",env))()
        world.arena=function() control.Builds=control.Builds+1 end
        world.holding=function(self,onSelect,onExit) eq(onSelect,nil); eq(onExit,nil); self.RoundLabel={} end
        local preview=assert(loadfile("src/server/BattleServer/StudioPreview.luau","t",env))()
        return {Preview=preview,World=world,Root=root,Control=control,Config=cfg,Model=model}
    end
    test("editor preview uses the shared builder without lighting or gameplay",function()
        local f=previewFixture(); local model=f.Preview.build(); eq(f.Control.Builds,1)
        eq(model.Name,"BrainRotBattle_EditorPreview"); eq(model:GetAttribute("BrainRotGenerated"),true); eq(f.Control.LightingReads,0)
    end)
    test("repeated preview builds replace only the generated model",function()
        local f=previewFixture(); local unrelated=f.Model("MyHandbuiltScenery",false)
        local old=f.Preview.build(); local new=f.Preview.build(); eq(old.Dead,true); eq(new.Dead,nil); eq(unrelated.Dead,nil)
        f.Preview.remove(); eq(new.Dead,true); eq(unrelated.Dead,nil)
    end)
    test("preview refuses to overwrite an unmarked same-name model",function()
        local f=previewFixture(); local model=f.Model(f.Preview.Name,false)
        eq(pcall(f.Preview.build),false); eq(f.Preview.remove(),false); eq(model.Dead,nil)
    end)
    test("preview cannot build in live servers or while Play runs",function()
        local f=previewFixture(); f.Control.Studio=false; eq(pcall(f.Preview.build),false)
        f.Control.Studio=true; f.Control.Running=true; eq(pcall(f.Preview.build),false)
    end)
    test("the practice flag also disables editor preview generation",function()
        local f=previewFixture(); f.Config.StudioPracticeEnabled=false; eq(pcall(f.Preview.build),false)
    end)
end
