# Brain Rot Battles

Standalone Roblox PvP base defense: protect your team's Brainrot, destroy enemy objectives, and be the last surviving team in a forest arena. Based on the battle concept and procedural Brainrot sculptures from `mace-dot/Rizzler-Roblox` at commit `26a3f5dc84c4abfb0f417fcd49ef2e3321340795`.

This is multiplayer PvP with eight Brainrot teams, up to four players per team (32 players total). Each team shares one base and one 50-HP character objective. This repository is battle-only. It does not load the original game's dummy, tomb, merchant, economy, upgrades, single-player mode selector, or save data. The original Rizzler-Roblox repository is not modified.

## Play

1. Join directly into the physical holding space; there is no mode-selection popup.
2. Walk into one of eight colorful character portals, or activate its **Join team** prompt. This reserves one of four team seats for the next round. A fifth teammate is rejected. Switch teams before the round starts without losing your old seat if the new team is full.
3. At least two players on two different teams start a 20-second countdown. Teams may start with fewer than four members, but never exceed four. The round supports eight team bases. Late arrivals and eliminated players can reserve next-round team seats while the current round runs.
4. Spawn with **200 HP**, a **Bat**, **Sniper**, **Handgun**, **Crossbow**, and **Sword**. Your team's stationary Brainrot objective has **50 shared HP**. Four players spawn at separate positions in the same base.
5. Every teammate respawns at the shared base while the team Brainrot survives. If it is destroyed, your next death eliminates you. Losing the objective while already dead cancels your pending respawn. Living owners are not immediately killed.
6. The last surviving team wins, even if several teammates remain alive. Friendly fire and damage to your own team's Brainrot are disabled. Simultaneous final eliminations and a 10-minute timeout produce draws. Results and intermission lead to fresh selection/countdown.

Spawn shields last 3 seconds and prevent both outgoing and incoming damage. Unoccupied objectives are dormant. Selection only affects your protected character/base; it does not replace your Roblox avatar.

## Controls

| Action | Desktop | Touch | Controller |
| --- | --- | --- | --- |
| Join Brainrot team | Walk through portal or E prompt | Walk through portal or tap prompt | Walk through portal or prompt |
| Equip weapon | Roblox backpack / 1–5 | Backpack tool slot | Roblox backpack |
| Attack | Click, aiming at center crosshair | FIRE button | Right trigger |
| Scope sniper | Right click toggles | SCOPE button | Left trigger toggles |
| Reload equipped ranged weapon | R | RELOAD button | X |
| Sprint | Hold Left Shift | SPRINT toggle | Left stick click toggle |
| Crouch | C toggle | CROUCH toggle | B toggle |
| Prone | X toggle | PRONE toggle | D-pad down toggle |

All balance values live in `src/shared/Config.luau`:

| Weapon | Player damage | Objective damage | Loaded + reserve | Fire interval | Reload |
| --- | ---: | ---: | --- | --- | --- |
| Bat | 25 | 10 | Melee | 0.65s | — |
| Sniper | 50 | 10 | 6 + 12 | 1.2s | 2.5s |
| Handgun | 20 | 10 | 16 + 32 | 0.25s | 1.5s |
| Crossbow | 65 | 10 | 1 + 8 | 1s | 1.8s |
| Sword | 35 | 10 | Melee | 0.7s | — |

Reloads transfer reserve ammunition; switching, death and leaving the arena cancel unfinished reloads. Switching never refills a weapon. A new life resets the loadout. Crossbow bolts travel at 180 studs/second with 28 studs/second² drop, swept collision, a 420-stud range and four-second lifetime. Melee makes one immediate, bounded contact sample per swing, with no lingering damage volume; bat reach is 8 studs and sword reach is 7. Every ray stops at the first solid surface, including intact glass. Models and grip/swing/recoil/reload motions are procedural; no new sound asset IDs have been invented.

