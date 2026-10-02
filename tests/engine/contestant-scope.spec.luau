--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local SpeedSurge = require("../../src/server/Disasters/SpeedSurge")
local LowGravity = require("../../src/server/Disasters/LowGravity")
local Tornado = require("../../src/server/Disasters/Tornado")
local JumpShock = require("../../src/server/Disasters/JumpShock")
local RisingLava = require("../../src/server/Disasters/RisingLava")

local function fakeContestant(name, position)
    local character = Instance.new("Model")
    character.Name = name .. "Character"

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Position = position
    root.Anchored = false
    root.Parent = character

    local hum = Instance.new("Humanoid")
    hum.WalkSpeed = 16
    hum.Parent = character

    character.Parent = workspace

    return {
        Name = name,
        Character = character,
    }, character, hum
end

describe("Contestant scoping", function()
    it("Speed Surge only modifies listed contestants", function()
        local included, includedCharacter, includedHum = fakeContestant(
            "Included",
            Config.ArenaCenter + Vector3.new(8, 4, 0)
        )
        local _, outsiderCharacter, outsiderHum = fakeContestant(
            "Outsider",
            Config.LobbyCenter + Vector3.new(0, 4, 0)
        )

        local cleanup = {}
        local onCleanup = {}
        local active = true

        SpeedSurge.start({
            Config = Config,
            Contestants = {included},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function() return active end,
            BalanceProfile = {SpeedMultiplier = 1.5},
        })

        expect(includedHum.WalkSpeed > 16).toBe(true)
        expect(outsiderHum.WalkSpeed).toBe(16)

        active = false
        for _, fn in ipairs(onCleanup) do
            pcall(fn)
        end

        expect(includedHum.WalkSpeed).toBe(16)

        includedCharacter:Destroy()
        outsiderCharacter:Destroy()
    end)

    it("Speed Surge applies to active AI hazard contestants without touching outsiders", function()
        local human, humanCharacter, humanHum = fakeContestant(
            "Human",
            Config.ArenaCenter + Vector3.new(6, 4, 0)
        )
        local bot, botCharacter, botHum = fakeContestant(
            "Bot",
            Config.ArenaCenter + Vector3.new(-6, 4, 0)
        )
        local outsider, outsiderCharacter, outsiderHum = fakeContestant(
            "Outsider",
            Config.LobbyCenter + Vector3.new(0, 4, 0)
        )

        bot.IsAISurvivor = true

        local cleanup = {}
        local onCleanup = {}

        SpeedSurge.start({
            Config = Config,
            Contestants = {human},
            HazardContestants = {human, bot},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function() return true end,
            IsContestantActive = function(subject)
                return subject == human or subject == bot
            end,
            BalanceProfile = {SpeedMultiplier = 1.5},
        })

        expect(humanHum.WalkSpeed > 16).toBe(true)
        expect(botHum.WalkSpeed > 16).toBe(true)
        expect(outsiderHum.WalkSpeed).toBe(16)

        for _, fn in ipairs(onCleanup) do
            pcall(fn)
        end

        humanCharacter:Destroy()
        botCharacter:Destroy()
        outsiderCharacter:Destroy()
    end)

    it("Speed Surge cleanup does not overwrite a newer speed state", function()
        local included, includedCharacter, includedHum = fakeContestant(
            "SpeedState",
            Config.ArenaCenter + Vector3.new(8, 4, 0)
        )

        local cleanup = {}
        local onCleanup = {}
        local active = true

        SpeedSurge.start({
            Config = Config,
            Contestants = {included},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function() return active end,
            IsContestantActive = function(player)
                return player == included
            end,
            BalanceProfile = {SpeedMultiplier = 1.5},
        })

        local surgeSpeed = includedHum.WalkSpeed
        expect(surgeSpeed > 16).toBe(true)

        includedHum.WalkSpeed = 18
        active = false
        for _, fn in ipairs(onCleanup) do
            pcall(fn)
        end

        expect(includedHum.WalkSpeed).toBe(18)
        includedCharacter:Destroy()
    end)

    it("Moon Gravity compensation tracks mass and never pulls downward", function()
        expect(LowGravity.compensationForce(10, 196.2, 55) > 0).toBe(true)
        expect(LowGravity.compensationForce(20, 196.2, 55)).toBe(
            LowGravity.compensationForce(10, 196.2, 55) * 2
        )
        expect(LowGravity.compensationForce(10, 40, 55)).toBe(0)
        expect(LowGravity.compensationForce(-5, 196.2, 55)).toBe(0)
    end)

    it("Moon Gravity only adds force to listed contestants and preserves world gravity", function()
        local included, includedCharacter = fakeContestant(
            "MoonIncluded",
            Config.ArenaCenter + Vector3.new(8, 4, 0)
        )
        local _, outsiderCharacter = fakeContestant(
            "MoonOutsider",
            Config.LobbyCenter + Vector3.new(0, 4, 0)
        )

        local worldGravity = workspace.Gravity
        local cleanup = {}
        local onCleanup = {}

        LowGravity.start({
            Config = Config,
            Contestants = {included},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function() return true end,
            IsContestantActive = function(player)
                return player == included
            end,
            BalanceProfile = {},
        })

        expect(workspace.Gravity).toBe(worldGravity)
        expect(includedCharacter:FindFirstChild("MoonGravityForce", true) ~= nil).toBe(true)
        expect(outsiderCharacter:FindFirstChild("MoonGravityForce", true) == nil).toBe(true)

        for _, object in ipairs(cleanup) do
            if object and object.Parent then
                object:Destroy()
            end
        end

        includedCharacter:Destroy()
        outsiderCharacter:Destroy()
    end)


    it("Rising Lava detects scripted contact only inside its footprint", function()
        local lavaPosition = Vector3.new(0, 5.5, 0)
        local lavaSize = Vector3.new(100, 4, 100)

        expect(RisingLava.rootInsideLava(Vector3.new(0, 10, 0), lavaPosition, lavaSize, 2.5)).toBe(true)
        expect(RisingLava.rootInsideLava(Vector3.new(0, 10.1, 0), lavaPosition, lavaSize, 2.5)).toBe(false)
        expect(RisingLava.rootInsideLava(Vector3.new(60, 5, 0), lavaPosition, lavaSize, 2.5)).toBe(false)
        expect(RisingLava.rootInsideLava(Vector3.new(0, 5, 60), lavaPosition, lavaSize, 2.5)).toBe(false)
    end)

    it("Rising Lava fully covers the active arena footprint", function()
        local size = RisingLava.coverageSize(Vector3.new(104, 2, 104), 8)
        expect(size.X).toBe(112)
        expect(size.Z).toBe(112)
        expect(size.Y).toBe(4)
    end)

    it("Rising Lava only eliminates active contestants", function()
        local included = {Name = "Included"}
        local outsider = {Name = "Outsider"}

        local ctx = {
            Contestants = {included},
            IsContestantActive = function(player)
                return player == included
            end,
        }

        expect(RisingLava.isActiveContestant(included, ctx)).toBe(true)
        expect(RisingLava.isActiveContestant(outsider, ctx)).toBe(false)
        expect(RisingLava.isActiveContestant(nil, ctx)).toBe(false)
    end)

    it("creates clear world telegraphs for Tornado and Jump Shock", function()
        local cleanup = {}
        local onCleanup = {}
        local active = true
        local ctx = {
            Config = Config,
            Contestants = {},
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function() return active end,
            BalanceProfile = {},
        }

        Tornado.start(ctx)
        task.wait(0.04)
        local tornado = workspace:FindFirstChild("RoundTornado")
        expect(tornado ~= nil).toBe(true)

        local dangerZone = tornado and tornado:FindFirstChild("DangerZone")
        expect(dangerZone ~= nil).toBe(true)
        expect((dangerZone :: BasePart).Size.Y).toBe(84)
        expect((dangerZone :: BasePart).Size.Z).toBe(84)

        JumpShock.start(ctx)

        active = false
        for _, fn in ipairs(onCleanup) do
            pcall(fn)
        end
        for _, object in ipairs(cleanup) do
            if object and object.Parent then
                object:Destroy()
            end
        end

        expect(workspace:FindFirstChild("RoundTornado") == nil).toBe(true)
    end)
end)

return nil
