local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local ResultPresentation = require(ReplicatedStorage.Shared.ResultPresentation)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ResultConstellationLocal"
folder.Parent = workspace

local trackedAttachments = {}
local previousPhase = "waiting"
local lastState = nil
local buildToken = 0

local function clear()
    buildToken += 1
    for _, attachment in ipairs(trackedAttachments) do
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end
    table.clear(trackedAttachments)
    folder:ClearAllChildren()
end

local function makePart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material
    part.Color = color
    part.Transparency = transparency
    part.Parent = folder
    return part
end

local function validModel(model)
    local root = model and model:FindFirstChild("HumanoidRootPart")
    local humanoid = model and model:FindFirstChildOfClass("Humanoid")
    if not model
        or not root
        or not root:IsA("BasePart")
        or not humanoid
        or humanoid.Health <= 0
    then
        return nil
    end
    return root
end

local function collectSurvivors(state, budget)
    local result = {}
    local seen = {}

    local ids = type(state.survivorUserIds) == "table"
        and state.survivorUserIds
        or {}

    for _, userId in ipairs(ids) do
        local numericId = tonumber(userId)
        local target = numericId and Players:GetPlayerByUserId(numericId) or nil
        local root = target and validModel(target.Character)
        if target and root then
            local key = "player:" .. tostring(target.UserId)
            seen[key] = true
            table.insert(result, {
                key = key,
                model = target.Character,
                root = root,
                localPlayer = target == player,
            })
        end
    end

    local aiFolder = workspace:FindFirstChild("AISurvivors")
    if aiFolder then
        local ai = {}
        for _, model in ipairs(aiFolder:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("AISurvivor") == true then
                local root = validModel(model)
                if root then
                    table.insert(ai, {
                        slot = math.max(
                            0,
                            math.floor(tonumber(model:GetAttribute("AISurvivorSlot")) or 0)
                        ),
                        model = model,
                        root = root,
                    })
                end
            end
        end
        table.sort(ai, function(a, b)
            return a.slot < b.slot
        end)
        for _, item in ipairs(ai) do
            local key = "ai:" .. tostring(item.slot)
            if not seen[key] then
                table.insert(result, {
                    key = key,
                    model = item.model,
                    root = item.root,
                    localPlayer = false,
                })
            end
        end
    end

    table.sort(result, function(a, b)
        if a.localPlayer ~= b.localPlayer then
            return a.localPlayer
        end
        return a.key < b.key
    end)

    while #result > budget do
        table.remove(result)
    end

    return result
end

local function addGroupLabel(centerAnchor, state, survivorCount, accentColor)
    local gui = Instance.new("BillboardGui")
    gui.Name = "ResultConstellationLabel"
    gui.Adornee = centerAnchor
    gui.AlwaysOnTop = false
    gui.LightInfluence = 0
    gui.Size = UDim2.fromOffset(360, 86)
    gui.StudsOffsetWorldSpace = Vector3.new(0, 8.6, 0)
    gui.MaxDistance = 170
    gui.Parent = centerAnchor

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = UITheme.Colors.Panel
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.Parent = gui
    UITheme.addCorner(panel, UITheme.Corners.Large)
    UITheme.addStroke(panel, accentColor, 1.4, 0.24)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromScale(0.05, 0.10)
    title.Size = UDim2.fromScale(0.90, 0.38)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.Text = survivorCount == 1
        and CoreLocalization.text(localeId, "RESULT_SOLE_SURVIVOR")
        or CoreLocalization.text(localeId, "RESULT_SURVIVOR_COUNT", survivorCount)
    title.TextColor3 = accentColor
    title.TextScaled = true
    title.Parent = panel
    UITheme.addTextConstraint(title, 15, 24)

    local disasterName = CoreLocalization.hazardTitle(
        localeId,
        state.disasterIds,
        tostring(state.title or "CHAOS")
    )
    local arenaName = CoreLocalization.arenaName(
        localeId,
        state.arenaId or state.arenaName,
        state.arenaName or "ARENA"
    )

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromScale(0.05, 0.58)
    subtitle.Size = UDim2.fromScale(0.90, 0.22)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.GothamBold
    subtitle.Text = tostring(disasterName) .. "  •  " .. tostring(arenaName)
    subtitle.TextColor3 = UITheme.Colors.Muted
    subtitle.TextScaled = true
    subtitle.TextWrapped = true
    subtitle.Parent = panel
    UITheme.addTextConstraint(subtitle, 10, 15)
end

local function addSurvivorPedestal(item, accentColor, secondaryColor, tier, reducedMotion)
    local root = item.root
    if not root or not root.Parent then
        return
    end

    local radius = item.localPlayer and 6.4 or 5.2
    local ring = makePart(
        "ResultSurvivorPedestal_" .. item.key,
        Vector3.new(0.055, radius, radius),
        CFrame.new(root.Position + Vector3.new(0, -2.65, 0))
            * CFrame.Angles(0, 0, math.rad(90)),
        item.localPlayer and secondaryColor or accentColor,
        Enum.Material.Neon,
        reducedMotion and 0.64 or 0.42
    )

    if not reducedMotion then
        local target = ring.Size
        ring.Size = Vector3.new(target.X, target.Y * 0.48, target.Z * 0.48)
        TweenService:Create(
            ring,
            TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = target, Transparency = 0.72}
        ):Play()
    end

    if tier.Name == "High" then
        local light = Instance.new("PointLight")
        light.Name = "ResultPedestalGlow"
        light.Color = ring.Color
        light.Brightness = 0.48
        light.Range = 7
        light.Shadows = false
        light.Parent = ring
    end
