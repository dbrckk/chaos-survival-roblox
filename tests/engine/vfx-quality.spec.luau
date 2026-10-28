--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VfxQuality = require("../../src/shared/VfxQuality")
local PerformancePulseRules = require("../../src/shared/PerformancePulseRules")
local DisasterCosmeticRules = require("../../src/shared/DisasterCosmeticRules")
local MobileReadabilityKit = require("../../src/client/MobileReadabilityKit")
local CameraOcclusionRules = require("../../src/shared/CameraOcclusionRules")
local SceneryLodRules = require("../../src/shared/SceneryLodRules")
local PbrDistrictRules = require("../../src/shared/PbrDistrictRules")
local DistrictKineticKit = require("../../src/client/DistrictKineticKit")

describe("Adaptive VFX quality", function()
    it("bounds Android FPS/memory telemetry before analytics or formatting", function()
        local sanitize = PerformancePulseRules.sanitize
        local source = {
            averageFps = 56.75,
            vfxTier = "Medium",
            deviceClass = "Touch",
            tierTransitions = 5.99,
            visualParts = 312.99,
            visualLights = 18,
            visualEffects = 30,
            totalMemoryMb = 888.25,
            instanceCount = 2300.8,
            frameTimeMs = 18.42,
            renderCpuMs = 8.75,
            renderGpuMs = 12.5,
        }
        local sample = sanitize(source)
        expect(sample.averageFps).toBe(56.75)
        expect(sample.deviceClass).toBe("Touch")
        expect(sample.vfxTier).toBe("Medium")
        expect(sample.tierTransitions).toBe(5)
        expect(sample.visualParts).toBe(312)
        expect(sample.instanceCount).toBe(2300)
        expect(sample.totalMemoryMb).toBe(888.25)
        expect(sample.renderGpuMs).toBe(12.5)

        local invalid = sanitize({
            averageFps = 0 / 0, tierTransitions = math.huge,
            visualParts = -math.huge, visualLights = -9.7,
            visualEffects = 1e8, totalMemoryMb = 0 / 0,
            instanceCount = math.huge, frameTimeMs = -math.huge,
            renderCpuMs = math.huge, renderGpuMs = 0 / 0,
            vfxTier = "Ultra", deviceClass = "iPhone;arbitrary value",
        })
        expect(invalid.averageFps).toBe(0)
        expect(invalid.tierTransitions).toBe(0)
        expect(invalid.visualParts).toBe(0)
        expect(invalid.visualLights).toBe(0)
        expect(invalid.visualEffects).toBe(2000)
        expect(invalid.totalMemoryMb).toBe(0)
        expect(invalid.instanceCount).toBe(0)
        expect(invalid.frameTimeMs).toBe(0)
        expect(invalid.renderCpuMs).toBe(0)
        expect(invalid.renderGpuMs).toBe(0)
        expect(invalid.vfxTier).toBe("Unknown")
        expect(invalid.deviceClass).toBe("Unknown")

        local empty = sanitize(nil)
        expect(empty.averageFps).toBe(0)
        expect(empty.totalMemoryMb).toBe(0)
        expect(empty.deviceClass).toBe("Unknown")

        local capped = sanitize({
            averageFps = 999, tierTransitions = 200,
            instanceCount = 1e10, frameTimeMs = 1200,
            renderGpuMs = 1800, vfxTier = "High", deviceClass = "Desktop",
        })
        expect(capped.averageFps).toBe(240)
        expect(capped.tierTransitions).toBe(99)
        expect(capped.instanceCount).toBe(250000)
        expect(capped.frameTimeMs).toBe(1000)
        expect(capped.renderGpuMs).toBe(1000)
        expect(capped.deviceClass).toBe("Desktop")
    end)

    it("filters Android structural sightlines to arena geometry, not other avatars", function()
        expect(CameraOcclusionRules.arenaRaycastParams(nil)).toBe(nil)

        local arena = Instance.new("Folder")
        arena.Name = "CameraSightlineArenaTest"
        arena.Parent = workspace
        local support = Instance.new("Part")
        support.Name = "SupportColumn"
        support.Anchored = true
        support.Size = Vector3.new(4, 5, 1)
        support.Position = Vector3.new(4567, 500, 6424)
        support.Parent = arena

        -- A large structural floor in front of a pillar should not swallow
        -- the raycast either; the old controller excluded Arena.Base.
        local base = Instance.new("Part")
        base.Name = "Base"
        base.Anchored = true
        base.Size = Vector3.new(4, 5, 1)
        base.Position = Vector3.new(4567, 500, 6430)
        base.Parent = arena

        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local ornament = Instance.new("Part")
        ornament.Name = "ForegroundOrnament"
        ornament.Anchored = true
        ornament.Size = Vector3.new(4, 5, 1)
        ornament.Position = Vector3.new(4567, 500, 6429)
        ornament.Parent = decor

        -- Walkable routes are intentionally not faded; their colliders
        -- must not prevent a real structural support from being found.
        local platforms = Instance.new("Folder")
        platforms.Name = "Platforms"
        platforms.Parent = arena
        local route = Instance.new("Part")
        route.Name = "RegularJumpRoute"
        route.Anchored = true
        route.Size = Vector3.new(4, 5, 1)
        route.Position = Vector3.new(4567, 500, 6427)
        route.Parent = platforms
        local bridge = Instance.new("Part")
        bridge.Name = "Skybridge"
        bridge:SetAttribute("ChaosSkybridge", true)
        bridge.Anchored = true
        bridge.Size = Vector3.new(4, 5, 1)
        bridge.Position = Vector3.new(4567, 500, 6418)
        bridge.Parent = platforms

        -- Moving hazard mechanics also must not steal the first hit.
        for _, folderName in ipairs({"Mechanics", "Spawns", "EntryGuides"}) do
            local folder = Instance.new("Folder")
            folder.Name = folderName
            folder.Parent = arena
            local blocker = Instance.new("Part")
            blocker.Name = "Foreground" .. folderName
            blocker.Anchored = true
            blocker.Size = Vector3.new(4, 5, 1)
            blocker.Position = Vector3.new(4567, 500, 6428)
            blocker.Parent = folder
        end

        -- Orbital ramps are traversable structural Parts but must never
        -- become locally transparent or steal the support-column hit.
        local helixCircuit = Instance.new("Folder")
        helixCircuit.Name = "HelixCircuit"
        helixCircuit.Parent = arena
        for _, routeName in ipairs({"HelixRamp1", "EntryRamp1", "CoreRamp1"}) do
            local ramp = Instance.new("Part")
            ramp.Name = routeName
            ramp.Anchored = true
            ramp.CanCollide = true
            ramp.Size = Vector3.new(4, 5, 1)
            ramp.Position = Vector3.new(4567, 500, 6427)
            ramp.Parent = helixCircuit
        end

        local otherAvatar = Instance.new("Part")
        otherAvatar.Name = "RemoteAvatarOccluder"
        otherAvatar.Anchored = true
        otherAvatar.Size = Vector3.new(4, 5, 1)
        otherAvatar.Position = Vector3.new(4567, 500, 6428)
        otherAvatar.Parent = workspace

        local params = CameraOcclusionRules.arenaRaycastParams(arena, base)
        expect(params.FilterType).toBe(Enum.RaycastFilterType.Include)
        expect(params.IgnoreWater).toBe(true)
        expect(#params.FilterDescendantsInstances).toBe(2)
        expect(params.FilterDescendantsInstances[1]).toBe(support)
        expect(params.FilterDescendantsInstances[2]).toBe(bridge)
        -- Scenery and actual jumping routes must never steal the hit
        -- from the opaque arena support behind them.
        expect(params.FilterDescendantsInstances[1] ~= decor).toBe(true)
        expect(params.FilterDescendantsInstances[1] ~= route).toBe(true)
        for _, candidate in ipairs(params.FilterDescendantsInstances) do
            expect(candidate ~= helixCircuit).toBe(true)
        end
        local hit = workspace:Raycast(
            Vector3.new(4567, 500, 6432), Vector3.new(0, 0, -12), params
        )
        expect(hit ~= nil and hit.Instance == support).toBe(true)

        otherAvatar:Destroy()
        arena:Destroy()
    end)

    it("distinguishes server-mounted original 3D from client streamed models", function()
        local count, received, complete = SceneryLodRules.original3DAudit(nil)
        expect(count).toBe(nil)
        expect(received).toBe(nil)
        expect(complete).toBe(false)

        local arena = Instance.new("Folder")
        arena.Name = "Original3DDiagnosticsTest"
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        local folder = Instance.new("Folder")
        folder.Name = "Original3DScenery"
        folder.Parent = decor

        count, received, complete = SceneryLodRules.original3DAudit(arena)
        expect(count).toBe(nil) -- No server mount receipt yet.
        expect(received).toBe(0)
        expect(complete).toBe(false)

        arena:SetAttribute("Original3DSceneryCount", 8)
        arena:SetAttribute("Original3DSceneryComplete", true)
        local good = Instance.new("Model")
        good.Name = "ApprovedModel"
        good:SetAttribute("CosmeticOnly", true)
        good:SetAttribute("Original3DAssetId", 102992487644269)
        good.Parent = folder
        -- A streamed model shell must not be counted as received geometry.
        count, received, complete = SceneryLodRules.original3DAudit(arena)
        expect(count).toBe(8)
        expect(received).toBe(0)
        expect(complete).toBe(true)

        local part = Instance.new("Part")
        part.Name = "MeshGeometry"
        part.Parent = good
        local unapproved = Instance.new("Model")
        unapproved.Name = "NonOriginalProp"
        unapproved.Parent = folder
        local fake = Instance.new("Part")
        fake.Parent = unapproved
        count, received, complete = SceneryLodRules.original3DAudit(arena)
        expect(count).toBe(8)
        expect(received).toBe(1) -- Only the authenticated cosmetic package.
        expect(complete).toBe(true)

        arena:SetAttribute("Original3DSceneryCount", math.huge)
        count, received, complete = SceneryLodRules.original3DAudit(arena)
        expect(count).toBe(nil) -- Reject untrusted/malformed telemetry.
        expect(received).toBe(1)
        arena:Destroy()
    end)

    it("protects essential mobile route outlines while dimming ornamental neon", function()
        local kit = MobileReadabilityKit
        local ornament = Instance.new("Part")
        ornament.Name = "NeonDecoration"
        ornament.Material = Enum.Material.Neon
        local edge = Instance.new("Part")
        edge.Name = "PlatformGlow12"
        edge.Material = Enum.Material.Neon
        local baseline = setmetatable({}, {__mode = "k"})

        for _, tier in ipairs({"High", "Medium", "Low"}) do
            kit.applyInstance(ornament, tier, baseline)
            kit.applyInstance(edge, tier, baseline)
            local ornamentOpacity = ornament.LocalTransparencyModifier
            local edgeOpacity = edge.LocalTransparencyModifier
            expect(ornamentOpacity > edgeOpacity).toBe(true)
            expect(edgeOpacity <= 0.071).toBe(true)
        end
        local low, lowLight = kit.profile("Low")
        local med, medLight = kit.profile("Medium")
        local high, highLight = kit.profile("High")
        expect(low > med and med > high).toBe(true)
        expect(lowLight < medLight and medLight < highLight).toBe(true)
        ornament:Destroy()
        edge:Destroy()
    end)

    it("starts touch devices conservatively without capping capable hardware", function()
        expect(VfxQuality.initialTier(true)).toBe("Medium")
        expect(VfxQuality.initialTier(false)).toBe("High")
        expect(VfxQuality.nextTier(VfxQuality.initialTier(true), 60)).toBe("High")
    end)

    it("excludes Android app-resume gaps without hiding truly slow rendered frames", function()
        local sample = VfxQuality.activeFrameSeconds
        expect(sample(1 / 60)).toBe(1 / 60)
        expect(sample(0.08)).toBe(0.08)
        expect(sample(0.45)).toBe(0.45)
        expect(sample(0.60)).toBe(0.60)
        expect(sample(0.61)).toBe(0)
        expect(sample(2.8)).toBe(0)
        expect(sample(nil)).toBe(0)
        expect(sample(0)).toBe(0)
        expect(sample(-0.1)).toBe(0)
        expect(sample(math.huge)).toBe(0)
        expect(sample(-math.huge)).toBe(0)
        expect(sample(0 / 0)).toBe(0)
    end)

    it("degrades progressively under sustained low frame rate", function()
        expect(VfxQuality.nextTier("High", 60)).toBe("High")
        expect(VfxQuality.nextTier("High", 40)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 30)).toBe("Low")
    end)

    it("uses hysteresis when recovering performance", function()
        expect(VfxQuality.nextTier("Low", 40)).toBe("Low")
        expect(VfxQuality.nextTier("Low", 45)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 50)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 55)).toBe("High")
    end)

    it("protects Android touch performance without changing desktop thresholds", function()
        expect(VfxQuality.nextTier("High", 47, true)).toBe("Medium")
        expect(VfxQuality.nextTier("High", 47, false)).toBe("High")
        expect(VfxQuality.nextTier("High", 48, true)).toBe("High")
        expect(VfxQuality.nextTier("Medium", 55, true)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 55, false)).toBe("High")
        expect(VfxQuality.nextTier("Medium", 58, true)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 60, true)).toBe("High")
        expect(VfxQuality.nextTier("Medium", 30, true)).toBe("Low")
        expect(VfxQuality.nextTier("Low", 45, true)).toBe("Low")
        expect(VfxQuality.nextTier("Low", 45, false)).toBe("Medium")
        expect(VfxQuality.nextTier("Low", 47, true)).toBe("Medium")
    end)

    it("requires stable samples for promotions but not downgrades", function()
        expect(VfxQuality.requiredStableSamples("High", "Medium", false)).toBe(1)
        expect(VfxQuality.requiredStableSamples("Medium", "Low", true)).toBe(1)
        expect(VfxQuality.requiredStableSamples("Low", "Medium", false)).toBe(2)
        expect(VfxQuality.requiredStableSamples("Medium", "High", false)).toBe(2)
        expect(VfxQuality.requiredStableSamples("Low", "Medium", true)).toBe(3)
        expect(VfxQuality.requiredStableSamples("Medium", "High", true)).toBe(3)
        expect(VfxQuality.requiredStableSamples("Medium", "Medium", true)).toBe(0)
    end)

    it("scales particle budgets predictably", function()
        expect(VfxQuality.particleCount("High", 20, 4)).toBe(20)
        expect(VfxQuality.particleCount("Medium", 20, 4)).toBe(14)
        expect(VfxQuality.particleCount("Low", 20, 4)).toBe(9)
        expect(VfxQuality.particleCount("Low", 2, 4)).toBe(4)
    end)

    it("runs decorative motion below gameplay VFX frequency", function()
        local high = VfxQuality.get("High")
        local medium = VfxQuality.get("Medium")
        local low = VfxQuality.get("Low")

        expect(high.DecorUpdateInterval >= (1 / 30)).toBe(true)
        expect(medium.DecorUpdateInterval >= (1 / 24)).toBe(true)
        expect(low.DecorUpdateInterval >= (1 / 15)).toBe(true)

        expect(high.DecorUpdateInterval > high.UpdateInterval).toBe(true)
        expect(medium.DecorUpdateInterval > medium.UpdateInterval).toBe(true)
        expect(low.DecorUpdateInterval > low.UpdateInterval).toBe(true)

        expect(high.DecorUpdateInterval < medium.DecorUpdateInterval).toBe(true)
        expect(medium.DecorUpdateInterval < low.DecorUpdateInterval).toBe(true)
    end)

    it("throttles optional disaster decoration on mobile and ReduceMotion", function()
        local q = VfxQuality
        expect(q.decorativeInterval("High", false)).toBe(1 / 30)
        expect(q.decorativeInterval("Medium", false)).toBe(1 / 24)
        expect(q.decorativeInterval("Low", false)).toBe(1 / 15)
        expect(q.decorativeInterval("High", true)).toBe(1 / 12)
        expect(q.decorativeInterval("Medium", true)).toBe(1 / 12)
        expect(q.decorativeInterval("Low", true)).toBe(1 / 12)
        expect(q.decorativeInterval("Unknown", false)).toBe(1 / 30)
        for _, name in ipairs({"Low", "Medium", "High"}) do
            expect(q.decorativeInterval(name, false)
                >= q.get(name).UpdateInterval).toBe(true)
            expect(q.decorativeInterval(name, true)
                >= q.decorativeInterval(name, false)).toBe(true)
        end
    end)

    it("reuses intact lava decoration but repairs missing cosmetic children", function()
        local rules = DisasterCosmeticRules
        local root = Instance.new("Folder")
        local lava = Instance.new("Part")
        lava.Parent = root
        local surface = Instance.new("Part")
        surface.Parent = root
        local attachment = Instance.new("Attachment")
        attachment.Parent = lava
        local embers = Instance.new("ParticleEmitter")
        embers.Parent = attachment
        local light = Instance.new("SurfaceLight")
        light.Parent = lava
        local state = {lava = lava, surface = surface, attachment = attachment,
            embers = embers, light = light}
        expect(rules.reusableLava(state, lava)).toBe(true)
        local otherLava = Instance.new("Part")
        expect(rules.reusableLava(state, otherLava)).toBe(false)
        expect(rules.reusableLava(nil, lava)).toBe(false)
        expect(rules.reusableLava(state, nil)).toBe(false)
        embers:Destroy()
        expect(rules.reusableLava(state, lava)).toBe(false)
        local replacement = Instance.new("ParticleEmitter")
        replacement.Parent = attachment
        state.embers = replacement
        expect(rules.reusableLava(state, lava)).toBe(true)
        surface:Destroy()
        expect(rules.reusableLava(state, lava)).toBe(false)
        local replacement = Instance.new("Part")
        replacement.Parent = root
        state.surface = replacement
        expect(rules.reusableLava(state, lava)).toBe(true)
        attachment.Parent = nil
        expect(rules.reusableLava(state, lava)).toBe(false)
        attachment.Parent = lava
        expect(rules.reusableLava(state, lava)).toBe(true)
        light.Parent = root
        expect(rules.reusableLava(state, lava)).toBe(false)
        otherLava:Destroy()
        root:Destroy()
    end)

    it("detects disconnected freeze mist or missing crystal geometry", function()
        local root = Instance.new("Folder")
        local warning = Instance.new("Part")
        warning.Parent = root
        local attachment = Instance.new("Attachment")
        attachment.Parent = warning
        local mist = Instance.new("ParticleEmitter")
        mist.Parent = attachment
        local crystal = Instance.new("WedgePart")
        crystal.Parent = root
        local state = {warning = warning, attachment = attachment,
            mist = mist, segments = {crystal}}
        local healthy = DisasterCosmeticRules.reusableFreeze
        expect(healthy(state, warning)).toBe(true)
        expect(healthy(state, nil)).toBe(false)
        attachment.Parent = nil
        expect(healthy(state, warning)).toBe(false)
        attachment.Parent = warning
        expect(healthy(state, warning)).toBe(true)
        mist.Parent = nil
        expect(healthy(state, warning)).toBe(false)
        mist.Parent = attachment
        crystal:Destroy()
        expect(healthy(state, warning)).toBe(false)
        root:Destroy()
    end)
    it("scales cosmetic lava and freeze particles from first render", function()
        local rules = DisasterCosmeticRules
        expect(rules.lavaEmberRate(1, false)).toBe(10)
        expect(math.abs(rules.lavaEmberRate(0.72, false) - 7.2) < 0.001).toBe(true)
        expect(math.abs(rules.lavaEmberRate(0.45, true) - 1.575) < 0.001).toBe(true)
        expect(rules.lavaEmberRate(nil, false)).toBe(0)
        expect(rules.freezeMistRate(1, false)).toBe(8)
        expect(math.abs(rules.freezeMistRate(0.72, false) - 5.76) < 0.001).toBe(true)
        expect(rules.freezeMistRate(1, true)).toBe(0)
        expect(rules.freezeMistRate(nil, false)).toBe(0)
    end)

    it("keeps tornado visuals idle outside the storm and budgeted on Android", function()
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            expect(VfxQuality.tornadoInterval(tier, false, false)).toBe(0.40)
            expect(VfxQuality.tornadoInterval(tier, true, false)).toBe(0.40)
            expect(VfxQuality.tornadoInterval(tier, false, nil)).toBe(0.40)
            expect(VfxQuality.tornadoInterval(tier, false, true))
                .toBe(VfxQuality.decorativeInterval(tier, false))
            expect(VfxQuality.tornadoInterval(tier, true, true))
                .toBe(VfxQuality.decorativeInterval(tier, true))
            expect(VfxQuality.tornadoInterval(tier, true, true)
                >= 1 / 12).toBe(true)
        end
        expect(math.abs(VfxQuality.tornadoInterval("High", false, true)
            - 1 / 30) < 0.0001).toBe(true)
        expect(math.abs(VfxQuality.tornadoInterval("Medium", false, true)
            - 1 / 24) < 0.0001).toBe(true)
        expect(math.abs(VfxQuality.tornadoInterval("Low", false, true)
            - 1 / 15) < 0.0001).toBe(true)
    end)

    it("exposes bounded quality scales", function()
        for _, tierName in ipairs({"High", "Medium", "Low"}) do
            local tier = VfxQuality.get(tierName)
            expect(tier.Scale > 0).toBe(true)
            expect(tier.Scale <= 1).toBe(true)
            expect(tier.ParticleScale > 0).toBe(true)
            expect(tier.ParticleScale <= 1).toBe(true)
            expect(tier.UpdateInterval > 0).toBe(true)
        end

        expect(VfxQuality.get("Low").UpdateInterval > VfxQuality.get("High").UpdateInterval).toBe(true)
    end)
    it("preserves mobile hazard-edge neon and avoids compounding light dimming", function()
        local kit = MobileReadabilityKit
        local baseline = setmetatable({}, {__mode = "k"})
        local edge = Instance.new("Part")
        edge.Name = "EdgeSafetyGlow"
        edge.Material = Enum.Material.Neon
        local decor = Instance.new("Part")
        decor.Name = "DecorationStrip"
        decor.Material = Enum.Material.Neon
        local light = Instance.new("PointLight")
        light.Brightness = 2

        kit.applyInstance(edge, "Low", baseline)
        kit.applyInstance(decor, "Low", baseline)
        kit.applyInstance(light, "Low", baseline)
        expect(math.abs(edge.LocalTransparencyModifier - 0.07) < 0.001).toBe(true)
        expect(math.abs(decor.LocalTransparencyModifier - 0.28) < 0.001).toBe(true)
        expect(math.abs(light.Brightness - 1.16) < 0.001).toBe(true)
        kit.applyInstance(light, "Medium", baseline)
        expect(math.abs(light.Brightness - 1.32) < 0.001).toBe(true)
        kit.applyInstance(light, "High", baseline)
        expect(math.abs(light.Brightness - 1.48) < 0.001).toBe(true)
        kit.applyInstance(light, "Low", baseline)
        expect(math.abs(light.Brightness - 1.16) < 0.001).toBe(true)
        expect(baseline[light]).toBe(2)
        expect(kit.isGameplayEdge(edge)).toBe(true)
        expect(kit.isGameplayEdge(decor)).toBe(false)
        expect(kit.profile("Low") > kit.profile("High")).toBe(true)
        edge:Destroy()
        decor:Destroy()
        light:Destroy()
    end)

    it("reattaches mobile readability to late Decor and replaced arenas", function()
        local generated = Instance.new("Folder")
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        local calls = 0
        local current = nil
        local disconnect = MobileReadabilityKit.watch(generated, function(decor)
            calls += 1
            current = decor
        end)
        expect(calls).toBe(1)
        arena.Parent = generated
        task.wait()
        expect(current == nil).toBe(true)
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = arena
        task.wait()
        expect(current).toBe(decor)

        decor.Parent = nil
        task.wait()
        expect(current == nil).toBe(true)
        local replacement = Instance.new("Folder")
        replacement.Name = "Arena"
        arena.Parent = nil
        replacement.Parent = generated
        local lateDecor = Instance.new("Folder")
        lateDecor.Name = "Decor"
        lateDecor.Parent = replacement
        task.wait()
        expect(current).toBe(lateDecor)

        disconnect()
        local oldCalls = calls
        lateDecor.Parent = nil
        task.wait()
        expect(calls).toBe(oldCalls)
        generated:Destroy()
        arena:Destroy()
        decor:Destroy()
        lateDecor:Destroy()
    end)

