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

        expect(math.abs(size.X - 52) < 0.001).toBe(true)
        expect(math.abs(size.Z - 0.35) < 0.001).toBe(true)
        expect(math.abs(offset.Z + 25.8) < 0.001).toBe(true)
        expect(math.abs(offset.Y - 1.25) < 0.001).toBe(true)
    end)

    it("Shrinking Arena recenters platforms without changing their height", function()
        local offset = ShrinkingArena.scaledLocalPosition(
            Vector3.new(34, 10, -25),
            0.5
        )

        expect(math.abs(offset.X - 17) < 0.001).toBe(true)
        expect(math.abs(offset.Y - 10) < 0.001).toBe(true)
        expect(math.abs(offset.Z + 12.5) < 0.001).toBe(true)
    end)

    it("Disappearing Platforms filters out invalid and already active parts", function()
        local folder = Instance.new("Folder")
        local valid = Instance.new("Part")
        valid.CanCollide = true
        valid.Parent = folder

        local disabled = Instance.new("Part")
        disabled.CanCollide = false
        disabled.Parent = folder

        local nested = Instance.new("Folder")
        nested.Parent = folder

        local activeStates = {}
        local eligible = DisappearingPlatforms.eligiblePlatforms(folder, activeStates)
        expect(#eligible).toBe(1)
        expect(eligible[1]).toBe(valid)

        activeStates[valid] = true
        expect(#DisappearingPlatforms.eligiblePlatforms(folder, activeStates)).toBe(0)

        folder:Destroy()
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