end

local function rebuild(state)
    clear()
    lastState = state

    if not state or tostring(state.phase or "") ~= "result" then
        return
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not base or not base:IsA("BasePart") then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local budget = ResultPresentation.constellationBudget(tier.Name)
    local survivors = collectSurvivors(state, budget)
    if #survivors == 0 then
        return
    end

    buildToken += 1
    local token = buildToken
    local variant = tostring(arena:GetAttribute("VariantId") or state.arenaId or "Classic")
    local theme = VisualTheme.arena(variant)
    local accentColor = #survivors == 1
        and UITheme.Colors.Gold
        or theme.Accent
    local secondaryColor = #survivors == 1
        and UITheme.Colors.Cyan
        or theme.Secondary

    local center = base.Position
        + Vector3.new(0, base.Size.Y * 0.5 + 0.15, 0)
    local radius = ResultPresentation.constellationRadius(tier.Name)

    local halo = makePart(
        "ResultConstellationHalo",
        Vector3.new(0.065, radius * 2, radius * 2),
        CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90)),
        accentColor,
        Enum.Material.Neon,
        reducedMotion and 0.70 or 0.46
    )

    if not reducedMotion then
        local target = halo.Size
        halo.Size = Vector3.new(target.X, 2.4, 2.4)
        TweenService:Create(
            halo,
            TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size = target, Transparency = 0.78}
        ):Play()
    end

    local core = makePart(
        "ResultConstellationCore",
        Vector3.new(0.16, 2.8, 2.8),
        CFrame.new(center + Vector3.new(0, 0.05, 0))
            * CFrame.Angles(0, 0, math.rad(90)),
        secondaryColor,
        Enum.Material.Neon,
        0.34
    )

    if tier.Name ~= "Low" then
        local coreLight = Instance.new("PointLight")
        coreLight.Name = "ResultConstellationGlow"
        coreLight.Color = accentColor
        coreLight.Brightness = tier.Name == "High" and 1.05 or 0.62
        coreLight.Range = tier.Name == "High" and 19 or 14
        coreLight.Shadows = false
        coreLight.Parent = core
    end

    local centerAnchor = Instance.new("Part")
    centerAnchor.Name = "ResultConstellationAnchor"
    centerAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
    centerAnchor.Position = center + Vector3.new(0, 2.8, 0)
    centerAnchor.Anchored = true
    centerAnchor.CanCollide = false
    centerAnchor.CanTouch = false
    centerAnchor.CanQuery = false
    centerAnchor.CastShadow = false
    centerAnchor.Transparency = 1
    centerAnchor.Parent = folder

    local hubAttachment = Instance.new("Attachment")
    hubAttachment.Name = "ResultConstellationHub"
    hubAttachment.Parent = centerAnchor

    addGroupLabel(centerAnchor, state, #survivors, accentColor)

    for index, item in ipairs(survivors) do
        if token ~= buildToken then
            return
        end

        local root = item.root
        if root and root.Parent then
            local attachment = Instance.new("Attachment")
            attachment.Name = "ResultConstellationTargetLocal"
            attachment.Parent = root
            table.insert(trackedAttachments, attachment)

            local beam = Instance.new("Beam")
            beam.Name = "ResultConstellationLink" .. tostring(index)
            beam.Attachment0 = hubAttachment
            beam.Attachment1 = attachment
            beam.FaceCamera = true
            beam.LightEmission = 0.85
            beam.LightInfluence = 0
            beam.Segments = 1
            beam.Width0 = tier.Name == "Low" and 0.035 or 0.055
            beam.Width1 = item.localPlayer and 0.085 or (tier.Name == "High" and 0.065 or 0.050)
            beam.Color = ColorSequence.new(
                accentColor,
                item.localPlayer and secondaryColor or theme.Secondary
            )
            beam.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.76),
                NumberSequenceKeypoint.new(0.5, tier.Name == "Low" and 0.82 or 0.64),
                NumberSequenceKeypoint.new(1, item.localPlayer and 0.40 or 0.56),
            })
            beam.Parent = centerAnchor

            addSurvivorPedestal(
                item,
                accentColor,
                secondaryColor,
                tier,
                reducedMotion
            )
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local phase = tostring(state.phase or "waiting")
    lastState = state

    if phase == "result" and previousPhase ~= "result" then
        task.delay(0.10, function()
            if lastState == state then
                rebuild(state)
            end
        end)
    elseif phase ~= "result" and previousPhase == "result" then
        clear()
    end

    previousPhase = phase
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    if lastState and tostring(lastState.phase or "") == "result" then
        rebuild(lastState)
    end
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    if lastState and tostring(lastState.phase or "") == "result" then
        rebuild(lastState)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
    end
end)
