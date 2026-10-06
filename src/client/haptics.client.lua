local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local mechanicEvent = remotes:WaitForChild("ArenaMechanicFeedback")
local impactEvent = remotes:WaitForChild("HazardImpactFeedback")
local nearMissEvent = remotes:WaitForChild("HazardNearMiss")
local shardEvent = remotes:WaitForChild("ChaosShardCollected")
local feedbackEvent = remotes:WaitForChild("RoundFeedback")
local stateEvent = remotes:WaitForChild("RoundState")

local lastPulseAt = 0
local lastFinalRush = false
local pulseToken = 0

local DEFAULT_MIN_PULSE_INTERVAL = 0.075
local REDUCED_MOTION_MIN_PULSE_INTERVAL = 0.12

local candidateInputs = {
    Enum.UserInputType.Gamepad1,
    Enum.UserInputType.Touch,
}

local function supported(inputType, motor)
    local okVibration, vibration = pcall(
        HapticService.IsVibrationSupported,
        HapticService,
        inputType
    )
    if not okVibration or vibration ~= true then
        return false
    end

    local okMotor, motorSupported = pcall(
        HapticService.IsMotorSupported,
        HapticService,
        inputType,
        motor
    )
    return okMotor and motorSupported == true
end

local function setMotor(inputType, motor, strength)
    pcall(
        HapticService.SetMotor,
        HapticService,
        inputType,
        motor,
        math.clamp(strength, 0, 1)
    )
end

local function pulse(strength, duration, large)
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local now = os.clock()
    local minInterval = reducedMotion
        and REDUCED_MOTION_MIN_PULSE_INTERVAL
        or DEFAULT_MIN_PULSE_INTERVAL

    if now - lastPulseAt < minInterval then
        return
    end

    local scale = reducedMotion and 0.40 or 1
    local amount = math.clamp((tonumber(strength) or 0) * scale, 0, 1)
    if amount <= 0 then
        return
    end

    local requestedMotor = large and Enum.VibrationMotor.Large or Enum.VibrationMotor.Small
    local targets = {}

    for _, inputType in ipairs(candidateInputs) do
        local relevant = (inputType == Enum.UserInputType.Touch and UserInputService.TouchEnabled)
            or (inputType == Enum.UserInputType.Gamepad1 and UserInputService.GamepadEnabled)

        if relevant and supported(inputType, requestedMotor) then
            table.insert(targets, {
                inputType = inputType,
                motor = requestedMotor,
                amount = amount,
            })
        elseif relevant and large and supported(inputType, Enum.VibrationMotor.Small) then
            table.insert(targets, {
                inputType = inputType,
                motor = Enum.VibrationMotor.Small,
                amount = amount * 0.86,
            })
        end
    end

    -- Do not invalidate the cleanup token of an active pulse unless this pulse
    -- can actually drive at least one motor.
    if #targets == 0 then
        return
    end

    lastPulseAt = now
    pulseToken += 1
    local token = pulseToken

    for _, target in ipairs(targets) do
        -- Explicitly stop either motor before switching intensity/type so a
        -- previous overlapping pulse cannot leave a motor latched on.
        setMotor(target.inputType, Enum.VibrationMotor.Large, 0)
        setMotor(target.inputType, Enum.VibrationMotor.Small, 0)
        setMotor(target.inputType, target.motor, target.amount)
    end

    task.delay(math.clamp(tonumber(duration) or 0.08, 0.03, 0.22), function()
        if token ~= pulseToken then
            return
        end
        for _, target in ipairs(targets) do
            setMotor(target.inputType, Enum.VibrationMotor.Large, 0)
            setMotor(target.inputType, Enum.VibrationMotor.Small, 0)
        end
    end)
end

mechanicEvent.OnClientEvent:Connect(function(payload)
    pulse(type(payload) == "table" and payload.overdrive == true and 0.42 or 0.28, 0.07, false)
end)

impactEvent.OnClientEvent:Connect(function(payload)
    if typeof(payload) ~= "table" or typeof(payload.position) ~= "Vector3" then
        return
    end

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local radius = math.max(1, tonumber(payload.radius) or 8)
    local reach = math.max(22, radius * 5.2)
    local distance = (root.Position - payload.position).Magnitude
    if distance > reach then
        return
    end

    local proximity = 1 - math.clamp(distance / reach, 0, 1)
    pulse(0.18 + proximity * 0.62, 0.06 + proximity * 0.08, proximity > 0.52)
end)

nearMissEvent.OnClientEvent:Connect(function()
    pulse(0.24, 0.045, false)
end)

shardEvent.OnClientEvent:Connect(function(payload)
    pulse(payload and payload.golden == true and 0.34 or 0.17, 0.045, false)
end)

feedbackEvent.OnClientEvent:Connect(function(feedback)
    if feedback.survived == true then
        pulse(0.30, 0.10, false)
        if player:GetAttribute("ReduceMotion") ~= true then
            task.delay(0.12, function()
                pulse(0.20, 0.07, false)
            end)
        end
    else
        pulse(0.34, 0.10, true)
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    local finalRush = state.phase == "round" and state.finalRush == true
    if finalRush and not lastFinalRush then
        pulse(0.30, 0.08, false)
    end
    lastFinalRush = finalRush
end)
