local DisasterClimax = {}

DisasterClimax.StageThresholds = {
    Surge = 0.98,
    Critical = 1.06,
}

DisasterClimax.Profiles = {
    RisingLava = {Kind="lava", Color=Color3.fromRGB(255,85,20), Secondary=Color3.fromRGB(255,215,75)},
    Meteors = {Kind="meteor", Color=Color3.fromRGB(255,120,45), Secondary=Color3.fromRGB(255,225,130)},
    LowGravity = {Kind="gravity", Color=Color3.fromRGB(105,130,255), Secondary=Color3.fromRGB(210,225,255)},
    DisappearingPlatforms = {Kind="fracture", Color=Color3.fromRGB(255,205,65), Secondary=Color3.fromRGB(255,240,150)},
    Tornado = {Kind="tornado", Color=Color3.fromRGB(75,205,215), Secondary=Color3.fromRGB(190,245,245)},
    Freeze = {Kind="freeze", Color=Color3.fromRGB(80,190,255), Secondary=Color3.fromRGB(205,245,255)},
    Bombs = {Kind="bomb", Color=Color3.fromRGB(255,60,60), Secondary=Color3.fromRGB(255,155,95)},
    SpeedSurge = {Kind="speed", Color=Color3.fromRGB(245,80,205), Secondary=Color3.fromRGB(255,195,245)},
    Darkness = {Kind="darkness", Color=Color3.fromRGB(100,90,205), Secondary=Color3.fromRGB(195,180,255)},
    ShrinkingArena = {Kind="shrink", Color=Color3.fromRGB(185,75,240), Secondary=Color3.fromRGB(245,175,255)},
    JumpShock = {Kind="shock", Color=Color3.fromRGB(80,155,255), Secondary=Color3.fromRGB(190,225,255)},
}

function DisasterClimax.stageFor(intensity, finalRush, overdrive)
    if finalRush == true then
        return 3
    end

    local value = tonumber(intensity) or 0
    if overdrive == true then
        return math.max(
            2,
            value >= DisasterClimax.StageThresholds.Critical and 2 or 1
        )
    end

    if value >= DisasterClimax.StageThresholds.Critical then
        return 2
    elseif value >= DisasterClimax.StageThresholds.Surge then
        return 1
    end
    return 0
end

-- Reject delayed cosmetic bursts from obsolete intensity stages, maps
-- or rounds, even if their scheduled callback was already queued.
function DisasterClimax.shouldPresent(requestToken, activeToken,
        requestedStage, latestStage, sameArena, inRound, eliminated)
    return requestToken == activeToken and requestedStage == latestStage
        and sameArena == true and inRound == true and eliminated ~= true
end

-- Reconcile a full authoritative RoundState disaster list. Removed hazards
-- lose their displayed stage, and their generation advances so a queued
-- callback cannot fire if the same hazard is removed and then re-added.
-- Generations remain bounded to the eleven known disaster identifiers.
function DisasterClimax.pruneInactive(stageById, generationById, ids)
    local active = {}
    if type(ids) == "table" then
        for _, id in ipairs(ids) do
            if type(id) == "string" and DisasterClimax.Profiles[id] then
                active[id] = true
            end
        end
    end
    for id in pairs(stageById) do
        if not active[id] then
            stageById[id] = nil
            generationById[id] = (generationById[id] or 0) + 1
        end
    end
end

-- Three bounded retries for arena Base arriving after RoundState.
local REPLICATION_RETRY_SECONDS = {0.15, 0.35, 0.70}

function DisasterClimax.replicationRetryDelay(attempt)
    if type(attempt) ~= "number" or attempt % 1 ~= 0 then
        return nil
    end
    return REPLICATION_RETRY_SECONDS[attempt]
end

-- A Double Chaos cinematic combines multiple purely decorative bursts.
-- Keep two different signatures legible without doubling the High-tier
-- transient meshes. Server warnings/impacts are not part of this budget.
function DisasterClimax.burstTier(requestedTier, simultaneousCount)
    local tier = requestedTier == "Low" and "Low"
        or requestedTier == "Medium" and "Medium" or "High"
    local count = math.max(0, tonumber(simultaneousCount) or 0)
    if count < 2 then return tier end
    if count >= 3 then return "Low" end
    return tier == "High" and "Medium" or tier
end

-- Bound one snapshot's simultaneous cinematic owners. Only recognized,
-- distinct disaster IDs can consume a cosmetic slot. Every authoritative
-- warning continues to render independently of this selection.
function DisasterClimax.burstIds(ids)
    local selected = {}
    local seen = {}
    if type(ids) ~= "table" then return selected end
    for _, id in ipairs(ids) do
        if type(id) == "string" and DisasterClimax.Profiles[id]
            and not seen[id] then
            table.insert(selected, id)
            seen[id] = true
            if #selected >= 2 then break end
        end
    end
    return selected
end

-- The transient climax folder is a separate budget from all critical
-- warning/VFX owners. All eleven climax kits share this 2/4/6/1 geometry cap.
function DisasterClimax.burstPieceCount(tier, reduced)
    if tier ~= "High" and tier ~= "Medium" and tier ~= "Low" then
        return 0
    end
    if reduced == true then return 1 end
    if tier == "High" then return 6 end
    if tier == "Medium" then return 4 end
    return 2
end

function DisasterClimax.burstPartLimit(requestedTier, simultaneousCount, reduced)
    local tier = DisasterClimax.burstTier(requestedTier, simultaneousCount)
    local count = math.max(1, math.floor(tonumber(simultaneousCount) or 1))
    return DisasterClimax.burstPieceCount(tier, reduced) * math.min(2, count)
end

-- Number of oldest cosmetic parts to evict before adding the incoming
-- signature. Keeps the total across *successive* snapshots under budget.
function DisasterClimax.burstEvictions(existing, incoming, limit)
    local before = math.max(0, math.floor(tonumber(existing) or 0))
    local newParts = math.max(0, math.floor(tonumber(incoming) or 0))
    local cap = math.max(0, math.floor(tonumber(limit) or 0))
    return math.max(0, before + newParts - cap)
end

function DisasterClimax.get(id)
    return DisasterClimax.Profiles[id]
end

return DisasterClimax
