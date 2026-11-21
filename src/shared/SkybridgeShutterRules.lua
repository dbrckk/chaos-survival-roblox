local Rules = {}

function Rules.active(phase)
    return phase == "Warning" or phase == "Raising" or phase == "Raised"
end

function Rules.forBridge(bridge)
    if not bridge or bridge:GetAttribute("ChaosSkybridge") ~= true then return nil end
    local platforms = bridge.Parent
    local arena = platforms and platforms.Parent
    local mechanics = arena and arena:FindFirstChild("Mechanics")
    local folder = mechanics and mechanics:FindFirstChild("SkybridgeShutters")
    local gate = folder and folder:FindFirstChild("BridgeShutter" .. bridge.Name)
    if gate and gate:IsA("BasePart") and gate:GetAttribute("BridgeShutter") == true
        and gate:GetAttribute("BridgeName") == bridge.Name
        and Rules.active(gate:GetAttribute("ShutterPhase")) then
        return gate
    end
    return nil
end

-- Gate height is measured from the physical deck. Its moving visual CFrame
-- would otherwise miss the corridor while the shutter is still below deck.
function Rules.blocksPath(gate, origin, destination, padding)
    if not gate or not Rules.active(gate:GetAttribute("ShutterPhase")) then return false end
    local deckTop = gate:GetAttribute("ShutterDeckTopY")
    if type(deckTop) ~= "number" then return false end
    local alongX = gate.Size.X < gate.Size.Z
    local a = gate.CFrame:PointToObjectSpace(origin)
    local b = gate.CFrame:PointToObjectSpace(destination)
    local start = alongX and a.X or a.Z
    local finish = alongX and b.X or b.Z
    local halfDepth = (alongX and gate.Size.X or gate.Size.Z) * .5 + (padding or 1.35)
    local canChooseSide = not gate.CanCollide and math.abs(start) <= .1
    if (start * finish >= 0 or canChooseSide)
        and math.abs(finish) >= math.max(math.abs(start), halfDepth) then
        return false -- clear motion out of the shutter, including from its centre
    end

    local delta = finish - start
    local t = math.abs(delta) > .001 and math.clamp(-start / delta, 0, 1) or 0
    if math.abs(start + delta * t) > halfDepth then return false end
    local cross = a:Lerp(b, t)
    local side = alongX and cross.Z or cross.X
    local halfWidth = (alongX and gate.Size.Z or gate.Size.X) * .5 + 1.1
    local y = origin.Y + (destination.Y - origin.Y) * t
    return math.abs(side) <= halfWidth and y >= deckTop + .55
        and y <= deckTop + gate.Size.Y + 2.8
end

function Rules.onBridge(bridge, position)
    local point = bridge.CFrame:PointToObjectSpace(position)
    local height = point.Y - bridge.Size.Y * .5
    return height >= .55 and height <= 6.4
        and math.abs(point.X) <= bridge.Size.X * .5 + .2
        and math.abs(point.Z) <= bridge.Size.Z * .5 + .2
end

-- Stage a short same-side retreat while the bridge is still walkable.
-- A runner at the middle of a noncolliding gate may clear either side.
function Rules.refugeOptions(bridge, gate, position, velocity)
    local alongX = bridge.Size.X > bridge.Size.Z
    local point = bridge.CFrame:PointToObjectSpace(position)
    local motion = bridge.CFrame:VectorToObjectSpace(velocity)
    local span = alongX and bridge.Size.X or bridge.Size.Z
    local gatePoint = bridge.CFrame:PointToObjectSpace(gate.Position)
    local gateAt = alongX and gatePoint.X or gatePoint.Z
    local delta = (alongX and point.X or point.Z) - gateAt
    local speed = alongX and motion.X or motion.Z
    local centered = math.abs(delta) <= .1
    local side = if centered then (speed < 0 and -1 or 1) else math.sign(delta)
    local height = bridge.Size.Y * .5 + 2.4
    local function at(sign, clearance)
        local axial = math.clamp(gateAt + sign * clearance, -span * .5 + 1.5, span * .5 - 1.5)
        return bridge.CFrame:PointToWorldSpace(
            alongX and Vector3.new(axial, height, 0) or Vector3.new(0, height, axial))
    end
    local retreat = math.max(5, math.abs(delta) + 3)
    local farther = math.max(9, math.abs(delta) + 5)
    local alternate = centered and not gate.CanCollide and at(-side, retreat) or nil
    return at(side, retreat), at(side, farther), alternate
end

return Rules
