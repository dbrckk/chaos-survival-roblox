local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)
local UIResponsive = require(ReplicatedStorage.Shared.UIResponsive)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)
local CelebrationMeshes = require(script.Parent.LobbyCelebrationMeshes)

local player = Players.LocalPlayer
local french = string.sub(string.lower(LocalizationService.RobloxLocaleId), 1, 2) == "fr"
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChaosShardCollected")
local worldEffects = Instance.new("Folder")
worldEffects.Name = "ChaosShardVfxLocal"
worldEffects.Parent = workspace

local function quality()
    return VfxQuality.deviceTier(
        player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled
    )
end

local gui = Instance.new("ScreenGui")
gui.Name = "ChaosShardFeedback"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 24
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "Reward"
label.AnchorPoint = Vector2.new(0.5, 0.5)
-- Centered above the Android control cluster; player survival actions
-- remain unobstructed during an optional pickup.
label.Position = UDim2.fromScale(0.5, 0.66)
label.Size = UDim2.fromOffset(300, 54)
label.BackgroundColor3 = UITheme.Colors.Panel
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = ""
label.TextColor3 = UITheme.Colors.Cyan
label.TextStrokeTransparency = 0.65
label.TextScaled = true
label.TextWrapped = not UserInputService.TouchEnabled
label.TextTruncate = UserInputService.TouchEnabled
    and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
label.TextTransparency = 1
label.Visible = false
label.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = label

local stroke = Instance.new("UIStroke")
stroke.Color = UITheme.Colors.Violet
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = label

local scale = Instance.new("UIScale")
scale.Scale = 0.78
scale.Parent = label

local token = 0
local touchDevice = UserInputService.TouchEnabled
local pendingReward = nil
local rewardFits = true

local rewardTextLimit = UITheme.addTextConstraint(label, 12, 23)

local viewportConnection
local function updateRewardLayout()
    if not touchDevice then
        label.Position = UDim2.fromScale(0.5, 0.66)
        label.Size = UDim2.fromOffset(300, 54)
        rewardTextLimit.MaxTextSize = 23
        return
    end
    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    local layout = UIResponsive.mobileShardToast(viewport)
    label.Position = UDim2.fromScale(layout.centerXScale, layout.centerYScale)
    label.Size = UDim2.fromOffset(layout.width, layout.height)
    rewardTextLimit.MaxTextSize = 17
    rewardFits = layout.fits
    if not rewardFits and label.Visible then
        -- A viewport rotation can invalidate the lane while a toast is live.
        -- The gameplay reward remains authoritative on the server.
        token += 1
        label.Visible = false
        MobileHudNotices.release("shard")
    end
end

local function bindRewardCamera()
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    local camera = workspace.CurrentCamera
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize")
            :Connect(updateRewardLayout)
    end
    updateRewardLayout()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindRewardCamera)
bindRewardCamera()

