-- One identifiable kinetic hero sculpture per rotating arena.
-- All motion is time-sliced and pauses in the lobby / on reduced motion.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SignatureKit = require(script.Parent.ArenaSignatureKit)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local state = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local folder = Instance.new("Folder")
folder.Name = "ArenaSignatureLocal"
folder.Parent = workspace

local phase = "waiting"
local bundle = nil
local mapConnection = nil

local function rebuild()
    folder:ClearAllChildren()
    bundle = nil
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then
        return
    end
    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    bundle = SignatureKit.build(folder, base, variant, tier.Name)
    SignatureKit.update(bundle, 0, true)
end

local function bind(generated)
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.defer(rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bind(child)
        task.defer(rebuild)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bind(nil)
        folder:ClearAllChildren()
        bundle = nil
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    task.defer(rebuild)
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if bundle then
        SignatureKit.update(bundle, 0, true)
    end
end)

state.OnClientEvent:Connect(function(snapshot)
    phase = tostring(snapshot.phase or "waiting")
    if bundle and (phase ~= "round" and phase ~= "ready") then
        SignatureKit.update(bundle, 0, true)
    end
end)

bind(workspace:FindFirstChild("GeneratedMap"))
task.defer(rebuild)

task.spawn(function()
    while true do
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
        local active = phase == "round" or phase == "ready"
        local reduced = player:GetAttribute("ReduceMotion") == true
        if active and not reduced and bundle and bundle.folder.Parent then
            SignatureKit.update(bundle, os.clock(), false)
            task.wait(tier.Name == "Low" and 0.22 or (tier.Name == "Medium" and 0.13 or 0.09))
        else
            task.wait(0.60)
        end
    end
end)
