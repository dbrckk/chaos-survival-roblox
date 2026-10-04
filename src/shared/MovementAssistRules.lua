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
        or not MovementAssistRules.stateAllowsJump(state)
    then
        return false
    end

    local elapsed = math.max(0, tonumber(secondsSinceGrounded) or math.huge)
    return elapsed <= MovementAssistRules.CoyoteSeconds
end

function MovementAssistRules.bufferUntil(now)
    local t = tonumber(now) or 0
    return t + MovementAssistRules.BufferSeconds
end

function MovementAssistRules.bufferActive(now, expiresAt)
    return (tonumber(expiresAt) or -math.huge) >= (tonumber(now) or 0)
end

return MovementAssistRules
