local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SurfaceAudioRules = require(ReplicatedStorage.Shared.SurfaceAudioRules)

local player = Players.LocalPlayer
local floorConnection = nil
local childAddedConnection = nil
local childRemovedConnection = nil
local boundSounds = {}
local baseVolumes = setmetatable({}, {__mode = "k"})

local SURFACE_SOUND_NAMES = {
    Running = true,
    Landing = true,
}

local function disconnect()
    if floorConnection then
        floorConnection:Disconnect()
        floorConnection = nil
    end
    if childAddedConnection then
        childAddedConnection:Disconnect()
        childAddedConnection = nil
    end
    if childRemovedConnection then
        childRemovedConnection:Disconnect()
        childRemovedConnection = nil
    end
    table.clear(boundSounds)
    table.clear(baseVolumes)
end

local function ensureEffects(sound)
    local eq = sound:FindFirstChild("ChaosSurfaceEQ")
    if not eq then
        eq = Instance.new("EqualizerSoundEffect")
        eq.Name = "ChaosSurfaceEQ"
        eq.Parent = sound
    end

    local reverb = sound:FindFirstChild("ChaosSurfaceReverb")
    if not reverb then
        reverb = Instance.new("ReverbSoundEffect")
        reverb.Name = "ChaosSurfaceReverb"
        reverb.DryLevel = 0
        reverb.Density = 0.54
        reverb.Diffusion = 0.72
        reverb.Parent = sound
    end

    return eq, reverb
end

local function applyProfile(sound, profile)
    local eq, reverb = ensureEffects(sound)
    eq.LowGain = profile.Low
    eq.MidGain = profile.Mid
    eq.HighGain = profile.High
    reverb.WetLevel = profile.Wet
    reverb.DecayTime = profile.Decay

    local baseVolume = baseVolumes[sound]
    if baseVolume == nil then
        baseVolume = sound.Volume
        baseVolumes[sound] = baseVolume
    end
    sound.Volume = player:GetAttribute("AudioMuted") == true and 0 or baseVolume
end

local function bindCharacter(character)
    disconnect()

    local humanoid = character:WaitForChild("Humanoid", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not root then
        return
    end

    local function refresh()
        local profile = SurfaceAudioRules.profile(humanoid.FloorMaterial)
        for sound in pairs(boundSounds) do
            if sound.Parent then
                applyProfile(sound, profile)
            else
                boundSounds[sound] = nil
            end
        end
    end

    local function maybeBindSound(child)
        if child:IsA("Sound") and SURFACE_SOUND_NAMES[child.Name] then
            boundSounds[child] = true
            if baseVolumes[child] == nil then
                baseVolumes[child] = child.Volume
            end
            refresh()
        end
    end

    for _, child in ipairs(root:GetChildren()) do
        maybeBindSound(child)
    end

    childAddedConnection = root.ChildAdded:Connect(maybeBindSound)
    childRemovedConnection = root.ChildRemoved:Connect(function(child)
        boundSounds[child] = nil
        baseVolumes[child] = nil
    end)
    floorConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(refresh)

    refresh()
end

if player.Character then
    task.spawn(bindCharacter, player.Character)
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(disconnect)


player:GetAttributeChangedSignal("AudioMuted"):Connect(function()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local profile = SurfaceAudioRules.profile(humanoid.FloorMaterial)
    for sound in pairs(boundSounds) do
        if sound.Parent then
            applyProfile(sound, profile)
        end
    end
end)
