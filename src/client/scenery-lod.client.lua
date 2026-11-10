local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualBudgetRules = require(ReplicatedStorage.Shared.VisualBudgetRules)
local SceneryLodRules = require(ReplicatedStorage.Shared.SceneryLodRules)
local SceneryLodCache = require(script.Parent.SceneryLodCache)
local MidgroundOutboardLodRules = require(ReplicatedStorage.Shared.MidgroundOutboardLodRules)
local PlatformIdentityLodRules = require(ReplicatedStorage.Shared.PlatformIdentityLodRules)
local DistrictFacadeDetailKit = require(script.Parent.DistrictFacadeDetailKit)
local DistrictGatewayMeshKit = require(script.Parent.DistrictGatewayMeshKit)
local PremiumDistrictFacadeMeshKit = require(script.Parent.PremiumDistrictFacadeMeshKit)
local ApprovedCornerMonumentMeshKit = require(script.Parent.ApprovedCornerMonumentMeshKit)
local ApprovedHeroStructureMeshKit = require(script.Parent.ApprovedHeroStructureMeshKit)
local ApprovedFoundationChassisMeshKit = require(script.Parent.ApprovedFoundationChassisMeshKit)
local ApprovedPerimeterButtressMeshKit = require(script.Parent.ApprovedPerimeterButtressMeshKit)
local ApprovedPerimeterMachineryMeshKit = require(script.Parent.ApprovedPerimeterMachineryMeshKit)
local ApprovedPerimeterRotorMeshKit = require(script.Parent.ApprovedPerimeterRotorMeshKit)
local ApprovedPerimeterArmorMeshKit = require(script.Parent.ApprovedPerimeterArmorMeshKit)
local ApprovedPerimeterStructuresMeshKit = require(script.Parent.ApprovedPerimeterStructuresMeshKit)
local ApprovedPerimeterVariantApexMeshKit = require(script.Parent.ApprovedPerimeterVariantApexMeshKit)
local ApprovedExteriorTowerMeshKit = require(script.Parent.ApprovedExteriorTowerMeshKit)
local ApprovedExteriorRidgeMeshKit = require(script.Parent.ApprovedExteriorRidgeMeshKit)
local ApprovedSkylineDepthMeshKit = require(script.Parent.ApprovedSkylineDepthMeshKit)
local ApprovedVariantTowersLandmarkMeshKit = require(script.Parent.ApprovedVariantTowersLandmarkMeshKit)
local ApprovedCrossroadsOpenGantryMeshKit = require(script.Parent.ApprovedCrossroadsOpenGantryMeshKit)
local ApprovedClassicBroadcastFinMeshKit = require(script.Parent.ApprovedClassicBroadcastFinMeshKit)
local ApprovedPrimarySkylineMeshKit = require(script.Parent.ApprovedPrimarySkylineMeshKit)
local ApprovedOrbitalSignatureRingMeshKit = require(script.Parent.ApprovedOrbitalSignatureRingMeshKit)
local ApprovedSouthOrbitalObservationRingMeshKit = require(script.Parent.ApprovedSouthOrbitalObservationRingMeshKit)
local ApprovedSouthTowersSkytransferMeshKit = require(script.Parent.ApprovedSouthTowersSkytransferMeshKit)
local ApprovedSouthTowersLiftTwinsMeshKit = require(script.Parent.ApprovedSouthTowersLiftTwinsMeshKit)
local ApprovedSouthTowersFinishingMeshKit = require(script.Parent.ApprovedSouthTowersFinishingMeshKit)
local ApprovedSouthCrossroadsExchangeMeshKit = require(script.Parent.ApprovedSouthCrossroadsExchangeMeshKit)
local ApprovedSouthOrbitalFinishingMeshKit = require(script.Parent.ApprovedSouthOrbitalFinishingMeshKit)
local ApprovedSouthHarborDrydockMeshKit = require(script.Parent.ApprovedSouthHarborDrydockMeshKit)
local ApprovedSouthClassicObservatoryMeshKit = require(script.Parent.ApprovedSouthClassicObservatoryMeshKit)
local ApprovedTowersSignatureBridgeMeshKit = require(script.Parent.ApprovedTowersSignatureBridgeMeshKit)
local ApprovedCrossroadsSignatureInterchangeMeshKit = require(script.Parent.ApprovedCrossroadsSignatureInterchangeMeshKit)
local ApprovedHarborSignatureGantryMeshKit = require(script.Parent.ApprovedHarborSignatureGantryMeshKit)
local ApprovedClassicSignatureObservatoryMeshKit = require(script.Parent.ApprovedClassicSignatureObservatoryMeshKit)
local ApprovedClassicForgedSupportsMeshKit = require(script.Parent.ApprovedClassicForgedSupportsMeshKit)
local PremiumRouteMeshKit = require(script.Parent.PremiumRouteMeshKit)
local SkySpineCrownMeshKit = require(script.Parent.SkySpineCrownMeshKit)
local HarborPromenadePortalMeshKit = require(script.Parent.HarborPromenadePortalMeshKit)
local HarborDockCaissonMeshKit = require(script.Parent.HarborDockCaissonMeshKit)
local HarborFreighterMeshKit = require(script.Parent.HarborFreighterMeshKit)
local HarborGantryKineticMeshKit = require(script.Parent.HarborGantryKineticMeshKit)
local HarborHeroStationMeshKit = require(script.Parent.HarborHeroStationMeshKit)
local HarborMidgroundBargeMeshKit = require(script.Parent.HarborMidgroundBargeMeshKit)
local HarborSeaMeshKit = require(script.Parent.HarborSeaMeshKit)
local TowerCoolingSpireMeshKit = require(script.Parent.TowerCoolingSpireMeshKit)
local ApprovedMidgroundSkylineMeshKit = require(script.Parent.ApprovedMidgroundSkylineMeshKit)
local ApprovedCinematicHorizonMeshKit = require(script.Parent.ApprovedCinematicHorizonMeshKit)
local ApprovedCinematicSkyTrafficMeshKit = require(script.Parent.ApprovedCinematicSkyTrafficMeshKit)
local ApprovedOrbitalHaloTrussMeshKit = require(script.Parent.ApprovedOrbitalHaloTrussMeshKit)
local OriginalOrbitalStationsMeshKit = require(script.Parent.OriginalOrbitalStationsMeshKit)
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
    -- Five creator-approved airborne/industrial MeshPart families replace
    -- the native ambient primitives outside the 320-stud playable edge.
    -- Center-origin culling at 125 would hide the ENTIRE pack from players
    -- approaching an edge, despite strict 2/4/6 Model quotas. Keep the
    -- authored traffic visible on Low/Medium, with no new LOD sampler.
    ArenaAmbientPropsLocal = {
        LowDistance = 230,
        MediumDistance = 290,
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
    -- The real 3D source replacements are per-silhouette, but native
    -- fallbacks used to be culled as ONE group from Arena.Base center.
    -- Sector-aware handling below keeps the same exact numeric thresholds.
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
    -- Source-welded cosmetic decks use the SAME cutoffs but individual
    -- real physical platform positions, not an all-or-none center cull.
    ArenaPlatformIdentityLocal = {
        LowDistance = 105,
        MediumDistance = 165,
    },
    LobbySurfaceDetailLocal = {
        LowDistance = 92,
        MediumDistance = 145,
        Origin = "Lobby",
    },
    -- The existing 5/8/11 nonphysical skyline sites span a 320-stud
    -- world. Never hide an adjacent authentic/native skyline entirely
    -- because the camera crossed the center-distance tier cutoff.
    -- Original Part counts stay fixed; new approved MeshParts have their
    -- own much stricter camera/pressure quotas and source-safe fallbacks.
    ArenaCinematicDepthLocal = {
        LowDistance = 240,
        MediumDistance = 315,
    },
    -- The original surface owner spans an actual 320-stud arena.
    -- Center-based 105/160 cutoffs hid approved relief and source plates
    -- from players near a real rim. Keep six Low genuine 3D plates and
    -- tier-capped Medium/High reliefs readable across the whole active deck.
    -- This still uses the existing camera sampler and Android Part census.
    ArenaSurfaceReliefLocal = {
        LowDistance = 240,
        MediumDistance = 300,
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

-- Client-only native sky masses are spread OUTSIDE the 320-stud floor.
-- A center-distance blanket mask falsely hides the one nearby landmark
-- when an Android player approaches the real rim. Apply the established
-- same-quality LOD masks to the exact builder-tagged four-to-six
-- noncolliding structures and their own ornaments, one physical owner at
-- a time. Existing imported MeshPart owners still decide fallback masking.
local function applyMidgroundOutboard(folder, profile, arenaOrigin, cameraPoint)
    local cache = ensureCache(folder)
    if cache.dirty then
        SceneryLodCache.refresh(folder, cache, classifyDescendant)
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local variant = arena and arena:GetAttribute("VariantId")
    local anchors = MidgroundOutboardLodRules.anchors(folder, variant)
    local previous = cache.midgroundSectorVisible or {}
    local sectorVisible = {}
    local limits = FOLDERS.ArenaMidgroundMassLocal
    local centralDistance = (cameraPoint - arenaOrigin).Magnitude
    local centralVisible = SceneryLodRules.visible(profile.Name,
        centralDistance, limits.LowDistance, limits.MediumDistance,
        cache.midgroundCentralVisible)
    cache.midgroundCentralVisible = centralVisible

    for index, anchor in pairs(anchors) do
        local distance = MidgroundOutboardLodRules.distance(
            cameraPoint, arenaOrigin, anchor.Position)
        sectorVisible[index] = SceneryLodRules.visible(profile.Name,
            distance, limits.LowDistance, limits.MediumDistance,
            previous[index])
    end
    cache.midgroundSectorVisible = sectorVisible

    -- Most of these source-authored native silhouettes are plain Parts.
    -- Keep the SAME LOD transparency cache as applyFolder, so approved
    -- replacements can own their native Transparency independently and
    -- fall back safely without stale LocalTransparencyModifier=1 masks.
    for _, descendant in ipairs(cache.entries) do
        if not descendant.Parent then
            cache.dirty = true
            continue
        end
        local ownerPart = descendant
        if not descendant:IsA("BasePart") then
            local ancestor = descendant.Parent
            while ancestor and ancestor ~= folder do
                if ancestor:IsA("BasePart") then
                    ownerPart = ancestor
                    break
                end
                ancestor = ancestor.Parent
            end
        end
        local index = MidgroundOutboardLodRules.index(ownerPart, variant)
        local visible = if index then sectorVisible[index] == true
            else centralVisible
        local minimumTier = descendant:GetAttribute("SceneryMinimumTier")
        if minimumTier == "Medium" and profile.Name == "Low"
            or minimumTier == "High" and profile.Name ~= "High" then
            visible = false
        end
        local lodHidden = descendant:GetAttribute("SceneryLodHidden") == true
        if descendant:IsA("BasePart") then
            if visible then
                if lodHidden then
                    descendant.LocalTransparencyModifier = tonumber(
                        descendant:GetAttribute("SceneryLodBaseTransparency")) or 0
                    descendant:SetAttribute("SceneryLodHidden", false)
                end
            elseif not lodHidden then
                descendant:SetAttribute("SceneryLodBaseTransparency",
                    descendant.LocalTransparencyModifier)
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.LocalTransparencyModifier = 1
            elseif descendant.LocalTransparencyModifier ~= 1 then
                descendant.LocalTransparencyModifier = 1
            end
        elseif VisualBudgetRules.isEffect(descendant)
            or VisualBudgetRules.isLight(descendant)
            or descendant:IsA("SurfaceGui") then
            if visible and lodHidden then
                descendant.Enabled =
                    descendant:GetAttribute("SceneryLodBaseEnabled") ~= false
                descendant:SetAttribute("SceneryLodHidden", false)
            elseif not visible and not lodHidden then
                descendant:SetAttribute("SceneryLodBaseEnabled",
                    descendant.Enabled)
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.Enabled = false
            elseif not visible and descendant.Enabled then
                descendant.Enabled = false
            end
        end
    end
end

-- The original floor finish renderer mounts its real MeshParts and
-- bevels under ONE Folder, yet each visible Part already has a weld to
-- an exact server-owned platform (or certified nonphysical support post).
-- Do NOT blanket-cull every route from the 320-stud arena CENTER on
-- Android. Apply the EXISTING 105/165-stud LOD to the nearest of center
-- and that actual platform; never modify the physical Part itself.
local function applyPlatformIdentityNearPlayer(folder, profile,
        arenaOrigin, cameraPoint)
    local cache = ensureCache(folder)
    if cache.dirty then
        SceneryLodCache.refresh(folder, cache, classifyDescendant)
    end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local decor = arena and arena:FindFirstChild("Decor")
    local limits = FOLDERS.ArenaPlatformIdentityLocal
    local centerDistance = (cameraPoint - arenaOrigin).Magnitude
    local centerVisible = SceneryLodRules.visible(profile.Name,
        centerDistance, limits.LowDistance, limits.MediumDistance,
        cache.platformIdentityCenterVisible)
    cache.platformIdentityCenterVisible = centerVisible

    local previous = cache.platformIdentityOwners or {}
    local owners = {}
    for _, descendant in ipairs(cache.entries) do
        if not descendant.Parent then
            cache.dirty = true
            continue
        end
        local part = descendant
        if not part:IsA("BasePart") then
            local ancestor = part.Parent
            while ancestor and ancestor ~= folder do
                if ancestor:IsA("BasePart") then
                    part = ancestor
                    break
                end
                ancestor = ancestor.Parent
            end
        end
        local native = PlatformIdentityLodRules.owner(part, platforms, decor)
        local visible = centerVisible
        if native then
            local known = owners[native]
            if known == nil then
                local distance = PlatformIdentityLodRules.distance(
                    cameraPoint, arenaOrigin, native.Position)
                known = SceneryLodRules.visible(profile.Name,
                    distance, limits.LowDistance, limits.MediumDistance,
                    previous[native])
                owners[native] = known
            end
            visible = known
        end

        local minimumTier = descendant:GetAttribute("SceneryMinimumTier")
        if minimumTier == "Medium" and profile.Name == "Low"
            or minimumTier == "High" and profile.Name ~= "High" then
            visible = false
        end
        local lodHidden = descendant:GetAttribute("SceneryLodHidden") == true
        if descendant:IsA("BasePart") then
            if visible then
                if lodHidden then
                    descendant.LocalTransparencyModifier = tonumber(
                        descendant:GetAttribute("SceneryLodBaseTransparency")) or 0
                    descendant:SetAttribute("SceneryLodHidden", false)
                end
            elseif not lodHidden then
                descendant:SetAttribute("SceneryLodBaseTransparency",
                    descendant.LocalTransparencyModifier)
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.LocalTransparencyModifier = 1
            elseif descendant.LocalTransparencyModifier ~= 1 then
                descendant.LocalTransparencyModifier = 1
            end
        elseif VisualBudgetRules.isEffect(descendant)
            or VisualBudgetRules.isLight(descendant)
            or descendant:IsA("SurfaceGui") then
            if visible and lodHidden then
                descendant.Enabled =
                    descendant:GetAttribute("SceneryLodBaseEnabled") ~= false
                descendant:SetAttribute("SceneryLodHidden", false)
            elseif not visible and not lodHidden then
                descendant:SetAttribute("SceneryLodBaseEnabled",
                    descendant.Enabled)
                descendant:SetAttribute("SceneryLodHidden", true)
                descendant.Enabled = false
            elseif not visible and descendant.Enabled then
                descendant.Enabled = false
            end
        end
    end
    -- Keep only currently replicated server owner Instances. No stale
    -- refs accumulate after streaming/round replacement on Android.
    cache.platformIdentityOwners = owners
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

-- The main ArenaPlatformIdentity owner currently samples real carapaces,
-- bridge girders, long cradles and columns ONLY on map/stream/template
-- rebuild. After crossing the 320-stud arena, the old 8/16 approved-mesh
-- slots stay concentrated near the spawn even while the camera moves.
-- Retarget that existing bounded owner when the camera crosses a genuine
-- large distance, reusing THIS 0.65/0.90s LOD pass. Never rebuild for
-- camera rotation, low-end devices, off-map views or every frame.
-- The hard 12-second cooldown avoids cloning hundreds of cosmetic welds
-- during fast avatar motion or noisy StreamingEnabled replication.
local nearFieldArena = nil
local nearFieldTier = nil
local nearFieldFocus = nil
local nearFieldLastChange = 0
local function retargetOriginalNearField(arena, cameraPoint, cameraReady,
        tier, pressure)
    if arena ~= nearFieldArena or tier ~= nearFieldTier then
        nearFieldArena = arena
        nearFieldTier = tier
        nearFieldFocus = nil
        nearFieldLastChange = 0
    end
    if not cameraReady or tier == "Low"
        or (tonumber(pressure) or 0) >= 2
        or not arena or not arena:IsA("Folder") then return end
    local base = arena:FindFirstChild("Base")
    if not base or not base:IsA("BasePart")
        or base.Size.X < 318 or base.Size.Z < 318 then return end
    local relative = base.CFrame:PointToObjectSpace(cameraPoint)
    if math.abs(relative.X) > base.Size.X * 0.5 + 16
        or math.abs(relative.Z) > base.Size.Z * 0.5 + 16
        or math.abs(relative.Y) > 130 then return end
    local now = os.clock()
    if not nearFieldFocus then
        nearFieldFocus = cameraPoint
        nearFieldLastChange = now
        return
    end
    local dx = cameraPoint.X - nearFieldFocus.X
    local dz = cameraPoint.Z - nearFieldFocus.Z
    if dx * dx + dz * dz < 88 * 88
        or now - nearFieldLastChange < 12 then return end
    nearFieldFocus = cameraPoint
    nearFieldLastChange = now
    -- Client-local epoch only: no remote traffic or gameplay authority.
    -- One subscribed visual owner rebuilds using its CURRENT camera.
    local previous = tonumber(player:GetAttribute(
        "LocalPremiumNearFieldEpoch")) or 0
    player:SetAttribute("LocalPremiumNearFieldEpoch", previous + 1)
end

-- Don't wait for the LOD tick when primary/secondary Darkness
-- arrives: the existing disaster controller publishes this attribute.
player:GetAttributeChangedSignal("LocalDarknessLightGuard"):Connect(function()
    SkySpineCrownMeshKit.setDarknessGuard(
        player:GetAttribute("LocalDarknessLightGuard") == true)
end)

-- P0 baseline: sample the COST of the existing complete LOD pass, not
-- the 0.65/0.90s sleep between passes. Publish only once per 16 passes,
-- with no new task, event, Workspace traversal or remote telemetry.
-- A total duration is not GPU time: pair this with Roblox MicroProfiler
-- before claiming a performance improvement.
local lodSampleCount = 0
local lodSampleTotalMs = 0
local lodSamplePeakMs = 0
local lodSampleFolderTotalMs = 0
local lodSample3dTotalMs = 0
-- Three independently expensive 3D owners; their timings are subsets of
-- the complete pass, never summed as an additional wall-clock duration.
local lodRouteTotalMs = 0
local lodGroundTotalMs = 0
local lodDistrictTotalMs = 0

task.spawn(function()
    while true do
        local lodStartedAt = os.clock()
        local profile = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), isTouch)

        local arenaOrigin, lobbyOrigin = currentOrigins()
        local cameraPoint, cameraReady, cameraLook = cameraPosition()
        for folderName, limits in pairs(FOLDERS) do
            if folderName ~= "PracticePadPolishLocal"
                and folderName ~= "ArenaMidgroundMassLocal"
                and folderName ~= "ArenaPlatformIdentityLocal" then
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

        local folderPassMs = (os.clock() - lodStartedAt) * 1000
        -- Exact local outboard fallback silhouettes: the old all-or-none
        -- center-only LOD hid nearby Native blocks at an arena rim when
        -- no approved 3D replacement was resident. Each builder-tagged
        -- group now retains the original Low/Medium threshold near its
        -- own real native anchor; no new visual/update loop.
        local midground = workspace:FindFirstChild("ArenaMidgroundMassLocal")
        if midground and midground:IsA("Folder") then
            applyMidgroundOutboard(midground, profile, arenaOrigin, cameraPoint)
        end

        -- Use REAL server platform welds for nearby original 3D decks
        -- and their trim; preserve the original quality cutoffs and all
        -- server disaster/collision authority. One existing LOD tick.
        local identity = workspace:FindFirstChild("ArenaPlatformIdentityLocal")
        if identity and identity:IsA("Folder") then
            applyPlatformIdentityNearPlayer(
                identity, profile, arenaOrigin, cameraPoint)
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
        -- Refresh actual carapace/column selection only after a major
        -- camera translation; the dynamic route mesh kit below continues
        -- using its own per-sample selection without any extra work loop.
        retargetOriginalNearField(arena, cameraPoint, cameraReady,
            profile.Name, player:GetAttribute("OptionalVfxPressure"))
        -- Premium real imported 3D on PHYSICAL jump decks and bridges:
        -- the SAME existing camera-tier loop owns all local MeshPart
        -- creation/cleanup. Original colliders and hazard cues stay live;
        -- animated collapse, shrink and stream changes hide cosmetics.
        local routeSyncStartedAt = os.clock()
        PremiumRouteMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook,
            player:GetAttribute("OptionalVfxPressure"), isTouch,
            player:GetAttribute("PbrMaterialsDisabled") == true)
        lodRouteTotalMs += (os.clock() - routeSyncStartedAt) * 1000
        -- Five-arena original 2,976-triangle sculpted floor: healthy
        -- High can now replace all 36 genuine 49-stud native floor bays,
        -- Medium 12 and Low 2. The EXISTING GPU/instance backpressure
        -- automatically demotes to 24/16 High or 8/4 Medium if Android
        -- frame pacing suffers. No new loop; danger decals stay on top.
        -- Shrink/streaming already restore native geometry immediately.
        local groundSyncStartedAt = os.clock()
        PremiumGroundMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook,
            player:GetAttribute("OptionalVfxPressure"), isTouch,
            player:GetAttribute("PbrMaterialsDisabled") == true)
        lodGroundTotalMs += (os.clock() - groundSyncStartedAt) * 1000
        local floorMeshes = PremiumGroundMeshKit.count()
        if player:GetAttribute("LocalOriginalGroundMeshCount") ~= floorMeshes then
            player:SetAttribute("LocalOriginalGroundMeshCount", floorMeshes)
        end
        -- True 2K Normal/Albedo/Roughness/Metalness SurfaceAppearance
        -- instances attached to the ALREADY verified 3D UV tile models.
        -- These are counts of actually mounted instances, not a claim of
        -- texture residency, frame rate or visual sign-off on Android.
        local pbrTiles, pbrAppearances = PremiumGroundMeshKit.pbrCount()
        if player:GetAttribute("LocalGroundPbr2KTileCount") ~= pbrTiles then
            player:SetAttribute("LocalGroundPbr2KTileCount", pbrTiles)
        end
        if player:GetAttribute("LocalGroundPbr2KAppearanceCount")
            ~= pbrAppearances then
            player:SetAttribute("LocalGroundPbr2KAppearanceCount",
                pbrAppearances)
        end
        -- Client-only diagnostics count genuine imported MODEL instances,
        -- not fabricated FPS or proof that Roblox textures finished drawing.
        local routeMeshes = PremiumRouteMeshKit.count()
        if player:GetAttribute("LocalOriginalRouteMeshCount") ~= routeMeshes then
            player:SetAttribute("LocalOriginalRouteMeshCount", routeMeshes)
        end
        local routePbrModels, routePbrAppearances =
            PremiumRouteMeshKit.pbrCount()
        if player:GetAttribute("LocalOriginalRoutePbr2KModelCount")
            ~= routePbrModels then
            player:SetAttribute("LocalOriginalRoutePbr2KModelCount",
                routePbrModels)
        end
        if player:GetAttribute("LocalOriginalRoutePbr2KAppearanceCount")
            ~= routePbrAppearances then
            player:SetAttribute("LocalOriginalRoutePbr2KAppearanceCount",
                routePbrAppearances)
        end
        -- Exact live number of panels hidden behind a sufficiently covering
        -- source-authentic 3D top, not number of desired routes or inferred
        -- render quality. Incomplete/faded meshes keep native landing paint.
        local connectedPairs = PremiumRouteMeshKit.connectedPairsCount()
        if player:GetAttribute("LocalOriginalConnectedRoute3DPairs")
            ~= connectedPairs then
            player:SetAttribute("LocalOriginalConnectedRoute3DPairs",
                connectedPairs)
        end
        local coveredPanels = PremiumRouteMeshKit.coveredPanelCount()
        if player:GetAttribute("LocalOriginalRoutePanelsCoveredCount")
            ~= coveredPanels then
            player:SetAttribute("LocalOriginalRoutePanelsCoveredCount",
                coveredPanels)
        end
        -- Complete the four real gateways in all five maps with the
        -- same approved source (steps 2/5/6/9), on the EXISTING camera
        -- sampler and Android part budget. Pressure reduces optional 3D.
        SkySpineCrownMeshKit.setDarknessGuard(
            player:GetAttribute("LocalDarknessLightGuard") == true)
        SkySpineCrownMeshKit.sync(arena, cameraPoint, profile.Name,
            cameraReady, cameraLook,
            player:GetAttribute("OptionalVfxPressure"), isTouch,
            player:GetAttribute("PbrMaterialsDisabled") == true)
        local crownMeshes = SkySpineCrownMeshKit.count()
        if player:GetAttribute("LocalOriginalSkySpineCrownCount")
            ~= crownMeshes then
            player:SetAttribute("LocalOriginalSkySpineCrownCount",
                crownMeshes)
        end
        local outerCrowns = SkySpineCrownMeshKit.outerCount()
        if player:GetAttribute("LocalOriginalSkySpineOuterCrownCount")
            ~= outerCrowns then
            player:SetAttribute("LocalOriginalSkySpineOuterCrownCount",
                outerCrowns)
        end
        local crownPbrModels, crownPbrAppearances =
            SkySpineCrownMeshKit.pbrCount()
        if player:GetAttribute("LocalOriginalSkySpinePbr2KModelCount")
            ~= crownPbrModels then
            player:SetAttribute("LocalOriginalSkySpinePbr2KModelCount",
                crownPbrModels)
        end
        if player:GetAttribute("LocalOriginalSkySpinePbr2KAppearanceCount")
            ~= crownPbrAppearances then
            player:SetAttribute("LocalOriginalSkySpinePbr2KAppearanceCount",
                crownPbrAppearances)
        end
        local gatewayLights = SkySpineCrownMeshKit.lightCount()
        if player:GetAttribute("LocalOriginalSkySpineSignalLightCount")
            ~= gatewayLights then
            player:SetAttribute("LocalOriginalSkySpineSignalLightCount",
                gatewayLights)
        end
        -- True original 3D harbor freight gantries over the SIX existing
        -- two-lane promenade arch sockets. No additional scanning loop:
        -- these share this exact camera-distance and Android tier pass.
        -- High up to six, Medium two, Low zero, pressure demotes optional
        -- detail but NEVER hides an actual platform or danger cue.
        HarborPromenadePortalMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"), isTouch,
            player:GetAttribute("PbrMaterialsDisabled") == true)
        local gantries = HarborPromenadePortalMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborPromenadeCount")
            ~= gantries then
            player:SetAttribute("LocalOriginalHarborPromenadeCount",gantries)
        end
        local gantryPbrModels, gantryPbrOverlays =
            HarborPromenadePortalMeshKit.pbrCount()
        if player:GetAttribute("LocalOriginalHarborGantryPbr2KModelCount")
            ~= gantryPbrModels then
            player:SetAttribute("LocalOriginalHarborGantryPbr2KModelCount",
                gantryPbrModels)
        end
        if player:GetAttribute("LocalOriginalHarborGantryPbr2KAppearanceCount")
            ~= gantryPbrOverlays then
            player:SetAttribute("LocalOriginalHarborGantryPbr2KAppearanceCount",
                gantryPbrOverlays)
        end
        -- Up to twelve real ORIGINAL 3D forged Harbor cargo skins on
        -- actual HarborRoute/HarborSpokeRoute jump landing parts, not new
        -- fake routes. This reuses the same camera/LOD/pressure owner,
        -- with all 7 MeshParts per verified source counted in the ledger.
        HarborDockCaissonMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local dockModels, dockPieces = HarborDockCaissonMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborDockCaissonCount")
            ~= dockModels then
            player:SetAttribute("LocalOriginalHarborDockCaissonCount",
                dockModels)
        end
        if player:GetAttribute("LocalOriginalHarborDockMeshPartCount")
            ~= dockPieces then
            player:SetAttribute("LocalOriginalHarborDockMeshPartCount",
                dockPieces)
        end
        -- Real approved 3D cargo freighter replaces the large distant
        -- Roblox-native ship ONLY when model and safe native fallback exist.
        -- Zero additional loops, server physics, lights or fake routes.
        HarborFreighterMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local freighter=HarborFreighterMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborFreighterCount")
            ~= freighter then
            player:SetAttribute("LocalOriginalHarborFreighterCount",freighter)
        end
        -- Replace the outboard Harbor hero's primitive pier, glazed
        -- signal house, radar mast and crane with a real source-certified
        -- 3D model. Native radar, storm lens, hoist and weight still drive
        -- the three kinetic MeshParts, through their OWN existing owners.
        -- One camera LOD sampler; absolutely no additional render loop.
        HarborHeroStationMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,player:GetAttribute("OptionalVfxPressure"))
        local heroStation=HarborHeroStationMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborHeroStationCount")
            ~= heroStation then
            player:SetAttribute("LocalOriginalHarborHeroStationCount",heroStation)
        end
        -- Four actual non-walkable nearshore craft: replace their stamped
        -- native container/block geometry with authentic chined ships,
        -- never mask adjacent cargo or an arena hazard. Reuse THIS
        -- existing camera/Android pressure sampler, no new polling.
        HarborMidgroundBargeMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local originalBarges=HarborMidgroundBargeMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborBargeCount")
            ~= originalBarges then
            player:SetAttribute("LocalOriginalHarborBargeCount",
                originalBarges)
        end
        -- Authentic source-authored coastal sea around the REAL
        -- 320-stud Storm Harbor arena: 7 sculpted UV/tangent MeshParts,
        -- zero water colliders or fake surfaces above gameplay. The sea
        -- is a primary environment silhouette on Low/Medium/High,
        -- not optional particle spam, and uses THIS existing LOD clock.
        HarborSeaMeshKit.sync(arena,cameraPoint,profile.Name,cameraReady)
        local ocean=HarborSeaMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborSeaCount")~=ocean then
            player:SetAttribute("LocalOriginalHarborSeaCount",ocean)
        end
        -- Outside the Harbor-specific branch, five genuine Tower Run
        -- cooling megastructures now replace square nonphysical native
        -- midground Parts, including their old roof details. Same LOD
        -- sampler, reversible safety/Android fallback, no extra tick.
        TowerCoolingSpireMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local trueCoolingSpires=TowerCoolingSpireMeshKit.count()
        if player:GetAttribute("LocalOriginalTowerCoolingSpireCount")
            ~=trueCoolingSpires then
            player:SetAttribute("LocalOriginalTowerCoolingSpireCount",
                trueCoolingSpires)
        end
        -- Replace the remaining outboard Classic/Grid broadcast boxes
        -- and Crossroads transit blocks with FOUR different already
        -- approved original 3D facade sources per arena, no new CDN load.
        -- Existing LOD/pressure cadence, all old native details reversible.
        ApprovedMidgroundSkylineMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local skyline=ApprovedMidgroundSkylineMeshKit.count()
        if player:GetAttribute("LocalOriginalMidgroundSkylineCount")
            ~=skyline then
            player:SetAttribute("LocalOriginalMidgroundSkylineCount",skyline)
        end
        local replaced=ApprovedMidgroundSkylineMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalMidgroundNativeReplaced")
            ~=replaced then
            player:SetAttribute("LocalOriginalMidgroundNativeReplaced",
                replaced)
        end
        -- A single source-authenticated cinematic horizon mesh owner
        -- replaces body, crown and optional slit at the real, stable
        -- eleven-sector locations of ALL five arena themes. The new
        -- models remain strictly visual, bound to the existing LOD tick
        -- and Android pressure levels; native art restores before unmount.
        ApprovedCinematicHorizonMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"),isTouch)
        local trueCinema=ApprovedCinematicHorizonMeshKit.count()
        if player:GetAttribute("LocalOriginalCinematicHorizon3DCount")
            ~=trueCinema then
            player:SetAttribute("LocalOriginalCinematicHorizon3DCount",
                trueCinema)
        end
        local replacedCinema=
            ApprovedCinematicHorizonMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalNativeCinematicHorizonPartsReplaced")
            ~=replacedCinema then
            player:SetAttribute("LocalNativeCinematicHorizonPartsReplaced",
                replacedCinema)
        end
        -- Five creator-approved moving 3D craft source models replace
        -- the 2/4 neon sky-traffic native slivers. WeldConstraints follow
        -- the ORIGINAL CFrame tween, not an extra per-frame animation.
        -- Template arrival late in streaming is picked up by this SAME
        -- quality-pressure, camera-ranked scenery sampler.
        ApprovedCinematicSkyTrafficMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"),isTouch)
        local traffic3D=ApprovedCinematicSkyTrafficMeshKit.count()
        if player:GetAttribute("LocalOriginalCinematicTraffic3DCount")
            ~=traffic3D then
            player:SetAttribute("LocalOriginalCinematicTraffic3DCount",
                traffic3D)
        end

        -- Original approved 3D open modular trusses, not the thin
        -- rectangle parts, replace nearby sectors of Orbital's entire
        -- 14-sector static halo. Quality/GPU pressure caps and the
        -- existing scenery sampler control all assembly and failback.
        ApprovedOrbitalHaloTrussMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"),isTouch)
        local realHalo=ApprovedOrbitalHaloTrussMeshKit.count()
        if player:GetAttribute("LocalOriginalOrbitalHalo3DCount")
            ~=realHalo then
            player:SetAttribute("LocalOriginalOrbitalHalo3DCount",realHalo)
        end
        local nativeHalo=ApprovedOrbitalHaloTrussMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalOrbitalHaloNativeReplaced")
            ~=nativeHalo then
            player:SetAttribute("LocalOriginalOrbitalHaloNativeReplaced",
                nativeHalo)
        end

        -- Authentic compact Orbital satellite/containment stations, not
        -- primitive sphere blocks. Reuse same camera/pressure sampler.
        OriginalOrbitalStationsMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local orbitalModels=OriginalOrbitalStationsMeshKit.count()
        if player:GetAttribute("LocalOriginalOrbitalStationCount")
            ~=orbitalModels then
            player:SetAttribute("LocalOriginalOrbitalStationCount",orbitalModels)
        end
        local orbitalNative=OriginalOrbitalStationsMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalOrbitalNativeReplaced")
            ~=orbitalNative then
            player:SetAttribute("LocalOriginalOrbitalNativeReplaced",orbitalNative)
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
        -- The closest genuine imported exterior structures still sit on
        -- 4-11 primitive Roblox foundation blocks. Replace the native
        -- cosmetics with a source-approved 3,072-triangle sculpted chassis;
        -- Low 0 / Medium 1 / High 2, reversible on shrink/stream/LOD loss.
        -- Parent under the existing imported owner to share its LOD census.
        ApprovedFoundationChassisMeshKit.sync(arena, imported, cameraPoint,
            profile.Name, cameraReady)
        local foundationMeshes = ApprovedFoundationChassisMeshKit.count()
        if player:GetAttribute("LocalApprovedFoundationChassis3DCount")
            ~= foundationMeshes then
            player:SetAttribute("LocalApprovedFoundationChassis3DCount",
                foundationMeshes)
        end
        -- Replace the most visible raw rectangular station buttresses
        -- with two owner-approved vertical structural meshes per real
        -- perimeter station (up to one Medium, two touch High, four PC High).
        -- It uses this SAME camera pass and respects VFX pressure; server
        -- collision, floor and nearby warning lights are never touched.
        ApprovedPerimeterButtressMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local stationMeshes = ApprovedPerimeterButtressMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterStation3DCount")
            ~= stationMeshes then
            player:SetAttribute("LocalApprovedPerimeterStation3DCount",
                stationMeshes)
        end
        local stationPrimitives =
            ApprovedPerimeterButtressMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterPrimitivePillarsReplaced")
            ~= stationPrimitives then
            player:SetAttribute("LocalPerimeterPrimitivePillarsReplaced",
                stationPrimitives)
        end
        -- The SAME existing LOD pass replaces the three big native machine
        -- cuboids at each actual perimeter station only after all three
        -- authentic equipment meshes are ready. No camera loop or physics.
        ApprovedPerimeterMachineryMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local machineStations = ApprovedPerimeterMachineryMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterMachineryStationCount")
            ~= machineStations then
            player:SetAttribute("LocalApprovedPerimeterMachineryStationCount",
                machineStations)
        end
        local machinePrimitives =
            ApprovedPerimeterMachineryMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterPrimitiveMachineryReplaced")
            ~= machinePrimitives then
            player:SetAttribute("LocalPerimeterPrimitiveMachineryReplaced",
                machinePrimitives)
        end
        -- P4: same already-running camera sample and pressure meter:
        -- three authentic previously moderated 3D rotor assemblies
        -- replace three native cylinder visuals per genuine perimeter
        -- station. Never alter MapBuilder, physics or disaster warnings.
        ApprovedPerimeterRotorMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local rotorStations = ApprovedPerimeterRotorMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterRotorStationCount")
            ~= rotorStations then
            player:SetAttribute("LocalApprovedPerimeterRotorStationCount",
                rotorStations)
        end
        local rotorPrimitives =
            ApprovedPerimeterRotorMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterPrimitiveRotorsReplaced")
            ~= rotorPrimitives then
            player:SetAttribute("LocalPerimeterPrimitiveRotorsReplaced",
                rotorPrimitives)
        end
        -- Genuine forged 3D replacement for four untouched native WedgeParts
        -- on the actual near-camera perimeter station. Same camera sampler,
        -- no new loop, no native collision/AI/disaster writes.
        ApprovedPerimeterArmorMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local armoredStations = ApprovedPerimeterArmorMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterArmorStationCount")
            ~= armoredStations then
            player:SetAttribute("LocalApprovedPerimeterArmorStationCount",
                armoredStations)
        end
        local wedgePrimitives =
            ApprovedPerimeterArmorMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterPrimitiveWedgesReplaced")
            ~= wedgePrimitives then
            player:SetAttribute("LocalPerimeterPrimitiveWedgesReplaced",
                wedgePrimitives)
        end
        -- Two final broad rectangular server station pieces: restore safe
        -- native cosmetics if genuine source, streaming or GPU tier fails.
        -- This consumes only the existing scenery camera/LOD sample.
        ApprovedPerimeterStructuresMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local sculptedStructures = ApprovedPerimeterStructuresMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterStructureStationCount")
            ~= sculptedStructures then
            player:SetAttribute("LocalApprovedPerimeterStructureStationCount",
                sculptedStructures)
        end
        local remainingBlockSubstitutions =
            ApprovedPerimeterStructuresMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterPrimitiveStructuralBlocksReplaced")
            ~= remainingBlockSubstitutions then
            player:SetAttribute("LocalPerimeterPrimitiveStructuralBlocksReplaced",
                remainingBlockSubstitutions)
        end
        -- Approved, truly different station apex 3D models on all five
        -- arena variants. Both authored native variant silhouettes restore
        -- atomically on missing source, StreamingEnabled or GPU pressure.
        -- Uses the SAME scenery LOD clock and camera input, no new loop.
        ApprovedPerimeterVariantApexMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local variantApexes=ApprovedPerimeterVariantApexMeshKit.count()
        if player:GetAttribute("LocalApprovedPerimeterVariantApexCount")
            ~=variantApexes then
            player:SetAttribute("LocalApprovedPerimeterVariantApexCount",
                variantApexes)
        end
        local nativeApexesReplaced=
            ApprovedPerimeterVariantApexMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPerimeterVariantNativePiecesReplaced")
            ~=nativeApexesReplaced then
            player:SetAttribute("LocalPerimeterVariantNativePiecesReplaced",
                nativeApexesReplaced)
        end
        -- Source-approved complete-height forged industrial skyline. Only
        -- four big native tower body/cap/rib Parts are replaced. The original
        -- SignalBand and Antenna stay readable. Existing LOD camera sample
        -- controls proximity, quality, pressure and fallback; no new loop.
        ApprovedExteriorTowerMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local exteriorTowers=ApprovedExteriorTowerMeshKit.count()
        if player:GetAttribute("LocalApprovedExteriorTowerCount")
            ~=exteriorTowers then
            player:SetAttribute("LocalApprovedExteriorTowerCount",
                exteriorTowers)
        end
        local nativeTowersReplaced=ApprovedExteriorTowerMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalExteriorPrimitiveTowerPartsReplaced")
            ~=nativeTowersReplaced then
            player:SetAttribute("LocalExteriorPrimitiveTowerPartsReplaced",
                nativeTowersReplaced)
        end
        -- Four source-authored exterior corner sculptural ridges.
        -- Each approved Model replaces three WedgeParts with real art,
        -- sharing the existing LOD sampler and mobile pressure budget.
        ApprovedExteriorRidgeMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local ridgesModels=ApprovedExteriorRidgeMeshKit.count()
        if player:GetAttribute("LocalApprovedExteriorRidgeModelCount")
            ~=ridgesModels then
            player:SetAttribute("LocalApprovedExteriorRidgeModelCount",
                ridgesModels)
        end
        local ridgesHidden=ApprovedExteriorRidgeMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalExteriorRidgePrimitivesReplaced")
            ~=ridgesHidden then
            player:SetAttribute("LocalExteriorRidgePrimitivesReplaced",
                ridgesHidden)
        end
        -- Four real SkylineStructure cores/caps/rib pairs per arena.
        -- Preserve their original foundation, insets, antennas and physics.
        -- Reuse owner-approved seven-MeshPart source on existing LOD tick.
        ApprovedPrimarySkylineMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local primaryMeshes=ApprovedPrimarySkylineMeshKit.count()
        if player:GetAttribute("LocalPrimarySkylineMeshCount")
            ~=primaryMeshes then
            player:SetAttribute("LocalPrimarySkylineMeshCount",primaryMeshes)
        end
        local primaryNative=ApprovedPrimarySkylineMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPrimarySkylinePrimitivesReplaced")
            ~=primaryNative then
            player:SetAttribute("LocalPrimarySkylinePrimitivesReplaced",
                primaryNative)
        end
        -- Eight distant wedge roofs per arena: original approved sculpted
        -- tower art, camera-ranked and pressure-budgeted; native aerials stay.
        ApprovedSkylineDepthMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"),isTouch)
        local depthModels=ApprovedSkylineDepthMeshKit.count()
        if player:GetAttribute("LocalApprovedSkylineDepthModelCount")
            ~=depthModels then
            player:SetAttribute("LocalApprovedSkylineDepthModelCount",
                depthModels)
        end
        local depthReplaced=ApprovedSkylineDepthMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSkylineDepthPrimitivesReplaced")
            ~=depthReplaced then
            player:SetAttribute("LocalSkylineDepthPrimitivesReplaced",
                depthReplaced)
        end
        -- Original Towers corner machines and sculpted cap: true
        -- seven-material creator-approved mesh. Native antenna survives.
        -- Same shared sampler, strict camera budget and reversible fallback.
        ApprovedVariantTowersLandmarkMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local landmarkMeshes=ApprovedVariantTowersLandmarkMeshKit.count()
        if player:GetAttribute("LocalTowersLandmarkMeshCount")
            ~=landmarkMeshes then
            player:SetAttribute("LocalTowersLandmarkMeshCount",
                landmarkMeshes)
        end
        local landmarkHidden=
            ApprovedVariantTowersLandmarkMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalTowersLandmarkPrimitivesReplaced")
            ~=landmarkHidden then
            player:SetAttribute("LocalTowersLandmarkPrimitivesReplaced",
                landmarkHidden)
        end
        -- Four open-frame 3D Crossroads gantries; preserve native
        -- neon signal strips and never modify route collision.
        ApprovedCrossroadsOpenGantryMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local gantryModels=ApprovedCrossroadsOpenGantryMeshKit.count()
        if player:GetAttribute("LocalCrossroadsGantryMeshCount")
            ~=gantryModels then
            player:SetAttribute("LocalCrossroadsGantryMeshCount",gantryModels)
        end
        local gantryHidden=
            ApprovedCrossroadsOpenGantryMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalCrossroadsGantryPrimitivesReplaced")
            ~=gantryHidden then
            player:SetAttribute("LocalCrossroadsGantryPrimitivesReplaced",
                gantryHidden)
        end
        -- Four original Classic forged broadcast fins: retain all native
        -- neon strips and original gameplay geometry, reversible camera LOD.
        ApprovedClassicBroadcastFinMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,isTouch,
            player:GetAttribute("OptionalVfxPressure"))
        local finModels=ApprovedClassicBroadcastFinMeshKit.count()
        if player:GetAttribute("LocalClassicFinMeshCount")~=finModels then
            player:SetAttribute("LocalClassicFinMeshCount",finModels)
        end
        local finReplaced=ApprovedClassicBroadcastFinMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalClassicFinPrimitivesReplaced")
            ~=finReplaced then
            player:SetAttribute("LocalClassicFinPrimitivesReplaced",finReplaced)
        end
        -- P4: sixteen rectangular native Orbital ReactorArc segments are
        -- swapped for one TRUE source-approved continuous hollow 3D torus,
        -- after all sixteen source arcs are present and source Model fits.
        -- Uses existing camera/quality/pressure sampler; no extra loop.
        ApprovedOrbitalSignatureRingMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local trueOrbitalRings=ApprovedOrbitalSignatureRingMeshKit.count()
        if player:GetAttribute("LocalApprovedOrbitalSignatureRingCount")
            ~=trueOrbitalRings then
            player:SetAttribute("LocalApprovedOrbitalSignatureRingCount",
                trueOrbitalRings)
        end
        local arcsReplaced=ApprovedOrbitalSignatureRingMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalPrimitiveOrbitalSignatureArcsReplaced")
            ~=arcsReplaced then
            player:SetAttribute("LocalPrimitiveOrbitalSignatureArcsReplaced",
                arcsReplaced)
        end
        -- P4 Towers signature: one original continuous sculpted service
        -- span hides ONLY two distant, nonphysical primitive slabs. The
        -- HangingSignal and playable Skyrail remain untouched. Existing
        -- LOD camera cadence and optional GPU-pressure fallback apply.
        ApprovedTowersSignatureBridgeMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local forgedBridges=ApprovedTowersSignatureBridgeMeshKit.count()
        if player:GetAttribute("LocalApprovedTowersForgedBridgeCount")
            ~=forgedBridges then
            player:SetAttribute("LocalApprovedTowersForgedBridgeCount",
                forgedBridges)
        end
        local nativeBridgeSlabs=
            ApprovedTowersSignatureBridgeMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalTowersSignaturePrimitiveSlabsReplaced")
            ~=nativeBridgeSlabs then
            player:SetAttribute("LocalTowersSignaturePrimitiveSlabsReplaced",
                nativeBridgeSlabs)
        end
        -- Original approved Crossroads double-deck interchange: one truly
        -- sculpted seven-MeshPart source replaces four nonphysical native
        -- skyline slabs/cantilevers atomically. No extra client loop.
        ApprovedCrossroadsSignatureInterchangeMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local genuineCrossroadsInterchanges=
            ApprovedCrossroadsSignatureInterchangeMeshKit.count()
        if player:GetAttribute("LocalApprovedCrossroadsInterchangeCount")
            ~=genuineCrossroadsInterchanges then
            player:SetAttribute("LocalApprovedCrossroadsInterchangeCount",
                genuineCrossroadsInterchanges)
        end
        local crossroadsPrimitives=
            ApprovedCrossroadsSignatureInterchangeMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalCrossroadsInterchangePrimitivePartsReplaced")
            ~=crossroadsPrimitives then
            player:SetAttribute("LocalCrossroadsInterchangePrimitivePartsReplaced",
                crossroadsPrimitives)
        end
        -- P4 Harbor: authentic sculpted full-size 3D gantry replaces the
        -- giant nonphysical beam, cab and counterweight only. Native hoists,
        -- support legs, cargo stack and playable floor are preserved.
        -- Existing LOD camera/pressure sampler; no new frame loop.
        ApprovedHarborSignatureGantryMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local harborSignatureGantries=
            ApprovedHarborSignatureGantryMeshKit.count()
        if player:GetAttribute("LocalApprovedHarborSignatureGantryCount")
            ~=harborSignatureGantries then
            player:SetAttribute("LocalApprovedHarborSignatureGantryCount",
                harborSignatureGantries)
        end
        local harborPrimitiveBlocks=
            ApprovedHarborSignatureGantryMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalHarborSignaturePrimitiveBlocksReplaced")
            ~=harborPrimitiveBlocks then
            player:SetAttribute("LocalHarborSignaturePrimitiveBlocksReplaced",
                harborPrimitiveBlocks)
        end
        -- Classic signature landmark: a continuous sculpted tapered relay
        -- mast + two REAL concave parabolic receivers replace exactly the
        -- seven huge native primitive silhouettes together. Existing LOD
        -- camera/pressure sampler, zero extra frame loops or collisions.
        ApprovedClassicSignatureObservatoryMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local classicOriginalObservatories=
            ApprovedClassicSignatureObservatoryMeshKit.count()
        if player:GetAttribute("LocalApprovedClassicObservatoryCount")
            ~=classicOriginalObservatories then
            player:SetAttribute("LocalApprovedClassicObservatoryCount",
                classicOriginalObservatories)
        end
        local classicNativePartsReplaced=
            ApprovedClassicSignatureObservatoryMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalClassicSignaturePrimitivePartsReplaced")
            ~=classicNativePartsReplaced then
            player:SetAttribute("LocalClassicSignaturePrimitivePartsReplaced",
                classicNativePartsReplaced)
        end
        -- The seven source-authenticated Classic support MeshParts
        -- atomically replace the five remaining massive native buttress,
        -- inclined spar and telemetry-panel shapes. The independent
        -- original twin-dish Model remains untouched. Existing LOD only.
        ApprovedClassicForgedSupportsMeshKit.sync(arena,cameraPoint,
            profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local classicSupports=ApprovedClassicForgedSupportsMeshKit.count()
        if player:GetAttribute("LocalApprovedClassicForgedSupportsCount")
            ~=classicSupports then
            player:SetAttribute("LocalApprovedClassicForgedSupportsCount",
                classicSupports)
        end
        local classicSupportNatives=
            ApprovedClassicForgedSupportsMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalClassicSupportPrimitivePartsReplaced")
            ~=classicSupportNatives then
            player:SetAttribute("LocalClassicSupportPrimitivePartsReplaced",
                classicSupportNatives)
        end
        -- True SOUTH horizon ring: replaces exactly 14 original Orbital
        -- ObservationArc native Parts after full owner-approved 3D mount.
        -- Northern reactor and real gameplay physics are untouched.
        ApprovedSouthOrbitalObservationRingMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local southRings=ApprovedSouthOrbitalObservationRingMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthOrbitalRingCount")
            ~=southRings then
            player:SetAttribute("LocalApprovedSouthOrbitalRingCount",southRings)
        end
        local southArcs=
            ApprovedSouthOrbitalObservationRingMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthOrbitalObservationArcsReplaced")
            ~=southArcs then
            player:SetAttribute("LocalSouthOrbitalObservationArcsReplaced",
                southArcs)
        end
        -- South Towers: approved forged bridge and hanging elevator,
        -- two nonphysical primitives atomically replaced on valid LOD.
        ApprovedSouthTowersSkytransferMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local towersSouthCount=ApprovedSouthTowersSkytransferMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthTowersSkytransferCount")
            ~=towersSouthCount then
            player:SetAttribute("LocalApprovedSouthTowersSkytransferCount",towersSouthCount)
        end
        local towersSouthReplaced=
            ApprovedSouthTowersSkytransferMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthTowersPrimitiveBlocksReplaced")
            ~=towersSouthReplaced then
            player:SetAttribute("LocalSouthTowersPrimitiveBlocksReplaced",towersSouthReplaced)
        end
        -- South Towers: approved sculpted lift shafts and crown trusses.
        ApprovedSouthTowersLiftTwinsMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local southLiftCount=ApprovedSouthTowersLiftTwinsMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthTowersLiftTwinsCount")
            ~=southLiftCount then
            player:SetAttribute("LocalApprovedSouthTowersLiftTwinsCount",southLiftCount)
        end
        local southLiftReplaced=
            ApprovedSouthTowersLiftTwinsMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthTowersLiftPrimitivesReplaced")
            ~=southLiftReplaced then
            player:SetAttribute("LocalSouthTowersLiftPrimitivesReplaced",southLiftReplaced)
        end
        -- Seven remaining South Towers cosmetic primitives:
        -- foundation, deck inset, twin guides and suspensions, signal.
        ApprovedSouthTowersFinishingMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local finishingCount=ApprovedSouthTowersFinishingMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthTowersFinishingCount")
            ~=finishingCount then
            player:SetAttribute("LocalApprovedSouthTowersFinishingCount",
                finishingCount)
        end
        local finishingReplaced=
            ApprovedSouthTowersFinishingMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthTowersFinishingPrimitivesReplaced")
            ~=finishingReplaced then
            player:SetAttribute("LocalSouthTowersFinishingPrimitivesReplaced",
                finishingReplaced)
        end
        -- South Crossroads: one approved seven-material sculpture
        -- covers all 13 nonphysical native freight/interchange parts.
        ApprovedSouthCrossroadsExchangeMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local crossroadsSouthCount=ApprovedSouthCrossroadsExchangeMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthCrossroadsExchangeCount")
            ~=crossroadsSouthCount then
            player:SetAttribute("LocalApprovedSouthCrossroadsExchangeCount",
                crossroadsSouthCount)
        end
        local crossroadsSouthReplaced=
            ApprovedSouthCrossroadsExchangeMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthCrossroadsPrimitivesReplaced")
            ~=crossroadsSouthReplaced then
            player:SetAttribute("LocalSouthCrossroadsPrimitivesReplaced",
                crossroadsSouthReplaced)
        end
        -- South Orbital: keep the 14-arc approved torus independent.
        -- Replace its six remaining cosmetic native Parts with sphere,
        -- forged pylons, original clamp and 3D foundation only when valid.
        ApprovedSouthOrbitalFinishingMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local orbitalFinishingCount=ApprovedSouthOrbitalFinishingMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthOrbitalFinishingCount")
            ~=orbitalFinishingCount then
            player:SetAttribute("LocalApprovedSouthOrbitalFinishingCount",
                orbitalFinishingCount)
        end
        local orbitalFinishingReplaced=
            ApprovedSouthOrbitalFinishingMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthOrbitalFinishingPrimitivesReplaced")
            ~=orbitalFinishingReplaced then
            player:SetAttribute("LocalSouthOrbitalFinishingPrimitivesReplaced",
                orbitalFinishingReplaced)
        end
        -- South Harbor: original approved drydock sculpture replaces
        -- all 14 static, nonphysical southern skyline natives only.
        ApprovedSouthHarborDrydockMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local southDrydockCount=ApprovedSouthHarborDrydockMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthHarborDrydockCount")
            ~=southDrydockCount then
            player:SetAttribute("LocalApprovedSouthHarborDrydockCount",
                southDrydockCount)
        end
        local southDrydockReplaced=
            ApprovedSouthHarborDrydockMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthHarborPrimitivePartsReplaced")
            ~=southDrydockReplaced then
            player:SetAttribute("LocalSouthHarborPrimitivePartsReplaced",
                southDrydockReplaced)
        end
        -- Classic south: two sculpted radar dishes and eleven support,
        -- bridge, cabin and foundation natives, all cosmetic.
        ApprovedSouthClassicObservatoryMeshKit.sync(
            arena,cameraPoint,profile.Name,cameraReady,
            player:GetAttribute("OptionalVfxPressure"))
        local classicSouthCount=ApprovedSouthClassicObservatoryMeshKit.count()
        if player:GetAttribute("LocalApprovedSouthClassicObservatoryCount")
            ~=classicSouthCount then
            player:SetAttribute("LocalApprovedSouthClassicObservatoryCount",
                classicSouthCount)
        end
        local classicSouthReplaced=
            ApprovedSouthClassicObservatoryMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalSouthClassicPrimitivesReplaced")
            ~=classicSouthReplaced then
            player:SetAttribute("LocalSouthClassicPrimitivesReplaced",
                classicSouthReplaced)
        end
        -- Use each exterior model pivot, including the full cargo vessel,
        -- for Medium proximity. On Low only server-marked essential ship
        -- Parts survive; four separate cranes retain zero visible Parts.
        -- Native collision and hazards are never touched.
        for _, scenery in ipairs(SceneryLodRules.harborGantryOwners(arena)) do
            applyFolder(scenery, HARBOR_GANTRY_LOD,
                profile, scenery:GetPivot().Position, cameraPoint)
        end
        -- Replace four source-authored native crane silhouettes with true
        -- kinetic MeshParts that follow the ALREADY-RUNNING native
        -- trolley/hoist motion. Same distance/quality LOD sample.
        -- Low=0; Medium=2/1/0, High=4/2/0 under mobile pressure.
        HarborGantryKineticMeshKit.sync(arena,cameraPoint,profile.Name,
            cameraReady,cameraLook,
            player:GetAttribute("OptionalVfxPressure"))
        local craneModels,cranePieces=HarborGantryKineticMeshKit.count()
        if player:GetAttribute("LocalOriginalHarborKineticGantryCount")
            ~= craneModels then
            player:SetAttribute("LocalOriginalHarborKineticGantryCount",
                craneModels)
        end
        if player:GetAttribute("LocalOriginalHarborKineticMeshPartCount")
            ~= cranePieces then
            player:SetAttribute("LocalOriginalHarborKineticMeshPartCount",
                cranePieces)
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
        local districtSyncStartedAt = os.clock()
        PremiumDistrictFacadeMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, cameraLook)
        lodDistrictTotalMs += (os.clock() - districtSyncStartedAt) * 1000
        local facadeMeshCount = PremiumDistrictFacadeMeshKit.count()
        if player:GetAttribute("LocalOriginalDistrictFacadeMeshCount")
            ~= facadeMeshCount then
            player:SetAttribute("LocalOriginalDistrictFacadeMeshCount",
                facadeMeshCount)
        end
        -- Count the ACTUAL native facade/roofline pieces displaced by
        -- genuine approved MeshParts, not just imported models rendered
        -- on top of primitive building masses. No extra update loop.
        local replacedRoofPieces =
            PremiumDistrictFacadeMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalDistrictRooflinesReplaced")
            ~= replacedRoofPieces then
            player:SetAttribute("LocalOriginalDistrictRooflinesReplaced",
                replacedRoofPieces)
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
        -- On the same camera pass, replace the four corner towers'
        -- primitive silhouettes with REAL approved observatory/freight/
        -- turbine/aerial MeshParts. Preserve foundation and original
        -- native fallback if source, streaming or shrink is unavailable.
        ApprovedCornerMonumentMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady, cameraLook)
        local cornerModels = ApprovedCornerMonumentMeshKit.count()
        if player:GetAttribute("LocalOriginalCornerMonumentCount")
            ~= cornerModels then
            player:SetAttribute("LocalOriginalCornerMonumentCount",
                cornerModels)
        end
        local nativeCornersReplaced =
            ApprovedCornerMonumentMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalCornerPiecesReplaced")
            ~= nativeCornersReplaced then
            player:SetAttribute("LocalOriginalCornerPiecesReplaced",
                nativeCornersReplaced)
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
        -- Genuine approved source-authored 3D now REPLACES the five huge
        -- primitive skyline heroes, one distinct asset per arena variant.
        -- Sync after native LOD: the mounted kit owns only the static
        -- noncolliding transparency fallback, never LocalTransparencyModifier.
        -- Reuse this exact camera pass; no additional heartbeat or API calls.
        ApprovedHeroStructureMeshKit.sync(arena, cameraPoint,
            profile.Name, cameraReady)
        local authenticHeroes = ApprovedHeroStructureMeshKit.count()
        if player:GetAttribute("LocalApprovedHeroStructure3DCount")
            ~= authenticHeroes then
            player:SetAttribute("LocalApprovedHeroStructure3DCount",
                authenticHeroes)
        end
        local nativeHeroPieces = ApprovedHeroStructureMeshKit.replacedNativeCount()
        if player:GetAttribute("LocalOriginalHeroPartsReplaced")
            ~= nativeHeroPieces then
            player:SetAttribute("LocalOriginalHeroPartsReplaced", nativeHeroPieces)
        end

        -- A pad's Highlight and particle emitter have separate parents.
        -- Apply LOD to just these two client-owned containers; applying it
        -- to the pad would wrongly hide the server-owned pad and light.
        for _, owner in ipairs(SceneryLodRules.practicePadVisualOwners(workspace)) do
            applyFolder(owner, FOLDERS.PracticePadPolishLocal,
                profile, lobbyOrigin, cameraPoint)
        end

        local lodPassMs = (os.clock() - lodStartedAt) * 1000
        lodSampleCount += 1
        lodSampleTotalMs += lodPassMs
        lodSampleFolderTotalMs += folderPassMs
        lodSample3dTotalMs += math.max(0, lodPassMs - folderPassMs)
        lodSamplePeakMs = math.max(lodSamplePeakMs, lodPassMs)
        if lodSampleCount >= 16 then
            -- Client-only diagnostic counters. The existing performance
            -- pulse can correlate these with frame pacing; these are NOT
            -- sent to the server, nor exposed as a player-facing HUD.
            player:SetAttribute("ClientSceneryLodAvgPassMs",
                math.floor(lodSampleTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodMaxPassMs",
                math.floor(lodSamplePeakMs * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodFolderAvgMs",
                math.floor(lodSampleFolderTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLod3dAvgMs",
                math.floor(lodSample3dTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodRouteAvgMs",
                math.floor(lodRouteTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodGroundAvgMs",
                math.floor(lodGroundTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodDistrictAvgMs",
                math.floor(lodDistrictTotalMs / lodSampleCount * 100 + 0.5) / 100)
            player:SetAttribute("ClientSceneryLodSampleClock", os.clock())
            lodSampleCount = 0
            lodSampleTotalMs = 0
            lodSamplePeakMs = 0
            lodSampleFolderTotalMs = 0
            lodSample3dTotalMs = 0
            lodRouteTotalMs = 0
            lodGroundTotalMs = 0
            lodDistrictTotalMs = 0
        end
        task.wait(profile.Name == "Low" and 0.65 or 0.90)
    end
end)
