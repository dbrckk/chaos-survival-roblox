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
    groove = {
        R15 = 507777268,
        R6 = 182436935,
        Loop = true,
        LabelEN = "GROOVE",
        LabelFR = "GROOVE",
    },
    laugh = {
        R15 = 507770818,
        R6 = 129423131,
        Loop = false,
        LabelEN = "LAUGH",
        LabelFR = "RIRE",
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
    -- Original joint choreography generated at runtime: no third-party
    -- animation asset or paid catalog dependency.
    robot = {
        Procedural = true, Loop = true,
        LabelEN = "NEON ROBOT", LabelFR = "ROBOT NEON",
    },
    orbit = {
        Procedural = true, Loop = true,
        LabelEN = "ORBIT DANCE", LabelFR = "DANSE ORBITE",
    },
}

LobbyShowtimeRules.Order = {"dance", "shuffle", "groove", "robot", "orbit", "cheer", "wave", "laugh"}

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
    if definition.Procedural == true then
        if rig ~= "R15" and rig ~= "R6" then
            return nil
        end
        return {
            Procedural = true,
            Loop = true,
            LabelEN = definition.LabelEN,
            LabelFR = definition.LabelFR,
        }
    end
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

-- Coordinate with AccessibilityQuickSettings at the top-right of the screen.
-- Reserve its expanded settings panel, not only its toggle button.
-- On narrow portrait screens, the settings panel occupies the right edge.
-- Dock Showtime on the left rather than clipping the emote grid offscreen.
function LobbyShowtimeRules.dockSide(viewportWidth, touch)
    return touch == true and (tonumber(viewportWidth) or 1280) < 450
        and "left" or "right"
end

function LobbyShowtimeRules.dockRightInset(viewportWidth, touch, veryNarrow)
    local width = math.max(1, tonumber(viewportWidth) or 1280)
    local rightGap = touch == true and 10 or width * 0.015
    local settingsPanelWidth = touch == true
        and (veryNarrow == true and 176 or 186)
        or 178
    return math.ceil(rightGap + settingsPanelWidth + 12)
end

-- One voluntary-feeling victory flourish on entry to RESULT: survivor only.
-- Do not replay on the server's once-per-second result timer snapshots.
function LobbyShowtimeRules.shouldCelebrate(phase, previousPhase, survivorUserIds, userId, reduceMotion)
    if phase ~= "result" or previousPhase == "result" or reduceMotion == true
        or type(survivorUserIds) ~= "table"
    then
        return false
    end
    for _, survivorId in ipairs(survivorUserIds) do
        if survivorId == userId then
            return true
        end
    end
    return false
end

function LobbyShowtimeRules.spatialBeatActive(phase, voteOptions, distance, muted)
    return LobbyShowtimeRules.enabled(phase, voteOptions)
        and muted ~= true
        and (tonumber(distance) or math.huge) <= 24
end

-- Non-blocking radial light wave launched by a nearby avatar emote.
-- Distance is world-space studs; age is seconds since the emote began.
function LobbyShowtimeRules.floorPulse(distance, age, reduceMotion)
    if reduceMotion == true then
        return 0
    end
    local elapsed = tonumber(age)
    if elapsed == nil or elapsed < 0 or elapsed > 1.45 then
        return 0
    end
    local radius = elapsed * 12
    local delta = math.abs((tonumber(distance) or math.huge) - radius)
    local ring = math.clamp(1 - delta / 2.55, 0, 1)
    return ring * math.clamp(1 - elapsed / 1.45, 0, 1)
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