Sprint speed is 30 (normal 20), crouch 12, prone 6. Five seconds of active sprint empties stamina; full recovery takes twenty seconds. Exhaustion requires 20% recovery before restarting. Stationary players do not drain stamina. Firing/reloading ends sprint. Crouch and prone change visible joints, actual body posture and collision, with server-selected state replicated to clients. Both Motor6D and AnimationConstraint rigs use the same pose evaluator. Low stances disable jumping/climbing; falling stops sprint and retains a low stance until a grounded, clear transition is requested. Standing checks overhead clearance. Death and match exit restore normal movement. The server sets speed and limits sustained excessive ground travel while allowing short network/knockback bursts. Avatar scales, stairs, slopes and replication still require Studio acceptance.

## Build and run

Install Aftman and run:

```sh
aftman install
mkdir -p build
rojo build default.project.json --output build/BrainRotBattle.rbxlx
```

Open the generated place in **a new Roblox Studio place**. For live development, use `rojo serve` and connect the Rojo Studio plugin to that new place. Set **Max Players to 32** in the published place's settings. Do not sync into the existing Rizzler single-player place: unmanaged old Studio objects are not part of this clean project.

In Studio, use **Test → Start Server with 2 players**. Join different character teams in the two clients. Selecting the same team intentionally waits for an opposing team. Test eight players as two full teams, then all 32 seats in a published test server. Test touch emulation separately. A normal one-player multiplayer session waits for an opponent; use the optional solo practice tools below to test alone.

Run the portable server rules/combat checks from the repository root:

```sh
lua5.4 tests/run.lua
# texlua tests/run.lua also works when TeX Live is installed.
```

GitHub Actions runs the tests and Rojo build and uploads a `BrainRotBattle-place` artifact. Roblox Studio and published-server tests still need to be performed; the Lua checks mock engine boundaries and do not prove physics, UI layout, replication, or device performance.

## Solo Studio testing (optional and retractable)

1. Sync/build the current project into a fresh Roblox Studio place, then press **Play**. One local player is enough for practice.
2. Walk into a Brainrot team portal to select your starting base.
3. Expand **STUDIO TEST TOOLS** and click **Start Solo Practice**.
4. You enter the real forest arena with 200 HP and all five weapons. Wait for the 3-second spawn shield before firing. The seven enemy Brainrots have 50 HP and use normal server hit detection.
5. Use **Reset Objectives + Recover Player**, **Respawn at My Base**, or the base chooser followed by **Switch to Chosen Base** to repeat tests.
6. Use **Destroy My Brainrot** and then reset/die to test final-life elimination. **Reset Objectives** recovers you after elimination.
7. **End Practice** or **Return to Holding** restores normal multiplayer selection. Practice has no automatic victory or timeout.

Only one tester owns the practice session. Other Studio clients cannot control it. An active normal match blocks practice startup. Two-player testing remains available as before: end practice, select opposing portals in two local clients, and wait for the normal countdown.

Practice starts inside the ground floor of the team selected at a portal. Each team slot has its own explicit engine spawn point and pad; final character positioning and death handling are configured after `LoadCharacterAsync` completes, with velocity cleared. Reset, respawn and switch-base actions use the same placement path.

**Disable everything:** set `StudioPracticeEnabled = false` in `src/shared/Config.luau`, sync, and restart Play. No practice remote or panel is created. The server always also requires `RunService:IsStudio()`, so published gameplay cannot enter practice even with the flag enabled.

Practice rules live in `PracticeState.luau` and `StudioPractice.luau`; production `MatchState.luau`, combat rules, health values and team capacity are unchanged. The optional panel is a separate LocalScript. The feature is delivered in one dedicated **Studio-only practice** Git commit; use `git log --oneline --grep='Studio-only practice'` to identify it and `git revert <commit-sha>` to remove it cleanly. Later overlapping edits can require resolving normal Git conflicts.

The revised implementation prompt, including the reversibility requirement, is in [docs/STUDIO_PRACTICE_PROMPT.md](docs/STUDIO_PRACTICE_PROMPT.md).

### Map preview before pressing Play

With Rojo synced and Studio stopped, open the **Command Bar** and run:

```lua
require(game.ServerScriptService.BattleServer.StudioPreview).build()
```

