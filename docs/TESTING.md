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
- At round start, verify each admitted player has 200/200 HP and exactly one of each of the five weapons. Verify each occupied Brainrot has 50/50 HP.
- Verify 3-second spawn protection in both directions. Confirm the new avatar does not get killed by arena bounds while loading.
- Fire through trees, boulders and base walls. Shots must stop at cover. Hit enemy objectives with all weapons, and confirm your own cannot be damaged.
- Die with an intact objective: respawn at the same base with health and loadout reset. Destroy the objective during the respawn delay: the pending respawn must become a holding-room body.
- Destroy a living opponent's objective: they stay alive. Their next death eliminates them and they cannot fire or return to the arena.
- Test sniper reload, tool switching, scope toggling, default backpack controls, touch FIRE/RELOAD/SCOPE, and controller controls. Check camera restoration on unequip, death and round end.
- Test two players losing their final lives together. Verify an explicit draw. Test timeout with multiple survivors.
- Disconnect one teammate and confirm their shared objective survives. Disconnect the entire team and confirm its objective is disabled. Confirm same-team weapon hits do no damage. The match must continue if two teams remain, even if one player is eliminated. Check team winners and results. The last surviving team must win with one, two, three or four surviving teammates. Play several consecutive rounds and check no duplicate tools, old timers, or stale damage.
- Check the UI at small phone sizes and all base routes for sniping exposure. Measure mobile performance in the generated forest with streaming enabled.
- If configured, test travel in real published clients and verify visible feedback on failed teleports.

No Studio or real-client result should be marked passed until it is actually run.

Character preservation: this update does not change `BrainrotSculptures.luau`; compare its Git diff with the preceding version rather than the historical extraction hash.

## Studio practice acceptance

The portable suite also exercises the actual practice controller/state and the geometry preview boundary. It does not run Roblox rendering or simulate client input.

- With one Studio client: choose a portal, start solo practice, confirm spawn/200 HP/all five weapons and seven 50-HP targets. Check real cover occlusion.
- Die with an intact objective, then test Destroy My Brainrot before and during a respawn delay. Use Reset Objectives after elimination; recover with one copy of each weapon.
- Switch to each base and check the original character appearances. Reset during respawn/loading; no old callback may teleport or equip you later.
- End or return to holding, then start a normal two-team local match. Normal victory/respawn rules must apply.
- Start practice with another Studio client watching: only the owning tester may control it. Disconnect the owner and verify normal admission returns.
- Set the flag false and restart Play: no panel or practice remote. On a published server, practice must remain unavailable even with the flag true.
- While Studio is stopped, run the documented preview build twice, frame the map, and remove it. Verify no duplicate geometry or interactive prompts and no changes to unrelated objects/lighting. Press Play with a generated preview present; only one gameplay world should remain.

The portable tests exercise rules and mocked engine boundaries. A successful Rojo build packages the place but does not prove engine behavior. Complete this manual checklist before claiming engine verification.
# Three-floor arena and selection-area checks

- Start solo practice from each chosen portal: spawn inside that base's ground floor, with 200 HP. Repeat Reset Objectives, Respawn and Switch Base, including quick repeated actions during character loading; check that there is no sky spawn or immediate bounds death.
- Traverse the enlarged island to the outer bases; no old boundary wall should cut through the map. The holding platform must remain outside the combat area.
- Check the two lookouts and two low metal bunkers. Climb the ladders and rear bunker ramps; verify the raised walls provide cover while allowing shots over the top.
- Locate vine trees in every sector by their visible leafy stems; there must be no CLIMB signs. Approximately one in five trees per sector should have vines. Climb and step onto the 8-, 16- and 24-stud branches, sit and descend; test touch/controller input and streamed access.
- Check that all tree types use the new trunks/branching foliage; inspect mobile frame rate with the denser silhouettes.

- Restart Play after syncing the updated source. Check the eight character signs at normal camera distance and while zooming out: they should recede with the portals, with no oversized reservation panel. The existing team HUD should be unchanged.
- Check the straight portal rows and each detailed character. Walk-in selection and the nearby E/touch/controller prompt should still reserve a seat.
- Jump against all four holding-platform edges and corners, including from a portal frame: the invisible border should keep the avatar on the platform.
- In solo practice, use each base in turn. From the ground floor, take the left staircase to the basement and the right staircase to the second floor; check headroom and both landings in each direction.
- Check the corresponding character and health bar upstairs, with no title. Damage it and check bar fill/color; check an empty bar on destruction and no bar on dormant objectives. Test friendly-fire protection and respawning at all four smaller ground-floor pads.
- Walk around the lockers, map table and bedrolls; stairs, spawn positions and access to the upstairs objective must remain clear.
- Inspect the central creator monument, ruins, camps and forest cover. Check frame rate on a mobile device; decorative foliage should not block movement or weapon rays.


