local UIResponsive = {}

function UIResponsive.classify(viewport, touch)
    local size = typeof(viewport) == "Vector2" and viewport or Vector2.new(1280, 720)
    local width = math.max(1, size.X)
    local height = math.max(1, size.Y)
    local aspect = width / height

    local tinyHeight = height < 420
    local compactHeight = height < 500
    local narrowWidth = width < 680
    local veryNarrow = width < 560
    local wide = aspect > 2.0

    return {
        touch = touch == true,
        width = width,
        height = height,
        aspect = aspect,
        tinyHeight = tinyHeight,
        compactHeight = compactHeight,
        narrowWidth = narrowWidth,
        veryNarrow = veryNarrow,
        wide = wide,
    }
end

function UIResponsive.mobileProfile(viewport)
    local c = UIResponsive.classify(viewport, true)

    local topHeight = c.tinyHeight and 46 or (c.compactHeight and 50 or 54)
    local timerSize = c.tinyHeight and 42 or (c.compactHeight and 44 or 46)
    local dockHeight = c.tinyHeight and 52 or 58
    local buttonHeight = c.tinyHeight and 44 or 48
    local coachHeight = c.tinyHeight and 40 or (c.compactHeight and 42 or 44)

    local voteHeight
    if c.tinyHeight then
        voteHeight = 138
    elseif c.compactHeight then
        voteHeight = 158
    else
        voteHeight = 176
    end

    return {
        narrowWidth = c.narrowWidth,
        veryNarrow = c.veryNarrow,
        tinyHeight = c.tinyHeight,
        compactHeight = c.compactHeight,
        wide = c.wide,
        -- On wide touch screens, reserve distinct lanes for PHOTO (left)
        -- and DASH (right) instead of extending the top header underneath.
        -- On wide landscape phones the Roblox native menu/chat rail owns
        -- the upper left ~28% of the screen (visible in Android captures).
        -- Offset the phase header right so the first words remain legible.
        topCenterXScale = c.wide and 0.60 or 0.50,
        topWidthScale = c.veryNarrow and 0.94 or (c.narrowWidth and 0.90 or (c.wide and 0.60 or 0.82)),
        topHeight = topHeight,
        timerSize = timerSize,
        dockWidthScale = c.veryNarrow and 0.98 or 0.94,
        dockHeight = dockHeight,
        dockButtonHeight = buttonHeight,
        voteWidthScale = c.veryNarrow and 0.98 or 0.94,
        voteHeight = voteHeight,
        coachWidthScale = c.veryNarrow and 0.92 or (c.wide and 0.72 or 0.82),
        coachHeight = coachHeight,
        resultWidthScale = c.veryNarrow and 0.96 or (c.wide and 0.70 or 0.88),
        resultHeight = c.tinyHeight and 176 or (c.compactHeight and 196 or 218),
        panelWidthScale = c.veryNarrow and 0.96 or (c.narrowWidth and 0.92 or 0.84),
        panelBottomOffset = dockHeight + 12,
        toastWidthScale = c.veryNarrow and 0.92 or 0.84,
        roundFocusWidthScale = c.veryNarrow and 0.90 or (c.narrowWidth and 0.82 or (c.wide and 0.48 or 0.68)),
        roundFocusHeight = c.tinyHeight and 42 or 46,
        roundFocusBottomOffset = c.tinyHeight and 72 or (c.compactHeight and 84 or 96),
    }
end

-- Optional district routes are secondary to survival alerts on touch.
-- Account for Roblox's native top-bar inset; unlike the primary ChaosHUD,
-- the expedition ScreenGui ignores the inset. Never overlap the header or
-- the bottom survival meter. If there is no room, hide this optional cue.
function UIResponsive.mobileExpeditionLayout(viewport, topInset)
    local c = UIResponsive.classify(viewport, true)
    local profile = UIResponsive.mobileProfile(viewport)
    local height = profile.tinyHeight and 46 or 51
    local inset = math.clamp(tonumber(topInset) or 0, 0, c.height)
    local minimumTop = inset + profile.topHeight + 48
    -- The top-center survival hazard is inset by Roblox native controls.
    -- On landscape phones, put the OPTIONAL route in the lower-left side
    -- lane, rather than the same top-center lane as the hazard banner.
    local targetTop = math.max(profile.topHeight + 62,
        inset + profile.topHeight + 78, c.height * 0.53)
    local maximumTop = c.height - profile.roundFocusBottomOffset - height - 10
    return {
        xScale = c.wide and 0.23 or 0.50,
        width = math.min(profile.veryNarrow and 190 or 208,
            math.max(168, c.width - 20)),
        height = height,
        topOffset = math.max(0, math.min(targetTop, maximumTop)),
        fits = maximumTop >= minimumTop,
    }
