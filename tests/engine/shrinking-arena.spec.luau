--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")
local OrbitalHelix = require("../../src/server/OrbitalHelix")

local function cleanup(callbacks, objects)
    for _, fn in ipairs(callbacks) do
        pcall(fn)
    end
    for _, object in ipairs(objects) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

describe("Shrinking Arena mobility integration", function()
    it("moves mobility pads inward and restores them on cleanup", function()
        MapBuilder.build(Config, "Towers", ArenaVariants)

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local base = arena and arena:FindFirstChild("Base")
        expect(base ~= nil).toBe(true)

        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local pad = Instance.new("Part")
        pad.Name = "MobilityPadRegression"
        pad.Anchored = true
        pad.Size = Vector3.new(6.5, 0.35, 6.5)
        pad.Position = (base :: BasePart).Position + Vector3.new(28, 1.7, 28)
        pad:SetAttribute("ArenaMobilityPad", true)
        pad:SetAttribute("ImpulseX", 40)
        pad:SetAttribute("ImpulseY", 10)
        pad:SetAttribute("ImpulseZ", -20)
        pad.Parent = mechanics

        local original = pad.CFrame
        local originalImpulse = Vector3.new(40, 10, -20)
        local originalDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.30,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function()
                return active
            end,
        })

        task.wait(0.18)

        local movedDistance = (
            Vector3.new(pad.Position.X, 0, pad.Position.Z)
            - Vector3.new((base :: BasePart).Position.X, 0, (base :: BasePart).Position.Z)
        ).Magnitude
        expect(movedDistance < originalDistance).toBe(true)

        local shrunkImpulse = Vector3.new(
            tonumber(pad:GetAttribute("ImpulseX")) or 0,
            tonumber(pad:GetAttribute("ImpulseY")) or 0,
            tonumber(pad:GetAttribute("ImpulseZ")) or 0
        )
        expect(math.abs(shrunkImpulse.X) < math.abs(originalImpulse.X)).toBe(true)
        expect(math.abs(shrunkImpulse.Z) < math.abs(originalImpulse.Z)).toBe(true)
        expect(shrunkImpulse.Y).toBe(originalImpulse.Y)

        active = false
        cleanup(callbacks, objects)
        expect(pad.CFrame).toBe(original)
        expect(pad:GetAttribute("ImpulseX")).toBe(originalImpulse.X)
        expect(pad:GetAttribute("ImpulseY")).toBe(originalImpulse.Y)
        expect(pad:GetAttribute("ImpulseZ")).toBe(originalImpulse.Z)

        if generated then
            generated:Destroy()
        end
    end)
    it("shrinks four Tower Run skybridge decks, rails and supports as one assembly", function()
        local root = MapBuilder.build(Config, "Towers", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena:FindFirstChild("Platforms")
        local decor = arena:FindFirstChild("Decor")
        local originals = {}
        local details = {}

        expect(ShrinkingArena.skybridgeSpan(49, 1)).toBe(49)
        expect(math.abs(ShrinkingArena.skybridgeSpan(49, 0.45) - 18.2) < 0.01).toBe(true)
        for index = 18, 21 do
            local bridge = platforms:FindFirstChild("Skybridge" .. index)
            expect(bridge ~= nil).toBe(true)
            expect(bridge.CanCollide).toBe(true)
            expect(bridge:GetAttribute("ChaosSkybridge")).toBe(true)
            local prefix = {
                "SkybridgeRail" .. index .. "_1",
                "SkybridgeRib" .. index .. "_0",
                "PlatformGlow" .. index,
                "PlatformPanel" .. index,
                "PlatformUnderFrame" .. index,
                "PlatformCoreGlow" .. index,
                "PlatformSupport" .. index .. "_1",
            }
            originals[bridge] = {cf = bridge.CFrame, size = bridge.Size}
            details[bridge] = {}
            for _, name in ipairs(prefix) do
                local part = decor:FindFirstChild(name)
                expect(part ~= nil).toBe(true)
                originals[part] = {cf = part.CFrame, size = part.Size}
                table.insert(details[bridge], part)
            end
        end

        local running = true
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config, RoundSeconds = 0.36,
            Cleanup = {}, OnCleanup = callbacks,
            Active = function() return running end,
        })
        task.wait(0.22)

        for bridge, old in pairs(originals) do
            if bridge:GetAttribute("ChaosSkybridge") == true then
                local alongX = old.size.X > old.size.Z
                local originalSpan = math.max(old.size.X, old.size.Z)
                local shrunkSpan = math.max(bridge.Size.X, bridge.Size.Z)
                expect(shrunkSpan < originalSpan).toBe(true)
                expect(shrunkSpan > 4).toBe(true)
                expect(bridge.CanCollide).toBe(true)
                expect((bridge.Position - old.cf.Position).Magnitude < 0.01).toBe(true)

                for _, detail in ipairs(details[bridge]) do
                    local prior = originals[detail]
                    local d0 = alongX and prior.size.X or prior.size.Z
                    local d1 = alongX and detail.Size.X or detail.Size.Z
                    if d0 > 2.2 then
                        expect(d1 < d0).toBe(true)
                    end
                    expect(detail.CanCollide).toBe(false)
                    expect(detail.Parent).toBe(decor)
                end
            end
        end

        running = false
        cleanup(callbacks, {})
        for part, old in pairs(originals) do
            expect((part.Position - old.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - old.size).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)

    it("shrinks every Orbital ramp with the decks, then restores its beams", function()
        local root = MapBuilder.build(Config, "Orbital", ArenaVariants)
        local arena = root:FindFirstChild("Arena")
        local platforms = arena and arena:FindFirstChild("Platforms")
        local helix = arena and arena:FindFirstChild("HelixCircuit")
        expect(platforms ~= nil).toBe(true)
        expect(helix ~= nil).toBe(true)

        local originals = {}
        local source = OrbitalHelix.capture(helix)
        expect(#source).toBe(8)
        for _, state in ipairs(source) do
            originals[state.ramp] = {
                cf = state.ramp.CFrame,
                size = state.ramp.Size,
            }
            expect(#state.decorations).toBe(8)
            for _, d in ipairs(state.decorations) do
                originals[d.part] = {cf = d.part.CFrame, size = d.part.Size}
            end
        end

        local active = true
        local objects = {}
        local callbacks = {}
        ShrinkingArena.start({
            Config = Config,
            RoundSeconds = 0.36,
            Cleanup = objects,
            OnCleanup = callbacks,
            Active = function() return active end,
        })
        task.wait(0.22)

        local advanced = 0
        for index = 1, 8 do
            local outer = platforms:FindFirstChild("Platform" .. index)
            local inner = platforms:FindFirstChild("Platform" .. (index + 8))
            local ramp = helix:FindFirstChild("HelixRamp" .. index)
            expect(outer ~= nil).toBe(true)
            expect(inner ~= nil).toBe(true)
            expect(ramp ~= nil).toBe(true)

            local from = outer.Position + Vector3.new(0, outer.Size.Y * 0.5 - 0.15, 0)
            local to = inner.Position + Vector3.new(0, inner.Size.Y * 0.5 - 0.15, 0)
            expect((ramp.Position - (from + to) * 0.5).Magnitude < 0.1).toBe(true)
            expect((ramp.CFrame.LookVector - (to - from).Unit).Magnitude < 0.02).toBe(true)
            expect(math.abs(ramp.Size.Z - ((to - from).Magnitude + 4.4)) < 0.1).toBe(true)

            local old = originals[ramp]
            if (ramp.Position - old.cf.Position).Magnitude > 1 then
                advanced += 1
            end
            expect(ramp.CanCollide).toBe(true)
            local rail = helix:FindFirstChild("HelixEdgeSignal" .. index .. "_1")
            expect(rail ~= nil).toBe(true)
            expect(rail.CanCollide).toBe(false)
            expect((rail.CFrame.Position - originals[rail].cf.Position).Magnitude > 0.3).toBe(true)
        end
        expect(advanced).toBe(8)

        active = false
        cleanup(callbacks, objects)
        for part, state in pairs(originals) do
            expect((part.CFrame.Position - state.cf.Position).Magnitude < 0.001).toBe(true)
            expect((part.Size - state.size).Magnitude < 0.001).toBe(true)
        end
        root:Destroy()
    end)
end)

return nil
