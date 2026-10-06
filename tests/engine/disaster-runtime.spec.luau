--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Config = require("../../src/shared/Config")
local MapBuilder = require("../../src/server/MapBuilder")
local ArenaVariants = require("../../src/server/ArenaVariants")
local DisasterBalance = require("../../src/server/DisasterBalance")

local disasters = {
    {id = "RisingLava", module = require("../../src/server/Disasters/RisingLava")},
    {id = "Meteors", module = require("../../src/server/Disasters/Meteors")},
    {id = "LowGravity", module = require("../../src/server/Disasters/LowGravity")},
    {id = "DisappearingPlatforms", module = require("../../src/server/Disasters/DisappearingPlatforms")},
    {id = "Tornado", module = require("../../src/server/Disasters/Tornado")},
    {id = "Freeze", module = require("../../src/server/Disasters/Freeze")},
    {id = "Bombs", module = require("../../src/server/Disasters/Bombs")},
    {id = "SpeedSurge", module = require("../../src/server/Disasters/SpeedSurge")},
    {id = "Darkness", module = require("../../src/server/Disasters/Darkness")},
    {id = "ShrinkingArena", module = require("../../src/server/Disasters/ShrinkingArena")},
    {id = "JumpShock", module = require("../../src/server/Disasters/JumpShock")},
}

local function runCleanup(cleanup, onCleanup)
    for _, callback in ipairs(onCleanup) do
        pcall(callback)
    end

    for _, object in ipairs(cleanup) do
        if object and object.Parent then
            object:Destroy()
        end
    end
end

describe("Headless disaster playtest", function()
    it("reports real tornado knockback contacts", function()
        MapBuilder.build(Config, "Classic", ArenaVariants)

        local active = true
        local cleanup = {}
        local onCleanup = {}
        local contactKind = nil

        local character = Instance.new("Model")
        character.Name = "TornadoContactSubject"

        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored = true
        root.CanCollide = false
        root.Position = Config.ArenaCenter + Vector3.new(12, 3, 0)
        root.Parent = character

        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = character
        character.Parent = workspace

        local subject = {
            Character = character,
        }

        local ctx = {
            Config = Config,
            RoundSeconds = 1,
            Cleanup = cleanup,
            OnCleanup = onCleanup,
            Active = function()
                return active
            end,
            HazardContestants = {subject},
            Contestants = {subject},
            IsContestantActive = function()
                return true
            end,
            BalanceProfile = DisasterBalance.mobileProfile(1),
            Intensity = function()
                return 1
            end,
            OnHazardContact = function(target, kind)
                if target == subject then
                    contactKind = kind
                end
            end,
        }

        local tornado = require("../../src/server/Disasters/Tornado")
        local ok, err = pcall(tornado.start, ctx)
        expect(ok).toBe(true)

        local deadline = os.clock() + 0.75
        while contactKind == nil and os.clock() < deadline do
            task.wait(0.05)
        end

        expect(contactKind).toBe("Tornado")

        active = false
        runCleanup(cleanup, onCleanup)
        character:Destroy()

        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end

        if not ok then
            error("Tornado contact runtime failed: " .. tostring(err))
        end
    end)

    it("starts and cleans every disaster inside a real Roblox DataModel", function()
        local originalGravity = workspace.Gravity

        for _, entry in ipairs(disasters) do
            MapBuilder.build(Config, "Classic", ArenaVariants)

            local active = true
            local cleanup = {}
            local onCleanup = {}

            local ctx = {
                Config = Config,
                RoundSeconds = 1,
                Cleanup = cleanup,
                OnCleanup = onCleanup,
                Active = function()
                    return active
                end,
                Contestants = {},
                BalanceProfile = DisasterBalance.mobileProfile(1),
            }

            local ok, err = pcall(entry.module.start, ctx)
            expect(ok).toBe(true)

            task.wait(0.08)
            active = false
            runCleanup(cleanup, onCleanup)
            task.wait(0.02)

            expect(workspace.Gravity).toBe(originalGravity)

            local root = workspace:FindFirstChild("GeneratedMap")
            expect(root ~= nil).toBe(true)
            expect((root :: Folder):FindFirstChild("Arena") ~= nil).toBe(true)

            local lava = workspace:FindFirstChild("RoundLava")
            expect(lava == nil).toBe(true)

            if not ok then
                error(entry.id .. " runtime failed: " .. tostring(err))
            end
        end

        local generated = workspace:FindFirstChild("GeneratedMap")
        if generated then
            generated:Destroy()
        end
    end)
end)

return nil
