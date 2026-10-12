--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local LobbyActivities = require("../../src/server/LobbyActivities")
local PracticeVisualKit = require("../../src/client/LobbyPracticeVisualKit")
local PracticePadRegistry = require("../../src/client/LobbyPracticePadRegistry")
local PracticeGlyphKit = require("../../src/client/LobbyPracticeGlyphKit")

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
        pad.CFrame = CFrame.new(13, 2, -9)
        expect((bundle.attachment.WorldPosition
            - (pad.Position + Vector3.new(0, 0.25, 0))).Magnitude < 0.001)
            .toBe(true)
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

    it("localizes server-created 3D practice signs after late replication", function()
        local pad = Instance.new("Part")
        pad:SetAttribute("LobbyPracticePad", true)
        expect(PracticeVisualKit.localizePadLabel(pad, "ESSAIE LE BOOST"))
            .toBe(false)
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "PracticeLabel"
        billboard.Parent = pad
        expect(PracticeVisualKit.localizePadLabel(pad, "ESSAIE LE BOOST"))
            .toBe(false)
        local label = Instance.new("TextLabel")
        label.Text = "PRACTICE BOOST"
        label.Parent = billboard
        expect(PracticeVisualKit.localizePadLabel(pad, "ESSAIE LE BOOST"))
            .toBe(true)
        expect(label.Text).toBe("ESSAIE LE BOOST")
        expect(PracticeVisualKit.localizePadLabel(pad, "TRY BOOST"))
            .toBe(true)
        expect(label.Text).toBe("TRY BOOST")
        expect(PracticeVisualKit.localizePadLabel(pad, ""))
            .toBe(false)
        pad:Destroy()
    end)

    it("sculpts tier-bound directional chevrons on each practice boost pad", function()
        local root = Instance.new("Folder")
        local center = Vector3.new(0, 0, -150)
        local offsets = {
            Vector3.new(-22, 0, 0), Vector3.new(22, 0, 0),
            Vector3.new(0, 0, -22), Vector3.new(0, 0, 22),
        }
        local counts = {Low = 2, Medium = 4, High = 6}
        local total = {Low = 0, Medium = 0, High = 0}
        for _, offset in ipairs(offsets) do
            local pad = Instance.new("Part")
            pad.Name = "PracticeBoostPad"
            pad.Size = Vector3.new(7.2, 0.3, 7.2)
            pad.Position = center + offset
            pad.Color = Color3.fromRGB(70, 215, 255)
            pad:SetAttribute("LobbyPracticePad", true)
            pad.Parent = root
            local heading = PracticeGlyphKit.direction(pad, center)
            expect(heading ~= nil).toBe(true)
            expect(heading:Dot(-offset.Unit) > 0.999).toBe(true)
            local holder = Instance.new("Folder")
            holder.Parent = pad
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local glyph = PracticeGlyphKit.build(holder, pad, tier, center)
                expect(glyph ~= nil).toBe(true)
                expect(#glyph:GetChildren()).toBe(counts[tier])
                total[tier] += #glyph:GetChildren()
                for _, part in ipairs(glyph:GetChildren()) do
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part.Material).toBe(Enum.Material.Neon)
                    expect(part.Size.Magnitude > 0).toBe(true)
                    expect((part.Position - pad.Position).Magnitude < 4.0)
                        .toBe(true)
                end
                glyph:Destroy()
            end
            pad:Destroy()
        end
        expect(total.Low).toBe(8)
        expect(total.Medium).toBe(16)
        expect(total.High).toBe(24)
        expect(PracticeGlyphKit.count("Other")).toBe(0)
        root:Destroy()
    end)

    it("keeps painted chevrons aligned with moved and rotated pads", function()
        local root = Instance.new("Folder")
        local pad = Instance.new("Part")
        pad.Size = Vector3.new(7.2, 0.3, 7.2)
        pad.Position = Vector3.new(-22, 1.45, -150)
        pad:SetAttribute("LobbyPracticePad", true)
        pad.Parent = root
        local bundle = PracticeVisualKit.create(pad)
        local glyph = PracticeGlyphKit.build(bundle.folder, pad,
            "High", Vector3.new(0, 0, -150))
        expect(glyph ~= nil).toBe(true)
        local stroke = glyph:GetChildren()[1]
        local relative = pad.CFrame:ToObjectSpace(stroke.CFrame)
        local connection = PracticeGlyphKit.follow(glyph, pad)
        expect(connection ~= nil and connection.Connected).toBe(true)
        bundle.glyphConnection = connection

        pad.CFrame = CFrame.new(12, 4, -161)
            * CFrame.Angles(0, math.rad(31), 0)
        task.wait()
        local expected = pad.CFrame * relative
        expect((stroke.Position - expected.Position).Magnitude < 0.001)
            .toBe(true)
        expect(stroke.CFrame.LookVector:Dot(expected.LookVector) > 0.9999)
            .toBe(true)
        expect(stroke.CanCollide).toBe(false)
        expect(stroke.Anchored).toBe(true)

        PracticeVisualKit.destroy(bundle)
        expect(connection.Connected).toBe(false)
        expect(#pad:GetChildren()).toBe(0)
        pad:Destroy()
        root:Destroy()
    end)

    it("refuses to follow orphaned or empty glyph folders", function()
        local root = Instance.new("Folder")
        local pad = Instance.new("Part")
        pad.Parent = root
        local glyph = Instance.new("Folder")
        glyph.Name = "PracticeVectorGlyphLocal"
        glyph.Parent = root
        expect(PracticeGlyphKit.follow(glyph, pad) == nil).toBe(true)
        expect(PracticeGlyphKit.follow(nil, pad) == nil).toBe(true)
        glyph:Destroy()
        pad:Destroy()
        root:Destroy()
    end)

    it("rejects invalid pad glyph input without allocating Parts", function()
        local root = Instance.new("Folder")
        local pad = Instance.new("Part")
        pad:SetAttribute("LobbyPracticePad", true)
        pad.Parent = root
        local folder = Instance.new("Folder")
        folder.Parent = pad
        expect(PracticeGlyphKit.build(folder, pad, "Unknown", Vector3.zero)
            == nil).toBe(true)
        expect(PracticeGlyphKit.build(folder, pad, "High",
            Vector3.new(math.huge, 0, 0)) == nil).toBe(true)
        expect(PracticeGlyphKit.direction(pad, Vector3.new(0/0, 0, 0))
            == nil).toBe(true)
        expect(#folder:GetChildren()).toBe(0)
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

    it("observes late practice attributes and detaches on streaming", function()
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
        pad.Name = "PracticeBoostPad1"
        pad.Parent = activities

        local attaches = 0
        local detaches = 0
        local observers = PracticePadRegistry.new(
            function()
                attaches += 1
                local bundle = PracticeVisualKit.create(pad)
                expect(bundle ~= nil).toBe(true)
            end,
            function()
                detaches += 1
                local attachment = pad:FindFirstChild("PracticeMotesAttachment")
                local folder = pad:FindFirstChild("PracticePadPolishLocal")
                if attachment then attachment:Destroy() end
                if folder then folder:Destroy() end
            end
        )

        expect(PracticePadRegistry.isCandidate(pad)).toBe(true)
        expect(PracticePadRegistry.isCandidate(nil)).toBe(false)
        expect(observers.watch(pad)).toBe(true)
        expect(observers.watch(pad)).toBe(false)
        expect(observers.count()).toBe(1)
        expect(attaches).toBe(0)

        pad:SetAttribute("LobbyPracticePad", true)
        task.wait()
        expect(attaches).toBe(1)
        expect(pad:FindFirstChild("PracticeMotesAttachment") ~= nil).toBe(true)
        pad:SetAttribute("LobbyPracticePad", false)
        task.wait()
        expect(detaches).toBe(1)
        expect(pad:FindFirstChild("PracticeMotesAttachment") == nil).toBe(true)
        pad:SetAttribute("LobbyPracticePad", true)
        task.wait()
        expect(attaches).toBe(2)
        expect(observers.stop(pad)).toBe(true)
        expect(observers.stop(pad)).toBe(false)
        expect(detaches).toBe(2)
        expect(observers.count()).toBe(0)
        pad:SetAttribute("LobbyPracticePad", false)
        pad:SetAttribute("LobbyPracticePad", true)
        task.wait()
        expect(attaches).toBe(2)
        root:Destroy()
    end)

    it("refuses unrelated server parts without tracking them", function()
        local unrelated = Instance.new("Part")
        unrelated:SetAttribute("LobbyPracticePad", true)
        local observers = PracticePadRegistry.new(function()
            expect(false).toBe(true)
        end, function()
            expect(false).toBe(true)
        end)
        expect(PracticePadRegistry.isCandidate(unrelated)).toBe(false)
        expect(observers.watch(unrelated)).toBe(false)
        expect(observers.count()).toBe(0)
        unrelated:Destroy()
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
