--!strict
local Lest = require("@lest")
local describe, it, expect = Lest.describe, Lest.it, Lest.expect

local FirstTimeExperience = require("../../src/shared/FirstTimeExperience")
local CoreLocalization = require("../../src/shared/CoreLocalization")

describe("First time experience", function()
    it("distinguishes the first round from the lightweight rookie window", function()
        expect(FirstTimeExperience.isFirstRound(0)).toBe(true)
        expect(FirstTimeExperience.isFirstRound(1)).toBe(true)
        expect(FirstTimeExperience.isFirstRound(2)).toBe(false)

        expect(FirstTimeExperience.isRookie(2)).toBe(true)
        expect(FirstTimeExperience.isRookie(3)).toBe(false)
    end)

    it("blocks double chaos while any contestant is on their first round", function()
        expect(FirstTimeExperience.allowDoubleChaos({1})).toBe(false)
        expect(FirstTimeExperience.allowDoubleChaos({20, 1, 8})).toBe(false)
        expect(FirstTimeExperience.allowDoubleChaos({2})).toBe(true)
        expect(FirstTimeExperience.allowDoubleChaos({2, 8, 20})).toBe(true)
    end)

    it("explains the core objective before the first vote", function()
        local text = FirstTimeExperience.coachText({
            phase = "intermission",
        }, {
            games = 0,
            practiceUses = 0,
        })
        expect(text).toBe("HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS")

        local learned = FirstTimeExperience.coachText({
            phase = "intermission",
        }, {
            games = 0,
            practiceUses = 1,
        })
        expect(learned).toBe("ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID RED/ORANGE WARNINGS")
    end)


    it("shares actionable vote availability with the world guide", function()
        for _, value in ipairs({false, 0, "vote", {}, {phase = "intermission"},
            {phase = "intermission", voteOptions = {}},
            {phase = "intermission", voteOptions = "invalid"},
        }) do
            expect(FirstTimeExperience.hasVoteOptions(value)).toBe(false)
        end
        expect(FirstTimeExperience.hasVoteOptions(nil)).toBe(false)
        expect(FirstTimeExperience.hasVoteOptions(
            {phase = "intermission", voteOptions = {{id = "Meteors"}}}
        )).toBe(true)
        expect(FirstTimeExperience.hasVoteOptions(
            {phase = "waiting", voteOptions = {{id = "Freeze"}}}
        )).toBe(true)
    end)


    it("restricts streamed rookie guide anchors to their map sections", function()
        local map = Instance.new("Folder")
        map.Name = "GeneratedMap"
        local lobby = Instance.new("Folder")
        lobby.Name = "Lobby"
        lobby.Parent = map
        local activities = Instance.new("Folder")
        activities.Name = "Activities"
        activities.Parent = lobby
        local decor = Instance.new("Folder")
        decor.Name = "Decor"
        decor.Parent = lobby
        local arena = Instance.new("Folder")
        arena.Name = "Arena"
        arena.Parent = map
        local mechanics = Instance.new("Folder")
        mechanics.Name = "Mechanics"
        mechanics.Parent = arena

        local practice = Instance.new("Part")
        practice.Parent = activities
        -- Delayed attribute replication still needs a watcher.
        expect(FirstTimeExperience.guideAnchorKind(practice, map)).toBe("practice")
        practice:SetAttribute("LobbyPracticePad", true)
        expect(FirstTimeExperience.guideAnchorKind(practice, map)).toBe("practice")

        local runway = Instance.new("Part")
        runway.Name = "ArenaRunway"
        runway.Parent = decor
        expect(FirstTimeExperience.guideAnchorKind(runway, map)).toBe("runway")

        local mobility = Instance.new("Part")
        mobility.Parent = mechanics
        expect(FirstTimeExperience.guideAnchorKind(mobility, map)).toBe("mobility")

        local unrelated = Instance.new("Part")
        unrelated.Parent = decor
        expect(FirstTimeExperience.guideAnchorKind(unrelated, map)).toBe(nil)
        expect(FirstTimeExperience.guideAnchorKind(nil, map)).toBe(nil)
        expect(FirstTimeExperience.guideAnchorKind(practice, nil)).toBe(nil)

        practice.Parent = nil
        expect(FirstTimeExperience.guideAnchorKind(practice, map)).toBe(nil)
        map:Destroy()
        practice:Destroy()
    end)

    it("uses the ready-phase arena ID over stale replicated metadata", function()
        local staleId, staleMatches = FirstTimeExperience.arenaGuideIdentity(
            {arenaId = "Orbital", arenaName = "ORBITAL GRID"}, "Classic"
        )
        expect(staleId).toBe("Orbital")
        expect(staleMatches).toBe(false)

        local currentId, currentMatches = FirstTimeExperience.arenaGuideIdentity(
            {arenaId = "Towers", arenaName = "TOWER RUN"}, "Towers"
        )
        expect(currentId).toBe("Towers")
        expect(currentMatches).toBe(true)

        local fallbackName, hasMetadata = FirstTimeExperience.arenaGuideIdentity(
            {arenaName = "TOWER RUN"}, "Classic"
        )
        expect(fallbackName).toBe("TOWER RUN")
        expect(hasMetadata).toBe(false)

        local fallbackId, fallbackMatches = FirstTimeExperience.arenaGuideIdentity(
            {}, "Classic"
        )
        expect(fallbackId).toBe("Classic")
        expect(fallbackMatches).toBe(true)

        local missingId, missingMatches = FirstTimeExperience.arenaGuideIdentity(
            false, "Classic"
        )
        expect(missingId).toBe(nil)
        expect(missingMatches).toBe(false)
    end)

    it("avoids rebuilding unchanged voting cards on each countdown tick", function()
        local old = {
            {id = "Meteors", name = "Meteors", hint = "Dodge", votes = 0},
            {id = "Freeze", name = "Freeze", hint = "Move", votes = 1},
        }
        local oldKey = FirstTimeExperience.voteRenderKey(old, nil, false)
        expect(type(oldKey)).toBe("string")
        local same = {
            {id = "Meteors", name = "Meteors", hint = "Dodge", votes = "0"},
            {id = "Freeze", name = "Freeze", hint = "Move", votes = 1},
        }
        expect(FirstTimeExperience.voteRenderKey(same, nil, false))
            .toBe(oldKey)
        expect(FirstTimeExperience.voteRenderKey({}, nil, false)).toBe(nil)
        expect(FirstTimeExperience.voteRenderKey("bad", nil, false)).toBe(nil)
        same[2].votes = 2
        expect(FirstTimeExperience.voteRenderKey(same, nil, false) ~= oldKey)
            .toBe(true)
        same[2].votes = 1
        same[1].hint = "Jump"
        expect(FirstTimeExperience.voteRenderKey(same, nil, false) ~= oldKey)
            .toBe(true)
        same[1].hint = "Dodge"
        same[1].name = "Fire"
        expect(FirstTimeExperience.voteRenderKey(same, nil, false) ~= oldKey)
            .toBe(true)
        same[1].name = "Meteors"
        expect(FirstTimeExperience.voteRenderKey(same, "Freeze", false) ~= oldKey)
            .toBe(true)
        expect(FirstTimeExperience.voteRenderKey(same, nil, true) ~= oldKey)
            .toBe(true)
        same[1].id = "Bombs"
        expect(FirstTimeExperience.voteRenderKey(same, nil, false) ~= oldKey)
            .toBe(true)
    end)

    it("only accepts distinct, renderable one-to-three-card ballots", function()
        local valid = {{id = "Meteors"}, {id = "Freeze"}, {id = "Bombs"}}
        expect(FirstTimeExperience.validVoteOptions(valid)).toBe(true)
        expect(FirstTimeExperience.validVoteOptions({{id = "Meteors"}})).toBe(true)
        for _, invalid in ipairs({
            {}, {"Meteors"}, {{name = "Meteors"}}, {{id = ""}},
            {{id = "Freeze"}, {id = "Freeze"}},
            {{id = "A"}, {id = "B"}, {id = "C"}, {id = "D"}},
            {{id = "Meteors"}, false},
        }) do
            expect(FirstTimeExperience.validVoteOptions(invalid)).toBe(false)
            expect(FirstTimeExperience.hasVoteOptions({voteOptions = invalid})).toBe(false)
        end
        expect(FirstTimeExperience.validVoteOptions(nil)).toBe(false)
    end)

    it("does not advertise voting before actionable options arrive", function()
        local state = {phase = "intermission"}
        local newbie = {games = 0, practiceUses = 0}
        for _, options in ipairs({{}, "not-a-ballot", true, 0}) do
            state.voteOptions = options
            expect(FirstTimeExperience.coachText(state, newbie))
                .toBe("HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS")
        end
        state.voteOptions = nil
        expect(FirstTimeExperience.coachText(state, newbie))
            .toBe("HOW TO PLAY  •  SURVIVE UNTIL 0  •  MOVE + JUMP  •  SHARDS = BONUS")
        state.voteOptions = {{id = "Freeze"}}
        expect(FirstTimeExperience.coachText(state, newbie))
            .toBe("VOTE  •  TAP THE CHAOS YOU WANT TO FACE")
        state.voteOptions = {}
        expect(FirstTimeExperience.coachText(state,
            {games = 1, practiceUses = 1})).toBe(nil)
    end)

    it("states the survival goal clearly during the ready phase", function()
        local text = FirstTimeExperience.coachText({
            phase = "ready",
        }, {
            games = 1,
        })
        expect(text).toBe("ROUND GOAL  •  SURVIVE UNTIL 0  •  AVOID THE HAZARD  •  SHARDS = BONUS")
    end)

    it("prioritizes voting when vote options are open", function()
        local text = FirstTimeExperience.coachText({
            phase = "intermission",
            voteOptions = {{id = "Meteors"}},
        }, {
            games = 0,
            practiceUses = 0,
        })
        expect(text).toBe("VOTE  •  TAP THE CHAOS YOU WANT TO FACE")
    end)

    it("keeps the entire action phase clear of rookie coach overlays", function()
        for _, seconds in ipairs({20, 7, 1}) do
            local text = FirstTimeExperience.coachText({
                phase = "round",
                seconds = seconds,
            }, {
                games = 1,
                mechanicUses = 1,
                shards = 1,
            })
            expect(text == nil).toBe(true)
        end
    end)

    it("localizes essential onboarding and hazard guidance in French", function()
        expect(CoreLocalization.language("fr-fr")).toBe("fr")
        expect(CoreLocalization.text("fr-fr", "SURVIVE_ZERO")).toBe("SURVIS JUSQU'À 0")
        expect(CoreLocalization.hazardName("fr-fr", "Meteors")).toBe("PLUIE DE MÉTÉORES")
        expect(CoreLocalization.hazardHint("fr-fr", "Meteors")).toBe("ÉVITE LES CERCLES D'ALERTE ORANGE")

        local localized = CoreLocalization.coach(
            "fr-fr",
            "VOTE  •  TAP THE CHAOS YOU WANT TO FACE"
        )
        expect(localized).toBe("VOTE  •  TOUCHE LE CHAOS QUE TU VEUX AFFRONTER")
    end)

    it("stops strong round coaching after the first game", function()
        local text = FirstTimeExperience.coachText({
            phase = "round",
            seconds = 20,
        }, {
            games = 2,
        })
        expect(text == nil).toBe(true)
    end)
end)

return nil
