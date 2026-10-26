-- Pure, bounded camera-to-avatar proximity test. Never changes gameplay,
-- camera zoom, character physics or server-visible transparency.
local CameraOcclusionRules = {}

-- Scope the structural sightline cast to the authoritative arena only.
-- A human or AI avatar in front of a pillar must not swallow the raycast
-- before the pillar gets a chance to fade. Remote survivors have a separate
-- bounded transparency owner in mobile-camera-sightline.client.lua.
-- Unlike a blacklist of current characters, this survives late replication
-- and new bot spawns without rebuilding filtering every 180 ms.
function CameraOcclusionRules.arenaRaycastParams(arena, base)
    if typeof(arena) ~= "Instance" then return nil end
    -- Preserve the original walkable-base exclusion. Include its sibling
    -- supports/decks instead of the whole arena, so a large floor cannot
    -- swallow the ray before an actual vertical sightline blocker is seen.
    local candidates = {}
    local platforms = arena:FindFirstChild("Platforms")
    for _, child in ipairs(arena:GetChildren()) do
        -- Cosmetic scenery, spawn markers and moving mechanics cannot be
        -- valid structural fade targets. They must not swallow a raycast
        -- aimed at an opaque support behind them.
        if child ~= base and child ~= platforms
            and child.Name ~= "Decor"
            and child.Name ~= "Spawns"
            and child.Name ~= "EntryGuides"
            and child.Name ~= "Mechanics"
            -- Orbital's physical Helix/Entry/Core ramps are critical
            -- walkable escape routes, never optional camera blockers.
            and child.Name ~= "HelixCircuit" then
            candidates[#candidates + 1] = child
        end
    end
    -- Ordinary playable platforms must stay fully visible, including
    -- temporary disappearing floors and perimeter jump routes. Only
    -- explicitly designated skybridges are eligible for camera softening.
    -- At most one immediate-child scan per camera sample; no extra rays.
    if platforms then
        for _, child in ipairs(platforms:GetChildren()) do
            if child:IsA("BasePart")
                and child:GetAttribute("ChaosSkybridge") == true then
                candidates[#candidates + 1] = child
            end
        end
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = candidates
    params.IgnoreWater = true
    return params
end

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

-- Select a bounded number of different visual blockers, nearest to the
-- local player's actual sight line. Stable input-order ties prevent a pair
-- of overlapping avatars from flickering between updates. This operates
-- only on prequalified on-screen candidates, never all workspace parts.
function CameraOcclusionRules.chooseOccluders(candidates, maximum)
    if type(candidates) ~= "table" then
        return {}
    end
    local rawLimit = tonumber(maximum) or 2
    if rawLimit ~= rawLimit or rawLimit == math.huge
        or rawLimit == -math.huge then
        rawLimit = 2
    end
    local limit = math.clamp(math.floor(rawLimit), 0, 2)
    if limit == 0 then return {} end
    local ranked = {}
    for index, entry in ipairs(candidates) do
        if type(entry) == "table" and entry.model ~= nil then
            local score = tonumber(entry.score)
            if score and score == score and math.abs(score) < math.huge then
                ranked[#ranked + 1] = {
                    model = entry.model,
                    score = score,
                    order = index,
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.score == b.score then
            return a.order < b.order
        end
        return a.score < b.score
    end)
    local selected, known = {}, {}
    for _, entry in ipairs(ranked) do
        if not known[entry.model] then
            known[entry.model] = true
            selected[#selected + 1] = entry.model
            if #selected >= limit then break end
        end
    end
    return selected
end

function CameraOcclusionRules.localModifier()
    -- Other survivors remain visible and recognizable even when their
    -- character briefly blocks most of the third-person camera.
    return 0.66
end

return CameraOcclusionRules
