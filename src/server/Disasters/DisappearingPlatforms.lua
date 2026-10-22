local D = {Name = "DISAPPEARING PLATFORMS", Hint = "YELLOW MEANS MOVE!"}

-- A 0.75s warning was too short for a mobile player or a normal-speed AI
-- to notice a distant platform signal and walk off its edge. This delay
-- is deliberately shared across player and bot physics; there is no
-- dedicated bot grace period or teleport.
D.WarningSeconds = 1.35
D.GoneSeconds = 2.0
D.RoundEndBufferSeconds = 2.0

-- Do not start a new collapse so late in a short Solo Rush round that
-- its full warning and outage cannot finish before results begin.
function D.canBegin(ctx, now)
    local deadline = ctx and tonumber(ctx.RoundEndsAt)
    if not deadline then return true end
    return (tonumber(now) or 0)
        + D.WarningSeconds + D.GoneSeconds + D.RoundEndBufferSeconds
        <= deadline
end

-- In experienced solo-hazard rounds the physical deck failures form
-- readable, repeatable acts instead of choosing an arbitrary tile every time.
-- This changes which real platform is at risk, not warning time, collision,
-- damage, cadence or the number of simultaneous collapses.
function D.waveMode(ctx, now, platformCount)
    if type(ctx) ~= "table" or ctx.EnablePlatformWaves ~= true
        or (tonumber(platformCount) or 0) < 4 then
        return "Scatter"
    end
    local start = tonumber(ctx.RoundStartedAt)
    local duration = tonumber(ctx.RoundSeconds)
    local clock = tonumber(now)
    if not start or not duration or not clock
        or start ~= start or duration ~= duration or clock ~= clock
        or duration < 24 or duration == math.huge
        or math.abs(start) == math.huge or math.abs(clock) == math.huge then
        return "Scatter"
    end
    local progress = math.clamp((clock - start) / duration, 0, 1)
    if progress < 0.34 then return "Scatter" end
    if progress < 0.69 then return "Sweep" end
    return "Flanks"
end

