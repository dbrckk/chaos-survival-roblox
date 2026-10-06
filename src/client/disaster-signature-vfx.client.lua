local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "DisasterSignatureVfxLocal"
folder.Parent = workspace

local phase = "waiting"
local ids = {}
local activeSignature = ""
local clock = 0
local states = {}
local mapConnection = nil
local meteorTrails = setmetatable({}, {__mode = "k"})

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function has(id)
    for _, value in ipairs(ids) do
        if value == id then
            return true
        end
    end
    return false
end

local function clear()
    table.clear(states)
    folder:ClearAllChildren()
end

local function arenaBase()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    return base and base:IsA("BasePart") and base or nil
end

local function part(name, size, cf, color, material, transparency, shape)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.CastShadow = false
    p.Color = color
    p.Material = material or Enum.Material.Neon
    p.Transparency = transparency or 0
    if shape then
        p.Shape = shape
    end
    p.Parent = folder
    return p
end

local function addMeteorTrail(meteor)
    if meteorTrails[meteor]
        or not meteor:IsA("BasePart")
        or meteor.Name ~= "RoundMeteor"
    then
        return
    end

    local q = tier()
    if q.Name == "Low" or player:GetAttribute("ReduceMotion") == true then
        return
    end

    local profile = DisasterVisuals.get("Meteors")
    local accent = profile and profile.Accent or Color3.fromRGB(255, 135, 50)
    local tint = profile and profile.Tint or Color3.fromRGB(255, 215, 120)

    local left = Instance.new("Attachment")
    left.Name = "SignatureMeteorTrailLeft"
    left.Position = Vector3.new(-meteor.Size.X * 0.24, 0, meteor.Size.Z * 0.20)
    left.Parent = meteor

    local right = Instance.new("Attachment")
    right.Name = "SignatureMeteorTrailRight"
    right.Position = Vector3.new(meteor.Size.X * 0.24, 0, meteor.Size.Z * 0.20)
    right.Parent = meteor

    local trail = Instance.new("Trail")
    trail.Name = "SignatureMeteorTrail"
    trail.Attachment0 = left
    trail.Attachment1 = right
    trail.FaceCamera = true
    trail.LightEmission = 0.82
    trail.LightInfluence = 0
    trail.Lifetime = q.Name == "High" and 0.24 or 0.16
    trail.MinLength = 0.08
    trail.Color = ColorSequence.new(accent, tint)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.26),
        NumberSequenceKeypoint.new(1, 1),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.88),
        NumberSequenceKeypoint.new(1, 0),
    })
    trail.Parent = meteor

    meteorTrails[meteor] = true
end

local function clearMeteorTrail(meteor)
    local trail = meteor:FindFirstChild("SignatureMeteorTrail")
    if trail then
        trail:Destroy()
    end

    local left = meteor:FindFirstChild("SignatureMeteorTrailLeft")
    if left then
        left:Destroy()
    end

    local right = meteor:FindFirstChild("SignatureMeteorTrailRight")
    if right then
        right:Destroy()
    end

    meteorTrails[meteor] = nil
end

local function bindExistingMeteors()
    local enabled = phase == "round"
        and has("Meteors")
        and tier().Name ~= "Low"
        and player:GetAttribute("ReduceMotion") ~= true

    for _, child in ipairs(workspace:GetChildren()) do
        if child.Name == "RoundMeteor" and child:IsA("BasePart") then
            if enabled then
                addMeteorTrail(child)
            else
                clearMeteorTrail(child)
            end
        end
    end
end

local function addLava(base, profile)
    local q = tier()
    local count = q.Name == "Low" and 4 or (q.Name == "Medium" and 6 or 8)
    local hx = base.Size.X * 0.5
    local hz = base.Size.Z * 0.5

    for i = 1, count do
        local side = i % 4
        local pos
        if side == 0 then
            pos = Vector3.new(-hx * 0.85, 1, (-0.6 + ((i * 17) % 100) / 100 * 1.2) * hz)
        elseif side == 1 then
            pos = Vector3.new(hx * 0.85, 1, (-0.6 + ((i * 19) % 100) / 100 * 1.2) * hz)
        elseif side == 2 then
            pos = Vector3.new((-0.6 + ((i * 23) % 100) / 100 * 1.2) * hx, 1, -hz * 0.85)
        else
            pos = Vector3.new((-0.6 + ((i * 29) % 100) / 100 * 1.2) * hx, 1, hz * 0.85)
        end

        local vent = part(
            "LavaHeatVent" .. i,
            Vector3.new(0.45, 4.8, 0.45),
            base.CFrame * CFrame.new(pos),
            i % 2 == 0 and profile.Accent or profile.Tint,
            Enum.Material.Neon,
            q.Name == "Low" and 0.62 or 0.48
        )
        states[#states + 1] = {
            kind = "lava",
            part = vent,
            index = i,
            baseCFrame = vent.CFrame,
        }
    end