end)

describe("PBR materials for four playable district hero environments", function()
    it("reserves expensive PBR for Android Medium/High only", function()
        expect(PbrDistrictRules.limit("Low")).toBe(0)
        expect(PbrDistrictRules.limit("Medium")).toBe(6)
        expect(PbrDistrictRules.limit("High")).toBe(16)
        expect(PbrDistrictRules.limit("Other")).toBe(0)
    end)

    it("authorizes exactly the four cosmetic local district models", function()
        local model = Instance.new("Model")
        model.Name = "Sector01_Observatory"
        model:SetAttribute("LocalOriginal3D", true)
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("DistrictSector", 1)
        expect(PbrDistrictRules.eligibleOwner(model)).toBe(true)
        model:SetAttribute("DistrictSector", 4)
        expect(PbrDistrictRules.eligibleOwner(model)).toBe(true)
        model:SetAttribute("DistrictSector", 5)
        expect(PbrDistrictRules.eligibleOwner(model)).toBe(false)
        model:SetAttribute("DistrictSector", 2)
        model:SetAttribute("CosmeticOnly", false)
        expect(PbrDistrictRules.eligibleOwner(model)).toBe(false)
        model:Destroy()
        local unsafe = Instance.new("Model")
        expect(PbrDistrictRules.eligibleOwner(unsafe)).toBe(false)
        unsafe:SetAttribute("ArenaDistrictArchitecture", true)
        expect(PbrDistrictRules.eligibleOwner(unsafe)).toBe(true)
        unsafe:Destroy()
    end)

    it("never touches hitboxes, neon, glass, authored variants or tiny decals", function()
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.Size = Vector3.new(8, 5, 4)
        part.Material = Enum.Material.Metal
        expect(PbrDistrictRules.eligiblePart(part)).toBe(true)
        part.CanCollide = true
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part.CanCollide = false
        part.Material = Enum.Material.Neon
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part.Material = Enum.Material.Glass
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part.Material = Enum.Material.Metal
        part.Transparency = 0.2
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part.Transparency = 0
        part.MaterialVariant = "ExistingPBR"
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part.MaterialVariant = ""
        part.Size = Vector3.new(2, 2, 2)
        expect(PbrDistrictRules.eligiblePart(part)).toBe(false)
        part:Destroy()
    end)

    it("maps authored material roles to all four real variants", function()
        expect(PbrDistrictRules.materialKey("FoundationPlinth", Enum.Material.Metal)).toBe("ceramic")
        expect(PbrDistrictRules.materialKey("DiamondPlateBrace", Enum.Material.Metal)).toBe("armor")
        expect(PbrDistrictRules.materialKey("CorrodedHousing", Enum.Material.CorrodedMetal)).toBe("oxidized")
        expect(PbrDistrictRules.materialKey("TelemetryHousing", Enum.Material.Metal)).toBe("titanium")
        expect(PbrDistrictRules.materialKey("ServiceShroud", Enum.Material.Metal)).toBe("oxidized")
    end)

    it("prioritizes large important surfaces instead of tiny assembly details", function()
        local hero = Instance.new("Part")
        hero.Name = "ReactorHousing"
        hero.Size = Vector3.new(8, 8, 8)
        local tiny = Instance.new("Part")
        tiny.Name = "Rivet"
        tiny.Size = Vector3.new(1, 1, 1)
        expect(PbrDistrictRules.priority(hero) > PbrDistrictRules.priority(tiny)).toBe(true)
        hero:Destroy()
        tiny:Destroy()
    end)
end)