Select `Workspace.BrainRotBattle_EditorPreview` in Explorer and press **F** to frame the full map. This uses the live geometry builder, detailed sculptures and portal labels, with no player sessions or interactive event connections. Rebuilding replaces only its marked generated container; unrelated objects and editor lighting are preserved.

Remove the preview with:

```lua
require(game.ServerScriptService.BattleServer.StudioPreview).remove()
```

The runtime removes an owned edit preview before building the actual world. The single practice flag also gates preview generation. Editor preview is for map inspection; press Play for weapons and respawns. If you edit builder code after requiring it in the Command Bar, reopen the place to refresh Studio's module cache before rebuilding.

## Arena

The 1300×1300 arena has eight bases on a 568-stud radius, approximately 435 studs between adjacent bases. Every fort has a basement at Y=-12, a ground floor at Y=0, and a second floor at Y=16. Separate stairs connect the floors. The matching Brainrot and its objective hitbox sit on a pedestal upstairs; players spawn on the ground floor. Cardinal foundations fit exact openings in the arena ground so the basements are genuinely accessible. Front and side doors provide multiple approaches. Four ground-floor pads occupy the usable interior corners (local X=±12, Z=±22). The actual spawn/respawn transforms face inward. Occupied pads try nearby positions in the same quadrant; fully occupied quadrants wait safely. All paths share the base transform and turn to meet each front door squarely.

Eight trail/cover sectors lead to a central creator monument and a ring of tribute platforms. The monument loads **CoolAwesomeness07**, user ID **133655557**, through Roblox's avatar API, anchors and sanitizes the model, and scales it up to 64 studs tall (bounded to a 54-stud footprint for circulation). A loading/unavailable `AvatarStatus` attribute identifies an empty pedestal if Roblox cannot supply the avatar. Rebuilding/restarting retries; preview and runtime use the same builder.

Continuous 82-stud stone walls surround the island, with overlapping collision cores and repeated buttresses/facing stones. Bases maintain at least 40 studs of rear clearance. Staggered standing-height rocks, crouch cover and low fallen logs avoid paths, foundations, landmarks and vine approaches. Ruins, camps, ferns, mushrooms and marsh details remain. Cover is scenery, not loot.

Upstairs objectives sit inside sealed inner rooms with intact bullet-blocking glass and full-height walls/roof. A six-stud entrance and offset baffle force attackers to turn before reaching the objective. The outer balcony retains open firing space above solid 3.5-stud parapets. All eight bases use identical protection and stair geometry.

Two wooden lookout towers have 16-stud-high decks, climbable ladders and 3.25-stud parapets. Two low metal field bunkers replace the other towers, with sheltered ground floors, rear ramps and protected upper firing decks. The holding platform remains separate, north of the enlarged island at Z=-850.

All trees use tapered, irregular trunks, connected solid branches and smaller layered wedge foliage, with broadleaf and conifer silhouettes. Approximately one in five trees in **each sector** has thick leafy vines, standable branching perches at 8, 16 and 24 studs, and a seat. The frequency is configurable with `ClimbableTreeEvery`; there are no CLIMB labels. Walk into the vine and move forward, then step sideways onto a branch. Trunks, substantial branches and climbing supports block shots; light foliage is non-colliding and non-queryable. Trees avoid paths, base excavations, camps, towers and perimeter access. Complete trees stream atomically; forts remain persistent. The planner is capped at 280 trees, and no static scenery uses frame loops. World attributes `TreeCount` and `VineTreeCount` expose the built counts.

Base statues show compact overhead health bars without names. Bars track the team objective's health, change from green to yellow/red, and hide on unoccupied bases. Base interiors include team-colored lockers, map tables, basement bedrolls, banners and lit objective surrounds. Four small pads mark the individual spawn positions. Players still respawn while their team's Brainrot survives.

The holding platform is physically isolated north of the arena and enclosed by invisible collision walls. Square portals face straight inward in two rows. Character/reservation signs use world-space dimensions with a 22-pixel text ceiling, shrinking with distance instead of dominating the screen when zoomed out. A short-range native join prompt avoids duplicating the character title. The central **BRAIN ROT BATTLES** sign and on-screen team HUD retain their existing sizing. There is no active single-player portal unless an optional external destination is configured.

