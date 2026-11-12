local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)
local MapVisualReadiness = require(ReplicatedStorage.Shared.MapVisualReadiness)
local JumpRouteCueRules = require(ReplicatedStorage.Shared.JumpRouteCueRules)
local PlatformFinishKit = require(script.Parent.PlatformFinishKit)
local PremiumLargeDeckHullMeshKit = require(script.Parent.PremiumLargeDeckHullMeshKit)
local PlatformNativeTrimReplacementKit = require(
    script.Parent.PlatformNativeTrimReplacementKit)
local PremiumLargeStructureMeshKit = require(
    script.Parent.PremiumLargeStructureMeshKit)
local PremiumPlatformSideMeshKit = require(
    script.Parent.PremiumPlatformSideMeshKit)
local HarborOutpostKit = require(script.Parent.HarborOutpostKit)

local player = Players.LocalPlayer
local roundEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local folder = Instance.new("Folder")
folder.Name = "ArenaPlatformIdentityLocal"
folder.Parent = workspace

-- All platform glyphs and bevel pieces share one bounded owner. A
-- CollapsePhase change updates only that platform's existing local parts;
-- it never rebuilds a whole arena or adds a per-frame loop.
local visualsByPlatform = {}
local collapseConnections = {}
local bridgeShutterConnections = {}
local routeAttributeConnections = {}
local outpostAttributeConnections = {}
local routeTargetConnections = {}
local routeCueStates = {}
local footprintDisconnects = {}
local originalColumnDisconnects = {}
-- Exact server-side native Parts covered by our locally mounted Low
-- source column. A streamed-out support must tear down the client mesh.
local mountedSupportNatives = {}
local mountedLongCradles = {}
local outpostMotions = {}
local currentOutpostPosture = "normal"

local function stopOutpostMotion(state)
    if state.tween then
        state.tween:Cancel()
        state.tween:Destroy()
        state.tween = nil
    end
    if state.joint and state.joint.Parent then
        state.joint.C0 = CFrame.identity
    end
end

local function refreshOutpostMotion(platform)
    local state = outpostMotions[platform]
    if not state then return end
    -- RoundState may arrive once a second. Never restart a tween unless
    -- the actual disaster posture changes. Also restore the creator's
    -- original metal color immediately on a phase or map transition.
    if state.posture ~= currentOutpostPosture then
        stopOutpostMotion(state)
        state.posture = currentOutpostPosture
        if state.instrument and state.instrument.Parent then
            state.instrument.Color = HarborOutpostKit.instrumentColor(
                state.baseColor, currentOutpostPosture
            )
        end
    end
    local phase = platform:GetAttribute("CollapsePhase")
    local active = player:GetAttribute("ReduceMotion") ~= true
        and platform.Parent ~= nil and state.joint.Parent ~= nil
        and platform.CanCollide and platform.Transparency < 0.75
        and phase ~= "Warning" and phase ~= "Gone"
    if not active then
        if state.tween then stopOutpostMotion(state) end
        return
    end
    if state.tween then return end
    local goal, duration = HarborOutpostKit.motionTarget(
        state.route, currentOutpostPosture
    )
    if not goal then return end
    state.joint.C0 = CFrame.identity
    -- Roblox TweenService supports CFrame properties on Weld. Only C0
    -- animates here; the existing shrink-footprint callback owns C1.
    -- Four owned tweens MAX in Medium/High, zero on Low and ReduceMotion.
    local tween = TweenService:Create(
        state.joint,
        TweenInfo.new(duration, Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut, -1, true),
        {C0 = goal}
    )
    state.tween = tween
    tween:Play()
end

local function clear()
    for _, connection in ipairs(originalColumnDisconnects) do
        connection:Disconnect()
    end
    table.clear(originalColumnDisconnects)
    table.clear(mountedSupportNatives)
    for platform in pairs(mountedLongCradles) do
        if platform.Parent then
            platform:SetAttribute("LocalOriginalLongCradleMounted", nil)
        end
        mountedLongCradles[platform] = nil
    end
    -- Restore any server-authored visual fallback before destroying our
    -- verified owner-replacement meshes. Colliders are never touched.
    PlatformNativeTrimReplacementKit.reset()
    if player:GetAttribute("LocalNativeStructuralPartsReplaced") ~= 0 then
        player:SetAttribute("LocalNativeStructuralPartsReplaced", 0)
    end
    if player:GetAttribute("LocalOriginalNearBridgeCradleCount") ~= 0 then
        player:SetAttribute("LocalOriginalNearBridgeCradleCount", 0)
    end
    if player:GetAttribute("LocalOriginalNearSupportColumnCount") ~= 0 then
        player:SetAttribute("LocalOriginalNearSupportColumnCount", 0)
    end
    if player:GetAttribute("LocalOriginalNearRouteCarapaceCount") ~= 0 then
        player:SetAttribute("LocalOriginalNearRouteCarapaceCount", 0)
    end
    if player:GetAttribute("LocalOriginalLowHubHullCount") ~= 0 then
        player:SetAttribute("LocalOriginalLowHubHullCount", 0)
    end
    if player:GetAttribute("LocalOriginalNearBridgeGirderCount") ~= 0 then
        player:SetAttribute("LocalOriginalNearBridgeGirderCount", 0)
    end
    if player:GetAttribute("LocalOriginalServiceHatch3DCount") ~= 0 then
        player:SetAttribute("LocalOriginalServiceHatch3DCount", 0)
    end
    if player:GetAttribute("LocalOriginalLargeStructure3DCount") ~= 0 then
        player:SetAttribute("LocalOriginalLargeStructure3DCount", 0)
    end
    for platform, state in pairs(outpostMotions) do
        stopOutpostMotion(state)
        for _, connection in ipairs(state.connections or {}) do
            connection:Disconnect()
        end
        outpostMotions[platform] = nil
    end
    for platform, connection in pairs(collapseConnections) do
        connection:Disconnect()
        collapseConnections[platform] = nil
    end
    for platform, connection in pairs(bridgeShutterConnections) do
        connection:Disconnect()
        bridgeShutterConnections[platform] = nil
    end
    for platform, disconnect in pairs(footprintDisconnects) do
        disconnect()
        footprintDisconnects[platform] = nil
    end
    for platform, connection in pairs(routeAttributeConnections) do
        connection:Disconnect()
        routeAttributeConnections[platform] = nil
    end
    for platform, connections in pairs(outpostAttributeConnections) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        outpostAttributeConnections[platform] = nil
    end
    for platform, connections in pairs(routeTargetConnections) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        routeTargetConnections[platform] = nil
    end
    table.clear(routeCueStates)
    table.clear(visualsByPlatform)
    folder:ClearAllChildren()
    if player:GetAttribute("LocalOriginalPlatformSideMeshPartCount") ~= 0 then
        player:SetAttribute("LocalOriginalPlatformSideMeshPartCount", 0)
    end
end

local function registerVisual(platform, visual)
    local visuals = visualsByPlatform[platform]
    if not visuals then
        visuals = {}
        visualsByPlatform[platform] = visuals
    end
    table.insert(visuals, visual)
end

