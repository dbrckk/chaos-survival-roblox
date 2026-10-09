-- Small, deterministic stage choreography for holographic *props*.
-- Does not manipulate real player rigs, Humanoids, Motor6D or game state.
-- Up to two figures are updated using the existing Showtime update cadence.
local ShowtimeChoreography = {}

local valid = {
    dance = true, shuffle = true, groove = true,
    cheer = true, wave = true, laugh = true,
}

function ShowtimeChoreography.style(now, index, leadEmote, audience)
    local emote = tostring(leadEmote or "")
    if valid[emote] and (tonumber(audience) or 0) > 0 then
        return emote
    end
    local cycle = {"groove", "shuffle", "dance", "wave", "cheer", "laugh"}
    local beat = math.floor(math.max(0, tonumber(now) or 0) / 3.8)
    return cycle[((beat + math.max(1, math.floor(tonumber(index) or 1)) - 1)
        % #cycle) + 1]
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
