local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)

local player = Players.LocalPlayer
local tracked = {}
local currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
local renderConnection = nil
local warningNames = {
    BombWarning = true,
    MeteorWarning = true,
    FreezeWarning = true,
    JumpShockWarning = true,
}

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    currentTier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
end)

local function ensureRenderLoop()
    if renderConnection or next(tracked) == nil then
        return
    end

    renderConnection = RunService.RenderStepped:Connect(function(dt)
        for part, state in pairs(tracked) do
            if not part.Parent then
                tracked[part] = nil
                continue
            end

            state.clock += dt
            if state.clock < currentTier.UpdateInterval then
                continue
            end
            state.clock = 0

            local alpha = math.clamp((workspace:GetServerTimeNow() - state.startedAt) / state.duration, 0, 1)
            local pulse = (math.sin(alpha * math.pi * 6) + 1) * 0.5

            if state.kind == "Freeze" then
                local freezePeak = 0.18 * currentTier.Scale
                part.Transparency = math.clamp(
                    0.84 - (freezePeak * math.sin(alpha * math.pi)),
                    0.60,
                    0.92
                )
            elseif state.kind == "JumpShock" then
                local diameter = state.startSize + ((state.endSize - state.startSize) * alpha)
                part.Size = Vector3.new(part.Size.X, diameter, diameter)
                part.Transparency = 0.30 + (0.58 * alpha)
            else
                local diameter = state.startSize + ((state.endSize - state.startSize) * alpha)
                part.Size = Vector3.new(diameter, part.Size.Y, diameter)
                part.Transparency = 0.12 + (pulse * 0.24)
            end

            if alpha >= 1 then
                tracked[part] = nil
            end
        end

        if next(tracked) == nil and renderConnection then
            renderConnection:Disconnect()
            renderConnection = nil
        end
    end)
end

local function register(part)
    if not part:IsA("BasePart") then
        return
    end

    local kind = part:GetAttribute("WarningKind")
    if type(kind) ~= "string" or kind == "" then
        return
    end

    tracked[part] = {
        startedAt = tonumber(part:GetAttribute("WarningStartedAt")) or workspace:GetServerTimeNow(),
        kind = kind,
        duration = math.max(0.05, tonumber(part:GetAttribute("WarningDuration")) or 0.05),
        startSize = math.max(0.1, tonumber(part:GetAttribute("WarningStartSize")) or part.Size.X),
        endSize = math.max(0.1, tonumber(part:GetAttribute("WarningEndSize")) or part.Size.X),
        clock = 0,
    }

    ensureRenderLoop()
end

local function maybeRegister(part)
    if not part:IsA("BasePart") then
        return
    end

    if part:GetAttribute("WarningKind") then
        register(part)
        return
    end

    if not warningNames[part.Name] then
        return
    end

    local connection
    connection = part:GetAttributeChangedSignal("WarningKind"):Connect(function()
        if part:GetAttribute("WarningKind") then
            if connection then
                connection:Disconnect()
            end
            register(part)
        end
    end)

    task.delay(1, function()
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end)
end

for _, child in ipairs(workspace:GetChildren()) do
    maybeRegister(child)
end

workspace.ChildAdded:Connect(maybeRegister)
workspace.ChildRemoved:Connect(function(child)
    tracked[child] = nil
end)
