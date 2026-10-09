-- Orbital Helix / directional luminous runners on all eight ramps.
-- Completely cosmetic: no server loop, no interactive collisions, no lights.
-- Streaming-safe and 0 parts on Low/ReduceMotion hardware.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local player = Players.LocalPlayer

local folder = Instance.new("Folder")
folder.Name = "OrbitalHelixLocal"
folder.Parent = workspace

local currentCircuit = nil
local currentTier = nil
local currentReduced = nil
local runners = {}
local orderedRamps = {}

local function resolveCircuit()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    return arena and arena:FindFirstChild("HelixCircuit")
end

local function readRamps(circuit)
    if not circuit then return {} end
    local ramps = {}
    for _, part in ipairs(circuit:GetChildren()) do
        if part:IsA("BasePart") and part:GetAttribute("OrbitalHelixRamp") == true then
            table.insert(ramps, part)
        end
    end
    table.sort(ramps, function(a, b)
        return (a:GetAttribute("HelixLane") or 0)
            < (b:GetAttribute("HelixLane") or 0)
    end)
    return ramps
end

local function reset()
    folder:ClearAllChildren()
    table.clear(runners)
    table.clear(orderedRamps)
end

local function createRunner(ramp, index, lane, tier)
    local part = Instance.new("Part")
    part.Name = "HelixMotionGlyph"
    part.Size = tier == "High"
        and Vector3.new(1.05, 0.075, 0.27)
        or Vector3.new(0.72, 0.07, 0.24)
    part.Material = Enum.Material.Neon
    part.Color = lane % 2 == 0
        and Color3.fromRGB(121, 253, 209)
        or Color3.fromRGB(95, 201, 255)
    part.Transparency = tier == "High" and 0.24 or 0.40
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Parent = folder
    table.insert(runners, {
        Part = part, Ramp = ramp, Lane = lane,
        Index = index, Count = tier == "High" and 3 or 1,
    })
end

local function rebuild(circuit, tier, reduced, ramps)
    reset()
    currentCircuit = circuit
    currentTier = tier
    currentReduced = reduced
    if reduced or tier == "Low" then return end

    orderedRamps = ramps
    for index, ramp in ipairs(ramps) do
        local n = tier == "High" and 3 or 1
        for lane = 1, n do
            createRunner(ramp, index, lane, tier)
        end
    end
end

local function draw(time)
    for _, runner in ipairs(runners) do
        local ramp = runner.Ramp
        if ramp and ramp.Parent then
            local count = runner.Count
            local t = (time * 0.44 + ((runner.Lane - 1) / count)
                + runner.Index * 0.037) % 1
            -- Local -Z is the inner-ring direction of each inclined ramp.
            local z = (0.5 - t) * (ramp.Size.Z - 1.8)
            local x = count == 1 and 0
                or (runner.Lane - 2) * (ramp.Size.X * 0.26)
            runner.Part.CFrame = ramp.CFrame * CFrame.new(
                x, ramp.Size.Y * 0.5 + 0.13, z
            )
        end
    end
end

task.spawn(function()
    while folder.Parent do
        local circuit = resolveCircuit()
        local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier")).Name
        local reduced = player:GetAttribute("ReduceMotion") == true
        local ramps = readRamps(circuit)
        local stale = circuit ~= currentCircuit or tier ~= currentTier
            or reduced ~= currentReduced or #ramps ~= #orderedRamps
        if stale then
            rebuild(circuit, tier, reduced, ramps)
        end

        if #runners > 0 then
            draw(os.clock())
            -- At most 24 client-only glowing glyphs; 8 on Medium.
            task.wait(tier == "High" and 0.075 or 0.14)
        else
            -- Zero GPU parts and minimal CPU usage outside Orbital,
            -- on Low tier, or with reduced motion enabled.
            task.wait(0.60)
        end
    end
end)
