local Config = {
    MinimumPlayers = 1,
    IntermissionSeconds = 12,
    VoteSeconds = 8,
    ReadySeconds = 4,
    RoundSeconds = 45,
    PostRoundSeconds = 8,

    WinCoins = 25,
    WinXP = 30,
    ParticipationCoins = 5,
    ParticipationXP = 10,

    DoubleChaosEvery = 5,
    DoubleChaosChance = 0.12,

    Solo = {
        IntermissionSeconds = 6,
        VoteSeconds = 4,
        ReadySeconds = 4,
        RoundSeconds = 30,
        PostRoundSeconds = 6,
        WinCoinMultiplier = 1.4,
        WinXPMultiplier = 1.25,
        DoubleChaosEvery = 4,
        DoubleChaosChance = 0.10,
    },

    ArenaCenter = Vector3.new(0, 0, 0),
    LobbyCenter = Vector3.new(0, 0, -150),
}
return Config
