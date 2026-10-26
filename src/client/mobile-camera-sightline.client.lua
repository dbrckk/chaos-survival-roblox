-- Keep the local avatar readable on Android when a nearby arena
-- support or another survivor blocks the third-person camera. Cosmetic
-- local fading only; no physics, replication or server gameplay changes.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CameraOcclusionRules = require(ReplicatedStorage.Shared.CameraOcclusionRules)

local player = Players.LocalPlayer
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local activePhase = "waiting"
local faded = nil
local previousModifier = 0
local fadeValue = 0.72
local lastCamera = nil

-- The Android screenshots showed players overlapping directly in front
-- of the lens. Soften at most TWO actual sightline blockers, rather than
-- arbitrarily picking only one (which leaves the next one covering the
-- whole screen). A locally faded player remains recognisable and collidable.
local fadedAvatars = {} -- Model -> { BasePart -> original modifier }
local avatarConnections = {} -- Model -> RBXScriptConnection
local avatarFade = CameraOcclusionRules.localModifier()

local function restoreAvatar(model)
    local connection = avatarConnections[model]
    if connection then
        connection:Disconnect()
        avatarConnections[model] = nil
    end
    local originalParts = fadedAvatars[model]
    if not originalParts then return end
    for part, original in pairs(originalParts) do
        if part and part.Parent
            and math.abs(part.LocalTransparencyModifier - avatarFade) < 0.001 then
            -- Yield to native Roblox camera fade or other local cosmetics
            -- if they changed the value while we owned it.
            part.LocalTransparencyModifier = original
        end
    end
    fadedAvatars[model] = nil
end

local function restoreAvatars()
    for model in pairs(fadedAvatars) do
        restoreAvatar(model)
    end
end

local function fadeDescendant(originals, instance)
    if not instance:IsA("BasePart") or originals[instance] ~= nil
        or instance.LocalTransparencyModifier >= 0.55 then
        return
    end
    originals[instance] = instance.LocalTransparencyModifier
    instance.LocalTransparencyModifier = avatarFade
end

local function applyAvatarFades(selected)
    local wanted = {}
    for _, model in ipairs(selected) do
        wanted[model] = true
    end
    for model in pairs(fadedAvatars) do
        if not wanted[model] or not model.Parent then
            restoreAvatar(model)
        end
    end
    for _, model in ipairs(selected) do
        if model.Parent and not fadedAvatars[model] then
            local originals = {}
            fadedAvatars[model] = originals
            -- One initial scan per selected avatar, NOT a full
            -- GetDescendants traversal every 180 ms on Android.
            for _, part in ipairs(model:GetDescendants()) do
                fadeDescendant(originals, part)
            end
            -- Accessories and streamed body parts are faded as they
            -- arrive. Disconnect when the avatar stops blocking the lens
            -- or is removed, avoiding a permanent per-avatar subscription.
            avatarConnections[model] = model.DescendantAdded:Connect(function(descendant)
                if fadedAvatars[model] ~= originals then return end
                fadeDescendant(originals, descendant)
                -- Some streamed accessories arrive already populated.
                -- Scan only that NEW accessory (once), never the entire
                -- avatar on every camera tick.
                if descendant:IsA("Accessory") or descendant:IsA("Model") then
                    for _, piece in ipairs(descendant:GetDescendants()) do
                        fadeDescendant(originals, piece)
                    end
                end
            end)
        end
    end
end

