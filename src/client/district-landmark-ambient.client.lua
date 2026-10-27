-- Four small client-side ambient beacons for original district skyline art.
-- Preserves scenery LOD transparency: never edits the mesh/part itself.
-- No new parts, sounds, network messages, physics or RenderStepped.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local LENSES = {
    [1] = "ScannerLens",
    [2] = "PodGlazing1",
    [3] = "ContainmentHeart",
    [4] = "NavigationLens",
}
local lights = {}
local containerConnection = nil

local function enabled()
    return tostring(player:GetAttribute("VfxQualityTier") or "Low") == "High"
        and player:GetAttribute("ReduceMotion") ~= true
end

local function clear()
    if containerConnection then
        containerConnection:Disconnect()
        containerConnection = nil
    end
    for part, bundle in pairs(lights) do
        bundle.tween:Cancel()
        bundle.light:Destroy()
        lights[part] = nil
    end
end

local function install(model)
    if not enabled() or not model:IsA("Model")
        or model:GetAttribute("SourceIsOriginal") ~= true then
        return
    end
    local index = tonumber(model:GetAttribute("CornerLandmarkIndex"))
    local lens = index and model:FindFirstChild(LENSES[index])
    if not lens or not lens:IsA("BasePart") or lights[lens] then
        return
    end
    local light = Instance.new("PointLight")
    light.Name = "LocalLandmarkPulse"
    light.Color = lens.Color
    light.Brightness = 0.45
    light.Range = 12
    light.Shadows = false
    light.Enabled = lens.Transparency < 0.95
    light.Parent = lens
    local tween = TweenService:Create(light,
        TweenInfo.new(2.4 + index * 0.3,
            Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 1.15})
    lights[lens] = {light = light, tween = tween}
    tween:Play()
end

local function refresh()
    clear()
    if not enabled() then return end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    local landmarks = decor and decor:FindFirstChild("ArenaCornerLandmarks3D")
    if not landmarks then return end
    for _, model in ipairs(landmarks:GetChildren()) do install(model) end
    containerConnection = landmarks.ChildAdded:Connect(install)
end

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(refresh)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(refresh)
workspace.DescendantAdded:Connect(function(instance)
    if instance.Name == "ArenaCornerLandmarks3D"
        and instance:IsA("Folder") then
        refresh()
    end
end)
workspace.DescendantRemoving:Connect(function(instance)
    if instance.Name == "ArenaCornerLandmarks3D"
        or (instance.Name == "Arena" and instance:IsA("Model")) then
        clear()
    end
end)

-- A low-frequency check follows existing mobile scenery LOD culling.
-- Distant landmarks must not illuminate invisible objects. Streaming
-- can remove an individual model without removing the entire folder.
task.spawn(function()
    while player.Parent do
        for part, bundle in pairs(lights) do
            if not part.Parent or not bundle.light.Parent then
                bundle.tween:Cancel()
                bundle.light:Destroy()
                lights[part] = nil
            else
                bundle.light.Enabled = part.Transparency < 0.95
            end
        end
        task.wait(1)
    end
end)

refresh()
