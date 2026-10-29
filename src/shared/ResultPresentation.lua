local ResultPresentation = {}

-- A server-confirmed result is sufficient to show the previous-round
-- recap in the lobby. Profile attributes (Games/DataLoaded) can lag a
-- round transition, especially on mobile; neither is a result receipt.
function ResultPresentation.showLobbyRecap(phase, recap)
    if phase ~= "intermission" and phase ~= "waiting" then
        return false
    end
    if type(recap) ~= "table"
        or type(recap.disasterIds) ~= "table"
        or #recap.disasterIds == 0 then
        return false
    end
    local number = tonumber(recap.roundNumber)
    return number ~= nil and number == number and number > 0
        and number < math.huge and number == math.floor(number)
end

local ELIMINATION_COPY = {
    Meteor = {
        title = "HIT BY METEOR",
        tip = "Move as soon as the orange warning circle appears",
    },
    Bomb = {
        title = "CAUGHT IN BOMB BLAST",
        tip = "Leave red markers before they detonate",
    },
    Lava = {
        title = "CAUGHT BY LAVA",
        tip = "Climb early and keep gaining height",
    },
    Tornado = {
        title = "THROWN BY TORNADO",
        tip = "Keep more distance from the tornado",
    },
    JumpShock = {
        title = "KNOCKED OFF BY SHOCKWAVE",
        tip = "Time your jump to clear the blue shockwave",
    },
    LowGravity = {
        title = "DRIFTED OFF THE ARENA",
        tip = "Use short jumps and steer back toward the center",
    },
    DisappearingPlatforms = {
        title = "PLATFORM COLLAPSED",
        tip = "Leave flashing platforms before they disappear",
    },
    ShrinkingArena = {
        title = "CAUGHT BY THE SHRINK",
        tip = "Move toward the center before the boundary closes",
    },
    Fall = {
        title = "FELL FROM THE ARENA",
        tip = "Use shorter jumps and recover toward the center",
    },
}

local ELIMINATION_COPY_FR = {
    Meteor = {
        title = "FRAPPÉ PAR UN MÉTÉORE",
        tip = "Bouge dès que le cercle d'alerte orange apparaît",
    },
    Bomb = {
        title = "PRIS DANS UNE EXPLOSION",
        tip = "Quitte les zones rouges avant l'explosion",
    },
    Lava = {
        title = "RATTRAPÉ PAR LA LAVE",
        tip = "Monte tôt et continue à prendre de la hauteur",
    },
    Tornado = {
        title = "PROJETÉ PAR LA TORNADE",
        tip = "Garde davantage de distance avec la tornade",
    },
    JumpShock = {
        title = "ÉJECTÉ PAR L'ONDE DE CHOC",
        tip = "Saute au bon moment pour esquiver l'onde bleue",
    },
    LowGravity = {
        title = "SORTI DE L'ARÈNE",
        tip = "Fais de petits sauts et reviens vers le centre",
    },
    DisappearingPlatforms = {
        title = "PLATEFORME EFFONDRÉE",
        tip = "Quitte les plateformes qui clignotent avant leur disparition",
    },
    ShrinkingArena = {
        title = "RATTRAPÉ PAR L'ARÈNE",
        tip = "Rejoins le centre avant que la limite se referme",
    },
    Fall = {
        title = "TOMBÉ DE L'ARÈNE",
        tip = "Fais des sauts plus courts et reviens vers le centre",
    },
}

local function french(localeId)
    return string.sub(string.lower(tostring(localeId or "")), 1, 2) == "fr"
end

function ResultPresentation.feedbackEliminationCause(survived, cause)
    if survived == true then
        return nil
    end

    local normalized = tostring(cause or "Unknown")
    if normalized == "" then
        return "Unknown"
    end
    return normalized
end

function ResultPresentation.eliminationCopy(feedback, localeId)
    feedback = type(feedback) == "table" and feedback or {}
    local source = french(localeId) and ELIMINATION_COPY_FR or ELIMINATION_COPY
    local copy = source[tostring(feedback.eliminationCause or "")]
    if copy then
        return copy.title, copy.tip
    end

    if french(localeId) then
        return "ÉLIMINÉ", "Réagis tôt à l'alerte du danger et garde une route sûre"
    end
    return "ELIMINATED", "React early to the hazard warning and keep a safe route"
end

local ELIMINATION_TO_DISASTER = {
    Meteor = "Meteors",
    Bomb = "Bombs",
    Lava = "RisingLava",
    Tornado = "Tornado",
    JumpShock = "JumpShock",
    LowGravity = "LowGravity",
    DisappearingPlatforms = "DisappearingPlatforms",
    ShrinkingArena = "ShrinkingArena",
}

function ResultPresentation.visualHazardOrder(feedback)
    feedback = type(feedback) == "table" and feedback or {}
    local ids = type(feedback.disasterIds) == "table" and feedback.disasterIds or {}

    local primary = ids[1]
    local secondary = ids[2]

    if feedback.survived ~= true and secondary then
        local causedBy = ELIMINATION_TO_DISASTER[tostring(feedback.eliminationCause or "")]
        if causedBy and causedBy == secondary then
            primary, secondary = secondary, primary
        end
    end

    return primary, secondary
