local Config = {
    MinimumPlayers = 1,
    IntermissionSeconds = 8,
    VoteSeconds = 6,
    ReadySeconds = 4,
    RoundSeconds = 45,
    PostRoundSeconds = 6,

    WinCoins = 25,
    WinXP = 30,
    ParticipationCoins = 5,
    ParticipationXP = 10,

    DoubleChaosEvery = 5,
    DoubleChaosChance = 0.12,

    Solo = {
        IntermissionSeconds = 4,
        VoteSeconds = 3,
        ReadySeconds = 4,
        RoundSeconds = 30,
        PostRoundSeconds = 5,
        WinCoinMultiplier = 1.4,
        WinXPMultiplier = 1.25,
        DoubleChaosEvery = 4,
        DoubleChaosChance = 0.10,
    },

    ArenaCenter = Vector3.new(0, 0, 0),
    -- Leave physical space between the 224-stud arena, its external
    -- skyline and the separate 74-stud lobby. The previous -150 placed
    -- the lobby floor just ONE stud from the enlarged arena edge.
    LobbyCenter = Vector3.new(0, 0, -270),
}
return Config
