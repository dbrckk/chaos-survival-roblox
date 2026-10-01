--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Freeze = require("../../src/server/Disasters/Freeze")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")
local ShrinkingArena = require("../../src/server/Disasters/ShrinkingArena")

local function baseContext()
    return {
        Config = Config,
        RoundSeconds = 1,
        Cleanup = {},
        OnCleanup = {},
        Active = function()
            return false
        end,
        Contestants = {},
        BalanceProfile = {},
    }
end

describe("Round cleanup contracts", function()
    it("structural disasters safely no-op when arena geometry is unavailable", function()
        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end

        local ctx = baseContext()
        expect(pcall(ShrinkingArena.start, ctx)).toBe(true)
        expect(pcall(DisappearingPlatforms.start, ctx)).toBe(true)
    end)

    it("Freeze registers deterministic cleanup restoration", function()
        local ctx = baseContext()
        Freeze.start(ctx)
        expect(#ctx.OnCleanup >= 1).toBe(true)

        for _, fn in ipairs(ctx.OnCleanup) do
            expect(pcall(fn)).toBe(true)
        end
    end)

    it("Shrinking Arena keeps visual borders aligned with the playable floor", function()
        local size, offset = ShrinkingArena.scaledEdgeTransform(
            Vector3.new(104, 0.45, 0.35),
            Vector3.new(0, 1.25, -51.6),
            0.5
        )

        expect(size.X).toBe(52)
        expect(size.Z).toBe(0.35)
        expect(offset.Z).toBe(-25.8)
        expect(offset.Y).toBe(1.25)
    end)

    it("Disappearing Platforms registers deterministic cleanup restoration", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)

        local ctx = baseContext()
        DisappearingPlatforms.start(ctx)
        expect(#ctx.OnCleanup >= 1).toBe(true)

        for _, fn in ipairs(ctx.OnCleanup) do
            expect(pcall(fn)).toBe(true)
        end

        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end
    end)
end)

return nil
