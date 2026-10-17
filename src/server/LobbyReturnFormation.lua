-- Deterministic non-overlapping return locations after a round.
-- Keep the native Roblox SpawnLocation for new joins; use its orientation
-- and flat-floor vicinity only when multiple living contestants return.
local LobbyReturnFormation = {}

local RADIUS = 2.6
local STANDING_HEADROOM = 8
local LOW_SURFACE_CUTOFF = 0.8
local X_OFFSETS = {0, 7, -7, 14, -14, 21, -21, 28, -28}
local Z_OFFSETS = {0, -6.5, 6.5, 13, 19.5, 26}

local function isSafe(position, floor, colliders)
    local localPosition = floor.CFrame:PointToObjectSpace(position)
    if math.abs(localPosition.X) + RADIUS >= floor.Size.X * 0.5
        or math.abs(localPosition.Z) + RADIUS >= floor.Size.Z * 0.5 then
        return false
    end

    local floorTop = floor.Position.Y + floor.Size.Y * 0.5
    for _, part in ipairs(colliders) do
        if part:IsA("BasePart") and part.CanCollide then
            local top = part.Position.Y + part.Size.Y * 0.5
            local bottom = part.Position.Y - part.Size.Y * 0.5
            -- Thin decorative floor panels are safe underneath feet,
            -- but pylons, the raised stage and other solid volumes are not.
            if top > floorTop + LOW_SURFACE_CUTOFF
                and bottom < floorTop + STANDING_HEADROOM then
                local localPart = part.CFrame:PointToObjectSpace(position)
                if math.abs(localPart.X) < part.Size.X * 0.5 + RADIUS
                    and math.abs(localPart.Z) < part.Size.Z * 0.5 + RADIUS then
                    return false
                end
            end
        end
    end
    return true
end

function LobbyReturnFormation.positions(spawn, floor, decor, count)
    if not spawn or not spawn:IsA("SpawnLocation")
        or not floor or not floor:IsA("BasePart")
        or not decor then
        return {}
    end

    count = math.max(0, math.floor(tonumber(count) or 0))
    if count == 0 then return {} end
    local positions = {}
    local colliders = decor:GetDescendants()
    local right = spawn.CFrame.RightVector
    local forward = spawn.CFrame.LookVector

    for _, z in ipairs(Z_OFFSETS) do
        for _, x in ipairs(X_OFFSETS) do
            local position = spawn.Position + right * x + forward * z
            if isSafe(position, floor, colliders) then
                positions[#positions + 1] = position
                if #positions >= count then
                    return positions
                end
            end
        end
    end

    return positions
end


-- AI survivors use separate flat-floor positions away from both the native
-- first-join pad and the first eight player return slots. The old AI offsets
-- were inside/at the lip of the raised central stage and could embed R15
-- feet or strand a bot immediately after an intermission transition.
local BOT_START_INDEX = 19

function LobbyReturnFormation.botLanding(spawn, floor, decor, slot, hipHeight, rootHalfHeight)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > 3 then return nil end
    local desiredIndex = BOT_START_INDEX + slot - 1
    local positions = LobbyReturnFormation.positions(spawn, floor, decor, desiredIndex)
    -- In case another lobby layout has fewer safe slots, try a nearby
    -- collision-checked position rather than using the raised stage.
    local point = positions[desiredIndex] or positions[slot + 3]
    if not point then return nil end
    local floorTop = floor.Position.Y + floor.Size.Y * 0.5
    local clearance = math.max(3.5,
        (tonumber(hipHeight) or 2) + (tonumber(rootHalfHeight) or 1) + 1.0)
    return CFrame.new(point.X, floorTop + clearance, point.Z)
        * spawn.CFrame.Rotation
end

return LobbyReturnFormation
