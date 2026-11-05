-- PvP configuration only. No single-player progression or DataStore dependencies.
return {
    Title = "BRAIN ROT BATTLES",
    BuildId = "forest-three-floor-bases-20261105c",
    -- One switch for all solo practice tools. The server ALSO requires IsStudio().
    StudioPracticeEnabled = true,
    PlayerHealth = 200,
    BrainrotHealth = 50,
    Capacity = 32,
    TeamSize = 4,
    MinimumPlayers = 2,
    MinimumTeams = 2,
    Countdown = 20,
    RoundDuration = 600,
    ResultsDuration = 6,
    Intermission = 10,
    RespawnDelay = 3,
    SpawnProtection = 3,
    WalkSpeed = 20,
    ArenaSize = 900,
    BaseRadius = 330,
    Holding = { X = 0, Y = 70, Z = -650, Width = 220, Depth = 150 },
    -- Set actual published destination IDs to enable optional cross-game travel.
    SinglePlayerPlaceId = 0,
    BattlePlaceId = 0,
    -- Reserved for future PvP persistence; this release never accesses old saves.
    DataStoreName = "BrainRotBattle_Progress_v1",
    Weapons = {
        Bat = { PlayerDamage = 25, ObjectiveDamage = 10, Cooldown = 0.65, Range = 10, Knockback = 22 },
        Sniper = { PlayerDamage = 70, ObjectiveDamage = 10, Cooldown = 1.2, Range = 650, Magazine = 5, Reload = 2.8 },
    },
    Characters = {
        { Id = "Tung", Name = "Tung Tung Tung Sahur", Color = "F5A34B" },
        { Id = "Tralalero", Name = "Tralalero Tralala", Color = "4CBFFF" },
        { Id = "Crocodilo", Name = "Bombardiro Crocodilo", Color = "7BDC71" },
        { Id = "Lirili", Name = "Lirili Larila", Color = "BA8CFF" },
        { Id = "Chimpanzini", Name = "Chimpanzini Bananini", Color = "FFE05A" },
        { Id = "Ballerina", Name = "Ballerina Cappuccina", Color = "FF8CCB" },
        { Id = "Trippi", Name = "Trippi Troppi", Color = "50E9DB" },
        { Id = "Patapim", Name = "Brr Brr Patapim", Color = "FF776D" },
    },
}