local function makePart(name, size, cframe, color, material, transparency, anchorPart)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.CFrame = cframe
    part.Anchored = anchorPart == nil
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part.Material = material or Enum.Material.Metal
    part.Color = color
    part.Transparency = transparency or 0
    part:SetAttribute("ChaosBaseTransparency", part.Transparency)
    part.Parent = folder

    if anchorPart and anchorPart:IsA("BasePart") then
        registerVisual(anchorPart, part)
        part.Massless = true
        local compactRoute = tonumber(anchorPart:GetAttribute("RouteTier")) ~= nil
        local weld = Instance.new(compactRoute and "Weld" or "WeldConstraint")
        weld.Name = "PlatformIdentityWeld"
        weld.Part0 = part
        weld.Part1 = anchorPart
        if compactRoute then
            weld.C0 = CFrame.identity
            weld.C1 = anchorPart.CFrame:ToObjectSpace(part.CFrame)
        end
        weld.Parent = part
    end

    return part
end

local function decorateClassic(platform, index, theme, tier)
    local top = platform.CFrame * CFrame.new(0, PlatformFinishKit.surfacePaintOffset(platform, 0.05), 0)
    local length = math.max(2.6, math.min(platform.Size.X, platform.Size.Z) * 0.56)
    -- Quiet calibration engraving: it shows deck construction, not a
    -- suggested jump. Reserve the distinctive cool-white Neon chevrons
    -- exclusively for geometry-verified parkour takeoffs.
    local transparency = tier.Name == "Low" and 0.48 or 0.29

    makePart(
        "ClassicPlatformAxisA" .. index,
        Vector3.new(length, 0.045, 0.16),
        top,
        theme.Detail:Lerp(theme.Structure, index % 2 == 0 and 0.38 or 0.28),
        Enum.Material.Metal,
        transparency,
        platform
    )

    if tier.Name == "High" then
        makePart(
            "ClassicPlatformAxisB" .. index,
            Vector3.new(0.16, 0.045, length),
            top,
            theme.Detail,
            Enum.Material.Metal,
            0.28,
            platform
        )
    end
end

local function decorateTowers(platform, index, theme, tier)
    local bottom = platform.CFrame * CFrame.new(0, -platform.Size.Y * 0.5 - 0.18, 0)
    local radius = math.max(2.0, math.min(platform.Size.X, platform.Size.Z) * 0.28)

    local core = makePart(
        "TowerPlatformLiftCore" .. index,
        Vector3.new(radius, 0.24, radius),
        -- Establish the final cylinder orientation BEFORE welding it
        -- to the authoritative platform. Rotating an already-welded
        -- Part can fight the constraint and move/snaps its assembly.
        bottom * CFrame.Angles(0, 0, math.rad(90)),
        index % 2 == 0 and theme.Secondary or theme.Accent,
        tier.Name == "High" and index % 3 == 1 and Enum.Material.Neon or Enum.Material.Metal,
        tier.Name == "High" and index % 3 == 1 and 0.48 or (tier.Name == "Low" and 0.36 or 0.22),
        platform
    )
    core.Shape = Enum.PartType.Cylinder

    if tier.Name == "High" and platform.Position.Y >= 10 then
        makePart(
            "TowerPlatformBrace" .. index,
            Vector3.new(
                math.max(3.2, platform.Size.X * 0.58),
                0.32,
                math.max(0.7, platform.Size.Z * 0.12)
            ),
            platform.CFrame * CFrame.new(0, -platform.Size.Y * 0.5 - 0.42, 0),
            theme.Structure:Lerp(theme.Detail, 0.20),
            Enum.Material.DiamondPlate,
            0.18,
            platform
        )
    end
end

local function decorateCrossroads(platform, index, theme, tier, arenaCenter)
    local center = platform.CFrame * CFrame.new(0, PlatformFinishKit.surfacePaintOffset(platform, 0.05), 0)
    local arenaDelta = Vector3.new(
        platform.Position.X - arenaCenter.X,
        0,
        platform.Position.Z - arenaCenter.Z
    )
    local alongX = math.abs(arenaDelta.X) >= math.abs(arenaDelta.Z)
    local length = alongX and platform.Size.X or platform.Size.Z
    local size = alongX
        and Vector3.new(math.max(2.5, length * 0.64), 0.05, 0.24)
        or Vector3.new(0.24, 0.05, math.max(2.5, length * 0.64))

    makePart(
        "CrossroadPlatformLane" .. index,
        size,
        center,
        theme.Detail:Lerp(theme.Structure, 0.35),
        Enum.Material.Metal,
        tier.Name == "Low" and 0.48 or 0.30,
        platform
    )

    if tier.Name == "High" then
        local capOffset = alongX
            and Vector3.new(0, 0, platform.Size.Z * 0.30)
            or Vector3.new(platform.Size.X * 0.30, 0, 0)
        local capSize = alongX
            and Vector3.new(math.max(2.0, platform.Size.X * 0.34), 0.045, 0.13)
            or Vector3.new(0.13, 0.045, math.max(2.0, platform.Size.Z * 0.34))

        for side = -1, 1, 2 do
            makePart(
                "CrossroadPlatformBranch" .. index .. "_" .. tostring(side),
                capSize,
                center * CFrame.new(
                    capOffset.X * side,
                    0,
                    capOffset.Z * side
                ),
                theme.Detail,
                Enum.Material.Metal,
                0.30,
                platform
            )
        end
    end
end

local function decorateOrbital(platform, index, theme, tier, arenaCenter)
    local radial = Vector3.new(
        platform.Position.X - arenaCenter.X,
        0,
        platform.Position.Z - arenaCenter.Z
    )
    if radial.Magnitude < 0.1 then
        radial = Vector3.new(1, 0, 0)
    else
        radial = radial.Unit
    end

    local tangent = Vector3.new(-radial.Z, 0, radial.X)
    local yaw = math.atan2(-tangent.Z, tangent.X)
    local center = CFrame.new(
        platform.Position + Vector3.new(0, PlatformFinishKit.surfacePaintOffset(platform, 0.05), 0)
    ) * CFrame.Angles(0, yaw, 0)

    local length = math.max(2.6, math.min(platform.Size.X, platform.Size.Z) * 0.70)
    makePart(
        "OrbitalPlatformTangent" .. index,
        Vector3.new(length, 0.05, 0.22),
        center,
        -- All orbital deck tangents are material markings, not glowing
        -- jump arrows (Orbital climbs by actual continuous helix ramps).
        theme.Detail:Lerp(theme.Structure, index % 2 == 0 and 0.32 or 0.46),
        Enum.Material.Metal,
        tier.Name == "Low" and 0.43 or 0.25,
        platform
    )

    if tier.Name ~= "Low" then
        local innerOffset = radial * -math.min(platform.Size.X, platform.Size.Z) * 0.22
        makePart(
            "OrbitalPlatformInnerRail" .. index,
            Vector3.new(length * 0.56, 0.045, 0.12),
            center + innerOffset,
            theme.Detail,
            Enum.Material.Glass,
            tier.Name == "High" and 0.40 or 0.52,
            platform
        )
    end
end

