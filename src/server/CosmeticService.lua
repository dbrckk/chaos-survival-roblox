local Players = game:GetService("Players")
local Cosmetics = require(script.Parent.CosmeticsCatalog)
local GameAnalytics = require(script.Parent.GameAnalytics)

local CosmeticService = {}

local stateEvent
local actionEvent

local EFFECT_NAMES = {
    "ChaosTrail",
    "ChaosTrailA0",
    "ChaosTrailA1",
    "ChaosAura",
    "ChaosAuraLight",
    "ChaosAuraHighlight",
}

local function clearEffect(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, name in ipairs(EFFECT_NAMES) do
        local obj = root:FindFirstChild(name)
        if obj then
            obj:Destroy()
        end
    end

    local highlight = character:FindFirstChild("ChaosAuraHighlight")
    if highlight then
        highlight:Destroy()
    end
end

local function applyTrail(root, item)
    local a0 = Instance.new("Attachment")
    a0.Name = "ChaosTrailA0"
    a0.Position = Vector3.new(0, 1.1, 0)
    a0.Parent = root

    local a1 = Instance.new("Attachment")
    a1.Name = "ChaosTrailA1"
    a1.Position = Vector3.new(0, -1.1, 0)
    a1.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "ChaosTrail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.48
    trail.MinLength = 0.08
    trail.FaceCamera = true
    trail.LightEmission = 0.78
    trail.LightInfluence = 0.18
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.72, 0.62),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.08),
        NumberSequenceKeypoint.new(0.75, 0.28),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.Color = ColorSequence.new(item.ColorA, item.ColorB)
    trail.Parent = root
end

local function applyAura(character, root, item)
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "ChaosAura"
    emitter.Rate = 18
    emitter.Lifetime = NumberRange.new(0.45, 0.9)
    emitter.Speed = NumberRange.new(0.6, 1.8)
    emitter.Drag = 2
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-90, 90)
    emitter.SpreadAngle = Vector2.new(55, 55)
    emitter.LightEmission = 0.8
    emitter.LightInfluence = 0
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(0.45, 0.16),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.18),
        NumberSequenceKeypoint.new(0.7, 0.4),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color = ColorSequence.new(item.ColorA, item.ColorB)
    emitter.Parent = root

    local light = Instance.new("PointLight")
    light.Name = "ChaosAuraLight"
    light.Color = item.ColorA
    light.Brightness = 0.85
    light.Range = 9
    light.Shadows = false
    light.Parent = root

    local highlight = Instance.new("Highlight")
    highlight.Name = "ChaosAuraHighlight"
    highlight.Adornee = character
    highlight.FillColor = item.ColorA
    highlight.FillTransparency = 0.82
    highlight.OutlineColor = item.ColorB
    highlight.OutlineTransparency = 0.22
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Parent = character
end

