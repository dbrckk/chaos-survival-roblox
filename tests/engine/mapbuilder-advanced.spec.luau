--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local OriginalMeshScenery = require("../../src/server/OriginalMeshScenery")
local PremiumRouteMeshKit = require("../../src/client/PremiumRouteMeshKit")
local SkySpineCrownMeshKit = require("../../src/client/SkySpineCrownMeshKit")
local ArenaKeelMeshKit = require("../../src/client/ArenaKeelMeshKit")
local UnderstructureBeamMeshKit = require("../../src/client/UnderstructureBeamMeshKit")
local PremiumGroundMeshKit = require("../../src/client/PremiumGroundMeshKit")
local LobbyReturnFormation = require("../../src/server/LobbyReturnFormation")
local ArenaVariants = require("../../src/server/ArenaVariants")
local JumpRouteCueRules = require("../../src/shared/JumpRouteCueRules")
local OrbitalHelix = require("../../src/server/OrbitalHelix")
local OrbitalRouteSignKit = require("../../src/client/OrbitalRouteSignKit")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")
local SpawnSafety = require("../../src/server/SpawnSafety")
local ArenaPresentation = require("../../src/shared/ArenaPresentation")
local VisualTheme = require("../../src/shared/VisualTheme")

describe("Chaos Survival engine", function()
    it("mounts genuine MeshPart route art only on live physical platforms and preserves shrink/collapse safety", function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local holder = Instance.new("Folder")
        holder.Name = "PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified", true)
        holder.Parent = ReplicatedStorage
        local function template(name, id, size)
            local model = Instance.new("Model")
            model.Name = name
            model:SetAttribute("OwnerVerified", true)
            model:SetAttribute("CosmeticOnly", true)
            model:SetAttribute("Original3DAssetId", id)
            local geometry = Instance.new("MeshPart")
            geometry.Size = size
            geometry.Anchored = true
            geometry.Parent = model
            model.Parent = holder
        end
        template("PremiumJumpDeck", 98478693994864, Vector3.new(11.9, 1.5, 11.9))
        -- Approved-source stand-in footprint: a 12x9 crossroad module
        -- fits the genuine 26x12 promenade after X/Z-aware placement.
        -- Towers' 49x4.5 bridge is deliberately TOO NARROW to claim
        -- safe full-module replacement; it must retain its native finish.
        template("PremiumSkybridgeModule", 94023662427980,
            Vector3.new(12, 1.3, 9))
        -- Authorized run #41644715829 produced this real Approved
        -- 3,072-triangle original production source. In-engine stand-in
        -- here tests the placement contract, not network moderation:
        -- 7-source-material/real-ID guards are enforced by release CI.
        template("OriginalUnderdeckChassis", 84582262145054,
            Vector3.new(23.3, 4.0, 10.0))
        local arena = Instance.new("Folder")
        arena.Name = "PremiumRouteSmokeArena"
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.Anchored = true
        base.Parent = arena
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local deck = Instance.new("Part")
        deck.Name = "Platform1"
        deck.Size = Vector3.new(12, 2, 12)
        deck.Anchored = true
        deck.CanCollide = true
        deck.Parent = platforms
        local nativePanel = Instance.new("Part")
        nativePanel.Name = "PlatformPanel1"
        nativePanel.Size = Vector3.new(11.2, 0.10, 11.2)
        nativePanel.Position = deck.Position + Vector3.new(0, 1.055, 0)
        nativePanel.Anchored = true
        nativePanel.CanCollide = false
        nativePanel.CanTouch = false
        nativePanel.CanQuery = false
        nativePanel.Parent = decor
        local bridge = Instance.new("Part")
        bridge.Name = "Skybridge2"
        bridge:SetAttribute("ChaosSkybridge", true)
        bridge.Size = Vector3.new(49, 2, 4.5)
        bridge.Position = Vector3.new(18, 4, 0)
        bridge.Anchored = true
        bridge.CanCollide = true
        bridge.Parent = platforms
        local narrowPanel = Instance.new("Part")
        narrowPanel.Name = "PlatformPanel2"
        narrowPanel.Size = Vector3.new(48.2, 0.10, 3.7)
        narrowPanel.Position = bridge.Position + Vector3.new(0, 1.055, 0)
        narrowPanel.Anchored = true
        narrowPanel.CanCollide = false
        narrowPanel.CanTouch = false
        narrowPanel.CanQuery = false
        narrowPanel.Parent = decor
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0), "Medium", true)
        -- One approved near-camera deck. The very narrow Tower Skybridge
        -- cannot fit 3 normal-size modules without long floating gaps:
        -- it retains the actual server-owned painted floor instead.
        expect(PremiumRouteMeshKit.count()).toBe(1)
        expect(narrowPanel.LocalTransparencyModifier).toBe(0)
        expect(PremiumRouteMeshKit.underdeckCount()).toBe(0)
        expect(deck.CanCollide).toBe(true)
        expect(bridge.CanCollide).toBe(true)
        expect(deck.Size).toBe(Vector3.new(12, 2, 12))
        expect(nativePanel.LocalTransparencyModifier).toBe(1)
        deck:SetAttribute("CollapsePhase", "Warning")
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0), "Medium", true)
        expect(PremiumRouteMeshKit.count()).toBe(0)
        expect(nativePanel.LocalTransparencyModifier).toBe(0)
        expect(narrowPanel.LocalTransparencyModifier).toBe(0)

        -- Public milestone: genuine approved bridge geometry now follows
        -- the LIVE physical Sky Promenade and Sky Spine, not fake local art.
        -- A plain 26 x 12 platform cannot impersonate a crossing route
        -- without the server's permanent and authored lane attributes.
        local crossing = Instance.new("Part")
        crossing.Name = "Platform3"
        crossing.Size = Vector3.new(26, 2, 12)
        crossing.Position = Vector3.new(3, 4, 0)
        crossing.Anchored = true
        crossing.CanCollide = true
        crossing:SetAttribute("ChaosPermanentRoute", true)
        crossing:SetAttribute("PromenadeLane", 1)
        crossing:SetAttribute("PromenadeStep", 3)
        crossing.Parent = platforms
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0),
            "Medium", true, Vector3.new(1, 0, 0))
        -- Source-footprint adaptive fit uses TWO full-width approved
        -- promenade modules plus one genuinely below-collider chassis.
        -- The 49x4.5 Towers Skybridge still never gets unsafe 3D scraps.
        expect(PremiumRouteMeshKit.count()).toBe(3)
        expect(narrowPanel.LocalTransparencyModifier).toBe(0)
        expect(PremiumRouteMeshKit.underdeckCount()).toBe(1)
        expect(crossing.CanCollide).toBe(true)
        local underfolder = workspace:FindFirstChild("PremiumRouteMeshLocal")
        local machine = underfolder:FindFirstChild("OriginalEngineeredUnderdeck3D")
        expect(machine ~= nil).toBe(true)
        local meshPart = machine:FindFirstChildWhichIsA("MeshPart", true)
        expect(meshPart ~= nil).toBe(true)
        expect(meshPart.CanCollide).toBe(false)
        expect(meshPart.CanTouch).toBe(false)
        expect(meshPart.CanQuery).toBe(false)
        local frame, dimensions = machine:GetBoundingBox()
        expect(frame.Position.Y + dimensions.Y * 0.5
            < crossing.Position.Y - crossing.Size.Y * 0.5).toBe(true)
        crossing:SetAttribute("PromenadeLane", nil)
        crossing:SetAttribute("PromenadeStep", nil)
        crossing:SetAttribute("SkySpineStep", 5)
        crossing:SetAttribute("SkySpineInterchange", true)
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0),
            "Medium", true, Vector3.new(1, 0, 0))
        expect(PremiumRouteMeshKit.count()).toBe(3)
        expect(PremiumRouteMeshKit.underdeckCount()).toBe(1)
        crossing:SetAttribute("ChaosPermanentRoute", false)
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0),
            "Medium", true, Vector3.new(1, 0, 0))
        expect(PremiumRouteMeshKit.count()).toBe(0)
        expect(PremiumRouteMeshKit.underdeckCount()).toBe(0)
        base.Size = Vector3.new(230, 2, 230)
        PremiumRouteMeshKit.sync(arena, Vector3.new(0, 12, 0), "Medium", true)
        expect(PremiumRouteMeshKit.count()).toBe(0)
        expect(PremiumRouteMeshKit.underdeckCount()).toBe(0)
        expect(deck.CanCollide).toBe(true)
        expect(bridge.CanCollide).toBe(true)
        PremiumRouteMeshKit.sync(nil, Vector3.zero, "Low", false)
        arena:Destroy()
        holder:Destroy()
    end)
    it("places owner-approved Sky Spine 3D only on real center interchange decks, preserving safe native fallback", function()
        -- The approved production Model ID and 1,696 real triangles are
        -- source/asset gated by build and Roblox upload #41660854748.
        -- This actual-engine scene checks collision, metadata, placement,
        -- LOD budgets, warning invisibility and native reappearance, not
        -- speculative network moderation or an Android screenshot.
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local holder = Instance.new("Folder")
        holder.Name = "PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified", true)
        holder.Parent = ReplicatedStorage
        local source = Instance.new("Model")
        source.Name = "OriginalSkySpineCrown"
        source:SetAttribute("OwnerVerified", true)
        source:SetAttribute("CosmeticOnly", true)
        source:SetAttribute("PremiumSkySpineCrown3D", true)
        source:SetAttribute("Original3DAssetId", 71492051540032)
        local imported = Instance.new("MeshPart")
        imported.Name = "ApprovedSourceBounds"
        imported.Size = Vector3.new(18.8, 20.52, 3.86)
        imported.Anchored = true
        imported.Parent = source
        local signal = Instance.new("MeshPart")
        signal.Name = "SkySpine_SIGNAL_Lens"
        signal.Size = Vector3.new(0.30, 0.48, 0.14)
        signal.Anchored = true
        signal.Parent = source
        source.Parent = holder

        local arena = Instance.new("Folder")
        arena.Name = "SkySpineOriginal3DEngineArena"
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.Anchored = true
        base.Parent = arena
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena

        local function makeDeck(index, step, offset)
            local deck = Instance.new("Part")
            deck.Name = "Platform" .. index
            deck.Position = Vector3.new(0, 15, offset)
            deck.Size = Vector3.new(12, 2, 20)
            deck.Anchored = true
            deck.CanCollide = true
            deck:SetAttribute("ChaosPermanentRoute", true)
            deck:SetAttribute("SkySpineInterchange", true)
            deck:SetAttribute("SkySpineStep", step)
            deck.Parent = platforms
            local crown = Instance.new("Part")
            crown.Name = "SkySpine" .. index .. "_InterchangeCrown"
            crown.Anchored = true
            crown.CanCollide = false
            crown:SetAttribute("SkySpineDecor", true)
            crown:SetAttribute("PerimeterPlatformIndex", index)
            crown.Parent = decor
            return deck, crown
        end
        -- The importer must accept every real high-route deck length,
        -- not just the synthetic 20-stud smoke fixture in this scene.
        for _, variantId in ipairs(ArenaVariants.Order) do
            local real = ArenaVariants.get(variantId)
            for _, step in ipairs({2, 5, 6, 9}) do
                local size = real.SkySpinePlatforms[step].size
                expect(size.X).toBe(12)
                expect(size.Y).toBe(2)
                expect(size.Z >= 14.5 and size.Z <= 33).toBe(true)
            end
        end
        local deck5, native5 = makeDeck(201, 5, 0)
        local deck6, native6 = makeDeck(202, 6, 24)
        local deck2, native2 = makeDeck(203, 2, -48)
        local deck9, native9 = makeDeck(204, 9, 72)
        local camera = Vector3.new(0, 20, 0)
        local budget = SkySpineCrownMeshKit.lightBudget
        expect(budget("Low", 0, true)).toBe(0)
        expect(budget("Medium", 0, true)).toBe(1)
        expect(budget("High", 0, true)).toBe(1)
        expect(budget("High", 0, false)).toBe(2)
        expect(budget("High", 1, false)).toBe(0)
        expect(budget("Medium", 2, true)).toBe(0)
        SkySpineCrownMeshKit.setDarknessGuard(false)
        -- Low Android now mounts one genuine near-camera crown, not a
        -- permanent primitive-only fallback. Physical deck remains solid.
        SkySpineCrownMeshKit.sync(arena, camera, "Low", true)
        expect(SkySpineCrownMeshKit.count()).toBe(1)
        expect(native5.LocalTransparencyModifier).toBe(1)
        expect(native2.LocalTransparencyModifier).toBe(0)
        expect(deck5.CanCollide).toBe(true)

        SkySpineCrownMeshKit.sync(arena, camera, "Medium", true,
            Vector3.new(0, 0, 1))
        expect(SkySpineCrownMeshKit.lightCount()).toBe(1)
        expect(SkySpineCrownMeshKit.count()).toBe(2)
        expect(native5.LocalTransparencyModifier).toBe(1)
        expect(native6.LocalTransparencyModifier).toBe(1)
        expect(native2.LocalTransparencyModifier).toBe(0)
        expect(SkySpineCrownMeshKit.outerCount()).toBe(0)
        expect(deck5.CanCollide).toBe(true)
        local localMeshes = workspace:FindFirstChild("OriginalSkySpineCrownLocal")
        expect(localMeshes ~= nil).toBe(true)
        local crownModel = nil
        for _, item in ipairs(localMeshes:GetChildren()) do
            if item:IsA("Model") and item:GetAttribute(
                "OriginalSkySpineStep") == 5 then
                crownModel = item
                break
            end
        end
        expect(crownModel ~= nil).toBe(true)
        expect(crownModel:GetAttribute("Original3DAssetId")).toBe(71492051540032)
        local fill = crownModel:FindFirstChild("OriginalSkySpineSignalFill", true)
        expect(fill ~= nil and fill:IsA("PointLight")).toBe(true)
        expect(fill.Parent:IsA("MeshPart")).toBe(true)
        expect(fill.Parent.Name:find("SIGNAL", 1, true) ~= nil).toBe(true)
        expect(fill.Shadows).toBe(false)
        expect(fill.Range <= 18).toBe(true)
        expect(fill.Brightness <= 0.35).toBe(true)
        SkySpineCrownMeshKit.setDarknessGuard(true)
        expect(fill.Enabled).toBe(false)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(0)
        SkySpineCrownMeshKit.setDarknessGuard(false)
        expect(fill.Enabled).toBe(true)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(1)
        -- An authentic late-replicated server crown must be occluded too.
        -- StreamingEnabled can deliver these native Parts after the mesh.
        local streamedNative = Instance.new("Part")
        streamedNative.Name = "SkySpine201_CommandRadar"
        streamedNative.CanCollide = false
        streamedNative:SetAttribute("SkySpineDecor", true)
        streamedNative:SetAttribute("PerimeterPlatformIndex", 201)
        streamedNative.Parent = decor
        expect(streamedNative.LocalTransparencyModifier).toBe(1)
        for _, part in ipairs(crownModel:GetDescendants()) do
            if part:IsA("BasePart") then
                expect(part:IsA("MeshPart")).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.CastShadow).toBe(false)
            end
        end

        deck5:SetAttribute("CollapsePhase", "Warning")
        -- Must react immediately to the real hazard BEFORE the next LOD tick.
        expect(native5.LocalTransparencyModifier).toBe(0)
        expect(streamedNative.LocalTransparencyModifier).toBe(0)
        expect(fill.Enabled).toBe(false)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(0)
        local geom = crownModel:FindFirstChildWhichIsA("MeshPart", true)
        expect(geom.LocalTransparencyModifier).toBe(1)
        SkySpineCrownMeshKit.sync(arena, camera, "Medium", true)
        expect(SkySpineCrownMeshKit.count()).toBe(2)
        expect(native6.LocalTransparencyModifier).toBe(1)
        expect(native2.LocalTransparencyModifier).toBe(1)
        deck5:SetAttribute("CollapsePhase", "Normal")
        SkySpineCrownMeshKit.sync(arena, camera, "High", true)
        expect(SkySpineCrownMeshKit.count()).toBe(4)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(2)
        expect(SkySpineCrownMeshKit.outerCount()).toBe(2)
        expect(native5.LocalTransparencyModifier).toBe(1)
        expect(native6.LocalTransparencyModifier).toBe(1)
        expect(native2.LocalTransparencyModifier).toBe(1)
        expect(native9.LocalTransparencyModifier).toBe(1)

        -- Even if the approved model disappears before the next camera
        -- sample, its exact native portico immediately reappears.
        local outerModel = nil
        for _, model in ipairs(localMeshes:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute(
                "OriginalSkySpineStep") == 2 then
                outerModel = model
                break
            end
        end
        expect(outerModel ~= nil).toBe(true)
        outerModel:Destroy()
        expect(native2.LocalTransparencyModifier).toBe(0)
        expect(SkySpineCrownMeshKit.count()).toBe(3)
        SkySpineCrownMeshKit.sync(arena, camera, "High", true)
        expect(SkySpineCrownMeshKit.count()).toBe(4)
        expect(native2.LocalTransparencyModifier).toBe(1)

        -- Mobile visual pressure must never alter real gameplay routes.
        SkySpineCrownMeshKit.sync(arena, camera, "High", true, nil, 1)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(0)
        expect(SkySpineCrownMeshKit.count()).toBe(2)
        SkySpineCrownMeshKit.sync(arena, camera, "High", true, nil, 2)
        expect(SkySpineCrownMeshKit.count()).toBe(1)
        SkySpineCrownMeshKit.sync(arena, camera, "Medium", true, nil, 2)
        expect(SkySpineCrownMeshKit.count()).toBe(0)
        expect(native5.LocalTransparencyModifier).toBe(0)
        SkySpineCrownMeshKit.sync(arena, camera, "High", true)
        expect(SkySpineCrownMeshKit.count()).toBe(4)

        -- A false physical platform cannot gain a cosmetic fake arch.
        deck5:SetAttribute("ChaosPermanentRoute", false)
        expect(native5.LocalTransparencyModifier).toBe(0)
        SkySpineCrownMeshKit.sync(arena, camera, "High", true)
        expect(SkySpineCrownMeshKit.count()).toBe(3)
        expect(deck5.CanCollide).toBe(true)
        expect(deck2.CanCollide).toBe(true)
        expect(deck9.CanCollide).toBe(true)
        base.Size = Vector3.new(230, 2, 230)
        expect(native6.LocalTransparencyModifier).toBe(0)
        expect(native9.LocalTransparencyModifier).toBe(0)
        expect(SkySpineCrownMeshKit.count()).toBe(0)
        SkySpineCrownMeshKit.sync(nil, Vector3.zero, "Low", false)
        expect(SkySpineCrownMeshKit.lightCount()).toBe(0)
        SkySpineCrownMeshKit.setDarknessGuard(true)
        arena:Destroy()
        holder:Destroy()
    end)
    it("mounts genuine approved suspended arena keel only BELOW real collision base, tiered and shrink safe", function()
        -- Source #41669929967 was moderation Approved. The CI registry
        -- verifies its real imported 3,332-triangle 7-material provenance.
        -- This Roblox engine scene checks actual Model/CFrame/physics/LOD
        -- contracts independently of any mocked image of the final game.
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local holder = Instance.new("Folder")
        holder.Name = "PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified", true)
        holder.Parent = ReplicatedStorage
        local source = Instance.new("Model")
        source.Name = "OriginalArenaKeel"
        source:SetAttribute("OwnerVerified", true)
        source:SetAttribute("CosmeticOnly", true)
        source:SetAttribute("PremiumArenaKeel3D", true)
        source:SetAttribute("Original3DAssetId", 121436301473005)
        local imported = Instance.new("MeshPart")
        imported.Name = "RealSourceGeometryFixture"
        imported.Size = Vector3.new(56.2, 14.8, 54)
        imported.Anchored = true
        imported.Parent = source
        source.Parent = holder

        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena:SetAttribute("VariantId", "Classic")
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.Anchored = true
        base.CanCollide = true
        base.CFrame = CFrame.new(100, 10, 240)
        base.Parent = arena
        local camera = base.Position + Vector3.new(0, 17, 0)
        ArenaKeelMeshKit.sync(arena, camera, "Low", true)
        expect(ArenaKeelMeshKit.count()).toBe(1)
        local bucket = workspace:FindFirstChild("OriginalArenaKeelLocal")
        expect(bucket ~= nil).toBe(true)
        for _, model in ipairs(bucket:GetChildren()) do
            expect(model:IsA("Model")).toBe(true)
            expect(model:GetAttribute("Original3DAssetId")).toBe(121436301473005)
            for _, part in ipairs(model:GetDescendants()) do
                if part:IsA("BasePart") then
                    expect(part:IsA("MeshPart")).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    local upper = part.Position.Y + part.Size.Y * .5
                    expect(upper < base.Position.Y - base.Size.Y * .5).toBe(true)
                end
            end
        end
        ArenaKeelMeshKit.sync(arena, camera, "Medium", true)
        expect(ArenaKeelMeshKit.count()).toBe(3)
        ArenaKeelMeshKit.sync(arena, camera, "High", true)
        expect(ArenaKeelMeshKit.count()).toBe(5)
        expect(base.CanCollide).toBe(true)
        -- The real disaster changes authoritative Size: remove all 3D
        -- immediately, even BEFORE the next camera sampler callback.
        base.Size = Vector3.new(230, 2, 230)
        expect(ArenaKeelMeshKit.count()).toBe(0)
        ArenaKeelMeshKit.sync(arena, camera, "High", true)
        expect(ArenaKeelMeshKit.count()).toBe(0)
        ArenaKeelMeshKit.sync(nil, Vector3.zero, "Low", false)
        arena:Destroy()
        holder:Destroy()
    end)
    it("swaps authentic 3D underfloor beam bays on Classic and Crossroads with safe native rollback", function()
        -- The imported production source is approved Model 84582262145054.
        -- The smoke fixture has matching real MeshPart dimensions; runtime
        -- still verifies the exact owner provenance and sanitized geometry.
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local holder = Instance.new("Folder")
        holder.Name = "PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified", true)
        holder.Parent = ReplicatedStorage
        local source = Instance.new("Model")
        source.Name = "OriginalUnderdeckChassis"
        source:SetAttribute("OwnerVerified", true)
        source:SetAttribute("CosmeticOnly", true)
        source:SetAttribute("PremiumUnderdeck3D", true)
        source:SetAttribute("Original3DAssetId", 84582262145054)
        -- The actual owner-approved chassis has SEVEN material MeshParts.
        -- A previous one-part fixture was invalid under Low's existing
        -- seven-mesh provenance gate, so it tested rejection rather than
        -- successful mount. Match the real asset's 7 material groups while
        -- keeping the existing 23.3 × 4.8 × 9.9 source envelope.
        for i, material in ipairs({
            "ARMOR", "BRUSHED", "CARBON", "GRIP",
            "ALLOY", "CERAMIC", "SIGNAL",
        }) do
            local realGeometry = Instance.new("MeshPart")
            realGeometry.Name = "ApprovedMaterial_" .. material
            realGeometry.Size = if i == 1
                then Vector3.new(23.3, 4.8, 9.9)
                else Vector3.new(3.8, .38, 1.15)
            realGeometry.Anchored = true
            realGeometry.CanCollide = false
            realGeometry.CanTouch = false
            realGeometry.CanQuery = false
            realGeometry.Parent = source
        end
        source.Parent = holder

        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena:SetAttribute("VariantId", "Classic")
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.CFrame = CFrame.new(0, 10, 0)
        base.Anchored = true
        base.CanCollide = true
        base.Parent = arena
        local nativeBucket = Instance.new("Folder")
        nativeBucket.Name = "ArenaUnderstructureLocal"
        nativeBucket.Parent = workspace

        local function nativeBeam(name, cframe, size)
            local part = Instance.new("Part")
            part.Name = name
            part.CFrame = cframe
            part.Size = size
            part.Transparency = .25
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part:SetAttribute("OriginalUnderstructureBeam", true)
            part.Parent = nativeBucket
            return part
        end
        local beams = {}
        for index, offset in ipairs({-84, -60, -36, 36, 60, 84}) do
            beams[index] = nativeBeam("UnderClassicBeamX" .. index,
                CFrame.new(offset, 4.6, 0), Vector3.new(23.3, 2.2, 6))
        end
        local camera = Vector3.new(-84, 27, 0)
        UnderstructureBeamMeshKit.sync(arena, camera, "Low", true)
        expect(UnderstructureBeamMeshKit.count()).toBe(1)
        expect(beams[1].Transparency).toBe(1)
        expect(beams[6].Transparency).toBe(.25)
        local originals = workspace:FindFirstChild("OriginalUnderstructureBeamsLocal")
        expect(originals ~= nil).toBe(true)
        local clone = originals:FindFirstChild(
            "OriginalApprovedUnderstructure3D_UnderClassicBeamX1")
        expect(clone ~= nil and clone:IsA("Model")).toBe(true)
        expect(clone:GetAttribute("Original3DAssetId")).toBe(84582262145054)
        for _, part in ipairs(clone:GetDescendants()) do
            if part:IsA("BasePart") then
                expect(part:IsA("MeshPart")).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.Position.Y + part.Size.Y * .5
                    < base.Position.Y - base.Size.Y * .5).toBe(true)
            end
        end
        UnderstructureBeamMeshKit.sync(arena, camera, "Medium", true)
        expect(UnderstructureBeamMeshKit.count()).toBe(4)
        UnderstructureBeamMeshKit.sync(arena, camera, "High", true)
        -- The six available fixture beams fit under High's twelve-model
        -- ceiling. Verify actual geometry, not an outdated four-model cap.
        expect(UnderstructureBeamMeshKit.count()).toBe(6)
        expect(base.CanCollide).toBe(true)

        -- Crossroads has different non-physical beams but the SAME
        -- owner-approved importer and Android tier caps.
        UnderstructureBeamMeshKit.reset()
        for _, beam in ipairs(beams) do
            expect(beam.Transparency).toBe(.25)
            beam:Destroy()
        end
        arena:SetAttribute("VariantId", "Crossroads")
        local north = nativeBeam("UnderCrossroadsBeamN1",
            CFrame.new(0, 4.1, -42), Vector3.new(7, 2, 23.3))
        local east = nativeBeam("UnderCrossroadsBeamE1",
            CFrame.new(42, 4.1, 0), Vector3.new(23.3, 2, 7))
        UnderstructureBeamMeshKit.sync(arena, Vector3.new(0, 25, -42),
            "Medium", true)
        expect(UnderstructureBeamMeshKit.count()).toBe(2)
        expect(north.Transparency).toBe(1)
        expect(east.Transparency).toBe(1)

        -- A genuine Shrinking Arena size change must synchronously remove
        -- BOTH 3D mounts and restore the original cosmetic beams.
        base.Size = Vector3.new(230, 2, 230)
        expect(UnderstructureBeamMeshKit.count()).toBe(0)
        expect(north.Transparency).toBe(.25)
        expect(east.Transparency).toBe(.25)
        expect(base.CanCollide).toBe(true)
        base.Size = Vector3.new(320, 2, 320)
        source:SetAttribute("OwnerVerified", false)
        UnderstructureBeamMeshKit.sync(arena, Vector3.new(0, 25, -42),
            "Medium", true)
        expect(UnderstructureBeamMeshKit.count()).toBe(0)
        expect(north.Transparency).toBe(.25)

        UnderstructureBeamMeshKit.reset()
        nativeBucket:Destroy()
        arena:Destroy()
        holder:Destroy()
    end)

    it("renders real original 3D ground MeshParts within Android tier caps and never leaves a phantom floor", function()
        -- Reuse the existing authenticated source→client engine integration
        -- suite at the public release milestone; do not invent image mocks
        -- or weaken the real world collision/shrinking restrictions.
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local holder = Instance.new("Folder")
        holder.Name = "PremiumRouteMeshTemplates"
        holder:SetAttribute("OwnerVerified", true)
        holder.Parent = ReplicatedStorage
        local template = Instance.new("Model")
        template.Name = "PremiumGroundTile"
        template:SetAttribute("OwnerVerified", true)
        template:SetAttribute("CosmeticOnly", true)
        template:SetAttribute("Original3DAssetId", 72507987666671)
        local mesh = Instance.new("MeshPart")
        mesh.Name = "ImportedOriginal3DGeometry"
        mesh.Size = Vector3.new(48.5, 0.25, 48.5)
        mesh.Anchored = true
        mesh.Parent = template
        template.Parent = holder

        local arena = Instance.new("Folder")
        arena.Name = "Ground3DSourceSmokeArena"
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.Anchored = true
        base.CanCollide = true
        base.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        for index = 1, 8 do
            local ground = Instance.new("Part")
            ground.Name = "PremiumGroundModule" .. index
            ground.Size = Vector3.new(49.133, 0.035, 49.133)
            ground.CFrame = base.CFrame
                * CFrame.new(((index - 1) % 4 - 1.5) * 50.33, 1.153,
                    (math.floor((index - 1) / 4) - 0.5) * 50.33)
            ground.Anchored = true
            ground.CanCollide = false
            ground.CanTouch = false
            ground.CanQuery = false
            ground:SetAttribute("OriginalGroundFinish", true)
            ground:SetAttribute("PremiumArchitecturalSurface", true)
            ground.Parent = decor
        end
        local camera = Vector3.new(0, 14, 0)
        -- The verified 2,976-triangle source now uses 2/8/24 resident
        -- Low/Medium/High caps, but this small engine fixture has 8 bays.
        PremiumGroundMeshKit.sync(arena, camera, "Low", true)
        expect(PremiumGroundMeshKit.count()).toBe(2)
        PremiumGroundMeshKit.sync(arena, camera, "Medium", true)
        expect(PremiumGroundMeshKit.count()).toBe(8)
        PremiumGroundMeshKit.sync(arena, camera, "High", true)
        expect(PremiumGroundMeshKit.count()).toBe(8)
        local cosmeticBucket = workspace:FindFirstChild("OriginalPremiumGroundMeshesLocal")
        expect(cosmeticBucket ~= nil).toBe(true)
        for _, clone in ipairs(cosmeticBucket:GetChildren()) do
            expect(clone:IsA("Model")).toBe(true)
            expect(clone:GetAttribute("OriginalGroundMeshId")).toBe(72507987666671)
            for _, part in ipairs(clone:GetDescendants()) do
                if part:IsA("BasePart") then
                    expect(part:IsA("MeshPart")).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                end
            end
        end
        -- A real shrink must remove ALL cosmetic floor meshes. Never move,
        -- hide, resize or replace the server's authoritative ground Base.
        base.Size = Vector3.new(231, 2, 231)
        PremiumGroundMeshKit.sync(arena, camera, "High", true)
        expect(PremiumGroundMeshKit.count()).toBe(0)
        expect(base.CanCollide).toBe(true)
        expect(base.Size).toBe(Vector3.new(231, 2, 231))
        PremiumGroundMeshKit.sync(nil, Vector3.zero, "Low", false)
        arena:Destroy()
        holder:Destroy()
    end)
    it("builds sixteen physical side lookouts without changing original route indices", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local variant = ArenaVariants.get(id)
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local platforms = arena:FindFirstChild("Platforms")
            local base = arena:FindFirstChild("Base")
            local start = #variant.Platforms + #variant.PerimeterPlatforms
            expect(#platforms:GetChildren()).toBe(
                start + 20 + #(variant.SkywayPlatforms or {})
                    + #(variant.SpokePlatforms or {})
                    + #(variant.PromenadePlatforms or {})
                    + #(variant.SkySpinePlatforms or {})
            )
            for route = 1, 4 do
                local forkIndex = #variant.Platforms
                    + (route - 1) * ArenaVariants.PerimeterSteps + 5
                for side = -1, 1, 2 do
                    local arrow = arena:FindFirstChild("Decor")
                        :FindFirstChild("BranchForkArrow" .. route .. "_"
                            .. tostring(side))
                    expect(arrow ~= nil and arrow:IsA("BasePart")).toBe(true)
                    expect(arrow:GetAttribute("PerimeterPlatformIndex"))
                        .toBe(forkIndex)
                    expect(arrow.CanCollide).toBe(false)
                end
                for step = 1, 4 do
                    local index = start + (route - 1) * 4 + step
                    local deck = platforms:FindFirstChild("Platform" .. index)
                    expect(deck ~= nil and deck:IsA("BasePart")).toBe(true)
                    expect(deck.Anchored).toBe(true)
                    expect(deck.CanCollide).toBe(true)
                    expect(deck:GetAttribute("BranchRoute")).toBe(route)
                    expect(deck:GetAttribute("BranchStep")).toBe(step)
                    expect(deck:GetAttribute("BranchParentStep")).toBe(5)
                    -- Both terminal lookouts and all physical access
                    -- landings remain connected throughout collapse waves.
                    expect(deck:GetAttribute("ChaosPermanentRoute")).toBe(true)
                    local decor = arena:FindFirstChild("Decor")
                    for side = -1, 1, 2 do
                        local mark = decor:FindFirstChild(
                            "BranchStepArrow" .. route .. "_" .. step
                                .. "_" .. tostring(side)
                        )
                        expect(mark ~= nil and mark:IsA("BasePart")).toBe(true)
                        expect(mark:GetAttribute("PerimeterPlatformIndex"))
                            .toBe(index)
                        expect(mark.CanCollide).toBe(false)
                        expect(mark.CanQuery).toBe(false)
                    end
                    expect(math.abs(deck.Position.Y - deck.Size.Y * 0.5
                        - (base.Position.Y + base.Size.Y * 0.5)) < 0.001)
                        .toBe(true)
                    if step == 4 then
                        local billboard = deck:FindFirstChild("SideLookoutLabel")
                        expect(billboard ~= nil and billboard:IsA("BillboardGui"))
                            .toBe(true)
                        expect(billboard.Adornee).toBe(deck)
                        expect(billboard.MaxDistance <= 80).toBe(true)
                        expect(billboard.AlwaysOnTop).toBe(false)
                    end
                end
            end
            root:Destroy()
        end
    end)

    it("builds physical Tower Run bridges with purely cosmetic edge rails", function()
        local root = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local decor = arena and arena:FindFirstChild("Decor")
        expect(platforms ~= nil).toBe(true)
        expect(decor ~= nil).toBe(true)

        local bridges = 0
        for _, p in ipairs((platforms :: Folder):GetChildren()) do
            if p:GetAttribute("ChaosSkybridge") == true then
                bridges += 1
                expect(p.CanCollide).toBe(true)
                expect(p:IsA("BasePart")).toBe(true)
                -- The server panel exists on every skybridge too; client
                -- markings must clear its actual upper face.
                local index = p.Name:match("^Skybridge(%d+)$")
                expect(index ~= nil).toBe(true)
                local panel = decor:FindFirstChild("PlatformPanel" .. index)
                expect(panel ~= nil).toBe(true)
                expect(panel.CanCollide).toBe(false)
                expect(panel.Size.Y > 0).toBe(true)
                expect(math.abs(p.Position.Y + p.Size.Y * 0.5
                    - (Config.ArenaCenter.Y + 13)) < 0.001).toBe(true)
            end
        end
        expect(bridges).toBe(4)
        -- Permanently safe bridges supply a consistent escape route; only
        -- adjacent conventional platforms participate in random collapse.
        local eligible = DisappearingPlatforms.eligiblePlatforms(platforms, {})
        expect(#eligible > 0).toBe(true)
        for _, candidate in ipairs(eligible) do
            expect(candidate:GetAttribute("ChaosSkybridge") == true).toBe(false)
        end

        for _, item in ipairs((decor :: Folder):GetChildren()) do
            if string.find(item.Name, "SkybridgeRail", 1, true) then
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
            end
        end
        expect((decor :: Folder):FindFirstChild("SkybridgeRail18_-1") ~= nil).toBe(true)

        -- The world model must actually build the four authored climbing
        -- routes (not merely declare them in ArenaVariants metadata).
        local tierCount = {[1] = 0, [2] = 0, [3] = 0, [4] = 0}
        for _, platform in ipairs((platforms :: Folder):GetChildren()) do
            local tier = tonumber(platform:GetAttribute("RouteTier"))
            if tier then
                expect(platform.CanCollide).toBe(true)
                tierCount[tier] += 1
            end
        end
        local authored = ArenaVariants.get("Towers")
        expect(#(platforms :: Folder):GetChildren()).toBe(
            #authored.Platforms + #authored.PerimeterPlatforms
                + #authored.BranchPlatforms + #authored.CrosslinkPlatforms
                + #authored.PromenadePlatforms
                + #authored.SkySpinePlatforms
        )
        -- Original 21 decks and Skybridges 18–21 are unchanged.
        -- The outer rim, 16 corner spurs and four physical crosslinks
        -- expand the routes without changing legacy game-system indices.
        expect(tierCount[1]).toBe(9)
        expect(tierCount[2]).toBe(12)
        expect(tierCount[3]).toBe(12)
        expect(tierCount[4]).toBe(36 + #authored.PromenadePlatforms
            + #authored.SkySpinePlatforms)

        -- Floor guidance must be genuinely visible but never obstruct
        -- escape movement, hazard collision or updraft pads.
        local guides = 0
        for _, item in ipairs((decor :: Folder):GetChildren()) do
            if item.Name:match("^TowerAscentChevron%d+_%-?%d+$") then
                guides += 1
                expect(item:IsA("BasePart")).toBe(true)
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
                expect(item.CastShadow).toBe(false)
                expect(item.Transparency < 0.7).toBe(true)
            end
        end
        expect(guides).toBe(8)
        root:Destroy()
    end)

    it("draws twenty-four noncolliding return-route chevrons in Crossroads", function()
        local root = MapBuilder.build(Config, "Crossroads", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local decor = arena and arena:FindFirstChild("Decor")
        expect(decor ~= nil).toBe(true)
        local count = 0
        for _, part in ipairs((decor :: Folder):GetChildren()) do
            if string.find(part.Name, "FluxRouteChevron", 1, true) then
                count += 1
                expect(part:IsA("BasePart")).toBe(true)
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.Size.Y <= 0.06).toBe(true)
            end
        end
        expect(count).toBe(24)

        -- Every authored interchange deck is actually physical, with a
        -- visible tier code that contracts alongside its collision.
        local platforms = arena:FindFirstChild("Platforms")
        expect(platforms ~= nil).toBe(true)
        expect(#(platforms :: Folder):GetChildren()).toBe(
            #ArenaVariants.get("Crossroads").Platforms + 52
                + #ArenaVariants.get("Crossroads").PromenadePlatforms
                + #ArenaVariants.get("Crossroads").SkySpinePlatforms
        )
        local tiers = {[1] = 0, [2] = 0, [3] = 0, [4] = 0}
        for index = 1, 17 do
            local deck = platforms:FindFirstChild("Platform" .. index)
            expect(deck ~= nil).toBe(true)
            expect(deck.CanCollide).toBe(true)
            local tier = tonumber(deck:GetAttribute("RouteTier"))
            expect(tier ~= nil).toBe(true)
            tiers[tier] += 1
            local finish = decor:FindFirstChild("PlatformPanel" .. index)
            expect(finish ~= nil).toBe(true)
            expect(finish.CanCollide).toBe(false)
        end
        expect(tiers[1]).toBe(5)
        expect(tiers[2]).toBe(4)
        expect(tiers[3]).toBe(4)
        expect(tiers[4]).toBe(4)
        root:Destroy()
    end)

    it("builds eight connected, solid Orbital helix ramps with cosmetic rails", function()
        local variant = ArenaVariants.get("Orbital")
        local center = Config.ArenaCenter
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local circuit = arena and arena:FindFirstChild("HelixCircuit")
        expect(circuit ~= nil).toBe(true)
        expect(OrbitalHelix.Count).toBe(8)

        local helixCount, entryCount, coreCount, noncolliding = 0, 0, 0, 0
        for _, obj in ipairs((circuit :: Folder):GetChildren()) do
            expect(obj:IsA("BasePart")).toBe(true)
            expect(obj.Anchored).toBe(true)
            expect(type(obj:GetAttribute("OrbitRouteGroup"))).toBe("string")
            local isHelix = obj:GetAttribute("OrbitalHelixRamp") == true
            local isEntry = obj:GetAttribute("OrbitalAccessRamp") == true
            local isCore = obj:GetAttribute("OrbitalCoreRamp") == true
            if isHelix or isEntry or isCore then
                if isHelix then helixCount += 1 end
                if isEntry then entryCount += 1 end
                if isCore then coreCount += 1 end
                local index = isHelix
                    and obj:GetAttribute("HelixLane")
                    or tonumber(obj.Name:match("%d+$"))
                local route = (isHelix or obj.Name == "HelixRamp9")
                    and OrbitalHelix.route(variant, center, index)
                    or OrbitalHelix.accessRoute(variant, center, index,
                        isEntry and "Entry" or "Core")
                expect(route ~= nil).toBe(true)
                expect(obj.CanCollide).toBe(true)
                expect(obj.CanTouch).toBe(true)
                expect(obj.CanQuery).toBe(true)
                expect(obj.Size.X >= 4.5).toBe(true)
                expect(obj.Size.Z >= 7).toBe(true)
                expect((obj.Position - route.CFrame.Position).Magnitude < 0.01)
                    .toBe(true)
                expect(obj.CFrame.LookVector:Dot(
                    (route.Finish - route.Start).Unit) > 0.999).toBe(true)
            else
                noncolliding += 1
                expect(obj.CanCollide).toBe(false)
                expect(obj.CanTouch).toBe(false)
                expect(obj.CanQuery).toBe(false)
                expect(obj.CastShadow).toBe(false)
            end
        end
        expect(helixCount).toBe(8)
        expect(entryCount).toBe(8)
        expect(coreCount).toBe(8)
        expect(noncolliding).toBe(132)
        -- The prior certified ninth core connector remains a real,
        -- transit-only route; no ninth mastery/scoring trigger is added.
        local core = circuit:FindFirstChild("HelixRamp9")
        expect(core ~= nil).toBe(true)
        expect(core:GetAttribute("OrbitalCoreRamp")).toBe(true)
        expect(core:GetAttribute("OrbitalHelixRamp") == nil).toBe(true)
        expect(circuit:FindFirstChild("CoreRamp2") == nil).toBe(true)
        local upper = arena:FindFirstChild("Platforms"):FindFirstChild("Platform18")
        local lower = arena:FindFirstChild("Platforms"):FindFirstChild("Platform17")
        local headroom = upper.Position.Y - upper.Size.Y * 0.5
            - (lower.Position.Y + lower.Size.Y * 0.5)
        expect(headroom >= 8.4).toBe(true)

        -- World signs must label actual solid access routes, not create
        -- fake walkable geometry. Check all eight entries and eight cores,
        -- including the legacy ninth (transit-only) connector.
        local signs = {}
        local count = 0
        for _, obj in ipairs(circuit:GetChildren()) do
            local kind = OrbitalRouteSignKit.kind(obj)
            if kind then
                count += 1
                local sign = OrbitalRouteSignKit.create(
                    obj, obj, "High", "fr-fr"
                )
                expect(sign ~= nil).toBe(true)
                expect(sign:IsA("SurfaceGui")).toBe(true)
                expect(sign.Parent).toBe(obj)
                expect(sign.Adornee).toBe(obj)
                table.insert(signs, sign)
                expect(sign.Face).toBe(Enum.NormalId.Top)
                expect(sign.AlwaysOnTop).toBe(false)
                expect(sign.Active).toBe(false)
                expect(sign.MaxDistance <= 115).toBe(true)
                local plate = sign:FindFirstChild("EtchedWayfindingPlate")
                local name = plate and plate:FindFirstChild("RouteName")
                expect(name ~= nil).toBe(true)
                expect(name.Text == (kind == "Entry" and "MONTER" or "RÉACTEUR"))
                    .toBe(true)
                expect(plate:FindFirstChild("DestinationHint") ~= nil)
                    .toBe(true)
            end
        end
        expect(count).toBe(16)
        expect(#signs).toBe(16)
        expect(OrbitalRouteSignKit.kind(core)).toBe("Core")
        local helixOne = circuit:FindFirstChild("HelixRamp1")
        expect(OrbitalRouteSignKit.kind(helixOne) == nil).toBe(true)
        expect(OrbitalRouteSignKit.create(helixOne, helixOne, "High", "en"))
            .toBe(nil)
        expect(OrbitalRouteSignKit.copy("Entry", "en-us")[1]).toBe("ASCEND")
        expect(OrbitalRouteSignKit.copy("Core", "fr-fr")[2])
            .toBe("DERNIER PALIER")

        -- Low-end mobile hardware keeps concise static wayfinding, but
        -- no extra decorative caption, lights, collisions or local parts.
        local low = OrbitalRouteSignKit.create(core, core, "Low", "en-us")
        table.insert(signs, low)
        expect(low ~= nil and low.Adornee == core).toBe(true)
        expect(low.PixelsPerStud).toBe(16)
        expect(low:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("DestinationHint") == nil).toBe(true)
        expect(low:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("RouteName").Text).toBe("CORE")
        local lowFr = OrbitalRouteSignKit.create(core, core, "Low", "fr-fr")
        table.insert(signs, lowFr)
        expect(lowFr:FindFirstChild("EtchedWayfindingPlate")
            :FindFirstChild("RouteName").Text).toBe("NOYAU")
        for _, sign in ipairs(signs) do
            for _, descendant in ipairs(sign:GetDescendants()) do
                expect(descendant:IsA("BasePart")).toBe(false)
                expect(descendant:IsA("PointLight")).toBe(false)
                expect(descendant:IsA("ParticleEmitter")).toBe(false)
            end
            -- Exactly these locally owned SurfaceGuis are removed on a
            -- streamed arena replacement or VFX quality change.
            sign:Destroy()
        end
        -- Existing collision/deck transform remains authoritative.
        expect(core.CanCollide).toBe(true)
        expect(core:FindFirstChild("OrbitalCoreNavigation") == nil)
            .toBe(true)

        local swapped = MapBuilder.buildArena(Config, "Classic", ArenaVariants)
        expect(swapped:FindFirstChild("HelixCircuit") == nil).toBe(true)
        root:Destroy()
    end)

    it("returns sixteen survivors to separated, solid-free lobby slots", function()
        local root = MapBuilder.build(Config, "Classic", ArenaVariants)
        local lobby = root:FindFirstChild("Lobby")
        local spawn = lobby and lobby:FindFirstChild("LobbySpawn")
        local floor = lobby and lobby:FindFirstChild("Floor")
        local decor = lobby and lobby:FindFirstChild("Decor")
        expect(lobby ~= nil and spawn ~= nil and floor ~= nil and decor ~= nil).toBe(true)

        local positions = LobbyReturnFormation.positions(spawn, floor, decor, 16)
        expect(#positions).toBe(16)
        expect(#LobbyReturnFormation.positions(nil, nil, nil, 3)).toBe(0)

        local floorTop = floor.Position.Y + floor.Size.Y * 0.5
        for index, candidate in ipairs(positions) do
            local onFloor = floor.CFrame:PointToObjectSpace(candidate)
            expect(math.abs(onFloor.X) + 2.6 < floor.Size.X * 0.5).toBe(true)
            expect(math.abs(onFloor.Z) + 2.6 < floor.Size.Z * 0.5).toBe(true)

            for _, obstacle in ipairs(decor:GetDescendants()) do
                if obstacle:IsA("BasePart") and obstacle.CanCollide then
                    local high = obstacle.Position.Y + obstacle.Size.Y * 0.5
                    local low = obstacle.Position.Y - obstacle.Size.Y * 0.5
                    if high > floorTop + 0.8 and low < floorTop + 8 then
                        local localCandidate = obstacle.CFrame:PointToObjectSpace(candidate)
                        local intersects = math.abs(localCandidate.X)
                            < obstacle.Size.X * 0.5 + 2.6
                            and math.abs(localCandidate.Z)
                            < obstacle.Size.Z * 0.5 + 2.6
                        expect(intersects).toBe(false)
                    end
                end
            end

            for otherIndex = index + 1, #positions do
                local delta = candidate - positions[otherIndex]
                local horizontal = Vector3.new(delta.X, 0, delta.Z)
                expect(horizontal.Magnitude >= 6.4).toBe(true)
            end
        end

        root:Destroy()
    end)

    it("renders only safe, owned 3D cosmetics beyond playable arena edges", function()
        local asset = Instance.new("Model")
        asset.Name = "UntrustedAssetPackage"
        local mesh = Instance.new("Part")
        mesh.Name = "OriginalMesh"
        mesh.Size = Vector3.new(13, 12, 3)
        mesh.Position = Vector3.new(0, 6, 0)
        mesh.Parent = asset
        local scriptInside = Instance.new("Script")
        scriptInside.Name = "UntrustedScriptMustNotRun"
        scriptInside.Parent = mesh
        local particles = Instance.new("ParticleEmitter")
        particles.Name = "UntrustedParticles"
        particles.Parent = mesh
        local sourceScript = Instance.new("ModuleScript")
        sourceScript.Parent = asset

        local sanitized = OriginalMeshScenery.sanitize(asset)
        expect(sanitized ~= nil).toBe(true)
        expect(#(sanitized :: Model):GetDescendants()).toBe(1)
        local cleanPart = (sanitized :: Model):FindFirstChild("OriginalMesh")
        expect(cleanPart ~= nil and cleanPart:IsA("BasePart")).toBe(true)
        if cleanPart and cleanPart:IsA("BasePart") then
            expect(cleanPart.Anchored).toBe(true)
            expect(cleanPart.CanCollide).toBe(false)
            expect(cleanPart.CanTouch).toBe(false)
            expect(cleanPart.CanQuery).toBe(false)
            expect(cleanPart.CastShadow).toBe(false)
            expect(cleanPart:FindFirstChild("UntrustedScriptMustNotRun") == nil)
                .toBe(true)
            expect(cleanPart:FindFirstChild("UntrustedParticles") == nil)
                .toBe(true)
        end

        -- Source models may have a stale authored/importer WorldPivot.
        -- Moving cloned Parts individually does not repair it automatically.
        -- This intentionally wrong pivot must not reach mounted scenery.
        (sanitized :: Model).WorldPivot = CFrame.new(900, 80, -900)

        for _, variantId in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena and arena:FindFirstChild("Decor")
            local base = arena and arena:FindFirstChild("Base")
            expect(base ~= nil and decor ~= nil).toBe(true)
            local placements = OriginalMeshScenery.placements(base, variantId)
            expect(#placements).toBe(8)
            local art = {}
            for _, slot in ipairs(placements) do
                art[slot.asset] = (art[slot.asset] or 0) + 1
            end
            -- Each arena uses all six approved originals, but repeats two
            -- signature silhouettes for its own eight-slot skyline.
            local expected = if variantId == "Orbital"
                then {orbital_halo_array = 2, perimeter_gate = 2,
                    reactor_spire = 1, sky_transit_exchange = 1,
                    plasma_foundry = 1, service_crane = 1}
                elseif variantId == "Towers"
                then {service_crane = 2, sky_transit_exchange = 2,
                    reactor_spire = 1, perimeter_gate = 1,
                    plasma_foundry = 1, orbital_halo_array = 1}
                elseif variantId == "Crossroads"
                then {perimeter_gate = 2, sky_transit_exchange = 2,
                    plasma_foundry = 1, service_crane = 1,
                    orbital_halo_array = 1, reactor_spire = 1}
                elseif variantId == "Harbor"
                then {service_crane = 2, plasma_foundry = 2,
                    perimeter_gate = 1, sky_transit_exchange = 1,
                    reactor_spire = 1, orbital_halo_array = 1}
                else {perimeter_gate = 2, plasma_foundry = 2,
                    reactor_spire = 1, service_crane = 1,
                    sky_transit_exchange = 1, orbital_halo_array = 1}
            for key, n in pairs(expected) do
                expect(art[key]).toBe(n)
            end
            for key, n in pairs(art) do
                expect(expected[key]).toBe(n)
            end
            local templates = {
                perimeter_gate = sanitized,
                reactor_spire = sanitized,
                service_crane = sanitized,
                plasma_foundry = sanitized,
                sky_transit_exchange = sanitized,
                orbital_halo_array = sanitized,
            }
            local count = OriginalMeshScenery.mount(arena, templates)
            expect(count).toBe(8)
            expect(OriginalMeshScenery.mount(arena, templates)).toBe(0)
            expect(arena:GetAttribute("Original3DSceneryCount")).toBe(8)
            expect(arena:GetAttribute("Original3DSceneryComplete")).toBe(true)
            local bucket = decor and decor:FindFirstChild("Original3DScenery")
            expect(bucket ~= nil).toBe(true)
            expect(#(bucket :: Folder):GetChildren()).toBe(8)

            for _, entry in ipairs(placements) do
                local placed = bucket and bucket:FindFirstChild(entry.name)
                expect(placed ~= nil and placed:IsA("Model")).toBe(true)
                if placed and placed:IsA("Model") then
                    expect(placed:GetAttribute("Original3DAssetId"))
                        .toBe(entry.assetId)
                    expect(placed:GetAttribute("CosmeticOnly")).toBe(true)
                    local box, dimensions = placed:GetBoundingBox()
                    expect(dimensions.Y > 0).toBe(true)
                    -- The LOD computes distance with GetPivot(), not
                    -- GetBoundingBox(); both must refer to the *mounted*
                    -- exterior location, never the stale template pivot.
                    local pivot = placed:GetPivot().Position
                    expect(math.abs(pivot.X - box.Position.X) < 0.05)
                        .toBe(true)
                    expect(math.abs(pivot.Z - box.Position.Z) < 0.05)
                        .toBe(true)
                    -- This deliberately narrow 13x12x3 sanitized test
                    -- mesh receives FOUR base layers, not the seven wider
                    -- chassis details reserved for true approved assets.
                    -- Keep both sizes covered: imported scene LOD must
                    -- still pivot on the actual mesh after augmentation.
                    expect(placed:GetAttribute("OriginalFoundationPieceCount"))
                        .toBe(4)
                    expect(math.abs(pivot.Y - box.Position.Y) < 8)
                        .toBe(true)
                    expect((pivot - Vector3.new(900, 80, -900)).Magnitude > 400)
                        .toBe(true)
                    for _, p in ipairs(placed:GetDescendants()) do
                        expect(p:IsA("BasePart")).toBe(true)
                        if p:IsA("BasePart") then
                            expect(p.Anchored).toBe(true)
                            expect(p.CanCollide).toBe(false)
                            expect(p.CanTouch).toBe(false)
                            expect(p.CanQuery).toBe(false)
                            expect(p.CastShadow).toBe(false)
                        end
                    end
                    local builtSupports = 0
                    local validNames = {
                        FoundationShoulder = true, FoundationInset = true,
                        FoundationBallast = true, FoundationGroundPad = true,
                    }
                    for _, support in ipairs(placed:GetChildren()) do
                        if support:GetAttribute("OriginalFoundationVisual") == true then
                            expect(support:IsA("Part")).toBe(true)
                            expect(validNames[support.Name]).toBe(true)
                            builtSupports += 1
                        end
                    end
                    expect(builtSupports).toBe(4)
                    local x, z = entry.position.X, entry.position.Z
                    expect(math.abs(x - base.Position.X) > base.Size.X * 0.5
                        or math.abs(z - base.Position.Z) > base.Size.Z * 0.5)
                        .toBe(true)
                end
            end
            root:Destroy()
        end

        local empty = Instance.new("Model")
        expect(OriginalMeshScenery.sanitize(empty)).toBe(nil)
        empty:Destroy()
        local huge = Instance.new("Model")
        local part = Instance.new("Part")
        part.Size = Vector3.new(70, 70, 70)
        part.Parent = huge
        expect(OriginalMeshScenery.sanitize(huge)).toBe(nil)
        huge:Destroy()
        asset:Destroy()
        local cleanModel = sanitized :: Model
        cleanModel:Destroy()
    end)

    it("separates all six approved imported mesh shapes from native 3D skyline", function()
        local sizes = {
            perimeter_gate = Vector3.new(58, 25, 38),
            reactor_spire = Vector3.new(30, 62, 30),
            service_crane = Vector3.new(60, 48, 20),
            plasma_foundry = Vector3.new(30, 28, 14),
            sky_transit_exchange = Vector3.new(32, 28, 15),
            orbital_halo_array = Vector3.new(23, 31, 12),
        }
        local templates = {}
        for name, size in pairs(sizes) do
            local model = Instance.new("Model")
            model.Name = name
            local part = Instance.new("Part")
            part.Name = "MockImportedMesh"
            part.Size = size
            part.Parent = model
            templates[name] = model
        end
        local function worldRadii(cf, size)
            local x = (math.abs(cf.RightVector.X) * size.X
                + math.abs(cf.UpVector.X) * size.Y
                + math.abs(cf.LookVector.X) * size.Z) * 0.5
            local z = (math.abs(cf.RightVector.Z) * size.X
                + math.abs(cf.UpVector.Z) * size.Y
                + math.abs(cf.LookVector.Z) * size.Z) * 0.5
            return x, z
        end

        for _, variantId in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, variantId, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local native = {}
            for _, model in ipairs(decor:GetChildren()) do
                if model:IsA("Model")
                    and model:GetAttribute("ChaosDistantScenery") == true then
                    local cf, size = model:GetBoundingBox()
                    local rx, rz = worldRadii(cf, size)
                    native[#native + 1] = {
                        x = cf.Position.X, z = cf.Position.Z,
                        rx = rx, rz = rz,
                    }
                end
            end
            expect(#native >= 12).toBe(true)
            expect(OriginalMeshScenery.mount(arena, templates)).toBe(8)
            local originals = decor:FindFirstChild("Original3DScenery")
            expect(#originals:GetChildren()).toBe(8)
            local occupied = {}
            for _, model in ipairs(originals:GetChildren()) do
                local cf, size = model:GetBoundingBox()
                local rx, rz = worldRadii(cf, size)
                occupied[#occupied + 1] = {
                    name = model.Name, x = cf.Position.X, z = cf.Position.Z,
                    rx = rx, rz = rz,
                }
                for _, bound in ipairs(native) do
                    local apartX = math.abs(cf.Position.X - bound.x)
                        >= rx + bound.rx + 3.9
                    local apartZ = math.abs(cf.Position.Z - bound.z)
                        >= rz + bound.rz + 3.9
                    expect(apartX or apartZ).toBe(true)
                end
                expect(model:GetAttribute("OriginalFoundationBuilt")).toBe(true)
            end
            -- Decorative packages must not interpenetrate each other:
            -- native skyline clearance alone is not enough.
            for i = 1, #occupied do
                for j = i + 1, #occupied do
                    local first, second = occupied[i], occupied[j]
                    local apartX = math.abs(first.x - second.x)
                        >= first.rx + second.rx + 3.9
                    local apartZ = math.abs(first.z - second.z)
                        >= first.rz + second.rz + 3.9
                    expect(apartX or apartZ).toBe(true)
                end
            end
            root:Destroy()
        end
        for _, template in pairs(templates) do template:Destroy() end
    end)

    it("has valid round timing and rewards", function()
        expect(Config.RoundSeconds > 0).toBe(true)
        expect(Config.IntermissionSeconds >= 0).toBe(true)
        expect(Config.WinCoins > 0).toBe(true)
        expect(Config.WinXP > 0).toBe(true)
    end)
end)


-- The coach uses exact live physical decks and server warning footprints;
-- only its visual optional guidance changes, never a score or collision.
describe("Adaptive premium parkour guidance", function()
    it("shows veteran recovery cues only after a real stall", function()
        local ready = JumpRouteCueRules.recoveryHintReady
        expect(ready(5.2, 0.2, true)).toBe(true)
        expect(ready(4.9, 0, true)).toBe(false)
        expect(ready(15, 4, true)).toBe(false)
        expect(ready(15, 1, false)).toBe(false)
        expect(ready(15, 1, nil)).toBe(false)
        expect(ready(math.huge, 0, true)).toBe(false)
        expect(ready(10, 0 / 0, true)).toBe(false)
        expect(ready(10, -1, true)).toBe(false)
    end)

    it("does not point toward or across a live server meteor or bomb", function()
        local safe = JumpRouteCueRules.safeGuidedPath
        local warning = Instance.new("Part")
        warning.Name = "MeteorWarning"
        warning.Anchored = true
        warning.CanCollide = false
        warning.Size = Vector3.new(3, 0.1, 3)
        warning.Position = Vector3.new(0, 2, 0)
        warning:SetAttribute("WarningEndSize", 24)
        warning.Parent = workspace
        local present = {warning}
        -- Both endpoints are safe, yet the straight jump path crosses the
        -- authoritative FUTURE 24-stud-diameter impact footprint.
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(false)
        expect(safe(Vector3.new(-24, 5, 25),
            Vector3.new(24, 5, 25), present)).toBe(true)
        expect(safe(Vector3.new(0, 5, 0),
            Vector3.new(20, 5, 0), present)).toBe(false)
        expect(safe(Vector3.new(-25, 5, 0),
            Vector3.new(0, 5, 0), present)).toBe(false)
        warning.Name = "BombWarning"
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(false)
        warning.Name = "HarmlessDecoration"
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(true)
        warning:Destroy()
        expect(safe(Vector3.new(-24, 5, 0),
            Vector3.new(24, 5, 0), present)).toBe(true)
        expect(safe(nil, Vector3.zero, {})).toBe(false)
        expect(safe(Vector3.zero, Vector3.zero, nil)).toBe(false)
    end)
end)



return nil
