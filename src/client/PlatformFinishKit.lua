-- Chaos Signal: minimal, recognizable platform detailing on moving geometry.
-- Decorative welds follow the authoritative platform without collisions.
-- No custom asset IDs, dynamic emitters, scripted physics or animation loops.
local PlatformFinishKit = {}
-- This module is also loaded as a pure helper by Roblox Cloud engine suites:
-- their ModuleScript sandbox has no global 'script'. Runtime Roblox clients
-- always have script.Parent; pure helpers retain the native art fallback.
local PremiumPlatformSideMeshKit = script and script.Parent
    and require(script.Parent.PremiumPlatformSideMeshKit) or nil

local NAMES = {
    Classic = {"ClassicCalibrationPlate", "ClassicDatumTick", "ClassicArmoredLip"},
    Towers = {"TowerHoistMount", "TowerGuideBracket", "TowerMaintenanceMark"},
    Crossroads = {"CrossroadsRouteChevron", "CrossroadsTrafficBranch", "CrossroadsDirectionStud"},
    Orbital = {"OrbitalFluxSpine", "OrbitalMagnetGuide", "OrbitalTelemetryEye"},
    Harbor = {"HarborTimberSplice", "HarborCargoSteelBand", "HarborUndersideKeel"},
}

function PlatformFinishKit.names(variant)
    return NAMES[variant]
end

function PlatformFinishKit.count(tier)
    if tier == "Low" then return 1 end
    if tier == "High" then return 3 end
    return 2
end

local function add(parent, platform, name, localFrame, size, color, material, alpha, shape)
    local part = Instance.new(shape == "WedgePart" and "WedgePart" or "Part")
    part.Name = name
    part.Size = size
    part.CFrame = platform.CFrame * localFrame
    part.Color = color
    part.Material = material
    part.Transparency = alpha
    part:SetAttribute("ChaosBaseTransparency", alpha)
    if shape and shape ~= "WedgePart" then part.Shape = shape end
    part.Anchored = false
    part.Massless = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.CastShadow = false
    part:SetAttribute("ChaosPlatformTrim", true)
    part.Parent = parent

    -- Skybridge spans change during Shrinking Arena. A WeldConstraint
    -- preserves the old offset and snaps resized trim back into place.
    -- Use an adjustable Weld only for skybridges; ordinary moving decks
    -- keep their existing lightweight WeldConstraint behavior.
    local skybridge = platform:GetAttribute("ChaosSkybridge") == true
    local adjustable = skybridge
        or tonumber(platform:GetAttribute("RouteTier")) ~= nil
    local joint = Instance.new(adjustable and "Weld" or "WeldConstraint")
    joint.Name = "ChaosPlatformTrimWeld"
    joint.Part0 = part
    joint.Part1 = platform
    if adjustable then
        joint.C0 = CFrame.identity
        joint.C1 = localFrame
    end
    joint.Parent = part
    return part
end

-- StreamingEnabled does not guarantee the order in which platform Parts
-- enter a client's GetChildren() result. A consistent natural-name order
-- keeps each platform's cosmetic identity and Low-tier budget stable
-- between Android sessions, reconnects and late-replicated siblings.
function PlatformFinishKit.orderedPlatforms(container)
    if not container then return {} end
    local ordered = {}
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(ordered, child)
        end
    end
    table.sort(ordered, function(a, b)
        local aPrefix, aNumber = string.match(a.Name, "^(.-)(%d+)$")
        local bPrefix, bNumber = string.match(b.Name, "^(.-)(%d+)$")
        if aPrefix and aPrefix == bPrefix then
            local ai, bi = tonumber(aNumber), tonumber(bNumber)
            if ai and bi and ai ~= bi then
                return ai < bi
            end
        end
        if a.Name ~= b.Name then
            return a.Name < b.Name
        end
        -- Named duplicates are unusual but can occur in streamed or
        -- procedural content; use spatial ties for a stable visual order.
        local ap, bp = a.Position, b.Position
        if ap.X ~= bp.X then return ap.X < bp.X end
        if ap.Z ~= bp.Z then return ap.Z < bp.Z end
        if ap.Y ~= bp.Y then return ap.Y < bp.Y end
        return false
    end)
    return ordered
end

-- Procedural platforms are named PlatformN / SkybridgeN by MapBuilder.
-- Use that server-authored identity for alternate Low-tier decoration:
-- the selected subset must not flip when Platform1 streams in AFTER
-- Platform2 or when a skybridge arrives later.
function PlatformFinishKit.visualIndex(platform, fallbackIndex)
    local suffix = platform and string.match(platform.Name, "(%d+)$")
    local number = suffix and tonumber(suffix)
    if number and number >= 1 and number < 10000
        and number % 1 == 0 then
        return number
    end
    return math.max(1, math.floor(tonumber(fallbackIndex) or 1))
end

-- Chunky, angled corner armor changes the silhouette without touching
-- the physical collision deck. Earlier armor sat below the deck bottom:
-- invisible from the mobile third-person camera. Wedges now sit above
-- the panel near the corners but INSIDE the true collision footprint,
-- so decorative armor never suggests a safe overhanging walkway.
-- High gets all four corners, Medium an opposing diagonal, Low none.
-- New geometry is local-only, massless and welded to the actual platform.
function PlatformFinishKit.armorCount(tier)
    if tier == "High" then return 4 end
    if tier == "Medium" then return 2 end
    return 0
end

