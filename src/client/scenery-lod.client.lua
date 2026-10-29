local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local SceneryLodRules = require(ReplicatedStorage.Shared.SceneryLodRules)
local SceneryLodCache = require(script.Parent.SceneryLodCache)

local player = Players.LocalPlayer

-- Server-owned original meshes are purely decorative and have reliable
-- Roblox-native horizon fallback. Low-end Android never renders them;
-- Medium renders them near the arena, High renders them everywhere.
-- Reuse the one existing scenery LOD loop (no extra RenderStepped).
local ORIGINAL_MESH_LOD = {
    LowDistance = 0,
    MediumDistance = 140,
}

-- The new off-map hero architectures are static Roblox-native 3D. On
-- low-tier Android hide these optional skyline parts; medium shows them
-- near the arena and high keeps the authored silhouette fully visible.
-- Uses the EXISTING LOD loop, not another per-frame task.
local HERO_ARCHITECTURE_LOD = {
    LowDistance = 0,
    MediumDistance = 185,
    KeepHeroLow = true,
}

-- Per-model native 3D district LOD: cull FAR towers individually,
-- never hide the whole arena's buildings because the camera left its
-- center. One existing 0.65/0.90s scenery loop; no new per-frame loops.
-- Low Android renders nearest authored 3D silhouettes, Medium more.
local DISTRICT_ARCHITECTURE_LOD = {
    LowDistance = 150,
    MediumDistance = 245,
}

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
    ArenaArchitecturalDetailsLocal = {
        LowDistance = 145,
        MediumDistance = 220,
    },
    -- Native client-only signal-ring structures appear only on Medium/
    -- High and stay hidden after the sector streams far away.
    DistrictSignalArchitectureLocal = {
        LowDistance = 0,
        MediumDistance = 220,
    },
    ArenaSignatureLocal = {
        LowDistance = 145,
        MediumDistance = 220,
    },
    -- AerialSurveyLocal intentionally omitted: AerialSurveyKit owns its
    -- own part masking, Light/Trail gating and camera-distance hysteresis.
    -- A second LOD writer could reveal distant drones at the cutoff.
    ArenaMidgroundMassLocal = {
        LowDistance = 145,
        MediumDistance = 215,
    },
    -- Near-playable exterior models sit inside the 320-stud floor.
    -- Low renders only four five-Part silhouettes and needs to see them
    -- while approaching the outskirts; Medium shows detailed scenes.
    -- Apply through the existing ONE scenery scheduler.
    DistrictSectorSetpiecesLocal = {
        LowDistance = 245,
        MediumDistance = 255,
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

local function classifyDescendant(descendant)
    return descendant:IsA("BasePart")
        or VisualBudgetRules.isLight(descendant)
        or VisualBudgetRules.isEffect(descendant)
end

-- The weak-key cache retains no destroyed map root. The small helper
-- only owns hierarchy invalidation/refresh, never a second LOD loop.
local folderCaches = setmetatable({}, {__mode = "k"})

local function ensureCache(folder)
    local cached = folderCaches[folder]
    if cached then return cached end
    local cache = {entries = {}, dirty = true}
    folderCaches[folder] = cache
    SceneryLodCache.watch(folder, cache)
    return cache
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
        SceneryLodCache.refresh(folder, cache, classifyDescendant)
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
        local partVisible = SceneryLodRules.entryVisible(
            profile.Name, visible, limits.KeepHeroLow,
            descendant:GetAttribute("HeroSilhouetteEssential")
        )

        if descendant:IsA("BasePart") then
            if partVisible then
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
            if partVisible then
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
        local profile = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)

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

        -- Original imported 3D is replicated by the server inside
        -- GeneratedMap/Arena/Decor, not a workspace-root *Local folder.
        -- Hide it without touching native platforms, collision or hazards.
        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local decor = arena and arena:FindFirstChild("Decor")
        local original = decor and decor:FindFirstChild("Original3DScenery")
        if original then
            applyFolder(original, ORIGINAL_MESH_LOD,
                profile, arenaOrigin, cameraPoint)
        end
        local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
        if district and district:IsA("Folder") then
            for _, structure in ipairs(district:GetChildren()) do
                if structure:IsA("Model")
                    and structure:GetAttribute("CosmeticOnly") == true
                    and structure:GetAttribute("SourceIsOriginal") == true then
                    -- A geometric pivot is stable for an anchored model.
                    -- Individual culling preserves nearby landmarks even
                    -- when the camera moves into a far corner of the map.
                    applyFolder(structure, DISTRICT_ARCHITECTURE_LOD,
                        profile, structure:GetPivot().Position, cameraPoint)
                end
            end
        end
        -- Four original corner skyline models are separate from the
        -- exactly sixteen district buildings. Cull each by its own pivot,
        -- using this existing loop instead of a second mobile update task.
        local cornerLandmarks = decor and decor:FindFirstChild("ArenaCornerLandmarks3D")
        if cornerLandmarks and cornerLandmarks:IsA("Folder") then
            for _, landmark in ipairs(cornerLandmarks:GetChildren()) do
                if landmark:IsA("Model")
                    and landmark:GetAttribute("CosmeticOnly") == true
                    and landmark:GetAttribute("SourceIsOriginal") == true then
                    applyFolder(landmark, DISTRICT_ARCHITECTURE_LOD,
                        profile, landmark:GetPivot().Position, cameraPoint)
                end
            end
        end
        local hero = SceneryLodRules.heroArchitectureOwner(workspace)
        if hero then
            applyFolder(hero, HERO_ARCHITECTURE_LOD,
                profile, arenaOrigin, cameraPoint)
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
