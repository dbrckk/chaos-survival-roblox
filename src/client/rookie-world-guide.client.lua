local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalizationService = game:GetService("LocalizationService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local CoreLocalization = require(ReplicatedStorage.Shared.CoreLocalization)
local VfxQuality = require(ReplicatedStorage.Shared.VfxQuality)
local VisualTheme = require(ReplicatedStorage.Shared.VisualTheme)

local player = Players.LocalPlayer
local localeId = LocalizationService.RobloxLocaleId
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")

local currentState = {
    phase = "waiting",
    voteOptions = nil,
}

local markerFolder = Instance.new("Folder")
markerFolder.Name = "RookieWorldGuideLocal"
markerFolder.Parent = workspace

local currentTarget = nil
local highlight = nil
local billboard = nil
local worldAssets = {}

local function clearMarker()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
    if billboard then
        billboard:Destroy()
        billboard = nil
    end
    for _, instance in ipairs(worldAssets) do
        if instance and instance.Parent then
            instance:Destroy()
        end
    end
    table.clear(worldAssets)
    currentTarget = nil
end

local function characterRoot()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    -- The READY packet can arrive while Roblox is replacing a dead rig.
    -- Only a living character may receive a physical movement cue.
    if not humanoid or humanoid.Health <= 0 then return nil end
    return root and root:IsA("BasePart") and root or nil
end

-- A close-looking pad can still be on another elevation, behind a
-- solid wall, or separated from the avatar by a missing piece of floor.
-- READY is the only phase in which this optional marker is shown; never
-- promise a route which we cannot confirm on the replicated physical map.
-- These few bounded probes execute only when the server sends READY or
-- the map/character changes, not in RenderStepped or a second scanner.
local function nearestReachablePad(parts)
    local root = characterRoot()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    if not root or not root:IsDescendantOf(workspace) or not arena then
        return nil
    end

    local ignored = {markerFolder}
    if root.Parent then
        table.insert(ignored, root.Parent)
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignored
    params.RespectCanCollide = true

    -- Rank eight or fewer authored pads by real horizontal distance FIRST.
    -- Once a safe pad is found, never raycast the remaining farther pads.
    -- These are local READY-only physics probes, not pathfinding or a loop.
    local ranked = {}
    for _, pad in ipairs(parts) do
        if pad:IsA("BasePart") and pad.Parent
            and pad.CanTouch and pad:GetAttribute("ArenaMobilityPad") == true
            and pad:IsDescendantOf(arena) then
            local offset = pad.Position - root.Position
            local flat = Vector3.new(offset.X, 0, offset.Z)
            local distance = flat.Magnitude
            if distance >= 4 and distance <= 56
                and math.abs(offset.Y) <= 5 then
                ranked[#ranked + 1] = {
                    part = pad,
                    flat = flat,
                    distance = distance,
                }
            end
        end
    end
    table.sort(ranked, function(a, b)
        return a.distance < b.distance
    end)

    for _, candidate in ipairs(ranked) do
        -- The nearest pad may be behind a wall or on a different
        -- physical route. Only point to an objectively direct approach.
        local obstacle = workspace:Raycast(
            root.Position, candidate.flat, params
        )
        if not obstacle
            or obstacle.Distance >= candidate.distance - 3.5 then
            local supported = true
            local groundY = nil
            local samples = math.max(3, math.ceil(candidate.distance / 3.5))
            local side = Vector3.new(-candidate.flat.Z, 0, candidate.flat.X).Unit * 1.3

            -- Probe BOTH endpoints and intermediate supports at <=3.5
            -- studs. Every other intermediate point probes the shoulder
            -- width too, rejecting tiny rails too narrow for an R15 rig.
            -- No unbounded search, extra workspace scan or frame loop.
            for step = 0, samples do
                local location = root.Position:Lerp(
                    candidate.part.Position, step / samples
                )
                local ground = workspace:Raycast(
                    location + Vector3.new(0, 2, 0),
                    Vector3.new(0, -11, 0), params
                )
                if not ground or not ground.Instance:IsDescendantOf(arena)
                    or ground.Normal.Y < 0.65
                    or ground.Position.Y > location.Y - 0.3
                    or (step == 0
                        and root.Position.Y - ground.Position.Y > 6)
                    or (groundY and math.abs(ground.Position.Y - groundY) > 2)
                then
                    supported = false
                    break
                end
                groundY = ground.Position.Y

                if step > 0 and step < samples and step % 2 == 0 then
                    for direction = -1, 1, 2 do
                        local shoulder = location + side * direction
                        local support = workspace:Raycast(
                            shoulder + Vector3.new(0, 2, 0),
                            Vector3.new(0, -11, 0), params
                        )
                        if not support
                            or not support.Instance:IsDescendantOf(arena)
                            or support.Normal.Y < 0.65
                            or support.Position.Y > shoulder.Y - 0.3
                            or math.abs(support.Position.Y - groundY) > 1.25
                        then
                            supported = false
                            break
                        end
                    end
                    if not supported then break end
                end
            end

            if supported then
                -- A READY state may outlive the exact physical pad if the
                -- arena is removed while client data is streaming.
                if candidate.part.Parent and candidate.part.CanTouch
                    and candidate.part:IsDescendantOf(arena) then
                    return candidate.part
                end
                return nil
            end
        end
    end
    return nil
end

local function practicePads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local activities = lobby and lobby:FindFirstChild("Activities")
    if not activities then
        return {}
    end

    local result = {}
    for _, child in ipairs(activities:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("LobbyPracticePad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function arenaRunway()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local lobby = generated and generated:FindFirstChild("Lobby")
    local decor = lobby and lobby:FindFirstChild("Decor")
    local runway = decor and decor:FindFirstChild("ArenaRunway")
    return runway and runway:IsA("BasePart") and runway or nil
end

local function arenaPads()
    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    if not mechanics then
        return {}
    end

    local result = {}
    for _, child in ipairs(mechanics:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("ArenaMobilityPad") == true then
            table.insert(result, child)
        end
    end
    return result
end

local function addWorldGuideAsset(instance)
    table.insert(worldAssets, instance)
    return instance
end

local function buildWorldBeacon(part, color)
    local tier = VfxQuality.get(player:GetAttribute("VfxQualityTier"))
    if tier.Name == "Low" then
        return
    end

    local reducedMotion = player:GetAttribute("ReduceMotion") == true
    local radius = math.clamp(math.max(part.Size.X, part.Size.Z) + 2.2, 4.8, 11.5)
    local y = part.Position.Y + part.Size.Y * 0.5 + 0.10

    local ring = Instance.new("Part")
    ring.Name = "RookieGuideAnchorRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.055, radius, radius)
    ring.CFrame = CFrame.new(part.Position.X, y, part.Position.Z)
        * CFrame.Angles(0, 0, math.rad(90))
    ring.Anchored = true
    ring.CanCollide = false
    ring.CanTouch = false
    ring.CanQuery = false
    ring.CastShadow = false
    ring.Material = Enum.Material.Neon
    ring.Color = color
    ring.Transparency = reducedMotion and 0.66 or 0.42
    ring.Parent = markerFolder
    addWorldGuideAsset(ring)

    if not reducedMotion then
        local targetSize = ring.Size
        ring.Size = Vector3.new(0.055, radius * 0.56, radius * 0.56)
        TweenService:Create(
            ring,
            TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {
                Size = targetSize,
                Transparency = 0.64,
            }
        ):Play()
    end

    local beacon = Instance.new("Part")
    beacon.Name = "RookieGuideBeacon"
    beacon.Size = Vector3.new(
        tier.Name == "High" and 0.22 or 0.16,
        tier.Name == "High" and 4.8 or 3.6,
        tier.Name == "High" and 0.22 or 0.16
    )
    beacon.CFrame = CFrame.new(
        part.Position.X,
        y + beacon.Size.Y * 0.5,
        part.Position.Z
    )
    beacon.Anchored = true
    beacon.CanCollide = false
    beacon.CanTouch = false
    beacon.CanQuery = false
    beacon.CastShadow = false
    beacon.Material = Enum.Material.Glass
    beacon.Color = VisualTheme.World.MetalLight:Lerp(color, 0.38)
    beacon.Transparency = tier.Name == "High" and 0.42 or 0.58
    beacon.Parent = markerFolder
    addWorldGuideAsset(beacon)

    if tier.Name == "High" then
        local cap = Instance.new("Part")
        cap.Name = "RookieGuideBeaconCap"
        cap.Shape = Enum.PartType.Ball
        cap.Size = Vector3.new(0.62, 0.62, 0.62)
        cap.CFrame = CFrame.new(
            part.Position.X,
            y + beacon.Size.Y + 0.24,
            part.Position.Z
        )
        cap.Anchored = true
        cap.CanCollide = false
        cap.CanTouch = false
        cap.CanQuery = false
        cap.CastShadow = false
        cap.Material = Enum.Material.Neon
        cap.Color = color:Lerp(Color3.new(1, 1, 1), 0.12)
        cap.Transparency = reducedMotion and 0.50 or 0.28
        cap.Parent = markerFolder
        addWorldGuideAsset(cap)
    end
end

local function mark(part, text, color)
    if currentTarget == part and highlight
        and (billboard or UserInputService.TouchEnabled) then
        return
    end

    clearMarker()
    if not part or not part.Parent then
        return
    end

    currentTarget = part

    highlight = Instance.new("Highlight")
    highlight.Name = "RookieGuideHighlight"
    highlight.Adornee = part
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.FillTransparency = 0.76
    highlight.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.35)
    highlight.OutlineTransparency = 0.05
    highlight.Parent = markerFolder

    buildWorldBeacon(part, color)

    -- Mobile already shows the survival goal and imminent hazard in two
    -- existing HUD owners. A third AlwaysOnTop label obscures the avatar
    -- on narrow screens; the bounded world highlight alone is enough.
    if UserInputService.TouchEnabled then return end

    billboard = Instance.new("BillboardGui")
    billboard.Name = "RookieGuideLabel"
    billboard.Adornee = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.fromOffset(178, 52)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.15, 0)
    billboard.MaxDistance = 76
    billboard.Parent = player:WaitForChild("PlayerGui")

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(10, 16, 27)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.Parent = billboard

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1.2
    stroke.Transparency = 0.26
    stroke.Parent = panel

    local rail = Instance.new("Frame")
    rail.Name = "GuideAccentRail"
    rail.Position = UDim2.fromScale(0.07, 0.14)
    rail.Size = UDim2.fromScale(0.86, 0.08)
    rail.BackgroundColor3 = color
    rail.BorderSizePixel = 0
    rail.Parent = panel

    local railCorner = Instance.new("UICorner")
    railCorner.CornerRadius = UDim.new(1, 0)
    railCorner.Parent = rail

    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromScale(0.07, 0.28)
    label.Size = UDim2.fromScale(0.86, 0.56)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = text
    label.TextColor3 = color:Lerp(Color3.new(1, 1, 1), 0.48)
    label.TextScaled = true
    label.TextWrapped = true
    label.Parent = panel

    local textConstraint = Instance.new("UITextSizeConstraint")
    textConstraint.MinTextSize = 11
    textConstraint.MaxTextSize = 18
    textConstraint.Parent = label
end

local function refresh()
    -- A temporarily unavailable DataStore must not disable read-only
    -- guidance. Never grant rewards, purchases or progression from this
    -- fallback; the player remains subject to the normal server roster.
    if player:GetAttribute("DataLoaded") ~= true
        and player:GetAttribute("DataLoadFailed") ~= true then
        clearMarker()
        return
    end

    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    -- The round focus HUD guides the first THREE entered rounds.
    -- Keep the optional real-world mobility cue consistent with that
    -- same window, including the third READY countdown.
    if not FirstTimeExperience.isGuidedPhase(games, currentState.phase) then
        clearMarker()
        return
    end

    local votingOpen = FirstTimeExperience.hasVoteOptions(currentState)
    if (currentState.phase == "intermission" or currentState.phase == "waiting")
        and votingOpen
    then
        clearMarker()
        return
    end

    -- First-time players need the survival objective, not two competing
    -- world beacons saying "TRY BOOST" or "ENTER ARENA". Lobby minigames
    -- are optional; the round automatically teleports participants.
    if games == 0
        and (currentState.phase == "waiting" or currentState.phase == "intermission")
    then
        clearMarker()
        return
    end

    if currentState.phase == "ready" then
        -- Only advertise an actually replicated, touch-enabled pad whose
        -- straight approach is supported by real collidable arena floor.
        -- If there is no verified route, prefer no marker to a fake one.
        -- Touch uses a world highlight, never a blocking billboard.
        mark(
            nearestReachablePad(arenaPads()),
            CoreLocalization.text(localeId, "ESCAPE_PAD"),
            Color3.fromRGB(120, 225, 255)
        )
        return
    end

    clearMarker()
end


-- The map's top-level model can arrive before its nested pads/runway,
-- and a pad can precede its replicated marker attribute. Listen only to
-- relevant direct children and their marker attributes, without polling
-- the full map or adding RenderStepped work on mobile.
local watchedMap = nil
local mapConnections = {}
local anchorConnections = {}
local refreshQueued = false

local function queueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    task.defer(function()
        refreshQueued = false
        refresh()
    end)
end

local function releaseMap()
    for _, connection in ipairs(mapConnections) do
        connection:Disconnect()
    end
    table.clear(mapConnections)
    for part, connection in pairs(anchorConnections) do
        connection:Disconnect()
        anchorConnections[part] = nil
    end
    watchedMap = nil
end

local function watchAnchor(part)
    local kind = FirstTimeExperience.guideAnchorKind(part, watchedMap)
    if not kind then return end

    if (kind == "practice" or kind == "mobility")
        and not anchorConnections[part] then
        local attribute = kind == "practice"
            and "LobbyPracticePad" or "ArenaMobilityPad"
        anchorConnections[part] = part:GetAttributeChangedSignal(attribute)
            :Connect(queueRefresh)
    end
    queueRefresh()
end

local function bindMap(generated)
    releaseMap()
    clearMarker()
    watchedMap = generated
    if not generated then return end

    table.insert(mapConnections, generated.DescendantAdded:Connect(watchAnchor))
    table.insert(mapConnections, generated.DescendantRemoving:Connect(function(part)
        local connection = anchorConnections[part]
        if connection then
            connection:Disconnect()
            anchorConnections[part] = nil
        end
        if part == currentTarget then
            queueRefresh()
        end
    end))

    for _, descendant in ipairs(generated:GetDescendants()) do
        watchAnchor(descendant)
    end
    queueRefresh()
end

local characterRootConnection = nil
local function watchCharacter(character)
    if characterRootConnection then
        characterRootConnection:Disconnect()
        characterRootConnection = nil
    end
    if not character then
        clearMarker()
        return
    end
    characterRootConnection = character.ChildAdded:Connect(function(child)
        if child.Name == "HumanoidRootPart" then
            queueRefresh()
        end
    end)
    task.delay(0.35, function()
        if player.Character == character then queueRefresh() end
    end)
end

stateEvent.OnClientEvent:Connect(function(state)
    -- Malformed RoundState must not replace a table with a scalar and
    -- crash later marker refreshes. Fail closed to the ordinary lobby cue.
    currentState = type(state) == "table"
        and state or {phase = "waiting", voteOptions = nil}
    refresh()
end)

player:GetAttributeChangedSignal("DataLoaded"):Connect(refresh)
player:GetAttributeChangedSignal("DataLoadFailed"):Connect(refresh)
player:GetAttributeChangedSignal("Games"):Connect(refresh)
player:GetAttributeChangedSignal("SessionRoundsPlayed"):Connect(refresh)
player:GetAttributeChangedSignal("LobbyPracticeUses"):Connect(refresh)
player:GetAttributeChangedSignal("RoundParticipant"):Connect(refresh)
player:GetAttributeChangedSignal("VfxQualityTier"):Connect(function()
    clearMarker()
    refresh()
end)
player:GetAttributeChangedSignal("ReduceMotion"):Connect(function()
    clearMarker()
    refresh()
end)

player.CharacterAdded:Connect(watchCharacter)
player.CharacterRemoving:Connect(function(character)
    if player.Character == character then
        if characterRootConnection then
            characterRootConnection:Disconnect()
            characterRootConnection = nil
        end
        clearMarker()
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "GeneratedMap" then
        bindMap(child)
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child == watchedMap then
        bindMap(workspace:FindFirstChild("GeneratedMap"))
    end
end)

watchCharacter(player.Character)
bindMap(workspace:FindFirstChild("GeneratedMap"))
