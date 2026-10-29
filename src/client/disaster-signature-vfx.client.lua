-- Distance-limited, device-budgeted meteor silhouettes.
-- Rendered locally on server-owned RoundMeteor parts, never changing physics.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local DisasterVisuals = require(ReplicatedStorage.Shared.DisasterVisuals)
local MeteorRules = require(ReplicatedStorage.Shared.MeteorSignatureRules)
local MeteorCoreSculptKit = require(script.Parent.MeteorCoreSculptKit)

local player = Players.LocalPlayer
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local phase = "waiting"
local meteorsActive = false
local trails = setmetatable({}, {__mode = "k"})
-- The previous 250ms effect refresh allocated workspace:GetChildren()
-- on every meteor frame. Double Chaos may have hundreds of unrelated
-- arena parts; track only direct server-owned RoundMeteor candidates.
local meteors = {}
local candidateBuffer = {}
local dirty = true
local sync
local syncQueued = false

local function registerMeteor(instance)
    if instance:IsA("BasePart")
        and instance.Name == "RoundMeteor"
        and instance.Parent == workspace
    then
        meteors[instance] = true
        dirty = true
        -- A meteor falls for only half a second: the ordinary 250ms scan
        -- can miss most of its descent. Sculpt it on the next scheduler turn.
        if phase == "round" and meteorsActive and not syncQueued then
            syncQueued = true
            task.defer(function()
                syncQueued = false
                if sync then sync() end
            end)
        end
    end
end

local function candidates()
    return MeteorRules.collectTracked(meteors, candidateBuffer, workspace)
end
local function clear(meteor)
    -- Only destroy the exact locally created instances. Name-based cleanup
    -- could remove another system's same-named Trail after StreamingEnabled
    -- recreates a meteor, leaving unrelated VFX broken.
    local state = trails[meteor]
    if not state then return end
    MeteorCoreSculptKit.clear(state.facets)
    for _, instance in ipairs({state.trail, state.left, state.right}) do
        if instance then instance:Destroy() end
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
    MeteorCoreSculptKit.clear(state.facets)
    state.facets = MeteorCoreSculptKit.build(meteor, tier, MeteorRules)
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
    local state = {trail = trail, left = left, right = right, tier = nil, facets = {}}
    trails[meteor] = state
    updateStyle(meteor, state, tier, lifetime)
end

sync = function()
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
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
        candidates(), viewerPosition
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
    if not nextActive then
        clearAll()
    elseif not syncQueued then
        -- The background scanner sleeps up to 800ms between rounds, longer
        -- than a falling meteor's entire flight. Wake immediately when the
        -- disaster becomes active, including for late-joining spectators.
        syncQueued = true
        task.defer(function()
            syncQueued = false
            if sync then sync() end
        end)
    end
end)

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    dirty = true
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    dirty = true
    if player:GetAttribute("ReduceMotion") == true then
        clearAll()
    elseif phase == "round" and meteorsActive and not syncQueued then
        -- Restoring effects must not wait for the next periodic scan.
        syncQueued = true
        task.defer(function()
            syncQueued = false
            if sync then sync() end
        end)
    end
end)

-- Subscribe before the initial sweep to avoid missing meteors arriving
-- during client startup. Existing meteors are discovered just once.
workspace.ChildAdded:Connect(registerMeteor)
workspace.ChildRemoved:Connect(function(child)
    if meteors[child] then
        meteors[child] = nil
        dirty = true
    end
    if trails[child] then clear(child) end
end)
for _, child in ipairs(workspace:GetChildren()) do
    registerMeteor(child)
end

task.spawn(function()
    while true do
        task.wait(phase == "round" and meteorsActive and 0.25 or 0.8)
        if dirty or (phase == "round" and meteorsActive) then
            dirty = false
            sync()
        end
    end
end)
