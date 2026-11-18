local ExteriorDetailGeometry = {}

-- The complete LOD models use the authored poses, even when an imported
-- fallback region is a quarter-turn away from that reference frame.
function ExteriorDetailGeometry.footprint(part, owner, assetId, fallbackClass)
    if not part or not part:IsA("BasePart") or part.Parent ~= owner
        or not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery then
        return nil
    end
    if part:IsA("MeshPart") then
        if part.MeshId == "" or part:GetAttribute("OriginalExteriorDetail3D") ~= true
            or part:GetAttribute("Original3DAssetId") ~= assetId then
            return nil
        end
        if part:GetAttribute("ExteriorDetailAxisSwap") == true then
            local size = part.Size
            return Vector3.new(size.Z, size.Y, size.X),
                part.CFrame * CFrame.Angles(0, -math.pi * .5, 0)
        end
    elseif not part:IsA(fallbackClass)
        or (fallbackClass == "Part" and part.Shape ~= Enum.PartType.Block) then
        return nil
    end
    return part.Size, part.CFrame
end

return ExteriorDetailGeometry
