-- Keep AI survivor nameplates readable without obscuring Android gameplay.
-- No new 3D instances or per-frame listeners; the client applies these
-- values only when its phase/quality changes or a rig streams into view.
local BotNameplateRules = {}

function BotNameplateRules.presentation(phase, tier, touch)
    local emphasize = phase == "ready" or phase == "intermission"
        or phase == "result"
    local distance = emphasize and 96 or 72

    -- On low-end touch screens, labels far across the arena form visual
    -- clutter and overdraw. Keep nearby players recognizable.
    if touch == true and tier == "Low" then
        distance = emphasize and 78 or 58
    end

    return {
        AlwaysOnTop = emphasize,
        MaxDistance = distance,
        StrokeTransparency = emphasize and 0.24 or 0.38,
    }
end

return BotNameplateRules
