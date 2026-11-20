-- Deterministic, conservative parkour wayfinding from physical decks.
-- Never turns an unverified island into a suggested jump. These rules
-- create no forces, collision, network traffic or reward advantage.
local SkyRouteConnectionRules = if script
    then require(script.Parent.SkyRouteConnectionRules)
    else require("./SkyRouteConnectionRules")
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

JumpRouteCueRules.deckTier = deckTier

local function hasStableSurface(part)
    local shutter = part:GetAttribute("BridgeShutterPhase")
    return part.Anchored and part.CanCollide and part.Transparency < .75
        and part:GetAttribute("CollapsePhase") == nil
        and (shutter == nil or shutter == "Idle")
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

function JumpRouteCueRules.select(from, orderedPlatforms, arenaCenter, variantId, isClear, rejected)
    -- An authored rescue crossing leads to branch step 2, whose tier is
    -- lower even though its landing is physically higher. Use the same
    -- route as the in-world guide, including on Orbital's perimeter.
    if deckTier(from) == 4 and from:GetAttribute("CrosslinkRoute") ~= nil then
        if from:GetAttribute("CrosslinkFromPerimeterStep") ~= 6
            or not hasStableSurface(from) then return nil end
        return JumpRouteCueRules.nextPhysical(from, orderedPlatforms, arenaCenter, variantId, nil, isClear)
    end
    -- Orbital's upper ascent uses real helical ramps, not an airborne jump.
    if variantId == "Orbital" or typeof(arenaCenter) ~= "Vector3" then
        return nil
    end
    local tier = deckTier(from)
    if not tier or tier == 4 or type(orderedPlatforms) ~= "table"
        or not from.Parent or not hasStableSurface(from) then
        return nil
    end

    local offset = from.Position - arenaCenter
    local centerRadius = Vector3.new(offset.X, 0, offset.Z).Magnitude
    local hub = tier == 1 and centerRadius < 4
    local fromTop = from.Position.Y + from.Size.Y * 0.5
    local best, bestScore = nil, math.huge

    for _, target in ipairs(orderedPlatforms) do
        local targetTier = deckTier(target)
        if target ~= from and target ~= rejected and target.Parent == from.Parent
            and targetTier and hasStableSurface(target)
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
                if score < bestScore and (not isClear or isClear(from,target)) then
                    best = target
                    bestScore = score
                end
            end
        end
    end
    return best
end

-- A takeoff marker is only truthful while the current physical pair
-- still satisfies the exact same tier/rise/gap limits as the original
-- selection. Shrinking Arena may change either deck's footprint without
-- destroying it: a static, previously valid arrow can become impossible.
-- Re-evaluate just this pair on relevant replication/size changes, not
-- the whole arena and not on RenderStepped.
function JumpRouteCueRules.cueStillSafe(from, target, arenaCenter, variantId)
    if not from or not target
        or not from:IsA("BasePart") or not target:IsA("BasePart")
        or not from.Parent or target.Parent ~= from.Parent then
        return false
    end
    return JumpRouteCueRules.select(
        from, {from, target}, arenaCenter, variantId
    ) == target
end

function JumpRouteCueRules.retarget(from, current, orderedPlatforms, arenaCenter, variantId, isClear)
    if JumpRouteCueRules.cueStillSafe(from,current,arenaCenter,variantId)
        and (not isClear or isClear(from,current)) then
        return current
    end
    return JumpRouteCueRules.select(from,orderedPlatforms,arenaCenter,variantId,isClear,current)
end

-- Position the sign INSIDE the supporting collision footprint, never
-- overhanging the edge as a ghost piece during Shrinking Arena.
function JumpRouteCueRules.takeoffFrame(from, target, paintOffset, edgePadding)
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
    if edgePadding then
        local inside = math.min(
            (from.Size.X*.5-edgePadding)/math.max(.0001,math.abs(dir.X)),
            (from.Size.Z*.5-edgePadding)/math.max(.0001,math.abs(dir.Z))
        )
        distance = math.max(0,math.min(distance,inside))
    end
    local face = from.CFrame * CFrame.new(
        dir.X * distance,
        tonumber(paintOffset) or (from.Size.Y * 0.5 + 0.16),
        dir.Z * distance
    )
    return CFrame.lookAt(face.Position, face.Position + horizontal.Unit,
        from.CFrame.UpVector)
end

