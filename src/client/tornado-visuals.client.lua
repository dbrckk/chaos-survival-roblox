local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
local updateClock = 0

local bindToken = 0

local function clearDebris()
    for _, piece in ipairs(debris) do
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
    local count = tier.Name == "Low" and 5 or (tier.Name == "Medium" and 8 or 12)

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
        piece:SetAttribute("OrbitAngle", ((i - 1) / count) * math.pi * 2)
        piece:SetAttribute("OrbitRadius", 5 + ((i * 11) % 18))
        piece:SetAttribute("OrbitHeight", 2 + ((i * 7) % 13))
        piece:SetAttribute("OrbitSpeed", 1.6 + ((i * 5) % 7) * 0.14)
        piece.Parent = debrisFolder
        table.insert(debris, piece)
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
    updateClock = 0

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

RunService.RenderStepped:Connect(function(dt)
    if not activeModel or not activeModel.Parent then
        return
    end

    pulseClock += dt
    updateClock += dt

    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if updateClock < tier.UpdateInterval then
        return
    end
    updateClock = 0

    local pulse = (math.sin(pulseClock * 4) + 1) * 0.5

    if dangerZone and dangerZone.Parent then
        dangerZone.Transparency = 0.88 + pulse * 0.07
    end
    if lower and lower.Parent then
        lower.Transparency = 0.30 + pulse * 0.16
    end
    if middle and middle.Parent then
        middle.Transparency = 0.40 + pulse * 0.15
    end
    if upper and upper.Parent then
        upper.Transparency = 0.50 + pulse * 0.14
    end
    if light and light.Parent then
        light.Brightness = (1.0 + pulse * 0.9) * tier.Scale
        light.Range = 20 + (6 * tier.Scale)
    end

    if middle and middle.Parent then
        local center = middle.Position
        for i, piece in ipairs(debris) do
            if piece.Parent then
                local baseAngle = piece:GetAttribute("OrbitAngle") or 0
                local radius = piece:GetAttribute("OrbitRadius") or 8
                local height = piece:GetAttribute("OrbitHeight") or 5
                local speed = piece:GetAttribute("OrbitSpeed") or 1.8
                local angle = baseAngle + pulseClock * speed
                local wobble = math.sin(pulseClock * 3.4 + i) * 0.55
                local position = center + Vector3.new(
                    math.cos(angle) * radius,
                    -5 + height + wobble,
                    math.sin(angle) * radius
                )
                piece.CFrame = CFrame.new(position)
                    * CFrame.Angles(pulseClock * 2.2 + i, -angle, pulseClock * 1.3)
            end
        end
    end
end)
