-- Keep AI survivor nameplates readable without obscuring Android gameplay.
-- No new 3D instances or per-frame listeners; the client applies these
-- values only when its phase/quality changes or a rig streams into view.
local BotNameplateRules = {}

function BotNameplateRules.presentation(phase, tier, touch)
    local emphasize = phase == "ready" or phase == "intermission"
        or phase == "result"
    local distance = emphasize and 96 or 72

    -- Android has a shorter visual lane than desktop. Show only nearby
    -- opponents during survival; do not paint ghost names through walls
    -- over the hazards and real-player thumb controls.
    if touch == true then
        if tier == "Low" then
            distance = emphasize and 58 or 42
        else
            distance = emphasize and 72 or 54
        end
    end

    return {
        AlwaysOnTop = emphasize and touch ~= true,
        MaxDistance = distance,
        StrokeTransparency = emphasize and 0.24 or 0.38,
    }
end

return BotNameplateRules
