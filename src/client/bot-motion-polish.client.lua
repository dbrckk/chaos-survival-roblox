local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local folder = nil
local bots = setmetatable({}, {__mode = "k"})
local clock = 0
local updateClock = 0

local function tier()
    return VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end

local function accent(model)
    local value = model:GetAttribute("ChaosAccent")
    return typeof(value) == "Color3" and value or Color3.fromRGB(105, 220, 185)
end

local function ensureChestPulse()
    -- CharacterPolish already owns the character PointLight budget.
    -- Keep this layer focused on gait/trail differentiation to avoid
    -- double-lighting AI rigs.
    return nil
end
local function watch(model)
    if bots[model] then
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or not root:IsA("BasePart") then
        task.delay(0.12, function()
            if model.Parent then
                watch(model)
            end
        end)
        return
    end

    local index = 1
    if folder then
        for i, child in ipairs(folder:GetChildren()) do
            if child == model then
                index = i
                break
            end
        end
    end

    bots[model] = {
        humanoid = humanoid,
        root = root,
        light = ensureChestPulse(model, index),
        index = index,
        lastSpeed = 0,
    }
end

local function bind(newFolder)
    folder = newFolder
    if not folder then
        return
    end

    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then
            watch(child)
        end
    end

    folder.ChildAdded:Connect(function(child)
        if child:IsA("Model") then
            task.defer(watch, child)
        end
    end)
end

local existing = workspace:FindFirstChild("AISurvivors")
if existing then
    bind(existing)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "AISurvivors" then
        bind(child)
    end
end)

RunService.RenderStepped:Connect(function(dt)
    clock += dt
    updateClock += dt

    local q = tier()
    if updateClock < math.max(1 / 30, q.UpdateInterval) then
        return
    end
    updateClock = 0

    local reduceMotion = player:GetAttribute("ReduceMotion") == true
    local motionScale = reduceMotion and 0.18 or 1

    for model, state in pairs(bots) do
        if not model.Parent or state.humanoid.Health <= 0 or not state.root.Parent then
            if state.light and state.light.Parent then
                state.light.Enabled = false
            end
            continue
        end

        local speed = Vector3.new(
            state.root.AssemblyLinearVelocity.X,
            0,
            state.root.AssemblyLinearVelocity.Z
        ).Magnitude
        state.lastSpeed = state.lastSpeed + (speed - state.lastSpeed) * 0.22

        if state.light and state.light.Parent then
            local running = state.lastSpeed > math.max(8, state.humanoid.WalkSpeed * 0.58)
            state.light.Enabled = q.Name == "High" and running and not reduceMotion
            if state.light.Enabled then
                local pulse = (math.sin(clock * (2.1 + state.index * 0.09) + state.index) + 1) * 0.5
                state.light.Color = accent(model)
                state.light.Brightness = (0.08 + pulse * 0.12) * motionScale
                state.light.Range = 4.5 + pulse * 1.2
            end
        end

        local trail = state.root:FindFirstChild("AISurvivorCosmeticTrail")
        if trail and trail:IsA("Trail") then
            local runRatio = math.clamp(state.lastSpeed / math.max(1, state.humanoid.WalkSpeed), 0, 1.25)
            trail.Enabled = q.Name ~= "Low" and runRatio > 0.68
            trail.Lifetime = (0.09 + (state.index % 3) * 0.024)
                * (q.Name == "High" and 1 or 0.72)
                * (reduceMotion and 0.30 or 1)
        end
    end
end)