end

-- Server RoundState is sent every result tick and when a client connects
-- during results. The personalized RoundFeedback event can occasionally
-- arrive late or be missed; recover a truthful, non-reward-claiming result
-- card from the authoritative participant/survivor roster instead of
-- leaving an empty screen. Never infer victory for a spectator.
function ResultPresentation.fallbackFeedback(state, userId, participating)
    if type(state) ~= "table" or state.phase ~= "result" then return nil end
    local id = tonumber(userId)
    local function inRoster(roster)
        if type(roster) ~= "table" or not id or id <= 0 then
            return false
        end
        for _, entryId in ipairs(roster) do
            if tonumber(entryId) == id then
                return true
            end
        end
        return false
    end

    -- Both rosters are frozen by the round server BEFORE reward processing:
    -- a failed achievement or late participant attribute cannot silently
    -- turn a real winner into a spectator or invent a spectator win.
    local won = inRoster(state.survivorUserIds)
    local hasParticipants = type(state.participantUserIds) == "table"
    local played = won
        or (hasParticipants and inRoster(state.participantUserIds))
        or (not hasParticipants and participating == true)
    return {
        survived = won,
        soleSurvivor = won and tonumber(state.soleSurvivorUserId) == id,
        spectating = not played,
        pendingRewards = played,
        roundNumber = state.roundNumber,
        arenaId = state.arenaId,
        arenaName = state.arenaName,
        disasterIds = state.disasterIds,
        doubleChaos = state.doubleChaos == true,
        fusionName = state.fusionName,
        soloMode = state.soloMode == true,
    }
end

-- The receipt may legitimately arrive during the final ROUND tick, before
-- the RESULT state. It must not reopen an old victory card once a new
-- numbered round has begun, or overwrite a newer result with stale data.
function ResultPresentation.acceptReceipt(feedback, phase, observedRound, resolvedRound)
    if type(feedback) ~= "table" then return false end
    local receiptRound = tonumber(feedback.roundNumber)
    if receiptRound == nil or receiptRound ~= receiptRound
        or receiptRound < 1 or receiptRound >= math.huge
        or receiptRound ~= math.floor(receiptRound)
    then
        return false
    end
    local seen = tonumber(observedRound)
    if seen and seen == seen and seen < math.huge and receiptRound < seen then
        return false
    end
    local resolved = tonumber(resolvedRound)
    if resolved and resolved == resolved and receiptRound < resolved then
        return false
    end
    -- READY always belongs to the *next* round; an old result must not
    -- replace the player's live instructions or controls.
    if phase == "ready" or phase == "intermission" or phase == "waiting" then
        return false
    end
    return true
end

-- Only the first card for a numbered round should introduce the result.
-- The later personalized reward receipt upgrades the same card in place:
-- flashing it a second time is distracting, especially on mobile.
-- A different round is a new presentation even if the prior card is
-- still fading out.
function ResultPresentation.animateCardArrival(visible, displayedRound, incomingRound)
    if visible ~= true then return true end
    local old = tonumber(displayedRound)
    local incoming = tonumber(incomingRound)
    if not old or not incoming
        or old ~= old or incoming ~= incoming
        or old == math.huge or old == -math.huge
        or incoming == math.huge or incoming == -math.huge then
        return true
    end
    return old ~= incoming
end

-- An earned result stays readable on every device. Android never needs
-- a screen-wide flash over touch controls, and Reduce Motion avoids both
-- the flash and the card scale entrance. A late receipt never reanimates.
function ResultPresentation.entryMotion(animateArrival, reducedMotion, touchDevice)
    local animateCard = animateArrival == true and reducedMotion ~= true
    local flashScreen = animateCard and touchDevice ~= true
    return animateCard, flashScreen
end

function ResultPresentation.kind(feedback)
    feedback = type(feedback) == "table" and feedback or {}

    local survived = feedback.survived == true
    local momentumBest = math.max(0, math.floor(tonumber(feedback.momentumBest) or 0))
    local master = survived
        and feedback.challengeCompleted == true
        and momentumBest >= 4

    if master then
        return "master"
    elseif survived and feedback.criticalSurvival == true then
        return "clutch"
    elseif survived then
        return "survived"
    end
    return "eliminated"
end

function ResultPresentation.title(feedback, localeId)
    local kind = ResultPresentation.kind(feedback)
    if french(localeId) then
        if kind == "master" then
            return "MANCHE MAÎTRISÉE !"
        elseif kind == "clutch" then
            return "SURVIE EXTRÊME !"
        elseif kind == "survived" then
            return feedback.soleSurvivor == true and "DERNIER SURVIVANT !" or "SURVÉCU !"
        end
    else
        if kind == "master" then
            return "MASTER ROUND!"
        elseif kind == "clutch" then
            return "CLUTCH SURVIVAL!"
        elseif kind == "survived" then
            return feedback.soleSurvivor == true and "LAST SURVIVOR!" or "SURVIVED!"
        end
    end

    local title = ResultPresentation.eliminationCopy(feedback, localeId)
    return title
