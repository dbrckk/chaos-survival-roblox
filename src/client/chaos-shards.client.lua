local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local UITheme = require(ReplicatedStorage.Shared.UITheme)

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ChaosShardCollected")

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
label.Position = UDim2.fromScale(0.5, UserInputService.TouchEnabled and 0.51 or 0.66)
label.Size = UDim2.fromOffset(UserInputService.TouchEnabled and 260 or 300,
    UserInputService.TouchEnabled and 49 or 54)
label.BackgroundColor3 = UITheme.Colors.Panel
label.BackgroundTransparency = 1
label.BorderSizePixel = 0
label.Font = Enum.Font.GothamBlack
label.Text = ""
label.TextColor3 = UITheme.Colors.Cyan
label.TextStrokeTransparency = 0.65
label.TextScaled = true
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

local function worldBurst(position, reward, source)
    if typeof(position) ~= "Vector3" then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local golden = (tonumber(reward) or 1) >= 3
    local signal = source == "DistrictSignal"
    local supply = source == "DistrictCache"
    local reduced = player:GetAttribute("ReduceMotion") == true
    -- The server source already distinguishes pickups; match that source
    -- with recognizably different shapes and color, not extra geometry.
    local primary = signal and Color3.fromRGB(255, 178, 72)
        or (supply and (golden and Color3.fromRGB(255, 222, 110)
            or Color3.fromRGB(109, 244, 193)))
        or (golden and Color3.fromRGB(255, 215, 75) or UITheme.Colors.Cyan)
    local secondary = signal and Color3.fromRGB(255, 107, 76)
        or (supply and (golden and Color3.fromRGB(240, 162, 75)
            or Color3.fromRGB(75, 193, 229)))
        or (golden and Color3.fromRGB(255, 145, 45) or UITheme.Colors.Violet)

    local core = Instance.new("Part")
    core.Name = "ShardPickupCoreLocal"
    core.Shape = Enum.PartType.Ball
    core.Size = Vector3.new(0.8, 0.8, 0.8)
    core.Position = position
    core.Anchored = true
    core.CanCollide = false
    core.CanTouch = false
    core.CanQuery = false
    core.CastShadow = false
    core.Material = Enum.Material.Neon
    core.Color = primary
    core.Transparency = 0.04
    core.Parent = workspace

    local ring = Instance.new("Part")
    ring.Name = "ShardPickupRingLocal"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.10, 1.2, 1.2)
    -- Live signals project a vertical radio-wave ring; supply crates and
    -- collectible shards retain their familiar horizontal pickup rings.
    ring.CFrame = CFrame.new(position) * (signal
        and CFrame.Angles(0, math.rad(45), 0)
        or CFrame.Angles(0, 0, math.rad(90)))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = secondary
    ring.Transparency = 0.16
    ring.Parent = workspace

    TweenService:Create(
        core,
        TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = reduced and Vector3.new(2.4, 2.4, 2.4)
                or ((signal or supply) and Vector3.new(5.2, 5.2, 5.2)
                    or (golden and Vector3.new(5.6, 5.6, 5.6)
                        or Vector3.new(4.2, 4.2, 4.2))),
            Transparency = 1,
        }
    ):Play()

    TweenService:Create(
        ring,
        TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            Size = reduced and Vector3.new(0.10, 4.0, 4.0)
                or ((signal or supply) and Vector3.new(0.10, 12.0, 12.0)
                    or (golden and Vector3.new(0.10, 11.5, 11.5)
                        or Vector3.new(0.10, 8.5, 8.5))),
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
    token += 1
    local current = token

    local golden = goldenFlag == true or (tonumber(reward) or 1) >= 3
    local flow = math.max(0, math.floor(tonumber(flowBonus) or 0))
    local shardTotal = math.max(1, math.floor(tonumber(total) or 1))
    if source == "DistrictSignal" then
        label.Text = "SIGNAL SECURED  •  +" .. tostring(reward) .. " COINS"
    elseif source == "DistrictCache" then
        label.Text = "SUPPLY CACHE  •  +" .. tostring(reward) .. " COINS"
    elseif golden then
        label.Text = "+" .. tostring(reward) .. " COINS  •  GOLDEN CHAOS SHARD"
    elseif shardTotal == 1 then
        label.Text = "SHARD +1  •  BONUS COIN  •  OPTIONAL"
    else
        label.Text = "+" .. tostring(reward) .. " COIN  •  CHAOS SHARD " .. tostring(shardTotal)
    end
    if flow > 0 then
        label.Text ..= "  •  FLOW COMBO +" .. tostring(flow)
    end
    label.TextColor3 = source == "DistrictSignal"
        and Color3.fromRGB(255, 199, 113)
        or (source == "DistrictCache"
            and (golden and Color3.fromRGB(255, 225, 105)
                or Color3.fromRGB(135, 244, 199)))
        or (golden and Color3.fromRGB(255, 225, 105) or UITheme.Colors.Cyan)
    stroke.Color = source == "DistrictSignal"
        and Color3.fromRGB(255, 135, 90)
        or (source == "DistrictCache"
            and Color3.fromRGB(119, 218, 181))
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

    local holdSeconds = (source == "DistrictSignal" or source == "DistrictCache")
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

local function quality()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

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

local function retuneVisibleShards()
    for shardPart in pairs(shardVisuals) do
        if shardPart.Parent then
            adaptReplicatedShardEffects(shardPart)
        end
    end
end

local function removeVisual(shardPart)
    local visual = shardVisuals[shardPart]
    if visual then
        shardVisuals[shardPart] = nil
        if visual.Parent then
            visual:Destroy()
        end
    end
end

local function attachVisual(shardPart)
    if not shardPart:IsA("BasePart")
        or shardPart:GetAttribute("ChaosShard") ~= true
        or shardVisuals[shardPart]
    then
        return
    end

    local golden = shardPart:GetAttribute("ChaosShardGolden") == true

    local folder = Instance.new("Folder")
    folder.Name = "LocalShardPolish"
    folder.Parent = shardPart

    local highlight = Instance.new("Highlight")
    highlight.Name = "ShardHighlight"
    highlight.Adornee = shardPart
    highlight.FillColor = golden and Color3.fromRGB(255, 215, 80) or Color3.fromRGB(90, 210, 255)
    highlight.FillTransparency = 0.68
    highlight.OutlineColor = golden and Color3.fromRGB(255, 245, 175) or Color3.fromRGB(210, 160, 255)
    highlight.OutlineTransparency = 0.18
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = folder

    local facets = {}
    for i = 1, 3 do
        local facet = Instance.new("Part")
        facet.Name = "ShardFacet" .. i
        facet.Anchored = true
        facet.CanCollide = false
        facet.CanTouch = false
        facet.CanQuery = false
        facet.CastShadow = false
        facet.Material = Enum.Material.Neon
        facet.Color = golden
            and (i == 2 and Color3.fromRGB(255, 155, 45) or Color3.fromRGB(255, 225, 95))
            or (i == 2 and Color3.fromRGB(165, 105, 255) or Color3.fromRGB(90, 215, 255))
        facet.Size = Vector3.new(0.28, 2.15, 0.56)
        facet.Transparency = quality().Name == "Low" and 1 or 0.24
        facet.CFrame = shardPart.CFrame
            * CFrame.Angles(0, math.rad((i - 1) * 60), math.rad(22))
        facet.Parent = folder
        table.insert(facets, facet)
    end

    local ring = Instance.new("SelectionSphere")
    ring.Name = "ShardRing"
    ring.Adornee = shardPart
    ring.Color3 = golden and Color3.fromRGB(255, 225, 105) or Color3.fromRGB(130, 225, 255)
    ring.SurfaceColor3 = golden and Color3.fromRGB(255, 145, 45) or Color3.fromRGB(145, 105, 255)
    ring.Transparency = 0.72
    ring.SurfaceTransparency = 1
    ring.Parent = folder

    folder:SetAttribute("HasCrystalFacets", true)
    shardVisuals[shardPart] = folder
    adaptReplicatedShardEffects(shardPart)
end

local function scanShards(root)
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
            adaptReplicatedShardEffects(shardPart)
        end
    end
end)

