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

function ParkourFlow.advance(memory, landedDeck, platforms, center, variant, now)
    local state = memory or {chain = 0, best = 0}
    local tick = tonumber(now)
    if not tick or tick ~= tick or tick == math.huge
        or tick == -math.huge then
        return state, false
    end
    if not validDeck(landedDeck, platforms) then
        state.deck = nil
        state.chain = 0
        state.at = nil
        return state, false
    end
    -- Duplicate Landed/Running transitions must never generate free links.
    if state.deck == landedDeck then
        return state, false
    end
    local elapsed = tick - (state.at or -math.huge)
    local continued = elapsed >= ParkourFlow.MinTransitionSeconds
        and elapsed <= ParkourFlow.MaxTransitionSeconds
        and ParkourFlow.legalJump(state.deck, landedDeck, platforms, center, variant)
    state.chain = continued and math.min(7, (state.chain or 0) + 1) or 0
    state.best = math.max(
        math.max(0, math.floor(tonumber(state.best) or 0)),
        state.chain
    )
    state.deck = landedDeck
    state.at = tick
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