local function worldBurst(position, reward, source)
    if typeof(position) ~= "Vector3" then
        return
    end

    local tier = quality()
    local golden = (tonumber(reward) or 1) >= 3
    local signal = source == "DistrictSignal"
    local supply = source == "DistrictCache"
    local cargo = source == "HarborCargo"
    local reduced = player:GetAttribute("ReduceMotion") == true
    -- The server source already distinguishes pickups; match that source
    -- with recognizably different shapes and color, not extra geometry.
    local primary = signal and Color3.fromRGB(255, 178, 72)
        or (supply and (golden and Color3.fromRGB(255, 222, 110)
            or Color3.fromRGB(109, 244, 193)))
        or (cargo and Color3.fromRGB(94, 226, 170))
        or (golden and Color3.fromRGB(255, 215, 75) or UITheme.Colors.Cyan)
    local secondary = signal and Color3.fromRGB(255, 107, 76)
        or (supply and (golden and Color3.fromRGB(240, 162, 75)
            or Color3.fromRGB(75, 193, 229)))
        or (cargo and Color3.fromRGB(82, 188, 227))
        or (golden and Color3.fromRGB(255, 145, 45) or UITheme.Colors.Violet)

    local pressure = player:GetAttribute("OptionalVfxPressure")
    local sculpted = tier.Name ~= "Low" and not reduced
    local fragment = sculpted and CelebrationMeshes.readyProfile("fragment", pressure)
    local core = CelebrationMeshes.cloneProfile(fragment) or Instance.new("Part")
    core.Name = "ShardPickupCoreLocal"
    if core:IsA("Part") then core.Shape = Enum.PartType.Ball end
    core.Size = Vector3.new(0.8, 0.8, 0.8)
    core.CFrame = CFrame.new(position)
    core.Anchored = true
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CastShadow = false
    core.Material = Enum.Material.Neon
    core.Color = primary
    core.Transparency = 0.04
    core.Parent = worldEffects

    local ringSource = sculpted and CelebrationMeshes.readyProfile("ring", pressure)
    local ring = CelebrationMeshes.disc(ringSource, position, 1.2, 0.10)
    ring.Name = "ShardPickupRingLocal"
    -- Live signals project a vertical radio-wave ring; supply crates and
    -- collectible shards retain their familiar horizontal pickup rings.
    if signal then
        ring.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(45), 0)
            * (ring:IsA("MeshPart") and CFrame.Angles(0, 0, math.pi * 0.5) or CFrame.identity)
    end
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = secondary
    ring.Transparency = 0.16
    ring.Parent = worldEffects

    TweenService:Create(
        core,
        TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = reduced and Vector3.new(2.4, 2.4, 2.4)
                or ((signal or supply or cargo) and Vector3.new(5.2, 5.2, 5.2)
                    or (golden and Vector3.new(5.6, 5.6, 5.6)
                        or Vector3.new(4.2, 4.2, 4.2))),
            Transparency = 1,
        }
    ):Play()

    TweenService:Create(
        ring,
        TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = CelebrationMeshes.size(ring, reduced and 4.0
                or ((signal or supply or cargo) and 12.0 or (golden and 11.5 or 8.5)), 0.10),
            Transparency = 1,
        }
    ):Play()

    if tier.Name ~= "Low" and not reduced then
        local attachment = Instance.new("Attachment")
        attachment.Parent = core

        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "ShardPickupMotes"
        emitter.Rate = 0
        emitter.Lifetime = NumberRange.new(0.28, 0.48)
        emitter.Speed = NumberRange.new(3.5, 7.5)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.LightEmission = 1
        emitter.Color = ColorSequence.new(primary, secondary)
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.22),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Parent = attachment
        emitter:Emit(VfxQuality.particleCount(tier.Name, golden and 28 or 18, golden and 10 or 7))
    end

    if tier.Name == "High" and not reduced then
        local light = Instance.new("PointLight")
        light.Color = primary
        light.Brightness = golden and 2.6 or 1.8
        light.Range = golden and 14 or 10
        light.Shadows = false
        light.Parent = core
        TweenService:Create(light, TweenInfo.new(0.22), {Brightness = 0}):Play()
    end

    Debris:AddItem(core, 0.40)
    Debris:AddItem(ring, 0.40)
end



