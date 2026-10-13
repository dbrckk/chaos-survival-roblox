-- Client-only, budgeted physical warning signatures. The server warning
-- remains authoritative for impact position, lifetime, damage and collisions.
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local WarningRules = require(ReplicatedStorage.Shared.HazardWarningSignatureRules)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "HazardWarningSignaturesLocal"
folder.Parent = workspace

local disappearingActive = false
local platformHighlights = {}

local warningEntries = {}
local creationOrder = {}

local function profile()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function localPart(group, className, name, size, frame, color, transparency)
    local part = Instance.new(className)
    part.Name = name
    part.Size = size
    part.CFrame = frame
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency
    part.Parent = group
    return part
end

local function releaseWarning(warning)
    local entry = warningEntries[warning]
    if not entry then return end
    warningEntries[warning] = nil
    for _, connection in ipairs(entry.connections) do
        connection:Disconnect()
    end
    if entry.group then
        entry.group:Destroy()
    end
end

-- Warnings can overlap during Double Chaos. Evict only decorative signatures,
-- never the server warning, to keep the local part count bounded.
local function reserveSignature(tierName, reduced)
    for i = #creationOrder, 1, -1 do
        local entry = warningEntries[creationOrder[i]]
        if not entry or not entry.group or not entry.group.Parent then
            table.remove(creationOrder, i)
        end
    end
    local limit = WarningRules.activeLimit(tierName, reduced)
    while #creationOrder >= limit do
        local oldest = table.remove(creationOrder, 1)
        releaseWarning(oldest)
    end
end

local function meteorSignature(warning, group, tierName, reduced, remaining, progress)
    local duration = remaining
    local center = warning.Position
    local initialHeight = reduced and 21 or (18 + 10 * progress)
    local column = localPart(
        group, "Part", "MeteorIncomingColumn",
        Vector3.new(0.45 + 0.30 * progress, initialHeight, 0.45 + 0.30 * progress),
        CFrame.new(center + Vector3.new(0, initialHeight * 0.5, 0)),
        Color3.fromRGB(255, 145, 55),
        reduced and 0.62 or (tierName == "Low" and 0.58 or 0.40)
    )
    if not reduced then
        TweenService:Create(column,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {
                Size = Vector3.new(0.75, 28, 0.75),
                CFrame = CFrame.new(center + Vector3.new(0, 14, 0)),
                Transparency = 0.88,
            }
        ):Play()
    end

    if tierName ~= "Low" and not reduced then
        local startY = 17.5 + (3 - 17.5) * progress
        local cap = localPart(
            group, "Part", "MeteorIncomingCap",
            Vector3.new(2.4, 0.20, 2.4),
            CFrame.new(center + Vector3.new(0, startY, 0)),
            Color3.fromRGB(255, 210, 100), 0.34 + 0.58 * progress
        )
        cap.Shape = Enum.PartType.Ball
        TweenService:Create(cap,
            TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = center + Vector3.new(0, 3, 0), Transparency = 0.92}
        ):Play()

        -- Hand-authored angular incoming fracture fins: only High can
        -- afford both blades; never obscure the actual warning disc.
        if tierName == "High" then
            for side = -1, 1, 2 do
                local offset = Vector3.new(side * 1.35, 0, 0)
                local blade = localPart(
                    group, "WedgePart", "MeteorEntryFin",
                    Vector3.new(0.18, 0.78, 2.0),
                    CFrame.new(center + offset + Vector3.new(0, startY + 1.2, 0))
                        * CFrame.Angles(math.rad(side * 30), math.rad(side * 25), math.rad(side * 20)),
                    Color3.fromRGB(255, 179, 77), 0.46
                )
                TweenService:Create(blade,
                    TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {
                        Position = center + offset + Vector3.new(0, 3.9, 0),
                        Transparency = 0.94,
                    }
                ):Play()
            end
        end
    end
end