-- Server MapBuilder covers each deck with a 0.10-thick PlatformPanel
-- centered 0.055 above the physical surface. Earlier local markings
-- were centered at +0.055 and hidden *inside* that panel on device.
-- Keep a narrow clearance above its actual upper face, regardless
-- of which client module paints the surface.
function PlatformFinishKit.surfacePaintOffset(platform, thickness)
    if not platform or not platform:IsA("BasePart") then return nil end
    local halfThickness = math.max(0.005, (tonumber(thickness) or 0.05) * 0.5)
    -- MapBuilder calls addPlatformFinish for ALL decks, including the
    -- Towers Skybridges. Their server-owned PlatformPanel is centered
    -- at physicalTop + 0.055 with thickness 0.10, too. Painting directly
    -- above the physical Part would be buried beneath that inset.
    return platform.Size.Y * 0.5 + 0.055 + 0.05 + halfThickness + 0.012
end

function PlatformFinishKit.buildArmor(parent, platform, variant, tier, theme)
    if not parent or not platform or not platform:IsA("BasePart")
        or not NAMES[variant] or not theme then
        return {}
    end
    local count = PlatformFinishKit.armorCount(tier)
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if count == 0 or math.min(sx, sz) < 3.2 then
        return {}
    end

    local armorSize = math.clamp(math.min(sx, sz) * 0.13, 0.75, 1.50)
    local color = theme.Structure:Lerp(theme.Detail, 0.34)
    local corners = {
        {-1, -1, 0},
        {1, -1, 90},
        {1, 1, 180},
        {-1, 1, 270},
    }
    local built = {}
    for cornerIndex, def in ipairs(corners) do
        if count == 4 or cornerIndex == 1 or cornerIndex == 3 then
            local frame = CFrame.new(
                def[1] * (sx * 0.5 - armorSize * 0.53),
                sy * 0.5 + 0.05,
                def[2] * (sz * 0.5 - armorSize * 0.53)
            ) * CFrame.Angles(0, math.rad(def[3]), 0)
            local plate = add(parent, platform,
                variant .. "CornerArmor" .. cornerIndex,
                frame,
                Vector3.new(armorSize, 0.34, armorSize),
                color,
                Enum.Material.Metal,
                0.04,
                "WedgePart"
            )
            plate:SetAttribute("ChaosArmorCorner", cornerIndex)
            table.insert(built, plate)
        end
    end
    return built
end

-- Recessed side plating adds depth to otherwise flat floating decks.
-- It is welded, non-solid and placed BELOW the playable top face; the
-- per-platform budget stays fixed (Low 0, Medium 2, High 4).
function PlatformFinishKit.sideRailCount(tier)
    if tier == "High" then return 4 end
    if tier == "Medium" then return 2 end
    return 0
end

function PlatformFinishKit.buildSideRails(parent, platform, tier, theme, variant, index, selectedBridge)
    if not parent or not platform or not platform:IsA("BasePart")
        or not theme or not NAMES[variant] then
        return {}
    end
    local count = PlatformFinishKit.sideRailCount(tier)
    if count > 0 and PremiumPlatformSideMeshKit
        and platform:GetAttribute("ChaosSkybridge") == true then
        -- Real 7-material creator-owned truss modules occupy the same
        -- existing visual budget and shrink/collapse owner as native bars.
        local original = PremiumPlatformSideMeshKit.bridgeGirders(
            parent, platform, tier, index, selectedBridge)
        if original then return original end
    end
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if count == 0 or math.min(sx, sz) < 4 then return {} end

    local railHeight = math.min(0.30, math.max(0.12, sy * 0.18))
    -- The deck's opaque physical Part otherwise occludes an inset rail.
    -- Expose the narrow vertical side face just outside the deck footprint,
    -- below the top so it cannot be mistaken for a walkable ledge.
    local y = -sy * 0.5 + railHeight * 0.5
    local outside = 0.055
    -- Structural side faces express each arena's actual material
    -- language without any extra Parts, emissive light, fake top
    -- ledge or change to the physical deck. Make the nearby platform
    -- construction recognizable even when its distant skyline is culled.
    local sideMaterials = {
        Classic = Enum.Material.DiamondPlate,
        Towers = Enum.Material.CorrodedMetal,
        Crossroads = Enum.Material.Concrete,
        Orbital = Enum.Material.Metal,
        Harbor = Enum.Material.WoodPlanks,
    }
    local material = sideMaterials[variant]
    local color = variant == "Harbor"
        and theme.Surface:Lerp(Color3.fromRGB(103, 82, 65), 0.42)
        or (variant == "Crossroads"
            and theme.Structure:Lerp(theme.Surface, 0.48)
            or theme.Detail:Lerp(theme.Structure, 0.38))
    local segments = {
        {Vector3.new(0, y, -sz * 0.5 - outside), Vector3.new(sx * 0.72, railHeight, 0.13)},
        {Vector3.new(0, y, sz * 0.5 + outside), Vector3.new(sx * 0.72, railHeight, 0.13)},
        {Vector3.new(-sx * 0.5 - outside, y, 0), Vector3.new(0.13, railHeight, sz * 0.72)},
        {Vector3.new(sx * 0.5 + outside, y, 0), Vector3.new(0.13, railHeight, sz * 0.72)},
    }
    local built = {}
    for index, segment in ipairs(segments) do
        if count == 4 or index <= 2 then
            local piece = add(parent, platform, "PlatformRecessedSideRail" .. index,
                CFrame.new(segment[1]), segment[2], color,
                material, 0.08)
            table.insert(built, piece)
        end
    end
    return built
