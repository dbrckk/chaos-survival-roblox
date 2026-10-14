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

local function updateStyle(meteor, state, tier, lifetime)
    if state.tier == tier then return end
    local style = MeteorRules.trailStyle(tier, false)
    if not style then return end
    local span = meteor.Size.X * style.Span
    state.left.Position = Vector3.new(-span, 0, meteor.Size.Z * 0.20)
    state.right.Position = Vector3.new(span, 0, meteor.Size.Z * 0.20)
    state.trail.WidthScale = style.WidthScale
    state.trail.Transparency = style.Transparency
    state.trail.LightEmission = style.LightEmission
    state.trail.Lifetime = lifetime
    state.tier = tier
end

local function add(meteor, tier, lifetime)
    if not meteor.Parent then return end
    local existing = trails[meteor]
    if existing then
        -- Quality can change during a half-second fall: update the single
        -- existing Trail in place rather than leaving the old tier's style.
        updateStyle(meteor, existing, tier, lifetime)
        return
    end

    local profile = DisasterVisuals.get("Meteors")
    local accent = profile and profile.Accent or Color3.fromRGB(255, 135, 50)
    local tint = profile and profile.Tint or Color3.fromRGB(255, 215, 120)
    local left = Instance.new("Attachment")
    left.Name = "SignatureMeteorTrailLeft"
    left.Parent = meteor
    local right = Instance.new("Attachment")
    right.Name = "SignatureMeteorTrailRight"
    right.Parent = meteor

    local trail = Instance.new("Trail")
    trail.Name = "SignatureMeteorTrail"
    trail.Attachment0 = left
    trail.Attachment1 = right
    trail.FaceCamera = true
    trail.LightInfluence = 0
    trail.MinLength = 0.08
    -- Four authored thermal stops read as a white-hot core, ember mantle
    -- and cooled smoke edge without adding emitters or light sources.
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tint:Lerp(Color3.new(1, 1, 1), 0.46)),
        ColorSequenceKeypoint.new(0.24, tint),
        ColorSequenceKeypoint.new(0.66, accent),
        ColorSequenceKeypoint.new(1, accent:Lerp(Color3.fromRGB(66, 37, 42), 0.72)),
    })
    trail.Parent = meteor
    local state = {trail = trail, left = left, right = right, tier = nil}
    trails[meteor] = state
    updateStyle(meteor, state, tier, lifetime)
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
            add(item.Part, tier.Name, profile.Lifetime)
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
    local nextPhase, nextActive = MeteorRules.readRoundState(state)
    if not nextPhase then return end
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
