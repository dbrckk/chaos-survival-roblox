local Players = game:GetService("Players")

local D = {Name = "RISING LAVA", Hint = "GET HIGH!"}

function D.coverageSize(baseSize, padding)
    local size = typeof(baseSize) == "Vector3" and baseSize or Vector3.new(102, 2, 102)
    local extra = math.max(0, tonumber(padding) or 8)
    return Vector3.new(
        math.max(1, size.X + extra),
        4,
        math.max(1, size.Z + extra)
    )
end

function D.rootInsideLava(rootPosition, lavaPosition, lavaSize, clearance)
    if typeof(rootPosition) ~= "Vector3"
        or typeof(lavaPosition) ~= "Vector3"
        or typeof(lavaSize) ~= "Vector3"
    then
        return false
    end

    local safeClearance = math.max(0, tonumber(clearance) or 2.5)
    local halfX = math.max(0, lavaSize.X * 0.5)
    local halfZ = math.max(0, lavaSize.Z * 0.5)
    local lavaTopY = lavaPosition.Y + (lavaSize.Y * 0.5)

    return math.abs(rootPosition.X - lavaPosition.X) <= halfX
        and math.abs(rootPosition.Z - lavaPosition.Z) <= halfZ
        and (rootPosition.Y - safeClearance) <= lavaTopY
end

function D.isActiveContestant(player, ctx)
    if not player then
        return false
    end

    if ctx.IsContestantActive then
        return ctx.IsContestantActive(player) == true
    end

    for _, contestant in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
        if contestant == player then
            return true
        end
    end

    return false
end

-- Accessories and stray limb touch events are not enough to eliminate a
-- player. Require a living current contestant's root near the lava surface,
-- while the disaster is still active.
function D.contactIsLethal(ctx, player, character, humanoid, lava)
    if not ctx or type(ctx.Active) ~= "function" or not ctx.Active()
        or not player or player.Character ~= character
        or not D.isActiveContestant(player, ctx)
        or not humanoid or humanoid.Parent ~= character or humanoid.Health <= 0
        or not lava or not lava.Parent then
        return false
    end
    -- An eligibility hook may yield while the player is eliminated,
    -- respawns, or the phase advances. Never kill an old/current rig after
    -- that transition, even if the original contact was valid.
    if not ctx.Active() or player.Character ~= character
        or humanoid.Health <= 0 or humanoid.Parent ~= character
        or not lava.Parent then
        return false
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return root ~= nil and root:IsA("BasePart")
        and D.rootInsideLava(root.Position, lava.Position, lava.Size, 2.5)
end

-- Advanced solo-disaster rounds use a telegraphed lava surge.
-- Total final rise stays exactly 25 studs. Beginner and fusion rounds
-- retain their original constant-rate floor for learnable first sessions.
-- Segments are continuous and strictly rising: slow climb, fast surge,
-- then a final controlled rise. A preview gives players time to climb.
function D.riseAt(elapsedSeconds, durationSeconds, enabled)
    local elapsed = tonumber(elapsedSeconds) or 0
    local duration = tonumber(durationSeconds) or 1
    if elapsed ~= elapsed or math.abs(elapsed) == math.huge then elapsed = 0 end
    if duration ~= duration or math.abs(duration) == math.huge or duration <= 0 then
        duration = 1
    end
    local time = math.clamp(elapsed / duration, 0, 1)
    if enabled ~= true then
        return time, nil
    end

    if time < 0.30 then
        return time * (0.28 / 0.38), "Climb"
    elseif time < 0.38 then
        return time * (0.28 / 0.38), "SurgeSoon"
    elseif time < 0.62 then
        return 0.28 + (time - 0.38) * (0.42 / 0.24), "Surge"
    end
    return 0.70 + (time - 0.62) * (0.30 / 0.38), "FinalRise"
end

