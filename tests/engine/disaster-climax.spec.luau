--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local DisasterClimax = require("../../src/shared/DisasterClimax")
local Signature = require("../../src/client/DisasterClimaxSignatureKit")
local Boundary = require("../../src/client/DisasterBoundaryClimaxKit")
local Elements = require("../../src/client/DisasterClimaxElementKit")

local IDS = {
    "RisingLava",
    "Meteors",
    "LowGravity",
    "DisappearingPlatforms",
    "Tornado",
    "Freeze",
    "Bombs",
    "SpeedSurge",
    "Darkness",
    "ShrinkingArena",
    "JumpShock",
}

describe("Disaster climax progression", function()
    it("covers every disaster with a unique climax profile", function()
        local kinds = {}
        for _, id in ipairs(IDS) do
            local profile = DisasterClimax.get(id)
            expect(profile ~= nil).toBe(true)
            expect(type(profile.Kind)).toBe("string")
            expect(typeof(profile.Color)).toBe("Color3")
            expect(typeof(profile.Secondary)).toBe("Color3")
            kinds[profile.Kind] = true
        end
        expect(#IDS).toBe(11)
        expect(next(kinds) ~= nil).toBe(true)
    end)

    it("progresses through surge and critical stages from intensity", function()
        expect(DisasterClimax.stageFor(0.90, false, false)).toBe(0)
        expect(DisasterClimax.stageFor(0.98, false, false)).toBe(1)
        expect(DisasterClimax.stageFor(1.06, false, false)).toBe(2)
    end)

    it("promotes overdrive to the critical visual stage", function()
        expect(DisasterClimax.stageFor(0.90, false, true)).toBe(2)
        expect(DisasterClimax.stageFor(1.02, false, true)).toBe(2)
    end)

    it("rejects delayed climax bursts from stale stages, maps and rounds", function()
        local can = DisasterClimax.shouldPresent
        expect(can(7, 7, 2, 2, true, true, false)).toBe(true)
        expect(can(7, 7, 2, 2, true, true, nil)).toBe(true)
        expect(can(6, 7, 2, 2, true, true, false)).toBe(false)
        expect(can(7, 7, 1, 2, true, true, false)).toBe(false)
        expect(can(7, 7, 2, nil, true, true, false)).toBe(false)
        expect(can(7, 7, 2, 2, false, true, false)).toBe(false)
        expect(can(7, 7, 2, 2, true, false, false)).toBe(false)
        expect(can(7, 7, 2, 2, true, true, true)).toBe(false)
    end)

    it("always gives final rush the highest climax stage", function()
        expect(DisasterClimax.stageFor(0.88, true, false)).toBe(3)
        expect(DisasterClimax.stageFor(1.12, true, true)).toBe(3)
    end)
end)

describe("Distinct frost and electric climax silhouettes", function()
    it("offers different geometric recipes without opaque circular discs", function()
        for _, kind in ipairs({"freeze", "shock"}) do
            for _, stage in ipairs({1, 2, 3}) do
                for _, tier in ipairs({"Low", "Medium", "High"}) do
                    local count = Signature.count(tier, false)
                    expect(count == 2 or count == 4 or count == 6).toBe(true)
                    for index = 1, count do
                        local recipe = Signature.recipe(kind, index, count, 140, stage)
                        expect(recipe ~= nil).toBe(true)
                        expect(recipe.Kind).toBe(kind)
                        expect(recipe.Wedge).toBe(kind == "freeze")
                        expect(recipe.Material).toBe(kind == "freeze"
                            and Enum.Material.Ice or Enum.Material.Neon)
                        expect(recipe.Size.X > 0 and recipe.Size.Y < 0.20).toBe(true)
                        expect(recipe.GoalSize.X > 0 and recipe.GoalSize.Y < 0.20).toBe(true)
                        expect(recipe.Start.Magnitude < recipe.Finish.Magnitude).toBe(true)
                        expect(recipe.Transparency >= 0.25).toBe(true)
                    end
                end
            end
        end
        expect(Signature.count("Low", true)).toBe(2)
        expect(Signature.count("High", true)).toBe(2)
        expect(Signature.count("Invalid", false)).toBe(0)
        expect(Signature.recipe("unknown", 1, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 0, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 5, 4, 100, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 1, 4, 0, 1) == nil).toBe(true)
        expect(Signature.recipe("freeze", 1, 4, 100, 0) == nil).toBe(true)
    end)

    it("keeps the fragments anchored to the local pitched deck in Roblox", function()
        local root = Instance.new("Folder")
        local deck = CFrame.new(24, 14, -18)
            * CFrame.Angles(math.rad(18), math.rad(45), math.rad(-11))
        local primary = Color3.fromRGB(90, 190, 255)
        local secondary = Color3.fromRGB(205, 245, 255)
        for _, kind in ipairs({"freeze", "shock"}) do
            for _, quality in ipairs({"Low", "Medium", "High"}) do
                local result = Signature.emit(root, kind, deck, 100, 2,
                    primary, secondary, quality, false)
                expect(#result).toBe(Signature.count(quality, false))
                for index, part in ipairs(result) do
                    expect(part:IsA(kind == "freeze" and "WedgePart" or "Part"))
                        .toBe(true)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part:GetAttribute("ChaosClimaxSignature")).toBe(kind)
                    if part:IsA("Part") then
                        expect(part.Shape == Enum.PartType.Cylinder).toBe(false)
                    end
                    local localPosition = deck:PointToObjectSpace(part.Position)
                    expect(math.abs(localPosition.Y - (kind == "freeze" and 0.20 or 0.15))
                        < 0.10).toBe(true)
                    expect(part.Color).toBe(index % 2 == 0 and secondary or primary)
                    part:Destroy()
                end
            end
            local quiet = Signature.emit(root, kind, deck, 100, 3,
                primary, secondary, "High", true)
            expect(#quiet).toBe(2)
            for _, part in ipairs(quiet) do
                part:Destroy()
            end
        end
        expect(#root:GetChildren()).toBe(0)
        expect(#Signature.emit(root, "invalid", deck, 100, 2,
            primary, secondary, "High", false)).toBe(0)
        expect(#Signature.emit(root, "freeze", nil, 100, 2,
            primary, secondary, "High", false)).toBe(0)
        root:Destroy()
    end)
end)

describe("Rectangular shrink and directional bomb climax", function()
    it("uses deterministic, different shapes with limited Android budgets", function()
        local deckSize = Vector3.new(132, 3, 74)
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local count = Boundary.count(tier, false)
            expect(count).toBe(tier == "Low" and 2
                or (tier == "Medium" and 4 or 6))
            for _, kind in ipairs({"blast", "shrink"}) do
                for _, stage in ipairs({1, 2, 3}) do
                    for i = 1, count do
                        local recipe = Boundary.recipe(kind, i, count, deckSize, stage)
                        local again = Boundary.recipe(kind, i, count, deckSize, stage)
                        expect(recipe ~= nil).toBe(true)
                        expect(recipe.Start).toBe(again.Start)
                        expect(recipe.Finish).toBe(again.Finish)
                        expect(recipe.Rotation).toBe(again.Rotation)
                        expect(recipe.Size.X > 0 and recipe.Size.Y <= 0.12).toBe(true)
                        expect(recipe.GoalSize.X > 0).toBe(true)
                        expect(recipe.Alpha >= 0.25 and recipe.Alpha <= 0.40).toBe(true)
                        expect(recipe.Material).toBe(kind == "blast"
                            and Enum.Material.Metal or Enum.Material.Glass)
                        expect(recipe.Label).toBe(kind == "blast"
                            and "BlastFin" or "ClosingEdge")
                        if kind == "blast" then
                            expect(recipe.Finish.Magnitude > recipe.Start.Magnitude)
                                .toBe(true)
                        else
                            expect(Vector2.new(recipe.Finish.X, recipe.Finish.Z).Magnitude
                                < Vector2.new(recipe.Start.X, recipe.Start.Z).Magnitude)
                                .toBe(true)
                            expect(recipe.Wedge).toBe(false)
                        end
                    end
                end
            end
        end
        expect(Boundary.count("High", true)).toBe(2)
        expect(Boundary.count("Medium", true)).toBe(2)
        expect(Boundary.count("invalid", false)).toBe(0)
        expect(Boundary.recipe("invalid", 1, 4, deckSize, 2) == nil).toBe(true)
        expect(Boundary.recipe("blast", 0, 4, deckSize, 2) == nil).toBe(true)
        expect(Boundary.recipe("shrink", 7, 6, deckSize, 2) == nil).toBe(true)
        expect(Boundary.recipe("shrink", 1, 4, deckSize, 0) == nil).toBe(true)
        expect(Boundary.recipe("shrink", 1, 4, Vector3.zero, 2) == nil).toBe(true)
    end)

    it("preserves sloped ground orientation, nonphysical pieces and reduced motion", function()
        local parent = Instance.new("Folder")
        local deck = CFrame.new(18, 14, -42)
            * CFrame.Angles(math.rad(14), math.rad(37), math.rad(-12))
        local deckSize = Vector3.new(142, 2.5, 82)
        local primary = Color3.fromRGB(225, 80, 170)
        local secondary = Color3.fromRGB(250, 190, 125)
        for _, kind in ipairs({"blast", "shrink"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local count = Boundary.count(tier, false)
                local pieces = Boundary.emit(parent, kind, deck, deckSize, 3,
                    primary, secondary, tier, false)
                expect(#pieces).toBe(count)
                for index, part in ipairs(pieces) do
                    local recipe = Boundary.recipe(kind, index, count, deckSize, 3)
                    expect(part.Anchored).toBe(true)
                    expect(part.CanCollide).toBe(false)
                    expect(part.CanQuery).toBe(false)
                    expect(part.CanTouch).toBe(false)
                    expect(part.CastShadow).toBe(false)
                    expect(part:GetAttribute("ChaosClimaxBoundary")).toBe(kind)
                    expect(part:IsA(recipe.Wedge and "WedgePart" or "Part")).toBe(true)
                    local actual = deck:PointToObjectSpace(part.Position)
                    expect((actual - recipe.Start).Magnitude < 0.01).toBe(true)
                    expect(part.Color).toBe(index % 2 == 0 and secondary or primary)
                    part:Destroy()
                end
            end
            local quiet = Boundary.emit(parent, kind, deck, deckSize, 2,
                primary, secondary, "High", true)
            expect(#quiet).toBe(2)
            for index, part in ipairs(quiet) do
                local recipe = Boundary.recipe(kind, index, 2, deckSize, 2)
                expect((deck:PointToObjectSpace(part.Position) - recipe.Finish)
                    .Magnitude < 0.01).toBe(true)
                part:Destroy()
            end
        end
        expect(#parent:GetChildren()).toBe(0)
        expect(#Boundary.emit(parent, "invalid", deck, deckSize, 2,
            primary, secondary, "High", false)).toBe(0)
        expect(#Boundary.emit(parent, "blast", nil, deckSize, 2,
            primary, secondary, "High", false)).toBe(0)
        parent:Destroy()
    end)

    it("maps each rectangular side to inward positions including asymmetric decks", function()
        local size = Vector3.new(160, 3, 60)
        for stage = 1, 3 do
            local seenX, seenZ = false, false
            for index = 1, 4 do
                local r = Boundary.recipe("shrink", index, 4, size, stage)
                if math.abs(r.Start.X) > 10 then
                    seenX = true
                    expect(math.abs(r.Start.X) > math.abs(r.Finish.X)).toBe(true)
                elseif math.abs(r.Start.Z) > 10 then
                    seenZ = true
                    expect(math.abs(r.Start.Z) > math.abs(r.Finish.Z)).toBe(true)
                end
            end
            expect(seenX).toBe(true)
            expect(seenZ).toBe(true)
        end
    end)
end)

describe("Procedural volcanic and meteor climax sculpture", function()
    it("keeps each original 3D recipe deterministic, bounded and distinct", function()
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local count = Elements.count(tier, false)
            expect(count).toBe(tier == "Low" and 2 or
                (tier == "Medium" and 4 or 6))
            expect(Elements.count(tier, true)).toBe(1)
            for _, kind in ipairs({"lava", "meteor", "tornado"}) do
                for stage = 1, 3 do
                    for i = 1, count do
                        local s = Elements.recipe(kind, i, count, 120, stage, tier)
                        local again = Elements.recipe(kind, i, count, 120, stage, tier)
                        expect(s ~= nil).toBe(true)
                        expect(s.Start).toBe(again.Start)
                        expect(s.Finish).toBe(again.Finish)
                        expect(s.Rotation).toBe(again.Rotation)
                        expect(s.Size.X > 0 and s.Size.Y > 0 and s.Size.Z > 0)
                            .toBe(true)
                        expect(s.GoalSize.X > 0 and s.GoalSize.Y > 0
                            and s.GoalSize.Z > 0).toBe(true)
                        expect(s.Transparency >= 0.35).toBe(true)
                        if kind == "lava" then
                            expect(s.Finish.Y > s.Start.Y).toBe(true)
                            expect(s.Name).toBe("LavaClimaxVolcanicFin")
                        elseif kind == "meteor" then
                            expect(s.Finish.Y < s.Start.Y).toBe(true)
                            expect(s.Name).toBe("MeteorClimaxSpearhead")
                        else
                            expect(s.Finish.Y > s.Start.Y).toBe(true)
                            expect(s.Name).toBe("TornadoClimaxHelixFin")
                        end
                        if tier == "Low" then
                            expect(s.Material).toBe(Enum.Material.SmoothPlastic)
                        end
                    end
                end
            end
        end
        expect(Elements.count("Invalid", false)).toBe(0)
        expect(Elements.count("Invalid", true)).toBe(0)
        expect(Elements.recipe("unknown", 1, 4, 120, 2, "High") == nil).toBe(true)
        expect(Elements.recipe("lava", 0, 4, 120, 2, "High") == nil).toBe(true)
        expect(Elements.recipe("meteor", 7, 6, 120, 2, "High") == nil).toBe(true)
        expect(Elements.recipe("lava", 1, 4, 0, 2, "High") == nil).toBe(true)
        expect(Elements.recipe("meteor", 1, 4, 120, 4, "High") == nil).toBe(true)
        expect(Elements.recipe("lava", 1, 4, 120, 2, "Invalid") == nil).toBe(true)
        expect(Elements.recipe("tornado", 1, 4, 120, 2, "Invalid") == nil).toBe(true)
        expect(Elements.recipe("tornado", 2.5, 4, 120, 2, "High") == nil).toBe(true)
    end)

    it("anchors one-shot wedges to pitched decks and respects ReduceMotion", function()
        local folder = Instance.new("Folder")
        local deck = CFrame.new(19, 7, -12)
            * CFrame.Angles(math.rad(13), math.rad(37), math.rad(-8))
        local primary = Color3.fromRGB(255, 87, 40)
        local secondary = Color3.fromRGB(255, 209, 110)
        for _, kind in ipairs({"lava", "meteor", "tornado"}) do
            for _, tier in ipairs({"Low", "Medium", "High"}) do
                local count = Elements.count(tier, false)
                local pieces = Elements.emit(folder, kind, deck,
                    134, 3, primary, secondary, tier, false)
                expect(#pieces).toBe(count)
                for i, piece in ipairs(pieces) do
                    local spec = Elements.recipe(kind, i, count, 134, 3, tier)
                    expect(piece:IsA("WedgePart")).toBe(true)
                    expect(piece.Anchored).toBe(true)
                    expect(piece.CanCollide).toBe(false)
                    expect(piece.CanTouch).toBe(false)
                    expect(piece.CanQuery).toBe(false)
                    expect(piece.CastShadow).toBe(false)
                    expect(piece.Material).toBe(spec.Material)
                    expect(piece:GetAttribute("ChaosClimaxElement")).toBe(kind)
                    expect((deck:PointToObjectSpace(piece.Position) - spec.Start)
                        .Magnitude < 0.02).toBe(true)
                    piece:Destroy()
                end
            end
            local quiet = Elements.emit(folder, kind, deck,
                134, 2, primary, secondary, "High", true)
            expect(#quiet).toBe(1)
            local final = Elements.recipe(kind, 1, 1, 134, 2, "High")
            expect((deck:PointToObjectSpace(quiet[1].Position) - final.Finish)
                .Magnitude < 0.02).toBe(true)
            quiet[1]:Destroy()
        end
        expect(#folder:GetChildren()).toBe(0)
        expect(#Elements.emit(folder, "invalid", deck, 134, 3,
            primary, secondary, "High", false)).toBe(0)
        folder:Destroy()
    end)
end)

return nil
