--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CoreLocalization = require("../../src/shared/CoreLocalization")

describe("Core localization", function()
    it("selects French and English from Roblox locale ids", function()
        expect(CoreLocalization.language("fr-fr")).toBe("fr")
        expect(CoreLocalization.language("fr-ca")).toBe("fr")
        expect(CoreLocalization.language("en-us")).toBe("en")
        expect(CoreLocalization.language("de-de")).toBe("en")
    end)

    it("formats core interaction copy", function()
        expect(CoreLocalization.text("en-us", "VOTE_SAVED")).toBe("VOTE SAVED")
        expect(CoreLocalization.text("fr-fr", "VOTE_SAVED")).toBe("VOTE ENREGISTRÉ")
        expect(CoreLocalization.text("en-us", "ALIVE_SHORT", 3)).toBe("3 ALIVE")
        expect(CoreLocalization.text("fr-fr", "ALIVE_SHORT", 3)).toBe("3 EN VIE")
        expect(CoreLocalization.text("fr-fr", "NEXT")).toBe("SUIVANT")
    end)

    it("localizes hazard names and actionable hints", function()
        expect(CoreLocalization.hazardName("en-us", "Meteors")).toBe("METEOR SHOWER")
        expect(CoreLocalization.hazardName("fr-fr", "Meteors")).toBe("PLUIE DE MÉTÉORES")
        expect(CoreLocalization.hazardAction("en-us", "Meteors")).toBe("DODGE")
        expect(CoreLocalization.hazardAction("fr-fr", "Meteors")).toBe("ESQUIVE")
        expect(
            string.find(
                CoreLocalization.hazardHint("fr-fr", "Bombs") or "",
                "ROUGES",
                1,
                true
            ) ~= nil
        ).toBe(true)
    end)

    it("localizes critical round actions and challenge labels", function()
        expect(CoreLocalization.text("fr-fr", "MOVE_CENTER")).toBe("REJOINS LE CENTRE")
        expect(CoreLocalization.text("fr-fr", "FINAL_RUSH")).toBe("SPRINT FINAL")
        expect(CoreLocalization.text("fr-fr", "OVERDRIVE")).toBe("SURCHARGE")
        expect(CoreLocalization.text("fr-fr", "SURVIVE_SECONDS", 5)).toBe("SURVIS  5s")
        expect(CoreLocalization.challengeShort("fr-fr", "SHARD_HUNT", "SHARDS")).toBe("ÉCLATS")
        expect(CoreLocalization.challengeShort("en-us", "DANGER_DANCE", "CLOSE CALL")).toBe("CLOSE CALL")
    end)

    it("localizes accessibility and save-status feedback", function()
        expect(CoreLocalization.text("en-us", "SOUND_ON")).toBe("SOUND • ON")
        expect(CoreLocalization.text("fr-fr", "SOUND_OFF")).toBe("SON • COUPÉ")
        expect(CoreLocalization.text("fr-fr", "TEMP_SESSION_TITLE")).toBe("SESSION TEMPORAIRE")
        expect(CoreLocalization.text("en-us", "SAVE_PAUSED_SHORT")).toBe("PROGRESS NOT SAVING")
    end)

    it("localizes first-time coaching without altering unknown copy", function()
        local source = "VOTE  •  TAP THE CHAOS YOU WANT TO FACE"
        expect(CoreLocalization.coach("fr-fr", source)).toBe(
            "VOTE  •  TOUCHE LE CHAOS QUE TU VEUX AFFRONTER"
        )
        expect(CoreLocalization.coach("en-us", source)).toBe(source)
        expect(CoreLocalization.coach("fr-fr", "CUSTOM")).toBe("CUSTOM")
    end)
end)

return nil