local function refreshAvatarOccluder(camera, localRoot, localCharacter)
    local focus = localRoot.Position + Vector3.new(0, 1.25, 0)
    local cameraPosition = camera.CFrame.Position
    local candidates = {}
    local function consider(model)
        if not model or not model.Parent or model == localCharacter then
            return
        end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        local root = model:FindFirstChild("HumanoidRootPart")
        if not humanoid or humanoid.Health <= 0
            or not root or not root:IsA("BasePart") then
            return
        end
        local score = CameraOcclusionRules.avatarOcclusion(
            cameraPosition, focus, root.Position + Vector3.new(0, 1.0, 0)
        )
        local head = model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            local headScore = CameraOcclusionRules.avatarOcclusion(
                cameraPosition, focus, head.Position
            )
            -- Raised avatars on ramps can obscure the camera with their
            -- upper body even when their HumanoidRootPart is out of line.
            if headScore and (not score or headScore < score) then
                score = headScore
            end
        end
        if score then
            -- Prefer incumbents slightly to prevent alternating between
            -- similarly close teammates in a dense round.
            if fadedAvatars[model] then
                score -= 0.4
            end
            candidates[#candidates + 1] = { model = model, score = score }
        end
    end

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            consider(other.Character)
        end
    end
    local bots = workspace:FindFirstChild("AISurvivors")
    if bots then
        local inspected = 0
        for _, model in ipairs(bots:GetChildren()) do
            if model:IsA("Model") then
                consider(model)
                inspected += 1
                if inspected >= 32 then break end
            end
        end
    end
    applyAvatarFades(CameraOcclusionRules.chooseOccluders(candidates, 2))
end

local function restore()
    restoreAvatars()
    if faded and faded.Parent then
        -- Yield to native Roblox camera/streaming writers if they adjusted
        -- this modifier while our temporary fade was in effect.
        if math.abs(faded.LocalTransparencyModifier - fadeValue) < 0.001 then
            faded.LocalTransparencyModifier = previousModifier
        end
    end
    faded = nil
    previousModifier = 0
    lastCamera = nil
end

local function supportedTarget(part, arena, base)
    local platforms = arena:FindFirstChild("Platforms")
    local mechanics = arena:FindFirstChild("Mechanics")
    local spawns = arena:FindFirstChild("Spawns")
    local decor = arena:FindFirstChild("Decor")
    local helixCircuit = arena:FindFirstChild("HelixCircuit")
    -- Never fade disappearing floors, mobility pads or ordinary platforms:
    -- players need to see their actual traversable routes. A designated
    -- skybridge may soften slightly when it occludes the local avatar.
    if platforms and part:IsDescendantOf(platforms)
        and part:GetAttribute("ChaosSkybridge") ~= true then
        return false
    end
    return part ~= base
        and part:IsA("BasePart")
        and part:IsDescendantOf(arena)
        and part.Anchored
        and part.CanCollide
        and part.Transparency < 0.35
        and part.Material ~= Enum.Material.Neon
        -- Decorations, warning areas, lifts, and mobile wayfinding are
        -- never faded: they carry essential gameplay information.
        and (not mechanics or not part:IsDescendantOf(mechanics))
        and (not spawns or not part:IsDescendantOf(spawns))
        and (not decor or not part:IsDescendantOf(decor))
        -- Helix, entry and core ramps carry real Orbital collision routes.
        -- Keep them readable even if a future camera filter is broadened.
        and (not helixCircuit or not part:IsDescendantOf(helixCircuit))
end

local function update()
    if not UserInputService.TouchEnabled
        or (activePhase ~= "ready" and activePhase ~= "round")
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true then
        restore()
        return
    end

    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    if camera ~= lastCamera then
        restore()
        lastCamera = camera
    end
    if not camera or camera.CameraType == Enum.CameraType.Scriptable
        or not root or not root:IsA("BasePart")
        or not arena or not base or not base:IsA("BasePart") then
        restore()
        return
    end

    local start = camera.CFrame.Position
    local toAvatar = root.Position + Vector3.new(0, 1.25, 0) - start
    local distance = toAvatar.Magnitude
    -- First-person views and spectator/zoomed-out cameras must not alter
    -- the appearance of the surrounding arena.
    if distance < 4 or distance > 32 then
        restore()
        return
    end

    -- Include only the replicated arena for structural occlusion. A
    -- different survivor, bot, local particle shell or hazard marker may
    -- stand closer to the lens than an opaque column; none should prevent
    -- the column from being tested. Avatars are handled independently.
    local params = CameraOcclusionRules.arenaRaycastParams(arena, base)
    local hit = params and workspace:Raycast(start, toAvatar, params)
    local nextPart = nil
    if hit and supportedTarget(hit.Instance, arena, base) then
        nextPart = hit.Instance
    end

    if nextPart ~= faded then
        -- Only restore the structural blocker here: remote avatar fade is
        -- independently owned and must not flicker when terrain ray hits
        -- change during movement.
        if faded and faded.Parent
            and math.abs(faded.LocalTransparencyModifier - fadeValue) < 0.001 then
            faded.LocalTransparencyModifier = previousModifier
        end
        faded = nil
        previousModifier = 0
        if nextPart and nextPart.Parent then
            faded = nextPart
            previousModifier = faded.LocalTransparencyModifier
            -- Don't overwrite parts intentionally hidden by another
            -- client-side visibility owner.
            if previousModifier < 0.55 then
                faded.LocalTransparencyModifier = fadeValue
            else
                faded = nil
            end
        end
    end

    refreshAvatarOccluder(camera, root, character)
end

roundState.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    activePhase = tostring(state.phase or "waiting")
    if activePhase ~= "round" and activePhase ~= "ready" then
        restore()
    end
end)

player.CharacterRemoving:Connect(restore)

task.spawn(function()
    while true do
        task.wait((activePhase == "round" or activePhase == "ready") and 0.18 or 0.55)
        update()
    end
end)
