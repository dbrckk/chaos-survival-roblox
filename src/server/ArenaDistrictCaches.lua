-- District supply expedition: four accessible first-tier caches and four
-- harder lookout chests per arena. Server-owned, single use per cache.
-- Each human can claim at most ONE chest of each tier in a round.
-- Uses Roblox ProximityPrompt (keyboard, gamepad, touch) with no remotes,
-- physics blockers, per-frame scripts or external assets.
local Players = game:GetService("Players")

local ArenaDistrictCaches = {}

ArenaDistrictCaches.EasyReward = 2
ArenaDistrictCaches.EliteReward = 5
ArenaDistrictCaches.PromptReach = 8

local function makeVisual(model, platform, name, size, offset, color, material)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.CFrame = platform.CFrame * CFrame.new(offset)
    item.Anchored = false
    item.CanCollide = false
    item.CanTouch = false
    item.CanQuery = false
    item.Massless = true
    item.CastShadow = false
    item.Material = material or Enum.Material.Metal
    item.Color = color
    item.Parent = model

    -- The lookout is a moving authoritative platform during Shrinking
    -- Arena; welding every cosmetic to it keeps prompt + visual in sync
    -- without ever moving a collectible via a Heartbeat loop.
    local join = Instance.new("WeldConstraint")
    join.Name = "FollowLiveLookout"
    join.Part0 = platform
    join.Part1 = item
    join.Parent = item
    return item
end