local function show(reward, total, goldenFlag, flowBonus, source)
    if touchDevice and not rewardFits then
        return
    end
    if touchDevice and not MobileHudNotices.claim("shard", 10) then
        -- Retain only the latest pickup, not a backlog obscuring survival.
        pendingReward = {
            deadline = os.clock() + 2.5,
            reward = reward,
            total = total,
            golden = goldenFlag,
            flowBonus = flowBonus,
            source = source,
        }
        return
    end
    pendingReward = nil
    token += 1
    local current = token

    local golden = goldenFlag == true or (tonumber(reward) or 1) >= 3
    local flow = math.max(0, math.floor(tonumber(flowBonus) or 0))
    local shardTotal = math.max(1, math.floor(tonumber(total) or 1))
    if source == "DistrictSignal" then
        label.Text = "SIGNAL SECURED  •  +" .. tostring(reward) .. " COINS"
    elseif source == "DistrictCache" then
        label.Text = "SUPPLY CACHE  •  +" .. tostring(reward) .. " COINS"
    elseif source == "HarborCargo" then
        label.Text = "CARGO ROUTE CLEARED  •  +" .. tostring(reward) .. " COINS"
    elseif golden then
        label.Text = "+" .. tostring(reward) .. " COINS  •  GOLDEN CHAOS SHARD"
    elseif shardTotal == 1 then
        label.Text = "SHARD +1  •  BONUS COIN  •  OPTIONAL"
    else
        label.Text = "+" .. tostring(reward) .. " COIN  •  CHAOS SHARD " .. tostring(shardTotal)
    end
    if touchDevice then
        -- Concise tactile feedback fits the side lane on landscape phones.
        if source == "DistrictSignal" then
            label.Text = (french and "SIGNAL +" or "SIGNAL +") .. tostring(reward)
        elseif source == "DistrictCache" then
            label.Text = (french and "CACHE +" or "CACHE +") .. tostring(reward)
        elseif source == "HarborCargo" then
            label.Text = (french and "CARGAISON +" or "CARGO +") .. tostring(reward)
        elseif golden then
            label.Text = (french and "ÉCLAT DORÉ +" or "GOLD SHARD +") .. tostring(reward)
        else
            label.Text = (french and "ÉCLAT +" or "SHARD +") .. tostring(reward)
        end
    end
    if flow > 0 then
        label.Text ..= touchDevice and (" • +" .. tostring(flow) .. " COMBO")
            or ("  •  FLOW COMBO +" .. tostring(flow))
    end
    label.TextColor3 = source == "DistrictSignal"
        and Color3.fromRGB(255, 199, 113)
        or (source == "DistrictCache"
            and (golden and Color3.fromRGB(255, 225, 105)
                or Color3.fromRGB(135, 244, 199)))
        or (source == "HarborCargo"
            and Color3.fromRGB(126, 255, 194))
        or (golden and Color3.fromRGB(255, 225, 105) or UITheme.Colors.Cyan)
    stroke.Color = source == "DistrictSignal"
        and Color3.fromRGB(255, 135, 90)
        or (source == "DistrictCache"
            and Color3.fromRGB(119, 218, 181))
        or (source == "HarborCargo"
            and Color3.fromRGB(61, 174, 155))
        or (golden and Color3.fromRGB(255, 165, 55) or UITheme.Colors.Violet)
    label.Visible = true
    label.TextTransparency = 1
    label.BackgroundTransparency = 1
    scale.Scale = 0.78

    TweenService:Create(
        label,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0, BackgroundTransparency = 0.12}
    ):Play()
    TweenService:Create(
        scale,
        TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = 1}
    ):Play()

    local holdSeconds = (source == "DistrictSignal"
        or source == "DistrictCache" or source == "HarborCargo")
        and 1.50 or ((not golden and shardTotal == 1) and 1.65 or 1.05)
    task.delay(holdSeconds, function()
        if current ~= token then
            return
        end

        TweenService:Create(
            label,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {TextTransparency = 1, BackgroundTransparency = 1}
        ):Play()
        TweenService:Create(
            scale,
            TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Scale = 0.9}
        ):Play()

        task.wait(0.23)
        if current == token then
            label.Visible = false
            if touchDevice then
                MobileHudNotices.release("shard")
            end
        end
    end)
end

if touchDevice then
    MobileHudNotices.Changed:Connect(function(owner)
        if owner ~= nil and owner ~= "shard" and label.Visible then
            token += 1
            label.Visible = false
        elseif owner == nil and pendingReward then
            local pending = pendingReward
            pendingReward = nil
            if os.clock() <= pending.deadline then
                task.defer(function()
                    show(pending.reward, pending.total, pending.golden,
                        pending.flowBonus, pending.source)
                end)
            end
        end
    end)
end

