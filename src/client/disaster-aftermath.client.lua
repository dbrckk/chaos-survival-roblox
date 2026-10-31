local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterAftermathTone = require(ReplicatedStorage.Shared.DisasterAftermathTone)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local tint = Lighting:FindFirstChild("ChaosAftermathTint")
if tint and not tint:IsA("ColorCorrectionEffect") then
    tint:Destroy()
    tint = nil
end
if not tint then
    tint = Instance.new("ColorCorrectionEffect")
end
tint.Name = "ChaosAftermathTint"
tint.Enabled = true
tint.Brightness = 0
tint.Contrast = 0
tint.Saturation = 0
tint.TintColor = Color3.new(1, 1, 1)
tint.Parent = Lighting

local blur = Lighting:FindFirstChild("ChaosAftermathBlur")
if blur and not blur:IsA("BlurEffect") then
    blur:Destroy()
    blur = nil
end
if not blur then
    blur = Instance.new("BlurEffect")
end
blur.Name = "ChaosAftermathBlur"
blur.Enabled = true
blur.Size = 0
blur.Parent = Lighting

local lastPhase = "waiting"
local lastDisasters = {}
local lastRoundNumber = nil
local token = 0
local tintTween = nil
local blurTween = nil

local function cancelTweens()
    if tintTween then
        tintTween:Cancel()
        tintTween = nil
    end
    if blurTween then
        blurTween:Cancel()
        blurTween = nil
    end
end

local function reset(duration)
    cancelTweens()

    tintTween = TweenService:Create(
        tint,
        TweenInfo.new(duration or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
            TintColor = Color3.new(1, 1, 1),
        }
    )
    blurTween = TweenService:Create(
        blur,
        TweenInfo.new(duration or 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = 0}
    )
    tintTween:Play()
    blurTween:Play()
end

local function playAftermath(ids)
    local quality = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local profile = DisasterAftermathTone.presentation(
        ids, quality.Name, player:GetAttribute("ReduceMotion") == true)
    if not profile then return end

    token += 1
    local current = token

    cancelTweens()
    tint.TintColor = Color3.new(1, 1, 1)
    tint.Saturation = 0
    tint.Contrast = 0
    blur.Size = 0

    tintTween = TweenService:Create(
        tint,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            TintColor = profile.Tint,
            Saturation = profile.Saturation,
            Contrast = profile.Contrast,
        }
    )
    blurTween = TweenService:Create(
        blur,
        TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = profile.Blur}
    )
    tintTween:Play()
    blurTween:Play()

    task.delay(profile.Hold, function()
        if current == token then
            reset(profile.Release)
        end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local phase = tostring(state.phase or "waiting")
    local incoming = tonumber(state.roundNumber)
    if not incoming or incoming ~= incoming or incoming <= 0
        or incoming == math.huge or incoming ~= math.floor(incoming) then
        incoming = nil
    end
    -- A late old snapshot must not roll back post-round color treatment.
    if incoming and lastRoundNumber and incoming < lastRoundNumber then
        return
    end
    local newRound = incoming ~= nil and lastRoundNumber ~= nil
        and incoming ~= lastRoundNumber
    if incoming then lastRoundNumber = incoming end

    if phase == "round" then
        -- Keep the final disaster mix current without creating two new
        -- Tweens on EVERY per-second RoundState heartbeat.
        lastDisasters = type(state.disasterIds) == "table"
            and table.clone(state.disasterIds) or {}
        if lastPhase ~= "round" or newRound then
            token += 1
            reset(0.18)
        end
    elseif lastPhase == "round" and phase == "result" then
        playAftermath(lastDisasters)
    elseif phase ~= "result" and (phase ~= lastPhase or newRound) then
        -- Do not repeatedly cancel/recreate neutral tweens throughout
        -- an idle lobby, READY countdown or intermission.
        token += 1
        reset(0.35)
    end

    lastPhase = phase
end)
