local Players = game:GetService("Players")

local RoundCollectibles = {}

RoundCollectibles.SpawnInterval = 8
RoundCollectibles.InitialDelay = 4
RoundCollectibles.CoinReward = 1
RoundCollectibles.GoldenCoinReward = 3
-- Optional high-route objective, never active in beginner-protected
-- rounds or alongside structural collapse / shrinking disasters.
RoundCollectibles.HarborCargoReward = 2
RoundCollectibles.HarborCargoLifetime = 22

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

local function candidateParts(arena, ctx)
    local spawns, outskirts, cargoCandidates = {}, {}, {}

    -- Keep the center safe for the first three guided rounds, and when
    -- a structural disaster might move/hide a support under an anchored
    -- shard. Later rounds can offer occasional real parkour rewards.
    local hazards = ctx.ActiveDisasters or {}
    local allowOutskirts = ctx.EnableDistrictCaches == true
        and hazards.ShrinkingArena ~= true
        and hazards.DisappearingPlatforms ~= true

    local spawnFolder = arena and arena:FindFirstChild("Spawns")
    if spawnFolder then
        for _, child in ipairs(spawnFolder:GetChildren()) do
            -- Spawn markers are intentionally NON-colliding; the broad
            -- arena floor underneath provides the physical support.
            if child:IsA("BasePart") and child.Parent then
                table.insert(spawns, child)
            end
        end
    end
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms then
        for _, child in ipairs(platforms:GetChildren()) do
            if child:IsA("BasePart") and child.Parent
                and child.CanCollide and child.Transparency < 0.95 then
                local harborStep = tonumber(child:GetAttribute("HarborStep"))
                local harborRoute = tonumber(child:GetAttribute("HarborRoute"))
                local elevatedCargo = harborRoute and harborRoute >= 1
                    and harborRoute <= 4
                    and (harborStep == 4 or harborStep == 6)
                if allowOutskirts
                    and child:GetAttribute("CollapsePhase") == nil
                    and ((child:GetAttribute("PerimeterStep") == 1
                        and tonumber(child:GetAttribute("PerimeterRoute")))
                        or elevatedCargo) then
                    -- On Harbor, the player can climb a *real* four- or
                    -- six-step cargo route for a valuable optional cache.
                    -- Every destination is a server-owned, colliding
                    -- physical platform, never a floating collectible.
                    if elevatedCargo then
                        table.insert(cargoCandidates, child)
                    else
                        table.insert(outskirts, child)
                    end
                elseif #spawns == 0 then
                    -- A future map without spawn pads still supports the
                    -- original shard mechanic on solid physical decks.
                    table.insert(spawns, child)
                end
            end
        end
    end
    return spawns, outskirts, cargoCandidates
end