event.OnClientEvent:Connect(function(payload)
    if type(payload) ~= "table" then return end
    local reward = math.clamp(math.floor(tonumber(payload.reward) or 1), 1, 100)
    show(reward, tonumber(payload.total) or 1, payload.golden == true, payload.flowBonus, payload.source)
    worldBurst(payload.position, reward, payload.source)
end)


local shardVisuals = {}
local pulseClock = 0

-- The server creates modest decorative emitters/lights for the REAL
-- coin shards. The existing local facet LOD only scaled local cosmetics,
-- so all Android tiers were still drawing identical replicated particles.
-- Adjust only presentation properties on this client. Never touch the
-- authoritative pickup body, touch handler, rewards or server state.
local function adaptReplicatedShardEffects(shardPart)
    if not shardPart:IsA("BasePart")
        or shardPart:GetAttribute("ChaosShard") ~= true then
        return
    end
    local tier = quality().Name
    local reduced = player:GetAttribute("ReduceMotion") == true
    local golden = shardPart:GetAttribute("ChaosShardGolden") == true
    local glow = shardPart:FindFirstChild("ShardGlow")
    if glow and glow:IsA("PointLight") then
        local sourceBrightness = golden and 2.0 or 1.3
        local brightness = sourceBrightness
            * (tier == "High" and 1 or (tier == "Medium" and 0.72 or 0.38))
        if glow.Brightness ~= brightness then
            glow.Brightness = brightness
        end
        -- Keep a visible low-tier glow; only shrink its light footprint.
        glow.Range = tier == "High" and (golden and 14 or 10)
            or (tier == "Medium" and 9 or 6)
        glow.Shadows = false
    end

    local attachment = shardPart:FindFirstChild("ShardVfx")
    local motes = attachment and attachment:FindFirstChild("ShardMotes")
    if motes and motes:IsA("ParticleEmitter") then
        local rate = reduced and 0
            or (tier == "High" and 8 or (tier == "Medium" and 3 or 0))
        motes.Rate = rate
        motes.Enabled = rate > 0
    end

    local sparkles = shardPart:FindFirstChild("GoldenShardSparkles")
    if sparkles and sparkles:IsA("Sparkles") then
        sparkles.Enabled = tier == "High" and not reduced
    end
end

local function unmountCore(shardPart, entry)
    if entry.originalMask ~= nil and shardPart.LocalTransparencyModifier == 1 then
        shardPart.LocalTransparencyModifier = entry.originalMask
    end
    entry.originalMask = nil
    entry.highlight.Adornee = shardPart
    entry.ring.Adornee = shardPart
    if entry.core then entry.core:Destroy() end
    if entry.halo then entry.halo:Destroy() end
    entry.core, entry.halo = nil, nil
    entry.coreSource, entry.haloSource = nil, nil
    entry.coreMeshId, entry.haloMeshId = nil, nil
end

local function removeVisual(shardPart)
    local visual = shardVisuals[shardPart]
    if visual then
        shardVisuals[shardPart] = nil
        unmountCore(shardPart, visual)
        visual.folder:Destroy()
    end
end

local function shardKind(shardPart)
    if shardPart:GetAttribute("ChaosShardGolden") == true then return "golden" end
    if shardPart:GetAttribute("ChaosShardCargo") == true then return "cargo" end
    return "ordinary"
end

local function attachVisual(shardPart)
    if not shardPart:IsA("BasePart")
        or shardPart:GetAttribute("ChaosShard") ~= true
        or shardVisuals[shardPart] then return end

    local parent = shardPart.Parent
    if not parent or parent.Name ~= "RoundChaosShards" or parent.Parent ~= workspace then return end
    local kind = shardKind(shardPart)
    local golden, cargo = kind == "golden", kind == "cargo"
    local folder = Instance.new("Folder")
    folder.Name = "LocalShardPolish"

    local highlight = Instance.new("Highlight")
    highlight.Name = "ShardHighlight"
    highlight.Adornee = shardPart
    highlight.FillColor = shardPart.Color
    highlight.FillTransparency = 0.68
    highlight.OutlineColor = golden and Color3.fromRGB(255, 245, 175)
        or (cargo and Color3.fromRGB(162, 255, 207) or Color3.fromRGB(210, 160, 255))
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = folder

    local ring = Instance.new("SelectionSphere")
    ring.Name = "ShardRing"
    ring.Adornee = shardPart
    ring.Color3 = highlight.OutlineColor
    ring.SurfaceTransparency = 1
    ring.Transparency = 0.72
    ring.Parent = folder

    folder.Parent = worldEffects
    shardVisuals[shardPart] = {folder = folder, highlight = highlight, ring = ring, kind = kind}
    adaptReplicatedShardEffects(shardPart)