function JumpRouteCueRules.takeoffChevron(from, target, paintOffset)
    if not from or not from:IsA("BasePart") then return nil end
    local halfWidth = math.min(from.Size.X,from.Size.Z)*.5
    -- .84 covers the farthest corner of either rotated stroke from the
    -- marker center (.313 center offset + .516 stroke half diagonal).
    local scale = math.min(1,(halfWidth-.12)/.84)
    if scale < .48 then return nil end
    local frame = JumpRouteCueRules.takeoffFrame(from,target,paintOffset,.12+.84*scale)
    if not frame then return nil end
    local tilt = math.rad(38)
    local left = frame*CFrame.new(-.28*scale,0,.14*scale)*CFrame.Angles(0,-tilt,0)
    local right = frame*CFrame.new(.28*scale,0,.14*scale)*CFrame.Angles(0,tilt,0)
    return left,right,Vector3.new(.15*scale,.045,1.02*scale)
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
function JumpRouteCueRules.safeLandingSurface(part)
    if not part or not part:IsA("BasePart") or not part.Parent
        or not part.Anchored or not part.CanCollide or part.Transparency >= 0.75 then
        return false
    end
    local phase = part:GetAttribute("CollapsePhase")
    local shutter = part:GetAttribute("BridgeShutterPhase")
    return phase ~= "Warning" and phase ~= "Gone"
        and (shutter == nil or shutter == "Idle")
end

function JumpRouteCueRules.safeLandingTarget(part)
    return JumpRouteCueRules.safeLandingSurface(part)
        and part.Name:match("^Platform%d+$") ~= nil
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
function JumpRouteCueRules.nearestEntry(orderedPlatforms, floorPoint, maxRange, canApproach)
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
                and distance <= range and distance < bestDistance
                and (not canApproach or canApproach(part)) then
                closest, bestDistance = part, distance
            end
        end
    end
    return closest
end

-- The 320-stud arenas have physically climbable exterior entries
-- more than 48 studs from a fresh spawn. During RisingLava, veterans
-- and beginners alike need a REAL starting point rather than a generic
-- "CLIMB" banner. Extend the range ONLY for this verified emergency.
-- An entry already under water or collapsing is never a refuge.
function JumpRouteCueRules.nearestLavaClimbEntry(
    orderedPlatforms, floorPoint, lava, maxRange, canApproach
)
    if type(orderedPlatforms) ~= "table"
        or typeof(floorPoint) ~= "Vector3" then return nil end
    local range = math.clamp(tonumber(maxRange) or 100, 12, 112)
    local selected, closest = nil, math.huge
    for _, part in ipairs(orderedPlatforms) do
        if JumpRouteCueRules.safeLandingTarget(part)
            and part:GetAttribute("RouteTier") == 1
            and part:GetAttribute("BranchRoute") == nil
            and part:GetAttribute("CrosslinkRoute") == nil
            and (part:GetAttribute("PerimeterRoute") == nil
                or (part:GetAttribute("PerimeterStep") == 1
                    and part:GetAttribute("ChaosPermanentRoute") == true))
            and part.Parent and part.Parent.Name == "Platforms"
            and not JumpRouteCueRules.lavaOnDeck(part, lava) then
            local top = part.Position.Y + part.Size.Y * 0.5
            local rise = top - floorPoint.Y
            local delta = part.Position - floorPoint
            local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
            -- The nearest floor-to-route step is still a native jump,
            -- not a teleport to an arbitrary high deck.
            if rise >= 1.5 and rise <= 5.2
                and distance <= range and distance < closest
                and (not canApproach or canApproach(part)) then
                selected, closest = part, distance
            end
        end
    end
    return selected
end

-- The perimeter has two authored forks. Validate both choices against
-- the same geometry and (when provided) the caller's live hazard filter.
local function perimeterChoices(from, orderedPlatforms, step, isClear)
    if not walkable(from) or type(orderedPlatforms) ~= "table"
        or from:GetAttribute("PerimeterStep") ~= step then return nil, nil end
    local route = from:GetAttribute("PerimeterRoute")
    if type(route) ~= "number" or route % 1 ~= 0
        or route < 1 or route > 4 then return nil, nil end

    local forward, detour
    for _, candidate in ipairs(orderedPlatforms) do
        if candidate == from or not candidate:IsA("BasePart")
            or candidate.Parent ~= from.Parent then continue end
        local isForward = candidate:GetAttribute("PerimeterRoute") == route
            and candidate:GetAttribute("PerimeterStep") == step + 1
        local isDetour = if step == 5
            then candidate:GetAttribute("BranchRoute") == route
                and candidate:GetAttribute("BranchStep") == 1
                and candidate:GetAttribute("BranchParentStep") == 5
            else candidate:GetAttribute("CrosslinkRoute") == route
                and candidate:GetAttribute("CrosslinkFromPerimeterStep") == 6
                and candidate:GetAttribute("CrosslinkToBranchStep") == 2
        if (isForward or isDetour) and JumpRouteCueRules.jumpable(from, candidate)
            and (not isClear or isClear(from, candidate)) then
            if isForward then forward = candidate else detour = candidate end
        end
        if forward and detour then break end
    end
    return forward, detour
end

function JumpRouteCueRules.forkOptions(from, orderedPlatforms, isClear)
    return perimeterChoices(from, orderedPlatforms, 5, isClear)
