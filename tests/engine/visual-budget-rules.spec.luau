--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VisualBudgetRules = require("../../src/shared/VisualBudgetRules")
local SceneryLodRules = require("../../src/shared/SceneryLodRules")
local CinematicPulseRingKit = require("../../src/client/CinematicPulseRingKit")
local LandingImprintKit = require("../../src/client/LandingImprintKit")
local DisasterIntroMotionKit = require("../../src/client/DisasterIntroMotionKit")
local DisasterBoundaryClimaxKit = require("../../src/client/DisasterBoundaryClimaxKit")
local LocomotionGroundFx = require("../../src/client/LocomotionGroundFx")
local LobbyPracticeVisualKit = require("../../src/client/LobbyPracticeVisualKit")
local ArenaFloorFollowerKit = require("../../src/client/ArenaFloorFollowerKit")
local HarborGantryMotionRules = require("../../src/shared/HarborGantryMotionRules")
local HarborScenery = require("../../src/server/HarborScenery")
local VisualTheme = require("../../src/shared/VisualTheme")
local PremiumGroundMeshKit = require("../../src/client/PremiumGroundMeshKit")
local PremiumGroundPbrKit = require("../../src/client/PremiumGroundPbrKit")
local PremiumRouteMeshKit = require("../../src/client/PremiumRouteMeshKit")
local PremiumRoutePbrKit = require("../../src/client/PremiumRoutePbrKit")
local SpatialMidgroundSelectionRules = require("../../src/shared/SpatialMidgroundSelectionRules")
local MidgroundOutboardLodRules = require("../../src/shared/MidgroundOutboardLodRules")
local PlatformIdentityLodRules = require("../../src/shared/PlatformIdentityLodRules")
local OrbitalStationLayoutRules = require("../../src/shared/OrbitalStationLayoutRules")
local ArenaDistrictArchitecture = require("../../src/server/ArenaDistrictArchitecture")
local PremiumDistrictFacadeMeshKit = require("../../src/client/PremiumDistrictFacadeMeshKit")
local ApprovedDistrictSidewallMeshKit = require("../../src/client/ApprovedDistrictSidewallMeshKit")

