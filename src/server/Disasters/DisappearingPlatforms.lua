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

-- Advanced rounds become a two-point positioning puzzle after their
-- midpoint. Keep rookie / Double Chaos rounds single-point, and preserve
-- at least six currently traversable platforms on complex arenas.
-- Only actual round time authorizes escalation: intensity alone can be
-- high on short, beginner-friendly Solo Rush rounds.
function D.waveSize(ctx, eligibleCount, now)
    if type(ctx) ~= "table" or ctx.EnableCollapseWaves ~= true
        or (tonumber(eligibleCount) or 0) < 8 then
        return 1
    end
    local started = tonumber(ctx.RoundStartedAt)
    local duration = tonumber(ctx.RoundSeconds)
    local clock = tonumber(now)
    if not started or not duration or not clock
        or started ~= started or duration ~= duration or clock ~= clock
        or math.abs(started) == math.huge or math.abs(clock) == math.huge
        or duration < 24 or duration == math.huge then
        return 1
    end
    return clock - started >= duration * 0.55 and 2 or 1
end

-- Never take two adjacent platforms at once. Start with a random platform,
-- then use the most distant available deck only if it is at least 18 studs
-- away. This preserves a navigable safe corridor rather than making an
-- unavoidable single choke point disappear wholesale.
function D.chooseWavePlatforms(eligible, requested, startingIndex)
    local selected = {}
    if type(eligible) ~= "table" or #eligible == 0 then
        return selected
    end
    local start = tonumber(startingIndex)
    if not start or start < 1 or start > #eligible
        or start ~= math.floor(start) then
        start = math.random(1, #eligible)
    end
    local first = eligible[start]
    if not first or not first:IsA("BasePart") then return selected end
    selected[1] = first

    if tonumber(requested) ~= 2 or #eligible < 8 then
        return selected
    end
    local farthest, distance = nil, 18
    for _, part in ipairs(eligible) do
        if part ~= first and part:IsA("BasePart") then
            local delta = part.Position - first.Position
            local separation = Vector3.new(delta.X, 0, delta.Z).Magnitude
            if separation > distance then
                farthest, distance = part, separation
            end
        end
    end
    if farthest then selected[2] = farthest end
    return selected
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
                -- Outer exit facades belong to a specific physical deck.
                -- Collapse them with collision, never leave a fake bridge.
                or (item:GetAttribute("PerimeterPlatformIndex")
                    and tostring(item:GetAttribute("PerimeterPlatformIndex")))
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
        end
    end

    ctx.OnCleanup[#ctx.OnCleanup+1] = function()
        generation += 1
        ctx.DoubleCollapseUnlocked = nil
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
            local chosen = D.chooseWavePlatforms(
                parts, D.waveSize(ctx, #parts, os.clock())
            )
            if #chosen > 0 then
                local staged = {}
                local serverStart = workspace:GetServerTimeNow()
                for _, p in ipairs(chosen) do
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
                    staged[#staged + 1] = {part = p, token = token}

                    D.setCosmeticsPhase(activeStates[p].cosmetics, "Warning")
                    -- A single timestamp synchronizes both clear warning
                    -- contours on spectators, humans and mobile clients.
                    p:SetAttribute("CollapseWarningStartedAt", serverStart)
                    p:SetAttribute("CollapsePhase", "Warning")
                    p.Color = Color3.fromRGB(255, 205, 70)
                    p.Material = Enum.Material.Neon

                    -- Local animated warning edges use the same contract as
                    -- single-platform waves; only physical decks disappear.
                    p.Transparency = math.min(p.Transparency, 0.24)
                end
                -- Mark the mechanic unlocked only AFTER both real warning
                -- decks were staged. Some beats can later use a single deck
                -- while earlier ones finish restoring; keep the hint truthful
                -- as a warning about a possible paired collapse.
                if #staged >= 2 then
                    ctx.DoubleCollapseUnlocked = true
                end

                task.wait(D.WarningSeconds)
                for _, entry in ipairs(staged) do
                    local p, token = entry.part, entry.token
                    local state = activeStates[p]
                    if ctx.Active() and state
                        and state.generation == token and p.Parent then
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
            end

            local intensity = ctx.Intensity and ctx.Intensity() or 1
            task.wait(math.max(0.95, 1.4 / intensity))
        end
    end)
end

return D
