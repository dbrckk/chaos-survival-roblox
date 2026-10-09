--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local LobbyPresentationRules = require("../../src/shared/LobbyPresentationRules")
local LobbyGateCueKit = require("../../src/client/LobbyGateCueKit")
local VisualTheme = require("../../src/shared/VisualTheme")

describe("Lobby presentation rules", function()
    it("detects voting from intermission vote options", function()
        expect(LobbyPresentationRules.mode("intermission", {
            {id = "Meteors"},
            {id = "Freeze"},
        })).toBe("vote")
        expect(LobbyPresentationRules.mode("intermission", nil)).toBe("social")
    end)

    it("prioritizes the correct lobby zone by phase", function()
        local vote = LobbyPresentationRules.emphasis("intermission", {{id = "Bombs"}})
        local launch = LobbyPresentationRules.emphasis("ready", nil)
        local social = LobbyPresentationRules.emphasis("intermission", nil)

        expect(vote.Center > vote.Practice).toBe(true)
        expect(launch.Runway > launch.Center).toBe(true)
        expect(social.Practice > social.Runway).toBe(true)
        expect(social.Social > vote.Social).toBe(true)
    end)

    it("provides contextual status copy", function()
        local voteTitle, voteSub = LobbyPresentationRules.statusText(
            "intermission",
            6,
            "VOTE FOR THE NEXT CHAOS",
            {{id = "Meteors"}}
        )
        expect(voteTitle).toBe("VOTE NOW")
        expect(voteSub).toBe("6s")

        local readyTitle, readySub = LobbyPresentationRules.statusText(
            "ready",
            3,
            "CHAOS FUSION: Storm Core",
            nil
        )
        expect(readyTitle).toBe("ENTERING ARENA")
        expect(readySub).toBe("Storm Core")
    end)

    it("uses a waiting-specific lobby message", function()
        local title, subtitle = LobbyPresentationRules.statusText(
            "waiting",
            0,
            "WAITING FOR PLAYERS",
            nil
        )
        expect(title).toBe("LOBBY OPEN")
        expect(subtitle).toBe("PRACTICE WHILE PLAYERS JOIN")
    end)

    it("keeps the arena gate actionable through the full lobby flow", function()
        local waitingTitle, waitingSub = LobbyPresentationRules.gateText(
            "waiting",
            0,
            "WAITING FOR PLAYERS",
            nil
        )
        expect(waitingTitle).toBe("TRAIN HERE")
        expect(waitingSub).toBe("MOVE • JUMP • WATCH THE GATE")

        local voteTitle, voteSub = LobbyPresentationRules.gateText(
            "intermission",
            7,
            "VOTE FOR THE NEXT CHAOS",
            {{id = "Meteors"}}
        )
        expect(voteTitle).toBe("VOTE NOW")
        expect(string.find(voteSub, "7s", 1, true) ~= nil).toBe(true)

        local readyTitle, readySub = LobbyPresentationRules.gateText(
            "ready",
            3,
            "CHAOS FUSION: Storm Core",
            nil
        )
        expect(readyTitle).toBe("ARENA READY")
        expect(string.find(readySub, "Storm Core", 1, true) ~= nil).toBe(true)
        expect(string.find(readySub, "3s", 1, true) ~= nil).toBe(true)

        local roundTitle, roundSub = LobbyPresentationRules.gateText(
            "round",
            12,
            "SURVIVE",
            nil
        )
        expect(roundTitle).toBe("ROUND LIVE")
        expect(roundSub).toBe("SURVIVE UNTIL 0")
    end)

    it("slows ambient pulses for accessibility", function()
        local normal = LobbyPresentationRules.pulseCadence("High", false, "launch")
        local reduced = LobbyPresentationRules.pulseCadence("High", true, "launch")
        expect(reduced > normal).toBe(true)
    end)

    it("increases decoration budget by quality tier", function()
        expect(LobbyPresentationRules.decorBudget("Low")
            < LobbyPresentationRules.decorBudget("Medium")).toBe(true)
        expect(LobbyPresentationRules.decorBudget("Medium")
            < LobbyPresentationRules.decorBudget("High")).toBe(true)
    end)
end)


describe("Premium lobby gate transition cues", function()
    it("builds safe decorative wings and route arrows for each graphics tier", function()
        local gate = Instance.new("Part")
        gate.Size = Vector3.new(23, 3, 3)
        gate.CFrame = CFrame.new(3, 12, 21) * CFrame.Angles(0, math.rad(31), 0)
        local runway = Instance.new("Part")
        runway.Size = Vector3.new(14, 0.1, 29)
        runway.CFrame = CFrame.new(3, 1, 12) * CFrame.Angles(0, math.rad(31), 0)
        local container = Instance.new("Folder")
        local counts = {Low = 2, Medium = 4, High = 6}
        local names = {}
        for _, tier in ipairs({"Low", "Medium", "High"}) do
            local kit = LobbyGateCueKit.build(
                container, gate, runway, tier, VisualTheme.Accents
            )
            expect(#kit.pieces).toBe(counts[tier])
            for _, entry in ipairs(kit.pieces) do
                local p = entry.part
                expect(p:IsA("BasePart")).toBe(true)
                expect(p:GetAttribute("ChaosLobbyGateCue")).toBe(true)
                expect(p.Anchored).toBe(true)
                expect(p.CanCollide).toBe(false)
                expect(p.CanTouch).toBe(false)
                expect(p.CanQuery).toBe(false)
                expect(p.CastShadow).toBe(false)
                expect(p.Material == Enum.Material.Neon).toBe(false)
                names[p.Name] = true
            end
            LobbyGateCueKit.apply(kit, "launch", VisualTheme.Accents, true)
            for _, entry in ipairs(kit.pieces) do
                expect(entry.part.Transparency < 0.30).toBe(true)
                expect(entry.part.Color).toBe(VisualTheme.Accents.Gold)
            end
            LobbyGateCueKit.apply(kit, "vote", VisualTheme.Accents, true)
            expect(kit.mode).toBe("vote")
            expect(kit.pieces[1].part.Color).toBe(VisualTheme.Accents.Magenta)
            LobbyGateCueKit.apply(kit, "inactive", VisualTheme.Accents, true)
            for _, entry in ipairs(kit.pieces) do
                expect(entry.part.Transparency).toBe(1)
                entry.part:Destroy()
            end
        end
        expect(names.GateVectorFinL).toBe(true)
        expect(names.RunwayArrowForwardR).toBe(true)
        expect(names.RunwayApproachMarkerR).toBe(true)
        expect(#container:GetChildren()).toBe(0)
        gate:Destroy()
        runway:Destroy()
        container:Destroy()
    end)

    it("refuses invalid lobby anchor and profile inputs", function()
        local container = Instance.new("Folder")
        local anchor = Instance.new("Part")
        local accent = VisualTheme.Accents
        expect(#LobbyGateCueKit.build(nil, anchor, anchor, "High", accent).pieces).toBe(0)
        expect(#LobbyGateCueKit.build(container, nil, anchor, "High", accent).pieces).toBe(0)
        expect(#LobbyGateCueKit.build(container, anchor, nil, "High", accent).pieces).toBe(0)
        expect(#LobbyGateCueKit.build(container, anchor, anchor, "Unknown", accent).pieces).toBe(0)
        expect(#LobbyGateCueKit.build(container, anchor, anchor, "High", nil).pieces).toBe(0)
        expect(#container:GetChildren()).toBe(0)
        anchor:Destroy()
        container:Destroy()
    end)
end)

return nil
