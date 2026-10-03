local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SurfaceAudioRules = require(ReplicatedStorage.Shared.SurfaceAudioRules)

local player = Players.LocalPlayer
local humanoidConnection = nil
local childConnection = nil

local function disconnect()
    if humanoidConnection then
        humanoidConnection:Disconnect()
        humanoidConnection = nil
    end
    if childConnection then
        childConnection:Disconnect()
        childConnection = nil
    end
end

local function applyToRunningSound(humanoid, running)
    if not running or not running:IsA("Sound") then
        return
    end

    local eq = running:FindFirstChild("ChaosFootstepEQ")
    if not eq then
        eq = Instance.new("EqualizerSoundEffect")
        eq.Name = "ChaosFootstepEQ"
        eq.Parent = running
    end

    local reverb = running:FindFirstChild("ChaosFootstepReverb")
    if not reverb then
        reverb = Instance.new("ReverbSoundEffect")
        reverb.Name = "ChaosFootstepReverb"
        reverb.DryLevel = 0
        reverb.Density = 0.54
        reverb.Diffusion = 0.72
        reverb.Parent = running
    end

    local function refresh()
        local profile = SurfaceAudioRules.profile(humanoid.FloorMaterial)
        eq.LowGain = profile.Low
        eq.MidGain = profile.Mid
        eq.HighGain = profile.High
        reverb.WetLevel = profile.Wet
        reverb.DecayTime = profile.Decay
    end

    refresh()
    humanoidConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(refresh)
end

local function bindCharacter(character)
    disconnect()

    local humanoid = character:WaitForChild("Humanoid", 5)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoid or not root then
        return
    end

    local running = root:FindFirstChild("Running")
    if running and running:IsA("Sound") then
        applyToRunningSound(humanoid, running)
        return
    end

    childConnection = root.ChildAdded:Connect(function(child)
        if child.Name == "Running" and child:IsA("Sound") then
            if childConnection then
                childConnection:Disconnect()
                childConnection = nil
            end
            applyToRunningSound(humanoid, child)
        end
    end)

    task.delay(4, function()
        if childConnection and childConnection.Connected then
            childConnection:Disconnect()
            childConnection = nil
        end
    end)
end

if player.Character then
    task.spawn(bindCharacter, player.Character)
end

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(disconnect)
