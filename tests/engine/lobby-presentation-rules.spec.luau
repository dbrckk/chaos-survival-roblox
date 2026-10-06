--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local LobbyPresentationRules = require("../../src/shared/LobbyPresentationRules")

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

    it("exposes semantic status tokens for localized clients", function()
        local vote = LobbyPresentationRules.statusPresentation(
            "intermission",
            6,
            "VOTE FOR THE NEXT CHAOS",
            {{id = "Meteors"}}
        )
        expect(vote.mode).toBe("vote")
        expect(vote.titleKey).toBe("LOBBY_VOTE_NOW")
        expect(vote.subtitleText).toBe("6s")

        local waiting = LobbyPresentationRules.statusPresentation(
            "waiting",
            0,
            "WAITING FOR PLAYERS",
            nil
        )
        expect(waiting.titleKey).toBe("LOBBY_OPEN")
        expect(waiting.subtitleKey).toBe("LOBBY_PRACTICE_JOIN")
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

return nil
