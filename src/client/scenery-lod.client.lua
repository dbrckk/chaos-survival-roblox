local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local SceneryLodRules = require(ReplicatedStorage.Shared.SceneryLodRules)

local player = Players.LocalPlayer

local FOLDERS = {
    ChaosEnvironmentDepthLocal = {
        LowDistance = 150,
        MediumDistance = 220,
    },
    ArenaAmbientPropsLocal = {
        LowDistance = 125,
        MediumDistance = 185,
    },
    ArenaSurfaceDetailLocal = {
        LowDistance = 115,
        MediumDistance = 170,
    },
    ArenaUnderstructureLocal = {
        LowDistance = 120,
        MediumDistance = 190,
    },
    ArenaEdgeProfileLocal = {
        LowDistance = 120,
        MediumDistance = 190,
    },
    ArenaNavigationLanguageLocal = {
        LowDistance = 110,
        MediumDistance = 175,
    },
    ArenaHeroSceneryLocal = {
        LowDistance = 130,
        MediumDistance = 205,
    },
    ArenaSignatureLocal = {
        LowDistance = 145,
        MediumDistance = 220,
    },
    AerialSurveyLocal = {
        LowDistance = 145,
        MediumDistance = 215,
    },
    ArenaMidgroundMassLocal = {
        LowDistance = 145,
        MediumDistance = 215,
    },
    ArenaServicePropsLocal = {
        LowDistance = 105,
        MediumDistance = 165,
    },
    ArenaFocalLightingLocal = {
        LowDistance = 135,
        MediumDistance = 195,
    },
    ArenaPlatformIdentityLocal = {
        LowDistance = 105,
        MediumDistance = 165,
    },
    LobbySurfaceDetailLocal = {
        LowDistance = 92,
        MediumDistance = 145,
        Origin = "Lobby",
    },
    ArenaCinematicDepthLocal = {
        LowDistance = 165,
        MediumDistance = 245,
    },
    ArenaSurfaceReliefLocal = {
        LowDistance = 105,
        MediumDistance = 160,
    },
    ArenaSilhouetteBreakupLocal = {
        LowDistance = 145,
        MediumDistance = 215,
    },
    ChaosWorldPolishLocal = {
        LowDistance = 135,
        MediumDistance = 205,
    },
    ArenaCinematicDisasterAtmosphereLocal = {
        LowDistance = 155,
        MediumDistance = 230,
    },
    LobbyCoreOrbitLocal = {
        LowDistance = 105,
        MediumDistance = 155,
        Origin = "Lobby",
    },
    LobbyCrewBeaconLocal = {
        LowDistance = 105,
        MediumDistance = 160,
        Origin = "Lobby",
    },
    LobbyPresentationLocal = {
        LowDistance = 110,
        MediumDistance = 165,
        Origin = "Lobby",
    },
    LobbyProfileHologramLocal = {
        LowDistance = 100,
        MediumDistance = 150,
        Origin = "Lobby",
    },
    LobbyRoundRecapLocal = {
        LowDistance = 105,
        MediumDistance = 160,
        Origin = "Lobby",
    },
    LobbyPersonalProgressLocal = {
        LowDistance = 100,
        MediumDistance = 150,
        Origin = "Lobby",
    },
    LobbyTimeTrialLocal = {
        LowDistance = 105,
        MediumDistance = 160,
        Origin = "Lobby",
    },
    LobbyWayfindingLocal = {
        LowDistance = 120,
        MediumDistance = 175,
        Origin = "Lobby",
    },
    -- Practice cosmetics are owned by server-created pads, not workspace.
    -- Nested Folder + sibling Attachment use the same safe visibility budget.
    PracticePadPolishLocal = {
        LowDistance = 100,
        MediumDistance = 150,
        Origin = "Lobby",
    },
    ResultConstellationLocal = {
        LowDistance = 145,
        MediumDistance = 215,
    },
    ResultSurvivorSpotlightsLocal = {
        LowDistance = 135,
        MediumDistance = 205,
    },
    RookieWorldGuideLocal = {
        LowDistance = 115,
        MediumDistance = 170,
        Origin = "Lobby",
    },
}

local function cameraPosition()
    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.Position or Vector3.zero
end

local folderCaches = setmetatable({}, {__mode = "k"})

local function classifyDescendant(descendant)
    if descendant:IsA("BasePart")
        or VisualBudgetRules.isLight(descendant)
        or VisualBudgetRules.isEffect(descendant)
    then
        return descendant
    end
    return nil
end

