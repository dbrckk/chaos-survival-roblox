--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local CoreLocalization = require("../../src/shared/CoreLocalization")
local DisasterVisuals = require("../../src/shared/DisasterVisuals")

describe("Core localization", function()
    it("selects French and English from Roblox locale ids", function()
        expect(CoreLocalization.language("fr-fr")).toBe("fr")
        expect(CoreLocalization.language("fr-ca")).toBe("fr")
        expect(CoreLocalization.language("en-us")).toBe("en")
        expect(CoreLocalization.language("de-de")).toBe("en")
    end)

    it("keeps spectator wait guidance short and translated on Android", function()
        expect(CoreLocalization.text("en-us", "SPECTATOR_LATE_ACTIONS"))
            .toBe("TRAIN OR WATCH")
        expect(CoreLocalization.text("fr-fr", "SPECTATOR_LATE_ACTIONS"))
            .toBe("TESTE OU REGARDE")
        expect(CoreLocalization.text("en-us", "SPECTATOR_LATE_WATCH"))
            .toBe("WATCH")
        expect(CoreLocalization.text("fr-fr", "SPECTATOR_LATE_WATCH"))
            .toBe("REGARDE")
    end)

    it("localizes gravity landing and longer-jump transition prompts", function()
        expect(CoreLocalization.text("en-us", "GRAVITY_PULL_RISING"))
            .toBe("GRAVITY GETTING STRONGER")
        expect(CoreLocalization.text("fr-fr", "GRAVITY_PULL_RISING"))
            .toBe("LA GRAVITÉ AUGMENTE")
        expect(CoreLocalization.text("en-us", "GRAVITY_FLOAT_RETURNING_SUB"))
            .toBe("PREPARE FOR LONGER JUMPS")
        expect(CoreLocalization.text("fr-fr", "GRAVITY_FLOAT_RETURNING_SUB"))
            .toBe("PRÉPARE-TOI À SAUTER PLUS LOIN")
    end)

    it("localizes both speed rhythm transition prompts", function()
        expect(CoreLocalization.text("en-us", "SPEED_TEMPO_SURGE")).toBe("SPEED BURST")
        expect(CoreLocalization.text("fr-fr", "SPEED_TEMPO_RECOVER")).toBe("PHASE DE CONTRÔLE")
        expect(CoreLocalization.text("en-us", "SPEED_TEMPO_RECOVER_SUB"))
            .toBe("REPOSITION BEFORE THE NEXT BOOST")
        expect(CoreLocalization.text("fr-fr", "SPEED_TEMPO_SURGE_SUB"))
            .toBe("COURS VITE • ATTENTION AUX BORDS")
    end)

    it("localizes early warning, active surge and last climb", function()
        expect(CoreLocalization.text("fr-fr", "LAVA_SURGE_SOON"))
            .toBe("ACCÉLÉRATION DE LA LAVE")
        expect(CoreLocalization.text("fr-fr", "LAVA_SURGE_ACTIVE_SUB"))
            .toBe("GRIMPE VITE • GAGNE DE LA HAUTEUR")
        expect(CoreLocalization.text("en-us", "LAVA_FINAL_RISE"))
            .toBe("FINAL LAVA RISE")
        expect(CoreLocalization.text("en-us", "BLACKOUT_POWER_RETURN"))
            .toBe("POWER RETURN")
        expect(CoreLocalization.text("fr-fr", "BLACKOUT_POWER_RETURN_SUB"))
            .toBe("REPÈRE LES CHEMINS AVANT LE NOIR")
        expect(CoreLocalization.text("fr-fr", "BLACKOUT_LIGHTS_DIM"))
            .toBe("LES LUMIÈRES BAISSENT")
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
        expect(CoreLocalization.text("fr-fr", "CHAOS_PROFILE")).toBe("TON PROFIL CHAOS")
        expect(CoreLocalization.text("fr-fr", "PROFILE_STATS", 4, 9, 120)).toBe(
            "NIV 4  •  9 VICTOIRES  •  120 PIÈCES"
        )
        expect(CoreLocalization.text("fr-fr", "CHAOS_RUN")).toBe("TA COURSE CHAOS")
        expect(CoreLocalization.text("fr-fr", "RUN_LEVEL_READY", 5)).toBe("NIVEAU 5 PRÊT")
        expect(CoreLocalization.text("fr-fr", "RESULT_CREW_ROUNDS", 3)).toBe(
            "ÉQUIPE • 3 MANCHES ENSEMBLE"
        )
        expect(CoreLocalization.text("fr-fr", "CHAOS_FUSION_SUB")).toBe("SURVIS AUX DEUX DANGERS")
        expect(CoreLocalization.text("fr-fr", "SHARE_MOMENT")).toBe("PARTAGER CE MOMENT")
        expect(CoreLocalization.text("fr-fr", "SHARE_REASON_LAST_SURVIVOR")).toBe(
            "DERNIER SURVIVANT"
        )
        expect(CoreLocalization.text("fr-fr", "SHARE_JOINED", "Nova")).toBe(
            "Nova A REJOINT TON MOMENT PARTAGÉ"
        )
        expect(CoreLocalization.text("fr-fr", "POSITION_YOURSELF")).toBe("PLACE-TOI")
        expect(CoreLocalization.text("fr-fr", "JUICE_MASTER_SUB", 4)).toBe(
            "Défi terminé • Élan x4"
        )
        expect(CoreLocalization.text("fr-fr", "JUICE_UNSTOPPABLE", 5)).toBe("INARRÊTABLE x5")
        expect(CoreLocalization.text("fr-fr", "NEAR_MISS_TITLE")).toBe("C'ÉTAIT JUSTE !")
        expect(CoreLocalization.text("fr-fr", "NEAR_MISS_COMBO", 3)).toBe(
            "DE JUSTESSE  x3"
        )
        expect(CoreLocalization.text("fr-fr", "NEAR_MISS_EDGE", 0.8)).toBe("0.8x LIMITE")
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

    it("gives every hazard a complete actionable EN/FR contract", function()
        local hazardIds = {}
        for hazardId in pairs(DisasterVisuals.Profiles) do
            table.insert(hazardIds, hazardId)
        end
        table.sort(hazardIds)
        expect(#hazardIds).toBe(11)

        for _, localeId in ipairs({"en-us", "fr-fr"}) do
            for _, hazardId in ipairs(hazardIds) do
                local name = CoreLocalization.hazardName(localeId, hazardId)
                local action = CoreLocalization.hazardAction(localeId, hazardId)
                local hint = CoreLocalization.hazardHint(localeId, hazardId)

                expect(type(name)).toBe("string")
                expect(#name >= 3).toBe(true)
                expect(type(action)).toBe("string")
                expect(#action >= 2).toBe(true)
                expect(type(hint)).toBe("string")
                expect(#hint >= 8).toBe(true)
            end
        end
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
        expect(CoreLocalization.text("en-us", "HAPTICS_ON")).toBe("HAPTICS • ON")
        expect(CoreLocalization.text("fr-fr", "HAPTICS_OFF")).toBe("VIBRATIONS • COUPÉES")
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
        expect(CoreLocalization.text("fr-fr", "PRACTICE_BOOST_APPLIED"))
            .toBe("BOOST ACTIVÉ")
        expect(CoreLocalization.text("en-us", "PRACTICE_BOOST_APPLIED"))
            .toBe("BOOST ACTIVATED")
        expect(CoreLocalization.text("fr-ca", "PRACTICE_BOOST_APPLIED"))
            .toBe("BOOST ACTIVÉ")
        expect(CoreLocalization.text("fr-fr", "ESCAPE_PAD")).toBe("PAD D'ÉVASION")
        expect(CoreLocalization.text("fr-fr", "WAYFIND_ARENA")).toBe("ARÈNE")
        expect(CoreLocalization.text("fr-fr", "WAYFIND_PRACTICE")).toBe("ENTRAÎNEMENT")
        expect(CoreLocalization.arenaName("fr-fr", "Classic", "fallback")).toBe("GRILLE CLASSIQUE")
        expect(CoreLocalization.arenaStrategy("fr-fr", "Classic", "fallback")).toBe(
            "Quatre parcours ascendants • saute entre les plateformes basses et hautes"
        )
        expect(CoreLocalization.arenaStrategy("en-us", "Classic", "fallback")).toBe(
            "Four rising escape routes • jump between low, mid and high decks"
        )
        expect(CoreLocalization.arenaStrategy("fr-fr", "Towers", "fallback")).toBe(
            "Quatre voies montantes • rejoins les ponts depuis le centre"
        )
        expect(CoreLocalization.arenaStrategy("en-us", "Towers", "fallback")).toBe(
            "Four ascending routes • reach the bridges from the central hub"
        )
        expect(CoreLocalization.arenaMechanicHint("fr-fr", "Towers", "fallback")).toBe(
            "Monte les paliers indiqués ; les pads cyan aident à prendre de la hauteur"
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
    it("localizes every playable district and all physical navigation actions", function()
        local frSectors = {"OBSERVATOIRE", "DÉPÔT DE FRET", "CENTRALE", "ANTENNES"}
        local enSectors = {"OBSERVATORY", "CARGO DEPOT", "POWER PLANT", "COMMS ARRAY"}
        for sector = 1, 4 do
            expect(CoreLocalization.text("fr-fr", "DISTRICT_SECTOR_" .. sector))
                .toBe(frSectors[sector])
            expect(CoreLocalization.text("en-us", "DISTRICT_SECTOR_" .. sector))
                .toBe(enSectors[sector])
        end
        expect(CoreLocalization.text("en-us", "DISTRICT_SECTOR_SIGN", "01", "OBSERVATORY"))
            .toBe("SECTOR 01\nOBSERVATORY")
        expect(CoreLocalization.text("fr-fr", "DISTRICT_SECTOR_SIGN", "01", "OBSERVATOIRE"))
            .toBe("SECTEUR 01\nOBSERVATOIRE")

        local samples = {
            DISTRICT_NEXT_JUMP = {},
            DISTRICT_OPEN_CACHE = {},
            DISTRICT_CLIMB = {2, 8},
            DISTRICT_FAST_TRAVEL = {2},
            DISTRICT_NEXT_SIGNAL = {3},
            DISTRICT_NEXT_SIGNAL_GENERIC = {},
            DISTRICT_SECURE_SIGNAL = {},
            DISTRICT_HIGH_ROUTE = {},
            DISTRICT_SHORT_ROUTE = {},
            DISTRICT_SIGNAL_SOON = {},
            DISTRICT_SIGNAL_NOW = {},
            DISTRICT_SIGNAL_OPENS = {"12s", 4},
            DISTRICT_SIGNAL_ENDS = {"8s", 4},
            DISTRICT_CACHE_REWARD = {5},
            DISTRICT_LANDING_JUMP = {4, 8},
        }
        for key, args in pairs(samples) do
            local english = CoreLocalization.text("en-us", key, table.unpack(args))
            local french = CoreLocalization.text("fr-fr", key, table.unpack(args))
            expect(type(english)).toBe("string")
            expect(type(french)).toBe("string")
            -- NOW is deliberately three characters in English.
            expect(#english >= 3).toBe(true)
            expect(#french >= 3).toBe(true)
            expect(english ~= key).toBe(true)
            expect(french ~= key).toBe(true)
        end
        expect(CoreLocalization.text("fr-fr", "DISTRICT_CLIMB", 2, 8))
            .toBe("MONTE 2/8")
        expect(CoreLocalization.text("fr-fr", "DISTRICT_FAST_TRAVEL", 3))
            .toBe("TRANSPORT RAPIDE D3")
        expect(CoreLocalization.text("fr-fr", "DISTRICT_CACHE_REWARD", 5))
            .toBe("CAISSE +5 PIÈCES")
        expect(CoreLocalization.text("fr-fr", "DISTRICT_LANDING_JUMP", 2, 6))
            .toBe("SAUT 2/6")
    end)
end)

return nil
