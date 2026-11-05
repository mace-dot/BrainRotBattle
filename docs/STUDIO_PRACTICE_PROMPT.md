# Studio-only practice implementation prompt

Implement an easily retractable Roblox Studio testing workflow in `mace-dot/BrainRotBattle` so one developer can enter the gameplay map and test combat without waiting for other players.

## Isolation and reversibility — required

Keep practice functionality isolated behind one `Config.StudioPracticeEnabled` flag. The server must also require `RunService:IsStudio()` for every practice request. Put the changes in a separate, dedicated Git commit so they can be reverted cleanly. Disabling practice must restore normal multiplayer behavior without further edits.

Keep the published game as multiplayer PvP: eight Brainrot teams, up to four players per team (32 players maximum), 200-HP players, and one shared 50-HP Brainrot objective per team. Preserve the original Brainrot names, models, colors and appearances. Leave the production `MatchState` rules unchanged; use a separate practice state/controller with a small integration boundary.

## Inspect before changing

Read repository instructions and the latest code, including `Main.server.luau`, `MatchState.luau`, `World.luau`, `Combat.luau`, `WeaponState.luau`, `BrainrotSculptures.luau`, `Battle.client.luau`, `Config.luau`, `Layout.luau`, and the existing tests.

The current solo test problem is not just the minimum player count. Normal admission requires two players on opposing teams, a single team immediately satisfies the normal victory condition, the world is built at runtime, and teleporting an unadmitted tester into the arena conflicts with combat and bounds validation. Fix the entire flow.

## Studio test panel

Add a compact, collapsible Studio-only panel separate from the normal HUD. Include:

- Start Solo Practice.
- Reset Objectives and recover an eliminated tester.
- Respawn at My Base.
- Choose and switch the practice base.
- Destroy My Brainrot for final-life testing.
- Return to Holding.
- End Practice.

Show `STUDIO PRACTICE — NOT A LIVE MATCH` during practice. Support small screens with scrolling if necessary. Do not restore the removed startup mode-selection popup or introduce camera/input locks.

## Solo session

The workflow must be: press Play, join a Brainrot through an existing holding-area portal, click Start Solo Practice, and spawn at that actual base. If no team is selected, ask the tester to choose one. Starting requires the tester to be in the holding area.

Use the real forest map, real spawn locations, original Brainrot sculptures, 200 player HP, the bat and sniper, and the existing ammo/reload/cooldown/spawn-shield rules. Register the tester in server-owned practice state so ordinary combat validation and the arena watchdog still apply.

Create seven explicit enemy training objectives with 50 HP each. Do not invent Player instances, fake user identities or normal roster entries to satisfy multiplayer admission. Enemy objectives do not require AI in this version. Use the production raycast and objective damage path; do not accept client damage or implement a separate permissive practice weapon system.

Allow shooting and hitting enemy objectives, inspecting damage feedback, destroying objectives, verifying that cover blocks shots, and confirming that the tester cannot damage their own objective with weapons.

## Lifecycle

Practice has no automatic solo victory and no round timeout. Ordinary death/respawn works while the tester's Brainrot survives. Destroy My Brainrot is an explicit server-owned developer action that disables subsequent respawns and allows testing elimination; it must also invalidate an already pending respawn.

Reset Objectives restores all eight objectives and the tester's health/loadout, including recovery from elimination. Respawn at My Base restores the tester while preserving existing objective damage. Switch Base uses the selected character's real base and resets the practice scenario. Never duplicate tools.

Invalidate old callbacks when resetting, switching, respawning manually, or ending. Use round/session identity as well as spawn tokens so a callback from an earlier practice session cannot affect normal matches or another practice session.

Practice must not overlap a normal active match. It may pause an unstarted countdown while preserving real team reservations. Only the tester who started the session may mutate it; other Studio clients must not hijack the session. On tester disconnect, stop practice and restore multiplayer selection without trying to reload a disconnected player.

End Practice and Return to Holding clear training state, tools, effects and pending callbacks, restore the production match object, return the tester to the holding room, and resume normal admission. A disabled flag must prevent session startup and remove a running session if rechecked at runtime.

## Server authorization

Client visibility is not authorization. Gate every action on the server using both the configuration flag and `RunService:IsStudio()`. Do not create a practice remote on published servers. Validate action names, chosen base IDs, ownership and player state, and rate-limit requests. No client can supply the acting user ID or authorize itself with a flag.

## Stopped-editor map preview

Provide a documented Command Bar entry point or small plugin that builds the map while Studio is stopped. Reuse the same geometry builder as the real game. Include the eight bases and original Brainrots, forest scenery, trails and cover, holding room and portal labels.

Build only geometry: do not start match services, player sessions, interactive prompt callbacks, timers or combat. Do not change the editor's lighting as a side effect. Use one named generated preview container, mark ownership, and support rebuilding/removing it without duplicates. Never overwrite unrelated Studio objects, including an unmarked object with a matching name. Clear the owned preview before runtime map generation to avoid duplicate geometry during Play.

Explain that editor preview is for inspecting the map; Play is required for weapons and respawns. A build command should reject execution outside Studio and during Play.

## Verification and delivery

Run existing rules/combat tests and add meaningful coverage for the Studio/flag gates; single-player admission; no automatic victory; objective damage through the production combat path; own-objective protection; ordinary respawns; final-life elimination; resets and recovery; base changes; stale callbacks; owner disconnect; request limiting; normal match exclusion/restoration; and safe, repeatable preview generation.

Preserve all normal multiplayer tests: two opposing teams can start, four seats per team, fifth teammate rejected, no friendly fire, shared objective/respawn rules, last-team victory.

Run a real Rojo build when the runtime supports it. If Studio or the Rojo executable is unavailable, explicitly distinguish portable automated results from unverified engine behavior. Do not claim visual or multiplayer playtesting based on mocks.

Update the README with exact solo practice and editor preview steps, the single disable flag, and clean Git revert instructions. Deliver a dedicated commit containing only this feature and its documentation/tests.