end

function JumpRouteCueRules.crosslinkOptions(from, orderedPlatforms, isClear)
    return perimeterChoices(from, orderedPlatforms, 6, isClear)
end

function JumpRouteCueRules.isOuterRoute(part)
    return part ~= nil and (part:GetAttribute("PerimeterRoute") ~= nil
        or part:GetAttribute("BranchRoute") ~= nil
        or part:GetAttribute("CrosslinkRoute") ~= nil
        or part:GetAttribute("PromenadeLane") ~= nil
        or part:GetAttribute("SkySpineStep") ~= nil)
end

-- Skill-aware parkour hint: after a veteran stays on the SAME physical
-- deck without travelling, show just one next-step marker. Normal movement,
-- jumping, emergencies and live mastery guidance always take precedence.
-- Pure predicate so client and engine specs agree on the timing contract.
JumpRouteCueRules.RecoverySeconds = 5.2
JumpRouteCueRules.RecoveryTravel = 3.4

-- Jumping in place raises the character root several studs vertically.
-- That is NOT horizontal course progress and must not silently restart the
-- veteran's 5.2-second help timer after every unsuccessful jump attempt.
function JumpRouteCueRules.horizontalProgressDistance(fromPosition, toPosition)
    if typeof(fromPosition) ~= "Vector3"
        or typeof(toPosition) ~= "Vector3" then
        return math.huge
    end
    local dx = toPosition.X - fromPosition.X
    local dz = toPosition.Z - fromPosition.Z
    local distance = math.sqrt(dx * dx + dz * dz)
    return distance == distance and distance < math.huge
        and distance or math.huge
end

function JumpRouteCueRules.recoveryHintReady(elapsed, progressDistance, grounded)
    local time = tonumber(elapsed)
    local distance = tonumber(progressDistance)
    return grounded == true
        and time ~= nil and time == time and time < math.huge
        and time >= JumpRouteCueRules.RecoverySeconds
        and distance ~= nil and distance == distance
        and distance >= 0 and distance <= JumpRouteCueRules.RecoveryTravel
end

-- A "NEXT JUMP" sign must not lure someone onto, or THROUGH, an
-- imminent meteor/bomb footprint. Those warnings are actual server
-- Parts at workspace root; the final impact diameter is authoritative,
-- not the initially small yellow preview. The danger UI owns escapes.
-- No scene queries or client-side hazard guesses; short, bounded math.
-- Geometric slab clipping against the server's oriented, floor-only
-- moving sweep corridors. Reusing their real CFrame/Size and active phase
-- avoids displaying NEXT JUMP inside a timed shock lane. Clip Y too:
-- a legitimate high cargo platform above the pulse stays navigable.
local function clipAxis(start, delta, lower, upper, enter, exit)
    if math.abs(delta) < 0.0001 then
        if start < lower or start > upper then return nil, nil end
        return enter, exit
    end
    local first = (lower - start) / delta
    local last = (upper - start) / delta
    if first > last then first, last = last, first end
    enter = math.max(enter, first)
    exit = math.min(exit, last)
    if enter > exit then return nil, nil end
    return enter, exit
end

function JumpRouteCueRules.activeSweepOnPath(fromPosition, toPosition, band)
    if typeof(fromPosition) ~= "Vector3"
        or typeof(toPosition) ~= "Vector3"
        or typeof(band) ~= "Instance" or not band:IsA("BasePart")
        or band.Parent == nil then
        return false
    end
    local phase = nil
    if band.Name:match("^GridSweepBand%d+$") then
        phase = band:GetAttribute("GridSweepPhase")
    elseif band.Name:match("^HarborSweepLane%d+$") then
        phase = band:GetAttribute("HarborSweepPhase")
    end
    if phase ~= "Warning" and phase ~= "Pulse" then return false end

    local start = band.CFrame:PointToObjectSpace(fromPosition)
    local finish = band.CFrame:PointToObjectSpace(toPosition)
    local travel = finish - start
    local enter, exit = clipAxis(
        start.X, travel.X, -band.Size.X * 0.5 - 1.4,
        band.Size.X * 0.5 + 1.4, 0, 1
    )
    if not enter then return false end
    enter, exit = clipAxis(
        start.Z, travel.Z, -band.Size.Z * 0.5 - 1.4,
        band.Size.Z * 0.5 + 1.4, enter, exit
    )
    if not enter then return false end
    enter, exit = clipAxis(
        start.Y, travel.Y, 0.65, 5.8, enter, exit
    )
    return enter ~= nil
end

