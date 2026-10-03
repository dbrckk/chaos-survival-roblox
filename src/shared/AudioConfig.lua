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
    GoldenShard = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.50, PlaybackSpeed = 1.60},
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
    Overdrive = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.52, PlaybackSpeed = 0.72},
    FinalRush = {SoundId = "rbxasset://sounds/swoosh.wav", Volume = 0.42, PlaybackSpeed = 1.05},
    FlowCombo = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.46, PlaybackSpeed = 2.35},
    MasterRound = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.62, PlaybackSpeed = 1.85},
    Darkness = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.25, PlaybackSpeed = 0.55},
    Shrink = {SoundId = "rbxasset://sounds/swoosh.wav", Volume = 0.24, PlaybackSpeed = 0.72},
}

AudioConfig.Composite = {
    Ready = {
        {Sound = "Ready", VolumeScale = 0.82, PitchOffset = -0.03},
        {Sound = "Countdown", Delay = 0.045, VolumeScale = 0.34, PitchOffset = -0.22},
    },
    RoundStart = {
        {Sound = "RoundStart", VolumeScale = 0.90, PitchOffset = -0.06},
        {Sound = "Speed", Delay = 0.035, VolumeScale = 0.28, PitchOffset = -0.38},
        {Sound = "UISelect", Delay = 0.105, VolumeScale = 0.18, PitchOffset = 0.20},
    },
    DoubleChaos = {
        {Sound = "DoubleChaos", VolumeScale = 0.92, PitchOffset = -0.10},
        {Sound = "Speed", Delay = 0.035, VolumeScale = 0.42, PitchOffset = -0.48},
        {Sound = "Countdown", Delay = 0.10, VolumeScale = 0.26, PitchOffset = -0.52},
    },
    FinalRush = {
        {Sound = "FinalRush", VolumeScale = 0.90, PitchOffset = -0.08},
        {Sound = "Countdown", Delay = 0.055, VolumeScale = 0.36, PitchOffset = -0.40},
        {Sound = "Speed", Delay = 0.11, VolumeScale = 0.22, PitchOffset = 0.18},
    },
    Survived = {
        {Sound = "Survived", VolumeScale = 0.92, PitchOffset = 0.02},
        {Sound = "Reward", Delay = 0.055, VolumeScale = 0.44, PitchOffset = -0.14},
        {Sound = "ShardCollect", Delay = 0.13, VolumeScale = 0.22, PitchOffset = 0.24},
    },
    Eliminated = {
        {Sound = "Eliminated", VolumeScale = 0.90, PitchOffset = -0.08},
        {Sound = "Darkness", Delay = 0.025, VolumeScale = 0.25, PitchOffset = -0.18},
        {Sound = "Hit", Delay = 0.085, VolumeScale = 0.15, PitchOffset = -0.26},
    },
    LevelUp = {
        {Sound = "LevelUp", VolumeScale = 0.90, PitchOffset = -0.02},
        {Sound = "Reward", Delay = 0.06, VolumeScale = 0.44, PitchOffset = 0.08},
    },
    MasterRound = {
        {Sound = "MasterRound", VolumeScale = 0.94, PitchOffset = -0.03},
        {Sound = "GoldenShard", Delay = 0.055, VolumeScale = 0.42, PitchOffset = -0.20},
        {Sound = "Reward", Delay = 0.12, VolumeScale = 0.38, PitchOffset = 0.10},
    },
    GoldenShard = {
        {Sound = "GoldenShard", VolumeScale = 0.92, PitchOffset = -0.02},
        {Sound = "Reward", Delay = 0.045, VolumeScale = 0.36, PitchOffset = 0.12},
    },
    Vote = {
        {Sound = "Vote", VolumeScale = 0.84, PitchOffset = -0.03},
        {Sound = "UISelect", Delay = 0.025, VolumeScale = 0.24, PitchOffset = 0.18},
    },
    Reward = {
        {Sound = "Reward", VolumeScale = 0.88, PitchOffset = -0.03},
        {Sound = "ShardCollect", Delay = 0.038, VolumeScale = 0.26, PitchOffset = -0.20},
    },
    LastSurvivor = {
        {Sound = "LastSurvivor", VolumeScale = 0.92, PitchOffset = -0.04},
        {Sound = "Darkness", Delay = 0.035, VolumeScale = 0.22, PitchOffset = -0.24},
    },
    Overdrive = {
        {Sound = "Overdrive", VolumeScale = 0.90, PitchOffset = -0.08},
        {Sound = "Speed", Delay = 0.035, VolumeScale = 0.38, PitchOffset = -0.26},
        {Sound = "Countdown", Delay = 0.085, VolumeScale = 0.22, PitchOffset = -0.46},
    },
    FlowCombo = {
        {Sound = "FlowCombo", VolumeScale = 0.90, PitchOffset = -0.02},
        {Sound = "ShardCollect", Delay = 0.03, VolumeScale = 0.30, PitchOffset = 0.10},
        {Sound = "Reward", Delay = 0.07, VolumeScale = 0.24, PitchOffset = 0.18},
    },
    NearMiss = {
        {Sound = "Speed", VolumeScale = 0.56, PitchOffset = 0.16},
        {Sound = "Wind", Delay = 0.025, VolumeScale = 0.20, PitchOffset = 0.28},
        {Sound = "Hit", Delay = 0.055, VolumeScale = 0.16, PitchOffset = 0.34},
    },
}