-- A fixed 25-stud flood could bury every reachable deck on low maps
-- (Classic's highest platforms top out at 12 studs above the arena center).
-- Cap the lava surface two studs below the FOURTH-highest physical deck:
-- several distinct players can still reach a winning position at 0 seconds.
-- This reads the actual generated collision platforms, not decorative art.
function D.safeRiseDistance(startTopY, platformTops, maximumRise)
    local start = tonumber(startTopY)
    if not start or start ~= start or math.abs(start) == math.huge then
        start = -6
    end
    local cap = tonumber(maximumRise)
    if not cap or cap ~= cap or math.abs(cap) == math.huge then
        cap = 25
    end
    cap = math.max(0, cap)
    local heights = {}
    if type(platformTops) == "table" then
        for _, value in ipairs(platformTops) do
            local height = tonumber(value)
            if height and height == height and math.abs(height) < math.huge then
                heights[#heights + 1] = height
            end
        end
    end
    if #heights == 0 then
        -- In a partially streamed/generated arena, avoid racing upward
        -- without any verified high-ground survival route.
        return math.min(cap, 15)
    end
    table.sort(heights, function(a, b) return a > b end)
    local refuge = heights[math.min(4, #heights)]
    return math.clamp(refuge - 2 - start, 0, cap)
end

function D.start(ctx)
    local generatedMap = workspace:FindFirstChild("GeneratedMap")
    local arena = generatedMap and generatedMap:FindFirstChild("Arena")
    local base = arena and arena:FindFirstChild("Base")
    local lavaSize = D.coverageSize(
        base and base:IsA("BasePart") and base.Size or nil,
        8
    )

    local lava = Instance.new("Part")
    lava.Name = "RoundLava"
    lava.Size = lavaSize
    lava.Position = ctx.Config.ArenaCenter + Vector3.new(0, -8, 0)
    lava.Anchored = true
    lava.CanCollide = false
    lava.CanTouch = true
    lava.CanQuery = false
    lava.CastShadow = false
    lava.Material = Enum.Material.Neon
    lava.Color = Color3.fromRGB(255, 85, 0)
    lava.Parent = workspace

    lava.Touched:Connect(function(hit)
        if not ctx.Active() then return end
        local current = hit
        local character = nil
        local player = nil

        while current and current ~= workspace do
            if current:IsA("Model") then
                player = Players:GetPlayerFromCharacter(current)
                if player then
                    character = current
                    break
                end
            end
            current = current.Parent
        end

        local hum = character and character:FindFirstChildOfClass("Humanoid")
        if D.contactIsLethal(ctx, player, character, hum, lava) then
            if ctx.OnFatalHazard then
                pcall(ctx.OnFatalHazard, player, "Lava")
            end
            -- Recording the fatal cause may itself yield or end the
            -- round. Revalidate before mutating a Humanoid.
            if D.contactIsLethal(ctx, player, character, hum, lava) then
                hum.Health = 0
            end
        end
    end)

    local startY = lava.Position.Y
    local platformTops = {}
    local platforms = arena and arena:FindFirstChild("Platforms")
    if platforms then
        for _, part in ipairs(platforms:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                platformTops[#platformTops+1] = part.Position.Y + part.Size.Y * 0.5
            end
        end
    end
    local riseDistance = D.safeRiseDistance(
        startY + lava.Size.Y * 0.5, platformTops, 25
    )
    local duration = math.max(
        0.1,
        tonumber(ctx.RoundSeconds or ctx.Config.RoundSeconds) or 1
    )
    local surgeEnabled = ctx.EnableLavaSurge == true
    local started = tonumber(ctx.RoundStartedAt) or os.clock()
    ctx.LavaStage = surgeEnabled and "Climb" or nil

    ctx.Cleanup[#ctx.Cleanup+1] = lava
    if type(ctx.OnCleanup) == "table" then
        ctx.OnCleanup[#ctx.OnCleanup+1] = function()
            ctx.LavaStage = nil
        end
    end

    task.spawn(function()
        local lastStage = ctx.LavaStage
        while ctx.Active() and lava.Parent do
            local alpha, stage = D.riseAt(
                os.clock() - started, duration, surgeEnabled
            )
            lava.Position = Vector3.new(lava.Position.X, startY + alpha * riseDistance, lava.Position.Z)
            if stage ~= lastStage then
                ctx.LavaStage = stage
                lastStage = stage
                -- Distinct but restrained color language for a real hazard
                -- rate change; all warnings and the floor remain visible.
                lava.Color = stage == "Surge"
                    and Color3.fromRGB(255, 60, 18)
                    or Color3.fromRGB(255, 85, 0)
            end

            for _, player in ipairs(ctx.HazardContestants or ctx.Contestants or {}) do
                -- Use the same round/character/health checks for the
                -- periodic scan as for Touched. Do not let a scan already
                -- in progress carry a fatal hit into the next round.
                if not ctx.Active() then break end
                local character = player.Character
                local hum = character and character:FindFirstChildOfClass("Humanoid")
                if D.contactIsLethal(ctx, player, character, hum, lava) then
                    if ctx.OnFatalHazard then
                        pcall(ctx.OnFatalHazard, player, "Lava")
                    end
                    if D.contactIsLethal(ctx, player, character, hum, lava) then
                        hum.Health = 0
                    end
                end
            end

            task.wait(0.1)
        end
    end)
end

return D
