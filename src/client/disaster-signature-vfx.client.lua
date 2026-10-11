-- Distance-limited, device-budgeted meteor silhouettes.
-- Rendered locally on server-owned RoundMeteor parts, never changing physics.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local MeteorRules = require(ReplicatedStorage.Shared.MeteorSignatureRules)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local phase = "waiting"
local meteorsActive = false
local trails = setmetatable({}, {__mode = "k"})
local dirty = true
local signalConnection = nil

local function clear(meteor)
    local trail = meteor:FindFirstChild("SignatureMeteorTrail")
    if trail then trail:Destroy() end
    for _, name in ipairs({"SignatureMeteorTrailLeft", "SignatureMeteorTrailRight"}) do
        local attachment = meteor:FindFirstChild(name)
        if attachment then attachment:Destroy() end
    end
    trails[meteor] = nil
end

local function clearAll()
    for meteor in pairs(trails) do
        clear(meteor)
    end
end

local function add(meteor, lifetime)
    if trails[meteor] or not meteor.Parent then return end
    local profile = DisasterVisuals.get("Meteors")
    local accent = profile and profile.Accent or Color3.fromRGB(255, 135, 50)
    local tint = profile and profile.Tint or Color3.fromRGB(255, 215, 120)
    -- Existing attachment names from older streaming instances are never
    -- reused blindly; locally owned effects always have matching endpoints.
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
    trail.Lifetime = lifetime
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
    trails[meteor] = true
end

local function sync()
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    local profile = MeteorRules.profile(tier.Name,
        player:GetAttribute("ReduceMotion") == true)
    if phase ~= "round" or not meteorsActive or profile.MaxTrails == 0 then
        clearAll()
        return
    end

    local camera = workspace.CurrentCamera
    local character = player.Character
    local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
    local viewerPosition = camera and camera.CFrame.Position
        or (playerRoot and playerRoot.Position)
    if not viewerPosition then
        clearAll()
        return
    end

    local ordered = MeteorRules.orderedCandidates(
        workspace:GetChildren(), viewerPosition
    )
    local eligible = {}
    local allocated = 0
    for _, item in ipairs(ordered) do
        if MeteorRules.shouldTrail(
            phase, meteorsActive, viewerPosition, item.Part.Position,
            tier.Name, false, allocated
        ) then
            allocated += 1
            eligible[item.Part] = true
            add(item.Part, profile.Lifetime)
        else
            -- Ordered candidates are sorted by distance. Once a candidate is
            -- outside range or the cap is reached, none further qualifies.
            break
        end
    end
    for meteor in pairs(trails) do
        if not eligible[meteor] or not meteor.Parent then
            clear(meteor)
        end
    end
end

stateEvent.OnClientEvent:Connect(function(state)
    local nextPhase = tostring(state and state.phase or "waiting")
    local nextActive = false
    if nextPhase == "round" then
        for _, id in ipairs(state.disasterIds or {}) do
            if id == "Meteors" then nextActive = true; break end
        end
    end
    phase = nextPhase
    meteorsActive = nextActive
    dirty = true
    if not nextActive then clearAll() end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    dirty = true
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    dirty = true
    if player:GetAttribute("ReduceMotion") == true then clearAll() end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "RoundMeteor" then dirty = true end
end)
workspace.ChildRemoved:Connect(function(child)
    if trails[child] then clear(child) end
end)

task.spawn(function()
    while true do
        task.wait(phase == "round" and meteorsActive and 0.25 or 0.8)
        if dirty or (phase == "round" and meteorsActive) then
            dirty = false
            sync()
        end
    end
end)
