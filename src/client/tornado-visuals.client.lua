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

local bindToken = 0

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
