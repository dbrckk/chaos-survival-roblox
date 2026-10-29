-- One real physical destination at a time during an experienced
-- high-ground mastery challenge. This is a *visual hint only*:
-- the server determines progress, standing time and Coins/XP.
--
-- No task loop, RenderStepped listener, custom Parts or new Remotes:
-- reuse the existing authoritative RoundState heartbeat (~1Hz).
-- Also respects rookie tutoring, live collapse warnings, streaming,
-- mobile graphic tiers and the optional Storm Harbor cargo objective.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local JumpRouteCueRules = require(ReplicatedStorage.Shared.JumpRouteCueRules)

local player = Players.LocalPlayer
local states = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local playerGui = player:WaitForChild("PlayerGui")
local marker, caption
local latestState = nil
local currentTarget = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
rayParams.RespectCanCollide = true

local function hide()
    if marker then
        marker.Enabled = false
        marker.Adornee = nil
    end
    currentTarget = nil
end

local function liveSurface(part)
    if not part or not part:IsA("BasePart") or not part.Parent
        or not part.Anchored or not part.CanCollide
        or part.Transparency >= 0.75 then return false end
    local phase = part:GetAttribute("CollapsePhase")
    return phase ~= "Warning" and phase ~= "Gone"
end

local function findRealChild(folder, name)
    local part = folder and folder:FindFirstChild(name)
    if liveSurface(part) then return part end
    return nil
end

local function orbitalNext(arena, from, root)
    -- Orbital's eight authored stair-free paths are physical inclined
    -- ramps, NOT jump-sized gaps. Always guide to a real server-owned
    -- collidable EntryRamp / HelixRamp / CoreRamp or its actual deck.
    local circuit = arena:FindFirstChild("HelixCircuit")
    local platforms = arena:FindFirstChild("Platforms")
    local base = arena:FindFirstChild("Base")
    if not circuit or not platforms or not base then return nil end

    if from == base then
        local best, bestDistance = nil, 44
        for i = 1, 8 do
            local ramp = findRealChild(circuit, "EntryRamp" .. i)
            if ramp then
                local start = ramp:GetAttribute("HelixStart")
                if typeof(start) == "Vector3" then
                    local flat = Vector3.new(
                        start.X - root.Position.X, 0,
                        start.Z - root.Position.Z
                    ).Magnitude
                    if flat < bestDistance then
                        best, bestDistance = ramp, flat
                    end
                end
            end
        end
        return best
    end

    if from.Parent == platforms then
        local id = tonumber(from.Name:match("^Platform(%d+)$"))
        if not id then return nil end
        if id >= 1 and id <= 8 then
            return findRealChild(circuit, "HelixRamp" .. id)
        elseif id >= 9 and id <= 16 then
            local lane = id - 8
            return findRealChild(
                circuit, lane == 2 and "HelixRamp9"
                    or ("CoreRamp" .. lane)
            )
        end
    elseif from.Parent == circuit then
        local entry = tonumber(from.Name:match("^EntryRamp(%d+)$"))
        if entry then
            return findRealChild(platforms, "Platform" .. entry)
        end
        local helix = tonumber(from.Name:match("^HelixRamp(%d+)$"))
        if helix then
            return findRealChild(
                platforms, "Platform" .. (helix == 9 and 18 or helix + 8)
            )
        end
        local core = tonumber(from.Name:match("^CoreRamp(%d+)$"))
        if core then
            return findRealChild(platforms, "Platform18")
        end
    end
    return nil
end

local function cargoCueHasPriority(root, arena)
    if arena:GetAttribute("VariantId") ~= "Harbor" then
        return false
    end
    local collectibles = workspace:FindFirstChild("RoundChaosShards")
    if not collectibles then return false end
    for _, shard in ipairs(collectibles:GetChildren()) do
        if shard:IsA("BasePart") and shard.Parent == collectibles
            and shard:GetAttribute("ChaosShardCargo") == true
            and (shard.Position - root.Position).Magnitude <= 48 then
            return true
        end
    end
    return false
end