local function createCache(ctx, platform, index, tier, personalClaims)
    local elite = tier == "Elite"
    local reward = elite and ArenaDistrictCaches.EliteReward
        or ArenaDistrictCaches.EasyReward
    local model = Instance.new("Model")
    model.Name = "DistrictCache" .. index .. tier
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model:SetAttribute("CosmeticOnly", true)
    model:SetAttribute("DistrictSupplyCache", true)
    model:SetAttribute("CacheReward", reward)
    model:SetAttribute("CacheTier", tier)
    model:SetAttribute("DistrictRoute", index)
    model.Parent = platform

    local top = platform.Size.Y * 0.5
    local alloy = elite and Color3.fromRGB(103, 113, 143)
        or Color3.fromRGB(72, 115, 135)
    local shadow = Color3.fromRGB(26, 45, 60)
    local gold = elite and Color3.fromRGB(245, 184, 71)
        or Color3.fromRGB(99, 220, 245)
    makeVisual(model, platform, "CacheFoot",
        Vector3.new(5.5, 0.45, 4.4),
        Vector3.new(0, top + 0.23, 0), shadow)
    local body = makeVisual(model, platform, "SupplyCase",
        Vector3.new(4.2, 2.2, 3.2),
        Vector3.new(0, top + 1.45, 0), alloy)
    for side = -1, 1, 2 do
        makeVisual(model, platform, "ReinforcedEdge" .. side,
            Vector3.new(0.44, 2.65, 3.5),
            Vector3.new(side * 2.07, top + 1.47, 0),
            shadow)
        makeVisual(model, platform, "SignalRail" .. side,
            Vector3.new(3.9, 0.22, 0.34),
            Vector3.new(0, top + 2.55, side * 1.56),
            gold, Enum.Material.Neon).Transparency = 0.16
    end
    local lid = makeVisual(model, platform, "CacheLid",
        Vector3.new(4.6, 0.55, 3.65),
        Vector3.new(0, top + 2.78, 0), shadow)
    makeVisual(model, platform, "SignalPrism",
        Vector3.new(1.4, 2.0, 1.4),
        Vector3.new(0, top + 4.1, 0),
        gold, Enum.Material.Glass).Transparency = 0.18

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "OpenDistrictCache"
    prompt.ActionText = "CLAIM +" .. reward .. " COINS"
    prompt.ObjectText = elite and "ELITE SUPPLY" or "DISTRICT SUPPLY"
    prompt.HoldDuration = elite and 0.45 or 0.25
    prompt.MaxActivationDistance = ArenaDistrictCaches.PromptReach
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = lid

    local tag = Instance.new("BillboardGui")
    tag.Name = "SupplyCacheLabel"
    tag.Adornee = lid
    tag.Size = UDim2.fromOffset(174, 40)
    tag.StudsOffsetWorldSpace = Vector3.new(0, 3.1, 0)
    tag.MaxDistance = 100
    tag.AlwaysOnTop = false
    tag.Parent = lid
    local label = Instance.new("TextLabel")
    label.Name = "ObjectiveText"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = Color3.fromRGB(16, 26, 40)
    label.BackgroundTransparency = 0.16
    label.BorderSizePixel = 0
    label.TextColor3 = gold
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Text = elite and "HIGH ROUTE  +5" or "SHORT ROUTE  +2"
    label.Parent = tag
    local border = Instance.new("UICorner")
    border.CornerRadius = UDim.new(0, 8)
    border.Parent = label

    local claimed = false
    local function refresh()
        prompt.Enabled = not claimed
            and platform.Parent ~= nil
            and platform.CanCollide
            and platform.Transparency < 0.95
            and ctx.Active()
    end
    local collisionConnection = platform:GetPropertyChangedSignal(
        "CanCollide"
    ):Connect(refresh)
    local visibilityConnection = platform:GetPropertyChangedSignal(
        "Transparency"
    ):Connect(refresh)
    model.Destroying:Connect(function()
        collisionConnection:Disconnect()
        visibilityConnection:Disconnect()
    end)
    refresh()

    prompt.Triggered:Connect(function(player)
        if claimed or not ctx.Active() or not platform.Parent
            or not platform.CanCollide or platform.Transparency >= 0.95
            or not player or player.Parent ~= Players
            or player:GetAttribute("DataLoaded") ~= true
            or not ctx.IsContestantActive(player)
        then
            return
        end
        local character = player.Character
        local human = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not human or human.Health <= 0
            or not root or not root:IsA("BasePart")
            or (root.Position - lid.Position).Magnitude
                > ArenaDistrictCaches.PromptReach + 4
        then
            return
        end
        -- Each player can claim a near chest and an elite chest, but not
        -- all four of the same tier. Both caps are enforced on the server.
        local userClaims = personalClaims[player.UserId]
        if not userClaims then
            userClaims = {}
            personalClaims[player.UserId] = userClaims
        end
        if userClaims[tier] then return end
        -- Mark first, preventing simultaneous claims or payout duplication.
        claimed = true
        userClaims[tier] = true
        prompt.Enabled = false
        if ctx.OnCollected then
            pcall(ctx.OnCollected, player,
                reward,
                lid.Position, elite, "DistrictCache")
        end
        model:Destroy()
    end)

    table.insert(ctx.Cleanup, model)
    return model
end

function ArenaDistrictCaches.start(ctx)
    -- Veteran-only optional detour: protected beginner rounds teach
    -- survival, avoiding distracting side quests on a 320-stud map.
    if ctx.EnableDistrictCaches ~= true then
        return 0
    end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if not platforms then return 0 end

    local stations = {Easy = {}, Elite = {}}
    for _, item in ipairs(platforms:GetChildren()) do
        if item:IsA("BasePart") then
            local tier, route
            if item:GetAttribute("PerimeterStep") == 4 then
                tier = "Easy"
                route = tonumber(item:GetAttribute("PerimeterRoute"))
            elseif item:GetAttribute("BranchStep") == 4 then
                tier = "Elite"
                route = tonumber(item:GetAttribute("BranchRoute"))
            end
            if tier and route and route >= 1 and route <= 4
                and route == math.floor(route)
                and not stations[tier][route] then
                stations[tier][route] = item
            end
        end
    end

    local personalClaims = {}
    local built = 0
    for route = 1, 4 do
        for _, tier in ipairs({"Easy", "Elite"}) do
            local support = stations[tier][route]
            if support then
                createCache(ctx, support, route, tier, personalClaims)
                built += 1
            end
        end
    end
    arena:SetAttribute("RoundDistrictCachesAvailable", built)
    return built
end

return ArenaDistrictCaches
