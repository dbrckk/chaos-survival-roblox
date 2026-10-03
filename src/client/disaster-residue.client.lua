local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local DisasterResidue = require(ReplicatedStorage.Shared.DisasterResidue)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stateEvent = remotes:WaitForChild("RoundState")
local impactEvent = remotes:WaitForChild("HazardImpactFeedback")

local folder = Instance.new("Folder")
folder.Name = "DisasterResidueLocal"
folder.Parent = workspace

local phase = "waiting"
local previousPhase = "waiting"
local lastIds = {}
local roundToken = 0

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function clearResidue(duration)
    roundToken += 1
    local children = folder:GetChildren()
    if #children == 0 then
        return
    end

    for _, instance in ipairs(children) do
        if instance:IsA("BasePart") then
            TweenService:Create(
                instance,
                TweenInfo.new(duration or 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1}
            ):Play()
            Debris:AddItem(instance, (duration or 0.25) + 0.08)
        else
            instance:Destroy()
        end
    end
end

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function surfaceAt(position)
    if typeof(position) ~= "Vector3" then
        return nil, nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if not generated then
        return position, Vector3.new(0, 1, 0)
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {generated}
    params.IgnoreWater = true

    local result = workspace:Raycast(
        position + Vector3.new(0, 18, 0),
        Vector3.new(0, -60, 0),
        params
    )

    if result then
        return result.Position + result.Normal * 0.035, result.Normal
    end

    return position, Vector3.new(0, 1, 0)
end

local function flatCFrame(position, normal, yaw)
    local up = normal.Magnitude > 0.01 and normal.Unit or Vector3.new(0, 1, 0)
    local tangent = math.abs(up:Dot(Vector3.new(0, 0, 1))) > 0.96
        and Vector3.new(1, 0, 0)
        or Vector3.new(0, 0, 1)
    local right = tangent:Cross(up).Unit
    local forward = up:Cross(right).Unit
    return CFrame.fromMatrix(position, right, up, forward)
        * CFrame.Angles(0, math.rad(yaw or 0), 0)
end

local function makePart(name, size, cframe, color, material, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material or Enum.Material.SmoothPlastic
    part.Color = color
    part.Transparency = transparency or 0.45
    part:SetAttribute("ResidueCreatedAt", os.clock())
    part.Parent = folder
    return part
end

local function fadeLater(part, lifetime)
    task.delay(math.max(0.2, lifetime - 0.8), function()
        if part.Parent then
            TweenService:Create(
                part,
                TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Transparency = 1}
            ):Play()
        end
    end)
    Debris:AddItem(part, lifetime + 0.05)
end

local function makeDisc(name, position, diameter, profile, transparency, lifetime)
    local surface, normal = surfaceAt(position)
    if not surface then
        return
    end

    local disc = makePart(
        name,
        Vector3.new(0.035, diameter, diameter),
        flatCFrame(surface, normal, 0) * CFrame.Angles(0, 0, math.rad(90)),
        profile.Color,
        profile.Material,
        transparency
    )
    disc.Shape = Enum.PartType.Cylinder
    fadeLater(disc, lifetime)
end

local function makeCracks(name, position, radius, profile, count, lifetime)
    local surface, normal = surfaceAt(position)
    if not surface then
        return
    end

    local base = flatCFrame(surface, normal, 0)
    for i = 1, count do
        local angle = ((i - 1) / count) * 360 + ((i * 31) % 17)
        local length = radius * (0.50 + ((i * 13) % 30) / 100)
        local line = makePart(
            name .. i,
            Vector3.new(0.10, 0.028, length),
            base
                * CFrame.Angles(0, math.rad(angle), 0)
                * CFrame.new(0, 0.01, -length * 0.42),
            profile.Color:Lerp(Color3.new(0, 0, 0), 0.22),
            profile.Material,
            0.38
        )
        fadeLater(line, lifetime)
    end
end

local function impactBudget(profile)
    if profile.Name == "Low" then
        return 18
    elseif profile.Name == "Medium" then
        return 34
    end
    return 52
end

local function trimBudget()
    local children = folder:GetChildren()
    local limit = impactBudget(tier())
    if #children <= limit then
        return
    end

    table.sort(children, function(a, b)
        return (a:GetAttribute("ResidueCreatedAt") or 0)
            < (b:GetAttribute("ResidueCreatedAt") or 0)
    end)

    for i = 1, #children - limit do
        children[i]:Destroy()
    end
end