local function show(target, isRamp, remaining)
    if not marker then
        marker = Instance.new("BillboardGui")
        marker.Name = "GroundedMasteryRouteCue"
        marker.AlwaysOnTop = false
        marker.LightInfluence = 0
        marker.ResetOnSpawn = false
        marker.Size = UDim2.fromOffset(144, 34)
        marker.Parent = playerGui

        caption = Instance.new("TextLabel")
        caption.Name = "PhysicalRouteHint"
        caption.Size = UDim2.fromScale(1, 1)
        caption.BackgroundColor3 = Color3.fromRGB(17, 31, 38)
        caption.BackgroundTransparency = 0.12
        caption.BorderSizePixel = 0
        caption.Font = Enum.Font.GothamBold
        caption.TextScaled = true
        caption.TextStrokeTransparency = 0.65
        caption.TextColor3 = Color3.fromRGB(158, 242, 198)
        caption.Parent = marker

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = caption

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(87, 214, 162)
        stroke.Thickness = 1.3
        stroke.Parent = caption
    end

    local french = player.LocaleId:sub(1, 2) == "fr"
    local message
    if isRamp then
        message = french and "SUIS LA RAMPE  ↑" or "FOLLOW RAMP  ↑"
    else
        message = french and "VERS LE SOMMET  ↑" or "CLIMB HIGHER  ↑"
    end
    caption.Text = message
    local tier = player:GetAttribute("VfxQualityTier")
    marker.MaxDistance = tier == "Low" and 36 or (tier == "Medium" and 44 or 48)
    if currentTarget ~= target then
        currentTarget = target
        marker.Adornee = target
        marker.StudsOffsetWorldSpace = Vector3.new(
            0, target.Size.Y * 0.5 + 2.7, 0
        )
    end
    marker.Enabled = remaining > 0
end

local function update()
    local state = latestState
    if not state or state.phase ~= "round"
        or state.challengeMetric ~= "highGround"
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true then
        hide()
        return
    end
    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    if FirstTimeExperience.isRookie(games) then
        hide()
        return
    end
    local required = math.max(1, math.floor(tonumber(state.challengeTarget) or 3))
    local achieved = math.max(0, math.floor(tonumber(
        player:GetAttribute("RoundPeakTier")) or 0))
    if achieved >= required then
        hide()
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0
        or not root or not root:IsA("BasePart")
        or humanoid.FloorMaterial == Enum.Material.Air then
        hide()
        return
    end

    -- The pre-existing ONE-sign rookie/cargo coach wins if active.
    -- This prevents duplicate targets where a Harbor cargo cache
    -- coincides with a mastery objective on a veteran round.
    local existingGuide = playerGui:FindFirstChild("RookiePhysicalJumpCue")
    if existingGuide and existingGuide:IsA("BillboardGui")
        and existingGuide.Enabled then
        hide()
        return
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not platforms or not liveSurface(base)
        or cargoCueHasPriority(root, arena) then
        hide()
        return
    end

    rayParams.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -9, 0), rayParams
    )
    local from = hit and hit.Instance
    if not liveSurface(from) or hit.Normal.Y < 0.65 then
        hide()
        return
    end

    local variant = arena:GetAttribute("VariantId")
    local target
    local isRamp = false
    if variant == "Orbital" then
        target = orbitalNext(arena, from, root)
        local circuit = arena:FindFirstChild("HelixCircuit")
        isRamp = circuit ~= nil and target ~= nil
            and target.Parent == circuit
    elseif from == base then
        target = JumpRouteCueRules.nearestEntry(
            platforms:GetChildren(), hit.Position, 42
        )
    elseif from.Parent == platforms then
        target = JumpRouteCueRules.nextPhysical(
            from, platforms:GetChildren(), base.Position, variant
        )
    end

    if not liveSurface(target)
        or (root.Position - target.Position).Magnitude > 48 then
        hide()
        return
    end
    local nextTier = tonumber(target:GetAttribute("RouteTier"))
    if nextTier and nextTier > required then
        hide()
        return
    end
    show(target, isRamp, required - achieved)
end

states.OnClientEvent:Connect(function(state)
    latestState = type(state) == "table" and state or nil
    update()
end)

player:GetAttributeChangedSignal("RoundPeakTier"):Connect(update)
player.CharacterRemoving:Connect(hide)
