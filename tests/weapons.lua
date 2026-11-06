return function(test,eq,Config,Weapons)
    test("five spawn weapons and separate player/objective balance",function()
        eq(#Config.Loadout,5); eq(Config.Weapons.Sniper.PlayerDamage,50)
        for _,name in ipairs(Config.Loadout) do eq(Config.Weapons[name].ObjectiveDamage,10) end
    end)
    for _,name in ipairs({"Handgun","Sniper","Crossbow"}) do
        local def=Config.Weapons[name]
        test(name.." exact starting magazine and reserve",function()
            local w=Weapons.new(Config); w:reset(1)
            local s=w:get(1,0,name); eq(s.Ammo,def.Magazine); eq(s.Reserve,def.Reserve)
            eq(s.Ammo+s.Reserve,name=="Handgun" and 48 or name=="Sniper" and 18 or 9)
        end)
        test(name.." partial reload conserves bullets and respects completion",function()
            local w=Weapons.new(Config); w:reset(1); assert(w:attack(1,name,0)); assert(w:reload(1,1,name))
            eq(w:reload(1,1.1,name),false); eq(w:attack(1,name,1.2),false)
            local s=w:get(1,1+def.Reload-0.01,name); eq(s.Ammo,def.Magazine-1); eq(s.Reserve,def.Reserve)
            s=w:get(1,1+def.Reload,name); eq(s.Ammo,def.Magazine); eq(s.Reserve,def.Reserve-1)
        end)
        test(name.." exhausts reserves without creating ammunition",function()
            local w=Weapons.new(Config); w:reset(1)
            local shots,t=0,0
            while shots<def.Magazine+def.Reserve do
                if w:get(1,t,name).Ammo==0 then assert(w:reload(1,t,name)); t=t+def.Reload end
                assert(w:attack(1,name,t)); shots=shots+1; t=t+def.Cooldown+0.01
            end
            eq(w:attack(1,name,t),false); eq(w:reload(1,t,name),false)
            eq(w:get(1,t,name).Ammo,0); eq(w:get(1,t,name).Reserve,0)
        end)
    end
    test("switch cancels reload without refilling or duplicating ammo",function()
        local w=Weapons.new(Config); w:reset(1); w:attack(1,"Sniper",0); w:reload(1,1,"Sniper")
        w:equip(1,"Bat"); w:equip(1,"Sniper")
        eq(w:get(1,10,"Sniper").Ammo,5); eq(w:get(1,10,"Sniper").Reserve,12)
    end)
    test("death or match-exit cancellation never completes a reload",function()
        local w=Weapons.new(Config); w:reset(1); w:attack(1,"Handgun",0); w:reload(1,1,"Handgun"); w:cancel(1)
        eq(w:get(1,100,"Handgun").Ammo,15); eq(w:get(1,100,"Handgun").Reserve,32)
        w:remove(1); eq(w:attack(1,"Handgun",101),false)
        w:reset(1); eq(w:get(1,102,"Handgun").Ammo,16)
    end)
    test("shared cooldown prevents switching to bypass cadence",function()
        local w=Weapons.new(Config); w:reset(1); assert(w:attack(1,"Sniper",0)); eq(w:attack(1,"Handgun",0.1),false)
        assert(w:attack(1,"Handgun",1.2)); eq(w:get(1,1.2,"Sniper").Ammo,5)
    end)
    test("reload transfers only the last available reserve",function()
        local w=Weapons.new(Config); w:reset(1); local s=w:get(1,0,"Handgun")
        s.Ammo=3; s.Reserve=2; assert(w:reload(1,1,"Handgun")); s=w:get(1,3,"Handgun")
        eq(s.Ammo,5); eq(s.Reserve,0)
    end)
end
