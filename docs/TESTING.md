# Validation

## Automated checks

`tests/run.lua` runs the production pure rule/configuration modules and the production combat request handler with a small Roblox boundary mock. It also compiles every game script using the shared Lua/Luau syntax subset.

Coverage includes four-seat team limits and atomic changes; all 32 seats; two-opposing-team admission; friendly-fire prevention; teammate disconnect handling; shared objective health and cancellation of all pending teammate respawns; last-team victory; capacity; countdown cancellation; exact base assignment; active/next-round roster separation; disconnects; 50-HP objectives; own-objective protection; 200-HP configuration; tokenized respawn; objective loss during a respawn delay; elimination; winners, simultaneous draws and timeouts; clean consecutive rounds; magazine resets; reload and cross-weapon cooldowns; arena spacing/bounds; server-origin shots; cover occlusion; shield protection; malformed requests; displaced heads; stale tools; objective-specific damage; one target per bat swing; request burst limits.

Lua mocks establish the server's decision logic. They do not establish that Roblox engine behavior, streaming, camera controls, generated geometry or replication work visually in Studio.

The `Validate battle game` workflow also runs a real Rojo build and uploads the resulting place file. A Rojo build checks serialization/project structure; it does not execute the game in Roblox Studio.

## Required Studio/published-client checks

- Start Server with 2–8 clients, then test 32 players on a published server with Max Players set to 32. Everyone joins the holding room with no mode popup or input/camera lock.
- Check all eight character models and portal labels from the default spawn on desktop and touch emulation.
- Walk through each portal and activate its prompt. Confirm each selected team/base matches its original Brainrot character. Join four players to one team and reject a fifth. Try simultaneous joins into the fourth seat; verify a rejected change retains the old selection.
- Leave during countdown; it must cancel if fewer than two opposing teams remain, even if four teammates are selected. Join mid-round; only a next-round reservation is available.
- At round start, verify each admitted player has 200/200 HP and exactly one bat and sniper. Verify each occupied Brainrot has 50/50 HP.
- Verify 3-second spawn protection in both directions. Confirm the new avatar does not get killed by arena bounds while loading.
- Fire through trees, boulders and base walls. Shots must stop at cover. Hit enemy objectives with both weapons, and confirm your own cannot be damaged.
- Die with an intact objective: respawn at the same base with health and loadout reset. Destroy the objective during the respawn delay: the pending respawn must become a holding-room body.
- Destroy a living opponent's objective: they stay alive. Their next death eliminates them and they cannot fire or return to the arena.
- Test sniper reload, tool switching, scope toggling, default backpack controls, touch FIRE/RELOAD/SCOPE, and controller controls. Check camera restoration on unequip, death and round end.
- Test two players losing their final lives together. Verify an explicit draw. Test timeout with multiple survivors.
- Disconnect one teammate and confirm their shared objective survives. Disconnect the entire team and confirm its objective is disabled. Confirm same-team bat/sniper hits do no damage. The match must continue if two teams remain, even if one player is eliminated. Check team winners and results. The last surviving team must win with one, two, three or four surviving teammates. Play several consecutive rounds and check no duplicate tools, old timers, or stale damage.
- Check the UI at small phone sizes and all base routes for sniping exposure. Measure mobile performance in the generated forest with streaming enabled.
- If configured, test travel in real published clients and verify visible feedback on failed teleports.

No Studio or real-client result should be marked passed until it is actually run.

Character extraction check: `git hash-object src/server/BattleServer/BrainrotSculptures.luau` must return `8e78c1f3377d3f869e617d1b0cd84e16ba6956d7`, matching the original repository.
