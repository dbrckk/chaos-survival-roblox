-- Preserve short coyote/buffered jumps without leaking input into an old rig.
-- Character and Humanoid replication may complete after a rapid respawn.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementAssistRules = require(ReplicatedStorage.Shared.MovementAssistRules)

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local floorConnection = nil
local stateConnection = nil
local bindVersion = 0
local lastGroundedAt = -math.huge
local bufferedUntil = -math.huge
local coyoteConsumed = true

local function disconnect()
    bindVersion += 1
    if floorConnection then
        floorConnection:Disconnect()
        floorConnection = nil
    end
    if stateConnection then
        stateConnection:Disconnect()
        stateConnection = nil
    end
    character = nil
    humanoid = nil
    -- A pending jump from a dead rig must never replay on respawn.
    lastGroundedAt = -math.huge
    bufferedUntil = -math.huge
    coyoteConsumed = true
end

local function isCurrent(version, boundCharacter, boundHumanoid)
    return bindVersion == version
        and character == boundCharacter
        and player.Character == boundCharacter
        and humanoid == boundHumanoid
        and boundHumanoid ~= nil
        and boundHumanoid.Parent == boundCharacter
end

local function jumpEnabled(h)
    return h ~= nil and MovementAssistRules.jumpEnabled(
        h.Health,
        h.UseJumpPower,
        h.JumpPower,
        h.JumpHeight,
        h:GetStateEnabled(Enum.HumanoidStateType.Jumping)
    )
end

local function requestAssistedJump()
    local active = humanoid
    if not active or character ~= player.Character or active.Parent ~= character then
        return
    end

    local now = os.clock()
    local grounded = active.FloorMaterial ~= Enum.Material.Air
    local state = active:GetState()

    if grounded then
        bufferedUntil = -math.huge
        coyoteConsumed = false
        return
    end

    if not coyoteConsumed
        and MovementAssistRules.canCoyoteJump(
            false,
            now - lastGroundedAt,
            state,
            jumpEnabled(active),
            coyoteConsumed
        )
    then
        coyoteConsumed = true
        bufferedUntil = -math.huge
        active.Jump = true
        return
    end

    if MovementAssistRules.stateAllowsJump(state)
        and jumpEnabled(active)
    then
        bufferedUntil = MovementAssistRules.bufferUntil(now)
    end
end

local function bindCharacter(nextCharacter)
    -- The initial task and CharacterAdded can race during replication.
    if player.Character ~= nextCharacter then
        return
    end

    disconnect()
    local version = bindVersion
    character = nextCharacter

    local nextHumanoid = nextCharacter:WaitForChild("Humanoid", 5)
    if not nextHumanoid or not nextHumanoid:IsA("Humanoid")
        or bindVersion ~= version or character ~= nextCharacter
        or player.Character ~= nextCharacter or nextHumanoid.Parent ~= nextCharacter
    then
        return
    end
    humanoid = nextHumanoid

    if nextHumanoid.FloorMaterial ~= Enum.Material.Air then
        lastGroundedAt = os.clock()
        coyoteConsumed = false
    else
        lastGroundedAt = -math.huge
        coyoteConsumed = true
    end
    bufferedUntil = -math.huge

    floorConnection = nextHumanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        if not isCurrent(version, nextCharacter, nextHumanoid) then
            return
        end

        if nextHumanoid.FloorMaterial ~= Enum.Material.Air then
            local now = os.clock()
            lastGroundedAt = now
            coyoteConsumed = false

            if MovementAssistRules.bufferActive(now, bufferedUntil)
                and jumpEnabled(nextHumanoid)
                and MovementAssistRules.stateAllowsJump(nextHumanoid:GetState())
            then
                bufferedUntil = -math.huge
                task.defer(function()
                    -- Landing callbacks can outlive this rig or the Freeze
                    -- Pulse that briefly disabled jumping.
                    if isCurrent(version, nextCharacter, nextHumanoid)
                        and nextHumanoid.FloorMaterial ~= Enum.Material.Air
                        and jumpEnabled(nextHumanoid)
                        and MovementAssistRules.stateAllowsJump(nextHumanoid:GetState())
                    then
                        nextHumanoid.Jump = true
                    end
                end)
            end
        end
    end)

    stateConnection = nextHumanoid.StateChanged:Connect(function(_, state)
        if not isCurrent(version, nextCharacter, nextHumanoid) then
            return
        end
        -- Roblox can transition from Jumping to Freefall within the
        -- 100ms coyote window. Consume the window for a normal jump so
        -- a second tap cannot create an unintended mid-air double jump.
        if state == Enum.HumanoidStateType.Jumping then
            coyoteConsumed = true
            bufferedUntil = -math.huge
        end
        if state == Enum.HumanoidStateType.Dead
            or state == Enum.HumanoidStateType.Seated
            or state == Enum.HumanoidStateType.Swimming
        then
            bufferedUntil = -math.huge
        end
    end)
end

UserInputService.JumpRequest:Connect(requestAssistedJump)

player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(function(removingCharacter)
    -- A delayed removal for the previous rig must not unbind the new one.
    if character == removingCharacter then
        disconnect()
    end
end)
if player.Character then
    task.spawn(bindCharacter, player.Character)
end