## Architecture

| File | Responsibility |
| --- | --- |
| `src/server/Main.server.luau` | Bootstrap, manual character lifecycle, round integration, snapshots, travel |
| `src/server/BattleServer/MatchState.luau` | Four-seat teams, locked rosters, shared objectives, respawn tokens, team outcomes |
| `src/server/BattleServer/Combat.luau` | Tool grants, server raycasts, damage validation, request limiting |
| `src/server/BattleServer/WeaponState.luau` | Server-owned ammo, attack/reload timers |
| `src/server/BattleServer/World.luau` | Holding space, eight selection portals, forest, bases and objective hitboxes |
| `src/server/BattleServer/ArenaArchitecture.luau` | Excavated ground, three-floor forts, stairs, upstairs objectives |
| `src/server/BattleServer/ArenaDetails.luau` | Central clearing and repeated forest/camp dressing |
| `src/server/BattleServer/HighGround.luau` | Two small lookouts and two metal field bunkers |
| `src/server/BattleServer/ForestTrees.luau` | Varied tree geometry, visible vines, perches and seats |
| `src/shared/ForestLayout.luau` | Deterministic forest layout and configurable per-sector climb distribution |
| `src/server/BattleServer/BrainrotSculptures.luau` | Detailed procedural character visuals shared by portals and bases |
| `src/shared/CoverLayout.luau` | Cover placement and route/climb exclusions |
| `src/shared/Posture.luau` | Shared R6/R15 joint pose evaluation |
| `src/server/BattleServer/MovementState.luau` | Stamina, stance and movement rules |
| `src/server/BattleServer/MovementRig.luau` | Avatar posture, collision and clearance |
| `src/server/BattleServer/MovementService.luau` | Server movement validation and lifecycle |
| `src/server/BattleServer/SpawnPlacement.luau` | Occupancy-aware interior spawn selection |
| `src/server/BattleServer/ProjectileState.luau` | Swept server bolt simulation |
| `src/server/BattleServer/WeaponModels.luau` | Five distinct procedural tools |
| `src/server/BattleServer/ArenaLandscape.luau` | Stone perimeter, paths and cover |
| `src/server/BattleServer/CreatorStatue.luau` | Shared preview/runtime avatar landmark |
| `src/shared/Config.luau` | PvP balance and destination configuration |
| `src/shared/Layout.luau` | Scalar map geometry and bounds |
| `src/client/Battle.client.luau` | HUD, touch/controller controls, aim/scope, visual feedback |

Clients request an attack direction/aim point, never accepted damage or a victim. The server derives ray origin and range, verifies equipped tools and round identity, validates combat membership/bounds, and enforces line of sight, ammo, cooldowns, ownership, and protection. Server-created objective hitboxes are queryable only while occupied and alive. Real Roblox Teams group teammates in the player list. Friendly-fire checks and shared objective health are enforced on the server. Decorative sculptures cannot intercept hits. Delayed respawns are guarded by round IDs, spawn tokens, and character generations.

The sculptures derive from the original `BrainrotSculptures.luau` (Git blob `8e78c1f3377d3f869e617d1b0cd84e16ba6956d7`) with additional bark, facial features, shark gills/sneaker laces, aircraft engines/teeth, cactus spines, banana peel, cup/tutu detail, shrimp shell bands, and leafy roots/toes. Both portals and objectives use the same builders. The original eight Brainrot sculptures remain procedural and unchanged in this update. Only the creator monument loads Roblox avatar assets.

There is no persistence in this initial version. `DataStoreName` reserves a separate PvP namespace for future work; original progression keys are never read or written.

## Publishing and optional travel

See [docs/PUBLISHING.md](docs/PUBLISHING.md) for Studio publishing, destination IDs, and integration with an external lobby. Pushing to GitHub does not publish the Roblox game. No working PlaceIds have been invented.

See [docs/TESTING.md](docs/TESTING.md) for automated coverage and the manual multiplayer checklist.
