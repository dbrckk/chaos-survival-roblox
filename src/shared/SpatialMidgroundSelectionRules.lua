-- Pure, deterministic placement of existing source-verified outboard
-- MeshPart silhouettes. No assets, Roblox Instances, network or loops.
-- Called only by the pre-existing 0.90-second scenery LOD sampler.
local Rules = {}

local function native(candidate)
    return candidate and (candidate.body or candidate.hull)
end

function Rules.choose(candidates, budget)
    local result = {}
    if type(candidates) ~= "table" then return result end
    local capacity = math.min(#candidates,
        math.max(0, math.floor(tonumber(budget) or 0)))
    local chosen = {}

    for _ = 1, capacity do
        local best, bestRank = nil, math.huge
        for _, candidate in ipairs(candidates) do
            local part = native(candidate)
            local position = part and part.Position
            local score = tonumber(candidate.score)
            if part and not result[part]
                and typeof(position) == "Vector3"
                and score and score == score
                and math.abs(score) ~= math.huge then
                local rank = score
                if #chosen > 0 then
                    local separation = math.huge
                    for _, previous in ipairs(chosen) do
                        local delta = position - previous.Position
                        local horizontal = Vector3.new(
                            delta.X, 0, delta.Z).Magnitude
                        separation = math.min(separation, horizontal)
                    end
                    -- The FIRST silhouette remains the closest, visibly
                    -- useful model. Subsequent SAME-budget slots spread
                    -- across actual outboard quadrants where possible.
                    -- Bounded bonus cannot defeat hard camera distance,
                    -- tier, quality-pressure or source-provenance gates.
                    rank -= math.min(90, separation * 0.24)
                end
                if not best or rank < bestRank
                    or (rank == bestRank
                        and (candidate.index or math.huge)
                            < (best.index or math.huge)) then
                    best, bestRank = candidate, rank
                end
            end
        end
        if not best then break end
        local part = native(best)
        result[part] = best
        chosen[#chosen + 1] = part
    end

    return result
end

return Rules
