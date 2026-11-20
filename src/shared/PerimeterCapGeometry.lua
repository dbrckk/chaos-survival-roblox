local PerimeterCapGeometry = {}

function PerimeterCapGeometry.slope(casting)
    if not casting or not casting.Parent or casting.CFrame.UpVector.Y < .999 then return nil end
    local model = casting.Parent
    -- The single SIGNAL region sits toward the high end of the casting.
    -- Its position identifies the high edge even if import swaps or flips X/Z.
    local highEnd
    for _, part in ipairs(model:GetChildren()) do
        if not part:IsA("MeshPart") then continue end
        local size = part.Size
        if math.abs(size.Y - .04066) < .025
            and math.abs(math.max(size.X, size.Z) - .9372) < .055
            and math.abs(math.min(size.X, size.Z) - .1638) < .055 then
            if highEnd then return nil end
            highEnd = casting.CFrame:PointToObjectSpace(part.Position)
        end
    end
    if not highEnd then return nil end
    local sideways = math.abs(highEnd.X) > math.abs(highEnd.Z)
    local forward = if sideways then highEnd.X else highEnd.Z
    local lateral = if sideways then highEnd.Z else highEnd.X
    if math.abs(math.abs(forward) - .4212) > .10 or math.abs(lateral) > .08 then
        return nil
    end
    local yaw = if sideways then -math.sign(forward) * math.pi / 2
        elseif forward < 0 then math.pi else 0
    return CFrame.Angles(0, yaw, 0), sideways
end

return PerimeterCapGeometry