describe("visual budget rules", function()
    it("shows one complete verified district 3D envelope on healthy Low and restores all five native masses on budget or facade loss", function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local facadeTemplates = Instance.new("Folder")
        facadeTemplates.Name = "ApprovedDistrictFacadeTemplates"
        facadeTemplates:SetAttribute("OwnerVerified", true)
        facadeTemplates.Parent = ReplicatedStorage
        local facadeSource = Instance.new("Model")
        facadeSource.Name = "Observatory"
        facadeSource:SetAttribute("OwnerVerified", true)
        facadeSource:SetAttribute("CosmeticOnly", true)
        facadeSource:SetAttribute("DistrictFacade3D", true)
        facadeSource:SetAttribute("Original3DAssetId", 132020956214241)
        local facadeMesh = Instance.new("MeshPart")
        facadeMesh.Size = Vector3.new(12, 20, 8)
        facadeMesh.Anchored = true
        facadeMesh.CanCollide = false
        facadeMesh.CanTouch = false
        facadeMesh.CanQuery = false
        facadeMesh.Parent = facadeSource
        facadeSource.Parent = facadeTemplates

        local sidewallTemplates = Instance.new("Folder")
        sidewallTemplates.Name = "ApprovedDistrictSidewallShellTemplates"
        sidewallTemplates:SetAttribute("OwnerVerified", true)
        sidewallTemplates.Parent = ReplicatedStorage
        local sidewallSource = Instance.new("Model")
        sidewallSource.Name = "Sidewall"
        sidewallSource:SetAttribute("OwnerVerified", true)
        sidewallSource:SetAttribute("CosmeticOnly", true)
        sidewallSource:SetAttribute("OriginalDistrictSidewallShell3D", true)
        sidewallSource:SetAttribute("Original3DAssetId", 77387019170428)
        for index, material in ipairs({
            "ARMOR", "BRUSHED", "CARBON", "GRIP",
            "ALLOY", "CERAMIC",
        }) do
            local piece = Instance.new("MeshPart")
            piece.Name = "ApprovedMaterial_" .. material
            piece.Size = if index == 1
                then Vector3.new(10.5, 13.1, 7.4)
                else Vector3.new(1.1, 1.1, 1.1)
            piece.CFrame = CFrame.new(0, 6.55, 0)
            piece.Anchored = true
            piece.CanCollide = false
            piece.CanTouch = false
            piece.CanQuery = false
            piece.Parent = sidewallSource
        end
        sidewallSource.Parent = sidewallTemplates

        local arena = Instance.new("Folder")
        arena.Name = "LowDistrict3DVerifiedArena"
        arena.Parent = workspace
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.CFrame = CFrame.new(0, 10, 0)
        base.Anchored = true
        base.CanCollide = true
        base:SetAttribute("OriginalSizeX", 320)
        base:SetAttribute("OriginalSizeZ", 320)
        base.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local district = ArenaDistrictArchitecture.build(
            decor, base, "Classic", VisualTheme.Arenas.Classic)
        expect(district ~= nil).toBe(true)
        local building = district:FindFirstChild("DistrictNorth1")
        local door = building:FindFirstChild("ServiceEntryDoor")
        local camera = door.Position + Vector3.new(0, 7, 0)
        local look = door.CFrame.LookVector
        local service = building:FindFirstChild("ServiceCore")
        local beam = building:FindFirstChild("ArmoredSupportL")
        local alpha = service.Transparency

        PremiumDistrictFacadeMeshKit.sync(arena, camera, "Low", true, look)
        expect(PremiumDistrictFacadeMeshKit.count()).toBe(1)
        expect(building:GetAttribute(
            "LocalApprovedDistrictFacadeMounted")).toBe(true)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Low", true, true, 0, look)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(1)
        expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(1)
        expect(building:GetAttribute(
            "LocalApprovedDistrictSidewallMounted")).toBe(true)
        local districtBit=bit32.lshift(1,
            building:GetAttribute("DistrictIndex")-1)
        expect(bit32.band(
            ApprovedDistrictSidewallMeshKit.residentMask16(),
            districtBit)).toBe(districtBit)
        expect(bit32.band(
            PremiumDistrictFacadeMeshKit.residentMask16(),
            districtBit)).toBe(districtBit)
        expect(ApprovedDistrictSidewallMeshKit.replacedNativeCount()).toBe(5)
        expect(service.Transparency).toBe(1)
        expect(beam.Transparency).toBe(1)
        expect(base.CanCollide).toBe(true)

        local originals = workspace:FindFirstChild(
            "ApprovedDistrictSidewallsLocal")
        local shell = originals:FindFirstChild("ApprovedOriginalDistrictSidewall3D")
        expect(shell ~= nil and shell:IsA("Model")).toBe(true)
        local pieces = 0
        for _, item in ipairs(shell:GetDescendants()) do
            if item:IsA("BasePart") then
                pieces += 1
                expect(item:IsA("MeshPart")).toBe(true)
                expect(item.CanCollide).toBe(false)
                expect(item.CanTouch).toBe(false)
                expect(item.CanQuery).toBe(false)
                expect(item.CastShadow).toBe(false)
            end
        end
        expect(pieces).toBe(6)

        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Low", true, true, 1, look)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
        expect(ApprovedDistrictSidewallMeshKit.replacedNativeCount()).toBe(0)
        expect(building:GetAttribute(
            "LocalApprovedDistrictSidewallMounted")).toBe(nil)
        expect(service.Transparency).toBe(alpha)
        expect(beam.Transparency).toBe(0)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Low", true, true, 0, look)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(1)

        base.Size = Vector3.new(230, 2, 230)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(1)
        PremiumDistrictFacadeMeshKit.sync(nil, Vector3.zero, "Low", false)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
        expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(0)
        expect(service.Transparency).toBe(alpha)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Low", true, true, 0, look)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)

        PremiumDistrictFacadeMeshKit.sync(
            arena, camera, "Medium", true, look)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Medium", true, false, 0, look)
        expect(ApprovedDistrictSidewallMeshKit.count() >= 1).toBe(true)
        expect(ApprovedDistrictSidewallMeshKit.completeCount() >= 1).toBe(true)
        expect(ApprovedDistrictSidewallMeshKit.completeCount()
            <= ApprovedDistrictSidewallMeshKit.count()).toBe(true)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Medium", true, false, 2, look)
        expect(ApprovedDistrictSidewallMeshKit.count()).toBe(0)
        expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(0)
        expect(service.Transparency).toBe(alpha)
        ApprovedDistrictSidewallMeshKit.sync(
            arena, camera, "Medium", true, false, 0, look)
        expect(ApprovedDistrictSidewallMeshKit.completeCount() >= 1)
            .toBe(true)
        PremiumDistrictFacadeMeshKit.sync(
            nil, Vector3.zero, "Medium", false, look)
        expect(ApprovedDistrictSidewallMeshKit.completeCount()).toBe(0)

        ApprovedDistrictSidewallMeshKit.sync(
            nil, Vector3.zero, "Low", false, true, 0, look)
        sidewallTemplates:Destroy()
        facadeTemplates:Destroy()
        arena:Destroy()
    end)
    it("keeps six orbital station source identities in fixed sectors across Android quality changes", function()
        local layout = OrbitalStationLayoutRules
        local native = Vector3.new(320, 12, 320)
        local low = layout.indices("Low")
        local medium = layout.indices("Medium")
        local high = layout.indices("High")
        expect(#low).toBe(3)
        expect(#medium).toBe(4)
        expect(#high).toBe(6)
        local seen = {}
        for _, index in ipairs(high) do
            seen[index] = layout.offset(native, index)
            expect(seen[index] ~= nil).toBe(true)
        end
        local mediumSet = {}
        for _, index in ipairs(medium) do
            expect(seen[index]).toBe(layout.offset(native, index))
            mediumSet[index] = true
        end
        local odd, even = 0, 0
        for _, index in ipairs(low) do
            expect(mediumSet[index]).toBe(true)
            expect(seen[index]).toBe(layout.offset(native, index))
            if index % 2 == 1 then odd += 1 else even += 1 end
        end
        expect(odd > 0 and even > 0).toBe(true)
        for i = 1, 6 do
            for j = i + 1, 6 do
                expect((seen[i] - seen[j]).Magnitude > 230).toBe(true)
            end
        end
        expect(layout.angle(1)).toBe(math.rad(18))
        expect(layout.angle(7)).toBe(nil)
        expect(layout.offset(native, 0)).toBe(nil)
        expect(layout.offset(Vector3.zero, 2)).toBe(nil)
    end)

    it("shows genuine near-rim source-welded platform 3D and ignores untrusted fake anchors", function()
        local rules = PlatformIdentityLodRules
        local center = Vector3.zero
        local camera = Vector3.new(215, 8, 0)
        local deckAtRim = Vector3.new(224, 8, 0)
        local distantDeck = Vector3.new(-214, 8, 0)
        local near = rules.distance(camera, center, deckAtRim)
        local far = rules.distance(camera, center, distantDeck)
        expect(near < 105).toBe(true)
        expect(SceneryLodRules.visible("Low", near, 105, 165, nil)).toBe(true)
        expect(SceneryLodRules.visible("Medium", near, 105, 165, nil)).toBe(true)
        expect(SceneryLodRules.visible("Medium", far, 105, 165, nil)).toBe(false)
        expect(rules.distance(Vector3.zero, center, distantDeck)).toBe(0)

        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        local visualOwner = Instance.new("Folder")
        visualOwner.Name = "ArenaPlatformIdentityLocal"
        local physics = Instance.new("Part")
        physics.Name = "Platform53"
        physics.Parent = platforms
        local visual = Instance.new("Part")
        visual.Parent = visualOwner
        local weld = Instance.new("Weld")
        weld.Name = "ChaosPlatformTrimWeld"
        weld.Part0 = visual
        weld.Part1 = physics
        weld.Parent = visual
        expect(rules.owner(visual, platforms, decor)).toBe(physics)
        weld.Part1 = nil
        expect(rules.owner(visual, platforms, decor)).toBe(nil)
        weld.Part1 = physics
        physics.Parent = nil
        expect(rules.owner(visual, platforms, decor)).toBe(nil)
        physics.Parent = platforms

        local support = Instance.new("Part")
        support.Name = "PlatformSupport53_1"
        support.Anchored = true
        support.CanCollide = false
        support.CanTouch = false
        support.CanQuery = false
        support.Parent = decor
        weld.Name = "OriginalSupportVisualWeld"
        weld.Part1 = support
        expect(rules.owner(visual, platforms, decor)).toBe(support)
        support.CanCollide = true
        expect(rules.owner(visual, platforms, decor)).toBe(nil)
        support.CanCollide = false
        support.Name = "UnknownObject"
        expect(rules.owner(visual, platforms, decor)).toBe(nil)
        visual:Destroy()
        support:Destroy()
        physics:Destroy()
        platforms:Destroy()
        decor:Destroy()
        visualOwner:Destroy()
        expect(rules.distance(nil, center, deckAtRim)).toBe(math.huge)
    end)

    it("keeps actual tagged original 3D skyline native fallbacks visible near the rim with unchanged distance cutoffs", function()
        local rules = MidgroundOutboardLodRules
        local floorCenter = Vector3.zero
        local camera = Vector3.new(221, 0, 0)
        local nearTower = Vector3.new(245, 14, 0)
        local farTower = Vector3.new(-240, 14, 0)
        local nearDistance = rules.distance(camera, floorCenter, nearTower)
        local farDistance = rules.distance(camera, floorCenter, farTower)
        local visible = SceneryLodRules.visible
        expect(nearDistance < 145).toBe(true)
        expect(visible("Low", nearDistance, 145, 215, nil)).toBe(true)
        expect(visible("Medium", nearDistance, 145, 215, nil)).toBe(true)
        expect(visible("Medium", farDistance, 145, 215, nil)).toBe(false)
        expect(visible("Low", farDistance, 145, 215, nil)).toBe(false)
        expect(rules.distance(Vector3.zero, floorCenter, nearTower)).toBe(0)

        local folder = Instance.new("Folder")
        local names = {
            Classic = {"ClassicBroadcastMass2", "OriginalMidgroundSkylineIndex"},
            Towers = {"TowerCoolingMass2", "OriginalTowerCoolingSpireIndex"},
            Crossroads = {"CrossroadsTransitMass2", "OriginalMidgroundSkylineIndex"},
            Orbital = {"OrbitalStationMass2", "OriginalOrbitalStationIndex"},
            Harbor = {"HarborFreightBargeHull2", "OriginalHarborMidgroundBargeIndex"},
        }
        for variant, tokens in pairs(names) do
            local part = Instance.new("Part")
            part.Name = tokens[1]
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part:SetAttribute("CosmeticOnly", true)
            part:SetAttribute(tokens[2], 2)
            if variant == "Classic" or variant == "Crossroads" then
                part:SetAttribute("OriginalMidgroundSkylineVariant", variant)
            end
            part.Parent = folder
            expect(rules.index(part, variant)).toBe(2)
            expect(rules.anchors(folder, variant)[2]).toBe(part)
            part.CanCollide = true
            expect(rules.index(part, variant)).toBe(nil)
            part.CanCollide = false
            part:SetAttribute("CosmeticOnly", false)
            expect(rules.index(part, variant)).toBe(nil)
            part:Destroy()
        end
        folder:Destroy()
        expect(rules.distance(nil, floorCenter, nearTower)).toBe(math.huge)
    end)

    it("spreads approved midground geometry over separate real-world sectors without raising tier caps", function()
        local selector = SpatialMidgroundSelectionRules.choose
        local nearA = {Position = Vector3.new(-210, 7, -90)}
        local nearB = {Position = Vector3.new(-199, 7, -84)}
        local farA = {Position = Vector3.new(210, 7, 90)}
        local farB = {Position = Vector3.new(201, 7, 102)}
        local candidates = {
            {body = nearA, index = 1, score = 10},
            {body = nearB, index = 2, score = 12},
            {body = farA, index = 3, score = 24},
            {body = farB, index = 4, score = 26},
        }
        local low = selector(candidates, 1)
        expect(low[nearA] ~= nil).toBe(true)
        expect(low[nearB] == nil).toBe(true)
        expect(low[farA] == nil).toBe(true)

        local medium = selector(candidates, 2)
        expect(medium[nearA] ~= nil).toBe(true)
        expect(medium[farA] ~= nil).toBe(true)
        expect(medium[nearB] == nil).toBe(true)
        expect(medium[farB] == nil).toBe(true)

        local boats = {
            {hull = nearA, index = 1, score = 10},
            {hull = nearB, index = 2, score = 12},
            {hull = farA, index = 3, score = 24},
        }
        local harbor = selector(boats, 2)
        expect(harbor[nearA] ~= nil).toBe(true)
        expect(harbor[farA] ~= nil).toBe(true)
        expect(harbor[nearB] == nil).toBe(true)
        local high = selector(candidates, 4)
        expect(high[nearA] ~= nil and high[nearB] ~= nil
            and high[farA] ~= nil and high[farB] ~= nil).toBe(true)
        expect(next(selector(candidates, 0)) == nil).toBe(true)
        expect(next(selector({}, 4)) == nil).toBe(true)
    end)

    it("covers both Towers and Orbital with separated true-model locations and unchanged mobile caps", function()
        local select = SpatialMidgroundSelectionRules.choose
        local positions = {
            Vector3.new(240, 14, 0),
            Vector3.new(235, 14, 7),
            Vector3.new(-245, 14, 0),
            Vector3.new(-240, 14, 8),
            Vector3.new(0, 14, 245),
            Vector3.new(0, 14, -246),
        }
        local candidates = {}
        for index, position in ipairs(positions) do
            candidates[index] = {
                body = {Position = position},
                index = index,
                score = 8 + index * 2,
            }
        end
        expect(select(candidates, 1)[candidates[1].body] ~= nil).toBe(true)
        local medium = select(candidates, 2)
        expect(medium[candidates[1].body] ~= nil).toBe(true)
        expect(medium[candidates[3].body] ~= nil).toBe(true)
        expect(medium[candidates[2].body] == nil).toBe(true)
        local towerHigh = select(candidates, 5)
        local total = 0
        for _ in pairs(towerHigh) do total += 1 end
        expect(total).toBe(5)
        local orbit = select(candidates, 3)
        expect(orbit[candidates[1].body] ~= nil).toBe(true)
        expect(orbit[candidates[3].body] ~= nil).toBe(true)
        expect(orbit[candidates[5].body] ~= nil).toBe(true)
        expect(orbit[candidates[2].body] == nil).toBe(true)
        local all = select(candidates, 6)
        total = 0
        for _ in pairs(all) do total += 1 end
        expect(total).toBe(6)
        local invalid = {
            {body = {Position = Vector3.zero}, score = 0/0, index = 1},
            {body = {Position = "bad"}, score = 1, index = 2},
        }
        expect(next(select(invalid, 6)) == nil).toBe(true)
    end)

    it("uses five specific approved UV-ground PBR finishes without increasing mobile texture residency", function()
        local kit = PremiumGroundPbrKit
        expect(kit.family("Classic")).toBe("DiamondArmor")
        expect(kit.family("Towers")).toBe("BrushedTitanium")
        expect(kit.family("Crossroads")).toBe("OxidizedSteel")
        expect(kit.family("Orbital")).toBe("ReactorCeramic")
        expect(kit.family("Harbor")).toBe("OxidizedSteel")
        expect(kit.family("Unknown")).toBe("DiamondArmor")

        local limit = kit.tileBudget
        expect(limit("Low", 0, true, false)).toBe(0)
        expect(limit("Medium", 0, true, false)).toBe(2)
        expect(limit("Medium", 1, true, false)).toBe(1)
        expect(limit("Medium", 2, true, false)).toBe(0)
        expect(limit("High", 0, true, false)).toBe(6)
        expect(limit("High", 1, true, false)).toBe(3)
        expect(limit("High", 2, true, false)).toBe(1)
        expect(limit("High", 0, false, false)).toBe(12)
        expect(limit("Medium", 0, false, false)).toBe(4)
        expect(limit("High", 1, false, false)).toBe(6)
        expect(limit("High", 0, true, true)).toBe(0)
        expect(limit("Medium", 0, false, true)).toBe(0)
        expect(limit("High", -100, true, false)).toBe(6)
        expect(limit("High", 1000, true, false)).toBe(1)
        expect(limit("High", 0/0, true, false)).toBe(6)
        expect(limit("Bogus", 0, false, false)).toBe(0)

        local fakeModel = Instance.new("Model")
        fakeModel:SetAttribute("CosmeticOnly", true)
        fakeModel:SetAttribute("OriginalGroundMeshId", 1)
        local fakeGround = Instance.new("Part")
        fakeGround:SetAttribute("OriginalGroundFinish", true)
        local bogus = {model = fakeModel, ground = fakeGround, pieces = {}}
        expect(kit.attach(bogus, "Classic")).toBe(0)
        kit.detach(bogus)
        expect(#fakeModel:GetDescendants()).toBe(0)
        fakeGround:Destroy()
        fakeModel:Destroy()
    end)

    it("preserves engine-imported original SurfaceAppearance while applying source-verified UV PBR", function()
        local replicated = game:GetService("ReplicatedStorage")
        local existing = replicated:FindFirstChild("OriginalGroundPbrTemplates")
        local library = existing
        local createdLibrary = false
        if not library then
            library = Instance.new("Folder")
            library.Name = "OriginalGroundPbrTemplates"
            library.Parent = replicated
            createdLibrary = true
        end
        local template = library:FindFirstChild("DiamondArmor")
        local createdTemplate = false
        if not template then
            template = Instance.new("SurfaceAppearance")
            template.Name = "DiamondArmor"
            template.Parent = library
            createdTemplate = true
        end

        -- No source mock: these are real Roblox MeshPart and
        -- SurfaceAppearance Instances, verifying engine parent/clone
        -- behavior, not invented success data or simulated image URLs.
        local model = Instance.new("Model")
        model.Name = "OriginalUploadedGroundInstance"
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("OriginalGroundMeshId", 72507987666671)
        model.Parent = workspace
        local piece = Instance.new("MeshPart")
        piece.Name = "ARMOR"
        piece.Parent = model
        local original = Instance.new("SurfaceAppearance")
        original.Name = "SourceImportedMaterialFactors"
        original.Parent = piece
        local ground = Instance.new("Part")
        ground:SetAttribute("OriginalGroundFinish", true)
        ground.Parent = workspace

        local entry = {model = model, ground = ground, pieces = {piece}}
        expect(PremiumGroundPbrKit.attach(entry, "Classic")).toBe(1)
        expect(original.Parent).toBe(nil)
        local overlay = piece:FindFirstChild("OriginalApprovedGroundPbr2K")
        expect(overlay ~= nil and overlay:IsA("SurfaceAppearance")).toBe(true)
        -- LOD reconciliation must not allocate a duplicate 2K atlas.
        expect(PremiumGroundPbrKit.attach(entry, "Classic")).toBe(1)
        expect(piece:FindFirstChild("OriginalApprovedGroundPbr2K")).toBe(overlay)
        PremiumGroundPbrKit.detach(entry)
        expect(original.Parent).toBe(piece)
        expect(piece:FindFirstChild("OriginalApprovedGroundPbr2K")).toBe(nil)
        expect(PremiumGroundPbrKit.attach(entry, "Classic")).toBe(1)
        PremiumGroundPbrKit.detach(entry)
        expect(original.Parent).toBe(piece)

        ground:Destroy()
        model:Destroy()
        if createdTemplate then template:Destroy() end
        if createdLibrary then library:Destroy() end
    end)

    it("finishes authenticated bridge joints and Sky Spine crowns with existing 2K maps without touching safety channels", function()
        local kit = PremiumRoutePbrKit
        local budget = kit.entryBudget
        expect(budget("Low", 0, true, false)).toBe(0)
        expect(budget("Medium", 0, true, false)).toBe(1)
        expect(budget("Medium", 1, true, false)).toBe(0)
        expect(budget("Medium", 1, false, false)).toBe(1)
        expect(budget("High", 0, true, false)).toBe(1)
        expect(budget("High", 0, false, false)).toBe(2)
        expect(budget("High", 1, true, false)).toBe(0)
        expect(budget("High", 1, false, false)).toBe(1)
        expect(budget("High", 2, false, false)).toBe(0)
        expect(budget("High", 0/0, true, false)).toBe(1)
        expect(budget("High", 0, true, true)).toBe(0)
        expect(budget("Unknown", 0, false, false)).toBe(0)

        local rs = game:GetService("ReplicatedStorage")
        local library = rs:FindFirstChild("OriginalGroundPbrTemplates")
        local createdLibrary = false
        if not library then
            library = Instance.new("Folder")
            library.Name = "OriginalGroundPbrTemplates"
            library.Parent = rs
            createdLibrary = true
        end
        local created = {}
        for _, name in ipairs({"BrushedTitanium", "DiamondArmor",
            "ReactorCeramic", "OxidizedSteel"}) do
            if not library:FindFirstChild(name) then
                local template = Instance.new("SurfaceAppearance")
                template.Name = name
                template.Parent = library
                created[#created + 1] = template
            end
        end
        -- REAL MeshPart/SufaceAppearance Roblox engine objects. The IDs
        -- are authenticated source IDs, not invented in-game texture URLs.
        local model = Instance.new("Model")
        model.Name = "OriginalPremiumRouteMesh"
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("OriginalPremiumRouteAssetId", 94023662427980)
        model.Parent = workspace
        local function part(name)
            local item = Instance.new("MeshPart")
            item.Name = name
            item.Parent = model
            return item
        end
        local metal = part("Chaos_ARMOR")
        local alloy = part("Chaos_ALLOY")
        local ceramic = part("Chaos_CERAMIC")
        local grip = part("Chaos_GRIP")
        local signal = part("Chaos_SIGNAL")
        local carbon = part("Chaos_CARBON")
        local original = Instance.new("SurfaceAppearance")
        original.Name = "ImportedSourceFactors"
        original.Parent = metal
        local entry = {models = {model}}
        expect(kit.apply(entry, "route", "Classic", true)).toBe(3)
        expect(original.Parent).toBe(nil)
        expect(metal:FindFirstChild("OriginalApprovedBridgePbr2K")
            ~= nil).toBe(true)
        expect(alloy:FindFirstChild("OriginalApprovedBridgePbr2K")
            ~= nil).toBe(true)
        expect(ceramic:FindFirstChild("OriginalApprovedBridgePbr2K")
            ~= nil).toBe(true)
        expect(grip:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        expect(signal:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        expect(carbon:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        local first = metal:FindFirstChild("OriginalApprovedBridgePbr2K")
        expect(kit.apply(entry, "route", "Classic", true)).toBe(3)
        expect(metal:FindFirstChild("OriginalApprovedBridgePbr2K")).toBe(first)
        -- Streaming may reveal another approved armor MeshPart after the
        -- initial PBR pass. Refresh the WHOLE bridge instead of leaving
        -- the new panel untextured until a tier/variant change.
        local late = part("Chaos_ARMOR_LateStreamed")
        expect(kit.apply(entry, "route", "Classic", true)).toBe(4)
        expect(late:FindFirstChild("OriginalApprovedBridgePbr2K")
            ~= nil).toBe(true)
        -- A removed or renamed armor panel must not leave stale PBR
        -- overlays or consume a slot that belongs to another segment.
        late.Name = "Chaos_SIGNAL_LateStreamed"
        expect(kit.apply(entry, "route", "Classic", true)).toBe(3)
        expect(late:FindFirstChild("OriginalApprovedBridgePbr2K")).toBe(nil)
        expect(kit.apply(entry, "route", "Classic", true)).toBe(3)
        local m, n = kit.count(entry)
        expect(m).toBe(1)
        expect(n).toBe(3)
        -- When the real bridge warns or Android reduces detail, do NOT
        -- destroy the engine-imported source material factor appearance.
        expect(kit.apply(entry, "route", "Classic", false)).toBe(0)
        expect(original.Parent).toBe(metal)
        expect(metal:FindFirstChild("OriginalApprovedBridgePbr2K")).toBe(nil)
        expect(kit.apply(entry, "route", "Harbor", true)).toBe(3)
        expect(kit.apply(entry, "route", "Bogus", true)).toBe(0)
        -- A lookalike unsafe marketplace Model never gets the 2K maps.
        model:SetAttribute("OriginalPremiumRouteAssetId", 1)
        expect(kit.apply(entry, "route", "Classic", true)).toBe(0)
        model:SetAttribute("OriginalPremiumRouteAssetId", 94023662427980)
        expect(kit.apply(entry, "route", "Classic", true)).toBe(3)
        kit.detach(entry)
        expect(original.Parent).toBe(metal)
        model:Destroy()

        local crown = Instance.new("Model")
        crown.Name = "OriginalApprovedSkySpineCrown3D"
        crown:SetAttribute("CosmeticOnly", true)
        crown:SetAttribute("Original3DAssetId", 71492051540032)
        crown.Parent = workspace
        local crownPart = Instance.new("MeshPart")
        crownPart.Name = "Chaos_BRUSHED"
        crownPart.Parent = crown
        local portico = {model = crown}
        expect(kit.apply(portico, "crown", "Towers", true)).toBe(1)
        expect(kit.apply(portico, "route", "Towers", true)).toBe(0)
        expect(kit.apply(portico, "crown", "Towers", true)).toBe(1)
        kit.detach(portico)
        expect(crownPart:FindFirstChild("OriginalApprovedBridgePbr2K"))
            .toBe(nil)
        crown:Destroy()
        for _, template in ipairs(created) do template:Destroy() end
        if createdLibrary then library:Destroy() end
    end)

    it("applies source-authenticated 2K Harbor gantry armor without painting danger or grip", function()
        local rs = game:GetService("ReplicatedStorage")
        local lib = rs:FindFirstChild("OriginalGroundPbrTemplates")
        local newLib = false
        if not lib then
            lib = Instance.new("Folder")
            lib.Name = "OriginalGroundPbrTemplates"
            lib.Parent = rs
            newLib = true
        end
        local created = {}
        for _, name in ipairs({"OxidizedSteel","BrushedTitanium","ReactorCeramic"}) do
            if not lib:FindFirstChild(name) then
                local template = Instance.new("SurfaceAppearance")
                template.Name = name
                template.Parent = lib
                created[#created+1] = template
            end
        end
        local model = Instance.new("Model")
        model.Name = "ApprovedHarborSuspendedCargoGantry3D"
        model:SetAttribute("CosmeticOnly",true)
        model:SetAttribute("Original3DAssetId",134157110756659)
        model:SetAttribute("OriginalHarborPromenadePortal3D",true)
        model.Parent = workspace
        local function mesh(group)
            local part = Instance.new("MeshPart")
            part.Name = "Original_"..group
            part.Parent = model
            return part
        end
        local armor = mesh("ARMOR")
        local alloy = mesh("ALLOY")
        local ceramic = mesh("CERAMIC")
        local grip = mesh("GRIP")
        local signal = mesh("SIGNAL")
        local carbon = mesh("CARBON")
        local import = Instance.new("SurfaceAppearance")
        import.Name = "ImportSourceFactors"
        import.Parent = armor
        local entry = {model=model}
        expect(PremiumRoutePbrKit.apply(entry,"gantry","Harbor",true)).toBe(3)
        expect(armor:FindFirstChild("OriginalApprovedBridgePbr2K")~=nil).toBe(true)
        expect(alloy:FindFirstChild("OriginalApprovedBridgePbr2K")~=nil).toBe(true)
        expect(ceramic:FindFirstChild("OriginalApprovedBridgePbr2K")~=nil).toBe(true)
        expect(signal:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        expect(grip:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        expect(carbon:FindFirstChildWhichIsA("SurfaceAppearance")).toBe(nil)
        expect(import.Parent).toBe(nil)
        local late = mesh("BRUSHED")
        expect(PremiumRoutePbrKit.apply(entry,"gantry","Harbor",true)).toBe(4)
        expect(late:FindFirstChild("OriginalApprovedBridgePbr2K")~=nil).toBe(true)
        PremiumRoutePbrKit.detach(entry)
        expect(import.Parent).toBe(armor)
        local n,m = PremiumRoutePbrKit.count(entry)
        expect(n).toBe(0)
        expect(m).toBe(0)
        model:SetAttribute("OriginalHarborPromenadePortal3D",false)
        expect(PremiumRoutePbrKit.apply(entry,"gantry","Harbor",true)).toBe(0)
        model:SetAttribute("OriginalHarborPromenadePortal3D",true)
        model:SetAttribute("Original3DAssetId",1)
        expect(PremiumRoutePbrKit.apply(entry,"gantry","Harbor",true)).toBe(0)
        model:Destroy()
        for _, createdTemplate in ipairs(created) do createdTemplate:Destroy() end
        if newLib then lib:Destroy() end
    end)

    it("restores the exact nine-part Harbor native arch immediately if its approved 3D Model disappears", function()
        local Kit = require("../../src/client/HarborPromenadePortalMeshKit")
        Kit.sync(nil, Vector3.zero, "Low", false)
        local rs = game:GetService("ReplicatedStorage")
        local holder = rs:FindFirstChild("ApprovedHarborPromenadePortalTemplates")
        local createdHolder = false
        if not holder then
            holder = Instance.new("Folder")
            holder.Name = "ApprovedHarborPromenadePortalTemplates"
            holder:SetAttribute("OwnerVerified", true)
            holder.Parent = rs
            createdHolder = true
        end
        local source = holder:FindFirstChild("CargoGantry")
        local createdSource = false
        if not source then
            source = Instance.new("Model")
            source.Name = "CargoGantry"
            source:SetAttribute("OwnerVerified", true)
            source:SetAttribute("CosmeticOnly", true)
            source:SetAttribute("OriginalHarborPromenadePortal3D", true)
            source:SetAttribute("Original3DAssetId", 134157110756659)
            local sourceMesh = Instance.new("MeshPart")
            sourceMesh.Name = "Approved_ARMOR"
            sourceMesh.Size = Vector3.new(19.4,20.1,12.6)
            sourceMesh.Parent = source
            source.Parent = holder
            createdSource = true
        end
        -- This is an actual Roblox engine integration fixture. Mirror the
        -- MapBuilder's signed GeneratedMap/Arena parentage, not a detached
        -- Folder that correctly fails the import provenance contract.
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = workspace
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena:SetAttribute("VariantId","Harbor")
        arena.Parent = generated
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320,2,320)
        base.Anchored = true
        base.CanCollide = true
        base:SetAttribute("OriginalSizeX", 320)
        base:SetAttribute("OriginalSizeZ", 320)
        base.Parent = arena
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local deck = Instance.new("Part")
        deck.Name = "Platform991"
        deck.Size = Vector3.new(26,2,12)
        deck.Position = Vector3.new(0,52,0)
        deck.Anchored = true
        deck.CanCollide = true
        deck:SetAttribute("ChaosPermanentRoute",true)
        deck:SetAttribute("RouteTier", 3)
        deck:SetAttribute("PromenadeLane",1)
        deck:SetAttribute("PromenadeStep",2)
        deck.Parent = platforms
        -- All nine actual authored ornament names must unmask as a group.
        -- Merely testing one pylon would miss a partial nine-piece fallback.
        local native = {}
        for _, suffix in ipairs({
            "LoadPylon-1", "LoadPylon1", "DiagonalStay-1",
            "DiagonalStay1", "MonumentalCrosshead", "UnderdeckTruss",
            "FreightHoistArm", "SuspendedCrate", "CargoChain",
        }) do
            local part = Instance.new("Part")
            part.Name = "Promenade991_" .. suffix
            part.Size = Vector3.new(1.6,13.25,1.8)
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part:SetAttribute("PromenadeVisualOnly",true)
            part:SetAttribute("PerimeterPlatformIndex",991)
            part.Parent = decor
            native[#native+1] = part
        end
        local function nativeMask(alpha)
            for _, part in ipairs(native) do
                expect(part.LocalTransparencyModifier).toBe(alpha)
            end
        end
        local camera = Vector3.new(0,54,-18)
        local look = Vector3.new(0,0,1)
        Kit.sync(arena,camera,"High",true,look,0,false,false)
        expect(Kit.count()).toBe(1)
        nativeMask(1)
        expect(deck.CanCollide).toBe(true)
        local bucket = workspace:FindFirstChild(
            "OriginalHarborPromenadePortalsLocal")
        expect(bucket ~= nil).toBe(true)
        local clone = bucket:FindFirstChild("ApprovedHarborSuspendedCargoGantry3D")
        expect(clone ~= nil and clone:IsA("Model")).toBe(true)
        clone:Destroy()
        nativeMask(0)
        expect(Kit.count()).toBe(0)
        Kit.sync(arena,camera,"High",true,look,0,false,false)
        expect(Kit.count()).toBe(1)
        nativeMask(1)
        deck:SetAttribute("CollapsePhase","Warning")
        nativeMask(0)
        Kit.sync(arena,camera,"High",true,look,0,false,false)
        expect(Kit.count()).toBe(0)
        deck:SetAttribute("CollapsePhase","Normal")
        Kit.sync(arena,camera,"High",true,look,0,false,false)
        expect(Kit.count()).toBe(1)
        -- ShrinkingArena moves the real floor BEFORE the RouteTier decks.
        -- The nine native structures must be visible during this gap.
        base.Size = Vector3.new(230,2,230)
        expect(Kit.count()).toBe(0)
        nativeMask(0)
        -- Once the genuine server-owned deck reaches the same scale,
        -- its imported arch can safely refit without adding collision.
        local scale = 230 / 320
        deck.Size = Vector3.new(26*scale,2,12*scale)
        Kit.sync(arena,camera,"High",true,look,0,false,false)
        expect(Kit.count()).toBe(1)
        nativeMask(1)
        expect(deck.CanCollide).toBe(true)
        deck:SetAttribute("CollapsePhase","Warning")
        nativeMask(0)
        Kit.sync(nil,Vector3.zero,"Low",false)
        generated:Destroy()
        if createdSource then source:Destroy() end
        if createdHolder then holder:Destroy() end
    end)

    it("honors actual 2/16/36 source-verified ground bay caps and mobile pressure fallbacks", function()
        local count = PremiumGroundMeshKit.residencyCount
        expect(count("High", 0)).toBe(36)
        expect(count("Medium", 0)).toBe(16)
        expect(count("Low", 0)).toBe(2)
        -- The existing hysteresis-filtered FPS/Parts pressure must
        -- reclaim genuine 7-MeshPart tiles without new render loops.
        expect(count("High", 1)).toBe(24)
        expect(count("High", 2)).toBe(16)
        expect(count("Medium", 1)).toBe(10)
        expect(count("Medium", 2)).toBe(4)
        expect(count("Low", 1)).toBe(2)
        expect(count("Low", 2)).toBe(1)
        -- Invalid or absent local pressure never creates unbounded clones.
        expect(count("High", nil)).toBe(36)
        expect(count("High", 300)).toBe(16)
        expect(count("Low", -10)).toBe(2)
        expect(count("High", 0/0)).toBe(36)
        expect(count("Unknown", 0)).toBe(2)
        local registered = false
        for _, owner in ipairs(VisualBudgetRules.LocalFolders) do
            if owner == "OriginalPremiumGroundMeshesLocal" then
                registered = true
            end
        end
        expect(registered).toBe(true)
    end)

    it("keeps genuine nearby 3D Sky Spine and promenade skins together only across real jumpable joints", function()
        local real = PremiumRouteMeshKit.realRouteJunction
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = workspace
        local function deck(name, size, position, lane, step, spine)
            local part = Instance.new("Part")
            part.Name = name
            part.Size = size
            part.CFrame = CFrame.new(position)
            part.Anchored = true
            part.CanCollide = true
            part:SetAttribute("ChaosPermanentRoute", true)
            if spine then
                part:SetAttribute("SkySpineInterchange", true)
                part:SetAttribute("SkySpineStep", step)
            else
                part:SetAttribute("PromenadeLane", lane)
                part:SetAttribute("PromenadeStep", step)
            end
            part.Parent = platforms
            return part
        end
        -- Authentic 26x12 promenade with a 2.4-stud honest jump gap.
        local a = deck("Platform501",Vector3.new(26,2,12),
            Vector3.new(-14.2,21,0),1,4,false)
        local b = deck("Platform502",Vector3.new(26,2,12),
            Vector3.new(14.2,21,0),1,5,false)
        expect(real(a,b)).toBe(true)
        expect(real(b,a)).toBe(true)
        local falseLink = deck("Platform503",Vector3.new(26,2,12),
            Vector3.new(42.6,21,0),1,8,false)
        expect(real(b,falseLink)).toBe(false)
        falseLink:SetAttribute("PromenadeStep",6)
        falseLink.CFrame = CFrame.new(72,21,0)
        expect(real(b,falseLink)).toBe(false)
        -- Sky Spine is physically transverse; the central H joint
        -- receives the same approved finish only if footprints touch.
        local spine = deck("Platform504",Vector3.new(12,2,26),
            Vector3.new(-14.2,21,18),nil,1,true)
        expect(real(a,spine)).toBe(true)
        expect(real(spine,a)).toBe(true)
        spine.CFrame = CFrame.new(-14.2,21,60)
        expect(real(a,spine)).toBe(false)
        spine.CFrame = CFrame.new(-14.2,21,18)
        spine:SetAttribute("CollapsePhase","Warning")
        expect(real(a,spine)).toBe(false)
        spine:SetAttribute("CollapsePhase","Normal")
        expect(real(a,spine)).toBe(true)
        a.CanCollide = false
        expect(real(a,b)).toBe(false)
        a.CanCollide = true
        local decoy = Instance.new("Part")
        decoy.Name = "Platform505"
        decoy.Size = a.Size
        decoy.Anchored = true
        decoy.CanCollide = true
        decoy.CFrame = CFrame.new(42.6,21,0)
        decoy.Parent = platforms
        expect(real(b,decoy)).toBe(false)
        decoy:Destroy()
        platforms:Destroy()
    end)

    it("fits real owner-approved bridge geometry without hiding incompletely covered physical decks", function()
        local deck = Instance.new("Part")
        deck.Size = Vector3.new(26, 2, 11)
        local bounds = Vector3.new(12, 1, 9)
        local fit = PremiumRouteMeshKit.sourceFit
        local count = PremiumRouteMeshKit.bridgeSegmentCount
        expect(count(deck, bounds, 4)).toBe(2)
        local result = fit(deck, bounds, 2, true)
        expect(result ~= nil and result.panelCovered == true).toBe(true)
        expect(math.abs(result.yaw) < 0.001).toBe(true)
        -- The approved import can swap X/Z; still face the real corridor.
        local swapped = fit(deck, Vector3.new(9, 1, 12), 2, true)
        expect(swapped ~= nil and swapped.panelCovered == true).toBe(true)
        expect(math.abs(swapped.yaw - math.pi * 0.5) < 0.001).toBe(true)
        deck.Size = Vector3.new(11, 2, 26)
        local turned = fit(deck, bounds, 2, true)
        expect(turned ~= nil and turned.panelCovered == true).toBe(true)
        expect(math.abs(turned.yaw - math.pi * 0.5) < 0.001).toBe(true)
        -- A huge, narrow bridge must retain its ORIGINAL readable floor
        -- paint when an approved mesh cannot cover the physical footprint.
        deck.Size = Vector3.new(49, 1, 4.5)
        local incomplete = fit(deck, bounds, 4, true)
        expect(incomplete ~= nil and incomplete.panelCovered == false).toBe(true)
        expect(incomplete.longCoverage < 0.68).toBe(true)
        deck.Size = Vector3.new(18, 2, 18)
        local tile = fit(deck, Vector3.new(17, 2, 17), 1, false)
        expect(tile ~= nil and tile.panelCovered == true).toBe(true)
        expect(fit(nil, bounds, 1, true)).toBe(nil)
        deck:Destroy()
    end)

    it("counts all approved route MeshParts in the existing Android budget ledger", function()
        local registered = false
        for _, name in ipairs(VisualBudgetRules.LocalFolders) do
            if name == "PremiumRouteMeshLocal" then registered = true end
        end
        expect(registered).toBe(true)
        local root = Instance.new("Folder")
        local original = Instance.new("Folder")
        original.Name = "PremiumRouteMeshLocal"
        original.Parent = root
        local model = Instance.new("Model")
        model.Name = "OriginalPremiumRouteMesh"
        model.Parent = original
        local deck = Instance.new("MeshPart")
        deck.Parent = model
        local bridge = Instance.new("MeshPart")
        bridge.Parent = model
        -- Genuine imported material Parts are BaseParts, not VFX emitters.
        local metrics, counted, byOwner = VisualBudgetRules.collect(root)
        expect(counted).toBe(1)
        expect(metrics.Parts).toBe(2)
        expect(metrics.Effects).toBe(0)
        expect(byOwner.PremiumRouteMeshLocal.Parts).toBe(2)
        root:Destroy()
    end)
    it("moves original Harbor cargo and crane trolleys only inside client LOD limits", function()
        local rules = HarborGantryMotionRules
        expect(rules.profile("Low", false).Count).toBe(0)
        expect(rules.profile("Medium", false).Count).toBe(2)
        expect(rules.profile("High", false).Count).toBe(4)
        expect(rules.profile("High", true).Count).toBe(0)
        expect(rules.profile("Medium", false).Interval >= 0.20).toBe(true)
        expect(rules.role("TrolleyCabin", false)).toBe("trolley")
        expect(rules.role("CabinWindow", false)).toBe("trolley")
        expect(rules.role("TrolleyDriveHousing", false)).toBe("trolley")
        expect(rules.role("HoistCable", false)).toBe("cable")
        expect(rules.role("CargoSpreader", false)).toBe("load")
        expect(rules.role("CargoSling-1", false)).toBe("load")
        expect(rules.role("ContainerRib-1", false)).toBe("load")
        expect(rules.role("CableDrum", false)).toBe("load")
        expect(rules.role("DrumArmorPlate1", false)).toBe("load")
        expect(rules.role("MainCrossgirder", false)).toBe(nil)
        expect(rules.role("RadarBoom", true)).toBe("radar")
        expect(rules.role("RadarBoom", false)).toBe(nil)
        for slot = 1, 4 do
            local restingTravel, restingLift = rules.pose(9, slot, 0)
            expect(restingTravel).toBe(0)
            expect(restingLift).toBe(0)
            for t = 0, 18, 0.5 do
                local travel, lift = rules.pose(t, slot, 1)
                expect(math.abs(travel) <= 4.7 + 0.0001).toBe(true)
                expect(lift >= 0 and lift <= 2.7 + 0.0001).toBe(true)
                -- Original 13-stud hoist cable can never invert/collapse.
                expect(13 - lift >= 10.3 - 0.0001).toBe(true)
            end
        end
        -- Verify the moving parts belong to actual original, real
        -- anchored and noncolliding Harbor models, not generated stand-ins.
        local decor = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(320, 2, 320)
        local fleet = HarborScenery.build(
            decor, base, VisualTheme.arena("Harbor"))
        expect(fleet ~= nil).toBe(true)
        for _, name in ipairs({
            "HarborGantryEastNorth", "HarborGantryEastSouth",
            "HarborGantryWestNorth", "HarborGantryWestSouth",
        }) do
            local crane = fleet:FindFirstChild(name)
            expect(crane ~= nil and crane:IsA("Model")).toBe(true)
            local movingCount = 0
            for _, piece in ipairs(crane:GetChildren()) do
                if piece:IsA("BasePart")
                    and rules.role(piece.Name, false) ~= nil then
                    movingCount += 1
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                end
            end
            expect(movingCount >= 8).toBe(true)
        end
        local vessel = fleet:FindFirstChild("HarborCargoVessel")
        expect(vessel ~= nil and vessel:IsA("Model")).toBe(true)
        local radar = vessel:FindFirstChild("RadarBoom")
        expect(radar ~= nil and rules.role(radar.Name, true) == "radar")
            .toBe(true)
        expect(radar.CanCollide).toBe(false)
        decor:Destroy()
        base:Destroy()

        expect(rules.radarAngle(3, 0)).toBe(0)
        for t = 0, 18, 0.5 do
            expect(math.abs(rules.radarAngle(t, 1))
                <= math.rad(58) + 0.0001).toBe(true)
        end
    end)

    it("spreads a diagnostic census over frames without changing exact counts", function()
        local root = Instance.new("Folder")
        local folder = Instance.new("Folder")
        folder.Name = VisualBudgetRules.LocalFolders[1]
        folder.Parent = root
        for _ = 1, 400 do
            Instance.new("Part").Parent = folder
        end
        Instance.new("PointLight").Parent = folder
        Instance.new("ParticleEmitter").Parent = folder

        local synchronous, syncFolders = VisualBudgetRules.collect(root)
        expect(synchronous.Parts).toBe(400)
        expect(synchronous.Lights).toBe(1)
        expect(synchronous.Effects).toBe(1)

        local checkpoints = 0
        local spread, audited = VisualBudgetRules.collect(root, function()
            checkpoints += 1
            -- The real client yields here; the engine test verifies the
            -- exact checkpoint contract without introducing test delays.
        end)
        expect(checkpoints >= 2).toBe(true)
        expect(audited).toBe(syncFolders)
        expect(spread.Parts).toBe(synchronous.Parts)
        expect(spread.Lights).toBe(synchronous.Lights)
        expect(spread.Effects).toBe(synchronous.Effects)

        local noRoot, count = VisualBudgetRules.collect(nil, function()
            checkpoints += 1
        end)
        expect(noRoot.Parts).toBe(0)
        expect(count).toBe(0)
        expect(checkpoints).toBe(2)
        root:Destroy()
    end)

    it("counts local meteor facets welded under authoritative impact Parts", function()
        local root = Instance.new("Folder")
        local meteor = Instance.new("Part")
        meteor.Name = "RoundMeteor"
        meteor.Parent = root
        for index = 1, 5 do
            local localFacet = Instance.new("WedgePart")
            localFacet.Name = "LocalMeteorFacet" .. index
            localFacet.Parent = meteor
        end
        local serverFacet = Instance.new("WedgePart")
        serverFacet.Name = "AuthoritativeProjectileShell"
        serverFacet.Parent = meteor
        local wrongType = Instance.new("Part")
        wrongType.Name = "LocalMeteorFacet6"
        wrongType.Parent = meteor
        local trail = Instance.new("Trail")
        trail.Name = "SignatureMeteorTrail"
        trail.Parent = meteor

        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(5)
        expect(metrics.Effects).toBe(1)
        meteor:FindFirstChild("LocalMeteorFacet1"):Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(4)
        root:Destroy()
    end)

    it("observes concurrent hazards without inventing Android FPS or scanning decor", function()
        local root = Instance.new("Folder")
        local types = {
            "BombWarning", "BombWarning", "MeteorWarning",
            "FreezeWarning", "JumpShockWarning",
            "RoundMeteor", "RoundLava", "OtherPart",
        }
        for _, name in ipairs(types) do
            local part = Instance.new("Part")
            part.Name = name
            part.Parent = root
        end
        local storm = Instance.new("Model")
        storm.Name = "RoundTornado"
        storm.Parent = root
        local irrelevant = Instance.new("Folder")
        irrelevant.Name = "BombWarning"
        irrelevant.Parent = root
        local reading = VisualBudgetRules.hazardSnapshot(
            root, {"Bombs", "Meteors", "Bombs"}
        )
        expect(reading.ActiveDisasters).toBe(2)
        expect(reading.Warnings).toBe(5)
        expect(reading.BombWarnings).toBe(2)
        expect(reading.MeteorWarnings).toBe(1)
        expect(reading.FreezeWarnings).toBe(1)
        expect(reading.JumpWarnings).toBe(1)
        expect(reading.LiveMeteors).toBe(1)
        expect(reading.LiveLava).toBe(1)
        expect(reading.LiveTornadoes).toBe(1)
        local empty = VisualBudgetRules.hazardSnapshot(nil, nil)
        expect(empty.Warnings).toBe(0)
        expect(empty.ActiveDisasters).toBe(0)
        root:Destroy()
    end)

    it("accounts for locally welded frost facets on player torsos", function()
        local root = Instance.new("Folder")
        local character = Instance.new("Model")
        character.Name = "VisualBudgetFreezeTest"
        character.Parent = root
        local torso = Instance.new("Part")
        torso.Name = "UpperTorso"
        torso.Parent = character

        local localFacet = Instance.new("WedgePart")
        localFacet.Name = "LocalFreezeArmorFacet1"
        localFacet.Parent = torso
        local unrelated = Instance.new("WedgePart")
        unrelated.Name = "AvatarCosmetic"
        unrelated.Parent = torso

        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(1)
        expect(metrics.Effects).toBe(0)
        localFacet:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(0)
        root:Destroy()
    end)

    it("hides only original off-map hero geometry on low-end Android", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local hero = Instance.new("Model")
        hero.Name = "ArenaHeroArchitecture3D"
        hero:SetAttribute("ChaosDistantScenery", true)
        hero:SetAttribute("SourceIsOriginal", true)
        hero.Parent = decor
        local part = Instance.new("Part")
        part.Parent = hero
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(hero)
        expect(SceneryLodRules.visible("Low", 5, 0, 185, nil)).toBe(false)
        expect(SceneryLodRules.visible("Medium", 110, 0, 185, nil)).toBe(true)
        expect(SceneryLodRules.visible("Medium", 204, 0, 185, false)).toBe(false)
        expect(SceneryLodRules.visible("High", 600, 0, 185, nil)).toBe(true)
        -- A replica with the same name is never trusted as cosmetic if its
        -- provenance flags are absent: no risk of hiding gameplay shells.
        hero:SetAttribute("SourceIsOriginal", nil)
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(nil)
        hero:SetAttribute("SourceIsOriginal", true)
        hero:SetAttribute("ChaosDistantScenery", false)
        expect(SceneryLodRules.heroArchitectureOwner(root)).toBe(nil)
        root:Destroy()
    end)

    it("uses progressively smaller budgets for lower tiers", function()
        local high = VisualBudgetRules.forTier("High")
        local medium = VisualBudgetRules.forTier("Medium")
        local low = VisualBudgetRules.forTier("Low")

        expect(high.Parts > medium.Parts).toBe(true)
        expect(medium.Parts > low.Parts).toBe(true)
        expect(high.Lights > medium.Lights).toBe(true)
        expect(medium.Lights > low.Lights).toBe(true)
        expect(high.Effects > medium.Effects).toBe(true)
        expect(medium.Effects > low.Effects).toBe(true)
    end)

    it("keeps local visual folder coverage unique and comprehensive", function()
        local seen = {}
        expect(#VisualBudgetRules.LocalFolders >= 37).toBe(true)

        for _, folderName in ipairs(VisualBudgetRules.LocalFolders) do
            expect(type(folderName)).toBe("string")
            expect(folderName ~= "").toBe(true)
            expect(seen[folderName] ~= true).toBe(true)
            seen[folderName] = true
        end
        -- Unlike root-level decorative folders, this lives under each
        -- marked lobby pad; live visual telemetry counts its Parts there.
        expect(seen.PracticeVectorGlyphLocal).toBe(true)
        expect(seen.PracticePadPolishLocal).toBe(true)
    end)

    it("classifies every managed GPU effect type consistently", function()
        local managed = {
            Instance.new("ParticleEmitter"),
            Instance.new("Trail"),
            Instance.new("Beam"),
            Instance.new("Highlight"),
            Instance.new("Smoke"),
            Instance.new("Fire"),
            Instance.new("Sparkles"),
        }

        for _, instance in ipairs(managed) do
            expect(VisualBudgetRules.isEffect(instance)).toBe(true)
            instance:Destroy()
        end

        local light = Instance.new("PointLight")
        expect(VisualBudgetRules.isLight(light)).toBe(true)
        expect(VisualBudgetRules.isEffect(light)).toBe(false)
        light:Destroy()
    end)

    it("audits marked arena mobility pad effects without counting server lighting", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local pads = {}
        for i = 1, 3 do
            local pad = Instance.new("Part")
            pad.Name = "MobilityPad" .. i
            pad:SetAttribute("ArenaMobilityPad", true)
            pad.Parent = mechanics

            local serverLight = Instance.new("PointLight")
            serverLight.Name = "MobilityPadLight"
            serverLight.Parent = pad
            local serverEmitter = Instance.new("ParticleEmitter")
            serverEmitter.Name = "UnrelatedServerEmitter"
            serverEmitter.Parent = pad

            local attachment = Instance.new("Attachment")
            attachment.Name = "LocalMobilityVfx"
            attachment.Parent = pad
            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = "MobilityPulseLocal"
            emitter.Parent = attachment

            local highlight = Instance.new("Highlight")
            highlight.Name = "MobilityPadHighlightLocal"
            highlight.Parent = pad
            pads[i] = pad
        end

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(audited).toBe(3)

        -- Late marker removal immediately excludes a pad from local budget
        -- without confusing server-owned VFX with local ownership.
        pads[1]:SetAttribute("ArenaMobilityPad", false)
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(4)
        expect(audited).toBe(2)

        pads[2]:FindFirstChild("LocalMobilityVfx"):Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(3)
        expect(audited).toBe(2)

        pads[3]:Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)
        expect(audited).toBe(1)

        pads[2]:FindFirstChild("MobilityPadHighlightLocal"):Destroy()
        metrics, audited = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        expect(audited).toBe(0)
        root:Destroy()
    end)

    it("counts four client practice-pad emitters and highlights nested under the lobby", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby
        local pads, bundles = {}, {}

        for i = 1, 4 do
            local pad = Instance.new("Part")
            pad.Name = "PracticeBoostPad" .. i
            pad:SetAttribute("LobbyPracticePad", true)
            pad.Parent = activities
            local serverLight = Instance.new("PointLight")
            serverLight.Parent = pad
            local bundle = LobbyPracticeVisualKit.create(pad)
            expect(bundle ~= nil).toBe(true)
            pads[#pads + 1] = pad
            bundles[#bundles + 1] = bundle
        end
        -- A server-owned unrelated effect must not consume the local
        -- budget merely because it happens to be under a lobby pad.
        local unrelated = Instance.new("ParticleEmitter")
        unrelated.Name = "ServerDecorEffect"
        unrelated.Parent = pads[1]

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(4)
        expect(metrics.Effects).toBe(8) -- emitter + highlight per pad
        expect(metrics.Lights).toBe(0) -- server-owned PointLight excluded
        expect(metrics.Parts).toBe(0) -- server-owned pads excluded
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)

        LobbyPracticeVisualKit.destroy(bundles[4])
        metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(3)
        expect(metrics.Effects).toBe(6)
        LobbyPracticeVisualKit.destroy(bundles[3])
        LobbyPracticeVisualKit.destroy(bundles[2])
        LobbyPracticeVisualKit.destroy(bundles[1])
        metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts new directional practice glyphs within existing local LOD budgets", function()
        local root = Instance.new("Folder")
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby
        local pad = Instance.new("Part")
        pad.Size = Vector3.new(7.2, 0.3, 7.2)
        pad:SetAttribute("LobbyPracticePad", true)
        pad.Parent = activities
        local bundle = LobbyPracticeVisualKit.create(pad)
        local glyphs = require("../../src/client/LobbyPracticeGlyphKit")
        local high = glyphs.build(bundle.folder, pad,
            "High", Vector3.new(0, 0, -150))
        expect(high ~= nil and #high:GetChildren() == 6).toBe(true)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(6)
        expect(metrics.Effects).toBe(2)
        high:Destroy()
        local low = glyphs.build(bundle.folder, pad,
            "Low", Vector3.new(0, 0, -150))
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(2)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        LobbyPracticeVisualKit.destroy(bundle)
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("audits avatar and solo-bot polish without server rig geometry", function()
        local root = Instance.new("Folder")
        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        local models = {}

        for index = 1, 3 do
            local model = Instance.new("Model")
            model.Name = index == 1 and "LivePlayerCharacter" or "SoloBot" .. index
            if index > 1 then model:SetAttribute("AISurvivor", true) end
            model.Parent = index == 1 and root or bots
            local torso = Instance.new("Part")
            torso.Name = "UpperTorso"
            torso.Parent = model
            local rootPart = Instance.new("Part")
            rootPart.Name = "HumanoidRootPart"
            rootPart.Parent = model
            local polish = Instance.new("Highlight")
            polish.Name = "ChaosCharacterPolishHighlight"
            polish.Parent = model
            local light = Instance.new("PointLight")
            light.Name = "ChaosCharacterPolishLight"
            light.Parent = torso
            local serverLight = Instance.new("PointLight")
            serverLight.Name = "ServerGameplayLight"
            serverLight.Parent = torso
            local serverAura = Instance.new("Highlight")
            serverAura.Name = "ServerGameplayAura"
            serverAura.Parent = model
            models[index] = {model = model, light = light}
        end

        -- The visual audit counts allocated Instances even when a quality
        -- tier temporarily disables a cosmetic; no hidden GPU allocations.
        models[3].light.Enabled = false
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Effects).toBe(3)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)

        -- An unrelated nested map rig is not owned by the character polish
        -- client controller and must not enter its budget accounting.
        local unrelatedFolder = Instance.new("Folder")
        unrelatedFolder.Parent = root
        local unrelated = Instance.new("Model")
        unrelated.Parent = unrelatedFolder
        Instance.new("Highlight").Parent = unrelated
        local unrelatedLight = Instance.new("PointLight")
        unrelatedLight.Name = "ChaosCharacterPolishLight"
        unrelatedLight.Parent = unrelated
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Effects).toBe(3)

        models[2].model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(2)
        expect(metrics.Effects).toBe(2)
        models[1].model:Destroy()
        models[3].model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts temporary Phase Dash ribbons on actual avatar roots", function()
        local root = Instance.new("Folder")
        local player = Instance.new("Model")
        player.Name = "PlayerCharacter"
        player.Parent = root
        local hrp = Instance.new("Part")
        hrp.Name = "HumanoidRootPart"
        hrp.Parent = player

        local ribbon = Instance.new("Trail")
        ribbon.Name = "PhaseDashRibbon"
        ribbon.Parent = hrp
        local orphan = Instance.new("Trail")
        orphan.Name = "PhaseDashRibbon"
        orphan.Parent = hrp
        orphan.Enabled = false

        local unrelated = Instance.new("Trail")
        unrelated.Name = "ServerCharacterTrail"
        unrelated.Parent = hrp
        local wrongType = Instance.new("Part")
        wrongType.Name = "PhaseDashRibbon"
        wrongType.Parent = hrp
        local torso = Instance.new("Part")
        torso.Name = "UpperTorso"
        torso.Parent = player
        local wrongParent = Instance.new("Trail")
        wrongParent.Name = "PhaseDashRibbon"
        wrongParent.Parent = torso

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(2)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        ribbon:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)

        -- Phase Dash does not normally run for bots, but the client-only
        -- accounting must also track a named ribbon on any streamed model.
        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        player.Parent = bots
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(1)
        orphan:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts human motion ribbons and hazard reaction beams on avatar roots", function()
        local root = Instance.new("Folder")
        local model = Instance.new("Model")
        model.Name = "RealCharacter"
        model.Parent = root
        local hrp = Instance.new("Part")
        hrp.Name = "HumanoidRootPart"
        hrp.Parent = model

        local names = {
            "ChaosMotionTrail", "PhaseDashRibbon",
            "ChaosReactionDodge", "ChaosReactionShock",
            "ChaosReactionLanding",
        }
        local effects = {}
        for _, name in ipairs(names) do
            local effect = Instance.new(
                (name == "ChaosMotionTrail" or name == "PhaseDashRibbon")
                    and "Trail" or "Beam"
            )
            effect.Name = name
            effect.Enabled = name ~= "ChaosReactionShock"
            effect.Parent = hrp
            effects[#effects + 1] = effect
        end
        local excludedServerTrail = Instance.new("Trail")
        excludedServerTrail.Name = "AISurvivorCosmeticTrail"
        excludedServerTrail.Parent = hrp
        local fake = Instance.new("Part")
        fake.Name = "ChaosReactionShock"
        fake.Parent = hrp
        local unrelated = Instance.new("Beam")
        unrelated.Name = "ServerExplosionBeam"
        unrelated.Parent = hrp
        local wrongParent = Instance.new("Beam")
        wrongParent.Name = "ChaosReactionLanding"
        wrongParent.Parent = model

        local bots = Instance.new("Folder")
        bots.Name = "AISurvivors"
        bots.Parent = root
        local bot = Instance.new("Model")
        bot:SetAttribute("AISurvivor", true)
        bot.Parent = bots
        local botRoot = Instance.new("Part")
        botRoot.Name = "HumanoidRootPart"
        botRoot.Parent = bot
        local botShock = Instance.new("Beam")
        botShock.Name = "ChaosReactionShock"
        botShock.Parent = botRoot

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        effects[2]:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(5)
        bot:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(4)
        model:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts duplicate orphan polish lights as actual allocated lights", function()
        local root = Instance.new("Folder")
        local model = Instance.new("Model")
        model.Parent = root
        local torso = Instance.new("Part")
        torso.Parent = model
        for _ = 1, 3 do
            local light = Instance.new("PointLight")
            light.Name = "ChaosCharacterPolishLight"
            light.Parent = torso
        end
        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(3)
        expect(metrics.Parts).toBe(0)
        root:Destroy()
    end)

    it("collects parts lights and effects from registered visual folders", function()
        local root = Instance.new("Folder")
        local layer = Instance.new("Folder")
        layer.Name = VisualBudgetRules.LocalFolders[1]
        layer.Parent = root

        local part = Instance.new("Part")
        part.Parent = layer

        local light = Instance.new("PointLight")
        light.Parent = part

        local attachment = Instance.new("Attachment")
        attachment.Parent = part

        local emitter = Instance.new("ParticleEmitter")
        emitter.Parent = attachment

        local highlight = Instance.new("Highlight")
        highlight.Parent = layer

        local smoke = Instance.new("Smoke")
        smoke.Parent = part

        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(1)
        expect(metrics.Lights).toBe(1)
        expect(metrics.Effects).toBe(3)

        root:Destroy()
    end)

    it("counts transient Phase Dash facets and Showtime glyphs in mobile budgets", function()
        local root = Instance.new("Folder")
        local dash = Instance.new("Folder")
        dash.Name = "PhaseDashVfxLocal"
        dash.Parent = root
        local showtime = Instance.new("Folder")
        showtime.Name = "LobbyShowtimeLocal"
        showtime.Parent = root

        for index = 1, 7 do
            local part = Instance.new("Part")
            part.Name = "PhaseDashRingFacet" .. index
            part.CanCollide = false
            part.Parent = dash
        end
        for index = 1, 3 do
            local part = Instance.new("Part")
            part.Name = "OrbitDanceGlyph" .. index
            part.CanCollide = false
            part.Parent = showtime
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(10)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits the entire four-gate Flux Relay scene rather than hiding it from budget metrics", function()
        local root = Instance.new("Folder")
        local flux = Instance.new("Folder")
        flux.Name = "FluxRelayLocal"
        flux.Parent = root
        for index = 1, 4 do
            for partIndex = 1, 12 do
                local piece = Instance.new("Part")
                piece.Name = "FluxGate" .. index .. "_" .. partIndex
                piece.CanCollide = false
                piece.Parent = flux
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(48)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("tracks up to twenty-four Orbital helix runner glyphs at High quality", function()
        local root = Instance.new("Folder")
        local helix = Instance.new("Folder")
        helix.Name = "OrbitalHelixLocal"
        helix.Parent = root
        for index = 1, 24 do
            local glyph = Instance.new("Part")
            glyph.Name = "HelixMotionGlyph"
            glyph.CanCollide = false
            glyph.CanTouch = false
            glyph.CanQuery = false
            glyph.Parent = helix
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(24)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("counts at most one transient High-tier Skyrail impulse flare", function()
        local root = Instance.new("Folder")
        local skyrail = Instance.new("Folder")
        skyrail.Name = "TowerSkyrailLocal"
        skyrail.Parent = root
        -- 48 authored structure/courier parts + 8 one-shot shards.
        for index = 1, 56 do
            local part = Instance.new("Part")
            part.Name = "TowerSkyrailLocal" .. index
            part.Anchored = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
            part.Parent = skyrail
        end
        local metrics = VisualBudgetRules.collect(root)
        expect(metrics.Parts).toBe(56)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("budgets noncolliding Tower Skyrail conductor structures and couriers", function()
        local folder = Instance.new("Folder")
        local skyrail = Instance.new("Folder")
        skyrail.Name = "TowerSkyrailLocal"
        skyrail.Parent = folder
        -- Maximum authored High tier: 2 pillars + 2 inset fibers +
        -- 2 counterweights + 1 header + 1 crown + 2 wings + 2 runners
        -- = 12 parts per bridge / 48 for all four bridges.
        for index = 1, 48 do
            local piece = Instance.new("Part")
            piece.Name = "Skyrail" .. index
            piece.CanCollide = false
            piece.Parent = skyrail
        end
        local metrics, counted = VisualBudgetRules.collect(folder)
        expect(counted).toBe(1)
        expect(metrics.Parts).toBe(48)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        folder:Destroy()
    end)

    it("includes all four detailed Classic Grid Circuit monuments in visual telemetry", function()
        local root = Instance.new("Folder")
        local circuit = Instance.new("Folder")
        circuit.Name = "GridCircuitLocal"
        circuit.Parent = root
        -- High tier: 25 parts per monument (100 total), plus
        -- 3 chevrons * 2 strokes * 4 route edges = 24 guide parts.
        for index = 1, 124 do
            local piece = Instance.new("Part")
            piece.Name = "CircuitArt" .. index
            piece.CanCollide = false
            piece.Parent = circuit
        end
        local metrics, count = VisualBudgetRules.collect(root)
        expect(count).toBe(1)
        expect(metrics.Parts).toBe(124)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits temporary meteor and bomb setpieces under their shared local folder", function()
        local root = Instance.new("Folder")
        local folder = Instance.new("Folder")
        folder.Name = "ImpactSetpieceLocal"
        folder.Parent = root
        local meteor = Instance.new("Folder")
        meteor.Name = "ImpactSignature_Meteor"
        meteor.Parent = folder
        local bomb = Instance.new("Folder")
        bomb.Name = "ImpactSignature_Bomb"
        bomb.Parent = folder
        for i = 1, 7 do
            Instance.new("WedgePart").Parent = meteor
        end
        for i = 1, 8 do
            Instance.new("Part").Parent = bomb
        end
        local found = 0
        for _, name in ipairs(VisualBudgetRules.LocalFolders) do
            if name == folder.Name then
                found += 1
            end
        end
        expect(found).toBe(1)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(15)
        root:Destroy()
    end)

    it("includes short-lived sprint and skid traces in the live part count", function()
        local root = Instance.new("Folder")
        local effects = Instance.new("Folder")
        effects.Name = "LocomotionContactLocal"
        effects.Parent = root
        local sprint = Instance.new("Folder")
        sprint.Name = "ChaosLaunchContact"
        sprint.Parent = effects
        for i = 1, 4 do
            local trace = Instance.new("Part")
            trace.Name = "LaunchFootTrace" .. i
            trace.Parent = sprint
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(1)
        expect(metrics.Parts).toBe(4)
        root:Destroy()
    end)

    it("audits all transient winner and transition contours without solid screen-covering disks", function()
        local root = Instance.new("Folder")
        local transitions = Instance.new("Folder")
        transitions.Name = "RoundTransitionPulsesLocal"
        transitions.Parent = root
        local celebrations = Instance.new("Folder")
        celebrations.Name = "RoundCelebrationPulsesLocal"
        celebrations.Parent = root
        local cf = CFrame.new(0, 5, 0)
        local tint = Color3.fromRGB(75, 214, 255)
        local first = CinematicPulseRingKit.emit(
            transitions, "RoundStart", cf, tint, 1, 82, 0.6, "Medium", true
        )
        local second = CinematicPulseRingKit.emit(
            celebrations, "Win", cf, tint, 1, 22, 0.6, "High", true
        )
        local third = CinematicPulseRingKit.emit(
            celebrations, "Clutch", cf, tint, 1, 19, 0.6, "High", true
        )
        expect(#first).toBe(6)
        expect(#second).toBe(8)
        expect(#third).toBe(8)
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(22)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        for _, arc in ipairs(first) do
            expect(arc.Shape).toBe(Enum.PartType.Block)
            expect(arc.CanCollide).toBe(false)
        end
        root:Destroy()
    end)

    it("counts simultaneous bot landings and launch marks in the live graphics budget", function()
        local root = Instance.new("Folder")
        local landing = Instance.new("Folder")
        landing.Name = "CharacterContactLocal"
        landing.Parent = root
        local locomotion = Instance.new("Folder")
        locomotion.Name = "LocomotionContactLocal"
        locomotion.Parent = root
        local frame = CFrame.new(0, 5, 0)
        for i = 1, 4 do
            local shifted = frame * CFrame.new(i * 2, 0, 0)
            local botLanding = LandingImprintKit.build(
                landing, shifted, Color3.fromRGB(120, 210, 230),
                "Mechanical", Enum.Material.Metal, 3, 0.85, false
            )
            expect(#botLanding).toBe(3)
            local botPivot = LocomotionGroundFx.build(
                locomotion, shifted, "Pivot", 0.9, "High"
            )
            expect(botPivot ~= nil).toBe(true)
            expect(#botPivot:GetChildren()).toBe(4)
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(28)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("counts all double-chaos intro strokes without full arena-covering cylinders", function()
        local root = Instance.new("Folder")
        local glyph = Instance.new("Folder")
        glyph.Name = "DisasterIntroGlyphLocal"
        glyph.Parent = root
        local motion = Instance.new("Folder")
        motion.Name = "DisasterIntroMotionLocal"
        motion.Parent = root
        local frame = CFrame.new(8, 3, -11)
            * CFrame.Angles(math.rad(7), math.rad(32), 0)
        local blue = Color3.fromRGB(75, 175, 255)
        local red = Color3.fromRGB(255, 80, 80)
        for _, kind in ipairs({"freeze", "blast"}) do
            local pieces = DisasterIntroMotionKit.emit(
                motion, kind, frame, 98, blue, red,
                "High", true, 0.58
            )
            expect(#pieces).toBe(6)
            for _, piece in ipairs(pieces) do
                expect(piece:IsA("Part") or piece:IsA("WedgePart")).toBe(true)
                if piece:IsA("Part") then
                    expect(piece.Shape).toBe(Enum.PartType.Block)
                end
                expect(piece.CanCollide).toBe(false)
                expect(piece.CanTouch).toBe(false)
                expect(piece.CanQuery).toBe(false)
                expect(piece.Size.Y <= 0.08).toBe(true)
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(12)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("audits shrinking/blackout scenery and both simultaneous climax signatures", function()
        local root = Instance.new("Folder")
        local persistent = Instance.new("Folder")
        persistent.Name = "ChaosMotionDisasterVfxLocal"
        persistent.Parent = root
        for i = 1, 8 do
            local part = Instance.new("Part")
            part.Name = i <= 4 and "ShrinkPerimeterLocal" .. i
                or "BlackoutEmergencyBeacon" .. (i - 4)
            part.Parent = persistent
        end
        local transient = Instance.new("Folder")
        transient.Name = "DisasterClimaxLocal"
        transient.Parent = root
        local frame = CFrame.new(3, 5, 7)
            * CFrame.Angles(0, math.rad(20), math.rad(9))
        local arenaSize = Vector3.new(124, 3, 92)
        local primary = Color3.fromRGB(250, 85, 110)
        local secondary = Color3.fromRGB(245, 220, 160)
        for _, kind in ipairs({"blast", "shrink"}) do
            local pieces = DisasterBoundaryClimaxKit.emit(transient, kind,
                frame, arenaSize, 3, primary, secondary, "High", false)
            expect(#pieces).toBe(6)
            for _, part in ipairs(pieces) do
                expect(part.CanCollide).toBe(false)
                expect(part.CanTouch).toBe(false)
                expect(part.CanQuery).toBe(false)
                expect(part.CastShadow).toBe(false)
            end
        end
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(2)
        expect(metrics.Parts).toBe(20)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        expect(VisualBudgetRules.withinBudget("Low", metrics)).toBe(true)
        root:Destroy()
    end)

    it("counts client lava light and hazard-attached particles without server shell parts", function()
        local root = Instance.new("Folder")
        local lava = Instance.new("Part")
        lava.Name = "RoundLava"
        lava.Parent = root
        local glow = Instance.new("SurfaceLight")
        glow.Name = "LavaGlowLocal"
        glow.Parent = lava
        local heat = Instance.new("Attachment")
        heat.Name = "LavaHeatLocal"
        heat.Parent = lava
        local embers = Instance.new("ParticleEmitter")
        embers.Name = "LavaEmbers"
        embers.Parent = heat
        local freeze = Instance.new("Part")
        freeze.Name = "FreezeWarning"
        freeze.Parent = root
        local mist = Instance.new("Attachment")
        mist.Name = "FreezeMistLocal"
        mist.Parent = freeze
        local emitter = Instance.new("ParticleEmitter")
        emitter.Name = "FreezeMist"
        emitter.Parent = mist
        -- Unrelated server-authored and wrongly parented objects do not count.
        local serverLamp = Instance.new("SurfaceLight")
        serverLamp.Name = "AuthoritativeHazardLight"
        serverLamp.Parent = lava
        local wrongType = Instance.new("Part")
        wrongType.Name = "LavaGlowLocal"
        wrongType.Parent = lava
        local fake = Instance.new("Part")
        fake.Name = "RoundLava"
        fake.Parent = root
        Instance.new("SurfaceLight").Parent = fake
        local metrics, folders = VisualBudgetRules.collect(root)
        expect(folders).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(1)
        expect(metrics.Effects).toBe(2)
        glow:Destroy()
        embers:Destroy()
        emitter:Destroy()
        metrics = VisualBudgetRules.collect(root)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(0)
        root:Destroy()
    end)

    it("counts attached local meteor trails even when meteor shells are server owned", function()
        local root = Instance.new("Folder")
        for i = 1, 6 do
            local meteor = Instance.new("Part")
            meteor.Name = "RoundMeteor"
            meteor.Parent = root
            local trail = Instance.new("Trail")
            trail.Name = "SignatureMeteorTrail"
            trail.Parent = meteor
        end
        local other = Instance.new("Part")
        other.Name = "OtherHazard"
        other.Parent = root
        local extra = Instance.new("Trail")
        extra.Name = "SignatureMeteorTrail"
        extra.Parent = other
        local metrics, audited = VisualBudgetRules.collect(root)
        expect(audited).toBe(0)
        expect(metrics.Parts).toBe(0)
        expect(metrics.Lights).toBe(0)
        expect(metrics.Effects).toBe(6)
        expect(VisualBudgetRules.withinBudget("High", metrics)).toBe(true)
        root:Destroy()
    end)

    it("classifies live visual budget status before any tier lookup", function()
        expect(type(VisualBudgetRules.status)).toBe("function")
        expect(VisualBudgetRules.status("High", {
            Parts = 1,
            Lights = 1,
            Effects = 1,
        })).toBe("OK")

        local high = VisualBudgetRules.forTier("High")
        expect(VisualBudgetRules.status("High", {
            Parts = high.Parts + 1,
            Lights = 0,
            Effects = 0,
        })).toBe("OVER")

        expect(VisualBudgetRules.status("Unknown", {
            Parts = 0,
            Lights = 0,
            Effects = 0,
        })).toBe("UNKNOWN")
    end)

    it("detects over-budget visual scenes", function()
        expect(VisualBudgetRules.withinBudget("Medium", {
            Parts = 400,
            Lights = 20,
            Effects = 30,
        })).toBe(true)

        expect(VisualBudgetRules.withinBudget("Low", {
            Parts = 441,
            Lights = 20,
            Effects = 30,
        })).toBe(false)

        local over = VisualBudgetRules.overages("Low", {
            Parts = 450,
            Lights = 40,
            Effects = 60,
        })

        expect(over.Parts).toBe(10)
        expect(over.Lights).toBe(8)
        expect(over.Effects).toBe(4)
    end)
end)


describe("Android decorative scenery LOD stability", function()
    it("keeps floating arena supports underneath a shrinking collision floor", function()
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Anchored = true
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(35, 12, -20)
        base.Parent = workspace

        local decor = Instance.new("Folder")
        decor.Name = "ArenaUnderstructureLocal"
        decor.Parent = workspace

        local support = Instance.new("Part")
        support.Size = Vector3.new(3, 12, 3)
        support.CFrame = base.CFrame * CFrame.new(32, -7, 24)
        support.Anchored = true
        support.CanCollide = false
        support.Parent = decor

        local beam = Instance.new("Part")
        beam.Size = Vector3.new(55, 0.8, 2)
        beam.CFrame = base.CFrame * CFrame.new(0, -2.5, -24)
        beam.Anchored = true
        beam.Parent = decor

        local snapshot = ArenaFloorFollowerKit.capture(base, decor)
        expect(snapshot ~= nil).toBe(true)
        base.Size = Vector3.new(45, 2, 36)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        expect(math.abs(support.Position.X - (35 + 32 * 0.45)) < 0.001).toBe(true)
        expect(math.abs(support.Position.Z - (-20 + 24 * 0.45)) < 0.001).toBe(true)
        expect(math.abs(support.Position.Y - 5) < 0.001).toBe(true)
        expect(math.abs(beam.Size.X - 55 * 0.45) < 0.001).toBe(true)
        expect(math.abs(beam.Size.Y - 0.8) < 0.001).toBe(true)

        base.Size = Vector3.new(100, 2, 80)
        expect(ArenaFloorFollowerKit.apply(snapshot)).toBe(2)
        expect(math.abs(support.Position.X - 67) < 0.001).toBe(true)
        expect(math.abs(support.Position.Z - 4) < 0.001).toBe(true)
        expect(math.abs(beam.Size.X - 55) < 0.001).toBe(true)

        decor:Destroy()
        base:Destroy()
    end)


    it("locates nested pad cosmetics but never server-owned lobby scenery", function()
        local root = Instance.new("Folder")
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(0)
        expect(#SceneryLodRules.practicePadVisualOwners(nil)).toBe(0)
        local generated = Instance.new("Folder")
        generated.Name = "GeneratedMap"
        generated.Parent = root
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby

        local pads = {}
        for i = 1, 4 do
            local pad = Instance.new("Part")
            pad.Name = "PracticeBoostPad" .. i
            pad:SetAttribute("LobbyPracticePad", true)
            pad.Parent = activities
            local light = Instance.new("PointLight")
            light.Name = "PracticePadLight"
            light.Parent = pad
            pads[i] = pad
            expect(LobbyPracticeVisualKit.create(pad) ~= nil).toBe(true)
        end
        local serverDecoration = Instance.new("ParticleEmitter")
        serverDecoration.Name = "ServerDecorMotes"
        serverDecoration.Parent = pads[1]

        local owners = SceneryLodRules.practicePadVisualOwners(root)
        expect(#owners).toBe(8)
        local unique = {}
        local highlightContainers, emitterContainers = 0, 0
        for _, owner in ipairs(owners) do
            expect(unique[owner] == nil).toBe(true)
            unique[owner] = true
            expect(owner:IsDescendantOf(activities)).toBe(true)
            expect(owner:IsA("BasePart")).toBe(false)
            expect(owner:IsA("Light")).toBe(false)
            if owner.Name == "PracticePadPolishLocal" then
                expect(owner:IsA("Folder")).toBe(true)
                highlightContainers += 1
            elseif owner.Name == "PracticeMotesAttachment" then
                expect(owner:IsA("Attachment")).toBe(true)
                emitterContainers += 1
            else
                expect(false).toBe(true)
            end
        end
        expect(highlightContainers).toBe(4)
        expect(emitterContainers).toBe(4)
        expect(unique[serverDecoration] == nil).toBe(true)
        expect(SceneryLodRules.visible("Low", 150, 100, 150, nil))
            .toBe(false)
        expect(SceneryLodRules.visible("High", 1000, 100, 150, nil))
            .toBe(true)

        pads[4]:Destroy()
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(6)
        local stray = Instance.new("Part")
        stray.Name = "UnrelatedPad"
        stray.Parent = activities
        local decoy = Instance.new("Folder")
        decoy.Name = "PracticePadPolishLocal"
        decoy.Parent = stray
        expect(#SceneryLodRules.practicePadVisualOwners(root)).toBe(6)
        root:Destroy()
    end)

    it("mounts a real original cargo vessel beyond Harbor without collisions or extra LOD owners", function()
        local HarborScenery = require("../../src/server/HarborScenery")
        local VisualTheme = require("../../src/shared/VisualTheme")
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(320, 2, 320)
        base.Anchored = true
        base.Parent = arena

        local fleet = HarborScenery.build(
            decor, base, VisualTheme.arena("Harbor")
        )
        expect(fleet ~= nil and fleet.Parent == decor).toBe(true)
        expect(#SceneryLodRules.harborGantryOwners(arena)).toBe(5)
        local ship = fleet:FindFirstChild("HarborCargoVessel")
        expect(ship ~= nil and ship:IsA("Model")).toBe(true)
        expect(ship:GetAttribute("ChaosDistantScenery")).toBe(true)
        expect(ship:GetAttribute("CosmeticOnly")).toBe(true)
        expect(ship:GetAttribute("SourceIsOriginal")).toBe(true)
        expect(ship:GetAttribute("HarborVesselScenery")).toBe(true)
        expect(ship.ModelStreamingMode).toBe(Enum.ModelStreamingMode.Atomic)
        for _, component in ipairs({
            "MainHull", "LowerKeel", "MainCargoDeck",
            "BowTaperPort", "CargoBaySill2", "Container2_1_2",
            "Wheelhouse", "BridgePanorama", "RadarMast",
        }) do
            expect(ship:FindFirstChild(component) ~= nil).toBe(true)
        end
        local parts = ship:GetDescendants()
        expect(#parts >= 65 and #parts <= 120).toBe(true)
        local arenaNorth = base.Position.Z - base.Size.Z * 0.5
        -- Low device quality retains only authentic major ship masses,
        -- rather than an empty skyline or the entire detail-heavy fleet.
        local lowCount = 0
        local lowNames = {}
        local entryVisible = SceneryLodRules.entryVisible
        expect(SceneryLodRules.visible("Low", 50, 0, 185, nil))
            .toBe(false)
        for _, part in ipairs(parts) do
            local essential = part:GetAttribute("HeroSilhouetteEssential") == true
            if essential then
                lowCount += 1
                lowNames[part.Name] = true
            end
            expect(entryVisible("Low", false, true, essential))
                .toBe(essential)
            expect(entryVisible("Medium", false, true, essential))
                .toBe(false)
            expect(entryVisible("High", true, true, essential))
                .toBe(true)
            expect(part:IsA("BasePart")).toBe(true)
            expect(part.Anchored).toBe(true)
            expect(part.CanCollide).toBe(false)
            expect(part.CanTouch).toBe(false)
            expect(part.CanQuery).toBe(false)
            expect(part.CastShadow).toBe(false)
            expect(part.Position.Z + part.Size.Z * 0.5 < arenaNorth - 12)
                .toBe(true)
        end
        expect(lowCount).toBe(14)
        for _, expected in ipairs({
            "MainHull", "LowerKeel", "MainCargoDeck",
            "BowTaperPort", "BowTaperStarboard", "SternDeckhouse",
            "Wheelhouse", "ExhaustStack",
            "Container1_-1_1", "Container1_1_1",
            "Container2_-1_1", "Container2_1_1",
            "Container3_-1_1", "Container3_1_1",
        }) do
            expect(lowNames[expected]).toBe(true)
        end
        for _, gantry in ipairs(fleet:GetChildren()) do
            if gantry ~= ship then
                for _, part in ipairs(gantry:GetDescendants()) do
                    expect(part:GetAttribute("HeroSilhouetteEssential") == true)
                        .toBe(false)
                end
            end
        end

        -- Clients may cull this original model, never real gameplay Parts.
        ship:SetAttribute("CosmeticOnly", false)
        expect(#SceneryLodRules.harborGantryOwners(arena)).toBe(4)
        ship:SetAttribute("CosmeticOnly", true)
        expect(#SceneryLodRules.harborGantryOwners(arena)).toBe(5)
        arena:Destroy()
    end)

    it("preserves only marked original 3D silhouette pieces on Android Low", function()
        local partVisible = SceneryLodRules.entryVisible
        expect(partVisible("Low", false, true, true)).toBe(true)
        expect(partVisible("Low", false, true, false)).toBe(false)
        expect(partVisible("Low", false, false, true)).toBe(false)
        expect(partVisible("Medium", false, true, true)).toBe(false)
        expect(partVisible("High", false, true, true)).toBe(false)
        expect(partVisible("Medium", true, true, false)).toBe(true)
        expect(partVisible("High", true, false, false)).toBe(true)
        -- Unrelated gameplay/LOD groups cannot use the hero exception.
        expect(partVisible("Low", false, nil, true)).toBe(false)
        expect(partVisible("Low", nil, true, false)).toBe(false)
    end)

    it("retains initial thresholds and never hides High quality scenery", function()
        local visible = SceneryLodRules.visible
        expect(visible("Low", 125, 125, 185, nil)).toBe(true)
        expect(visible("Low", 125.01, 125, 185, nil)).toBe(false)
        expect(visible("Medium", 185, 125, 185, nil)).toBe(true)
        expect(visible("Medium", 185.01, 125, 185, nil)).toBe(false)
        expect(visible("High", 10000, 125, 185, nil)).toBe(true)
        expect(visible("High", math.huge, 125, 185, false)).toBe(true)
    end)

    it("prevents toggling when a camera grazes an LOD distance cutoff", function()
        local show = SceneryLodRules.visible
        expect(SceneryLodRules.Hysteresis).toBe(8)
        for _, tier in ipairs({"Low", "Medium"}) do
            local cutoff = tier == "Low" and 125 or 185
            expect(show(tier, cutoff + 5, 125, 185, true)).toBe(true)
            expect(show(tier, cutoff + 9, 125, 185, true)).toBe(false)
            expect(show(tier, cutoff - 5, 125, 185, false)).toBe(false)
            expect(show(tier, cutoff - 9, 125, 185, false)).toBe(true)
        end
    end)

    it("fails closed for invalid mobile distance measurements", function()
        local show = SceneryLodRules.visible
        expect(show("Low", -1, 125, 185, true)).toBe(false)
        expect(show("Low", 0/0, 125, 185, true)).toBe(false)
        expect(show("Low", math.huge, 125, 185, false)).toBe(false)
        expect(show("Medium", "near", 125, 185, nil)).toBe(false)
        expect(show("Medium", 20, 0, 185, nil)).toBe(true)
        expect(show("Low", 20, 0, 185, nil)).toBe(false)
    end)
end)

return nil
