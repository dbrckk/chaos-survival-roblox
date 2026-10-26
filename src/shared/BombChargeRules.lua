-- Pure, server-clock-driven bomb anticipation silhouette. No hitboxes,
-- explosions or extra network events; the ground warning stays authoritative.
local BombChargeRules = {}

local BUDGETS = {
    Low = {Count = 1, MaxDistance = 65, MaxActive = 2},
    Medium = {Count = 3, MaxDistance = 100, MaxActive = 3},
    High = {Count = 5, MaxDistance = 125, MaxActive = 4},
}
-- Cache profiles: the existing shared warning renderer runs at 30 Hz.
local REDUCED = {
    Low = {Count = 1, MaxDistance = 65, MaxActive = 2},
    Medium = {Count = 1, MaxDistance = 100, MaxActive = 3},
    High = {Count = 1, MaxDistance = 125, MaxActive = 4},
}

local function finite(v)
    return type(v) == "number" and v == v and math.abs(v) < math.huge
end

function BombChargeRules.profile(tier, reduced)
    local source = reduced == true and REDUCED or BUDGETS
    return source[tostring(tier or "Low")] or source.Low
end

function BombChargeRules.visible(tier, distance, slot)
    local config = BUDGETS[tostring(tier or "Low")] or BUDGETS.Low
    return finite(distance) and distance >= 0 and distance <= config.MaxDistance
        and finite(slot) and slot % 1 == 0
        and slot >= 1 and slot <= config.MaxActive
end

-- When Bomb Rain overlaps with Double Chaos, rendering depends on camera
-- proximity rather than Lua table iteration order. This keeps the nearest
-- bomb silhouettes available to players with low-end Android GPUs, while
-- distant warnings retain the authoritative ground ring and escape cue.
function BombChargeRules.nearestSlots(tracked, viewerPosition, tier)
    local slots = {}
    if type(tracked) ~= "table" or typeof(viewerPosition) ~= "Vector3" then
        return slots
    end

    local config = BUDGETS[tostring(tier or "Low")] or BUDGETS.Low
    local eligible = {}
    for warning, state in pairs(tracked) do
        if typeof(warning) == "Instance" and warning:IsA("BasePart")
            and warning.Name == "BombWarning" and warning.Parent == workspace
            and type(state) == "table" and state.kind == "Bomb" then
            local distance = (viewerPosition - warning.Position).Magnitude
            if finite(distance) and distance <= config.MaxDistance then
                eligible[#eligible + 1] = {warning = warning, distance = distance}
            end
        end
    end

    table.sort(eligible, function(a, b)
        return a.distance < b.distance
    end)
    for slot = 1, math.min(config.MaxActive, #eligible) do
        slots[eligible[slot].warning] = slot
    end
    return slots
end

-- Pieces share a rotating local body frame, but the motion stops entirely
-- under ReduceMotion. Low-tier keeps one dark, recognizable spherical charge.
function BombChargeRules.recipe(index, count, progress, reduced)
    if not finite(index) or index % 1 ~= 0
        or not finite(count) or count % 1 ~= 0
        or count < 1 or count > 5 or index < 1 or index > count
        or not finite(progress) then
        return nil
    end

    local alpha = math.clamp(progress, 0, 1)
    local motion = reduced == true and 0 or alpha
    local altitude = reduced == true and 2.3
        or (0.92 + 6.2 * (1 - alpha) ^ 1.35)
    local frame = CFrame.new(0, altitude, 0)
        * CFrame.Angles(math.rad(-16) * motion, motion * math.pi * 2.2, 0)
    local part = {
        Shape = "Block",
        Material = Enum.Material.Metal,
        Color = Color3.fromRGB(89, 97, 112),
        Transparency = 0.04,
    }

    if index == 1 then
        part.Shape = "Ball"
        part.Size = Vector3.new(2.15, 2.15, 2.15)
        -- A single armored core now owns the complete falling silhouette.
        -- Heat rises visibly as the server countdown approaches detonation;
        -- no extra Part, particle emitter, flash or render loop is allocated.
        part.Color = Color3.fromRGB(85, 48, 59):Lerp(
            Color3.fromRGB(205, 67, 55), reduced == true and 0.35 or alpha * 0.67
        )
        part.Transform = frame
    elseif index <= 3 then
        local side = index == 2 and -1 or 1
        part.Shape = "Wedge"
        part.Color = index == 2 and Color3.fromRGB(170, 68, 68)
            or Color3.fromRGB(68, 75, 89)
        part.Size = Vector3.new(0.34, 1.22, 1.12)
        part.Transform = frame * CFrame.new(side * 1.04, -0.16, 0)
            * CFrame.Angles(0, side * math.rad(24), side * math.rad(26))
    elseif index == 4 then
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 71, 53)
        -- The fissure grows brighter (lower transparency) as impact nears.
        part.Transparency = reduced == true and 0.28
            or (0.41 - 0.30 * alpha)
        part.Size = Vector3.new(0.19, 1.43, 0.22)
        part.Transform = frame * CFrame.new(0, 0, -1.09)
    else
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 172, 99):Lerp(
            Color3.fromRGB(255, 242, 183), reduced == true and 0.35 or alpha
        )
        part.Size = Vector3.new(0.34, 0.34, 0.34)
        part.Transform = frame * CFrame.new(0, 1.13, 0)
    end

    return part
end

return BombChargeRules