workspace.DescendantRemoving:Connect(function(descendant)
    if shardVisuals[descendant] then
        removeVisual(descendant)
    end
end)

scanShards(workspace)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(retuneVisibleShards)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(retuneVisibleShards)

task.spawn(function()
    while true do
        if next(shardVisuals) == nil then
            task.wait(0.20)
            continue
        end

        local tier = quality()
        local reduced = player:GetAttribute("ReduceMotion") == true
        -- Decorative facets must not consume a 30Hz task on low-end
        -- Android when they are entirely invisible. High keeps the
        -- original 30Hz polish; Medium 15Hz, Low 5Hz, reduced motion 5Hz.
        -- This is the existing single shard scheduler, not a new loop.
        local interval = tier.Name == "High" and (1 / 30)
            or (tier.Name == "Medium" and (1 / 15) or 0.20)
        if reduced then interval = math.max(interval, 0.20) end
        local dt = task.wait(interval)
        pulseClock += dt

        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")

        for shardPart, folder in pairs(shardVisuals) do
            if not shardPart.Parent or not folder.Parent then
                removeVisual(shardPart)
            else
                local distance = rootPart
                    and (rootPart.Position - shardPart.Position).Magnitude
                    or 999
                local closeDistance = 24 * tier.Scale
                local close = distance <= closeDistance
                local golden = shardPart:GetAttribute("ChaosShardGolden") == true
                local pulseSpeed = golden
                    and (close and 8.2 or 5.2)
                    or (close and 6.5 or 3.8)
                local pulse = reduced and 0.5
                    or (math.sin(pulseClock * pulseSpeed) + 1) * 0.5

                local highlight = folder:FindFirstChild("ShardHighlight")
                if highlight and highlight:IsA("Highlight") then
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

                local ring = folder:FindFirstChild("ShardRing")
                if ring and ring:IsA("SelectionSphere") then
                    ring.Transparency = (close and 0.46 or 0.68) + pulse * 0.12
                end

                for i = 1, 3 do
                    local facet = folder:FindFirstChild("ShardFacet" .. i)
                    if facet and facet:IsA("BasePart") then
                        if tier.Name == "Low" then
                            -- Three faceted parts already exist so users
                            -- can upgrade quality mid-round, but there is
                            -- no reason to rotate invisible geometry.
                            facet.Transparency = 1
                        else
                            -- Far-away shards keep a static silhouette.
                            -- Only nearby ones spend CFrame updates on
                            -- orbiting crystal facets.
                            if close and not reduced then
                                local angle = pulseClock
                                    * (golden and 1.85 or 1.45)
                                    + math.rad((i - 1) * 60)
                                facet.CFrame = shardPart.CFrame
                                    * CFrame.Angles(0, angle,
                                        math.rad(22
                                            + math.sin(pulseClock * 2 + i) * 4))
                            end
                            facet.Transparency = (close and 0.12 or 0.36)
                                + pulse * 0.08
                        end
                    end
                end
            end
        end
    end
end)
