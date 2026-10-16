-- Small, deterministic stage choreography for holographic *props*.
-- Does not manipulate real player rigs, Humanoids, Motor6D or game state.
-- Up to two figures are updated using the existing Showtime update cadence.
local ShowtimeChoreography = {}

local valid = {
    dance = true, shuffle = true, groove = true,
    cheer = true, wave = true, laugh = true,
    robot = true, orbit = true,
}

function ShowtimeChoreography.style(now, index, leadEmote, audience)
    local emote = tostring(leadEmote or "")
    if valid[emote] and (tonumber(audience) or 0) > 0 then
        return emote
    end
    local cycle = {"groove", "shuffle", "robot", "dance", "orbit", "wave", "cheer", "laugh"}
    local beat = math.floor(math.max(0, tonumber(now) or 0) / 3.8)
    return cycle[((beat + math.max(1, math.floor(tonumber(index) or 1)) - 1)
        % #cycle) + 1]
end

-- A restrained, localized marquee responds to real participation. It is
-- information in existing UI, not a new surface or a flashing overlay.
function ShowtimeChoreography.caption(leadEmote, audience, french)
    local crowd = math.clamp(math.floor(tonumber(audience) or 0), 0, 4)
    if crowd == 0 then
        return french == true and "PISTE DE DANSE" or "CHAOS SHOWTIME"
    end
    local labels = {
        dance = {"DANSE", "DANCE"},
        shuffle = {"SHUFFLE", "SHUFFLE"},
        groove = {"GROOVE", "GROOVE"},
        cheer = {"BRAVO", "CHEER"},
        wave = {"SALUT", "WAVE"},
        laugh = {"RIRE", "LAUGH"},
        robot = {"ROBOT NEON", "NEON ROBOT"},
        orbit = {"ORBITALE", "ORBIT DANCE"},
    }
    local entry = labels[tostring(leadEmote or "")]
    if entry then
        return french == true and ("EN DUO / " .. entry[1])
            or ("DUET / " .. entry[2])
    end
    if crowd >= 2 then
        return french == true and "DANSONS ENSEMBLE" or "DANCE TOGETHER"
    end
    return french == true and "REJOINS LA DANSE" or "JOIN THE FLOOR"
end

function ShowtimeChoreography.pose(now, index, leadEmote, audience, reduceMotion)
    local style = ShowtimeChoreography.style(now, index, leadEmote, audience)
    local stationary = reduceMotion == true
    local t = stationary and 0 or math.max(0, tonumber(now) or 0)
    local performer = math.max(1, math.floor(tonumber(index) or 1))
    local group = math.clamp(tonumber(audience) or 0, 0, 4)
    local rhythm = t * (style == "shuffle" and 3.5 or 2.6)
        + (performer - 1) * math.pi
    local beat = stationary and 0 or math.sin(rhythm)
    local sway = stationary and 0 or math.sin(rhythm * 0.5)
    local energy = stationary and 0 or (0.82 + group * 0.045)

    -- Pose fields are angles in radians, offsets in studs, all tightly bounded.
    local pose = {
        Style = style,
        Sway = sway * 0.42 * energy,
        Bob = math.abs(beat) * 0.12 * energy,
        Yaw = sway * 0.17,
        Roll = sway * 0.075,
        HeadYaw = -sway * 0.16,
        ArmL = -0.24 - beat * 0.30,
        ArmR = 0.24 - beat * 0.30,
        ArmSwing = beat * 0.20,
        LegSwing = beat * 0.22,
        ShoulderRoll = 0.12,
    }
    if style == "shuffle" then
        pose.Sway = sway * 0.54 * energy
        pose.Yaw = beat * 0.26
        pose.ArmL = -0.48 - beat * 0.21
        pose.ArmR = 0.38 + beat * 0.24
        pose.LegSwing = beat * 0.48
    elseif style == "dance" then
        pose.Yaw = math.sin(rhythm * 0.5) * 0.37
        pose.Bob = math.abs(beat) * 0.20 * energy
        pose.ArmL = -0.82 - beat * 0.30
        pose.ArmR = 0.82 - beat * 0.30
        pose.LegSwing = beat * 0.32
    elseif style == "groove" then
        pose.Sway = sway * 0.49 * energy
        pose.ArmL = -0.32 + beat * 0.40
        pose.ArmR = 0.32 + beat * 0.40
        pose.Roll = sway * 0.19
    elseif style == "cheer" then
        pose.Bob = math.abs(beat) * 0.14 * energy
        pose.ArmL = -1.34 - beat * 0.15
        pose.ArmR = 1.34 + beat * 0.15
        pose.LegSwing = beat * 0.11
    elseif style == "wave" then
        pose.Bob = 0
        pose.ArmL = -0.14
        pose.ArmR = 1.28 + math.sin(rhythm * 2) * 0.29
        pose.HeadYaw = 0.20 + sway * 0.08
        pose.LegSwing = 0
    elseif style == "laugh" then
        pose.Sway = 0
        pose.Yaw = 0
        pose.Roll = beat * 0.09
        pose.Bob = math.abs(beat) * 0.065
        pose.ArmL = -0.46
        pose.ArmR = 0.46
        pose.LegSwing = 0
    elseif style == "robot" then
        -- An original stepped silhouette with clean mechanical accents.
        -- The discretized beats contrast with ordinary smooth emote loops.
        local step = stationary and 0 or math.floor((t * 3.8 + performer) % 8)
        local side = step % 2 == 0 and 1 or -1
        pose.Sway = side * 0.13 * energy
        pose.Bob = step % 4 == 0 and 0.12 or 0
        pose.Yaw = side * 0.22
        pose.Roll = -side * 0.08
        pose.ArmL = -0.68 + side * 0.48
        pose.ArmR = 0.68 + side * 0.48
        pose.HeadYaw = -side * 0.24
        pose.LegSwing = side * 0.24
        pose.ArmSwing = 0
    elseif style == "orbit" then
        -- Interlaced upper-body orbit and opposing feet; no spins of
        -- HumanoidRootPart or camera, so the player stays in control.
        pose.Sway = math.sin(rhythm * 0.5) * 0.28 * energy
        pose.Yaw = math.sin(rhythm * 0.75) * 0.42
        pose.Roll = math.cos(rhythm * 0.5) * 0.18
        pose.Bob = (0.5 + 0.5 * math.sin(rhythm)) * 0.15 * energy
        pose.ArmL = -0.72 - math.sin(rhythm) * 0.52
        pose.ArmR = 0.72 + math.cos(rhythm) * 0.52
        pose.HeadYaw = -pose.Yaw * 0.65
        pose.LegSwing = math.sin(rhythm * 0.6) * 0.32
        pose.ArmSwing = math.sin(rhythm * 0.65) * 0.16
    end
    if stationary then
        -- Reduced motion is a quiet, static pose: no shaking or dancing.
        pose.Sway = 0
        pose.Bob = 0
        pose.Yaw = 0
        pose.Roll = 0
        pose.HeadYaw = 0
        pose.LegSwing = 0
        pose.ArmSwing = 0
    end
    return pose
end

return ShowtimeChoreography