end

local function meshPiece(source, name, frame, size, color, material, alpha)
    local part = CelebrationMeshes.cloneProfile(source)
    if not part then return nil end
    part.Name = name
    part.MaterialVariant = ""
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.LocalTransparencyModifier = 0
    part.Size = size
    part.CFrame = frame
    part.Color = color
    part.Material = material
    part.Transparency = alpha
    return part
end

local function syncSculpt(shardPart, entry, profile, haloProfile)
    if entry.coreSource == profile and entry.haloSource == haloProfile
        and entry.coreMeshId == (profile and profile.MeshId)
        and entry.haloMeshId == (haloProfile and haloProfile.MeshId) then return end
    unmountCore(shardPart, entry)
    if not profile then return end

    local cargo, golden = entry.kind == "cargo", entry.kind == "golden"
    local size = cargo and Vector3.new(1.50, 0.90, 1.20)
        or (golden and Vector3.new(1.42, 1.32, 1.42) or Vector3.new(0.98, 1.60, 0.98))
    local offset = cargo and CFrame.Angles(0, math.pi * 0.25, 0) or CFrame.identity
    if cargo and profile.Size.Z > profile.Size.X then
        size = Vector3.new(size.Z, size.Y, size.X)
        offset *= CFrame.Angles(0, math.pi * 0.5, 0)
    end
    local core = meshPiece(profile, "SculptedShardCore", shardPart.CFrame * offset,
        size, shardPart.Color, cargo and Enum.Material.SmoothPlastic or Enum.Material.Neon,
        shardPart.Transparency)
    if not core then return end
    local halo = meshPiece(haloProfile, "SculptedGoldHalo", shardPart.CFrame,
        Vector3.new(1.92, 0.12, 1.92), Color3.fromRGB(255, 221, 116), Enum.Material.Neon, 0.22)
    core.Parent = entry.folder
    if halo then halo.Parent = entry.folder end
    entry.core, entry.halo, entry.coreOffset = core, halo, offset
    entry.coreSource, entry.haloSource = profile, halo and haloProfile or nil
    entry.coreMeshId = profile.MeshId
    entry.haloMeshId = halo and haloProfile.MeshId or nil
    entry.highlight.Adornee = core
    entry.ring.Adornee = nil
    entry.originalMask = shardPart.LocalTransparencyModifier
    shardPart.LocalTransparencyModifier = 1
end

local function scanShards(root)
    if not root then return end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant:GetAttribute("ChaosShard") == true then
            attachVisual(descendant)
        end
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("ChaosShard") == true then
        attachVisual(descendant)
    elseif descendant.Name == "ShardGlow"
        or descendant.Name == "GoldenShardSparkles"
        or descendant.Name == "ShardMotes" then
        -- A newly streamed shard can arrive before its light/attachment,
        -- so tune those later descendants as soon as they become visible.
        local parent = descendant.Parent
        local shardPart = parent and parent:IsA("Attachment") and parent.Parent
            or parent
        if shardPart and shardPart:IsA("BasePart") then
            attachVisual(shardPart)
            adaptReplicatedShardEffects(shardPart)
        end
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if shardVisuals[descendant] then
        removeVisual(descendant)
    end
end)

scanShards(workspace:FindFirstChild("RoundChaosShards"))

