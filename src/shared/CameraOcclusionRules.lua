-- Pure, bounded camera-to-avatar proximity test. Never changes gameplay,
-- camera zoom, character physics or server-visible transparency.
local CameraOcclusionRules = {}

function CameraOcclusionRules.avatarOcclusion(cameraPosition, focusPosition, blockerPosition)
    if typeof(cameraPosition) ~= "Vector3"
        or typeof(focusPosition) ~= "Vector3"
        or typeof(blockerPosition) ~= "Vector3" then
        return nil
    end
    local axis = focusPosition - cameraPosition
    local lengthSquared = axis:Dot(axis)
    -- First-person zoom, far spectator cameras and cutscenes are excluded.
    if lengthSquared < 16 or lengthSquared > 32 * 32 then
        return nil
    end
    local toBlocker = blockerPosition - cameraPosition
    local blockerDistanceSquared = toBlocker:Dot(toBlocker)
    if blockerDistanceSquared > 11 * 11 then
        return nil
    end

    local along = toBlocker:Dot(axis) / lengthSquared
    -- A player next to the local avatar, behind the camera, or behind
    -- the subject is not a camera occluder. This only acts on the segment.
    -- A body almost touching the lens can already cover the screen;
    -- do not require it to be 10% along the full camera-to-player line.
    if along < 0 or along > 0.88 then
        return nil
    end
    local perpendicular = (blockerPosition - (cameraPosition + axis * along)).Magnitude
    if perpendicular > 3.1 then
        return nil
    end

    -- Prefer the actual visual blocker, not the first player in iteration
    -- order. A maximum of one avatar is softened at any given time.
    return perpendicular + math.sqrt(blockerDistanceSquared) * 0.06
end

function CameraOcclusionRules.localModifier()
    -- Other survivors remain visible and recognizable even when their
    -- character briefly blocks most of the third-person camera.
    return 0.66
end

return CameraOcclusionRules
