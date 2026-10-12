-- Cosmetic aerial survey squadron. Its warning hue reacts to live
-- disaster state but never provides a fictional safe collision surface.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local AerialSurveyRules = require(ReplicatedStorage.Shared.AerialSurveyRules)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local AerialSurveyKit = require(script.Parent.AerialSurveyKit)

local player = Players.LocalPlayer
local roundEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local folder = Instance.new("Folder")
folder.Name = "AerialSurveyLocal"
folder.Parent = workspace

local phase = "waiting"
local activeDisasters = {}
local finalRush = false
local currentBase = nil
local currentVariant = nil
local currentTier = nil
local fleet = nil

roundEvent.OnClientEvent:Connect(function(state)
    phase = tostring(type(state) == "table" and state.phase or "waiting")
    activeDisasters = type(state) == "table" and state.disasterIds or {}
    finalRush = type(state) == "table" and state.finalRush == true
end)

local function context()
    local map = workspace:FindFirstChild("GeneratedMap")
    local arena = map and map:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart") then return nil, nil end
    return base, tostring(arena:GetAttribute("VariantId") or "Classic")
end

local function rebuild(base, variant, tier)
    folder:ClearAllChildren()
    fleet = nil
    currentBase, currentVariant, currentTier = base, variant, tier
    if base then
        fleet = AerialSurveyKit.build(folder, base, variant,
            tier, VisualTheme.arena(variant))
    end
end

local function alertColor()
    if phase ~= "round" or type(activeDisasters) ~= "table" then
        return nil
    end
    for _, id in ipairs(activeDisasters) do
        local preset = DisasterVisuals.get(tostring(id))
        if preset and preset.Accent then return preset.Accent end
    end
    return nil
end

task.spawn(function()
    while folder.Parent do
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local base, variant = context()
        if currentBase ~= base or currentVariant ~= variant
            or currentTier ~= tier or (fleet and not fleet.folder.Parent)
        then
            rebuild(base, variant, tier)
        end
        local camera = workspace.CurrentCamera
        local distance = fleet and camera
            and (camera.CFrame.Position - base.Position).Magnitude or nil
        local close = fleet and AerialSurveyRules.inRange(
            distance, tier, fleet.inRange)
        if fleet then
            -- The survey kit is the sole owner of drone geometry masking.
            -- Retain the previous visibility for camera-edge hysteresis.
            fleet.inRange = close
            AerialSurveyKit.update(fleet, close and os.clock() or 0,
                phase, player:GetAttribute("ReduceMotion") == true or not close,
                alertColor(), finalRush, activeDisasters, close == true)
        end
        local interval = fleet and fleet.profile.Interval or 0.65
        task.wait(close and interval or math.max(0.65, interval))
    end
end)
