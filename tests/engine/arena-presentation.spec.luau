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

return nil
