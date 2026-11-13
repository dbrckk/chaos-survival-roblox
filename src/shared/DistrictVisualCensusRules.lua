--!strict
-- Pure, budget-free 16-building census for the currently streamed arena.
-- Bits come from ACTUALLY mounted creator-approved facade and sidewall
-- MeshParts, never from static MapBuilder primitive totals or fake models.
-- N means no approved 3D on a STREAMED building, not necessarily drawn;
-- - means that the server building is not currently replicated to client.
local Rules = {}
local FULL16 = 65535

local function bounded(mask)
    if type(mask) ~= "number" or mask ~= mask then return 0 end
    return bit32.band(math.floor(mask), FULL16)
end

function Rules.summarize(loadedMask, facadeMask, sidewallMask)
    local loaded = bounded(loadedMask)
    local fronts = bit32.band(loaded, bounded(facadeMask))
    local sides = bit32.band(loaded, bounded(sidewallMask))
    local state = table.create(16)
    local totals = {
        loaded = 0, unstreamed = 0, complete = 0,
        facadeOnly = 0, sidewallOnly = 0, nativeOnly = 0,
    }
    for index = 1, 16 do
        local bit = bit32.lshift(1, index - 1)
        if bit32.band(loaded, bit) == 0 then
            state[index] = "-"
            totals.unstreamed += 1
        else
            totals.loaded += 1
            local facade = bit32.band(fronts, bit) ~= 0
            local sidewall = bit32.band(sides, bit) ~= 0
            if facade and sidewall then
                state[index] = "B"
                totals.complete += 1
            elseif facade then
                state[index] = "F"
                totals.facadeOnly += 1
            elseif sidewall then
                state[index] = "S"
                totals.sidewallOnly += 1
            else
                state[index] = "N"
                totals.nativeOnly += 1
            end
        end
    end
    totals.states = table.concat(state)
    return totals
end

return Rules
