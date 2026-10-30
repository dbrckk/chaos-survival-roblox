-- Pure, bounded rules for the local descent reticle. The reticle is an
-- estimate, never an authoritative prediction of hazards or collision.
local JumpLandingPreviewRules = {}
local routeModule = script and script.Parent:FindFirstChild("JumpRouteCueRules")
local JumpRouteCueRules = if routeModule
    then require(routeModule)
    else require("./JumpRouteCueRules")

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

JumpLandingPreviewRules.SampleSeconds = 0.10
JumpLandingPreviewRules.MaxPredictionSeconds = 0.42
JumpLandingPreviewRules.MaxDrop = 13
JumpLandingPreviewRules.MaxHorizontalTravel = 8
-- One near, one mid-flight and one late lookahead. At most three candidate
-- rays plus one confirmation per 10Hz sample, never a ray per rendered frame.
JumpLandingPreviewRules.ProbeSeconds = {0.08, 0.23, 0.36}
JumpLandingPreviewRules.ProbeToleranceSeconds = 0.14

-- Classify a REAL collidable landing before drawing local brackets.
-- An amber CollapsePhase=Warning target is not safe: show an explicit
-- hazard X while collision still exists, rather than silently hiding the
-- only preview of the upcoming landing. Gone and unrecognised phases are
-- rejected. This is UI-only: it cannot change server-owned terrain.
function JumpLandingPreviewRules.surfaceStatus(part)
    if typeof(part) ~= "Instance" or not part:IsA("BasePart")
        or not part.CanCollide or part.Transparency >= 0.75 then
        return "Unavailable"
    end
    local phase = part:GetAttribute("CollapsePhase")
    if phase == "Warning" then
        return "Warning"
    end
    if phase ~= nil then
        return "Unavailable"
    end
    return "Safe"
end

-- Meteor and bomb warnings are replicated by the authoritative server
-- BEFORE damage, with an exact final blast diameter. The actual disaster
-- damages HumanoidRootPart within a THREE-DIMENSIONAL sphere centered one
-- stud above the warning Part. A 2D circle would incorrectly mark safe
-- high-ground roofs red. Only read fully configured, live, known warnings;
-- never trust unrelated neon geometry or client-supplied danger labels.
function JumpLandingPreviewRules.impactWarningAt(landingRoot, marker)
    if typeof(landingRoot) ~= "Vector3"
        or typeof(marker) ~= "Instance" or not marker:IsA("BasePart")
        or marker.Parent ~= workspace then
        return false
    end
    local kind = marker:GetAttribute("WarningKind")
    if not ((marker.Name == "MeteorWarning" and kind == "Meteor")
        or (marker.Name == "BombWarning" and kind == "Bomb")) then
        return false
    end
    local diameter = tonumber(marker:GetAttribute("WarningEndSize"))
    if not finite(diameter) or diameter <= 0 then
        return false
    end
    -- Server-owned radial damage is measured at the character's ROOT,
    -- not the feet or a cosmetic client-side impact shell.
    local center = marker.Position + Vector3.new(0, 1, 0)
    local radius = math.clamp(diameter * 0.5, 0.05, 120)
    return (landingRoot - center).Magnitude <= radius
end

