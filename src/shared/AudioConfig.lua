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
    RoundStart = {SoundId = "rbxasset://sounds/switch.wav", Volume = 0.45, PlaybackSpeed = 0.85},
    DoubleChaos = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.55, PlaybackSpeed = 0.75},
    Survived = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.52, PlaybackSpeed = 1.55},
    Eliminated = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.42, PlaybackSpeed = 0.72},
    Reward = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.36, PlaybackSpeed = 1.9},
    LevelUp = {SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.58, PlaybackSpeed = 2.15},
    JumpShock = {SoundId = "rbxasset://sounds/short spring sound.wav", Volume = 0.34, PlaybackSpeed = 1.15},
    Meteor = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.30, PlaybackSpeed = 0.9},
    Bombs = {SoundId = "rbxasset://sounds/collide.wav", Volume = 0.36, PlaybackSpeed = 0.7},
    Wind = {SoundId = "rbxasset://sounds/action_falling.ogg", Volume = 0.17, PlaybackSpeed = 0.85, Looped = true},
    LowGravity = {SoundId = "rbxasset://sounds/action_swim.mp3", Volume = 0.12, PlaybackSpeed = 0.72, Looped = true},
}

AudioConfig.DisasterLoop = {
    Tornado = "Wind",
    Meteors = "Wind",
    SpeedSurge = "Wind",
    LowGravity = "LowGravity",
}

AudioConfig.DisasterAccent = {
    JumpShock = "JumpShock",
    Bombs = "Bombs",
    Meteors = "Meteor",
}

return AudioConfig