local function ensureCache(folder)
    local cache = folderCaches[folder]
    if cache then
        return cache
    end

    cache = {
        entries = {},
        dirty = true,
    }
    folderCaches[folder] = cache

    folder.DescendantAdded:Connect(function(descendant)
        if classifyDescendant(descendant) then
            cache.dirty = true
        end
    end)
    folder.DescendantRemoving:Connect(function(descendant)
        if classifyDescendant(descendant) then
            cache.dirty = true
        end
    end)

    return cache
end

local function refreshCache(folder, cache)
    table.clear(cache.entries)
    for _, descendant in ipairs(folder:GetDescendants()) do
        if classifyDescendant(descendant) then
            table.insert(cache.entries, descendant)
        end
    end
    cache.dirty = false
end

local function applyFolder(folder, limits, profile, origin, cameraPoint)
    local cache = ensureCache(folder)
    local distance = (cameraPoint - origin).Magnitude
    local visible = SceneryLodRules.visible(
        profile.Name, distance, limits.LowDistance, limits.MediumDistance,
        cache.visible
    )
    local wasVisible = cache.visible
    local wasDirty = cache.dirty
    cache.visible = visible
    if wasDirty then
        refreshCache(folder, cache)
    end

    -- An already-visible, unchanged folder has nothing to restore. Skip
    -- walking hundreds of parts/effects on every Android LOD update.
    -- Hidden folders still run each pass to enforce concealment if another
    -- cosmetic owner changes a transparency or Enabled property.
    if visible and wasVisible == true and not wasDirty then
        return
    end

    for _, descendant in ipairs(cache.entries) do
        if not descendant.Parent then
            cache.dirty = true
            continue
        end

        local lodHidden = descendant:GetAttribute("SceneryLodHidden") == true

        if descendant:IsA("BasePart") then
            if visible then
                if lodHidden then
                    local baseTransparency = descendant:GetAttribute("SceneryLodBaseTransparency")
                    descendant.LocalTransparencyModifier = tonumber(baseTransparency) or 0
                    descendant:SetAttribute("SceneryLodHidden", false)
                end
            elseif not lodHidden then
                descendant:SetAttribute(
                    "SceneryLodBaseTransparency",
                    descendant.LocalTransparencyModifier
                )
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.LocalTransparencyModifier = 1
            elseif descendant.LocalTransparencyModifier ~= 1 then
                -- Other cosmetic owners can still change this property;
                -- re-hide only if the value actually drifted.
                descendant.LocalTransparencyModifier = 1
            end
        elseif VisualBudgetRules.isEffect(descendant)
            or VisualBudgetRules.isLight(descendant)
        then
            if visible then
                if lodHidden then
                    local baseEnabled = descendant:GetAttribute("SceneryLodBaseEnabled")
                    descendant.Enabled = baseEnabled ~= false
                    descendant:SetAttribute("SceneryLodHidden", false)
                end
            elseif not lodHidden then
                descendant:SetAttribute("SceneryLodBaseEnabled", descendant.Enabled)
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.Enabled = false
            elseif descendant.Enabled then
                descendant.Enabled = false
            end
        end
    end
end

local function currentOrigins()
    local generated = workspace:FindFirstChild("GeneratedMap")

    local arena = generated and generated:FindFirstChild("Arena")
    local arenaBase = arena and arena:FindFirstChild("Base")
    local arenaOrigin = arenaBase and arenaBase:IsA("BasePart")
        and arenaBase.Position
        or Vector3.zero

    local lobby = generated and generated:FindFirstChild("Lobby")
    local lobbyFloor = lobby and lobby:FindFirstChild("Floor")
    local lobbyOrigin = lobbyFloor and lobbyFloor:IsA("BasePart")
        and lobbyFloor.Position
        or arenaOrigin

    return arenaOrigin, lobbyOrigin
end

task.spawn(function()
    while true do
        local profile = VfxQuality.get(player:GetAttribute("VfxQualityTier"))

        local arenaOrigin, lobbyOrigin = currentOrigins()
        local cameraPoint = cameraPosition()
        for folderName, limits in pairs(FOLDERS) do
            if folderName ~= "PracticePadPolishLocal" then
                local folder = workspace:FindFirstChild(folderName)
                if folder then
                    local origin = limits.Origin == "Lobby" and lobbyOrigin or arenaOrigin
                    applyFolder(folder, limits, profile, origin, cameraPoint)
                end
            end
        end

        -- A pad's Highlight and particle emitter have separate parents.
        -- Apply LOD to just these two client-owned containers; applying it
        -- to the pad would wrongly hide the server-owned pad and light.
        for _, owner in ipairs(SceneryLodRules.practicePadVisualOwners(workspace)) do
            applyFolder(owner, FOLDERS.PracticePadPolishLocal,
                profile, lobbyOrigin, cameraPoint)
        end

        task.wait(profile.Name == "Low" and 0.65 or 0.90)
    end
end)
