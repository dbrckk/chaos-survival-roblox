--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local LobbyActivities = require("../../src/server/LobbyActivities")
local PracticeVisualKit = require("../../src/client/LobbyPracticeVisualKit")

describe("Lobby activities", function()
    it("provides four symmetric practice boost pads", function()
        expect(#LobbyActivities.Definitions).toBe(4)

        local planarTotal = Vector3.zero
        for _, definition in ipairs(LobbyActivities.Definitions) do
            planarTotal += Vector3.new(definition.offset.X, 0, definition.offset.Z)
            expect(math.abs(definition.offset.Y - 1.45) < 0.001).toBe(true)
        end

        expect(planarTotal.Magnitude < 0.001).toBe(true)
    end)

    it("keeps particle attachments on their actual arena pads", function()
        local root = Instance.new("Folder")
        local pad = Instance.new("Part")
        pad.Color = Color3.fromRGB(110, 195, 250)
        pad:SetAttribute("LobbyPracticePad", true)
        pad.Parent = root
        local bundle = PracticeVisualKit.create(pad)
        expect(bundle ~= nil).toBe(true)
        expect(bundle.folder.Parent).toBe(pad)
        expect(bundle.attachment.Parent).toBe(pad)
        expect(bundle.emitter.Parent).toBe(bundle.attachment)
        expect(bundle.highlight.Adornee).toBe(pad)
        expect(bundle.emitter:IsA("ParticleEmitter")).toBe(true)
        expect(#pad:GetChildren()).toBe(2)
        expect(PracticeVisualKit.create(pad) == nil).toBe(true)
        PracticeVisualKit.destroy(bundle)
        expect(#pad:GetChildren()).toBe(0)
        local fresh = PracticeVisualKit.create(pad)
        expect(fresh ~= nil).toBe(true)
        PracticeVisualKit.destroy(fresh)
        expect(#pad:GetChildren()).toBe(0)
        pad:Destroy()
        root:Destroy()
    end)

    it("gates practice motes on Reduce Motion without hiding pad guidance", function()
        expect(PracticeVisualKit.rate({Name = "High", ParticleScale = 1}, false))
            .toBe(4)
        expect(PracticeVisualKit.rate({Name = "Medium", ParticleScale = 0.5}, false))
            .toBe(2)
        expect(PracticeVisualKit.rate({Name = "Low", ParticleScale = 0.2}, false))
            .toBe(0.8)
        expect(PracticeVisualKit.rate({Name = "High", ParticleScale = 1}, true))
            .toBe(0)
        expect(PracticeVisualKit.rate({Name = "High", ParticleScale = math.huge}, false))
            .toBe(0)
        expect(PracticeVisualKit.create(nil) == nil).toBe(true)
        local invalid = Instance.new("Part")
        expect(PracticeVisualKit.create(invalid) == nil).toBe(true)
        invalid:Destroy()
    end)

    it("keeps practice boosts inside movement safety limits", function()
        local result = LobbyActivities.safeVelocity(
            Vector3.new(40, 10, 0),
            Vector3.new(31, 28, 0)
        )

        expect(Vector3.new(result.X, 0, result.Z).Magnitude <= 48.001).toBe(true)
        expect(result.Y <= 48.001).toBe(true)
        expect(result.Y >= -45.001).toBe(true)
    end)
end)

return nil
