# Brain Rot Battles

Standalone Roblox PvP base defense: protect your team's Brainrot, destroy enemy objectives, and be the last surviving team in a forest arena. Based on the battle concept and procedural Brainrot sculptures from `mace-dot/Rizzler-Roblox` at commit `26a3f5dc84c4abfb0f417fcd49ef2e3321340795`.

This is multiplayer PvP with eight Brainrot teams, up to four players per team (32 players total). Each team shares one base and one 50-HP character objective. This repository is battle-only. It does not load the original game's dummy, tomb, merchant, economy, upgrades, single-player mode selector, or save data. The original Rizzler-Roblox repository is not modified.

## Play

1. Join directly into the physical holding space; there is no mode-selection popup.
2. Walk into one of eight colorful character portals, or activate its **Join team** prompt. This reserves one of four team seats for the next round. A fifth teammate is rejected. Switch teams before the round starts without losing your old seat if the new team is full.
3. At least two players on two different teams start a 20-second countdown. Teams may start with fewer than four members, but never exceed four. The round supports eight team bases. Late arrivals and eliminated players can reserve next-round team seats while the current round runs.
4. Spawn with **200 HP**, a **Bat**, and a **Sniper**. Your team's stationary Brainrot objective has **50 shared HP**. Four players spawn at separate positions in the same base.
5. Every teammate respawns at the shared base while the team Brainrot survives. If it is destroyed, your next death eliminates you. Losing the objective while already dead cancels your pending respawn. Living owners are not immediately killed.
6. The last surviving team wins, even if several teammates remain alive. Friendly fire and damage to your own team's Brainrot are disabled. Simultaneous final eliminations and a 10-minute timeout produce draws. Results and intermission lead to fresh selection/countdown.

Spawn shields last 3 seconds and prevent both outgoing and incoming damage. Unoccupied objectives are dormant. Selection only affects your protected character/base; it does not replace your Roblox avatar.

## Controls

| Action | Desktop | Touch | Controller |
| --- | --- | --- | --- |
| Join Brainrot team | Walk through portal or E prompt | Walk through portal or tap prompt | Walk through portal or prompt |
| Equip weapon | Roblox backpack / 1 or 2 | Backpack tool slot | Roblox backpack |
| Attack | Click, aiming at center crosshair | FIRE button | Right trigger |
| Scope sniper | Right click toggles | SCOPE button | Left trigger toggles |
| Reload sniper | R | RELOAD button | X |

The sniper has a 5-shot magazine, a 1.2-second fire interval, and a 2.8-second reload. Bat damage is 25 against players / 10 against objectives; sniper damage is 70 against players / 10 against objectives. These values are independent in `src/shared/Config.luau`.

## Build and run

Install Aftman and run:

```sh
aftman install
mkdir -p build
rojo build default.project.json --output build/BrainRotBattle.rbxlx
```

Open the generated place in **a new Roblox Studio place**. For live development, use `rojo serve` and connect the Rojo Studio plugin to that new place. Set **Max Players to 32** in the published place's settings. Do not sync into the existing Rizzler single-player place: unmanaged old Studio objects are not part of this clean project.

In Studio, use **Test → Start Server with 2 players**. Join different character teams in the two clients. Selecting the same team intentionally waits for an opposing team. Test eight players as two full teams, then all 32 seats in a published test server. Test touch emulation separately. A normal one-player Play test intentionally waits for an opponent.

Run the portable server rules/combat checks from the repository root:

```sh
lua5.4 tests/run.lua
# texlua tests/run.lua also works when TeX Live is installed.
```

GitHub Actions runs the tests and Rojo build and uploads a `BrainRotBattle-place` artifact. Roblox Studio and published-server tests still need to be performed; the Lua checks mock engine boundaries and do not prove physics, UI layout, replication, or device performance.

## Arena

The 900×900 arena has eight bases on a 330-stud radius, approximately 253 studs between adjacent bases. Each base has sheltered objective placement, a front spawn screen, and two flanking entrances. Eight equal trail/cover sectors connect to a central cornucopia-style clearing. The middle contains 96 trees, boulders, logs, stumps, bushes, ruined walls, and small stepped ridges. The repeated sectors keep routes and cover broadly balanced. Final sightlines, travel times, and mobile frame rate require Studio playtesting.

The holding room is physically isolated north of the arena. Always-on-top portal labels have dark backings, bright character colors, and visible reservation status. The central **BRAIN ROT BATTLES** sign is large and readable from the holding spawn. There is no active single-player portal unless an optional external destination is configured.

## Architecture

| File | Responsibility |
| --- | --- |
| `src/server/Main.server.luau` | Bootstrap, manual character lifecycle, round integration, snapshots, travel |
| `src/server/BattleServer/MatchState.luau` | Four-seat teams, locked rosters, shared objectives, respawn tokens, team outcomes |
| `src/server/BattleServer/Combat.luau` | Tool grants, server raycasts, damage validation, request limiting |
| `src/server/BattleServer/WeaponState.luau` | Server-owned ammo, attack/reload timers |
| `src/server/BattleServer/World.luau` | Holding space, eight selection portals, forest, bases and objective hitboxes |
| `src/server/BattleServer/BrainrotSculptures.luau` | Extracted original procedural character visuals |
| `src/shared/Config.luau` | PvP balance and destination configuration |
| `src/shared/Layout.luau` | Scalar map geometry and bounds |
| `src/client/Battle.client.luau` | HUD, touch/controller controls, aim/scope, visual feedback |

Clients request an attack direction/aim point, never accepted damage or a victim. The server derives ray origin and range, verifies equipped tools and round identity, validates combat membership/bounds, and enforces line of sight, ammo, cooldowns, ownership, and protection. Server-created objective hitboxes are queryable only while occupied and alive. Real Roblox Teams group teammates in the player list. Friendly-fire checks and shared objective health are enforced on the server. Decorative sculptures cannot intercept hits. Delayed respawns are guarded by round IDs, spawn tokens, and character generations.

The original `BrainrotSculptures.luau` is preserved byte-for-byte (Git blob `8e78c1f3377d3f869e617d1b0cd84e16ba6956d7`): the same eight names, procedural shapes, colors, and features are used for portal previews and objectives.

There is no persistence in this initial version. `DataStoreName` reserves a separate PvP namespace for future work; original progression keys are never read or written.

## Publishing and optional travel

See [docs/PUBLISHING.md](docs/PUBLISHING.md) for Studio publishing, destination IDs, and integration with an external lobby. Pushing to GitHub does not publish the Roblox game. No working PlaceIds have been invented.

See [docs/TESTING.md](docs/TESTING.md) for automated coverage and the manual multiplayer checklist.
