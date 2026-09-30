--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")

describe("Chaos Survival engine", function()
    it("builds a complete playable map hierarchy", function()
        local existing = workspace:FindFirstChild("GeneratedMap")
        if existing then
            existing:Destroy()
        end

        local root = MapBuilder.build(Config)

        expect(root ~= nil).toBe(true)
        expect(root.Parent == workspace).toBe(true)
        expect(root:FindFirstChild("Lobby") ~= nil).toBe(true)
        expect(root:FindFirstChild("Arena") ~= nil).toBe(true)

        local arena = root:FindFirstChild("Arena")
        expect(arena ~= nil).toBe(true)

        local spawns = arena and arena:FindFirstChild("Spawns")
        local platforms = arena and arena:FindFirstChild("Platforms")

        expect(spawns ~= nil).toBe(true)
        expect(platforms ~= nil).toBe(true)
        expect(#(spawns :: Folder):GetChildren() >= 4).toBe(true)
        expect(#(platforms :: Folder):GetChildren() >= 10).toBe(true)

        root:Destroy()
    end)

    it("has valid round timing and rewards", function()
        expect(Config.RoundSeconds > 0).toBe(true)
        expect(Config.IntermissionSeconds >= 0).toBe(true)
        expect(Config.WinCoins > 0).toBe(true)
        expect(Config.WinXP > 0).toBe(true)
    end)
end)

return nil
