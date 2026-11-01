-- STRUCTURAL CATACLYSM / FIVE ARENAS
-- An actual server-owned destruction of the six NONCOLLIDING monumental
-- gateway assemblies. Real meteor/bomb impacts or a sustained tornado/lava
-- cause visible progressive failures; the physical 200-stud promenades,
-- warnings, damage rules and 8-player spawns remain untouched.
--
-- No extra damage, deceptive collider, new remote or external asset.
-- Server tweens replicate the same structural destruction to all viewers.
local TweenService = game:GetService("TweenService")

local StructuralCollapse = {}
StructuralCollapse.MinBetweenFailures = 3.0
StructuralCollapse.MaxFailures = 6
StructuralCollapse.FractureSeconds = 1.15
StructuralCollapse.InitialWindStressSeconds = 6.5
StructuralCollapse.StressIntervalSeconds = 5.0

local VALID_IMPACTS = {Meteor = true, Bomb = true}
local VALID_STRESS = {Tornado = true, RisingLava = true}

function StructuralCollapse.enabled(ctx)
    if type(ctx) ~= "table" or type(ctx.Active) ~= "function"
        or type(ctx.OnCleanup) ~= "table"
        or type(ctx.ActiveDisasters) ~= "table" then return false end
    -- A simultaneous ShrinkingArena owns deck-relative decorations every
    -- 0.15s. Never let a collapse tween fight its CFrame/Size restoration.
    if ctx.ActiveDisasters.ShrinkingArena == true then return false end
    for id in pairs(ctx.ActiveDisasters) do
        if id == "Meteors" or id == "Bombs" or VALID_STRESS[id] then
            return true
        end
    end
    return false
end

