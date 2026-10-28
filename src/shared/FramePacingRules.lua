--!strict
-- Frame pacing from the existing adaptive VFX RenderStepped sampler.
-- A 1ms histogram avoids per-frame tables, sorting or a second render loop.
-- Suspended/mobile-background frames are excluded; see VfxQuality.activeFrameSeconds.
local FramePacingRules = {}

local MAX_MS = 600
local SLOW_FRAME_SECONDS = 1 / 30

function FramePacingRules.new()
    return {
        bins = {},
        count = 0,
        slow = 0,
    }
end

function FramePacingRules.add(window, seconds)
    if type(seconds) ~= "number" or seconds ~= seconds
        or seconds <= 0 or seconds > 0.60
        or seconds == math.huge or seconds == -math.huge then
        return false
    end
    local ms = math.clamp(math.ceil(seconds * 1000), 1, MAX_MS)
    window.bins[ms] = (window.bins[ms] or 0) + 1
    window.count += 1
    if seconds > SLOW_FRAME_SECONDS then
        window.slow += 1
    end
    return true
end

-- Approximate P95 at <=1ms resolution, rather than reporting only the
-- single worst frame (which is dominated by occasional OS scheduling).
-- Slow percent is the share of frames longer than 33.3ms (<30 FPS).
function FramePacingRules.summary(window)
    if window.count <= 0 then return 0, 0 end
    local rank = math.ceil(window.count * 0.95)
    local soFar = 0
    local p95 = MAX_MS
    for ms = 1, MAX_MS do
        soFar += window.bins[ms] or 0
        if soFar >= rank then
            p95 = ms
            break
        end
    end
    local slowPercent = math.floor(100 * window.slow / window.count + 0.5)
    return p95, slowPercent
end

function FramePacingRules.reset(window)
    table.clear(window.bins)
    window.count = 0
    window.slow = 0
end

return FramePacingRules