function D.choosePlatform(parts, mode, sequence, previous, roundNumber)
    if type(parts) ~= "table" or #parts == 0 then return nil end
    local eligible = {}
    for _, part in ipairs(parts) do
        if typeof(part) == "Instance" and part:IsA("BasePart")
            and part.Parent and part.CanCollide
            and part:GetAttribute("ChaosSkybridge") ~= true
            and (part ~= previous or #parts == 1) then
            eligible[#eligible + 1] = part
        end
    end
    if #eligible == 0 then return nil end
    if mode ~= "Sweep" and mode ~= "Flanks" then
        return eligible[math.random(1, #eligible)]
    end

    -- A left-to-right or right-to-left sweep is determined by true
    -- world coordinates, not random names (maps all use different layouts).
    -- Reverse the direction between rounds for an extra skill challenge.
    local reverse = math.floor(tonumber(roundNumber) or 1) % 2 == 0
    table.sort(eligible, function(a, b)
        local difference = a.Position.X - b.Position.X
        if math.abs(difference) < 0.01 then
            difference = a.Position.Z - b.Position.Z
        end
        if math.abs(difference) < 0.01 then
            return a.Name < b.Name
        end
        return reverse and difference > 0 or difference < 0
    end)

    local beat = math.max(1, math.floor(tonumber(sequence) or 1))
    if mode == "Flanks" then
        -- Alternate opposite walkable flanks, with the SAME 1.35s warning
        -- and only one physical outage. No surprise simultaneous collapse.
        return eligible[beat % 2 == 1 and 1 or #eligible]
    end
    return eligible[((beat - 1) % #eligible) + 1]
end

function D.eligiblePlatforms(folder, activeStates)
    local result = {}
    if not folder then
        return result
    end

    for _, item in ipairs(folder:GetChildren()) do
        if item:IsA("BasePart")
            and item.CanCollide
            -- Tower Run's engineered skybridges are permanent route backbones.
            -- Their attached visual rails must never advertise a phantom path.
            and item:GetAttribute("ChaosSkybridge") ~= true
            and not activeStates[item]
        then
            result[#result+1] = item
        end
    end

    return result
end

-- The physical platform is not the only thing visible: server-authored
-- deck panels, subframes, core glow and structural supports must follow its
-- disappearance. Otherwise players see a phantom floor after collision is
-- disabled. Skybridges are intentionally permanent and never eligible.
function D.cosmeticsForPlatform(decor, platform)
    if not decor or not platform or not platform:IsA("BasePart") then
        return {}
    end
    local index = platform.Name:match("^Platform(%d+)$")
    if not index then return {} end

    local result = {}
    for _, item in ipairs(decor:GetChildren()) do
        if item:IsA("BasePart") then
            local attachedIndex =
                item.Name:match("^PlatformGlow(%d+)$")
                or item.Name:match("^PlatformPanel(%d+)$")
                or item.Name:match("^PlatformUnderFrame(%d+)$")
                or item.Name:match("^PlatformCoreGlow(%d+)$")
                or item.Name:match("^PlatformSupport(%d+)_%d+$")
                or item.Name:match("^PlatformBevel(%d+)_%d+$")
            if attachedIndex == index then
                table.insert(result, {
                    part = item,
                    transparency = item.Transparency,
                })
            end
        end
    end
    return result
end

function D.setCosmeticsPhase(cosmetics, phase)
    for _, entry in ipairs(cosmetics or {}) do
        local piece = entry.part
        if piece and piece.Parent then
            if phase == "Gone" then
                piece.Transparency = 1
            elseif phase == "Warning" then
                -- Expose the amber authoritative warning deck through the
                -- opaque top panel instead of camouflaging a collapse.
                piece.Transparency = math.max(entry.transparency,
                    piece.Name:match("^PlatformPanel") and 0.80 or 0.60)
            else
                piece.Transparency = entry.transparency
            end
        end
    end
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local folder = arena and arena:FindFirstChild("Platforms")
    if not folder then
        return
    end

    local decor = arena and arena:FindFirstChild("Decor")
    local activeStates = {}
    local generation = 0
    local lastSelected = nil
    local waveBeat = 0
    local lastWaveMode = nil

    local function restore(part)
        local state = activeStates[part]
        if not state then
            return
        end

        activeStates[part] = nil
        if part and part.Parent then
            part.Transparency = state.transparency
            part.CanCollide = state.canCollide
            part.Color = state.color
            part.Material = state.material
            D.setCosmeticsPhase(state.cosmetics, nil)
            part:SetAttribute("CollapsePhase", nil)
            part:SetAttribute("CollapseWarningStartedAt", nil)
            part:SetAttribute("CollapseWaveMode", nil)
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        generation += 1
        local parts = {}
        for part in pairs(activeStates) do
            table.insert(parts, part)
        end
        for _, part in ipairs(parts) do
            restore(part)
        end
    end

    task.spawn(function()
        while ctx.Active() and folder.Parent do
            if not D.canBegin(ctx, os.clock()) then break end
            local parts = D.eligiblePlatforms(folder, activeStates)
            if #parts > 0 then
                local mode = D.waveMode(ctx, os.clock(), #parts)
                if mode ~= lastWaveMode then
                    waveBeat = 0
                    lastWaveMode = mode
                end
                waveBeat += 1
                local p = D.choosePlatform(
                    parts, mode, waveBeat, lastSelected, ctx.RoundNumber
                )
                if not p then break end
                lastSelected = p
                generation += 1
                local token = generation
                activeStates[p] = {
                    transparency = p.Transparency,
                    canCollide = p.CanCollide,
                    color = p.Color,
                    material = p.Material,
                    generation = token,
                    cosmetics = D.cosmeticsForPlatform(decor, p),
                }

                D.setCosmeticsPhase(activeStates[p].cosmetics, "Warning")
                p:SetAttribute("CollapseWaveMode", mode ~= "Scatter" and mode or nil)
                p:SetAttribute("CollapseWarningStartedAt", workspace:GetServerTimeNow())
                p:SetAttribute("CollapsePhase", "Warning")
                p.Color = Color3.fromRGB(255, 205, 70)
                p.Material = Enum.Material.Neon

                -- Keep one authoritative replicated fallback cue. The animated
                -- edge/cross pulse is client-owned by disappearing-platform-readability,
                -- avoiding repeated server property replication for cosmetic motion.
                p.Transparency = math.min(p.Transparency, 0.24)
                p.Color = Color3.fromRGB(255, 205, 70)
                task.wait(D.WarningSeconds)
                local state = activeStates[p]
                if ctx.Active() and state and state.generation == token and p.Parent then
                    p:SetAttribute("CollapsePhase", "Gone")
                    p.Transparency = 1
                    p.CanCollide = false
                    D.setCosmeticsPhase(state.cosmetics, "Gone")

                    task.delay(D.GoneSeconds, function()
                        local delayedState = activeStates[p]
                        if delayedState and delayedState.generation == token then
                            restore(p)
                        end
                    end)
                else
                    restore(p)
                end
            end

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.95, 1.4 / intensity))
        end
    end)
end

return D