-- The actual RisingLava server checks HumanoidRootPart against the
-- replicated RoundLava volume with 2.5 studs of foot clearance.
-- Reuse the SAME geometric threshold for CLIENT-ONLY navigation and the
-- landing reticle: do not draw an inviting teal safe marker in lethal lava.
-- No prediction of future flood rise, extra RemoteEvents or physics changes.
function JumpRouteCueRules.lavaAtRoot(rootPosition, lava)
    if typeof(rootPosition) ~= "Vector3"
        or typeof(lava) ~= "Instance" or not lava:IsA("BasePart")
        or lava.Name ~= "RoundLava" or lava.Parent ~= workspace then
        return false
    end
    local halfX, halfZ = lava.Size.X * 0.5, lava.Size.Z * 0.5
    local topY = lava.Position.Y + lava.Size.Y * 0.5
    return math.abs(rootPosition.X - lava.Position.X) <= halfX
        and math.abs(rootPosition.Z - lava.Position.Z) <= halfZ
        and rootPosition.Y - 2.5 <= topY
end

-- A wayfinding target is a real BasePart, not an avatar. Use the real
-- deck top + the minimum avatar clearance: when lava reaches this deck,
-- even standing on it cannot provide a safe route. Never hide high decks.
function JumpRouteCueRules.lavaOnDeck(deck, lava)
    if typeof(deck) ~= "Instance" or not deck:IsA("BasePart") then
        return false
    end
    local rootAtDeck = deck.Position + Vector3.new(
        0, deck.Size.Y * 0.5 + 2.5, 0
    )
    return JumpRouteCueRules.lavaAtRoot(rootAtDeck, lava)
end

function JumpRouteCueRules.safeGuidedPath(fromPosition, toPosition, warnings)
    if typeof(fromPosition) ~= "Vector3"
        or typeof(toPosition) ~= "Vector3"
        or type(warnings) ~= "table" then
        return false
    end
    for _, warning in ipairs(warnings) do
        if typeof(warning) == "Instance"
            and warning:IsA("BasePart")
            and warning.Parent == workspace
            and (warning.Name == "MeteorWarning" or warning.Name == "BombWarning")
        then
            local diameter = tonumber(warning:GetAttribute("WarningEndSize"))
            local visibleDiameter = math.max(warning.Size.X, warning.Size.Z)
            if not diameter or diameter ~= diameter
                or diameter <= 0 or diameter == math.huge then
                diameter = visibleDiameter
            end
            local radius = math.clamp(math.max(diameter, visibleDiameter) * 0.5
                + 3, 0, 120)
            -- Real Meteor/Bomb damage uses 3D root-to-impact distance,
            -- not a flat floor circle. Match its impact center while
            -- retaining the rookie guide's 3-stud safety buffer: a roof
            -- above the blast sphere remains a genuinely safe escape.
            -- Until WarningEndSize replicates, conservatively use the
            -- visible server-authored marker's current footprint.
            local impactCenter = warning.Position + Vector3.new(0, 1, 0)
            local start = fromPosition - impactCenter
            local finish = toPosition - impactCenter
            -- Hide optional parkour coaching if a true near-impact route
            -- intersects this sphere. The main survival warning still wins.
            if start.Magnitude <= radius or finish.Magnitude <= radius then
                return false
            end
            local travel = finish - start
            local lengthSquared = travel:Dot(travel)
            if lengthSquared > 0.001 then
                local t = math.clamp(-start:Dot(travel) / lengthSquared, 0, 1)
                if (start + travel * t).Magnitude <= radius then
                    return false
                end
            end
        elseif typeof(warning) == "Instance"
            and warning:IsA("BasePart")
            and warning.Parent ~= nil
            and JumpRouteCueRules.activeSweepOnPath(
                fromPosition, toPosition, warning
            ) then
            return false
        end
    end
    return true
end

-- Harbor's two upper freight gantries are level, intentionally separated
-- by genuine jump gaps. They do not use the ASCENDING-only helper above:
-- accepting a flat leap globally would also create fake low-ceiling routes.
-- This predicate is only applied to explicit server-owned HarborSkyway IDs.
function JumpRouteCueRules.skywayLeap(from, target)
    if not walkable(from) or not JumpRouteCueRules.safeLandingTarget(target)
        or from == target or from.Parent ~= target.Parent then
        return false
    end
    local gap = JumpRouteCueRules.gap(from, target)
    local rise = (target.Position.Y + target.Size.Y * 0.5)
        - (from.Position.Y + from.Size.Y * 0.5)
    return gap ~= nil and gap > 0.15 and gap <= JumpRouteCueRules.MaxGap
        and math.abs(rise) <= 1.2
end

