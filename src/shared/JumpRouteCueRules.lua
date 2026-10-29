-- Deterministic, conservative parkour wayfinding from physical decks.
-- Never turns an unverified island into a suggested jump. These rules
-- create no forces, collision, network traffic or reward advantage.
local JumpRouteCueRules = {}

JumpRouteCueRules.MaxGap = 3.85
JumpRouteCueRules.MaxRise = 4.05

local function deckTier(part)
    if not part or not part:IsA("BasePart")
        or not part.Name:match("^Platform%d+$") then
        return nil
    end
    local n = part:GetAttribute("RouteTier")
    if type(n) == "number" and n % 1 == 0 and n >= 1 and n <= 4 then
        return n
    end
    return nil
end

function JumpRouteCueRules.gap(from, target)
    if not from or not target
        or not from:IsA("BasePart") or not target:IsA("BasePart") then
        return nil
    end
    local dx = math.max(0, math.abs(target.Position.X - from.Position.X)
        - (from.Size.X + target.Size.X) * 0.5)
    local dz = math.max(0, math.abs(target.Position.Z - from.Position.Z)
        - (from.Size.Z + target.Size.Z) * 0.5)
    return math.sqrt(dx * dx + dz * dz)
end

function JumpRouteCueRules.select(from, orderedPlatforms, arenaCenter, variantId)
    -- Orbital's upper ascent uses real helical ramps, not an airborne jump.
    if variantId == "Orbital" or typeof(arenaCenter) ~= "Vector3" then
        return nil
    end
    local tier = deckTier(from)
    if not tier or tier == 4 or type(orderedPlatforms) ~= "table" then
        return nil
    end

    local offset = from.Position - arenaCenter
    local centerRadius = Vector3.new(offset.X, 0, offset.Z).Magnitude
    local hub = tier == 1 and centerRadius < 4
    local fromTop = from.Position.Y + from.Size.Y * 0.5
    local best, bestScore = nil, math.huge

    for _, target in ipairs(orderedPlatforms) do
        local targetTier = deckTier(target)
        if target ~= from and target.Parent == from.Parent
            and targetTier
            and (targetTier == tier + 1 or (hub and targetTier == tier))
        then
            local rise = target.Position.Y + target.Size.Y * 0.5 - fromTop
            local gap = JumpRouteCueRules.gap(from, target)
            local delta = target.Position - from.Position
            local horizontalDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude

            -- Adjacent top surfaces must have a real takeoff gap. Overlap
            -- would mean a low overhead roof, not a jumpable ascending lane.
            -- The one exception is a level hub-to-entry move, with no
            -- overhead clearance problem, only when its deck is outward.
            local sameTierHub = hub and targetTier == tier
                and rise >= -0.05 and rise <= JumpRouteCueRules.MaxRise
                and Vector3.new(target.Position.X - arenaCenter.X, 0,
                    target.Position.Z - arenaCenter.Z).Magnitude > centerRadius + 4
            local ascent = targetTier == tier + 1
                and rise >= 0.5 and rise <= JumpRouteCueRules.MaxRise

            if (sameTierHub or ascent) and gap
                and gap > 0.15 and gap <= JumpRouteCueRules.MaxGap
                and horizontalDistance >= 5
            then
                local score = gap + horizontalDistance * 0.08
                    + math.max(0, rise) * 0.18
                if score < bestScore then
                    best = target
                    bestScore = score
                end
            end
        end
    end
    return best
end

-- Position the sign INSIDE the supporting collision footprint, never
-- overhanging the edge as a ghost piece during Shrinking Arena.
function JumpRouteCueRules.takeoffFrame(from, target, paintOffset)
    if not from or not target
        or not from:IsA("BasePart") or not target:IsA("BasePart") then
        return nil
    end
    local delta = target.Position - from.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    if horizontal.Magnitude < 0.01 then return nil end

    local dir = from.CFrame:VectorToObjectSpace(horizontal.Unit)
    local border = math.min(
        (from.Size.X * 0.5) / math.max(0.0001, math.abs(dir.X)),
        (from.Size.Z * 0.5) / math.max(0.0001, math.abs(dir.Z))
    )
    local distance = math.max(0, border - 1.5)
    local face = from.CFrame * CFrame.new(
        dir.X * distance,
        tonumber(paintOffset) or (from.Size.Y * 0.5 + 0.16),
        dir.Z * distance
    )
    return CFrame.lookAt(face.Position, face.Position + horizontal.Unit,
        from.CFrame.UpVector)
end


