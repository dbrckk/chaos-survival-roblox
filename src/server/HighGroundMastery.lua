--!strict
-- Grounded, one-per-round climb mastery. This module does not grant Coins,
-- move the character, listen to touches, create loops or accept client
-- messages. Called from the EXISTING once-per-second server round tick
-- only when a legitimate high-ground challenge is active.
local HighGroundMastery = {}

-- A genuine, stable 2-sample landing on a real collidable server platform
-- is required. Looking at a rooftop, brushing a step midair, riding a
-- cosmetic mesh or touching a collapsing deck cannot earn mastery.
function HighGroundMastery.sample(character, platformFolder, state, now)
    local memory = state or {}
    if typeof(character) ~= "Instance" or not character:IsA("Model")
        or typeof(platformFolder) ~= "Instance"
        or not platformFolder:IsA("Folder")
        or type(now) ~= "number" or now ~= now
        or now == math.huge or now == -math.huge then
        memory.deck = nil
        return memory, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0
        or not root or not root:IsA("BasePart")
        or humanoid.FloorMaterial == Enum.Material.Air
        or math.abs(root.AssemblyLinearVelocity.Y) > 7.5 then
        memory.deck = nil
        return memory, nil
    end

    if memory.character ~= character or not memory.rayParams then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character}
        params.RespectCanCollide = true
        memory.rayParams = params
        memory.character = character
        memory.deck = nil
    end

    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -7.5, 0), memory.rayParams
    )
    local deck = hit and hit.Instance
    local tier = deck and tonumber(deck:GetAttribute("RouteTier")) or nil
    if not deck or deck.Parent ~= platformFolder
        or not deck:IsA("BasePart") or not deck.CanCollide
        or deck.Transparency >= 0.75
        or deck:GetAttribute("CollapsePhase") ~= nil
        or not hit or hit.Normal.Y < 0.84
        or not tier or tier < 1 or tier > 4 or tier % 1 ~= 0
        or root.Position.Y < deck.Position.Y + deck.Size.Y * 0.5 + 1.2
        or root.Position.Y > deck.Position.Y + deck.Size.Y * 0.5 + 5.5 then
        memory.deck = nil
        return memory, nil
    end

    if deck ~= memory.deck then
        memory.deck = deck
        memory.firstSeenAt = now
        return memory, nil
    end

    local heldFor = now - (memory.firstSeenAt or now)
    if heldFor < 0.7 or heldFor > 2.5 then
        memory.firstSeenAt = now
        return memory, nil
    end
    -- At most one progress update for each new higher route tier.
    local peak = math.clamp(
        math.floor(tonumber(memory.peak) or 0), 0, 4
    )
    if tier > peak then
        memory.peak = tier
        return memory, tier
    end
    return memory, nil
end

return HighGroundMastery
