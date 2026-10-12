--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaPresentation = require("../../src/shared/ArenaPresentation")
local VisualTheme = require("../../src/shared/VisualTheme")
local MapVisualReadiness = require("../../src/shared/MapVisualReadiness")
local ArenaSignatureKit = require("../../src/client/ArenaSignatureKit")
local ArenaDetailKit = require("../../src/client/ArenaDetailKit")
local PlatformFinishKit = require("../../src/client/PlatformFinishKit")
local ArenaEdgeFinishKit = require("../../src/client/ArenaEdgeFinishKit")
local ArenaSilhouetteAccentKit = require("../../src/client/ArenaSilhouetteAccentKit")
local ArenaDeckFinishKit = require("../../src/client/ArenaDeckFinishKit")
local ArenaSceneryFrames = require("../../src/shared/ArenaSceneryFrames")
local MobileReadabilityKit = require("../../src/client/MobileReadabilityKit")
local IdentityMotionRules = require("../../src/shared/ArenaIdentityMotionRules")
local IdentityMotionReadiness = require("../../src/shared/ArenaIdentityMotionReadiness")

local CENTER = Vector3.new(0, 0, 0)

local function planarUnit(vector)
    local flat = Vector3.new(vector.X, 0, vector.Z)
    return flat.Magnitude > 0.001 and flat.Unit or Vector3.zero
end

describe("Arena presentation", function()
    it("faces Classic spawns toward the arena center", function()
        local spawn = Vector3.new(30, 3, -30)
        local cf = ArenaPresentation.spawnCFrame("Classic", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        expect(cf.LookVector:Dot(inward) > 0.98).toBe(true)
    end)

    it("frames Towers inward while targeting elevated structure", function()
        local spawn = Vector3.new(-32, 3, -32)
        local target = ArenaPresentation.lookTarget("Towers", spawn, CENTER)
        local cf = ArenaPresentation.spawnCFrame("Towers", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)

        expect(target.Y > CENTER.Y + 8).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.90).toBe(true)
    end)

    it("aligns Crossroads spawns with a cardinal lane", function()
        local spawn = Vector3.new(36, 3, 18)
        local cf = ArenaPresentation.spawnCFrame("Crossroads", spawn, CENTER)
        expect(math.abs(cf.LookVector.X) > 0.98).toBe(true)
        expect(math.abs(cf.LookVector.Z) < 0.05).toBe(true)
    end)

    it("frames Orbital spawns along the ring instead of straight inward", function()
        local spawn = Vector3.new(35, 3, 0)
        local cf = ArenaPresentation.spawnCFrame("Orbital", spawn, CENTER)
        local inward = planarUnit(CENTER - spawn)
        local tangent = Vector3.new(0, 0, 1)

        expect(cf.LookVector:Dot(tangent) > 0.80).toBe(true)
        expect(cf.LookVector:Dot(inward) > 0.15).toBe(true)
    end)

    it("always returns a planar stable spawn orientation", function()
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local cf = ArenaPresentation.spawnCFrame(
                variant,
                Vector3.new(-30, 3, 30),
                CENTER
            )
            expect(math.abs(cf.LookVector.Y) < 0.001).toBe(true)
            expect(cf.LookVector.Magnitude > 0.99).toBe(true)
        end
    end)
end)