## Fortress, loadout and movement update acceptance

Automated checks now include: all four usable-corner pads; rotated/transformed positions and squared doorway paths; excavation area and stair headroom; occupied-pad fallback/wait; rear wall clearance; per-sector vine frequency; cover/path/climb exclusions; sampled exterior rays against every objective-hitbox corner and the actual enclosure boxes; intact queryable glass; exactly 50 sniper damage; all five objective-damage values; initial/partial/exhausted ammo, cancellation and swaps; sword reach and cover; first-contact bolt sweeps across thin glass under a long frame, gravity and range/lifetime; sprint/recharge/exhaustion/stance rules; production request, shield and team protections; and existing practice/preview admission rules.

The GitHub workflow's previously failing spawn-spacing assertion is preserved: it requires at least ten studs between spawn slots. The old six-stud spacing violated it. Corner spawns now satisfy the original assertion. Obsolete five-bullet/infinite-reload expectations were replaced with finite-ammunition tests. A local passing suite is not a claim that a new GitHub run has already completed.

Run the following in Roblox Studio; these checks have **not** been performed by the coding agent:

- Start eight clients on two teams. Confirm four distinct corner pads per base, inward facing, no simultaneous body collisions. Occupy a pad before a respawn and verify safe fallback. Fill its nearby candidates and verify it waits without moving upstairs or outside.
- Reset and respawn in each of the eight bases. Switch/reset practice while a character is loading. Confirm queued loads cannot leave a stale avatar, duplicate loadout, sky spawn or deadlocked controls.
- Walk both staircases, basement landings, every square doorway path, balcony and dogleg objective entrance. Inspect the enlarged roof and clearance around the matching statue. Enter the objective room and damage the enemy objective normally.
- From all exterior sides and elevated trees/towers, fire every ranged weapon toward the objective, including through the glass and entrance. Glass stays intact and stops bullets/bolts. Check roof/floor protection too. Shoot approaching enemies from the balcony above its parapets.
- Walk all perimeter seams and corners. Try roofs, rocks, vines and towers as routes over the wall. The wall must stop escape; server bounds remain a backup.
- Find vines in every sector without labels. Stand/jump on every branch tier, enter/leave seats, and check that the visible branches match their solid surfaces. Verify light foliage conceals without stopping bullets or snagging players/cameras.
- Use standing, crouching and prone cover. Confirm actual body/head height and hit detection from another client, including R6, R15, upgraded joints and different avatar scales. Walk stairs/slopes in each posture; rotate prone next to walls; test transitions under low ceilings, jumping, climbing and falling. No wall/floor clipping or standing into ceilings is acceptable.
- Check sniper damage: four unprotected hits remove 200 HP; objective damage remains ten. Check all five weapons against enemies, teammates and protected players. Try camera peeking around walls while the muzzle is blocked.
- Start with handgun 16+32, sniper 6+12 and crossbow 1+8. Partial reload, exhaust all ammo, switch midway, die during reload and end practice/round during reload. No extra bullets or reload completions after cancellation. New lives reset the loadout.
- Fire bolts across thin glass and moving targets with network emulation. Each bolt stops once, drops visibly, and disappears on impact, death/round exit, range or timeout. Test sword reach through floors, walls and glass; a swing cannot repeat damage.
- Sprint while moving for five seconds; fully recharge over twenty. Stationary sprint must not drain. After exhaustion, restarting needs 20%. Fire/reload to stop sprint. Crouch/prone must prevent sprint.
- Test all desktop, touch and controller bindings, hotbar slots, scope and lower camera posture. Check narrow phone and landscape layouts, joystick/jump clearance, ammo/reload text and stamina. Practice controls collapse when practice starts and can be reopened deliberately.
- Confirm CoolAwesomeness07's actual avatar appears in runtime and stopped-editor preview. Check `CreatorMonument.AvatarStatus` if Roblox cannot fetch it. Confirm the statue is static/decorative, with no additional objective, and center routes remain open.
- Measure forest streaming, client frame rate, server simulation, projectile cleanup and multiplayer posture replication under load. Play complete selection/countdown/round/victory/reset cycles, including objective destruction and final-life elimination.

No uploaded weapon animation or sound assets are required. Weapon motions and low-posture walk/crawl motion are procedural. The avatar monument is the sole new Roblox asset fetch. Final visual quality and physical traversal require these in-engine checks.
