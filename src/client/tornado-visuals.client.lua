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

local function buildDebris()
    clearDebris()
    if not activeModel or not activeModel.Parent or not middle then
        return
    end

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local reduced = player:GetAttribute("ReduceMotion") == true
    local count = reduced and 3
        or (tier.Name == "Low" and 5 or (tier.Name == "Medium" and 8 or 12))

    debrisFolder = Instance.new("Folder")
    debrisFolder.Name = "TornadoDebrisLocal"
    debrisFolder.Parent = workspace

    for i = 1, count do
        local piece = Instance.new("Part")
        piece.Name = "WindDebris" .. i
        piece.Anchored = true
        piece.CanCollide = false
        piece.CanTouch = false
        piece.CanQuery = false
        piece.CastShadow = false
        piece.Material = i % 3 == 0 and Enum.Material.Neon or Enum.Material.Metal
        piece.Color = i % 3 == 0
            and Color3.fromRGB(115, 235, 235)
            or Color3.fromRGB(95, 115, 125)
        piece.Size = Vector3.new(
            0.35 + ((i * 7) % 5) * 0.10,
            0.25 + ((i * 3) % 4) * 0.08,
            0.9 + ((i * 5) % 7) * 0.14
        )
        piece.Transparency = i % 3 == 0 and 0.20 or 0.08
        piece.Parent = debrisFolder
        table.insert(debris, {
            part = piece,
            angle = ((i - 1) / count) * math.pi * 2,
            radius = 5 + ((i * 11) % 18),
            height = 2 + ((i * 7) % 13),
            speed = 1.6 + ((i * 5) % 7) * 0.14,
        })
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

local function refreshDebris()
    if activeModel and activeModel.Parent and middle then
        buildDebris()
    end
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshDebris)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshDebris)

ensureRenderLoop = function()
    if loopStarted then
        return
    end
    loopStarted = true

    task.spawn(function()
        while true do
            if not activeModel or not activeModel.Parent then
                task.wait(0.18)
                continue
            end

            local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
            local dt = task.wait(math.max(1 / 60, tier.UpdateInterval))
            pulseClock += dt

            local reduceMotion = player:GetAttribute("ReduceMotion") == true
            local motionScale = reduceMotion and 0.18 or 1
            local pulse = (
                math.sin(pulseClock * (reduceMotion and 1.1 or 4)) + 1
            ) * 0.5

            local pulseScale = reduceMotion and 0.32 or 1
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
                for i, state in ipairs(debris) do
                    local piece = state.part
                    if piece and piece.Parent then
                        local angle = state.angle
                            + pulseClock * state.speed * motionScale
                        local wobble = math.sin(
                            pulseClock * 3.4 * motionScale + i
                        ) * 0.55 * motionScale
                        local position = center + Vector3.new(
                            math.cos(angle) * state.radius,
                            -5 + state.height + wobble,
                            math.sin(angle) * state.radius
                        )
                        piece.CFrame = CFrame.new(position)
                            * CFrame.Angles(
                                pulseClock * 2.2 * motionScale + i,
                                -angle,
                                pulseClock * 1.3 * motionScale
                            )
                    end
                end
            end
        end
    end)
end

ensureRenderLoop()