describe("Kinetic arena signatures", function()
    it("builds four genuinely different tier-aware scenic monuments", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        base.CFrame = CFrame.new(0, 0, 0)
        local ids = {
            {"Classic", "ClassicRadarSweep"},
            {"Towers", "TowerAnimatedLift"},
            {"Crossroads", "CrossroadAnimatedSignal1"},
            {"Orbital", "OrbitalGyroscopeHeart"},
        }
        for _, entry in ipairs(ids) do
            local variant = entry[1]
            local signature = entry[2]
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaSignatureKit.build(root, base, variant, tier, VisualTheme)
                expect(built.folder:FindFirstChild(signature) ~= nil).toBe(true)
                expect(#built.parts <= built.profile.MaxParts).toBe(true)
                expect(#built.animated >= 1).toBe(true)
                for _, part in ipairs(built.parts) do
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                end
                built.folder:Destroy()
            end
        end
        base:Destroy()
        root:Destroy()
    end)


    it("adds an arena-specific silhouette beyond a generic pillar or neon bar", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(110, 2, 110)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local signatures = {
                Classic = "ClassicGoniometerArc1",
                Towers = "TowerTensionTruss-1_1",
                Crossroads = "CrossroadRouteChevron-1_1",
                Orbital = "OrbitalContainmentPylon1",
            }
            for arenaId, motif in pairs(signatures) do
                local bundle = ArenaSignatureKit.build(parent, base, arenaId, tier, VisualTheme)
                expect(bundle.folder:FindFirstChild(motif) ~= nil).toBe(true)
                expect(#bundle.parts > 12).toBe(true)
                expect(#bundle.parts <= bundle.profile.MaxParts).toBe(true)
                for _, item in ipairs(bundle.parts) do
                    expect(item.Anchored).toBe(true)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                end
                bundle.folder:Destroy()
            end
        end
        base:Destroy()
        parent:Destroy()
    end)

    it("animates original tower counterweights opposite the lift and restores accessibility pose", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local built = ArenaSignatureKit.build(root, base, "Towers", tier, VisualTheme)
            local lift = built.folder:FindFirstChild("TowerAnimatedLift")
            local left = built.folder:FindFirstChild("TowerCounterweight-1")
            local right = built.folder:FindFirstChild("TowerCounterweight1")
            expect(lift ~= nil and left ~= nil and right ~= nil).toBe(true)
            local liftFrame, leftFrame, rightFrame = lift.CFrame, left.CFrame, right.CFrame
            ArenaSignatureKit.update(built, 2.5, false)
            local liftDelta = lift.Position.Y - liftFrame.Position.Y
            local leftDelta = left.Position.Y - leftFrame.Position.Y
            local rightDelta = right.Position.Y - rightFrame.Position.Y
            expect(liftDelta > 0).toBe(true)
            expect(leftDelta < 0 and rightDelta < 0).toBe(true)
            expect(math.abs(leftDelta) <= 1.401).toBe(true)
            expect(math.abs(rightDelta - leftDelta) < 0.0001).toBe(true)
            ArenaSignatureKit.update(built, 9, true)
            expect(lift.CFrame).toBe(liftFrame)
            expect(left.CFrame).toBe(leftFrame)
            expect(right.CFrame).toBe(rightFrame)
            built.folder:Destroy()
        end
        base:Destroy()
        root:Destroy()
    end)

    it("keeps tower geometry finite when an invalid animation clock arrives", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        local built = ArenaSignatureKit.build(root, base, "Towers", "Low", VisualTheme)
        ArenaSignatureKit.update(built, 0, true)
        local cabin = built.folder:FindFirstChild("TowerAnimatedLift")
        local weight = built.folder:FindFirstChild("TowerCounterweight1")
        local cabinFrame, weightFrame = cabin.CFrame, weight.CFrame
        for _, invalid in ipairs({math.huge, -math.huge, 0 / 0, -5, 1e8, "not-a-time"}) do
            ArenaSignatureKit.update(built, invalid, false)
            expect(cabin.CFrame).toBe(cabinFrame)
            expect(weight.CFrame).toBe(weightFrame)
        end
        built.folder:Destroy()
        base:Destroy()
        root:Destroy()
    end)

    it("freezes motion predictably for mobile accessibility", function()
        local root = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 100)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local built = ArenaSignatureKit.build(root, base, variant, "Medium", VisualTheme)
            local animated = built.animated[1].part
            ArenaSignatureKit.update(built, 1, true)
            local frozenCF = animated.CFrame
            local frozenTransparency = animated.Transparency
            ArenaSignatureKit.update(built, 10, true)
            expect(animated.CFrame).toBe(frozenCF)
            expect(animated.Transparency).toBe(frozenTransparency)
            ArenaSignatureKit.update(built, 2, false)
            expect(
                animated.CFrame ~= frozenCF
                    or animated.Transparency ~= frozenTransparency
                    or variant == "Orbital"
            ).toBe(true)
            built.folder:Destroy()
        end
        base:Destroy()
        root:Destroy()
    end)
end)


describe("Late-replicated visual map readiness", function()
    it("rebuilds only when the target floor or arena base actually arrives", function()
        local generated = Instance.new("Folder")
        local calls = 0
        local sawBase = false
        local active = MapVisualReadiness.watch(generated, "Arena", "Base", function(base)
            calls += 1
            sawBase = base ~= nil
        end)
        expect(calls).toBe(1)
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        expect(calls).toBe(2)
        expect(sawBase).toBe(false)
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Parent = arena
        expect(calls).toBe(3)
        expect(sawBase).toBe(true)
        arena:SetAttribute("VariantId", "Orbital")
        expect(calls).toBe(4)
        expect(MapVisualReadiness.part(generated, "Arena", "Base")).toBe(base)
        base:Destroy()
        expect(calls).toBe(5)
        expect(sawBase).toBe(false)
        active()
        local replacement = Instance.new("Part")
        replacement.Name = "Base"
        replacement.Parent = arena
        expect(calls).toBe(5)
        generated:Destroy()
    end)

    it("detects a lobby floor that appears after its parent model", function()
        local generated = Instance.new("Folder")
        local calls = 0
        local current = nil
        local dispose = MapVisualReadiness.watch(generated, "Lobby", "Floor", function(floor)
            calls += 1
            current = floor
        end)
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = generated
        local floor = Instance.new("Part")
        floor.Name = "Floor"
        floor.Parent = lobby
        expect(calls).toBe(3)
        expect(current).toBe(floor)
        lobby:Destroy()
        expect(current == nil).toBe(true)
        dispose()
        generated:Destroy()
    end)
end)


describe("Arena architectural secondary motifs", function()
    it("keeps each arena uniquely recognizable across both prop scales", function()
        local root = Instance.new("Folder")
        local host = Instance.new("Part")
        host.Size = Vector3.new(6, 8, 5)
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            for _, role in ipairs({"Service", "Midground"}) do
                local names = ArenaDetailKit.names(variant, role)
                expect(names ~= nil).toBe(true)
                expect(#names).toBe(3)
                for _, tier in ipairs({"Low", "Medium", "High"}) do
                    local built = ArenaDetailKit.build(root, role, variant, host, tier,
                        VisualTheme.arena(variant))
                    expect(#built).toBe(ArenaDetailKit.count(tier))
                    for i, part in ipairs(built) do
                        expect(part.Name).toBe(names[i])
                        expect(part.Anchored).toBe(true)
                        expect(part.CanCollide).toBe(false)
                        expect(part.CanQuery).toBe(false)
                        expect(part.CanTouch).toBe(false)
                        expect(part:GetAttribute("ChaosVisualMotif")).toBe(true)
                        part:Destroy()
                    end
                end
            end
        end
        host:Destroy()
        root:Destroy()
    end)

    it("does not create geometry without a valid parent, host and arena", function()
        local folder = Instance.new("Folder")
        local host = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaDetailKit.build(folder, "Service", "Unknown", host, "High", theme)).toBe(0)
        expect(#ArenaDetailKit.build(folder, "Service", "Classic", nil, "High", theme)).toBe(0)
        expect(#ArenaDetailKit.build(folder, "Service", "Classic", host, "High", nil)).toBe(0)
        host:Destroy()
        folder:Destroy()
    end)
end)


describe("Moving platform premium trim kit", function()
    it("creates four distinctive, bounded, non-colliding welded motifs", function()
        local parent = Instance.new("Folder")
        local platform = Instance.new("Part")
        platform.Size = Vector3.new(12, 2, 12)
        platform.Parent = workspace
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = PlatformFinishKit.names(variant)
            expect(#names).toBe(3)
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = PlatformFinishKit.build(parent, platform, variant,
                    tier, VisualTheme.arena(variant))
                expect(#built).toBe(PlatformFinishKit.count(tier))
                for index, item in ipairs(built) do
                    expect(item.Name).toBe(names[index])
                    expect(item:GetAttribute("ChaosPlatformTrim")).toBe(true)
                    expect(item.Massless).toBe(true)
                    expect(item.Anchored).toBe(false)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                    local weld = item:FindFirstChild("ChaosPlatformTrimWeld")
                    expect(weld ~= nil).toBe(true)
                    expect(weld.Part0).toBe(item)
                    expect(weld.Part1).toBe(platform)
                    item:Destroy()
                end
            end
        end
        platform:Destroy()
        parent:Destroy()
    end)

    it("refuses unexpected variants and invalid platform parents", function()
        local container = Instance.new("Folder")
        local base = Instance.new("Part")
        expect(#PlatformFinishKit.build(container, base, "NotAnArena", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.build(container, nil, "Classic", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        expect(#PlatformFinishKit.build(nil, base, "Classic", "High",
            VisualTheme.arena("Classic"))).toBe(0)
        base:Destroy()
        container:Destroy()
    end)
end)
 

describe("Premium arena perimeter geometry", function()
    it("keeps the four outboard edge silhouettes distinct at every graphics tier", function()
        local parent = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 2, 80)
        base.CFrame = CFrame.new(21, 13, -17)
            * CFrame.Angles(0, math.rad(31), 0)
        local seen = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaEdgeFinishKit.names(variant)
            expect(#names).toBe(3)
            expect(seen[names[1]] == nil).toBe(true)
            seen[names[1]] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaEdgeFinishKit.build(
                    parent, base, variant, tier, VisualTheme.arena(variant))
                expect(#built).toBe(ArenaEdgeFinishKit.count(tier) * 4)
                local north = parent:FindFirstChild(names[1] .. "North")
                expect(north ~= nil).toBe(true)
                local offset = base.CFrame:PointToObjectSpace(north.Position)
                expect(offset.Z < -base.Size.Z * 0.5).toBe(true)
                for _, item in ipairs(built) do
                    expect(item:GetAttribute("ChaosEdgeFinish")).toBe(true)
                    expect(item.Anchored).toBe(true)
                    expect(item.CanCollide).toBe(false)
                    expect(item.CanTouch).toBe(false)
                    expect(item.CanQuery).toBe(false)
                    if tier == "Low" then
                        expect(item.Material == Enum.Material.Neon).toBe(false)
                    end
                    item:Destroy()
                end
            end
        end
        parent:Destroy()
        base:Destroy()
    end)

    it("does not generate unmanaged edge geometry for invalid inputs", function()
        local holder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaEdgeFinishKit.build(holder, base, "Unknown", "High", theme)).toBe(0)
        expect(#ArenaEdgeFinishKit.build(holder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaEdgeFinishKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        holder:Destroy()
        base:Destroy()
    end)
end)


describe("Arena skyline visual identity", function()
    it("keeps four distinct outboard silhouettes readable from Low to High", function()
        local holder = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(100, 3, 84)
        base.CFrame = CFrame.new(27, 14, -34)
            * CFrame.Angles(0, math.rad(34), 0)
        local primaryNames = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaSilhouetteAccentKit.names(variant)
            expect(#names).toBe(4)
            expect(primaryNames[names[1]] == nil).toBe(true)
            primaryNames[names[1]] = true
            for _, tierName in ipairs({"Low", "Medium", "High"}) do
                local built = ArenaSilhouetteAccentKit.build(
                    holder, base, variant, tierName, VisualTheme.arena(variant))
                expect(#built).toBe(ArenaSilhouetteAccentKit.count(tierName))
                for i, part in ipairs(built) do
                    expect(part.Name).toBe(names[i])
                    expect(part:GetAttribute("ChaosSilhouetteAccent")).toBe(true)
                    expect(part:GetAttribute("ArenaVariant")).toBe(variant)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Size.X > 0 and part.Size.Y > 0 and part.Size.Z > 0).toBe(true)
                    local relative = base.CFrame:PointToObjectSpace(part.Position)
                    expect(
                        math.abs(relative.X) > base.Size.X * 0.5
                            or math.abs(relative.Z) > base.Size.Z * 0.5
                    ).toBe(true)
                    if tierName == "Low" then
                        expect(part.Material == Enum.Material.Neon).toBe(false)
                    end
                    part:Destroy()
                end
            end
        end
        expect(ArenaSilhouetteAccentKit.count("Low")).toBe(2)
        expect(ArenaSilhouetteAccentKit.count("Medium")).toBe(3)
        expect(ArenaSilhouetteAccentKit.count("High")).toBe(4)
        holder:Destroy()
        base:Destroy()
    end)

    it("keeps Crossroads service beam aligned with rotated and tilted pylons", function()
        local left = Instance.new("Part")
        local right = Instance.new("Part")
        for _, frame in ipairs({
            CFrame.new(0, 12, 0),
            CFrame.new(21, 18, -9) * CFrame.Angles(0, math.rad(53), 0),
            CFrame.new(-15, 24, 36)
                * CFrame.Angles(math.rad(13), math.rad(-37), math.rad(8)),
        }) do
            left.CFrame = frame * CFrame.new(-63, 7.2, 12)
            right.CFrame = frame * CFrame.new(-63, 5.2, 18)
            local actual = ArenaSilhouetteAccentKit.crossroadsBeamFrame(left, right)
            local expected = frame * CFrame.new(-63, 10, 15)
                * CFrame.Angles(math.rad(9), 0, 0)
            expect((actual.Position - expected.Position).Magnitude < 0.001).toBe(true)
            expect(actual.LookVector:Dot(expected.LookVector) > 0.9999).toBe(true)
            expect(actual.UpVector:Dot(expected.UpVector) > 0.9999).toBe(true)
            expect(actual.RightVector:Dot(expected.RightVector) > 0.9999).toBe(true)
        end
        left:Destroy()
        right:Destroy()
    end)

    it("keeps static outboard 3D landmarks registered to a moving arena", function()
        local root = Instance.new("Folder")
        local scenery = Instance.new("Folder")
        scenery.Name = "ArenaSilhouetteBreakupLocal"
        scenery.Parent = root
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Size = Vector3.new(110, 3, 90)
        base.CFrame = CFrame.new(9, 14, 22)
        base.Parent = root

        for _, tier in ipairs({"Low", "Medium", "High"}) do
            for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
                local pieces = ArenaSilhouetteAccentKit.build(
                    scenery, base, variant, tier, VisualTheme.arena(variant)
                )
                local expectedCount = ArenaSilhouetteAccentKit.count(tier)
                expect(#pieces).toBe(expectedCount)
                local relativeFrames = {}
                for index, part in ipairs(pieces) do
                    relativeFrames[index] = base.CFrame:ToObjectSpace(part.CFrame)
                end
                local following = ArenaSilhouetteAccentKit.follow(scenery, base)
                expect(following ~= nil and following.Connected).toBe(true)
                base.CFrame = CFrame.new(41, 28, -19)
                    * CFrame.Angles(math.rad(4), math.rad(57), math.rad(-7))
                task.wait()
                expect(#scenery:GetChildren()).toBe(expectedCount)
                for index, part in ipairs(pieces) do
                    local expectedFrame = base.CFrame * relativeFrames[index]
                    expect((part.Position - expectedFrame.Position).Magnitude < 0.001)
                        .toBe(true)
                    expect(part.CFrame.LookVector:Dot(expectedFrame.LookVector) > 0.9999)
                        .toBe(true)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                end
                -- ShrinkingArena can reassign the same base CFrame during
                -- its size-only updates. The outboard pose must remain exact.
                local previousFrame = base.CFrame
                local previousPieceFrames = {}
                for index, part in ipairs(pieces) do
                    previousPieceFrames[index] = part.CFrame
                end
                base.Size = Vector3.new(78, 3, 63)
                base.CFrame = previousFrame
                task.wait()
                for index, part in ipairs(pieces) do
                    expect(part.CFrame).toBe(previousPieceFrames[index])
                end
                following:Disconnect()
                expect(following.Connected).toBe(false)
                local retained = pieces[1].CFrame
                base.CFrame = CFrame.new(-23, 20, 61)
                task.wait()
                expect(pieces[1].CFrame).toBe(retained)
                scenery:ClearAllChildren()
            end
        end
        expect(ArenaSilhouetteAccentKit.follow(scenery, base) == nil).toBe(true)
        expect(ArenaSilhouetteAccentKit.follow(nil, base) == nil).toBe(true)
        expect(ArenaSilhouetteAccentKit.follow(scenery, nil) == nil).toBe(true)
        base:Destroy()
        root:Destroy()
    end)

    it("ignores unexpected inputs without creating scenery", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaSilhouetteAccentKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Unexpected", "High", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Classic", "Unknown", theme)).toBe(0)
        expect(#ArenaSilhouetteAccentKit.build(folder, base, "Classic", "High", nil)).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)
end)


describe("Arena premium deck material finishes", function()
    it("preserves four physically distinct floor recipes in rotated arenas", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        base.Size = Vector3.new(112, 3, 92)
        base.CFrame = CFrame.new(31, 18, -16)
            * CFrame.Angles(math.rad(9), math.rad(36), math.rad(-5))
        local observedNames = {}
        local firstMaterials = {}
        for _, variant in ipairs({"Classic", "Towers", "Crossroads", "Orbital"}) do
            local names = ArenaDeckFinishKit.names(variant)
            expect(#names).toBe(6)
            expect(observedNames[names[1]] == nil).toBe(true)
            observedNames[names[1]] = true
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local generated = ArenaDeckFinishKit.build(
                    folder, base, variant, tier, VisualTheme.arena(variant))
                expect(#generated).toBe(ArenaDeckFinishKit.count(tier))
                for index, part in ipairs(generated) do
                    expect(part.Name).toBe(names[index])
                    expect(part:GetAttribute("ChaosDeckFinish")).toBe(true)
                    expect(part:GetAttribute("ArenaVariant")).toBe(variant)
                    expect(part:GetAttribute("SurfaceBaseColor")).toBe(part.Color)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Material == Enum.Material.Neon).toBe(false)
                    local localPosition = base.CFrame:PointToObjectSpace(part.Position)
                    expect(math.abs(localPosition.X) < base.Size.X * 0.5).toBe(true)
                    expect(math.abs(localPosition.Z) < base.Size.Z * 0.5).toBe(true)
                    expect(localPosition.Y > base.Size.Y * 0.5 + 0.13).toBe(true)
                    expect(part.CFrame.UpVector:Dot(base.CFrame.UpVector) > 0.98).toBe(true)
                    if index == 1 then
                        firstMaterials[variant] = part.Material
                    end
                    part:Destroy()
                end
            end
        end
        expect(firstMaterials.Classic).toBe(Enum.Material.Metal)
        expect(firstMaterials.Towers).toBe(Enum.Material.CorrodedMetal)
        expect(firstMaterials.Crossroads).toBe(Enum.Material.Concrete)
        expect(firstMaterials.Orbital).toBe(Enum.Material.Metal)
        expect(ArenaDeckFinishKit.count("Low")).toBe(2)
        expect(ArenaDeckFinishKit.count("Medium")).toBe(4)
        expect(ArenaDeckFinishKit.count("High")).toBe(6)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)

    it("rejects invalid deck inputs before allocating geometry", function()
        local folder = Instance.new("Folder")
        local base = Instance.new("Part")
        local theme = VisualTheme.arena("Classic")
        expect(#ArenaDeckFinishKit.build(nil, base, "Classic", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, nil, "Classic", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Unknown", "High", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Classic", "Unknown", theme)).toBe(0)
        expect(#ArenaDeckFinishKit.build(folder, base, "Classic", "High", nil)).toBe(0)
        expect(#folder:GetChildren()).toBe(0)
        base:Destroy()
        folder:Destroy()
    end)
end)


describe("Rotated cinematic arena scenery frames", function()
    it("keeps the environment and moving craft aligned to a tilted map", function()
        local base = Instance.new("Part")
        base.CFrame = CFrame.new(37, 14, -22)
            * CFrame.Angles(math.rad(11), math.rad(36), math.rad(-6))
        local offset = Vector3.new(67, 25, -88)
        local position = ArenaSceneryFrames.point(base, offset)
        local frame = ArenaSceneryFrames.frame(base, offset, math.rad(31))
        local localPoint = base.CFrame:PointToObjectSpace(position)
        expect((localPoint - offset).Magnitude < 0.0001).toBe(true)
        expect((frame.Position - position).Magnitude < 0.0001).toBe(true)
        expect(frame.UpVector:Dot(base.CFrame.UpVector) > 0.999).toBe(true)
        expect(frame.LookVector:Dot(base.CFrame.LookVector) < 0.99).toBe(true)
        base:Destroy()
    end)
end)


describe("Touch decor streamed-subtree readability", function()
    it("dims nested Neon and lights without compounding quality changes", function()
        local holder = Instance.new("Folder")
        local nested = Instance.new("Model")
        local glow = Instance.new("Part")
        glow.Name = "DecorativeNeon"
        glow.Material = Enum.Material.Neon
        glow.Parent = nested
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.Parent = nested
        local lamp = Instance.new("PointLight")
        lamp.Brightness = 5
        lamp.Parent = glow
        nested.Parent = holder
        local baselines = setmetatable({}, {__mode = "k"})

        -- A populated Model arrives as one streamed subtree.
        MobileReadabilityKit.applyTree(nested, "Low", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.18) < 0.0001).toBe(true)
        -- Roblox stores this property as a float; 0.07 may round slightly upward.
        expect(math.abs(edge.LocalTransparencyModifier - 0.07) < 0.0001).toBe(true)
        expect(math.abs(lamp.Brightness - 3.1) < 0.0001).toBe(true)
        MobileReadabilityKit.applyTree(nested, "High", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.08) < 0.0001).toBe(true)
        expect(math.abs(lamp.Brightness - 4) < 0.0001).toBe(true)
        MobileReadabilityKit.applyTree(nested, "Low", baselines)
        expect(math.abs(lamp.Brightness - 3.1) < 0.0001).toBe(true)

        local streamed = Instance.new("Folder")
        local newLight = Instance.new("SpotLight")
        newLight.Brightness = 10
        newLight.Parent = streamed
        streamed.Parent = nested
        MobileReadabilityKit.applyTree(streamed, "Medium", baselines)
        expect(math.abs(newLight.Brightness - 7.2) < 0.0001).toBe(true)
        expect(baselines[lamp]).toBe(5)
        expect(baselines[newLight]).toBe(10)
        holder:Destroy()
    end)
    it("does not reveal LOD-hidden Neon on mobile tier changes", function()
        local holder = Instance.new("Folder")
        local glow = Instance.new("Part")
        glow.Name = "AmbientNeon"
        glow.Material = Enum.Material.Neon
        glow.LocalTransparencyModifier = 1
        glow:SetAttribute("SceneryLodHidden", true)
        glow.Parent = holder
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.LocalTransparencyModifier = 1
        edge:SetAttribute("SceneryLodHidden", true)
        edge.Parent = holder
        local lamp = Instance.new("PointLight")
        lamp.Brightness = 5
        lamp.Enabled = false
        lamp.Parent = glow
        local baselines = setmetatable({}, {__mode = "k"})

        MobileReadabilityKit.applyTree(holder, "Low", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(lamp.Enabled).toBe(false)
        expect(math.abs(lamp.Brightness - 3.1) < 0.0001).toBe(true)

        MobileReadabilityKit.applyTree(holder, "High", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(lamp.Enabled).toBe(false)

        -- The LOD owner has now restored visibility and its own baseline.
        glow:SetAttribute("SceneryLodHidden", false)
        edge:SetAttribute("SceneryLodHidden", false)
        glow.LocalTransparencyModifier = 0
        edge.LocalTransparencyModifier = 0
        MobileReadabilityKit.applyTree(holder, "Medium", baselines)
        expect(math.abs(glow.LocalTransparencyModifier - 0.12) < 0.0001).toBe(true)
        expect(math.abs(edge.LocalTransparencyModifier - 0.054) < 0.0001).toBe(true)
        expect(lamp.Enabled).toBe(false)
        expect(math.abs(lamp.Brightness - 3.6) < 0.0001).toBe(true)
        holder:Destroy()
    end)
    it("reapplies touch tint at LOD reveal and disconnects stale observers", function()
        local folder = Instance.new("Folder")
        local glow = Instance.new("Part")
        glow.Name = "DecorativeNeon"
        glow.Material = Enum.Material.Neon
        glow.Parent = folder
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        edge.Parent = folder
        local baselines = setmetatable({}, {__mode = "k"})
        local callbacks = 0
        local function attach(part)
            return MobileReadabilityKit.watchLodReturn(part, function(revealed)
                callbacks += 1
                MobileReadabilityKit.applyInstance(revealed, "Medium", baselines)
            end)
        end
        local disconnectGlow = attach(glow)
        local disconnectEdge = attach(edge)

        -- LOD hides a part after recording its own baseline. Touch
        -- readability must never override that full invisibility.
        glow:SetAttribute("SceneryLodHidden", true)
        edge:SetAttribute("SceneryLodHidden", true)
        glow.LocalTransparencyModifier = 1
        edge.LocalTransparencyModifier = 1
        MobileReadabilityKit.applyTree(folder, "High", baselines)
        expect(glow.LocalTransparencyModifier).toBe(1)
        expect(edge.LocalTransparencyModifier).toBe(1)
        expect(callbacks).toBe(0)

        -- The LOD controller restores its modifier *before* revealing.
        glow.LocalTransparencyModifier = 0
        edge.LocalTransparencyModifier = 0
        glow:SetAttribute("SceneryLodHidden", false)
        edge:SetAttribute("SceneryLodHidden", false)
        expect(callbacks).toBe(2)
        expect(math.abs(glow.LocalTransparencyModifier - 0.12) < 0.0001)
            .toBe(true)
        expect(math.abs(edge.LocalTransparencyModifier - 0.054) < 0.0001)
            .toBe(true)
        glow:SetAttribute("SceneryLodHidden", true)
        glow.LocalTransparencyModifier = 1
        expect(callbacks).toBe(2)

        disconnectGlow:Disconnect()
        disconnectEdge:Disconnect()
        glow.LocalTransparencyModifier = 0
        glow:SetAttribute("SceneryLodHidden", false)
        expect(callbacks).toBe(2)
        expect(glow.LocalTransparencyModifier).toBe(0)
        folder:Destroy()
    end)
end)


describe("Android arena identity ornament motion", function()
    it("eases in mechanical ornaments without stealing hazard cue priority", function()
        local rules = IdentityMotionRules
        for _, phase in ipairs({"ready", "round", "result"}) do
            expect(rules.phaseEnvelope(phase, 0)).toBe(0)
            expect(rules.phaseEnvelope(phase, -1)).toBe(0)
            expect(rules.phaseEnvelope(phase, "0.3")).toBe(0)
            expect(rules.phaseEnvelope(phase, 0 / 0)).toBe(0)
            local middle = rules.phaseEnvelope(phase, 0.17)
            local full = rules.phaseEnvelope(phase, 0.34)
            expect(middle > 0).toBe(true)
            expect(middle < full).toBe(true)
            expect(math.abs(middle - full * 0.5) < 0.0001).toBe(true)
            expect(rules.phaseEnvelope(phase, 1.5)).toBe(full)
        end
        expect(rules.phaseEnvelope("round", 2)).toBe(1)
        expect(rules.phaseEnvelope("ready", 2)).toBe(0.68)
        expect(rules.phaseEnvelope("result", 2)).toBe(0.46)
        -- Active-to-active transitions ease from their actual previous pose.
        expect(rules.phaseEnvelope("round", 0, 0.68)).toBe(0.68)
        expect(math.abs(rules.phaseEnvelope("round", 0.17, 0.68) - 0.84)
            < 0.0001).toBe(true)
        expect(rules.phaseEnvelope("round", 0.34, 0.68)).toBe(1)
        expect(rules.phaseEnvelope("result", 0, 1)).toBe(1)
        expect(math.abs(rules.phaseEnvelope("result", 0.17, 1) - 0.73)
            < 0.0001).toBe(true)
        expect(math.abs(rules.phaseEnvelope("result", 0.34, 1) - 0.46)
            < 0.0001).toBe(true)
        -- Early interruptions retain the previous fractional strength.
        expect(rules.phaseEnvelope("round", 0, 0.27)).toBe(0.27)
        expect(rules.phaseEnvelope("round", 0.34, 0.27)).toBe(1)
        expect(rules.phaseEnvelope("waiting", 0, 1)).toBe(0)
        for _, phase in ipairs({"waiting", "unknown", "vote", ""}) do
            expect(rules.phaseEnvelope(phase, 10)).toBe(0)
        end
        -- Reduced motion and tier budgets still gate the whole presentation.
        expect(rules.motionScale("High", true)
            * rules.phaseEnvelope("round", 1)).toBe(0)
        expect(rules.motionScale("Low", false)
            * rules.phaseEnvelope("round", 1)).toBe(0.38)
    end)

    it("eases Final Rush visual focus without altering accessibility gates", function()
        local rules = IdentityMotionRules
        expect(rules.focusTarget("round", true)).toBe(0.38)
        expect(rules.focusTarget("round", false)).toBe(1)
        expect(rules.focusTarget("ready", true)).toBe(1)
        expect(rules.focusTarget("result", true)).toBe(1)
        expect(rules.focusTarget("waiting", true)).toBe(1)
        expect(rules.focusTarget("round", nil)).toBe(1)

        expect(rules.focusEnvelope(1, 0.38, 0)).toBe(1)
        expect(math.abs(rules.focusEnvelope(1, 0.38, 0.225) - 0.69)
            < 0.0001).toBe(true)
        expect(rules.focusEnvelope(1, 0.38, 0.45)).toBe(0.38)
        expect(rules.focusEnvelope(1, 0.38, 1)).toBe(0.38)
        expect(rules.focusEnvelope(0.38, 1, 0)).toBe(0.38)
        expect(math.abs(rules.focusEnvelope(0.38, 1, 0.225) - 0.69)
            < 0.0001).toBe(true)
        expect(rules.focusEnvelope(0.38, 1, 0.45)).toBe(1)

        local mid = rules.focusEnvelope(1, 0.38, 0.225)
        expect(rules.focusEnvelope(mid, 1, 0)).toBe(mid)
        expect(rules.focusEnvelope(mid, 1, 0.45)).toBe(1)
        expect(rules.focusEnvelope(1, 0.38, -1)).toBe(1)
        expect(rules.focusEnvelope(1, 0.38, 0/0)).toBe(1)
        expect(rules.focusEnvelope(math.huge, 0.38, 0)).toBe(1)
        expect(rules.focusEnvelope(1, math.huge, 0.45)).toBe(1)

        local low = rules.motionScale("Low", false)
            * rules.phaseEnvelope("round", 1)
            * rules.focusEnvelope(1, rules.focusTarget("round", true), 1)
        expect(math.abs(low - 0.1444) < 0.0001).toBe(true)
        expect(rules.motionScale("High", true)
            * rules.focusEnvelope(1, 0.38, 1)).toBe(0)
    end)

    it("restores LOD-hidden identity decor and eases streamed motion from rest", function()
        local rules = IdentityMotionRules
        expect(rules.resumeEnvelope(0)).toBe(0)
        expect(rules.resumeEnvelope(-1)).toBe(0)
        expect(rules.resumeEnvelope("0.24")).toBe(0)
        expect(rules.resumeEnvelope(0/0)).toBe(0)
        expect(rules.resumeEnvelope(math.huge)).toBe(0)
        expect(rules.resumeEnvelope(-math.huge)).toBe(0)
        expect(math.abs(rules.resumeEnvelope(0.24) - 0.5) < 0.0001)
            .toBe(true)
        expect(rules.resumeEnvelope(0.48)).toBe(1)
        expect(rules.resumeEnvelope(2)).toBe(1)
        expect(math.abs(rules.motionScale("Low", false)
            * rules.resumeEnvelope(0.24) - 0.19) < 0.0001).toBe(true)
        expect(rules.motionScale("High", true)
            * rules.resumeEnvelope(2)).toBe(0)

        local holder = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = holder
        local baseline = {
            baseCFrame = CFrame.new(7, 9, -2)
                * CFrame.Angles(0, math.rad(30), 0),
            baseColor = Color3.fromRGB(42, 170, 235),
            baseTransparency = 0.31,
        }
        part.CFrame = baseline.baseCFrame * CFrame.new(0, 1.2, 0)
        part.Color = Color3.new(1, 1, 1)
        part.Transparency = 0.65
        part.LocalTransparencyModifier = 0.42
        part:SetAttribute("SceneryLodHidden", true)
        expect(rules.shouldUpdate(part)).toBe(false)
        expect(rules.restorePose(part, baseline)).toBe(true)
        expect((part.CFrame.Position - baseline.baseCFrame.Position).Magnitude
            < 0.0001).toBe(true)
        expect(part.CFrame.RightVector:Dot(baseline.baseCFrame.RightVector)
            > 0.99999).toBe(true)
        expect(part.Color).toBe(baseline.baseColor)
        expect(math.abs(part.Transparency - baseline.baseTransparency) < 1e-5)
            .toBe(true)
        -- Scenery LOD alone owns the local visibility modifier.
        expect(math.abs(part.LocalTransparencyModifier - 0.42) < 1e-5)
            .toBe(true)
        expect(part:GetAttribute("SceneryLodHidden")).toBe(true)

        part:SetAttribute("SceneryLodHidden", false)
        expect(rules.shouldUpdate(part)).toBe(true)
        expect(rules.restorePose(part, {})).toBe(false)
        part.Parent = nil
        expect(rules.restorePose(part, baseline)).toBe(false)
        part:Destroy()
        holder:Destroy()
    end)

    it("keeps authored tier scales and fully disables continuous ReduceMotion", function()
        expect(IdentityMotionRules.motionScale("Low", false)).toBe(0.38)
        expect(IdentityMotionRules.motionScale("Medium", false)).toBe(0.68)
        expect(IdentityMotionRules.motionScale("High", false)).toBe(1)
        expect(IdentityMotionRules.motionScale("Unknown", false)).toBe(0.38)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            expect(IdentityMotionRules.motionScale(tier, true)).toBe(0)
            expect(IdentityMotionRules.interval(tier, true, true, true)).toBe(0.60)
        end
    end)

    it("sleeps when inactive or no identity pieces have replicated", function()
        expect(IdentityMotionRules.interval("Low", false, true, true)).toBe(0.16)
        expect(IdentityMotionRules.interval("Medium", false, true, true)).toBe(0.09)
        expect(IdentityMotionRules.interval("High", false, true, true)).toBe(0.09)
        expect(IdentityMotionRules.interval("High", false, false, true)).toBe(0.60)
        expect(IdentityMotionRules.interval("High", false, true, false)).toBe(0.60)
    end)

    it("does not write to far-away or removed decor", function()
        local root = Instance.new("Folder")
        local part = Instance.new("Part")
        part.Parent = root
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(true)
        part:SetAttribute("SceneryLodHidden", true)
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(false)
        part:SetAttribute("SceneryLodHidden", false)
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(true)
        part.Parent = nil
        expect(IdentityMotionRules.shouldUpdate(part)).toBe(false)
        expect(IdentityMotionRules.shouldUpdate(nil)).toBe(false)
        part:Destroy()
        root:Destroy()
    end)

    it("uses eight distinct bounded 3D micro-motions with stable original frames", function()
        local cases = {
            {"Classic", "GridMarkerGlow1"},
            {"Classic", "ClassicBroadcastGlow1"},
            {"Towers", "TowerBand1_1"},
            {"Towers", "TowerMachineryCap1"},
            {"Towers", "TowerAntenna1"},
            {"Crossroads", "CrossroadGate1"},
            {"Crossroads", "CrossroadSignal1"},
            {"Orbital", "OrbitalReactorNode1"},
        }
        local base = CFrame.new(19, 8, -7)
            * CFrame.Angles(math.rad(7), math.rad(45), math.rad(-5))
        for _, entry in ipairs(cases) do
            local variant, name = entry[1], entry[2]
            local high = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 1
            )
            local low = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 0.38
            )
            expect(high ~= nil).toBe(true)
            expect(low ~= nil).toBe(true)
            local function distanceFromRest(cf)
                return cf.Position.Magnitude
                    + (cf.RightVector - Vector3.new(1, 0, 0)).Magnitude
                    + (cf.UpVector - Vector3.new(0, 1, 0)).Magnitude
            end
            expect(distanceFromRest(high) > distanceFromRest(low)).toBe(true)
            expect(high.Position.Magnitude <= 0.181).toBe(true)
            expect(low.Position.Magnitude <= high.Position.Magnitude + 0.0001)
                .toBe(true)
            local localPose = base:ToObjectSpace(base * high)
            expect((localPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect((localPose.UpVector - high.UpVector).Magnitude < 0.0001)
                .toBe(true)
            -- No accumulation: evaluating the same time always yields the
            -- same local transform, independent of the prior animation frame.
            local repeatPose = IdentityMotionRules.ornamentOffset(
                variant, name, 1.37, 1, 1)
            expect((repeatPose.Position - high.Position).Magnitude < 0.0001)
                .toBe(true)
            expect(repeatPose.RightVector:Dot(high.RightVector) > 0.99999)
                .toBe(true)
            -- A long but realistic session remains a valid finite pose.
            expect(IdentityMotionRules.ornamentOffset(
                variant, name, 4097.37, 1, 1) ~= nil).toBe(true)
        end
        expect(IdentityMotionRules.ornamentOffset(
            "Towers", "TowerBand1_1", 1, 1, 1) ~= nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Orbital", "OrbitalCrown1", 1, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "RoundMeteor", 1, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 1, 0) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", math.huge, 1, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 10000001, 1, 1) == nil).toBe(true)
        for _, bad in ipairs({math.huge, -math.huge, 0/0}) do
            expect(IdentityMotionRules.ornamentOffset(
                "Classic", "GridMarkerGlow1", 1, bad, 1) == nil).toBe(true)
            expect(IdentityMotionRules.ornamentOffset(
                "Classic", "GridMarkerGlow1", 1, 1, bad) == nil).toBe(true)
        end
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 65, 1) == nil).toBe(true)
        expect(IdentityMotionRules.ornamentOffset(
            "Classic", "GridMarkerGlow1", 1, 1.5, 1) == nil).toBe(true)
    end)

    it("watches only the named direct-decor ornaments in each arena", function()
        local valid = {
            Classic = {"GridMarkerGlow1", "ClassicBroadcastGlow4"},
            Towers = {"TowerBand4_3", "TowerMachineryCap2", "TowerAntenna1"},
            Crossroads = {"CrossroadGate3", "CrossroadSignal4"},
            Orbital = {"OrbitalCrown1", "OrbitalCrown12", "OrbitalReactorNode8"},
        }
        for variant, names in pairs(valid) do
            for _, name in ipairs(names) do
                expect(IdentityMotionRules.isIdentityPart(variant, name)).toBe(true)
            end
        end
        for _, invalid in ipairs({
            {"Classic", "GridMarkerGlow5"},
            {"Towers", "TowerBand5_1"},
            {"Towers", "TowerBand3_4"},
            {"Crossroads", "CrossroadSignal8"},
            {"Orbital", "OrbitalCrown13"},
            {"Orbital", "OrbitalReactorNode0"},
            {"Orbital", "RoundMeteor"},
            {"Unknown", "OrbitalCrown1"},
        }) do
            expect(IdentityMotionRules.isIdentityPart(invalid[1], invalid[2]))
                .toBe(false)
        end
        expect(IdentityMotionRules.isIdentityPart("Orbital", nil)).toBe(false)
    end)
    it("recovers late Arena/Decor, variant swaps and streamed identity parts", function()
        local generated = Instance.new("Folder")
        local count = 0
        local observedArena, observedDecor, observedVariant = nil, nil, nil
        local disconnect = IdentityMotionReadiness.watch(generated, function(arena, decor, variant)
            count += 1
            observedArena, observedDecor, observedVariant = arena, decor, variant
        end, IdentityMotionRules.isIdentityPart)
        expect(count).toBe(1)
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = generated
        expect(observedArena).toBe(arena)
        expect(observedDecor == nil).toBe(true)
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        expect(observedDecor).toBe(decor)
        expect(observedVariant).toBe("Classic")

        local beforeUnrelated = count
        local unrelated = Instance.new("Part")
        unrelated.Name = "RoundMeteor"
        unrelated.Parent = decor
        expect(count).toBe(beforeUnrelated)
        local identity = Instance.new("Part")
        identity.Name = "GridMarkerGlow1"
        identity.Parent = decor
        expect(count).toBe(beforeUnrelated + 1)
        identity.Parent = nil
        expect(count).toBe(beforeUnrelated + 2)

        arena:SetAttribute("VariantId", "Orbital")
        expect(observedVariant).toBe("Orbital")
        local crown = Instance.new("Part")
        crown.Name = "OrbitalCrown12"
        crown.Parent = decor
        local afterCrown = count
        expect(afterCrown > beforeUnrelated + 2).toBe(true)

        decor.Parent = nil
        expect(observedDecor == nil).toBe(true)
        local afterDetach = count
        local stale = Instance.new("Part")
        stale.Name = "OrbitalReactorNode1"
        stale.Parent = decor
        expect(count).toBe(afterDetach)

        local freshDecor = Instance.new("Folder")
        freshDecor.Name = "Decor"
        freshDecor.Parent = arena
        expect(observedDecor).toBe(freshDecor)
        local freshNode = Instance.new("Part")
        freshNode.Name = "OrbitalReactorNode8"
        freshNode.Parent = freshDecor
        expect(count > afterDetach + 1).toBe(true)

        arena.Parent = nil
        expect(observedArena == nil).toBe(true)
        local afterArenaGone = count
        local orphan = Instance.new("Part")
        orphan.Name = "OrbitalCrown1"
        orphan.Parent = freshDecor
        expect(count).toBe(afterArenaGone)

        local replacement = Instance.new("Folder")
        replacement.Name = "Arena"
        replacement:SetAttribute("VariantId", "Towers")
        replacement.Parent = generated
        expect(observedArena).toBe(replacement)
        expect(observedVariant).toBe("Towers")
        disconnect()
        local afterDisconnect = count
        local replacementDecor = Instance.new("Folder")
        replacementDecor.Name = "Decor"
        replacementDecor.Parent = replacement
        expect(count).toBe(afterDisconnect)
        generated:Destroy()
        arena:Destroy()
        decor:Destroy()
        identity:Destroy()
    end)

end)

return nil
