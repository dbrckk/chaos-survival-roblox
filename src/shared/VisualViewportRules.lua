-- Pure viewport bounds for optional character ribbons and footwork VFX.
-- Camera projection is performed by the client; no raycasts or allocations.
local VisualViewportRules = {}

function VisualViewportRules.contains(x, y, depth, width, height, wasVisible)
    local w, h = tonumber(width), tonumber(height)
    -- Some clients initially have a zero-sized viewport. Preserve existing
    -- distance and quality gates until projection data becomes available.
    if not w or not h or w <= 0 or h <= 0 then return true end
    local px, py, z = tonumber(x), tonumber(y), tonumber(depth)
    if not px or not py or not z or z <= 0 then return false end
    local margin = wasVisible == true and 0.18 or 0.10
    return px >= -w * margin and px <= w * (1 + margin)
        and py >= -h * margin and py <= h * (1 + margin)
end

return VisualViewportRules
