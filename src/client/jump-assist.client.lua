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
local childAddedConnection = nil
local childRemovedConnection = nil
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
    if childAddedConnection then
        childAddedConnection:Disconnect()
        childAddedConnection = nil
    end
    if childRemovedConnection then
        childRemovedConnection:Disconnect()
        childRemovedConnection = nil
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
    if player.Character ~= nextCharacter then return end

    disconnect()
    local version = bindVersion
    character = nextCharacter

    -- There is NO timeout. Android streaming and delayed avatar assembly
    -- can take longer than WaitForChild("Humanoid", 5): that old path
    -- silently left the player without any assisted jumping until respawn.
    -- Keep only two event subscriptions on the current character.
    local function attachIfReady()
        if bindVersion ~= version or character ~= nextCharacter
            or player.Character ~= nextCharacter then
            return
        end
        local nextHumanoid = nextCharacter:FindFirstChildOfClass("Humanoid")
        if not nextHumanoid or nextHumanoid.Parent ~= nextCharacter then
            return
        end
        if humanoid == nextHumanoid then return end

        if floorConnection then
            floorConnection:Disconnect()
            floorConnection = nil
        end
        if stateConnection then
            stateConnection:Disconnect()
            stateConnection = nil
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

        local dispatchQueued = false
        local function dispatchBufferedLanding()
            if not isCurrent(version, nextCharacter, nextHumanoid)
                or dispatchQueued then return end
            local now = os.clock()
            if not MovementAssistRules.bufferActive(now, bufferedUntil) then
                bufferedUntil = -math.huge
                return
            end
            if not MovementAssistRules.canDispatchBufferedJump(
                now, bufferedUntil,
                nextHumanoid.FloorMaterial ~= Enum.Material.Air,
                nextHumanoid:GetState(), jumpEnabled(nextHumanoid)
            ) then
                return
            end
            dispatchQueued = true
            task.defer(function()
                dispatchQueued = false
                if not isCurrent(version, nextCharacter, nextHumanoid) then
                    return
                end
                local sampleTime = os.clock()
                if MovementAssistRules.canDispatchBufferedJump(
                    sampleTime, bufferedUntil,
                    nextHumanoid.FloorMaterial ~= Enum.Material.Air,
                    nextHumanoid:GetState(), jumpEnabled(nextHumanoid)
                ) then
                    -- One consumed request, even if FloorMaterial and
                    -- StateChanged both announce the same R15 landing.
                    bufferedUntil = -math.huge
                    coyoteConsumed = true
                    nextHumanoid.Jump = true
                end
            end)
        end

        floorConnection = nextHumanoid:GetPropertyChangedSignal(
            "FloorMaterial"
        ):Connect(function()
            if not isCurrent(version, nextCharacter, nextHumanoid) then
                return
            end
            if nextHumanoid.FloorMaterial ~= Enum.Material.Air then
                lastGroundedAt = os.clock()
                coyoteConsumed = false
                dispatchBufferedLanding()
            end
        end)

        stateConnection = nextHumanoid.StateChanged:Connect(function(_, state)
            if not isCurrent(version, nextCharacter, nextHumanoid) then
                return
            end
            if state == Enum.HumanoidStateType.Jumping then
                -- Normal jump already happened: no coyote double-tap.
                coyoteConsumed = true
                bufferedUntil = -math.huge
            elseif state == Enum.HumanoidStateType.Dead
                or state == Enum.HumanoidStateType.Seated
                or state == Enum.HumanoidStateType.Swimming then
                bufferedUntil = -math.huge
            elseif state == Enum.HumanoidStateType.Landed
                or state == Enum.HumanoidStateType.Running
                or state == Enum.HumanoidStateType.RunningNoPhysics then
                if nextHumanoid.FloorMaterial ~= Enum.Material.Air then
                    -- FloorMaterial may have reached Solid one frame
                    -- BEFORE StateChanged or vice versa. Only a real
                    -- grounded state with a pending buffer can dispatch.
                    lastGroundedAt = os.clock()
                    dispatchBufferedLanding()
                end
            end
        end)
    end

    childAddedConnection = nextCharacter.ChildAdded:Connect(function(child)
        if child:IsA("Humanoid") then
            task.defer(attachIfReady)
        end
    end)
    childRemovedConnection = nextCharacter.ChildRemoved:Connect(function(child)
        if child == humanoid then
            if floorConnection then
                floorConnection:Disconnect()
                floorConnection = nil
            end
            if stateConnection then
                stateConnection:Disconnect()
                stateConnection = nil
            end
            humanoid = nil
            lastGroundedAt = -math.huge
            bufferedUntil = -math.huge
            coyoteConsumed = true
            -- Handle a second Humanoid already replicated before the
            -- removal event; never reattach to the old rig.
            task.defer(attachIfReady)
        end
    end)
    attachIfReady()
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