-- The same physical skyway is traversable in either direction. The
-- optional travelDirection is the rookie coach's last REAL landed step,
-- never client authority over platforms or jumps.
function JumpRouteCueRules.nextSkyway(from, orderedPlatforms, travelDirection, isClear)
    if not walkable(from) or type(orderedPlatforms) ~= "table" then
        return nil
    end
    local lane = from:GetAttribute("HarborSkywayLane")
    local step = from:GetAttribute("HarborSkywayStep")
    local harborRoute = from:GetAttribute("HarborRoute")
    local harborStep = from:GetAttribute("HarborStep")

    local targetLane, nextStep, targetHarbor = nil, nil, nil
    if (lane == 1 or lane == 2)
        and type(step) == "number" and step % 1 == 0
        and step >= 1 and step <= 7 then
        -- Veteran/late-stream fallback directs toward the nearer terminal,
        -- while an active traverser keeps the direction of their last jump.
        local direction = travelDirection == 1 and 1
            or (travelDirection == -1 and -1
                or (from.Position.X < 0 and -1 or 1))
        targetLane = lane
        nextStep = step + direction
        if nextStep < 1 or nextStep > 7 then
            targetHarbor = lane == 1
                and (direction > 0 and 2 or 1)
                or (direction > 0 and 4 or 3)
            targetLane, nextStep = nil, nil
        end
    elseif harborStep == 7 and type(harborRoute) == "number"
        and harborRoute % 1 == 0 and harborRoute >= 1
        and harborRoute <= 4 then
        targetLane = harborRoute <= 2 and 1 or 2
        nextStep = harborRoute % 2 == 1 and 1 or 7
    else
        return nil
    end

    for _, candidate in ipairs(orderedPlatforms) do
        if candidate:IsA("BasePart")
            and candidate.Parent == from.Parent
            and (targetHarbor and candidate:GetAttribute("HarborRoute")
                    == targetHarbor
                and candidate:GetAttribute("HarborStep") == 7
                or targetLane
                    and candidate:GetAttribute("HarborSkywayLane")
                        == targetLane
                    and candidate:GetAttribute("HarborSkywayStep") == nextStep)
            and JumpRouteCueRules.skywayLeap(from, candidate)
            and (not isClear or isClear(from,candidate)) then
            return candidate
        end
    end
    return nil
end

-- The five 320-stud arenas already contain TWO real eight-step sky
-- promenades and a ten-step transverse Sky Spine. Their horizontal
-- 2.4-stud jumps were invisible to the coach: the ordinary jump predicate
-- requires a rise and the original selector stops at RouteTier 4.
-- Strictly pair server-authored route metadata AND genuine current physics.
-- A connection where footprints overlap is a *walk*, not a fake jump.
function JumpRouteCueRules.skyNetworkLink(from, target)
    -- A player already standing on an amber Warning deck must be guided
    -- OUT before it disappears; only the destination must be hazard-safe.
    if not walkable(from)
        or not JumpRouteCueRules.safeLandingTarget(target)
        or from == target or from.Parent ~= target.Parent
        or from:GetAttribute("ChaosPermanentRoute") ~= true
        or target:GetAttribute("ChaosPermanentRoute") ~= true then
        return false
    end
    local fromSpine = from:GetAttribute("SkySpineStep") ~= nil
    local targetSpine = target:GetAttribute("SkySpineStep") ~= nil
    if fromSpine and target:GetAttribute("PromenadeLane") ~= nil then
        return SkyRouteConnectionRules.spineJunction(from, target, from)
    elseif targetSpine and from:GetAttribute("PromenadeLane") ~= nil then
        return SkyRouteConnectionRules.spineJunction(target, from, from)
    end
    local firstTop = from.Position.Y + from.Size.Y * 0.5
    local secondTop = target.Position.Y + target.Size.Y * 0.5
    if math.abs(secondTop - firstTop) > 0.25 then return false end
    local dx = target.Position.X - from.Position.X
    local dz = target.Position.Z - from.Position.Z
    if dx * dx + dz * dz < 9 then return false end
    local gap = JumpRouteCueRules.gap(from, target)
    return gap ~= nil and gap <= JumpRouteCueRules.MaxGap
end

