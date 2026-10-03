--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisasterBalance = require("../../src/server/DisasterBalance")

local entries = {
    {Id = "RisingLava", Module = require("../../src/server/Disasters/RisingLava")},
    {Id = "Meteors", Module = require("../../src/server/Disasters/Meteors")},
    {Id = "LowGravity", Module = require("../../src/server/Disasters/LowGravity")},
    {Id = "DisappearingPlatforms", Module = require("../../src/server/Disasters/DisappearingPlatforms")},
    {Id = "Tornado", Module = require("../../src/server/Disasters/Tornado")},
    {Id = "Freeze", Module = require("../../src/server/Disasters/Freeze")},
    {Id = "Bombs", Module = require("../../src/server/Disasters/Bombs")},
    {Id = "SpeedSurge", Module = require("../../src/server/Disasters/SpeedSurge")},
    {Id = "Darkness", Module = require("../../src/server/Disasters/Darkness")},
    {Id = "ShrinkingArena", Module = require("../../src/server/Disasters/ShrinkingArena")},
    {Id = "JumpShock", Module = require("../../src/server/Disasters/JumpShock")},
}

local function cleanupRound(cleanup, onCleanup)
    for _, fn in ipairs(onCleanup) do
        pcall(fn)
    end
    for _, object in ipairs(cleanup) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

local function executeSet(modules, variantId)
    MapBuilder.build(Config, variantId, ArenaVariants)

    local cleanup = {}
    local onCleanup = {}
    local active = true
    local ctx = {
        Config = Config,
        RoundSeconds = 0.25,
        Cleanup = cleanup,
        OnCleanup = onCleanup,
        Active = function() return active end,
        Contestants = {},
        BalanceProfile = DisasterBalance.mobileProfile(1),
    }

    for _, module in ipairs(modules) do
        local ok, err = pcall(module.start, ctx)
        expect(ok).toBe(true)
        if not ok then
            error(tostring(err))
        end
    end

    task.wait(0.025)
    active = false
    cleanupRound(cleanup, onCleanup)
    task.wait(0.01)

    local root = workspace:FindFirstChild("GeneratedMap")
    expect(root ~= nil).toBe(true)
    local arena = root and root:FindFirstChild("Arena")
    expect(arena ~= nil).toBe(true)
    expect((arena :: Folder):GetAttribute("VariantId")).toBe(variantId)
    expect(workspace:FindFirstChild("RoundLava") == nil).toBe(true)
end

describe("Automated gameplay matrix", function()
    it("runs every disaster on every arena layout", function()
        local originalGravity = workspace.Gravity

        for _, variantId in ipairs(ArenaVariants.Order) do
            for _, entry in ipairs(entries) do
                executeSet({entry.Module}, variantId)
                expect(workspace.Gravity).toBe(originalGravity)
            end
        end
    end)

    it("runs every allowed Double Chaos pair without leaking state", function()
        local originalGravity = workspace.Gravity
        local testedPairs = 0

        for i = 1, #entries do
            for j = i + 1, #entries do
                local a = entries[i]
                local b = entries[j]

                if DisasterBalance.compatible(a.Id, b.Id) then
                    executeSet({a.Module, b.Module}, "Classic")
                    expect(workspace.Gravity).toBe(originalGravity)
                    testedPairs += 1
                end
            end
        end

        expect(testedPairs >= 40).toBe(true)

        local root = workspace:FindFirstChild("GeneratedMap")
        if root then
            root:Destroy()
        end
    end)
end)

return nil
