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

-- A screenshot from Android showed a survivor's shoulder obscuring most
-- of the view while the owner's avatar remained behind it. Only soften
-- ONE nearby interfering humanoid locally; other survivors must remain
-- readable and never become invisible or lose collisions.
local fadedAvatar = nil
local originalAvatarModifiers = {}
local avatarFade = CameraOcclusionRules.localModifier()

local function restoreAvatar()
    for part, original in pairs(originalAvatarModifiers) do
        if part and part.Parent
            and math.abs(part.LocalTransparencyModifier - avatarFade) < 0.001 then
            -- Do not override another controller (native camera, LOD, etc.)
            -- if it modified the value after this feature touched it.
            part.LocalTransparencyModifier = original
        end
        originalAvatarModifiers[part] = nil
    end
    fadedAvatar = nil
end

local function applyAvatarFade(model)
    if fadedAvatar == model then
        return
    end
    restoreAvatar()
    if not model or not model.Parent then
        return
    end
    fadedAvatar = model
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart")
            and part.LocalTransparencyModifier < 0.55 then
            originalAvatarModifiers[part] = part.LocalTransparencyModifier
            part.LocalTransparencyModifier = avatarFade
        end
    end
end

local function refreshAvatarOccluder(camera, localRoot, localCharacter)
    local focus = localRoot.Position + Vector3.new(0, 1.25, 0)
    local cameraPosition = camera.CFrame.Position
    local closest, bestScore = nil, math.huge
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
        if score then
            -- Small hysteresis avoids alternating transparency between
            -- two teammates moving across the same sightline.
            if model == fadedAvatar then
                score -= 0.4
            end
            if score < bestScore then
                bestScore = score
                closest = model
            end
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
    applyAvatarFade(closest)
end

local function restore()
    restoreAvatar()
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

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character, base}
    params.IgnoreWater = true
    local hit = workspace:Raycast(start, toAvatar, params)
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
