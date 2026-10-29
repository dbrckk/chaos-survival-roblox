-- A single, depth-tested world-space NEXT JUMP cue for new players.
-- The source deck must be under the character's feet. All targets are
-- server-owned, collision-checked, and sourced from the live arena.
-- No new Parts, collision, rewards, network traffic, lights or RenderStepped.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FirstTimeExperience = require(ReplicatedStorage.Shared.FirstTimeExperience)
local JumpRouteCueRules = require(ReplicatedStorage.Shared.JumpRouteCueRules)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RoundState")
local currentPhase = "waiting"
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

stateEvent.OnClientEvent:Connect(function(state)
    if type(state) ~= "table" then return end
    currentPhase = tostring(state.phase or "waiting")
    if currentPhase ~= "ready" and currentPhase ~= "round" then
        hide()
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

local function update()
    local games = FirstTimeExperience.effectiveGames(
        player:GetAttribute("Games"),
        player:GetAttribute("SessionRoundsPlayed")
    )
    -- Rookie guidance stays focused on survival. Experienced players
    -- see a cargo cue only while an actual timed Harbor objective exists.
    local rookie = FirstTimeExperience.isRookie(games)
    if (currentPhase ~= "ready" and currentPhase ~= "round")
        or (not rookie and currentPhase ~= "round")
        or player:GetAttribute("RoundParticipant") ~= true
        or player:GetAttribute("RoundEliminated") == true then
        hide()
        return false
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0
        or humanoid.FloorMaterial == Enum.Material.Air then
        hide()
        return true
    end

    local generated = workspace:FindFirstChild("GeneratedMap")
    local arena = generated and generated:FindFirstChild("Arena")
    local platforms = arena and arena:FindFirstChild("Platforms")
    local base = arena and arena:FindFirstChild("Base")
    if not platforms or not base or not base:IsA("BasePart") then
        hide()
        return true
    end

    -- The old platform folder can be destroyed when the map changes.
    -- Do not keep a stale target, array or listener from a previous round.
    if generated ~= currentMap or platforms ~= mapPlatforms then
        currentMap, mapPlatforms = generated, platforms
        hide()
    end

    rayParams.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -9, 0), rayParams
    )
    local from = hit and hit.Instance
    if not from or hit.Normal.Y < 0.65 then
        hide()
        return true
    end

    local pieces = platforms:GetChildren()
    local target = nil
    local french = player.LocaleId:sub(1, 2) == "fr"
    local hint = french and "SAUT SUIVANT  ↑" or "NEXT JUMP  ↑"
    if not rookie then
        target, hint = cargoWaypoint(
            from, pieces, base, root, arena, french)
    elseif from == base then
        -- The largest missing first-session cue was *before* the first
        -- jump. Guide from the actual floor to a short, grounded entry.
        target = JumpRouteCueRules.nearestEntry(
            pieces, hit.Position, 42
        )
    elseif from.Parent == platforms then
        target = JumpRouteCueRules.nextPhysical(
            from, pieces, base.Position, arena:GetAttribute("VariantId")
        )
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
    if not target or (root.Position - target.Position).Magnitude > 46 then
        hide()
        return true
    end

    local sign = gui()
    -- Calm teal for normal rookie guidance, sea-green for cargo. Retain
    -- depth testing and a single HUD owner on all Android tiers.
    local guideColor = rookie and Color3.fromRGB(210, 248, 236)
        or Color3.fromRGB(146, 255, 196)
    if caption.TextColor3 ~= guideColor then
        caption.TextColor3 = guideColor
    end
    if caption.Text ~= hint then caption.Text = hint end
    if currentTarget ~= target then
        currentTarget = target
        sign.Adornee = target
        sign.StudsOffsetWorldSpace = Vector3.new(
            0, target.Size.Y * 0.5 + 3.1, 0
        )
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
