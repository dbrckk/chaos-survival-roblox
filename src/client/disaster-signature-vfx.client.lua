local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local phase = "waiting"
local ids = {}
local activeSignature = ""
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

local function addMeteorTrail(meteor)
    if meteorTrails[meteor]
        or not meteor:IsA("BasePart")
        or meteor.Name ~= "RoundMeteor"
    then
        return
    end

    local quality = tier()
    if quality.Name == "Low" or player:GetAttribute("ReduceMotion") == true then
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
    trail.Lifetime = quality.Name == "High" and 0.24 or 0.16
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

local function refreshMeteorTrails()
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

workspace.ChildAdded:Connect(function(child)
    if child.Name == "RoundMeteor" and phase == "round" and has("Meteors") then
        task.defer(addMeteorTrail, child)
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refreshMeteorTrails)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refreshMeteorTrails)

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
        refreshMeteorTrails()
    end
end)

refreshMeteorTrails()
