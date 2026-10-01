local AudioConfig = {}

AudioConfig.Music = {
    Lobby = {
        SoundId = "rbxassetid://1837849285",
        Volume = 0.11,
        PlaybackSpeed = 1,
        Looped = true,
    },
}

AudioConfig.Sfx = {
    UISelect = {SoundId = "rbxasset://sounds/button.wav", Volume = 0.32, PlaybackSpeed = 1.35},
    Vote = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.34, PlaybackSpeed = 1.15},
    Countdown = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.28, PlaybackSpeed = 1.7},
    Ready = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.30, PlaybackSpeed = 1.35},
    RoundStart = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.45, PlaybackSpeed = 0.85},
    DoubleChaos = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.55, PlaybackSpeed = 0.75},
    LastSurvivor = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.48, PlaybackSpeed = 0.62},
    Survived = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.52, PlaybackSpeed = 1.55},
    Eliminated = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.42, PlaybackSpeed = 0.72},
    Hit = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.18, PlaybackSpeed = 1.45},
    Reward = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.36, PlaybackSpeed = 1.9},
    ShardCollect = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.30, PlaybackSpeed = 2.25},
    LevelUp = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.58, PlaybackSpeed = 2.15},
    JumpShock = {SoundId = "rbxasset://sounds/short spring sound.wav", Volume = 0.34, PlaybackSpeed = 1.15},
    Meteor = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.30, PlaybackSpeed = 0.9},
    Bombs = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.36, PlaybackSpeed = 0.7},
    Wind = {SoundId = "rbxasset://sounds/action_falling.ogg", Volume = 0.17, PlaybackSpeed = 0.85, Looped = true},
    LowGravity = {SoundId = "rbxasset://sounds/action_swim.mp3", Volume = 0.12, PlaybackSpeed = 0.72, Looped = true},
    Lava = {SoundId = "rbxasset://sounds/action_falling.ogg", Volume = 0.16, PlaybackSpeed = 0.62},
    PlatformWarning = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.28, PlaybackSpeed = 1.55},
    Tornado = {SoundId = "rbxasset://sounds/action_falling.ogg", Volume = 0.24, PlaybackSpeed = 0.78},
    Freeze = {SoundId = "rbxasset://sounds/impact_water.mp3", Volume = 0.22, PlaybackSpeed = 1.35},
    Speed = {SoundId = "rbxasset://sounds/swoosh.wav", Volume = 0.28, PlaybackSpeed = 1.65},
    MobilityPad = {SoundId = "rbxasset://sounds/swoosh.wav", Volume = 0.34, PlaybackSpeed = 1.25},
    Darkness = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.25, PlaybackSpeed = 0.55},
    Shrink = {SoundId = "rbxasset://sounds/swoosh.wav", Volume = 0.24, PlaybackSpeed = 0.72},
}

AudioConfig.DisasterLoop = {
    Tornado = "Wind",
    Meteors = "Wind",
    SpeedSurge = "Wind",
    LowGravity = "LowGravity",
}

AudioConfig.DisasterAccent = {
    RisingLava = "Lava",
    Meteors = "Meteor",
    LowGravity = "LowGravity",
    DisappearingPlatforms = "PlatformWarning",
    Tornado = "Tornado",
    Freeze = "Freeze",
    Bombs = "Bombs",
    SpeedSurge = "Speed",
    Darkness = "Darkness",
    ShrinkingArena = "Shrink",
    JumpShock = "JumpShock",
}

return AudioConfig
