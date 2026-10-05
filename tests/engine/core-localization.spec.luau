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
        expect(CoreLocalization.text("fr-fr", "INVITE_FRIENDS")).toBe("INVITER DES AMIS")
        expect(CoreLocalization.text("fr-fr", "BRING_BACKUP")).toBe("APPELLE DU RENFORT")
        expect(CoreLocalization.text("fr-fr", "LAST_CHAOS")).toBe("DERNIER CHAOS")
        expect(CoreLocalization.text("fr-fr", "SURVIVED_COUNT", 2, 4)).toBe("2 / 4 ONT SURVÉCU")
        expect(CoreLocalization.text("fr-fr", "FRIEND_JOINED_CREW", "Nova")).toBe("Nova A REJOINT TON ÉQUIPE")
        expect(CoreLocalization.text("fr-fr", "SOCIAL_REACTION_AGAIN")).toBe("ENCORE !")
        expect(CoreLocalization.text("fr-fr", "SOCIAL_REACTION_WOW")).toBe("INCROYABLE !")
        expect(CoreLocalization.text("fr-fr", "RESULT_SURVIVOR_COUNT", 3)).toBe("3 SURVIVANTS")
        expect(CoreLocalization.text("fr-fr", "RESULT_SOLE_SURVIVOR")).toBe("DERNIER SURVIVANT")
        expect(CoreLocalization.text("fr-fr", "YOU_SURVIVED")).toBe("TU AS SURVÉCU")
        expect(CoreLocalization.text("fr-fr", "ELIMINATED_FEED", "Nova")).toBe("Nova a été éliminé")
        expect(CoreLocalization.text("fr-fr", "RESULT_STREAK_TAG", 3)).toBe("SÉRIE x3")
        expect(CoreLocalization.text("fr-fr", "RESULT_NEXT_GOAL", 5, 120)).toBe(
            "PROCHAIN OBJECTIF • NIVEAU 5 • 120 XP RESTANTS"
        )
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

    it("localizes device controls and compact settings", function()
        expect(CoreLocalization.text("fr-fr", "SETTINGS")).toBe("RÉGLAGES")
        expect(
            CoreLocalization.text("fr-fr", "KEYBOARD_CONTROLS")
        ).toBe("WASD = BOUGER  •  ESPACE = SAUTER  •  SURVIS JUSQU'À 0")
        expect(
            CoreLocalization.text("en-us", "GAMEPAD_CONTROLS")
        ).toBe("LEFT STICK = MOVE  •  A = JUMP  •  SURVIVE UNTIL 0")
    end)

    it("localizes progression content by stable ids", function()
        expect(CoreLocalization.questTitle("fr-fr", "PLAY_3", "fallback")).toBe("Joue 3 manches")
        expect(CoreLocalization.questTitle("fr-fr", "DOUBLE_3", "fallback")).toBe(
            "Survis à 3 manches Double Chaos"
        )
        expect(
            CoreLocalization.achievementTitle("fr-fr", "FIRST_SURVIVOR", "fallback")
        ).toBe("Premier survivant")
        expect(
            CoreLocalization.achievementDescription("fr-fr", "LEVEL_5", "fallback")
        ).toBe("Atteins le niveau 5")
        expect(CoreLocalization.text("fr-fr", "DAY_STREAK", 7)).toBe("SÉRIE DE 7 JOURS")
        expect(CoreLocalization.text("fr-fr", "PRACTICE_BOOST")).toBe("ESSAIE LE BOOST")
        expect(CoreLocalization.text("fr-fr", "ESCAPE_PAD")).toBe("PAD D'ÉVASION")
        expect(CoreLocalization.text("fr-fr", "WAYFIND_ARENA")).toBe("ARÈNE")
        expect(CoreLocalization.text("fr-fr", "WAYFIND_PRACTICE")).toBe("ENTRAÎNEMENT")
        expect(CoreLocalization.arenaName("fr-fr", "Classic", "fallback")).toBe("GRILLE CLASSIQUE")
        expect(CoreLocalization.arenaStrategy("fr-fr", "Towers", "fallback")).toBe(
            "Arène verticale • prends de la hauteur sans te faire enfermer"
        )
        expect(CoreLocalization.arenaMechanicName("fr-fr", "Orbital", "fallback")).toBe(
            "BOOSTERS ORBITAUX"
        )
        expect(CoreLocalization.medal("fr-fr", "SHARD HUNTER")).toBe("CHASSEUR D'ÉCLATS")
        expect(CoreLocalization.medal("fr-fr", "UNKNOWN")).toBe("UNKNOWN")
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
