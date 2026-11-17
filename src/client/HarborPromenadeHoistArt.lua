-- Static cargo artwork assembled from the certified girder and the
-- separate trolley, cables and load of the approved container crane.
local PlatformSide = if script and script.Parent
    and script.Parent:FindFirstChild("PremiumPlatformSideMeshKit")
    then require(script.Parent.PremiumPlatformSideMeshKit)
    else require("./PremiumPlatformSideMeshKit")

local Art = {}
local ROLE = "OriginalHarborGantryKineticRole"
local MOVING_ROLES = {"Trolley", "Cable", "Load"}
Art.PartCount = 6

function Art.beamSource()
    local beam = PlatformSide.harborGirderSource()
    if beam then beam.model = beam.parts[1].Parent end
    return beam
end

function Art.roles(source)
    local found = {}
    local static = 0
    for _, part in ipairs(source:GetDescendants()) do
        if part:IsA("MeshPart") then
            local role = part:GetAttribute(ROLE)
            if role == "Static" then
                static += 1
            elseif table.find(MOVING_ROLES, role) and not found[role]
                and part.Archivable and part.Transparency < 1 then
                found[role] = part
            else
                return nil
            end
        end
    end
    if static ~= 4 or not (found.Trolley and found.Cable and found.Load) then return nil end
    return found
end

function Art.build(source, beam)
    local roles = Art.roles(source)
    if not roles then return nil end
    local clone, pieces = Instance.new("Model"), {}
    local function add(mesh, role, frame, bounds, id)
        local piece = mesh:Clone()
        if not piece then return false end
        local pose = frame:ToObjectSpace(mesh.CFrame)
        if math.abs(pose.UpVector.Y) < .999
            or math.max(math.abs(pose.RightVector.X), math.abs(pose.RightVector.Z)) < .999 then
            piece:Destroy()
            return false
        end
        piece.Name = "HarborHoist" .. role
        piece:SetAttribute("Original3DAssetId", id)
        piece.Parent = clone
        pieces[piece] = {role=role, frame=pose, bounds=bounds}
        return true
    end
    for _, mesh in ipairs(beam.parts) do
        if not add(mesh, "Arm", beam.frame, beam.bounds, 122766792774607) then
            clone:Destroy()
            return nil
        end
    end
    for _, role in ipairs(MOVING_ROLES) do
        local mesh = roles[role]
        local size = mesh.Size
        local swapped = size.Z > size.X
        local turn = swapped and CFrame.Angles(0, math.pi*.5, 0) or CFrame.identity
        local bounds = swapped and Vector3.new(size.Z, size.Y, size.X) or size
        if not add(mesh, role, mesh.CFrame*turn, bounds, 75684193304551) then
            clone:Destroy()
            return nil
        end
    end
    return clone, pieces
end

function Art.targets(arm, crate, chain, scale)
    local trolley = arm.CFrame * CFrame.new(
        arm.CFrame:PointToObjectSpace(chain.Position).X, -.10, -2*scale)
    local trolleySize = Vector3.new(2.6*scale, 1.25, 4.6*scale)
    local bottom = crate.Position + crate.CFrame.UpVector*(crate.Size.Y*.5-.06)
    local top = trolley.Position - trolley.UpVector*(trolleySize.Y*.5-.06)
    local cableHeight = (top-bottom):Dot(arm.CFrame.UpVector)
    if cableHeight <= .5 then return nil end
    return {
        Arm={frame=arm.CFrame, size=arm.Size*.98},
        Trolley={frame=trolley, size=trolleySize},
        Cable={frame=CFrame.new(bottom+arm.CFrame.UpVector*cableHeight*.5)*arm.CFrame.Rotation,
            size=Vector3.new(1.5*scale,cableHeight,.70*scale)},
        Load={frame=crate.CFrame, size=crate.Size},
    }
end

function Art.refit(piece, target)
    if piece.lastFrame == target.frame and piece.lastSize == target.size then return end
    local pose = piece.frame
    local fit = target.size/piece.bounds
    local right, look = pose.RightVector, pose.LookVector
    local alongX = math.abs(right.X)*fit.X + math.abs(right.Z)*fit.Z
    local alongZ = math.abs(look.X)*fit.X + math.abs(look.Z)*fit.Z
    local size = piece.size*Vector3.new(alongX,fit.Y,alongZ)
    piece.part.Size = Vector3.new(math.max(size.X,.025),size.Y,math.max(size.Z,.025))
    piece.part.CFrame = target.frame*CFrame.new(pose.Position*fit)*pose.Rotation
    piece.lastFrame,piece.lastSize=target.frame,target.size
end

return Art
