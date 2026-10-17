local MovementAssistRules = {}

MovementAssistRules.CoyoteSeconds = 0.10
MovementAssistRules.BufferSeconds = 0.12

local BLOCKED_STATES = {
    [Enum.HumanoidStateType.Dead] = true,
    [Enum.HumanoidStateType.Seated] = true,
    [Enum.HumanoidStateType.Swimming] = true,
    [Enum.HumanoidStateType.Climbing] = true,
}

function MovementAssistRules.stateAllowsJump(state)
    return BLOCKED_STATES[state] ~= true
end

function MovementAssistRules.canCoyoteJump(
    grounded,
    secondsSinceGrounded,
    state,
    jumpEnabled
)
    if grounded == true
        or jumpEnabled ~= true
        or state ~= Enum.HumanoidStateType.Freefall
        or not MovementAssistRules.stateAllowsJump(state)
    then
        return false
    end

    local elapsed = math.max(0, tonumber(secondsSinceGrounded) or math.huge)
    return elapsed <= MovementAssistRules.CoyoteSeconds
end

-- Use only the jump control mode actually selected by Roblox. The
-- other property may remain positive while a disaster disables jumping.
-- SetStateEnabled(Jumping, false) must also block assisted jumps.
function MovementAssistRules.jumpEnabled(health, useJumpPower, jumpPower, jumpHeight, stateEnabled)
    if type(health) ~= "number" or health ~= health or health <= 0
        or stateEnabled ~= true then
        return false
    end
    local strength = if useJumpPower == true then jumpPower else jumpHeight
    return type(strength) == "number" and strength == strength
        and strength > 0 and strength < math.huge
end

function MovementAssistRules.bufferUntil(now)
    local t = tonumber(now) or 0
    return t + MovementAssistRules.BufferSeconds
end

function MovementAssistRules.bufferActive(now, expiresAt)
    return (tonumber(expiresAt) or -math.huge) >= (tonumber(now) or 0)
end

return MovementAssistRules
