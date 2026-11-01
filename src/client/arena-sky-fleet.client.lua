-- Four enormous but lightweight air-traffic silhouettes give each
-- 320-stud arena a distinct moving skyline, never a fake usable platform.
-- Uses one existing RoundState stream and one tier-paced cosmetic coroutine.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SkyFleet = require(script.Parent.ArenaSkyFleetKit)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)

local player = Players.LocalPlayer
local roundEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local folder = Instance.new("Folder")
folder.Name = "ArenaSkyFleetLocal"
folder.Parent = workspace

local watchedMap = nil
local disconnectReadiness = nil
local rebuildQueued = false
local bundle = nil
local clock = 0
local phase = "waiting"
local finalRush = false
local disasterCount = 0

local function tierName()
    return VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled
    ).Name
end

local function clear()
    folder:ClearAllChildren()
    bundle = nil
    clock = 0
end

local function rebuild()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = MapVisualReadiness.part(generated, "Arena", "Base")
    if not arena or not base then
        clear()
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "")
    local tier = tierName()
    if SkyFleet.matches(bundle, base, variant, tier, folder) then
        return
    end

    clear()
    local theme = VisualTheme.arena(variant)
    bundle = SkyFleet.build(folder, base, variant, theme, tier)
    if bundle then
        SkyFleet.pose(bundle, 0, "waiting", true, false, 0)
    end
end

local function scheduleRebuild()
    if rebuildQueued then return end
    rebuildQueued = true
    task.defer(function()
        rebuildQueued = false
        rebuild()
    end)
end

local function bindMap(generated)
    if watchedMap == generated then return end
    if disconnectReadiness then
        disconnectReadiness()
        disconnectReadiness = nil
    end
    watchedMap = generated
    clear()
    if generated then
        disconnectReadiness = MapVisualReadiness.watch(
            generated, "Arena", "Base", scheduleRebuild
        )
    end
    scheduleRebuild()
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and child == workspace:FindFirstChild("GeneratedMap") then
        bindMap(child)
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    clock = 0
    if bundle then
        SkyFleet.pose(bundle, 0, "waiting", true, false, 0)
    end
end)

roundEvent.OnClientEvent:Connect(function(snapshot)
    if type(snapshot) ~= "table" then return end
    local nextPhase = tostring(snapshot.phase or "waiting")
    if nextPhase ~= phase then
        clock = 0
    end
    phase = nextPhase
    finalRush = phase == "round" and snapshot.finalRush == true

    local ids = type(snapshot.disasterIds) == "table"
        and snapshot.disasterIds or {}
    disasterCount = math.min(2, #ids)
    if phase ~= "round" and phase ~= "ready" and phase ~= "result" then
        if bundle then
            SkyFleet.pose(bundle, 0, "waiting", true, false, 0)
        end
    end
end)

bindMap(workspace:FindFirstChild("GeneratedMap"))
scheduleRebuild()

task.spawn(function()
    while true do
        local profile = SkyFleet.profile(tierName())
        local active = phase == "ready" or phase == "round" or phase == "result"
        local reduced = player:GetAttribute("ReduceMotion") == true
        if not bundle or not bundle.folder.Parent or not active or reduced then
            task.wait(0.55)
        else
            -- A suspended Android app can resume with an enormous dt;
            -- never fast-forward flying hulls through the skyline.
            local dt = task.wait(profile.interval)
            if bundle and bundle.folder.Parent
                and (phase == "ready" or phase == "round" or phase == "result")
                and player:GetAttribute("ReduceMotion") ~= true then
                clock += math.clamp(tonumber(dt) or 0, 0, 0.25)
                SkyFleet.pose(bundle, clock, phase, false, finalRush, disasterCount)
            end
        end
    end
end)
