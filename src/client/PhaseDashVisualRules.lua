-- Distinct, low-instance Phase Dash shockwave silhouettes.
-- Per-facet geometry replaces uniform neon-circle dimensions without
-- increasing 5/7/10-part per-ring device budgets.
local Rules = {}

-- Pure distance policy: no remote dash LOD for local/invalid/offscreen targets.
function Rules.isDistantRemote(isLocal, distance)
    return isLocal == false and type(distance) == "number"
        and distance == distance and distance >= 72 and distance <= 110
end

function Rules.count(tier, reducedMotion, distant)
    -- Close-up signatures keep the authored full-detail silhouettes.
    -- Accessibility and distant non-local avatars share conservative caps.
    if reducedMotion == true or distant == true then
        if tier == "High" then return 5 end
        if tier == "Medium" then return 4 end
        if tier == "Low" then return 3 end
        return 0
    end
    if tier == "High" then return 10 end
    if tier == "Medium" then return 7 end
    if tier == "Low" then return 5 end
    return 0
end

function Rules.facet(tier, index, secondary, reducedMotion, distant)
    local count = Rules.count(tier, reducedMotion, distant)
    if count == 0 or type(index) ~= "number" or index ~= index
        or math.abs(index) == math.huge or index % 1 ~= 0
        or index < 1 or index > count then
        return nil
    end
    local angle = (index - 1) / count * math.pi * 2
    local wing = math.abs(math.sin(angle))
    local nose = math.cos(angle)
    local alternating = index % 2 == 0 and -1 or 1
    local accent = secondary == true
    return {
        Angle = angle,
        Count = count,
        StartScale = 1 + 0.035 * wing,
        -- Forward-biased pressure blades and shorter trailing segments.
        EndScale = (accent and 0.90 or 1)
            + 0.11 * wing + 0.07 * nose,
        ChordScale = (accent and 0.76 or 0.89)
            + 0.065 * wing,
        Thickness = accent and 0.14 or 0.17,
        Height = accent and 0.075 or (0.09 + 0.014 * wing),
        Bank = math.rad(alternating * (accent and 13 or 8)),
        Alpha = accent and 0.43 or (0.27 + wing * 0.06),
    }
end

return Rules
