--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VfxQuality = require("../../src/shared/VfxQuality")
local DisasterCosmeticRules = require("../../src/shared/DisasterCosmeticRules")
local MobileReadabilityKit = require("../../src/client/MobileReadabilityKit")

describe("Adaptive VFX quality", function()
    it("starts touch devices conservatively without capping capable hardware", function()
        expect(VfxQuality.initialTier(true)).toBe("Medium")
        expect(VfxQuality.initialTier(false)).toBe("High")
        expect(VfxQuality.nextTier(VfxQuality.initialTier(true), 60)).toBe("High")
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

    it("protects touch FPS without reducing desktop visual quality", function()
        -- Short-lived 43–47 FPS mobile loads should not remain on High.
        expect(VfxQuality.nextTier("High", 47, true)).toBe("Medium")
        expect(VfxQuality.nextTier("High", 47, false)).toBe("High")
        expect(VfxQuality.nextTier("High", 48, true)).toBe("High")

        -- An ordinary 55–58 FPS touch sample is not sufficient to promote.
        -- Existing multi-sample promotion hysteresis applies as well.
        expect(VfxQuality.nextTier("Medium", 57, true)).toBe("Medium")
        expect(VfxQuality.nextTier("Medium", 57, false)).toBe("High")
        expect(VfxQuality.nextTier("Medium", 59, true)).toBe("High")

        expect(VfxQuality.nextTier("Low", 45, true)).toBe("Low")
        expect(VfxQuality.nextTier("Low", 45, false)).toBe("Medium")
        expect(VfxQuality.nextTier("Low", 47, true)).toBe("Medium")
        -- Emergency quality reductions stay immediate on all devices.
        expect(VfxQuality.nextTier("Medium", 29, true)).toBe("Low")
        expect(VfxQuality.nextTier("Medium", 29, false)).toBe("Low")
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
        expect(math.abs(decor.LocalTransparencyModifier - 0.18) < 0.001).toBe(true)
        expect(math.abs(light.Brightness - 1.24) < 0.001).toBe(true)
        kit.applyInstance(light, "Medium", baseline)
        expect(math.abs(light.Brightness - 1.44) < 0.001).toBe(true)
        kit.applyInstance(light, "High", baseline)
        expect(math.abs(light.Brightness - 1.60) < 0.001).toBe(true)
        kit.applyInstance(light, "Low", baseline)
        expect(math.abs(light.Brightness - 1.24) < 0.001).toBe(true)
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

return nil
