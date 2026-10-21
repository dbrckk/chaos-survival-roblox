local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local HazardGlyphs = require(ReplicatedStorage.Shared.HazardGlyphs)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local HazardWarningSignatureRules = require(ReplicatedStorage.Shared.HazardWarningSignatureRules)
local GroundOutline = require(script.Parent.HazardGroundOutlineKit)

local player = Players.LocalPlayer
local tracked = {}
local localDecor = Instance.new("Folder")
localDecor.Name = "ChaosHazardWarningDecorLocal"
localDecor.Parent = workspace
local currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
local loopStarted = false
local warningNames = {
    BombWarning = true,
    MeteorWarning = true,
    FreezeWarning = true,
    JumpShockWarning = true,
}

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end)

local function warningDeckFrame(part, deck)
    return HazardWarningSignatureRules.frame(part.Position, deck)
end

local function destroySignature(state)
    if not state or not state.signature then return end
    for _, piece in ipairs(state.signature) do
        if piece.Parent then piece:Destroy() end
    end
end

-- Reconcile against live quality/accessibility without duplicating objects.
-- Existing pieces are retained where possible; old excess pieces are removed
-- on the very next render update when the player lowers their quality tier.
local function syncShockSignature(part, state, diameter, progress, reduced)
    if state.kind ~= "JumpShock" then return end
    local count = HazardWarningSignatureRules.count(
        "JumpShock", currentTier.Name, reduced
    )
    local pieces = state.signature
    if not pieces then return end
    while #pieces > count do
        local extra = table.remove(pieces)
        if extra and extra.Parent then extra:Destroy() end
    end
    local centerFrame = warningDeckFrame(part, state.deck)
    for index = 1, count do
        local design = HazardWarningSignatureRules.recipe(
            "JumpShock", index, count, diameter, reduced and 0 or progress
        )
        local piece = pieces[index]
        if not piece then
            piece = Instance.new("Part")
            piece.Name = "JumpShockAngularWarning" .. index
            piece.Anchored = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.CastShadow = false
            piece.Parent = localDecor
            pieces[index] = piece
        end
        piece.Size = design.Size
        piece.CFrame = centerFrame * CFrame.new(design.Offset) * design.Rotation
        piece.Material = design.Material
        piece.Color = design.Secondary and design.SecondaryColor or design.Color
        piece.Transparency = reduced and 0.67 or design.Transparency
    end
end


local function ensureRenderLoop()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            if next(tracked) == nil then
                task.wait(0.18)
                continue
            end

            currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
            task.wait(math.max(1 / 30, currentTier.UpdateInterval))

            -- All simultaneous warnings must use the SAME authoritative
            -- server-time snapshot: fewer engine calls and synchronized
            -- countdown rings during Bomb Rain + Meteor Shower.
            local serverNow = workspace:GetServerTimeNow()
            local reduced = player:GetAttribute("ReduceMotion") == true
            for part, state in pairs(tracked) do
                if not part.Parent then
                    if state.ring then
                        GroundOutline.destroy(state.ring)
                    end
                    if state.label and state.label.Parent then
                        state.label:Destroy()
                    end
                    destroySignature(state)
                    tracked[part] = nil
                    continue
                end

                local alpha = math.clamp(
                    (serverNow - state.startedAt) / state.duration,
                    0,
                    1
                )
                local pulse = reduced
                    and 0.5
                    or ((math.sin(alpha * math.pi * 6) + 1) * 0.5)

                if state.kind == "Freeze" then
                    local freezePeak = 0.12 * currentTier.Scale
                    part.Transparency = reduced and 0.82 or math.clamp(
                        0.84 - (freezePeak * math.sin(alpha * math.pi)),
                        0.69,
                        0.92
                    )
                elseif state.kind == "JumpShock" then
                    -- In ReduceMotion, show the final hazard coverage at once
                    -- instead of sweeping a large luminous disc across sightlines.
                    local diameter = HazardWarningSignatureRules.visualDiameter(
                        state.startSize, state.endSize, alpha, reduced
                    )
                    part.Size = Vector3.new(part.Size.X, diameter, diameter)
                    part.Transparency = reduced and 0.78
                        or (0.62 + 0.27 * alpha)

                    syncShockSignature(part, state, diameter, alpha, reduced)
                else
                    local diameter = HazardWarningSignatureRules.visualDiameter(
                        state.startSize, state.endSize, alpha, reduced
                    )
                    part.Size = Vector3.new(diameter, part.Size.Y, diameter)
                    -- An opaque warning disc conceals the platform edges
                    -- and any escape route. Keep a restrained fill, with
                    -- the strong hollow perimeter as the primary signal.
                    local base = state.kind == "Meteor" and 0.69 or 0.66
                    part.Transparency = reduced and 0.62
                        or math.clamp(base - alpha * 0.10 - pulse * 0.05, 0.47, 0.78)

                    if state.ring then
                        -- Hollow world-space surface contours preserve the
                        -- arena floor and avoid a duplicate solid disc.
                        GroundOutline.update(
                            state.ring, part.Position, diameter,
                            alpha, reduced, pulse, currentTier.Name
                        )
                    end
                end

                if state.label and state.label.Parent then
                    state.label.StudsOffsetWorldSpace = Vector3.new(
                        0,
                        reduced and 2.66 or (2.6 + pulse * 0.18),
                        0
                    )
                    -- Registered warning labels do not change identity.
                    -- Avoid an Instance tree search on every 30 Hz tick
                    -- for every simultaneous hazard.
                    local text = state.warningText
                    if text and text.Parent then
                        text.TextTransparency = reduced and 0.02
                            or math.clamp(0.02 + alpha * 0.22, 0, 1)
                        text.TextStrokeTransparency = reduced and 0.42
                            or math.clamp(0.42 + alpha * 0.30, 0, 1)
                    end
                end

                if alpha >= 1 then
                    if state.ring then
                        GroundOutline.destroy(state.ring)
                    end
                    if state.label and state.label.Parent then
                        state.label:Destroy()
                    end
                    destroySignature(state)
                    tracked[part] = nil
                end
            end
        end
    end)