end

-- One authoritative, testable choice of player-facing survivor identity.
-- Real last survivor requires the server's soleSurvivorUserId; surviving
-- alone in a one-contestant game must never grant the champion title.
function ResultPresentation.spotlightLabelKey(champion, isLocal)
    if champion == true then return "RESULT_SOLE_SURVIVOR" end
    return isLocal == true and "YOU_SURVIVED" or "SURVIVOR_LABEL"
end

function ResultPresentation.worldLabel(feedback, isLocal)
    local kind = ResultPresentation.kind(feedback)

    if kind == "master" then
        return isLocal and "MASTER ROUND" or "MASTER SURVIVOR"
    elseif kind == "clutch" then
        return isLocal and "CLUTCH SURVIVAL" or "SURVIVOR"
    elseif kind == "survived" then
        if feedback.soleSurvivor == true then return "LAST SURVIVOR" end
        return isLocal and "YOU SURVIVED" or "SURVIVOR"
    end

    return isLocal and "ELIMINATED" or nil
end

function ResultPresentation.constellationBudget(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 3
    elseif tier == "High" then
        return 8
    end
    return 6
end

function ResultPresentation.constellationRadius(tierName)
    local tier = tostring(tierName or "Medium")
    if tier == "Low" then
        return 10
    elseif tier == "High" then
        return 16
    end
    return 13
end

function ResultPresentation.architectureProfile(tierName, survivorCount)
    local tier = tostring(tierName or "Medium")
    local survivors = math.max(0, math.floor(tonumber(survivorCount) or 0))

    if tier == "Low" or survivors <= 0 then
        return {
            Pylons = 0,
            Height = 0,
            RadiusScale = 0,
        }
    elseif tier == "High" then
        return {
            Pylons = survivors == 1 and 6 or 5,
            Height = survivors == 1 and 7.4 or 6.6,
            RadiusScale = 0.74,
        }
    end

    return {
        Pylons = survivors == 1 and 4 or 3,
        Height = survivors == 1 and 5.6 or 5.0,
        RadiusScale = 0.68,
    }
end

function ResultPresentation.intensity(feedback)
    local kind = ResultPresentation.kind(feedback)
    if kind == "master" then
        return 1
    elseif kind == "clutch" then
        return 0.86
    elseif kind == "survived" then
        return 0.72
    end
    return 0.48
end


-- Compact, factual reason to replay, shown below the round's EXISTING
-- reward receipt. Only authoritative per-player RoundFeedback can create
-- this line: provisional server-roster results never invent currency,
-- ranks or progress. No persistence claims or new rewards.
local function rewardCount(value)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge
        or n < 0 then return 0 end
    return math.min(999999, math.floor(n))
end

function ResultPresentation.replayHighlight(feedback, localeId)
    if type(feedback) ~= "table"
        or feedback.spectating == true
        or feedback.pendingRewards == true
        or feedback.rewardsUnavailable == true then
        return nil
    end
    local fr = french(localeId)
    local coins = rewardCount(feedback.challengeCoins)
    local xp = rewardCount(feedback.challengeXP)
    if feedback.challengeCompleted == true and (coins > 0 or xp > 0) then
        return {
            Text = (fr and "DÉFI RÉUSSI" or "CHALLENGE CLEARED")
                .. string.format("  +%d %s / +%d XP",
                    coins, fr and "PIÈCES" or "COINS", xp),
            Kind = "completed",
        }
    end

    -- On a lost round, existing ResultTip still teaches how to avoid
    -- the cause. This extra line shows the REAL next long-term target
    -- without replacing that actionable survival advice.
    local mastery = feedback.arenaMastery
    if type(mastery) == "table" and mastery.maxed ~= true
        and type(mastery.nextTier) == "string"
        and mastery.nextTier ~= "" then
        local missing = rewardCount(mastery.remaining)
        if missing > 0 then
            return {
                Text = (fr and "PROCHAIN RANG " or "NEXT RANK ")
                    .. tostring(mastery.nextTier)
                    .. string.format("  •  %d %s", missing,
                        fr and "POINTS RESTANTS" or "POINTS TO GO"),
                Kind = "progress",
            }
        end
    end

    if feedback.survived == true and rewardCount(feedback.streak) >= 2 then
        return {
            Text = fr and "PROLONGE TA SÉRIE À LA PROCHAINE MANCHE"
                or "KEEP YOUR STREAK ALIVE NEXT ROUND",
            Kind = "progress",
        }
    end
    local target = rewardCount(feedback.challengeTarget)
    if target > 0 and feedback.challengeCompleted ~= true then
        return {
            Text = string.format("%s  %d/%d",
                fr and "DÉFI DE CETTE MANCHE" or "THIS ROUND'S CHALLENGE",
                math.min(target, rewardCount(feedback.challengeProgress)),
                target),
            Kind = "progress",
        }
    end
    return nil
end

return ResultPresentation