local nextSourceCheck = 0
local function refreshVisibleShards()
    nextSourceCheck = 0
    local pressured = (tonumber(player:GetAttribute("OptionalVfxPressure")) or 0) >= 1
    for shardPart, entry in pairs(shardVisuals) do
        adaptReplicatedShardEffects(shardPart)
        if pressured then unmountCore(shardPart, entry) end
    end
end
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshVisibleShards)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshVisibleShards)
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(refreshVisibleShards)

local function readySource(profiles, role, pressure)
    if profiles[role] == nil then
        profiles[role] = CelebrationMeshes.readyProfile(role, pressure) or false
    end
    return profiles[role] or nil
end

task.spawn(function()
    while true do
        if next(shardVisuals) == nil then
            task.wait(0.20)
            continue
        end

        local tier = quality()
        local reduced = player:GetAttribute("ReduceMotion") == true
        -- Keep the existing single scheduler. Static Low and reduced
        -- motion markers only need a slower visibility update.
        local interval = tier.Name == "High" and (1 / 30)
            or (tier.Name == "Medium" and (1 / 15) or 0.20)
        if reduced then interval = math.max(interval, 0.20) end
        local dt = task.wait(interval)
        pulseClock += dt

        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local profiles
        if pulseClock >= nextSourceCheck then
            profiles = {}
            nextSourceCheck = pulseClock + 0.8
        end
        local pressure = profiles and player:GetAttribute("OptionalVfxPressure")

        for shardPart, entry in pairs(shardVisuals) do
            local folder = entry.folder
            if not shardPart:IsDescendantOf(workspace) then
                removeVisual(shardPart)
            elseif not folder.Parent then
                removeVisual(shardPart)
                attachVisual(shardPart)
            else
                if (entry.core and entry.core.Parent ~= folder)
                    or (entry.halo and entry.halo.Parent ~= folder) then
                    unmountCore(shardPart, entry)
                    -- Keep the gameplay marker visible until the next
                    -- scheduled source check can rebuild the assembly.
                    continue
                end
                if profiles then
                    local core = readySource(profiles, entry.kind == "cargo" and "casting" or "core", pressure)
                    local halo = core and entry.kind == "golden" and tier.Name ~= "Low"
                        and readySource(profiles, "ring", pressure) or nil
                    syncSculpt(shardPart, entry, core, halo)
                end
                local distance = rootPart
                    and (rootPart.Position - shardPart.Position).Magnitude
                    or 999
                local closeDistance = 24 * tier.Scale
                local close = distance <= closeDistance
                local golden = entry.kind == "golden"
                local pulseSpeed = golden
                    and (close and 8.2 or 5.2)
                    or (close and 6.5 or 3.8)
                local pulse = reduced and 0.5
                    or (math.sin(pulseClock * pulseSpeed) + 1) * 0.5

                local highlight = entry.highlight
                if highlight.Parent == folder then
                    local detailScale = tier.Scale
                    highlight.FillTransparency = math.clamp(
                        (close and 0.42 or 0.66)
                            + pulse * 0.08
                            + ((1 - detailScale) * 0.12),
                        0,
                        1
                    )
                    highlight.OutlineTransparency = math.clamp(
                        (close and 0.04 or 0.18)
                            + ((1 - detailScale) * 0.22),
                        0,
                        1
                    )
                end

                local ring = entry.ring
                if ring.Adornee and ring.Parent == folder then
                    ring.Transparency = (close and 0.46 or 0.68) + pulse * 0.12
                end

                if entry.core then
                    local frame = shardPart.CFrame * entry.coreOffset
                    if entry.core.CFrame ~= frame then entry.core.CFrame = frame end
                    entry.core.Transparency = shardPart.Transparency
                end
                if entry.halo then
                    local tilt = close and not reduced and (0.16 + pulse * 0.08) or 0.16
                    entry.halo.CFrame = shardPart.CFrame * CFrame.Angles(tilt, 0, tilt)
                    entry.halo.Transparency = math.max(shardPart.Transparency, 0.22)
                end
            end
        end
    end
end)