-- The existing landing reticle must not declare "safe" when the
-- SERVER'S own active shock band crosses this precise physical contact.
-- Compare the projected HumanoidRootPart position, not the deck surface:
-- raised platforms above the band are genuinely protected. The shared
-- path classifier already handles rotated/axis-aligned sweep footprints.
-- Tower shutters are a separate obstacle on a REAL named skybridge; warn
-- only close to the actual metal sill, not on the whole safe bridge.
function JumpLandingPreviewRules.hazardAt(landingRoot, landingPart, hazards)
    if typeof(landingRoot) ~= "Vector3"
        or typeof(landingPart) ~= "Instance"
        or not landingPart:IsA("BasePart")
        or type(hazards) ~= "table" then
        return false
    end
    for _, hazard in ipairs(hazards) do
        if typeof(hazard) == "Instance" and hazard:IsA("BasePart")
            and hazard.Parent ~= nil then
            if JumpLandingPreviewRules.impactWarningAt(landingRoot, hazard) then
                return true
            end
            if JumpRouteCueRules.lavaAtRoot(landingRoot, hazard) then
                return true
            end
            if JumpRouteCueRules.activeSweepOnPath(
                landingRoot, landingRoot, hazard
            ) then
                return true
            end
            if hazard:GetAttribute("BridgeShutter") == true
                and hazard:GetAttribute("BridgeName") == landingPart.Name then
                local phase = hazard:GetAttribute("ShutterPhase")
                if phase == "Warning" or phase == "Raising"
                    or phase == "Raised" then
                    local point = hazard.CFrame:PointToObjectSpace(landingRoot)
                    if math.abs(point.X) <= hazard.Size.X * 0.5 + 1.3
                        and math.abs(point.Z) <= hazard.Size.Z * 0.5 + 1.3
                        and point.Y >= -3 and point.Y <= 6.5 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function JumpLandingPreviewRules.probeMatches(probeSeconds, contactSeconds)
    return finite(probeSeconds) and finite(contactSeconds)
        and probeSeconds >= 0
        and contactSeconds >= 0
        and contactSeconds <= JumpLandingPreviewRules.MaxPredictionSeconds
        and math.abs(probeSeconds - contactSeconds)
            <= JumpLandingPreviewRules.ProbeToleranceSeconds
end

function JumpLandingPreviewRules.eligible(
    phase, participant, eliminated, health, humanoidState, grounded, verticalSpeed
)
    return phase == "round" and participant == true
        and eliminated ~= true
        and finite(health) and health > 0
        and humanoidState == Enum.HumanoidStateType.Freefall
        and grounded == false
        and finite(verticalSpeed) and verticalSpeed < -3
end

function JumpLandingPreviewRules.timeToSurface(verticalSpeed, gravity, drop)
    if not finite(verticalSpeed) or not finite(gravity)
        or not finite(drop) or gravity <= 0 or drop < 0
        or drop > JumpLandingPreviewRules.MaxDrop
        or verticalSpeed >= -3
    then
        return nil
    end
    -- Positive root of drop = -verticalSpeed * t + gravity * t^2 / 2.
    -- Horizontal velocity is sampled locally; a distant airborne player
    -- does not get an unreliable or misleading long-horizon path.
    local discriminant = verticalSpeed * verticalSpeed + 2 * gravity * drop
    local t = (verticalSpeed + math.sqrt(discriminant)) / gravity
    if t < 0 or t > JumpLandingPreviewRules.MaxPredictionSeconds then
        return nil
    end
    return t
end

-- Select the first imminent collision surface, not the later base
-- floor which happens to line up more closely with a sampling timestamp.
-- Keep a 25ms tie band so nearly identical surfaces remain deterministic.
function JumpLandingPreviewRules.preferContact(
    probeSeconds, contactSeconds, bestSeconds, bestError
)
    if not JumpLandingPreviewRules.probeMatches(probeSeconds, contactSeconds) then
        return false
    end
    if bestSeconds == nil then return true end
    if not finite(bestSeconds) or not finite(bestError) then return false end
    if contactSeconds < bestSeconds - 0.025 then return true end
    return math.abs(contactSeconds - bestSeconds) <= 0.025
        and math.abs(probeSeconds - contactSeconds) < bestError
end

function JumpLandingPreviewRules.edgeMargin(platform, hitPosition)
    if typeof(platform) ~= "Instance" or not platform:IsA("BasePart")
        or typeof(hitPosition) ~= "Vector3" then
        return nil
    end
    local localPoint = platform.CFrame:PointToObjectSpace(hitPosition)
    local x = platform.Size.X * 0.5 - math.abs(localPoint.X)
    local z = platform.Size.Z * 0.5 - math.abs(localPoint.Z)
    return math.min(x, z)
end

return JumpLandingPreviewRules