end

local function addDarkness(base, profile)
    local q = tier()
    if q.Name == "Low" then
        return
    end

    local count = q.Name == "High" and 8 or 4
    local radius = math.min(base.Size.X, base.Size.Z) * 0.42

    for i = 1, count do
        local angle = ((i - 1) / count) * math.pi * 2
        local orb = part(
            "VoidMote" .. i,
            Vector3.new(1.6, 1.6, 1.6),
            CFrame.new(
                base.Position
                    + Vector3.new(
                        math.cos(angle) * radius,
                        4 + (i % 3) * 2,
                        math.sin(angle) * radius
                    )
            ),
            profile.Accent,
            Enum.Material.Neon,
            0.58,
            Enum.PartType.Ball
        )
        states[#states + 1] = {
            kind = "darkness",
            part = orb,
            index = i,
            base = base,
            angle = angle,
            radius = radius,
        }
    end
end

local function rebuild()
    clear()
    if phase ~= "round" then
        return
    end

    local base = arenaBase()
    if not base then
        return
    end

    -- Tornado is intentionally not duplicated here. The real RoundTornado model
    -- is already enhanced by tornado-visuals.client.lua.
    if has("Meteors") then
        bindExistingMeteors()
    end
    if has("Darkness") then
        addDarkness(base, DisasterVisuals.get("Darkness"))
    end
end

local function bindMap()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    if generated then
        mapConnection = generated.ChildAdded:Connect(function(child)
            if child.Name == "Arena" then
                task.delay(0.08, rebuild)
            end
        end)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap()
        task.delay(0.08, rebuild)
    elseif child.Name == "RoundMeteor" and phase == "round" and has("Meteors") then
        task.defer(addMeteorTrail, child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "GeneratedMap" then
        clear()
        bindMap()
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    rebuild()
    bindExistingMeteors()
end)

player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    bindExistingMeteors()
end)

stateEvent.OnClientEvent:Connect(function(state)
    local nextPhase = tostring(state.phase or "waiting")
    local nextIds = {}
    for _, id in ipairs(state.disasterIds or {}) do
        nextIds[#nextIds + 1] = tostring(id)
    end
    table.sort(nextIds)

    local nextSignature = nextPhase .. "|" .. table.concat(nextIds, ",")
    phase = nextPhase
    ids = nextIds

    if nextSignature ~= activeSignature then
        activeSignature = nextSignature
        rebuild()
    elseif phase == "round" and has("Meteors") then
        bindExistingMeteors()
    end
end)

task.spawn(function()
    while true do
        local q = tier()
        local dt = task.wait(math.max(1 / 30, q.UpdateInterval))

        if #states == 0 then
            continue
        end

        clock += dt
        local reduced = player:GetAttribute("ReduceMotion") == true
        local motion = reduced and 0.16 or 1

        for _, state in ipairs(states) do
            local p = state.part
            if not p or not p.Parent then
                continue
            end

            if state.kind == "lava" then
                local pulse = (math.sin(clock * (2.6 + state.index * 0.05)) + 1) * 0.5
                p.Size = Vector3.new(0.45, 4.4 + pulse * 3.2 * motion, 0.45)
                p.CFrame = state.baseCFrame * CFrame.new(0, (p.Size.Y - 4.8) * 0.5, 0)
                p.Transparency = 0.42 + pulse * 0.20
            elseif state.kind == "darkness" and state.base and state.base.Parent then
                local direction = state.index % 2 == 0 and 1 or -1
                local angle = state.angle + clock * 0.12 * motion * direction
                local y = 5 + math.sin(clock * 0.9 + state.index) * 1.6 * motion
                p.CFrame = CFrame.new(
                    state.base.Position
                        + Vector3.new(
                            math.cos(angle) * state.radius,
                            y,
                            math.sin(angle) * state.radius
                        )
                )
                p.Transparency = 0.50
                    + ((math.sin(clock * 1.4 + state.index) + 1) * 0.5) * 0.28
            end
        end
    end
end)

bindMap()
rebuild()
