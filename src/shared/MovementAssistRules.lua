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
    jumpEnabled,
    jumpAlreadyUsed
)
    if grounded == true
        or jumpEnabled ~= true
        or jumpAlreadyUsed == true
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

-- During an Android/slow-network landing the local FloorMaterial and
-- HumanoidStateType.Landed events may arrive in either order. The buffered
-- request is valid only after actual grounded contact, while jumping is
-- enabled, and outside the OLD Jumping state. A landed callback rechecks it
-- without adding a Heartbeat loop or a second midair jump.
function MovementAssistRules.canDispatchBufferedJump(
    now, expiresAt, grounded, state, enabled
)
    -- FloorMaterial may settle to Solid while Roblox still reports
    -- Freefall/Jumping. Those states are not permission to jump AGAIN.
    -- The matching Landed/Running event will retry without polling.
    local contactState = state == Enum.HumanoidStateType.Landed
        or state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.RunningNoPhysics
    return grounded == true
        and enabled == true
        and contactState
        and MovementAssistRules.stateAllowsJump(state)
        and MovementAssistRules.bufferActive(now, expiresAt)
end

return MovementAssistRules