-- Return actual bidirectional upper-route progression AND the real H-shaped
-- spine turn. Only these exact server-authored combinations are considered:
-- branch lookout 4 <-> promenade endpoint, promenade N step 4 <->
-- spine N step 1, promenade S step 4 <-> spine S step 10,
-- consecutive promenade/spine steps. No position-only sky bridge guesses.
function JumpRouteCueRules.skyNetworkOptions(from, orderedPlatforms,
        travelDirection)
    if not walkable(from)
        or type(orderedPlatforms) ~= "table" then return nil, nil end
    local lane = from:GetAttribute("PromenadeLane")
    local step = from:GetAttribute("PromenadeStep")
    local spine = from:GetAttribute("SkySpineStep")
    local branchRoute = from:GetAttribute("BranchRoute")
    local branchStep = from:GetAttribute("BranchStep")
    local forwardLane, forwardStep, forwardBranch
    local forwardSpine, alternateSpine, alternateLane
    local direction = travelDirection == -1 and -1 or 1

    if type(lane) == "number" and (lane == 1 or lane == 2)
        and type(step) == "number" and step % 1 == 0
        and step >= 1 and step <= 8 then
        if travelDirection ~= 1 and travelDirection ~= -1 then
            direction = step <= 4 and 1 or -1
        end
        forwardStep = step + direction
        if forwardStep >= 1 and forwardStep <= 8 then
            forwardLane = lane
        else
            forwardBranch = lane == 1
                and (direction < 0 and 1 or 2)
                or (direction < 0 and 3 or 4)
            forwardStep = nil
        end
        if step == 4 then
            alternateSpine = lane == 1 and 1 or 10
        end
    elseif type(spine) == "number" and spine % 1 == 0
        and spine >= 1 and spine <= 10
        and from:GetAttribute("SkySpineInterchange") == true then
        if travelDirection ~= 1 and travelDirection ~= -1 then
            direction = spine <= 5 and 1 or -1
        end
        forwardSpine = spine + direction
        if forwardSpine < 1 or forwardSpine > 10 then
            forwardSpine = nil
        end
        if spine == 1 or spine == 10 then
            alternateLane = spine == 1 and 1 or 2
        end
    elseif type(branchRoute) == "number"
        and branchRoute % 1 == 0 and branchRoute >= 1
        and branchRoute <= 4 and branchStep == 4 then
        forwardLane = branchRoute <= 2 and 1 or 2
        forwardStep = branchRoute % 2 == 1 and 1 or 8
    else
        return nil, nil
    end

    local forward, interchange
    for _, candidate in ipairs(orderedPlatforms) do
        if candidate ~= from and candidate:IsA("BasePart")
            and candidate.Parent == from.Parent
            and JumpRouteCueRules.skyNetworkLink(from, candidate) then
            if forwardLane and candidate:GetAttribute("PromenadeLane")
                    == forwardLane
                and candidate:GetAttribute("PromenadeStep") == forwardStep then
                forward = candidate
            elseif forwardBranch
                and candidate:GetAttribute("BranchRoute") == forwardBranch
                and candidate:GetAttribute("BranchStep") == 4 then
                forward = candidate
            elseif forwardSpine
                and candidate:GetAttribute("SkySpineInterchange") == true
                and candidate:GetAttribute("SkySpineStep") == forwardSpine then
                forward = candidate
            elseif alternateSpine
                and candidate:GetAttribute("SkySpineInterchange") == true
                and candidate:GetAttribute("SkySpineStep") == alternateSpine then
                interchange = candidate
            elseif alternateLane
                and candidate:GetAttribute("PromenadeLane") == alternateLane
                and candidate:GetAttribute("PromenadeStep") == 4 then
                interchange = candidate
            end
        end
    end
    return forward, interchange
end

-- Reverse only an authored ascent. Validate the lower landing rather than
-- treating the higher departure as a safe destination during a warning.
local function outerAscent(from, target)
    local ridge = from:GetAttribute("PerimeterRoute")
    local ridgeStep = from:GetAttribute("PerimeterStep")
    local branch = from:GetAttribute("BranchRoute")
    local branchStep = from:GetAttribute("BranchStep")
    local crossing = from:GetAttribute("CrosslinkRoute")
    if ridge and type(ridgeStep) == "number" then
        return (target:GetAttribute("PerimeterRoute") == ridge
                and target:GetAttribute("PerimeterStep") == ridgeStep + 1)
            or (ridgeStep == 5 and target:GetAttribute("BranchRoute") == ridge
                and target:GetAttribute("BranchStep") == 1 and target:GetAttribute("BranchParentStep") == 5)
            or (ridgeStep == 6 and target:GetAttribute("CrosslinkRoute") == ridge
                and target:GetAttribute("CrosslinkFromPerimeterStep") == 6
                and target:GetAttribute("CrosslinkToBranchStep") == 2)
    elseif branch and type(branchStep) == "number" then
        return target:GetAttribute("BranchRoute") == branch
            and target:GetAttribute("BranchStep") == branchStep + 1
    elseif crossing and from:GetAttribute("CrosslinkFromPerimeterStep") == 6
        and from:GetAttribute("CrosslinkToBranchStep") == 2 then
        return target:GetAttribute("BranchRoute") == crossing and target:GetAttribute("BranchStep") == 2
    end
    return false
end

function JumpRouteCueRules.canDescend(from, target)
    if not walkable(from) or not JumpRouteCueRules.safeLandingTarget(target)
        or from.Parent ~= target.Parent or not outerAscent(target, from) then return false end
    local gap = JumpRouteCueRules.gap(from, target)
    local drop = from.Position.Y + from.Size.Y * 0.5 - target.Position.Y - target.Size.Y * 0.5
    return gap > 0.15 and gap <= JumpRouteCueRules.MaxGap
        and drop >= 0.4 and drop <= JumpRouteCueRules.MaxRise
end

