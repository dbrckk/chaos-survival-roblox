--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local VisualBudgetRules = require("../../src/shared/VisualBudgetRules")

describe("visual budget rules", function()
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

return nil
