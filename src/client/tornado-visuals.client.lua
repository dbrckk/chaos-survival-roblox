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
local pulseClock = 0
local updateClock = 0

local function bind(model)
    if not model or model.Name ~= "RoundTornado" then
        return
    end

    activeModel = model
    dangerZone = model:FindFirstChild("DangerZone")
    lower = model:FindFirstChild("LowerFunnel")
    middle = model:FindFirstChild("MiddleFunnel")
    upper = model:FindFirstChild("UpperFunnel")
    light = middle and middle:FindFirstChild("TornadoGlow") or nil
    pulseClock = 0
    updateClock = 0
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
        activeModel = nil
        dangerZone = nil
        lower = nil
        middle = nil
        upper = nil
        light = nil
    end
end)

findExisting()

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
end)
