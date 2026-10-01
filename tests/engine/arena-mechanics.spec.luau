--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ArenaVariants = require("../../src/server/ArenaVariants")
local ArenaMechanics = require("../../src/server/ArenaMechanics")
local MovementSafety = require("../../src/server/MovementSafety")
local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")

describe("Arena mechanics", function()
    it("defines one mobility mechanic for every playable arena", function()
        local seenNames = {}

        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(mechanic ~= nil).toBe(true)
            expect(type(mechanic.Name)).toBe("string")
            expect(type(mechanic.Hint)).toBe("string")
            expect(#mechanic.Name >= 4).toBe(true)
            expect(#mechanic.Hint >= 24).toBe(true)
            expect(#mechanic.Hint <= 96).toBe(true)
            expect(seenNames[mechanic.Name] == nil).toBe(true)
            seenNames[mechanic.Name] = true
        end
    end)

    it("provides multiple telegraphed mobility choices per arena", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)
            expect(#mechanic.Pads >= 4).toBe(true)

            for _, pad in ipairs(mechanic.Pads) do
                expect(typeof(pad.offset)).toBe("Vector3")
                expect(typeof(pad.impulse)).toBe("Vector3")
                expect(pad.impulse.Magnitude >= 20).toBe(true)
                expect(pad.impulse.Magnitude <= 60).toBe(true)
            end
        end
    end)

    it("keeps ambient pad particles client-side", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)

        local cleanup = {}
        local ctx = {
            Config = Config,
            Cleanup = cleanup,
            OnCleanup = {},
            Active = function() return true end,
            Contestants = {},
            IsContestantActive = function() return false end,
        }

        local result = ArenaMechanics.start(ctx, "Classic")
        expect(result ~= nil).toBe(true)

        local generated = workspace:FindFirstChild("GeneratedMap")
        local arena = generated and generated:FindFirstChild("Arena")
        local mechanics = arena and arena:FindFirstChild("Mechanics")
        expect(mechanics ~= nil).toBe(true)
        expect(mechanics and mechanics:FindFirstChildWhichIsA("ParticleEmitter", true) == nil).toBe(true)

        for _, object in ipairs(cleanup) do
            if object and object.Parent then
                object:Destroy()
            end
        end
        if generated then
            generated:Destroy()
        end
    end)

    it("uses the shared movement safety contract for pad impulses", function()
        local current = Vector3.new(90, 80, -95)
        local impulse = Vector3.new(46, 55, 46)

        local padVelocity = ArenaMechanics.safeVelocity(current, impulse)
        local sharedVelocity = MovementSafety.addImpulse(current, impulse, 60, -52, 58)

        expect((padVelocity - sharedVelocity).Magnitude < 0.001).toBe(true)
    end)

    it("clamps stacked disaster velocity before applying pad motion", function()
        local velocity = ArenaMechanics.safeVelocity(
            Vector3.new(90, 80, -95),
            Vector3.new(46, 55, 46)
        )

        local horizontal = Vector3.new(velocity.X, 0, velocity.Z)
        expect(horizontal.Magnitude <= 60.001).toBe(true)
        expect(velocity.Y).toBe(58)

        local falling = ArenaMechanics.safeVelocity(
            Vector3.new(0, -90, 0),
            Vector3.new(0, 8, 0)
        )
        expect(falling.Y).toBe(-52)
    end)

    it("keeps mobility impulses non-lethal and bounded", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local mechanic = ArenaMechanics.get(id)

            for _, pad in ipairs(mechanic.Pads) do
                expect(pad.impulse.Y >= 0).toBe(true)
                expect(math.abs(pad.impulse.X) <= 50).toBe(true)
                expect(math.abs(pad.impulse.Z) <= 50).toBe(true)
                expect(pad.impulse.Y <= 55).toBe(true)
            end
        end
    end)
end)

return nil
