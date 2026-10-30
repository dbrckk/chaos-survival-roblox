-- A tiny read-only spatial model for Storm Harbor's server-owned
-- crane sweeps. No collision, rewards or timing decisions originate here:
-- only the actual replicated lane phase, dimensions, timestamps and
-- the player's current position are used for the local warning.
local HarborSweepGuidance = {}

local function finite(value)
    return type(value) == "number"
        and value == value
        and value < math.huge
        and value > -math.huge
end

local function phaseTime(band, phase, now)
    local start = band:GetAttribute(
        phase == "Pulse" and "HarborSweepPulseAt"
            or "HarborSweepWarningAt"
    )
    local duration = band:GetAttribute(
        phase == "Pulse" and "HarborSweepPulseSeconds"
            or "HarborSweepWarningSeconds"
    )
    if not finite(start) or not finite(duration)
        or duration <= 0 or duration > 10 then
        return nil
    end
    local remaining = start + duration - now
    if remaining <= 0 or remaining > duration + 0.4 then
        return nil
    end
    return remaining
end

local function exitSign(coordinate, centerCoordinate)
    if coordinate > 0.05 then return 1 end
    if coordinate < -0.05 then return -1 end
    -- Standing at the exact midpoint: choose the edge toward the SAFE
    -- arena centre rather than an arbitrary outward direction.
    return centerCoordinate >= 0 and 1 or -1
end

function HarborSweepGuidance.read(band, playerPosition, arenaCenter, serverNow)
    if not band or not band:IsA("BasePart")
        or not band.Parent
        or typeof(playerPosition) ~= "Vector3"
        or typeof(arenaCenter) ~= "Vector3"
        or not finite(serverNow) then
        return nil
    end

    local phase = band:GetAttribute("HarborSweepPhase")
    if phase ~= "Warning" and phase ~= "Pulse" then
        return nil
    end
    local remaining = phaseTime(band, phase, serverNow)
    if not remaining then return nil end

    local localPoint = band.CFrame:PointToObjectSpace(playerPosition)
    -- The server pulse affects only the low floor corridor, up to
    -- root height 5.1. Above it, parkour players are deliberately safe.
    if localPoint.Y < 0.5 or localPoint.Y > 5.1 then
        return nil
    end

    local halfX, halfZ = band.Size.X * 0.5, band.Size.Z * 0.5
    local distanceX = math.abs(localPoint.X) - halfX
    local distanceZ = math.abs(localPoint.Z) - halfZ
    local outside = math.max(0, distanceX, distanceZ)
    if outside > 4 then return nil end

    local centerLocal = band.CFrame:PointToObjectSpace(arenaCenter)
    local toX = halfX - math.abs(localPoint.X)
    local toZ = halfZ - math.abs(localPoint.Z)
    local localDirection
    if toX <= toZ then
        localDirection = Vector3.new(
            exitSign(localPoint.X, centerLocal.X), 0, 0
        )
    else
        localDirection = Vector3.new(
            0, 0, exitSign(localPoint.Z, centerLocal.Z)
        )
    end

    local direction = band.CFrame:VectorToWorldSpace(localDirection)
    direction = Vector3.new(direction.X, 0, direction.Z)
    if direction.Magnitude < 0.2 then return nil end
    direction = direction.Unit

    return {
        phase = phase,
        remaining = remaining,
        direction = direction,
        outside = outside,
        inside = distanceX <= 0 and distanceZ <= 0,
        position = band.Position,
    }
end

function HarborSweepGuidance.select(folder, playerPosition, arenaCenter, serverNow)
    if not folder or not folder:IsA("Folder") then return nil end
    local best, bestPriority
    -- Only the four real bands, not their 3D BillboardGui warning labels.
    for _, band in ipairs(folder:GetChildren()) do
        if band:IsA("BasePart")
            and band:GetAttribute("HarborSweepIndex") ~= nil then
            local candidate = HarborSweepGuidance.read(
                band, playerPosition, arenaCenter, serverNow
            )
            if candidate then
                -- Active pulse > amber warning; physically inside >
                -- outside the strip. Overlapping port bands cannot
                -- generate multiple contradictory phone instructions.
                local priority = (candidate.phase == "Pulse" and 0 or 10)
                    + (candidate.inside and 0 or 3)
                    + candidate.outside
                    + candidate.remaining * 0.01
                if not bestPriority or priority < bestPriority then
                    best, bestPriority = candidate, priority
                end
            end
        end
    end
    return best
end

return HarborSweepGuidance