-- First-session in-world guidance follows ONLY actual server-created,
-- physically jumpable decks. The source is a raycast against collidable
-- platforms, not a guessed screen-space waypoint. Never suggest a route
-- into a disabled/disappearing platform, or across an impossible jump.
local function walkable(part)
    return part ~= nil and part:IsA("BasePart")
        and part.Name:match("^Platform%d+$") ~= nil
        and part.Anchored and part.CanCollide
        and part.Transparency < 0.75
end

-- A yellow collapse warning is already a bad landing choice while
-- its server-owned CanCollide is still true. Do not direct newcomers to
-- the doomed target; a player standing on a warning deck may still be
-- guided OUT to a safe successor.
function JumpRouteCueRules.safeLandingTarget(part)
    if not walkable(part) then return false end
    local phase = part:GetAttribute("CollapsePhase")
    return phase ~= "Warning" and phase ~= "Gone"
end

function JumpRouteCueRules.jumpable(from, target)
    if not walkable(from) or not JumpRouteCueRules.safeLandingTarget(target)
        or from == target or from.Parent ~= target.Parent then
        return false
    end
    local gap = JumpRouteCueRules.gap(from, target)
    local rise = (target.Position.Y + target.Size.Y * 0.5)
        - (from.Position.Y + from.Size.Y * 0.5)
    return gap ~= nil
        and gap > 0.15 and gap <= JumpRouteCueRules.MaxGap
        and rise >= 0.4 and rise <= JumpRouteCueRules.MaxRise
end

-- On the arena floor, lead a rookie toward a REAL low, grounded
-- takeoff deck. Only first-tier original/perimeter entries are eligible;
-- never point toward a floating roof, a side-branch shortcut or a hidden
-- platform. Position is the actual floor raycast hit, not the camera.
function JumpRouteCueRules.nearestEntry(orderedPlatforms, floorPoint, maxRange)
    if type(orderedPlatforms) ~= "table"
        or typeof(floorPoint) ~= "Vector3" then
        return nil
    end
    local range = math.clamp(tonumber(maxRange) or 42, 8, 48)
    local closest, bestDistance = nil, math.huge
    for _, part in ipairs(orderedPlatforms) do
        if JumpRouteCueRules.safeLandingTarget(part)
            and part:GetAttribute("RouteTier") == 1
            and part:GetAttribute("BranchRoute") == nil
            and (part:GetAttribute("PerimeterRoute") == nil
                or part:GetAttribute("PerimeterStep") == 1) then
            local top = part.Position.Y + part.Size.Y * 0.5
            local rise = top - floorPoint.Y
            local delta = part.Position - floorPoint
            local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
            if rise >= 1.5 and rise <= 5.2
                and distance <= range and distance < bestDistance then
                closest, bestDistance = part, distance
            end
        end
    end
    return closest
end

-- Original central routes use conservative spatial selection. Perimeter
-- and side-lookout steps have explicit server-authored route/step IDs;
-- using those IDs avoids directing a novice across unrelated adjacent
-- towers. The last step is a genuine end point, never a phantom jump.
function JumpRouteCueRules.nextPhysical(from, orderedPlatforms, arenaCenter, variantId)
    if not walkable(from) or type(orderedPlatforms) ~= "table" then
        return nil
    end

    local route = from:GetAttribute("PerimeterRoute")
    local step = from:GetAttribute("PerimeterStep")
    local branch = from:GetAttribute("BranchRoute")
    local branchStep = from:GetAttribute("BranchStep")

    if route ~= nil or branch ~= nil then
        local routeId = route or branch
        local index = route ~= nil and step or branchStep
        local last = route ~= nil and 8 or 4
        if type(routeId) ~= "number" or routeId % 1 ~= 0
            or routeId < 1 or routeId > 4
            or type(index) ~= "number" or index % 1 ~= 0
            or index < 1 or index >= last then
            return nil
        end

        for _, candidate in ipairs(orderedPlatforms) do
            if candidate ~= from and candidate:IsA("BasePart")
                and candidate:GetAttribute(
                    route ~= nil and "PerimeterRoute" or "BranchRoute"
                ) == routeId
                and candidate:GetAttribute(
                    route ~= nil and "PerimeterStep" or "BranchStep"
                ) == index + 1
                and JumpRouteCueRules.jumpable(from, candidate) then
                return candidate
            end
        end
        return nil
    end

    local target = JumpRouteCueRules.select(
        from, orderedPlatforms, arenaCenter, variantId
    )
    if target and JumpRouteCueRules.jumpable(from, target) then
        return target
    end
    return nil
end

return JumpRouteCueRules
