local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local activeModel = nil
local dangerZone = nil
local lower = nil
local middle = nil
local upper = nil
local light = nil
local debrisFolder = nil
local debris = {}
local pulseClock = 0
local loopStarted = false
local ensureRenderLoop

local bindToken = 0

local function clearDebris()
    for _, state in ipairs(debris) do
        local piece = state.part
        if piece and piece.Parent then
            piece:Destroy()
        end
    end
    table.clear(debris)
    if debrisFolder and debrisFolder.Parent then
        debrisFolder:Destroy()
    end
    debrisFolder = nil
end

-- One authored helical pose per debris shard. Reuse the same 5/8/12
-- Parts for all tiers; no extra emitters, lights or collision instances.
local function poseShard(state, center, time)
    local angle = state.angle + time * state.speed
    local orbit = state.radius + math.sin(time * 1.15 + state.index * 0.83) * 0.38
    local lift = math.sin(time * 2.2 + state.index * 1.7) * 0.46
    local position = center + Vector3.new(
        math.cos(angle) * orbit,
        -5 + state.height + lift,
        math.sin(angle) * orbit
    )
    state.part.CFrame = CFrame.new(position)
        * CFrame.Angles(
            math.rad(state.pitch) + math.sin(time * 1.4 + state.index) * 0.11,
            -angle + math.pi * 0.5,
            math.rad(state.bank) + math.sin(time * 2.0 + state.index) * 0.16
        )
end

local function buildDebris()
    clearDebris()
    if not activeModel or not activeModel.Parent or not middle then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local count = tier.Name == "Low" and 5 or (tier.Name == "Medium" and 8 or 12)

    debrisFolder = Instance.new("Folder")
    debrisFolder.Name = "TornadoDebrisLocal"
    debrisFolder.Parent = workspace

    for i = 1, count do
        local glint = i % 4 == 0
        local piece = Instance.new("WedgePart")
        piece.Name = "WindDebris" .. i
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        -- A few pale glass facets catch the storm's light; the majority
        -- remain matte, wind-sheared metal, not glowing generic cubes.
        piece.Material = glint and Enum.Material.Glass or Enum.Material.Metal
        piece.Color = glint and Color3.fromRGB(122, 211, 220)
            or (i % 3 == 0 and Color3.fromRGB(72, 106, 121)
                or Color3.fromRGB(98, 115, 125))
        piece.Size = Vector3.new(
            0.30 + ((i * 7) % 5) * 0.11,
            0.24 + ((i * 3) % 4) * 0.09,
            1.20 + ((i * 5) % 7) * 0.19
        )
        piece.Transparency = glint and 0.29 or 0.08
        piece.Parent = debrisFolder
        local height = 2 + ((i * 7) % 13)
        local state = {
            part = piece,
            index = i,
            angle = ((i - 1) / count) * math.pi * 2
                + (height / 16) * math.pi * 0.85,
            radius = 5 + ((i * 11) % 16) * 0.81,
            height = height,
            speed = 1.55 + ((i * 5) % 7) * 0.13,
            pitch = (i % 2 == 0 and -1 or 1) * (8 + i % 4 * 5),
            bank = (i % 2 == 0 and 1 or -1) * (13 + i % 5 * 7),
        }
        -- Never let a newly streamed shard flash at world origin before
        -- the visual update loop's next quality-dependent tick.
        poseShard(state, middle.Position, pulseClock)
        table.insert(debris, state)
    end
end

local function bind(model)
    if not model or model.Name ~= "RoundTornado" then
        return
    end

    bindToken += 1
    local token = bindToken
    activeModel = model
    pulseClock = 0

    if ensureRenderLoop then
        ensureRenderLoop()
    end

    task.spawn(function()
        local nextDangerZone = model:WaitForChild("DangerZone", 2)
        local nextLower = model:WaitForChild("LowerFunnel", 2)
        local nextMiddle = model:WaitForChild("MiddleFunnel", 2)
        local nextUpper = model:WaitForChild("UpperFunnel", 2)

        if token ~= bindToken or activeModel ~= model or not model.Parent then
            return
        end

        dangerZone = nextDangerZone
        lower = nextLower
        middle = nextMiddle
        upper = nextUpper
        light = nextMiddle and nextMiddle:FindFirstChild("TornadoGlow") or nil
        buildDebris()
    end)
end

local function findExisting()
    local model = workspace:FindFirstChild("RoundTornado")
    if model then
        bind(model)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "RoundTornado" then
        task.defer(bind, child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == activeModel then
        bindToken += 1
        activeModel = nil
        dangerZone = nil
        lower = nil
        middle = nil
        upper = nil
        light = nil
        clearDebris()
    end
end)

findExisting()

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    if activeModel and activeModel.Parent and middle then
        buildDebris()
    end
end)

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
            local dt = task.wait(tier.UpdateInterval)

            if not activeModel or not activeModel.Parent then
                continue
            end

            local reduceMotion = player:GetAttribute("ReduceMotion") == true
            -- Pausing the visual clock keeps reduced-motion debris completely
            -- still. Clamping lost frames avoids a giant jump when Android
            -- resumes from the background; server tornado timing is untouched.
            if not reduceMotion then
                pulseClock += math.clamp(tonumber(dt) or 0, 0, 0.22)
            end
            local pulse = reduceMotion and 0.5
                or (math.sin(pulseClock * 4) + 1) * 0.5
            local pulseScale = reduceMotion and 0 or 1
            if dangerZone and dangerZone.Parent then
                dangerZone.Transparency = 0.90 + pulse * 0.05 * pulseScale
            end
            if lower and lower.Parent then
                lower.Transparency = 0.34 + pulse * 0.12 * pulseScale
            end
            if middle and middle.Parent then
                middle.Transparency = 0.44 + pulse * 0.11 * pulseScale
            end
            if upper and upper.Parent then
                upper.Transparency = 0.54 + pulse * 0.10 * pulseScale
            end
            if light and light.Parent then
                light.Brightness = (1.0 + pulse * 0.9 * pulseScale) * tier.Scale
                light.Range = 20 + (6 * tier.Scale)
            end

            if middle and middle.Parent then
                local center = middle.Position
                for _, state in ipairs(debris) do
                    if state.part.Parent then
                        poseShard(state, center, pulseClock)
                    end
                end
            end
        end
    end)
end
ensureRenderLoop()
