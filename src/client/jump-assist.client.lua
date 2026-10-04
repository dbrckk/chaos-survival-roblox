local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MovementAssistRules = require(ReplicatedStorage.Shared.MovementAssistRules)

local player = Players.LocalPlayer
local character = nil
local humanoid = nil
local floorConnection = nil
local stateConnection = nil
local lastGroundedAt = -math.huge
local bufferedUntil = -math.huge
local coyoteConsumed = false

local function disconnect()
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
end

local function jumpEnabled(h)
    return h
        and h.Health > 0
        and (h.JumpPower > 0 or h.JumpHeight > 0)
end

local function requestAssistedJump()
    if not humanoid or not humanoid.Parent then
        return
    end

    local now = os.clock()
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    local state = humanoid:GetState()

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
            jumpEnabled(humanoid)
        )
    then
        coyoteConsumed = true
        bufferedUntil = -math.huge
        humanoid.Jump = true
        return
    end

    if MovementAssistRules.stateAllowsJump(state)
        and jumpEnabled(humanoid)
    then
        bufferedUntil = MovementAssistRules.bufferUntil(now)
    end
end

local function bindCharacter(nextCharacter)
    disconnect()

    character = nextCharacter
    humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then
        return
    end

    if humanoid.FloorMaterial ~= Enum.Material.Air then
        lastGroundedAt = os.clock()
        coyoteConsumed = false
    else
        lastGroundedAt = -math.huge
        coyoteConsumed = true
    end
    bufferedUntil = -math.huge

    floorConnection = humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
        if not humanoid then
            return
        end

        if humanoid.FloorMaterial ~= Enum.Material.Air then
            local now = os.clock()
            lastGroundedAt = now
            coyoteConsumed = false

            if MovementAssistRules.bufferActive(now, bufferedUntil)
                and jumpEnabled(humanoid)
                and MovementAssistRules.stateAllowsJump(humanoid:GetState())
            then
                bufferedUntil = -math.huge
                task.defer(function()
                    if humanoid and humanoid.Parent then
                        humanoid.Jump = true
                    end
                end)
            end
        end
    end)

    stateConnection = humanoid.StateChanged:Connect(function(_, state)
        if state == Enum.HumanoidStateType.Dead
            or state == Enum.HumanoidStateType.Seated
            or state == Enum.HumanoidStateType.Swimming
        then
            bufferedUntil = -math.huge
        end
    end)
end

UserInputService.JumpRequest:Connect(requestAssistedJump)

if player.Character then
    task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)
player.CharacterRemoving:Connect(disconnect)