-- Storm Harbor needs a recognizable timber quay on each genuine
-- jumpable platform, not Classic's calibration-axis neon. Keep the
-- additional detailing off Low-tier touch phones; core Harbor finish
-- pieces, takeoff chevrons and physical panels still display normally.
-- All pieces are inside the real deck, linked to its shrink footprint
-- and inherit collapse visibility from the existing single owner.
local function decorateHarbor(platform, index, theme, tier)
    if tier.Name == "Low" then return end
    local width = math.min(platform.Size.X, platform.Size.Z)
    if width < 4.5 then return end
    local top = PlatformFinishKit.surfacePaintOffset(platform, 0.045)
    local hardware = theme.Structure:Lerp(
        Color3.fromRGB(114, 101, 89), 0.38
    )
    -- Short offset cargo lashing stripe is an intentionally incomplete
    -- crossbar, NOT a fake bridge or hazard arrow.
    makePart(
        "HarborCargoLashing" .. index,
        Vector3.new(math.min(platform.Size.X * 0.55, 6.8), 0.045, 0.24),
        platform.CFrame * CFrame.new(
            0, top, platform.Size.Z * 0.26
        ),
        hardware,
        Enum.Material.CorrodedMetal,
        0.26,
        platform
    )
    if tier.Name == "High" then
        makePart(
            "HarborKeelMount" .. index,
            Vector3.new(
                math.min(platform.Size.X * 0.58, 7.0),
                0.27,
                math.min(platform.Size.Z * 0.22, 1.8)
            ),
            platform.CFrame * CFrame.new(
                0, -platform.Size.Y * 0.5 - 0.23, 0
            ),
            theme.Detail:Lerp(hardware, 0.58),
            Enum.Material.WoodPlanks,
            0.13,
            platform
        )
    end
end

