local Players = game:GetService("Players")
local Cosmetics = require(script.Parent.CosmeticsCatalog)

local CosmeticService = {}

local stateEvent
local actionEvent

local function clearEffect(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    for _, name in ipairs({"ChaosTrail", "ChaosTrailA0", "ChaosTrailA1"}) do
        local obj = root:FindFirstChild(name)
        if obj then
            obj:Destroy()
        end
    end
end

local function applyEffect(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    clearEffect(character)

    local id = player:GetAttribute("EquippedCosmetic") or ""
    local item = Cosmetics.get(id)
    if not item or item.Kind ~= "trail" then
        return
    end

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
    trail.Lifetime = 0.45
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.LightEmission = 0.65
    trail.Color = ColorSequence.new(item.ColorA, item.ColorB)
    trail.Parent = root
end

local function stateFor(player)
    local owned = Cosmetics.deserialize(player:GetAttribute("OwnedCosmetics") or "")
    return {
        catalog = Cosmetics.publicList(),
        owned = owned,
        equipped = player:GetAttribute("EquippedCosmetic") or "",
    }
end

local function sendState(player, unlocked)
    if stateEvent then
        stateEvent:FireClient(player, {
            state = stateFor(player),
            unlocked = unlocked or {},
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

        player.CharacterAdded:Connect(function()
            task.wait(0.15)
            applyEffect(player)
        end)

        if player.Character then
            applyEffect(player)
        end
    end)
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

        if action ~= "equip" or type(cosmeticId) ~= "string" then
            return
        end

        if not allowAction(player.UserId) then
            return
        end

        local owned = player:GetAttribute("OwnedCosmetics") or ""
        if not Cosmetics.canEquip(owned, cosmeticId) then
            return
        end

        player:SetAttribute("EquippedCosmetic", cosmeticId)
        applyEffect(player)
        sendState(player)
    end)

    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        setupPlayer(player)
    end
end

return CosmeticService
