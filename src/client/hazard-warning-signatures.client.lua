local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "HazardWarningSignaturesLocal"
folder.Parent = workspace

local disappearingActive = false
local platformHighlights = {}

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function localPart(name, size, cframe, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency or 0.3
    part.Parent = folder
    return part
end

local function warningDuration(warning, fallback)
    return math.clamp(
        tonumber(warning:GetAttribute("WarningDuration")) or fallback,
        0.25,
        2.5
    )
end

local function meteorSignature(warning)
    local tier = profile()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local duration = warningDuration(warning, 0.9)

    local column = localPart(
        "MeteorIncomingColumn",
        Vector3.new(0.45, 18, 0.45),
        CFrame.new(warning.Position + Vector3.new(0, 9, 0)),
        Color3.fromRGB(255, 145, 55),
        tier.Name == "Low" and 0.58 or 0.40
    )

    TweenService:Create(
        column,
        TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {
            Size = reduced
                and Vector3.new(0.55, 21, 0.55)
                or Vector3.new(0.75, 28, 0.75),
            Transparency = reduced and 0.74 or 0.88,
        }
    ):Play()
    Debris:AddItem(column, duration + 0.08)

    if tier.Name ~= "Low" and not reduced then
        local cap = localPart(
            "MeteorIncomingCap",
            Vector3.new(2.4, 0.20, 2.4),
            CFrame.new(warning.Position + Vector3.new(0, 17.5, 0)),
            Color3.fromRGB(255, 210, 100),
            0.34
        )
        cap.Shape = Enum.PartType.Ball
        TweenService:Create(
            cap,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Position = warning.Position + Vector3.new(0, 3, 0),
                Transparency = 0.92,
            }
        ):Play()
        Debris:AddItem(cap, duration + 0.08)
    end
end

local function bombSignature(warning)
    local tier = profile()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local duration = warningDuration(warning, 1.25)
    local length = tier.Name == "Low" and 6.5 or 8.5

    local armA = localPart(
        "BombCrossA",
        Vector3.new(length, 0.11, 0.55),
        CFrame.new(warning.Position + Vector3.new(0, 0.14, 0)),
        Color3.fromRGB(255, 65, 65),
        0.28
    )
    local arms = {armA}

    if tier.Name ~= "Low" and not reduced then
        local armB = localPart(
            "BombCrossB",
            Vector3.new(0.55, 0.11, length),
            CFrame.new(warning.Position + Vector3.new(0, 0.14, 0)),
            Color3.fromRGB(255, 115, 80),
            0.28
        )
        table.insert(arms, armB)
    end

    for index, arm in ipairs(arms) do
        if reduced then
            TweenService:Create(
                arm,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                {Transparency = 0.58}
            ):Play()
        else
            TweenService:Create(
                arm,
                TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {
                    Size = index == 1
                        and Vector3.new(length * 0.42, 0.11, 0.55)
                        or Vector3.new(0.55, 0.11, length * 0.42),
                    Transparency = 0.76,
                }
            ):Play()
        end
        Debris:AddItem(arm, duration + 0.08)
    end
end

local function jumpShockSignature(warning)
    local tier = profile()
    local reduced = player:GetAttribute("ReduceMotion") == true
    local duration = warningDuration(warning, 0.65)
    local count = reduced and 1 or (tier.Name == "Low" and 1 or 2)

    for i = 1, count do
        local ring = localPart(
            "JumpShockSignature" .. i,
            Vector3.new(0.10, 8 + (i - 1) * 4, 8 + (i - 1) * 4),
            CFrame.new(warning.Position + Vector3.new(0, 0.08 + i * 0.04, 0))
                * CFrame.Angles(0, 0, math.rad(90)),
            i == 1 and Color3.fromRGB(75, 165, 255) or Color3.fromRGB(170, 220, 255),
            0.34 + (i - 1) * 0.12
        )
        ring.Shape = Enum.PartType.Cylinder

        TweenService:Create(
            ring,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Size = Vector3.new(
                    0.10,
                    90 + (i - 1) * 18,
                    90 + (i - 1) * 18
                ),
                Transparency = 0.90,
            }
        ):Play()
        Debris:AddItem(ring, duration + 0.08)
    end
end

local function bindWarning(instance)
    if not instance:IsA("BasePart") then
        return
    end

    if instance.Name == "MeteorWarning" then
        task.defer(function()
            if instance.Parent then
                meteorSignature(instance)
            end
        end)
    elseif instance.Name == "BombWarning" then
        task.defer(function()
            if instance.Parent then
                bombSignature(instance)
            end
        end)
    elseif instance.Name == "JumpShockWarning" then
        task.defer(function()
            if instance.Parent then
                jumpShockSignature(instance)
            end
        end)
    end
end

workspace.ChildAdded:Connect(bindWarning)

local function removePlatformHighlight(part)
    local highlight = platformHighlights[part]
    if highlight then
        platformHighlights[part] = nil
        if highlight.Parent then
            highlight:Destroy()
        end
    end
end

local function updatePlatformHighlights()
    if not disappearingActive then
        for part in pairs(platformHighlights) do
            removePlatformHighlight(part)
        end
        return
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not platforms then
        return
    end

    local tier = profile()
    local seen = {}

    for _, part in ipairs(platforms:GetChildren()) do
        if part:IsA("BasePart")
            and part.Material == Enum.Material.Neon
            and part.Transparency < 0.75
        then
            seen[part] = true
            if not platformHighlights[part] then
                local highlight = Instance.new("Highlight")
                highlight.Name = "DisappearingPlatformWarningLocal"
                highlight.Adornee = part
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.FillColor = Color3.fromRGB(255, 190, 45)
                highlight.OutlineColor = Color3.fromRGB(255, 235, 120)
                highlight.FillTransparency = tier.Name == "Low" and 0.92 or 0.84
                highlight.OutlineTransparency = tier.Name == "Low" and 0.36 or 0.18
                highlight.Parent = folder
                platformHighlights[part] = highlight
            end
        end
    end

    for part in pairs(platformHighlights) do
        if not seen[part] or not part.Parent then
            removePlatformHighlight(part)
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local active = false
    if state.phase == "round" then
        for _, id in ipairs(state.disasterIds or {}) do
            if id == "DisappearingPlatforms" then
                active = true
                break
            end
        end
    end
    disappearingActive = active
    if not active then
        updatePlatformHighlights()
    end
end)

task.spawn(function()
    while true do
        if disappearingActive then
            updatePlatformHighlights()
            task.wait(0.12)
        else
            task.wait(0.35)
        end
    end
end)
