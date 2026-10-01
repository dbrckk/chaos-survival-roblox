local Players = game:GetService("Players")

local RoundCollectibles = {}

RoundCollectibles.SpawnInterval = 8
RoundCollectibles.InitialDelay = 4
RoundCollectibles.CoinReward = 1
RoundCollectibles.GoldenCoinReward = 3

function RoundCollectibles.maxActive(contestantCount, soloMode)
    if soloMode then
        return 1
    end
    return math.clamp(math.ceil(math.max(1, contestantCount or 1) / 3), 1, 3)
end

function RoundCollectibles.reward()
    return RoundCollectibles.CoinReward
end

function RoundCollectibles.goldenReward()
    return RoundCollectibles.GoldenCoinReward
end

local function playerFromHit(hit)
    local current = hit
    while current and current ~= workspace do
        if current:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(current)
            if player then
                return player
            end
        end
        current = current.Parent
    end
    return nil
end

local function candidateParts(arena)
    local candidates = {}

    -- Prefer permanent spawn pads so a pickup never becomes stranded in mid-air
    -- when a disaster removes or moves temporary arena platforms.
    local spawns = arena and arena:FindFirstChild("Spawns")
    if spawns then
        for _, child in ipairs(spawns:GetChildren()) do
            if child:IsA("BasePart") and child.Parent then
                table.insert(candidates, child)
            end
        end
    end

    if #candidates > 0 then
        return candidates
    end

    -- Fallback keeps the system functional for future arena layouts that omit
    -- dedicated spawn pads.
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms then
        for _, child in ipairs(platforms:GetChildren()) do
            if child:IsA("BasePart") and child.Parent then
                table.insert(candidates, child)
            end
        end
    end

    return candidates
end

local function makeShard(container, supportPart, index, reward, golden)
    local resolvedReward = math.max(1, math.floor(tonumber(reward) or RoundCollectibles.CoinReward))
    local isGolden = golden == true

    local shard = Instance.new("Part")
    shard.Name = "ChaosShard" .. index
    shard.Shape = Enum.PartType.Ball
    shard.Size = Vector3.new(1.55, 1.55, 1.55)
    shard.Anchored = true
    shard.CanCollide = false
    shard.CanQuery = false
    shard.CanTouch = true
    shard.CastShadow = false
    shard.Material = Enum.Material.Neon
    shard.Color = isGolden and Color3.fromRGB(255, 205, 70) or Color3.fromRGB(95, 220, 255)
    shard.Position = supportPart.Position + Vector3.new(0, (supportPart.Size.Y * 0.5) + 2.2, 0)
    shard:SetAttribute("ChaosShard", true)
    shard:SetAttribute("ChaosShardReward", resolvedReward)
    shard:SetAttribute("ChaosShardGolden", isGolden)
    shard.Parent = container

    local light = Instance.new("PointLight")
    light.Name = "ShardGlow"
    light.Color = shard.Color
    light.Brightness = isGolden and 2.0 or 1.3
    light.Range = isGolden and 14 or 10
    light.Shadows = false
    light.Parent = shard

    local attachment = Instance.new("Attachment")
    attachment.Name = "ShardVfx"
    attachment.Parent = shard

    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ShardMotes"
    emitter.Rate = 8
    emitter.Lifetime = NumberRange.new(0.35, 0.7)
    emitter.Speed = NumberRange.new(0.5, 1.6)
    emitter.Acceleration = Vector3.new(0, 1.2, 0)
    emitter.SpreadAngle = Vector2.new(24, 24)
    emitter.LightEmission = 0.9
    emitter.Color = isGolden
        and ColorSequence.new(
            Color3.fromRGB(255, 240, 145),
            Color3.fromRGB(255, 155, 45)
        )
        or ColorSequence.new(
            Color3.fromRGB(85, 205, 255),
            Color3.fromRGB(185, 120, 255)
        )
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Parent = attachment

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ShardLabel"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(96, 34)
    billboard.StudsOffset = Vector3.new(0, 1.8, 0)
    billboard.MaxDistance = 70
    billboard.Parent = shard

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 24, 38)
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = isGolden and ("GOLD SHARD  +" .. tostring(resolvedReward)) or ("SHARD  +" .. tostring(resolvedReward))
    label.TextColor3 = isGolden and Color3.fromRGB(255, 230, 115) or Color3.fromRGB(150, 235, 255)
    label.TextScaled = true
    label.TextStrokeTransparency = 0.7
    label.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 9)
    corner.Parent = label

    local stroke = Instance.new("UIStroke")
    stroke.Color = isGolden and Color3.fromRGB(255, 170, 55) or Color3.fromRGB(145, 110, 255)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.35
    stroke.Parent = label

    return shard