function StructuralCollapse.findGateways(arena)
    local groups = {}
    if not arena then return groups end
    local platforms = arena:FindFirstChild("Platforms")
    local decor = arena:FindFirstChild("Decor")
    if not platforms or not decor then return groups end

    for _, part in ipairs(decor:GetChildren()) do
        if part:IsA("BasePart")
            and part:GetAttribute("PromenadeVisualOnly") == true
            and part.CanCollide == false
            and part.CanTouch == false
            and part.CanQuery == false then
            local index = part:GetAttribute("PerimeterPlatformIndex")
            if type(index) == "number" and index % 1 == 0
                and index > 0 then
                local gate = groups[index]
                if not gate then
                    local platform = platforms:FindFirstChild(
                        "Platform" .. tostring(index))
                    if platform and platform:IsA("BasePart")
                        and platform:GetAttribute("PromenadeLane") ~= nil
                        and platform:GetAttribute("PromenadeStep") ~= nil then
                        gate = {platform = platform, parts = {}, index = index}
                        groups[index] = gate
                    end
                end
                if gate then
                    gate.parts[#gate.parts + 1] = part
                end
            end
        end
    end
    local ordered = {}
    for _, group in pairs(groups) do
        if #group.parts >= 6 and group.platform.Parent then
            table.sort(group.parts, function(a, b) return a.Name < b.Name end)
            ordered[#ordered + 1] = group
        end
    end
    table.sort(ordered, function(a, b) return a.index < b.index end)
    return ordered
end

-- A source-only pure geometry rule: farther structural sections visibly
-- pitch and fall in opposite directions, creating distinct break silhouettes.
-- No player's collision, velocity, health or camera is ever modified here.
function StructuralCollapse.goal(rest, size, slot, kind)
    local side = slot % 2 == 0 and 1 or -1
    local y = -(8.5 + (slot % 3) * 3.0)
    local x = side * (4.5 + (slot % 4) * 1.4)
    local z = (slot % 3 - 1) * 4.2
    local tilt = math.rad(18 + (slot % 4) * 12)
    if kind == "Tornado" then
        x *= 1.8
        tilt *= 1.6
    elseif kind == "RisingLava" then
        y *= 0.55
        z *= 1.6
    end
    local rotation = CFrame.Angles(
        math.rad(side * (14 + (slot % 3) * 8)), tilt * side,
        tilt * -side
    )
    return rest * CFrame.new(x, y, z) * rotation
end

function StructuralCollapse.start(ctx)
    if not StructuralCollapse.enabled(ctx) then return nil end
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not arena or not arena.Parent then return nil end
    local groups = StructuralCollapse.findGateways(arena)
    if #groups < 2 then return nil end
    local active = true
    local sequence = 0
    local broken = {}
    local snapshots = {}
    local tweens = {}
    local lastAt = -math.huge
    local roundNumber = math.floor(math.max(0, tonumber(ctx.RoundNumber) or 0))

    local initialCount = arena:GetAttribute("StructuralFailures")
    arena:SetAttribute("StructuralFailures", 0)

    local function restore()
        if not active then return end
        active = false
        for _, tween in ipairs(tweens) do tween:Cancel() end
        table.clear(tweens)
        for part, original in pairs(snapshots) do
            if part.Parent then
                part.CFrame = original.cframe
                part.Transparency = original.transparency
                part.Color = original.color
                part:SetAttribute("StructuralRuin", nil)
            end
        end
        for _, group in ipairs(groups) do
            if group.platform.Parent then
                group.platform:SetAttribute("StructuralFractureKind", nil)
                group.platform:SetAttribute("StructuralFractureStartedAt", nil)
                group.platform:SetAttribute("StructuralFracturePhase", nil)
            end
        end
        if arena.Parent then
            arena:SetAttribute("StructuralFailures", initialCount)
        end
    end
    ctx.OnCleanup[#ctx.OnCleanup + 1] = restore

    local function fracture(kind, impactPosition)
        if not active or not ctx.Active() or not arena.Parent
            or not VALID_IMPACTS[kind] and not VALID_STRESS[kind]
            or sequence >= math.min(StructuralCollapse.MaxFailures, #groups)
        then return false end
        local now = os.clock()
        if now - lastAt < StructuralCollapse.MinBetweenFailures then
            return false
        end
        local choice = nil
        if typeof(impactPosition) == "Vector3" then
            -- Crack the nearest still-intact gateway, so the aftermath
            -- advances coherently outward from the TRUE blast center.
            -- Deterministic indexed tie breaks for identical distances.
            local bestDistance = math.huge
            for idx, group in ipairs(groups) do
                if not broken[idx] and group.platform.Parent then
                    local delta = group.platform.Position - impactPosition
                    local distance = delta.X * delta.X + delta.Z * delta.Z
                    if distance < bestDistance then
                        bestDistance = distance
                        choice = {idx = idx, group = group}
                    end
                end
            end
        else
            for attempt = 1, #groups do
                local idx = ((roundNumber + sequence + attempt - 1)
                    % #groups) + 1
                if not broken[idx] then
                    choice = {idx = idx, group = groups[idx]}
                    break
                end
            end
        end
        if not choice or not choice.group.platform.Parent then return false end
        local group = choice.group
        broken[choice.idx] = true
        sequence += 1
        lastAt = now

        -- The original impact already completed its server damage and
        -- warning contract. This is the *same event*, not a new hazard.
        local startTime = workspace:GetServerTimeNow()
        group.platform:SetAttribute("StructuralFractureStartedAt", startTime)
        group.platform:SetAttribute("StructuralFractureKind", kind)
        group.platform:SetAttribute("StructuralFracturePhase", "Broken")
        arena:SetAttribute("StructuralFailures", sequence)

        for i, part in ipairs(group.parts) do
            if part.Parent and not snapshots[part] then
                local original = {
                    cframe = part.CFrame, transparency = part.Transparency,
                    color = part.Color,
                }
                snapshots[part] = original
                part:SetAttribute("StructuralRuin", true)
                local goal = StructuralCollapse.goal(
                    original.cframe, part.Size, i, kind)
                local tween = TweenService:Create(part,
                    TweenInfo.new(StructuralCollapse.FractureSeconds
                        + (i % 3) * 0.14, Enum.EasingStyle.Quad,
                        Enum.EasingDirection.In),
                    {CFrame = goal, Transparency = 1}
                )
                tweens[#tweens + 1] = tween
                tween:Play()
            end
        end
        return true
    end

    -- Real meteor/bomb callbacks share this entry point. Only actual
    -- authoritative impacts, never fake random client triggers, break an arch.
    local function onImpact(position, kind)
        if VALID_IMPACTS[kind] and ctx.ActiveDisasters[
            kind == "Meteor" and "Meteors" or "Bombs"] then
            return fracture(kind, position)
        end
        return false
    end

    if ctx.ActiveDisasters.Tornado or ctx.ActiveDisasters.RisingLava then
        -- One infrequent stress sequence, only during an active severe
        -- disaster. There is no frame-step loop and no spawned physics.
        local stressKind = ctx.ActiveDisasters.Tornado
            and "Tornado" or "RisingLava"
        task.spawn(function()
            task.wait(StructuralCollapse.InitialWindStressSeconds)
            while active and ctx.Active() and arena.Parent
                and sequence < StructuralCollapse.MaxFailures do
                fracture(stressKind)
                task.wait(StructuralCollapse.StressIntervalSeconds)
            end
        end)
    end
    return onImpact
end

return StructuralCollapse
