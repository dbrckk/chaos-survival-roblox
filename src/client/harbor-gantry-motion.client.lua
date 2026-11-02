-- Four ORIGINAL distant Storm Harbor cranes now operate visibly:
-- trolleys traverse their real overhead rails, actual hoist cables
-- shorten as suspended loads rise, and the ship radar sweeps the port.
-- All movement is CLIENT-ONLY on existing anchored/noncolliding Parts.
-- Never changes hazard/parkour collision, server position, or rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local Motion = require(ReplicatedStorage.Shared.HarborGantryMotionRules)
local player = Players.LocalPlayer

local CRANE_NAMES = {
    "HarborGantryEastNorth",
    "HarborGantryEastSouth",
    "HarborGantryWestNorth",
    "HarborGantryWestSouth",
}
local fleet = nil
local cranes = {}
local radar = nil
local clock = 0
local lastScanAt = -math.huge

local function restore(record)
    if not record or not record.animated then return end
    for _, entry in ipairs(record.parts) do
        local part = entry.part
        if part and part.Parent then
            part.CFrame = entry.frame
            if entry.role == "cable" then
                part.Size = entry.size
            end
        end
    end
    record.animated = false
    record.fade = 0
end

local function clear()
    for _, record in ipairs(cranes) do restore(record) end
    restore(radar)
    table.clear(cranes)
    radar = nil
    fleet = nil
    clock = 0
end

local function capturePart(parts, part, vessel)
    if not part or not part:IsA("BasePart")
        or part.CanCollide or part.CanTouch or part.CanQuery then
        return
    end
    local role = Motion.role(part.Name, vessel)
    if role then
        parts[#parts + 1] = {
            part = part, role = role,
            frame = part.CFrame, size = part.Size,
        }
    end
end

local function captureCrane(model, index)
    if not model or not model:IsA("Model")
        or model:GetAttribute("HarborGantryScenery") ~= true
        or model:GetAttribute("CosmeticOnly") ~= true then return nil end
    local crossgirder = model:FindFirstChild("MainCrossgirder")
    if not crossgirder or not crossgirder:IsA("BasePart") then
        return nil
    end
    local record = {
        model = model,
        index = index,
        frame = crossgirder.CFrame,
        reference = crossgirder,
        parts = {},
        fade = 0,
        animated = false,
    }
    for _, child in ipairs(model:GetChildren()) do
        capturePart(record.parts, child, false)
    end
    return #record.parts >= 6 and record or nil
end

local function captureRadar(model)
    if not model or not model:IsA("Model")
        or model:GetAttribute("HarborVesselScenery") ~= true then return nil end
    local entry = {}
    capturePart(entry, model:FindFirstChild("RadarBoom"), true)
    if #entry ~= 1 then return nil end
    return {model = model, reference = entry[1].part,
        parts = entry, fade = 0, animated = false}
end

local function findFleet()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not arena or arena:GetAttribute("VariantId") ~= "Harbor" then
        return nil
    end
    local decor = arena:FindFirstChild("Decor")
    return decor and decor:FindFirstChild("StormHarborGantryFleet")
end

local function refresh()
    local nextFleet = findFleet()
    if nextFleet ~= fleet then
        clear()
        fleet = nextFleet
    end
    if not fleet then return end

    -- Atomic model streaming may bring in a crane AFTER the arena root.
    -- Reacquire only missing/destroyed models, preserving captured rest
    -- poses of parts already being animated on this client.
    for index, name in ipairs(CRANE_NAMES) do
        local model = fleet:FindFirstChild(name)
        local record = cranes[index]
        if record and (record.model ~= model or not record.reference.Parent) then
            restore(record)
            cranes[index] = nil
            record = nil
        end
        if not record then
            cranes[index] = captureCrane(model, index)
        end
    end
    local vessel = fleet:FindFirstChild("HarborCargoVessel")
    if radar and (radar.model ~= vessel or not radar.reference.Parent) then
        restore(radar)
        radar = nil
    end
    if not radar then radar = captureRadar(vessel) end
end

local function applyCrane(record, time)
    record.fade = math.min(1, record.fade + 0.12)
    local drive, hoist = Motion.pose(time, record.index, record.fade)
    local frame = record.frame
    local trolleyOffset = frame:VectorToWorldSpace(
        Vector3.new(0, 0, drive))
    local loadOffset = frame:VectorToWorldSpace(
        Vector3.new(0, hoist, drive))
    local cableOffset = frame:VectorToWorldSpace(
        Vector3.new(0, hoist * 0.5, drive))

    for _, entry in ipairs(record.parts) do
        local part = entry.part
        if part and part.Parent then
            if entry.role == "trolley" then
                part.CFrame = CFrame.new(trolleyOffset) * entry.frame
            elseif entry.role == "cable" then
                part.CFrame = CFrame.new(cableOffset) * entry.frame
                part.Size = Vector3.new(
                    entry.size.X, math.max(7, entry.size.Y - hoist),
                    entry.size.Z)
            else
                part.CFrame = CFrame.new(loadOffset) * entry.frame
            end
        end
    end
    record.animated = true
end

local function applyRadar(record, time)
    local entry = record.parts[1]
    if not entry or not entry.part.Parent then return end
    record.fade = math.min(1, record.fade + 0.12)
    entry.part.CFrame = entry.frame
        * CFrame.Angles(0, Motion.radarAngle(time, record.fade), 0)
    record.animated = true
end

local function step(profile, dt)
    local camera = workspace.CurrentCamera
    if not camera or not fleet or not fleet.Parent
        or profile.Count == 0 then
        for _, record in ipairs(cranes) do restore(record) end
        restore(radar)
        return
    end

    -- Zero trig/CFrame writes for hidden cranes and distant camera views.
    -- Medium animates only the TWO nearest; High animates all four.
    local visible = {}
    for _, record in ipairs(cranes) do
        local part = record.reference
        if part and part.Parent
            and part.LocalTransparencyModifier < 0.9 then
            local distance = (part.Position - camera.CFrame.Position).Magnitude
            if distance < profile.Range then
                visible[#visible + 1] = {record = record, distance = distance}
            end
        end
    end
    table.sort(visible, function(a, b) return a.distance < b.distance end)
    local chosen = {}
    for index = 1, math.min(profile.Count, #visible) do
        chosen[visible[index].record] = true
    end

    clock += math.clamp(tonumber(dt) or 0, 0, 0.25)
    for _, record in ipairs(cranes) do
        if chosen[record] then applyCrane(record, clock)
        else restore(record) end
    end
    if radar and radar.reference and radar.reference.Parent
        and radar.reference.LocalTransparencyModifier < 0.9
        and (radar.reference.Position - camera.CFrame.Position).Magnitude
            < profile.Range then
        applyRadar(radar, clock)
    else
        restore(radar)
    end
end

task.spawn(function()
    while true do
        local tier = VfxQuality.deviceTier(
            player:GetAttribute("VfxQualityTier"),
            UserInputService.TouchEnabled
        ).Name
        local profile = Motion.profile(
            tier, player:GetAttribute("ReduceMotion") == true)
        if os.clock() - lastScanAt > 1.8 then
            lastScanAt = os.clock()
            refresh()
        end
        local dt = task.wait(profile.Interval)
        step(profile, dt)
    end
end)