local function impactResidue(payload)
    if phase ~= "round" or type(payload) ~= "table" then
        return
    end

    local kind = tostring(payload.kind or "")
    local disasterId = kind == "Meteor" and "Meteors"
        or (kind == "Bomb" and "Bombs" or nil)
    local profile = disasterId and DisasterResidue.get(disasterId)
    if not profile then
        return
    end

    local position = payload.position
    if typeof(position) ~= "Vector3" then
        return
    end

    local quality = tier()
    local radius = math.clamp(tonumber(payload.radius) or 8, 2, 40)
    local lifetime = DisasterResidue.impactLifetime(quality.Name)
    local diameter = radius * (kind == "Meteor" and 0.82 or 0.68)

    makeDisc(
        kind .. "ScorchResidue",
        position,
        diameter,
        profile,
        quality.Name == "Low" and 0.72 or 0.58,
        lifetime
    )

    if quality.Name ~= "Low" then
        makeCracks(
            kind .. "ImpactCrack",
            position,
            radius * 0.78,
            profile,
            quality.Name == "High" and 5 or 3,
            lifetime
        )
    end
    trimBudget()
end

local function warningResidue(instance)
    if not instance:IsA("BasePart") then
        return
    end

    local id
    if instance.Name == "FreezeWarning" then
        id = "Freeze"
    elseif instance.Name == "JumpShockWarning" then
        id = "JumpShock"
    else
        return
    end

    local token = roundToken
    local duration = math.max(
        0.1,
        tonumber(instance:GetAttribute("WarningDuration")) or 0.7
    )
    local position = instance.Position

    task.delay(duration + 0.03, function()
        if token ~= roundToken or phase ~= "round" then
            return
        end

        local profile = DisasterResidue.get(id)
        local quality = tier()
        if not profile then
            return
        end

        makeDisc(
            id .. "PulseResidue",
            position,
            id == "Freeze" and 11 or 8,
            profile,
            quality.Name == "Low" and 0.80 or 0.68,
            quality.Name == "Low" and 1.4 or 2.4
        )

        if quality.Name == "High" then
            makeCracks(
                id .. "PulseTrace",
                position,
                id == "Freeze" and 5.5 or 4.2,
                profile,
                4,
                2.2
            )
        end
        trimBudget()
    end)
end

local function resultResidueFor(id, index, count, base, quality)
    local profile = DisasterResidue.get(id)
    if not profile then
        return
    end

    local budget = DisasterResidue.resultBudget(quality.Name)
    local perDisaster = math.max(1, math.floor(budget / math.max(1, count)))
    local halfX = base.Size.X * 0.5
    local halfZ = base.Size.Z * 0.5
    local lifetime = quality.Name == "Low" and 2.2 or 3.8

    for i = 1, perDisaster do
        local seed = i + index * 11
        local x = ((((seed * 37) % 101) / 100) * 2 - 1) * halfX * 0.68
        local z = ((((seed * 53) % 97) / 96) * 2 - 1) * halfZ * 0.68
        local position = base.Position
            + Vector3.new(x, base.Size.Y * 0.5 + 0.08, z)

        if profile.Kind == "fracture"
            or profile.Kind == "scrape"
            or profile.Kind == "streak"
            or profile.Kind == "edge"
        then
            local yaw = (seed * 47) % 180
            local surface, normal = surfaceAt(position)
            if surface then
                local length = profile.Kind == "edge" and 7.5 or 5.5
                local trace = makePart(
                    id .. "ResultTrace" .. i,
                    Vector3.new(0.12, 0.025, length),
                    flatCFrame(surface, normal, yaw),
                    profile.Color,
                    profile.Material,
                    quality.Name == "Low" and 0.76 or 0.62
                )
                fadeLater(trace, lifetime)
            end
        else
            local diameter = profile.Kind == "frost" and 6.5
                or (profile.Kind == "crater" and 5.5 or 4.8)
            makeDisc(
                id .. "ResultResidue" .. i,
                position,
                diameter,
                profile,
                quality.Name == "Low" and 0.78 or 0.64,
                lifetime
            )

            if quality.Name == "High"
                and (profile.Kind == "crater"
                    or profile.Kind == "scorch"
                    or profile.Kind == "shock")
            then
                makeCracks(
                    id .. "ResultCrack" .. i .. "_",
                    position,
                    diameter * 0.72,
                    profile,
                    3,
                    lifetime
                )
            end
        end
    end
end

local function playResultResidue()
    local base = arenaBase()
    if not base then
        return
    end

    local quality = tier()
    for index, id in ipairs(lastIds) do
        resultResidueFor(id, index, #lastIds, base, quality)
    end
    trimBudget()
end

impactEvent.OnClientEvent:Connect(impactResidue)
workspace.ChildAdded:Connect(warningResidue)

stateEvent.OnClientEvent:Connect(function(state)
    previousPhase = phase
    phase = tostring(state.phase or "waiting")

    if phase == "round" then
        local ids = {}
        for _, id in ipairs(state.disasterIds or {}) do
            table.insert(ids, tostring(id))
        end
        lastIds = ids

        if previousPhase ~= "round" then
            clearResidue(0.18)
        end
    elseif previousPhase == "round" and phase == "result" then
        roundToken += 1
        playResultResidue()
    elseif phase == "ready" or phase == "intermission" or phase == "waiting" then
        clearResidue(0.28)
    end
end)