local function bombSignature(warning, group, tierName, reduced, remaining, progress)
    local center = warning.Position
    local length = tierName == "Low" and 6.5 or 8.5
    local displayedLength = reduced and length or (length * (1 - 0.58 * progress))
    local axes = tierName == "Low" and not reduced and 1 or 2

    for axis = 1, axes do
        local size = axis == 1
            and Vector3.new(displayedLength, 0.11, 0.55)
            or Vector3.new(0.55, 0.11, displayedLength)
        local arm = localPart(
            group, "Part", axis == 1 and "BombCrossA" or "BombCrossB",
            size, CFrame.new(center + Vector3.new(0, 0.14, 0)),
            axis == 1 and Color3.fromRGB(255, 65, 65)
                or Color3.fromRGB(255, 115, 80), reduced and 0.37 or 0.28
        )
        if not reduced then
            TweenService:Create(arm,
                TweenInfo.new(remaining, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
                {
                    Size = axis == 1
                        and Vector3.new(length * 0.42, 0.11, 0.55)
                        or Vector3.new(0.55, 0.11, length * 0.42),
                    Transparency = 0.76,
                }
            ):Play()
        end
    end

    -- A static bomb silhouette is safer for ReduceMotion. Otherwise the
    -- visual body starts at the correct position for the remaining warning.
    local startHeight = reduced and 4.2
        or (tierName == "Low" and 18 or 26)
            + (1.7 - (tierName == "Low" and 18 or 26)) * progress
    local body = localPart(
        group, "Part", "BombIncomingBody",
        Vector3.new(2.2, 2.2, 2.2),
        CFrame.new(center + Vector3.new(0, startHeight, 0)),
        Color3.fromRGB(62, 66, 76), reduced and 0.12 or 0.06
    )
    body.Shape = Enum.PartType.Ball
    body.Material = Enum.Material.Metal

    if not reduced then
        TweenService:Create(body,
            TweenInfo.new(remaining, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = center + Vector3.new(0, 1.7, 0), Transparency = 0.02}
        ):Play()
    end

    if tierName ~= "Low" and not reduced then
        local band = localPart(
            group, "Part", "BombIncomingBand",
            Vector3.new(2.55, 0.28, 2.55), body.CFrame,
            Color3.fromRGB(255, 72, 58), 0.30 + progress * 0.38
        )
        band.Shape = Enum.PartType.Cylinder
        band.CFrame = band.CFrame * CFrame.Angles(0, 0, math.rad(90))
        TweenService:Create(band,
            TweenInfo.new(remaining, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = center + Vector3.new(0, 1.7, 0), Transparency = 0.68}
        ):Play()

        if tierName == "High" then
            for side = -1, 1, 2 do
                local offset = Vector3.new(side * 1.25, 0.25, 0)
                local fin = localPart(
                    group, "WedgePart", "BombPressureFin",
                    Vector3.new(0.16, 1.0, 1.1),
                    CFrame.new(center + offset + Vector3.new(0, startHeight, 0))
                        * CFrame.Angles(0, 0, math.rad(side * 30)),
                    Color3.fromRGB(255, 116, 78), 0.34
                )
                TweenService:Create(fin,
                    TweenInfo.new(remaining, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    {
                        Position = center + offset + Vector3.new(0, 1.7, 0),
                        Transparency = 0.76,
                    }
                ):Play()
            end
        end
    end
end

local function tryPresent(warning)
    local entry = warningEntries[warning]
    if not entry or entry.rendered or warning.Parent ~= workspace then return end
    local kind = warning.Name == "MeteorWarning" and "Meteor" or "Bomb"
    if warning:GetAttribute("WarningKind") ~= kind then return end
    local remaining, progress = WarningRules.window(
        warning:GetAttribute("WarningStartedAt"),
        warning:GetAttribute("WarningDuration"),
        workspace:GetServerTimeNow()
    )
    if not remaining or remaining <= 0.05 then return end

    local tier = profile()
    local reduced = player:GetAttribute("ReduceMotion") == true
    reserveSignature(tier.Name, reduced)

    local group = Instance.new("Folder")
    group.Name = kind .. "WarningSignature"
    group.Parent = folder
    entry.rendered = true
    entry.group = group
    table.insert(creationOrder, warning)

    if kind == "Meteor" then
        meteorSignature(warning, group, tier.Name, reduced, remaining, progress)
    else
        bombSignature(warning, group, tier.Name, reduced, remaining, progress)
    end
    Debris:AddItem(group, remaining + 0.10)
end

local function bindWarning(warning)
    if not warning:IsA("BasePart")
        or (warning.Name ~= "MeteorWarning" and warning.Name ~= "BombWarning")
        or warningEntries[warning] then
        return
    end

    -- Do not assume WarningKind/StartedAt replicated with the Part.
    local entry = {rendered = false, group = nil, connections = {}}
    warningEntries[warning] = entry
    table.insert(entry.connections,
        warning:GetAttributeChangedSignal("WarningKind"):Connect(function()
            tryPresent(warning)
        end))
    table.insert(entry.connections,
        warning:GetAttributeChangedSignal("WarningStartedAt"):Connect(function()
            tryPresent(warning)
        end))
    table.insert(entry.connections,
        warning:GetAttributeChangedSignal("WarningDuration"):Connect(function()
            tryPresent(warning)
        end))
    task.defer(tryPresent, warning)
end

workspace.ChildAdded:Connect(bindWarning)
workspace.ChildRemoved:Connect(function(child)
    if warningEntries[child] then releaseWarning(child) end
end)
for _, child in ipairs(workspace:GetChildren()) do
    bindWarning(child)
end

-- Changes to motion or visual quality must apply to warning effects already
-- playing. Tear down their local artwork and recreate only the remainder
-- of the same server warning; do not extend the damage timer.
local function refreshWarningSignatures()
    local live = {}
    for warning in pairs(warningEntries) do
        table.insert(live, warning)
    end
    for _, warning in ipairs(live) do
        releaseWarning(warning)
    end
    table.clear(creationOrder)
    for _, warning in ipairs(live) do
        if warning.Parent == workspace then
            bindWarning(warning)
        end
    end
end

player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshWarningSignatures)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshWarningSignatures)

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
    if type(state) ~= "table" then return end
    local active = false
    if state.phase == "round" then
        for _, id in ipairs(
            type(state.disasterIds) == "table" and state.disasterIds or {}
        ) do
            if id == "DisappearingPlatforms" then
                active = true
                break
            end
        end
    else
        -- A round cancellation must also clean up any lingering local
        -- meteor/bomb signatures; the server warnings are untouched.
        local toRelease = {}
        for warning in pairs(warningEntries) do
            table.insert(toRelease, warning)
        end
        for _, warning in ipairs(toRelease) do
            releaseWarning(warning)
        end
        table.clear(creationOrder)
    end
    disappearingActive = active
    if not active then updatePlatformHighlights() end
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
