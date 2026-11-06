return function(test,eq,Config)
    local v={}; v.__index=function(a,k)
        if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
        if k=="Unit" then return a/a.Magnitude end
    end
    local function vec(x,y,z) return setmetatable({X=x,Y=y,Z=z},v) end
    v.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
    v.__mul=function(a,b) return vec(a.X*b,a.Y*b,a.Z*b) end
    v.__div=function(a,b) return vec(a.X/b,a.Y/b,a.Z/b) end
    local env=setmetatable({Vector3={new=vec}},{__index=_G})
    local P=assert(loadfile("src/server/BattleServer/ProjectileState.luau","t",env))()
    local function bolt() return {Def=Config.Weapons.Crossbow,Age=0,Distance=0,Position=vec(0,10,0),Velocity=vec(180,0,0)} end
    test("crossbow sweeps thin glass even during a long server frame",function()
        local b=bolt(); local contacts=0
        local done,hit=P.advance(b,0.5,function(origin,delta)
            if origin.X<=12 and origin.X+delta.X>=12 then contacts=contacts+1; return {Position=vec(12,10,0),Instance="glass"} end
        end)
        eq(done,true); eq(hit.Instance,"glass"); eq(contacts,1); eq(b.Position.X,12)
    end)
    test("crossbow gravity changes its trajectory and lifetime is bounded",function()
        local b=bolt(); eq(P.advance(b,0.5,function() end),false)
        assert(b.Position.Y<10); assert(b.Velocity.Y<0)
        assert(P.advance(b,10,function() end)); assert(b.Distance<=Config.Weapons.Crossbow.Range+0.001)
    end)
end