describe("Author-owned kinetic details in four active 3D districts", function()
    it("uses restrained medium/high animation signatures on all four models", function()
        for sector = 1, 4 do
            expect(#DistrictKineticKit.plan(sector, "Low", false)).toBe(0)
            expect(#DistrictKineticKit.plan(sector, "Medium", false) >= 1).toBe(true)
            expect(#DistrictKineticKit.plan(sector, "High", false) >= 2).toBe(true)
            expect(#DistrictKineticKit.plan(sector, "High", true)).toBe(0)
        end
        expect(#DistrictKineticKit.plan(0, "High", false)).toBe(0)
        expect(#DistrictKineticKit.plan(5, "High", false)).toBe(0)
        expect(#DistrictKineticKit.plan("abc", "High", false)).toBe(0)
    end)

    it("animates only safe local cosmetic anchored parts and restores state", function()
        local model = Instance.new("Model")
        model:SetAttribute("LocalOriginal3D", true)
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("DistrictSector", 4)
        local target = Instance.new("Part")
        target.Name = "CommsSignalFin"
        target.Anchored = true
        target.CanCollide = false
        target.CanQuery = false
        target.CanTouch = false
        target.Size = Vector3.new(9, 7, 1.4)
        target.CFrame = CFrame.new(15, 6, 18)
        target.Parent = model
        local original = target.CFrame
        local tracks = DistrictKineticKit.start(model, 4, "Medium", false)
        expect(#tracks).toBe(1)
        expect(tracks[1].part).toBe(target)
        expect(tracks[1].property).toBe("CFrame")
        DistrictKineticKit.stop(tracks)
        expect(#tracks).toBe(0)
        expect(target.CFrame).toBe(original)
        expect(#DistrictKineticKit.start(model, 4, "Low", false)).toBe(0)
        expect(#DistrictKineticKit.start(model, 4, "High", true)).toBe(0)

        target.CanCollide = true
        expect(#DistrictKineticKit.start(model, 4, "High", false)).toBe(0)
        target.CanCollide = false
        model:SetAttribute("CosmeticOnly", false)
        expect(#DistrictKineticKit.start(model, 4, "High", false)).toBe(0)
        model:Destroy()
    end)

    it("keeps animated accent fades bounded, tiered and reversible", function()
        local model = Instance.new("Model")
        model:SetAttribute("LocalOriginal3D", true)
        model:SetAttribute("CosmeticOnly", true)
        model:SetAttribute("DistrictSector", 2)
        for _, name in ipairs({"CargoStripe-1", "CargoStripe1", "CraneCap"}) do
            local part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.Transparency = 0.32
            part.Parent = model
        end
        local medium = DistrictKineticKit.start(model, 2, "Medium", false)
        expect(#medium).toBe(2)
        DistrictKineticKit.stop(medium)
        local high = DistrictKineticKit.start(model, 2, "High", false)
        expect(#high).toBe(3)
        DistrictKineticKit.stop(high)
        for _, child in ipairs(model:GetChildren()) do
            expect(math.abs(child.Transparency - 0.32) < 0.0001).toBe(true)
        end
        model:Destroy()
    end)
end)

return nil
