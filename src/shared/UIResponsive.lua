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

    local topHeight = c.tinyHeight and 56 or (c.compactHeight and 60 or 68)
    local timerSize = c.tinyHeight and 44 or (c.compactHeight and 48 or 54)
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
        topWidthScale = c.veryNarrow and 0.96 or (c.narrowWidth and 0.92 or (c.wide and 0.82 or 0.88)),
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
        roundFocusWidthScale = c.veryNarrow and 0.90 or (c.narrowWidth and 0.82 or (c.wide and 0.52 or 0.68)),
        roundFocusHeight = c.tinyHeight and 42 or 46,
        roundFocusBottomOffset = c.tinyHeight and 72 or (c.compactHeight and 84 or 96),
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
