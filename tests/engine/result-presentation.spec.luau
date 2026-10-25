--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local ResultPresentation = require("../../src/shared/ResultPresentation")
local CoreLocalization = require("../../src/shared/CoreLocalization")
local RoundJourneyRules = require("../../src/shared/RoundJourneyRules")
local RoundResultState = require("../../src/server/RoundResultState")

describe("Result presentation", function()
    it("shows a verified prior round in the lobby despite delayed player data", function()
        local show = ResultPresentation.showLobbyRecap
        local recap = {roundNumber = 12, disasterIds = {"Meteors"}}
        expect(show("intermission", recap)).toBe(true)
        expect(show("waiting", recap)).toBe(true)
        expect(show("result", recap)).toBe(false)
        expect(show("ready", recap)).toBe(false)
        expect(show("round", recap)).toBe(false)
        expect(show("intermission", nil)).toBe(false)
        expect(show("intermission", {})).toBe(false)
        expect(show("intermission", {
            roundNumber = 12, disasterIds = {},
        })).toBe(false)
        expect(show("waiting", {
            roundNumber = math.huge, disasterIds = {"Meteors"},
        })).toBe(false)
        expect(show("waiting", {
            roundNumber = 0 / 0, disasterIds = {"Meteors"},
        })).toBe(false)
    end)

    it("announces surviving humans and bots before rewards are settled", function()
        local participants = {101, 202}
        local survivors = {101}
        local snapshot = RoundResultState.snapshot({
            roundNumber = 17,
            seconds = 6,
            participantUserIds = participants,
            survivorUserIds = survivors,
            aiSurvivorsAlive = 2,
            contestantCount = 5,
            doubleChaos = true,
            fusionName = "STORMFIRE",
            soloMode = false,
            arenaId = "Orbital",
            arenaName = "ORBITAL RING",
            disasterIds = {"Meteors", "RisingLava"},
        })
        expect(snapshot.phase).toBe("result")
        expect(snapshot.title).toBe("3 SURVIVED")
        expect(snapshot.survivorsAlive).toBe(3)
        expect(snapshot.contestantCount).toBe(5)
        expect(snapshot.seconds).toBe(6)
        expect(snapshot.doubleChaos).toBe(true)
        expect(snapshot.soleSurvivorUserId).toBe(nil)
        local won = ResultPresentation.fallbackFeedback(snapshot, 101, false)
        expect(won.survived).toBe(true)
        expect(won.pendingRewards).toBe(true)
        expect(won.coins == nil).toBe(true)
        local lost = ResultPresentation.fallbackFeedback(snapshot, 202, false)
        expect(lost.survived).toBe(false)
        expect(lost.spectating).toBe(false)
        local audience = ResultPresentation.fallbackFeedback(snapshot, 303, true)
        expect(audience.spectating).toBe(true)

        local tick = RoundResultState.atSecond(snapshot, 2)
        expect(tick.seconds).toBe(2)
        expect(snapshot.seconds).toBe(6)
        expect(tick.survivorUserIds[1]).toBe(survivors[1])
        expect(tick.participantUserIds[1]).toBe(participants[1])
        expect(tick.survivorUserIds == survivors).toBe(false)
        expect(tick.participantUserIds == participants).toBe(false)
        expect(tick.title).toBe(snapshot.title)
    end)

    it("keeps frozen victory, disaster and roster evidence across countdown packets", function()
        local participants = {101, 202}
        local survivors = {101}
        local disasters = {"Meteors", "Bombs"}
        local state = RoundResultState.snapshot({
            roundNumber = 21,
            seconds = 5,
            participantUserIds = participants,
            survivorUserIds = survivors,
            disasterIds = disasters,
            aiSurvivorsAlive = 0,
            contestantCount = 2,
        })
        expect(state.soleSurvivorUserId).toBe(101)
        expect(state.title).toBe("1 SURVIVED")

        -- Progression, analytics and later round setup may change their
        -- scratch arrays after the result has already been announced.
        participants[1] = 303
        table.insert(participants, 404)
        survivors[1] = 202
        table.clear(disasters)
        expect(#state.participantUserIds).toBe(2)
        expect(state.participantUserIds[1]).toBe(101)
        expect(state.survivorUserIds[1]).toBe(101)
        expect(state.disasterIds[1]).toBe("Meteors")
        expect(state.disasterIds[2]).toBe("Bombs")

        local firstTick = RoundResultState.atSecond(state, 3)
        firstTick.participantUserIds[1] = 999
        table.clear(firstTick.survivorUserIds)
        firstTick.disasterIds[1] = "RisingLava"
        local secondTick = RoundResultState.atSecond(state, 2)
        expect(secondTick.participantUserIds[1]).toBe(101)
        expect(secondTick.survivorUserIds[1]).toBe(101)
        expect(secondTick.disasterIds[1]).toBe("Meteors")
        expect(state.participantUserIds[1]).toBe(101)
        expect(state.survivorUserIds[1]).toBe(101)
        expect(state.disasterIds[1]).toBe("Meteors")
        expect(firstTick.seconds).toBe(3)
        expect(secondTick.seconds).toBe(2)
        expect(ResultPresentation.fallbackFeedback(secondTick, 101, false).survived)
            .toBe(true)
        expect(ResultPresentation.fallbackFeedback(secondTick, 202, false).survived)
            .toBe(false)
    end)

    it("never tells players a wipeout is a win or overcounts bots", function()
        local empty = RoundResultState.snapshot({
            roundNumber = 18,
            participantUserIds = {101, 202},
            survivorUserIds = {},
            aiSurvivorsAlive = 0,
            contestantCount = 2,
            seconds = 8,
        })
        expect(empty.title).toBe("TOTAL WIPEOUT")
        expect(empty.survivorsAlive).toBe(0)
        expect(ResultPresentation.fallbackFeedback(empty, 101, true).survived)
            .toBe(false)
        local bots = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            contestantCount = 3,
        })
        expect(bots.title).toBe("1 SURVIVED")
        expect(ResultPresentation.fallbackFeedback(bots, 101, false).survived)
            .toBe(false)
        expect(RoundResultState.atSecond(bots, -2).seconds).toBe(0)
        expect(bots.soleSurvivorUserId).toBe(nil)

        -- The champion label requires genuine competition and exactly
        -- one surviving human, with no surviving AI opponents.
        local last = RoundResultState.snapshot({
            roundNumber = 19,
            participantUserIds = {101, 202},
            survivorUserIds = {101},
            aiSurvivorsAlive = 0,
            contestantCount = 4,
        })
        expect(last.soleSurvivorUserId).toBe(101)
        local champion = ResultPresentation.fallbackFeedback(last, 101, false)
        expect(champion.soleSurvivor).toBe(true)
        expect(ResultPresentation.title(champion, "fr-fr")).toBe("DERNIER SURVIVANT !")
        expect(ResultPresentation.title(champion, "en-us")).toBe("LAST SURVIVOR!")
        expect(ResultPresentation.worldLabel(champion, true)).toBe("LAST SURVIVOR")
        local championKey = ResultPresentation.spotlightLabelKey(true, true)
        expect(championKey).toBe("RESULT_SOLE_SURVIVOR")
        expect(ResultPresentation.spotlightLabelKey(true, false)).toBe(championKey)
        expect(CoreLocalization.text("fr-fr", championKey))
            .toBe("DERNIER SURVIVANT")
        expect(CoreLocalization.text("en-us", championKey))
            .toBe("LAST SURVIVOR")
        expect(ResultPresentation.spotlightLabelKey(false, true))
            .toBe("YOU_SURVIVED")
        expect(ResultPresentation.spotlightLabelKey(false, false))
            .toBe("SURVIVOR_LABEL")
        expect(ResultPresentation.fallbackFeedback(last, 202, true).soleSurvivor)
            .toBe(false)

        local unopposed = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {101},
            aiSurvivorsAlive = 0,
            contestantCount = 1,
        })
        expect(unopposed.soleSurvivorUserId).toBe(nil)
        local unopposedFeedback = ResultPresentation.fallbackFeedback(
            unopposed, 101, true
        )
        expect(unopposedFeedback.soleSurvivor).toBe(false)
        expect(ResultPresentation.spotlightLabelKey(
            unopposedFeedback.soleSurvivor, true
        )).toBe("YOU_SURVIVED")
    end)

    it("crowns only the actual last surviving AI in a competitive round", function()
        local context = {
            roundNumber = 27,
            participantUserIds = {101},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            soleAliveAISlot = 2,
            contestantCount = 4,
        }
        local aiChampion = RoundResultState.snapshot(context)
        expect(aiChampion.survivorsAlive).toBe(1)
        expect(aiChampion.soleSurvivorAISlot).toBe(2)
        expect(aiChampion.soleSurvivorUserId).toBe(nil)
        local tick = RoundResultState.atSecond(aiChampion, 3)
        expect(tick.soleSurvivorAISlot).toBe(2)
        expect(ResultPresentation.spotlightLabelKey(
            tick.soleSurvivorAISlot == 2, false
        )).toBe("RESULT_SOLE_SURVIVOR")
        expect(ResultPresentation.fallbackFeedback(aiChampion, 101, false).survived)
            .toBe(false)

        -- One human plus one living AI is not a champion result.
        local tied = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {101},
            aiSurvivorsAlive = 1,
            soleAliveAISlot = 2,
            contestantCount = 2,
        })
        expect(tied.soleSurvivorAISlot).toBe(nil)
        expect(tied.soleSurvivorUserId).toBe(nil)
        local unopposed = RoundResultState.snapshot({
            participantUserIds = {},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            soleAliveAISlot = 2,
            contestantCount = 1,
        })
        expect(unopposed.soleSurvivorAISlot).toBe(nil)
        local lostMetadata = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            contestantCount = 4,
        })
        expect(lostMetadata.soleSurvivorAISlot).toBe(nil)
        local malformed = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            soleAliveAISlot = math.huge,
            contestantCount = 4,
        })
        expect(malformed.soleSurvivorAISlot).toBe(nil)
        local impossibleSlot = RoundResultState.snapshot({
            participantUserIds = {101},
            survivorUserIds = {},
            aiSurvivorsAlive = 1,
            soleAliveAISlot = 9,
            contestantCount = 4,
        })
        expect(impossibleSlot.soleSurvivorAISlot).toBe(nil)
        local humanChampion = RoundResultState.snapshot({
            participantUserIds = {101, 202},
            survivorUserIds = {202},
            aiSurvivorsAlive = 0,
            soleAliveAISlot = 2,
            contestantCount = 3,
        })
        expect(humanChampion.soleSurvivorUserId).toBe(202)
        expect(humanChampion.soleSurvivorAISlot).toBe(nil)
    end)

    it("requires a new authoritative READY after a finished win to certify replay", function()
        local replay = RoundJourneyRules.replayStarted
        expect(replay(7, {phase = "ready", roundNumber = 8})).toBe(true)
        expect(replay(7, {phase = "intermission", roundNumber = 8})).toBe(false)
        expect(replay(7, {phase = "round", roundNumber = 8})).toBe(false)
        expect(replay(7, {phase = "result", roundNumber = 7})).toBe(false)
        expect(replay(7, {phase = "ready", roundNumber = 7})).toBe(false)
        expect(replay(7, {phase = "ready", roundNumber = 9})).toBe(false)
        expect(replay(7, {phase = "ready"})).toBe(false)
        expect(replay(7, false)).toBe(false)
        expect(replay(nil, {phase = "ready", roundNumber = 8})).toBe(false)
        expect(replay(0, {phase = "ready", roundNumber = 1})).toBe(false)
        expect(replay(math.huge, {phase = "ready", roundNumber = math.huge}))
            .toBe(false)
    end)

    it("upgrades a verified receipt quietly in the existing result card", function()
        local animate = ResultPresentation.animateCardArrival
        -- Frozen result preview is introduced once, then real rewards
        -- update the same visible card without a second full-screen flash.
        expect(animate(false, nil, 12)).toBe(true)
        expect(animate(true, 12, 12)).toBe(false)
        expect(animate(true, "12", 12)).toBe(false)
        expect(animate(true, 12, 13)).toBe(true)
        expect(animate(false, 12, 12)).toBe(true)
        -- Fail safe rather than suppress the only result introduction
        -- when an unnumbered/invalid message slipped through.
        expect(animate(true, nil, 12)).toBe(true)
        expect(animate(true, 12, nil)).toBe(true)
        expect(animate(true, math.huge, 12)).toBe(true)
        expect(animate(true, 12, 0 / 0)).toBe(true)
    end)

    it("suppresses fullscreen result flashes on touch and all motion when requested", function()
        local motion = ResultPresentation.entryMotion
        local card, flash = motion(true, false, false)
        expect(card).toBe(true)
        expect(flash).toBe(true)
        card, flash = motion(true, false, true)
        expect(card).toBe(true)
        expect(flash).toBe(false)
        card, flash = motion(true, true, false)
        expect(card).toBe(false)
        expect(flash).toBe(false)
        card, flash = motion(true, true, true)
        expect(card).toBe(false)
        expect(flash).toBe(false)
        card, flash = motion(false, false, false)
        expect(card).toBe(false)
        expect(flash).toBe(false)
        card, flash = motion(nil, nil, nil)
        expect(card).toBe(false)
        expect(flash).toBe(false)
    end)

    it("accepts the current result receipt but rejects stale or next-round overlays", function()
        local accepts = ResultPresentation.acceptReceipt
        expect(accepts({roundNumber = 8}, "round", 8, 7)).toBe(true)
        expect(accepts({roundNumber = 8}, "result", 8, 8)).toBe(true)
        expect(accepts({roundNumber = 7}, "round", 8, 7)).toBe(false)
        expect(accepts({roundNumber = 8}, "ready", 9, 8)).toBe(false)
        expect(accepts({roundNumber = 9}, "intermission", 9, 8)).toBe(false)
        expect(accepts({roundNumber = 8}, "waiting", 8, 7)).toBe(false)
        expect(accepts({roundNumber = 7}, "result", 8, 8)).toBe(false)
        expect(accepts({roundNumber = 8}, "result", 8, 9)).toBe(false)
        expect(accepts({roundNumber = 0}, "round", nil, nil)).toBe(false)
        expect(accepts({roundNumber = math.huge}, "round", nil, nil)).toBe(false)
        expect(accepts({roundNumber = "bad"}, "round", nil, nil)).toBe(false)
        expect(accepts(nil, "round", nil, nil)).toBe(false)
        -- The celebration renderer and HUD must apply the same acceptance
        -- policy: no late red/green pulses after READY or a later result.
        expect(accepts({roundNumber = 23, survived = true},
            "result", 24, 23)).toBe(false)
        expect(accepts({roundNumber = 23, survived = false},
            "intermission", 24, 23)).toBe(false)
        expect(accepts({roundNumber = 24, survived = true},
            "round", 24, 23)).toBe(true)
        expect(accepts({roundNumber = 24, survived = true},
            "result", 24, 24)).toBe(true)
    end)

    it("rebuilds a truthful victory card when the personalized result event is delayed", function()
        local state = {
            phase = "result",
            roundNumber = 9,
            arenaId = "Classic",
            arenaName = "CLASSIC GRID",
            disasterIds = {"Meteors"},
            survivorUserIds = {101, 203},
            soloMode = true,
        }
        local won = ResultPresentation.fallbackFeedback(state, 203, true)
        expect(won.survived).toBe(true)
        expect(won.pendingRewards).toBe(true)
        expect(won.spectating).toBe(false)
        expect(won.roundNumber).toBe(9)
        expect(won.arenaId).toBe("Classic")
        expect(won.coins == nil).toBe(true)
        expect(won.xp == nil).toBe(true)
        expect(ResultPresentation.title(won, "fr-fr")).toBe("SURVÉCU !")
        expect(CoreLocalization.text("fr-fr", "RESULT_REWARDS_PENDING"))
            .toBe("RÉCOMPENSES EN COURS...")
        expect(CoreLocalization.text("en-us", "RESULT_REWARDS_PENDING"))
            .toBe("REWARDS SYNCING...")
        expect(CoreLocalization.text("fr-fr", "RESULT_SPECTATOR_TITLE"))
            .toBe("MANCHE TERMINÉE")

        local eliminated = ResultPresentation.fallbackFeedback(state, 204, true)
        expect(eliminated.survived).toBe(false)
        expect(eliminated.pendingRewards).toBe(true)

        -- The survivor roster is more authoritative than a late replica
        -- of RoundParticipant. The player still won the round.
        local delayedAttribute = ResultPresentation.fallbackFeedback(state, 203, false)
        expect(delayedAttribute.survived).toBe(true)
        expect(delayedAttribute.spectating).toBe(false)
        expect(delayedAttribute.pendingRewards).toBe(true)

        local spectator = ResultPresentation.fallbackFeedback(state, 204, false)
        expect(spectator.survived).toBe(false)
        expect(spectator.spectating).toBe(true)
        expect(spectator.pendingRewards).toBe(false)

        expect(ResultPresentation.fallbackFeedback({phase = "round"}, 203, true) == nil)
            .toBe(true)
        expect(ResultPresentation.fallbackFeedback(nil, 203, true) == nil)
            .toBe(true)
        expect(ResultPresentation.fallbackFeedback({phase = "result"}, 0, true).survived)
            .toBe(false)
    end)

    it("recovers a failed winner's result from frozen rosters, not reward success", function()
        local state = {
            phase = "result",
            roundNumber = 15,
            survivorUserIds = {101, 303},
            participantUserIds = {101, 202, 303},
            disasterIds = {"Bombs"},
        }
        -- The entire roster comes from the actual round, not from how
        -- many players completed their Coins/XP writes.
        local winner = ResultPresentation.fallbackFeedback(state, 101, false)
        expect(winner.survived).toBe(true)
        expect(winner.spectating).toBe(false)
        expect(winner.pendingRewards).toBe(true)
        expect(winner.coins == nil).toBe(true)
        local loser = ResultPresentation.fallbackFeedback(state, 202, false)
        expect(loser.survived).toBe(false)
        expect(loser.spectating).toBe(false)
        expect(loser.pendingRewards).toBe(true)
        local spectator = ResultPresentation.fallbackFeedback(state, 999, true)
        expect(spectator.survived).toBe(false)
        expect(spectator.spectating).toBe(true)
        expect(spectator.pendingRewards).toBe(false)

        -- An explicit empty roster must override stale RoundParticipant.
        local noParticipants = ResultPresentation.fallbackFeedback({
            phase = "result", survivorUserIds = {}, participantUserIds = {},
        }, 202, true)
        expect(noParticipants.spectating).toBe(true)

        -- On failed settlement, the player should be informed that the
        -- amount is unknown rather than being shown a fabricated +0 award.
        expect(CoreLocalization.text("en-us", "RESULT_REWARDS_UNAVAILABLE"))
            .toBe("REWARDS COULD NOT BE VERIFIED")
        expect(CoreLocalization.text("fr-fr", "RESULT_REWARDS_UNAVAILABLE"))
            .toBe("GAINS NON VÉRIFIÉS")
    end)

    it("prioritizes master over clutch", function()
        expect(ResultPresentation.kind({
            survived = true,
            criticalSurvival = true,
            challengeCompleted = true,
            momentumBest = 4,
        })).toBe("master")
    end)

    it("promotes critical survival to a distinct result", function()
        local feedback = {
            survived = true,
            criticalSurvival = true,
            challengeCompleted = false,
            momentumBest = 1,
        }
        expect(ResultPresentation.kind(feedback)).toBe("clutch")
        expect(ResultPresentation.title(feedback)).toBe("CLUTCH SURVIVAL!")
        expect(ResultPresentation.worldLabel(feedback, true)).toBe("CLUTCH SURVIVAL")
    end)

    it("keeps ordinary survival and elimination distinct", function()
        expect(ResultPresentation.kind({survived = true})).toBe("survived")
        expect(ResultPresentation.title({survived = true})).toBe("SURVIVED!")
        expect(ResultPresentation.kind({survived = false})).toBe("eliminated")
        expect(ResultPresentation.title({survived = false})).toBe("ELIMINATED")
    end)

    it("normalizes elimination causes for round feedback", function()
        expect(ResultPresentation.feedbackEliminationCause(true, "Meteor")).toBe(nil)
        expect(ResultPresentation.feedbackEliminationCause(false, "Meteor")).toBe("Meteor")
        expect(ResultPresentation.feedbackEliminationCause(false, nil)).toBe("Unknown")
        expect(ResultPresentation.feedbackEliminationCause(false, "")).toBe("Unknown")
    end)

    it("teaches the new timed Jump Shock dodge after elimination", function()
        local enTitle, enTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "JumpShock",
        }, "en-us")
        local frTitle, frTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "JumpShock",
        }, "fr-fr")
        expect(enTitle).toBe("KNOCKED OFF BY SHOCKWAVE")
        expect(string.find(enTip, "jump", 1, true) ~= nil).toBe(true)
        expect(string.find(frTip, "Saute", 1, true) ~= nil).toBe(true)
        expect(frTitle).toBe("ÉJECTÉ PAR L'ONDE DE CHOC")
    end)

    it("explains known elimination causes", function()
        local meteorTitle, meteorTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Meteor",
        })
        expect(meteorTitle).toBe("HIT BY METEOR")
        expect(string.find(meteorTip, "orange warning circle", 1, true) ~= nil).toBe(true)
        expect(ResultPresentation.title({
            survived = false,
            eliminationCause = "Meteor",
        })).toBe("HIT BY METEOR")

        local platformTitle, platformTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "DisappearingPlatforms",
        })
        expect(platformTitle).toBe("PLATFORM COLLAPSED")
        expect(string.find(platformTip, "flashing platforms", 1, true) ~= nil).toBe(true)

        local shrinkTitle, shrinkTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "ShrinkingArena",
        })
        expect(shrinkTitle).toBe("CAUGHT BY THE SHRINK")
        expect(string.find(shrinkTip, "center", 1, true) ~= nil).toBe(true)

        local fallTitle, fallTip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Fall",
        })
        expect(fallTitle).toBe("FELL FROM THE ARENA")
        expect(string.find(fallTip, "shorter jumps", 1, true) ~= nil).toBe(true)
    end)

    it("gives every known elimination cause useful EN/FR revenge guidance", function()
        local causes = {
            "Meteor",
            "Bomb",
            "Lava",
            "Tornado",
            "JumpShock",
            "LowGravity",
            "DisappearingPlatforms",
            "ShrinkingArena",
            "Fall",
        }

        for _, localeId in ipairs({"en-us", "fr-fr"}) do
            for _, cause in ipairs(causes) do
                local title, tip = ResultPresentation.eliminationCopy({
                    survived = false,
                    eliminationCause = cause,
                }, localeId)

                expect(type(title)).toBe("string")
                expect(#title >= 4).toBe(true)
                expect(type(tip)).toBe("string")
                expect(#tip >= 12).toBe(true)
            end
        end
    end)

    it("prioritizes the actual lethal hazard in Double Chaos result visuals", function()
        local primary, secondary = ResultPresentation.visualHazardOrder({
            survived = false,
            disasterIds = {"Tornado", "Bombs"},
            eliminationCause = "Bomb",
        })
        expect(primary).toBe("Bombs")
        expect(secondary).toBe("Tornado")

        local survivedPrimary, survivedSecondary = ResultPresentation.visualHazardOrder({
            survived = true,
            disasterIds = {"Tornado", "Bombs"},
            eliminationCause = "Bomb",
        })
        expect(survivedPrimary).toBe("Tornado")
        expect(survivedSecondary).toBe("Bombs")

        local fallPrimary, fallSecondary = ResultPresentation.visualHazardOrder({
            survived = false,
            disasterIds = {"Tornado", "Bombs"},
            eliminationCause = "Fall",
        })
        expect(fallPrimary).toBe("Tornado")
        expect(fallSecondary).toBe("Bombs")
    end)

    it("falls back to useful generic elimination guidance", function()
        local title, tip = ResultPresentation.eliminationCopy({
            survived = false,
            eliminationCause = "Unknown",
        })
        expect(title).toBe("ELIMINATED")
        expect(#tip > 10).toBe(true)
    end)

    it("scales survivor constellation complexity with device quality", function()
        expect(ResultPresentation.constellationBudget("Low")).toBe(3)
        expect(ResultPresentation.constellationBudget("Medium")).toBe(6)
        expect(ResultPresentation.constellationBudget("High")).toBe(8)
        expect(ResultPresentation.constellationRadius("Low")).toBe(10)
        expect(ResultPresentation.constellationRadius("High")).toBe(16)
    end)

    it("scales premium result architecture without burdening low quality", function()
        local low = ResultPresentation.architectureProfile("Low", 1)
        local medium = ResultPresentation.architectureProfile("Medium", 3)
        local high = ResultPresentation.architectureProfile("High", 3)
        local sole = ResultPresentation.architectureProfile("High", 1)

        expect(low.Pylons).toBe(0)
        expect(low.Height).toBe(0)
        expect(high.Pylons > medium.Pylons).toBe(true)
        expect(high.Height > medium.Height).toBe(true)
        expect(sole.Pylons >= high.Pylons).toBe(true)
        expect(sole.RadiusScale <= 0.8).toBe(true)
    end)

    it("orders presentation intensity by result importance", function()
        local master = ResultPresentation.intensity({
            survived = true,
            challengeCompleted = true,
            momentumBest = 4,
        })
        local clutch = ResultPresentation.intensity({
            survived = true,
            criticalSurvival = true,
        })
        local survived = ResultPresentation.intensity({survived = true})
        local eliminated = ResultPresentation.intensity({survived = false})

        expect(master > clutch).toBe(true)
        expect(clutch > survived).toBe(true)
        expect(survived > eliminated).toBe(true)
    end)
end)

return nil
