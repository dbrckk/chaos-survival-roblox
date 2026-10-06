--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local AnimationCatalog = require("../../src/shared/AnimationCatalog")

describe("animation catalog", function()
    it("keeps every AI fallback clip as a positive asset id", function()
        for _, id in pairs(AnimationCatalog.AISurvivor) do
            expect(type(id)).toBe("number")
            expect(id > 0).toBe(true)
            expect(AnimationCatalog.assetId(id)).toBe("rbxassetid://" .. tostring(id))
        end
    end)

    it("rejects invalid animation ids", function()
        expect(AnimationCatalog.assetId(nil)).toBe("")
        expect(AnimationCatalog.assetId(0)).toBe("")
        expect(AnimationCatalog.assetId(-5)).toBe("")
    end)
end)

return nil