end

-- A Tower skybridge is a solid permanent route. Shrinking Arena contracts
-- its long axis (unlike ordinary platforms, which only translate).
-- Local welded paint, side rails and corner armor must contract too;
-- otherwise they imply a phantom walkable route beyond the real bridge.
-- Capture once per generated set, then change ONLY existing client Parts.
function PlatformFinishKit.captureSkybridgeFootprint(platform, pieces)
    if not platform or not platform:IsA("BasePart")
        or platform:GetAttribute("ChaosSkybridge") ~= true then
        return nil
    end
    local size = platform.Size
    local alongX = size.X >= size.Z
    local snapshot = {
        platform = platform,
        originalSpan = alongX and size.X or size.Z,
        alongX = alongX,
        entries = {},
    }
    for _, piece in ipairs(pieces or {}) do
        if piece and piece:IsA("BasePart") and piece.Parent then
            snapshot.entries[#snapshot.entries + 1] = {
                part = piece,
                size = piece.Size,
                localCFrame = platform.CFrame:ToObjectSpace(piece.CFrame),
            }
        end
    end
    return snapshot
end

function PlatformFinishKit.applySkybridgeFootprint(snapshot)
    if not snapshot or not snapshot.platform
        or not snapshot.platform.Parent or snapshot.originalSpan <= 0 then
        return 0
    end

    local platform = snapshot.platform
    local span = snapshot.alongX and platform.Size.X or platform.Size.Z
    local ratio = math.clamp(span / snapshot.originalSpan, 0.05, 4)
    local updated = 0
    for _, data in ipairs(snapshot.entries) do
        local piece = data.part
        if piece and piece.Parent then
            local position = data.localCFrame.Position
            local rotation = data.localCFrame - position
            local scaled = snapshot.alongX
                and Vector3.new(position.X * ratio, position.Y, position.Z)
                or Vector3.new(position.X, position.Y, position.Z * ratio)
            -- Short bolts, trims and armor stay rigid, while long paint and
            -- side bands shorten with the real deck. No fake walkway edges.
            local size = data.size
            -- Creator-owned glTF girder meshes can have their LONG LOCAL
            -- axis on X or Z independently of the physical skybridge's
            -- WORLD long axis. Compress the actual authored axis, not the
            -- Roblox platform axis, or a rotated girder becomes a ghost
            -- structure beyond the shrinking collision deck.
            local importedAxis = piece:GetAttribute("OriginalBridgeLongAxis")
            if importedAxis == "X" then
                piece.Size = Vector3.new(
                    math.max(0.05, size.X * ratio), size.Y, size.Z)
            elseif importedAxis == "Z" then
                piece.Size = Vector3.new(
                    size.X, size.Y, math.max(0.05, size.Z * ratio))
            else
                piece.Size = snapshot.alongX
                    and Vector3.new(size.X > 2.2 and size.X * ratio or size.X,
                        size.Y, size.Z)
                    or Vector3.new(size.X, size.Y,
                        size.Z > 2.2 and size.Z * ratio or size.Z)
            end
            local localFrame = CFrame.new(scaled) * rotation
            local joint = piece:FindFirstChild("ChaosPlatformTrimWeld")
            if joint and joint:IsA("Weld") then
                -- C0 is identity, so C1 is the exact platform-relative
                -- frame. Updating it changes the physical weld offset.
                joint.C1 = localFrame
            else
                piece.CFrame = platform.CFrame * localFrame
            end
            updated += 1
        end
    end
    return updated
end

function PlatformFinishKit.bindSkybridgeFootprint(platform, pieces)
    local snapshot = PlatformFinishKit.captureSkybridgeFootprint(platform, pieces)
    if not snapshot then return function() end end

    local connected = true
    local scheduled = false
    local connection = platform:GetPropertyChangedSignal("Size"):Connect(function()
        if not connected or scheduled then return end
        scheduled = true
        task.defer(function()
            scheduled = false
            if connected then PlatformFinishKit.applySkybridgeFootprint(snapshot) end
        end)
    end)
    return function()
        connected = false
        connection:Disconnect()
    end
end

-- Real near-camera structural depth, not more glowing rectangles:
-- inset ribbed service hatches and a two-level metal casing are welded to
-- actual collidable decks. Existing collapse/shrink owners register these
-- three nonblocking meshes. Tight budget: 1 out of 3 physical platforms,
-- Medium/High only; zero extra lights, textures or update loops.
-- Use already approved five-arena floor sculptures for genuine welded
-- service-hatch detail on actual moving decks. The native three-layer hatch
-- below remains a fallback until the approved source has replicated.
-- No new asset upload, physics, render loop or server-side platform change.
-- The same five creator-approved reliefs are used for both legacy
-- source mounting and the near-camera selection. Never reserve a scarce
-- 3D slot for a missing/invalid model (StreamingEnabled can deliver it late).
local SERVICE_HATCH_ASSETS = {
    Classic = 102746904688141,
    Towers = 74708751016233,
    Crossroads = 84038993323581,
    Orbital = 123089585720736,
    Harbor = 94830155055482,
}

