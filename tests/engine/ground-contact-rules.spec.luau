--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local Rules = require("../../src/shared/GroundContactRules")
local SurfaceAudioRules = require("../../src/shared/SurfaceAudioRules")
local LandingImprintKit = require("../../src/client/LandingImprintKit")

describe("Grounded character contact game feel", function()
    it("limits decoration to living round entrants rather than the lobby and spectators", function()
        expect(Rules.eligible("round", true, true, false, false)).toBe(true)
        expect(Rules.eligible("round", true, true, true, false)).toBe(false)
        expect(Rules.eligible("round", true, nil, false, false)).toBe(false)
        expect(Rules.eligible("waiting", true, true, false, false)).toBe(false)
        expect(Rules.eligible("result", true, true, false, false)).toBe(false)
        expect(Rules.eligible("round", false, false, false, true)).toBe(true)
        expect(Rules.eligible("round", false, false, false, nil)).toBe(false)
    end)

    it("keeps local contacts visible in Low but removes expensive remote visuals", function()
        expect(Rules.pieceBudget("Low", false, false, true)).toBe(1)
        expect(Rules.pieceBudget("Low", false, false, false)).toBe(0)
        expect(Rules.pieceBudget("High", false, false, true)).toBe(6)
        expect(Rules.pieceBudget("High", false, false, false)).toBe(4)
        expect(Rules.pieceBudget("Medium", false, false, true)).toBe(4)
        expect(Rules.pieceBudget("Medium", false, false, false)).toBe(3)
        expect(Rules.pieceBudget("High", true, false, true)).toBe(1)
        expect(Rules.pieceBudget("High", true, false, false)).toBe(0)
        expect(Rules.pieceBudget("High", false, true, false)).toBe(0)
        expect(Rules.pieceBudget("Unknown", false, false, true)).toBe(0)
    end)

    it("gives metallic, mineral, icy floors genuinely distinct contact materials", function()
        expect(Rules.materialStyle(Enum.Material.Metal)).toBe("Mechanical")
        expect(Rules.materialStyle(Enum.Material.DiamondPlate)).toBe("Mechanical")
        expect(Rules.materialStyle(Enum.Material.Slate)).toBe("Mineral")
        expect(Rules.materialStyle(Enum.Material.Concrete)).toBe("Mineral")
        expect(Rules.materialStyle(Enum.Material.Ice)).toBe("Crystal")
        expect(Rules.materialStyle(Enum.Material.Glass)).toBe("Crystal")
        expect(Rules.materialStyle(Enum.Material.SmoothPlastic)).toBe("Neutral")
        local iceSound = SurfaceAudioRules.profile(Enum.Material.Ice)
        local metalSound = SurfaceAudioRules.profile(Enum.Material.Metal)
        local slateSound = SurfaceAudioRules.profile(Enum.Material.Slate)
        expect(iceSound.High ~= metalSound.High).toBe(true)
        expect(slateSound.Low ~= metalSound.Low).toBe(true)
    end)

    it("adds a quiet floor-specific heavy landing cue only after meaningful airtime", function()
        local metal = Rules.landingAudio(Enum.Material.Metal, 1.10, "High", false)
        local stone = Rules.landingAudio(Enum.Material.Slate, 1.10, "High", false)
        local crystal = Rules.landingAudio(Enum.Material.Ice, 1.10, "High", false)
        local mutedMotion = Rules.landingAudio(Enum.Material.Ice, 1.10, "High", true)
        expect(metal ~= nil and stone ~= nil and crystal ~= nil).toBe(true)
        expect(metal.Style).toBe("Mechanical")
        expect(stone.Style).toBe("Mineral")
        expect(crystal.Style).toBe("Crystal")
        expect(metal.PitchOffset ~= stone.PitchOffset).toBe(true)
        expect(crystal.PitchOffset ~= stone.PitchOffset).toBe(true)
        expect(crystal.VolumeScale <= 0.18).toBe(true)
        expect(mutedMotion.VolumeScale < crystal.VolumeScale).toBe(true)
        expect(Rules.landingAudio(Enum.Material.Ice, 0.3, "High", false) == nil).toBe(true)
        expect(Rules.landingAudio(Enum.Material.Ice, nil, "High", false) == nil).toBe(true)
        expect(Rules.landingAudio(Enum.Material.Metal, 1.1, "Low", false).VolumeScale
            < metal.VolumeScale).toBe(true)
    end)

    it("caps active parts, limits visibility and debounces air landings", function()
        expect(Rules.concurrentLimit("Low")).toBe(6)
        expect(Rules.concurrentLimit("Medium")).toBe(18)
        expect(Rules.concurrentLimit("High")).toBe(30)
        expect(Rules.maxDistance("High") > Rules.maxDistance("Medium")).toBe(true)
        expect(Rules.maxDistance("Medium") > Rules.maxDistance("Low")).toBe(true)
        expect(Rules.minAirtime("Low") > Rules.minAirtime("Medium")).toBe(true)
        expect(Rules.cooldownReady(4.0, nil)).toBe(true)
        expect(Rules.cooldownReady(4.2, 4.0)).toBe(false)
        expect(Rules.cooldownReady(4.8, 4.0)).toBe(true)
    end)
end)


