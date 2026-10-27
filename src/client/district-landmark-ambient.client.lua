-- Client-only ambient animation for the four distinctive skyline landmarks.
-- Enhances large arena legibility without server replicated animation.
-- No new geometry, textures, lights, sounds, physics or RenderStepped.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local TRACKED = {
    ScannerLens = true,
    PodGlazing1 = true,
    PodGlazing2 = true,
    ContainmentHeart = true,
    NavigationLens = true,
    GlassBelt = true,
}
local animations = {}
local epoch = 0
local mapConnection

local function qualityAllowed()
    local tier = tostring(player:GetAttribute("VfxQualityTier") or "Low")
    return tier ~= "Low" and player:GetAttribute("ReduceMotion") ~= true
end

local function stopAll()
    epoch += 1
    for part, data in pairs(animations) do
        data.tween:Cancel()
        if part.Parent then
            part.Transparency = data.original
        end
        animations[part] = nil
    end
end

local function pulse(part)
    if animations[part] or not part:IsA("BasePart")
        or not TRACKED[part.Name] or not qualityAllowed() then
        return
    end
    local original = part.Transparency
    local low = math.clamp(original - 0.12, 0, 0.9)
    local high = math.clamp(original + 0.23, 0, 0.92)
    local duration = 2.0 + ((#part.Name % 4) * 0.31)
    local tween = TweenService:Create(part,
        TweenInfo.new(duration, Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut, -1, true),
        {Transparency = high})
    animations[part] = {tween = tween, original = original}
    part.Transparency = low
    tween:Play()
end

local function untrack(part)
    local data = animations[part]
    if data then
        data.tween:Cancel()
        if part.Parent then part.Transparency = data.original end
        animations[part] = nil
    end
end

local function isLandmarkPart(part, container)
    return part:IsA("BasePart") and part.Parent
        and part.Parent:IsA("Model")
        and part.Parent.Parent == container
        and part.Parent:GetAttribute("SourceIsOriginal") == true
        and part.Parent:GetAttribute("CornerLandmarkIndex") ~= nil
end

local function bindArena(arena)
    stopAll()
    if mapConnection then
        mapConnection:Disconnect()
        mapConnection = nil
    end
    if not arena then return end
    local decor = arena:FindFirstChild("Decor")
    local landmarks = decor and decor:FindFirstChild("ArenaCornerLandmarks3D")
    if not landmarks then return end
    for _, child in ipairs(landmarks:GetDescendants()) do
        if isLandmarkPart(child, landmarks) then
            pulse(child)
        end
    end
    mapConnection = landmarks.DescendantAdded:Connect(function(child)
        if isLandmarkPart(child, landmarks) then pulse(child) end
    end)
end

local function bindCurrent()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    bindArena(arena)
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    bindCurrent()
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    bindCurrent()
end)
workspace.DescendantAdded:Connect(function(instance)
    if instance.Name == "ArenaCornerLandmarks3D"
        and instance:IsA("Folder") then
        -- Roblox streaming may deliver the folder after the arena itself.
        bindCurrent()
    end
end)
workspace.DescendantRemoving:Connect(function(instance)
    if instance.Name == "Arena" and instance:IsA("Model") then
        bindArena(nil)
    elseif animations[instance] then
        untrack(instance)
    end
end)

bindCurrent()
