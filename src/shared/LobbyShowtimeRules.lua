-- Phase-gated, asset-backed emotes and device-scaled lobby showtime.
-- No gameplay bonuses or server permissions are associated with emotes.
local LobbyShowtimeRules = {}

LobbyShowtimeRules.Emotes = {
    dance = {
        R15 = 507771019,
        R6 = 182435998,
        Loop = true,
        LabelEN = "DANCE",
        LabelFR = "DANSE",
    },
    shuffle = {
        R15 = 507776043,
        R6 = 182436842,
        Loop = true,
        LabelEN = "SHUFFLE",
        LabelFR = "SHUFFLE",
    },
    cheer = {
        R15 = 507770677,
        R6 = 129423030,
        Loop = false,
        LabelEN = "CHEER",
        LabelFR = "BRAVO",
    },
    wave = {
        R15 = 507770239,
        R6 = 128777973,
        Loop = false,
        LabelEN = "WAVE",
        LabelFR = "SALUT",
    },
}

LobbyShowtimeRules.Order = {"dance", "shuffle", "cheer", "wave"}

function LobbyShowtimeRules.enabled(phase, voteOptions)
    local current = tostring(phase or "")
    return current == "waiting"
        or current == "result"
        or (
            current == "intermission"
            and not (type(voteOptions) == "table" and #voteOptions > 0)
        )
end

function LobbyShowtimeRules.canEmote(phase, voteOptions, health)
    return LobbyShowtimeRules.enabled(phase, voteOptions)
        and (tonumber(health) or 0) > 0
end

function LobbyShowtimeRules.get(id, rigType)
    local definition = LobbyShowtimeRules.Emotes[id]
    local rig = tostring(rigType or "")
    if not definition then
        return nil
    end
    local animationId = definition[rig]
    if type(animationId) ~= "number" or animationId <= 0 then
        return nil
    end
    return {
        AnimationId = animationId,
        Loop = definition.Loop,
        LabelEN = definition.LabelEN,
        LabelFR = definition.LabelFR,
    }
end

function LobbyShowtimeRules.profile(tier)
    local name = tostring(tier or "Low")
    if name == "High" then
        return {Grid = 5, Dancers = 2, Lights = 2, Bursts = 18, Interval = 0.10}
    elseif name == "Medium" then
        return {Grid = 4, Dancers = 1, Lights = 1, Bursts = 10, Interval = 0.16}
    end
    return {Grid = 3, Dancers = 0, Lights = 0, Bursts = 4, Interval = 0.26}
end

return LobbyShowtimeRules
