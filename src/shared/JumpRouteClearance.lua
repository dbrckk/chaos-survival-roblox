-- A conservative body envelope for route guidance. Actual jumps still
-- use the player's Humanoid physics and the server's collision geometry.
local BODY = Vector3.new(2.2,4.5,2.2)
local EDGE_INSET = 1.2
local BODY_BOTTOM = .14
local SAMPLES = {.28,.72,1}
local STRAIGHT = {1}

local function edge(deck,direction,inset)
    local localDirection = deck.CFrame:VectorToObjectSpace(direction)
    local distance = math.min(deck.Size.X*.5/math.max(.0001,math.abs(localDirection.X)),
        deck.Size.Z*.5/math.max(.0001,math.abs(localDirection.Z)))
    return deck.Position+direction*math.max(0,distance-inset)
        +Vector3.yAxis*(deck.Size.Y*.5+BODY_BOTTOM+BODY.Y*.5)
end

local Clearance = {}

function Clearance.forArena(arena)
    local cast = RaycastParams.new()
    cast.IncludeInstances = {arena}
    cast.RespectCanCollide = true
    local overlap = OverlapParams.new()
    overlap.IncludeInstances = {arena}
    overlap.RespectCanCollide = true
    overlap.MaxParts = 1

    local function arcClear(start,finish,direction,lift)
        local midpoint = (start+finish)*.5
        local facing = CFrame.lookAt(Vector3.zero,direction)

        -- Fast rejection for clear air. This box covers the full arc,
        -- including the player's width and the highest possible headroom.
        local height = BODY.Y+math.abs(finish.Y-start.Y)+lift
        local broadCenter = Vector3.new(midpoint.X,midpoint.Y+lift*.5,midpoint.Z)
        local span = (Vector3.new(finish.X,0,finish.Z)-Vector3.new(start.X,0,start.Z)).Magnitude
        if #workspace:GetPartBoundsInBox(CFrame.new(broadCenter)*facing,
            Vector3.new(BODY.X,height,span+BODY.Z),overlap) == 0 then return true end

        local previous = start
        for _,fraction in ipairs(lift > 0 and SAMPLES or STRAIGHT) do
            local point = start:Lerp(finish,fraction)+Vector3.yAxis*(4*lift*fraction*(1-fraction))
            local frame = CFrame.new(previous)*facing
            -- A cast skips overlaps already present at its starting pose.
            if #workspace:GetPartBoundsInBox(frame,BODY,overlap) > 0
                or workspace:Blockcast(frame,BODY,point-previous,cast) then return false end
            previous = point
        end
        return #workspace:GetPartBoundsInBox(CFrame.new(finish)*facing,BODY,overlap) == 0
    end

    -- floorPoint checks the approach from the arena floor. deckPoint checks
    -- the approach across a raised source deck to its usual takeoff edge.
    local function linkClear(from,target,floorPoint,deckPoint)
        local shutter = target:GetAttribute("BridgeShutterPhase")
        if shutter and shutter ~= "Idle" then return false end
        local delta = target.Position-(floorPoint or from.Position)
        local flat = Vector3.new(delta.X,0,delta.Z)
        if flat.Magnitude < .01 then return false end
        local direction = flat.Unit
        local finish = edge(target,-direction,EDGE_INSET)
        local exclusions = {from,target}
        local start
        if floorPoint then
            local floorY = floorPoint.Y+BODY_BOTTOM+BODY.Y*.5
            local takeoff = edge(target,-direction,-1.3)
            start = Vector3.new(takeoff.X,floorY,takeoff.Z)
            local approach = floorPoint+Vector3.yAxis*(BODY_BOTTOM+BODY.Y*.5)
            local runUp = (start-approach):Dot(direction)
            if runUp < 0 then
                -- Still allow a jump from just outside the edge. Someone
                -- underneath the deck needs to move out before jumping.
                local lip = edge(target,-direction,0)
                if (lip-approach):Dot(direction) <= .05 then return false end
                start = approach
            end
            if runUp > .05 then
                cast.ExcludeInstances = {from}
                overlap.ExcludeInstances = {from}
                if not arcClear(approach,start,direction,0) then return false end
            end
        else
            start = edge(from,direction,EDGE_INSET)
            if deckPoint then
                local approach = deckPoint+Vector3.yAxis*(BODY_BOTTOM+BODY.Y*.5)
                local approachDelta = start-approach
                local heading = Vector3.new(approachDelta.X,0,approachDelta.Z)
                if heading.Magnitude > .05 then
                    cast.ExcludeInstances = {from}
                    overlap.ExcludeInstances = {from}
                    if not arcClear(approach,start,heading.Unit,0) then return false end
                end
            end
        end
        cast.ExcludeInstances = exclusions
        overlap.ExcludeInstances = exclusions
        return arcClear(start,finish,direction,math.abs(finish.Y-start.Y)*.5+1.25)
    end
    -- Verify the floor-return corridor with the same R15 volume. The
    -- destination is a point on the real base, not the centre of the map.
    local function groundExitClear(from, base, destination, deckPoint)
        local delta = destination - from.Position
        local direction = Vector3.new(delta.X, 0, delta.Z).Unit
        local lip = edge(from, direction, EDGE_INSET)
        local bodyOffset = Vector3.yAxis * (BODY_BOTTOM + BODY.Y * .5)
        cast.ExcludeInstances = {from, base}
        overlap.ExcludeInstances = {from, base}
        local approach = deckPoint + bodyOffset
        local shift = lip - approach
        local flat = Vector3.new(shift.X, 0, shift.Z)
        if flat.Magnitude > .05 and not arcClear(approach, lip, flat.Unit, 0) then return false end
        local release = edge(from, direction, -1.35)
        return arcClear(lip, release, direction, 0)
            and arcClear(release, destination + bodyOffset, direction, 0)
    end
    return linkClear, groundExitClear
end

return Clearance