AudioConfig.Composite.Lava = {
    {Sound = "Lava", VolumeScale = 0.82, PitchOffset = -0.08},
    {Sound = "Darkness", Delay = 0.025, VolumeScale = 0.18, PitchOffset = -0.34},
    {Sound = "Hit", Delay = 0.075, VolumeScale = 0.12, PitchOffset = -0.28},
}
AudioConfig.Composite.Meteor = {
    {Sound = "Meteor", VolumeScale = 0.90, PitchOffset = -0.06},
    {Sound = "Wind", Delay = 0.018, VolumeScale = 0.18, PitchOffset = 0.18},
    {Sound = "Hit", Delay = 0.055, VolumeScale = 0.16, PitchOffset = -0.34},
}
AudioConfig.Composite.LowGravity = {
    {Sound = "LowGravity", VolumeScale = 0.72, PitchOffset = -0.08},
    {Sound = "Speed", Delay = 0.035, VolumeScale = 0.16, PitchOffset = -0.42},
    {Sound = "UISelect", Delay = 0.095, VolumeScale = 0.12, PitchOffset = 0.28},
}
AudioConfig.Composite.PlatformWarning = {
    {Sound = "PlatformWarning", VolumeScale = 0.88, PitchOffset = -0.05},
    {Sound = "Countdown", Delay = 0.050, VolumeScale = 0.20, PitchOffset = 0.24},
}
AudioConfig.Composite.Tornado = {
    {Sound = "Tornado", VolumeScale = 0.84, PitchOffset = -0.06},
    {Sound = "Wind", Delay = 0.015, VolumeScale = 0.26, PitchOffset = -0.18},
    {Sound = "Speed", Delay = 0.070, VolumeScale = 0.12, PitchOffset = -0.42},
}
AudioConfig.Composite.Freeze = {
    {Sound = "Freeze", VolumeScale = 0.88, PitchOffset = 0.02},
    {Sound = "PlatformWarning", Delay = 0.035, VolumeScale = 0.18, PitchOffset = 0.34},
    {Sound = "Darkness", Delay = 0.085, VolumeScale = 0.12, PitchOffset = 0.22},
}
AudioConfig.Composite.Bombs = {
    {Sound = "Bombs", VolumeScale = 0.92, PitchOffset = -0.08},
    {Sound = "Hit", Delay = 0.030, VolumeScale = 0.22, PitchOffset = -0.42},
    {Sound = "Countdown", Delay = 0.085, VolumeScale = 0.14, PitchOffset = -0.48},
}
AudioConfig.Composite.Speed = {
    {Sound = "Speed", VolumeScale = 0.88, PitchOffset = 0.02},
    {Sound = "Wind", Delay = 0.020, VolumeScale = 0.18, PitchOffset = 0.34},
    {Sound = "UISelect", Delay = 0.075, VolumeScale = 0.12, PitchOffset = 0.38},
}
AudioConfig.Composite.Darkness = {
    {Sound = "Darkness", VolumeScale = 0.90, PitchOffset = -0.06},
    {Sound = "LowGravity", Delay = 0.030, VolumeScale = 0.16, PitchOffset = -0.34},
}
AudioConfig.Composite.Shrink = {
    {Sound = "Shrink", VolumeScale = 0.88, PitchOffset = -0.10},
    {Sound = "Countdown", Delay = 0.040, VolumeScale = 0.18, PitchOffset = -0.52},
    {Sound = "Darkness", Delay = 0.085, VolumeScale = 0.12, PitchOffset = -0.30},
}
AudioConfig.Composite.JumpShock = {
    {Sound = "JumpShock", VolumeScale = 0.90, PitchOffset = 0.02},
    {Sound = "Speed", Delay = 0.025, VolumeScale = 0.16, PitchOffset = 0.32},
    {Sound = "Countdown", Delay = 0.070, VolumeScale = 0.12, PitchOffset = 0.40},
}
AudioConfig.Composite.MobilityPad = {
    {Sound = "MobilityPad", VolumeScale = 0.88, PitchOffset = -0.02},
    {Sound = "Speed", Delay = 0.020, VolumeScale = 0.22, PitchOffset = 0.18},
}
AudioConfig.Composite.Hit = {
    {Sound = "Hit", VolumeScale = 0.90, PitchOffset = -0.03},
    {Sound = "Darkness", Delay = 0.020, VolumeScale = 0.10, PitchOffset = -0.32},
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
