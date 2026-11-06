-- A single, depth-tested world-space NEXT JUMP cue for new players.
-- The source deck must be under the character's feet. All targets are
-- server-owned, collision-checked, and sourced from the live arena.
-- No new Parts, collision, rewards, network traffic, lights or RenderStepped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local JumpRouteCueRules = require(ReplicatedStorage.Shared.JumpRouteCueRules)
local MobileHudNotices = require(ReplicatedStorage.Shared.MobileHudNotices)
local HAZARD_OWNER = "imminent-hazard"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local currentPhase = "waiting"
local currentChallenge = nil
local currentDisasters = {}
local finalRush = false
-- Recovery is session-local cosmetic state, never a server score or entitlement.
local recoveryDeck = nil
local recoveryAnchor = nil
local recoverySince = 0
local recoveryCharacter = nil
-- Track actual contacted decks, not camera heading or guessed joystick
-- intent. This lets the SAME physical upper Harbor gangway guide jumps
-- in either direction, including backtracking during a storm.
local lastSkywayDeck = nil
local skywayDirection = nil
local skywayArrival = nil
-- Also follow the genuinely walkable five-map H-shaped upper network.
-- Its direction is inferred from already-landed physical platforms, not
-- the direction the player's camera happens to face.
local lastSkyNetworkDeck = nil
local skyNetworkDirection = nil
local function resetSkyway()
    lastSkywayDeck, skywayDirection, skywayArrival = nil, nil, nil
    lastSkyNetworkDeck, skyNetworkDirection = nil, nil
end
local function skyRouteDirection(from)
    if from:GetAttribute("PromenadeLane") ~= nil
        or from:GetAttribute("SkySpineStep") ~= nil
        or (from:GetAttribute("BranchRoute") ~= nil
            and from:GetAttribute("BranchStep") == 4) then
        return skyNetworkDirection
    end
    return skywayDirection
end
local function resetRecovery()
    recoveryDeck, recoveryAnchor, recoverySince = nil, nil, 0
end

-- Reuse the existing low-frequency coach polling. Cache ONLY the actual
-- server warning Parts; never scan every descendant on each Android tick.
local liveWarnings = {}
local function trackWarning(child)
    if child:IsA("BasePart")
        and (child.Name == "MeteorWarning" or child.Name == "BombWarning")
    then
        liveWarnings[child] = true
    end
end
workspace.ChildAdded:Connect(trackWarning)
workspace.ChildRemoved:Connect(function(child)
    liveWarnings[child] = nil
end)
for _, child in ipairs(workspace:GetChildren()) do
    trackWarning(child)
end