-- Mark only geometry-verified ascending routes. The two short chevron
-- strokes are fully inside the takeoff deck, welded to its real footprint.
-- Existing collapse and shrink listeners own all visibility/resize work.
local function decorateTakeoff(platform, target, index, theme, quality)
    local frame = JumpRouteCueRules.takeoffFrame(
        platform, target, PlatformFinishKit.surfacePaintOffset(platform, 0.05) + 0.025
    )
    if not frame then return end
    local strokes = {}
    -- The verified safe route is restrained cool-white across all arenas;
    -- collapse/hazard warnings remain the more urgent amber/orange cue.
    -- Enlarge only these TWO existing strokes, not their part count.
    local opacity = quality.Name == "Low" and 0.34 or 0.43
    local color = Color3.fromRGB(185, 236, 239):Lerp(theme.Accent, 0.24)
    for side = -1, 1, 2 do
        local piece = makePart(
            "ParkourTakeoffChevron" .. index .. "_" .. tostring(side),
            Vector3.new(0.15, 0.045, 1.02),
            frame * CFrame.new(side * 0.28, 0, 0.14)
                * CFrame.Angles(0, math.rad(side * 38), 0),
            color,
            Enum.Material.Neon,
            opacity,
            platform
        )
        strokes[#strokes + 1] = piece
    end
    routeCueStates[platform] = {target = target, strokes = strokes}
end

local function syncTakeoff(platform, center, variant)
    local cue = routeCueStates[platform]
    if not cue then return end
    -- A shrinking deck can retain collision but lose the original gap:
    -- do not continue to advertise a now-impossible jump on Android.
    local valid = JumpRouteCueRules.cueStillSafe(
        platform, cue.target, center, variant
    )
    for _, stroke in ipairs(cue.strokes) do
        if stroke.Parent then
            stroke.Transparency = valid
                and stroke:GetAttribute("ChaosBaseTransparency") or 1
        end
    end
end

local scheduleRebuild

local function rebuild()
    clear()

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not arena or not platforms or not base or not base:IsA("BasePart") then
        return
    end

    local variant = tostring(arena:GetAttribute("VariantId") or "Classic")
    local theme = VisualTheme.arena(variant)
    local tier = VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"), UserInputService.TouchEnabled)
    local index = 0
    local replacements = {}
    local actualSupportParts = {}
    -- Original large structures use the same existing owner/census:
    -- limit source-authenticated modules, not "platform" count, to
    -- prevent a single 40-stud pillar silently spending the whole budget.
    local supportBudget = tier.Name == "High" and 16
        or (tier.Name == "Medium" and 8
            or ((tonumber(player:GetAttribute("OptionalVfxPressure")) or 0)
                == 0 and 1 or 0))
    local longCradleBudget = tier.Name == "High" and 4
        or (tier.Name == "Medium" and 2
            or ((tonumber(player:GetAttribute("OptionalVfxPressure")) or 0)
                == 0 and 1 or 0))
    local originalLargeCount = 0
    local decor = arena:FindFirstChild("Decor")
    local ordered = PlatformFinishKit.orderedPlatforms(platforms)
    local camera = workspace.CurrentCamera
    local cameraPoint = camera and camera.CFrame.Position or nil
    local cameraLook = camera and camera.CFrame.LookVector or nil
    -- Collect already provenance-checked candidates BEFORE spending the
    -- fixed Low 3D budget. An eligible bridge 120 studs away must not
    -- suppress a genuine relief/hull directly under the player's feet.
    local nearBridgeGirders = PremiumPlatformSideMeshKit.selectBridgeGirders(
        ordered, tier.Name, base, cameraPoint, cameraLook,
        player:GetAttribute("OptionalVfxPressure"))
    local nearCameraCarapaces = PremiumPlatformSideMeshKit.selectCarapaceDecks(
        ordered, variant, tier.Name, base, cameraPoint, cameraLook,
        player:GetAttribute("OptionalVfxPressure"))
    local lowHubDeck = tier.Name == "Low"
        and PremiumLargeDeckHullMeshKit.selectLowDeck(
            ordered, base, cameraPoint,
            player:GetAttribute("OptionalVfxPressure")) or nil
    local nearServiceHatches = PlatformFinishKit.selectOriginalServiceHatches(
        ordered, variant, tier.Name, base, cameraPoint, cameraLook,
        player:GetAttribute("OptionalVfxPressure"))

    -- Low visual source reservation is an actual successful MODEL mount,
    -- never a speculative source/size check. A missing or malformed clone
    -- must release its exclusive budget for the next approved art family
    -- rather than leaving the player's hero deck with only native blocks.
    -- Staged pieces enter the SAME folder, registrar and shrink/collapse
    -- owner below. One foreground model OR one two-sided bridge model;
    -- no second owner, retained hidden duplicates or new frame sampler.
    local lowPreMounted = {}
    if tier.Name == "Low" then
        local function nearest(set)
            local chosen, distance = nil, math.huge
            if typeof(cameraPoint) ~= "Vector3" then
                return chosen, distance
            end
            for platform in pairs(set) do
                if platform.Parent == platforms then
                    local d = (platform.Position - cameraPoint).Magnitude
                    if d < distance or (d == distance
                        and chosen and platform.Name < chosen.Name) then
                        chosen, distance = platform, d
                    end
                end
            end
            return chosen, distance
        end
        -- Only four mutually exclusive genuine original families exist.
        -- At most four bounded attempts on a map/tier/pressure rebuild.
        for _ = 1, 4 do
            local bridge, bridgeDistance = nearest(nearBridgeGirders)
            local carapace, carapaceDistance = nearest(nearCameraCarapaces)
            local hatch, hatchDistance = nearest(nearServiceHatches)
            local hullDistance = lowHubDeck
                and typeof(cameraPoint) == "Vector3"
                and (lowHubDeck.Position-cameraPoint).Magnitude or math.huge
            local foregroundDistance = math.min(
                carapaceDistance, hatchDistance, hullDistance)
            local choice, target = nil, nil
            if bridge and (foregroundDistance == math.huge
                or bridgeDistance <= foregroundDistance + 16) then
                choice, target = "bridge", bridge
            else
                local hatchScore = hatchDistance
                if typeof(cameraLook) == "Vector3"
                    and cameraLook.Y < -0.50 then
                    hatchScore -= 12
                end
                -- The full 18x18 sculpted hub remains the important
                -- silhouette at equal distance. A strongly top-down
                -- near hatch gets its previously selected visibility bias.
                if lowHubDeck and hullDistance <= math.min(
                    carapaceDistance + 12, hatchScore + 12) then
                    choice, target = "hull", lowHubDeck
                elseif carapace and carapaceDistance <= hatchScore + 8 then
                    choice, target = "carapace", carapace
                elseif hatch then
                    choice, target = "hatch", hatch
                end
            end
            if not target then break end
            local id = PlatformFinishKit.visualIndex(target, 1)
            local pieces = nil
            if choice == "bridge" then
                pieces = PremiumPlatformSideMeshKit.bridgeGirders(
                    folder, target, tier.Name, id, true)
            elseif choice == "hull" then
                pieces = PremiumLargeDeckHullMeshKit.install(
                    folder, target, tier.Name, id, true)
            elseif choice == "carapace" then
                pieces = PremiumPlatformSideMeshKit.carapace(
                    folder, target, variant, tier.Name, id, true)
            else
                pieces = PlatformFinishKit.buildServiceHatch(
                    folder, target, variant, tier.Name, theme, id, true)
            end
            local expected = choice == "bridge" and 14 or 7
            if pieces and #pieces == expected then
                -- Exactly one successful source family was published.
                -- These are not throwaway tests: later platform traversal
                -- adopts the ALREADY-MOUNTED parts without cloning again.
                lowPreMounted[target] = {kind = choice, parts = pieces}
                nearBridgeGirders = choice == "bridge"
                    and {[target] = true} or {}
                nearCameraCarapaces = choice == "carapace"
                    and {[target] = true} or {}
                nearServiceHatches = choice == "hatch"
                    and {[target] = true} or {}
                lowHubDeck = choice == "hull" and target or nil
                break
            end
            -- A successful full source must be atomic; never retain
            -- partial 3D bundles or spent budget from a failed mount.
            for _, piece in ipairs(pieces or {}) do
                piece:Destroy()
            end
            if choice == "bridge" then
                nearBridgeGirders = {}
            elseif choice == "hull" then
                lowHubDeck = nil
            elseif choice == "carapace" then
                nearCameraCarapaces = {}
            else
                nearServiceHatches = {}
            end
        end
        if next(lowPreMounted) == nil then
            nearBridgeGirders = {}
            nearCameraCarapaces = {}
            nearServiceHatches = {}
            lowHubDeck = nil
        end
    end
    local lowBridgeChosen = tier.Name == "Low"
        and next(nearBridgeGirders) ~= nil
    local mountedBridgeGirders = 0
    local mountedCameraCarapaces = 0
    local mountedLowHubHulls = 0
    local mountedServiceHatches3D = 0
    local nearCradles,nearSupports={},{}
    if not lowBridgeChosen then
        nearCradles,nearSupports =
            PremiumLargeStructureMeshKit.selectNearRouteStructures(
                ordered,decor,variant,tier.Name,base,
                camera and camera.CFrame.Position or nil,
                camera and camera.CFrame.LookVector or nil,
                player:GetAttribute("OptionalVfxPressure"))
    end
    -- One 14-piece bridge OR two 7-piece Low structural slots,
    -- never both. Medium/High unchanged.
    if lowBridgeChosen then
        longCradleBudget = 0
        supportBudget = 0
    elseif tier.Name == "Low" and next(nearCradles) ~= nil then
        supportBudget = 0
    end
    local mountedRouteCradles = 0
    local mountedCloseSupports = 0

    for _, platform in ipairs(ordered) do
        if platform:IsA("BasePart") then
            index += 1
            local visualIndex = PlatformFinishKit.visualIndex(platform, index)

            -- The physical deck may stream before its RouteTier attribute.
            -- Rebuild once the replicated metadata arrives so the first
            -- streamed-in ornaments use resizable Welds, not rigid
            -- WeldConstraints that could imply ghost ledges while shrinking.
            if platform.Name:match("^Platform%d+$")
                and tonumber(platform:GetAttribute("RouteTier")) == nil then
                routeAttributeConnections[platform] =
                    platform:GetAttributeChangedSignal("RouteTier"):Connect(function()
                        scheduleRebuild()
                    end)
            end
            -- The 16 appended Harbor terminals can stream in with their
            -- RouteTier already present but one or both spoke attributes
            -- still pending. Subscribe ONLY to the known four-by-four
            -- appended index range (95..110); do not add 220 listeners
            -- to every older Harbor platform or invent a polling loop.
            if variant == "Harbor"
                and visualIndex >= 95 and visualIndex <= 110
                and (platform:GetAttribute("HarborSpokeRoute") == nil
                    or platform:GetAttribute("HarborSpokeStep") == nil) then
                outpostAttributeConnections[platform] = {
                    platform:GetAttributeChangedSignal("HarborSpokeRoute")
                        :Connect(function() scheduleRebuild() end),
                    platform:GetAttributeChangedSignal("HarborSpokeStep")
                        :Connect(function() scheduleRebuild() end),
                }
            end
            -- Low keeps half-density native surface paint, but a real
            -- selected original undercradle or support MUST be allowed
            -- through this guard even on an EVEN-index physical PlatformN.
            -- Previously selection happened above but this gate silently
            -- skipped the genuine 7-MeshPart install (and its native trim
            -- masking), wasting Low's one scarce structural source slot.
            -- The native PlatformFinishKit.build remains independently
            -- half-density below; gameplay takeoff cues are unaffected.
            if tier.Name ~= "Low" or visualIndex % 2 ~= 0
                or nearBridgeGirders[platform] == true
                or nearServiceHatches[platform] == true
                or nearCradles[platform] == true
                or nearSupports[platform] == true then
            -- A camera-selected original bridge, hatch, undercradle or
            -- support can sit on an EVEN-index physical deck. Register the
            -- true art without reintroducing omitted native Low paint.
            if tier.Name ~= "Low" or visualIndex % 2 ~= 0 then
                for _, piece in ipairs(PlatformFinishKit.build(
                    folder, platform, variant, tier.Name, theme
                )) do
                    registerVisual(platform, piece)
                end
            end
            -- Build authentic 3D structural art first. If it succeeds,
            -- completely avoid the native WedgePart armor/brace/rail layers
            -- that previously occupied the SAME physical deck silhouette.
            -- Native fallback is still built in full if a real mesh is
            -- unavailable, unsuitable for this deck, or fails to load.
            -- The authored 18x18 central hub needs its own full-size
            -- original hull, not a tiny 10-stud carapace scaled up as a
            -- decorative sticker. Fallback remains the established kit.
            local staged = lowPreMounted[platform]
            local largeHullPieces = (staged and staged.kind == "hull"
                and staged.parts) or PremiumLargeDeckHullMeshKit.install(
                    folder, platform, tier.Name, visualIndex,
                    tier.Name == "Low" and platform == lowHubDeck)
            if tier.Name == "Low" and largeHullPieces then
                mountedLowHubHulls += 1
            end
            local carapacePieces = largeHullPieces
                or (staged and staged.kind == "carapace" and staged.parts)
                or PlatformFinishKit.buildCarapace(
                    folder, platform, variant, tier.Name, theme, visualIndex,
                    nearCameraCarapaces[platform] == true)
            if carapacePieces[1] and carapacePieces[1]:GetAttribute(
                "NearCameraCarapace3D") == true then
                mountedCameraCarapaces += 1
            end
            local authenticCarapace = carapacePieces[1] ~= nil
                and carapacePieces[1]:GetAttribute(
                    "Original3DStructuralSide") == true
            local sidePieces = {}
            if not authenticCarapace then
                sidePieces = (staged and staged.kind == "bridge"
                    and staged.parts) or PlatformFinishKit.buildSideRails(
                    folder, platform, tier.Name, theme, variant, visualIndex,
                    nearBridgeGirders[platform] == true)
            end
            local authenticBridge = sidePieces[1] ~= nil
                and sidePieces[1]:GetAttribute(
                    "Original3DStructuralSide") == true
            if authenticCarapace then
                replacements[tostring(visualIndex)] = "carapace"
            elseif authenticBridge then
                replacements[tostring(visualIndex)] = "bridge"
                mountedBridgeGirders += 1
            end
            if not authenticCarapace and not authenticBridge then
                for _, piece in ipairs(PlatformFinishKit.buildArmor(
                    folder, platform, variant, tier.Name, theme
                )) do
                    registerVisual(platform, piece)
                end
            end
            for _, piece in ipairs(sidePieces) do
                registerVisual(platform, piece)
            end
            if not authenticCarapace and not authenticBridge then
                for _, piece in ipairs(PlatformFinishKit.buildLoadBraces(
                    folder, platform, variant, tier.Name, theme
                )) do
                    registerVisual(platform, piece)
                end
            end
            -- Textured-looking three-layer native hardware on a strictly
            -- bounded subset of actual jump decks. Shares this existing
            -- platform's weld, collapse visibility and shrinking footprint.
            local hatchPieces = (staged and staged.kind == "hatch"
                and staged.parts) or PlatformFinishKit.buildServiceHatch(
                folder, platform, variant, tier.Name, theme, visualIndex,
                nearServiceHatches[platform] == true)
            -- Only count a COMPLETE, actually mounted verified 3D source;
            -- three-piece native fallback does not count as imported art.
            if hatchPieces[1] and hatchPieces[1]:IsA("MeshPart")
                and hatchPieces[1]:GetAttribute("OriginalServiceHatch3D")
                    == true then
                mountedServiceHatches3D += 1
            end
            for _, piece in ipairs(hatchPieces) do
                registerVisual(platform, piece)
            end

            -- Long elevated promenades and the Sky Spine previously
            -- rested on a solid, square server underframe. Swap up to
            -- 1/2 compatible decks to the real sculpted 22-stud lattice,
            -- only after exact owner provenance and dimensions are checked.
            -- It follows RouteTier shrink via the existing welded snapshot.
            if longCradleBudget > 0 and not authenticCarapace
                and nearCradles[platform] == true then
                local cradle = PremiumLargeStructureMeshKit.longCradle(
                    folder, platform, tier.Name, visualIndex, true)
                if cradle then
                    replacements[tostring(visualIndex)] = "cradle"
                    -- Shared cosmetic-only arbitration prevents the old
                    -- 3K-triangle underdeck chassis from being mounted
                    -- behind this newer genuine open-frame undercradle.
                    -- Client-local attribute NEVER grants a gameplay route.
                    platform:SetAttribute("LocalOriginalLongCradleMounted", true)
                    mountedLongCradles[platform] = true
                    longCradleBudget -= 1
                    mountedRouteCradles += 1
                    for _, piece in ipairs(cradle) do
                        registerVisual(platform, piece)
                        originalLargeCount += 1
                    end
                end
            end
            -- Actual server-authored PlatformSupport instances, NOT new
            -- phantom load-bearing routes, own authentic tall columns.
            -- One sparse support family per map/tier, at most 8/16
            -- source-model segments (7 MeshParts each). The existing
            -- CollapsePhase visual registrar hides them on warning/gone.
            if supportBudget > 0 and decor
                and nearSupports[platform] == true then
                local columns = PremiumLargeStructureMeshKit.supports(
                    folder, decor, platform, variant, tier.Name,
                    visualIndex, supportBudget, true)
                if columns then
                    supportBudget -= columns.modules
                    mountedCloseSupports += #columns.covered
                    for _, support in ipairs(columns.covered) do
                        actualSupportParts[#actualSupportParts+1] = support
                        mountedSupportNatives[support] = true
                    end
                    for _, connection in ipairs(columns.disconnects) do
                        originalColumnDisconnects[#originalColumnDisconnects+1] =
                            connection
                    end
                    for _, piece in ipairs(columns.parts) do
                        registerVisual(platform, piece)
                        originalLargeCount += 1
                    end
                end
            end
            -- New authentic MeshParts and native carapace fallback both
            -- enter the EXISTING collapse/shrink snapshot and visibility owner.
            for _, piece in ipairs(carapacePieces) do
                registerVisual(platform, piece)
            end

            if variant == "Towers" then
                decorateTowers(platform, visualIndex, theme, tier)
            elseif variant == "Crossroads" then
                decorateCrossroads(platform, visualIndex, theme, tier, base.Position)
            elseif variant == "Orbital" then
                decorateOrbital(platform, visualIndex, theme, tier, base.Position)
            elseif variant == "Harbor" then
                decorateHarbor(platform, visualIndex, theme, tier)
                -- Only the four real cardinal terminal decks get authored
                -- 3D port infrastructure. The existing visual registrar,
                -- shrink-weld, collapse owner and tier rebuild own it.
                -- No new scene loop, world physics or touch occlusion.
                local _, instrument = HarborOutpostKit.build(
                    makePart, platform, visualIndex, theme, tier.Name
                )
                if instrument then
                    local joint = instrument:FindFirstChild(
                        "PlatformIdentityWeld"
                    )
                    if joint and joint:IsA("Weld") then
                        outpostMotions[platform] = {
                            joint = joint,
                            instrument = instrument,
                            baseColor = instrument.Color,
                            route = platform:GetAttribute("HarborSpokeRoute"),
                            connections = {
                                platform:GetPropertyChangedSignal("CanCollide")
                                    :Connect(function()
                                        refreshOutpostMotion(platform)
                                    end),
                                platform:GetPropertyChangedSignal("Transparency")
                                    :Connect(function()
                                        refreshOutpostMotion(platform)
                                    end),
                            },
                        }
                    end
                end
            elseif variant == "Classic" then
                decorateClassic(platform, visualIndex, theme, tier)
            end
            end

            -- Orbital uses continuous physical Helix ramps instead of
            -- jumping between these deck tiers; no false route arrows.
            local target = JumpRouteCueRules.select(
                platform, ordered, base.Position, variant
            )
            if target then
                decorateTakeoff(platform, target, visualIndex, theme, tier)
            end

            -- Permanent Tower skybridges shorten during Shrinking Arena.
            -- Their welded client trims must track the authoritative span
            -- without regenerating geometry, allocating new Parts or polling.
            if platform:GetAttribute("ChaosSkybridge") == true then
                footprintDisconnects[platform] =
                    PlatformFinishKit.bindSkybridgeFootprint(
                        platform, visualsByPlatform[platform]
                    )
            elseif tonumber(platform:GetAttribute("RouteTier")) ~= nil then
                -- All visible Classic trims track the physical footprint as
                -- Shrinking Arena contracts both axes. No ghost ledges.
                footprintDisconnects[platform] =
                    PlatformFinishKit.bindRouteFootprint(
                        platform, visualsByPlatform[platform]
                    )
            end

            -- A platform can enter while already Gone (streaming/late
            -- replication) or switch phase after the visuals are built.
            local function syncRoute()
                syncTakeoff(platform, base.Position, variant)
            end
            local function syncCollapse()
                local pieces=visualsByPlatform[platform]
                PlatformFinishKit.applyCollapseVisibility(
                    pieces, platform:GetAttribute("CollapsePhase")
                )
                -- BridgeShutterPhase is independent from CollapsePhase.
                -- The genuine sculpted girders are cosmetic and must
                -- immediately leave the server's physical warning/
                -- closing shutter visible, even without a collapse.
                if platform:GetAttribute("ChaosSkybridge")==true then
                    local shutter=platform:GetAttribute("BridgeShutterPhase")
                    if shutter and shutter~="Idle" then
                        for _,piece in ipairs(pieces or {}) do
                            if piece.Parent and piece:IsA("MeshPart")
                                and piece:GetAttribute(
                                    "Original3DStructuralSide")==true then
                                piece.Transparency=1
                            end
                        end
                    end
                end
                syncRoute()
                refreshOutpostMotion(platform)
            end
            collapseConnections[platform] =
                platform:GetAttributeChangedSignal("CollapsePhase"):Connect(syncCollapse)
            if platform:GetAttribute("ChaosSkybridge")==true then
                bridgeShutterConnections[platform] =
                    platform:GetAttributeChangedSignal("BridgeShutterPhase")
                        :Connect(syncCollapse)
            end
            if target then
                -- Size can shrink without any CollapsePhase change.
                -- These events only refresh the two route strokes;
                -- the larger decorative fade remains phase-triggered.
                routeTargetConnections[platform] = {
                    platform:GetPropertyChangedSignal("Size"):Connect(syncRoute),
                    platform:GetPropertyChangedSignal("CanCollide"):Connect(syncRoute),
                    platform:GetPropertyChangedSignal("Transparency"):Connect(syncRoute),
                    target:GetAttributeChangedSignal("CollapsePhase"):Connect(syncRoute),
                    target:GetPropertyChangedSignal("Size"):Connect(syncRoute),
                    target:GetPropertyChangedSignal("CanCollide"):Connect(syncRoute),
                    target:GetPropertyChangedSignal("Transparency"):Connect(syncRoute),
                }
            end
            syncCollapse()
        end
    end
    -- Once genuine owner-approved MeshParts are fully built, mask ONLY
    -- corresponding nonphysical server WedgePart/underframe/bridge ribs.
    -- This preserves all gameplay lights, warning rails, platforms and
    -- the original fallback in the server. Streams are handled by its
    -- Folder.ChildAdded observer with exact name/index provenance.
    -- Genuine mounted 22-stud bridge interchanges and real columns,
    -- counted only after the complete MeshPart source is committed.
    if player:GetAttribute("LocalOriginalNearBridgeCradleCount")
        ~= mountedRouteCradles then
        player:SetAttribute("LocalOriginalNearBridgeCradleCount",
            mountedRouteCradles)
    end
    if player:GetAttribute("LocalOriginalNearSupportColumnCount")
        ~= mountedCloseSupports then
        player:SetAttribute("LocalOriginalNearSupportColumnCount",
            mountedCloseSupports)
    end
    -- Actual successful true-3D structural shell count, not the number
    -- of requested candidates; persisted only as client diagnostics.
    if player:GetAttribute("LocalOriginalNearRouteCarapaceCount")
        ~= mountedCameraCarapaces then
        player:SetAttribute("LocalOriginalNearRouteCarapaceCount",
            mountedCameraCarapaces)
    end
    if player:GetAttribute("LocalOriginalLowHubHullCount")
        ~= mountedLowHubHulls then
        player:SetAttribute("LocalOriginalLowHubHullCount",
            mountedLowHubHulls)
    end
    if player:GetAttribute("LocalOriginalNearBridgeGirderCount")
        ~= mountedBridgeGirders then
        player:SetAttribute("LocalOriginalNearBridgeGirderCount",
            mountedBridgeGirders)
    end
    if player:GetAttribute("LocalOriginalServiceHatch3DCount")
        ~= mountedServiceHatches3D then
        player:SetAttribute("LocalOriginalServiceHatch3DCount",
            mountedServiceHatches3D)
    end
    PlatformNativeTrimReplacementKit.bind(
        arena, replacements, function(nativeCount)
            if player:GetAttribute("LocalNativeStructuralPartsReplaced")
                ~= nativeCount then
                player:SetAttribute("LocalNativeStructuralPartsReplaced",
                    nativeCount)
            end
        end, actualSupportParts, folder)
    if player:GetAttribute("LocalOriginalLargeStructure3DCount")
        ~= originalLargeCount then
        player:SetAttribute("LocalOriginalLargeStructure3DCount",
            originalLargeCount)
    end
    -- Count genuine moderated structural MeshParts on this one active map.
    -- Attribute is diagnostic only, never used to control physics or tier.
    local genuineCount = 0
    for _, piece in ipairs(folder:GetChildren()) do
        if piece:IsA("MeshPart")
            and piece:GetAttribute("Original3DStructuralSide") == true then
            genuineCount += 1
        end
    end
    if player:GetAttribute("LocalOriginalPlatformSideMeshPartCount")
        ~= genuineCount then
        player:SetAttribute("LocalOriginalPlatformSideMeshPartCount", genuineCount)
    end
end

local disconnectBaseWatch = nil
local disconnectPlatformsWatch = nil
local disconnectDecorWatch = nil
local platformsConnection = nil
local platformsRemoveConnection = nil
local decorAddedConnection = nil
local decorRemovedConnection = nil
local watchedPlatforms = nil
local watchedDecor = nil
local watchedMap = nil
local rebuildPending = false
local decorRebuildPending = false
local decorGeneration = 0

scheduleRebuild = function()
    if rebuildPending then return end
    rebuildPending = true
    -- The 320x320 arena can replicate hundreds of Platforms in separate
    -- network batches. Rebuilding the full 3D weld owner once per defer
    -- caused first-join Android churn. A single short scheduled batch
    -- preserves late-source recovery without an update/render loop.
    task.delay(0.12, function()
        rebuildPending = false
        rebuild()
    end)
end

-- Support posts arrive as many independently streamed cosmetic Parts.
-- Batch only relevant real PlatformSupportN_K changes into ONE owner
-- rebuild, rather than re-creating the entire visual map for every
-- streamed bolt, rail, warning or server detail.
local function queueSupportRebuild()
    if decorRebuildPending then return end
    decorRebuildPending = true
    local generation = decorGeneration
    task.delay(0.18, function()
        if generation ~= decorGeneration then return end
        decorRebuildPending = false
        scheduleRebuild()
    end)
end

local function watchDecor(generated)
    local arena = generated and generated:FindFirstChild("Arena")
    local decor = arena and arena:FindFirstChild("Decor")
    if decor == watchedDecor then return end
    if decorAddedConnection then decorAddedConnection:Disconnect() end
    if decorRemovedConnection then decorRemovedConnection:Disconnect() end
    decorAddedConnection = nil
    decorRemovedConnection = nil
    watchedDecor = decor
    decorGeneration += 1
    decorRebuildPending = false
    if decor and decor:IsA("Folder") then
        local function supportChanged(part)
            -- Low used to ignore ALL late native support arrivals.
            -- If the 7-MeshPart approved model had already streamed in,
            -- first-join could remain rectangular forever. Recover only
            -- one camera-near, genuine support on healthy Low; no global
            -- rebuild for hundreds of faraway streamed posts.
            if not part:IsA("BasePart")
                or not part.Name:match("^PlatformSupport%d+_%d+$") then
                return
            end
            local templates = ReplicatedStorage:FindFirstChild(
                "ApprovedLargeStructureTemplates")
            local activeArena = workspace:FindFirstChild("GeneratedMap")
            activeArena = activeArena and activeArena:FindFirstChild("Arena")
            local variant = activeArena and tostring(
                activeArena:GetAttribute("VariantId") or "Classic")
            if not templates or not variant
                or not templates:FindFirstChild(variant) then return end
            local quality = VfxQuality.deviceTier(
                player:GetAttribute("VfxQualityTier"),
                UserInputService.TouchEnabled).Name
            if quality == "Low" then
                -- The one original column may outlive its streamed-out
                -- native source Part: rebuild ONLY if it was truly covered.
                -- Faraway unrelated removals do not cause full-map churn.
                if part.Parent ~= decor then
                    if mountedSupportNatives[part] == true then
                        queueSupportRebuild()
                    end
                    return
                end
                -- No churn while pressure has already demoted optional 3D,
                -- or when this owner has spent its one Low support slot.
                if (tonumber(player:GetAttribute("OptionalVfxPressure")) or 0) > 0
                    or (tonumber(player:GetAttribute(
                        "LocalOriginalNearSupportColumnCount")) or 0) > 0 then
                    return
                end
                local index = part.Name:match(
                    "^PlatformSupport(%d+)_%d+$")
                local platforms = activeArena and
                    activeArena:FindFirstChild("Platforms")
                local deck = platforms and
                    platforms:FindFirstChild("Platform"..tostring(index))
                local camera = workspace.CurrentCamera
                if not deck or not deck:IsA("BasePart")
                    or not deck.CanCollide or not camera
                    or (deck.Position-camera.CFrame.Position).Magnitude > 125 then
                    return
                end
            end
            queueSupportRebuild()
        end
        decorAddedConnection = decor.ChildAdded:Connect(supportChanged)
        decorRemovedConnection = decor.ChildRemoved:Connect(supportChanged)
    end
end

local function watchPlatforms(generated)
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms == watchedPlatforms then return end
    if platformsConnection then platformsConnection:Disconnect() end
    if platformsRemoveConnection then platformsRemoveConnection:Disconnect() end
    platformsConnection = nil
    platformsRemoveConnection = nil
    watchedPlatforms = platforms
    if platforms then
        platformsConnection = platforms.ChildAdded:Connect(function(child)
            if child:IsA("BasePart") then scheduleRebuild() end
        end)
        platformsRemoveConnection = platforms.ChildRemoved:Connect(function(child)
            if child:IsA("BasePart") then scheduleRebuild() end
        end)
    end
end

local function bindGeneratedMap(generated)
    watchedMap = generated
    if disconnectBaseWatch then disconnectBaseWatch() end
    if disconnectPlatformsWatch then disconnectPlatformsWatch() end
    if disconnectDecorWatch then disconnectDecorWatch() end
    disconnectBaseWatch = nil
    disconnectPlatformsWatch = nil
    disconnectDecorWatch = nil
    watchPlatforms(nil)
    watchDecor(nil)
    if generated then
        disconnectBaseWatch = MapVisualReadiness.watch(
            generated, "Arena", "Base", function()
                watchPlatforms(generated)
                scheduleRebuild()
            end
        )
        -- The Platforms folder is not a BasePart. This second watch is used
        -- solely for its ChildAdded/Removed notifications and variant signal.
        disconnectPlatformsWatch = MapVisualReadiness.watch(
            generated, "Arena", "Platforms", function()
                watchPlatforms(generated)
                scheduleRebuild()
            end
        )
        -- Only the Decor folder's arrival/removal and actual physical
        -- support-post replication can affect genuine tall mesh columns.
        -- LongCradle underframes no longer wait for this folder at all.
        disconnectDecorWatch = MapVisualReadiness.watch(
            generated, "Arena", "Decor", function()
                watchDecor(generated)
                scheduleRebuild()
            end
        )
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap"
        and workspace:FindFirstChild("GeneratedMap") == child then
        bindGeneratedMap(child)
        scheduleRebuild()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))
        clear()
        scheduleRebuild()
    end
end)

