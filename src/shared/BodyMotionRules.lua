local BodyMotionRules = {}

-- Both Roblox skeletons can receive mild *local* joint-offset polish.
-- All bindings target the rig's original Motor6Ds, never the Animator,
-- physics assembly, server-owned movement or replicated character assets.
local function existingMotor(part, name)
    local joint = part and part:FindFirstChild(name)
    return joint and joint:IsA("Motor6D") and joint or nil
end

function BodyMotionRules.joints(character, rigType)
    if not character or not character:IsA("Model") then return nil end
    if rigType == Enum.HumanoidRigType.R15 then
        local lower = character:FindFirstChild("LowerTorso")
        local upper = character:FindFirstChild("UpperTorso")
        return {
            waist = existingMotor(upper, "Waist"),
            rootJoint = existingMotor(lower, "Root"),
            leftHip = existingMotor(lower, "LeftHip"),
            rightHip = existingMotor(lower, "RightHip"),
            leftShoulder = existingMotor(upper, "LeftShoulder"),
            rightShoulder = existingMotor(upper, "RightShoulder"),
        }
    elseif rigType == Enum.HumanoidRigType.R6 then
        local torso = character:FindFirstChild("Torso")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        return {
            waist = nil, -- R6 has no waist; all lean stays on RootJoint.
            rootJoint = existingMotor(hrp, "RootJoint")
                or existingMotor(torso, "RootJoint"),
            leftHip = existingMotor(torso, "Left Hip"),
            rightHip = existingMotor(torso, "Right Hip"),
            leftShoulder = existingMotor(torso, "Left Shoulder"),
            rightShoulder = existingMotor(torso, "Right Shoulder"),
        }
    end
    return nil
end

-- R6's single rigid Torso and wide-offset shoulders need less additive
-- lean than R15. Avoid dramatic inversions when switching avatar rigs.
function BodyMotionRules.rigPoseScale(rigType)
    if rigType == Enum.HumanoidRigType.R15 then return 1 end
    if rigType == Enum.HumanoidRigType.R6 then return 0.46 end
    return 0
end

function BodyMotionRules.stride(speed, grounded, speedSurge)
    local safeSpeed = math.max(0, tonumber(speed) or 0)
    if grounded ~= true or safeSpeed < 2.5 then
        return 0, 0
    end

    local weight = math.clamp((safeSpeed - 2.5) / 14.5, 0, 1)
    local frequency = 5.2 + math.min(5.0, safeSpeed * 0.24)
    if speedSurge == true then
        frequency *= 1.12
        weight = math.min(1, weight * 1.08)
    end

    return weight, frequency
end

function BodyMotionRules.brakeWeight(acceleration, moving)
    if moving ~= true then
        return 0
    end
    local value = tonumber(acceleration) or 0
    return math.clamp(-value / 150, 0, 1)
end

function BodyMotionRules.turnResponse(previousDirection, currentDirection)
    if typeof(previousDirection) ~= "Vector3"
        or typeof(currentDirection) ~= "Vector3"
    then
        return 0, 0
    end

    local a = Vector3.new(previousDirection.X, 0, previousDirection.Z)
    local b = Vector3.new(currentDirection.X, 0, currentDirection.Z)
    if a.Magnitude < 0.05 or b.Magnitude < 0.05 then
        return 0, 0
    end

    a = a.Unit
    b = b.Unit

    local signed = math.clamp(a:Cross(b).Y, -1, 1)
    local severity = math.clamp((1 - a:Dot(b)) * 0.5, 0, 1)
    return signed, severity
end

function BodyMotionRules.readyStance(phase, grounded, speed)
    if tostring(phase or "waiting") ~= "ready" or grounded ~= true then
        return 0
    end

    local safeSpeed = math.max(0, tonumber(speed) or 0)
    return math.clamp(1 - (safeSpeed / 12), 0, 1)
end

-- A directional, short-lived *cosmetic* flinch from the explosion source.
-- X is the local rightward escape vector; Forward is -local Z.
-- The contact/damage authority is elsewhere: this never adds force or damage.
function BodyMotionRules.blastResponse(rootFrame, sourcePosition, radius)
    if typeof(rootFrame) ~= "CFrame" or typeof(sourcePosition) ~= "Vector3" then
        return 0, 0, 0
    end
    local fromBlast = rootFrame.Position - sourcePosition
    local distance = fromBlast.Magnitude
    local reach = math.max(20, math.clamp(tonumber(radius) or 8, 1, 40) * 4.2)
    if distance >= reach then
        return 0, 0, 0
    end
    local strength = math.clamp(1 - distance / reach, 0, 1)
    local flat = Vector3.new(fromBlast.X, 0, fromBlast.Z)
    if flat.Magnitude < 0.05 then
        return strength, 0, 0
    end
    local localAway = rootFrame:VectorToObjectSpace(flat.Unit)
    return strength, math.clamp(localAway.X, -1, 1),
        math.clamp(-localAway.Z, -1, 1)
end

function BodyMotionRules.motionScale(reduceMotion)
    return reduceMotion == true and 0.18 or 1
end

return BodyMotionRules
