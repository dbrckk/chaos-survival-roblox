--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")

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
end)

return nil