bindGeneratedMap(workspace:FindFirstChild("GeneratedMap"))

-- The already existing RoundState message drives the port machinery
-- without another RemoteEvent, ticker or disaster polling task.
roundEvent.OnClientEvent:Connect(function(packet)
    -- A malformed/late payload resets to the calm authored posture rather
    -- than locking Harbor instruments in a stale disaster condition.
    if type(packet) ~= "table" then packet = nil end
    local posture = HarborOutpostKit.disasterPosture(
        packet and packet.disasterIds, packet and packet.phase
    )
    if posture == currentOutpostPosture then return end
    currentOutpostPosture = posture
    for platform in pairs(outpostMotions) do
        refreshOutpostMotion(platform)
    end
end)

-- Replication may deliver a Model before its owner/asset verification
-- attributes. ChildAdded alone leaves genuine 3D in primitive fallback
-- until a new map or camera sector arrives. Observe only the existing
-- approved template metadata, on the same bounded rebuild scheduler.
-- This is an event-driven recovery path, not a new polling/render loop.
local approvedTemplateNames = {
    Classic = true, Towers = true, Crossroads = true,
    Orbital = true, Harbor = true, Bridge = true,
    LongCradle = true, LargeDeckHull = true,
}
local function watchVerifiedTemplateReadiness(holder, connections, marker)
    if not holder or not holder:IsA("Folder") then return end
    connections[#connections + 1] = holder:GetAttributeChangedSignal(
        "OwnerVerified"):Connect(scheduleRebuild)
    local observed = {}
    local function attach(model)
        if not model:IsA("Model") or not approvedTemplateNames[model.Name]
            or observed[model] then return end
        observed[model] = true
        for _, attribute in ipairs({
            "OwnerVerified", "Original3DAssetId", "CosmeticOnly", marker,
        }) do
            connections[#connections + 1] =
                model:GetAttributeChangedSignal(attribute):Connect(function()
                    if model.Parent == holder then scheduleRebuild() end
                end)
        end
    end
    for _, model in ipairs(holder:GetChildren()) do attach(model) end
    connections[#connections + 1] = holder.ChildAdded:Connect(attach)
end

-- Original service hatches are loaded in a late server asset lane.
-- Rebuild the existing platform visual owner once the current arena's
-- approved model becomes available; otherwise first-join players would
-- retain native three-Part hatches until the next map transition.
-- Only model arrivals/removals matter; no polling or extra render loop.
local platformReliefTemplateConnections = {}
local currentPlatformReliefTemplates = nil
local function watchPlatformReliefTemplates(holder)
    if currentPlatformReliefTemplates == holder then return end
    for _, connection in ipairs(platformReliefTemplateConnections) do
        connection:Disconnect()
    end
    table.clear(platformReliefTemplateConnections)
    currentPlatformReliefTemplates = holder
    if holder and holder:IsA("Folder") then
        watchVerifiedTemplateReadiness(holder,
            platformReliefTemplateConnections, "OriginalFloorRelief3D")
        local function changed(child)
            local generated = workspace:FindFirstChild("GeneratedMap")
            local arena = generated and generated:FindFirstChild("Arena")
            local variant = arena and tostring(
                arena:GetAttribute("VariantId") or "Classic")
            if variant == child.Name then scheduleRebuild() end
        end
        platformReliefTemplateConnections[#platformReliefTemplateConnections + 1] =
            holder.ChildAdded:Connect(changed)
        platformReliefTemplateConnections[#platformReliefTemplateConnections + 1] =
            holder.ChildRemoved:Connect(changed)
        scheduleRebuild()
    end
end
-- Owner-approved platform carapaces arrive well after the map.
-- Rebuild the same existing PlatformIdentity owner on a relevant arrival.
-- All previously registered welds/shrink listeners are disconnected by clear.
local sideTemplateConnections = {}
local watchedSideTemplates = nil
local function watchSideTemplates(holder)
    if watchedSideTemplates == holder then return end
    for _, connection in ipairs(sideTemplateConnections) do
        connection:Disconnect()
    end
    table.clear(sideTemplateConnections)
    watchedSideTemplates = holder
    if holder and holder:IsA("Folder") then
        watchVerifiedTemplateReadiness(holder,
            sideTemplateConnections, "OriginalStructuralSide3D")
        local function changed(child)
            local generated = workspace:FindFirstChild("GeneratedMap")
            local arena = generated and generated:FindFirstChild("Arena")
            local variant = arena and tostring(
                arena:GetAttribute("VariantId") or "Classic")
            if variant == child.Name or child.Name == "Bridge" then
                scheduleRebuild()
            end
        end
        sideTemplateConnections[#sideTemplateConnections+1] =
            holder.ChildAdded:Connect(changed)
        sideTemplateConnections[#sideTemplateConnections+1] =
            holder.ChildRemoved:Connect(changed)
        scheduleRebuild()
    end
end

-- Late, optional owner-validated hero hull source. Only the model
-- itself triggers an existing visual rebuild, never a new frame loop.
local hullTemplateConnections = {}
local watchedHullTemplates = nil
local function watchHullTemplates(holder)
    if watchedHullTemplates == holder then return end
    for _, connection in ipairs(hullTemplateConnections) do
        connection:Disconnect()
    end
    table.clear(hullTemplateConnections)
    watchedHullTemplates = holder
    if holder and holder:IsA("Folder") then
        watchVerifiedTemplateReadiness(holder,
            hullTemplateConnections, "OriginalLargeDeckHull3D")
        local function onHullChanged(child)
            if child.Name == "LargeDeckHull" then scheduleRebuild() end
        end
        hullTemplateConnections[#hullTemplateConnections+1] =
            holder.ChildAdded:Connect(onHullChanged)
        hullTemplateConnections[#hullTemplateConnections+1] =
            holder.ChildRemoved:Connect(onHullChanged)
        scheduleRebuild()
    end
end

-- Late-arriving approved tall columns and long-route open lattice.
-- This shares the same already present client rebuild owner; no ticker.
local largeStructureTemplateConnections = {}
local watchedLargeStructureTemplates = nil
local function watchLargeStructureTemplates(holder)
    if watchedLargeStructureTemplates == holder then return end
    for _, connection in ipairs(largeStructureTemplateConnections) do
        connection:Disconnect()
    end
    table.clear(largeStructureTemplateConnections)
    watchedLargeStructureTemplates = holder
    if holder and holder:IsA("Folder") then
        watchVerifiedTemplateReadiness(holder,
            largeStructureTemplateConnections, "OriginalLargeStructure3D")
        local function changed(child)
            local generated = workspace:FindFirstChild("GeneratedMap")
            local arena = generated and generated:FindFirstChild("Arena")
            local variant = arena and tostring(
                arena:GetAttribute("VariantId") or "Classic")
            if child.Name == variant or child.Name == "LongCradle" then
                scheduleRebuild()
            end
        end
        largeStructureTemplateConnections[#largeStructureTemplateConnections+1] =
            holder.ChildAdded:Connect(changed)
        largeStructureTemplateConnections[#largeStructureTemplateConnections+1] =
            holder.ChildRemoved:Connect(changed)
        scheduleRebuild()
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child.Name == "ApprovedFloorReliefTemplates" then
        watchPlatformReliefTemplates(child)
    elseif child.Name == "ApprovedPlatformSideTemplates" then
        watchSideTemplates(child)
    elseif child.Name == "ApprovedLargeDeckHullTemplates" then
        watchHullTemplates(child)
    elseif child.Name == "ApprovedLargeStructureTemplates" then
        watchLargeStructureTemplates(child)
    end
end)
ReplicatedStorage.ChildRemoved:Connect(function(child)
    if child == currentPlatformReliefTemplates then
        watchPlatformReliefTemplates(nil)
        scheduleRebuild()
    elseif child == watchedSideTemplates then
        watchSideTemplates(nil)
        scheduleRebuild()
    elseif child == watchedHullTemplates then
        watchHullTemplates(nil)
        scheduleRebuild()
    elseif child == watchedLargeStructureTemplates then
        watchLargeStructureTemplates(nil)
        scheduleRebuild()
    end
end)
watchPlatformReliefTemplates(
    ReplicatedStorage:FindFirstChild("ApprovedFloorReliefTemplates"))
watchSideTemplates(
    ReplicatedStorage:FindFirstChild("ApprovedPlatformSideTemplates"))
watchHullTemplates(
    ReplicatedStorage:FindFirstChild("ApprovedLargeDeckHullTemplates"))
watchLargeStructureTemplates(
    ReplicatedStorage:FindFirstChild("ApprovedLargeStructureTemplates"))

player:GetAttributeChangedSignal("VfxQualityTier"):Connect(scheduleRebuild)
-- Exactly one optional Low authentic deck may be mounted in the
-- existing platform owner. Remove it promptly when adaptive pressure
-- rises, restoring the two native wedges; no extra render/camera loop.
player:GetAttributeChangedSignal("OptionalVfxPressure"):Connect(function()
    if VfxQuality.deviceTier(player:GetAttribute("VfxQualityTier"),
        UserInputService.TouchEnabled).Name == "Low" then
        scheduleRebuild()
    end
end)
-- The EXISTING scenery-LOD camera sampler requests a bounded retarget
-- only after traversing 88 studs and a 12-second cooldown. No camera loop
-- or premium source/model quota is added to this owner.
player:GetAttributeChangedSignal("LocalPremiumNearFieldEpoch")
    :Connect(scheduleRebuild)
-- Accessibility changes affect at most four existing instrument tweens;
-- never rebuild the whole arena just to freeze/restart the moving heads.
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    for platform in pairs(outpostMotions) do
        refreshOutpostMotion(platform)
    end
end)

rebuild()