function JumpRouteCueRules.outerDescent(from, platforms, isClear)
    if not walkable(from) or type(platforms) ~= "table" then return nil end
    local connector
    for _, target in ipairs(platforms) do
        if JumpRouteCueRules.canDescend(from, target) and (not isClear or isClear(from, target)) then
            if target:GetAttribute("CrosslinkRoute") == nil then return target end
            connector = target
        end
    end
    return connector
end

function JumpRouteCueRules.outerRouteLink(from, target)
    if not walkable(from) or not JumpRouteCueRules.safeLandingTarget(target)
        or from == target or from.Parent ~= target.Parent then return false end
    if outerAscent(from, target) then return JumpRouteCueRules.jumpable(from, target) end
    if JumpRouteCueRules.canDescend(from, target) then return true end
    if not JumpRouteCueRules.skyNetworkLink(from, target) then return false end

    local lane, nextLane = from:GetAttribute("PromenadeLane"), target:GetAttribute("PromenadeLane")
    local span, nextSpan = from:GetAttribute("PromenadeStep"), target:GetAttribute("PromenadeStep")
    if lane and nextLane then
        return lane == nextLane and type(span) == "number" and type(nextSpan) == "number"
            and math.abs(span - nextSpan) == 1
    end
    local spine, nextSpine = from:GetAttribute("SkySpineStep"), target:GetAttribute("SkySpineStep")
    if spine and nextSpine then
        return type(spine) == "number" and type(nextSpine) == "number" and math.abs(spine - nextSpine) == 1
    elseif (spine and nextLane) or (nextSpine and lane) then
        return true -- skyNetworkLink already requires the real intersection.
    end
    local lookout, promenade = if lane then target else from, if lane then from else target
    local route = lookout:GetAttribute("BranchRoute")
    if type(route) ~= "number" or route < 1 or route > 4
        or lookout:GetAttribute("BranchStep") ~= 4 then return false end
    return promenade:GetAttribute("PromenadeLane") == (route <= 2 and 1 or 2)
        and promenade:GetAttribute("PromenadeStep") == (route % 2 == 1 and 1 or 8)
end

function JumpRouteCueRules.groundExit(from, base)
    if not walkable(from) or not JumpRouteCueRules.safeLandingSurface(base)
        or from:GetAttribute("PerimeterStep") ~= 1 or not from.Parent
        or from.Parent.Name ~= "Platforms" or base.Name ~= "Base"
        or from.Parent.Parent ~= base.Parent then return nil end
    local top = base.Position.Y + base.Size.Y * 0.5
    local drop = from.Position.Y + from.Size.Y * 0.5 - top
    if drop < 0.4 or drop > JumpRouteCueRules.MaxRise then return nil end

    local inward = base.Position - from.Position
    local flat = Vector3.new(inward.X, 0, inward.Z)
    if flat.Magnitude < 0.01 then return nil end
    local direction = flat.Unit
    local localDirection = from.CFrame:VectorToObjectSpace(direction)
    local edgeDistance = math.min(
        from.Size.X * 0.5 / math.max(.0001, math.abs(localDirection.X)),
        from.Size.Z * 0.5 / math.max(.0001, math.abs(localDirection.Z))
    )
    local point = from.Position + direction * (edgeDistance + 3)
    point = Vector3.new(point.X, top, point.Z)
    local spot = base.CFrame:PointToObjectSpace(point)
    if math.abs(spot.X) > base.Size.X * .5 - 2 or math.abs(spot.Z) > base.Size.Z * .5 - 2 then return nil end
    return point
end

