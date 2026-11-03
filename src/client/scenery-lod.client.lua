local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local SceneryLodRules = require(ReplicatedStorage.Shared.SceneryLodRules)
local SceneryLodCache = require(script.Parent.SceneryLodCache)
local DistrictFacadeDetailKit = require(script.Parent.DistrictFacadeDetailKit)
local DistrictGatewayMeshKit = require(script.Parent.DistrictGatewayMeshKit)
local PremiumDistrictFacadeMeshKit = require(script.Parent.PremiumDistrictFacadeMeshKit)
local PremiumRouteMeshKit = require(script.Parent.PremiumRouteMeshKit)
local SkySpineCrownMeshKit = require(script.Parent.SkySpineCrownMeshKit)
local ArenaKeelMeshKit = require(script.Parent.ArenaKeelMeshKit)
local UnderstructureBeamMeshKit = require(script.Parent.UnderstructureBeamMeshKit)
local PremiumGroundMeshKit = require(script.Parent.PremiumGroundMeshKit)

local player = Players.LocalPlayer
local isTouch = UserInputService.TouchEnabled

-- Six APPROVED creator-owned real 3D mesh packages supply the distant
-- skyline. Previously Low never showed any MeshPart and Medium's 140-stud
-- distance hid them from most of a 320-stud arena, leaving players with
-- only native fallback boxes. Use a strict camera-ranked residency budget:
-- 1 nearest original on Low, 3 on Medium, all on High. No new assets, loops,
-- remote fetches or PBR quota: this only controls already replicated meshes.
local ORIGINAL_MESH_LOD = {
    LowDistance = 150,
    MediumDistance = 245,
}
local ORIGINAL_MESH_HIDDEN = {
    LowDistance = 0,
    MediumDistance = 0,
}
local ORIGINAL_MESH_LIMIT = {Low = 1, Medium = 3, High = 8}

