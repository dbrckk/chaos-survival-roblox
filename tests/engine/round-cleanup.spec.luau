--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local Freeze = require("../../src/server/Disasters/Freeze")
local DisappearingPlatforms = require("../../src/server/Disasters/DisappearingPlatforms")

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
    it("Freeze registers deterministic cleanup restoration", function()
        local ctx = baseContext()
        Freeze.start(ctx)
        expect(#ctx.OnCleanup >= 1).toBe(true)

        for _, fn in ipairs(ctx.OnCleanup) do
            expect(pcall(fn)).toBe(true)
        end
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