local function serviceHatchSource(variant)
    local assetId = SERVICE_HATCH_ASSETS[variant]
    if not assetId then return nil end
    local holder = game:GetService("ReplicatedStorage")
        :FindFirstChild("ApprovedFloorReliefTemplates")
    local source = holder and holder:FindFirstChild(variant)
    if not holder or not holder:IsA("Folder")
        or holder:GetAttribute("OwnerVerified") ~= true
        or not source or not source:IsA("Model") or source.Parent ~= holder
        or source:GetAttribute("Original3DAssetId") ~= assetId
        or source:GetAttribute("OwnerVerified") ~= true
        or source:GetAttribute("CosmeticOnly") ~= true
        or source:GetAttribute("OriginalFloorRelief3D") ~= true then
        return nil
    end
    local count = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("BasePart") then
            if not part:IsA("MeshPart")
                or part.CanCollide or part.CanTouch or part.CanQuery then
                return nil
            end
            count += 1
        elseif part:IsA("LuaSourceContainer") then
            return nil
        end
    end
    if count < 1 or count > 12 then return nil end
    local _, dimensions = source:GetBoundingBox()
    if math.max(dimensions.X, dimensions.Z) < 2.7
        or math.min(dimensions.X, dimensions.Z) < .45
        or dimensions.Y <= 0 or dimensions.Y > .75 then
        return nil
    end
    return source, dimensions, assetId
end