local function applyEffect(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    clearEffect(character)

    local id = player:GetAttribute("EquippedCosmetic") or ""
    local item = Cosmetics.get(id)
    if not item then
        return
    end

    if item.Kind == "trail" then
        applyTrail(root, item)
    elseif item.Kind == "aura" then
        applyAura(character, root, item)
    end
end

local function stateFor(player)
    local owned = Cosmetics.deserialize(player:GetAttribute("OwnedCosmetics") or "")
    return {
        catalog = Cosmetics.publicList(),
        owned = owned,
        equipped = player:GetAttribute("EquippedCosmetic") or "",
        coins = math.max(0, tonumber(player:GetAttribute("Coins")) or 0),
    }
end

local function sendState(player, unlocked, notice)
    if stateEvent then
        stateEvent:FireClient(player, {
            state = stateFor(player),
            unlocked = unlocked or {},
            notice = notice,
        })
    end
end

local function syncUnlocks(player)
    local merged, unlocked = Cosmetics.mergeLevelUnlocks(
        player:GetAttribute("OwnedCosmetics") or "",
        player:GetAttribute("Level") or 1
    )

    player:SetAttribute("OwnedCosmetics", merged)

    local equipped = player:GetAttribute("EquippedCosmetic") or ""
    if equipped == "" and Cosmetics.canEquip(merged, "trail_blue") then
        player:SetAttribute("EquippedCosmetic", "trail_blue")
    elseif not Cosmetics.canEquip(merged, equipped) then
        player:SetAttribute("EquippedCosmetic", "")
    end

    sendState(player, unlocked)
    applyEffect(player)
end

local function setupPlayer(player)
    task.spawn(function()
        if not player:GetAttribute("DataLoaded") then
            player:GetAttributeChangedSignal("DataLoaded"):Wait()
        end

        if player.Parent ~= Players then
            return
        end

        syncUnlocks(player)

        player:GetAttributeChangedSignal("Level"):Connect(function()
            syncUnlocks(player)
        end)

        player:GetAttributeChangedSignal("Coins"):Connect(function()
            if stateEvent then
                sendState(player)
            end
        end)

        player.CharacterAdded:Connect(function()
            task.wait(0.15)
            applyEffect(player)
        end)

        if player.Character then
            applyEffect(player)
        end
    end)
end

local function buyCosmetic(player, cosmeticId)
    local owned = player:GetAttribute("OwnedCosmetics") or ""
    local coins = math.max(0, tonumber(player:GetAttribute("Coins")) or 0)
    local canBuy, reason = Cosmetics.canBuy(owned, cosmeticId, coins)
    if not canBuy then
        sendState(player, nil, reason)
        return
    end

    local item = Cosmetics.get(cosmeticId)
    if not item then
        return
    end

    local price = math.max(0, tonumber(item.CoinPrice) or 0)
    if price <= 0 or coins < price then
        sendState(player, nil, "insufficient_coins")
        return
    end

    player:SetAttribute("Coins", coins - price)
    player:SetAttribute("OwnedCosmetics", Cosmetics.buy(owned, cosmeticId))
    player:SetAttribute("EquippedCosmetic", cosmeticId)
    applyEffect(player)
    sendState(player, nil, "purchased")

    local solo = #Players:GetPlayers() <= 1
    GameAnalytics.economySink(player, price, "Cosmetic", cosmeticId, solo)
    GameAnalytics.custom(
        player,
        "CosmeticPurchased",
        price,
        "Cosmetic:" .. cosmeticId,
        "Level:" .. tostring(player:GetAttribute("Level") or 1),
        "Mode:" .. GameAnalytics.modeLabel(solo)
    )
end

function CosmeticService.grant(player, cosmeticId)
    if not player or type(cosmeticId) ~= "string" then
        return false
    end

    local item = Cosmetics.get(cosmeticId)
    if not item then
        return false
    end

    local owned = Cosmetics.deserialize(player:GetAttribute("OwnedCosmetics") or "")
    if owned[cosmeticId] then
        return true
    end

    owned[cosmeticId] = true
    player:SetAttribute("OwnedCosmetics", Cosmetics.serialize(owned))
    if (player:GetAttribute("EquippedCosmetic") or "") == "" then
        player:SetAttribute("EquippedCosmetic", cosmeticId)
        applyEffect(player)
    end
    sendState(player, {cosmeticId}, "premium_granted")
    return true
end

function CosmeticService.sync(player)
    if player:GetAttribute("DataLoaded") then
        syncUnlocks(player)
    end
end

function CosmeticService.init(remotes, rateLimiterFactory)
    stateEvent = remotes:FindFirstChild("CosmeticState") or Instance.new("RemoteEvent")
    stateEvent.Name = "CosmeticState"
    stateEvent.Parent = remotes

    actionEvent = remotes:FindFirstChild("CosmeticAction") or Instance.new("RemoteEvent")
    actionEvent.Name = "CosmeticAction"
    actionEvent.Parent = remotes

    local allowAction = rateLimiterFactory.new(0.25)

    actionEvent.OnServerEvent:Connect(function(player, action, cosmeticId)
        if action == "sync" then
            sendState(player)
            return
        end

        if not allowAction(player.UserId) then
            return
        end

        if type(cosmeticId) ~= "string" then
            return
        end

        if action == "buy" then
            buyCosmetic(player, cosmeticId)
            return
        end

        if action ~= "equip" then
            return
        end

        local owned = player:GetAttribute("OwnedCosmetics") or ""
        if not Cosmetics.canEquip(owned, cosmeticId) then
            return
        end

        player:SetAttribute("EquippedCosmetic", cosmeticId)
        applyEffect(player)
        sendState(player)

        GameAnalytics.custom(
            player,
            "CosmeticEquipped",
            1,
            "Cosmetic:" .. cosmeticId,
            "Level:" .. tostring(player:GetAttribute("Level") or 1)
        )
    end)

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return CosmeticService