end

function UIResponsive.showOptionalRoute(hazardVisible, roundEventVisible, introVisible)
    return hazardVisible ~= true
        and roundEventVisible ~= true
        and introVisible ~= true
end

-- Foreground escalation uses one compact toast lane, never a second
-- full-width strip over the authoritative GEL / hazard timer.
function UIResponsive.mobileEscalationToast(viewport)
    local c = UIResponsive.classify(viewport, true)
    return {
        centerXScale = 0.50,
        centerYScale = c.tinyHeight and 0.43 or 0.43,
        widthScale = c.veryNarrow and 0.82 or (c.wide and 0.34 or 0.58),
        height = c.tinyHeight and 38 or 44,
        titleMaxTextSize = c.tinyHeight and 18 or 21,
        subtitleMaxTextSize = c.tinyHeight and 12 or 14,
    }
end

-- Optional pickup feedback stays out of the center avatar/camera lane.
-- Short phones may hide the route while this reward is on screen.
function UIResponsive.mobileShardToast(viewport)
    local c = UIResponsive.classify(viewport, true)
    return {
        centerXScale = c.wide and 0.23 or 0.50,
        centerYScale = c.tinyHeight and 0.70 or 0.69,
        width = c.veryNarrow and 184 or 230,
        height = c.tinyHeight and 34 or 40,
    }
end

-- Primary round introductions should not cover the avatar and other
-- survivors on Android. The warning timer already occupies the top edge:
-- place the short reveal directly below it, never across screen center.
function UIResponsive.mobileRoundBanner(viewport)
    local c = UIResponsive.classify(viewport, true)
    return {
        widthScale = c.veryNarrow and 0.90
            or (c.narrowWidth and 0.86 or (c.wide and 0.73 or 0.80)),
        height = c.tinyHeight and 54 or (c.compactHeight and 58 or 64),
        centerYScale = 0.39,
        titleMaxTextSize = c.tinyHeight and 19 or 24,
        subtitleMaxTextSize = c.tinyHeight and 13 or 17,
    }
end

-- One safe, testable layout for the client-owned Dash action button.
-- The native Roblox jump control uses the bottom-right thumb zone.
-- Keep DASH above it, fully inside the visible viewport even when rotated
-- to a short Android landscape orientation. Sizes are physical pixels.
function UIResponsive.phaseDashLayout(viewport)
    local c = UIResponsive.classify(viewport, true)
    local width = c.veryNarrow and 74 or (c.compactHeight and 82 or 94)
    local height = c.tinyHeight and 48 or 54
    local rightInset = c.veryNarrow and 12 or 20
    local bottomInset = math.clamp(c.height * 0.32, 160, 208)
    -- In extremely shallow viewports, keep the whole control visible
    -- below the hazard header; never shrink its touch target to fit.
    bottomInset = math.min(bottomInset, math.max(0, c.height - height - 66))
    return {
        width = width,
        height = height,
        rightInset = rightInset,
        bottomInset = bottomInset,
        -- Room to the LEFT of the button, outside the top hazard HUD.
        hintWidth = math.min(168, width + 80,
            math.max(72, c.width - rightInset - width - 16)),
    }
end

function UIResponsive.criticalTextMin(viewport)
    local c = UIResponsive.classify(viewport, true)
    if c.tinyHeight then
        return 13
    elseif c.compactHeight then
        return 14
    end
    return 15
end

function UIResponsive.touchTargetSatisfied(height)
    return (tonumber(height) or 0) >= 44
end

return UIResponsive