describe("Premium material landing imprints", function()
    it("replaces every old opaque landing cylinder with up to six surface-aligned marks", function()
        local root = Instance.new("Folder")
        local normal = Vector3.new(0.1, 1, 0.24).Unit
        local guide = Vector3.zAxis
        local right = guide:Cross(normal).Unit
        local back = normal:Cross(right).Unit
        local frame = CFrame.fromMatrix(Vector3.new(22, 6, -9), right, normal, back)
        local variants = {
            {"Mechanical", Enum.Material.Metal, 4},
            {"Mineral", Enum.Material.Slate, 6},
            {"Crystal", Enum.Material.Glass, 3},
            {"Neutral", Enum.Material.SmoothPlastic, 1},
        }
        for _, variant in ipairs(variants) do
            local style, material, count = variant[1], variant[2], variant[3]
            local pieces = LandingImprintKit.build(
                root, frame, Color3.fromRGB(130, 185, 226),
                style, material, count, 0.82, false
            )
            expect(#pieces).toBe(count)
            for i, p in ipairs(pieces) do
                expect(p:IsA("BasePart")).toBe(true)
                expect(p:IsA("WedgePart") or p:IsA("Part")).toBe(true)
                expect(p:GetAttribute("ChaosLandingImprint")).toBe(true)
                expect(p:GetAttribute("LandingSurfaceStyle")).toBe(style)
                expect(p.Anchored).toBe(true)
                expect(p.CanCollide).toBe(false)
                expect(p.CanTouch).toBe(false)
                expect(p.CanQuery).toBe(false)
                expect(p.CastShadow).toBe(false)
                expect(p.Size.Y <= 0.05).toBe(true)
                expect(p.Size.Z <= 0.80).toBe(true)
                expect(math.abs(p.CFrame.UpVector:Dot(normal)) > 0.99).toBe(true)
                expect(p.Transparency >= 0.25).toBe(true)
                if style == "Mineral" or style == "Crystal" then
                    expect(p:IsA("WedgePart")).toBe(i > 1)
                end
                p:Destroy()
            end
        end
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
    end)

    it("caps its geometry at the same Low, Medium and High landing budgets", function()
        local root = Instance.new("Folder")
        local basis = CFrame.new()
        local color = Color3.new(1, 1, 1)
        local budgets = {
            {"Low", true, 1},
            {"Medium", true, 4},
            {"Medium", false, 3},
            {"High", true, 6},
            {"High", false, 4},
        }
        for _, info in ipairs(budgets) do
            local count = Rules.pieceBudget(info[1], false, false, info[2])
            expect(count).toBe(info[3])
            local pieces = LandingImprintKit.build(
                root, basis, color, "Mechanical", Enum.Material.Metal,
                count, 0.8, info[1] == "Low"
            )
            expect(#pieces).toBe(count)
            for _, piece in ipairs(pieces) do
                piece:Destroy()
            end
        end
        expect(#LandingImprintKit.build(
            root, basis, color, "Mechanical", Enum.Material.Metal,
            7, 1, false
        )).toBe(0)
        expect(#LandingImprintKit.build(
            root, basis, color, "Mechanical", Enum.Material.Metal,
            0, 1, false
        )).toBe(0)
        expect(#LandingImprintKit.build(
            root, basis, color, "Mechanical", nil,
            3, 1, false
        )).toBe(0)
        expect(#LandingImprintKit.build(
            root, nil, color, "Mechanical", Enum.Material.Metal,
            3, 1, false
        )).toBe(0)
        expect(#root:GetChildren()).toBe(0)
        root:Destroy()
    end)
end)

return nil