end

function RoundCollectibles.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    if not arena then
        return nil
    end

    local candidates = candidateParts(arena)
    if #candidates == 0 then
        return nil
    end

    local container = Instance.new("Folder")
    container.Name = "RoundChaosShards"
    container.Parent = workspace
    table.insert(ctx.Cleanup, container)

    local maxActive = RoundCollectibles.maxActive(#(ctx.Contestants or {}), ctx.SoloMode == true)

    local function activeLimit()
        local surge = ctx.Overdrive and ctx.Overdrive() == true
        return math.min(4, maxActive + (surge and 1 or 0))
    end
    local spawnIndex = 0
    local goldenSpawned = false
    local lastCandidate = nil

    local function activeCount()
        local count = 0
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("BasePart") and child:GetAttribute("ChaosShard") == true then
                count += 1
            end
        end
        return count
    end

    local function chooseCandidate()
        if #candidates == 1 then
            return candidates[1]
        end

        local candidate = candidates[math.random(1, #candidates)]
        local attempts = 0
        while candidate == lastCandidate and attempts < 4 do
            candidate = candidates[math.random(1, #candidates)]
            attempts += 1
        end
        lastCandidate = candidate
        return candidate
    end

    local function spawnOne()
        if not ctx.Active() or not container.Parent or activeCount() >= activeLimit() then
            return
        end

        local support = chooseCandidate()
        if not support or not support.Parent then
            return
        end

        spawnIndex += 1
        local golden = ctx.Overdrive and ctx.Overdrive() == true and not goldenSpawned
        local reward = golden and RoundCollectibles.goldenReward() or RoundCollectibles.reward()
        if golden then
            goldenSpawned = true
        end

        local shard = makeShard(container, support, spawnIndex, reward, golden)
        local claimed = false

        shard.Touched:Connect(function(hit)
            if claimed or not ctx.Active() or not shard.Parent then
                return
            end

            local player = playerFromHit(hit)
            if not player or not ctx.IsContestantActive(player) then
                return
            end

            claimed = true
            local collectedReward = math.max(
                1,
                math.floor(tonumber(shard:GetAttribute("ChaosShardReward")) or RoundCollectibles.reward())
            )
            if ctx.OnCollected then
                ctx.OnCollected(
                    player,
                    collectedReward,
                    shard.Position,
                    shard:GetAttribute("ChaosShardGolden") == true
                )
            end
            shard:Destroy()
        end)
    end

    task.spawn(function()
        task.wait(RoundCollectibles.InitialDelay)

        while ctx.Active() and container.Parent do
            spawnOne()
            local surge = ctx.Overdrive and ctx.Overdrive() == true
            task.wait(surge and math.max(3, RoundCollectibles.SpawnInterval * 0.5) or RoundCollectibles.SpawnInterval)
        end
    end)

    return {
        name = "Chaos Shards",
        reward = RoundCollectibles.CoinReward,
        goldenReward = RoundCollectibles.GoldenCoinReward,
        maxActive = maxActive,
    }
end

return RoundCollectibles