-- Original central routes use conservative spatial selection. Perimeter
-- and side-lookout steps have explicit server-authored route/step IDs;
-- using those IDs avoids directing a novice across unrelated adjacent
-- towers. The last step is a genuine end point, never a phantom jump.
function JumpRouteCueRules.nextPhysical(from, orderedPlatforms, arenaCenter, variantId, skywayDirection, isClear)
    if not walkable(from) or type(orderedPlatforms) ~= "table" then
        return nil
    end

    if from:GetAttribute("HarborSkywayLane") ~= nil then
        return JumpRouteCueRules.nextSkyway(
            from, orderedPlatforms, skywayDirection, isClear
        )
    end

    -- All five maps share a real H-shaped high-altitude platform network.
    -- These certified level routes need different, bidirectional geometry
    -- rules from the central ASCENDING jump selection below.
    if from:GetAttribute("PromenadeLane") ~= nil
        or from:GetAttribute("SkySpineStep") ~= nil
        or (from:GetAttribute("BranchRoute") ~= nil
            and from:GetAttribute("BranchStep") == 4) then
        local forward, junction = JumpRouteCueRules.skyNetworkOptions(
            from, orderedPlatforms, skywayDirection)
        if forward and (not isClear or isClear(from,forward)) then return forward end
        if junction and (not isClear or isClear(from,junction)) then return junction end

        -- If the intended direction and junction are both blocked, the
        -- previous span can still be a valid way out of the hazard.
        local step = from:GetAttribute("PromenadeStep") or from:GetAttribute("SkySpineStep")
        if type(step) ~= "number" then return nil end
        local midpoint = from:GetAttribute("PromenadeLane") ~= nil and 4 or 5
        local direction = if skywayDirection == -1 or skywayDirection == 1
            then skywayDirection else (step <= midpoint and 1 or -1)
        local retreat = JumpRouteCueRules.skyNetworkOptions(from, orderedPlatforms, -direction)
        return retreat and (not isClear or isClear(from,retreat)) and retreat or nil
    end

    -- Storm Harbor's newer cardinal dry-dock routes are also authored
    -- and physically ordered, never a nearest-tier hallucination. The
    -- same ordinary jumpability predicate filters collapsing decks,
    -- missing collision and impossible gaps or rises.
    local spokeRoute = from:GetAttribute("HarborSpokeRoute")
    local spokeStep = from:GetAttribute("HarborSpokeStep")
    if spokeRoute ~= nil or spokeStep ~= nil then
        if variantId ~= "Harbor"
            or type(spokeRoute) ~= "number" or spokeRoute % 1 ~= 0
            or spokeRoute < 1 or spokeRoute > 4
            or type(spokeStep) ~= "number" or spokeStep % 1 ~= 0
            or spokeStep < 1 or spokeStep >= 4 then
            return nil
        end
        for _, destination in ipairs(orderedPlatforms) do
            if destination ~= from and destination:IsA("BasePart")
                and destination:GetAttribute("HarborSpokeRoute") == spokeRoute
                and destination:GetAttribute("HarborSpokeStep") == spokeStep + 1
                and JumpRouteCueRules.jumpable(from, destination)
                and (not isClear or isClear(from,destination)) then
                return destination
            end
        end
        return nil
    end

    -- Storm Harbor's tight 90-degree switchbacks need their real,
    -- authored order. Spatial nearest-tier selection alone can steer
    -- novices to a DIFFERENT quay with no attainable jump.
    local harborRoute = from:GetAttribute("HarborRoute")
    local harborStep = from:GetAttribute("HarborStep")
    if harborRoute ~= nil or harborStep ~= nil then
        if type(harborRoute) ~= "number" or harborRoute % 1 ~= 0
            or harborRoute < 1 or harborRoute > 4
            or type(harborStep) ~= "number" or harborStep % 1 ~= 0
            or harborStep < 1 or harborStep > 7 then
            return nil
        end
        if harborStep == 7 then
            return JumpRouteCueRules.nextSkyway(from, orderedPlatforms,nil,isClear)
        end
        for _, destination in ipairs(orderedPlatforms) do
            if destination ~= from and destination:IsA("BasePart")
                and destination:GetAttribute("HarborRoute") == harborRoute
                and destination:GetAttribute("HarborStep") == harborStep + 1
                and JumpRouteCueRules.jumpable(from, destination)
                and (not isClear or isClear(from,destination)) then
                return destination
            end
        end
        return nil
    end

    local route = from:GetAttribute("PerimeterRoute")
    local step = from:GetAttribute("PerimeterStep")
    local branch = from:GetAttribute("BranchRoute")
    local branchStep = from:GetAttribute("BranchStep")
    local crossing = from:GetAttribute("CrosslinkRoute")

    if crossing ~= nil then
        if type(crossing) ~= "number" or crossing % 1 ~= 0
            or crossing < 1 or crossing > 4
            or from:GetAttribute("CrosslinkFromPerimeterStep") ~= 6
            or from:GetAttribute("CrosslinkToBranchStep") ~= 2 then
            return nil
        end
        for _, target in ipairs(orderedPlatforms) do
            if target ~= from and target:IsA("BasePart")
                and target:GetAttribute("BranchRoute") == crossing
                and target:GetAttribute("BranchStep") == 2
                and JumpRouteCueRules.jumpable(from, target)
                and (not isClear or isClear(from,target)) then
                return target
            end
        end
        return nil
    end

    if route ~= nil or branch ~= nil then
        -- The forward route is the default, but only if the physical
        -- landing is still safe. The branch offers a real escape option
        -- when a collapsing or missing main deck blocks the ascent.
        if route ~= nil and (step == 5 or step == 6) then
            local forward, detour = perimeterChoices(from, orderedPlatforms, step, isClear)
            return forward or detour
        end
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
                and JumpRouteCueRules.jumpable(from, candidate)
                and (not isClear or isClear(from,candidate)) then
                return candidate
            end
        end
        return nil
    end

    local target = JumpRouteCueRules.select(
        from, orderedPlatforms, arenaCenter, variantId,isClear
    )
    if target and JumpRouteCueRules.jumpable(from, target) then
        return target
    end
    return nil
end

return JumpRouteCueRules