local function warningsNow()
    local result = {}
    for part in pairs(liveWarnings) do
        if part.Parent == workspace then
            result[#result + 1] = part
        else
            liveWarnings[part] = nil
        end
    end

    -- Unlike meteor warning Parts, these permanent lanes live under the
    -- CURRENT arena mechanics and transition between Idle/Warning/Pulse.
    -- Four inexpensive direct children per map at existing 0.4/0.85 s
    -- guide cadence, no per-frame descendants scan or stale-map watcher.
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if mechanics then
        for _, folderName in ipairs({"GridSweep", "HarborCargoSweep"}) do
            local folder = mechanics:FindFirstChild(folderName)
            if folder then
                for _, band in ipairs(folder:GetChildren()) do
                    if band:IsA("BasePart")
                        and (band:GetAttribute("GridSweepPhase") == "Warning"
                            or band:GetAttribute("GridSweepPhase") == "Pulse"
                            or band:GetAttribute("HarborSweepPhase") == "Warning"
                            or band:GetAttribute("HarborSweepPhase") == "Pulse") then
                        result[#result + 1] = band
                    end
                end
            end
        end
    end
    return result
end
-- This optional sign must not recommend a deck already submerged by
-- the live server-owned lava. Keep the existing meteor/bomb/sweep route
-- classifier and add only one cheap workspace-root lookup per target.
local function safeGuidedTargetPath(fromPosition, target, warnings)
    if not target or not target:IsA("BasePart") then return false end
    -- Compare the same HumanoidRootPart clearance used by the authoritative
    -- disaster and the airborne landing preview. Using the deck's CENTER
    -- instead of the player's standing height incorrectly hides safe upper
    -- exits while a bomb detonates well below them.
    -- Cargo pickups are not standable platforms; keep their actual goal
    -- position for the route test rather than inventing a floor under them.
    local rampStart = target.Parent and target.Parent.Name == "HelixCircuit"
        and target:GetAttribute("HelixStart") or nil
    local toPosition = typeof(rampStart) == "Vector3"
        and rampStart + Vector3.new(0, 2.5, 0) or target.Position
    if target.Parent and target.Parent.Name == "Platforms" then
        toPosition += Vector3.new(0, target.Size.Y * 0.5 + 2.5, 0)
    end
    if not JumpRouteCueRules.safeGuidedPath(
        fromPosition, toPosition, warnings
    ) then
        return false
    end
    local lava = workspace:FindFirstChild("RoundLava")
    if typeof(rampStart) == "Vector3" then
        return not JumpRouteCueRules.lavaAtRoot(toPosition, lava)
    end
    return not JumpRouteCueRules.lavaOnDeck(target, lava)
end

local marker
local caption
local currentTarget
local currentMap
local mapPlatforms

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local function hide()
    if marker then marker.Enabled = false end
    currentTarget = nil
end

-- The real danger event can arrive between two 0.4-second guidance polls.
-- Hide the existing world sign in that SAME frame, without another loop.
-- Recovery is handled by the already-running coach when the alert releases.
MobileHudNotices.Changed:Connect(function(owner)
    if UserInputService.TouchEnabled and owner == HAZARD_OWNER then
        hide()
    end
end)

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    local previous = currentPhase
    currentPhase = tostring(state.phase or "waiting")
    currentChallenge = state.challengeMetric
    currentDisasters = type(state.disasterIds) == "table"
        and state.disasterIds or {}
    finalRush = state.finalRush == true
    if currentPhase ~= previous then
        resetRecovery()
        resetSkyway()
    end
    if currentPhase ~= "ready" and currentPhase ~= "round" then
        hide()
        resetRecovery()
    end
end)

local function gui()
    if marker and marker.Parent == playerGui then return marker end
    if marker then marker:Destroy() end
    marker = Instance.new("BillboardGui")
    marker.Name = "RookiePhysicalJumpCue"
    marker.Size = UDim2.fromOffset(144, 38)
    marker.MaxDistance = 48
    marker.AlwaysOnTop = false
    marker.LightInfluence = 0
    marker.Enabled = false
    marker.ResetOnSpawn = false
    marker.Parent = playerGui

    caption = Instance.new("TextLabel")
    caption.Name = "NextPhysicalJump"
    caption.Size = UDim2.fromScale(1, 1)
    caption.BackgroundColor3 = Color3.fromRGB(13, 27, 38)
    caption.BackgroundTransparency = 0.10
    caption.BorderSizePixel = 0
    caption.TextColor3 = Color3.fromRGB(210, 248, 236)
    caption.TextStrokeTransparency = 0.4
    caption.Font = Enum.Font.GothamBlack
    caption.TextScaled = true
    caption.Text = player.LocaleId:sub(1, 2) == "fr"
        and "SAUT SUIVANT  ↑" or "NEXT JUMP  ↑"
    caption.Parent = marker

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = caption
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(70, 207, 185)
    border.Thickness = 1.6
    border.Parent = caption
    return marker
end

-- Experienced players get the same SINGLE physical-next-jump marker
-- when a genuine two-coin Harbor cargo cache is active. Resolve route
-- and step only from server-owned deck/shard attributes; do not invent
-- waypoints, scan for off-route roofs, or obscure disaster warnings.
local function cargoWaypoint(from, pieces, base, root, arena, french)
    if arena:GetAttribute("VariantId") ~= "Harbor" then
        return nil, nil
    end
    local collectibles = workspace:FindFirstChild("RoundChaosShards")
    if not collectibles then return nil, nil end

    local bestTarget, bestHint, bestDistance = nil, nil, math.huge
    for _, shard in ipairs(collectibles:GetChildren()) do
        if shard:IsA("BasePart") and shard.Parent == collectibles
            and shard:GetAttribute("ChaosShardCargo") == true then
            local route = shard:GetAttribute("HarborCargoRoute")
            local goalStep = shard:GetAttribute("HarborCargoStep")
            if type(route) == "number" and route >= 1 and route <= 4
                and type(goalStep) == "number"
                and (goalStep == 4 or goalStep == 6) then
                local nextStep, destination, atCache = 0, nil, false
                if from == base then
                    -- Only a verified, floor-accessible first deck.
                    for _, deck in ipairs(pieces) do
                        if deck:GetAttribute("HarborRoute") == route
                            and deck:GetAttribute("HarborStep") == 1
                            and JumpRouteCueRules.safeLandingTarget(deck)
                            and deck.Position.Y + deck.Size.Y * 0.5
                                - (base.Position.Y + base.Size.Y * 0.5) <= 5.2 then
                            destination = deck
                            break
                        end
                    end
                elseif from.Parent == base.Parent:FindFirstChild("Platforms")
                    and from:GetAttribute("HarborRoute") == route then
                    local step = from:GetAttribute("HarborStep")
                    if type(step) == "number" and step >= 1
                        and step <= goalStep then
                        nextStep = step
                        if step == goalStep
                            and JumpRouteCueRules.safeLandingTarget(from) then
                            destination = shard
                            atCache = true
                        else
                            local nextDeck = JumpRouteCueRules.nextPhysical(
                                from, pieces, base.Position, "Harbor")
                            if nextDeck
                                and nextDeck:GetAttribute("HarborRoute") == route
                                and nextDeck:GetAttribute("HarborStep") == step + 1 then
                                destination = nextDeck
                            end
                        end
                    end
                end

                if destination then
                    local distance = (root.Position - destination.Position).Magnitude
                    if distance <= 46 and distance < bestDistance then
                        bestDistance = distance
                        bestTarget = destination
                        if atCache then
                            bestHint = french and "CARGAISON +2  •  ICI"
                                or "CARGO +2  •  HERE"
                        else
                            local remaining = goalStep - nextStep
                            bestHint = french
                                and ("CARGAISON +2  •  " .. remaining .. " SAUTS")
                                or ("CARGO +2  •  " .. remaining .. " JUMPS")
                        end
                    end
                end
            end
        end
    end
    return bestTarget, bestHint
end

-- Orbital's vertical escape is a continuous, server-built ramp network.
-- Generic deck-jump rules deliberately refuse this arena, so the mobile
-- rookie marker must follow its REAL entry/helix/core ramp transitions.
local function orbitalRampNext(arena, from, root, base, platforms)
    if arena:GetAttribute("VariantId") ~= "Orbital" then return nil end
    local circuit = arena:FindFirstChild("HelixCircuit")
    if not circuit then return nil end
    local function real(folder, name)
        local part = folder and folder:FindFirstChild(name)
        if not part or not part:IsA("BasePart") or not part.Anchored
            or not part.CanCollide or part.Transparency >= 0.75
            or part:GetAttribute("CollapsePhase") == "Warning"
            or part:GetAttribute("CollapsePhase") == "Gone" then
            return nil
        end
        return part
    end
    local function nearestEntry(maxDistance)
        local closest, distance = nil, maxDistance
        for i = 1, 8 do
            local part = real(circuit, "EntryRamp" .. i)
            local start = part and part:GetAttribute("HelixStart")
            if typeof(start) == "Vector3" then
                local delta = start - root.Position
                local flat = Vector3.new(delta.X, 0, delta.Z).Magnitude
                if flat < distance then
                    closest, distance = part, flat
                end
            end
        end
        return closest
    end
    if from == base then return nearestEntry(44) end
    if from.Parent == platforms then
        local id = tonumber(from.Name:match("^Platform(%d+)$"))
        if id == 17 then return nearestEntry(56) end
        if id and id >= 1 and id <= 8 then
            return real(circuit, "HelixRamp" .. id)
        elseif id and id >= 9 and id <= 16 then
            local lane = id - 8
            return real(circuit, lane == 2 and "HelixRamp9"
                or ("CoreRamp" .. lane))
        end
    elseif from.Parent == circuit then
        local entry = tonumber(from.Name:match("^EntryRamp(%d+)$"))
        if entry then return real(platforms, "Platform" .. entry) end
        local helix = tonumber(from.Name:match("^HelixRamp(%d+)$"))
        if helix then
            return real(platforms, "Platform" .. (helix == 9 and 18
                or helix + 8))
        end
        local core = tonumber(from.Name:match("^CoreRamp(%d+)$"))
        if core then return real(platforms, "Platform18") end
    end
    return nil
end

local function update()
    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    -- Rookie guidance stays focused on survival. Experienced players
    -- see a cargo cue only while an actual timed Harbor objective exists.
    local rookie = FirstTimeExperience.isRookie(games)
    -- Rising lava is lethal to beginners AND veteran avatars alike.
    -- Reuse this ONE existing depth-tested marker to direct a genuine
    -- ascent instead of creating a competing Android objective card.
    local lavaClimbActive = currentPhase == "round"
        and table.find(currentDisasters, "RisingLava") ~= nil
    if (currentPhase ~= "ready" and currentPhase ~= "round")
        or (not rookie and currentPhase ~= "round")
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true then
        hide()
        resetRecovery()
        return false
    end

    local character = player.Character
    if character ~= recoveryCharacter then
        recoveryCharacter = character
        resetRecovery()
        resetSkyway()
    end
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then
        hide()
        resetRecovery()
        return true
    end
    if humanoid.FloorMaterial == Enum.Material.Air then
        -- Hide guidance while airborne, but retain the same-deck timer.
        -- A failed jump should NOT restart the veteran's recovery delay.
        hide()
        return true
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not platforms or not base or not base:IsA("BasePart") then
        hide()
        resetRecovery()
        return true
    end

    -- The old platform folder can be destroyed when the map changes.
    -- Do not keep a stale target, array or listener from a previous round.
    if generated ~= currentMap or platforms ~= mapPlatforms then
        currentMap, mapPlatforms = generated, platforms
        hide()
        resetRecovery()
        resetSkyway()
    end

    rayParams.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -9, 0), rayParams
    )
    local from = hit and hit.Instance
    if not from or hit.Normal.Y < 0.65 then
        hide()
        resetRecovery()
        return true
    end

    -- A skyway bridge has no scripted jump, only genuine, raised steel
    -- landing Parts. Preserve last completed direction across a freefall
    -- and do not point straight BACK at the roof after reaching its end.
    if from ~= lastSkywayDeck then
        local lane = from:GetAttribute("HarborSkywayLane")
        local previous = lastSkywayDeck
        if lane ~= nil then
            local formerLane = previous and previous:GetAttribute(
                "HarborSkywayLane"
            )
            local formerStep = previous and previous:GetAttribute(
                "HarborSkywayStep"
            )
            local step = from:GetAttribute("HarborSkywayStep")
            if formerLane == lane and type(formerStep) == "number"
                and type(step) == "number" and formerStep ~= step then
                skywayDirection = step > formerStep and 1 or -1
            elseif previous and previous:GetAttribute("HarborStep") == 7 then
                skywayDirection = previous.Position.X < base.Position.X
                    and 1 or -1
            else
                skywayDirection = from.Position.X < base.Position.X
                    and 1 or -1
            end
            skywayArrival = nil
        elseif from:GetAttribute("HarborStep") == 7 and previous
            and previous:GetAttribute("HarborSkywayLane") ~= nil then
            skywayArrival = from
            skywayDirection = nil
        else
            skywayDirection = nil
            skywayArrival = nil
        end
        lastSkywayDeck = from
    end

    -- On first arrival at a promenade end, point inward. Once a player
    -- actually lands on its next deck, preserve that real travel direction
    -- even when retreating during a disaster. The Sky Spine's north/south
    -- ends similarly preserve the player's actual sequence of landings.
    if from ~= lastSkyNetworkDeck then
        local previous = lastSkyNetworkDeck
        local lane = from:GetAttribute("PromenadeLane")
        local promenadeStep = from:GetAttribute("PromenadeStep")
        local spineStep = from:GetAttribute("SkySpineStep")
        if (lane == 1 or lane == 2)
            and type(promenadeStep) == "number" then
            if previous and previous:GetAttribute("PromenadeLane") == lane
                and type(previous:GetAttribute("PromenadeStep")) == "number"
                and previous:GetAttribute("PromenadeStep") ~= promenadeStep then
                skyNetworkDirection = promenadeStep
                    > previous:GetAttribute("PromenadeStep") and 1 or -1
            elseif previous and previous:GetAttribute("BranchStep") == 4 then
                skyNetworkDirection = previous.Position.X < base.Position.X
                    and 1 or -1
            else
                skyNetworkDirection = promenadeStep <= 4 and 1 or -1
            end
        elseif type(spineStep) == "number"
            and from:GetAttribute("SkySpineInterchange") == true then
            if previous and type(previous:GetAttribute("SkySpineStep"))
                    == "number"
                and previous:GetAttribute("SkySpineStep") ~= spineStep then
                skyNetworkDirection = spineStep
                    > previous:GetAttribute("SkySpineStep") and 1 or -1
            else
                skyNetworkDirection = spineStep <= 5 and 1 or -1
            end
        else
            skyNetworkDirection = nil
        end
        lastSkyNetworkDeck = from
    end

    local now = os.clock()
    -- Walking several studs or reaching another real deck immediately
    -- removes the optional recovery sign; no HUD spam for skilled runs.
    local traveled = JumpRouteCueRules.horizontalProgressDistance(
        recoveryAnchor, root.Position
    )
    if from ~= recoveryDeck or not recoveryAnchor
        or traveled > JumpRouteCueRules.RecoveryTravel then
        recoveryDeck = from
        recoveryAnchor = root.Position
        recoverySince = now
    end

    local pieces = platforms:GetChildren()
    if skywayArrival == from then
        -- This is a completed, genuine harbor-to-harbor crossing. The
        -- destination's own cargo route has no forced continuation and
        -- should not immediately nag a newcomer to reverse direction.
        hide()
        return true
    end
    local target = nil
    local french = player.LocaleId:sub(1, 2) == "fr"
    local hint = french and "SAUT SUIVANT  ↑" or "NEXT JUMP  ↑"
    if lavaClimbActive then
        -- Never point to a painted floor arrow or a distant invented
        -- refuge. The target is one actual live server PlatformN or
        -- a genuine Orbital helix ramp with its physical entry.
        local variant = arena:GetAttribute("VariantId")
        if variant == "Orbital" then
            target = orbitalRampNext(arena, from, root, base, platforms)
            if not target and from.Parent == platforms then
                target = JumpRouteCueRules.nextPhysical(
                    from, pieces, base.Position, variant,
                    skyRouteDirection(from))
            end
        elseif from == base then
            target = JumpRouteCueRules.nearestLavaClimbEntry(
                pieces, hit.Position, workspace:FindFirstChild("RoundLava"),
                106)
        elseif from.Parent == platforms then
            target = JumpRouteCueRules.nextPhysical(
                from, pieces, base.Position, variant,
                skyRouteDirection(from))
        end
        if target then
            if from == base then
                hint = french and "VERS LES HAUTEURS  ↑"
                    or "FIND HIGH GROUND  ↑"
            else
                local nextTop = target.Position.Y + target.Size.Y * 0.5
                local currentTop = from.Position.Y + from.Size.Y * 0.5
                if nextTop > currentTop + 0.35 then
                    hint = french and "GRIMPE PLUS HAUT  ↑"
                        or "CLIMB HIGHER  ↑"
                else
                    -- The genuinely level Sky Spine / promenades
                    -- should never be labelled as a higher step.
                    hint = french and "SUIS LA PASSERELLE  ↑"
                        or "FOLLOW THE SKYWAY  ↑"
                end
            end
        end
    elseif not rookie then
        -- Mastery already owns its own physical objective marker. An
        -- optional hint only assists a genuinely stalled platform runner.
        target, hint = cargoWaypoint(
            from, pieces, base, root, arena, french)
        if not target and currentChallenge ~= "highGround"
            and not finalRush and from.Parent == platforms
            and JumpRouteCueRules.recoveryHintReady(
                now - recoverySince,
                traveled,
                true
            ) then
            target = JumpRouteCueRules.nextPhysical(
                from, pieces, base.Position, arena:GetAttribute("VariantId"),
                skyRouteDirection(from)
            )
            if target then
                hint = french and "REPRENDS LE PARCOURS  ↑"
                    or "RESUME THE ROUTE  ↑"
            end
        end
    elseif arena:GetAttribute("VariantId") == "Orbital" then
        -- This world uses physical ramps instead of tiered jump gaps.
        -- Preserve the SAME one-sign Android guide, not a second HUD.
        target = orbitalRampNext(arena, from, root, base, platforms)
        if target then
            hint = french and "SUIS LA RAMPE  ↑" or "FOLLOW THE RAMP  ↑"
        end
    elseif from == base then
        -- The largest missing first-session cue was *before* the first
        -- jump. Guide from the actual floor to a short, grounded entry.
        target = JumpRouteCueRules.nearestEntry(
            pieces, hit.Position, 42
        )
    elseif from.Parent == platforms then
        target = JumpRouteCueRules.nextPhysical(
            from, pieces, base.Position, arena:GetAttribute("VariantId"),
            skyRouteDirection(from)
        )
        if from:GetAttribute("PromenadeLane") ~= nil
            or from:GetAttribute("SkySpineStep") ~= nil
            or (from:GetAttribute("BranchRoute") ~= nil
                and from:GetAttribute("BranchStep") == 4) then
            local isJunction = from:GetAttribute("PromenadeStep") == 4
                or from:GetAttribute("SkySpineStep") == 1
                or from:GetAttribute("SkySpineStep") == 10
            if isJunction then
                local forward, crossing = JumpRouteCueRules.skyNetworkOptions(
                    from, pieces, skyRouteDirection(from))
                if forward and crossing then
                    hint = french and "2 CHEMINS EN HAUTEUR"
                        or "2 SKY ROUTES"
                end
            end
            if target and JumpRouteCueRules.gap(from, target) <= 0.15
                and hint == (french and "SAUT SUIVANT  ↑"
                    or "NEXT JUMP  ↑") then
                hint = french and "PASSAGE EN HAUTEUR  ↑"
                    or "SKY CROSSING  ↑"
            end
        end
        if from:GetAttribute("PerimeterStep") == 5 then
            local forward, flank = JumpRouteCueRules.forkOptions(
                from, pieces
            )
            if forward and flank then
                -- A genuine, server-authored choice. The physical fork
                -- arrows show the side direction; keep only ONE nearby
                -- billboard rather than obscuring danger telegraphs.
                hint = french and "2 ROUTES  •  CHOISIS"
                    or "2 PATHS  •  CHOOSE"
            elseif flank and not forward then
                hint = french and "DÉTOUR SÛR  ↑"
                    or "SAFE DETOUR  ↑"
            end
        end
        if from:GetAttribute("PerimeterStep") == 6 then
            local forward, detour = JumpRouteCueRules.crosslinkOptions(
                from, pieces
            )
            if forward and detour then
                hint = french and "2 ROUTES  •  CHOISIS"
                    or "2 PATHS  •  CHOOSE"
            elseif detour and not forward then
                hint = french and "PASSAGE SÛR  ↑"
                    or "SAFE CROSSING  ↑"
            end
        elseif from:GetAttribute("CrosslinkRoute") ~= nil then
            hint = french and "VERS LE BELVÉDÈRE  ↑"
                or "TO LOOKOUT  ↑"
        end
    end
    local dangerWarnings = warningsNow()
    -- If a genuine timed hazard overlaps the proposed jump, never put
    -- an optional route sign on top of the game's primary escape cue.
    -- At authored perimeter forks prefer a real alternate path instead.
    if target and not safeGuidedTargetPath(
        root.Position, target, dangerWarnings
    ) then
        local alternative = nil
        if (rookie or lavaClimbActive) and from == base then
            -- Don't simply hide the very first actionable cue when a
            -- meteor covers the nearest entry; look for another REAL
            -- first-tier takeoff in range, only during a live warning.
            local remaining = {}
            for _, deck in ipairs(pieces) do
                if deck:IsA("BasePart") and safeGuidedTargetPath(
                    root.Position, deck, dangerWarnings
                ) then
                    remaining[#remaining + 1] = deck
                end
            end
            alternative = lavaClimbActive
                and JumpRouteCueRules.nearestLavaClimbEntry(
                    remaining, hit.Position,
                    workspace:FindFirstChild("RoundLava"), 106)
                or JumpRouteCueRules.nearestEntry(
                    remaining, hit.Position, 42)
        elseif from.Parent == platforms then
            if from:GetAttribute("PerimeterStep") == 5 then
                local forward, flank = JumpRouteCueRules.forkOptions(from, pieces)
                alternative = target == forward and flank or forward
            elseif from:GetAttribute("PerimeterStep") == 6 then
                local forward, crossing = JumpRouteCueRules.crosslinkOptions(from, pieces)
                alternative = target == forward and crossing or forward
            elseif from:GetAttribute("PromenadeStep") == 4
                or from:GetAttribute("SkySpineStep") == 1
                or from:GetAttribute("SkySpineStep") == 10 then
                local forward, crossing = JumpRouteCueRules.skyNetworkOptions(
                    from, pieces, skyRouteDirection(from))
                alternative = target == forward and crossing or forward
            end
        end
        if alternative and safeGuidedTargetPath(
            root.Position, alternative, dangerWarnings
        ) then
            target = alternative
            hint = french and "DÉTOUR SÛR  ↑" or "SAFE DETOUR  ↑"
        else
            target = nil
        end
    end
    -- A long orbital ramp's CENTER can be far from its actionable entry.
    -- Only for server-authored ramps, use the real HelixStart takeoff
    -- coordinate rather than suppressing the guide or marking midair.
    local rampStart = target and target.Parent
        and target.Parent.Name == "HelixCircuit"
        and target:GetAttribute("HelixStart") or nil
    local guideDistance = typeof(rampStart) == "Vector3"
        and (root.Position - rampStart).Magnitude
        or (target and (root.Position - target.Position).Magnitude
            or math.huge)
    local maxGuideDistance = lavaClimbActive
        and from == base and 108 or 46
    if not target or guideDistance > maxGuideDistance then
        hide()
        -- Never burn an extra fast loop to search for optional hints.
        return rookie
    end

    -- Only standard jump/recovery cues announce the late precision grade.
    -- Never replace cargo objectives, fork choices or an emergency
    -- safe-detour hint. Reuse the one existing depth-tested BillboardGui.
    local grade = tonumber(target:GetAttribute("ParkourGrade"))
    if grade and (hint == (french and "SAUT SUIVANT  ↑" or "NEXT JUMP  ↑")
        or hint == (french and "REPRENDS LE PARCOURS  ↑"
            or "RESUME THE ROUTE  ↑")) then
        if grade >= 4 then
            hint = french and "SAUT EXPERT  ↑" or "EXPERT JUMP  ↑"
        elseif grade >= 3 then
            hint = french and "SAUT PRÉCIS  ↑" or "PRECISION JUMP  ↑"
        end
    end

    -- Physical wayfinding is always subordinate to the authoritative
    -- imminent-disaster instruction. The hazard UI owns the SAME mobile
    -- notification lane, and it can preempt this marker immediately.
    -- On desktop the world-space depth-tested sign remains unchanged.
    if UserInputService.TouchEnabled
        and MobileHudNotices.current() == HAZARD_OWNER then
        hide()
        return true
    end
    local sign = gui()
    sign.MaxDistance = lavaClimbActive and from == base and 112 or 48
    -- Calm teal for normal rookie guidance, sea-green for cargo. Retain
    -- depth testing and a single HUD owner on all Android tiers.
    local guideColor = lavaClimbActive
        and Color3.fromRGB(208, 255, 227)
        or (rookie and Color3.fromRGB(210, 248, 236)
            or Color3.fromRGB(146, 255, 196))
    if caption.TextColor3 ~= guideColor then
        caption.TextColor3 = guideColor
    end
    if caption.Text ~= hint then caption.Text = hint end
    if currentTarget ~= target then
        currentTarget = target
        sign.Adornee = target
        sign.StudsOffsetWorldSpace = typeof(rampStart) == "Vector3"
            and (rampStart + Vector3.new(0, 3.1, 0) - target.Position)
            or Vector3.new(0, target.Size.Y * 0.5 + 3.1, 0)
    end
    sign.Enabled = true
    return true
end

task.spawn(function()
    while true do
        local active = update()
        task.wait(active and 0.40 or 0.85)
    end
end)