-- The ORIGINAL 1-in-9 High / 1-in-18 Medium authentic mesh budget is
-- counted from currently safe legacy-eligible decks. Move those same slots
-- onto the in-view platforms that ALREADY owned native 3-piece hatches,
-- replacing rather than stacking their simple forms. No new visual owner.
function PlatformFinishKit.selectOriginalServiceHatches(
        ordered, variant, tier, base, cameraPoint, cameraLook)
    local chosen = {}
    if (tier ~= "High" and tier ~= "Medium")
        or type(ordered) ~= "table"
        or not base or not base:IsA("BasePart") then return chosen end
    local source, sourceSize = serviceHatchSource(variant)
    if not source then return chosen end
    local sourceLong = math.max(sourceSize.X, sourceSize.Z)
    local sourceShort = math.min(sourceSize.X, sourceSize.Z)
    local legacyStep = tier == "High" and 9 or 18
    local focus = base.Position
    local hasCamera = false
    if typeof(cameraPoint) == "Vector3" then
        local localCamera = base.CFrame:PointToObjectSpace(cameraPoint)
        if math.abs(localCamera.X) <= base.Size.X * .5 + 16
            and math.abs(localCamera.Z) <= base.Size.Z * .5 + 16
            and math.abs(localCamera.Y) <= 130 then
            focus = cameraPoint
            hasCamera = true
        end
    end
    local look = typeof(cameraLook) == "Vector3"
        and Vector3.new(cameraLook.X, 0, cameraLook.Z) or Vector3.zero
    if look.Magnitude > .2 then look = look.Unit
    else look = Vector3.zero end
    local quota = 0
    local candidates = {}
    for index, platform in ipairs(ordered) do
        if platform:IsA("BasePart") and platform.Parent
            and platform.Name:match("^Platform%d+$")
            and platform.Anchored and platform.CanCollide
            and platform.Transparency < .75 then
            local id = PlatformFinishKit.visualIndex(platform, index)
            local phase = platform:GetAttribute("CollapsePhase")
            local shutter = platform:GetAttribute("BridgeShutterPhase")
            local sx, sz = platform.Size.X, platform.Size.Z
            if id % 3 == 1 and math.min(sx, sz) >= 8
                and math.max(sx, sz) <= 36
                and (phase == nil or phase == "Normal" or phase == "Safe")
                and (shutter == nil or shutter == "Idle") then
                local width = math.min(sx * .55, 6.2)
                local depth = math.min(sz * .42, 4.2)
                local scale = math.min(1,
                    width * .96 / sourceLong,
                    depth * .90 / sourceShort)
                if scale >= .45 then
                    -- Count only source-bearing platforms that the OLD
                    -- index gate would actually have been able to mount.
                    if id % legacyStep == 1 then quota += 1 end
                    local delta = platform.Position - focus
                    local distance = Vector3.new(
                        delta.X, delta.Y * .6, delta.Z).Magnitude
                    local score = distance
                    local flat = Vector3.new(delta.X, 0, delta.Z)
                    if hasCamera and flat.Magnitude > 30
                        and look.Magnitude > .2 then
                        score -= flat.Unit:Dot(look)
                            * math.min(36, flat.Magnitude * .18)
                    end
                    candidates[#candidates + 1] = {
                        part = platform, id = id, score = score,
                    }
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.id < b.id
    end)
    for i = 1, math.min(quota, #candidates) do
        chosen[candidates[i].part] = true
    end
    return chosen
end

local function originalServiceHatch(parent, platform, variant, tier,
        width, depth, upper, index, selected)
    -- FALSE: this owner already allocated its finite mesh slots.
    -- NIL: preserve legacy use in independent engine helper callers.
    local step = tier == "High" and 9 or 18
    if selected == false
        or (selected ~= true
            and math.floor(tonumber(index) or 0) % step ~= 1) then
        return nil
    end
    local source, original, assetId = serviceHatchSource(variant)
    if not source then return nil end
    local copy = source:Clone()
    -- Preserve the entire original relief, no non-uniform mesh distortion.
    local scale = math.min(1, width * .96 / long, depth * .90 / short)
    if scale < .45 or not pcall(function() copy:ScaleTo(scale) end) then
        copy:Destroy()
        return nil
    end
    local sourceFrame, bounds = copy:GetBoundingBox()
    local yaw = original.X < original.Z and math.pi * .5 or 0
    local target = platform.CFrame
        * CFrame.new(0, upper + .05, -platform.Size.Z * .19)
        * CFrame.Angles(0, yaw, 0)
    local made = {}
    for _, part in ipairs(copy:GetDescendants()) do
        if part:IsA("MeshPart") then
            part.CFrame = target * sourceFrame:ToObjectSpace(part.CFrame)
            part.Anchored = false
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.CastShadow = false
            part:SetAttribute("ChaosBaseTransparency", part.Transparency)
            part:SetAttribute("ChaosPlatformTrim", true)
            part:SetAttribute("OriginalServiceHatch3D", true)
            part:SetAttribute("Original3DAssetId", assetId)
            made[#made + 1] = part
        end
    end
    if #made ~= #pieces then copy:Destroy(); return nil end
    local adjustable = platform:GetAttribute("ChaosSkybridge") == true
        or tonumber(platform:GetAttribute("RouteTier")) ~= nil
    for i, part in ipairs(made) do
        part.Name = variant .. "OriginalServiceHatch3D_" .. tostring(i)
        part.Parent = parent
        local weld = Instance.new(adjustable and "Weld" or "WeldConstraint")
        weld.Name = "ChaosPlatformTrimWeld"
        weld.Part0 = part
        weld.Part1 = platform
        if adjustable then
            weld.C0 = CFrame.identity
            weld.C1 = platform.CFrame:ToObjectSpace(part.CFrame)
        end
        weld.Parent = part
    end
    copy:Destroy()
    return made
end

function PlatformFinishKit.buildServiceHatch(parent, platform, variant,
        tier, theme, index, selected)
    if not parent or not platform or not platform:IsA("BasePart")
        or tier == "Low" or not NAMES[variant] or not theme
        or (math.floor(tonumber(index) or 0) % 3 ~= 1)
        or platform:GetAttribute("ChaosSkybridge") == true
    then return {} end
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if math.min(sx, sz) < 8 or math.max(sx, sz) > 36 then return {} end
    local upper = PlatformFinishKit.surfacePaintOffset(platform, 0.065)
    local hatchWidth = math.min(sx * 0.55, 6.2)
    local hatchDepth = math.min(sz * 0.42, 4.2)
    local original = originalServiceHatch(
        parent, platform, variant, tier, hatchWidth, hatchDepth, upper, index,
        selected)
    if original then return original end
    local materials = {
        Classic = Enum.Material.DiamondPlate,
        Towers = Enum.Material.CorrodedMetal,
        Crossroads = Enum.Material.Concrete,
        Orbital = Enum.Material.Metal,
        Harbor = Enum.Material.WoodPlanks,
    }
    local color = theme.Structure:Lerp(theme.Detail, 0.28)
    local accent = theme.Detail:Lerp(theme.Surface, 0.42)
    local hatch = add(parent, platform, variant .. "ServiceHatch",
        CFrame.new(0, upper, -sz * 0.19),
        Vector3.new(hatchWidth, 0.18, hatchDepth), color,
        materials[variant], 0.05)
    hatch:SetAttribute("ChaosServiceHatch", true)
    local collar = add(parent, platform, variant .. "ServiceCollar",
        CFrame.new(0, upper + 0.11, -sz * 0.19),
        Vector3.new(math.max(1.0, hatchWidth - 0.70), 0.08,
            math.max(1.0, hatchDepth - 0.70)),
        accent, Enum.Material.Metal, 0.11)
    collar:SetAttribute("ChaosServiceHatch", true)
    local handle = add(parent, platform, variant .. "ServiceHandle",
        CFrame.new(0, upper + 0.18, -sz * 0.19),
        Vector3.new(math.min(1.7, hatchWidth * 0.36), 0.10, 0.25),
        theme.Structure, Enum.Material.DiamondPlate, 0.02)
    handle:SetAttribute("ChaosServiceHatch", true)
    return {hatch, collar, handle}
end

-- Classic's authored zigzag decks shrink along BOTH horizontal axes.
-- Keep every welded client-only stripe, armor/brace and axis cue strictly
-- inside its real collision deck instead of showing a phantom 10-stud top.
function PlatformFinishKit.captureRouteFootprint(platform, pieces)
    if not platform or not platform:IsA("BasePart")
        or tonumber(platform:GetAttribute("RouteTier")) == nil then
        return nil
    end
    local snapshot = {
        platform = platform,
        originalSize = platform.Size,
        entries = {},
    }
    for _, piece in ipairs(pieces or {}) do
        if piece and piece:IsA("BasePart") and piece.Parent
            and piece:GetAttribute("SkipRouteFootprint") ~= true then
            -- True 3D support columns are welded to the real anchored
            -- PlatformSupport, whose server CFrame and Size already follow
            -- the arena shrink. A second deck-relative shrink would apply
            -- contraction twice and could leave a floating fake pillar.
            snapshot.entries[#snapshot.entries + 1] = {
                part = piece,
                size = piece.Size,
                localCFrame = platform.CFrame:ToObjectSpace(piece.CFrame),
            }
        end
    end
    return snapshot
end

function PlatformFinishKit.applyRouteFootprint(snapshot)
    if not snapshot or not snapshot.platform or not snapshot.platform.Parent then
        return 0
    end
    local deck = snapshot.platform
    local original = snapshot.originalSize
    if original.X <= 0 or original.Z <= 0 then return 0 end
    local ratioX = math.clamp(deck.Size.X / original.X, 0.05, 4)
    local ratioZ = math.clamp(deck.Size.Z / original.Z, 0.05, 4)
    local changed = 0
    for _, data in ipairs(snapshot.entries) do
        local part = data.part
        if part and part.Parent then
            local p = data.localCFrame.Position
            local rotation = data.localCFrame - p
            local localFrame = CFrame.new(p.X * ratioX, p.Y, p.Z * ratioZ)
                * rotation
            part.Size = Vector3.new(
                math.max(0.05, data.size.X * ratioX),
                data.size.Y,
                math.max(0.05, data.size.Z * ratioZ)
            )
            local joint = part:FindFirstChild("ChaosPlatformTrimWeld")
                or part:FindFirstChild("PlatformIdentityWeld")
            if joint and joint:IsA("Weld") then
                joint.C1 = localFrame
            else
                part.CFrame = deck.CFrame * localFrame
            end
            changed += 1
        end
    end
    return changed
end

function PlatformFinishKit.bindRouteFootprint(platform, pieces)
    local snapshot = PlatformFinishKit.captureRouteFootprint(platform, pieces)
    if not snapshot then return function() end end
    local connected = true
    local queued = false
    local listener = platform:GetPropertyChangedSignal("Size"):Connect(function()
        if not connected or queued then return end
        queued = true
        task.defer(function()
            queued = false
            if connected then PlatformFinishKit.applyRouteFootprint(snapshot) end
        end)
    end)
    -- A streaming player can first encounter an already-shrinking deck.
    PlatformFinishKit.applyRouteFootprint(snapshot)
    return function()
        connected = false
        listener:Disconnect()
    end
end

-- Art direction: load-bearing diagonal steel gives floating decks an
-- engineered underside, not a floating plastic slab. Each brace starts
-- under a real deck corner and terminates under its central frame.
-- Only Medium/High allocate them; no extra light, mesh or physics owner.
function PlatformFinishKit.braceCount(tier)
    if tier == "High" then return 4 end
    if tier == "Medium" then return 2 end
    return 0
end

function PlatformFinishKit.buildLoadBraces(parent, platform, variant, tier, theme)
    if not parent or not platform or not platform:IsA("BasePart")
        or not NAMES[variant] or not theme
        or platform:GetAttribute("ChaosSkybridge") == true then
        return {}
    end

    local count = PlatformFinishKit.braceCount(tier)
    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    if count == 0 or math.min(sx, sz) < 9 then return {} end

    local drop = math.clamp(math.min(sx, sz) * 0.24, 1.5, 3.0)
    -- Each real close-up jump deck has its own load-bearing language.
    -- Reuse the same 0/2/4 brace budget, welds and shrink/collapse owner:
    -- no new physics, decorative parts, loops or fake reachable ledges.
    local profiles = {
        Classic = {material = Enum.Material.DiamondPlate, width = 0.55,
            depth = 0.58, tone = theme.Detail:Lerp(theme.Structure, 0.44)},
        Towers = {material = Enum.Material.CorrodedMetal, width = 0.75,
            depth = 0.64, tone = theme.Structure:Lerp(theme.Detail, 0.22)},
        Crossroads = {material = Enum.Material.Concrete, width = 0.68,
            depth = 0.60, tone = theme.Surface:Lerp(theme.Structure, 0.55)},
        Orbital = {material = Enum.Material.Metal, width = 0.42,
            depth = 0.48, tone = theme.Detail:Lerp(theme.Secondary, 0.35)},
        Harbor = {material = Enum.Material.WoodPlanks, width = 0.70,
            depth = 0.58, tone = theme.Surface:Lerp(Color3.fromRGB(104, 80, 58), 0.38)},
    }
    local profile = profiles[variant]
    local color = profile.tone
    local corners = {
        {-1, -1},
        {1, 1},
        {-1, 1},
        {1, -1},
    }
    local built = {}
    for i = 1, count do
        local dir = corners[i]
        local start = Vector3.new(
            dir[1] * sx * 0.36, -sy * 0.5 - 0.22, dir[2] * sz * 0.30
        )
        local finish = Vector3.new(
            dir[1] * sx * 0.11, -sy * 0.5 - drop, dir[2] * sz * 0.08
        )
        local midpoint = (start + finish) * 0.5
        local length = (finish - start).Magnitude
        local brace = add(
            parent, platform, variant .. "LoadBrace" .. i,
            CFrame.lookAt(midpoint, finish),
            Vector3.new(profile.width, profile.depth, length),
            color, profile.material, tier == "High" and 0.08 or 0.14
        )
        brace:SetAttribute("ChaosLoadBrace", true)
        built[#built + 1] = brace
    end
    return built
end

-- Authored native 3D carapaces turn rectangular jump blocks into engineered
-- modules with sloped facings and an exposed underside chassis. Reuse the
-- existing welded client trim ownership: collapse visibility, route shrink,
-- streaming and tier rebuild need NO extra listeners or physics objects.
-- Every visible top of a wedge is BELOW the actual walkable collider top.
-- Per-arena variants differ in steel, alloy, armored ceramic and dock metal.
local CARAPACE_PROFILES = {
    Classic = {shell = Enum.Material.DiamondPlate,
        core = Enum.Material.CorrodedMetal, tint = 0.38},
    Towers = {shell = Enum.Material.Foil,
        core = Enum.Material.DiamondPlate, tint = 0.29},
    Crossroads = {shell = Enum.Material.CorrodedMetal,
        core = Enum.Material.DiamondPlate, tint = 0.46},
    Orbital = {shell = Enum.Material.CeramicTiles,
        core = Enum.Material.Foil, tint = 0.42},
    Harbor = {shell = Enum.Material.CorrodedMetal,
        core = Enum.Material.DiamondPlate, tint = 0.34},
}

function PlatformFinishKit.carapaceCount(tier, index)
    local number = math.floor(tonumber(index) or 0)
    if number < 1 then return 0 end
    if tier == "High" and number % 3 == 1 then return 7 end
    if tier == "Medium" and number % 4 == 1 then return 4 end
    if tier == "Low" and number % 8 == 1 then return 2 end
    return 0
end

function PlatformFinishKit.buildCarapace(parent, platform, variant, tier, theme, index, selectedForOriginal)
    if not parent or not platform or not platform:IsA("BasePart")
        or not theme or not CARAPACE_PROFILES[variant]
        or platform:GetAttribute("ChaosSkybridge") == true then
        return {}
    end
    local budget = PlatformFinishKit.carapaceCount(tier, index)
    -- A selected verified original may replace a previously undecorated
    -- physical deck. Never construct NEW native fallback parts solely
    -- because a source was selected: preserve the legacy 3/4/8 cadence.
    if budget == 0 and selectedForOriginal ~= true then return {} end

    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    -- Narrow skywalks and the giant structural spans already have their
    -- own original geometry. Only finish existing real jump decks.
    if math.min(sx, sz) < 7 or math.max(sx, sz) > 36 then
        return {}
    end

    -- Source-authenticated sculpted full underside/side facings replace
    -- seven crude WedgePart/Part modules on sparse High/Medium decks.
    -- The native art below is only built when the genuine mesh is absent.
    if PremiumPlatformSideMeshKit then
        local original = PremiumPlatformSideMeshKit.carapace(
            parent, platform, variant, tier, index, selectedForOriginal)
        if original then return original end
    end
    if budget == 0 then return {} end

    local p = CARAPACE_PROFILES[variant]
    local shellColor = theme.Structure:Lerp(theme.Detail, p.tint)
    local coreColor = theme.Surface:Lerp(theme.Structure, 0.54)
    local accent = theme.Detail:Lerp(theme.Secondary, 0.09)
    local built = {}
    local function piece(name, frame, size, color, material, alpha, shape)
        local item = add(parent, platform, variant .. "DeckCarapace"
            .. tostring(index) .. name, frame, size,
            color, material, alpha, shape)
        item:SetAttribute("OriginalDeckCarapace", true)
        built[#built + 1] = item
    end

    -- These sloped side facings are *outside* the deck's vertical silhouette
    -- only, ending at least 0.08 studs BELOW the physical top. They are
    -- never reachable side shelves or phantom landings for players/bots.
    local y = sy * 0.5 - 0.54
    local longSpan = math.max(3, sx * 0.78)
    for side = -1, 1, 2 do
        piece(side == -1 and "NorthFacetedSkirt" or "SouthFacetedSkirt",
            CFrame.new(0, y, side * (sz * 0.5 - 0.12))
                * CFrame.Angles(0, side == -1 and 0 or math.pi, 0),
            Vector3.new(longSpan, 0.84, 0.90),
            shellColor, p.shell, 0.04, "WedgePart")
    end

    if budget >= 4 then
        -- An inset keel below the deck cuts away the toy floating-cube look.
        -- It is noncolliding, massless, and cannot change real jump height.
        piece("RecessedLoadKeel",
            CFrame.new(0, -sy * 0.5 - 0.36, 0),
            Vector3.new(math.max(3.0, sx * 0.61), 0.68,
                math.max(3.0, sz * 0.57)),
            coreColor, p.core, 0.055)
        piece("PortServiceFin",
            CFrame.new(-sx * 0.5 + 0.12, y, 0)
                * CFrame.Angles(0, math.pi * 0.5, 0),
            Vector3.new(sz * 0.66, 0.84, 0.90),
            accent, p.shell, 0.075, "WedgePart")
    end

    if budget >= 7 then
        piece("StarboardServiceFin",
            CFrame.new(sx * 0.5 - 0.12, y, 0)
                * CFrame.Angles(0, -math.pi * 0.5, 0),
            Vector3.new(sz * 0.66, 0.84, 0.90),
            accent, p.shell, 0.075, "WedgePart")
        for side = -1, 1, 2 do
            local start = Vector3.new(side * sx * 0.35,
                -sy * 0.5 - 0.14, -sz * 0.24)
            local finish = Vector3.new(side * sx * 0.11,
                -sy * 0.5 - 1.70, sz * 0.10)
            local delta = finish - start
            piece(side == -1 and "PortDiagonalSpar" or "StarboardDiagonalSpar",
                CFrame.lookAt((start + finish) * 0.5, finish),
                Vector3.new(0.44, 0.51, delta.Magnitude),
                coreColor, p.core, 0.07)
        end
    end
    return built
end

-- Platform disappearance is gameplay, not an artistic overlay: any local
-- welded armor or painted glyph must also become completely invisible.
-- Saved base transparencies survive repeated Warning/Gone/Restore cycles.
function PlatformFinishKit.applyCollapseVisibility(parts, phase)
    for _, item in ipairs(parts or {}) do
        if item and item.Parent and item:IsA("BasePart") then
            local original = item:GetAttribute("ChaosBaseTransparency")
            if type(original) ~= "number" then
                original = item.Transparency
                item:SetAttribute("ChaosBaseTransparency", original)
            end
            -- Fade local decorative paint and armor during the authoritative
            -- amber warning. Otherwise opaque client trim can obscure the
            -- yellow deck cue on Android even though the server panel fades.
            -- Gone still hides everything; restoration is idempotent.
            if phase == "Gone" then
                item.Transparency = 1
            elseif phase == "Warning" then
                item.Transparency = math.max(original, 0.80)
            else
                item.Transparency = original
            end
        end
    end
end

function PlatformFinishKit.build(parent, platform, variant, tier, theme)
    local names = NAMES[variant]
    if not parent or not platform or not platform:IsA("BasePart")
        or not names or not theme
    then
        return {}
    end

    local sx, sy, sz = platform.Size.X, platform.Size.Y, platform.Size.Z
    local top = PlatformFinishKit.surfacePaintOffset(platform, 0.05)
    local count = PlatformFinishKit.count(tier)
    local built = {}
    local function piece(i, localFrame, size, color, material, alpha, shape)
        if i > count then return end
        table.insert(built, add(parent, platform, names[i], localFrame, size,
            color, material, alpha, shape))
    end

    if variant == "Classic" then
        -- Datum plate and instrument hashes communicate an engineered radar grid.
        piece(1, CFrame.new(-sx * 0.23, top, -sz * 0.26),
            Vector3.new(sx * 0.38, 0.026, 0.36),
            theme.Detail, Enum.Material.Metal, 0.24)
        piece(2, CFrame.new(-sx * 0.23, top + 0.015, -sz * 0.23),
            Vector3.new(0.12, 0.027, sz * 0.22),
            theme.Secondary, Enum.Material.Metal, 0.25)
        piece(3, CFrame.new(-sx * 0.43, -sy * 0.11, 0),
            Vector3.new(0.24, sy * 0.68, sz * 0.26),
            theme.Structure, Enum.Material.DiamondPlate, 0.08)

    elseif variant == "Towers" then
        -- Below-deck hoist cradle keeps the walking surface unobstructed.
        piece(1, CFrame.new(0, -sy * 0.5 - 0.16, 0),
            Vector3.new(sx * 0.58, 0.27, sz * 0.20),
            theme.Structure, Enum.Material.DiamondPlate, 0.10)
        piece(2, CFrame.new(sx * 0.36, -sy * 0.24, 0),
            Vector3.new(0.33, sy * 0.47, sz * 0.51),
            theme.Detail, Enum.Material.Metal, 0.11)
        piece(3, CFrame.new(0, -sy * 0.5 - 0.33, 0),
            Vector3.new(sx * 0.20, 0.10, sz * 0.23),
            theme.Accent, Enum.Material.Neon, 0.53)

    elseif variant == "Crossroads" then
        -- Routing chevrons, not free-floating light strips, direct the eye.
        piece(1, CFrame.new(-sx * 0.19, top, -sz * 0.13)
            * CFrame.Angles(0, math.rad(-34), 0),
            Vector3.new(sx * 0.40, 0.026, 0.29),
            theme.Detail, Enum.Material.Metal, 0.15)
        piece(2, CFrame.new(sx * 0.16, top + 0.005, sz * 0.13)
            * CFrame.Angles(0, math.rad(34), 0),
            Vector3.new(sx * 0.32, 0.027, 0.20),
            theme.Secondary, Enum.Material.Metal, 0.23)
        piece(3, CFrame.new(sx * 0.37, top + 0.015, sz * 0.33),
            Vector3.new(0.42, 0.028, 0.42),
            theme.Accent, Enum.Material.Glass, 0.48)

    elseif variant == "Harbor" then
        -- Every 90-degree cargo switchback gets distinct wood-and-steel
        -- construction, never the Classic radar-grid markings. Finish
        -- parts remain INSIDE the real physical deck and are welded to it,
        -- so Shrinking Arena cannot leave a ghost walkway. A low-end
        -- Android client sees one cheap inset on alternate platforms only.
        local timber = theme.Surface:Lerp(Color3.fromRGB(113, 91, 73), 0.28)
        local hardware = theme.Structure:Lerp(theme.Detail, 0.34)
        piece(1, CFrame.new(-sx * 0.16, top, -sz * 0.18),
            Vector3.new(math.max(2.2, sx * 0.52), 0.028, 0.34),
            timber, Enum.Material.WoodPlanks, 0.16)
        piece(2, CFrame.new(sx * 0.14, top + 0.009, sz * 0.28),
            Vector3.new(math.max(2.0, sx * 0.56), 0.038, 0.23),
            hardware, Enum.Material.CorrodedMetal, 0.18)
        piece(3, CFrame.new(0, -sy * 0.5 - 0.20, 0),
            Vector3.new(math.max(2.4, sx * 0.64), 0.26,
                math.max(0.7, sz * 0.20)),
            hardware, Enum.Material.Metal, 0.10)

    elseif variant == "Orbital" then
        -- An arc-segment tangent to the route + a non-flashing telemetry lens.
        piece(1, CFrame.new(0, top, -sz * 0.29),
            Vector3.new(sx * 0.58, 0.028, 0.26),
            theme.Detail, Enum.Material.Metal, 0.12)
        piece(2, CFrame.new(0, top + 0.008, -sz * 0.21),
            Vector3.new(sx * 0.34, 0.027, 0.13),
            theme.Secondary, Enum.Material.Glass, 0.40)
        piece(3, CFrame.new(sx * 0.33, top + 0.017, -sz * 0.29),
            Vector3.new(0.39, 0.045, 0.39),
            theme.Accent, Enum.Material.Glass, 0.35, Enum.PartType.Ball)
    end

    return built
end

return PlatformFinishKit