-- The existing exterior fleet includes 4 gantries and one full cargo
-- vessel. Low Android keeps ONLY the 14 structural cargo silhouette
-- Parts explicitly authored on the real ship, not 30-Part cranes, tiny
-- railings, corrugations, effects or gameplay hazard cover. Medium shows
-- the nearby complete vessel and cranes; High retains full original art.
-- Keep using this one 0.65/0.90-second scenery-LOD update owner.
local HARBOR_GANTRY_LOD = {
    LowDistance = 0,
    MediumDistance = 185,
    KeepHeroLow = true,
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

-- The FOUR client-authored sector monuments are distributed across the
-- actual 320-stud playable map. Applying one arena-center LOD decision to
-- their parent Folder needlessly keeps distant sectors rendered (or hides
-- a nearby one at an extreme corner). Cull each true model pivot instead.
local LOCAL_SECTOR_SETPIECE_LOD = {
    LowDistance = 245,
    MediumDistance = 255,
}

-- The original cinematic sky fleet is made of 2/3/4 enormous floating
-- ships rather than small filler particles. Cull EACH aircraft by its
-- actual world pivot; an arena-center decision would keep distant
-- corner traffic rendering throughout an Android session.
local SKY_FLEET_LOD = {
    LowDistance = 255,
    MediumDistance = 350,
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
        -- The authored hero is OUTBOARD of the 320-stud arena, not at
        -- the arena center. Use its real local build origin on Android.
        Origin = "CosmeticArt",
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
    -- DistrictSectorSetpiecesLocal is deliberately handled below PER
    -- MODEL rather than hiding all four sectors from the arena center.
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
    if not camera then return Vector3.zero, false, Vector3.zero end
    local viewport = camera.ViewportSize
    -- Streaming can complete before Android creates a usable viewport.
    -- Keep existing LOD computation, but defer new optional Parts until
    -- a real camera is available to show them.
    return camera.CFrame.Position, viewport.X > 0 and viewport.Y > 0,
        camera.CFrame.LookVector
end

local function classifyDescendant(descendant)
    return descendant:IsA("BasePart")
        or VisualBudgetRules.isLight(descendant)
        or VisualBudgetRules.isEffect(descendant)
        -- World-space sector signs must disappear with their facade.
        -- Otherwise SurfaceGuis could remain after mobile LOD culls 3D.
        or descendant:IsA("SurfaceGui")
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
    local previousTier = cache.lastProfile
    cache.lastProfile = profile.Name
    cache.visible = visible
    if wasDirty then
        SceneryLodCache.refresh(folder, cache, classifyDescendant)
    end

    -- An already-visible, unchanged folder has nothing to restore. Skip
    -- walking hundreds of parts/effects on every Android LOD update.
    -- Hidden folders still run each pass to enforce concealment if another
    -- cosmetic owner changes a transparency or Enabled property.
    if visible and wasVisible == true and not wasDirty
        and previousTier == profile.Name then
        return visible
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
        -- Optional detail tiers are visibility masks, never destructive
        -- server asset edits. Quality switches must reveal/hide them even
        -- if the building's distance visibility itself has not changed.
        local minimumTier = descendant:GetAttribute("SceneryMinimumTier")
        if minimumTier == "Medium" and profile.Name == "Low"
            or minimumTier == "High" and profile.Name ~= "High" then
            partVisible = false
        end

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
            or descendant:IsA("SurfaceGui")
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
    return visible
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
        local profile = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), isTouch)

        local arenaOrigin, lobbyOrigin = currentOrigins()
        local cameraPoint, cameraReady, cameraLook = cameraPosition()
        for folderName, limits in pairs(FOLDERS) do
            if folderName ~= "PracticePadPolishLocal" then
                local folder = workspace:FindFirstChild(folderName)
                if folder then
                    local origin = limits.Origin == "Lobby" and lobbyOrigin or arenaOrigin
                    if limits.Origin == "CosmeticArt" then
                        -- The local builder publishes one position for the
                        -- currently loaded arena. Before its Base streams
                        -- in (or after a map swap), fall back safely.
                        local authored = folder:GetAttribute("CosmeticWorldOrigin")
                        if typeof(authored) == "Vector3" then
                            origin = authored
                        end
                    end
                    applyFolder(folder, limits, profile, origin, cameraPoint)
                end
            end
        end

        -- Each playable-sector original 3D monument is its own client
        -- Model at a different location. Keep the exact old Low/Medium
        -- thresholds but use the real model pivot for each, like the
        -- existing server district/corner building culling below.
        -- Native prompts, camera controls and hazards are not modified.
        local sectorFolder = workspace:FindFirstChild("DistrictSectorSetpiecesLocal")
        if sectorFolder and sectorFolder:IsA("Folder") then
            for _, model in ipairs(sectorFolder:GetChildren()) do
                local sector = model:GetAttribute("DistrictSector")
                if model:IsA("Model")
                    and model:GetAttribute("LocalOriginal3D") == true
                    and model:GetAttribute("CosmeticOnly") == true
                    and type(sector) == "number"
                    and sector >= 1 and sector <= 4
                    and sector == math.floor(sector) then
                    applyFolder(model, LOCAL_SECTOR_SETPIECE_LOD,
                        profile, model:GetPivot().Position, cameraPoint)
                end
            end
        end

        -- Reuse this owner for individually authored sky ships. Cosmetic
        -- animation reads the LOD mask and skips hidden craft; no second
        -- distance poller, no modification to networked map geometry.
        local skyFleet = workspace:FindFirstChild("ArenaSkyFleetLocal")
        if skyFleet and skyFleet:IsA("Folder") then
            local fleet = skyFleet:FindFirstChildWhichIsA("Folder")
            if fleet then
                for _, craft in ipairs(fleet:GetChildren()) do
                    if craft:IsA("Model")
                        and craft:GetAttribute("CosmeticOnly") == true
                        and craft:GetAttribute("LocalOriginal3D") == true then
                        applyFolder(craft, SKY_FLEET_LOD, profile,
                            craft:GetPivot().Position, cameraPoint)
                    end
                end
            end
        end

        -- Original imported 3D is replicated by the server inside
        -- GeneratedMap/Arena/Decor, not a workspace-root *Local folder.
        -- Hide it without touching native platforms, collision or hazards.
        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local decor = arena and arena:FindFirstChild("Decor")
        -- Premium real imported 3D on PHYSICAL jump decks and bridges:
        -- the SAME existing camera-tier loop owns all local MeshPart
        -- creation/cleanup. Original colliders and hazard cues stay live;
        -- animated collapse, shrink and stream changes hide cosmetics.
        PremiumRouteMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook)
        -- Five-arena original 2,976-triangle industrial floor: share the
        -- existing 0.65/0.90s camera cadence instead of another loop.
        -- Low = 2, Medium = 8, High = 24 original approved local tiles;
        -- base/shrink changes hide art immediately via instance events.
        PremiumGroundMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook)
        local floorMeshes = PremiumGroundMeshKit.count()
        if player:GetAttribute("LocalOriginalGroundMeshCount") ~= floorMeshes then
            player:SetAttribute("LocalOriginalGroundMeshCount", floorMeshes)
        end
        -- Client-only diagnostics count genuine imported MODEL instances,
        -- not fabricated FPS or proof that Roblox textures finished drawing.
        local routeMeshes = PremiumRouteMeshKit.count()
        if player:GetAttribute("LocalOriginalRouteMeshCount") ~= routeMeshes then
            player:SetAttribute("LocalOriginalRouteMeshCount", routeMeshes)
        end
        -- An actual approved, sculpted high interchange on the TWO
        -- real Sky Spine center decks, never on a painted phantom bridge.
        -- Same camera sampler, strict Android Low 1 / Medium 1 / High 2.
        SkySpineCrownMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook)
        local crownMeshes = SkySpineCrownMeshKit.count()
        if player:GetAttribute("LocalOriginalSkySpineCrownCount")
            ~= crownMeshes then
            player:SetAttribute("LocalOriginalSkySpineCrownCount",
                crownMeshes)
        end
        -- One more genuinely imported, source-gated 3D silhouette under
        -- the arena, 1/3/5 MODEL copies on Low/Medium/High. No new loop.
        -- Dismount immediately on shrink to prevent phantom 3D decking.
        ArenaKeelMeshKit.sync(arena, cameraPoint, profile.Name, cameraReady)
        local keelMeshes = ArenaKeelMeshKit.count()
        if player:GetAttribute("LocalOriginalArenaKeelCount") ~= keelMeshes then
            player:SetAttribute("LocalOriginalArenaKeelCount", keelMeshes)
        end
        -- Real original 3,072-triangle approved 3D chassis replace ONLY
        -- near-camera marked cosmetic underfloor beam bays. Low 1 / Medium
        -- 4 / High 12; every bay has a self-restoring native fallback.
        -- Reuse the SAME established camera sampler and part census.
        UnderstructureBeamMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady)
        local beamMeshes = UnderstructureBeamMeshKit.count()
        if player:GetAttribute("LocalOriginalUnderstructureBeamCount")
            ~= beamMeshes then
            player:SetAttribute("LocalOriginalUnderstructureBeamCount", beamMeshes)
        end
        -- Count real, approved underdeck MODEL instances separately: the
        -- same adaptive scenery owner already counts their MeshParts
        -- in the existing PremiumRouteMeshLocal budget census.
        local underdecks = PremiumRouteMeshKit.underdeckCount()
        if player:GetAttribute("LocalOriginalUnderdeckMeshCount") ~= underdecks then
            player:SetAttribute("LocalOriginalUnderdeckMeshCount", underdecks)
        end

        -- Rank at most eight approved, creator-owned imported Models by
        -- actual camera proximity. This makes REAL meshes visible on Android
        -- rather than native fallback only, while permitting at most one
        -- imported model on Low and three on Medium at any one time.
        local imported = SceneryLodRules.original3DVisualOwners(arena)
        table.sort(imported, function(a, b)
            local da = (a:GetPivot().Position - cameraPoint).Magnitude
            local db = (b:GetPivot().Position - cameraPoint).Magnitude
            if da ~= db then return da < db end
            return a.Name < b.Name
        end)
        local maxVisible = ORIGINAL_MESH_LIMIT[profile.Name] or 1
        for index, model in ipairs(imported) do
            applyFolder(model,
                index <= maxVisible and ORIGINAL_MESH_LOD
                    or ORIGINAL_MESH_HIDDEN,
                profile, model:GetPivot().Position, cameraPoint)
        end
        -- Use each exterior model pivot, including the full cargo vessel,
        -- for Medium proximity. On Low only server-marked essential ship
        -- Parts survive; four separate cranes retain zero visible Parts.
        -- Native collision and hazards are never touched.
        for _, scenery in ipairs(SceneryLodRules.harborGantryOwners(arena)) do
            applyFolder(scenery, HARBOR_GANTRY_LOD,
                profile, scenery:GetPivot().Position, cameraPoint)
        end
        local district = decor and decor:FindFirstChild("ArenaDistrictArchitecture3D")
        -- The 16 original native facades now gain a bounded set of TRUE,
        -- creator-approved imported 3D industrial portal MeshParts at close
        -- range. A single existing LOD owner selects at most 1/2/4.
        -- All original server-authored doors remain visible if unavailable.
        DistrictGatewayMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook)
        local gatewayCount = DistrictGatewayMeshKit.count()
        if player:GetAttribute("LocalOriginalGatewayMeshCount") ~= gatewayCount then
            player:SetAttribute("LocalOriginalGatewayMeshCount", gatewayCount)
        end
        local localFacadeParts = 0
        if district and district:IsA("Folder") then
            for _, structure in ipairs(district:GetChildren()) do
                if structure:IsA("Model")
                    and structure:GetAttribute("CosmeticOnly") == true
                    and structure:GetAttribute("SourceIsOriginal") == true then
                    -- Both LOD and facade kit use the same real model
                    -- location and the exact same scheduled camera snapshot.
                    -- Core 3D silhouette remains server-owned; four/six
                    -- optional local details are created only near-camera.
                    -- Client-generated facade hardware can extend
                    -- model bounds. Use the stable SERVER foundation instead
                    -- of a dynamic bounding-box pivot for LOD hysteresis.
                    local anchor = structure:FindFirstChild("BasaltFoundation")
                    local origin = anchor and anchor:IsA("BasePart")
                        and anchor.Position or structure:GetPivot().Position
                    local visible = applyFolder(
                        structure, DISTRICT_ARCHITECTURE_LOD,
                        profile, origin, cameraPoint)
                    localFacadeParts += DistrictFacadeDetailKit.sync(
                        structure, profile.Name, visible,
                        (cameraPoint - origin).Magnitude, isTouch, cameraReady)
                end
            end
        end
        -- Run AFTER the authoritative native district LOD, so source
        -- doors already have their actual visible/hidden state. Never
        -- show imported facades on an offscreen, culled or shrunk building.
        PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, cameraLook)
        local facadeMeshCount = PremiumDistrictFacadeMeshKit.count()
        if player:GetAttribute("LocalOriginalDistrictFacadeMeshCount")
            ~= facadeMeshCount then
            player:SetAttribute("LocalOriginalDistrictFacadeMeshCount",
                facadeMeshCount)
        end
        -- The counter measures LOCAL instances, not server replication,
        -- GPU time or device FPS. Keep it stable on unchanged LOD passes.
        if player:GetAttribute("LocalFacadeDetailCount") ~= localFacadeParts then
            player:SetAttribute("LocalFacadeDetailCount", localFacadeParts)
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
        -- Four original peripheral facade retrofits have genuine individual
        -- positions; reuse the existing district architecture LOD sampler.
        -- No additional Heartbeat, new script or fake collidable geometry.
        local retrofits = decor and decor:FindFirstChild("OriginalExteriorRetrofits")
        if retrofits and retrofits:IsA("Folder") then
            for _, retrofit in ipairs(retrofits:GetChildren()) do
                if retrofit:IsA("Model")
                    and retrofit:GetAttribute("OriginalExteriorRetrofit") == true
                    and retrofit:GetAttribute("SourceIsOriginal") == true
                    and retrofit:GetAttribute("CosmeticOnly") == true then
                    applyFolder(retrofit, DISTRICT_ARCHITECTURE_LOD,
                        profile, retrofit:GetPivot().Position, cameraPoint)
                end
            end
        end
        local hero = SceneryLodRules.heroArchitectureOwner(workspace)
        if hero then
            -- Server-authored original hero model also lives beyond the
            -- playable floor. Model pivot is a reliable location for its
            -- geometric visual owner, unlike the arena's central Base.
            applyFolder(hero, HERO_ARCHITECTURE_LOD,
                profile, hero:GetPivot().Position, cameraPoint)
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
