local Players = game:GetService("Players")
local RemoteRegistry = require(script.Parent.RemoteRegistry)

local PlayerReadiness = require(script.Parent.PlayerReadiness)
local PlayerData = require(script.Parent.PlayerData)
local Cosmetics = require(script.Parent.CosmeticsCatalog)
local GameAnalytics = require(script.Parent.GameAnalytics)

local CosmeticService = {}

local setupStarted = setmetatable({}, {__mode = "k"})

local stateEvent
local actionEvent

local EFFECT_NAMES = {
    "ChaosTrail",
    "ChaosTrailA0",
    "ChaosTrailA1",
    "ChaosAura",
    "ChaosAuraLight",
}

local function clearEffects(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, name in ipairs(EFFECT_NAMES) do
            local obj = root:FindFirstChild(name)
            if obj then
                obj:Destroy()
            end
        end
    end

    local highlight = character and character:FindFirstChild("ChaosAuraHighlight")
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

local function slotForKind(kind)
    if kind == "trail" then
        return "EquippedTrail"
    elseif kind == "aura" then
        return "EquippedAura"
    end
    return nil
end

local function applyEffects(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    clearEffects(character)

    local trailId = player:GetAttribute("EquippedTrail") or ""
    local trailItem = Cosmetics.get(trailId)
    if trailItem and trailItem.Kind == "trail" then
        applyTrail(root, trailItem)
    end

    local auraId = player:GetAttribute("EquippedAura") or ""
    local auraItem = Cosmetics.get(auraId)
    if auraItem and auraItem.Kind == "aura" then
        applyAura(character, root, auraItem)
    end
end

local function stateFor(player)
    local owned = Cosmetics.deserialize(player:GetAttribute("OwnedCosmetics") or "")
    return {
        catalog = Cosmetics.publicList(),
        owned = owned,
        equipped = {
            trail = player:GetAttribute("EquippedTrail") or "",
            aura = player:GetAttribute("EquippedAura") or "",
        },
        coins = math.max(0, tonumber(player:GetAttribute("Coins")) or 0),
        collectionLog = Cosmetics.collectionState(player:GetAttribute("OwnedCosmetics") or ""),
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

local function normalizeSlot(player, slotAttribute, expectedKind, fallbackId)
    local owned = player:GetAttribute("OwnedCosmetics") or ""
    local equipped = player:GetAttribute(slotAttribute) or ""
    local item = Cosmetics.get(equipped)

    if equipped ~= "" and (not item or item.Kind ~= expectedKind or not Cosmetics.canEquip(owned, equipped)) then
        player:SetAttribute(slotAttribute, "")
        equipped = ""
    end

    if equipped == "" and fallbackId and Cosmetics.canEquip(owned, fallbackId) then
        local fallback = Cosmetics.get(fallbackId)
        if fallback and fallback.Kind == expectedKind then
            player:SetAttribute(slotAttribute, fallbackId)
        end
    end
end

local function syncUnlocks(player)
    if player:GetAttribute("DataPersistenceAvailable") ~= true then
        sendState(player, {})
        applyEffects(player)
        return
    end

    local merged, unlocked = Cosmetics.mergeLevelUnlocks(
        player:GetAttribute("OwnedCosmetics") or "",
        player:GetAttribute("Level") or 1
    )

    local masteryMerged, masteryUnlocked = Cosmetics.mergeMasteryUnlocks(
        merged,
        player:GetAttribute("ArenaMastery") or ""
    )
    merged = masteryMerged
    for _, cosmeticId in ipairs(masteryUnlocked) do
        table.insert(unlocked, cosmeticId)
    end

    player:SetAttribute("OwnedCosmetics", merged)
    normalizeSlot(player, "EquippedTrail", "trail", "trail_blue")
    normalizeSlot(player, "EquippedAura", "aura", nil)

    sendState(player, unlocked)
    applyEffects(player)
end

local function setupPlayer(player)
    if setupStarted[player] then
        return
    end
    setupStarted[player] = true
    task.spawn(function()
        if not PlayerReadiness.waitForDataLoaded(player) then
            return
        end

        syncUnlocks(player)

        player:GetAttributeChangedSignal("Level"):Connect(function()
            syncUnlocks(player)
        end)

        player:GetAttributeChangedSignal("ArenaMastery"):Connect(function()
            syncUnlocks(player)
        end)

        player:GetAttributeChangedSignal("Coins"):Connect(function()
            if stateEvent then
                sendState(player)
            end
        end)

        player.CharacterAdded:Connect(function()
            task.wait(0.15)
            applyEffects(player)
        end)

        if player.Character then
            applyEffects(player)
        end
    end)
end

local function equipCosmetic(player, cosmeticId)
    if player.Parent ~= Players
        or player:GetAttribute("DataLoaded") ~= true
        or player:GetAttribute("DataPersistenceAvailable") ~= true
    then
        return false
    end

    local item = Cosmetics.get(cosmeticId)
    if not item then
        return false
    end

    local owned = player:GetAttribute("OwnedCosmetics") or ""
    if not Cosmetics.canEquip(owned, cosmeticId) then
        return false
    end

    local slot = slotForKind(item.Kind)
    if not slot then
        return false
    end

    player:SetAttribute(slot, cosmeticId)
    applyEffects(player)
    sendState(player)

    GameAnalytics.custom(
        player,
        "CosmeticEquipped",
        1,
        "Cosmetic:" .. cosmeticId,
        "Kind:" .. tostring(item.Kind),
        "Level:" .. tostring(player:GetAttribute("Level") or 1)
    )
    return true
end

local function buyCosmetic(player, cosmeticId)
    if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then
        return
    end

    if player:GetAttribute("DataPersistenceAvailable") ~= true then
        sendState(player, nil, "data_unavailable")
        return
    end

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
    equipCosmetic(player, cosmeticId)
    sendState(player, nil, "purchased")
    task.spawn(PlayerData.save, player, true)

    local solo = #Players:GetPlayers() <= 1
    GameAnalytics.economySink(player, price, "Cosmetic", cosmeticId, solo)
    GameAnalytics.custom(
        player,
        "CosmeticPurchased",
        price,
        "Cosmetic:" .. cosmeticId,
        "Kind:" .. tostring(item.Kind),
        "Mode:" .. GameAnalytics.modeLabel(solo)
    )
end

function CosmeticService.grant(player, cosmeticId)
    if not player
        or player.Parent ~= Players
        or player:GetAttribute("DataLoaded") ~= true
        or player:GetAttribute("DataPersistenceAvailable") ~= true
        or type(cosmeticId) ~= "string"
    then
        return false
    end

    local item = Cosmetics.get(cosmeticId)
    if not item then
        return false
    end

    local owned = Cosmetics.deserialize(player:GetAttribute("OwnedCosmetics") or "")
    local newlyGranted = not owned[cosmeticId]
    if newlyGranted then
        owned[cosmeticId] = true
        player:SetAttribute("OwnedCosmetics", Cosmetics.serialize(owned))
    end

    local slot = slotForKind(item.Kind)
    if slot and (player:GetAttribute(slot) or "") == "" then
        player:SetAttribute(slot, cosmeticId)
        applyEffects(player)
    end

    sendState(player, newlyGranted and {cosmeticId} or {}, newlyGranted and "premium_granted" or nil)
    if newlyGranted then
        task.spawn(PlayerData.save, player, true)
    end
    return true
end

function CosmeticService.sync(player)
    if player:GetAttribute("DataLoaded") then
        syncUnlocks(player)
    end
end

function CosmeticService.init(remotes, rateLimiterFactory)
    stateEvent = RemoteRegistry.ensureRemoteEvent(remotes, "CosmeticState")
    actionEvent = RemoteRegistry.ensureRemoteEvent(remotes, "CosmeticAction")

    local allowAction = rateLimiterFactory.new(0.25)
    local allowSync = rateLimiterFactory.new(1.0)

    actionEvent.OnServerEvent:Connect(function(player, action, cosmeticId)
        if player.Parent ~= Players or player:GetAttribute("DataLoaded") ~= true then
            return
        end

        if action == "sync" then
            if allowSync(player.UserId) then
                sendState(player)
            end
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
        elseif action == "equip" then
            equipCosmetic(player, cosmeticId)
        end
    end)

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return CosmeticService
