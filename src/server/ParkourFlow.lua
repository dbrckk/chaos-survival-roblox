-- Server-verified consecutive physical platform landings. No client
-- messages, touch shortcuts, invented checkpoints or movement modifiers.
-- One raycast is sampled only after a humanoid's actual landing event.
local JumpRouteCueRules = require(game:GetService("ReplicatedStorage").Shared.JumpRouteCueRules)

local ParkourFlow = {}

ParkourFlow.AceJumps = 3
ParkourFlow.LegendJumps = 6
ParkourFlow.AceXP = 4
ParkourFlow.LegendExtraXP = 3
ParkourFlow.MinTransitionSeconds = 0.27
ParkourFlow.MaxTransitionSeconds = 9.0
-- The veteran Moon Gravity disaster can sustain a real jump far longer
-- than a normal gravity arc; don't misclassify slow, authentic landings.
ParkourFlow.MaxAirSeconds = 5.0

local function validDeck(deck, platforms)
    return typeof(deck) == "Instance" and deck:IsA("BasePart")
        and deck.Parent == platforms
        and deck.Name:match("^Platform%d+$") ~= nil
        and deck.Anchored and deck.CanCollide
        and deck.Transparency < 0.75
        and deck:GetAttribute("CollapsePhase") == nil
end

-- Only a server-authored NEXT jump in the actual course is eligible.
-- For real forks there may be two valid successors: the default guide
-- chooses one, but players are rewarded equally for the physical detour.
function ParkourFlow.legalJump(from, to, platforms, center, variant)
    if not validDeck(from, platforms) or not validDeck(to, platforms)
        or not JumpRouteCueRules.jumpable(from, to) then
        return false
    end
    local parts = platforms:GetChildren()
    if JumpRouteCueRules.nextPhysical(from, parts, center, variant) == to then
        return true
    end
    if from:GetAttribute("PerimeterStep") == 5 then
        local first, flank = JumpRouteCueRules.forkOptions(from, parts)
        return to == first or to == flank
    end
    if from:GetAttribute("PerimeterStep") == 6 then
        local first, detour = JumpRouteCueRules.crosslinkOptions(from, parts)
        return to == first or to == detour
    end
    return false
end

local function validTime(now)
    return type(now) == "number" and now == now
        and now > -math.huge and now < math.huge
end

local function clearFlight(state)
    state.jumpFrom = nil
    state.jumpAt = nil
    state.jumpOrigin = nil
end

-- A route link is not a jump merely because the character changes Parts.
-- Observe the server Humanoid's Jumping state WHILE the last grounded deck
-- is still within true takeoff/coyote distance. Never accept a client claim.
function ParkourFlow.takeoff(memory, platforms, rootPosition, now)
    local state = memory or {chain = 0, best = 0}
    if state.jumpFrom ~= nil then
        return state, false
    end
    if not validTime(now) or typeof(rootPosition) ~= "Vector3"
        or not validDeck(state.deck, platforms) then
        return state, false
    end
    local position = state.deck.CFrame:PointToObjectSpace(rootPosition)
    local halfX, halfZ = state.deck.Size.X * 0.5, state.deck.Size.Z * 0.5
    local halfY = state.deck.Size.Y * 0.5
    -- Allow legitimate edge/coyote launches, but no jumps teleported from
    -- outside the actual departure deck or already high in the air.
    if math.abs(position.X) > halfX + 3.2
        or math.abs(position.Z) > halfZ + 3.2
        or position.Y < halfY + 0.35
        or position.Y > halfY + 8 then
        return state, false
    end
    state.jumpFrom = state.deck
    state.jumpAt = now
    state.jumpOrigin = rootPosition
    return state, true
end

-- A jump is counted only after an observed takeoff AND a physically verified
-- landing on an authored successor. Reject walking across deck seams,
-- stale airborne events, teleports, repeated contact callbacks and hovering.
-- A failed jump resets the CURRENT chain but never erases the round's best.
function ParkourFlow.advance(memory, landedDeck, platforms, center, variant, now, landingPosition)
    local state = memory or {chain = 0, best = 0}
    if not validTime(now) then
        return state, false
    end
    if not validDeck(landedDeck, platforms) then
        clearFlight(state)
        state.deck = nil
        state.chain = 0
        state.at = nil
        return state, false
    end
    -- Native Landed/Running/FloorMaterial can all fire on the same deck.
    -- A same-deck landing consumes a jump; walking afterward cannot cash it.
    if state.deck == landedDeck then
        clearFlight(state)
        return state, false
    end

    local flightSeconds = now - (state.jumpAt or -math.huge)
    local elapsed = now - (state.at or -math.huge)
    local displacement = math.huge
    if typeof(landingPosition) == "Vector3"
        and typeof(state.jumpOrigin) == "Vector3" then
        local difference = landingPosition - state.jumpOrigin
        displacement = Vector3.new(difference.X, 0, difference.Z).Magnitude
    end
    -- Speed boosts exist; allow 48 studs/s plus 5 studs of sampling/jump
    -- leeway, but do not reward instant multi-deck teleports.
    local plausibleFlight = flightSeconds >= 0.20
        and flightSeconds <= ParkourFlow.MaxAirSeconds
        and displacement >= 0.8
        and displacement <= flightSeconds * 48 + 5
    local continued = state.jumpFrom == state.deck
        and elapsed >= ParkourFlow.MinTransitionSeconds
        and elapsed <= ParkourFlow.MaxTransitionSeconds
        and plausibleFlight
        and ParkourFlow.legalJump(state.deck, landedDeck, platforms, center, variant)
    clearFlight(state)
    state.chain = continued and math.min(7, (state.chain or 0) + 1) or 0
    state.best = math.max(
        math.max(0, math.floor(tonumber(state.best) or 0)),
        state.chain
    )
    state.deck = landedDeck
    state.at = now
    return state, continued
end

function ParkourFlow.bonusXP(best)
    local value = math.max(0, math.floor(tonumber(best) or 0))
    if value >= ParkourFlow.LegendJumps then
        return ParkourFlow.AceXP + ParkourFlow.LegendExtraXP
    end
    return value >= ParkourFlow.AceJumps and ParkourFlow.AceXP or 0
end

-- The actual server world collision determines which deck was landed on.
-- Cosmetic panels, dying decks, inclined sides, and the floor are rejected.
function ParkourFlow.landedDeck(character, platforms, params)
    if typeof(character) ~= "Instance" or not character:IsA("Model")
        or typeof(platforms) ~= "Instance" or not platforms:IsA("Folder")
        or not params then
        return nil
    end
    local h = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not h or h.Health <= 0 or h.FloorMaterial == Enum.Material.Air
        or not root or not root:IsA("BasePart") then
        return nil
    end
    local state = h:GetState()
    if state ~= Enum.HumanoidStateType.Landed
        and state ~= Enum.HumanoidStateType.Running
        and state ~= Enum.HumanoidStateType.RunningNoPhysics then
        return nil
    end
    local hit = workspace:Raycast(
        root.Position, Vector3.new(0, -7.5, 0), params
    )
    local deck = hit and hit.Instance
    if not hit or hit.Normal.Y < 0.84
        or not validDeck(deck, platforms) then
        return nil
    end
    local point = deck.CFrame:PointToObjectSpace(root.Position)
    if math.abs(point.X) > deck.Size.X * 0.5 - 0.1
        or math.abs(point.Z) > deck.Size.Z * 0.5 - 0.1
        or point.Y < deck.Size.Y * 0.5 + 1
        or point.Y > deck.Size.Y * 0.5 + 5.5 then
        return nil
    end
    return deck
end

return ParkourFlow
