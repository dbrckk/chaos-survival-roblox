-- Keep the local avatar readable when the third-person Android camera
-- slips behind a nearby solid arena support. This is cosmetic and local:
-- no physics, replication, survivor visibility, or server gameplay changes.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local roundState = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local activePhase = "waiting"
local faded = nil
local previousModifier = 0

local function restore()
    if faded and faded.Parent then
        faded.LocalTransparencyModifier = previousModifier
    end
    faded = nil
    previousModifier = 0
end

local function supportedTarget(part, arena, base)
    return part ~= base
        and part:IsA("BasePart")
        and part:IsDescendantOf(arena)
        and part.Anchored
        and part.CanCollide
        and part.Transparency < 0.35
        and part.Material ~= Enum.Material.Neon
        -- Decorations, warning areas, lifts, and mobile wayfinding are
        -- never faded: they carry essential gameplay information.
        and (not arena:FindFirstChild("Mechanics") or not part:IsDescendantOf(arena.Mechanics))
        and (not arena:FindFirstChild("Spawns") or not part:IsDescendantOf(arena.Spawns))
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
    if not camera or not root or not root:IsA("BasePart")
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
        restore()
        if nextPart and nextPart.Parent then
            faded = nextPart
            previousModifier = faded.LocalTransparencyModifier
            -- Don't overwrite parts intentionally hidden by another
            -- client-side visibility owner.
            if previousModifier < 0.55 then
                faded.LocalTransparencyModifier = 0.72
            else
                faded = nil
            end
        end
    end
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