end

local WARNING_GLYPH_IDS = {
    Meteor = "Meteors",
    Bomb = "Bombs",
    Freeze = "Freeze",
    JumpShock = "JumpShock",
}

local function addWarningGlyph(parent, kind, color)
    local hazardId = WARNING_GLYPH_IDS[kind]
    local recipe = hazardId and HazardGlyphs.get(hazardId) or nil
    if not recipe then
        return
    end

    local glyph = Instance.new("Frame")
    glyph.Name = "WarningGlyph"
    glyph.AnchorPoint = Vector2.new(0, 0.5)
    glyph.Position = UDim2.fromScale(0.035, 0.5)
    glyph.Size = UDim2.fromScale(0.22, 0.72)
    glyph.BackgroundColor3 = color:Lerp(Color3.fromRGB(12, 16, 24), 0.70)
    glyph.BackgroundTransparency = 0.12
    glyph.BorderSizePixel = 0
    glyph.ZIndex = 2
    glyph.Parent = parent

    local glyphCorner = Instance.new("UICorner")
    glyphCorner.CornerRadius = UDim.new(0, 7)
    glyphCorner.Parent = glyph

    local canvas = Instance.new("Frame")
    canvas.AnchorPoint = Vector2.new(0.5, 0.5)
    canvas.Position = UDim2.fromScale(0.5, 0.5)
    canvas.Size = UDim2.fromScale(0.72, 0.72)
    canvas.BackgroundTransparency = 1
    canvas.ZIndex = 2
    canvas.Parent = glyph

    for _, def in ipairs(recipe) do
        local segment = Instance.new("Frame")
        segment.AnchorPoint = Vector2.new(0.5, 0.5)
        segment.Position = UDim2.fromScale(def.X, def.Y)
        segment.Size = UDim2.fromScale(def.Width, def.Height)
        segment.Rotation = def.Rotation or 0
        segment.BackgroundColor3 = color
        segment.BackgroundTransparency = 0.04
        segment.BorderSizePixel = 0
        segment.ZIndex = 2
        segment.Parent = canvas

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = segment
    end
end