local function makeShard(container, supportPart, index, reward, golden, cargo)
    local resolvedReward = math.max(1, math.floor(tonumber(reward) or RoundCollectibles.CoinReward))
    local isGolden = golden == true
    local isCargo = cargo == true and not isGolden

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
    shard.Color = isGolden and Color3.fromRGB(255, 205, 70)
        or (isCargo and Color3.fromRGB(94, 226, 170)
            or Color3.fromRGB(95, 220, 255))
    shard.Position = supportPart.Position + Vector3.new(0, (supportPart.Size.Y * 0.5) + 2.2, 0)
    shard:SetAttribute("ChaosShard", true)
    shard:SetAttribute("ChaosShardReward", resolvedReward)
    shard:SetAttribute("ChaosShardGolden", isGolden)
    shard:SetAttribute("ChaosShardCargo", isCargo)
    if isCargo then
        shard:SetAttribute(
            "HarborCargoRoute", supportPart:GetAttribute("HarborRoute"))
        shard:SetAttribute(
            "HarborCargoStep", supportPart:GetAttribute("HarborStep"))
    end
    shard.Parent = container

    local light = Instance.new("PointLight")
    light.Name = "ShardGlow"
    light.Color = shard.Color
    light.Brightness = isGolden and 2.0 or 1.3
    light.Range = isGolden and 14 or 10
    light.Shadows = false
    light.Parent = shard

    if isGolden then
        local sparkles = Instance.new("Sparkles")
        sparkles.Name = "GoldenShardSparkles"
        sparkles.SparkleColor = Color3.fromRGB(255, 225, 105)
        sparkles.Parent = shard
    end

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
    billboard.Size = UDim2.fromOffset(isCargo and 118 or 96, 34)
    billboard.StudsOffset = Vector3.new(0, 1.8, 0)
    billboard.MaxDistance = isCargo and 95 or 70
    billboard.Parent = shard

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(12, 24, 38)
    label.BackgroundTransparency = 0.18
    label.BorderSizePixel = 0
    label.Font = Enum.Font.GothamBlack
    label.Text = isGolden and ("GOLD SHARD  +" .. tostring(resolvedReward))
        or (isCargo and ("CARGO CACHE  +" .. tostring(resolvedReward))
            or ("SHARD  +" .. tostring(resolvedReward)))
    label.TextColor3 = isGolden and Color3.fromRGB(255, 230, 115)
        or (isCargo and Color3.fromRGB(140, 255, 195)
            or Color3.fromRGB(150, 235, 255))
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

    local candidates, outskirts, cargoCandidates = candidateParts(arena, ctx)
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
        -- Floor, then a marked elevated cargo challenge, then an
        -- entry-route reward. Dedicated pools prevent the interesting
        -- prize being lost in a random draw among sixteen perimeter
        -- decks; ordinary rounds never gain the cargo-only pool.
        local ordinal = spawnIndex + 1
        local pool = candidates
        if #cargoCandidates > 0 and ordinal % 3 == 2 then
            pool = cargoCandidates
        elseif #outskirts > 0 and ordinal % 3 == 0 then
            pool = outskirts
        end
        local available = {}
        for _, candidate in ipairs(pool) do
            if candidate.Parent and candidate.Transparency < 0.95
                and candidate:GetAttribute("CollapsePhase") == nil
                and (pool == candidates or candidate.CanCollide) then
                available[#available + 1] = candidate
            end
        end
        if #available == 0 and pool ~= candidates then
            for _, candidate in ipairs(candidates) do
                if candidate.Parent then
                    available[#available + 1] = candidate
                end
            end
        end
        if #available == 0 then return nil end

        local candidate = available[math.random(1, #available)]
        for _ = 1, 4 do
            if candidate ~= lastCandidate or #available == 1 then break end
            candidate = available[math.random(1, #available)]
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
        local cargoStep = tonumber(support:GetAttribute("HarborStep"))
        local cargo = not golden and tonumber(support:GetAttribute("HarborRoute"))
            and (cargoStep == 4 or cargoStep == 6)
            and ctx.EnableDistrictCaches == true
            and (ctx.ActiveDisasters or {}).DisappearingPlatforms ~= true
            and (ctx.ActiveDisasters or {}).ShrinkingArena ~= true
        local reward = golden and RoundCollectibles.goldenReward()
            or (cargo and RoundCollectibles.HarborCargoReward
                or RoundCollectibles.reward())
        if golden then
            goldenSpawned = true
        end

        local shard = makeShard(
            container, support, spawnIndex, reward, golden, cargo)
        local claimed = false

        -- An uncollected shard must never occupy the final active slot
        -- for the entire round. Rotate inaccessible/ignored pickups after
        -- 12 seconds on normal floors, 22 for a real four/six-jump
        -- cargo ascent. The four-shard ceiling remains unchanged.
        task.delay(cargo and RoundCollectibles.HarborCargoLifetime or 12, function()
            if shard.Parent and not claimed then
                shard:Destroy()
            end
        end)

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
                local ok, err = pcall(
                    ctx.OnCollected,
                    player,
                    collectedReward,
                    shard.Position,
                    shard:GetAttribute("ChaosShardGolden") == true,
                    shard:GetAttribute("ChaosShardCargo") == true
                        and "HarborCargo" or nil
                )
                if not ok then
                    warn("Chaos shard reward callback failed:", err)
                end
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
