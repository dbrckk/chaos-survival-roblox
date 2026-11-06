--!strict
-- Screenshot-based readability gate, 2026-11-05: a rusty safe floor
-- must not resemble the authoritative neon orange RisingLava flood.
-- All checks run against real Roblox Parts/MapBuilder colliders, never
-- permissioning a fictitious hazard or assigning a new mesh/texture.
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect
local Config = require("../../src/shared/Config")
local ArenaVariants = require("../../src/server/ArenaVariants")
local MapBuilder = require("../../src/server/MapBuilder")
local Rules = require("../../src/shared/LavaGroundContrastRules")
local Crisis = require("../../src/shared/ArenaCrisisSurfaceRules")
local DisasterVisuals = require("../../src/shared/DisasterVisuals")
local PBR = require("../../src/client/PremiumGroundPbrKit")

local function errorFromOrange(c)
    -- All safe-material transforms suppress excessive warm orange
    -- dominance (R >> G and R >> B), preserving a blue-steel hue.
    return c.R - (c.G + c.B) * 0.5
end

describe("Android lava versus physically safe deck materials", function()
    it("enables contrast ONLY for live round lava including double chaos", function()
        expect(Rules.enabled({phase = "round",
            disasterIds = {"RisingLava"}})).toBe(true)
        expect(Rules.enabled({phase = "round",
            disasterIds = {"Bombs", "RisingLava"}})).toBe(true)
        expect(Rules.enabled({phase = "ready",
            disasterIds = {"RisingLava"}})).toBe(false)
        expect(Rules.enabled({phase = "result",
            disasterIds = {"RisingLava"}})).toBe(false)
        expect(Rules.enabled({phase = "round",
            disasterIds = {"Tornado"}})).toBe(false)
        expect(Rules.enabled({phase = "round"})).toBe(false)
        expect(Rules.enabled(nil)).toBe(false)
    end)

    it("cools warm safe steel and restores EXACT original materials", function()
        local rust = Color3.fromRGB(187, 102, 68)
        for _, role in ipairs({"deck", "module", "mesh", "detail"}) do
            local safe = Rules.tint(rust, role, true)
            expect(typeof(safe)).toBe("Color3")
            expect(safe ~= rust).toBe(true)
            expect(errorFromOrange(safe) < errorFromOrange(rust))
                .toBe(true)
            expect(Rules.tint(rust, role, false)).toBe(rust)
        end
        expect(Rules.tint(rust, "hazard", true)).toBe(rust)
        expect(Rules.tint(rust, "platform", true)).toBe(rust)
        expect(Rules.tint(nil, "deck", true)).toBe(nil)
    end)

    it("never edits collidable floors, warning parts or untrusted decals", function()
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = workspace
        local inset = Instance.new("Part")
        inset.Name = "ArenaDeckInset"
        inset.Size = Vector3.new(313, 0.14, 313)
        inset.Anchored = true
        inset.CanCollide = false
        inset.CanTouch = false
        inset.CanQuery = false
        inset:SetAttribute("PremiumArchitecturalSurface", true)
        inset.Parent = decor
        expect(Rules.nativeRole(inset, decor)).toBe("deck")

        local module = inset:Clone()
        module.Name = "PremiumGroundModule13"
        module.Size = Vector3.new(49, 0.035, 49)
        module:SetAttribute("OriginalGroundFinish", true)
        module.Parent = decor
        expect(Rules.nativeRole(module, decor)).toBe("module")
        module.CanCollide = true
        expect(Rules.nativeRole(module, decor)).toBe(nil)
        module.CanCollide = false
        module.Transparency = 0.9
        expect(Rules.nativeRole(module, decor)).toBe(nil)
        module.Transparency = 0
        expect(Rules.nativeRole(module, decor)).toBe("module")

        local fake = module:Clone()
        fake.Name = "BombWarningRing"
        fake.Parent = decor
        expect(Rules.nativeRole(fake, decor)).toBe(nil)
        fake:Destroy()
        module:Destroy()
        decor:Destroy()
    end)

    it("retints ONLY the real five authored arena deck insets", function()
        for _, id in ipairs(ArenaVariants.Order) do
            local root = MapBuilder.build(Config, id, ArenaVariants)
            local arena = root:FindFirstChild("Arena")
            local decor = arena:FindFirstChild("Decor")
            local inset = decor:FindFirstChild("ArenaDeckInset")
            local base = arena:FindFirstChild("Base")
            expect(inset ~= nil and inset:IsA("BasePart")).toBe(true)
            expect(Rules.nativeRole(inset, decor)).toBe("deck")
            expect(Rules.nativeRole(base, decor)).toBe(nil)
            expect(inset.CanCollide).toBe(false)
            local steel = Rules.tint(inset.Color, "deck", true)
            expect(steel ~= inset.Color).toBe(true)
            root:Destroy()
        end
    end)

    it("reuses approved 2K titanium and avoids warm disaster details", function()
        expect(PBR.family("Harbor")).toBe("OxidizedSteel")
        expect(PBR.family("Crossroads")).toBe("OxidizedSteel")
        expect(PBR.family("LavaSafeSteel")).toBe("BrushedTitanium")
        local profile = Crisis.profile(
            {"RisingLava"}, "round", "High", false, false,
            DisasterVisuals)
        expect(profile.LavaActive).toBe(true)
        local warm = Color3.fromRGB(187, 102, 68)
        local cooled = Crisis.shade(warm, Enum.Material.Metal,
            "RepairPlate4", 4, profile, 13.0)
        expect(errorFromOrange(cooled) < errorFromOrange(warm))
            .toBe(true)
        local finished = Crisis.profile(
            {"RisingLava"}, "result", "Medium", false, false,
            DisasterVisuals)
        expect(finished.LavaActive).toBe(false)
        expect(Crisis.shade(warm, Enum.Material.Metal,
            "RepairPlate4", 4, finished, 13.0)).toBe(warm)
    end)
end)

return nil
