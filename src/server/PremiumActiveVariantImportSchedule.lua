-- Optional original 3D signature art may be loaded earlier for the
-- currently displayed variant, without front-loading all five worlds.
-- IMPORTANT: use inside the existing delayed task.spawn, never while
-- constructing the map or initializing the first playable round.
local Schedule = {}

function Schedule.waitFor(variant, earlySeconds, fallbackSeconds)
    assert(type(variant)=="string" and variant~="")
    assert(type(earlySeconds)=="number" and earlySeconds>0)
    assert(type(fallbackSeconds)=="number"
        and fallbackSeconds>=earlySeconds)

    -- Wait for essential Roblox startup and the map to become available.
    task.wait(earlySeconds)

    local generated=workspace:FindFirstChild("GeneratedMap")
    local arena=generated and generated:FindFirstChild("Arena")
    local isActive=arena and arena:IsA("Folder")
        and arena.Parent==generated
        and arena:GetAttribute("VariantId")==variant

    if isActive then return true end

    -- Inactive sources keep their original delayed first-import budget.
    -- Do not poll the arena or add another per-frame / network job.
    task.wait(fallbackSeconds-earlySeconds)
    return false
end

return Schedule
