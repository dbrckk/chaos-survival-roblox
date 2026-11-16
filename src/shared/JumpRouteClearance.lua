-- A conservative body envelope for route guidance. Actual jumps still
-- use the player's Humanoid physics and the server's collision geometry.
local BODY = Vector3.new(2.2,4.5,2.2)
local EDGE_INSET = 1.2
local BODY_BOTTOM = .14
local SAMPLES = {.28,.72,1}

local function edge(deck,direction)
    local localDirection = deck.CFrame:VectorToObjectSpace(direction)
    local distance = math.min(deck.Size.X*.5/math.max(.0001,math.abs(localDirection.X)),
        deck.Size.Z*.5/math.max(.0001,math.abs(localDirection.Z)))
    return deck.Position+direction*math.max(0,distance-EDGE_INSET)
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

    return function(from,target)
        local delta = target.Position-from.Position
        local flat = Vector3.new(delta.X,0,delta.Z)
        if flat.Magnitude < .01 then return false end
        local direction = flat.Unit
        local start,finish = edge(from,direction),edge(target,-direction)
        local midpoint = (start+finish)*.5
        local lift = math.abs(finish.Y-start.Y)*.5+1.25
        local facing = CFrame.lookAt(Vector3.zero,direction)
        local exclusions = {from,target}
        cast.ExcludeInstances = exclusions
        overlap.ExcludeInstances = exclusions

        -- Fast rejection for clear air. This box covers the full arc,
        -- including the player's width and the highest possible headroom.
        local height = BODY.Y+math.abs(finish.Y-start.Y)+lift
        local broadCenter = Vector3.new(midpoint.X,midpoint.Y+lift*.5,midpoint.Z)
        local span = (Vector3.new(finish.X,0,finish.Z)-Vector3.new(start.X,0,start.Z)).Magnitude
        if #workspace:GetPartBoundsInBox(CFrame.new(broadCenter)*facing,
            Vector3.new(BODY.X,height,span+BODY.Z),overlap) == 0 then return true end

        local previous = start
        for _,fraction in ipairs(SAMPLES) do
            local point = start:Lerp(finish,fraction)+Vector3.yAxis*(4*lift*fraction*(1-fraction))
            local frame = CFrame.new(previous)*facing
            -- A cast skips overlaps already present at its starting pose.
            if #workspace:GetPartBoundsInBox(frame,BODY,overlap) > 0
                or workspace:Blockcast(frame,BODY,point-previous,cast) then return false end
            previous = point
        end
        return #workspace:GetPartBoundsInBox(CFrame.new(finish)*facing,BODY,overlap) == 0
    end
end

return Clearance