local function register(part, snapshot)
    if not part:IsA("BasePart") or tracked[part] or not snapshot then
        return
    end

    local kind = snapshot.Kind

    local ring = nil
    if kind == "Meteor" or kind == "Bomb" then
        ring = GroundOutline.create(localDecor, kind)
    end

    local signature = nil
    local signatureDeck = nil
    if kind == "JumpShock" then
        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        signatureDeck = base and base:IsA("BasePart") and base.CFrame or nil
        signature = {}
    end


    local label = Instance.new("BillboardGui")
    label.Name = kind .. "WarningLabelLocal"
    label.Adornee = part
    label.Size = UDim2.fromOffset(132, 32)
    label.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
    -- A dozen always-on-top world labels obscure the player's avatar on
    -- narrow Android cameras. Depth test labels, keep the ground ring.
    label.AlwaysOnTop = false
    label.LightInfluence = 0
    label.MaxDistance = currentTier.Name == "Low" and 68 or 105
    label.Parent = localDecor

    local warningText = Instance.new("TextLabel")
    warningText.Name = "WarningText"
    warningText.Size = UDim2.fromScale(1, 1)
    warningText.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
    warningText.BackgroundTransparency = 0.18
    warningText.BorderSizePixel = 0
    warningText.Font = Enum.Font.GothamBlack
    warningText.Text = HazardWarningSignatureRules.label(
        kind, player.LocaleId, CoreLocalization
    ) or string.upper(kind)
    warningText.TextColor3 = kind == "Bomb"
        and Color3.fromRGB(255, 120, 120)
        or (kind == "Meteor"
            and Color3.fromRGB(255, 205, 115)
            or Color3.fromRGB(170, 225, 255))
    warningText.TextScaled = true
    warningText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    warningText.TextStrokeTransparency = 0.42
    warningText.ZIndex = 1
    warningText.Parent = label

    local textPadding = Instance.new("UIPadding")
    textPadding.PaddingLeft = UDim.new(0, 38)
    textPadding.PaddingRight = UDim.new(0, 7)
    textPadding.Parent = warningText

    addWarningGlyph(warningText, kind, warningText.TextColor3)

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = warningText

    local stroke = Instance.new("UIStroke")
    stroke.Color = warningText.TextColor3
    stroke.Thickness = 1
    stroke.Transparency = 0.35
    stroke.Parent = warningText

    tracked[part] = {
        startedAt = snapshot.StartedAt,
        kind = kind,
        duration = snapshot.Duration,
        startSize = snapshot.StartSize,
        endSize = snapshot.EndSize,
        ring = ring,
        signature = signature,
        deck = signatureDeck,
        label = label,
        warningText = warningText,
    }

    -- Initial client appearance must also use the authoritative elapsed
    -- fraction; otherwise a late join first shows the wrong impact radius.
    local reduced = player:GetAttribute("ReduceMotion") == true
    local diameter = HazardWarningSignatureRules.visualDiameter(
        snapshot.StartSize, snapshot.EndSize, snapshot.Progress, reduced
    )
    if ring then
        -- A late-joining mobile client must not show the initial server
        -- disc while the local contour already reflects elapsed warning time.
        part.Size = Vector3.new(diameter, part.Size.Y, diameter)
        local pulse = reduced and 0.5
            or (math.sin(snapshot.Progress * math.pi * 6) + 1) * 0.5
        local base = kind == "Meteor" and 0.69 or 0.66
        part.Transparency = reduced and 0.62
            or math.clamp(base - snapshot.Progress * 0.10 - pulse * 0.05, 0.47, 0.78)
        GroundOutline.update(
            ring, part.Position, diameter, snapshot.Progress,
            reduced, pulse, currentTier.Name
        )
    elseif kind == "JumpShock" then
        -- Shock's cylinder uses Y/Z for its warning diameter. Match the
        -- replicated elapsed fraction on the first frame as well.
        part.Size = Vector3.new(part.Size.X, diameter, diameter)
        part.Transparency = reduced and 0.78
            or (0.62 + 0.27 * snapshot.Progress)
    elseif kind == "Freeze" and reduced then
        part.Transparency = 0.82
    end
    if kind == "JumpShock" then
        syncShockSignature(part, tracked[part], diameter, snapshot.Progress, reduced)
    end
    ensureRenderLoop()
end

-- Listen until the exact server metadata bundle has replicated. Timers are
-- not reliable here: slow Android networks may deliver WarningStartedAt or
-- the final diameter well after the warning instance itself.
local pendingWarnings = {}

local function disconnectPending(part)
    local connections = pendingWarnings[part]
    if not connections then return end
    pendingWarnings[part] = nil
    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
end

local function maybeRegister(part)
    if not part:IsA("BasePart") or not warningNames[part.Name]
        or part.Parent ~= workspace or tracked[part] then
        return
    end

    local snapshot = HazardWarningSignatureRules.snapshot(
        part, workspace:GetServerTimeNow()
    )
    if snapshot then
        disconnectPending(part)
        register(part, snapshot)
        return
    end
    if pendingWarnings[part] then return end

    local connections = {}
    pendingWarnings[part] = connections
    for _, name in ipairs({
        "WarningKind", "WarningStartedAt", "WarningDuration",
        "WarningStartSize", "WarningEndSize",
    }) do
        table.insert(connections,
            part:GetAttributeChangedSignal(name):Connect(function()
                if part.Parent == workspace then
                    maybeRegister(part)
                else
                    disconnectPending(part)
                end
            end))
    end
    -- Close the subscription race if metadata became complete while
    -- the five listeners were being installed.
    maybeRegister(part)
end

for _, child in ipairs(workspace:GetChildren()) do
    maybeRegister(child)
end

workspace.ChildAdded:Connect(maybeRegister)
workspace.ChildRemoved:Connect(function(child)
    disconnectPending(child)
    local state = tracked[child]
    if state and state.ring then
        GroundOutline.destroy(state.ring)
    end
    if state and state.label and state.label.Parent then
        state.label:Destroy()
    end
    destroySignature(state)
    tracked[child] = nil
end)
